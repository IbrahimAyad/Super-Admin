/**
 * INVENTORY MANAGEMENT SERVICE
 * Comprehensive inventory tracking and management for order fulfillment
 * Handles stock updates, reservations, and low stock alerts
 */

import { supabase } from '@/lib/supabase-client';

// ============================================
// TYPES AND INTERFACES
// ============================================

export interface InventoryItem {
  id: string;
  variant_id: string;
  product_id: string;
  quantity_in_stock: number;
  quantity_reserved: number;
  quantity_available: number;
  reorder_point: number;
  reorder_quantity: number;
  cost_per_unit: number;
  last_counted_at?: string;
  last_restocked_at?: string;
  warehouse_location?: string;
  created_at: string;
  updated_at: string;
}

export interface InventoryMovement {
  id: string;
  variant_id: string;
  movement_type: MovementType;
  quantity_change: number;
  reason: string;
  reference_id?: string; // Order ID, adjustment ID, etc.
  reference_type?: string; // 'order', 'adjustment', 'restock', etc.
  cost_per_unit?: number;
  notes?: string;
  created_by?: string;
  created_at: string;
}

export interface StockReservation {
  id: string;
  variant_id: string;
  order_id: string;
  quantity_reserved: number;
  reserved_at: string;
  expires_at?: string;
  status: ReservationStatus;
}

export interface LowStockAlert {
  id: string;
  variant_id: string;
  product_name: string;
  variant_name: string;
  current_stock: number;
  reorder_point: number;
  days_of_stock_remaining: number;
  alert_level: AlertLevel;
  acknowledged: boolean;
  acknowledged_by?: string;
  acknowledged_at?: string;
}

export type MovementType = 
  | 'sale'           // Stock sold (order fulfillment)
  | 'return'         // Stock returned
  | 'adjustment'     // Manual adjustment
  | 'restock'        // New stock received
  | 'transfer'       // Transfer between locations
  | 'damaged'        // Damaged/defective stock
  | 'reservation'    // Stock reserved for order
  | 'release'        // Reservation released

export type ReservationStatus = 'active' | 'fulfilled' | 'expired' | 'cancelled';
export type AlertLevel = 'low' | 'critical' | 'out_of_stock';

// ============================================
// INVENTORY TRACKING FUNCTIONS
// ============================================

/**
 * Get current inventory levels for a variant
 */
export async function getInventoryLevel(variantId: string): Promise<InventoryItem | null> {
  try {
    const { data, error } = await supabase
      .from('inventory')
      .select(`
        *,
        product_variants!inner(
          id,
          name,
          product_id,
          products!inner(
            id,
            name,
            sku
          )
        )
      `)
      .eq('variant_id', variantId)
      .single();

    if (error && error.code !== 'PGRST116') throw error;

    return data || null;
  } catch (error) {
    console.error('Error getting inventory level:', error);
    throw error;
  }
}

/**
 * Update inventory levels after order fulfillment
 */
export async function updateInventoryForFulfillment(
  orderId: string,
  items: Array<{ variant_id: string; quantity: number }>
): Promise<void> {
  try {
    for (const item of items) {
      if (!item.variant_id) continue;

      // Get current inventory
      const inventory = await getInventoryLevel(item.variant_id);
      if (!inventory) {
        console.warn(`No inventory record found for variant ${item.variant_id}`);
        continue;
      }

      // Calculate new quantities
      const newQuantityInStock = Math.max(0, inventory.quantity_in_stock - item.quantity);
      const newQuantityReserved = Math.max(0, inventory.quantity_reserved - item.quantity);
      const newQuantityAvailable = newQuantityInStock - newQuantityReserved;

      // Update inventory
      const { error: updateError } = await supabase
        .from('inventory')
        .update({
          quantity_in_stock: newQuantityInStock,
          quantity_reserved: newQuantityReserved,
          quantity_available: newQuantityAvailable,
          updated_at: new Date().toISOString()
        })
        .eq('variant_id', item.variant_id);

      if (updateError) throw updateError;

      // Record inventory movement
      await recordInventoryMovement({
        variant_id: item.variant_id,
        movement_type: 'sale',
        quantity_change: -item.quantity,
        reason: 'Order fulfillment',
        reference_id: orderId,
        reference_type: 'order'
      });

      // Update reservation status
      await supabase
        .from('stock_reservations')
        .update({
          status: 'fulfilled',
          updated_at: new Date().toISOString()
        })
        .eq('order_id', orderId)
        .eq('variant_id', item.variant_id);

      // Check for low stock alerts
      await checkLowStockAlert(item.variant_id);
    }
  } catch (error) {
    console.error('Error updating inventory for fulfillment:', error);
    throw error;
  }
}

