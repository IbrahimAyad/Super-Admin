-- =====================================================
-- VENDOR AND DROPSHIP TABLES - SUPABASE COMPATIBLE
-- Run this script in your Supabase SQL Editor
-- Fixed for Supabase compatibility
-- =====================================================

-- First, create the update_updated_at function if it doesn't exist
CREATE OR REPLACE FUNCTION update_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- =====================================================
-- 1. VENDORS TABLE
-- =====================================================

CREATE TABLE IF NOT EXISTS vendors (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  name VARCHAR(255) NOT NULL,
  email VARCHAR(255) NOT NULL,
  phone VARCHAR(50),
  address JSONB,
  dropship_enabled BOOLEAN DEFAULT true,
  auto_send_orders BOOLEAN DEFAULT false,
  products TEXT[], -- Array of product IDs this vendor supplies
  lead_time_days INTEGER DEFAULT 7,
  minimum_order_value DECIMAL(10,2) DEFAULT 0,
  shipping_cost DECIMAL(10,2) DEFAULT 0,
  notes TEXT,
  payment_terms VARCHAR(100),
  account_number VARCHAR(100),
  tax_id VARCHAR(50),
  website VARCHAR(255),
  contact_person VARCHAR(255),
  status VARCHAR(50) DEFAULT 'active' CHECK (status IN ('active', 'inactive', 'pending')),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- =====================================================
-- 2. DROPSHIP ORDERS TABLE
-- =====================================================

CREATE TABLE IF NOT EXISTS dropship_orders (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  parent_order_id UUID REFERENCES orders(id) ON DELETE CASCADE,
  vendor_id UUID REFERENCES vendors(id),
  order_number VARCHAR(100) UNIQUE NOT NULL,
  items JSONB NOT NULL, -- Array of order items for this vendor
  status VARCHAR(50) DEFAULT 'pending' CHECK (status IN ('pending', 'confirmed', 'processing', 'shipped', 'delivered', 'cancelled')),
  customer_shipping JSONB NOT NULL, -- Customer shipping address
  vendor_cost DECIMAL(10,2), -- Cost from vendor
  vendor_shipping DECIMAL(10,2), -- Vendor shipping cost
  tracking_number VARCHAR(255),
  carrier VARCHAR(100),
  vendor_invoice_number VARCHAR(100),
  sent_to_vendor_at TIMESTAMP WITH TIME ZONE,
  confirmed_by_vendor_at TIMESTAMP WITH TIME ZONE,
  shipped_at TIMESTAMP WITH TIME ZONE,
  delivered_at TIMESTAMP WITH TIME ZONE,
  notes TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- =====================================================
-- 3. VENDOR PRODUCTS TABLE
-- =====================================================

CREATE TABLE IF NOT EXISTS vendor_products (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  vendor_id UUID REFERENCES vendors(id) ON DELETE CASCADE,
  product_id UUID REFERENCES products(id) ON DELETE CASCADE,
  vendor_sku VARCHAR(255),
  vendor_price DECIMAL(10,2) NOT NULL,
  minimum_quantity INTEGER DEFAULT 1,
  lead_time_override INTEGER,
  is_preferred BOOLEAN DEFAULT false,
  notes TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  UNIQUE(vendor_id, product_id)
);

-- =====================================================
-- 4. VENDOR COMMUNICATIONS LOG
-- =====================================================

CREATE TABLE IF NOT EXISTS vendor_communications (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  vendor_id UUID REFERENCES vendors(id),
  dropship_order_id UUID REFERENCES dropship_orders(id),
  type VARCHAR(50) CHECK (type IN ('order_sent', 'order_confirmed', 'tracking_received', 'issue_reported', 'general')),
  subject VARCHAR(255),
  message TEXT,
  attachments JSONB,
  status VARCHAR(50) DEFAULT 'sent',
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  created_by VARCHAR(255)
);

-- =====================================================
-- 5. MODIFY EXISTING TABLES (Safe alterations)
-- =====================================================

-- Add columns to products table if they don't exist
DO $$ 
BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                 WHERE table_name = 'products' AND column_name = 'vendor_id') THEN
    ALTER TABLE products ADD COLUMN vendor_id UUID REFERENCES vendors(id);
  END IF;
  
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                 WHERE table_name = 'products' AND column_name = 'vendor_price') THEN
    ALTER TABLE products ADD COLUMN vendor_price DECIMAL(10,2);
  END IF;
END $$;

-- Add order_type to orders table if it doesn't exist
DO $$ 
BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                 WHERE table_name = 'orders' AND column_name = 'order_type') THEN
    ALTER TABLE orders ADD COLUMN order_type VARCHAR(50) DEFAULT 'regular' 
      CHECK (order_type IN ('regular', 'dropship', 'mixed'));
  END IF;
