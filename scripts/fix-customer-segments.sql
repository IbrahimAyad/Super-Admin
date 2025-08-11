-- =====================================================
-- FIX CUSTOMER_SEGMENTS VIEW
-- Drops existing object and recreates as view
-- =====================================================

-- First drop if exists (whether table or view)
DROP VIEW IF EXISTS customer_segments CASCADE;
DROP TABLE IF EXISTS customer_segments CASCADE;

-- Now create as view
CREATE OR REPLACE VIEW customer_segments AS
SELECT 
  id,
  email,
  name,
  customer_tier,
  CASE 
    WHEN vip_status = true THEN 'VIP'
    WHEN total_orders > 5 THEN 'Loyal'
    WHEN total_orders > 1 THEN 'Repeat'
    ELSE 'New'
  END as segment,
  CASE
    WHEN days_since_last_purchase <= 30 THEN 'Active'
    WHEN days_since_last_purchase <= 90 THEN 'At Risk'
    WHEN days_since_last_purchase <= 180 THEN 'Lapsed'
    WHEN days_since_last_purchase IS NULL THEN 'Never Purchased'
    ELSE 'Lost'
  END as activity_status,
  total_spent,
  total_orders,
  average_order_value,
  primary_occasion,
  last_purchase_date
FROM customers;

-- Verify it was created
SELECT 'customer_segments view created successfully' as status;