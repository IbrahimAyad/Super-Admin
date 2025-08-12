/**
 * ORDER SERVICE
 * Comprehensive order management, fulfillment, and tracking service
 * For KCT Menswear Super Admin system
 */

import { supabase } from '@/lib/supabase-client';
import { getClientForOperation } from '@/lib/supabase-client';

// ============================================
// TYPES AND INTERFACES
// ============================================

export interface Order {
  id: string;
  order_number: string;
  customer_id?: string;
  guest_email?: string;
  status: OrderStatus;
  fulfillment_status?: FulfillmentStatus;
  total_amount: number;
  subtotal: number;
  tax_amount: number;
  shipping_amount: number;
  discount_amount?: number;
  
  // Addresses
  shipping_address?: any;
  billing_address?: any;
  
  // Tracking
  tracking_number?: string;
  carrier_name?: string;
  shipped_at?: string;
  delivered_at?: string;
  estimated_delivery?: string;
  
  // Metadata
  priority?: Priority;
  source_channel?: string;
  notes?: string;
  
  // Relations
  customer?: any;
  items?: OrderItem[];
  
  // Timestamps
  created_at: string;
  updated_at: string;
}

export interface OrderItem {
  id: string;
  order_id: string;
  product_id: string;
  variant_id?: string;
  product_name: string;
  variant_name?: string;
  quantity: number;
  price: number;
  total_price: number;
  
  // Fulfillment
  fulfillment_status?: string;
  
  // Relations
  product?: any;
  variant?: any;
}

export interface OrderFulfillment {
  id: string;
  order_id: string;
  status: FulfillmentStatus;
  tracking_number?: string;
  carrier?: Carrier;
  tracking_url?: string;
  
  // Fulfillment details
  warehouse_location?: string;
  assigned_picker?: string;
  assigned_packer?: string;
  
  // Timestamps
  processing_started_at?: string;
  shipped_at?: string;
  estimated_delivery_date?: string;
  actual_delivery_date?: string;
  
  // Cost
  shipping_cost?: number;
  shipping_method?: string;
  
  // Notes
  internal_notes?: string;
}

export interface OrderNote {
  id: string;
  order_id: string;
  note_type: 'internal' | 'customer_service' | 'fulfillment' | 'shipping' | 'accounting';
  content: string;
  is_customer_visible: boolean;
  is_urgent: boolean;
  created_by: string;
  created_at: string;
}

export interface OrderRefund {
  id: string;
  order_id: string;
  refund_type: 'full_refund' | 'partial_refund' | 'return' | 'exchange' | 'store_credit';
  reason: string;
  reason_category: string;
  original_amount: number;
  refund_amount: number;
  status: 'requested' | 'approved' | 'processing' | 'completed' | 'failed' | 'cancelled';
  refund_method?: string;
  stripe_refund_id?: string;
}

// ============================================
// ENUMS AND CONSTANTS
// ============================================

export type OrderStatus = 
  | 'pending' 
  | 'confirmed' 
  | 'processing' 
  | 'shipped' 
  | 'delivered' 
  | 'cancelled' 
  | 'refunded';

export type FulfillmentStatus = 
  | 'pending' 
  | 'processing' 
  | 'shipped' 
  | 'delivered' 
  | 'cancelled';

export type Priority = 'low' | 'normal' | 'high' | 'urgent';

export type Carrier = 'usps' | 'ups' | 'fedex' | 'dhl' | 'other';

export type NotificationType = 
  | 'order_confirmation' 
  | 'order_processing' 
  | 'order_shipped' 
  | 'order_delivered' 
  | 'order_cancelled' 
  | 'order_delayed' 
  | 'custom';

// Order Status Flow
export const ORDER_STATUS_FLOW: Record<OrderStatus, OrderStatus[]> = {
  pending: ['confirmed', 'cancelled'],
  confirmed: ['processing', 'cancelled'],
  processing: ['shipped', 'cancelled'],
  shipped: ['delivered'],
  delivered: [],
  cancelled: [],
  refunded: []
};

// Order Status Descriptions
export const ORDER_STATUS_DESCRIPTIONS: Record<OrderStatus, string> = {
  pending: 'Order received, awaiting confirmation',
  confirmed: 'Order confirmed, ready for processing',
  processing: 'Order being prepared for shipment',
  shipped: 'Order shipped, tracking available',
  delivered: 'Order delivered to customer',
  cancelled: 'Order cancelled',
  refunded: 'Order refunded'
};

