import { createClient } from '@supabase/supabase-js';

const supabaseUrl = 'https://gvcswimqaxvylgxbklbz.supabase.co';
const supabaseKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imd2Y3N3aW1xYXh2eWxneGJrbGJ6Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTM3NjA1MzAsImV4cCI6MjA2OTMzNjUzMH0.UZdiGcJXUV5VYetjWXV26inmbj2yXdiT03Z6t_5Lg24';

const supabase = createClient(supabaseUrl, supabaseKey);

async function checkSuits() {
  const { data, error } = await supabase
    .from('products')
    .select('sku, name, category')
    .or('category.eq.Men\'s Suits,name.ilike.%suit%')
    .order('sku');

  if (error) {
    console.error('Error:', error);
    return;
  }

  console.log('Existing suits in database:');
  if (data && data.length > 0) {
    data.forEach(p => console.log(`- ${p.sku}: ${p.name} (${p.category})`));
    console.log(`\nTotal suits found: ${data.length}`);
  } else {
    console.log('No suits found in database');
  }
}

checkSuits();