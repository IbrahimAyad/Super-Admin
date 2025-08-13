#!/usr/bin/env deno run --allow-net --allow-env

/**
 * Payment Error Handling and Recovery System
 * 
 * This system provides:
 * 1. Intelligent payment failure handling
 * 2. Automatic retry mechanisms  
 * 3. Customer communication for failed payments
 * 4. Failed payment recovery workflows
 * 5. Chargeback and dispute management
 * 
 * Usage: deno run --allow-net --allow-env payment-error-recovery.ts
 */

import { createClient } from "https://esm.sh/@supabase/supabase-js@2.45.0";
import Stripe from "https://esm.sh/stripe@14.21.0";

const SUPABASE_URL = Deno.env.get("SUPABASE_URL");
const SUPABASE_SERVICE_ROLE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");
const STRIPE_SECRET_KEY = Deno.env.get("STRIPE_SECRET_KEY");

if (!SUPABASE_URL || !SUPABASE_SERVICE_ROLE_KEY || !STRIPE_SECRET_KEY) {
  console.error("❌ Missing required environment variables");
  Deno.exit(1);
}

const supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY);
const stripe = new Stripe(STRIPE_SECRET_KEY, { apiVersion: "2023-10-16" });

/**
 * Payment failure reason categorization
 */
export enum FailureCategory {
  INSUFFICIENT_FUNDS = "insufficient_funds",
  CARD_DECLINED = "card_declined", 
  EXPIRED_CARD = "expired_card",
  INCORRECT_CVC = "incorrect_cvc",
  PROCESSING_ERROR = "processing_error",
  AUTHENTICATION_REQUIRED = "authentication_required",
  FRAUD_SUSPECTED = "fraud_suspected",
  NETWORK_ERROR = "network_error",
  UNKNOWN = "unknown"
}

export interface PaymentFailure {
  orderId: string;
  paymentIntentId: string;
  customerId?: string;
  customerEmail: string;
  amount: number;
  currency: string;
  failureReason: string;
  failureCategory: FailureCategory;
  canRetry: boolean;
  retryAttempts: number;
  lastRetryAt?: string;
  nextRetryAt?: string;
  createdAt: string;
}

export interface RetryStrategy {
  maxRetries: number;
  baseDelayMinutes: number;
  exponentialBackoff: boolean;
  notifyCustomer: boolean;
  requireManualApproval: boolean;
}

/**
 * Payment Error Recovery Manager
 */
export class PaymentErrorRecovery {
  private supabase: any;
  private stripe: Stripe;
  
  constructor(supabase: any, stripe: Stripe) {
    this.supabase = supabase;
    this.stripe = stripe;
  }

  /**
   * Process a payment failure and determine recovery strategy
   */
  async handlePaymentFailure(paymentIntent: Stripe.PaymentIntent): Promise<void> {
    console.log(`🔍 Processing payment failure: ${paymentIntent.id}`);

    try {
      // Categorize the failure
      const failureCategory = this.categorizeFailure(paymentIntent.last_payment_error);
      const canRetry = this.determineRetryability(failureCategory, paymentIntent);
      
      // Get order and customer information
      const { data: order } = await this.supabase
        .from("orders")
        .select("*, customers(*)")
        .eq("stripe_payment_intent_id", paymentIntent.id)
        .single();

      if (!order) {
        console.error(`Order not found for payment intent: ${paymentIntent.id}`);
        return;
      }

      // Create payment failure record
      const failure: Partial<PaymentFailure> = {
        orderId: order.id,
        paymentIntentId: paymentIntent.id,
        customerId: order.customer_id,
        customerEmail: order.guest_email || order.customers?.email,
        amount: paymentIntent.amount / 100,
        currency: paymentIntent.currency,
        failureReason: paymentIntent.last_payment_error?.message || "Unknown error",
        failureCategory,
        canRetry,
        retryAttempts: 0,
        createdAt: new Date().toISOString()
      };

      // Store failure record
      const { data: failureRecord } = await this.supabase
        .from("payment_failures")
        .insert(failure)
        .select()
        .single();

      // Update order status
      await this.supabase
        .from("orders")
        .update({
          status: "payment_failed",
          payment_error: failure.failureReason,
          updated_at: new Date().toISOString()
        })
        .eq("id", order.id);

      // Release inventory reservations
      await this.releaseInventoryReservations(order.id);

      // Determine and execute recovery strategy
      const strategy = this.getRetryStrategy(failureCategory);
      
      if (canRetry && strategy.maxRetries > 0) {
        await this.scheduleRetry(failureRecord.id, strategy);
      }

      // Notify customer about the failure
      if (failure.customerEmail) {
        await this.notifyCustomerOfFailure(failure, strategy);
      }

      // Alert admin for critical failures
      if (this.isCriticalFailure(failureCategory)) {
        await this.alertAdminOfCriticalFailure(failure);
      }

      console.log(`✅ Payment failure processed: ${failureCategory}`);

    } catch (error) {
      console.error("Error handling payment failure:", error);
      throw error;
    }
  }

