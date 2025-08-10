#!/bin/bash

# Set Supabase Edge Function Secrets
# IMPORTANT: Replace these with your actual keys!

echo "🔐 Setting up Supabase Edge Function Secrets"
echo "============================================"

# Get your Stripe secret key from .env
STRIPE_KEY=$(grep "STRIPE_SECRET_KEY" .env | cut -d '=' -f2)

if [ -z "$STRIPE_KEY" ]; then
    echo "Enter your Stripe Secret Key (starts with sk_):"
    read -s STRIPE_KEY
fi

echo ""
echo "Setting secrets..."

# Set Stripe secret key
supabase secrets set STRIPE_SECRET_KEY=$STRIPE_KEY

# Set Stripe webhook secret (you'll get this from Stripe Dashboard after creating webhook)
echo "Enter your Stripe Webhook Secret (starts with whsec_):"
echo "(Get this from Stripe Dashboard > Developers > Webhooks)"
read -s WEBHOOK_SECRET
supabase secrets set STRIPE_WEBHOOK_SECRET=$WEBHOOK_SECRET

# Set email service key (optional - for email functions)
echo ""
echo "Do you have a Resend API key for emails? (y/n)"
read HAS_RESEND
if [ "$HAS_RESEND" = "y" ]; then
    echo "Enter your Resend API Key:"
    read -s RESEND_KEY
    supabase secrets set RESEND_API_KEY=$RESEND_KEY
fi

# Set service role key (from Supabase dashboard)
echo ""
echo "Enter your Supabase Service Role Key:"
echo "(Get this from Supabase Dashboard > Settings > API)"
read -s SERVICE_ROLE_KEY
supabase secrets set SUPABASE_SERVICE_ROLE_KEY=$SERVICE_ROLE_KEY

echo ""
echo "✅ Secrets configured!"
echo ""
echo "📝 Next: Configure Stripe Webhook"
echo "1. Go to: https://dashboard.stripe.com/webhooks"
echo "2. Click 'Add endpoint'"
echo "3. Enter URL: https://gvcswimqaxvylgxbklbz.supabase.co/functions/v1/stripe-webhook-secure"
echo "4. Select events:"
echo "   - checkout.session.completed"
echo "   - payment_intent.succeeded"
echo "   - payment_intent.failed"
echo "   - customer.created"
echo "5. Copy the webhook secret and run this script again to set it"