export const FULFILLMENT_STATUS_DESCRIPTIONS: Record<FulfillmentStatus, string> = {
  pending: 'Awaiting fulfillment processing',
  processing: 'Being picked and packed',
  shipped: 'Package shipped to customer',
  delivered: 'Package delivered',
  cancelled: 'Fulfillment cancelled'
};

export const CARRIER_NAMES: Record<Carrier, string> = {
  usps: 'USPS',
  ups: 'UPS',
  fedex: 'FedEx',
  dhl: 'DHL',
  other: 'Other'
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

// ============================================
// ADVANCED ORDER MANAGEMENT FUNCTIONS
// ============================================

/**
 * Get orders with advanced filtering and pagination
 */
export async function getOrders(options: {
  page?: number;
  limit?: number;
  status?: OrderStatus;
  fulfillmentStatus?: FulfillmentStatus;
  priority?: Priority;
  assignedTo?: string;
  dateFrom?: string;
  dateTo?: string;
  searchTerm?: string;
} = {}) {
  const {
    page = 1,
    limit = 50,
    status,
    fulfillmentStatus,
    priority,
    assignedTo,
    dateFrom,
    dateTo,
    searchTerm
  } = options;

  const offset = (page - 1) * limit;

  try {
    let query = supabase
      .from('orders')
      .select(`
        *,
        customers!left(
          id,
          first_name,
          last_name,
          email,
          phone
        ),
        order_items!left(
          id,
          product_name,
          variant_name,
          quantity,
          price,
          total_price
        ),
        order_fulfillment!left(
          id,
          status,
          tracking_number,
          carrier,
          estimated_delivery_date
        )
      `)
      .order('created_at', { ascending: false })
      .range(offset, offset + limit - 1);

    // Apply filters
    if (status) {
      query = query.eq('status', status);
    }

    if (fulfillmentStatus) {
      query = query.eq('fulfillment_status', fulfillmentStatus);
    }

    if (priority) {
      query = query.eq('priority', priority);
    }

    if (assignedTo) {
      query = query.eq('assigned_to', assignedTo);
    }

    if (dateFrom) {
      query = query.gte('created_at', dateFrom);
    }

    if (dateTo) {
      query = query.lte('created_at', dateTo);
    }

    if (searchTerm) {
      query = query.or(`
        order_number.ilike.%${searchTerm}%,
        guest_email.ilike.%${searchTerm}%
      `);
    }

    const { data, error, count } = await query;

    if (error) throw error;

    return {
      orders: data || [],
      totalCount: count || 0,
      totalPages: Math.ceil((count || 0) / limit),
      currentPage: page
    };
  } catch (error) {
    console.error('Error fetching orders:', error);
    throw error;
  }
}

// ============================================
// FULFILLMENT MANAGEMENT
// ============================================

/**
 * Create fulfillment record for order
 */
export async function createOrderFulfillment(params: {
  orderId: string;
  warehouseLocation?: string;
  assignedPicker?: string;
  assignedPacker?: string;
  notes?: string;
}) {
  const { orderId, warehouseLocation, assignedPicker, assignedPacker, notes } = params;

  try {
    const { data, error } = await supabase
      .from('order_fulfillment')
      .insert({
        order_id: orderId,
        status: 'pending',
        warehouse_location: warehouseLocation,
        assigned_picker: assignedPicker,
        assigned_packer: assignedPacker,
        internal_notes: notes,
        created_at: new Date().toISOString()
      })
      .select()
      .single();

    if (error) throw error;

    await createOrderEvent({
      orderId,
      eventType: 'fulfillment',
      title: 'Fulfillment record created',
      description: 'Order entered fulfillment pipeline',
      metadata: {
        fulfillmentId: data.id,
        warehouseLocation,
        assignedPicker,
        assignedPacker
      }
    });

    return data;
  } catch (error) {
    console.error('Error creating fulfillment record:', error);
    throw error;
  }
}

/**
 * Update fulfillment status
 */
export async function updateFulfillmentStatus(params: {
  fulfillmentId: string;
  status: FulfillmentStatus;
  trackingNumber?: string;
  carrier?: Carrier;
  estimatedDelivery?: string;
  shippingCost?: number;
  notes?: string;
}) {
  const { fulfillmentId, status, trackingNumber, carrier, estimatedDelivery, shippingCost, notes } = params;

  try {
    const updateData: any = {
      status,
      updated_at: new Date().toISOString()
    };

    if (status === 'processing') {
      updateData.processing_started_at = new Date().toISOString();
    }

    if (status === 'shipped') {
      updateData.shipped_at = new Date().toISOString();
      if (trackingNumber) updateData.tracking_number = trackingNumber;
      if (carrier) updateData.carrier = carrier;
      if (estimatedDelivery) updateData.estimated_delivery_date = estimatedDelivery;
      if (shippingCost) updateData.shipping_cost = shippingCost;
    }

    if (status === 'delivered') {
      updateData.actual_delivery_date = new Date().toISOString();
    }

    if (notes) {
      updateData.internal_notes = notes;
    }

    const { error } = await supabase
      .from('order_fulfillment')
      .update(updateData)
      .eq('id', fulfillmentId);

    if (error) throw error;

    return { success: true };
  } catch (error) {
    console.error('Error updating fulfillment status:', error);
    throw error;
  }
}

// ============================================
// TRACKING MANAGEMENT ENHANCED
// ============================================

/**
 * Generate tracking URL based on carrier
 */
function generateTrackingUrl(carrier: string, trackingNumber: string): string {
  const trackingUrls: Record<string, string> = {
    usps: `https://tools.usps.com/go/TrackConfirmAction?tLabels=${trackingNumber}`,
    ups: `https://www.ups.com/track?loc=en_US&tracknum=${trackingNumber}`,
    fedex: `https://www.fedex.com/fedextrack/?trknbr=${trackingNumber}`,
    dhl: `https://www.dhl.com/us-en/home/tracking/tracking-express.html?submit=1&tracking-id=${trackingNumber}`
  };

  return trackingUrls[carrier] || '';
}

// ============================================
// SHIPPING LABEL MANAGEMENT ENHANCED
// ============================================

/**
 * Enhanced shipping label generation
 */
export async function generateShippingLabelEnhanced(params: {
  orderId: string;
  carrier: Carrier;
  serviceType: string;
  weight: number;
  dimensions: {
    length: number;
    width: number;
    height: number;
  };
  insuranceAmount?: number;
}) {
  const { orderId, carrier, serviceType, weight, dimensions, insuranceAmount } = params;

  try {
    // Get order details for addresses
    const order = await getOrderDetails(orderId);

    // Mock label generation (replace with actual carrier API integration)
    const mockLabelData = {
      label_url: `https://example.com/labels/${Date.now()}.pdf`,
      tracking_number: generateMockTrackingNumber(carrier),
      shipping_cost: calculateShippingCostEnhanced(carrier, serviceType, weight),
      insurance_cost: insuranceAmount ? insuranceAmount * 0.01 : 0 // 1% of insured value
    };

    // Store label in database
    const { data: label, error } = await supabase
      .from('shipping_labels')
      .insert({
        order_id: orderId,
        label_url: mockLabelData.label_url,
        tracking_number: mockLabelData.tracking_number,
        carrier,
        service_type: serviceType,
        weight_lbs: weight,
        length_inches: dimensions.length,
        width_inches: dimensions.width,
        height_inches: dimensions.height,
        shipping_cost: mockLabelData.shipping_cost,
        insurance_cost: mockLabelData.insurance_cost,
        from_address: getCompanyAddress(),
        to_address: order.shipping_address,
        status: 'generated'
      })
      .select()
      .single();

    if (error) throw error;

    // Update order with tracking information
    await updateTrackingInfo(
      orderId,
      mockLabelData.tracking_number,
      carrier,
      calculateEstimatedDelivery(serviceType)
    );

    // Create event
    await createOrderEvent({
      orderId,
      eventType: 'shipping',
      title: 'Shipping label generated',
      description: `${CARRIER_NAMES[carrier]} ${serviceType} label generated`,
      metadata: {
        labelId: label.id,
        trackingNumber: mockLabelData.tracking_number,
        carrier,
        serviceType,
        shippingCost: mockLabelData.shipping_cost
      }
    });

    return label;
  } catch (error) {
    console.error('Error generating shipping label:', error);
    throw error;
  }
}

// Helper functions for shipping
function generateMockTrackingNumber(carrier: Carrier): string {
  const prefixes: Record<Carrier, string> = {
    usps: '9400',
    ups: '1Z',
    fedex: '7712',
    dhl: '5678',
    other: '0000'
  };

  const prefix = prefixes[carrier];
  const randomNumber = Math.random().toString().substring(2, 12);
  return `${prefix}${randomNumber}`;
}

function calculateShippingCostEnhanced(carrier: Carrier, serviceType: string, weight: number): number {
  // Enhanced shipping cost calculation
  const baseCosts: Record<Carrier, number> = {
    usps: 8.50,
    ups: 12.00,
    fedex: 15.00,
    dhl: 18.00,
    other: 10.00
  };

  const serviceMultipliers: Record<string, number> = {
    standard: 1.0,
    express: 1.5,
    overnight: 2.5
  };

  const baseCost = baseCosts[carrier];
  const serviceMultiplier = serviceMultipliers[serviceType] || 1.0;
  const weightMultiplier = Math.max(1, Math.ceil(weight));

  return Math.round((baseCost * serviceMultiplier * weightMultiplier) * 100) / 100;
}

function calculateEstimatedDelivery(serviceType: string): string {
  const daysToAdd: Record<string, number> = {
    standard: 5,
    express: 2,
    overnight: 1
  };

  const days = daysToAdd[serviceType] || 5;
  const deliveryDate = new Date();
  deliveryDate.setDate(deliveryDate.getDate() + days);
  
  return deliveryDate.toISOString().split('T')[0];
}

function getCompanyAddress() {
  return {
    name: 'KCT Menswear',
    line1: '123 Business St',
    line2: 'Suite 100',
    city: 'Business City',
    state: 'BC',
    postal_code: '12345',
    country: 'US',
    phone: '555-123-4567'
  };
}

// ============================================
// NOTIFICATIONS MANAGEMENT
// ============================================

/**
 * Create order notification
 */
export async function createOrderNotification(params: {
  orderId: string;
  notificationType: NotificationType;
  deliveryMethod: 'email' | 'sms' | 'push';
  recipientEmail?: string;
  recipientPhone?: string;
  templateData?: any;
}) {
  const { orderId, notificationType, deliveryMethod, recipientEmail, recipientPhone, templateData } = params;

  try {
    const { data, error } = await supabase
      .from('order_notifications')
      .insert({
        order_id: orderId,
        notification_type: notificationType,
        delivery_method: deliveryMethod,
        recipient_email: recipientEmail,
        recipient_phone: recipientPhone,
        template_id: `${notificationType}_template`,
        template_data: templateData || {},
        status: 'pending'
      })
      .select()
      .single();

    if (error) throw error;

    // TODO: Integrate with actual email/SMS service
    console.log('Notification created:', data);

    return data;
  } catch (error) {
    console.error('Error creating notification:', error);
    throw error;
  }
}

// ============================================
// NOTES MANAGEMENT
// ============================================

/**
 * Add note to order
 */
export async function addOrderNote(params: {
  orderId: string;
  noteType: 'internal' | 'customer_service' | 'fulfillment' | 'shipping' | 'accounting';
  content: string;
  isCustomerVisible?: boolean;
  isUrgent?: boolean;
}) {
  const { orderId, noteType, content, isCustomerVisible = false, isUrgent = false } = params;

  try {
    const { data, error } = await supabase
      .from('order_notes')
      .insert({
        order_id: orderId,
        note_type: noteType,
        content,
        is_customer_visible: isCustomerVisible,
        is_urgent: isUrgent
      })
      .select()
      .single();

    if (error) throw error;

    await createOrderEvent({
      orderId,
      eventType: 'internal_note',
      title: `${noteType} note added`,
      description: isUrgent ? 'Urgent note added' : 'Note added',
      metadata: {
        noteId: data.id,
        noteType,
        isUrgent,
        isCustomerVisible
      }
    });

    return data;
  } catch (error) {
    console.error('Error adding order note:', error);
    throw error;
  }
}

/**
 * Get order notes
 */
export async function getOrderNotes(orderId: string) {
  try {
    const { data, error } = await supabase
      .from('order_notes')
      .select(`
        *,
        created_by_profile:admin_users!left(
          user_id,
          first_name,
          last_name
        )
      `)
      .eq('order_id', orderId)
      .order('created_at', { ascending: false });

    if (error) throw error;
    return data || [];
  } catch (error) {
    console.error('Error fetching order notes:', error);
    throw error;
  }
}

// ============================================
// REFUNDS AND RETURNS
// ============================================

/**
 * Create refund request
 */
export async function createRefund(params: {
  orderId: string;
  refundType: 'full_refund' | 'partial_refund' | 'return' | 'exchange' | 'store_credit';
  reason: string;
  reasonCategory: string;
  refundAmount: number;
  refundMethod?: string;
  customerNotes?: string;
  internalNotes?: string;
}) {
  const { orderId, refundType, reason, reasonCategory, refundAmount, refundMethod, customerNotes, internalNotes } = params;

  try {
    // Get original order amount
    const { data: order, error: orderError } = await supabase
      .from('orders')
      .select('total_amount')
      .eq('id', orderId)
      .single();

    if (orderError) throw orderError;

    const { data, error } = await supabase
      .from('order_refunds')
      .insert({
        order_id: orderId,
        refund_type: refundType,
        reason,
        reason_category: reasonCategory,
        original_amount: order.total_amount,
        refund_amount: refundAmount,
        refund_method: refundMethod,
        customer_notes: customerNotes,
        internal_notes: internalNotes,
        status: 'requested'
      })
      .select()
      .single();

    if (error) throw error;

    await createOrderEvent({
      orderId,
      eventType: 'payment',
      title: `${refundType} requested`,
      description: `Refund of $${(refundAmount / 100).toFixed(2)} requested`,
      metadata: {
        refundId: data.id,
        refundType,
        refundAmount,
        reason
      }
    });

    return data;
  } catch (error) {
    console.error('Error creating refund:', error);
    throw error;
  }
}

// ============================================
// UTILITY FUNCTIONS
// ============================================

/**
 * Create order event
 */
async function createOrderEvent(params: {
  orderId: string;
  eventType: string;
  title: string;
  description: string;
  metadata?: any;
}) {
  const { orderId, eventType, title, description, metadata } = params;

  try {
    const { error } = await supabase
      .from('order_events')
      .insert({
        order_id: orderId,
        event_type: eventType,
        event_category: 'workflow',
        title,
        description,
        metadata: metadata || {},
        is_automated: false,
        is_customer_visible: ['shipping', 'payment'].includes(eventType)
      });

    if (error) throw error;
  } catch (error) {
    console.error('Error creating order event:', error);
    // Don't throw here to avoid breaking the main operation
  }
}

/**
 * Export orders to CSV with enhanced fields
 */
export function exportOrdersToCSV(orders: any[]) {
  try {
    const csvHeaders = [
      'Order Number',
      'Customer Name',
      'Customer Email',
      'Status',
      'Fulfillment Status',
      'Priority',
      'Total Amount',
      'Payment Status',
      'Created Date',
      'Shipped Date',
      'Tracking Number',
      'Carrier',
      'Notes'
    ];

    const csvRows = orders.map(order => [
      order.order_number,
      order.customers ? `${order.customers.first_name} ${order.customers.last_name}` : 'Guest',
      order.customers?.email || order.guest_email || '',
      order.status,
      order.fulfillment_status || 'pending',
      order.priority || 'normal',
      `$${(order.total_amount / 100).toFixed(2)}`,
      order.financial_status || order.payment_status || 'pending',
      new Date(order.created_at).toLocaleDateString(),
      order.shipped_at ? new Date(order.shipped_at).toLocaleDateString() : '',
      order.tracking_number || '',
      order.carrier_name || '',
      order.notes || ''
    ]);

    const csvContent = [csvHeaders, ...csvRows]
      .map(row => row.map(field => `"${field}"`).join(','))
      .join('\n');

    // Create and download file
    const blob = new Blob([csvContent], { type: 'text/csv;charset=utf-8;' });
    const link = document.createElement('a');
    const url = URL.createObjectURL(blob);
    link.setAttribute('href', url);
    link.setAttribute('download', `orders_export_${new Date().toISOString().split('T')[0]}.csv`);
    link.style.visibility = 'hidden';
    document.body.appendChild(link);
    link.click();
    document.body.removeChild(link);

    return { success: true };
  } catch (error) {
    console.error('Error exporting orders:', error);
    throw error;
  }
}