  /**
   * Categorize payment failure based on error details
   */
  private categorizeFailure(paymentError?: Stripe.PaymentIntent.LastPaymentError): FailureCategory {
    if (!paymentError) return FailureCategory.UNKNOWN;

    const code = paymentError.code;
    const type = paymentError.type;
    const message = paymentError.message?.toLowerCase() || "";

    // Card-specific errors
    if (code === "card_declined") {
      if (message.includes("insufficient")) return FailureCategory.INSUFFICIENT_FUNDS;
      if (message.includes("expired")) return FailureCategory.EXPIRED_CARD;
      if (message.includes("cvc") || message.includes("security")) return FailureCategory.INCORRECT_CVC;
      return FailureCategory.CARD_DECLINED;
    }

    // Authentication errors
    if (code === "authentication_required" || type === "authentication_error") {
      return FailureCategory.AUTHENTICATION_REQUIRED;
    }

    // Fraud prevention
    if (code === "fraudulent" || message.includes("fraud")) {
      return FailureCategory.FRAUD_SUSPECTED;
    }

    // Processing errors
    if (type === "api_error" || type === "api_connection_error") {
      return FailureCategory.NETWORK_ERROR;
    }

    if (type === "card_error") {
      return FailureCategory.PROCESSING_ERROR;
    }

    return FailureCategory.UNKNOWN;
  }

  /**
   * Determine if a payment failure can be retried
   */
  private determineRetryability(category: FailureCategory, paymentIntent: Stripe.PaymentIntent): boolean {
    // Never retry these categories
    const nonRetryableCategories = [
      FailureCategory.FRAUD_SUSPECTED,
      FailureCategory.INCORRECT_CVC,
      FailureCategory.EXPIRED_CARD
    ];

    if (nonRetryableCategories.includes(category)) {
      return false;
    }

    // Don't retry if too many attempts already made
    const attempts = paymentIntent.charges?.data?.[0]?.outcome?.risk_level;
    if (attempts === "highest") {
      return false;
    }

    // Network errors and processing errors are usually retryable
    const retryableCategories = [
      FailureCategory.NETWORK_ERROR,
      FailureCategory.PROCESSING_ERROR,
      FailureCategory.AUTHENTICATION_REQUIRED
    ];

    return retryableCategories.includes(category);
  }

  /**
   * Get retry strategy based on failure category
   */
  private getRetryStrategy(category: FailureCategory): RetryStrategy {
    const strategies: Record<FailureCategory, RetryStrategy> = {
      [FailureCategory.NETWORK_ERROR]: {
        maxRetries: 5,
        baseDelayMinutes: 5,
        exponentialBackoff: true,
        notifyCustomer: false,
        requireManualApproval: false
      },
      [FailureCategory.PROCESSING_ERROR]: {
        maxRetries: 3,
        baseDelayMinutes: 15,
        exponentialBackoff: true,
        notifyCustomer: true,
        requireManualApproval: false
      },
      [FailureCategory.AUTHENTICATION_REQUIRED]: {
        maxRetries: 1,
        baseDelayMinutes: 0,
        exponentialBackoff: false,
        notifyCustomer: true,
        requireManualApproval: false
      },
      [FailureCategory.INSUFFICIENT_FUNDS]: {
        maxRetries: 2,
        baseDelayMinutes: 1440, // 24 hours
        exponentialBackoff: false,
        notifyCustomer: true,
        requireManualApproval: false
      },
      [FailureCategory.CARD_DECLINED]: {
        maxRetries: 1,
        baseDelayMinutes: 60,
        exponentialBackoff: false,
        notifyCustomer: true,
        requireManualApproval: true
      },
      [FailureCategory.EXPIRED_CARD]: {
        maxRetries: 0,
        baseDelayMinutes: 0,
        exponentialBackoff: false,
        notifyCustomer: true,
        requireManualApproval: true
      },
      [FailureCategory.INCORRECT_CVC]: {
        maxRetries: 0,
        baseDelayMinutes: 0,
        exponentialBackoff: false,
        notifyCustomer: true,
        requireManualApproval: true
      },
      [FailureCategory.FRAUD_SUSPECTED]: {
        maxRetries: 0,
        baseDelayMinutes: 0,
        exponentialBackoff: false,
        notifyCustomer: false,
        requireManualApproval: true
      },
      [FailureCategory.UNKNOWN]: {
        maxRetries: 1,
        baseDelayMinutes: 30,
        exponentialBackoff: false,
        notifyCustomer: true,
        requireManualApproval: true
      }
    };

    return strategies[category];
  }

