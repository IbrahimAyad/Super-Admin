-- ============================================
-- TEST DATA FOR FINANCIAL DASHBOARD
-- ============================================
-- Run this in Supabase SQL Editor to create sample orders

-- Insert test customers
INSERT INTO customers (email, first_name, last_name, phone, stripe_customer_id)
VALUES 
  ('john.smith@example.com', 'John', 'Smith', '+12025551234', 'cus_test1'),
  ('sarah.johnson@example.com', 'Sarah', 'Johnson', '+12025555678', 'cus_test2'),
  ('mike.wilson@example.com', 'Mike', 'Wilson', '+12025559012', 'cus_test3')
ON CONFLICT (email) DO NOTHING;

-- Insert test orders (with realistic amounts in cents)
INSERT INTO orders (
  order_number,
  customer_id,
  total_amount,
  status,
  financial_status,
  stripe_checkout_session_id,
  stripe_payment_intent_id,
  shipping_address,
  billing_address,
  items,
  created_at
)
SELECT
  'KCT-2025-' || LPAD((1000 + ROW_NUMBER() OVER())::text, 5, '0'),
  c.id,
  CASE 
    WHEN RANDOM() < 0.3 THEN 29999  -- $299.99
    WHEN RANDOM() < 0.6 THEN 49999  -- $499.99
    WHEN RANDOM() < 0.8 THEN 79999  -- $799.99
    ELSE 149999  -- $1,499.99
  END as total_amount,
  'confirmed' as status,
  CASE 
    WHEN RANDOM() < 0.8 THEN 'paid'
    WHEN RANDOM() < 0.9 THEN 'partially_refunded'
    ELSE 'refunded'
  END as financial_status,
  'cs_test_' || gen_random_uuid()::text,
  'pi_test_' || gen_random_uuid()::text,
  jsonb_build_object(
    'line1', '123 Main St',
    'city', 'New York',
    'state', 'NY',
    'postal_code', '10001',
    'country', 'US'
  ),
  jsonb_build_object(
    'line1', '123 Main St',
    'city', 'New York',
    'state', 'NY',
    'postal_code', '10001',
    'country', 'US'
  ),
  jsonb_build_array(
    jsonb_build_object(
      'name', 'Luxury Velvet Blazer',
      'sku', 'LVB-001',
      'quantity', 1,
      'unit_price', 29999,
      'total_price', 29999,
      'stripe_product_id', 'prod_test1',
      'stripe_price_id', 'price_test1'
    )
  ),
  NOW() - INTERVAL '1 day' * (ROW_NUMBER() OVER())
FROM customers c
CROSS JOIN generate_series(1, 5);

-- Insert some pending refund requests
INSERT INTO refund_requests (
  order_id,
  reason,
  refund_amount,
  status,
  created_at
)
SELECT 
  o.id,
  CASE 
    WHEN RANDOM() < 0.3 THEN 'Size does not fit'
    WHEN RANDOM() < 0.6 THEN 'Product defect'
    ELSE 'Changed mind'
  END as reason,
  o.total_amount,  -- Full refund amount
  'pending',
  NOW() - INTERVAL '1 hour' * (ROW_NUMBER() OVER())
FROM orders o
WHERE o.financial_status = 'paid'
LIMIT 3;

-- View the results
SELECT 
  COUNT(*) as total_orders,
  SUM(total_amount)/100.0 as total_revenue,
  COUNT(CASE WHEN financial_status = 'paid' THEN 1 END) as paid_orders,
  COUNT(CASE WHEN financial_status = 'refunded' THEN 1 END) as refunded_orders
FROM orders
WHERE created_at > NOW() - INTERVAL '30 days';

SELECT COUNT(*) as pending_refunds, SUM(refund_amount)/100.0 as total_refund_amount
FROM refund_requests
WHERE status = 'pending';