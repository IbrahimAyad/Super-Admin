# Edge Function Deployment Guide

## Required Edge Functions

The admin panel requires these Edge Functions to be deployed to Supabase:

### 1. sync-stripe-product
**Location**: `supabase/functions/sync-stripe-product/`
**Purpose**: Syncs products from Supabase to Stripe
**Required Environment Variables**:
- `STRIPE_SECRET_KEY` - Your Stripe secret key (sk_live_...)
- `SUPABASE_URL` - Auto-set by Supabase
- `SUPABASE_SERVICE_ROLE_KEY` - Auto-set by Supabase

### 2. create-checkout
**Location**: `supabase/functions/create-checkout/`
**Purpose**: Creates Stripe checkout sessions
**Required Environment Variables**:
- `STRIPE_SECRET_KEY` - Your Stripe secret key (sk_live_...)
- `SUPABASE_URL` - Auto-set by Supabase
- `SUPABASE_SERVICE_ROLE_KEY` - Auto-set by Supabase

## Deployment Steps

### Step 1: Install Supabase CLI
```bash
npm install -g supabase
```

### Step 2: Link to your project
```bash
supabase link --project-ref gvcswimqaxvylgxbklbz
```

### Step 3: Set Environment Variables in Supabase Dashboard

1. Go to https://supabase.com/dashboard/project/gvcswimqaxvylgxbklbz/settings/functions
2. Add the following secrets:
   - `STRIPE_SECRET_KEY` = Your Stripe secret key (starts with `sk_live_...`)

### Step 4: Deploy Edge Functions
```bash
# Deploy sync-stripe-product function
supabase functions deploy sync-stripe-product

# Deploy create-checkout function
supabase functions deploy create-checkout
```

### Step 5: Verify Deployment
```bash
# List deployed functions
supabase functions list

# Test sync-stripe-product
curl -X POST https://gvcswimqaxvylgxbklbz.supabase.co/functions/v1/sync-stripe-product \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer YOUR_ANON_KEY" \
  -d '{"test": true}'

# Test create-checkout
curl -X POST https://gvcswimqaxvylgxbklbz.supabase.co/functions/v1/create-checkout \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer YOUR_ANON_KEY" \
  -d '{"test": true}'
```

## Troubleshooting

### Error: "Edge Function not ready"
- Ensure the function is deployed: `supabase functions list`
- Check function logs: `supabase functions logs sync-stripe-product`
- Verify environment variables are set in Supabase dashboard

### Error: "Missing required environment variables"
- Go to Supabase dashboard → Settings → Edge Functions → Secrets
- Add `STRIPE_SECRET_KEY` with your Stripe secret key

### Error: "CORS error"
- The functions already include CORS headers
- Ensure you're using the correct Supabase URL

## Testing in Admin Panel

1. Navigate to Admin Panel → Integrations → Stripe Sync
2. Click "Validate Configuration"
3. If validation passes, click "Start Sync" (use Dry Run first)
4. Monitor progress in the UI

## Important Notes

- **Never commit** the `STRIPE_SECRET_KEY` to git
- Edge Functions automatically have access to `SUPABASE_URL` and `SUPABASE_SERVICE_ROLE_KEY`
- Functions are serverless and scale automatically
- Check function logs for debugging: `supabase functions logs [function-name]`