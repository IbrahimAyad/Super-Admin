import { serve } from "https://deno.land/std@0.190.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.45.0";
import Stripe from "https://esm.sh/stripe@14.21.0";
import { createRateLimitedEndpoint } from '../_shared/rate-limit-middleware.ts';
import { 
  checkReplayProtection, 
  sanitizeErrorMessage,
  createSecureWebhookHeaders 
} from "../_shared/webhook-security.ts";

// Environment validation
const STRIPE_SECRET_KEY = Deno.env.get("STRIPE_SECRET_KEY");
const STRIPE_WEBHOOK_SECRET = Deno.env.get("STRIPE_WEBHOOK_SECRET");
const SUPABASE_URL = Deno.env.get("SUPABASE_URL");
const SUPABASE_SERVICE_ROLE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");

if (!STRIPE_SECRET_KEY || !STRIPE_WEBHOOK_SECRET || !SUPABASE_URL || !SUPABASE_SERVICE_ROLE_KEY) {
  console.error("Missing required environment variables");
  throw new Error("Server configuration error");
}

// Create rate limited endpoint handlers
const rateLimitedEndpoints = createRateLimitedEndpoint(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY);

/**
 * Main Stripe webhook handler
 */
async function handleStripeWebhook(req: Request): Promise<Response> {
  // Webhooks should only accept POST requests
  if (req.method !== "POST") {
    return new Response("Method not allowed", { 
      status: 405,
      headers: createSecureWebhookHeaders()
    });
  }

  try {

    // Initialize Stripe with validated secret
    const stripe = new Stripe(STRIPE_SECRET_KEY, {
      apiVersion: "2023-10-16",
    });

    // Initialize Supabase with validated credentials
    const supabase = createClient(
      SUPABASE_URL,
      SUPABASE_SERVICE_ROLE_KEY,
      { auth: { persistSession: false } }
    );

    // Get required headers
    const signature = req.headers.get("stripe-signature");
    if (!signature) {
      throw new Error("Missing webhook signature");
    }

    // Read body as text for signature verification
    const body = await req.text();
    
    // Construct and verify webhook event
    let event: Stripe.Event;
    try {
      event = stripe.webhooks.constructEvent(body, signature, STRIPE_WEBHOOK_SECRET);
    } catch (err) {
      console.error("Webhook signature verification failed:", err);
      return new Response(
        JSON.stringify({ error: "Invalid signature" }), 
        { 
          status: 401,
          headers: createSecureWebhookHeaders()
        }
      );
    }

    // Replay protection
    if (!checkReplayProtection(event.id)) {
      console.warn(`Duplicate webhook detected: ${event.id}`);
      return new Response(
        JSON.stringify({ error: "Duplicate webhook" }), 
        { 
          status: 409,
          headers: createSecureWebhookHeaders()
        }
      );
    }

    // Get client IP for logging
    const clientIp = req.headers.get("x-forwarded-for") || 
                     req.headers.get("x-real-ip") || 
                     req.headers.get("cf-connecting-ip") || 
                     "unknown";

    // Log webhook processing
    console.log(`Processing webhook: ${event.type} (${event.id})`);
    
    // Log webhook event in database
    await supabase
      .from("webhook_logs")
      .insert({
        webhook_id: event.id,
        source: "stripe",
        event_type: event.type,
        payload: event,
        status: "processing",
        ip_address: clientIp,
      });

    // Process webhook based on event type
    try {
      switch (event.type) {
        case "checkout.session.completed": {
          const session = event.data.object as Stripe.Checkout.Session;
          await handleCheckoutCompleted(supabase, stripe, session);
          break;
        }
        case "payment_intent.succeeded": {
          const paymentIntent = event.data.object as Stripe.PaymentIntent;
          await handlePaymentSucceeded(supabase, paymentIntent);
          break;
        }
        case "payment_intent.payment_failed": {
          const paymentIntent = event.data.object as Stripe.PaymentIntent;
          await handlePaymentFailed(supabase, paymentIntent);
          break;
        }
        case "customer.created": {
          const customer = event.data.object as Stripe.Customer;
          await handleCustomerCreated(supabase, customer);
          break;
        }
        case "charge.dispute.created": {
          const dispute = event.data.object as Stripe.Dispute;
          await handleDisputeCreated(supabase, dispute);
          break;
        }
        default:
          console.log(`Unhandled event type: ${event.type}`);
      }

      // Update webhook log status
      await supabase
        .from("webhook_logs")
        .update({ 
          status: "completed",
          processed_at: new Date().toISOString()
        })
        .eq("webhook_id", event.id);

    } catch (processingError) {
      // Log processing error
      console.error(`Error processing ${event.type}:`, processingError);
      
      await supabase
        .from("webhook_logs")
        .update({ 
          status: "failed",
          error_message: processingError.message,
          processed_at: new Date().toISOString()
        })
        .eq("webhook_id", event.id);

      throw processingError;
    }

    // Return success response
    return new Response(
      JSON.stringify({ received: true }), 
      {
        status: 200,
        headers: createSecureWebhookHeaders()
      }
    );

  } catch (error) {
    // Log error securely
    console.error("Webhook error:", error);
    
    // Return sanitized error response
    const errorMessage = sanitizeErrorMessage(error);
    const statusCode = error.message?.includes("signature") ? 401 : 400;
    
    return new Response(
      JSON.stringify({ error: errorMessage }), 
      {
        status: statusCode,
        headers: createSecureWebhookHeaders()
      }
    );
  }
}

