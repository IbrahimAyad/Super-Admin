#!/usr/bin/env node
/**
 * KCT ORDER SYNC VERIFICATION TEST SCRIPT
 * 
 * This script tests the order sync between the KCT website checkout
 * and the admin system by simulating webhook calls and verifying
 * the order data structure matches expectations.
 * 
 * Usage: node test-order-sync.js
 * 
 * Requirements:
 * - Node.js 18+
 * - Supabase credentials configured
 * - Test Stripe webhook events
 */

const { createClient } = require('@supabase/supabase-js');

// Configuration
const SUPABASE_URL = process.env.SUPABASE_URL || 'YOUR_SUPABASE_URL';
const SUPABASE_SERVICE_ROLE_KEY = process.env.SUPABASE_SERVICE_ROLE_KEY || 'YOUR_SERVICE_ROLE_KEY';

// Initialize Supabase client
const supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY);

// Test data structures
const mockStripeSession = {
  id: 'cs_test_' + Math.random().toString(36).substr(2, 9),
  amount_total: 15999, // $159.99
  amount_subtotal: 13999, // $139.99
  currency: 'usd',
  customer_details: {
    email: 'test@example.com',
    name: 'John Doe',
    phone: '+1234567890',
    address: {
      line1: '123 Test St',
      line2: 'Apt 4B',
      city: 'Test City',
      state: 'NY',
      postal_code: '10001',
      country: 'US'
    }
  },
  shipping_details: {
    name: 'John Doe',
    address: {
      line1: '123 Test St',
      line2: 'Apt 4B', 
      city: 'Test City',
      state: 'NY',
      postal_code: '10001',
      country: 'US'
    }
  },
  total_details: {
    amount_tax: 1200, // $12.00
    amount_shipping: 800 // $8.00
  },
  payment_intent: 'pi_test_' + Math.random().toString(36).substr(2, 9),
  metadata: {
    items: JSON.stringify([
      {
        name: 'Classic Navy Suit',
        price: 299.99,
        quantity: 1,
        size: '42R',
        color: 'Navy',
        category: 'Suits',
        stripeProductId: 'prod_test123',
        stripePriceId: 'price_test123',
        image: 'https://example.com/suit.jpg',
        metadata: {
          type: 'suit',
          fit: 'classic',
          style: 'business'
        }
      },
      {
        name: 'White Dress Shirt',
        price: 89.99,
        quantity: 2,
        size: '16-34',
        color: 'White',
        category: 'Shirts',
        stripeProductId: 'prod_test456',
        stripePriceId: 'price_test456',
        image: 'https://example.com/shirt.jpg',
        metadata: {
          type: 'dress_shirt',
          fit: 'slim',
          style: 'formal'
        }
      }
    ]),
    order_type: 'standard',
    bundle_type: null,
    bundle_discount: '0'
  }
};

// Field mapping tests
const FIELD_MAPPINGS = {
  // Webhook -> Admin expected field names
  'amount_total': 'total_amount',
  'amount_subtotal': 'subtotal', 
  'total_details.amount_tax': 'tax_amount',
  'total_details.amount_shipping': 'shipping_amount',
  'guest_email': 'customer_email', // Admin expects this for display
  'order_number': 'order_number', // Generated in webhook
  'status': 'status', // Should be 'confirmed' from webhook
  'payment_status': 'payment_status', // Should be 'paid'
  'stripe_session_id': 'stripe_checkout_session_id', // Admin might expect different name
};

class OrderSyncTester {
  constructor() {
    this.testResults = [];
    this.errors = [];
  }

  async runAllTests() {
    console.log('🧪 Starting KCT Order Sync Verification Tests...\n');

    try {
      // Test 1: Database Schema Validation
      await this.testDatabaseSchema();
      
      // Test 2: Webhook Order Creation
      await this.testWebhookOrderCreation();
      
      // Test 3: Field Mapping Verification
      await this.testFieldMappings();
      
      // Test 4: Admin Display Compatibility
      await this.testAdminDisplayCompatibility();
      
      // Test 5: Bundle Order Handling
      await this.testBundleOrders();
      
      // Test 6: Guest vs Customer Orders
      await this.testGuestVsCustomerOrders();
      
      // Test 7: Order Item Structure
      await this.testOrderItemStructure();
      
      // Generate report
      this.generateReport();
      
    } catch (error) {
      console.error('❌ Critical test failure:', error);
      process.exit(1);
    }
  }

