import { supabase } from '../supabase-client';
import Stripe from 'stripe';

// Initialize Stripe (replace with your secret key)
const stripe = new Stripe(process.env.STRIPE_SECRET_KEY || '', {
  apiVersion: '2024-06-20',
});

export interface RefundRequest {
  id: string;
  orderId: string;
  customerId: string;
  amount: number;
  originalAmount: number;
  reason: string;
  status: 'pending' | 'approved' | 'rejected' | 'processed';
  requestDate: string;
  processedDate?: string;
  stripeRefundId?: string;
  notes?: string;
}

export interface TaxRate {
  id: string;
  jurisdiction: string;
  taxType: string;
  rate: number;
  appliesTo: string;
  effectiveDate: string;
  status: 'active' | 'inactive';
}

export interface PaymentTransaction {
  id: string;
  orderId: string;
  customerId: string;
  amount: number;
  currency: string;
  paymentMethod: string;
  processorTransactionId: string;
  status: 'pending' | 'completed' | 'failed' | 'refunded';
  fees: number;
  netAmount: number;
  createdAt: string;
}

export class FinancialService {
  // Refund Management
  static async getRefundRequests(status?: string): Promise<{ success: boolean; data: RefundRequest[]; error?: string }> {
    try {
      let query = supabase.from('refund_requests').select('*');
      
      if (status) {
        query = query.eq('status', status);
      }
      
      const { data, error } = await query.order('created_at', { ascending: false });

      if (error) {
        return { success: false, data: [], error: error.message };
      }

      return { success: true, data: data || [] };
    } catch (error) {
      return { success: false, data: [], error: 'Failed to fetch refund requests' };
    }
  }

  static async createRefundRequest(request: Omit<RefundRequest, 'id'>): Promise<{ success: boolean; data?: RefundRequest; error?: string }> {
    try {
      const { data, error } = await supabase
        .from('refund_requests')
        .insert([request])
        .select()
        .single();

      if (error) {
        return { success: false, error: error.message };
      }

      return { success: true, data };
    } catch (error) {
      return { success: false, error: 'Failed to create refund request' };
    }
  }

  static async processRefund(refundId: string, amount: number, reason: string): Promise<{ success: boolean; error?: string }> {
    try {
      // Get the refund request
      const { data: refundRequest, error: fetchError } = await supabase
        .from('refund_requests')
        .select('*')
        .eq('id', refundId)
        .single();

      if (fetchError || !refundRequest) {
        return { success: false, error: 'Refund request not found' };
      }

      // Get the original order to find the Stripe payment intent
      const { data: order, error: orderError } = await supabase
        .from('orders')
        .select('stripe_payment_intent_id')
        .eq('id', refundRequest.order_id)
        .single();

      if (orderError || !order?.stripe_payment_intent_id) {
        return { success: false, error: 'Original payment not found' };
      }

      // Process refund through Stripe
      const refund = await stripe.refunds.create({
        payment_intent: order.stripe_payment_intent_id,
        amount: Math.round(amount * 100), // Convert to cents
        reason: 'requested_by_customer',
        metadata: {
          refund_request_id: refundId,
          reason: reason
        }
      });

      // Update refund request status
      const { error: updateError } = await supabase
        .from('refund_requests')
        .update({
          status: 'processed',
          processed_date: new Date().toISOString(),
          stripe_refund_id: refund.id,
          amount: amount
        })
        .eq('id', refundId);

      if (updateError) {
        return { success: false, error: 'Failed to update refund status' };
      }

      // Log the transaction
      await this.logTransaction({
        orderId: refundRequest.order_id,
        customerId: refundRequest.customer_id,
        amount: -amount, // Negative for refund
        currency: 'USD',
        paymentMethod: 'stripe_refund',
        processorTransactionId: refund.id,
        status: 'completed',
        fees: 0,
        netAmount: -amount
      });

      return { success: true };
    } catch (error: any) {
      console.error('Refund processing error:', error);
      return { success: false, error: error.message || 'Failed to process refund' };
    }
  }

  // Tax Management
  static async getTaxRates(): Promise<{ success: boolean; data: TaxRate[]; error?: string }> {
    try {
      const { data, error } = await supabase
        .from('tax_rates')
        .select('*')
        .order('jurisdiction');

      if (error) {
        return { success: false, data: [], error: error.message };
      }

      return { success: true, data: data || [] };
    } catch (error) {
      return { success: false, data: [], error: 'Failed to fetch tax rates' };
    }
  }