// Handler functions with improved error handling and validation

async function handleCheckoutCompleted(
  supabase: any,
  stripe: Stripe,
  session: Stripe.Checkout.Session
) {
  // Validate session data
  if (!session.id || !session.payment_status) {
    throw new Error("Invalid checkout session data");
  }

  // Only process paid sessions
  if (session.payment_status !== "paid") {
    console.log(`Session ${session.id} not paid yet, skipping`);
    return;
  }

  console.log(`Processing checkout session: ${session.id}`);

  try {
    // Get checkout session data from our database
    const { data: checkoutSession } = await supabase
      .from("checkout_sessions")
      .select("*")
      .eq("stripe_session_id", session.id)
      .single();

    // Extract user profile ID from metadata
    const userId = session.metadata?.user_id || checkoutSession?.user_id;
    const sessionId = session.metadata?.session_id || checkoutSession?.session_id;

    // Create or update customer record
    let customerId;
    if (session.customer) {
      customerId = await handleCustomerFromSession(supabase, session, userId);
    }

    // Create order record
    const orderData = {
      order_number: `ORD-${Date.now()}-${Math.random().toString(36).substr(2, 6).toUpperCase()}`,
      stripe_checkout_session_id: session.id,
      stripe_payment_intent_id: session.payment_intent,
      customer_id: customerId,
      user_id: userId,
      guest_email: !userId ? session.customer_details?.email : null,
      total_amount: (session.amount_total || 0) / 100,
      currency: session.currency || 'usd',
      status: 'processing',
      payment_status: 'paid',
      payment_received_at: new Date().toISOString(),
      shipping_address: session.shipping_details?.address ? {
        name: session.shipping_details.name,
        address: session.shipping_details.address,
      } : null,
      billing_address: session.customer_details?.address,
      metadata: {
        stripe_session_id: session.id,
        checkout_session_id: sessionId,
        custom_fields: session.custom_fields,
      },
    };

    const { data: order, error: orderError } = await supabase
      .from("orders")
      .insert(orderData)
      .select()
      .single();

    if (orderError) {
      throw new Error(`Failed to create order: ${orderError.message}`);
    }

    // Process order items
    if (checkoutSession?.items) {
      await processOrderItems(supabase, order.id, checkoutSession.items);
    }

    // Update user profile with purchase data
    if (userId) {
      await updateUserProfileAfterPurchase(supabase, userId, order);
    }

    // Release inventory reservations and update stock
    if (sessionId) {
      await finalizeInventoryUpdates(supabase, sessionId, checkoutSession?.items);
    }

    // Clear cart items
    if (userId || sessionId) {
      await clearCartAfterCheckout(supabase, userId, sessionId);
    }

    // Update checkout session status
    await supabase
      .from("checkout_sessions")
      .update({ 
        status: "completed",
        order_id: order.id,
        completed_at: new Date().toISOString()
      })
      .eq("stripe_session_id", session.id);

    // Send order confirmation email
    try {
      await sendOrderConfirmationEmail(supabase, session, order);
    } catch (emailError) {
      // Log but don't fail the webhook
      console.error("Failed to send confirmation email:", emailError);
    }

    // Trigger fulfillment workflow
    try {
      await triggerFulfillmentWorkflow(supabase, order);
    } catch (fulfillmentError) {
      console.error("Failed to trigger fulfillment:", fulfillmentError);
    }

    console.log(`Successfully processed order ${order.order_number}`);

  } catch (error) {
    console.error("Error in checkout completion:", error);
    
    // Update checkout session with error
    await supabase
      .from("checkout_sessions")
      .update({ 
        status: "failed",
        error_message: error.message,
        failed_at: new Date().toISOString()
      })
      .eq("stripe_session_id", session.id);

    throw error;
  }
}

