/**
 * REFUND SERVICE
 * Comprehensive refund processing and management
 * 
 * Features:
 * - Stripe refund processing
 * - Partial and full refunds
 * - Refund validation and authorization
 * - Inventory management integration
 * - Audit trail and compliance
 * - Dispute handling
 */

import { supabase } from '../supabase-client';

// Types
export interface RefundRequest {
  id: string;
  order_id: string;
  customer_id?: string;
  requested_by: 'customer' | 'admin' | 'system';
  requester_id?: string;
  type: 'full' | 'partial';
  amount?: number; // Required for partial refunds
  reason: 'duplicate' | 'fraudulent' | 'requested_by_customer' | 'defective' | 'not_received' | 'other';
  reason_details?: string;
  items?: Array<{
    product_id: string;
    variant_id?: string;
    quantity: number;
    unit_refund_amount: number;
  }>;
  status: 'pending' | 'approved' | 'processing' | 'completed' | 'failed' | 'cancelled';
  stripe_refund_id?: string;
  refund_amount: number;
  fees_refunded: number;
  created_at: string;
  processed_at?: string;
  approved_by?: string;
  metadata?: Record<string, any>;
}

export interface RefundPolicy {
  id: string;
  name: string;
  max_refund_days: number;
  allowed_reasons: string[];
  requires_approval: boolean;
  auto_approve_threshold?: number;
  restocking_fee_percentage?: number;
  shipping_refundable: boolean;
  partial_refunds_allowed: boolean;
  is_active: boolean;
}

export interface RefundStats {
  total_refunds: number;
  total_amount: number;
  refund_rate: number;
  avg_processing_time: number;
  by_reason: Array<{
    reason: string;
    count: number;
    amount: number;
  }>;
  by_status: Array<{
    status: string;
    count: number;
  }>;
}

class RefundService {
  /**
   * Create a refund request
   */
  async createRefundRequest(request: Omit<RefundRequest, 'id' | 'created_at' | 'status'>): Promise<RefundRequest> {
    try {
      // Validate the refund request
      await this.validateRefundRequest(request);

      // Check refund policy compliance
      const policy = await this.getApplicableRefundPolicy(request.order_id);
      if (!this.isRefundPolicyCompliant(request, policy)) {
        throw new Error('Refund request does not comply with refund policy');
      }

      // Calculate refund amounts
      const refundCalculation = await this.calculateRefundAmounts(request);

      const { data, error } = await supabase
        .from('refund_requests')
        .insert([{
          ...request,
          refund_amount: refundCalculation.refund_amount,
          fees_refunded: refundCalculation.fees_refunded,
          status: policy.requires_approval && 
                  refundCalculation.refund_amount > (policy.auto_approve_threshold || 0) 
                  ? 'pending' : 'approved'
        }])
        .select()
        .single();

      if (error) throw error;

      // Auto-process if approved and below threshold
      if (data.status === 'approved') {
        await this.processRefund(data.id);
      }

      return data;
    } catch (error) {
      console.error('Error creating refund request:', error);
      throw new Error(`Failed to create refund request: ${error.message}`);
    }
  }

  /**
   * Validate refund request
   */
  private async validateRefundRequest(request: any): Promise<void> {
    // Get order details
    const { data: order, error } = await supabase
      .from('orders')
      .select('*, items:order_items(*)')
      .eq('id', request.order_id)
      .single();

    if (error) throw new Error('Order not found');

    // Check if order is refundable
    if (order.status === 'cancelled' || order.status === 'refunded') {
      throw new Error('Order cannot be refunded');
    }

    // Check refund timing
    const orderDate = new Date(order.created_at);
    const daysSinceOrder = Math.floor((Date.now() - orderDate.getTime()) / (1000 * 60 * 60 * 24));
    
    const policy = await this.getApplicableRefundPolicy(request.order_id);
    if (daysSinceOrder > policy.max_refund_days) {
      throw new Error(`Refund period expired. Must request within ${policy.max_refund_days} days.`);
    }

    // Validate partial refund items
    if (request.type === 'partial' && request.items) {
      for (const item of request.items) {
        const orderItem = order.items.find((oi: any) => 
          oi.product_id === item.product_id && 
          (!item.variant_id || oi.variant_id === item.variant_id)
        );
        
        if (!orderItem) {
          throw new Error(`Item not found in order: ${item.product_id}`);
        }
        
        if (item.quantity > orderItem.quantity) {
          throw new Error(`Refund quantity exceeds ordered quantity for ${item.product_id}`);
        }
      }
    }

    // Check for existing refund requests
    const { data: existingRefunds } = await supabase
      .from('refund_requests')
      .select('*')
      .eq('order_id', request.order_id)
      .in('status', ['pending', 'approved', 'processing']);

    if (existingRefunds && existingRefunds.length > 0) {
      throw new Error('Refund request already exists for this order');
    }
  }

