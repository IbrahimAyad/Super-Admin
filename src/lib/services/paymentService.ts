/**
 * PAYMENT SERVICE
 * Comprehensive payment processing and validation
 * 
 * Features:
 * - Payment method validation
 * - Multi-provider support (Stripe, PayPal)
 * - Payment intent management
 * - Fraud detection integration
 * - PCI compliance helpers
 * - Payment analytics
 */

import { supabase } from '../supabase-client';

// Types
export interface PaymentMethod {
  id: string;
  customer_id?: string;
  type: 'card' | 'bank_account' | 'digital_wallet' | 'buy_now_pay_later';
  provider: 'stripe' | 'paypal' | 'apple_pay' | 'google_pay' | 'afterpay' | 'klarna';
  provider_payment_method_id: string;
  is_default: boolean;
  metadata: {
    last4?: string;
    brand?: string;
    exp_month?: number;
    exp_year?: number;
    country?: string;
    fingerprint?: string;
  };
  status: 'active' | 'inactive' | 'requires_action';
  created_at: string;
  updated_at: string;
}

export interface PaymentIntent {
  id: string;
  order_id?: string;
  customer_id?: string;
  amount: number;
  currency: string;
  status: 'requires_payment_method' | 'requires_confirmation' | 'requires_action' | 'processing' | 'succeeded' | 'requires_capture' | 'canceled';
  payment_method_id?: string;
  provider: 'stripe' | 'paypal';
  provider_intent_id: string;
  client_secret?: string;
  next_action?: any;
  last_payment_error?: any;
  metadata?: Record<string, any>;
  created_at: string;
  updated_at: string;
}

export interface FraudCheck {
  id: string;
  payment_intent_id: string;
  risk_score: number;
  risk_level: 'low' | 'medium' | 'high' | 'critical';
  checks: {
    cvc_check?: 'pass' | 'fail' | 'unavailable';
    address_line1_check?: 'pass' | 'fail' | 'unavailable';
    address_postal_code_check?: 'pass' | 'fail' | 'unavailable';
    velocity_check?: 'pass' | 'fail';
    ip_geolocation_check?: 'pass' | 'fail';
    device_fingerprint_check?: 'pass' | 'fail';
  };
  recommendations: Array<{
    action: 'allow' | 'review' | 'block';
    reason: string;
    confidence: number;
  }>;
  provider_data?: any;
  created_at: string;
}

export interface PaymentAnalytics {
  total_volume: number;
  total_transactions: number;
  success_rate: number;
  average_amount: number;
  by_method: Array<{
    type: string;
    volume: number;
    count: number;
    success_rate: number;
  }>;
  by_country: Array<{
    country: string;
    volume: number;
    count: number;
  }>;
  fraud_metrics: {
    total_flagged: number;
    false_positive_rate: number;
    blocked_amount: number;
  };
  trends: Array<{
    date: string;
    volume: number;
    count: number;
    success_rate: number;
  }>;
}

class PaymentService {
  /**
   * Create payment intent
   */
  async createPaymentIntent(params: {
    amount: number;
    currency: string;
    customer_id?: string;
    order_id?: string;
    payment_method_types?: string[];
    metadata?: Record<string, any>;
    automatic_payment_methods?: boolean;
  }): Promise<PaymentIntent> {
    try {
      // Validate amount and currency
      this.validatePaymentAmount(params.amount, params.currency);

      // Create via Edge Function for security
      const { data, error } = await supabase.functions.invoke('create-payment-intent', {
        body: {
          amount: Math.round(params.amount * 100), // Convert to cents
          currency: params.currency.toLowerCase(),
          customer_id: params.customer_id,
          order_id: params.order_id,
          payment_method_types: params.payment_method_types || ['card'],
          automatic_payment_methods: params.automatic_payment_methods || true,
          metadata: params.metadata || {}
        }
      });

      if (error) throw error;

      // Store payment intent in database
      const { data: paymentIntent, error: dbError } = await supabase
        .from('payment_intents')
        .insert([{
          order_id: params.order_id,
          customer_id: params.customer_id,
          amount: params.amount,
          currency: params.currency,
          status: data.status,
          provider: 'stripe',
          provider_intent_id: data.id,
          client_secret: data.client_secret,
          metadata: params.metadata
        }])
        .select()
        .single();

      if (dbError) throw dbError;

      return paymentIntent;

    } catch (error) {
      console.error('Error creating payment intent:', error);
      throw new Error(`Failed to create payment intent: ${error.message}`);
    }
  }