/**
 * Reserve inventory for an order
 */
export async function reserveInventory(
  orderId: string,
  items: Array<{ variant_id: string; quantity: number }>,
  expirationHours: number = 24
): Promise<{ success: boolean; reservations: StockReservation[]; errors: string[] }> {
  const reservations: StockReservation[] = [];
  const errors: string[] = [];

  try {
    for (const item of items) {
      if (!item.variant_id) continue;

      // Get current inventory
      const inventory = await getInventoryLevel(item.variant_id);
      if (!inventory) {
        errors.push(`No inventory record found for variant ${item.variant_id}`);
        continue;
      }

      // Check if enough stock is available
      if (inventory.quantity_available < item.quantity) {
        errors.push(`Insufficient stock for variant ${item.variant_id}. Available: ${inventory.quantity_available}, Requested: ${item.quantity}`);
        continue;
      }

      // Create reservation
      const expiresAt = new Date();
      expiresAt.setHours(expiresAt.getHours() + expirationHours);

      const { data: reservation, error: reservationError } = await supabase
        .from('stock_reservations')
        .insert({
          variant_id: item.variant_id,
          order_id: orderId,
          quantity_reserved: item.quantity,
          expires_at: expiresAt.toISOString(),
          status: 'active'
        })
        .select()
        .single();

      if (reservationError) {
        errors.push(`Failed to create reservation for variant ${item.variant_id}: ${reservationError.message}`);
        continue;
      }

      // Update inventory quantities
      const newQuantityReserved = inventory.quantity_reserved + item.quantity;
      const newQuantityAvailable = inventory.quantity_in_stock - newQuantityReserved;

      const { error: updateError } = await supabase
        .from('inventory')
        .update({
          quantity_reserved: newQuantityReserved,
          quantity_available: newQuantityAvailable,
          updated_at: new Date().toISOString()
        })
        .eq('variant_id', item.variant_id);

      if (updateError) {
        errors.push(`Failed to update inventory for variant ${item.variant_id}: ${updateError.message}`);
        continue;
      }

      // Record inventory movement
      await recordInventoryMovement({
        variant_id: item.variant_id,
        movement_type: 'reservation',
        quantity_change: -item.quantity,
        reason: 'Stock reserved for order',
        reference_id: orderId,
        reference_type: 'order'
      });

      reservations.push(reservation);
    }

    return {
      success: errors.length === 0,
      reservations,
      errors
    };
  } catch (error) {
    console.error('Error reserving inventory:', error);
    throw error;
  }
}

/**
 * Release inventory reservations (when order is cancelled)
 */
export async function releaseInventoryReservations(orderId: string): Promise<void> {
  try {
    // Get active reservations for the order
    const { data: reservations, error: reservationsError } = await supabase
      .from('stock_reservations')
      .select('*')
      .eq('order_id', orderId)
      .eq('status', 'active');

    if (reservationsError) throw reservationsError;

    for (const reservation of reservations || []) {
      // Get current inventory
      const inventory = await getInventoryLevel(reservation.variant_id);
      if (!inventory) continue;

      // Update inventory quantities
      const newQuantityReserved = Math.max(0, inventory.quantity_reserved - reservation.quantity_reserved);
      const newQuantityAvailable = inventory.quantity_in_stock - newQuantityReserved;

      const { error: updateError } = await supabase
        .from('inventory')
        .update({
          quantity_reserved: newQuantityReserved,
          quantity_available: newQuantityAvailable,
          updated_at: new Date().toISOString()
        })
        .eq('variant_id', reservation.variant_id);

      if (updateError) throw updateError;

      // Update reservation status
      await supabase
        .from('stock_reservations')
        .update({
          status: 'cancelled',
          updated_at: new Date().toISOString()
        })
        .eq('id', reservation.id);

      // Record inventory movement
      await recordInventoryMovement({
        variant_id: reservation.variant_id,
        movement_type: 'release',
        quantity_change: reservation.quantity_reserved,
        reason: 'Reservation released - order cancelled',
        reference_id: orderId,
        reference_type: 'order'
      });
    }
  } catch (error) {
    console.error('Error releasing inventory reservations:', error);
    throw error;
  }
}