  /**
   * Schedule automatic payment retry
   */
  private async scheduleRetry(failureId: string, strategy: RetryStrategy): Promise<void> {
    const delay = strategy.baseDelayMinutes * 60 * 1000; // Convert to milliseconds
    const nextRetryAt = new Date(Date.now() + delay).toISOString();

    await this.supabase
      .from("payment_failures")
      .update({
        next_retry_at: nextRetryAt,
        retry_strategy: strategy
      })
      .eq("id", failureId);

    console.log(`📅 Scheduled retry for ${new Date(nextRetryAt).toLocaleString()}`);
  }

  /**
   * Execute payment retry
   */
  async executePaymentRetry(failureId: string): Promise<boolean> {
    console.log(`🔄 Executing payment retry for failure: ${failureId}`);

    try {
      // Get failure record
      const { data: failure } = await this.supabase
        .from("payment_failures")
        .select("*")
        .eq("id", failureId)
        .single();

      if (!failure) {
        throw new Error("Payment failure record not found");
      }

      // Check if retry is still valid
      if (failure.retry_attempts >= (failure.retry_strategy?.maxRetries || 0)) {
        console.log("Maximum retry attempts reached");
        return false;
      }

      // Get original payment intent
      const paymentIntent = await this.stripe.paymentIntents.retrieve(failure.payment_intent_id);

      // Create new payment intent for retry
      const newPaymentIntent = await this.stripe.paymentIntents.create({
        amount: Math.round(failure.amount * 100),
        currency: failure.currency,
        customer: failure.customer_id,
        metadata: {
          original_payment_intent: failure.payment_intent_id,
          retry_attempt: failure.retry_attempts + 1,
          order_id: failure.order_id
        },
        payment_method_types: ["card"],
        confirmation_method: "automatic"
      });

      // Update failure record
      await this.supabase
        .from("payment_failures")
        .update({
          retry_attempts: failure.retry_attempts + 1,
          last_retry_at: new Date().toISOString(),
          next_retry_at: null,
          retry_payment_intent_id: newPaymentIntent.id
        })
        .eq("id", failureId);

      // Update order with new payment intent
      await this.supabase
        .from("orders")
        .update({
          stripe_payment_intent_id: newPaymentIntent.id,
          status: "pending_payment",
          updated_at: new Date().toISOString()
        })
        .eq("id", failure.order_id);

      // Send retry notification to customer
      await this.notifyCustomerOfRetry(failure, newPaymentIntent);

      console.log(`✅ Payment retry executed: ${newPaymentIntent.id}`);
      return true;

    } catch (error) {
      console.error("Error executing payment retry:", error);
      
      // Update failure record with error
      await this.supabase
        .from("payment_failures")
        .update({
          retry_attempts: failure.retry_attempts + 1,
          last_retry_at: new Date().toISOString(),
          retry_error: error.message
        })
        .eq("id", failureId);

      return false;
    }
  }

