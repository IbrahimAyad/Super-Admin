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
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Create indexes for order_status_history
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

-- Create indexes for shipping_labels
CREATE INDEX IF NOT EXISTS idx_shipping_labels_order ON shipping_labels(order_id);
CREATE INDEX IF NOT EXISTS idx_shipping_labels_tracking ON shipping_labels(tracking_number);

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
ADD COLUMN IF NOT EXISTS return_requested_at TIMESTAMPTZ,
ADD COLUMN IF NOT EXISTS return_approved_at TIMESTAMPTZ;

-- Function to update order status and track history
CREATE OR REPLACE FUNCTION update_order_status(
  p_order_id UUID,
  p_new_status VARCHAR(50),
  p_notes TEXT DEFAULT NULL,
  p_user_id UUID DEFAULT NULL
)
RETURNS BOOLEAN AS $$
DECLARE
  v_current_status VARCHAR(50);
  v_valid_transition BOOLEAN := false;
BEGIN
  -- Get current status
  SELECT status INTO v_current_status
  FROM orders WHERE id = p_order_id;
  
  -- Validate status transition
  CASE v_current_status
    WHEN 'pending' THEN
      v_valid_transition := p_new_status IN ('confirmed', 'cancelled');
    WHEN 'confirmed' THEN
      v_valid_transition := p_new_status IN ('processing', 'cancelled');
    WHEN 'processing' THEN
      v_valid_transition := p_new_status IN ('shipped', 'cancelled');
    WHEN 'shipped' THEN
      v_valid_transition := p_new_status IN ('delivered', 'returned');
    WHEN 'delivered' THEN
      v_valid_transition := p_new_status IN ('returned');
    ELSE
      v_valid_transition := false;
  END CASE;
  
  IF NOT v_valid_transition THEN
    RAISE EXCEPTION 'Invalid status transition from % to %', v_current_status, p_new_status;
  END IF;
  
  -- Update order status
  UPDATE orders SET
    status = p_new_status,
    updated_at = NOW(),
    confirmed_at = CASE WHEN p_new_status = 'confirmed' THEN NOW() ELSE confirmed_at END,
    processing_at = CASE WHEN p_new_status = 'processing' THEN NOW() ELSE processing_at END,
    shipped_at = CASE WHEN p_new_status = 'shipped' THEN NOW() ELSE shipped_at END,
    delivered_at = CASE WHEN p_new_status = 'delivered' THEN NOW() ELSE delivered_at END,
    cancelled_at = CASE WHEN p_new_status = 'cancelled' THEN NOW() ELSE cancelled_at END
  WHERE id = p_order_id;
  
  -- Record history
  INSERT INTO order_status_history (
    order_id,
    status,
    notes,
    created_by
  ) VALUES (
    p_order_id,
    p_new_status,
    p_notes,
    p_user_id
  );
  
  RETURN true;
END;
$$ LANGUAGE plpgsql;

-- Function to bulk update order statuses
CREATE OR REPLACE FUNCTION bulk_update_order_status(
  p_order_ids UUID[],
  p_new_status VARCHAR(50),
  p_notes TEXT DEFAULT NULL,
  p_user_id UUID DEFAULT NULL
)
RETURNS INTEGER AS $$
DECLARE
  v_order_id UUID;
  v_count INTEGER := 0;
BEGIN
  FOREACH v_order_id IN ARRAY p_order_ids
  LOOP
    BEGIN
      PERFORM update_order_status(v_order_id, p_new_status, p_notes, p_user_id);
      v_count := v_count + 1;
    EXCEPTION
      WHEN OTHERS THEN
        -- Log error but continue with other orders
        RAISE NOTICE 'Failed to update order %: %', v_order_id, SQLERRM;
    END;
  END LOOP;
  
  RETURN v_count;
END;
$$ LANGUAGE plpgsql;

-- RLS Policies
ALTER TABLE order_status_history ENABLE ROW LEVEL SECURITY;
ALTER TABLE shipping_labels ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Admin can view order history" ON order_status_history
  FOR SELECT USING (true);

CREATE POLICY "Admin can create order history" ON order_status_history
  FOR INSERT WITH CHECK (true);

CREATE POLICY "Admin can manage shipping labels" ON shipping_labels
  FOR ALL USING (true);

-- Grants
GRANT ALL ON order_status_history TO authenticated;
GRANT ALL ON shipping_labels TO authenticated;
GRANT EXECUTE ON FUNCTION update_order_status(UUID, VARCHAR(50), TEXT, UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION bulk_update_order_status(UUID[], VARCHAR(50), TEXT, UUID) TO authenticated;