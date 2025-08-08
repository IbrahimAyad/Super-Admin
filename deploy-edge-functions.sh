#!/bin/bash

# Quick Edge Function Deployment Script

echo "🚀 Deploying Stripe Edge Functions to Supabase..."
echo ""
echo "This script will deploy the Edge Functions needed for Stripe integration."
echo ""

# Step 1: Login to Supabase
echo "Step 1: Login to Supabase"
echo "========================="
echo "You'll need to authenticate with Supabase."
echo "Running: supabase login"
supabase login

# Step 2: Link to project
echo ""
echo "Step 2: Link to your project"
echo "============================"
echo "Linking to project: gvcswimqaxvylgxbklbz"
supabase link --project-ref gvcswimqaxvylgxbklbz

# Step 3: Deploy sync-stripe-product function
echo ""
echo "Step 3: Deploy sync-stripe-product function"
echo "==========================================="
supabase functions deploy sync-stripe-product

# Step 4: Deploy create-checkout function
echo ""
echo "Step 4: Deploy create-checkout function"
echo "======================================="
supabase functions deploy create-checkout

# Step 5: List deployed functions
echo ""
echo "Step 5: Verify deployment"
echo "========================"
supabase functions list

echo ""
echo "✅ Deployment complete!"
echo ""
echo "Next steps:"
echo "1. Go to https://supabase.com/dashboard/project/gvcswimqaxvylgxbklbz/settings/functions"
echo "2. Add your STRIPE_SECRET_KEY in the Secrets section"
echo "3. Test the Stripe sync in the Admin Panel"