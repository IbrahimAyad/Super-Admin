import { serve } from "https://deno.land/std@0.190.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.45.0";
import Stripe from "https://esm.sh/stripe@14.21.0";
import { createRateLimitedEndpoint } from '../_shared/rate-limit-middleware.ts';
import { 
  validateApiKey, 
  sanitizeErrorMessage,
  createSecureHeaders 
} from "../_shared/webhook-security.ts";

// Environment validation
const STRIPE_SECRET_KEY = Deno.env.get("STRIPE_SECRET_KEY");
const SUPABASE_URL = Deno.env.get("SUPABASE_URL");
const SUPABASE_SERVICE_ROLE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");

if (!STRIPE_SECRET_KEY || !SUPABASE_URL || !SUPABASE_SERVICE_ROLE_KEY) {
  console.error("Missing required environment variables");
  throw new Error("Server configuration error");
}

// Initialize clients
const stripe = new Stripe(STRIPE_SECRET_KEY, {
  apiVersion: "2023-10-16",
});

const supabase = createClient(
  SUPABASE_URL,
  SUPABASE_SERVICE_ROLE_KEY,
  { auth: { persistSession: false } }
);

// Rate limited endpoint
const rateLimitedEndpoints = createRateLimitedEndpoint(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY);

/**
 * Process refund securely with comprehensive validation
 */
async function processRefund(req: Request): Promise<Response> {
  if (req.method !== "POST") {
    return new Response("Method not allowed", { 
      status: 405,
      headers: createSecureHeaders()
    });
  }

  try {
    // Validate API key
    const apiKey = req.headers.get("Authorization")?.replace("Bearer ", "");
    if (!validateApiKey(apiKey)) {
      return new Response(
        JSON.stringify({ error: "Unauthorized" }), 
        { 
          status: 401,
          headers: createSecureHeaders()
        }
      );
    }

    const { refund_request_id, refund_amount } = await req.json();

    // Validate required fields
    if (!refund_request_id || !refund_amount) {
      return new Response(
        JSON.stringify({ error: "Missing required fields" }), 
        { 
          status: 400,
          headers: createSecureHeaders()
        }
      );
    }

    // Get refund request details
    const { data: refundRequest, error: refundError } = await supabase
      .from('refund_requests')
      .select(`
        *,
        orders (
          id,
          stripe_payment_intent_id,
          stripe_checkout_session_id,
          total,
          currency,
          customer_id
        )
      `)
      .eq('id', refund_request_id)
      .eq('status', 'approved')
      .single();

    if (refundError || !refundRequest) {
      return new Response(
        JSON.stringify({ error: "Refund request not found or not approved" }), 
        { 
          status: 404,
          headers: createSecureHeaders()
        }
      );
    }

    // Validate refund amount
    if (refund_amount > refundRequest.orders.total) {
      return new Response(
        JSON.stringify({ error: "Refund amount exceeds order total" }), 
        { 
          status: 400,
          headers: createSecureHeaders()
        }
      );
    }

    // Process refund with Stripe
    let stripeRefund;
    const refundAmountCents = Math.round(refund_amount * 100);

    try {
      if (refundRequest.orders.stripe_payment_intent_id) {
        // Refund via Payment Intent
        stripeRefund = await stripe.refunds.create({
          payment_intent: refundRequest.orders.stripe_payment_intent_id,
          amount: refundAmountCents,
          reason: getStripeRefundReason(refundRequest.reason),
          metadata: {
            refund_request_id: refund_request_id,
            order_id: refundRequest.order_id,
            processed_by: 'system'
          }
        });
      } else if (refundRequest.orders.stripe_checkout_session_id) {
        // Get payment intent from checkout session
        const session = await stripe.checkout.sessions.retrieve(
          refundRequest.orders.stripe_checkout_session_id
        );
        
        if (!session.payment_intent) {
          throw new Error("No payment intent found for checkout session");
        }

        stripeRefund = await stripe.refunds.create({
          payment_intent: session.payment_intent as string,
          amount: refundAmountCents,
          reason: getStripeRefundReason(refundRequest.reason),
          metadata: {
            refund_request_id: refund_request_id,
            order_id: refundRequest.order_id,
            processed_by: 'system'
          }
        });
      } else {
        throw new Error("No Stripe payment reference found");
      }

      // Create financial transaction record
      await supabase
        .from('financial_transactions')
        .insert([{
          order_id: refundRequest.order_id,
          type: refundRequest.type === 'full' ? 'refund' : 'partial_refund',
          status: stripeRefund.status === 'succeeded' ? 'completed' : 'pending',
          amount: refund_amount,
          currency: refundRequest.orders.currency,
          fees: calculateRefundFees(refund_amount),
          net_amount: refund_amount - calculateRefundFees(refund_amount),
          gateway: 'stripe',
          gateway_transaction_id: stripeRefund.id,
          metadata: {
            refund_request_id: refund_request_id,
            stripe_refund_id: stripeRefund.id,
            original_charge: stripeRefund.charge
          }
        }]);

      // Create audit trail
      await supabase
        .from('financial_audit_trails')
        .insert([{
          transaction_id: stripeRefund.id,
          action: 'refund_processed',
          changes: {
            refund_amount: refund_amount,
            stripe_refund_id: stripeRefund.id,
            status: stripeRefund.status
          },
          reason: `Refund processed for ${refundRequest.reason}`
        }]);

      // Check for suspicious refund patterns
      await checkRefundAbusePatterns(refundRequest.orders.customer_id);

      return new Response(
        JSON.stringify({ 
          success: true,
          stripe_refund_id: stripeRefund.id,
          status: stripeRefund.status,
          amount: refund_amount
        }), 
        {
          status: 200,
          headers: createSecureHeaders()
        }
      );

    } catch (stripeError: any) {
      console.error("Stripe refund failed:", stripeError);

      // Log failed refund attempt
      await supabase
        .from('financial_audit_trails')
        .insert([{
          transaction_id: refund_request_id,
          action: 'refund_failed',
          changes: {
            error: stripeError.message,
            refund_amount: refund_amount
          },
          reason: 'Stripe refund processing failed'
        }]);

      return new Response(
        JSON.stringify({ 
          error: "Refund processing failed",
          details: sanitizeErrorMessage(stripeError)
        }), 
        { 
          status: 400,
          headers: createSecureHeaders()
        }
      );
    }

  } catch (error: any) {
    console.error("Refund processing error:", error);
    
    return new Response(
      JSON.stringify({ 
        error: "Internal server error",
        details: sanitizeErrorMessage(error)
      }), 
      {
        status: 500,
        headers: createSecureHeaders()
      }
    );
  }
}

