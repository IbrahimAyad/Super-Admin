# Stripe Webhook Setup Guide

## 🚨 CRITICAL: Set This Up Before Going Live!

Without webhooks, your system won't:
- Update order status after payment
- Track inventory after purchases
- Send order confirmation emails
- Handle refunds or disputes

## Step 1: Get Your Webhook Endpoint URL

Your webhook endpoint is:
```
https://gvcswimqaxvylgxbklbz.supabase.co/functions/v1/stripe-webhook-secure
```

## Step 2: Configure in Stripe Dashboard

1. Go to [Stripe Dashboard](https://dashboard.stripe.com/webhooks)
2. Click **"Add endpoint"**
3. Enter the endpoint URL above
4. Select these events to listen to:
   - ✅ `checkout.session.completed`
   - ✅ `payment_intent.succeeded`
   - ✅ `payment_intent.payment_failed`
   - ✅ `customer.created`
   - ✅ `charge.dispute.created`

## Step 3: Get Your Webhook Secret

After creating the endpoint:
1. Click on the webhook endpoint you just created
2. Click **"Reveal"** under Signing secret
3. Copy the secret (starts with `whsec_`)

## Step 4: Set Environment Variables in Supabase

```bash
# Go to Supabase Dashboard > Edge Functions > Secrets
# Add these secrets:

STRIPE_SECRET_KEY=sk_live_YOUR_LIVE_KEY
STRIPE_WEBHOOK_SECRET=whsec_YOUR_WEBHOOK_SECRET
```

Or via CLI:
```bash
supabase secrets set STRIPE_SECRET_KEY="sk_live_YOUR_LIVE_KEY"
supabase secrets set STRIPE_WEBHOOK_SECRET="whsec_YOUR_WEBHOOK_SECRET"
```

## Step 5: Deploy the Webhook Function

The webhook function is already created, just deploy it:

```bash
# Deploy the webhook function
supabase functions deploy stripe-webhook-secure
```

## Step 6: Test the Webhook

### Option A: Use Stripe CLI (Recommended)
```bash
# Install Stripe CLI
brew install stripe/stripe-cli/stripe

# Login to Stripe
stripe login

# Forward webhooks to local endpoint for testing
stripe listen --forward-to https://gvcswimqaxvylgxbklbz.supabase.co/functions/v1/stripe-webhook-secure

# In another terminal, trigger a test event
stripe trigger checkout.session.completed
```

### Option B: Use Stripe Dashboard
1. Go to your webhook endpoint in Stripe Dashboard
2. Click **"Send test webhook"**
3. Select `checkout.session.completed`
4. Click **"Send test webhook"**

## Step 7: Verify Webhook is Working

Check if webhooks are being received:

```sql
-- Run in Supabase SQL Editor
SELECT 
  webhook_id,
  event_type,
  status,
  processed_at,
  error_message
FROM webhook_logs
ORDER BY created_at DESC
LIMIT 10;
```

## What Each Webhook Does

### `checkout.session.completed`
- Creates order in database
- Updates inventory
- Sends order confirmation email
- Links customer to Stripe

### `payment_intent.succeeded`
- Updates payment status
- Records transaction
- Updates order to "paid"

### `payment_intent.payment_failed`
- Marks order as failed
- Restores inventory
- Sends failure notification

### `customer.created`
- Creates/updates customer profile
- Links Stripe customer ID

### `charge.dispute.created`
- Flags order for review
- Notifies admin
- Pauses fulfillment

## Troubleshooting

### Webhook Returns 401 Unauthorized
- Check `STRIPE_WEBHOOK_SECRET` is set correctly
- Ensure you're using the production webhook secret

### Webhook Returns 400 Bad Request
- Check Stripe API version compatibility
- Verify payload structure

### Orders Not Creating
- Check `orders` table exists
- Verify RLS policies allow insert
- Check Supabase service role key

### Test Mode vs Live Mode
Make sure you're using:
- **Test keys** (`sk_test_`) for development
- **Live keys** (`sk_live_`) for production
- Matching webhook secrets for each mode

## Security Checklist

✅ Webhook secret is set and validated
✅ Using HTTPS endpoint only
✅ Rate limiting is enabled
✅ Replay protection is active
✅ Error messages are sanitized
✅ IP filtering (optional) configured

## Monitor Webhook Health

```sql
-- Check webhook success rate
SELECT 
  DATE(created_at) as date,
  event_type,
  COUNT(*) as total_events,
  COUNT(CASE WHEN status = 'completed' THEN 1 END) as successful,
  COUNT(CASE WHEN status = 'failed' THEN 1 END) as failed,
  ROUND(
    COUNT(CASE WHEN status = 'completed' THEN 1 END)::numeric / 
    COUNT(*)::numeric * 100, 2
  ) as success_rate
FROM webhook_logs
WHERE created_at > NOW() - INTERVAL '7 days'
GROUP BY DATE(created_at), event_type
ORDER BY date DESC, event_type;
```

## Next Steps

After webhooks are working:
1. ✅ Test a real purchase flow
2. ✅ Verify order creation
3. ✅ Check inventory updates
4. ✅ Confirm email sending
5. ✅ Test refund handling

## Important URLs

- **Webhook Endpoint**: `https://gvcswimqaxvylgxbklbz.supabase.co/functions/v1/stripe-webhook-secure`
- **Stripe Dashboard**: https://dashboard.stripe.com/webhooks
- **Supabase Functions**: https://supabase.com/dashboard/project/gvcswimqaxvylgxbklbz/functions
- **Test with**: https://dashboard.stripe.com/test/webhooks