  /**
   * Confirm payment intent
   */
  async confirmPaymentIntent(paymentIntentId: string, paymentMethodId?: string): Promise<PaymentIntent> {
    try {
      const { data: paymentIntent, error } = await supabase
        .from('payment_intents')
        .select('*')
        .eq('id', paymentIntentId)
        .single();

      if (error) throw error;

      // Perform fraud check before confirmation
      const fraudCheck = await this.performFraudCheck(paymentIntent);
      
      if (fraudCheck.risk_level === 'critical') {
        throw new Error('Payment blocked due to high fraud risk');
      }

      // Confirm via Edge Function
      const { data: confirmResult, error: confirmError } = await supabase.functions.invoke('confirm-payment-intent', {
        body: {
          provider_intent_id: paymentIntent.provider_intent_id,
          payment_method_id: paymentMethodId
        }
      });

      if (confirmError) throw confirmError;

      // Update payment intent status
      const { data: updatedIntent, error: updateError } = await supabase
        .from('payment_intents')
        .update({
          status: confirmResult.status,
          payment_method_id: paymentMethodId,
          next_action: confirmResult.next_action,
          last_payment_error: confirmResult.last_payment_error,
          updated_at: new Date().toISOString()
        })
        .eq('id', paymentIntentId)
        .select()
        .single();

      if (updateError) throw updateError;

      return updatedIntent;

    } catch (error) {
      console.error('Error confirming payment intent:', error);
      throw new Error(`Failed to confirm payment: ${error.message}`);
    }
  }

  /**
   * Save payment method for future use
   */
  async savePaymentMethod(params: {
    customer_id: string;
    provider_payment_method_id: string;
    type: string;
    provider: string;
    metadata?: any;
    is_default?: boolean;
  }): Promise<PaymentMethod> {
    try {
      // If setting as default, unset other defaults
      if (params.is_default) {
        await supabase
          .from('payment_methods')
          .update({ is_default: false })
          .eq('customer_id', params.customer_id);
      }

      const { data, error } = await supabase
        .from('payment_methods')
        .insert([{
          customer_id: params.customer_id,
          type: params.type,
          provider: params.provider,
          provider_payment_method_id: params.provider_payment_method_id,
          metadata: params.metadata || {},
          is_default: params.is_default || false,
          status: 'active'
        }])
        .select()
        .single();

      if (error) throw error;
      return data;

    } catch (error) {
      console.error('Error saving payment method:', error);
      throw new Error('Failed to save payment method');
    }
  }

  /**
   * Get customer payment methods
   */
  async getCustomerPaymentMethods(customerId: string): Promise<PaymentMethod[]> {
    try {
      const { data, error } = await supabase
        .from('payment_methods')
        .select('*')
        .eq('customer_id', customerId)
        .eq('status', 'active')
        .order('is_default', { ascending: false })
        .order('created_at', { ascending: false });

      if (error) throw error;
      return data;

    } catch (error) {
      console.error('Error getting payment methods:', error);
      throw new Error('Failed to retrieve payment methods');
    }
  }