END $$;

-- =====================================================
-- 6. CREATE INDEXES (Without CONCURRENTLY)
-- =====================================================

-- Vendors indexes
CREATE INDEX IF NOT EXISTS idx_vendors_status ON vendors(status);
CREATE INDEX IF NOT EXISTS idx_vendors_dropship_enabled ON vendors(dropship_enabled);

-- Dropship orders indexes
CREATE INDEX IF NOT EXISTS idx_dropship_orders_parent ON dropship_orders(parent_order_id);
CREATE INDEX IF NOT EXISTS idx_dropship_orders_vendor ON dropship_orders(vendor_id);
CREATE INDEX IF NOT EXISTS idx_dropship_orders_status ON dropship_orders(status);
CREATE INDEX IF NOT EXISTS idx_dropship_orders_created ON dropship_orders(created_at DESC);

-- Vendor products indexes
CREATE INDEX IF NOT EXISTS idx_vendor_products_vendor ON vendor_products(vendor_id);
CREATE INDEX IF NOT EXISTS idx_vendor_products_product ON vendor_products(product_id);

-- Vendor communications indexes
CREATE INDEX IF NOT EXISTS idx_vendor_communications_vendor ON vendor_communications(vendor_id);
CREATE INDEX IF NOT EXISTS idx_vendor_communications_order ON vendor_communications(dropship_order_id);

-- =====================================================
-- 7. ROW LEVEL SECURITY
-- =====================================================

ALTER TABLE vendors ENABLE ROW LEVEL SECURITY;
ALTER TABLE dropship_orders ENABLE ROW LEVEL SECURITY;
ALTER TABLE vendor_products ENABLE ROW LEVEL SECURITY;
ALTER TABLE vendor_communications ENABLE ROW LEVEL SECURITY;

-- Drop existing policies if they exist and recreate
DROP POLICY IF EXISTS "Admin full access to vendors" ON vendors;
CREATE POLICY "Admin full access to vendors" ON vendors
  FOR ALL USING (true); -- Simplified for now, adjust based on your auth setup

DROP POLICY IF EXISTS "Admin full access to dropship_orders" ON dropship_orders;
CREATE POLICY "Admin full access to dropship_orders" ON dropship_orders
  FOR ALL USING (true);

DROP POLICY IF EXISTS "Admin full access to vendor_products" ON vendor_products;
CREATE POLICY "Admin full access to vendor_products" ON vendor_products
  FOR ALL USING (true);

DROP POLICY IF EXISTS "Admin full access to vendor_communications" ON vendor_communications;
CREATE POLICY "Admin full access to vendor_communications" ON vendor_communications
  FOR ALL USING (true);

-- =====================================================
-- 8. TRIGGERS
-- =====================================================

-- Create triggers for updated_at
DROP TRIGGER IF EXISTS update_vendors_updated_at ON vendors;
CREATE TRIGGER update_vendors_updated_at 
  BEFORE UPDATE ON vendors
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();

DROP TRIGGER IF EXISTS update_dropship_orders_updated_at ON dropship_orders;
CREATE TRIGGER update_dropship_orders_updated_at 
  BEFORE UPDATE ON dropship_orders
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();

DROP TRIGGER IF EXISTS update_vendor_products_updated_at ON vendor_products;
CREATE TRIGGER update_vendor_products_updated_at 
  BEFORE UPDATE ON vendor_products
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();

-- =====================================================
-- 9. SAMPLE VENDOR DATA
-- =====================================================

-- Insert sample vendors (safe with ON CONFLICT)
INSERT INTO vendors (name, email, phone, dropship_enabled, auto_send_orders, lead_time_days, notes)
VALUES 
  ('Premium Suits Co', 'orders@premiumsuits.com', '555-0100', true, true, 5, 'Main suit supplier, fast shipping'),
  ('Luxury Tuxedos Ltd', 'sales@luxurytux.com', '555-0200', true, false, 7, 'High-end tuxedos, manual order confirmation required'),
  ('Accessories Direct', 'fulfill@accessoriesdirect.com', '555-0300', true, true, 3, 'Ties, cufflinks, pocket squares')
ON CONFLICT (id) DO NOTHING;

-- =====================================================
-- 10. VERIFICATION
-- =====================================================

-- Check that all tables were created
SELECT 
  'Vendor tables created successfully!' as status,
  COUNT(*) as vendor_count 
FROM vendors;

-- List all vendor-related tables
SELECT table_name 
FROM information_schema.tables 
WHERE table_schema = 'public' 
  AND table_name IN ('vendors', 'dropship_orders', 'vendor_products', 'vendor_communications')
ORDER BY table_name;