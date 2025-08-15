-- CREATE CHECKOUT SESSION TRACKING TABLES
-- Run this in Supabase SQL Editor

-- Create sequence for order numbers first
CREATE SEQUENCE IF NOT EXISTS order_number_seq START WITH 1000;

-- Create checkout_sessions table
CREATE TABLE IF NOT EXISTS checkout_sessions (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  session_id VARCHAR(255) UNIQUE NOT NULL,
  chat_session_id VARCHAR(255),
  customer_email VARCHAR(255),
  customer_id UUID REFERENCES customers(id),
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

-- Create indexes for better performance
CREATE INDEX idx_checkout_sessions_session_id ON checkout_sessions(session_id);
CREATE INDEX idx_checkout_sessions_chat_session_id ON checkout_sessions(chat_session_id);
CREATE INDEX idx_checkout_sessions_customer_email ON checkout_sessions(customer_email);
CREATE INDEX idx_checkout_sessions_status ON checkout_sessions(status);
CREATE INDEX idx_checkout_sessions_created_at ON checkout_sessions(created_at DESC);

-- Create chat_orders table for completed orders from chat
CREATE TABLE IF NOT EXISTS chat_orders (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  order_number VARCHAR(50) UNIQUE NOT NULL DEFAULT ('CHT' || LPAD(NEXTVAL('order_number_seq')::TEXT, 6, '0')),
  checkout_session_id VARCHAR(255) REFERENCES checkout_sessions(session_id),
  customer_id UUID REFERENCES customers(id),
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

-- Create indexes for chat_orders
CREATE INDEX idx_chat_orders_order_number ON chat_orders(order_number);
CREATE INDEX idx_chat_orders_customer_email ON chat_orders(customer_email);
CREATE INDEX idx_chat_orders_status ON chat_orders(status);
CREATE INDEX idx_chat_orders_payment_status ON chat_orders(payment_status);
CREATE INDEX idx_chat_orders_created_at ON chat_orders(created_at DESC);

-- Note: Sequence already created at the beginning of the script

-- Create function to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create triggers for updated_at
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

-- Create RLS policies
ALTER TABLE checkout_sessions ENABLE ROW LEVEL SECURITY;
ALTER TABLE chat_orders ENABLE ROW LEVEL SECURITY;

-- Allow authenticated users to view their own checkout sessions
CREATE POLICY "Users can view own checkout sessions"
ON checkout_sessions FOR SELECT
USING (auth.email() = customer_email OR auth.uid() = customer_id);

-- Allow service role to manage all checkout sessions
CREATE POLICY "Service role can manage checkout sessions"
ON checkout_sessions FOR ALL
USING (auth.role() = 'service_role');

-- Allow authenticated users to view their own orders
CREATE POLICY "Users can view own orders"
ON chat_orders FOR SELECT
USING (auth.email() = customer_email OR auth.uid() = customer_id);

-- Allow service role to manage all orders
CREATE POLICY "Service role can manage orders"
ON chat_orders FOR ALL
USING (auth.role() = 'service_role');

-- Grant permissions
GRANT SELECT ON checkout_sessions TO anon, authenticated;
GRANT ALL ON checkout_sessions TO service_role;
GRANT SELECT ON chat_orders TO anon, authenticated;
GRANT ALL ON chat_orders TO service_role;

-- Sample query to verify tables
SELECT 
  table_name,
  column_name,
  data_type,
  is_nullable
FROM information_schema.columns
WHERE table_schema = 'public'
AND table_name IN ('checkout_sessions', 'chat_orders')
ORDER BY table_name, ordinal_position;