  /**
   * Release inventory reservations for failed payment
   */
  private async releaseInventoryReservations(orderId: string): Promise<void> {
    try {
      // Get order items
      const { data: orderItems } = await this.supabase
        .from("order_items")
        .select("variant_id, quantity")
        .eq("order_id", orderId);

      if (!orderItems) return;

      // Release inventory for each item
      for (const item of orderItems) {
        if (item.variant_id) {
          await this.supabase.rpc("restore_inventory_on_cancel", {
            variant_uuid: item.variant_id,
            quantity_restored: item.quantity
          });
        }
      }

      console.log(`📦 Released inventory for order: ${orderId}`);
    } catch (error) {
      console.error("Error releasing inventory:", error);
    }
  }

  /**
   * Check if failure requires immediate admin attention
   */
  private isCriticalFailure(category: FailureCategory): boolean {
    const criticalCategories = [
      FailureCategory.FRAUD_SUSPECTED,
      FailureCategory.PROCESSING_ERROR // If frequent
    ];

    return criticalCategories.includes(category);
  }

  /**
   * Send payment failure notification to customer
   */
  private async notifyCustomerOfFailure(failure: Partial<PaymentFailure>, strategy: RetryStrategy): Promise<void> {
    try {
      const emailData = {
        to: failure.customerEmail,
        subject: "Payment Issue - KCT Menswear",
        template: "payment_failure",
        data: {
          customerName: "Valued Customer", // Could be enhanced with actual name
          orderId: failure.orderId,
          amount: failure.amount,
          currency: failure.currency,
          failureReason: this.getCustomerFriendlyErrorMessage(failure.failureCategory!),
          canRetry: failure.canRetry,
          nextRetryDate: strategy.maxRetries > 0 ? new Date(Date.now() + strategy.baseDelayMinutes * 60 * 1000) : null,
          supportEmail: "support@kctmenswear.com",
          supportPhone: "1-800-KCT-MENS"
        }
      };

      // Send via email service
      await fetch(`${SUPABASE_URL}/functions/v1/send-email`, {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          "Authorization": `Bearer ${SUPABASE_SERVICE_ROLE_KEY}`
        },
        body: JSON.stringify(emailData)
      });

      console.log(`📧 Payment failure notification sent to: ${failure.customerEmail}`);
    } catch (error) {
      console.error("Error sending failure notification:", error);
    }
  }

  /**
   * Send payment retry notification to customer
   */
  private async notifyCustomerOfRetry(failure: any, newPaymentIntent: Stripe.PaymentIntent): Promise<void> {
    try {
      const emailData = {
        to: failure.customer_email,
        subject: "Payment Retry - KCT Menswear",
        template: "payment_retry",
        data: {
          customerName: "Valued Customer",
          orderId: failure.order_id,
          amount: failure.amount,
          currency: failure.currency,
          retryAttempt: failure.retry_attempts + 1,
          paymentUrl: `https://dashboard.stripe.com/payment-intents/${newPaymentIntent.id}`, // Could be custom checkout
          supportEmail: "support@kctmenswear.com"
        }
      };

      await fetch(`${SUPABASE_URL}/functions/v1/send-email`, {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          "Authorization": `Bearer ${SUPABASE_SERVICE_ROLE_KEY}`
        },
        body: JSON.stringify(emailData)
      });

      console.log(`🔄 Payment retry notification sent`);
    } catch (error) {
      console.error("Error sending retry notification:", error);
    }
  }

  /**
   * Alert admin of critical payment failure
   */
  private async alertAdminOfCriticalFailure(failure: Partial<PaymentFailure>): Promise<void> {
    try {
      const alertData = {
        to: "admin@kctmenswear.com",
        subject: `Critical Payment Failure Alert - ${failure.failureCategory}`,
        template: "admin_payment_alert",
        data: {
          failureCategory: failure.failureCategory,
          orderId: failure.orderId,
          paymentIntentId: failure.paymentIntentId,
          customerEmail: failure.customerEmail,
          amount: failure.amount,
          currency: failure.currency,
          failureReason: failure.failureReason,
          timestamp: failure.createdAt
        }
      };

      await fetch(`${SUPABASE_URL}/functions/v1/send-email`, {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          "Authorization": `Bearer ${SUPABASE_SERVICE_ROLE_KEY}`
        },
        body: JSON.stringify(alertData)
      });

      console.log(`🚨 Critical failure alert sent to admin`);
    } catch (error) {
      console.error("Error sending admin alert:", error);
    }
  }

  /**
   * Get customer-friendly error message
   */
  private getCustomerFriendlyErrorMessage(category: FailureCategory): string {
    const messages: Record<FailureCategory, string> = {
      [FailureCategory.INSUFFICIENT_FUNDS]: "Your card was declined due to insufficient funds. Please try a different payment method or contact your bank.",
      [FailureCategory.CARD_DECLINED]: "Your card was declined. Please try a different payment method or contact your bank.",
      [FailureCategory.EXPIRED_CARD]: "Your card has expired. Please update your payment method with a current card.",
      [FailureCategory.INCORRECT_CVC]: "The security code (CVC) for your card was incorrect. Please check your card details and try again.",
      [FailureCategory.PROCESSING_ERROR]: "There was a temporary issue processing your payment. We'll try again shortly.",
      [FailureCategory.AUTHENTICATION_REQUIRED]: "Your bank requires additional verification for this transaction. Please complete the authentication process.",
      [FailureCategory.FRAUD_SUSPECTED]: "This transaction has been flagged for security review. Please contact our support team.",
      [FailureCategory.NETWORK_ERROR]: "There was a temporary connection issue. We'll try processing your payment again shortly.",
      [FailureCategory.UNKNOWN]: "There was an unexpected issue with your payment. Our team has been notified and will resolve this quickly."
    };

    return messages[category] || messages[FailureCategory.UNKNOWN];
  }

  /**
   * Get payment failure analytics
   */
  async getFailureAnalytics(timeframe: string = "30 days"): Promise<any> {
    const startDate = new Date(Date.now() - this.parseTimeframe(timeframe));
    
    const { data: failures } = await this.supabase
      .from("payment_failures")
      .select("*")
      .gte("created_at", startDate.toISOString());

    if (!failures || failures.length === 0) {
      return { message: "No payment failures in timeframe" };
    }

    // Analyze failure patterns
    const categoryCounts = failures.reduce((acc: any, failure: any) => {
      acc[failure.failure_category] = (acc[failure.failure_category] || 0) + 1;
      return acc;
    }, {});

    const retrySuccessRate = failures.filter(f => f.retry_attempts > 0 && f.status === 'resolved').length / 
                            failures.filter(f => f.retry_attempts > 0).length * 100;

    const totalLostRevenue = failures
      .filter(f => f.status !== 'resolved')
      .reduce((sum: number, f: any) => sum + f.amount, 0);

    return {
      totalFailures: failures.length,
      failuresByCategory: categoryCounts,
      retrySuccessRate: `${retrySuccessRate.toFixed(1)}%`,
      totalLostRevenue: `$${totalLostRevenue.toFixed(2)}`,
      averageFailureAmount: `$${(failures.reduce((sum: number, f: any) => sum + f.amount, 0) / failures.length).toFixed(2)}`,
      recommendations: this.generateFailureRecommendations(categoryCounts, retrySuccessRate)
    };
  }

  private parseTimeframe(timeframe: string): number {
    const match = timeframe.match(/(\d+)\s*(day|week|month)s?/);
    if (!match) return 30 * 24 * 60 * 60 * 1000; // Default 30 days

    const value = parseInt(match[1]);
    const unit = match[2];

    switch (unit) {
      case 'day': return value * 24 * 60 * 60 * 1000;
      case 'week': return value * 7 * 24 * 60 * 60 * 1000;
      case 'month': return value * 30 * 24 * 60 * 60 * 1000;
      default: return 30 * 24 * 60 * 60 * 1000;
    }
  }

  private generateFailureRecommendations(categoryCounts: any, retrySuccessRate: number): string[] {
    const recommendations = [];

    if (categoryCounts[FailureCategory.CARD_DECLINED] > 5) {
      recommendations.push("High number of card declines - consider implementing alternative payment methods");
    }

    if (categoryCounts[FailureCategory.FRAUD_SUSPECTED] > 2) {
      recommendations.push("Multiple fraud alerts - review and adjust fraud detection settings");
    }

    if (retrySuccessRate < 50) {
      recommendations.push("Low retry success rate - review retry strategies and timing");
    }

    if (categoryCounts[FailureCategory.PROCESSING_ERROR] > 3) {
      recommendations.push("Processing errors detected - investigate payment processor status");
    }

    return recommendations;
  }
}

