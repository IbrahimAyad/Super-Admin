-- =====================================================
-- ADD MISSING NAME COLUMN
-- Quick fix for the missing 'name' column error
-- =====================================================

-- Add the missing name column
ALTER TABLE customers 
ADD COLUMN IF NOT EXISTS name VARCHAR(255);

-- Verify it was added
SELECT 
  column_name,
  data_type
FROM information_schema.columns
WHERE table_name = 'customers'
AND column_name = 'name';