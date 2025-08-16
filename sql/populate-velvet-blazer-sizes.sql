-- Populate sizes for Velvet Blazer products
-- This script creates all size variants for blazers

-- First, check what velvet blazer products we have
SELECT id, name, sku, category 
FROM products 
WHERE LOWER(name) LIKE '%velvet%blazer%';

-- Delete existing variants for velvet blazers to start fresh
DELETE FROM product_variants 
WHERE product_id IN (
  SELECT id FROM products 
  WHERE LOWER(name) LIKE '%velvet%blazer%'
);

-- Now create all size variants for velvet blazers
DO $$
DECLARE
  product_record RECORD;
  size_text TEXT;
  sizes_array TEXT[];
  inventory_qty INTEGER;
  created_count INTEGER := 0;
BEGIN
  -- Define blazer sizes
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

  -- Loop through velvet blazer products
  FOR product_record IN 
    SELECT p.*, pe.color_name, pe.color_family
    FROM products p
    LEFT JOIN products_enhanced pe ON p.id = pe.id
    WHERE LOWER(p.name) LIKE '%velvet%blazer%'
  LOOP
    RAISE NOTICE 'Creating variants for: %', product_record.name;
    
    -- Create a variant for each size
    FOREACH size_text IN ARRAY sizes_array
    LOOP
      -- Set inventory based on size type
      IF size_text LIKE '%L' THEN
        inventory_qty := floor(random() * 8 + 2)::INTEGER; -- 2-10 units
      ELSIF size_text LIKE '%S' THEN
        inventory_qty := floor(random() * 8 + 2)::INTEGER; -- 2-10 units
      ELSE -- Regular sizes
        inventory_qty := floor(random() * 15 + 10)::INTEGER; -- 10-25 units
      END IF;

      -- Insert the variant
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
        COALESCE(product_record.color_name, product_record.color_family, 'Midnight Navy'),
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
      
      created_count := created_count + 1;
    END LOOP;
  END LOOP;
  
  RAISE NOTICE 'Created % variants', created_count;
END $$;

-- Show the results
SELECT 
  p.name,
  COUNT(pv.id) as total_variants,
  STRING_AGG(
    pv.option1 || ' (' || pv.inventory_quantity || ')', 
    ', ' 
    ORDER BY 
      CASE 
        WHEN pv.option1 ~ '^\d+S$' THEN CAST(SUBSTRING(pv.option1 FROM '^\d+') AS INTEGER) * 10 + 1
        WHEN pv.option1 ~ '^\d+R$' THEN CAST(SUBSTRING(pv.option1 FROM '^\d+') AS INTEGER) * 10 + 2
        WHEN pv.option1 ~ '^\d+L$' THEN CAST(SUBSTRING(pv.option1 FROM '^\d+') AS INTEGER) * 10 + 3
        ELSE 999
      END
  ) as "sizes_with_inventory"
FROM products p
JOIN product_variants pv ON p.id = pv.product_id
WHERE LOWER(p.name) LIKE '%velvet%blazer%'
GROUP BY p.id, p.name;