async function handlePaymentSucceeded(supabase: any, paymentIntent: Stripe.PaymentIntent) {
  if (!paymentIntent.id) {
    throw new Error("Invalid payment intent data");
  }

  console.log(`Processing payment success: ${paymentIntent.id}`);

  const { error } = await supabase
    .from("orders")
    .update({ 
      status: "processing",
      payment_received_at: new Date().toISOString()
    })
    .eq("stripe_payment_intent_id", paymentIntent.id);

  if (error) {
    throw new Error(`Failed to update order: ${error.message}`);
  }
}

async function handlePaymentFailed(supabase: any, paymentIntent: Stripe.PaymentIntent) {
  if (!paymentIntent.id) {
    throw new Error("Invalid payment intent data");
  }

  console.log(`Processing payment failure: ${paymentIntent.id}`);

  const { error } = await supabase
    .from("orders")
    .update({ 
      status: "payment_failed",
      payment_error: paymentIntent.last_payment_error?.message
    })
    .eq("stripe_payment_intent_id", paymentIntent.id);

  if (error) {
    throw new Error(`Failed to update order: ${error.message}`);
  }

  // Could trigger a payment failure email here
}

async function handleCustomerCreated(supabase: any, customer: Stripe.Customer) {
  if (!customer.id || !customer.email) {
    console.log("Skipping customer creation - missing required data");
    return;
  }

  console.log(`Processing new customer: ${customer.id}`);

  // Check if customer already exists
  const { data: existingCustomer } = await supabase
    .from("customers")
    .select("id")
    .eq("email", customer.email)
    .single();

  if (!existingCustomer) {
    const { error } = await supabase
      .from("customers")
      .insert({
        email: customer.email,
        first_name: customer.name?.split(" ")[0],
        last_name: customer.name?.split(" ").slice(1).join(" "),
        phone: customer.phone,
        stripe_customer_id: customer.id,
      });

    if (error) {
      throw new Error(`Failed to create customer: ${error.message}`);
    }
  } else {
    // Update existing customer with Stripe ID
    await supabase
      .from("customers")
      .update({ stripe_customer_id: customer.id })
      .eq("id", existingCustomer.id);
  }
}

async function handleDisputeCreated(supabase: any, dispute: Stripe.Dispute) {
  console.log(`Processing dispute: ${dispute.id}`);
  
  // Log dispute for manual review
  await supabase
    .from("payment_disputes")
    .insert({
      stripe_dispute_id: dispute.id,
      payment_intent_id: dispute.payment_intent,
      amount: dispute.amount / 100,
      currency: dispute.currency,
      reason: dispute.reason,
      status: dispute.status,
      created_at: new Date(dispute.created * 1000).toISOString(),
    });

  // Could trigger an alert email to admins here
}

// Enhanced helper functions for webhook processing

async function handleCustomerFromSession(
  supabase: any, 
  session: Stripe.Checkout.Session, 
  userId?: string
): Promise<string | null> {
  if (!session.customer || typeof session.customer === 'object') {
    return null;
  }

  const customerId = session.customer as string;
  const customerEmail = session.customer_details?.email;

  if (!customerEmail) return customerId;

  try {
    // Check if customer exists in our database
    const { data: existingCustomer } = await supabase
      .from("customers")
      .select("id")
      .eq("stripe_customer_id", customerId)
      .single();

    if (existingCustomer) {
      // Update customer with user ID if available
      if (userId) {
        await supabase
          .from("customers")
          .update({ auth_user_id: userId })
          .eq("id", existingCustomer.id);
      }
      return existingCustomer.id;
    }

    // Create new customer record
    const customerData = {
      email: customerEmail,
      first_name: session.customer_details?.name?.split(' ')[0] || '',
      last_name: session.customer_details?.name?.split(' ').slice(1).join(' ') || '',
      phone: session.customer_details?.phone,
      stripe_customer_id: customerId,
      auth_user_id: userId,
      billing_address: session.customer_details?.address,
      created_at: new Date().toISOString(),
    };

    const { data: newCustomer, error } = await supabase
      .from("customers")
      .insert(customerData)
      .select("id")
      .single();

    if (error) {
      console.error("Failed to create customer:", error);
      return null;
    }

    return newCustomer.id;
  } catch (error) {
    console.error("Error handling customer from session:", error);
    return null;
  }
}

