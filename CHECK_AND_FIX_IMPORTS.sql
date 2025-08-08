-- ============================================
-- CHECK WHAT'S WRONG WITH IMPORTS
-- ============================================

-- Check products table structure
SELECT column_name, data_type, is_nullable
FROM information_schema.columns
WHERE table_name = 'products'
ORDER BY ordinal_position;

-- Check if SKU column exists and has unique constraint
SELECT 
  tc.constraint_name,
  tc.constraint_type,
  kcu.column_name
FROM information_schema.table_constraints tc
JOIN information_schema.key_column_usage kcu 
  ON tc.constraint_name = kcu.constraint_name
WHERE tc.table_name = 'products'
  AND tc.constraint_type IN ('UNIQUE', 'PRIMARY KEY');

-- ============================================
-- FIXED IMPORT FUNCTIONS
-- ============================================

-- Drop old functions
DROP FUNCTION IF EXISTS import_customers_from_csv(JSONB);
DROP FUNCTION IF EXISTS import_products_from_csv(JSONB);

-- Fixed Customer Import Function
CREATE OR REPLACE FUNCTION import_customers_from_csv(csv_data JSONB)
RETURNS JSONB AS $$
DECLARE
  v_imported INTEGER := 0;
  v_errors INTEGER := 0;
  v_customer JSONB;
  v_email TEXT;
  v_customer_id UUID;
BEGIN
  -- Loop through each customer in the CSV data
  FOR v_customer IN SELECT * FROM jsonb_array_elements(csv_data)
  LOOP
    v_email := LOWER(TRIM(v_customer->>'email'));
    
    -- Skip if no email
    IF v_email IS NULL OR v_email = '' THEN
      v_errors := v_errors + 1;
      CONTINUE;
    END IF;
    
    BEGIN
      -- Check if customer exists
      SELECT id INTO v_customer_id FROM customers WHERE email = v_email;
      
      IF v_customer_id IS NULL THEN
        -- Insert new customer
        INSERT INTO customers (
          id,
          email,
          first_name,
          last_name,
          phone,
          company,
          created_at,
          updated_at
        ) VALUES (
          gen_random_uuid(),
          v_email,
          TRIM(v_customer->>'first_name'),
          TRIM(v_customer->>'last_name'),
          TRIM(v_customer->>'phone'),
          TRIM(v_customer->>'company'),
          NOW(),
          NOW()
        );
        v_imported := v_imported + 1;
      ELSE
        -- Update existing customer
        UPDATE customers SET
          first_name = COALESCE(NULLIF(TRIM(v_customer->>'first_name'), ''), first_name),
          last_name = COALESCE(NULLIF(TRIM(v_customer->>'last_name'), ''), last_name),
          phone = COALESCE(NULLIF(TRIM(v_customer->>'phone'), ''), phone),
          company = COALESCE(NULLIF(TRIM(v_customer->>'company'), ''), company),
          updated_at = NOW()
        WHERE id = v_customer_id;
        v_imported := v_imported + 1;
      END IF;
      
    EXCEPTION
      WHEN OTHERS THEN
        v_errors := v_errors + 1;
        RAISE NOTICE 'Error importing customer %: %', v_email, SQLERRM;
    END;
  END LOOP;
  
  RETURN jsonb_build_object(
    'imported', v_imported,
    'errors', v_errors,
    'total', v_imported + v_errors
  );
END;
$$ LANGUAGE plpgsql;

-- Fixed Product Import Function (handles your schema)
CREATE OR REPLACE FUNCTION import_products_from_csv(csv_data JSONB)
RETURNS JSONB AS $$
DECLARE
  v_imported INTEGER := 0;
  v_errors INTEGER := 0;
  v_product JSONB;
  v_name TEXT;
  v_product_id UUID;
  v_sku TEXT;