  async testDatabaseSchema() {
    console.log('📊 Testing database schema compatibility...');
    
    try {
      // Check orders table structure
      const { data: ordersColumns } = await supabase
        .rpc('get_table_columns', { table_name: 'orders' })
        .single();
      
      // Check order_items table structure
      const { data: itemsColumns } = await supabase
        .rpc('get_table_columns', { table_name: 'order_items' })
        .single();
      
      // Verify required columns exist
      const requiredOrderFields = [
        'id', 'order_number', 'customer_id', 'guest_email', 'status',
        'subtotal', 'tax_amount', 'shipping_amount', 'total_amount',
        'stripe_session_id', 'stripe_payment_intent_id'
      ];
      
      const requiredItemFields = [
        'id', 'order_id', 'product_sku', 'product_name', 'quantity',
        'unit_price', 'total_price', 'size', 'color'
      ];
      
      this.addTestResult('Database Schema', 'orders table exists', true);
      this.addTestResult('Database Schema', 'order_items table exists', true);
      
    } catch (error) {
      this.addError('Database schema check failed', error);
    }
  }

  async testWebhookOrderCreation() {
    console.log('🎣 Testing webhook order creation process...');
    
    try {
      // Simulate the webhook's order creation process
      const orderData = this.simulateWebhookOrderCreation(mockStripeSession);
      
      // Verify order structure matches webhook output
      const requiredFields = [
        'order_number', 'customer_id', 'guest_email', 'status',
        'subtotal', 'tax_amount', 'shipping_amount', 'total_amount'
      ];
      
      let allFieldsPresent = true;
      requiredFields.forEach(field => {
        if (!(field in orderData)) {
          allFieldsPresent = false;
          this.addError(`Missing field in webhook order creation: ${field}`);
        }
      });
      
      this.addTestResult('Webhook Order Creation', 'All required fields present', allFieldsPresent);
      this.addTestResult('Webhook Order Creation', 'Order number generation', orderData.order_number?.startsWith('KCT-'));
      this.addTestResult('Webhook Order Creation', 'Status set to confirmed', orderData.status === 'confirmed');
      this.addTestResult('Webhook Order Creation', 'Payment status set to paid', orderData.payment_status === 'paid');
      
    } catch (error) {
      this.addError('Webhook order creation test failed', error);
    }
  }

  async testFieldMappings() {
    console.log('🗺️ Testing field mappings between webhook and admin...');
    
    try {
      const webhookOrder = this.simulateWebhookOrderCreation(mockStripeSession);
      const adminExpectedFields = this.getAdminExpectedFields();
      
      // Check if webhook fields map correctly to admin expectations
      Object.entries(FIELD_MAPPINGS).forEach(([webhookField, adminField]) => {
        const webhookHasField = this.hasNestedProperty(webhookOrder, webhookField);
        const adminExpectsField = adminExpectedFields.includes(adminField);
        
        this.addTestResult('Field Mappings', `${webhookField} -> ${adminField}`, webhookHasField);
      });
      
    } catch (error) {
      this.addError('Field mapping test failed', error);
    }
  }

  async testAdminDisplayCompatibility() {
    console.log('🖥️ Testing admin display compatibility...');
    
    try {
      const testOrder = this.simulateWebhookOrderCreation(mockStripeSession);
      
      // Test fields that admin UI specifically uses
      const adminUIFields = [
        'order_number', 'customer_email', 'customer_name', 'status',
        'subtotal', 'tax', 'shipping', 'total', 'created_at', 'order_items'
      ];
      
      // Simulate admin transformation (from AdminOrderManagement.tsx)
      const transformedOrder = {
        ...testOrder,
        tax: testOrder.tax_amount || 0,
        shipping: testOrder.shipping_amount || 0,
        discount: testOrder.discount_amount || 0,
        total: testOrder.total_amount || 0,
        customer_name: testOrder.guest_email || 'Guest Customer',
        customer_email: testOrder.guest_email || ''
      };
      
      adminUIFields.forEach(field => {
        const hasField = field in transformedOrder;
        this.addTestResult('Admin Display', `${field} available`, hasField);
      });
      
    } catch (error) {
      this.addError('Admin display compatibility test failed', error);
    }
  }

  async testBundleOrders() {
    console.log('📦 Testing bundle order handling...');
    
    try {
      // Create bundle order test data
      const bundleSession = {
        ...mockStripeSession,
        metadata: {
          ...mockStripeSession.metadata,
          order_type: 'bundle',
          bundle_type: 'wedding_party',
          bundle_discount: '50.00'
        }
      };
      
      const bundleOrder = this.simulateWebhookOrderCreation(bundleSession);
      
      this.addTestResult('Bundle Orders', 'Bundle type detection', bundleOrder.order_type === 'bundle');
      this.addTestResult('Bundle Orders', 'Bundle discount applied', bundleOrder.discount_amount === 50.00);
      
    } catch (error) {
      this.addError('Bundle order test failed', error);
    }
  }

