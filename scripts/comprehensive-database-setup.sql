-- =====================================================
-- COMPREHENSIVE DATABASE SETUP FOR ALL OPTIMIZATIONS
-- Run this script in your Supabase SQL Editor
-- Created: 2025-08-10
-- =====================================================

-- =====================================================
-- 1. DATABASE BACKUP SYSTEM TABLES
-- =====================================================

-- Create database_backups table
CREATE TABLE IF NOT EXISTS database_backups (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  backup_name VARCHAR(255) NOT NULL UNIQUE,
  backup_type VARCHAR(50) CHECK (backup_type IN ('manual', 'scheduled', 'auto')),
  tables_included TEXT[],
  size_bytes BIGINT,
  status VARCHAR(50) CHECK (status IN ('completed', 'in_progress', 'failed')),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  completed_at TIMESTAMP WITH TIME ZONE,
  error_message TEXT,
  backup_url TEXT,
  retention_days INTEGER DEFAULT 30
);

-- Create backup_schedules table
CREATE TABLE IF NOT EXISTS backup_schedules (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  schedule_name VARCHAR(255) NOT NULL,
  frequency VARCHAR(50) CHECK (frequency IN ('daily', 'weekly', 'monthly')),
  time_of_day TIME NOT NULL,
  day_of_week INTEGER,
  day_of_month INTEGER,
  enabled BOOLEAN DEFAULT true,
  last_run TIMESTAMP WITH TIME ZONE,
  next_run TIMESTAMP WITH TIME ZONE,
  retention_days INTEGER DEFAULT 30,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create backup_restore_log table
CREATE TABLE IF NOT EXISTS backup_restore_log (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  backup_id UUID REFERENCES database_backups(id),
  restored_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  restored_by VARCHAR(255)
);

-- Create backups storage bucket
INSERT INTO storage.buckets (id, name, public)
VALUES ('backups', 'backups', false)
ON CONFLICT (id) DO NOTHING;

-- =====================================================
-- 2. ORDER PROCESSING AUTOMATION TABLES
-- =====================================================

-- Create orders table if not exists
CREATE TABLE IF NOT EXISTS orders (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  order_number VARCHAR(100) UNIQUE NOT NULL,
  customer_id UUID,
  status VARCHAR(50) CHECK (status IN ('pending', 'processing', 'shipped', 'delivered', 'cancelled')),
  payment_status VARCHAR(50) CHECK (payment_status IN ('pending', 'paid', 'refunded')),
  total_amount DECIMAL(10,2),
  subtotal DECIMAL(10,2),
  tax_amount DECIMAL(10,2),
  shipping_amount DECIMAL(10,2),
  shipping_address JSONB,
  billing_address JSONB,
  tracking_number VARCHAR(255),
  carrier VARCHAR(100),
  notes TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create order_items table if not exists
CREATE TABLE IF NOT EXISTS order_items (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  order_id UUID REFERENCES orders(id) ON DELETE CASCADE,
  product_id UUID,
  product_name VARCHAR(255),
  variant_id UUID,
  variant_name VARCHAR(255),
  quantity INTEGER NOT NULL,
  price DECIMAL(10,2) NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create customers table if not exists
CREATE TABLE IF NOT EXISTS customers (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  name VARCHAR(255),
  email VARCHAR(255) UNIQUE,
  phone VARCHAR(50),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create automation_rules table
CREATE TABLE IF NOT EXISTS automation_rules (
  id SERIAL PRIMARY KEY,
  name VARCHAR(255) NOT NULL,
  condition VARCHAR(255),
  action VARCHAR(255),
  enabled BOOLEAN DEFAULT true,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Insert default automation rules
INSERT INTO automation_rules (name, condition, action, enabled)
VALUES 
  ('Auto-confirm paid orders', 'payment_received', 'update_status_processing', true),
  ('Send tracking email', 'tracking_added', 'send_tracking_email', true),
  ('Flag high-value orders', 'order_over_500', 'flag_for_review', false),
  ('Auto-generate shipping labels', 'status_processing', 'create_shipping_label', true)
ON CONFLICT DO NOTHING;

-- =====================================================
-- 3. SMART INVENTORY ALERTS TABLES
-- =====================================================

-- Create inventory_alerts table
CREATE TABLE IF NOT EXISTS inventory_alerts (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  type VARCHAR(50) CHECK (type IN ('low_stock', 'out_of_stock', 'overstock', 'fast_moving', 'slow_moving')),
  severity VARCHAR(50) CHECK (severity IN ('critical', 'warning', 'info')),
  product_id UUID,
  current_stock INTEGER,
  threshold INTEGER,
  recommended_action TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  acknowledged BOOLEAN DEFAULT false,
  acknowledged_at TIMESTAMP WITH TIME ZONE,
  acknowledged_by VARCHAR(255),
  auto_resolved BOOLEAN DEFAULT false
);

-- Create alert_rules table
CREATE TABLE IF NOT EXISTS alert_rules (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  name VARCHAR(255) NOT NULL,
  type VARCHAR(50),
  condition TEXT,
  threshold INTEGER,
  action VARCHAR(50) CHECK (action IN ('email', 'notification', 'auto_reorder', 'flag')),
  enabled BOOLEAN DEFAULT true,
  category VARCHAR(100),
  notify_emails TEXT[],
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create purchase_orders table
CREATE TABLE IF NOT EXISTS purchase_orders (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  product_id UUID,
  supplier_id UUID,
  quantity INTEGER NOT NULL,
  estimated_cost DECIMAL(10,2),
  actual_cost DECIMAL(10,2),
  status VARCHAR(50) CHECK (status IN ('pending', 'ordered', 'shipped', 'received', 'cancelled')),
  order_date DATE,
  expected_date DATE,
  received_date DATE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create inventory_history table
CREATE TABLE IF NOT EXISTS inventory_history (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  product_id UUID,
  variant_id UUID,
  change_type VARCHAR(50) CHECK (change_type IN ('sale', 'restock', 'adjustment', 'return')),
  quantity_change INTEGER,
  previous_quantity INTEGER,
  new_quantity INTEGER,
  reason TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  created_by VARCHAR(255)
);

-- =====================================================
-- 4. CUSTOMER EMAIL AUTOMATION TABLES
-- =====================================================

-- Create email_templates table
CREATE TABLE IF NOT EXISTS email_templates (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  name VARCHAR(255) NOT NULL,
  type VARCHAR(50) CHECK (type IN ('order_confirmation', 'shipping', 'delivery', 'review_request', 'welcome', 'abandoned_cart', 'promotional')),
  subject TEXT NOT NULL,
  content TEXT NOT NULL,
  variables TEXT[],
  enabled BOOLEAN DEFAULT true,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  send_count INTEGER DEFAULT 0,
  open_rate DECIMAL(5,2) DEFAULT 0,
  click_rate DECIMAL(5,2) DEFAULT 0
);

-- Create email_campaigns table
CREATE TABLE IF NOT EXISTS email_campaigns (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  name VARCHAR(255) NOT NULL,
  template_id UUID REFERENCES email_templates(id),
  trigger VARCHAR(50) CHECK (trigger IN ('immediate', 'scheduled', 'event_based')),
  event_type VARCHAR(100),
  schedule_time TIMESTAMP WITH TIME ZONE,
  delay_hours INTEGER,
  audience_filter JSONB,
  status VARCHAR(50) CHECK (status IN ('draft', 'active', 'paused', 'completed')),
  sent_count INTEGER DEFAULT 0,
  pending_count INTEGER DEFAULT 0,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create email_queue table
CREATE TABLE IF NOT EXISTS email_queue (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  to_email VARCHAR(255) NOT NULL,
  template_id UUID REFERENCES email_templates(id),
  campaign_id UUID REFERENCES email_campaigns(id),
  data JSONB,
  status VARCHAR(50) CHECK (status IN ('pending', 'sent', 'failed')),
  scheduled_for TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  sent_at TIMESTAMP WITH TIME ZONE,
  error_message TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create email_events table for tracking
CREATE TABLE IF NOT EXISTS email_events (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  email_queue_id UUID REFERENCES email_queue(id),
  event_type VARCHAR(50) CHECK (event_type IN ('opened', 'clicked', 'bounced', 'unsubscribed')),
  event_data JSONB,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- =====================================================
-- 5. PERFORMANCE INDEXES
-- =====================================================

-- Products indexes
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_products_category ON products(category);
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_products_status ON products(status);
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_products_created_at ON products(created_at DESC);

-- Product images indexes
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_product_images_product_id ON product_images(product_id);
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_product_images_position ON product_images(product_id, position);

-- Orders indexes
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_orders_customer_id ON orders(customer_id);
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_orders_status ON orders(status);
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_orders_payment_status ON orders(payment_status);
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_orders_created_at ON orders(created_at DESC);

-- Order items indexes
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_order_items_order_id ON order_items(order_id);
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_order_items_product_id ON order_items(product_id);

-- Inventory alerts indexes
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_inventory_alerts_product_id ON inventory_alerts(product_id);
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_inventory_alerts_acknowledged ON inventory_alerts(acknowledged);
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_inventory_alerts_created_at ON inventory_alerts(created_at DESC);

-- Email queue indexes
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_email_queue_status ON email_queue(status);
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_email_queue_scheduled_for ON email_queue(scheduled_for);
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_email_queue_template_id ON email_queue(template_id);

-- =====================================================
-- 6. ROW LEVEL SECURITY (RLS) POLICIES
-- =====================================================

-- Enable RLS on sensitive tables
ALTER TABLE database_backups ENABLE ROW LEVEL SECURITY;
ALTER TABLE orders ENABLE ROW LEVEL SECURITY;
ALTER TABLE customers ENABLE ROW LEVEL SECURITY;
ALTER TABLE email_queue ENABLE ROW LEVEL SECURITY;

-- Admin-only policies for backups
CREATE POLICY "Admin full access to backups" ON database_backups
  FOR ALL USING (auth.jwt() ->> 'role' = 'admin');

-- Order policies
CREATE POLICY "Admin full access to orders" ON orders
  FOR ALL USING (auth.jwt() ->> 'role' = 'admin');

CREATE POLICY "Customers can view own orders" ON orders
  FOR SELECT USING (customer_id = auth.uid());

-- Customer policies
CREATE POLICY "Admin full access to customers" ON customers
  FOR ALL USING (auth.jwt() ->> 'role' = 'admin');

CREATE POLICY "Customers can view own data" ON customers
  FOR SELECT USING (id = auth.uid());

-- Email queue policies
CREATE POLICY "Admin full access to email queue" ON email_queue
  FOR ALL USING (auth.jwt() ->> 'role' = 'admin');

-- =====================================================
-- 7. HELPER FUNCTIONS
-- =====================================================

-- Function to calculate inventory levels
CREATE OR REPLACE FUNCTION calculate_inventory_level(p_product_id UUID)
RETURNS INTEGER AS $$
DECLARE
  total_inventory INTEGER;
BEGIN
  SELECT COALESCE(SUM(inventory_quantity), 0)
  INTO total_inventory
  FROM product_variants
  WHERE product_id = p_product_id;
  
  RETURN total_inventory;
END;
$$ LANGUAGE plpgsql;

-- Function to check low stock products
CREATE OR REPLACE FUNCTION check_low_stock_products(threshold INTEGER DEFAULT 10)
RETURNS TABLE(product_id UUID, product_name TEXT, total_inventory INTEGER) AS $$
BEGIN
  RETURN QUERY
  SELECT 
    p.id,
    p.name,
    calculate_inventory_level(p.id) as total_inventory
  FROM products p
  WHERE calculate_inventory_level(p.id) < threshold;
END;
$$ LANGUAGE plpgsql;

-- Function to get email template variables
CREATE OR REPLACE FUNCTION extract_template_variables(template_content TEXT)
RETURNS TEXT[] AS $$
DECLARE
  variables TEXT[];
BEGIN
  SELECT ARRAY_AGG(DISTINCT match[1])
  INTO variables
  FROM regexp_matches(template_content, '\{([^}]+)\}', 'g') AS match;
  
  RETURN COALESCE(variables, ARRAY[]::TEXT[]);
END;
$$ LANGUAGE plpgsql;

-- =====================================================
-- 8. TRIGGERS
-- =====================================================

-- Trigger to update 'updated_at' timestamp
CREATE OR REPLACE FUNCTION update_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Apply update trigger to relevant tables
CREATE TRIGGER update_orders_updated_at BEFORE UPDATE ON orders
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();

CREATE TRIGGER update_products_updated_at BEFORE UPDATE ON products
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();

CREATE TRIGGER update_customers_updated_at BEFORE UPDATE ON customers
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();

-- Trigger to create inventory alert on low stock
CREATE OR REPLACE FUNCTION check_inventory_alert()
RETURNS TRIGGER AS $$
BEGIN
  IF NEW.inventory_quantity < 10 AND OLD.inventory_quantity >= 10 THEN
    INSERT INTO inventory_alerts (
      type,
      severity,
      product_id,
      current_stock,
      threshold,
      recommended_action
    ) VALUES (
      'low_stock',
      CASE WHEN NEW.inventory_quantity < 5 THEN 'critical' ELSE 'warning' END,
      NEW.product_id,
      NEW.inventory_quantity,
      10,
      'Consider reordering this product'
    );
  END IF;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER inventory_alert_trigger AFTER UPDATE ON product_variants
  FOR EACH ROW EXECUTE FUNCTION check_inventory_alert();

-- =====================================================
-- 9. SAMPLE DATA INITIALIZATION
-- =====================================================

-- Insert sample email templates if none exist
INSERT INTO email_templates (name, type, subject, content, variables, enabled)
SELECT 
  'Order Confirmation',
  'order_confirmation',
  'Order Confirmation - #{order_number}',
  'Dear {customer_name}, Thank you for your order #{order_number}. Total: ${total}',
  ARRAY['customer_name', 'order_number', 'total'],
  true
WHERE NOT EXISTS (SELECT 1 FROM email_templates WHERE type = 'order_confirmation');

INSERT INTO email_templates (name, type, subject, content, variables, enabled)
SELECT 
  'Shipping Notification',
  'shipping',
  'Your Order Has Shipped - #{order_number}',
  'Hi {customer_name}, Your order has shipped! Tracking: {tracking_number}',
  ARRAY['customer_name', 'order_number', 'tracking_number'],
  true
WHERE NOT EXISTS (SELECT 1 FROM email_templates WHERE type = 'shipping');

-- =====================================================
-- 10. GRANT PERMISSIONS
-- =====================================================

-- Grant permissions to authenticated users for read operations
GRANT SELECT ON ALL TABLES IN SCHEMA public TO authenticated;

-- Grant full permissions to service role for admin operations
GRANT ALL ON ALL TABLES IN SCHEMA public TO service_role;
GRANT ALL ON ALL SEQUENCES IN SCHEMA public TO service_role;
GRANT ALL ON ALL FUNCTIONS IN SCHEMA public TO service_role;

-- =====================================================
-- VERIFICATION QUERIES
-- =====================================================

-- Check all tables created
SELECT table_name 
FROM information_schema.tables 
WHERE table_schema = 'public' 
  AND table_name IN (
    'database_backups',
    'backup_schedules',
    'backup_restore_log',
    'orders',
    'order_items',
    'customers',
    'automation_rules',
    'inventory_alerts',
    'alert_rules',
    'purchase_orders',
    'inventory_history',
    'email_templates',
    'email_campaigns',
    'email_queue',
    'email_events'
  )
ORDER BY table_name;

-- Check indexes created
SELECT 
  schemaname,
  tablename,
  indexname
FROM pg_indexes 
WHERE schemaname = 'public' 
  AND indexname LIKE 'idx_%'
ORDER BY tablename, indexname;

-- Check RLS policies
SELECT 
  schemaname,
  tablename,
  policyname
FROM pg_policies
WHERE schemaname = 'public'
ORDER BY tablename, policyname;

-- =====================================================
-- END OF COMPREHENSIVE DATABASE SETUP
-- =====================================================

-- Summary report
SELECT 
  'Database setup completed successfully!' as message,
  NOW() as completed_at;