-- ============================================
-- CREATE IMPORT/EXPORT FUNCTIONS
-- ============================================

-- Function to import customers from CSV data
CREATE OR REPLACE FUNCTION import_customers_from_csv(csv_data JSONB)
RETURNS JSONB AS $$
DECLARE
  v_imported INTEGER := 0;
  v_errors INTEGER := 0;
  v_customer JSONB;
  v_email TEXT;
BEGIN
  -- Loop through each customer in the CSV data
  FOR v_customer IN SELECT * FROM jsonb_array_elements(csv_data)
  LOOP
    v_email := v_customer->>'email';
    
    -- Skip if no email
    IF v_email IS NULL OR v_email = '' THEN
      v_errors := v_errors + 1;
      CONTINUE;
    END IF;
    
    BEGIN
      -- Insert or update customer
      INSERT INTO customers (
        email,
        first_name,
        last_name,
        phone,
        company,
        created_at,
        updated_at
      ) VALUES (
        v_email,
        v_customer->>'first_name',
        v_customer->>'last_name',
        v_customer->>'phone',
        v_customer->>'company',
        NOW(),
        NOW()
      )
      ON CONFLICT (email) DO UPDATE SET
        first_name = COALESCE(EXCLUDED.first_name, customers.first_name),
        last_name = COALESCE(EXCLUDED.last_name, customers.last_name),
        phone = COALESCE(EXCLUDED.phone, customers.phone),
        company = COALESCE(EXCLUDED.company, customers.company),
        updated_at = NOW();
      
      v_imported := v_imported + 1;
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

-- Function to import products from CSV data
CREATE OR REPLACE FUNCTION import_products_from_csv(csv_data JSONB)
RETURNS JSONB AS $$
DECLARE
  v_imported INTEGER := 0;
  v_errors INTEGER := 0;
  v_product JSONB;
  v_sku TEXT;
  v_product_id UUID;
BEGIN
  -- Loop through each product in the CSV data
  FOR v_product IN SELECT * FROM jsonb_array_elements(csv_data)
  LOOP
    v_sku := v_product->>'sku';
    
    -- Skip if no SKU
    IF v_sku IS NULL OR v_sku = '' THEN
      v_errors := v_errors + 1;
      CONTINUE;
    END IF;
    
    BEGIN
      -- Insert or update product
      INSERT INTO products (
        id,
        sku,
        name,
        description,
        category,
        base_price,
        status,
        created_at,
        updated_at
      ) VALUES (
        gen_random_uuid(),
        v_sku,
        v_product->>'name',
        v_product->>'description',
        v_product->>'category',
        COALESCE((v_product->>'base_price')::DECIMAL, 0),
        COALESCE(v_product->>'status', 'active'),
        NOW(),
        NOW()
      )
      ON CONFLICT (sku) DO UPDATE SET
        name = COALESCE(EXCLUDED.name, products.name),
        description = COALESCE(EXCLUDED.description, products.description),
        category = COALESCE(EXCLUDED.category, products.category),
        base_price = COALESCE(EXCLUDED.base_price, products.base_price),
        status = COALESCE(EXCLUDED.status, products.status),
        updated_at = NOW()
      RETURNING id INTO v_product_id;
      
      -- Create default variant if sizes provided
      IF v_product->>'sizes' IS NOT NULL THEN
        INSERT INTO product_variants (
          product_id,
          size,
          sku,
          price,
          inventory_quantity,
          available_quantity
        )
        SELECT 
          v_product_id,
          size_value,
          v_sku || '-' || size_value,
          COALESCE((v_product->>'base_price')::INTEGER * 100, 0), -- Convert to cents
          COALESCE((v_product->>'stock')::INTEGER, 0),
          COALESCE((v_product->>'stock')::INTEGER, 0)
        FROM jsonb_array_elements_text(
          CASE 
            WHEN jsonb_typeof(v_product->'sizes') = 'array' 
            THEN v_product->'sizes'
            ELSE ('["' || (v_product->>'sizes') || '"]')::jsonb
          END
        ) AS size_value
        ON CONFLICT (sku) DO UPDATE SET
          price = EXCLUDED.price,
          inventory_quantity = EXCLUDED.inventory_quantity,
          available_quantity = EXCLUDED.available_quantity;
      END IF;
      
      v_imported := v_imported + 1;
    EXCEPTION
      WHEN OTHERS THEN
        v_errors := v_errors + 1;
        RAISE NOTICE 'Error importing product %: %', v_sku, SQLERRM;
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
-- TEST THE FUNCTIONS
-- ============================================

-- Test customer import
SELECT import_customers_from_csv('[
  {"email": "test@example.com", "first_name": "Test", "last_name": "User", "phone": "555-0001"},
  {"email": "demo@example.com", "first_name": "Demo", "last_name": "User", "phone": "555-0002"}
]'::jsonb) as customer_import_result;

-- Test product import
SELECT import_products_from_csv('[
  {"sku": "TEST-001", "name": "Test Product", "description": "Test", "category": "Test", "base_price": "99.99", "status": "active"}
]'::jsonb) as product_import_result;