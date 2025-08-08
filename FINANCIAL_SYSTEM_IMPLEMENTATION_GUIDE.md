# KCT Admin Financial Management System - Implementation Guide

## Overview

This document provides complete instructions for implementing the production-ready financial management system for KCT Admin. The system replaces all mock data with real database-driven functionality.

## 🗄️ Database Schema Overview

The financial system includes the following core components:

### Core Financial Tables
- **`payment_transactions`** - All payment/refund transactions with complete audit trail
- **`payment_fees`** - Detailed fee tracking per transaction
- **`refund_requests`** - Complete refund workflow management
- **`tax_rates`** - Jurisdiction-based tax configuration
- **`financial_reconciliation`** - Daily financial summaries

### Configuration Tables
- **`payment_method_configurations`** - Admin-configurable payment settings
- **`customer_payment_methods`** - Saved customer payment methods
- **`tax_jurisdiction_mapping`** - Geographic tax rate mapping
- **`financial_report_templates`** - Configurable report definitions

### Integration Tables
- **`payment_webhooks`** - Stripe webhook processing and tracking

## 🚀 Deployment Steps

### Step 1: Database Schema Deployment

Execute the SQL files in this exact order:

```sql
-- 1. Base financial schema (if not already deployed)
\i financial_management_schema.sql

-- 2. Extended schema with component-specific tables
\i complete_financial_schema.sql

-- 3. Main deployment with sample data
\i DEPLOY_FINANCIAL_SYSTEM.sql

-- 4. Security policies (CRITICAL for production)
\i financial_rls_policies.sql

-- 5. Stripe webhook integration
\i stripe_webhook_integration.sql

-- 6. Performance queries and views
\i financial_dashboard_queries.sql
```

### Step 2: Validation

After deployment, run validation:

```sql
SELECT * FROM validate_financial_deployment();
```

Expected results: All tests should return 'PASS' status.

## 📊 Component Integration

### 1. RefundProcessor Component

**Replace mock data with:**

```typescript
// Get pending refunds
const { data: pendingRefunds } = await supabase
  .from('v_pending_refunds')
  .select('*')
  .order('request_date', { ascending: true });

// Get refund summary metrics
const { data: metrics } = await supabase
  .rpc('get_refund_summary_metrics');

// Process a refund
const { data: result } = await supabase
  .rpc('process_refund_request', {
    p_refund_id: refundId,
    p_approved_amount: amount,
    p_processor_notes: notes,
    p_processed_by: currentUser.email
  });
```

**Key queries available:**
- `v_pending_refunds` - View of all pending refunds with customer/order details
- `get_refund_summary_metrics()` - Summary statistics for dashboard cards
- `process_refund_request()` - Complete refund processing with validation

### 2. FinancialManagement Component

**Replace mock data with:**

```typescript
// Get financial dashboard metrics
const { data: metrics } = await supabase
  .rpc('get_financial_dashboard_metrics', {
    p_date_from: startDate,
    p_date_to: endDate,
    p_currency_code: 'USD'
  });

// Get recent transactions
const { data: transactions } = await supabase
  .from('v_recent_transactions')
  .select('*')
  .limit(50);

// Get financial alerts (pending refunds, etc.)
const { data: alerts } = await supabase
  .from('refund_requests')
  .select('count')
  .eq('status', 'PENDING');
```

**Key queries available:**
- `get_financial_dashboard_metrics()` - All dashboard summary cards
- `v_recent_transactions` - Recent transaction activity
- Real-time alerts based on pending operations

### 3. FinancialReports Component

**Replace mock data with:**

```typescript
// Get revenue report with period comparison
const { data: report } = await supabase
  .rpc('get_revenue_report', {
    p_date_range: '30d', // '7d', '30d', '90d', '1y', 'custom'
    p_currency_code: 'USD',
    p_custom_start: customStartDate,
    p_custom_end: customEndDate
  });

// Export report data
const { data: exportData } = await supabase
  .from('payment_transactions')
  .select(`
    created_at,
    gross_amount,
    tax_amount,
    fee_amount,
    net_amount,
    processor_name,
    currency_code
  `)
  .gte('created_at', startDate)
  .lte('created_at', endDate);
```

**Key queries available:**
- `get_revenue_report()` - Comprehensive revenue analysis with period comparison
- Custom export queries for CSV/PDF generation
- Real-time financial metrics

### 4. PaymentMethodSettings Component

**Replace mock data with:**

```typescript
// Get payment method configurations
const { data: paymentMethods } = await supabase
  .from('v_payment_method_settings')
  .select('*')
  .order('display_order');

// Update payment method settings
const { data: result } = await supabase
  .from('payment_method_configurations')
  .update({
    is_enabled: isEnabled,
    requires_cvv: requiresCVV,
    risk_threshold: riskThreshold,
    // ... other settings
  })
  .eq('config_id', configId);

// Get payment statistics
const { data: stats } = await supabase
  .rpc('update_payment_method_statistics', { p_days_back: 30 });
```

