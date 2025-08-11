/**
 * ENHANCED CUSTOMER IMPORT SCRIPT
 * Imports the enhanced_customers_menswear.csv into the database
 * Run with: node scripts/import-enhanced-customers.js
 */

const fs = require('fs');
const csv = require('csv-parse');
const { createClient } = require('@supabase/supabase-js');

// Initialize Supabase client
const supabaseUrl = process.env.VITE_SUPABASE_URL;
const supabaseServiceKey = process.env.SUPABASE_SERVICE_ROLE_KEY;
const supabase = createClient(supabaseUrl, supabaseServiceKey);

// Parse CSV and import customers
async function importCustomers() {
  const csvFile = './enhanced_customers_menswear.csv';
  const fileContent = fs.readFileSync(csvFile, 'utf-8');
  
  const records = await new Promise((resolve, reject) => {
    csv.parse(fileContent, {
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

  for (const record of records) {
    try {
      // Clean and transform the data
      const customerData = {
        email: record['Email']?.toLowerCase().trim(),
        first_name: record['First Name']?.trim() || null,
        last_name: record['Last Name']?.trim() || null,
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
        created_at: new Date().toISOString(),
        updated_at: new Date().toISOString()
      };

      // Check if customer exists
      const { data: existingCustomer, error: checkError } = await supabase
        .from('customers')
        .select('id')
        .eq('email', customerData.email)
        .single();

      if (existingCustomer) {
        // Update existing customer (exclude fields that might not exist)
        const updateData = { ...customerData };
        // Add name field from first_name and last_name
        if (!updateData.name && (updateData.first_name || updateData.last_name)) {
          updateData.name = `${updateData.first_name || ''} ${updateData.last_name || ''}`.trim();
        }
        
        const { error: updateError } = await supabase
          .from('customers')
          .update(updateData)
          .eq('id', existingCustomer.id);

        if (updateError) throw updateError;
        updateCount++;
        console.log(`Updated: ${customerData.email}`);
      } else {
        // Insert new customer
        // Add name field from first_name and last_name if not present
        const insertData = { ...customerData };
        if (!insertData.name && (insertData.first_name || insertData.last_name)) {
          insertData.name = `${insertData.first_name || ''} ${insertData.last_name || ''}`.trim();
        }
        
        const { data: newCustomer, error: insertError } = await supabase
          .from('customers')
          .insert(insertData)
          .select()
          .single();

        if (insertError) throw insertError;
        successCount++;
        console.log(`Imported: ${customerData.email}`);

        // Also create/update user_profile with size data
        await updateUserProfile(newCustomer.id, customerData.email, record);
      }

    } catch (error) {
      console.error(`Error processing ${record['Email']}:`, error.message);
      errorCount++;
    }
  }

  console.log('\n=== Import Summary ===');
  console.log(`✅ New customers imported: ${successCount}`);
  console.log(`🔄 Existing customers updated: ${updateCount}`);
  console.log(`❌ Errors: ${errorCount}`);
  console.log(`📊 Total processed: ${records.length}`);
}

// Update user_profiles table with size information
async function updateUserProfile(customerId, email, record) {
  const sizeProfile = {
    jacket_size: record['jacket_size'] || null,
    jacket_size_confidence: parseFloat(record['jacket_size_confidence']) || 0,
    vest_size: record['vest_size'] || null,
    vest_size_confidence: parseFloat(record['vest_size_confidence']) || 0,
    shirt_size: record['shirt_size'] || null,
    shirt_size_confidence: parseFloat(record['shirt_size_confidence']) || 0,
    shoe_size: record['shoe_size'] || null,
    shoe_size_confidence: parseFloat(record['shoe_size_confidence']) || 0,
    pants_size: record['pants_size'] || null,
    pants_size_confidence: parseFloat(record['pants_size_confidence']) || 0,
    size_profile_completeness: parseFloat(record['size_profile_completeness']) || 0
  };

  // Remove null/empty values
  Object.keys(sizeProfile).forEach(key => {
    if (!sizeProfile[key] || sizeProfile[key] === '0.0' || sizeProfile[key] === 0) {
      delete sizeProfile[key];
    }
  });

  if (Object.keys(sizeProfile).length > 0) {
    const { error } = await supabase
      .from('user_profiles')
      .upsert({
        id: customerId,
        email: email,
        full_name: `${record['First Name'] || ''} ${record['Last Name'] || ''}`.trim(),
        size_profile: sizeProfile,
        updated_at: new Date().toISOString()
      });

    if (error) {
      console.error(`Failed to update user_profile for ${email}:`, error.message);
    }
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

// Parse date strings
function parseDate(dateStr) {
  if (!dateStr || dateStr === 'NaT') return null;
  try {
    const date = new Date(dateStr);
    return isNaN(date.getTime()) ? null : date.toISOString().split('T')[0];
  } catch {
    return null;
  }
}

// Run the import
importCustomers().catch(console.error);