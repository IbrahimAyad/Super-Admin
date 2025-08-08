import { supabase } from '@/lib/supabase-client';

// Order Status Flow
export const ORDER_STATUS_FLOW = {
  pending: ['confirmed', 'cancelled'],
  confirmed: ['processing', 'cancelled'],
  processing: ['shipped', 'cancelled'],
  shipped: ['delivered', 'returned'],
  delivered: ['returned'],
  cancelled: [],
  returned: ['refunded'],
  refunded: []
};

// Order Status Descriptions
export const ORDER_STATUS_DESCRIPTIONS = {
  pending: 'Order placed, awaiting confirmation',
  confirmed: 'Order confirmed, payment verified',
  processing: 'Order is being prepared for shipment',
  shipped: 'Order has been shipped',
  delivered: 'Order has been delivered',
  cancelled: 'Order has been cancelled',
  returned: 'Order has been returned',
  refunded: 'Order has been refunded'
};

export interface OrderStatusUpdate {
  orderId: string;
  newStatus: string;
  notes?: string;
  trackingNumber?: string;
  carrierName?: string;
  estimatedDelivery?: string;
  actualDelivery?: string;
}

export interface ShippingLabel {
  orderId: string;
  carrier: 'usps' | 'ups' | 'fedex' | 'dhl';
  serviceType: string;
  weight: number;
  dimensions?: {
    length: number;
    width: number;
    height: number;
  };
}

export interface OrderTimeline {
  id: string;
  order_id: string;
  status: string;
  description: string;
  created_at: string;
  created_by?: string;
  metadata?: any;
}

/**
 * Get detailed order with all related data
 */
export async function getOrderDetails(orderId: string) {
  try {
    const { data: order, error } = await supabase
      .from('orders')
      .select(`
        *,
        customers!left(
          id,
          first_name,
          last_name,
          email,
          phone,
          stripe_customer_id
        ),
        order_status_history!left(
          id,
          status,
          notes,
          created_at,
          created_by
        ),
        refund_requests!left(
          id,
          reason,
          refund_amount,
          status,
          created_at
        )
      `)
      .eq('id', orderId)
      .single();

    if (error) throw error;

    // Parse items if they're stored as JSONB
    if (order?.items && typeof order.items === 'string') {
      order.items = JSON.parse(order.items);
    }

    return order;
  } catch (error) {
    console.error('Error fetching order details:', error);
    throw error;
  }
}

/**
 * Update order status with validation and history tracking
 */
export async function updateOrderStatus(update: OrderStatusUpdate) {
  try {
    // Get current order status
    const { data: currentOrder, error: fetchError } = await supabase
      .from('orders')
      .select('status, order_number')
      .eq('id', update.orderId)
      .single();

    if (fetchError) throw fetchError;
    if (!currentOrder) throw new Error('Order not found');

    // Validate status transition
    const allowedTransitions = ORDER_STATUS_FLOW[currentOrder.status as keyof typeof ORDER_STATUS_FLOW];
    if (!allowedTransitions.includes(update.newStatus)) {
      throw new Error(`Cannot transition from ${currentOrder.status} to ${update.newStatus}`);
    }

    // Prepare update data
    const updateData: any = {
      status: update.newStatus,
      updated_at: new Date().toISOString()
    };

    // Add status-specific fields
    switch (update.newStatus) {
      case 'confirmed':
        updateData.confirmed_at = new Date().toISOString();
        break;
      case 'processing':
        updateData.processing_at = new Date().toISOString();
        break;
      case 'shipped':
        updateData.shipped_at = new Date().toISOString();
        if (update.trackingNumber) {
          updateData.tracking_number = update.trackingNumber;
          updateData.carrier_name = update.carrierName || 'USPS';
        }
        if (update.estimatedDelivery) {
          updateData.estimated_delivery = update.estimatedDelivery;
        }
        break;
      case 'delivered':
        updateData.delivered_at = update.actualDelivery || new Date().toISOString();
        updateData.actual_delivery = update.actualDelivery || new Date().toISOString();
        break;
      case 'cancelled':
        updateData.cancelled_at = new Date().toISOString();
        updateData.cancellation_reason = update.notes;
        break;
    }

    // Update the order
    const { data: updatedOrder, error: updateError } = await supabase
      .from('orders')
      .update(updateData)
      .eq('id', update.orderId)
      .select()
      .single();

    if (updateError) throw updateError;

    // Add to status history
    await addOrderStatusHistory({
      order_id: update.orderId,
      status: update.newStatus,
      notes: update.notes || ORDER_STATUS_DESCRIPTIONS[update.newStatus as keyof typeof ORDER_STATUS_DESCRIPTIONS],
      metadata: {
        previous_status: currentOrder.status,
        tracking_number: update.trackingNumber,
        carrier: update.carrierName
      }
    });

    // Handle inventory adjustments
    if (update.newStatus === 'cancelled' || update.newStatus === 'refunded') {
      await restoreInventory(update.orderId);
    }

    // Send notification (if email service is configured)
    await sendOrderStatusNotification(update.orderId, update.newStatus);

    return updatedOrder;
  } catch (error) {
    console.error('Error updating order status:', error);
    throw error;
  }
}

