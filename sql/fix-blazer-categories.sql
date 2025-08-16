-- Fix blazers that are incorrectly categorized as Accessories
-- These should be in the Blazers category

-- First, let's see what we have
SELECT name, category 
FROM products 
WHERE LOWER(name) LIKE '%blazer%' 
AND category = 'Accessories';

-- Update blazers to correct category
UPDATE products 
SET category = 'Blazers'
WHERE LOWER(name) LIKE '%blazer%' 
AND category = 'Accessories';

-- Also update in products_enhanced
UPDATE products_enhanced 
SET category = 'Blazers'
WHERE LOWER(name) LIKE '%blazer%' 
AND category = 'Accessories';

-- Now let's clean up and recreate variants with proper logic
-- Delete existing variants for these blazers
DELETE FROM product_variants 
WHERE product_id IN (
  SELECT id FROM products 
  WHERE LOWER(name) LIKE '%blazer%'
);

-- Recreate with correct sizes
DO $$
DECLARE
  product_record RECORD;
  size_text TEXT;
  sizes_array TEXT[];
  inventory_qty INTEGER;
  created_count INTEGER := 0;
BEGIN
  -- Loop through all blazers
  FOR product_record IN 
    SELECT p.*, pe.color_name, pe.color_family
    FROM products p
    LEFT JOIN products_enhanced pe ON p.id = pe.id
    WHERE LOWER(p.name) LIKE '%blazer%'
    ORDER BY p.name
  LOOP
    -- Blazer sizes
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
    
    RAISE NOTICE 'Creating variants for: %', product_record.name;
    
    -- Create a variant for each size
    FOREACH size_text IN ARRAY sizes_array
    LOOP
      -- Set inventory based on size type
      IF size_text LIKE '%L' THEN
        inventory_qty := floor(random() * 8 + 2)::INTEGER;
      ELSIF size_text LIKE '%S' THEN
        inventory_qty := floor(random() * 8 + 2)::INTEGER;
      ELSIF size_text IN ('40R', '42R', '38R') THEN
        inventory_qty := floor(random() * 20 + 15)::INTEGER;
      ELSE
        inventory_qty := floor(random() * 15 + 5)::INTEGER;
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
      ) ON CONFLICT DO NOTHING;
      
      created_count := created_count + 1;
    END LOOP;
  END LOOP;
  
  RAISE NOTICE 'Created % variants for blazers', created_count;
END $$;

-- Show updated results
SELECT 
  p.name,
  p.category,
  COUNT(pv.id) as variant_count,
  STRING_AGG(
    pv.option1, 
    ', ' 
    ORDER BY 
      CASE 
        WHEN pv.option1 ~ '^\d+S$' THEN CAST(SUBSTRING(pv.option1 FROM '^\d+') AS INTEGER) * 10 + 1
        WHEN pv.option1 ~ '^\d+R$' THEN CAST(SUBSTRING(pv.option1 FROM '^\d+') AS INTEGER) * 10 + 2
        WHEN pv.option1 ~ '^\d+L$' THEN CAST(SUBSTRING(pv.option1 FROM '^\d+') AS INTEGER) * 10 + 3
        ELSE 999
      END
  ) as sizes
FROM products p
JOIN product_variants pv ON p.id = pv.product_id
WHERE LOWER(p.name) LIKE '%blazer%'
GROUP BY p.id, p.name, p.category
ORDER BY p.name;