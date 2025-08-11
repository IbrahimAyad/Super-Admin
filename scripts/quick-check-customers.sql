-- =====================================================
-- QUICK CHECK SCRIPT
-- Run this first to see what columns already exist
-- =====================================================

-- Check if customers table exists and what columns it has
SELECT 
  column_name,
  data_type,
  column_default
FROM information_schema.columns
WHERE table_name = 'customers'
ORDER BY ordinal_position;

-- Count existing customers
SELECT COUNT(*) as customer_count FROM customers;

-- Check if any of the new columns already exist
SELECT 
  CASE 
    WHEN column_name IS NOT NULL THEN 'EXISTS'
    ELSE 'MISSING'
  END as status,
  col_check.expected_column
FROM (
  VALUES 
    ('first_name'),
    ('last_name'),
    ('accepts_email_marketing'),
    ('total_spent'),
    ('customer_tier'),
    ('vip_status')
) AS col_check(expected_column)
LEFT JOIN information_schema.columns ic 
  ON ic.table_name = 'customers' 
  AND ic.column_name = col_check.expected_column;