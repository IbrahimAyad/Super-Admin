-- Populate Product Variants with Sizes
-- Run this in Supabase SQL Editor to create size variants for all products

DO $$
DECLARE
  product_record RECORD;
  size_text TEXT;
  sizes_array TEXT[];
  inventory_qty INTEGER;
BEGIN
  -- Loop through all products
  FOR product_record IN 
    SELECT * FROM products_enhanced 
    WHERE status = 'active'
  LOOP
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

    -- Check if variants already exist for this product
    IF NOT EXISTS (
      SELECT 1 FROM product_variants 
      WHERE product_id = product_record.id
    ) THEN
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
      END LOOP;
    ELSE
      RAISE NOTICE 'Skipping % - already has variants', product_record.name;
    END IF;
  END LOOP;

  -- Update any NULL option1 values to 'One Size' for existing variants
  UPDATE product_variants 
  SET option1 = 'One Size' 
  WHERE option1 IS NULL;

  RAISE NOTICE 'Product variant population complete!';
END $$;

-- Verify the results
SELECT 
  pe.name as product_name,
  pe.category,
  pv.option1 as size,
  pv.option2 as color,
  pv.inventory_quantity,
  pv.sku
FROM product_variants pv
JOIN products_enhanced pe ON pv.product_id = pe.id
ORDER BY pe.name, pv.option1
LIMIT 20;