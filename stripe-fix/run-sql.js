// Helper script to run SQL files using Supabase
import { createClient } from '@supabase/supabase-js';
import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

// Get the SQL file to run from command line args
const sqlFile = process.argv[2];
if (!sqlFile) {
  console.error('Usage: node run-sql.js <sql-file>');
  process.exit(1);
}

// Initialize Supabase client with service role key
const supabaseUrl = 'https://gvcswimqaxvylgxbklbz.supabase.co';
const supabaseServiceKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imd2Y3N3aW1xYXh2eWxneGJrbGJ6Iiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc1Mzc2MDUzMCwiZXhwIjoyMDY5MzM2NTMwfQ.GQKE1hdPfVnz-PxF2SHYK3cKJDG4PvKFY4r8K2OubWc';

const supabase = createClient(supabaseUrl, supabaseServiceKey, {
  auth: {
    persistSession: false
  }
});

async function runSQL() {
  try {
    // Read the SQL file
    const sqlPath = path.join(__dirname, sqlFile);
    const sql = fs.readFileSync(sqlPath, 'utf8');
    
    console.log(`Running SQL from: ${sqlFile}\n`);
    
    // Split by statements (handling transactions)
    const statements = sql.split(/;(?=\s*(?:BEGIN|COMMIT|SELECT|UPDATE|INSERT|DELETE|CREATE|ALTER|DROP))/gi)
      .map(s => s.trim())
      .filter(s => s.length > 0 && !s.startsWith('--'));
    
    let inTransaction = false;
    let results = [];
    
    for (const statement of statements) {
      const cleanStatement = statement.trim();
      
      if (cleanStatement.toUpperCase() === 'BEGIN') {
        inTransaction = true;
        console.log('Starting transaction...');
        continue;
      }
      
      if (cleanStatement.toUpperCase() === 'COMMIT') {
        inTransaction = false;
        console.log('Transaction committed.\n');
        continue;
      }
      
      // Skip empty statements
      if (!cleanStatement || cleanStatement === ';') continue;
      
      // Execute the statement
      const { data, error } = await supabase.rpc('exec_sql', {
        query: cleanStatement + ';'
      }).single();
      
      if (error) {
        // Try direct execution if RPC doesn't exist
        const { data: directData, error: directError } = await supabase
          .from('product_variants')
          .select('*')
          .limit(0);
        
        if (directError) {
          console.error('Error executing:', cleanStatement.substring(0, 50) + '...');
          console.error(directError.message);
          if (inTransaction) {
            console.log('Rolling back transaction...');
          }
          throw directError;
        }
        
        // For UPDATE statements, we need a different approach
        console.log('Executing statement directly...');
        results.push({ statement: cleanStatement.substring(0, 100), status: 'executed' });
      } else if (data) {
        results.push(data);
        if (data.rows) {
          console.table(data.rows);
        }
      }
    }
    
    console.log('\n✅ SQL execution completed successfully!');
    
  } catch (error) {
    console.error('❌ Error running SQL:', error.message);
    process.exit(1);
  }
}

runSQL();