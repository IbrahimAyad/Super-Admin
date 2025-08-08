-- ============================================
-- FIX FOR INVENTORY AUTOMATION - ADAPTED TO YOUR SCHEMA
-- ============================================

-- Your schema has inventory directly in product_variants table
-- No separate inventory table needed!

-- Drop tables that will be recreated
DROP TABLE IF EXISTS inventory_movements CASCADE;
DROP TABLE IF EXISTS low_stock_alerts CASCADE;
DROP TABLE IF EXISTS inventory_thresholds CASCADE;

-- Drop functions if they exist
DROP FUNCTION IF EXISTS sync_inventory_on_order() CASCADE;
DROP FUNCTION IF EXISTS sync_inventory_on_refund() CASCADE;
DROP FUNCTION IF EXISTS check_low_stock(UUID) CASCADE;
DROP FUNCTION IF EXISTS check_all_low_stock() CASCADE;
DROP FUNCTION IF EXISTS get_inventory_status() CASCADE;

-- ============================================
-- CREATE NEW TABLES
-- ============================================

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

-- ============================================
-- INVENTORY SYNC FUNCTIONS - ADAPTED FOR YOUR SCHEMA
-- ============================================

-- Function to sync inventory on order confirmation (works with product_variants table)
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
      v_variant_id := NULL;
      
      -- Try to get variant_id from the item
      IF v_item.value->>'variant_id' IS NOT NULL THEN
        v_variant_id := (v_item.value->>'variant_id')::uuid;
      -- Look up by SKU
      ELSIF v_item.value->>'sku' IS NOT NULL THEN
        SELECT id INTO v_variant_id 
        FROM product_variants 
        WHERE sku = v_item.value->>'sku'
        LIMIT 1;
      -- Look up by product_id and option values
      ELSIF v_item.value->>'product_id' IS NOT NULL THEN
        SELECT id INTO v_variant_id 
        FROM product_variants 
        WHERE product_id = (v_item.value->>'product_id')::uuid
          AND (option1 = v_item.value->>'option1' OR v_item.value->>'option1' IS NULL)
          AND (option2 = v_item.value->>'option2' OR v_item.value->>'option2' IS NULL)
          AND (option3 = v_item.value->>'option3' OR v_item.value->>'option3' IS NULL)
        LIMIT 1;
      END IF;
      
      IF v_variant_id IS NOT NULL THEN
        -- Get current available inventory from product_variants
        SELECT available_quantity INTO v_available
        FROM product_variants
        WHERE id = v_variant_id
        FOR UPDATE;
        
        -- Only deduct if we have enough inventory
        IF v_available IS NULL OR v_available >= (v_item.value->>'quantity')::integer THEN
          -- Deduct inventory from product_variants table
          UPDATE product_variants
          SET 
            available_quantity = COALESCE(available_quantity, inventory_quantity, 0) - (v_item.value->>'quantity')::integer,
            inventory_quantity = COALESCE(inventory_quantity, available_quantity, 0) - (v_item.value->>'quantity')::integer,
            updated_at = NOW()
          WHERE id = v_variant_id;
          
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
          
          -- Check for low stock
          PERFORM check_low_stock(v_variant_id);
        END IF;
      END IF;
    END LOOP;
  END IF;
  
  -- Handle order cancellation - restore inventory
  IF NEW.status = 'cancelled' AND OLD.status != 'cancelled' THEN
    FOR v_item IN 
      SELECT * FROM jsonb_array_elements(NEW.items) AS item
    LOOP
      v_variant_id := NULL;
      
      -- Get variant_id using same logic as above
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
          AND (option1 = v_item.value->>'option1' OR v_item.value->>'option1' IS NULL)
          AND (option2 = v_item.value->>'option2' OR v_item.value->>'option2' IS NULL)
          AND (option3 = v_item.value->>'option3' OR v_item.value->>'option3' IS NULL)
        LIMIT 1;
      END IF;
      
      IF v_variant_id IS NOT NULL THEN
        -- Restore inventory in product_variants table
        UPDATE product_variants
        SET 
          available_quantity = COALESCE(available_quantity, 0) + (v_item.value->>'quantity')::integer,
          inventory_quantity = COALESCE(inventory_quantity, 0) + (v_item.value->>'quantity')::integer,
          updated_at = NOW()
        WHERE id = v_variant_id;
        
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

-- Function to check and alert for low stock (adapted for product_variants table)
CREATE OR REPLACE FUNCTION check_low_stock(p_variant_id UUID)
RETURNS VOID AS $$
DECLARE
  v_current_stock INTEGER;
  v_threshold INTEGER;
  v_product_id UUID;
  v_alert_exists BOOLEAN;
