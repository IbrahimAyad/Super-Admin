// Test Stripe Configuration
const stripeKey = process.env.NEXT_PUBLIC_STRIPE_PUBLISHABLE_KEY || process.env.VITE_STRIPE_PUBLISHABLE_KEY;

console.log('Testing Stripe Configuration...');
console.log('=====================================');

if (!stripeKey) {
  console.error('❌ No Stripe publishable key found in environment variables');
  process.exit(1);
}

// Check if it's a live key
if (stripeKey.startsWith('pk_live_')) {
  console.log('✅ Using LIVE Stripe key');
  console.log(`   Account ID: ${stripeKey.substring(8, 15)}...`);
} else if (stripeKey.startsWith('pk_test_')) {
  console.log('⚠️  Using TEST Stripe key');
  console.log(`   Account ID: ${stripeKey.substring(8, 15)}...`);
} else {
  console.error('❌ Invalid Stripe key format');
  process.exit(1);
}

console.log('=====================================');
console.log('Configuration looks good!');
console.log('');
console.log('Next steps:');
console.log('1. Run the database fix script in Supabase SQL Editor');
console.log('2. Configure CORS in Cloudflare R2 dashboard');
console.log('3. Test the checkout flow on the website');
console.log('4. Configure Resend email service when domain is verified');