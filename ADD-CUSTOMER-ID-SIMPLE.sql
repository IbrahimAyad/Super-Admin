-- ================================================================
-- SIMPLE FIX: Add customer_id to orders table
-- ================================================================

-- Method 1: Direct ALTER (if column doesn't exist)
ALTER TABLE orders ADD COLUMN IF NOT EXISTS customer_id UUID;

-- Method 2: If the above doesn't work, try without IF NOT EXISTS
-- Uncomment and run this if Method 1 fails:
-- ALTER TABLE orders ADD COLUMN customer_id UUID;

-- Verify the column was added
SELECT 
  column_name, 
  data_type 
FROM information_schema.columns 
WHERE table_name = 'orders' 
AND column_name = 'customer_id';

-- If you see a result above, the column was added successfully!

-- Now let's also add other columns that might be missing
ALTER TABLE orders ADD COLUMN IF NOT EXISTS email TEXT;
ALTER TABLE orders ADD COLUMN IF NOT EXISTS order_number TEXT;
ALTER TABLE orders ADD COLUMN IF NOT EXISTS payment_status TEXT DEFAULT 'pending';
ALTER TABLE orders ADD COLUMN IF NOT EXISTS total_amount DECIMAL(10,2) DEFAULT 0;
ALTER TABLE orders ADD COLUMN IF NOT EXISTS status TEXT DEFAULT 'pending';
ALTER TABLE orders ADD COLUMN IF NOT EXISTS created_at TIMESTAMPTZ DEFAULT NOW();

-- Show all columns in orders table
SELECT 
  column_name, 
  data_type,
  column_default
FROM information_schema.columns 
WHERE table_name = 'orders' 
ORDER BY ordinal_position;

SELECT '✅ Columns added to orders table!' as status;