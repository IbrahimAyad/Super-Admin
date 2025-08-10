#!/bin/bash

# Deploy Edge Functions to Supabase
# Run this script to deploy all Edge Functions

echo "🚀 Deploying Edge Functions to Supabase"
echo "========================================"

# Check if Supabase CLI is installed
if ! command -v supabase &> /dev/null; then
    echo "❌ Supabase CLI is not installed"
    echo "Install it with: brew install supabase/tap/supabase"
    exit 1
fi

# Check if we're in the right directory
if [ ! -d "supabase/functions" ]; then
    echo "❌ Not in project root directory"
    echo "Please run this script from your project root"
    exit 1
fi

# Login to Supabase (if not already logged in)
echo "📝 Checking Supabase authentication..."
supabase projects list &> /dev/null
if [ $? -ne 0 ]; then
    echo "Please log in to Supabase:"
    supabase login
fi

# Link to your project (if not already linked)
if [ ! -f "supabase/.temp/project-ref" ]; then
    echo "🔗 Linking to your Supabase project..."
    echo "Enter your project ref (from Supabase dashboard):"
    read PROJECT_REF
    supabase link --project-ref $PROJECT_REF
fi

# Deploy functions
echo ""
echo "📦 Deploying Edge Functions..."
echo "------------------------------"

# Priority functions to deploy first
PRIORITY_FUNCTIONS=(
    "stripe-webhook-secure"
    "create-checkout-secure"
    "sync-stripe-products"
    "send-order-confirmation-secure"
    "email-service"
)

# Deploy priority functions
for func in "${PRIORITY_FUNCTIONS[@]}"; do
    if [ -d "supabase/functions/$func" ]; then
        echo "Deploying $func..."
        supabase functions deploy $func --no-verify-jwt
        if [ $? -eq 0 ]; then
            echo "✅ $func deployed successfully"
        else
            echo "❌ Failed to deploy $func"
        fi
        echo ""
    fi
done

# Deploy all other functions
echo "Deploying remaining functions..."
supabase functions deploy --no-verify-jwt

echo ""
echo "🔑 Setting up secrets..."
echo "------------------------"
echo "You need to set these secrets in Supabase Dashboard:"
echo ""
echo "1. Go to: https://app.supabase.com/project/YOUR_PROJECT/settings/vault"
echo "2. Add these secrets:"
echo "   - STRIPE_SECRET_KEY (your Stripe secret key)"
echo "   - STRIPE_WEBHOOK_SECRET (from Stripe webhook settings)"
echo "   - RESEND_API_KEY or SENDGRID_API_KEY (for emails)"
echo "   - SUPABASE_SERVICE_ROLE_KEY (your service role key)"
echo ""
echo "Or run these commands:"
echo "supabase secrets set STRIPE_SECRET_KEY=sk_live_xxx"
echo "supabase secrets set STRIPE_WEBHOOK_SECRET=whsec_xxx"
echo "supabase secrets set RESEND_API_KEY=re_xxx"
echo ""

echo "✅ Deployment complete!"
echo ""
echo "📝 Next steps:"
echo "1. Set up secrets in Supabase Dashboard"
echo "2. Configure Stripe webhook endpoint:"
echo "   - Go to Stripe Dashboard > Developers > Webhooks"
echo "   - Add endpoint: https://YOUR_PROJECT.supabase.co/functions/v1/stripe-webhook-secure"
echo "   - Select events to listen for"
echo "3. Test the functions"