async function processOrderItems(supabase: any, orderId: string, items: any[]) {
  const orderItems = items.map(item => ({
    order_id: orderId,
    product_id: item.product_id,
    variant_id: item.variant_id,
    quantity: item.quantity,
    unit_price: item.price || 0,
    total_price: (item.price || 0) * item.quantity,
    customizations: item.customization || {},
    stripe_price_id: item.price_id,
    created_at: new Date().toISOString(),
  }));

  const { error } = await supabase
    .from("order_items")
    .insert(orderItems);

  if (error) {
    throw new Error(`Failed to create order items: ${error.message}`);
  }
}

async function updateUserProfileAfterPurchase(supabase: any, userId: string, order: any) {
  try {
    // Get current user profile
    const { data: profile } = await supabase
      .from("user_profiles")
      .select("*")
      .eq("id", userId)
      .single();

    if (!profile) return;

    // Calculate lifetime value update
    const currentLifetimeValue = profile.lifetime_value || 0;
    const newLifetimeValue = currentLifetimeValue + order.total_amount;

    // Update profile with purchase data
    await supabase
      .from("user_profiles")
      .update({
        lifetime_value: newLifetimeValue,
        last_purchase_at: new Date().toISOString(),
        total_orders: (profile.total_orders || 0) + 1,
        updated_at: new Date().toISOString(),
      })
      .eq("id", userId);

    // Update customer segment based on lifetime value
    let customerSegment = 'bronze';
    if (newLifetimeValue >= 1000) customerSegment = 'gold';
    else if (newLifetimeValue >= 500) customerSegment = 'silver';

    await supabase
      .from("customers")
      .update({ 
        customer_segment: customerSegment,
        lifetime_value: newLifetimeValue,
        last_order_at: new Date().toISOString(),
      })
      .eq("auth_user_id", userId);

  } catch (error) {
    console.error("Error updating user profile after purchase:", error);
  }
}

async function finalizeInventoryUpdates(supabase: any, sessionId: string, items: any[]) {
  try {
    // Release reservations and update inventory
    for (const item of items) {
      if (item.variant_id && item.quantity) {
        // Remove from inventory
        await supabase.rpc("update_inventory_after_sale", {
          variant_uuid: item.variant_id,
          quantity_sold: item.quantity,
          order_reference: sessionId,
        });
      }
    }

    // Remove reservations
    await supabase
      .from("stock_reservations")
      .delete()
      .eq("session_id", sessionId);

  } catch (error) {
    console.error("Error finalizing inventory updates:", error);
  }
}

async function clearCartAfterCheckout(supabase: any, userId?: string, sessionId?: string) {
  try {
    let query = supabase.from("cart_items").delete();

    if (userId) {
      query = query.eq("user_id", userId);
    } else if (sessionId) {
      query = query.eq("session_id", sessionId);
    } else {
      return; // Can't clear without identifier
    }

    await query;
  } catch (error) {
    console.error("Error clearing cart after checkout:", error);
  }
}

async function triggerFulfillmentWorkflow(supabase: any, order: any) {
  try {
    // Create fulfillment record
    await supabase
      .from("order_fulfillment")
      .insert({
        order_id: order.id,
        status: "pending",
        fulfillment_method: "standard_shipping",
        estimated_ship_date: new Date(Date.now() + 2 * 24 * 60 * 60 * 1000).toISOString(), // 2 days
        created_at: new Date().toISOString(),
      });

    // Could trigger external fulfillment API here
    
  } catch (error) {
    console.error("Error triggering fulfillment workflow:", error);
  }
}

async function sendOrderConfirmationEmail(supabase: any, session: Stripe.Checkout.Session, order?: any) {
  const customerEmail = session.customer_email || session.customer_details?.email;
  if (!customerEmail) return;

  const orderData = {
    orderId: order?.order_number || session.id,
    customerEmail,
    customerName: session.customer_details?.name || "Valued Customer",
    total: (session.amount_total || 0) / 100,
    currency: session.currency || "usd",
    orderDetails: order || null,
    shippingAddress: session.shipping_details?.address,
  };

  const response = await fetch(`${SUPABASE_URL}/functions/v1/send-order-confirmation-secure`, {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
      "Authorization": `Bearer ${SUPABASE_SERVICE_ROLE_KEY}`,
    },
    body: JSON.stringify(orderData),
  });

  if (!response.ok) {
    throw new Error("Failed to trigger order confirmation email");
  }
}

// Apply webhook rate limiting (1000 requests/minute)
const protectedHandler = rateLimitedEndpoints.webhook(handleStripeWebhook);

// Serve the protected endpoint
serve(protectedHandler);