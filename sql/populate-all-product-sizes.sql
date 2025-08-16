-- Comprehensive script to populate ALL products with appropriate size variants
-- This script will create size variants for all products based on their category

-- First, clear existing variants (optional - comment out if you want to keep existing)
TRUNCATE TABLE product_variants CASCADE;

-- Now populate variants for ALL products
DO $$
DECLARE
  product_record RECORD;
  size_text TEXT;
  sizes_array TEXT[];
  inventory_qty INTEGER;
  created_count INTEGER := 0;
  product_count INTEGER := 0;
BEGIN
  RAISE NOTICE 'Starting to create variants for all products...';
  
  -- Loop through all active products
  FOR product_record IN 
    SELECT p.*, pe.color_name, pe.color_family
    FROM products p
    LEFT JOIN products_enhanced pe ON p.id = pe.id
    WHERE p.status = 'active'
    ORDER BY p.category, p.name
  LOOP
    product_count := product_count + 1;
    
    -- Determine sizes based on category and product name
    IF product_record.category IN ('Blazers', 'Suits', 'Tuxedos') OR 
       LOWER(product_record.name) LIKE '%suit%' OR 
       LOWER(product_record.name) LIKE '%blazer%' OR
       LOWER(product_record.name) LIKE '%tuxedo%' OR
       LOWER(product_record.name) LIKE '%jacket%' THEN
      -- Full suit/blazer sizes
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
      -- Dress shirt neck sizes
      sizes_array := ARRAY['14.5', '15', '15.5', '16', '16.5', '17', '17.5', '18'];
      
    ELSIF product_record.category = 'Pants' OR 
          LOWER(product_record.name) LIKE '%pant%' OR
          LOWER(product_record.name) LIKE '%trouser%' OR
          LOWER(product_record.name) LIKE '%slack%' THEN
      -- Waist sizes for pants
      sizes_array := ARRAY['28', '30', '32', '34', '36', '38', '40', '42', '44'];
      
    ELSIF product_record.category = 'Accessories' OR
          LOWER(product_record.name) LIKE '%tie%' OR
          LOWER(product_record.name) LIKE '%bow%' OR
          LOWER(product_record.name) LIKE '%cufflink%' OR
          LOWER(product_record.name) LIKE '%pocket square%' OR
          LOWER(product_record.name) LIKE '%vest%' OR
          LOWER(product_record.name) LIKE '%suspender%' OR
          LOWER(product_record.name) LIKE '%cummerb%' OR
          LOWER(product_record.name) LIKE '%belt%' OR
          LOWER(product_record.name) LIKE '%scarf%' THEN
      -- One size for accessories
      sizes_array := ARRAY['One Size'];
      
    ELSIF LOWER(product_record.name) LIKE '%vest%' AND 
          product_record.category != 'Accessories' THEN
      -- Vests might have regular sizes
      sizes_array := ARRAY['S', 'M', 'L', 'XL', 'XXL', 'XXXL'];
      
    ELSE
      -- Default sizes for other items
      sizes_array := ARRAY['S', 'M', 'L', 'XL', 'XXL'];
    END IF;

    -- Create a variant for each size
    FOREACH size_text IN ARRAY sizes_array
    LOOP
      -- Set inventory based on size type and popularity
      IF size_text = 'One Size' THEN
        inventory_qty := 100;
      ELSIF size_text LIKE '%L' AND size_text != 'L' AND size_text != 'XL' AND size_text != 'XXL' THEN
        -- Long suit sizes - less common
        inventory_qty := floor(random() * 8 + 2)::INTEGER;
      ELSIF size_text LIKE '%S' AND size_text != 'S' THEN
        -- Short suit sizes - less common
        inventory_qty := floor(random() * 8 + 2)::INTEGER;
      ELSIF size_text IN ('40R', '42R', '38R', 'L', 'M', '32', '34', '16', '16.5') THEN
        -- Most common sizes - higher inventory
        inventory_qty := floor(random() * 20 + 15)::INTEGER;
      ELSE
        -- Regular inventory
        inventory_qty := floor(random() * 15 + 5)::INTEGER;
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
          RAISE WARNING 'Error creating variant for % size %: %', product_record.name, size_text, SQLERRM;
      END;
    END LOOP;
  END LOOP;
  
  RAISE NOTICE '';
  RAISE NOTICE '=========================================';
  RAISE NOTICE 'VARIANT CREATION COMPLETE!';
  RAISE NOTICE 'Processed % products', product_count;
  RAISE NOTICE 'Created % variants', created_count;
  RAISE NOTICE '=========================================';
END $$;

-- Show summary by category
SELECT 
  p.category,
  COUNT(DISTINCT p.id) as products,
  COUNT(pv.id) as total_variants,
  ROUND(AVG(pv.inventory_quantity)) as avg_inventory,
  SUM(pv.inventory_quantity) as total_inventory
FROM products p
LEFT JOIN product_variants pv ON p.id = pv.product_id
GROUP BY p.category
ORDER BY COUNT(pv.id) DESC;

-- Show sample products with their sizes
SELECT 
  p.name,
  p.category,
  COUNT(pv.id) as variant_count,
  STRING_AGG(
    pv.option1, 
    ', ' 
    ORDER BY 
      CASE 
        -- Sort suit sizes properly
        WHEN pv.option1 ~ '^\d+S$' THEN CAST(SUBSTRING(pv.option1 FROM '^\d+') AS INTEGER) * 10 + 1
        WHEN pv.option1 ~ '^\d+R$' THEN CAST(SUBSTRING(pv.option1 FROM '^\d+') AS INTEGER) * 10 + 2
        WHEN pv.option1 ~ '^\d+L$' THEN CAST(SUBSTRING(pv.option1 FROM '^\d+') AS INTEGER) * 10 + 3
        -- Sort regular sizes
        WHEN pv.option1 = 'S' THEN 1
        WHEN pv.option1 = 'M' THEN 2
        WHEN pv.option1 = 'L' THEN 3
        WHEN pv.option1 = 'XL' THEN 4
        WHEN pv.option1 = 'XXL' THEN 5
        WHEN pv.option1 = 'XXXL' THEN 6
        -- Sort numeric sizes
        WHEN pv.option1 ~ '^\d+\.?\d*$' THEN CAST(REPLACE(pv.option1, '.', '') AS NUMERIC)
        -- One Size and others
        WHEN pv.option1 = 'One Size' THEN 0
        ELSE 999
      END
  ) as sizes
FROM products p
JOIN product_variants pv ON p.id = pv.product_id
GROUP BY p.id, p.name, p.category
ORDER BY p.category, p.name
LIMIT 20;