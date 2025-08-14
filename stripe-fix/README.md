# Stripe Integration Fix - Step by Step Guide

## Current Status: STEP 2 - Create Missing Stripe Prices

## File Locations
All files are in `/Users/ibrahim/Desktop/Super-Admin/stripe-fix/`

- `step1-clear-imports.sql` - Clear August imports (COMPLETED)
- `step2-create-prices.js` - Create missing Stripe prices (CURRENT STEP)
- `step3-map-products.sql` - Map all products to Stripe prices
- `step4-verify.sql` - Verify everything works
- `step5-add-new-products.sql` - Add socks, belts, pants, etc.

## Step-by-Step Instructions

### ✅ Step 1: Clear August Imports (COMPLETED)
```bash
psql $DATABASE_URL < stripe-fix/step1-clear-imports.sql
```

### 🔄 Step 2: Create Missing Stripe Prices (YOU ARE HERE)
```bash
# First, set your Stripe secret key
export STRIPE_SECRET_KEY="sk_live_YOUR_KEY_HERE"

# Then run the script
node stripe-fix/step2-create-prices.js

# Save the output price IDs!
```

### Step 3: Map Products to Stripe Prices
```bash
# After getting price IDs from step 2, run:
psql $DATABASE_URL < stripe-fix/step3-map-products.sql
```

### Step 4: Verify Everything
```bash
psql $DATABASE_URL < stripe-fix/step4-verify.sql
```

### Step 5: Add New Products
```bash
psql $DATABASE_URL < stripe-fix/step5-add-new-products.sql
```

## Quick Commands to Run

```bash
# From /Users/ibrahim/Desktop/Super-Admin/ directory:

# Current step - Create Stripe prices:
export STRIPE_SECRET_KEY="sk_live_YOUR_KEY"
node stripe-fix/step2-create-prices.js

# Next step - Map products:
psql $DATABASE_URL < stripe-fix/step3-map-products.sql
```

## What Each Step Does

1. **step1** - Clears stripe IDs from August imports only (preserves July core products)
2. **step2** - Creates 12 new Stripe prices we need ($10, $15, $29.99, etc.)
3. **step3** - Maps ALL products to correct Stripe prices based on your pricing
4. **step4** - Checks that everything is mapped correctly
5. **step5** - Adds new products (socks, belts, pants, tie clips, cufflinks)

## Important Price IDs (Already in Stripe)
- $24.99 → `price_1RpvHlCHc12x7sCzp0TVNS92` (Ties)
- $39.99 → `price_1RpvWnCHc12x7sCzzioA64qD` (Shirts)
- $179.99 → `price_1Rpv2tCHc12x7sCzVvLRto3m` (2-piece suit)
- $229.99 → `price_1Rpv31CHc12x7sCzlFtlUflr` (3-piece suit)

## Prices We're Creating (Step 2)
- $10.00 - Socks, Pocket squares
- $15.00 - Tie clips
- $29.99 - Belts
- $44.99 - Turtlenecks
- $49.99 - Vests, Suspenders
- $59.99 - Dress pants
- $69.99 - Tuxedo/Satin pants
- $79.99 - Loafers
- $89.99 - Dress shoes
- $129.99 - Premium sweaters
- $329.99 - Ultra premium suits
- $349.99 - Exclusive suits