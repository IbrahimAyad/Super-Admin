-- =====================================================
-- STEP 1: CREATE PRICE TIERS TABLE
-- Run this first in Supabase SQL Editor
-- =====================================================

-- Create price tiers table if not exists
CREATE TABLE IF NOT EXISTS price_tiers (
  tier_id VARCHAR(50) PRIMARY KEY,
  tier_number INTEGER UNIQUE NOT NULL CHECK (tier_number BETWEEN 1 AND 20),
  min_price INTEGER NOT NULL,
  max_price INTEGER,
  display_range VARCHAR(50) NOT NULL,
  tier_name VARCHAR(50) NOT NULL,
  tier_label VARCHAR(100),
  description TEXT,
  color_code VARCHAR(7),
  icon VARCHAR(50),
  marketing_message TEXT,
  typical_occasions TEXT[],
  target_audience TEXT,
  positioning VARCHAR(50),
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Grant permissions
GRANT ALL ON price_tiers TO authenticated, anon;

-- Verify table was created
SELECT 'Price tiers table created successfully' as status;