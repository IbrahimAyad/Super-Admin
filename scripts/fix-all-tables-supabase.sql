-- =====================================================
-- FIX ALL AUTOMATION TABLES FOR SUPABASE
-- Run each section separately if needed
-- =====================================================

-- SECTION 1: Create base functions
-- =====================================================

CREATE OR REPLACE FUNCTION update_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- SECTION 2: Fix customers table if missing
-- =====================================================

CREATE TABLE IF NOT EXISTS customers (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  name VARCHAR(255),
  email VARCHAR(255) UNIQUE,
  phone VARCHAR(50),
  shipping_address JSONB,
  billing_address JSONB,
  order_count INTEGER DEFAULT 0,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- SECTION 3: Fix orders table columns
-- =====================================================

-- Add missing columns to orders table if they don't exist
DO $$ 
BEGIN
  -- Add customer_id if missing
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                 WHERE table_name = 'orders' AND column_name = 'customer_id') THEN
    ALTER TABLE orders ADD COLUMN customer_id UUID;
  END IF;
  
  -- Add payment_status if missing
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                 WHERE table_name = 'orders' AND column_name = 'payment_status') THEN
    ALTER TABLE orders ADD COLUMN payment_status VARCHAR(50) DEFAULT 'pending';
  END IF;
  
  -- Add tracking_number if missing
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                 WHERE table_name = 'orders' AND column_name = 'tracking_number') THEN
    ALTER TABLE orders ADD COLUMN tracking_number VARCHAR(255);
  END IF;
  
  -- Add carrier if missing
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                 WHERE table_name = 'orders' AND column_name = 'carrier') THEN
    ALTER TABLE orders ADD COLUMN carrier VARCHAR(100);
  END IF;

  -- Add notes if missing
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                 WHERE table_name = 'orders' AND column_name = 'notes') THEN
    ALTER TABLE orders ADD COLUMN notes TEXT;
  END IF;

  -- Add order_type if missing
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                 WHERE table_name = 'orders' AND column_name = 'order_type') THEN
    ALTER TABLE orders ADD COLUMN order_type VARCHAR(50) DEFAULT 'regular';
  END IF;
END $$;

-- SECTION 4: Create order_items table if missing
-- =====================================================

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

-- SECTION 5: Create email automation tables
-- =====================================================

CREATE TABLE IF NOT EXISTS email_templates (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  name VARCHAR(255) NOT NULL,
  type VARCHAR(50),
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

CREATE TABLE IF NOT EXISTS email_campaigns (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  name VARCHAR(255) NOT NULL,
  template_id UUID REFERENCES email_templates(id),
  trigger VARCHAR(50),
  event_type VARCHAR(100),
  schedule_time TIMESTAMP WITH TIME ZONE,
  delay_hours INTEGER,
  audience_filter JSONB,
  status VARCHAR(50),
  sent_count INTEGER DEFAULT 0,
  pending_count INTEGER DEFAULT 0,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS email_queue (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  to_email VARCHAR(255) NOT NULL,
  template_id VARCHAR(255), -- Changed from UUID reference to allow string template names
  campaign_id UUID,
  data JSONB,
  status VARCHAR(50) DEFAULT 'pending',
  scheduled_for TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  sent_at TIMESTAMP WITH TIME ZONE,
  error_message TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- SECTION 6: Create inventory alert tables
-- =====================================================

CREATE TABLE IF NOT EXISTS inventory_alerts (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  type VARCHAR(50),
  severity VARCHAR(50),
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

CREATE TABLE IF NOT EXISTS alert_rules (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  name VARCHAR(255) NOT NULL,
  type VARCHAR(50),
  condition TEXT,
  threshold INTEGER,
  action VARCHAR(50),
  enabled BOOLEAN DEFAULT true,
  category VARCHAR(100),
  notify_emails TEXT[],
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS purchase_orders (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  product_id UUID,
  supplier_id UUID,
  quantity INTEGER NOT NULL,
  estimated_cost DECIMAL(10,2),
  actual_cost DECIMAL(10,2),
  status VARCHAR(50) DEFAULT 'pending',
  order_date DATE,
  expected_date DATE,
  received_date DATE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- SECTION 7: Create automation rules table
-- =====================================================

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
ON CONFLICT (id) DO NOTHING;

-- SECTION 8: Create backup tables
-- =====================================================

CREATE TABLE IF NOT EXISTS database_backups (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  backup_name VARCHAR(255) NOT NULL UNIQUE,
  backup_type VARCHAR(50),
  tables_included TEXT[],
  size_bytes BIGINT,
  status VARCHAR(50),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  completed_at TIMESTAMP WITH TIME ZONE,
  error_message TEXT,
  backup_url TEXT,
  retention_days INTEGER DEFAULT 30
);

CREATE TABLE IF NOT EXISTS backup_schedules (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  schedule_name VARCHAR(255) NOT NULL,
  frequency VARCHAR(50),
  time_of_day TIME NOT NULL,
  day_of_week INTEGER,
  day_of_month INTEGER,
  enabled BOOLEAN DEFAULT true,
  last_run TIMESTAMP WITH TIME ZONE,
  next_run TIMESTAMP WITH TIME ZONE,
  retention_days INTEGER DEFAULT 30,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- SECTION 9: Create basic indexes (without CONCURRENTLY)
-- =====================================================

-- Orders indexes
CREATE INDEX IF NOT EXISTS idx_orders_customer_id ON orders(customer_id);
CREATE INDEX IF NOT EXISTS idx_orders_status ON orders(status);
CREATE INDEX IF NOT EXISTS idx_orders_created_at ON orders(created_at DESC);

-- Order items indexes
CREATE INDEX IF NOT EXISTS idx_order_items_order_id ON order_items(order_id);
CREATE INDEX IF NOT EXISTS idx_order_items_product_id ON order_items(product_id);

-- Email queue indexes
CREATE INDEX IF NOT EXISTS idx_email_queue_status ON email_queue(status);
CREATE INDEX IF NOT EXISTS idx_email_queue_scheduled_for ON email_queue(scheduled_for);

-- Inventory alerts indexes
CREATE INDEX IF NOT EXISTS idx_inventory_alerts_product_id ON inventory_alerts(product_id);
CREATE INDEX IF NOT EXISTS idx_inventory_alerts_acknowledged ON inventory_alerts(acknowledged);

-- SECTION 10: Verify all tables
-- =====================================================

SELECT 
  table_name,
  'Created' as status
FROM information_schema.tables 
WHERE table_schema = 'public' 
  AND table_name IN (
    'customers',
    'order_items',
    'email_templates',
    'email_campaigns',
    'email_queue',
    'inventory_alerts',
    'alert_rules',
    'purchase_orders',
    'automation_rules',
    'database_backups',
    'backup_schedules'
  )
ORDER BY table_name;

-- Final status
SELECT 'All automation tables fixed!' as message, NOW() as completed_at;