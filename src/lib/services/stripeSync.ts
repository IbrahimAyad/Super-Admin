/**
 * STRIPE SYNC SERVICE
 * Safe, incremental synchronization of products to Stripe
 * 
 * Features:
 * - Batch processing to avoid rate limits
 * - Rollback capability
 * - Progress tracking
 * - Error recovery
 * - Dry run mode for testing
 */

import { supabase } from '../supabase-client';

export interface SyncOptions {
  dryRun?: boolean;
  batchSize?: number;
  categories?: string[];
  productIds?: string[];
  skipExisting?: boolean;
}

export interface SyncResult {
  success: boolean;
  productsProcessed: number;
  variantsProcessed: number;
  errors: Array<{
    type: 'product' | 'variant';
    id: string;
    name: string;
    error: string;
  }>;
  skipped: number;
}

export class StripeSyncService {
  private batchSize: number = 10; // Process 10 products at a time to avoid rate limits

  /**
   * Sync products to Stripe
   * This is the main entry point for syncing
   */
  async syncProducts(options: SyncOptions = {}): Promise<SyncResult> {
    const result: SyncResult = {
      success: true,
      productsProcessed: 0,
      variantsProcessed: 0,
      errors: [],
      skipped: 0
    };

    try {
      // Get products to sync
      const products = await this.getProductsToSync(options);
      
      if (products.length === 0) {
        console.log('No products to sync');
        return result;
      }

      console.log(`Starting sync for ${products.length} products...`);

      // Process in batches
      const batchSize = options.batchSize || this.batchSize;
      for (let i = 0; i < products.length; i += batchSize) {
        const batch = products.slice(i, i + batchSize);
        console.log(`Processing batch ${Math.floor(i / batchSize) + 1}/${Math.ceil(products.length / batchSize)}`);
        
        for (const product of batch) {
          if (options.dryRun) {
            console.log(`[DRY RUN] Would sync product: ${product.name} (${product.id})`);
            result.productsProcessed++;
            continue;
          }

          try {
            await this.syncSingleProduct(product, options);
            result.productsProcessed++;
          } catch (error) {
            console.error(`Failed to sync product ${product.name}:`, error);
            result.errors.push({
              type: 'product',
              id: product.id,
              name: product.name,
              error: error.message
            });
            result.success = false;
          }
        }

        // Add delay between batches to respect rate limits
        if (i + batchSize < products.length && !options.dryRun) {
          console.log('Waiting 2 seconds before next batch...');
          await new Promise(resolve => setTimeout(resolve, 2000));
        }
      }

      // Log final results
      console.log('Sync completed:', {
        processed: result.productsProcessed,
        errors: result.errors.length,
        skipped: result.skipped
      });

    } catch (error) {
      console.error('Sync failed:', error);
      result.success = false;
      throw error;
    }

    return result;
  }

  /**
   * Get products that need syncing
   */
  private async getProductsToSync(options: SyncOptions) {
    let query = supabase
      .from('products')
      .select(`
        *,
        product_variants (
          id,
          title,
          price,
          sku,
          inventory_quantity,
          stripe_price_id
        )
      `);

    // Filter by sync status
    if (options.skipExisting) {
      query = query.is('stripe_product_id', null);
    }

    // Filter by categories if specified
    if (options.categories && options.categories.length > 0) {
      query = query.in('category', options.categories);
    }

    // Filter by specific product IDs if specified
    if (options.productIds && options.productIds.length > 0) {
      query = query.in('id', options.productIds);
    }

    const { data, error } = await query;

    if (error) {
      throw new Error(`Failed to fetch products: ${error.message}`);
    }

    return data || [];
  }

  /**
   * Sync a single product to Stripe
   */
  private async syncSingleProduct(product: any, options: SyncOptions) {
    console.log(`Syncing product: ${product.name}`);

    // Skip if already synced and skipExisting is true
    if (product.stripe_product_id && options.skipExisting) {
      console.log(`Skipping ${product.name} - already synced`);
      return;
    }

    // Call Edge Function to create/update Stripe product
    const { data: syncResult, error: syncError } = await supabase.functions.invoke('sync-stripe-product', {
      body: {
        product: {
          id: product.id,
          name: product.name,
          description: product.description,
          sku: product.sku,
          metadata: {
            supabase_id: product.id,
            category: product.category,
            vendor: product.vendor
          }
        },
        variants: product.product_variants.map((variant: any) => ({
          id: variant.id,
          price: variant.price,
          title: variant.title,
          sku: variant.sku,
          metadata: {
            supabase_variant_id: variant.id,
            inventory_quantity: variant.inventory_quantity
          }
        })),
        mode: product.stripe_product_id ? 'update' : 'create'
      }
    });

    if (syncError) {
      throw new Error(`Stripe sync failed: ${syncError.message}`);
    }

    // Update product with Stripe IDs
    const { error: updateError } = await supabase
      .from('products')
      .update({
        stripe_product_id: syncResult.stripe_product_id,
        stripe_sync_status: 'synced',
        stripe_synced_at: new Date().toISOString()
      })
      .eq('id', product.id);

    if (updateError) {
      throw new Error(`Failed to update product: ${updateError.message}`);
    }

    // Update variants with Stripe price IDs
    if (syncResult.price_ids) {
      for (const [variantId, stripePriceId] of Object.entries(syncResult.price_ids)) {
        await supabase
          .from('product_variants')
          .update({ stripe_price_id: stripePriceId })
          .eq('id', variantId);
      }
    }

    // Log sync
    await this.logSync('product', product.id, 'success', {
      stripe_product_id: syncResult.stripe_product_id,
      variants_synced: syncResult.price_ids ? Object.keys(syncResult.price_ids).length : 0
    });

    console.log(`✓ Synced ${product.name} with ${product.product_variants.length} variants`);
  }

