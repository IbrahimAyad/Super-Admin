-- ============================================
-- DIAGNOSTIC: Check existing table structure
-- ============================================

-- First, let's see what columns exist in the inventory table
SELECT column_name, data_type 
FROM information_schema.columns 
WHERE table_name = 'inventory'
ORDER BY ordinal_position;

-- Check if product_variants table exists and its structure
SELECT column_name, data_type 
FROM information_schema.columns 
WHERE table_name = 'product_variants'
ORDER BY ordinal_position;

-- ============================================
-- FIX FOR INVENTORY AUTOMATION MIGRATION (055)
-- ============================================

-- Drop tables that will be recreated (safe - they're new tables)
DROP TABLE IF EXISTS inventory_movements CASCADE;
DROP TABLE IF EXISTS low_stock_alerts CASCADE;
DROP TABLE IF EXISTS inventory_thresholds CASCADE;

-- Drop functions if they exist
DROP FUNCTION IF EXISTS sync_inventory_on_order() CASCADE;
DROP FUNCTION IF EXISTS sync_inventory_on_refund() CASCADE;
DROP FUNCTION IF EXISTS check_low_stock(UUID) CASCADE;
DROP FUNCTION IF EXISTS check_all_low_stock() CASCADE;
DROP FUNCTION IF EXISTS cleanup_expired_stock_reservations() CASCADE;
DROP FUNCTION IF EXISTS get_inventory_status() CASCADE;
DROP FUNCTION IF EXISTS scheduled_cleanup_reservations() CASCADE;

-- Check if inventory table has variant_id or product_variant_id
DO $$
BEGIN
    -- Add variant_id column if it doesn't exist
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'inventory' 
                   AND column_name = 'variant_id') THEN
        
        -- Check if there's a product_variant_id column instead
        IF EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'inventory' 
                   AND column_name = 'product_variant_id') THEN
            -- Rename product_variant_id to variant_id for consistency
            ALTER TABLE inventory RENAME COLUMN product_variant_id TO variant_id;
        ELSE
            -- Add variant_id column if neither exists
            ALTER TABLE inventory ADD COLUMN variant_id UUID REFERENCES product_variants(id);
            
            -- Try to populate it from product_id if that exists
            IF EXISTS (SELECT 1 FROM information_schema.columns 
                       WHERE table_name = 'inventory' 
                       AND column_name = 'product_id') THEN
                -- This assumes a 1:1 relationship for now
                UPDATE inventory i
                SET variant_id = (
                    SELECT id FROM product_variants pv 
                    WHERE pv.product_id = i.product_id 
                    LIMIT 1
                )
                WHERE variant_id IS NULL;
            END IF;
        END IF;
    END IF;
END
$$;

-- Now create the new tables with proper structure

