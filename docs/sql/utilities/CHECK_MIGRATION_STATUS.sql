-- CHECK WHICH MIGRATIONS HAVE BEEN RUN
-- Run this in Supabase SQL Editor to see what's already applied

-- 1. Check if we have a migrations tracking table
SELECT EXISTS (
    SELECT 1 
    FROM information_schema.tables 
    WHERE table_name = 'schema_migrations'
) as has_migrations_table;

-- 2. Check what tables actually exist in your database
SELECT 
    'EXISTING TABLES CHECK' as check_type,
    json_build_object(
        'has_refund_requests', EXISTS(SELECT 1 FROM information_schema.tables WHERE table_name = 'refund_requests'),
        'has_payment_transactions', EXISTS(SELECT 1 FROM information_schema.tables WHERE table_name = 'payment_transactions'),
        'has_analytics_events', EXISTS(SELECT 1 FROM information_schema.tables WHERE table_name = 'analytics_events'),
        'has_financial_transactions', EXISTS(SELECT 1 FROM information_schema.tables WHERE table_name = 'financial_transactions'),
        'has_tax_rates', EXISTS(SELECT 1 FROM information_schema.tables WHERE table_name = 'tax_rates'),
        'has_product_variants', EXISTS(SELECT 1 FROM information_schema.tables WHERE table_name = 'product_variants'),
        'has_store_settings', EXISTS(SELECT 1 FROM information_schema.tables WHERE table_name = 'store_settings'),
        'has_admin_users', EXISTS(SELECT 1 FROM information_schema.tables WHERE table_name = 'admin_users'),
        'has_orders', EXISTS(SELECT 1 FROM information_schema.tables WHERE table_name = 'orders'),
        'has_order_items', EXISTS(SELECT 1 FROM information_schema.tables WHERE table_name = 'order_items')
    ) as tables_status;

-- 3. List all tables in public schema
SELECT 
    'ALL PUBLIC TABLES' as info,
    array_agg(table_name ORDER BY table_name) as tables
FROM information_schema.tables
WHERE table_schema = 'public'
AND table_type = 'BASE TABLE';

-- 4. Check specific migration artifacts
SELECT 
    'MIGRATION ARTIFACTS' as check_type,
    json_build_object(
        'has_2fa_columns', EXISTS(SELECT 1 FROM information_schema.columns WHERE table_name = 'admin_users' AND column_name = 'two_factor_secret'),
        'has_stripe_fields', EXISTS(SELECT 1 FROM information_schema.columns WHERE table_name = 'orders' AND column_name = 'stripe_payment_intent_id'),
        'has_refund_status', EXISTS(SELECT 1 FROM information_schema.columns WHERE table_name = 'orders' AND column_name = 'refund_status'),
        'has_financial_status', EXISTS(SELECT 1 FROM information_schema.columns WHERE table_name = 'orders' AND column_name = 'financial_status')
    ) as features;