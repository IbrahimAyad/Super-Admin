-- ============================================
-- COMPLETE ORDER PROCESSING SETUP
-- ============================================
-- Run this in Supabase SQL Editor

-- First, run the migration to create tables
-- (Copy contents of 053_order_processing_tables.sql here)

-- Order Status History Table
CREATE TABLE IF NOT EXISTS order_status_history (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  order_id UUID NOT NULL REFERENCES orders(id) ON DELETE CASCADE,
  status VARCHAR(50) NOT NULL,
  notes TEXT,
  metadata JSONB DEFAULT '{}',
  created_by UUID REFERENCES auth.users(id),
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_order_status_history_order ON order_status_history(order_id);
CREATE INDEX IF NOT EXISTS idx_order_status_history_created ON order_status_history(created_at DESC);

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
  voided_at TIMESTAMPTZ
);

CREATE INDEX IF NOT EXISTS idx_shipping_labels_order ON shipping_labels(order_id);
CREATE INDEX IF NOT EXISTS idx_shipping_labels_tracking ON shipping_labels(tracking_number);

-- Add missing columns to orders table if they don't exist
DO $$ 
BEGIN
  -- Add carrier_name if it doesn't exist
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                WHERE table_name = 'orders' AND column_name = 'carrier_name') THEN
    ALTER TABLE orders ADD COLUMN carrier_name VARCHAR(50);
  END IF;

  -- Add estimated_delivery if it doesn't exist  
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                WHERE table_name = 'orders' AND column_name = 'estimated_delivery') THEN
    ALTER TABLE orders ADD COLUMN estimated_delivery TIMESTAMPTZ;
  END IF;

  -- Add actual_delivery if it doesn't exist
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                WHERE table_name = 'orders' AND column_name = 'actual_delivery') THEN
    ALTER TABLE orders ADD COLUMN actual_delivery TIMESTAMPTZ;
  END IF;

  -- Add processing_at if it doesn't exist
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                WHERE table_name = 'orders' AND column_name = 'processing_at') THEN
    ALTER TABLE orders ADD COLUMN processing_at TIMESTAMPTZ;
  END IF;

  -- Add confirmed_at if it doesn't exist
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                WHERE table_name = 'orders' AND column_name = 'confirmed_at') THEN
    ALTER TABLE orders ADD COLUMN confirmed_at TIMESTAMPTZ;
  END IF;

  -- Add shipped_at if it doesn't exist
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                WHERE table_name = 'orders' AND column_name = 'shipped_at') THEN
    ALTER TABLE orders ADD COLUMN shipped_at TIMESTAMPTZ;
  END IF;

  -- Add delivered_at if it doesn't exist
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                WHERE table_name = 'orders' AND column_name = 'delivered_at') THEN
    ALTER TABLE orders ADD COLUMN delivered_at TIMESTAMPTZ;
  END IF;

  -- Add cancelled_at if it doesn't exist
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                WHERE table_name = 'orders' AND column_name = 'cancelled_at') THEN
    ALTER TABLE orders ADD COLUMN cancelled_at TIMESTAMPTZ;
  END IF;

  -- Add cancellation_reason if it doesn't exist
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                WHERE table_name = 'orders' AND column_name = 'cancellation_reason') THEN
    ALTER TABLE orders ADD COLUMN cancellation_reason TEXT;
  END IF;

  -- Add internal_notes if it doesn't exist
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                WHERE table_name = 'orders' AND column_name = 'internal_notes') THEN
    ALTER TABLE orders ADD COLUMN internal_notes TEXT;
  END IF;

  -- Add priority if it doesn't exist
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                WHERE table_name = 'orders' AND column_name = 'priority') THEN
    ALTER TABLE orders ADD COLUMN priority VARCHAR(20) DEFAULT 'normal';
  END IF;

  -- Add fulfillment_status if it doesn't exist
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                WHERE table_name = 'orders' AND column_name = 'fulfillment_status') THEN
    ALTER TABLE orders ADD COLUMN fulfillment_status VARCHAR(50) DEFAULT 'unfulfilled';
  END IF;
END $$;

-- Create indexes
CREATE INDEX IF NOT EXISTS idx_orders_carrier ON orders(carrier_name);
CREATE INDEX IF NOT EXISTS idx_orders_priority ON orders(priority);
CREATE INDEX IF NOT EXISTS idx_orders_fulfillment ON orders(fulfillment_status);

-- Enable RLS
ALTER TABLE order_status_history ENABLE ROW LEVEL SECURITY;
ALTER TABLE shipping_labels ENABLE ROW LEVEL SECURITY;

-- Create policies (allow all for admin)
CREATE POLICY "Admin can manage order history" ON order_status_history
  FOR ALL USING (true);

CREATE POLICY "Admin can manage shipping labels" ON shipping_labels
  FOR ALL USING (true);

-- ============================================
-- TEST DATA SETUP
-- ============================================

-- Update some existing orders with different statuses for testing
UPDATE orders 
SET status = 'confirmed',
    confirmed_at = NOW() - INTERVAL '2 days',
    priority = 'normal'
WHERE status = 'pending' 
LIMIT 3;

UPDATE orders 
SET status = 'processing',
    confirmed_at = NOW() - INTERVAL '3 days',
    processing_at = NOW() - INTERVAL '1 day',
    priority = 'high'
WHERE status = 'pending' 
LIMIT 2;

UPDATE orders 
SET status = 'shipped',
    confirmed_at = NOW() - INTERVAL '5 days',
    processing_at = NOW() - INTERVAL '4 days',
    shipped_at = NOW() - INTERVAL '2 days',
    tracking_number = 'USPS-' || gen_random_uuid()::text,
    carrier_name = 'USPS',
    estimated_delivery = NOW() + INTERVAL '3 days'
WHERE status = 'pending' 
LIMIT 2;

-- Add some order status history
INSERT INTO order_status_history (order_id, status, notes)
SELECT 
  id,
  'confirmed',
  'Order confirmed and payment verified'
FROM orders
WHERE status IN ('confirmed', 'processing', 'shipped')
ON CONFLICT DO NOTHING;

INSERT INTO order_status_history (order_id, status, notes)
SELECT 
  id,
  'processing',
  'Order is being prepared for shipment'
FROM orders
WHERE status IN ('processing', 'shipped')
ON CONFLICT DO NOTHING;

INSERT INTO order_status_history (order_id, status, notes)
SELECT 
  id,
  'shipped',
  'Order has been shipped via ' || COALESCE(carrier_name, 'USPS')
FROM orders
WHERE status = 'shipped'
ON CONFLICT DO NOTHING;

-- Verify the setup
SELECT 
  'Orders by Status' as metric,
  status,
  COUNT(*) as count
FROM orders
GROUP BY status

UNION ALL

SELECT 
  'Order History Entries' as metric,
  'Total' as status,
  COUNT(*)::bigint as count
FROM order_status_history

UNION ALL

SELECT 
  'Orders with Tracking' as metric,
  'Has Tracking' as status,
  COUNT(*)::bigint as count
FROM orders
WHERE tracking_number IS NOT NULL;