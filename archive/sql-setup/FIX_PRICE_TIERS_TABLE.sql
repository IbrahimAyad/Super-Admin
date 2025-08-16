-- =====================================================
-- FIX: Add missing columns to price_tiers table
-- Run this before Step 2
-- =====================================================

-- Add all missing columns to the price_tiers table
ALTER TABLE price_tiers 
ADD COLUMN IF NOT EXISTS tier_name VARCHAR(50),
ADD COLUMN IF NOT EXISTS tier_label VARCHAR(100),
ADD COLUMN IF NOT EXISTS description TEXT,
ADD COLUMN IF NOT EXISTS color_code VARCHAR(7),
ADD COLUMN IF NOT EXISTS icon VARCHAR(50),
ADD COLUMN IF NOT EXISTS marketing_message TEXT,
ADD COLUMN IF NOT EXISTS typical_occasions TEXT[],
ADD COLUMN IF NOT EXISTS target_audience TEXT,
ADD COLUMN IF NOT EXISTS positioning VARCHAR(50);

-- Verify columns were added
SELECT 
  column_name, 
  data_type 
FROM information_schema.columns 
WHERE table_name = 'price_tiers' 
ORDER BY ordinal_position;

-- Show success message
SELECT 'Columns added successfully - Now run STEP 2' as status;