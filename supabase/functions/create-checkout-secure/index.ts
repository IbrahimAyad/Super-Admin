import { serve } from "https://deno.land/std@0.190.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.45.0";
import Stripe from "https://esm.sh/stripe@14.21.0";
import { getCorsHeaders } from "../_shared/cors.ts";
import { 
  validateEmail, 
  validateAmount, 
  sanitizeString,
  sanitizeObject 
} from "../_shared/validation.ts";
import { createRateLimitedEndpoint, createUserTieredLimits } from '../_shared/rate-limit-middleware.ts';
import { sanitizeErrorMessage } from "../_shared/webhook-security.ts";

// Environment validation
const STRIPE_SECRET_KEY = Deno.env.get("STRIPE_SECRET_KEY");
const SUPABASE_URL = Deno.env.get("SUPABASE_URL");
const SUPABASE_SERVICE_ROLE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");

if (!STRIPE_SECRET_KEY || !SUPABASE_URL || !SUPABASE_SERVICE_ROLE_KEY) {
  console.error("Missing required environment variables");
  throw new Error("Server configuration error");
}

// Create rate limited endpoint handlers
const rateLimitedEndpoints = createRateLimitedEndpoint(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY);

interface CartItem {
  product_id?: string;
  variant_id?: string;
  stripe_price_id?: string;
  quantity: number;
  customization?: Record<string, any>;
}

interface CheckoutRequest {
  items: CartItem[];
  success_url?: string;
  cancel_url?: string;
  customer_email?: string;
  customer_details?: {
    name?: string;
    phone?: string;
    address?: {
      line1: string;
      line2?: string;
      city: string;
      state: string;
      postal_code: string;
      country: string;
    };
  };
}

/**
 * Main checkout handler
 */