**Key queries available:**
- `v_payment_method_settings` - Complete payment method configuration view
- Real-time transaction statistics per payment method
- Security settings management

### 5. TaxConfiguration Component

**Replace mock data with:**

```typescript
// Get tax rates
const { data: taxRates } = await supabase
  .from('tax_rates')
  .select('*')
  .order('jurisdiction_name');

// Add/update tax rate
const { data: result } = await supabase
  .from('tax_rates')
  .upsert({
    jurisdiction_code: jurisdictionCode,
    jurisdiction_name: jurisdictionName,
    tax_type: taxType,
    rate_percentage: rate / 100, // Convert percentage to decimal
    effective_from: effectiveDate,
    created_by: currentUser.email
  });

// Get effective tax rate for calculation
const { data: rate } = await supabase
  .rpc('get_effective_tax_rate', {
    p_jurisdiction_code: 'US-CA',
    p_tax_type: 'SALES_TAX',
    p_effective_date: new Date().toISOString().split('T')[0]
  });
```

**Key queries available:**
- Direct tax_rates table access with full CRUD operations
- `get_effective_tax_rate()` - Real-time tax calculation
- Jurisdiction mapping for automatic tax determination

## 🔐 Security Implementation

### Row Level Security (RLS)

The system implements comprehensive RLS policies:

```sql
-- Enable RLS on all financial tables
ALTER TABLE payment_transactions ENABLE ROW LEVEL SECURITY;

-- Example policy - only admin users can access financial data
CREATE POLICY "Admin users can read transactions" ON payment_transactions
  FOR SELECT USING (is_admin_user());
```

### Role-Based Access Control

The system supports multiple admin roles:
- **SUPER_ADMIN** - Full access to all financial data
- **ADMIN** - Access to current operations and reports
- **FINANCE_MANAGER** - Financial reports and reconciliation
- **CUSTOMER_SERVICE** - Limited refund processing access

### Usage in Components

```typescript
// Check user permissions
const { data: canAccessFinancial } = await supabase
  .rpc('can_access_financial_data');

if (!canAccessFinancial) {
  // Redirect or show access denied
  return;
}

// All queries will be automatically filtered by RLS
const { data: transactions } = await supabase
  .from('payment_transactions')
  .select('*'); // Only returns data user has access to
```

## 🎯 Stripe Webhook Integration

### Setup Webhook Endpoint

1. Configure webhook endpoint in your application:

```typescript
// API route: /api/webhooks/stripe
import { NextRequest, NextResponse } from 'next/server';
import { supabase } from '@/lib/supabase';

export async function POST(req: NextRequest) {
  const body = await req.text();
  const signature = req.headers.get('stripe-signature');
  
  try {
    // Process webhook
    const { data, error } = await supabase
      .rpc('process_stripe_webhook', {
        p_webhook_payload: JSON.parse(body),
        p_webhook_signature: signature,
        p_webhook_secret: process.env.STRIPE_WEBHOOK_SECRET
      });
    
    if (error) throw error;
    
    return NextResponse.json({ success: true, data });
  } catch (error) {
    console.error('Webhook processing failed:', error);
    return NextResponse.json(
      { error: 'Webhook processing failed' },
      { status: 500 }
    );
  }
}
```

2. Configure webhook events in Stripe Dashboard:
   - `payment_intent.succeeded`
   - `payment_intent.payment_failed`
   - `charge.dispute.created`
   - `refund.created`
   - `refund.updated`
   - `payout.paid`

### Webhook Monitoring

```typescript
// Monitor webhook processing
const { data: webhookStats } = await supabase
  .rpc('get_webhook_processing_stats', { p_days_back: 7 });

// Retry failed webhooks
const { data: retryResults } = await supabase
  .rpc('retry_failed_webhooks', { 
    p_max_retries: 3,
    p_retry_delay_minutes: 60 
  });
```

## 📈 Performance Optimization

### Database Indexes

All critical indexes are automatically created:

```sql
-- High-performance indexes for common queries
CREATE INDEX CONCURRENTLY idx_payment_transactions_created_date 
ON payment_transactions(created_at);

CREATE INDEX CONCURRENTLY idx_refund_requests_status 
ON refund_requests(status, created_at);

-- And 20+ more optimized indexes
```

### Query Performance Tips

1. **Always use date ranges** for time-series queries:
   ```typescript
   .gte('created_at', startDate)
   .lte('created_at', endDate)
   ```

2. **Use specific columns** instead of `select('*')`:
   ```typescript
   .select('transaction_id, gross_amount, created_at')
   ```

3. **Leverage database functions** for complex calculations:
   ```typescript
   .rpc('get_financial_dashboard_metrics') // Instead of client-side calculations
   ```

## 🔧 Environment Configuration

### Required Environment Variables

```env
# Database
SUPABASE_URL=your_supabase_url
SUPABASE_ANON_KEY=your_supabase_anon_key
SUPABASE_SERVICE_ROLE_KEY=your_service_role_key

# Stripe
STRIPE_PUBLISHABLE_KEY=pk_live_...
STRIPE_SECRET_KEY=sk_live_...
STRIPE_WEBHOOK_SECRET=whsec_...

# PayPal (if enabled)
PAYPAL_CLIENT_ID=your_paypal_client_id
PAYPAL_CLIENT_SECRET=your_paypal_client_secret
```

