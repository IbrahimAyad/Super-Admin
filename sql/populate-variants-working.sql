-- Working script to populate product variants with correct sizes
-- This version handles all required fields in the products table

-- First, let's check the products table structure
DO $$
BEGIN
  -- Add missing columns if they don't exist
  ALTER TABLE products ADD COLUMN IF NOT EXISTS color_name TEXT;
  ALTER TABLE products ADD COLUMN IF NOT EXISTS color_family TEXT;
  ALTER TABLE products ADD COLUMN IF NOT EXISTS description TEXT;
  
  -- Make description nullable if it's not
  ALTER TABLE products ALTER COLUMN description DROP NOT NULL;
END $$;

-- Copy all products from products_enhanced to products with all required fields
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
  id, 
  name, 
  COALESCE(description, name || ' - Premium quality product from KCT Menswear'), -- Provide default description
  category, 
  sku, 
  base_price,
  status,
  created_at,
  updated_at
FROM products_enhanced
ON CONFLICT (id) DO UPDATE SET
  name = EXCLUDED.name,
  description = EXCLUDED.description,
  sku = EXCLUDED.sku,
  category = EXCLUDED.category,
  base_price = EXCLUDED.base_price,
  status = EXCLUDED.status;

-- Update color information from products_enhanced
UPDATE products p
SET 
  color_name = pe.color_name,
  color_family = pe.color_family
FROM products_enhanced pe
WHERE p.id = pe.id;

-- Clear any existing variants to start fresh (optional - comment out if you want to keep existing)
-- DELETE FROM product_variants;

-- Now populate variants with proper sizes
DO $$
DECLARE
  product_record RECORD;
  size_text TEXT;
  sizes_array TEXT[];
  inventory_qty INTEGER;
  variant_count INTEGER;
  created_count INTEGER := 0;
  skipped_count INTEGER := 0;