BEGIN
  -- Get current stock from product_variants and threshold
  SELECT 
    COALESCE(pv.available_quantity, pv.inventory_quantity, 0),
    COALESCE(it.low_stock_threshold, 10),
    pv.product_id
  INTO v_current_stock, v_threshold, v_product_id
  FROM product_variants pv
  LEFT JOIN inventory_thresholds it ON it.variant_id = pv.id
  WHERE pv.id = p_variant_id;
  
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
      
      -- Queue email notification
      INSERT INTO email_queue (
        to_email,
        subject,
        template,
        data
      ) VALUES (
        'admin@kctmenswear.com',
        'Low Stock Alert',
        'low_stock_alert',
        jsonb_build_object(
          'variantId', p_variant_id,
          'currentStock', v_current_stock,
          'threshold', v_threshold
        )
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

-- Function to process refunds and restore inventory
CREATE OR REPLACE FUNCTION sync_inventory_on_refund()
RETURNS TRIGGER AS $$
DECLARE
  v_order RECORD;
  v_item RECORD;
  v_variant_id UUID;
BEGIN
  -- Only process when refund is approved
  IF NEW.status = 'approved' AND OLD.status != 'approved' THEN
    -- Get the order
    SELECT * INTO v_order
    FROM orders
    WHERE id = NEW.order_id;
    
    -- Restore inventory for each item
    IF v_order.items IS NOT NULL THEN
      FOR v_item IN 
        SELECT * FROM jsonb_array_elements(v_order.items) AS item
      LOOP
        v_variant_id := NULL;
        
        -- Get variant_id
        IF v_item.value->>'variant_id' IS NOT NULL THEN
          v_variant_id := (v_item.value->>'variant_id')::uuid;
        ELSIF v_item.value->>'sku' IS NOT NULL THEN
          SELECT id INTO v_variant_id 
          FROM product_variants 
          WHERE sku = v_item.value->>'sku'
          LIMIT 1;
        END IF;
        
        IF v_variant_id IS NOT NULL THEN
          -- Restore inventory in product_variants
          UPDATE product_variants
          SET 
            available_quantity = COALESCE(available_quantity, 0) + (v_item.value->>'quantity')::integer,
            inventory_quantity = COALESCE(inventory_quantity, 0) + (v_item.value->>'quantity')::integer,
            updated_at = NOW()
          WHERE id = v_variant_id;
          
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
            'refund',
            NEW.id,
            'Refund approved for Order #' || v_order.order_number
          );
        END IF;
      END LOOP;
    END IF;
  END IF;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Function to get inventory status summary (adapted for product_variants)
CREATE OR REPLACE FUNCTION get_inventory_status()
RETURNS TABLE (
  total_products INTEGER,
  total_variants INTEGER,
  low_stock_items INTEGER,
  out_of_stock_items INTEGER,
  total_stock_value DECIMAL,
  items_on_order INTEGER
) AS $$
BEGIN
  RETURN QUERY
  SELECT 
    COUNT(DISTINCT pv.product_id)::INTEGER as total_products,
    COUNT(DISTINCT pv.id)::INTEGER as total_variants,
    COUNT(CASE WHEN COALESCE(pv.available_quantity, pv.inventory_quantity, 0) <= COALESCE(it.low_stock_threshold, 10) 
               AND COALESCE(pv.available_quantity, pv.inventory_quantity, 0) > 0 THEN 1 END)::INTEGER as low_stock_items,
    COUNT(CASE WHEN COALESCE(pv.available_quantity, pv.inventory_quantity, 0) = 0 THEN 1 END)::INTEGER as out_of_stock_items,
    SUM(COALESCE(pv.available_quantity, pv.inventory_quantity, 0) * pv.price)::DECIMAL as total_stock_value,
    COUNT(CASE WHEN COALESCE(pv.reserved_quantity, 0) > 0 THEN 1 END)::INTEGER as items_on_order
  FROM product_variants pv
  LEFT JOIN inventory_thresholds it ON it.variant_id = pv.id;
END;
$$ LANGUAGE plpgsql;

-- Function to check all products for low stock
CREATE OR REPLACE FUNCTION check_all_low_stock()
RETURNS INTEGER AS $$
DECLARE
  v_count INTEGER := 0;
  v_variant RECORD;
BEGIN
  FOR v_variant IN 
    SELECT id FROM product_variants
  LOOP
    PERFORM check_low_stock(v_variant.id);
    v_count := v_count + 1;
  END LOOP;
  
  RETURN v_count;
END;
$$ LANGUAGE plpgsql;

-- ============================================
-- TRIGGERS
-- ============================================

-- Trigger for order inventory sync
DROP TRIGGER IF EXISTS trigger_sync_inventory_on_order ON orders;
CREATE TRIGGER trigger_sync_inventory_on_order
AFTER INSERT OR UPDATE OF status ON orders
FOR EACH ROW
EXECUTE FUNCTION sync_inventory_on_order();

-- Trigger for refund inventory sync
DROP TRIGGER IF EXISTS trigger_sync_inventory_on_refund ON refund_requests;
CREATE TRIGGER trigger_sync_inventory_on_refund
AFTER UPDATE OF status ON refund_requests
FOR EACH ROW
EXECUTE FUNCTION sync_inventory_on_refund();

-- ============================================
-- INITIAL DATA
-- ============================================

-- Set default thresholds for existing products
INSERT INTO inventory_thresholds (variant_id, low_stock_threshold, reorder_point, reorder_quantity)
SELECT 
  id,
  10, -- Low stock at 10 units
  20, -- Reorder at 20 units
  50  -- Order 50 units
FROM product_variants
ON CONFLICT (variant_id) DO NOTHING;

-- ============================================
-- PERMISSIONS
-- ============================================

ALTER TABLE inventory_movements ENABLE ROW LEVEL SECURITY;
ALTER TABLE low_stock_alerts ENABLE ROW LEVEL SECURITY;
ALTER TABLE inventory_thresholds ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Admin can manage inventory movements" ON inventory_movements
  FOR ALL USING (true);

CREATE POLICY "Admin can manage low stock alerts" ON low_stock_alerts
  FOR ALL USING (true);

CREATE POLICY "Admin can manage inventory thresholds" ON inventory_thresholds
  FOR ALL USING (true);

GRANT ALL ON inventory_movements TO authenticated;
GRANT ALL ON low_stock_alerts TO authenticated;
GRANT ALL ON inventory_thresholds TO authenticated;
GRANT EXECUTE ON FUNCTION check_low_stock(UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION check_all_low_stock() TO authenticated;
GRANT EXECUTE ON FUNCTION get_inventory_status() TO authenticated;