  /**
   * Delete payment method
   */
  async deletePaymentMethod(paymentMethodId: string, customerId: string): Promise<void> {
    try {
      // Detach from provider first
      const { data: paymentMethod, error } = await supabase
        .from('payment_methods')
        .select('*')
        .eq('id', paymentMethodId)
        .eq('customer_id', customerId)
        .single();

      if (error) throw error;

      // Detach via Edge Function
      await supabase.functions.invoke('detach-payment-method', {
        body: {
          provider_payment_method_id: paymentMethod.provider_payment_method_id,
          provider: paymentMethod.provider
        }
      });

      // Mark as inactive in database
      await supabase
        .from('payment_methods')
        .update({ status: 'inactive' })
        .eq('id', paymentMethodId);

    } catch (error) {
      console.error('Error deleting payment method:', error);
      throw new Error('Failed to delete payment method');
    }
  }

  /**
   * Validate payment method
   */
  async validatePaymentMethod(params: {
    provider_payment_method_id: string;
    provider: string;
    amount: number;
    currency: string;
  }): Promise<{
    is_valid: boolean;
    checks: {
      card_valid: boolean;
      funds_sufficient: boolean;
      not_expired: boolean;
      cvc_valid: boolean;
    };
    risk_score?: number;
  }> {
    try {
      const { data, error } = await supabase.functions.invoke('validate-payment-method', {
        body: params
      });

      if (error) throw error;
      return data;

    } catch (error) {
      console.error('Error validating payment method:', error);
      return {
        is_valid: false,
        checks: {
          card_valid: false,
          funds_sufficient: false,
          not_expired: false,
          cvc_valid: false
        }
      };
    }
  }

  /**
   * Perform fraud check
   */
  async performFraudCheck(paymentIntent: PaymentIntent): Promise<FraudCheck> {
    try {
      const { data, error } = await supabase.functions.invoke('fraud-check', {
        body: {
          payment_intent_id: paymentIntent.id,
          provider_intent_id: paymentIntent.provider_intent_id,
          amount: paymentIntent.amount,
          currency: paymentIntent.currency,
          customer_id: paymentIntent.customer_id
        }
      });

      if (error) throw error;

      // Store fraud check results
      const { data: fraudCheck, error: dbError } = await supabase
        .from('fraud_checks')
        .insert([{
          payment_intent_id: paymentIntent.id,
          risk_score: data.risk_score,
          risk_level: data.risk_level,
          checks: data.checks,
          recommendations: data.recommendations,
          provider_data: data.provider_data
        }])
        .select()
        .single();

      if (dbError) throw dbError;
      return fraudCheck;

    } catch (error) {
      console.error('Error performing fraud check:', error);
      // Return safe defaults
      return {
        id: '',
        payment_intent_id: paymentIntent.id,
        risk_score: 50,
        risk_level: 'medium',
        checks: {},
        recommendations: [{
          action: 'review',
          reason: 'Fraud check failed',
          confidence: 0.5
        }],
        created_at: new Date().toISOString()
      };
    }
  }

  /**
   * Capture authorized payment
   */
  async capturePayment(paymentIntentId: string, amountToCapture?: number): Promise<PaymentIntent> {
    try {
      const { data: paymentIntent, error } = await supabase
        .from('payment_intents')
        .select('*')
        .eq('id', paymentIntentId)
        .single();

      if (error) throw error;

      if (paymentIntent.status !== 'requires_capture') {
        throw new Error('Payment intent is not in capturable state');
      }

      // Capture via Edge Function
      const { data: captureResult, error: captureError } = await supabase.functions.invoke('capture-payment', {
        body: {
          provider_intent_id: paymentIntent.provider_intent_id,
          amount_to_capture: amountToCapture ? Math.round(amountToCapture * 100) : undefined
        }
      });

      if (captureError) throw captureError;

      // Update payment intent
      const { data: updatedIntent, error: updateError } = await supabase
        .from('payment_intents')
        .update({
          status: captureResult.status,
          updated_at: new Date().toISOString()
        })
        .eq('id', paymentIntentId)
        .select()
        .single();

      if (updateError) throw updateError;
      return updatedIntent;

    } catch (error) {
      console.error('Error capturing payment:', error);
      throw new Error(`Failed to capture payment: ${error.message}`);
    }
  }