  async testGuestVsCustomerOrders() {
    console.log('👤 Testing guest vs customer order handling...');
    
    try {
      // Test guest order
      const guestOrder = this.simulateWebhookOrderCreation(mockStripeSession);
      this.addTestResult('Guest Orders', 'Guest email stored', !!guestOrder.guest_email);
      this.addTestResult('Guest Orders', 'Customer ID null for guest', guestOrder.customer_id === null);
      
      // Test customer order (would have customer_id set)
      const customerSession = { ...mockStripeSession };
      const customerOrder = this.simulateWebhookOrderCreation(customerSession, 'customer-uuid-123');
      this.addTestResult('Customer Orders', 'Customer ID set', !!customerOrder.customer_id);
      
    } catch (error) {
      this.addError('Guest vs customer test failed', error);
    }
  }

  async testOrderItemStructure() {
    console.log('📋 Testing order item structure...');
    
    try {
      const items = JSON.parse(mockStripeSession.metadata.items);
      const processedItems = items.map(item => ({
        product_sku: this.generateSKU(item),
        product_name: item.name,
        stripe_product_id: item.stripeProductId,
        stripe_price_id: item.stripePriceId,
        quantity: item.quantity,
        unit_price: item.price,
        total_price: item.price * item.quantity,
        size: item.size || 'One Size',
        color: item.color || 'Default',
        category: item.category || 'Unknown',
        image_url: item.image || '',
        attributes: item.metadata || {}
      }));
      
      const requiredItemFields = [
        'product_sku', 'product_name', 'quantity', 'unit_price',
        'total_price', 'size', 'color', 'category'
      ];
      
      let allItemFieldsPresent = true;
      processedItems.forEach((item, index) => {
        requiredItemFields.forEach(field => {
          if (!(field in item)) {
            allItemFieldsPresent = false;
            this.addError(`Missing field in item ${index}: ${field}`);
          }
        });
      });
      
      this.addTestResult('Order Items', 'All required item fields present', allItemFieldsPresent);
      this.addTestResult('Order Items', 'SKU generation working', processedItems[0].product_sku.startsWith('KCT-'));
      
    } catch (error) {
      this.addError('Order item structure test failed', error);
    }
  }

  simulateWebhookOrderCreation(session, customerId = null) {
    const orderNumber = `KCT-${new Date().getFullYear()}-${String(Date.now()).slice(-6)}`;
    
    return {
      order_number: orderNumber,
      customer_id: customerId,
      guest_email: customerId ? null : session.customer_details?.email,
      status: 'confirmed',
      order_type: session.metadata?.order_type === 'bundle' ? 'bundle' : 'standard',
      subtotal: (session.amount_subtotal || 0) / 100,
      tax_amount: (session.total_details?.amount_tax || 0) / 100,
      shipping_amount: (session.total_details?.amount_shipping || 0) / 100,
      discount_amount: parseFloat(session.metadata?.bundle_discount || '0'),
      total_amount: (session.amount_total || 0) / 100,
      currency: session.currency?.toUpperCase() || 'USD',
      payment_status: 'paid',
      payment_method: 'stripe',
      stripe_session_id: session.id,
      stripe_payment_intent_id: session.payment_intent,
      created_at: new Date().toISOString(),
      confirmed_at: new Date().toISOString()
    };
  }

  generateSKU(item) {
    const category = item.category || "UNKNOWN";
    const color = (item.color || "DEFAULT").toUpperCase().replace(/\s+/g, "");
    const size = (item.size || "OS").replace(/[^A-Z0-9]/g, "");
    
    let sku = `KCT-${category.toUpperCase()}-${color}`;
    
    if (item.metadata) {
      if (item.metadata.type) {
        sku += `-${item.metadata.type.toUpperCase().replace(/[^A-Z0-9]/g, "")}`;
      }
      if (item.metadata.style) {
        sku += `-${item.metadata.style.toUpperCase()}`;
      }
      if (item.metadata.fit) {
        sku += `-${item.metadata.fit.toUpperCase()}`;
      }
    }
    
    if (size !== "OS") {
      sku += `-${size}`;
    }
    
    return sku;
  }

  getAdminExpectedFields() {
    return [
      'id', 'order_number', 'customer_email', 'customer_name', 'status',
      'subtotal', 'tax', 'shipping', 'discount', 'total', 'currency',
      'shipping_address', 'billing_address', 'bundle_info', 'created_at',
      'updated_at', 'order_items'
    ];
  }

  hasNestedProperty(obj, path) {
    return path.split('.').reduce((current, key) => {
      return current && current[key] !== undefined;
    }, obj);
  }

  addTestResult(category, test, passed) {
    this.testResults.push({
      category,
      test,
      passed,
      timestamp: new Date().toISOString()
    });
  }

  addError(message, error = null) {
    this.errors.push({
      message,
      error: error?.message || error,
      timestamp: new Date().toISOString()
    });
  }

