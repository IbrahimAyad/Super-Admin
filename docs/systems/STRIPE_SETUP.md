# Stripe Configuration for Financial Management

## Required Stripe Setup

### 1. Get Your Stripe API Keys
1. Go to [Stripe Dashboard](https://dashboard.stripe.com/apikeys)
2. Copy your **Publishable key** (starts with `pk_test_` or `pk_live_`)
3. Copy your **Secret key** (starts with `sk_test_` or `sk_live_`)

### 2. Configure Frontend (Public Key)
Add to your `.env` file:
```bash
VITE_STRIPE_PUBLISHABLE_KEY=pk_test_your-actual-key-here
```

### 3. Configure Backend (Secret Key) 
**IMPORTANT**: Never put the secret key in frontend code!

For Supabase Edge Functions, add the secret key via Supabase CLI:
```bash
supabase secrets set STRIPE_SECRET_KEY=sk_test_your-actual-key-here
```

Or via Supabase Dashboard:
1. Go to your project settings
2. Navigate to Edge Functions → Secrets
3. Add `STRIPE_SECRET_KEY` with your secret key value

### 4. Required Stripe Webhooks
Set up these webhook endpoints in Stripe Dashboard:

1. **Payment Intent Webhook**
   - URL: `https://your-project.supabase.co/functions/v1/stripe-webhook`
   - Events: `payment_intent.succeeded`, `payment_intent.payment_failed`

2. **Refund Webhook**
   - URL: `https://your-project.supabase.co/functions/v1/stripe-refund-webhook`
   - Events: `charge.refunded`, `charge.refund.updated`

### 5. Test Your Configuration
```javascript
// Test in browser console (after setting VITE_STRIPE_PUBLISHABLE_KEY)
console.log('Stripe key configured:', import.meta.env.VITE_STRIPE_PUBLISHABLE_KEY?.startsWith('pk_'));
```

### 6. Production Checklist
- [ ] Replace test keys with live keys
- [ ] Update webhook URLs to production domain
- [ ] Enable webhook signature verification
- [ ] Set up proper error monitoring
- [ ] Configure payment method types (cards, wallets, etc.)
- [ ] Set up fraud detection rules

## Integration with Financial Management

The Financial Management system uses Stripe for:
- **Refund Processing**: `financialService.ts` processes refunds via Stripe API
- **Payment Tracking**: Links Stripe payment intents to orders
- **Transaction Fees**: Tracks Stripe processing fees
- **Reconciliation**: Matches Stripe payouts with internal records

## Troubleshooting

### Common Issues:
1. **"Stripe is not defined"**: Ensure Stripe.js is loaded
2. **401 Unauthorized**: Check your API keys
3. **Webhook failures**: Verify endpoint URLs and event types
4. **Refund failures**: Ensure payment intent exists and is refundable

### Support Resources:
- [Stripe Documentation](https://stripe.com/docs)
- [Stripe API Reference](https://stripe.com/docs/api)
- [Test Card Numbers](https://stripe.com/docs/testing)