  static async calculateTax(amount: number, jurisdiction: string): Promise<{ success: boolean; data?: { taxAmount: number; rate: number }; error?: string }> {
    try {
      const { data: taxRate, error } = await supabase
        .from('tax_rates')
        .select('rate')
        .eq('jurisdiction', jurisdiction)
        .eq('status', 'active')
        .single();

      if (error || !taxRate) {
        return { success: false, error: 'Tax rate not found for jurisdiction' };
      }

      const taxAmount = (amount * taxRate.rate) / 100;

      return {
        success: true,
        data: {
          taxAmount,
          rate: taxRate.rate
        }
      };
    } catch (error) {
      return { success: false, error: 'Failed to calculate tax' };
    }
  }

  static async saveTaxRate(taxRate: Omit<TaxRate, 'id'>): Promise<{ success: boolean; data?: TaxRate; error?: string }> {
    try {
      const { data, error } = await supabase
        .from('tax_rates')
        .insert([taxRate])
        .select()
        .single();

      if (error) {
        return { success: false, error: error.message };
      }

      return { success: true, data };
    } catch (error) {
      return { success: false, error: 'Failed to save tax rate' };
    }
  }

  // Transaction Management
  static async logTransaction(transaction: Omit<PaymentTransaction, 'id' | 'createdAt'>): Promise<{ success: boolean; error?: string }> {
    try {
      const { error } = await supabase
        .from('payment_transactions')
        .insert([{
          ...transaction,
          created_at: new Date().toISOString()
        }]);

      if (error) {
        return { success: false, error: error.message };
      }

      return { success: true };
    } catch (error) {
      return { success: false, error: 'Failed to log transaction' };
    }
  }

  static async getTransactions(limit = 50): Promise<{ success: boolean; data: PaymentTransaction[]; error?: string }> {
    try {
      const { data, error } = await supabase
        .from('payment_transactions')
        .select('*')
        .order('created_at', { ascending: false })
        .limit(limit);

      if (error) {
        return { success: false, data: [], error: error.message };
      }

      return { success: true, data: data || [] };
    } catch (error) {
      return { success: false, data: [], error: 'Failed to fetch transactions' };
    }
  }

  // Financial Reports
  static async getFinancialSummary(dateRange: { start: string; end: string }): Promise<{
    success: boolean;
    data?: {
      totalRevenue: number;
      totalTransactions: number;
      totalFees: number;
      totalRefunds: number;
      avgOrderValue: number;
    };
    error?: string;
  }> {
    try {
      const { data, error } = await supabase
        .rpc('get_financial_summary', {
          start_date: dateRange.start,
          end_date: dateRange.end
        });

      if (error) {
        return { success: false, error: error.message };
      }

      return { success: true, data: data || {} };
    } catch (error) {
      return { success: false, error: 'Failed to fetch financial summary' };
    }
  }

  // Daily Reconciliation
  static async getDailyReconciliation(date: string): Promise<{
    success: boolean;
    data?: {
      totalSales: number;
      totalRefunds: number;
      totalFees: number;
      netAmount: number;
      transactionCount: number;
      discrepancies: any[];
    };
    error?: string;
  }> {
    try {
      const { data, error } = await supabase
        .rpc('get_daily_reconciliation', { reconciliation_date: date });

      if (error) {
        return { success: false, error: error.message };
      }

      return { success: true, data: data || {} };
    } catch (error) {
      return { success: false, error: 'Failed to fetch daily reconciliation' };
    }
  }

  // Payment Method Configuration
  static async getPaymentMethods(): Promise<{ success: boolean; data: any[]; error?: string }> {
    try {
      const { data, error } = await supabase
        .from('payment_methods')
        .select('*')
        .eq('is_active', true);

      if (error) {
        return { success: false, data: [], error: error.message };
      }

      return { success: true, data: data || [] };
    } catch (error) {
      return { success: false, data: [], error: 'Failed to fetch payment methods' };
    }
  }

  static async updatePaymentMethodSettings(method: string, settings: any): Promise<{ success: boolean; error?: string }> {
    try {
      const { error } = await supabase
        .from('payment_methods')
        .update({ settings, updated_at: new Date().toISOString() })
        .eq('method_name', method);

      if (error) {
        return { success: false, error: error.message };
      }

      return { success: true };
    } catch (error) {
      return { success: false, error: 'Failed to update payment method settings' };
    }
  }
}