-- Inventory Movements Table (audit trail)
CREATE TABLE IF NOT EXISTS inventory_movements (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  variant_id UUID REFERENCES product_variants(id) ON DELETE CASCADE,
  movement_type VARCHAR(50) NOT NULL, -- 'sale', 'return', 'restock', 'adjustment', 'reservation'
  quantity INTEGER NOT NULL, -- Positive for additions, negative for deductions
  reference_type VARCHAR(50), -- 'order', 'refund', 'manual', 'reservation'
  reference_id UUID, -- Order ID, Refund ID, etc.
  notes TEXT,
  created_by UUID REFERENCES auth.users(id),
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Create indexes for inventory_movements
CREATE INDEX IF NOT EXISTS idx_inventory_movements_variant ON inventory_movements(variant_id);
CREATE INDEX IF NOT EXISTS idx_inventory_movements_type ON inventory_movements(movement_type);
CREATE INDEX IF NOT EXISTS idx_inventory_movements_created ON inventory_movements(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_inventory_movements_reference ON inventory_movements(reference_type, reference_id);

-- Low Stock Alerts Table
CREATE TABLE IF NOT EXISTS low_stock_alerts (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  variant_id UUID REFERENCES product_variants(id) ON DELETE CASCADE,
  product_id UUID REFERENCES products(id) ON DELETE CASCADE,
  current_stock INTEGER NOT NULL,
  threshold INTEGER NOT NULL,
  alert_sent BOOLEAN DEFAULT false,
  alert_sent_at TIMESTAMPTZ,
  resolved BOOLEAN DEFAULT false,
  resolved_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Create indexes for low_stock_alerts
CREATE INDEX IF NOT EXISTS idx_low_stock_alerts_variant ON low_stock_alerts(variant_id);
CREATE INDEX IF NOT EXISTS idx_low_stock_alerts_resolved ON low_stock_alerts(resolved);
CREATE INDEX IF NOT EXISTS idx_low_stock_alerts_created ON low_stock_alerts(created_at DESC);

-- Inventory Thresholds Table
CREATE TABLE IF NOT EXISTS inventory_thresholds (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  variant_id UUID REFERENCES product_variants(id) ON DELETE CASCADE UNIQUE,
  low_stock_threshold INTEGER DEFAULT 10,
  reorder_point INTEGER DEFAULT 20,
  reorder_quantity INTEGER DEFAULT 50,
  auto_reorder BOOLEAN DEFAULT false,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Simplified inventory sync function (handles both variant_id in items or separate lookup)
CREATE OR REPLACE FUNCTION sync_inventory_on_order()
RETURNS TRIGGER AS $$
DECLARE
  v_item RECORD;
  v_variant_id UUID;
  v_available INTEGER;
BEGIN
  -- Only process when order is confirmed
  IF NEW.status = 'confirmed' AND (OLD.status IS NULL OR OLD.status != 'confirmed') THEN
    -- Process each item in the order
    FOR v_item IN 
      SELECT * FROM jsonb_array_elements(NEW.items) AS item
    LOOP
      -- Try to get variant_id from the item or look it up
      v_variant_id := NULL;
      
      -- First try: variant_id directly in item
      IF v_item.value->>'variant_id' IS NOT NULL THEN
        v_variant_id := (v_item.value->>'variant_id')::uuid;
      -- Second try: look up by SKU
      ELSIF v_item.value->>'sku' IS NOT NULL THEN
        SELECT id INTO v_variant_id 
        FROM product_variants 
        WHERE sku = v_item.value->>'sku'
        LIMIT 1;
      -- Third try: look up by product_id if only one variant
      ELSIF v_item.value->>'product_id' IS NOT NULL THEN
        SELECT id INTO v_variant_id 
        FROM product_variants 
        WHERE product_id = (v_item.value->>'product_id')::uuid
        LIMIT 1;
      END IF;
      
      IF v_variant_id IS NOT NULL THEN
        -- Get current available inventory
        SELECT available_quantity INTO v_available
        FROM inventory
        WHERE variant_id = v_variant_id
        FOR UPDATE;
        
        -- Only deduct if we have enough inventory
        IF v_available >= (v_item.value->>'quantity')::integer THEN
          -- Deduct inventory
          UPDATE inventory
          SET 
            available_quantity = available_quantity - (v_item.value->>'quantity')::integer,
            updated_at = NOW()
          WHERE variant_id = v_variant_id;
          
          -- Record movement
          INSERT INTO inventory_movements (
            variant_id,
            movement_type,
            quantity,
            reference_type,
            reference_id,
            notes
          ) VALUES (
            v_variant_id,
            'sale',
            -(v_item.value->>'quantity')::integer,
            'order',
            NEW.id,
            'Order #' || NEW.order_number || ' confirmed'
          );
        END IF;
      END IF;
    END LOOP;
  END IF;
  
  -- Handle order cancellation - restore inventory
  IF NEW.status = 'cancelled' AND OLD.status != 'cancelled' THEN
    FOR v_item IN 
      SELECT * FROM jsonb_array_elements(NEW.items) AS item
    LOOP
      -- Get variant_id using same logic as above
      v_variant_id := NULL;
      
      IF v_item.value->>'variant_id' IS NOT NULL THEN
        v_variant_id := (v_item.value->>'variant_id')::uuid;
      ELSIF v_item.value->>'sku' IS NOT NULL THEN
        SELECT id INTO v_variant_id 
        FROM product_variants 
        WHERE sku = v_item.value->>'sku'
        LIMIT 1;
      ELSIF v_item.value->>'product_id' IS NOT NULL THEN
        SELECT id INTO v_variant_id 
        FROM product_variants 
        WHERE product_id = (v_item.value->>'product_id')::uuid
        LIMIT 1;
      END IF;
      
      IF v_variant_id IS NOT NULL THEN
        -- Restore inventory
        UPDATE inventory
        SET 
          available_quantity = available_quantity + (v_item.value->>'quantity')::integer,
          updated_at = NOW()
        WHERE variant_id = v_variant_id;
        
        -- Record movement
        INSERT INTO inventory_movements (
          variant_id,
          movement_type,
          quantity,
          reference_type,
          reference_id,
          notes
        ) VALUES (
          v_variant_id,
          'return',
          (v_item.value->>'quantity')::integer,
          'order',
          NEW.id,
          'Order #' || NEW.order_number || ' cancelled - inventory restored'
        );
      END IF;
    END LOOP;
  END IF;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Simplified check low stock function
CREATE OR REPLACE FUNCTION check_low_stock(p_variant_id UUID)
RETURNS VOID AS $$
DECLARE
  v_current_stock INTEGER;
  v_threshold INTEGER;
  v_product_id UUID;
  v_alert_exists BOOLEAN;
BEGIN
  -- Get current stock and threshold
  SELECT 
    i.available_quantity,
    COALESCE(it.low_stock_threshold, 10),
    pv.product_id
  INTO v_current_stock, v_threshold, v_product_id
  FROM inventory i
  JOIN product_variants pv ON pv.id = i.variant_id
  LEFT JOIN inventory_thresholds it ON it.variant_id = i.variant_id
  WHERE i.variant_id = p_variant_id;
  
  -- Check if stock is below threshold
  IF v_current_stock <= v_threshold THEN
    -- Check if alert already exists and is unresolved
    SELECT EXISTS(
      SELECT 1 FROM low_stock_alerts
      WHERE variant_id = p_variant_id
        AND resolved = false
    ) INTO v_alert_exists;
    
    -- Create alert if it doesn't exist
    IF NOT v_alert_exists THEN
      INSERT INTO low_stock_alerts (
        variant_id,
        product_id,
        current_stock,
        threshold
      ) VALUES (
        p_variant_id,
        v_product_id,
        v_current_stock,
        v_threshold
      );
    END IF;
  ELSE
    -- Resolve any existing alerts if stock is restored
    UPDATE low_stock_alerts
    SET 
      resolved = true,
      resolved_at = NOW()
    WHERE variant_id = p_variant_id
      AND resolved = false;
  END IF;
END;
$$ LANGUAGE plpgsql;

-- Create trigger for order inventory sync
DROP TRIGGER IF EXISTS trigger_sync_inventory_on_order ON orders;
CREATE TRIGGER trigger_sync_inventory_on_order
AFTER INSERT OR UPDATE OF status ON orders
FOR EACH ROW
EXECUTE FUNCTION sync_inventory_on_order();

-- Set default thresholds for existing products
INSERT INTO inventory_thresholds (variant_id, low_stock_threshold, reorder_point, reorder_quantity)
SELECT 
  id,
  10, -- Low stock at 10 units
  20, -- Reorder at 20 units
  50  -- Order 50 units
FROM product_variants
ON CONFLICT (variant_id) DO NOTHING;

-- Enable RLS
ALTER TABLE inventory_movements ENABLE ROW LEVEL SECURITY;
ALTER TABLE low_stock_alerts ENABLE ROW LEVEL SECURITY;
ALTER TABLE inventory_thresholds ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Admin can manage inventory movements" ON inventory_movements
  FOR ALL USING (true);

CREATE POLICY "Admin can manage low stock alerts" ON low_stock_alerts
  FOR ALL USING (true);

CREATE POLICY "Admin can manage inventory thresholds" ON inventory_thresholds
  FOR ALL USING (true);

-- Grants
GRANT ALL ON inventory_movements TO authenticated;
GRANT ALL ON low_stock_alerts TO authenticated;
GRANT ALL ON inventory_thresholds TO authenticated;
GRANT EXECUTE ON FUNCTION check_low_stock(UUID) TO authenticated;