  /**
   * Log sync operation
   */
  private async logSync(type: string, entityId: string, status: string, metadata?: any) {
    await supabase
      .from('stripe_sync_log')
      .insert({
        sync_type: type,
        entity_id: entityId,
        entity_type: type,
        status: status,
        metadata: metadata,
        action: status === 'success' ? 'create' : 'error'
      });
  }

  /**
   * Get sync status summary
   */
  async getSyncStatus(): Promise<{
    totalProducts: number;
    syncedProducts: number;
    pendingProducts: number;
    failedProducts: number;
    totalVariants: number;
    syncedVariants: number;
    lastSyncAt: string | null;
  }> {
    const { data, error } = await supabase
      .from('stripe_sync_summary')
      .select('*')
      .single();

    if (error) {
      console.error('Failed to get sync status:', error);
      return {
        totalProducts: 0,
        syncedProducts: 0,
        pendingProducts: 0,
        failedProducts: 0,
        totalVariants: 0,
        syncedVariants: 0,
        lastSyncAt: null
      };
    }

    return {
      totalProducts: data.products_synced + data.products_pending,
      syncedProducts: data.products_synced,
      pendingProducts: data.products_pending,
      failedProducts: data.products_failed,
      totalVariants: data.variants_synced + data.variants_pending,
      syncedVariants: data.variants_synced,
      lastSyncAt: data.last_sync_at
    };
  }

  /**
   * Validate Stripe configuration
   */
  async validateStripeConfig(): Promise<{
    isValid: boolean;
    hasSecretKey: boolean;
    hasPublishableKey: boolean;
    edgeFunctionReady: boolean;
    errors: string[];
  }> {
    const errors: string[] = [];
    
    // Check for publishable key in environment
    const hasPublishableKey = !!import.meta.env.VITE_STRIPE_PUBLISHABLE_KEY && 
                              !import.meta.env.VITE_STRIPE_PUBLISHABLE_KEY.includes('your-stripe');
    
    if (!hasPublishableKey) {
      errors.push('Stripe publishable key not configured in .env');
    }

    // Test Edge Function availability
    let edgeFunctionReady = false;
    try {
      const { error } = await supabase.functions.invoke('sync-stripe-products', {
        body: { test: true }
      });
      edgeFunctionReady = !error;
      if (error) {
        errors.push(`Edge Function not ready: ${error.message}`);
      }
    } catch (e) {
      errors.push('Edge Function not accessible');
    }

    return {
      isValid: errors.length === 0,
      hasSecretKey: true, // Assumed to be in Edge Functions
      hasPublishableKey,
      edgeFunctionReady,
      errors
    };
  }

  /**
   * Rollback sync for specific products
   */
  async rollbackSync(productIds: string[]): Promise<{
    success: boolean;
    rolledBack: number;
    errors: string[];
  }> {
    const errors: string[] = [];
    let rolledBack = 0;

    for (const productId of productIds) {
      try {
        // Clear Stripe IDs from product
        await supabase
          .from('products')
          .update({
            stripe_product_id: null,
            stripe_sync_status: 'pending',
            stripe_synced_at: null,
            stripe_sync_error: null
          })
          .eq('id', productId);

        // Clear Stripe IDs from variants
        await supabase
          .from('product_variants')
          .update({ stripe_price_id: null })
          .eq('product_id', productId);

        rolledBack++;
      } catch (error) {
        errors.push(`Failed to rollback ${productId}: ${error.message}`);
      }
    }

    return {
      success: errors.length === 0,
      rolledBack,
      errors
    };
  }
}

// Export singleton instance
export const stripeSyncService = new StripeSyncService();
export default stripeSyncService;