/**
 * Handle inventory for returns
 */
export async function processReturnInventory(
  orderId: string,
  items: Array<{ variant_id: string; quantity: number; condition: string }>
): Promise<void> {
  try {
    for (const item of items) {
      if (!item.variant_id) continue;

      // Determine if item can be restocked based on condition
      const canRestock = ['new', 'like_new', 'good'].includes(item.condition);
      
      if (canRestock) {
        // Get current inventory
        const inventory = await getInventoryLevel(item.variant_id);
        if (!inventory) continue;

        // Update inventory levels
        const newQuantityInStock = inventory.quantity_in_stock + item.quantity;
        const newQuantityAvailable = newQuantityInStock - inventory.quantity_reserved;

        const { error: updateError } = await supabase
          .from('inventory')
          .update({
            quantity_in_stock: newQuantityInStock,
            quantity_available: newQuantityAvailable,
            updated_at: new Date().toISOString()
          })
          .eq('variant_id', item.variant_id);

        if (updateError) throw updateError;

        // Record inventory movement
        await recordInventoryMovement({
          variant_id: item.variant_id,
          movement_type: 'return',
          quantity_change: item.quantity,
          reason: `Return processed - condition: ${item.condition}`,
          reference_id: orderId,
          reference_type: 'return'
        });
      } else {
        // Record as damaged/non-restockable
        await recordInventoryMovement({
          variant_id: item.variant_id,
          movement_type: 'damaged',
          quantity_change: 0,
          reason: `Return not restocked - condition: ${item.condition}`,
          reference_id: orderId,
          reference_type: 'return'
        });
      }
    }
  } catch (error) {
    console.error('Error processing return inventory:', error);
    throw error;
  }
}

// ============================================
// INVENTORY MOVEMENTS
// ============================================

/**
 * Record inventory movement
 */
export async function recordInventoryMovement(movement: {
  variant_id: string;
  movement_type: MovementType;
  quantity_change: number;
  reason: string;
  reference_id?: string;
  reference_type?: string;
  cost_per_unit?: number;
  notes?: string;
}): Promise<InventoryMovement> {
  try {
    const { data, error } = await supabase
      .from('inventory_movements')
      .insert({
        ...movement,
        created_at: new Date().toISOString()
      })
      .select()
      .single();

    if (error) throw error;
    return data;
  } catch (error) {
    console.error('Error recording inventory movement:', error);
    throw error;
  }
}

/**
 * Get inventory movement history for a variant
 */
export async function getInventoryMovements(
  variantId: string,
  limit: number = 50
): Promise<InventoryMovement[]> {
  try {
    const { data, error } = await supabase
      .from('inventory_movements')
      .select('*')
      .eq('variant_id', variantId)
      .order('created_at', { ascending: false })
      .limit(limit);

    if (error) throw error;
    return data || [];
  } catch (error) {
    console.error('Error getting inventory movements:', error);
    throw error;
  }
}

// ============================================
// LOW STOCK ALERTS
// ============================================

/**
 * Check and create low stock alerts
 */
export async function checkLowStockAlert(variantId: string): Promise<void> {
  try {
    const inventory = await getInventoryLevel(variantId);
    if (!inventory) return;

    const alertLevel = determineAlertLevel(inventory);
    if (!alertLevel) return;

    // Check if alert already exists and is not acknowledged
    const { data: existingAlert } = await supabase
      .from('low_stock_alerts')
      .select('id')
      .eq('variant_id', variantId)
      .eq('acknowledged', false)
      .single();

    if (existingAlert) return; // Alert already exists

    // Calculate days of stock remaining (simplified calculation)
    const daysOfStockRemaining = calculateDaysOfStock(inventory);

    // Create new alert
    await supabase
      .from('low_stock_alerts')
      .insert({
        variant_id: variantId,
        product_name: inventory.product_variants?.products?.name || 'Unknown Product',
        variant_name: inventory.product_variants?.name || 'Default Variant',
        current_stock: inventory.quantity_available,
        reorder_point: inventory.reorder_point,
        days_of_stock_remaining: daysOfStockRemaining,
        alert_level: alertLevel,
        acknowledged: false
      });

  } catch (error) {
    console.error('Error checking low stock alert:', error);
  }
}