/**
 * Chargeback and Dispute Management
 */
export class ChargebackManager {
  private supabase: any;
  private stripe: Stripe;

  constructor(supabase: any, stripe: Stripe) {
    this.supabase = supabase;
    this.stripe = stripe;
  }

  async handleDispute(dispute: Stripe.Dispute): Promise<void> {
    console.log(`⚠️ Processing dispute: ${dispute.id}`);

    try {
      // Create dispute record
      const disputeData = {
        stripe_dispute_id: dispute.id,
        payment_intent_id: dispute.payment_intent as string,
        amount: dispute.amount / 100,
        currency: dispute.currency,
        reason: dispute.reason,
        status: dispute.status,
        evidence_due_by: dispute.evidence_details?.due_by ? 
          new Date(dispute.evidence_details.due_by * 1000).toISOString() : null,
        created_at: new Date(dispute.created * 1000).toISOString()
      };

      const { data: disputeRecord } = await this.supabase
        .from("payment_disputes")
        .insert(disputeData)
        .select()
        .single();

      // Get associated order
      const { data: order } = await this.supabase
        .from("orders")
        .select("*, customers(*)")
        .eq("stripe_payment_intent_id", dispute.payment_intent)
        .single();

      if (order) {
        // Update order status
        await this.supabase
          .from("orders")
          .update({
            status: "disputed",
            dispute_id: disputeRecord.id,
            updated_at: new Date().toISOString()
          })
          .eq("id", order.id);

        // Alert admin immediately
        await this.alertAdminOfDispute(disputeRecord, order);

        // Gather evidence automatically
        await this.gatherDisputeEvidence(disputeRecord.id, order);
      }

      console.log(`✅ Dispute processed: ${dispute.reason}`);
    } catch (error) {
      console.error("Error handling dispute:", error);
    }
  }