async function handleCreateCheckout(req: Request): Promise<Response> {
  const origin = req.headers.get("origin");
  const corsHeaders = getCorsHeaders(origin);

  if (req.method === "OPTIONS") {
    return new Response(null, { headers: corsHeaders });
  }

  // Only accept POST requests
  if (req.method !== "POST") {
    return new Response("Method not allowed", { 
      status: 405,
      headers: corsHeaders
    });
  }

  try {
    // Parse and validate request body
    let body: CheckoutRequest;
    try {
      body = await req.json();
    } catch {
      throw new Error("Invalid JSON payload");
    }

    const { items, success_url, cancel_url, customer_email, customer_details } = body;

    // Validate required fields
    if (!items || !Array.isArray(items) || items.length === 0) {
      throw new Error("Cart items are required");
    }

    if (items.length > 50) {
      throw new Error("Too many items in cart (max 50)");
    }

    // Validate email if provided
    let validatedEmail: string | undefined;
    if (customer_email) {
      const emailValidation = validateEmail(customer_email);
      if (!emailValidation.isValid) {
        throw new Error(`Invalid email: ${emailValidation.errors[0]}`);
      }
      validatedEmail = emailValidation.sanitized;
    }

    // Validate URLs
    const allowedDomains = [
      "localhost:8080",
      "localhost:5173", 
      "kctmenswear.com",
      "admin.kctmenswear.com"
    ];

    const validateUrl = (url: string | undefined, fieldName: string): string | undefined => {
      if (!url) return undefined;
      
      try {
        const parsed = new URL(url);
        const isAllowed = allowedDomains.some(domain => 
          parsed.hostname === domain || parsed.hostname.endsWith(`.${domain}`)
        );
        
        if (!isAllowed) {
          throw new Error(`Invalid ${fieldName} domain`);
        }
        
        // Only allow http for localhost, https for production
        if (parsed.hostname === "localhost" && parsed.protocol !== "http:") {
          throw new Error(`Invalid ${fieldName} protocol for localhost`);
        }
        if (parsed.hostname !== "localhost" && parsed.protocol !== "https:") {
          throw new Error(`Invalid ${fieldName} protocol`);
        }
        
        return parsed.toString();
      } catch {
        throw new Error(`Invalid ${fieldName} URL`);
      }
    };

    const validatedSuccessUrl = validateUrl(success_url, "success_url");
    const validatedCancelUrl = validateUrl(cancel_url, "cancel_url");

    // Initialize services
    const stripe = new Stripe(STRIPE_SECRET_KEY, {
      apiVersion: "2023-10-16",
    });

    const supabase = createClient(
      SUPABASE_URL,
      SUPABASE_SERVICE_ROLE_KEY,
      { auth: { persistSession: false } }
    );

    // Generate session ID for stock reservations
    const sessionId = crypto.randomUUID();
    
    // Validate and build line items
    const lineItems: Stripe.Checkout.SessionCreateParams.LineItem[] = [];
    const orderDetails = { items: [], session_id: sessionId };
    let totalAmount = 0;

    for (let i = 0; i < items.length; i++) {
      const item = items[i];
      
      // Validate item structure
      if (!item || typeof item !== 'object') {
        throw new Error(`Invalid item at position ${i + 1}`);
      }

      // Validate quantity
      const quantity = parseInt(String(item.quantity));
      if (isNaN(quantity) || quantity < 1 || quantity > 100) {
        throw new Error(`Invalid quantity for item ${i + 1}: must be between 1 and 100`);
      }

      // Sanitize customization
      const customization = item.customization ? sanitizeObject(item.customization) : {};

      let lineItem: Stripe.Checkout.SessionCreateParams.LineItem;

      if (item.stripe_price_id) {
        // Validate Stripe price ID format
        if (typeof item.stripe_price_id !== 'string' || !item.stripe_price_id.startsWith('price_')) {
          throw new Error(`Invalid Stripe price ID for item ${i + 1}`);
        }

        // Verify price exists and is active
        try {
          const price = await stripe.prices.retrieve(item.stripe_price_id);
          if (!price.active) {
            throw new Error(`Price ${item.stripe_price_id} is not active`);
          }
          
          totalAmount += (price.unit_amount || 0) * quantity;
          
          lineItem = {
            price: item.stripe_price_id,
            quantity: quantity,
          };
        } catch (stripeError) {
          throw new Error(`Invalid price for item ${i + 1}`);
        }

        // Check inventory if variant_id provided
        if (item.variant_id) {
          await validateAndReserveInventory(
            supabase, 
            sanitizeString(item.variant_id), 
            quantity, 
            sessionId
          );
        }
      } else if (item.variant_id) {
        // Validate variant ID format (UUID)
        const variantId = sanitizeString(item.variant_id);
        if (!isValidUUID(variantId)) {
          throw new Error(`Invalid variant ID for item ${i + 1}`);
        }

        // Get variant and validate
        const { data: variant, error: variantError } = await supabase
          .from("product_variants")
          .select("*, products(*)")
          .eq("id", variantId)
          .single();

        if (variantError || !variant) {
          throw new Error(`Product variant not found for item ${i + 1}`);
        }

        // Validate price
        const priceValidation = validateAmount(variant.price, { min: 0.50, max: 10000 });
        if (!priceValidation.isValid) {
          throw new Error(`Invalid price for item ${i + 1}: ${priceValidation.errors[0]}`);
        }

        totalAmount += priceValidation.sanitized * quantity;

        // Check and reserve inventory
        await validateAndReserveInventory(supabase, variantId, quantity, sessionId);

        // Create Stripe price for catalog product
        const price = await stripe.prices.create({
          currency: "usd",
          unit_amount: Math.round(priceValidation.sanitized * 100),
          product_data: {
            name: sanitizeString(variant.products.name, 100),
            description: sanitizeString(variant.products.description || "", 500),
            metadata: {
              product_id: variant.products.id,
              variant_id: variant.id,
              sku: sanitizeString(variant.sku),
            },
          },
        });

        lineItem = {
          price: price.id,
          quantity: quantity,
        };
      } else {
        throw new Error(`Item ${i + 1} must have either stripe_price_id or variant_id`);
      }

      lineItems.push(lineItem);
      orderDetails.items.push({
        ...item,
        quantity,
        customization,
        price_id: lineItem.price,
      });
    }

    // Validate total amount
    if (totalAmount > 100000) { // $1000 limit
      throw new Error("Order total exceeds maximum allowed amount");
    }

    // Get customer and user profile if authenticated
    let customerId;
    let userProfile;
    const authHeader = req.headers.get("Authorization");
    if (authHeader && validatedEmail) {
      try {
        const token = authHeader.replace("Bearer ", "");
        const { data: { user } } = await supabase.auth.getUser(token);
        
        if (user) {
          // Get user profile for enhanced checkout experience
          const { data: profile } = await supabase
            .from("user_profiles")
            .select("*")
            .eq("id", user.id)
            .single();

          if (profile) {
            userProfile = profile;
          }

          // Check for existing Stripe customer
          const { data: existingCustomer } = await supabase
            .from("customers")
            .select("stripe_customer_id")
            .eq("auth_user_id", user.id)
            .single();

          if (existingCustomer?.stripe_customer_id) {
            customerId = existingCustomer.stripe_customer_id;
          } else {
            // Create or find customer by email
            const { data: emailCustomer } = await supabase
              .from("customers")
              .select("stripe_customer_id")
              .eq("email", validatedEmail)
              .single();

            if (emailCustomer?.stripe_customer_id) {
              customerId = emailCustomer.stripe_customer_id;
              
              // Link the customer to the user
              await supabase
                .from("customers")
                .update({ auth_user_id: user.id })
                .eq("email", validatedEmail);
            }
          }
        }
      } catch {
        // Invalid auth token, continue as guest
      }
    }

    // Prepare session metadata
    const sessionMetadata = {
      order_details: JSON.stringify(orderDetails),
      session_id: sessionId,
      user_id: userProfile?.id || "",
      customer_details: customer_details ? JSON.stringify(customer_details) : "",
    };

    // Prepare customer creation data if needed
    let customerCreateData;
    if (!customerId && validatedEmail) {
      customerCreateData = {
        email: validatedEmail,
        name: customer_details?.name || userProfile?.full_name,
        phone: customer_details?.phone || userProfile?.phone,
        address: customer_details?.address ? {
          line1: customer_details.address.line1,
          line2: customer_details.address.line2,
          city: customer_details.address.city,
          state: customer_details.address.state,
          postal_code: customer_details.address.postal_code,
          country: customer_details.address.country,
        } : undefined,
        metadata: {
          supabase_user_id: userProfile?.id || "",
          source: "checkout",
        }
      };
    }

    // Enhanced payment method configuration
    const paymentMethodTypes = ["card"];
    
    // Add additional payment methods based on region and eligibility
    if (validatedEmail && !validatedEmail.includes("+test")) {
      // Only add these for real emails, not test emails
      // paymentMethodTypes.push("us_bank_account"); // Enable if needed
    }

    // Create checkout session with validated data
    const session = await stripe.checkout.sessions.create({
      customer: customerId,
      customer_email: customerId ? undefined : validatedEmail,
      customer_creation: !customerId ? "always" : undefined,
      line_items: lineItems,
      mode: "payment",
      success_url: validatedSuccessUrl || `${origin || "https://kctmenswear.com"}/order-success?session_id={CHECKOUT_SESSION_ID}`,
      cancel_url: validatedCancelUrl || `${origin || "https://kctmenswear.com"}/cart`,
      metadata: sessionMetadata,
      expires_at: Math.floor(Date.now() / 1000) + (15 * 60), // 15 minutes
      
      // Address collection
      shipping_address_collection: {
        allowed_countries: ["US", "CA"],
      },
      billing_address_collection: "required",
      
      // Contact collection
      phone_number_collection: {
        enabled: true,
      },
      
      // Payment configuration
      payment_method_types: paymentMethodTypes,
      payment_method_options: {
        card: {
          request_three_d_secure: "automatic", // Enhanced security
        },
      },
      
      // Security features
      submit_type: "pay",
      allow_promotion_codes: false, // Prevent discount abuse
      
      // Fraud prevention
      customer_update: customerId ? {
        address: "auto",
        name: "auto",
        shipping: "auto",
      } : undefined,
      
      // Invoice creation for record keeping
      invoice_creation: {
        enabled: true,
        invoice_data: {
          description: `Order for ${validatedEmail}`,
          metadata: {
            session_id: sessionId,
            user_id: userProfile?.id || "",
          },
          footer: "Thank you for your business!",
        },
      },
      
      // Automatic tax calculation (if configured)
      automatic_tax: {
        enabled: false, // Enable when tax settings are configured
      },
      
      // Custom fields for additional data collection
      custom_fields: userProfile ? [] : [
        {
          key: "marketing_opt_in",
          label: {
            type: "text",
            text: "Subscribe to marketing emails",
          },
          type: "dropdown",
          dropdown: {
            options: [
              { label: "Yes", value: "yes" },
              { label: "No", value: "no" },
            ],
          },
          optional: true,
        },
      ],
      
      // Consent collection
      consent_collection: {
        terms_of_service: "required",
        privacy_policy: "required",
      },
    });

    // Log checkout creation with enhanced data
    await supabase
      .from("checkout_sessions")
      .insert({
        session_id: sessionId,
        stripe_session_id: session.id,
        customer_email: validatedEmail,
        total_amount: totalAmount,
        items: orderDetails.items,
        status: "created",
        expires_at: new Date(session.expires_at * 1000).toISOString(),
        user_id: userProfile?.id || null,
        customer_details: customer_details || null,
        metadata: {
          user_profile_id: userProfile?.id,
          has_saved_addresses: userProfile?.saved_addresses?.length > 0,
          payment_methods_available: paymentMethodTypes,
          origin: origin,
        },
      });

    // Update user profile last activity if authenticated
    if (userProfile?.id) {
      await supabase
        .from("user_profiles")
        .update({ 
          last_login_at: new Date().toISOString(),
          updated_at: new Date().toISOString()
        })
        .eq("id", userProfile.id);
    }

    return new Response(JSON.stringify({ 
      url: session.url,
      session_id: session.id,
      checkout_session_id: sessionId 
    }), {
      headers: { ...corsHeaders, "Content-Type": "application/json" },
      status: 200,
    });

  } catch (error) {
    console.error("Checkout error:", error);
    
    // Clean up any reservations on error
    if (sessionId) {
      try {
        await supabase
          .from("stock_reservations")
          .delete()
          .eq("session_id", sessionId);
      } catch {
        // Ignore cleanup errors
      }
    }

    const errorMessage = sanitizeErrorMessage(error);
    const statusCode = error.message?.includes("Rate limit") ? 429 : 
                      error.message?.includes("Invalid") ? 400 : 500;

    return new Response(JSON.stringify({ error: errorMessage }), {
      headers: { ...corsHeaders, "Content-Type": "application/json" },
      status: statusCode,
    });
  }
}

