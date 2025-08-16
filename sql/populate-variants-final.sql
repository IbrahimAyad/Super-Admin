-- Final script to populate product variants with correct sizes
-- This handles the products table structure and uses proper suit sizes

-- First, ensure products table has the data it needs
DO $$
BEGIN
  -- Check if products table has the columns we need
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'products' 
    AND column_name = 'color_name'
  ) THEN
    -- Add missing columns if they don't exist
    ALTER TABLE products ADD COLUMN IF NOT EXISTS color_name TEXT;
    ALTER TABLE products ADD COLUMN IF NOT EXISTS color_family TEXT;
  END IF;
END $$;

-- Copy all products from products_enhanced to products
INSERT INTO products (id, name, sku, category, base_price, status, created_at, updated_at)
SELECT 
  id, 
  name, 
  sku, 
  category, 
  base_price,
  status,
  created_at,
  updated_at
FROM products_enhanced
ON CONFLICT (id) DO UPDATE SET
  name = EXCLUDED.name,
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

-- Now populate variants with proper sizes
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
    SELECT 
      p.*,
      pe.color_name,
      pe.color_family
    FROM products p
    LEFT JOIN products_enhanced pe ON p.id = pe.id
    WHERE p.status = 'active'
  LOOP
    -- Check if variants already exist for this product
    SELECT COUNT(*) INTO variant_count
    FROM product_variants 
    WHERE product_id = product_record.id;
    
    IF variant_count > 0 THEN
      RAISE NOTICE 'Skipping % - already has % variants', product_record.name, variant_count;
      CONTINUE;
    END IF;

    -- Determine sizes based on category and product name
    IF product_record.category IN ('Blazers', 'Suits') OR 
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
          LOWER(product_record.name) LIKE '%pocket square%' THEN
      -- One size for accessories
      sizes_array := ARRAY['One Size'];
    ELSE
      -- Default sizes for other items
      sizes_array := ARRAY['S', 'M', 'L', 'XL', 'XXL'];
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
          product_record.sku || '-' || REPLACE(size_text, '.', '') || REPLACE(size_text, ' ', ''),
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
        WHEN unique_violation THEN
          RAISE NOTICE 'Variant already exists for % - Size: %', product_record.name, size_text;
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

-- Show summary statistics
SELECT 
  'Products in products table' as metric,
  COUNT(*) as count
FROM products
UNION ALL
SELECT 
  'Products in products_enhanced table' as metric,
  COUNT(*) as count
FROM products_enhanced
UNION ALL
SELECT 
  'Products with Variants' as metric,
  COUNT(DISTINCT product_id) as count
FROM product_variants
UNION ALL
SELECT 
  'Total Variants Created' as metric,
  COUNT(*) as count
FROM product_variants
UNION ALL
SELECT 
  'Suit/Blazer Variants' as metric,
  COUNT(*) as count
FROM product_variants pv
JOIN products p ON pv.product_id = p.id
WHERE p.category IN ('Blazers', 'Suits')
UNION ALL
SELECT 
  'Shirt Variants' as metric,
  COUNT(*) as count
FROM product_variants pv
JOIN products p ON pv.product_id = p.id
WHERE p.category = 'Shirts';

-- Show sample of suit products with their sizes
SELECT 
  p.name as product_name,
  p.category,
  STRING_AGG(pv.option1, ', ' ORDER BY 
    CASE 
      WHEN pv.option1 LIKE '%S' THEN 1
      WHEN pv.option1 LIKE '%R' THEN 2
      WHEN pv.option1 LIKE '%L' THEN 3
      ELSE 4
    END,
    pv.option1
  ) as available_sizes
FROM products p
JOIN product_variants pv ON p.id = pv.product_id
WHERE p.category IN ('Blazers', 'Suits') 
   OR LOWER(p.name) LIKE '%suit%'
   OR LOWER(p.name) LIKE '%blazer%'
GROUP BY p.id, p.name, p.category
LIMIT 10;

-- Show inventory distribution
SELECT 
  'Total Inventory Units' as metric,
  SUM(inventory_quantity) as total
FROM product_variants
UNION ALL
SELECT 
  'Average Inventory per Variant' as metric,
  ROUND(AVG(inventory_quantity)) as total
FROM product_variants
UNION ALL
SELECT 
  'Products with Low Stock (< 5 units)' as metric,
  COUNT(*) as total
FROM product_variants
WHERE inventory_quantity < 5;