  /**
   * Cancel payment intent
   */
  async cancelPaymentIntent(paymentIntentId: string, reason?: string): Promise<PaymentIntent> {
    try {
      const { data: paymentIntent, error } = await supabase
        .from('payment_intents')
        .select('*')
        .eq('id', paymentIntentId)
        .single();

      if (error) throw error;

      // Cancel via Edge Function
      const { data: cancelResult, error: cancelError } = await supabase.functions.invoke('cancel-payment-intent', {
        body: {
          provider_intent_id: paymentIntent.provider_intent_id,
          cancellation_reason: reason
        }
      });

      if (cancelError) throw cancelError;

      // Update payment intent
      const { data: updatedIntent, error: updateError } = await supabase
        .from('payment_intents')
        .update({
          status: 'canceled',
          metadata: { 
            ...paymentIntent.metadata,
            cancellation_reason: reason,
            canceled_at: new Date().toISOString()
          },
          updated_at: new Date().toISOString()
        })
        .eq('id', paymentIntentId)
        .select()
        .single();

      if (updateError) throw updateError;
      return updatedIntent;

    } catch (error) {
      console.error('Error canceling payment intent:', error);
      throw new Error('Failed to cancel payment intent');
    }
  }

  /**
   * Get payment analytics
   */
  async getPaymentAnalytics(params: {
    start_date: string;
    end_date: string;
    currency?: string;
    customer_id?: string;
  }): Promise<PaymentAnalytics> {
    try {
      const { data, error } = await supabase.rpc('get_payment_analytics', {
        start_date: params.start_date,
        end_date: params.end_date,
        currency_filter: params.currency,
        customer_filter: params.customer_id
      });

      if (error) throw error;
      return data;

    } catch (error) {
      console.error('Error getting payment analytics:', error);
      throw new Error('Failed to retrieve payment analytics');
    }
  }

  /**
   * Get failed payments for retry
   */
  async getFailedPayments(limit: number = 50): Promise<Array<PaymentIntent & { retry_count: number; next_retry_at: string }>> {
    try {
      const { data, error } = await supabase
        .from('payment_intents')
        .select(`
          *,
          payment_retries!inner(retry_count, next_retry_at)
        `)
        .eq('status', 'requires_action')
        .not('last_payment_error', 'is', null)
        .lte('payment_retries.next_retry_at', new Date().toISOString())
        .limit(limit);

      if (error) throw error;
      return data;

    } catch (error) {
      console.error('Error getting failed payments:', error);
      throw new Error('Failed to retrieve failed payments');
    }
  }

  /**
   * Retry failed payment
   */
  async retryFailedPayment(paymentIntentId: string): Promise<PaymentIntent> {
    try {
      const { data: paymentIntent, error } = await supabase
        .from('payment_intents')
        .select('*')
        .eq('id', paymentIntentId)
        .single();

      if (error) throw error;

      // Check retry limits
      const { data: retryInfo, error: retryError } = await supabase
        .from('payment_retries')
        .select('*')
        .eq('payment_intent_id', paymentIntentId)
        .single();

      if (retryError && retryError.code !== 'PGRST116') throw retryError;

      if (retryInfo && retryInfo.retry_count >= 3) {
        throw new Error('Maximum retry attempts exceeded');
      }

      // Retry via Edge Function
      const { data: retryResult, error: retryFunctionError } = await supabase.functions.invoke('retry-payment', {
        body: {
          provider_intent_id: paymentIntent.provider_intent_id
        }
      });

      if (retryFunctionError) throw retryFunctionError;

      // Update retry count
      await supabase
        .from('payment_retries')
        .upsert([{
          payment_intent_id: paymentIntentId,
          retry_count: (retryInfo?.retry_count || 0) + 1,
          last_retry_at: new Date().toISOString(),
          next_retry_at: new Date(Date.now() + 60 * 60 * 1000).toISOString() // 1 hour later
        }], { onConflict: 'payment_intent_id' });

      // Update payment intent
      const { data: updatedIntent, error: updateError } = await supabase
        .from('payment_intents')
        .update({
          status: retryResult.status,
          last_payment_error: retryResult.last_payment_error,
          updated_at: new Date().toISOString()
        })
        .eq('id', paymentIntentId)
        .select()
        .single();

      if (updateError) throw updateError;
      return updatedIntent;

    } catch (error) {
      console.error('Error retrying payment:', error);
      throw new Error(`Failed to retry payment: ${error.message}`);
    }
  }