/**
 * Determine alert level based on inventory
 */
function determineAlertLevel(inventory: InventoryItem): AlertLevel | null {
  if (inventory.quantity_available <= 0) {
    return 'out_of_stock';
  } else if (inventory.quantity_available <= inventory.reorder_point * 0.5) {
    return 'critical';
  } else if (inventory.quantity_available <= inventory.reorder_point) {
    return 'low';
  }
  return null;
}

/**
 * Calculate estimated days of stock remaining
 */
function calculateDaysOfStock(inventory: InventoryItem): number {
  // This is a simplified calculation
  // In production, you'd use sales velocity data
  const averageDailySales = 1; // Placeholder
  return Math.floor(inventory.quantity_available / averageDailySales);
}

/**
 * Get low stock alerts
 */
export async function getLowStockAlerts(
  alertLevel?: AlertLevel,
  acknowledged?: boolean
): Promise<LowStockAlert[]> {
  try {
    let query = supabase
      .from('low_stock_alerts')
      .select('*')
      .order('alert_level', { ascending: false })
      .order('created_at', { ascending: false });

    if (alertLevel) {
      query = query.eq('alert_level', alertLevel);
    }

    if (acknowledged !== undefined) {
      query = query.eq('acknowledged', acknowledged);
    }

    const { data, error } = await query;
    if (error) throw error;

    return data || [];
  } catch (error) {
    console.error('Error getting low stock alerts:', error);
    throw error;
  }
}

/**
 * Acknowledge low stock alert
 */
export async function acknowledgeLowStockAlert(
  alertId: string,
  acknowledgedBy: string
): Promise<void> {
  try {
    const { error } = await supabase
      .from('low_stock_alerts')
      .update({
        acknowledged: true,
        acknowledged_by: acknowledgedBy,
        acknowledged_at: new Date().toISOString()
      })
      .eq('id', alertId);

    if (error) throw error;
  } catch (error) {
    console.error('Error acknowledging low stock alert:', error);
    throw error;
  }
}

// ============================================
// INVENTORY ADJUSTMENTS
// ============================================

/**
 * Create inventory adjustment
 */
export async function createInventoryAdjustment(adjustment: {
  variant_id: string;
  quantity_change: number;
  reason: string;
  cost_per_unit?: number;
  notes?: string;
}): Promise<void> {
  try {
    // Get current inventory
    const inventory = await getInventoryLevel(adjustment.variant_id);
    if (!inventory) {
      throw new Error(`No inventory record found for variant ${adjustment.variant_id}`);
    }

    // Calculate new quantities
    const newQuantityInStock = Math.max(0, inventory.quantity_in_stock + adjustment.quantity_change);
    const newQuantityAvailable = newQuantityInStock - inventory.quantity_reserved;

    // Update inventory
    const { error: updateError } = await supabase
      .from('inventory')
      .update({
        quantity_in_stock: newQuantityInStock,
        quantity_available: newQuantityAvailable,
        updated_at: new Date().toISOString()
      })
      .eq('variant_id', adjustment.variant_id);

    if (updateError) throw updateError;

    // Record movement
    await recordInventoryMovement({
      variant_id: adjustment.variant_id,
      movement_type: 'adjustment',
      quantity_change: adjustment.quantity_change,
      reason: adjustment.reason,
      cost_per_unit: adjustment.cost_per_unit,
      notes: adjustment.notes
    });

    // Check for alerts
    await checkLowStockAlert(adjustment.variant_id);

  } catch (error) {
    console.error('Error creating inventory adjustment:', error);
    throw error;
  }
}

/**
 * Process restock
 */