### Payment Method Configuration

Update payment method configurations via admin interface:

```sql
-- Update Stripe configuration
UPDATE payment_method_configurations SET
  api_key_public = 'pk_live_...',
  api_key_secret = 'sk_live_...', -- Encrypt this!
  webhook_secret = 'whsec_...', -- Encrypt this!
  is_enabled = true
WHERE processor_name = 'STRIPE';
```

## 📊 Monitoring and Maintenance

### Daily Reconciliation

```sql
-- Run daily reconciliation (can be automated)
SELECT calculate_daily_reconciliation(
  CURRENT_DATE - INTERVAL '1 day',
  'USD'
);
```

### Health Checks

```typescript
// Component health check
const { data: health } = await supabase
  .rpc('test_financial_rls_policies');

// Transaction processing health
const { data: processing } = await supabase
  .from('v_webhook_monitoring')
  .select('*')
  .eq('processing_status', 'failed')
  .gte('received_at', new Date(Date.now() - 24*60*60*1000));
```

### Performance Monitoring

```sql
-- Monitor slow queries
SELECT * FROM pg_stat_statements 
WHERE query LIKE '%payment_transactions%' 
ORDER BY mean_time DESC;

-- Update table statistics regularly
ANALYZE payment_transactions;
ANALYZE refund_requests;
```

## 🚨 Troubleshooting

### Common Issues

1. **"Permission denied" errors**
   - Ensure RLS policies are properly configured
   - Check that admin user has correct role in `admin_users` table

2. **Slow dashboard loading**
   - Check if indexes are created: `\di payment_transactions`
   - Verify date ranges are being used in queries
   - Consider using materialized views for heavy calculations

3. **Webhook processing failures**
   - Check webhook signature validation
   - Verify webhook secret is correctly configured
   - Monitor `payment_webhooks` table for failed attempts

4. **Incorrect financial calculations**
   - Verify currency conversions (amounts in cents vs dollars)
   - Check tax rate decimal format (0.0875 for 8.75%)
   - Ensure fee calculations include both fixed and percentage components

### Debugging Queries

```sql
-- Check recent transaction activity
SELECT * FROM v_recent_transactions LIMIT 10;

-- Verify refund processing
SELECT * FROM v_pending_refunds;

-- Monitor webhook processing
SELECT * FROM v_webhook_monitoring 
WHERE received_at >= CURRENT_DATE - INTERVAL '1 day';

-- Check financial metrics calculation
SELECT * FROM get_financial_dashboard_metrics();
```

## 📝 Migration from Mock Data

### Component Update Checklist

- [ ] Replace all `useState` mock data with Supabase queries
- [ ] Update loading states to handle async database calls
- [ ] Add error handling for database operations
- [ ] Test all CRUD operations (Create, Read, Update, Delete)
- [ ] Verify real-time data updates work correctly
- [ ] Update TypeScript interfaces to match database schema
- [ ] Test with real Stripe webhook events
- [ ] Validate all financial calculations with real data

### Example Migration

**Before (Mock Data):**
```typescript
const [pendingRefunds] = useState([
  { id: 'rf_001', amount: 299.99, status: 'pending' }
]);
```

**After (Real Database):**
```typescript
const [pendingRefunds, setPendingRefunds] = useState([]);
const [loading, setLoading] = useState(true);

useEffect(() => {
  async function fetchRefunds() {
    try {
      const { data, error } = await supabase
        .from('v_pending_refunds')
        .select('*');
      
      if (error) throw error;
      setPendingRefunds(data);
    } catch (error) {
      console.error('Error fetching refunds:', error);
    } finally {
      setLoading(false);
    }
  }
  
  fetchRefunds();
}, []);
```

## 🎯 Production Deployment

### Pre-Production Checklist

- [ ] All SQL scripts executed successfully
- [ ] RLS policies tested and working
- [ ] Stripe webhook endpoint configured and tested
- [ ] Payment method configurations updated with live credentials
- [ ] Tax rates configured for all relevant jurisdictions
- [ ] Performance indexes created and verified
- [ ] Backup and recovery procedures tested
- [ ] Monitoring and alerting configured

### Go-Live Steps

1. Deploy database schema to production
2. Update environment variables with live credentials
3. Configure Stripe webhooks with production endpoint
4. Test critical workflows with small transactions
5. Enable monitoring and alerting
6. Update component code to use real queries
7. Perform final end-to-end testing

---

## 📞 Support

For implementation support or questions:
1. Review the generated TypeScript types: `SELECT generate_typescript_types();`
2. Check deployment validation: `SELECT * FROM validate_financial_deployment();`
3. Monitor system health: `SELECT * FROM v_financial_security_summary;`

The financial management system is now production-ready with comprehensive security, performance optimizations, and real-time data processing capabilities.