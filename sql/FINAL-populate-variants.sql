-- FINAL COMPREHENSIVE SOLUTION FOR POPULATING PRODUCT VARIANTS
-- This script handles all required fields and relationships properly

-- STEP 1: Analyze what we have
DO $$
BEGIN
  RAISE NOTICE '';
  RAISE NOTICE '=================================';
  RAISE NOTICE 'STARTING PRODUCT VARIANT SETUP';
  RAISE NOTICE '=================================';
END $$;

-- STEP 2: Check if we should use products or products_enhanced
DO $$
DECLARE
  products_count INTEGER;
  products_enhanced_count INTEGER;
  use_products_enhanced BOOLEAN := false;
BEGIN
  SELECT COUNT(*) INTO products_count FROM products;
  SELECT COUNT(*) INTO products_enhanced_count FROM products_enhanced;
  
  RAISE NOTICE 'products table has % records', products_count;
  RAISE NOTICE 'products_enhanced table has % records', products_enhanced_count;
  
  -- If products table is empty but products_enhanced has data, we need to sync
  IF products_count = 0 AND products_enhanced_count > 0 THEN
    RAISE NOTICE 'Need to sync from products_enhanced to products';
    use_products_enhanced := true;
  END IF;
END $$;

-- STEP 3: Create a function to generate handle from name
CREATE OR REPLACE FUNCTION generate_handle(name_text TEXT) 
RETURNS TEXT AS $$
BEGIN
  RETURN LOWER(
    REGEXP_REPLACE(
      REGEXP_REPLACE(
        REGEXP_REPLACE(name_text, '[^a-zA-Z0-9\s-]', '', 'g'),
        '\s+', '-', 'g'
      ),
      '-+', '-', 'g'
    )
  );
END;
$$ LANGUAGE plpgsql;

-- STEP 4: Ensure products table has all needed columns and sync data
DO $$
DECLARE
  col_exists BOOLEAN;
BEGIN
  -- Check if handle column exists in products table
  SELECT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'products' AND column_name = 'handle'
  ) INTO col_exists;
  
  IF col_exists THEN
    -- If products table has handle column, we need to populate it
    RAISE NOTICE 'products table has handle column - will populate from products_enhanced';
    
    -- First, make handle nullable temporarily if it's not
    ALTER TABLE products ALTER COLUMN handle DROP NOT NULL;
    
    -- Insert or update products from products_enhanced
    INSERT INTO products (
      id, 
      name, 
      handle,
      description,
      category,
      sku,
      base_price,
      status,
      created_at,
      updated_at
    )
    SELECT 
      pe.id,
      pe.name,
      COALESCE(pe.handle, generate_handle(pe.name)),
      COALESCE(pe.description, pe.name || ' - Premium quality from KCT Menswear'),
      pe.category,
      pe.sku,
      pe.base_price,
      pe.status,
      pe.created_at,
      pe.updated_at
    FROM products_enhanced pe
    ON CONFLICT (id) DO UPDATE SET
      name = EXCLUDED.name,
      handle = EXCLUDED.handle,
      description = EXCLUDED.description,
      category = EXCLUDED.category,
      sku = EXCLUDED.sku,
      base_price = EXCLUDED.base_price,
      status = EXCLUDED.status;
      
    -- Set handle to NOT NULL again if needed
    UPDATE products SET handle = generate_handle(name) WHERE handle IS NULL;
    
  ELSE
    RAISE NOTICE 'products table does not have handle column - skipping handle sync';
    
    -- Just sync the basic fields
    INSERT INTO products (
      id,
      name,
      description,
      category,
      sku,
      base_price,
      status,
      created_at,
      updated_at
    )
    SELECT 
      pe.id,
      pe.name,
      COALESCE(pe.description, pe.name || ' - Premium quality from KCT Menswear'),
      pe.category,
      pe.sku,
      pe.base_price,
      pe.status,
      pe.created_at,
      pe.updated_at
    FROM products_enhanced pe
    ON CONFLICT (id) DO UPDATE SET
      name = EXCLUDED.name,
      description = EXCLUDED.description,
      category = EXCLUDED.category,
      sku = EXCLUDED.sku,
      base_price = EXCLUDED.base_price,
      status = EXCLUDED.status;
  END IF;
  
  RAISE NOTICE 'Products sync complete';
