-- Clean fix without formatting issues
-- Run each section one at a time

-- SECTION 1: Check current state
SELECT 
  'Current Columns' as info,
  string_agg(column_name, ', ') as columns
FROM information_schema.columns 
WHERE table_name = 'products_enhanced';

-- SECTION 2: Add missing columns
DO $$ 
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'products_enhanced' AND column_name = 'handle'
  ) THEN
    ALTER TABLE products_enhanced ADD COLUMN handle VARCHAR(255);
    UPDATE products_enhanced SET handle = slug WHERE handle IS NULL;
    RAISE NOTICE 'Added handle column';
  END IF;
  
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'products_enhanced' AND column_name = 'slug'
  ) THEN
    ALTER TABLE products_enhanced ADD COLUMN slug VARCHAR(255);
    UPDATE products_enhanced SET slug = handle WHERE slug IS NULL;
    RAISE NOTICE 'Added slug column';
  END IF;
  
  UPDATE products_enhanced 
  SET 
    slug = COALESCE(slug, handle, LOWER(REGEXP_REPLACE(name, '[^a-zA-Z0-9]+', '-', 'g'))),
    handle = COALESCE(handle, slug, LOWER(REGEXP_REPLACE(name, '[^a-zA-Z0-9]+', '-', 'g')))
  WHERE slug IS NULL OR handle IS NULL;
END $$;

-- SECTION 3: Grant permissions
GRANT USAGE ON SCHEMA public TO anon;
GRANT USAGE ON SCHEMA public TO authenticated;
GRANT ALL ON products_enhanced TO anon;
GRANT ALL ON products_enhanced TO authenticated;

-- SECTION 4: Disable RLS
ALTER TABLE products_enhanced DISABLE ROW LEVEL SECURITY;

-- SECTION 5: Activate products
UPDATE products_enhanced 
SET status = 'active' 
WHERE status IS NULL OR status = 'draft';

-- SECTION 6: Verify
SELECT 
  COUNT(*) as total_products,
  COUNT(CASE WHEN slug IS NOT NULL THEN 1 END) as has_slug,
  COUNT(CASE WHEN handle IS NOT NULL THEN 1 END) as has_handle,
  COUNT(CASE WHEN status = 'active' THEN 1 END) as active
FROM products_enhanced;

-- SECTION 7: Show products
SELECT 
  id,
  name,
  sku,
  handle,
  slug,
  status,
  price_tier
FROM products_enhanced
ORDER BY created_at DESC;