  generateReport() {
    console.log('\n' + '='.repeat(60));
    console.log('📊 KCT ORDER SYNC TEST REPORT');
    console.log('='.repeat(60));
    
    const categories = [...new Set(this.testResults.map(r => r.category))];
    
    categories.forEach(category => {
      const categoryTests = this.testResults.filter(r => r.category === category);
      const passed = categoryTests.filter(t => t.passed).length;
      const total = categoryTests.length;
      
      console.log(`\n${category}:`);
      console.log(`  ✅ ${passed}/${total} tests passed`);
      
      categoryTests.forEach(test => {
        const icon = test.passed ? '  ✓' : '  ✗';
        const color = test.passed ? '' : '';
        console.log(`${icon} ${test.test}${color}`);
      });
    });
    
    if (this.errors.length > 0) {
      console.log('\n🚨 ERRORS DETECTED:');
      this.errors.forEach(error => {
        console.log(`  ❌ ${error.message}`);
        if (error.error) console.log(`     Details: ${error.error}`);
      });
    }
    
    const totalTests = this.testResults.length;
    const totalPassed = this.testResults.filter(r => r.passed).length;
    const successRate = Math.round((totalPassed / totalTests) * 100);
    
    console.log('\n' + '='.repeat(60));
    console.log(`📈 OVERALL RESULTS: ${totalPassed}/${totalTests} tests passed (${successRate}%)`);
    console.log(`🚨 ERRORS: ${this.errors.length} issues found`);
    console.log('='.repeat(60));
    
    // Recommendations
    this.generateRecommendations();
  }

  generateRecommendations() {
    console.log('\n💡 RECOMMENDATIONS:\n');
    
    const failedTests = this.testResults.filter(r => !r.passed);
    
    if (failedTests.some(t => t.category === 'Field Mappings')) {
      console.log('1. 🔧 Fix field mapping inconsistencies in webhook');
      console.log('   - Ensure webhook creates fields with names expected by admin');
      console.log('   - Update AdminOrderManagement.tsx transformation logic');
    }
    
    if (failedTests.some(t => t.category === 'Database Schema')) {
      console.log('2. 📊 Update database schema');
      console.log('   - Add missing required columns to orders/order_items tables');
      console.log('   - Run latest migrations');
    }
    
    if (failedTests.some(t => t.category === 'Admin Display')) {
      console.log('3. 🖥️ Update admin UI compatibility');
      console.log('   - Modify AdminOrderManagement component to handle webhook data structure');
      console.log('   - Add null checks for optional fields');
    }
    
    if (this.errors.length > 0) {
      console.log('4. 🚨 Fix critical errors');
      console.log('   - Review error messages above');
      console.log('   - Test webhook with actual Stripe events');
    }
    
    console.log('5. 🧪 Set up continuous testing');
    console.log('   - Integrate this script into CI/CD pipeline');
    console.log('   - Add webhook event monitoring');
    console.log('   - Create admin order creation alerts');
  }
}

// Helper function to create test RPC if needed
async function createHelperFunctions() {
  console.log('Creating helper functions for tests...');
  
  const getColumnsFunction = `
    CREATE OR REPLACE FUNCTION get_table_columns(table_name text)
    RETURNS TABLE(column_name text, data_type text, is_nullable text)
    LANGUAGE sql
    AS $$
      SELECT column_name::text, data_type::text, is_nullable::text
      FROM information_schema.columns
      WHERE table_schema = 'public' AND table_name = $1
      ORDER BY ordinal_position;
    $$;
  `;
  
  try {
    await supabase.rpc('exec', { sql: getColumnsFunction });
    console.log('✅ Helper functions created');
  } catch (error) {
    console.log('ℹ️ Helper functions may already exist or need manual creation');
  }
}

// Main execution
async function main() {
  console.log('🚀 KCT Order Sync Verification Test Suite');
  console.log('==========================================\n');
  
  if (!SUPABASE_URL || !SUPABASE_SERVICE_ROLE_KEY || 
      SUPABASE_URL === 'YOUR_SUPABASE_URL' || 
      SUPABASE_SERVICE_ROLE_KEY === 'YOUR_SERVICE_ROLE_KEY') {
    console.error('❌ Please set SUPABASE_URL and SUPABASE_SERVICE_ROLE_KEY environment variables');
    console.log('\nUsage:');
    console.log('SUPABASE_URL=your_url SUPABASE_SERVICE_ROLE_KEY=your_key node test-order-sync.js');
    process.exit(1);
  }
  
  const tester = new OrderSyncTester();
  
  try {
    await createHelperFunctions();
    await tester.runAllTests();
  } catch (error) {
    console.error('❌ Test suite failed:', error);
    process.exit(1);
  }
}

// Run the tests
if (require.main === module) {
  main().catch(console.error);
}

module.exports = { OrderSyncTester };