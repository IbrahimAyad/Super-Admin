# Supabase Edge Functions Documentation

Complete documentation for all Edge Functions in the KCT Menswear system.

## Overview

Edge Functions are serverless functions that run on Supabase's edge network. They handle sensitive operations that require service role access or external API integrations.

## Function List

| Function | Purpose | Trigger |
|----------|---------|---------|
| `stripe-webhook` | Handle Stripe webhooks | Webhook from Stripe |
| `stripe-webhook-secure` | Secure Stripe webhook handler | Webhook from Stripe |
| `sync-stripe-product` | Sync single product to Stripe | Admin action |
| `sync-stripe-products` | Bulk sync products to Stripe | Admin action |
| `create-checkout` | Create Stripe checkout session | Customer checkout |
| `create-checkout-secure` | Secure checkout with validation | Customer checkout |
| `process-refund` | Process Stripe refunds | Admin action |
| `send-email` | Send transactional emails | Various triggers |
| `email-service` | Email service coordinator | Various triggers |
| `send-order-confirmation` | Send order confirmation emails | Order placed |
| `send-welcome-email` | Send welcome emails | User signup |
| `send-password-reset` | Send password reset emails | Password reset request |
| `send-abandoned-cart` | Send cart abandonment emails | Scheduled task |
| `send-marketing-campaign` | Send marketing emails | Admin action |
| `ai-recommendations` | Generate AI product recommendations | User preference update |
| `bundle-builder` | Create product bundles | Admin/User action |
| `get-products` | Enhanced product fetching | API request |
| `analytics-dashboard` | Generate analytics data | Dashboard load |
| `daily-report` | Generate daily reports | Scheduled task |
| `kct-webhook` | Handle KCT API webhooks | External webhook |

## Core Functions

### stripe-webhook

Handles all Stripe webhook events.

**Endpoint**: `/functions/v1/stripe-webhook`

**Events Handled**:
- `checkout.session.completed`
- `payment_intent.succeeded`
- `payment_intent.failed`
- `customer.created`
- `customer.subscription.created`
- `customer.subscription.updated`
- `customer.subscription.deleted`
- `invoice.paid`
- `invoice.payment_failed`

**Implementation**:
```typescript
import { serve } from "https://deno.land/std@0.190.0/http/server.ts";
import Stripe from "https://esm.sh/stripe@14.21.0";

serve(async (req) => {
  const signature = req.headers.get("stripe-signature");
  const body = await req.text();
  
  // Verify webhook signature
  const stripe = new Stripe(Deno.env.get("STRIPE_SECRET_KEY"));
  const webhookSecret = Deno.env.get("STRIPE_WEBHOOK_SECRET");
  
  let event;
  try {
    event = stripe.webhooks.constructEvent(body, signature, webhookSecret);
  } catch (err) {
    return new Response(`Webhook Error: ${err.message}`, { status: 400 });
  }
  
  // Handle events
  switch (event.type) {
    case "checkout.session.completed":
      await handleCheckoutComplete(event.data.object);
      break;
    // ... other cases
  }
  
  return new Response(JSON.stringify({ received: true }), { status: 200 });
});
```

### sync-stripe-product

Syncs a single product to Stripe.

**Endpoint**: `/functions/v1/sync-stripe-product`

**Request Body**:
```json
{
  "product": {
    "id": "uuid",
    "name": "Product Name",
    "description": "Description",
    "metadata": {}
  },
  "variants": [
    {
      "id": "uuid",
      "price": 299.99,
      "title": "Variant Name",
      "sku": "SKU123"
    }
  ],
  "mode": "create" // or "update"
}
```

**Response**:
```json
{
  "success": true,
  "stripe_product_id": "prod_xxx",
  "price_ids": {
    "variant_uuid": "price_xxx"
  }
}
```

### create-checkout-secure

Creates a Stripe checkout session with validation.

**Endpoint**: `/functions/v1/create-checkout-secure`

**Request Body**:
```json
{
  "items": [
    {
      "price_id": "price_xxx",
      "quantity": 1
    }
  ],
  "customer_email": "customer@example.com",
  "success_url": "https://example.com/success",
  "cancel_url": "https://example.com/cancel",
  "metadata": {
    "order_id": "uuid",
    "customer_id": "uuid"
  }
}
```

**Security Features**:
- Rate limiting
- Input validation
- CORS handling
- Webhook security

### email-service

Centralized email service for all email operations.

**Endpoint**: `/functions/v1/email-service`

**Request Body**:
```json
{
  "template": "order_confirmation",
  "to": "customer@example.com",
  "data": {
    "order_number": "ORD-2025-001",
    "customer_name": "John Doe",
    "items": [...],
    "total": 299.99
  }
}
```

