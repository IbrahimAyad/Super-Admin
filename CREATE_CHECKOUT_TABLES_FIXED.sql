-- CREATE CHECKOUT SESSION TRACKING TABLES (FIXED VERSION)
-- Run this in Supabase SQL Editor
-- Safe to run multiple times (idempotent)

-- Create sequence for order numbers first
DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_sequences WHERE schemaname = 'public' AND sequencename = 'order_number_seq') THEN
    CREATE SEQUENCE order_number_seq START WITH 1000;
  END IF;
END $$;

-- Create checkout_sessions table
CREATE TABLE IF NOT EXISTS checkout_sessions (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  session_id VARCHAR(255) UNIQUE NOT NULL,
  chat_session_id VARCHAR(255),
  customer_email VARCHAR(255),
  customer_id UUID,
  cart_data JSONB NOT NULL,
  amount INTEGER NOT NULL, -- Amount in cents
  currency VARCHAR(3) DEFAULT 'usd',
  status VARCHAR(50) DEFAULT 'pending', -- pending, completed, expired, cancelled
  stripe_payment_intent_id VARCHAR(255),
  stripe_customer_id VARCHAR(255),
  shipping_address JSONB,
  billing_address JSONB,
  metadata JSONB,
  completed_at TIMESTAMP,
  expires_at TIMESTAMP DEFAULT (NOW() + INTERVAL '24 hours'),
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);

-- Create indexes for better performance (IF NOT EXISTS)
CREATE INDEX IF NOT EXISTS idx_checkout_sessions_session_id ON checkout_sessions(session_id);
CREATE INDEX IF NOT EXISTS idx_checkout_sessions_chat_session_id ON checkout_sessions(chat_session_id);
CREATE INDEX IF NOT EXISTS idx_checkout_sessions_customer_email ON checkout_sessions(customer_email);
CREATE INDEX IF NOT EXISTS idx_checkout_sessions_status ON checkout_sessions(status);
CREATE INDEX IF NOT EXISTS idx_checkout_sessions_created_at ON checkout_sessions(created_at DESC);

-- Create chat_orders table for completed orders from chat
CREATE TABLE IF NOT EXISTS chat_orders (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  order_number VARCHAR(50) UNIQUE,
  checkout_session_id VARCHAR(255),
  customer_id UUID,
  customer_email VARCHAR(255) NOT NULL,
  items JSONB NOT NULL,
  subtotal INTEGER NOT NULL,
  shipping_cost INTEGER DEFAULT 0,
  tax_amount INTEGER DEFAULT 0,
  total_amount INTEGER NOT NULL,
  currency VARCHAR(3) DEFAULT 'usd',
  status VARCHAR(50) DEFAULT 'pending', -- pending, processing, shipped, delivered, cancelled
  payment_status VARCHAR(50) DEFAULT 'pending', -- pending, paid, failed, refunded
  stripe_payment_intent_id VARCHAR(255),
  shipping_address JSONB NOT NULL,
  billing_address JSONB,
  tracking_number VARCHAR(255),
  notes TEXT,
  metadata JSONB,
  shipped_at TIMESTAMP,
  delivered_at TIMESTAMP,
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);

-- Add the order_number with default value after table creation to avoid issues
DO $$
BEGIN
  -- Check if order_number column exists and has no default
  IF EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'chat_orders' 
    AND column_name = 'order_number'
    AND column_default IS NULL
  ) THEN
    -- Add default value to existing column
    ALTER TABLE chat_orders 
    ALTER COLUMN order_number 
    SET DEFAULT ('CHT' || LPAD(NEXTVAL('order_number_seq')::TEXT, 6, '0'));
  ELSIF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'chat_orders' 
    AND column_name = 'order_number'
  ) THEN
    -- Add column with default if it doesn't exist
    ALTER TABLE chat_orders 
    ADD COLUMN order_number VARCHAR(50) UNIQUE 
    DEFAULT ('CHT' || LPAD(NEXTVAL('order_number_seq')::TEXT, 6, '0'));
  END IF;
END $$;

-- Set NOT NULL constraint on order_number
ALTER TABLE chat_orders ALTER COLUMN order_number SET NOT NULL;

-- Create indexes for chat_orders (IF NOT EXISTS)
CREATE INDEX IF NOT EXISTS idx_chat_orders_order_number ON chat_orders(order_number);
CREATE INDEX IF NOT EXISTS idx_chat_orders_customer_email ON chat_orders(customer_email);
CREATE INDEX IF NOT EXISTS idx_chat_orders_status ON chat_orders(status);
CREATE INDEX IF NOT EXISTS idx_chat_orders_payment_status ON chat_orders(payment_status);
CREATE INDEX IF NOT EXISTS idx_chat_orders_created_at ON chat_orders(created_at DESC);

