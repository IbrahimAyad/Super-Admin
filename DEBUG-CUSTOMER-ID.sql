-- ================================================================
-- DEBUG: Check what's happening with customer_id column
-- ================================================================

-- 1. Show ALL columns in the orders table
SELECT 
  ordinal_position,
  column_name, 
  data_type,
  is_nullable,
  column_default
FROM information_schema.columns 
WHERE table_schema = 'public' 
  AND table_name = 'orders'
ORDER BY ordinal_position;

-- 2. Check if column exists in different schema
SELECT 
  table_schema,
  table_name,
  column_name
FROM information_schema.columns 
WHERE column_name = 'customer_id' 
  AND table_name = 'orders';

-- 3. Try to directly add the column (will show specific error if it exists)
DO $$
BEGIN
  ALTER TABLE orders ADD COLUMN customer_id UUID;
  RAISE NOTICE 'Successfully added customer_id column';
EXCEPTION
  WHEN duplicate_column THEN
    RAISE NOTICE 'Column customer_id already exists';
  WHEN OTHERS THEN
    RAISE NOTICE 'Error adding customer_id: %', SQLERRM;
END $$;

-- 4. Check again after attempt
SELECT 
  column_name, 
  data_type
FROM information_schema.columns 
WHERE table_schema = 'public' 
  AND table_name = 'orders'
  AND column_name = 'customer_id';

-- 5. If still not found, check if there's a different orders table
SELECT 
  table_schema,
  table_name,
  table_type
FROM information_schema.tables 
WHERE table_name LIKE '%order%'
ORDER BY table_schema, table_name;

-- 6. Force add with explicit schema
ALTER TABLE public.orders ADD COLUMN IF NOT EXISTS customer_id UUID;

-- 7. Final check
SELECT 
  'Final check:' as status,
  EXISTS (
    SELECT 1 
    FROM information_schema.columns 
    WHERE table_schema = 'public' 
      AND table_name = 'orders'
      AND column_name = 'customer_id'
  ) as customer_id_exists;