**Supported Templates**:
- `order_confirmation`
- `order_shipped`
- `welcome`
- `password_reset`
- `abandoned_cart`
- `marketing`
- `fitting_reminder`
- `measurement_request`

### ai-recommendations

Generates AI-powered product recommendations.

**Endpoint**: `/functions/v1/ai-recommendations`

**Request Body**:
```json
{
  "customer_id": "uuid",
  "preferences": {
    "colors": ["navy", "grey"],
    "styles": ["business casual"],
    "occasions": ["work", "dinner"],
    "budget": 500
  },
  "context": {
    "season": "fall",
    "event_type": "wedding"
  }
}
```

**Response**:
```json
{
  "recommendations": [
    {
      "product_id": "uuid",
      "confidence": 0.95,
      "reasoning": "Matches color preference and occasion",
      "variants": ["uuid1", "uuid2"]
    }
  ],
  "bundles": [
    {
      "name": "Complete Look",
      "items": [...],
      "discount": 10,
      "total_price": 449.99
    }
  ]
}
```

## Deployment

### Deploy All Functions

```bash
# Deploy all functions
supabase functions deploy

# Deploy with secrets
supabase secrets set STRIPE_SECRET_KEY=sk_live_xxx
supabase secrets set RESEND_API_KEY=re_xxx
supabase functions deploy
```

### Deploy Single Function

```bash
# Deploy specific function
supabase functions deploy function-name

# With custom config
supabase functions deploy function-name \
  --no-verify-jwt \
  --import-map ./import_map.json
```

### Local Development

```bash
# Serve function locally
supabase functions serve function-name

# Test locally
curl -i --location --request POST \
  'http://localhost:54321/functions/v1/function-name' \
  --header 'Authorization: Bearer YOUR_ANON_KEY' \
  --header 'Content-Type: application/json' \
  --data '{"key":"value"}'
```

## Configuration

### Environment Variables

Required secrets for Edge Functions:

```bash
# Supabase
SUPABASE_URL
SUPABASE_SERVICE_ROLE_KEY

# Stripe
STRIPE_SECRET_KEY
STRIPE_WEBHOOK_SECRET

# Email Service (choose one)
RESEND_API_KEY
SENDGRID_API_KEY

# AI Services
OPENAI_API_KEY
KCT_API_KEY

# Other
ENCRYPTION_KEY
WEBHOOK_SECRET
```

### CORS Configuration

All functions should include CORS headers:

```typescript
const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 
    'authorization, x-client-info, apikey, content-type',
};

// OPTIONS request
if (req.method === 'OPTIONS') {
  return new Response(null, { headers: corsHeaders });
}
```

### Rate Limiting

Implement rate limiting using the shared middleware:

```typescript
import { rateLimitMiddleware } from '../_shared/rate-limit-middleware.ts';

serve(async (req) => {
  // Check rate limit
  const rateLimitResult = await rateLimitMiddleware(req);
  if (!rateLimitResult.allowed) {
    return new Response('Rate limit exceeded', { status: 429 });
  }
  
  // Process request
});
```

## Security

### Input Validation

All functions should validate input:

```typescript
import { z } from 'https://deno.land/x/zod/mod.ts';

const schema = z.object({
  email: z.string().email(),
  amount: z.number().positive(),
});

const result = schema.safeParse(body);
if (!result.success) {
  return new Response(
    JSON.stringify({ error: result.error }),
    { status: 400 }
  );
}
```

### Authentication

Functions can verify JWT tokens:

```typescript
import { createClient } from '@supabase/supabase-js';

const supabase = createClient(
  Deno.env.get('SUPABASE_URL'),
  Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')
);

// Verify user
const token = req.headers.get('Authorization')?.replace('Bearer ', '');
const { data: { user }, error } = await supabase.auth.getUser(token);

if (error || !user) {
  return new Response('Unauthorized', { status: 401 });
}
```

### Webhook Security

Verify webhook signatures:

```typescript
import { createHmac } from 'https://deno.land/std/node/crypto.ts';

function verifyWebhookSignature(
  payload: string,
  signature: string,
  secret: string
): boolean {
  const hmac = createHmac('sha256', secret);
  hmac.update(payload);
  const expectedSignature = hmac.digest('hex');
  return signature === expectedSignature;
}
```

## Monitoring

### Logging

View function logs:

```bash
# Real-time logs
supabase functions logs function-name --tail

# Historical logs
supabase functions logs function-name --since 1h

# Filter by level
supabase functions logs function-name --level error
```

### Metrics

Monitor function performance:

```sql
-- Function invocations
SELECT 
  function_name,
  COUNT(*) as invocations,
  AVG(duration_ms) as avg_duration,
  MAX(duration_ms) as max_duration,
  COUNT(*) FILTER (WHERE status = 'error') as errors
FROM function_logs
WHERE created_at > NOW() - INTERVAL '24 hours'
GROUP BY function_name;
```

### Alerts

Set up alerts for function failures:

```javascript
// In function code
if (error) {
  // Log to monitoring service
  await fetch('https://monitoring.service/alert', {
    method: 'POST',
    body: JSON.stringify({
      function: 'function-name',
      error: error.message,
      timestamp: new Date().toISOString(),
    }),
  });
}
```

## Testing

### Unit Tests

```typescript
// function.test.ts
import { assertEquals } from "https://deno.land/std/testing/asserts.ts";
import { handler } from "./index.ts";

Deno.test("Function returns correct response", async () => {
  const req = new Request("http://localhost", {
    method: "POST",
    body: JSON.stringify({ test: true }),
  });
  
  const response = await handler(req);
  const data = await response.json();
  
  assertEquals(response.status, 200);
  assertEquals(data.success, true);
});

// Run tests
// deno test function.test.ts
```

### Integration Tests

```bash
# Test with curl
curl -X POST \
  https://your-project.supabase.co/functions/v1/function-name \
  -H "Authorization: Bearer YOUR_ANON_KEY" \
  -H "Content-Type: application/json" \
  -d '{"test": true}'

# Test with Postman/Insomnia
# Import the collection from docs/postman-collection.json
```

## Best Practices

### 1. Error Handling

Always return proper error responses:

```typescript
try {
  // Process request
} catch (error) {
  console.error('Function error:', error);
  
  return new Response(
    JSON.stringify({
      error: error.message,
      code: error.code || 'UNKNOWN_ERROR',
    }),
    { 
      status: error.status || 500,
      headers: { 'Content-Type': 'application/json' },
    }
  );
}
```

### 2. Timeouts

Set appropriate timeouts:

```typescript
const controller = new AbortController();
const timeoutId = setTimeout(() => controller.abort(), 25000); // 25 seconds

try {
  const response = await fetch(url, { 
    signal: controller.signal 
  });
  clearTimeout(timeoutId);
} catch (error) {
  if (error.name === 'AbortError') {
    return new Response('Request timeout', { status: 408 });
  }
}
```

### 3. Resource Cleanup

Clean up resources properly:

```typescript
let client;
try {
  client = await connectToDatabase();
  // Use client
} finally {
  if (client) {
    await client.close();
  }
}
```

### 4. Idempotency

Make functions idempotent when possible:

```typescript
// Check if action was already performed
const existing = await supabase
  .from('processed_events')
  .select('id')
  .eq('event_id', eventId)
  .single();

if (existing) {
  return new Response('Already processed', { status: 200 });
}

// Process and mark as complete
await processEvent(eventId);
await supabase
  .from('processed_events')
  .insert({ event_id: eventId });
```

## Troubleshooting

### Function Not Deploying

```bash
# Check function syntax
deno check supabase/functions/function-name/index.ts

# Deploy with verbose output
supabase functions deploy function-name --debug
```

### Function Timing Out

- Increase timeout in function config
- Optimize database queries
- Use background jobs for long tasks
- Implement pagination

### Memory Issues

- Stream large responses
- Process data in chunks
- Clean up variables
- Use efficient data structures

### Cold Start Issues

- Keep functions warm with scheduled pings
- Minimize dependencies
- Use lightweight libraries
- Cache connections when possible

## Migration Guide

### From Vercel Functions

```typescript
// Vercel function
export default async function handler(req, res) {
  res.status(200).json({ data });
}

// Supabase Edge Function
serve(async (req) => {
  return new Response(
    JSON.stringify({ data }),
    { 
      status: 200,
      headers: { 'Content-Type': 'application/json' },
    }
  );
});
```

### From Netlify Functions

```typescript
// Netlify function
exports.handler = async (event, context) => {
  return {
    statusCode: 200,
    body: JSON.stringify({ data }),
  };
};

// Supabase Edge Function
serve(async (req) => {
  return new Response(
    JSON.stringify({ data }),
    { status: 200 }
  );
});
```

## Resources

- [Supabase Edge Functions Docs](https://supabase.com/docs/guides/functions)
- [Deno Deploy Documentation](https://deno.com/deploy/docs)
- [Example Functions](https://github.com/supabase/supabase/tree/master/examples/edge-functions)
- [Function Templates](https://github.com/supabase-community/functions)

---

**Last Updated**: August 2025  
**Version**: 1.0.0