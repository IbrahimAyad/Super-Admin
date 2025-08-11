-- =====================================================
-- PREPARE DATABASE FOR ENHANCED CUSTOMER IMPORT
-- Run this before importing the CSV data
-- =====================================================

-- 1. Add new columns to customers table
ALTER TABLE customers ADD COLUMN IF NOT EXISTS first_name VARCHAR(255);
ALTER TABLE customers ADD COLUMN IF NOT EXISTS last_name VARCHAR(255);
ALTER TABLE customers ADD COLUMN IF NOT EXISTS accepts_email_marketing BOOLEAN DEFAULT false;
ALTER TABLE customers ADD COLUMN IF NOT EXISTS accepts_sms_marketing BOOLEAN DEFAULT false;
ALTER TABLE customers ADD COLUMN IF NOT EXISTS total_spent DECIMAL(10,2) DEFAULT 0;
ALTER TABLE customers ADD COLUMN IF NOT EXISTS total_orders INTEGER DEFAULT 0;
ALTER TABLE customers ADD COLUMN IF NOT EXISTS customer_tier VARCHAR(50) DEFAULT 'Bronze';
ALTER TABLE customers ADD COLUMN IF NOT EXISTS engagement_score INTEGER DEFAULT 0;
ALTER TABLE customers ADD COLUMN IF NOT EXISTS average_order_value DECIMAL(10,2) DEFAULT 0;
ALTER TABLE customers ADD COLUMN IF NOT EXISTS repeat_customer BOOLEAN DEFAULT false;
ALTER TABLE customers ADD COLUMN IF NOT EXISTS vip_status BOOLEAN DEFAULT false;
ALTER TABLE customers ADD COLUMN IF NOT EXISTS primary_occasion VARCHAR(50);
ALTER TABLE customers ADD COLUMN IF NOT EXISTS first_purchase_date DATE;
ALTER TABLE customers ADD COLUMN IF NOT EXISTS last_purchase_date DATE;
ALTER TABLE customers ADD COLUMN IF NOT EXISTS days_since_last_purchase INTEGER;
ALTER TABLE customers ADD COLUMN IF NOT EXISTS notes TEXT;
ALTER TABLE customers ADD COLUMN IF NOT EXISTS tags TEXT;

-- 2. Create indexes for better performance
CREATE INDEX IF NOT EXISTS idx_customers_email ON customers(email);
CREATE INDEX IF NOT EXISTS idx_customers_tier ON customers(customer_tier);
CREATE INDEX IF NOT EXISTS idx_customers_vip ON customers(vip_status);
CREATE INDEX IF NOT EXISTS idx_customers_last_purchase ON customers(last_purchase_date DESC);

-- 3. Create customer segments view for easy querying
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
    ELSE 'Lost'
  END as activity_status,
  total_spent,
  total_orders,
  average_order_value,
  primary_occasion,
  last_purchase_date
FROM customers;

-- 4. Create function to calculate customer lifetime value
CREATE OR REPLACE FUNCTION calculate_customer_ltv(customer_id UUID)
RETURNS TABLE (
  current_ltv DECIMAL(10,2),
  predicted_ltv DECIMAL(10,2),
  retention_probability DECIMAL(5,2)
) AS $$
DECLARE
  avg_order_value DECIMAL(10,2);
  purchase_frequency DECIMAL(10,2);
  customer_lifespan INTEGER;
BEGIN
  -- Get customer metrics
  SELECT 
    average_order_value,
    CASE 
      WHEN total_orders > 0 AND first_purchase_date IS NOT NULL 
      THEN total_orders::DECIMAL / GREATEST(1, DATE_PART('day', last_purchase_date - first_purchase_date) / 30)
      ELSE 0 
    END,
    CASE 
      WHEN first_purchase_date IS NOT NULL 
      THEN DATE_PART('day', CURRENT_DATE - first_purchase_date)
      ELSE 0 
    END
  INTO avg_order_value, purchase_frequency, customer_lifespan
  FROM customers
  WHERE id = customer_id;

  -- Calculate LTV
  RETURN QUERY
  SELECT 
    total_spent as current_ltv,
    (avg_order_value * purchase_frequency * 24)::DECIMAL(10,2) as predicted_ltv, -- 24 month prediction
    CASE 
      WHEN days_since_last_purchase <= 30 THEN 0.85
      WHEN days_since_last_purchase <= 60 THEN 0.65
      WHEN days_since_last_purchase <= 90 THEN 0.45
      WHEN days_since_last_purchase <= 180 THEN 0.25
      ELSE 0.10
    END::DECIMAL(5,2) as retention_probability
  FROM customers
  WHERE id = customer_id;
END;
$$ LANGUAGE plpgsql;

-- 5. Create trigger to update customer metrics after orders
CREATE OR REPLACE FUNCTION update_customer_metrics()
RETURNS TRIGGER AS $$
BEGIN
  -- Update customer metrics when new order is placed
  UPDATE customers
  SET 
    total_orders = total_orders + 1,
    total_spent = total_spent + NEW.total_amount,
    average_order_value = (total_spent + NEW.total_amount) / (total_orders + 1),
    last_purchase_date = CURRENT_DATE,
    days_since_last_purchase = 0,
    repeat_customer = CASE WHEN total_orders >= 1 THEN true ELSE false END,
    updated_at = NOW()
  WHERE id = NEW.customer_id;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger on orders table
DROP TRIGGER IF EXISTS update_customer_metrics_trigger ON orders;
CREATE TRIGGER update_customer_metrics_trigger
AFTER INSERT ON orders
FOR EACH ROW
EXECUTE FUNCTION update_customer_metrics();

-- 6. Verify the structure
SELECT 
  column_name,
  data_type,
  is_nullable
FROM information_schema.columns
WHERE table_name = 'customers'
ORDER BY ordinal_position;

-- Summary
SELECT 
  'Database prepared for customer import!' as status,
  COUNT(*) as existing_customers
FROM customers;