  /**
   * Check PCI compliance status
   */
  async checkPCICompliance(): Promise<{
    is_compliant: boolean;
    last_assessment: string;
    certificate_expires: string;
    issues: Array<{
      severity: 'low' | 'medium' | 'high';
      description: string;
      remediation: string;
    }>;
  }> {
    try {
      const { data, error } = await supabase
        .from('system_settings')
        .select('value')
        .eq('key', 'pci_compliance_status')
        .single();

      if (error) throw error;
      return JSON.parse(data.value);

    } catch (error) {
      console.error('Error checking PCI compliance:', error);
      return {
        is_compliant: false,
        last_assessment: '',
        certificate_expires: '',
        issues: [{
          severity: 'high',
          description: 'Unable to verify PCI compliance status',
          remediation: 'Contact system administrator'
        }]
      };
    }
  }

  /**
   * Generate payment reconciliation report
   */
  async generateReconciliationReport(date: string): Promise<{
    total_processed: number;
    total_fees: number;
    successful_payments: number;
    failed_payments: number;
    disputed_payments: number;
    reconciled: boolean;
    discrepancies: Array<{
      type: string;
      description: string;
      amount: number;
    }>;
  }> {
    try {
      const { data, error } = await supabase.rpc('generate_payment_reconciliation_report', {
        report_date: date
      });

      if (error) throw error;
      return data;

    } catch (error) {
      console.error('Error generating reconciliation report:', error);
      throw new Error('Failed to generate reconciliation report');
    }
  }

  // Private helper methods

  private validatePaymentAmount(amount: number, currency: string): void {
    if (amount <= 0) {
      throw new Error('Payment amount must be greater than zero');
    }

    // Currency-specific minimums
    const minimums: Record<string, number> = {
      usd: 0.50,
      eur: 0.50,
      gbp: 0.30,
      cad: 0.50,
      aud: 0.50
    };

    const minimum = minimums[currency.toLowerCase()] || 1.00;
    if (amount < minimum) {
      throw new Error(`Minimum payment amount is ${minimum} ${currency.toUpperCase()}`);
    }

    // Maximum limits for security
    const maximum = 99999.99;
    if (amount > maximum) {
      throw new Error(`Maximum payment amount is ${maximum} ${currency.toUpperCase()}`);
    }
  }

  /**
   * Setup webhook endpoints for payment providers
   */
  async setupWebhooks(): Promise<{
    stripe_webhook_url: string;
    paypal_webhook_url: string;
  }> {
    try {
      const baseUrl = await this.getBaseUrl();
      
      return {
        stripe_webhook_url: `${baseUrl}/functions/v1/stripe-webhook-secure`,
        paypal_webhook_url: `${baseUrl}/functions/v1/paypal-webhook-secure`
      };

    } catch (error) {
      console.error('Error setting up webhooks:', error);
      throw new Error('Failed to setup webhooks');
    }
  }

  private async getBaseUrl(): Promise<string> {
    const { data, error } = await supabase
      .from('system_settings')
      .select('value')
      .eq('key', 'base_url')
      .single();

    if (error) throw error;
    return data.value;
  }
}

// Export singleton instance
export const paymentService = new PaymentService();
export default paymentService;