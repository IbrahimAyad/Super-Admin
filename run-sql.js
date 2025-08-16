import { createClient } from '@supabase/supabase-js';
import { readFileSync } from 'fs';

const supabaseUrl = 'https://gvcswimqaxvylgxbklbz.supabase.co';
const supabaseServiceKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imd2Y3N3aW1xYXh2eWxneGJrbGJ6Iiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc1Mzc2MDUzMCwiZXhwIjoyMDY5MzM2NTMwfQ.BhEBfJL7cRqzJ_qRK23HhtI5YFJx7MJgJUWJPZbR6N8';

const supabase = createClient(supabaseUrl, supabaseServiceKey);

async function runSQL() {
  try {
    const sql = readFileSync('./setup-enhanced-columns.sql', 'utf8');
    console.log('Running SQL to add enhanced columns...');
    
    const { data, error } = await supabase.rpc('exec_sql', { 
      sql_text: sql 
    });
    
    if (error) {
      console.error('❌ SQL Error:', error);
    } else {
      console.log('✅ SQL executed successfully:', data);
    }
  } catch (error) {
    console.error('❌ Error:', error.message);
  }
}

runSQL();