/**
 * Map internal refund reasons to Stripe reasons
 */
function getStripeRefundReason(reason: string): 'duplicate' | 'fraudulent' | 'requested_by_customer' {
  switch (reason) {
    case 'duplicate':
      return 'duplicate';
    case 'fraudulent':
      return 'fraudulent';
    case 'requested_by_customer':
    case 'defective':
    case 'not_received':
    case 'other':
    default:
      return 'requested_by_customer';
  }
}

/**
 * Calculate refund processing fees
 */
function calculateRefundFees(amount: number): number {
  // Stripe doesn't refund processing fees for most transactions
  // This is for tracking purposes
  return Math.round((amount * 0.029 + 0.30) * 100) / 100;
}

/**
 * Check for refund abuse patterns
 */
async function checkRefundAbusePatterns(customerId?: string): Promise<void> {
  if (!customerId) return;

  try {
    const thirtyDaysAgo = new Date(Date.now() - 30 * 24 * 60 * 60 * 1000).toISOString();

    // Count refunds in last 30 days
    const { data: recentRefunds, error } = await supabase
      .from('refund_requests')
      .select('*')
      .eq('customer_id', customerId)
      .gte('created_at', thirtyDaysAgo)
      .eq('status', 'completed');

    if (error) throw error;

    const refundCount = recentRefunds?.length || 0;
    const totalRefunded = recentRefunds?.reduce((sum, refund) => sum + refund.refund_amount, 0) || 0;

    // Alert thresholds
    const MAX_REFUNDS_30_DAYS = 5;
    const MAX_REFUND_AMOUNT_30_DAYS = 1000;

    if (refundCount > MAX_REFUNDS_30_DAYS || totalRefunded > MAX_REFUND_AMOUNT_30_DAYS) {
      // Create financial alert
      await supabase
        .from('financial_alerts')
        .insert([{
          type: 'unusual_refund_pattern',
          severity: refundCount > MAX_REFUNDS_30_DAYS * 2 ? 'high' : 'medium',
          message: `Customer has ${refundCount} refunds totaling $${totalRefunded} in the last 30 days`,
          metadata: {
            customer_id: customerId,
            refund_count: refundCount,
            total_refunded: totalRefunded,
            pattern_detected: refundCount > MAX_REFUNDS_30_DAYS ? 'high_frequency' : 'high_value'
          },
          status: 'active'
        }]);
    }

  } catch (error) {
    console.error("Error checking refund abuse patterns:", error);
    // Don't fail the refund for this
  }
}

/**
 * Validate refund eligibility
 */
async function validateRefundEligibility(refundRequestId: string): Promise<{
  eligible: boolean;
  reason?: string;
}> {
  try {
    const { data: refundRequest, error } = await supabase
      .from('refund_requests')
      .select(`
        *,
        orders (
          id,
          created_at,
          status,
          total
        )
      `)
      .eq('id', refundRequestId)
      .single();

    if (error || !refundRequest) {
      return { eligible: false, reason: "Refund request not found" };
    }

    // Check if order is already refunded
    if (refundRequest.orders.status === 'refunded') {
      return { eligible: false, reason: "Order already refunded" };
    }

    // Check refund window (30 days default)
    const orderDate = new Date(refundRequest.orders.created_at);
    const daysSinceOrder = Math.floor((Date.now() - orderDate.getTime()) / (1000 * 60 * 60 * 24));
    
    if (daysSinceOrder > 30) {
      return { eligible: false, reason: "Refund window has expired" };
    }

    // Check for existing processed refunds
    const { data: existingRefunds, error: refundError } = await supabase
      .from('refund_requests')
      .select('refund_amount')
      .eq('order_id', refundRequest.order_id)
      .eq('status', 'completed');

    if (refundError) throw refundError;

    const totalRefunded = existingRefunds?.reduce((sum, r) => sum + r.refund_amount, 0) || 0;
    const newTotal = totalRefunded + refundRequest.refund_amount;

    if (newTotal > refundRequest.orders.total) {
      return { eligible: false, reason: "Refund would exceed order total" };
    }

    return { eligible: true };

  } catch (error) {
    console.error("Error validating refund eligibility:", error);
    return { eligible: false, reason: "Validation error" };
  }
}

// Apply rate limiting (100 refunds per hour)
const protectedHandler = rateLimitedEndpoints.refund(processRefund);

// Serve the protected endpoint
serve(protectedHandler);