export async function processRestock(restock: {
  variant_id: string;
  quantity: number;
  cost_per_unit: number;
  supplier?: string;
  reference_number?: string;
  notes?: string;
}): Promise<void> {
  try {
    // Get current inventory
    const inventory = await getInventoryLevel(restock.variant_id);
    if (!inventory) {
      throw new Error(`No inventory record found for variant ${restock.variant_id}`);
    }

    // Calculate new quantities
    const newQuantityInStock = inventory.quantity_in_stock + restock.quantity;
    const newQuantityAvailable = newQuantityInStock - inventory.quantity_reserved;

    // Update inventory
    const { error: updateError } = await supabase
      .from('inventory')
      .update({
        quantity_in_stock: newQuantityInStock,
        quantity_available: newQuantityAvailable,
        cost_per_unit: restock.cost_per_unit,
        last_restocked_at: new Date().toISOString(),
        updated_at: new Date().toISOString()
      })
      .eq('variant_id', restock.variant_id);

    if (updateError) throw updateError;

    // Record movement
    await recordInventoryMovement({
      variant_id: restock.variant_id,
      movement_type: 'restock',
      quantity_change: restock.quantity,
      reason: `Restock from ${restock.supplier || 'supplier'}`,
      reference_id: restock.reference_number,
      reference_type: 'purchase_order',
      cost_per_unit: restock.cost_per_unit,
      notes: restock.notes
    });

  } catch (error) {
    console.error('Error processing restock:', error);
    throw error;
  }
}

// ============================================
// INVENTORY REPORTS
// ============================================

/**
 * Get inventory summary report
 */
export async function getInventorySummaryReport(): Promise<{
  total_products: number;
  total_variants: number;
  total_stock_value: number;
  low_stock_items: number;
  out_of_stock_items: number;
}> {
  try {
    const { data: summary, error } = await supabase
      .rpc('get_inventory_summary');

    if (error) throw error;

    return summary[0] || {
      total_products: 0,
      total_variants: 0,
      total_stock_value: 0,
      low_stock_items: 0,
      out_of_stock_items: 0
    };
  } catch (error) {
    console.error('Error getting inventory summary:', error);
    throw error;
  }
}

/**
 * Get low stock report
 */
export async function getLowStockReport(): Promise<Array<{
  variant_id: string;
  product_name: string;
  variant_name: string;
  sku: string;
  current_stock: number;
  reorder_point: number;
  reorder_quantity: number;
  cost_per_unit: number;
  days_of_stock: number;
}>> {
  try {
    const { data, error } = await supabase
      .from('inventory')
      .select(`
        variant_id,
        quantity_available,
        reorder_point,
        reorder_quantity,
        cost_per_unit,
        product_variants!inner(
          id,
          name,
          sku,
          products!inner(
            id,
            name
          )
        )
      `)
      .lte('quantity_available', supabase.raw('reorder_point'))
      .order('quantity_available', { ascending: true });

    if (error) throw error;

    return (data || []).map(item => ({
      variant_id: item.variant_id,
      product_name: item.product_variants.products.name,
      variant_name: item.product_variants.name,
      sku: item.product_variants.sku,
      current_stock: item.quantity_available,
      reorder_point: item.reorder_point,
      reorder_quantity: item.reorder_quantity,
      cost_per_unit: item.cost_per_unit,
      days_of_stock: calculateDaysOfStock(item as any)
    }));
  } catch (error) {
    console.error('Error getting low stock report:', error);
    throw error;
  }
}

// ============================================
// CLEANUP FUNCTIONS
// ============================================

/**
 * Clean up expired reservations
 */
export async function cleanupExpiredReservations(): Promise<void> {
  try {
    // Get expired reservations
    const { data: expiredReservations, error: expiredError } = await supabase
      .from('stock_reservations')
      .select('*')
      .eq('status', 'active')
      .lt('expires_at', new Date().toISOString());

    if (expiredError) throw expiredError;

    for (const reservation of expiredReservations || []) {
      // Release the reservation
      await releaseInventoryReservations(reservation.order_id);
      
      // Mark as expired
      await supabase
        .from('stock_reservations')
        .update({
          status: 'expired',
          updated_at: new Date().toISOString()
        })
        .eq('id', reservation.id);
    }
  } catch (error) {
    console.error('Error cleaning up expired reservations:', error);
  }
}

/**
 * Initialize inventory record for new variant
 */
export async function initializeInventoryRecord(variantId: string): Promise<void> {
  try {
    // Check if record already exists
    const existing = await getInventoryLevel(variantId);
    if (existing) return;

    // Create new inventory record
    const { error } = await supabase
      .from('inventory')
      .insert({
        variant_id: variantId,
        quantity_in_stock: 0,
        quantity_reserved: 0,
        quantity_available: 0,
        reorder_point: 5,
        reorder_quantity: 20,
        cost_per_unit: 0,
        warehouse_location: 'main'
      });

    if (error) throw error;
  } catch (error) {
    console.error('Error initializing inventory record:', error);
    throw error;
  }
}