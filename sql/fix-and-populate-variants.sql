-- Fix Product Variants and Populate with Sizes
-- This script handles the foreign key issue and populates variants

-- First, let's check what products table exists and has data
DO $$
DECLARE
  products_count INTEGER;
  products_enhanced_count INTEGER;
BEGIN
  -- Check if products table exists and has data
  SELECT COUNT(*) INTO products_count 
  FROM information_schema.tables 
  WHERE table_schema = 'public' 
  AND table_name = 'products';
  
  SELECT COUNT(*) INTO products_enhanced_count 
  FROM products_enhanced;
  
  RAISE NOTICE 'products table exists: %, products_enhanced has % records', 
    products_count > 0, products_enhanced_count;
END $$;

-- Option 1: If you want to keep using products_enhanced, 
-- we need to update the foreign key constraint
-- UNCOMMENT THE FOLLOWING SECTION IF YOU WANT TO USE products_enhanced:

/*
-- Drop the existing foreign key constraint
ALTER TABLE product_variants 
DROP CONSTRAINT IF EXISTS product_variants_product_id_fkey;

-- Add new foreign key constraint to products_enhanced
ALTER TABLE product_variants 
ADD CONSTRAINT product_variants_product_id_fkey 
FOREIGN KEY (product_id) 
REFERENCES products_enhanced(id) 
ON DELETE CASCADE;
*/

-- Option 2: Copy products_enhanced data to products table
-- This is safer if other parts of the system expect products table

-- First ensure products table exists with same structure
CREATE TABLE IF NOT EXISTS products (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL,
  sku TEXT NOT NULL,
  category TEXT,
  base_price INTEGER,
  color_name TEXT,
  color_family TEXT,
  status TEXT DEFAULT 'active',
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Copy all products from products_enhanced to products if not already there
INSERT INTO products (id, name, sku, category, base_price, color_name, color_family, status, created_at, updated_at)
SELECT 
  id, 
  name, 
  sku, 
  category, 
  base_price,
  color_name,
  color_family,
  status,
  created_at,
  updated_at
FROM products_enhanced
ON CONFLICT (id) DO NOTHING;

-- Now populate variants for products
DO $$
DECLARE
  product_record RECORD;
  size_text TEXT;
  sizes_array TEXT[];
  inventory_qty INTEGER;
  variant_count INTEGER;
BEGIN
  -- Loop through all products
  FOR product_record IN 
    SELECT * FROM products 
    WHERE status = 'active'
  LOOP
    -- Check if variants already exist for this product
    SELECT COUNT(*) INTO variant_count
    FROM product_variants 
    WHERE product_id = product_record.id;
    
    IF variant_count > 0 THEN
      RAISE NOTICE 'Skipping % - already has % variants', product_record.name, variant_count;
      CONTINUE;
    END IF;

    -- Determine sizes based on category
    CASE product_record.category
      WHEN 'Blazers' THEN
        sizes_array := ARRAY['34R', '36R', '38R', '40R', '42R', '44R', '46R', '48R'];
      WHEN 'Suits' THEN
        sizes_array := ARRAY['34R', '36R', '38R', '40R', '42R', '44R', '46R', '48R'];
      WHEN 'Shirts' THEN
        sizes_array := ARRAY['S', 'M', 'L', 'XL', 'XXL', 'XXXL'];
      WHEN 'Pants' THEN
        sizes_array := ARRAY['28', '30', '32', '34', '36', '38', '40', '42'];
      WHEN 'Accessories' THEN
        sizes_array := ARRAY['One Size'];
      ELSE
        sizes_array := ARRAY['S', 'M', 'L', 'XL', 'XXL'];
    END CASE;

    -- Create a variant for each size
    FOREACH size_text IN ARRAY sizes_array
    LOOP
      -- Random inventory between 5-25 for sizes, 100 for one-size
      IF size_text = 'One Size' THEN
        inventory_qty := 100;
      ELSE
        inventory_qty := floor(random() * 20 + 5)::INTEGER;
      END IF;

      -- Insert the variant
      BEGIN
        INSERT INTO product_variants (
          product_id,
          title,
          option1, -- Size
          option2, -- Color
          sku,
          price,
          inventory_quantity,
          available,
          available_quantity,
          reserved_quantity,
          stock_quantity,
          created_at,
          updated_at
        ) VALUES (
          product_record.id,
          product_record.name || ' - ' || size_text,
          size_text,
          COALESCE(product_record.color_name, product_record.color_family, 'Default'),
          product_record.sku || '-' || REPLACE(size_text, ' ', ''),
          product_record.base_price,
          inventory_qty,
          true,
          inventory_qty,
          0,
          inventory_qty,
          NOW(),
          NOW()
        );
        RAISE NOTICE 'Created variant for % - Size: %', product_record.name, size_text;
      EXCEPTION
        WHEN OTHERS THEN
          RAISE NOTICE 'Error creating variant for % - Size: %: %', product_record.name, size_text, SQLERRM;
      END;
    END LOOP;
  END LOOP;

  RAISE NOTICE 'Product variant population complete!';
END $$;

-- Update any NULL option1 values to 'One Size' for existing variants
UPDATE product_variants 
SET option1 = 'One Size' 
WHERE option1 IS NULL;

-- Show summary
SELECT 
  'Total Products' as metric,
  COUNT(DISTINCT p.id) as count
FROM products p
UNION ALL
SELECT 
  'Products with Variants' as metric,
  COUNT(DISTINCT pv.product_id) as count
FROM product_variants pv
UNION ALL
SELECT 
  'Total Variants' as metric,
  COUNT(*) as count
FROM product_variants pv
UNION ALL
SELECT 
  'Variants with Sizes' as metric,
  COUNT(*) as count
FROM product_variants pv
WHERE option1 IS NOT NULL AND option1 != '';

-- Show sample data
SELECT 
  p.name as product_name,
  p.category,
  pv.option1 as size,
  pv.option2 as color,
  pv.inventory_quantity,
  pv.sku
FROM product_variants pv
JOIN products p ON pv.product_id = p.id
ORDER BY p.name, pv.option1
LIMIT 20;