/**
 * Add entry to order status history
 */
async function addOrderStatusHistory(entry: {
  order_id: string;
  status: string;
  notes?: string;
  metadata?: any;
}) {
  try {
    const { error } = await supabase
      .from('order_status_history')
      .insert({
        order_id: entry.order_id,
        status: entry.status,
        notes: entry.notes,
        metadata: entry.metadata,
        created_at: new Date().toISOString()
      });

    if (error) throw error;
  } catch (error) {
    console.error('Error adding status history:', error);
    // Don't throw - this is not critical
  }
}

/**
 * Update tracking information
 */
export async function updateTrackingInfo(
  orderId: string,
  trackingNumber: string,
  carrier: string,
  estimatedDelivery?: string
) {
  try {
    const { data, error } = await supabase
      .from('orders')
      .update({
        tracking_number: trackingNumber,
        carrier_name: carrier,
        estimated_delivery: estimatedDelivery,
        updated_at: new Date().toISOString()
      })
      .eq('id', orderId)
      .select()
      .single();

    if (error) throw error;

    // Add to history
    await addOrderStatusHistory({
      order_id: orderId,
      status: 'tracking_added',
      notes: `Tracking number ${trackingNumber} added (${carrier})`,
      metadata: { tracking_number: trackingNumber, carrier }
    });

    return data;
  } catch (error) {
    console.error('Error updating tracking info:', error);
    throw error;
  }
}

/**
 * Generate shipping label (placeholder - integrate with actual shipping API)
 */
export async function generateShippingLabel(params: ShippingLabel) {
  try {
    // This would integrate with shipping APIs like EasyPost, ShipStation, etc.
    // For now, we'll create a mock label record

    const { data: order } = await supabase
      .from('orders')
      .select('order_number, shipping_address, total_amount')
      .eq('id', params.orderId)
      .single();

    if (!order) throw new Error('Order not found');

    // Mock shipping label data
    const labelData = {
      order_id: params.orderId,
      carrier: params.carrier,
      service_type: params.serviceType,
      tracking_number: `MOCK-${Date.now()}`,
      label_url: `https://example.com/labels/${params.orderId}.pdf`,
      cost: calculateShippingCost(params.weight, params.serviceType),
      created_at: new Date().toISOString()
    };

    // Store label info
    const { data: label, error } = await supabase
      .from('shipping_labels')
      .insert(labelData)
      .select()
      .single();

    if (error) throw error;

    // Update order with tracking
    await updateTrackingInfo(
      params.orderId,
      labelData.tracking_number,
      params.carrier.toUpperCase()
    );

    return label;
  } catch (error) {
    console.error('Error generating shipping label:', error);
    throw error;
  }
}

/**
 * Calculate shipping cost (mock implementation)
 */
function calculateShippingCost(weight: number, serviceType: string): number {
  const rates = {
    standard: 5.99,
    express: 15.99,
    overnight: 29.99
  };
  
  const baseRate = rates[serviceType as keyof typeof rates] || rates.standard;
  const weightSurcharge = Math.max(0, (weight - 1) * 2); // $2 per pound over 1 lb
  
  return baseRate + weightSurcharge;
}

/**
 * Restore inventory for cancelled/refunded orders
 */