  /**
   * Calculate refund amounts including fees
   */
  private async calculateRefundAmounts(request: any): Promise<{
    refund_amount: number;
    fees_refunded: number;
    restocking_fee: number;
  }> {
    const { data: order, error } = await supabase
      .from('orders')
      .select('*, items:order_items(*)')
      .eq('id', request.order_id)
      .single();

    if (error) throw new Error('Order not found');

    let refundAmount = 0;
    let restockingFee = 0;

    const policy = await this.getApplicableRefundPolicy(request.order_id);

    if (request.type === 'full') {
      refundAmount = order.total;
      
      // Apply restocking fee if applicable
      if (policy.restocking_fee_percentage && policy.restocking_fee_percentage > 0) {
        restockingFee = (order.subtotal * policy.restocking_fee_percentage) / 100;
        refundAmount -= restockingFee;
      }

      // Subtract shipping if not refundable
      if (!policy.shipping_refundable && order.shipping_cost) {
        refundAmount -= order.shipping_cost;
      }
    } else {
      // Partial refund calculation
      for (const item of request.items || []) {
        refundAmount += item.quantity * item.unit_refund_amount;
      }

      // Apply proportional restocking fee
      if (policy.restocking_fee_percentage && policy.restocking_fee_percentage > 0) {
        restockingFee = (refundAmount * policy.restocking_fee_percentage) / 100;
        refundAmount -= restockingFee;
      }
    }

    // Calculate fees to refund (typically Stripe processing fees)
    const feesRefunded = Math.min(
      (refundAmount * 0.029) + 0.30, // Stripe fee structure
      order.processing_fees || 0
    );

    return {
      refund_amount: refundAmount,
      fees_refunded: feesRefunded,
      restocking_fee: restockingFee
    };
  }

  /**
   * Process approved refund
   */
  async processRefund(refundRequestId: string): Promise<RefundRequest> {
    try {
      const { data: refundRequest, error } = await supabase
        .from('refund_requests')
        .select('*')
        .eq('id', refundRequestId)
        .single();

      if (error) throw new Error('Refund request not found');

      if (refundRequest.status !== 'approved') {
        throw new Error('Refund request must be approved before processing');
      }

      // Update status to processing
      await supabase
        .from('refund_requests')
        .update({ status: 'processing' })
        .eq('id', refundRequestId);

      try {
        // Process refund via Edge Function for security
        const { data: refundResult, error: refundError } = await supabase.functions.invoke('process-refund', {
          body: {
            refund_request_id: refundRequestId,
            refund_amount: refundRequest.refund_amount
          }
        });

        if (refundError) throw refundError;

        // Update refund request with Stripe refund ID
        const { data: updatedRequest, error: updateError } = await supabase
          .from('refund_requests')
          .update({
            status: 'completed',
            stripe_refund_id: refundResult.stripe_refund_id,
            processed_at: new Date().toISOString()
          })
          .eq('id', refundRequestId)
          .select()
          .single();

        if (updateError) throw updateError;

        // Update order status if full refund
        if (refundRequest.type === 'full') {
          await supabase
            .from('orders')
            .update({ status: 'refunded' })
            .eq('id', refundRequest.order_id);
        }

        // Handle inventory restoration
        await this.restoreInventory(refundRequest);

        // Send refund notification
        await this.sendRefundNotification(updatedRequest);

        return updatedRequest;

      } catch (processingError) {
        // Mark refund as failed
        await supabase
          .from('refund_requests')
          .update({ 
            status: 'failed',
            metadata: { 
              error: processingError.message,
              failed_at: new Date().toISOString()
            }
          })
          .eq('id', refundRequestId);

        throw processingError;
      }

    } catch (error) {
      console.error('Error processing refund:', error);
      throw new Error(`Failed to process refund: ${error.message}`);
    }
  }

