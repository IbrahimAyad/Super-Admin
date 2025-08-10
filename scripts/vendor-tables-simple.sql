-- =====================================================
-- SIMPLE VENDOR TABLES - MINIMAL VERSION
-- Run this in Supabase SQL Editor
-- =====================================================

-- Create update function first
CREATE OR REPLACE FUNCTION update_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create vendors table
CREATE TABLE IF NOT EXISTS vendors (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  name VARCHAR(255) NOT NULL,
  email VARCHAR(255) NOT NULL,
  phone VARCHAR(50),
  address JSONB,
  dropship_enabled BOOLEAN DEFAULT true,
  auto_send_orders BOOLEAN DEFAULT false,
  products TEXT[],
  lead_time_days INTEGER DEFAULT 7,
  notes TEXT,
  status VARCHAR(50) DEFAULT 'active',
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create dropship_orders table
CREATE TABLE IF NOT EXISTS dropship_orders (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  parent_order_id UUID,
  vendor_id UUID REFERENCES vendors(id),
  order_number VARCHAR(100) UNIQUE NOT NULL,
  items JSONB NOT NULL,
  status VARCHAR(50) DEFAULT 'pending',
  customer_shipping JSONB NOT NULL,
  vendor_cost DECIMAL(10,2),
  tracking_number VARCHAR(255),
  notes TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Add basic indexes
CREATE INDEX IF NOT EXISTS idx_vendors_status ON vendors(status);
CREATE INDEX IF NOT EXISTS idx_dropship_orders_vendor ON dropship_orders(vendor_id);
CREATE INDEX IF NOT EXISTS idx_dropship_orders_status ON dropship_orders(status);

-- Add triggers for updated_at
CREATE TRIGGER update_vendors_updated_at 
  BEFORE UPDATE ON vendors
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();

CREATE TRIGGER update_dropship_orders_updated_at 
  BEFORE UPDATE ON dropship_orders
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();

-- Add sample vendors
INSERT INTO vendors (name, email, phone, dropship_enabled, notes)
VALUES 
  ('Premium Suits Co', 'orders@premiumsuits.com', '555-0100', true, 'Main suit supplier'),
  ('Luxury Tuxedos Ltd', 'sales@luxurytux.com', '555-0200', true, 'High-end tuxedos'),
  ('Accessories Direct', 'fulfill@accessoriesdirect.com', '555-0300', true, 'Ties and accessories')
ON CONFLICT (id) DO NOTHING;

-- Verify tables were created
SELECT 
  'Tables created: ' || COUNT(*)::text as status
FROM information_schema.tables 
WHERE table_name IN ('vendors', 'dropship_orders');