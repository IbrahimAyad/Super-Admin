-- ============================================
-- ORDER PROCESSING ENHANCEMENT TABLES
-- ============================================

-- Order Status History Table
CREATE TABLE IF NOT EXISTS order_status_history (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  order_id UUID NOT NULL REFERENCES orders(id) ON DELETE CASCADE,
  status VARCHAR(50) NOT NULL,
  notes TEXT,
  metadata JSONB DEFAULT '{}',
  created_by UUID REFERENCES auth.users(id),
  created_at TIMESTAMPTZ DEFAULT NOW(),
  
  -- Indexes
  INDEX idx_order_status_history_order (order_id),
  INDEX idx_order_status_history_created (created_at DESC)
);

-- Shipping Labels Table
CREATE TABLE IF NOT EXISTS shipping_labels (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  order_id UUID NOT NULL REFERENCES orders(id) ON DELETE CASCADE,
  carrier VARCHAR(50) NOT NULL,
  service_type VARCHAR(50) NOT NULL,
  tracking_number VARCHAR(255) UNIQUE,
  label_url TEXT,
  cost DECIMAL(10, 2),
  weight DECIMAL(10, 2),
  dimensions JSONB,
  status VARCHAR(50) DEFAULT 'created',
  created_at TIMESTAMPTZ DEFAULT NOW(),
  voided_at TIMESTAMPTZ,
  
  -- Indexes
  INDEX idx_shipping_labels_order (order_id),
  INDEX idx_shipping_labels_tracking (tracking_number)
);

-- Add missing columns to orders table if they don't exist
ALTER TABLE orders 
ADD COLUMN IF NOT EXISTS carrier_name VARCHAR(50),
ADD COLUMN IF NOT EXISTS estimated_delivery TIMESTAMPTZ,
ADD COLUMN IF NOT EXISTS actual_delivery TIMESTAMPTZ,
ADD COLUMN IF NOT EXISTS processing_at TIMESTAMPTZ,
ADD COLUMN IF NOT EXISTS confirmed_at TIMESTAMPTZ,
ADD COLUMN IF NOT EXISTS shipped_at TIMESTAMPTZ,
ADD COLUMN IF NOT EXISTS delivered_at TIMESTAMPTZ,
ADD COLUMN IF NOT EXISTS cancelled_at TIMESTAMPTZ,
ADD COLUMN IF NOT EXISTS cancellation_reason TEXT,
ADD COLUMN IF NOT EXISTS return_reason TEXT,
ADD COLUMN IF NOT EXISTS return_tracking_number VARCHAR(255),
ADD COLUMN IF NOT EXISTS internal_notes TEXT,
ADD COLUMN IF NOT EXISTS priority VARCHAR(20) DEFAULT 'normal',
ADD COLUMN IF NOT EXISTS fulfillment_status VARCHAR(50) DEFAULT 'unfulfilled';

-- Create indexes for new columns
CREATE INDEX IF NOT EXISTS idx_orders_carrier ON orders(carrier_name);
CREATE INDEX IF NOT EXISTS idx_orders_priority ON orders(priority);
CREATE INDEX IF NOT EXISTS idx_orders_fulfillment ON orders(fulfillment_status);

-- Order Fulfillment Queue View
CREATE OR REPLACE VIEW order_fulfillment_queue AS
SELECT 
  o.id,
  o.order_number,
  o.status,
  o.priority,
  o.total_amount,
  o.created_at,
  o.confirmed_at,
  c.first_name || ' ' || c.last_name as customer_name,
  c.email as customer_email,
  o.shipping_address,
  o.items,
  CASE 
    WHEN o.priority = 'urgent' THEN 1
    WHEN o.priority = 'high' THEN 2
    WHEN o.priority = 'normal' THEN 3
    WHEN o.priority = 'low' THEN 4
    ELSE 5
  END as priority_order
FROM orders o
LEFT JOIN customers c ON o.customer_id = c.id
WHERE o.status IN ('confirmed', 'processing')
  AND o.fulfillment_status = 'unfulfilled'
ORDER BY priority_order, o.created_at;

