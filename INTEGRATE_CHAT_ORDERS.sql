-- INTEGRATE CHAT ORDERS WITH MAIN ORDER SYSTEM
-- Run this in Supabase SQL Editor after creating chat order tables

-- Add source column to orders table if it doesn't exist
ALTER TABLE orders 
ADD COLUMN IF NOT EXISTS source VARCHAR(50) DEFAULT 'standard';

-- Add metadata column for storing additional info
ALTER TABLE orders
ADD COLUMN IF NOT EXISTS metadata JSONB;

-- Add customer_email if missing (for guest checkouts)
ALTER TABLE orders
ADD COLUMN IF NOT EXISTS customer_email VARCHAR(255);

-- Create index for source column for better performance
CREATE INDEX IF NOT EXISTS idx_orders_source ON orders(source);
CREATE INDEX IF NOT EXISTS idx_orders_customer_email ON orders(customer_email);

-- Update existing orders to have source = 'standard' if null
UPDATE orders 
SET source = 'standard' 
WHERE source IS NULL;

-- Create a view that combines both order tables for unified reporting
CREATE OR REPLACE VIEW unified_orders AS
SELECT 
  o.id,
  o.order_number,
  o.customer_id,
  COALESCE(o.customer_email, c.email) as customer_email,
  o.status,
  o.order_type,
  o.total_amount,
  o.payment_status,
  o.payment_method,
  o.source,
  o.created_at,
  o.updated_at,
  -- Include chat order details if available
  co.checkout_session_id,
  co.stripe_payment_intent_id as chat_payment_intent,
  CASE 
    WHEN o.source = 'chat_commerce' THEN true
    ELSE false
  END as is_chat_order,
  o.metadata
FROM orders o
LEFT JOIN customers c ON o.customer_id = c.id
LEFT JOIN chat_orders co ON o.order_number = co.order_number;

-- Create function to sync chat orders automatically
CREATE OR REPLACE FUNCTION sync_chat_order_to_main()
RETURNS TRIGGER AS $$
BEGIN
  -- Only sync if payment is confirmed
  IF NEW.payment_status = 'paid' THEN
    -- Check if order already exists in main table
    IF NOT EXISTS (
      SELECT 1 FROM orders 
      WHERE order_number = NEW.order_number
    ) THEN
      -- Insert into main orders table
      INSERT INTO orders (
        order_number,
        customer_email,
        status,
        order_type,
        subtotal,
        total_amount,
        payment_status,
        payment_method,
        source,
        metadata,
        created_at
      ) VALUES (
        NEW.order_number,
        NEW.customer_email,
        CASE 
          WHEN NEW.status = 'pending' THEN 'confirmed'
          ELSE NEW.status
        END,
        'standard',
        NEW.subtotal,
        NEW.total_amount,
        NEW.payment_status,
        'stripe',
        'chat_commerce',
        jsonb_build_object(
          'chat_order_id', NEW.id,
          'checkout_session_id', NEW.checkout_session_id,
          'stripe_payment_intent_id', NEW.stripe_payment_intent_id,
          'synced_from_chat', true,
          'synced_at', NOW()
        ),
        NEW.created_at
      );
      
      -- Log the sync
      RAISE NOTICE 'Chat order % synced to main orders table', NEW.order_number;
    END IF;
  END IF;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger for automatic syncing
DROP TRIGGER IF EXISTS sync_chat_order_trigger ON chat_orders;
CREATE TRIGGER sync_chat_order_trigger
AFTER INSERT OR UPDATE ON chat_orders
FOR EACH ROW
EXECUTE FUNCTION sync_chat_order_to_main();

-- Grant permissions for the view
GRANT SELECT ON unified_orders TO anon, authenticated;

-- Sync any existing paid chat orders
INSERT INTO orders (
  order_number,
  customer_email,
  status,
  order_type,
  subtotal,
  total_amount,
  payment_status,
  payment_method,
  source,
  metadata,
  created_at
)
SELECT 
  co.order_number,
  co.customer_email,
  CASE 
    WHEN co.status = 'pending' THEN 'confirmed'
    ELSE co.status
  END,
  'standard',
  co.subtotal,
  co.total_amount,
  co.payment_status,
  'stripe',
  'chat_commerce',
  jsonb_build_object(
    'chat_order_id', co.id,
    'checkout_session_id', co.checkout_session_id,
    'stripe_payment_intent_id', co.stripe_payment_intent_id,
    'synced_from_chat', true,
    'synced_at', NOW()
  ),
  co.created_at
FROM chat_orders co
WHERE co.payment_status = 'paid'
AND NOT EXISTS (
  SELECT 1 FROM orders o 
  WHERE o.order_number = co.order_number
);

-- Verify integration
SELECT 
  'Integration Status' as check_type,
  COUNT(DISTINCT o.order_number) as total_orders,
  COUNT(DISTINCT CASE WHEN o.source = 'chat_commerce' THEN o.order_number END) as chat_orders,
  COUNT(DISTINCT CASE WHEN o.source = 'standard' THEN o.order_number END) as standard_orders,
  'Orders table ready for unified management' as status
FROM orders o;

-- Check if trigger is working
SELECT 
  trigger_name,
  event_manipulation,
  event_object_table,
  action_statement
FROM information_schema.triggers
WHERE trigger_name = 'sync_chat_order_trigger';