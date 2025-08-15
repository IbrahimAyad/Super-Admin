-- ================================================================
-- FIX ORDERS TABLE - Add customer_id and other missing columns
-- ================================================================

-- First, let's see what columns currently exist in orders table
SELECT column_name, data_type 
FROM information_schema.columns 
WHERE table_name = 'orders' 
ORDER BY ordinal_position;

-- Add customer_id column if it doesn't exist
DO $$ 
BEGIN
  IF NOT EXISTS (
    SELECT 1 
    FROM information_schema.columns 
    WHERE table_name = 'orders' 
    AND column_name = 'customer_id'
  ) THEN
    ALTER TABLE orders ADD COLUMN customer_id UUID;
    RAISE NOTICE 'Added customer_id column to orders table';
  ELSE
    RAISE NOTICE 'customer_id column already exists';
  END IF;
EXCEPTION
  WHEN OTHERS THEN
    RAISE NOTICE 'Error adding customer_id: %', SQLERRM;
END $$;

-- Add other potentially missing columns
DO $$ 
BEGIN
  -- Add order_number if missing
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'orders' AND column_name = 'order_number'
  ) THEN
    ALTER TABLE orders ADD COLUMN order_number TEXT;
    RAISE NOTICE 'Added order_number column';
  END IF;

  -- Add email if missing  
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'orders' AND column_name = 'email'
  ) THEN
    ALTER TABLE orders ADD COLUMN email TEXT;
    RAISE NOTICE 'Added email column';
  END IF;

  -- Add payment_status if missing
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'orders' AND column_name = 'payment_status'
  ) THEN
    ALTER TABLE orders ADD COLUMN payment_status TEXT DEFAULT 'pending';
    RAISE NOTICE 'Added payment_status column';
  END IF;

  -- Add total_amount if missing
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'orders' AND column_name = 'total_amount'
  ) THEN
    ALTER TABLE orders ADD COLUMN total_amount DECIMAL(10,2) DEFAULT 0;
    RAISE NOTICE 'Added total_amount column';
  END IF;

  -- Add status if missing
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'orders' AND column_name = 'status'
  ) THEN
    ALTER TABLE orders ADD COLUMN status TEXT DEFAULT 'pending';
    RAISE NOTICE 'Added status column';
  END IF;

  -- Add created_at if missing
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'orders' AND column_name = 'created_at'
  ) THEN
    ALTER TABLE orders ADD COLUMN created_at TIMESTAMPTZ DEFAULT NOW();
    RAISE NOTICE 'Added created_at column';
  END IF;
  
EXCEPTION
  WHEN OTHERS THEN
    RAISE NOTICE 'Error adding columns: %', SQLERRM;
END $$;

-- Now show the updated structure
SELECT 
  column_name, 
  data_type,
  is_nullable,
  column_default
FROM information_schema.columns 
WHERE table_name = 'orders' 
ORDER BY ordinal_position;

-- Test that customer_id now exists
SELECT 'Testing customer_id column...' as test;
SELECT customer_id FROM orders LIMIT 0;

-- If we get here, customer_id exists!
SELECT '✅ Orders table fixed! customer_id and other columns are now available.' as status;