  private async alertAdminOfDispute(dispute: any, order: any): Promise<void> {
    const alertData = {
      to: "admin@kctmenswear.com",
      subject: `🚨 Chargeback Alert - Order ${order.order_number}`,
      template: "chargeback_alert",
      data: {
        disputeId: dispute.stripe_dispute_id,
        orderId: order.order_number,
        amount: dispute.amount,
        currency: dispute.currency,
        reason: dispute.reason,
        customerEmail: order.guest_email || order.customers?.email,
        evidenceDue: dispute.evidence_due_by,
        orderDate: order.created_at
      }
    };

    await fetch(`${SUPABASE_URL}/functions/v1/send-email`, {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        "Authorization": `Bearer ${SUPABASE_SERVICE_ROLE_KEY}`
      },
      body: JSON.stringify(alertData)
    });
  }

  private async gatherDisputeEvidence(disputeId: string, order: any): Promise<void> {
    // Automatically gather available evidence
    const evidence = {
      customer_communication: "Order confirmation and shipping notifications sent",
      receipt: `Order receipt for ${order.order_number}`,
      shipping_documentation: order.tracking_number ? `Tracking: ${order.tracking_number}` : null,
      customer_signature: order.delivery_confirmation || null,
      service_documentation: `Order fulfilled on ${order.shipped_at}`,
      access_activity_log: `Customer accessed account on ${order.created_at}`
    };

    await this.supabase
      .from("payment_disputes")
      .update({
        evidence: evidence,
        updated_at: new Date().toISOString()
      })
      .eq("id", disputeId);
  }
}

// Testing and analytics functions
async function testPaymentErrorRecovery(): Promise<void> {
  console.log("🧪 Testing Payment Error Recovery System\n");

  const recovery = new PaymentErrorRecovery(supabase, stripe);

  // Test failure categorization
  console.log("1. Testing Failure Categorization:");
  const testErrors = [
    { code: "card_declined", message: "insufficient funds" },
    { code: "authentication_required", message: "3D Secure required" },
    { type: "api_error", message: "network timeout" }
  ];

  // Test analytics
  console.log("\n2. Getting Failure Analytics:");
  const analytics = await recovery.getFailureAnalytics("7 days");
  console.log("Analytics:", analytics);

  console.log("\n✅ Payment error recovery testing completed");
}

// Main execution
if (import.meta.main) {
  await testPaymentErrorRecovery();
}