  /**
   * Approve refund request
   */
  async approveRefundRequest(refundRequestId: string, adminId: string, notes?: string): Promise<void> {
    try {
      const { error } = await supabase
        .from('refund_requests')
        .update({
          status: 'approved',
          approved_by: adminId,
          metadata: { 
            approval_notes: notes,
            approved_at: new Date().toISOString()
          }
        })
        .eq('id', refundRequestId)
        .eq('status', 'pending');

      if (error) throw error;

      // Auto-process approved refund
      await this.processRefund(refundRequestId);

    } catch (error) {
      console.error('Error approving refund request:', error);
      throw new Error('Failed to approve refund request');
    }
  }

  /**
   * Reject refund request
   */
  async rejectRefundRequest(refundRequestId: string, adminId: string, reason: string): Promise<void> {
    try {
      const { error } = await supabase
        .from('refund_requests')
        .update({
          status: 'cancelled',
          approved_by: adminId,
          metadata: { 
            rejection_reason: reason,
            rejected_at: new Date().toISOString()
          }
        })
        .eq('id', refundRequestId)
        .eq('status', 'pending');

      if (error) throw error;

      // Send rejection notification
      const { data: refundRequest } = await supabase
        .from('refund_requests')
        .select('*, orders(customer_id)')
        .eq('id', refundRequestId)
        .single();

      if (refundRequest) {
        await this.sendRefundRejectionNotification(refundRequest, reason);
      }

    } catch (error) {
      console.error('Error rejecting refund request:', error);
      throw new Error('Failed to reject refund request');
    }
  }

  /**
   * Get refund requests with filters
   */
  async getRefundRequests(filters: {
    status?: string;
    customer_id?: string;
    start_date?: string;
    end_date?: string;
    limit?: number;
    offset?: number;
  }): Promise<{ refunds: RefundRequest[]; total_count: number }> {
    try {
      let query = supabase
        .from('refund_requests')
        .select(`
          *,
          orders (
            order_number,
            customer_id,
            customers (
              first_name,
              last_name,
              email
            )
          )
        `, { count: 'exact' })
        .order('created_at', { ascending: false });

      if (filters.status) {
        query = query.eq('status', filters.status);
      }
      if (filters.customer_id) {
        query = query.eq('orders.customer_id', filters.customer_id);
      }
      if (filters.start_date) {
        query = query.gte('created_at', filters.start_date);
      }
      if (filters.end_date) {
        query = query.lte('created_at', filters.end_date);
      }
      if (filters.limit) {
        query = query.limit(filters.limit);
      }
      if (filters.offset) {
        query = query.range(filters.offset, (filters.offset || 0) + (filters.limit || 50) - 1);
      }

      const { data, error, count } = await query;

      if (error) throw error;

      return {
        refunds: data as RefundRequest[],
        total_count: count || 0
      };
    } catch (error) {
      console.error('Error getting refund requests:', error);
      throw new Error('Failed to retrieve refund requests');
    }
  }

  /**
   * Get refund statistics
   */
  async getRefundStats(startDate: string, endDate: string): Promise<RefundStats> {
    try {
      const { data, error } = await supabase.rpc('get_refund_statistics', {
        start_date: startDate,
        end_date: endDate
      });

      if (error) throw error;
      return data;
    } catch (error) {
      console.error('Error getting refund stats:', error);
      throw new Error('Failed to retrieve refund statistics');
    }
  }

