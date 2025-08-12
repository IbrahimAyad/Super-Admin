#\!/bin/bash

# Deploy Edge Functions to Supabase
# Usage: ./deploy-edge-functions.sh

echo "🚀 Starting Edge Functions deployment..."

# Check if supabase CLI is installed
if \! command -v supabase &> /dev/null; then
    echo "❌ Supabase CLI not found. Please install it first:"
    echo "   brew install supabase/tap/supabase"
    exit 1
fi

# Check if logged in
if \! supabase projects list &> /dev/null; then
    echo "📝 Please login to Supabase:"
    supabase login
fi

# Deploy critical functions
echo ""
echo "📦 Deploying secure checkout functions..."
supabase functions deploy create-checkout-secure
supabase functions deploy stripe-webhook-secure

echo ""
echo "📧 Deploying email functions..."
supabase functions deploy send-order-confirmation-secure
supabase functions deploy send-verification-email
supabase functions deploy send-password-reset-secure
supabase functions deploy email-service-secure

echo ""
echo "🛍️ Deploying order processing functions..."
supabase functions deploy process-refund
supabase functions deploy get-order

echo ""
echo "📊 Deploying product functions..."
supabase functions deploy get-products-secure
supabase functions deploy sync-stripe-products

echo ""
echo "✅ Deployment complete\!"
echo ""
echo "Next steps:"
echo "1. Set your secrets using: supabase secrets set KEY=value"
echo "2. Configure Stripe webhook in Stripe Dashboard"
echo "3. Run database migrations"
echo "4. Test the functions"
echo ""
echo "To view logs: supabase functions logs FUNCTION_NAME"
