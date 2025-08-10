-- =====================================================
-- VENDOR AND DROPSHIP ORDER MANAGEMENT TABLES
-- Run this script in your Supabase SQL Editor
-- Created: 2025-08-10
-- =====================================================

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
-- 3. VENDOR PRODUCTS TABLE (for vendor-specific pricing)
-- =====================================================

CREATE TABLE IF NOT EXISTS vendor_products (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  vendor_id UUID REFERENCES vendors(id) ON DELETE CASCADE,
  product_id UUID REFERENCES products(id) ON DELETE CASCADE,
  vendor_sku VARCHAR(255),
  vendor_price DECIMAL(10,2) NOT NULL,
  minimum_quantity INTEGER DEFAULT 1,
  lead_time_override INTEGER, -- Override vendor's default lead time
  is_preferred BOOLEAN DEFAULT false, -- Mark as preferred vendor for this product
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
-- 5. ADD VENDOR REFERENCE TO PRODUCTS TABLE
-- =====================================================

ALTER TABLE products 
ADD COLUMN IF NOT EXISTS vendor_id UUID REFERENCES vendors(id),
ADD COLUMN IF NOT EXISTS vendor_price DECIMAL(10,2);

-- =====================================================
-- 6. ADD ORDER TYPE TO ORDERS TABLE
-- =====================================================

ALTER TABLE orders
ADD COLUMN IF NOT EXISTS order_type VARCHAR(50) DEFAULT 'regular' CHECK (order_type IN ('regular', 'dropship', 'mixed'));

-- =====================================================
-- 7. INDEXES FOR PERFORMANCE
-- =====================================================

CREATE INDEX IF NOT EXISTS idx_vendors_status ON vendors(status);
CREATE INDEX IF NOT EXISTS idx_vendors_dropship_enabled ON vendors(dropship_enabled);

CREATE INDEX IF NOT EXISTS idx_dropship_orders_parent ON dropship_orders(parent_order_id);
CREATE INDEX IF NOT EXISTS idx_dropship_orders_vendor ON dropship_orders(vendor_id);
CREATE INDEX IF NOT EXISTS idx_dropship_orders_status ON dropship_orders(status);
CREATE INDEX IF NOT EXISTS idx_dropship_orders_created ON dropship_orders(created_at DESC);

CREATE INDEX IF NOT EXISTS idx_vendor_products_vendor ON vendor_products(vendor_id);
CREATE INDEX IF NOT EXISTS idx_vendor_products_product ON vendor_products(product_id);

CREATE INDEX IF NOT EXISTS idx_vendor_communications_vendor ON vendor_communications(vendor_id);
CREATE INDEX IF NOT EXISTS idx_vendor_communications_order ON vendor_communications(dropship_order_id);

-- =====================================================
-- 8. ROW LEVEL SECURITY
-- =====================================================

ALTER TABLE vendors ENABLE ROW LEVEL SECURITY;
ALTER TABLE dropship_orders ENABLE ROW LEVEL SECURITY;
ALTER TABLE vendor_products ENABLE ROW LEVEL SECURITY;
ALTER TABLE vendor_communications ENABLE ROW LEVEL SECURITY;

-- Admin-only policies
CREATE POLICY "Admin full access to vendors" ON vendors
  FOR ALL USING (auth.jwt() ->> 'role' = 'admin');

CREATE POLICY "Admin full access to dropship_orders" ON dropship_orders
  FOR ALL USING (auth.jwt() ->> 'role' = 'admin');

CREATE POLICY "Admin full access to vendor_products" ON vendor_products
  FOR ALL USING (auth.jwt() ->> 'role' = 'admin');

CREATE POLICY "Admin full access to vendor_communications" ON vendor_communications
  FOR ALL USING (auth.jwt() ->> 'role' = 'admin');

-- =====================================================
-- 9. HELPER FUNCTIONS
-- =====================================================

-- Function to get preferred vendor for a product
CREATE OR REPLACE FUNCTION get_preferred_vendor(p_product_id UUID)
RETURNS UUID AS $$
DECLARE
  vendor_id UUID;
BEGIN
  SELECT vp.vendor_id INTO vendor_id
  FROM vendor_products vp
  JOIN vendors v ON v.id = vp.vendor_id
  WHERE vp.product_id = p_product_id
    AND vp.is_preferred = true
    AND v.status = 'active'
    AND v.dropship_enabled = true
  LIMIT 1;
  
  -- If no preferred vendor, get the one with lowest price
  IF vendor_id IS NULL THEN
    SELECT vp.vendor_id INTO vendor_id
    FROM vendor_products vp
    JOIN vendors v ON v.id = vp.vendor_id
    WHERE vp.product_id = p_product_id
      AND v.status = 'active'
      AND v.dropship_enabled = true
    ORDER BY vp.vendor_price ASC
    LIMIT 1;
  END IF;
  
  RETURN vendor_id;
END;
$$ LANGUAGE plpgsql;

-- Function to calculate vendor order totals
CREATE OR REPLACE FUNCTION calculate_vendor_order_total(p_dropship_order_id UUID)
RETURNS TABLE(
  item_total DECIMAL(10,2),
  shipping_cost DECIMAL(10,2),
  total_cost DECIMAL(10,2)
) AS $$
DECLARE
  items_total DECIMAL(10,2);
  shipping DECIMAL(10,2);
BEGIN
  SELECT 
    COALESCE(SUM((item->>'vendor_price')::DECIMAL * (item->>'quantity')::INTEGER), 0),
    COALESCE(vendor_shipping, 0)
  INTO items_total, shipping
  FROM dropship_orders,
    jsonb_array_elements(items) AS item
  WHERE id = p_dropship_order_id
  GROUP BY vendor_shipping;
  
  RETURN QUERY
  SELECT 
    items_total,
    shipping,
    items_total + shipping;
END;
$$ LANGUAGE plpgsql;

-- =====================================================
-- 10. TRIGGERS
-- =====================================================

-- Update timestamp trigger for vendors
CREATE TRIGGER update_vendors_updated_at BEFORE UPDATE ON vendors
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();

-- Update timestamp trigger for dropship_orders
CREATE TRIGGER update_dropship_orders_updated_at BEFORE UPDATE ON dropship_orders
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();

-- Update timestamp trigger for vendor_products
CREATE TRIGGER update_vendor_products_updated_at BEFORE UPDATE ON vendor_products
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();

-- =====================================================
-- 11. SAMPLE VENDOR DATA
-- =====================================================

-- Insert sample vendors
INSERT INTO vendors (name, email, phone, dropship_enabled, auto_send_orders, lead_time_days, notes)
VALUES 
  ('Premium Suits Co', 'orders@premiumsuits.com', '555-0100', true, true, 5, 'Main suit supplier, fast shipping'),
  ('Luxury Tuxedos Ltd', 'sales@luxurytux.com', '555-0200', true, false, 7, 'High-end tuxedos, manual order confirmation required'),
  ('Accessories Direct', 'fulfill@accessoriesdirect.com', '555-0300', true, true, 3, 'Ties, cufflinks, pocket squares')
ON CONFLICT DO NOTHING;

-- =====================================================
-- 12. GRANT PERMISSIONS
-- =====================================================

GRANT ALL ON vendors TO authenticated;
GRANT ALL ON dropship_orders TO authenticated;
GRANT ALL ON vendor_products TO authenticated;
GRANT ALL ON vendor_communications TO authenticated;

-- =====================================================
-- VERIFICATION QUERIES
-- =====================================================

-- Check all vendor-related tables created
SELECT table_name 
FROM information_schema.tables 
WHERE table_schema = 'public' 
  AND table_name IN ('vendors', 'dropship_orders', 'vendor_products', 'vendor_communications')
ORDER BY table_name;

-- Check vendor count
SELECT COUNT(*) as vendor_count FROM vendors;

-- Check if columns were added to existing tables
SELECT column_name, data_type
FROM information_schema.columns
WHERE table_name = 'products' AND column_name IN ('vendor_id', 'vendor_price')
UNION ALL
SELECT column_name, data_type
FROM information_schema.columns
WHERE table_name = 'orders' AND column_name = 'order_type';

-- Summary
SELECT 
  'Vendor and Dropship tables setup completed!' as message,
  NOW() as completed_at;