BEGIN
  -- Loop through each product in the CSV data
  FOR v_product IN SELECT * FROM jsonb_array_elements(csv_data)
  LOOP
    v_name := TRIM(v_product->>'name');
    v_sku := TRIM(COALESCE(v_product->>'sku', ''));
    
    -- Skip if no name
    IF v_name IS NULL OR v_name = '' THEN
      v_errors := v_errors + 1;
      CONTINUE;
    END IF;
    
    BEGIN
      -- Generate SKU if not provided
      IF v_sku = '' THEN
        v_sku := UPPER(REPLACE(v_name, ' ', '-')) || '-' || SUBSTRING(gen_random_uuid()::TEXT, 1, 8);
      END IF;
      
      -- Check if product exists by name (since SKU might not be unique in your schema)
      SELECT id INTO v_product_id FROM products WHERE name = v_name;
      
      IF v_product_id IS NULL THEN
        -- Insert new product
        INSERT INTO products (
          id,
          name,
          description,
          category,
          base_price,
          status,
          available,
          created_at,
          updated_at
        ) VALUES (
          gen_random_uuid(),
          v_name,
          COALESCE(v_product->>'description', ''),
          COALESCE(v_product->>'category', 'Uncategorized'),
          COALESCE((v_product->>'base_price')::DECIMAL, 0),
          COALESCE(v_product->>'status', 'active'),
          true,
          NOW(),
          NOW()
        ) RETURNING id INTO v_product_id;
        
        -- Create product variants if sizes provided
        IF v_product->>'sizes' IS NOT NULL AND v_product->>'sizes' != '' THEN
          -- Parse sizes (handle comma-separated string)
          INSERT INTO product_variants (
            id,
            product_id,
            title,
            price,
            sku,
            inventory_quantity,
            available_quantity,
            option1,
            created_at,
            updated_at
          )
          SELECT 
            gen_random_uuid(),
            v_product_id,
            v_name || ' - ' || TRIM(size_value),
            COALESCE((v_product->>'base_price')::DECIMAL * 100, 0)::INTEGER, -- Convert to cents
            v_sku || '-' || UPPER(REPLACE(TRIM(size_value), ' ', '')),
            COALESCE((v_product->>'stock')::INTEGER, 0),
            COALESCE((v_product->>'stock')::INTEGER, 0),
            TRIM(size_value), -- Store size in option1
            NOW(),
            NOW()
          FROM (
            SELECT UNNEST(STRING_TO_ARRAY(v_product->>'sizes', ',')) AS size_value
          ) sizes;
        ELSE
          -- Create default variant
          INSERT INTO product_variants (
            id,
            product_id,
            title,
            price,
            sku,
            inventory_quantity,
            available_quantity,
            option1,
            created_at,
            updated_at
          ) VALUES (
            gen_random_uuid(),
            v_product_id,
            v_name || ' - Default',
            COALESCE((v_product->>'base_price')::DECIMAL * 100, 0)::INTEGER,
            v_sku,
            COALESCE((v_product->>'stock')::INTEGER, 0),
            COALESCE((v_product->>'stock')::INTEGER, 0),
            'One Size',
            NOW(),
            NOW()
          );
        END IF;
        
        v_imported := v_imported + 1;
      ELSE
        -- Update existing product
        UPDATE products SET
          description = COALESCE(NULLIF(v_product->>'description', ''), description),
          category = COALESCE(NULLIF(v_product->>'category', ''), category),
          base_price = COALESCE((v_product->>'base_price')::DECIMAL, base_price),
          status = COALESCE(v_product->>'status', status),
          updated_at = NOW()
        WHERE id = v_product_id;
        
        v_imported := v_imported + 1;
      END IF;
      
    EXCEPTION
      WHEN OTHERS THEN
        v_errors := v_errors + 1;
        RAISE NOTICE 'Error importing product %: %', v_name, SQLERRM;
    END;
  END LOOP;
  
  RETURN jsonb_build_object(
    'imported', v_imported,
    'errors', v_errors,
    'total', v_imported + v_errors
  );
END;
$$ LANGUAGE plpgsql;

-- Grant permissions
GRANT EXECUTE ON FUNCTION import_customers_from_csv(JSONB) TO authenticated;
GRANT EXECUTE ON FUNCTION import_products_from_csv(JSONB) TO authenticated;

-- ============================================
-- TEST IMPORTS WITH PROPER DATA
-- ============================================

-- Test customer import
SELECT import_customers_from_csv('[
  {"email": "john.doe@example.com", "first_name": "John", "last_name": "Doe", "phone": "555-0001", "company": "ABC Corp"},
  {"email": "jane.smith@example.com", "first_name": "Jane", "last_name": "Smith", "phone": "555-0002", "company": "XYZ Inc"}
]'::jsonb) as customer_test;

-- Test product import with your schema
SELECT import_products_from_csv('[
  {"name": "Test Suit", "description": "A test suit product", "category": "Suits", "base_price": "299.99", "status": "active", "sizes": "S,M,L,XL", "stock": "10"},
  {"name": "Test Shirt", "description": "A test shirt", "category": "Shirts", "base_price": "79.99", "status": "active", "sizes": "S,M,L", "stock": "20"}
]'::jsonb) as product_test;