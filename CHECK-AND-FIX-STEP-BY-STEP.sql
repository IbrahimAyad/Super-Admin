-- ================================================================
-- STEP BY STEP CHECK AND FIX
-- Run each section one at a time to see where the error occurs
-- ================================================================

-- STEP 1: Check current state of orders table
SELECT '===== STEP 1: Current orders table columns =====' as step;
SELECT 
  column_name, 
  data_type,
  ordinal_position
FROM information_schema.columns 
WHERE table_schema = 'public' 
  AND table_name = 'orders'
ORDER BY ordinal_position;

-- STEP 2: Add customer_id if it doesn't exist
SELECT '===== STEP 2: Adding customer_id column =====' as step;
ALTER TABLE public.orders ADD COLUMN IF NOT EXISTS customer_id UUID;

-- STEP 3: Verify customer_id was added
SELECT '===== STEP 3: Verify customer_id exists =====' as step;
SELECT 
  column_name, 
  data_type
FROM information_schema.columns 
WHERE table_schema = 'public' 
  AND table_name = 'orders'
  AND column_name = 'customer_id';

-- STEP 4: Create customers table first (no dependencies)
SELECT '===== STEP 4: Creating customers table =====' as step;
CREATE TABLE IF NOT EXISTS customers (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  email TEXT UNIQUE NOT NULL,
  name TEXT,
  phone TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- STEP 5: Create reviews table (doesn't reference orders.customer_id)
SELECT '===== STEP 5: Creating reviews table =====' as step;
CREATE TABLE IF NOT EXISTS reviews (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  product_id UUID REFERENCES products(id) ON DELETE CASCADE,
  customer_id UUID,  -- No foreign key to customers yet
  rating INTEGER CHECK (rating >= 1 AND rating <= 5),
  title TEXT,
  comment TEXT,
  verified_purchase BOOLEAN DEFAULT false,
  helpful_count INTEGER DEFAULT 0,
  status TEXT DEFAULT 'pending',
  images TEXT[],
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- STEP 6: Create cart_items table
SELECT '===== STEP 6: Creating cart_items table =====' as step;
CREATE TABLE IF NOT EXISTS cart_items (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  customer_id UUID,  -- No foreign key
  session_id TEXT,
  product_id UUID REFERENCES products(id) ON DELETE CASCADE,
  variant_id UUID,  -- No foreign key to variants
  quantity INTEGER DEFAULT 1,
  price DECIMAL(10,2),
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- STEP 7: Check what we have so far
SELECT '===== STEP 7: Verification check =====' as step;
SELECT 
  'orders has customer_id' as check_item,
  EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_schema = 'public' 
      AND table_name = 'orders' 
      AND column_name = 'customer_id'
  ) as result
UNION ALL
SELECT 
  'customers table exists',
  EXISTS (
    SELECT 1 FROM information_schema.tables 
    WHERE table_schema = 'public' 
      AND table_name = 'customers'
  )
UNION ALL
SELECT 
  'reviews table exists',
  EXISTS (
    SELECT 1 FROM information_schema.tables 
    WHERE table_schema = 'public' 
      AND table_name = 'reviews'
  )
UNION ALL
SELECT 
  'cart_items table exists',
  EXISTS (
    SELECT 1 FROM information_schema.tables 
    WHERE table_schema = 'public' 
      AND table_name = 'cart_items'
  );

-- STOP HERE AND CHECK THE RESULTS BEFORE CONTINUING!