BEGIN
  -- Loop through all products
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
    -- Check if variants already exist for this product
    SELECT COUNT(*) INTO variant_count
    FROM product_variants 
    WHERE product_id = product_record.id;
    
    IF variant_count > 0 THEN
      RAISE NOTICE 'Skipping % - already has % variants', product_record.name, variant_count;
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
      RAISE NOTICE 'Using suit sizes for: %', product_record.name;
    ELSIF product_record.category = 'Shirts' OR 
          LOWER(product_record.name) LIKE '%shirt%' THEN
      -- Dress shirt sizes (neck sizes)
      sizes_array := ARRAY['14.5', '15', '15.5', '16', '16.5', '17', '17.5', '18'];
      RAISE NOTICE 'Using shirt sizes for: %', product_record.name;
    ELSIF product_record.category = 'Pants' OR 
          LOWER(product_record.name) LIKE '%pant%' OR
          LOWER(product_record.name) LIKE '%trouser%' THEN
      -- Waist sizes for pants
      sizes_array := ARRAY['28', '30', '32', '34', '36', '38', '40', '42'];
      RAISE NOTICE 'Using pants sizes for: %', product_record.name;
    ELSIF product_record.category = 'Accessories' OR
          LOWER(product_record.name) LIKE '%tie%' OR
          LOWER(product_record.name) LIKE '%bow%' OR
          LOWER(product_record.name) LIKE '%cufflink%' OR
          LOWER(product_record.name) LIKE '%pocket square%' OR
          LOWER(product_record.name) LIKE '%vest%' OR
          LOWER(product_record.name) LIKE '%suspender%' THEN
      -- One size for accessories
      sizes_array := ARRAY['One Size'];
      RAISE NOTICE 'Using one size for: %', product_record.name;
    ELSE
      -- Default sizes for other items
      sizes_array := ARRAY['S', 'M', 'L', 'XL', 'XXL'];
      RAISE NOTICE 'Using default sizes for: %', product_record.name;
    END IF;

    -- Create a variant for each size
    FOREACH size_text IN ARRAY sizes_array
    LOOP
      -- Set inventory based on size type
      IF size_text = 'One Size' THEN
        inventory_qty := 100;
      ELSIF size_text LIKE '%L' THEN
        -- Long sizes typically have less stock
        inventory_qty := floor(random() * 10 + 3)::INTEGER;
      ELSIF size_text LIKE '%S' THEN
        -- Short sizes typically have less stock
        inventory_qty := floor(random() * 10 + 3)::INTEGER;
      ELSE
        -- Regular sizes have more stock
        inventory_qty := floor(random() * 20 + 10)::INTEGER;
      END IF;

      -- Insert the variant
      BEGIN
        INSERT INTO product_variants (
          product_id,
          title,
          option1, -- Size
          option2, -- Color  
          option3, -- Additional attribute (could be material, pattern, etc.)
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
          NULL, -- Can be used for material or other attributes
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
        WHEN unique_violation THEN
          RAISE NOTICE 'SKU already exists for % - Size: %', product_record.name, size_text;
        WHEN OTHERS THEN
          RAISE NOTICE 'Error creating variant for % - Size: %: %', product_record.name, size_text, SQLERRM;
      END;
    END LOOP;
  END LOOP;

  RAISE NOTICE '';
  RAISE NOTICE '=================================';
  RAISE NOTICE 'VARIANT POPULATION COMPLETE!';
  RAISE NOTICE 'Created % new variants', created_count;
  RAISE NOTICE 'Skipped % products with existing variants', skipped_count;
  RAISE NOTICE '=================================';
END $$;

-- Update any NULL option1 values to 'One Size' for existing variants
UPDATE product_variants 
SET option1 = 'One Size' 
WHERE option1 IS NULL;

-- Show summary statistics
WITH stats AS (
  SELECT 
    COUNT(DISTINCT p.id) as total_products,
    COUNT(DISTINCT pv.product_id) as products_with_variants,
    COUNT(pv.id) as total_variants,
    AVG(pv.inventory_quantity) as avg_inventory,
    SUM(pv.inventory_quantity) as total_inventory
  FROM products p
  LEFT JOIN product_variants pv ON p.id = pv.product_id
  WHERE p.status = 'active'
)
SELECT 
  total_products as "Total Products",
  products_with_variants as "Products with Variants",
  total_variants as "Total Variants",
  ROUND(avg_inventory) as "Avg Inventory per Variant",
  total_inventory as "Total Inventory Units"
FROM stats;

-- Show breakdown by category
SELECT 
  p.category,
  COUNT(DISTINCT p.id) as products,
  COUNT(pv.id) as variants,
  STRING_AGG(DISTINCT pv.option1, ', ' ORDER BY pv.option1) as sizes
FROM products p
LEFT JOIN product_variants pv ON p.id = pv.product_id
GROUP BY p.category
ORDER BY p.category;

-- Show sample of products with their variants
SELECT 
  p.name as "Product Name",
  p.category as "Category",
  COUNT(pv.id) as "Variant Count",
  STRING_AGG(pv.option1, ', ' ORDER BY 
    CASE 
      WHEN pv.option1 ~ '^\d+S$' THEN CAST(SUBSTRING(pv.option1 FROM '^\d+') AS INTEGER) * 10 + 1
      WHEN pv.option1 ~ '^\d+R$' THEN CAST(SUBSTRING(pv.option1 FROM '^\d+') AS INTEGER) * 10 + 2
      WHEN pv.option1 ~ '^\d+L$' THEN CAST(SUBSTRING(pv.option1 FROM '^\d+') AS INTEGER) * 10 + 3
      WHEN pv.option1 ~ '^\d+\.?\d*$' THEN CAST(REPLACE(pv.option1, '.', '') AS INTEGER)
      ELSE 999
    END,
    pv.option1
  ) as "Available Sizes"
FROM products p
LEFT JOIN product_variants pv ON p.id = pv.product_id
WHERE p.status = 'active'
GROUP BY p.id, p.name, p.category
ORDER BY p.category, p.name
LIMIT 20;