END $$;

-- STEP 5: Now populate product variants with correct sizes
DO $$
DECLARE
  product_record RECORD;
  size_text TEXT;
  sizes_array TEXT[];
  inventory_qty INTEGER;
  variant_count INTEGER;
  created_count INTEGER := 0;
  skipped_count INTEGER := 0;
  error_count INTEGER := 0;
BEGIN
  RAISE NOTICE '';
  RAISE NOTICE 'Starting variant creation...';
  
  -- Loop through all active products
  FOR product_record IN 
    SELECT 
      p.*,
      pe.color_name,
      pe.color_family
    FROM products p
    LEFT JOIN products_enhanced pe ON p.id = pe.id
    WHERE p.status = 'active'
    ORDER BY p.name
  LOOP
    -- Check if variants already exist
    SELECT COUNT(*) INTO variant_count
    FROM product_variants 
    WHERE product_id = product_record.id;
    
    IF variant_count > 0 THEN
      skipped_count := skipped_count + 1;
      CONTINUE;
    END IF;

    -- Determine sizes based on category and product name
    IF product_record.category IN ('Blazers', 'Suits', 'Tuxedos') OR 
       LOWER(product_record.name) LIKE '%suit%' OR 
       LOWER(product_record.name) LIKE '%blazer%' OR
       LOWER(product_record.name) LIKE '%tuxedo%' THEN
      -- Full suit sizes with S, R, L variations
      sizes_array := ARRAY[
        '34S', '34R',
        '36S', '36R',
        '38S', '38R', '38L',
        '40S', '40R', '40L',
        '42S', '42R', '42L',
        '44S', '44R', '44L',
        '46S', '46R', '46L',
        '48S', '48R', '48L',
        '50S', '50R', '50L',
        '52R', '52L',
        '54R', '54L'
      ];
    ELSIF product_record.category = 'Shirts' OR 
          LOWER(product_record.name) LIKE '%shirt%' THEN
      -- Dress shirt sizes (neck sizes)
      sizes_array := ARRAY['14.5', '15', '15.5', '16', '16.5', '17', '17.5', '18'];
    ELSIF product_record.category = 'Pants' OR 
          LOWER(product_record.name) LIKE '%pant%' OR
          LOWER(product_record.name) LIKE '%trouser%' THEN
      -- Waist sizes for pants
      sizes_array := ARRAY['28', '30', '32', '34', '36', '38', '40', '42'];
    ELSIF product_record.category = 'Accessories' OR
          LOWER(product_record.name) LIKE '%tie%' OR
          LOWER(product_record.name) LIKE '%bow%' OR
          LOWER(product_record.name) LIKE '%cufflink%' OR
          LOWER(product_record.name) LIKE '%pocket square%' OR
          LOWER(product_record.name) LIKE '%vest%' OR
          LOWER(product_record.name) LIKE '%suspender%' OR
          LOWER(product_record.name) LIKE '%cummerb%' THEN
      -- One size for accessories
      sizes_array := ARRAY['One Size'];
    ELSE
      -- Default sizes for other items
      sizes_array := ARRAY['S', 'M', 'L', 'XL', 'XXL'];
    END IF;

    -- Create variants for each size
    FOREACH size_text IN ARRAY sizes_array
    LOOP
      -- Set inventory based on size type
      IF size_text = 'One Size' THEN
        inventory_qty := 100;
      ELSIF size_text LIKE '%L' THEN
        inventory_qty := floor(random() * 10 + 3)::INTEGER;
      ELSIF size_text LIKE '%S' THEN
        inventory_qty := floor(random() * 10 + 3)::INTEGER;
      ELSE
        inventory_qty := floor(random() * 20 + 10)::INTEGER;
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
          product_record.sku || '-' || REPLACE(REPLACE(size_text, '.', ''), ' ', ''),
          product_record.base_price,
          inventory_qty,
          true,
          inventory_qty,
          0,
          inventory_qty,
          NOW(),
          NOW()
        );
        created_count := created_count + 1;
      EXCEPTION
        WHEN OTHERS THEN
          error_count := error_count + 1;
          RAISE WARNING 'Error for % size %: %', product_record.name, size_text, SQLERRM;
      END;
    END LOOP;
  END LOOP;

  RAISE NOTICE '';
  RAISE NOTICE '=================================';
  RAISE NOTICE 'VARIANT CREATION COMPLETE';
  RAISE NOTICE 'Created: % variants', created_count;
  RAISE NOTICE 'Skipped: % products (had variants)', skipped_count;
  RAISE NOTICE 'Errors: %', error_count;
  RAISE NOTICE '=================================';
