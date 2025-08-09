-- ============================================
-- DIAGNOSTIC SQL - Check Table Structure
-- Run this in Supabase SQL Editor to debug
-- ============================================

-- 1. Check products table columns
SELECT 
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns
WHERE table_schema = 'public' 
AND table_name = 'products'
ORDER BY ordinal_position;

-- 2. Check for required columns
SELECT 
    EXISTS(SELECT 1 FROM information_schema.columns 
           WHERE table_name = 'products' AND column_name = 'slug') as has_slug,
    EXISTS(SELECT 1 FROM information_schema.columns 
           WHERE table_name = 'products' AND column_name = 'metadata') as has_metadata,
    EXISTS(SELECT 1 FROM information_schema.columns 
           WHERE table_name = 'products' AND column_name = 'details') as has_details,
    EXISTS(SELECT 1 FROM information_schema.columns 
           WHERE table_name = 'products' AND column_name = 'product_type') as has_product_type;

-- 3. Check RLS policies
SELECT 
    schemaname,
    tablename,
    policyname,
    permissive,
    roles,
    cmd,
    qual,
    with_check
FROM pg_policies
WHERE tablename = 'products';

-- 4. Check current user permissions
SELECT 
    auth.uid() as user_id,
    auth.role() as current_role,
    auth.email() as user_email;

-- 5. Test minimal insert (will rollback)
BEGIN;
INSERT INTO products (
    name,
    sku,
    slug,
    base_price,
    status,
    category,
    created_at,
    updated_at
) VALUES (
    'Test Product',
    'TEST-SKU-001',
    'test-product-001',
    99.99,
    'active',
    'Test',
    NOW(),
    NOW()
) RETURNING *;
ROLLBACK;

-- 6. Create RPC function for diagnostics
CREATE OR REPLACE FUNCTION get_table_columns(table_name text)
RETURNS json AS $$
BEGIN
    RETURN (
        SELECT json_agg(
            json_build_object(
                'column_name', column_name,
                'data_type', data_type,
                'is_nullable', is_nullable,
                'column_default', column_default
            )
        )
        FROM information_schema.columns
        WHERE table_schema = 'public' 
        AND table_name = get_table_columns.table_name
        ORDER BY ordinal_position
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;