// Helper functions

function isValidUUID(uuid: string): boolean {
  const uuidRegex = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;
  return uuidRegex.test(uuid);
}

async function validateAndReserveInventory(
  supabase: any,
  variantId: string,
  quantity: number,
  sessionId: string
): Promise<void> {
  // Check available inventory
  const { data: availableQty, error: invError } = await supabase
    .rpc("get_available_inventory", { variant_uuid: variantId });

  if (invError) {
    throw new Error("Failed to check inventory");
  }

  if (availableQty < quantity) {
    // Get product name for better error message
    const { data: variant } = await supabase
      .from("product_variants")
      .select("products(name)")
      .eq("id", variantId)
      .single();
    
    const productName = variant?.products?.name || "item";
    throw new Error(`Insufficient inventory for ${productName}`);
  }

  // Reserve stock
  const { error: reserveError } = await supabase
    .from("stock_reservations")
    .insert({
      variant_id: variantId,
      quantity: quantity,
      session_id: sessionId,
      reserved_at: new Date().toISOString(),
      expires_at: new Date(Date.now() + 15 * 60 * 1000).toISOString(), // 15 minutes
    });

  if (reserveError) {
    throw new Error("Failed to reserve inventory");
  }
}

// Create tiered rate limiting for checkout:
// - Admin users: 500 requests/minute
// - Authenticated users: 10 requests/minute (checkout default)
// - Anonymous users: 10 requests/minute (checkout default)
const tieredRateLimits = createUserTieredLimits('checkout');

// Apply tiered rate limiting to the handler
const protectedHandler = rateLimitedEndpoints.tiered(handleCreateCheckout, tieredRateLimits);

// Serve the protected endpoint
serve(protectedHandler);