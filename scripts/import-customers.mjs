/**
 * ENHANCED CUSTOMER IMPORT SCRIPT (ES Module Version)
 * Run with: node scripts/import-customers.mjs
 */

import fs from 'fs';
import { parse } from 'csv-parse';
import { createClient } from '@supabase/supabase-js';
import dotenv from 'dotenv';

// Load environment variables
dotenv.config();

// Use hardcoded values as fallback if env not available
const supabaseUrl = process.env.VITE_SUPABASE_URL || 'https://gvcswimqaxvylgxbklbz.supabase.co';
const supabaseServiceKey = process.env.SUPABASE_SERVICE_ROLE_KEY || process.env.VITE_SUPABASE_ANON_KEY || 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imd2Y3N3aW1xYXh2eWxneGJrbGJ6Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTM3NjA1MzAsImV4cCI6MjA2OTMzNjUzMH0.UZdiGcJXUV5VYetjWXV26inmbj2yXdiT03Z6t_5Lg24';

console.log('Connecting to Supabase...');
const supabase = createClient(supabaseUrl, supabaseServiceKey);

// Parse date strings
function parseDate(dateStr) {
  if (!dateStr || dateStr === 'NaT' || dateStr === '') return null;
  try {
    const date = new Date(dateStr);
    return isNaN(date.getTime()) ? null : date.toISOString().split('T')[0];
  } catch {
    return null;
  }
}

// Build address JSON from CSV fields
function buildAddress(record) {
  const address = {
    line1: record['Default Address Address1'] || record['Address Line 1'] || null,
    line2: record['Default Address Address2'] || null,
    city: record['Default Address City'] || record['City'] || null,
    state: record['Default Address Province Code'] || record['State Code'] || null,
    postal_code: record['Default Address Zip'] || record['Zip Code'] || null,
    country: record['Default Address Country Code'] || 'US',
    company: record['Default Address Company'] || null,
    phone: record['Default Address Phone'] || null
  };

  // Remove null values
  Object.keys(address).forEach(key => {
    if (!address[key]) delete address[key];
  });

  return Object.keys(address).length > 0 ? address : null;
}

// Main import function
async function importCustomers() {
  const csvFile = './enhanced_customers_menswear.csv';
  
  if (!fs.existsSync(csvFile)) {
    console.error(`CSV file not found: ${csvFile}`);
    return;
  }
  
  const fileContent = fs.readFileSync(csvFile, 'utf-8');
  
  const records = await new Promise((resolve, reject) => {
    parse(fileContent, {
      columns: true,
      skip_empty_lines: true,
      trim: true
    }, (err, records) => {
      if (err) reject(err);
      else resolve(records);
    });
  });

  console.log(`Found ${records.length} customers to import`);
  
  let successCount = 0;
  let errorCount = 0;
  let updateCount = 0;
  let skipCount = 0;

  // Process in batches to avoid overwhelming the database
  const batchSize = 10;
  for (let i = 0; i < records.length; i += batchSize) {
    const batch = records.slice(i, Math.min(i + batchSize, records.length));
    
    await Promise.all(batch.map(async (record) => {
      try {
        // Skip if no email
        if (!record['Email']) {
          skipCount++;
          return;
        }

        // Build full name from first and last names
        const firstName = record['First Name']?.trim() || '';
        const lastName = record['Last Name']?.trim() || '';
        const fullName = `${firstName} ${lastName}`.trim() || null;
        
        // Clean and transform the data
        const customerData = {
          email: record['Email']?.toLowerCase().trim(),
          first_name: firstName || null,
          last_name: lastName || null,
          name: fullName,
          phone: record['Phone']?.replace(/[^\d+]/g, '') || null,
          accepts_email_marketing: record['Accepts Email Marketing'] === 'yes',
          accepts_sms_marketing: record['Accepts SMS Marketing'] === 'yes',
          total_spent: parseFloat(record['total_spent']) || 0,
          total_orders: parseInt(record['total_orders']) || 0,
          customer_tier: record['customer_tier'] || 'Bronze',
          engagement_score: parseInt(record['engagement_score']) || 0,
          average_order_value: parseFloat(record['average_order_value']) || 0,
          repeat_customer: record['repeat_customer'] === 'yes',
          vip_status: record['vip_status'] === 'yes',
          primary_occasion: record['primary_occasion'] || 'general',
          first_purchase_date: parseDate(record['first_purchase_date']),
          last_purchase_date: parseDate(record['last_purchase_date']),
          days_since_last_purchase: parseInt(record['days_since_last_purchase']) || null,
          notes: record['Note'] || null,
          tags: record['Tags'] || null,
          shipping_address: buildAddress(record),
          updated_at: new Date().toISOString()
        };

        // Check if customer exists
        const { data: existingCustomers } = await supabase
          .from('customers')
          .select('id')
          .eq('email', customerData.email);

        if (existingCustomers && existingCustomers.length > 0) {
          // Update existing customer
          const { error: updateError } = await supabase
            .from('customers')
            .update(customerData)
            .eq('id', existingCustomers[0].id);

          if (updateError) throw updateError;
          updateCount++;
          console.log(`✅ Updated: ${customerData.email}`);
        } else {
          // Insert new customer
          customerData.created_at = new Date().toISOString();
          
          const { error: insertError } = await supabase
            .from('customers')
            .insert(customerData);

          if (insertError) throw insertError;
          successCount++;
          console.log(`✨ Imported: ${customerData.email}`);
        }

      } catch (error) {
        console.error(`❌ Error processing ${record['Email']}:`, error.message);
        errorCount++;
      }
    }));
    
    // Progress update
    console.log(`Progress: ${Math.min(i + batchSize, records.length)}/${records.length}`);
  }

  console.log('\n=== Import Summary ===');
  console.log(`✨ New customers imported: ${successCount}`);
  console.log(`✅ Existing customers updated: ${updateCount}`);
  console.log(`⏭️  Skipped (no email): ${skipCount}`);
  console.log(`❌ Errors: ${errorCount}`);
  console.log(`📊 Total processed: ${records.length}`);
}

// Run the import
console.log('Starting customer import...');
importCustomers().catch(console.error);