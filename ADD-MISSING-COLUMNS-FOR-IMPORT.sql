-- ADD MISSING COLUMNS FOR KCT MASTER IMPORT
-- Run this in Supabase SQL Editor before re-running the import

-- 1. Add missing columns to products table
ALTER TABLE products
ADD COLUMN IF NOT EXISTS handle VARCHAR(200),
ADD COLUMN IF NOT EXISTS meta_title VARCHAR(200),
ADD COLUMN IF NOT EXISTS meta_description TEXT,
ADD COLUMN IF NOT EXISTS search_keywords TEXT,
ADD COLUMN IF NOT EXISTS tags TEXT[],
ADD COLUMN IF NOT EXISTS gallery_count INTEGER DEFAULT 0,
ADD COLUMN IF NOT EXISTS stripe_status VARCHAR(50),
ADD COLUMN IF NOT EXISTS updated_date TIMESTAMP WITH TIME ZONE,
ADD COLUMN IF NOT EXISTS total_images INTEGER DEFAULT 0,
ADD COLUMN IF NOT EXISTS gallery_urls TEXT[],
ADD COLUMN IF NOT EXISTS image_status VARCHAR(50);

-- 2. Check what columns we have now
SELECT 
    column_name, 
    data_type,
    is_nullable
FROM information_schema.columns 
WHERE table_name = 'products'
ORDER BY ordinal_position;

-- 3. Success message
DO $$
BEGIN
  RAISE NOTICE '✅ Missing columns added!';
  RAISE NOTICE 'The import script can now run successfully';
END $$;