-- Order Analytics View
CREATE OR REPLACE VIEW order_analytics AS
SELECT 
  DATE_TRUNC('day', created_at) as order_date,
  COUNT(*) as total_orders,
  COUNT(CASE WHEN status = 'delivered' THEN 1 END) as delivered_orders,
  COUNT(CASE WHEN status = 'cancelled' THEN 1 END) as cancelled_orders,
  SUM(total_amount) / 100.0 as total_revenue,
  AVG(total_amount) / 100.0 as avg_order_value,
  COUNT(DISTINCT customer_id) as unique_customers,
  COUNT(CASE WHEN customer_id IS NULL THEN 1 END) as guest_orders,
  AVG(CASE 
    WHEN delivered_at IS NOT NULL AND shipped_at IS NOT NULL 
    THEN EXTRACT(EPOCH FROM (delivered_at - shipped_at)) / 86400.0 
  END) as avg_delivery_days,
  AVG(CASE 
    WHEN shipped_at IS NOT NULL AND confirmed_at IS NOT NULL 
    THEN EXTRACT(EPOCH FROM (shipped_at - confirmed_at)) / 3600.0 
  END) as avg_processing_hours
FROM orders
GROUP BY order_date
ORDER BY order_date DESC;

-- Function to get next order number
CREATE OR REPLACE FUNCTION get_next_order_number()
RETURNS TEXT AS $$
DECLARE
  current_year TEXT;
  last_number INTEGER;
  new_number TEXT;
BEGIN
  current_year := TO_CHAR(NOW(), 'YYYY');
  
  -- Get the last order number for this year
  SELECT COALESCE(MAX(CAST(SUBSTRING(order_number FROM 10) AS INTEGER)), 0)
  INTO last_number
  FROM orders
  WHERE order_number LIKE 'KCT-' || current_year || '-%';
  
  -- Generate new order number
  new_number := 'KCT-' || current_year || '-' || LPAD((last_number + 1)::TEXT, 5, '0');
  
  RETURN new_number;
END;
$$ LANGUAGE plpgsql;

-- Function to calculate order fulfillment time
CREATE OR REPLACE FUNCTION calculate_fulfillment_time(
  confirmed_time TIMESTAMPTZ,
  delivered_time TIMESTAMPTZ
)
RETURNS INTERVAL AS $$
BEGIN
  IF confirmed_time IS NULL OR delivered_time IS NULL THEN
    RETURN NULL;
  END IF;
  
  RETURN delivered_time - confirmed_time;
END;
$$ LANGUAGE plpgsql IMMUTABLE;

-- Trigger to update fulfillment status
CREATE OR REPLACE FUNCTION update_fulfillment_status()
RETURNS TRIGGER AS $$
BEGIN
  -- Update fulfillment status based on order status
  IF NEW.status = 'shipped' OR NEW.status = 'delivered' THEN
    NEW.fulfillment_status = 'fulfilled';
  ELSIF NEW.status = 'cancelled' OR NEW.status = 'refunded' THEN
    NEW.fulfillment_status = 'cancelled';
  ELSIF NEW.status IN ('confirmed', 'processing') THEN
    NEW.fulfillment_status = 'unfulfilled';
  END IF;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_update_fulfillment_status
BEFORE UPDATE OF status ON orders
FOR EACH ROW
EXECUTE FUNCTION update_fulfillment_status();

-- RLS Policies
ALTER TABLE order_status_history ENABLE ROW LEVEL SECURITY;
ALTER TABLE shipping_labels ENABLE ROW LEVEL SECURITY;

-- Admin can see all
CREATE POLICY "Admin can view all order history" ON order_status_history
  FOR ALL USING (true);

CREATE POLICY "Admin can view all shipping labels" ON shipping_labels
  FOR ALL USING (true);

-- Grants
GRANT ALL ON order_status_history TO authenticated;
GRANT ALL ON shipping_labels TO authenticated;
GRANT EXECUTE ON FUNCTION get_next_order_number() TO authenticated;
GRANT EXECUTE ON FUNCTION calculate_fulfillment_time(TIMESTAMPTZ, TIMESTAMPTZ) TO authenticated;