// Test Edge Function directly
const SUPABASE_URL = 'https://gvcswimqaxvylgxbklbz.supabase.co';
const SUPABASE_ANON_KEY = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imd2Y3N3aW1xYXh2eWxneGJrbGJ6Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3MzAzNDE3NDEsImV4cCI6MjA0NTkxNzc0MX0.qfJLSmFdMLulgyuv1r8RfC8_IQcnmcDcrVqpGqQh4pw';

async function testEdgeFunction() {
  try {
    console.log('Testing Edge Function...');
    
    const response = await fetch(`${SUPABASE_URL}/functions/v1/sync-stripe-product`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Authorization': `Bearer ${SUPABASE_ANON_KEY}`,
        'Origin': 'https://super-admin-ptucakswa-ibrahimayads-projects.vercel.app'
      },
      body: JSON.stringify({ test: true })
    });

    console.log('Response status:', response.status);
    console.log('Response headers:', Object.fromEntries(response.headers.entries()));
    
    const data = await response.text();
    console.log('Response data:', data);
    
    if (response.ok) {
      console.log('✅ Edge Function is working!');
    } else {
      console.log('❌ Edge Function failed');
    }
  } catch (error) {
    console.error('Error testing Edge Function:', error);
  }
}

testEdgeFunction();