-- Create function to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create triggers for updated_at (DROP and recreate to ensure they exist)
DROP TRIGGER IF EXISTS update_checkout_sessions_updated_at ON checkout_sessions;
CREATE TRIGGER update_checkout_sessions_updated_at
BEFORE UPDATE ON checkout_sessions
FOR EACH ROW
EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS update_chat_orders_updated_at ON chat_orders;
CREATE TRIGGER update_chat_orders_updated_at
BEFORE UPDATE ON chat_orders
FOR EACH ROW
EXECUTE FUNCTION update_updated_at_column();

-- Enable RLS (Row Level Security)
ALTER TABLE checkout_sessions ENABLE ROW LEVEL SECURITY;
ALTER TABLE chat_orders ENABLE ROW LEVEL SECURITY;

-- Drop existing policies if they exist and recreate
DROP POLICY IF EXISTS "Users can view own checkout sessions" ON checkout_sessions;
CREATE POLICY "Users can view own checkout sessions"
ON checkout_sessions FOR SELECT
USING (
  auth.email() = customer_email 
  OR auth.uid() = customer_id
  OR auth.role() = 'service_role'
);

DROP POLICY IF EXISTS "Service role can manage checkout sessions" ON checkout_sessions;
CREATE POLICY "Service role can manage checkout sessions"
ON checkout_sessions FOR ALL
USING (auth.role() = 'service_role');

DROP POLICY IF EXISTS "Users can view own orders" ON chat_orders;
CREATE POLICY "Users can view own orders"
ON chat_orders FOR SELECT
USING (
  auth.email() = customer_email 
  OR auth.uid() = customer_id
  OR auth.role() = 'service_role'
);

DROP POLICY IF EXISTS "Service role can manage orders" ON chat_orders;
CREATE POLICY "Service role can manage orders"
ON chat_orders FOR ALL
USING (auth.role() = 'service_role');

-- Grant permissions
GRANT SELECT ON checkout_sessions TO anon, authenticated;
GRANT ALL ON checkout_sessions TO service_role;
GRANT SELECT ON chat_orders TO anon, authenticated;
GRANT ALL ON chat_orders TO service_role;
GRANT USAGE, SELECT ON SEQUENCE order_number_seq TO anon, authenticated, service_role;

-- Verify tables were created successfully
DO $$
DECLARE
  checkout_sessions_exists BOOLEAN;
  chat_orders_exists BOOLEAN;
  sequence_exists BOOLEAN;
BEGIN
  -- Check if tables exist
  SELECT EXISTS (
    SELECT 1 FROM information_schema.tables 
    WHERE table_schema = 'public' 
    AND table_name = 'checkout_sessions'
  ) INTO checkout_sessions_exists;
  
  SELECT EXISTS (
    SELECT 1 FROM information_schema.tables 
    WHERE table_schema = 'public' 
    AND table_name = 'chat_orders'
  ) INTO chat_orders_exists;
  
  SELECT EXISTS (
    SELECT 1 FROM pg_sequences 
    WHERE schemaname = 'public' 
    AND sequencename = 'order_number_seq'
  ) INTO sequence_exists;
  
  -- Raise notice about status
  IF checkout_sessions_exists AND chat_orders_exists AND sequence_exists THEN
    RAISE NOTICE 'SUCCESS: All tables and sequences created successfully!';
  ELSE
    RAISE NOTICE 'WARNING: Some objects may not have been created:';
    IF NOT checkout_sessions_exists THEN
      RAISE NOTICE '  - checkout_sessions table missing';
    END IF;
    IF NOT chat_orders_exists THEN
      RAISE NOTICE '  - chat_orders table missing';
    END IF;
    IF NOT sequence_exists THEN
      RAISE NOTICE '  - order_number_seq sequence missing';
    END IF;
  END IF;
END $$;

-- Sample query to verify structure
SELECT 
  'Tables created successfully!' as status,
  (SELECT COUNT(*) FROM information_schema.tables 
   WHERE table_schema = 'public' 
   AND table_name IN ('checkout_sessions', 'chat_orders')) as tables_count,
  (SELECT COUNT(*) FROM pg_sequences 
   WHERE schemaname = 'public' 
   AND sequencename = 'order_number_seq') as sequence_count,
  'Ready for checkout processing' as message;