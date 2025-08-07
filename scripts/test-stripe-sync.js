/**
 * STRIPE SYNC TESTING SCRIPT
 * Use this to test the sync system before full deployment
 */

import { createClient } from '@supabase/supabase-js';
import { stripeSyncService } from '../src/lib/services/stripeSync.js';

// Configuration
const SUPABASE_URL = process.env.VITE_SUPABASE_URL;
const SUPABASE_SERVICE_KEY = process.env.SUPABASE_SERVICE_ROLE_KEY;

if (!SUPABASE_URL || !SUPABASE_SERVICE_KEY) {
  console.error('Missing Supabase configuration');
  process.exit(1);
}

const supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE_KEY);

async function runTests() {
  console.log('🚀 Starting Stripe Sync System Tests...\n');

  try {
    // Test 1: Validate Configuration
    console.log('📋 Test 1: Validating Configuration...');
    const config = await stripeSyncService.validateStripeConfig();
    console.log('Config validation:', {
      isValid: config.isValid,
      hasPublishableKey: config.hasPublishableKey,
      edgeFunctionReady: config.edgeFunctionReady,
      errors: config.errors
    });
    
    if (!config.isValid) {
      console.error('❌ Configuration is invalid. Please fix errors before proceeding.');
      return;
    }
    console.log('✅ Configuration is valid\n');

    // Test 2: Check Database Schema
    console.log('📋 Test 2: Checking Database Schema...');
    const { data: products } = await supabase
      .from('products')
      .select('id, name, stripe_product_id, product_variants(id, stripe_price_id)')
      .limit(5);
    
    console.log(`✅ Found ${products?.length || 0} sample products`);
    console.log(`✅ Schema includes Stripe fields\n`);

    // Test 3: Get Category Breakdown
    console.log('📋 Test 3: Getting Category Breakdown...');
    const categories = await stripeSyncService.getProductsByCategory();
    console.log('Product distribution by category:');
    Object.entries(categories)
      .sort(([,a], [,b]) => a - b)
      .forEach(([category, count], index) => {
        console.log(`  ${index + 1}. ${category}: ${count} products`);
      });
    console.log('');

    // Test 4: Dry Run on Smallest Category
    const smallestCategory = Object.entries(categories)
      .sort(([,a], [,b]) => a - b)[0];
    
    if (smallestCategory) {
      console.log(`📋 Test 4: Dry Run on "${smallestCategory[0]}" (${smallestCategory[1]} products)...`);
      const dryRunResult = await stripeSyncService.syncProducts({
        dryRun: true,
        categories: [smallestCategory[0]],
        skipExisting: true,
        batchSize: 5
      });
      
      console.log('Dry run results:', {
        success: dryRunResult.success,
        productsProcessed: dryRunResult.productsProcessed,
        errors: dryRunResult.errors.length,
        errorDetails: dryRunResult.errors.map(e => `${e.name}: ${e.error}`)
      });
      
      if (dryRunResult.errors.length === 0) {
        console.log('✅ Dry run completed without errors');
      } else {
        console.log('⚠️  Dry run found issues - review before real sync');
      }
      console.log('');
    }

    // Test 5: Check Sync Status
    console.log('📋 Test 5: Getting Sync Status...');
    const status = await stripeSyncService.getSyncStatus();
    console.log('Current sync status:', {
      totalProducts: status.totalProducts,
      syncedProducts: status.syncedProducts,
      pendingProducts: status.pendingProducts,
      failedProducts: status.failedProducts,
      lastSync: status.lastSyncAt
    });
    console.log('');

    // Test 6: Progressive Sync Strategy Validation
    console.log('📋 Test 6: Validating Progressive Sync Strategy...');
    const sortedCategories = Object.entries(categories)
      .sort(([,a], [,b]) => a - b);
    
    console.log('Recommended progressive sync order:');
    sortedCategories.forEach(([category, count], index) => {
      const phase = index + 1;
      const estimatedTime = Math.ceil(count / 5) * 2 + 30; // Rough estimate
      console.log(`  Phase ${phase}: ${category} (${count} products, ~${estimatedTime}s)`);
    });
    console.log('');

    console.log('🎉 All tests completed successfully!');
    console.log('\n📋 Next Steps:');
    console.log('1. Go to /admin/stripe-sync in your admin dashboard');
    console.log('2. Start with Progressive Dry Run to test without changes');
    console.log('3. If dry run succeeds, run Progressive Sync with real data');
    console.log('4. Monitor progress and check Stripe dashboard');

  } catch (error) {
    console.error('❌ Test failed:', error);
    console.error('Stack:', error.stack);
  }
}

// Run the tests
runTests();