END $$;

-- STEP 6: Fix any existing variants without sizes
UPDATE product_variants 
SET option1 = 'One Size' 
WHERE option1 IS NULL OR option1 = '';

-- STEP 7: Show results
SELECT 'Summary Statistics' as report_section;
SELECT 
  'Total Products' as metric,
  COUNT(*) as count
FROM products
WHERE status = 'active'
UNION ALL
SELECT 
  'Products with Variants' as metric,
  COUNT(DISTINCT product_id) as count
FROM product_variants
UNION ALL
SELECT 
  'Total Variants' as metric,
  COUNT(*) as count
FROM product_variants
UNION ALL
SELECT 
  'Total Inventory Units' as metric,
  SUM(inventory_quantity) as count
FROM product_variants;

-- Show breakdown by category
SELECT 'Variants by Category' as report_section;
SELECT 
  COALESCE(p.category, 'Unknown') as category,
  COUNT(DISTINCT p.id) as products,
  COUNT(pv.id) as variants,
  ROUND(AVG(pv.inventory_quantity)) as avg_inventory
FROM products p
LEFT JOIN product_variants pv ON p.id = pv.product_id
WHERE p.status = 'active'
GROUP BY p.category
ORDER BY COUNT(pv.id) DESC;

-- Show some sample products with their sizes
SELECT 'Sample Products with Sizes' as report_section;
SELECT 
  p.name,
  p.category,
  STRING_AGG(
    pv.option1, 
    ', ' 
    ORDER BY 
      CASE 
        WHEN pv.option1 ~ '^\d+S$' THEN CAST(SUBSTRING(pv.option1 FROM '^\d+') AS INTEGER) * 10 + 1
        WHEN pv.option1 ~ '^\d+R$' THEN CAST(SUBSTRING(pv.option1 FROM '^\d+') AS INTEGER) * 10 + 2
        WHEN pv.option1 ~ '^\d+L$' THEN CAST(SUBSTRING(pv.option1 FROM '^\d+') AS INTEGER) * 10 + 3
        WHEN pv.option1 = 'S' THEN 1
        WHEN pv.option1 = 'M' THEN 2
        WHEN pv.option1 = 'L' THEN 3
        WHEN pv.option1 = 'XL' THEN 4
        WHEN pv.option1 = 'XXL' THEN 5
        WHEN pv.option1 = 'XXXL' THEN 6
        WHEN pv.option1 ~ '^\d+\.?\d*$' THEN CAST(REPLACE(pv.option1, '.', '') AS NUMERIC)
        ELSE 999
      END
  ) as sizes
FROM products p
JOIN product_variants pv ON p.id = pv.product_id
WHERE p.status = 'active'
GROUP BY p.id, p.name, p.category
LIMIT 15;

-- Clean up the function we created
DROP FUNCTION IF EXISTS generate_handle(TEXT);