async function restoreInventory(orderId: string) {
  try {
    const { data: order } = await supabase
      .from('orders')
      .select('items')
      .eq('id', orderId)
      .single();

    if (!order || !order.items) return;

    const items = typeof order.items === 'string' ? JSON.parse(order.items) : order.items;

    for (const item of items) {
      if (item.variant_id) {
        // Get current inventory
        const { data: inventory } = await supabase
          .from('inventory')
          .select('available_quantity')
          .eq('variant_id', item.variant_id)
          .single();

        if (inventory) {
          // Restore the quantity
          await supabase
            .from('inventory')
            .update({
              available_quantity: inventory.available_quantity + item.quantity
            })
            .eq('variant_id', item.variant_id);
        }
      }
    }
  } catch (error) {
    console.error('Error restoring inventory:', error);
    // Don't throw - this is not critical
  }
}

/**
 * Send order status notification email
 */
async function sendOrderStatusNotification(orderId: string, newStatus: string) {
  try {
    // This would integrate with email service (Resend, SendGrid, etc.)
    // For now, just log
    console.log(`Email notification would be sent for order ${orderId}: ${newStatus}`);
    
    // In production, you would:
    // 1. Get order and customer details
    // 2. Generate email template based on status
    // 3. Send via email service
    
    return true;
  } catch (error) {
    console.error('Error sending notification:', error);
    return false;
  }
}

/**
 * Get order timeline/history
 */
export async function getOrderTimeline(orderId: string): Promise<OrderTimeline[]> {
  try {
    const { data, error } = await supabase
      .from('order_status_history')
      .select('*')
      .eq('order_id', orderId)
      .order('created_at', { ascending: false });

    if (error) throw error;

    return data || [];
  } catch (error) {
    console.error('Error fetching order timeline:', error);
    return [];
  }
}

/**
 * Bulk update order statuses
 */
export async function bulkUpdateOrderStatus(
  orderIds: string[],
  newStatus: string,
  notes?: string
) {
  const results = {
    successful: [] as string[],
    failed: [] as { orderId: string; error: string }[]
  };

  for (const orderId of orderIds) {
    try {
      await updateOrderStatus({
        orderId,
        newStatus,
        notes
      });
      results.successful.push(orderId);
    } catch (error: any) {
      results.failed.push({
        orderId,
        error: error.message || 'Unknown error'
      });
    }
  }

  return results;
}

/**
 * Get order statistics
 */
export async function getOrderStatistics(days: number = 30) {
  try {
    const startDate = new Date();
    startDate.setDate(startDate.getDate() - days);

    const { data: orders, error } = await supabase
      .from('orders')
      .select('status, total_amount, created_at')
      .gte('created_at', startDate.toISOString());

    if (error) throw error;

    // Calculate statistics
    const stats = {
      total: orders?.length || 0,
      pending: 0,
      confirmed: 0,
      processing: 0,
      shipped: 0,
      delivered: 0,
      cancelled: 0,
      totalRevenue: 0,
      averageOrderValue: 0
    };

    orders?.forEach(order => {
      stats[order.status as keyof typeof stats]++;
      stats.totalRevenue += order.total_amount / 100;
    });

    if (stats.total > 0) {
      stats.averageOrderValue = stats.totalRevenue / stats.total;
    }

    return stats;
  } catch (error) {
    console.error('Error fetching order statistics:', error);
    throw error;
  }
}

/**
 * Export orders to CSV
 */
export function exportOrdersToCSV(orders: any[]) {
  const headers = [
    'Order Number',
    'Customer',
    'Email',
    'Status',
    'Total',
    'Payment Status',
    'Created Date',
    'Shipped Date',
    'Tracking Number'
  ];

  const rows = orders.map(order => [
    order.order_number,
    `${order.customers?.first_name || ''} ${order.customers?.last_name || ''}`.trim() || 'Guest',
    order.customers?.email || order.guest_email || '',
    order.status,
    `$${(order.total_amount / 100).toFixed(2)}`,
    order.financial_status || order.payment_status || 'pending',
    new Date(order.created_at).toLocaleDateString(),
    order.shipped_at ? new Date(order.shipped_at).toLocaleDateString() : '',
    order.tracking_number || ''
  ]);

  const csvContent = [
    headers.join(','),
    ...rows.map(row => row.map(cell => `"${cell}"`).join(','))
  ].join('\n');

  const blob = new Blob([csvContent], { type: 'text/csv' });
  const url = URL.createObjectURL(blob);
  const a = document.createElement('a');
  a.href = url;
  a.download = `orders-${new Date().toISOString().split('T')[0]}.csv`;
  a.click();
  URL.revokeObjectURL(url);
}