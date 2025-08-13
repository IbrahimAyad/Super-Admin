import { createClient } from '@supabase/supabase-js';
import fs from 'fs';

const supabaseUrl = 'https://gvcswimqaxvylgxbklbz.supabase.co';
const supabaseKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imd2Y3N3aW1xYXh2eWxneGJrbGJ6Iiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc1Mzc2MDUzMCwiZXhwIjoyMDY5MzM2NTMwfQ.WP6fHzd1PGFxaILz3r1O4lNKLqy-WB5Q89Ht3iGzrLM';

const supabase = createClient(supabaseUrl, supabaseKey);

async function runImport() {
  try {
    // Read the SQL file
    const sql = fs.readFileSync('sql/imports/import-products-OPTION-COLUMNS.sql', 'utf8');
    
    console.log('Running product import SQL...');
    
    // Execute the SQL
    const { data, error } = await supabase.rpc('exec_sql', { sql_query: sql });
    
    if (error) {
      // If exec_sql doesn't exist, try direct query
      console.log('Trying alternative method...');
      
      // Split by semicolons and execute major blocks
      const statements = sql.split(/;\s*$/m).filter(s => s.trim());
      
      for (const statement of statements) {
        if (statement.trim().startsWith('--') || !statement.trim()) continue;
        
        // For now, just show what we would execute
        console.log('Would execute:', statement.substring(0, 100) + '...');
      }
      
      console.log('\nTo run this import, you need to execute the SQL file directly in Supabase SQL Editor');
      console.log('Go to: https://supabase.com/dashboard/project/gvcswimqaxvylgxbklbz/sql');
      console.log('And run the contents of sql/imports/import-products-OPTION-COLUMNS.sql');
      
    } else {
      console.log('Import completed successfully!');
      if (data) console.log('Result:', data);
    }
    
  } catch (err) {
    console.error('Error:', err);
  }
}

runImport();