  /**
   * Get applicable refund policy
   */
  private async getApplicableRefundPolicy(orderId: string): Promise<RefundPolicy> {
    try {
      // For now, return default policy - could be enhanced to support product-specific policies
      const { data, error } = await supabase
        .from('refund_policies')
        .select('*')
        .eq('is_active', true)
        .eq('name', 'default')
        .single();

      if (error) {
        // Return default fallback policy
        return {
          id: 'default',
          name: 'default',
          max_refund_days: 30,
          allowed_reasons: ['duplicate', 'fraudulent', 'requested_by_customer', 'defective', 'not_received', 'other'],
          requires_approval: true,
          auto_approve_threshold: 50.00,
          restocking_fee_percentage: 0,
          shipping_refundable: false,
          partial_refunds_allowed: true,
          is_active: true
        };
      }

      return data;
    } catch (error) {
      console.error('Error getting refund policy:', error);
      throw new Error('Failed to retrieve refund policy');
    }
  }

  /**
   * Check refund policy compliance
   */
  private isRefundPolicyCompliant(request: any, policy: RefundPolicy): boolean {
    // Check if reason is allowed
    if (!policy.allowed_reasons.includes(request.reason)) {
      return false;
    }

    // Check if partial refunds are allowed
    if (request.type === 'partial' && !policy.partial_refunds_allowed) {
      return false;
    }

    return true;
  }

  /**
   * Restore inventory for refunded items
   */
  private async restoreInventory(refundRequest: RefundRequest): Promise<void> {
    try {
      if (refundRequest.type === 'full') {
        // Restore all items from the order
        const { data: orderItems, error } = await supabase
          .from('order_items')
          .select('*')
          .eq('order_id', refundRequest.order_id);

        if (error) throw error;

        for (const item of orderItems || []) {
          await supabase.rpc('restore_inventory', {
            product_id: item.product_id,
            variant_id: item.variant_id,
            quantity: item.quantity
          });
        }
      } else if (refundRequest.items) {
        // Restore specific items
        for (const item of refundRequest.items) {
          await supabase.rpc('restore_inventory', {
            product_id: item.product_id,
            variant_id: item.variant_id,
            quantity: item.quantity
          });
        }
      }
    } catch (error) {
      console.error('Error restoring inventory:', error);
      // Don't fail the refund for inventory issues
    }
  }

  /**
   * Send refund notification
   */
  private async sendRefundNotification(refundRequest: RefundRequest): Promise<void> {
    try {
      await supabase.functions.invoke('send-refund-notification', {
        body: {
          refund_request_id: refundRequest.id,
          type: 'completed'
        }
      });
    } catch (error) {
      console.error('Error sending refund notification:', error);
      // Don't fail the refund for notification issues
    }
  }

  /**
   * Send refund rejection notification
   */
  private async sendRefundRejectionNotification(refundRequest: any, reason: string): Promise<void> {
    try {
      await supabase.functions.invoke('send-refund-notification', {
        body: {
          refund_request_id: refundRequest.id,
          type: 'rejected',
          rejection_reason: reason
        }
      });
    } catch (error) {
      console.error('Error sending rejection notification:', error);
    }
  }

  /**
   * Check for refund abuse patterns
   */
  async checkRefundAbusePatterns(customerId?: string, email?: string): Promise<{
    is_suspicious: boolean;
    patterns: Array<{
      type: 'high_frequency' | 'high_value' | 'same_items' | 'rapid_succession';
      description: string;
      risk_level: 'low' | 'medium' | 'high';
    }>;
  }> {
    try {
      const { data, error } = await supabase.rpc('check_refund_abuse_patterns', {
        customer_id: customerId,
        email: email
      });

      if (error) throw error;
      return data;
    } catch (error) {
      console.error('Error checking refund abuse patterns:', error);
      return { is_suspicious: false, patterns: [] };
    }
  }
}

// Export singleton instance
export const refundService = new RefundService();
export default refundService;