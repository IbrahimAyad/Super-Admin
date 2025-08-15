-- =====================================================
-- ENHANCED PRODUCT SYSTEM IMPLEMENTATION
-- Fashion Industry Standard with 20-Tier Pricing
-- Supports 1-9+ Images with JSONB Structure
-- =====================================================

-- STEP 1: CREATE ENHANCED PRODUCTS TABLE
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS products_enhanced (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  
  -- Core Product Information
  name VARCHAR(255) NOT NULL,
  sku VARCHAR(100) UNIQUE NOT NULL,
  handle VARCHAR(255) UNIQUE NOT NULL,
  
  -- Fashion-Specific Fields
  style_code VARCHAR(50),
  season VARCHAR(50),
  collection VARCHAR(100),
  
  -- Categorization
  category VARCHAR(100) NOT NULL,
  subcategory VARCHAR(100),
  product_type VARCHAR(50),
  occasion JSONB DEFAULT '[]'::jsonb,
  
  -- 20-Tier Pricing System
  price_tier VARCHAR(50) NOT NULL,
  base_price INTEGER NOT NULL CHECK (base_price >= 0),
  compare_at_price INTEGER,
  cost_per_unit INTEGER,
  
  -- Fashion Attributes
  color_family VARCHAR(50),
  color_name VARCHAR(100),
  materials JSONB DEFAULT '{}'::jsonb,
  care_instructions TEXT[],
  
  -- Fit & Sizing
  fit_type VARCHAR(50),
  size_range JSONB DEFAULT '{}'::jsonb,
  measurements JSONB DEFAULT '{}'::jsonb,
  
  -- Enhanced Image Structure (Supports 1-9+ images)
  images JSONB DEFAULT '{
    "hero": null,
    "flat": null,
    "lifestyle": [],
    "details": [],
    "variants": {},
    "video": null,
    "gallery_order": [],
    "total_images": 0
  }'::jsonb NOT NULL,
  
  -- SEO & Marketing
  description TEXT,
  meta_title VARCHAR(70),
  meta_description VARCHAR(160),
  tags TEXT[],
  
  -- Inventory & Status
  status VARCHAR(20) DEFAULT 'draft' CHECK (status IN ('draft', 'active', 'archived')),
  is_available BOOLEAN DEFAULT true,
  launch_date TIMESTAMPTZ,
  discontinue_date TIMESTAMPTZ,
  
  -- Stripe Integration
  stripe_product_id VARCHAR(255),
  stripe_active BOOLEAN DEFAULT false,
  
  -- Analytics & Performance
  view_count INTEGER DEFAULT 0,
  add_to_cart_count INTEGER DEFAULT 0,
  purchase_count INTEGER DEFAULT 0,
  return_rate DECIMAL(5,2),
  
  -- Timestamps
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Create indexes for performance
CREATE INDEX IF NOT EXISTS idx_products_enhanced_status ON products_enhanced(status);
CREATE INDEX IF NOT EXISTS idx_products_enhanced_category ON products_enhanced(category, subcategory);
CREATE INDEX IF NOT EXISTS idx_products_enhanced_price_tier ON products_enhanced(price_tier);
CREATE INDEX IF NOT EXISTS idx_products_enhanced_sku ON products_enhanced(sku);
CREATE INDEX IF NOT EXISTS idx_products_enhanced_handle ON products_enhanced(handle);
CREATE INDEX IF NOT EXISTS idx_products_enhanced_images_gin ON products_enhanced USING gin(images);
CREATE INDEX IF NOT EXISTS idx_products_enhanced_stripe ON products_enhanced(stripe_product_id) WHERE stripe_product_id IS NOT NULL;

-- STEP 2: CREATE PRICE TIER CONFIGURATION TABLE
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS price_tiers (
  tier_id VARCHAR(50) PRIMARY KEY,
  tier_number INTEGER UNIQUE NOT NULL CHECK (tier_number BETWEEN 1 AND 20),
  min_price INTEGER NOT NULL,
  max_price INTEGER,
  display_range VARCHAR(50) NOT NULL,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Insert 20 price tiers
INSERT INTO price_tiers (tier_id, tier_number, min_price, max_price, display_range) VALUES
  ('TIER_1', 1, 5000, 7499, '$50-74'),
  ('TIER_2', 2, 7500, 9999, '$75-99'),
  ('TIER_3', 3, 10000, 12499, '$100-124'),
  ('TIER_4', 4, 12500, 14999, '$125-149'),
  ('TIER_5', 5, 15000, 19999, '$150-199'),
  ('TIER_6', 6, 20000, 24999, '$200-249'),
  ('TIER_7', 7, 25000, 29999, '$250-299'),
  ('TIER_8', 8, 30000, 39999, '$300-399'),
  ('TIER_9', 9, 40000, 49999, '$400-499'),
  ('TIER_10', 10, 50000, 59999, '$500-599'),
  ('TIER_11', 11, 60000, 69999, '$600-699'),
  ('TIER_12', 12, 70000, 79999, '$700-799'),
  ('TIER_13', 13, 80000, 89999, '$800-899'),
  ('TIER_14', 14, 90000, 99999, '$900-999'),
  ('TIER_15', 15, 100000, 124999, '$1000-1249'),
  ('TIER_16', 16, 125000, 149999, '$1250-1499'),
  ('TIER_17', 17, 150000, 199999, '$1500-1999'),
  ('TIER_18', 18, 200000, 299999, '$2000-2999'),
  ('TIER_19', 19, 300000, 499999, '$3000-4999'),
  ('TIER_20', 20, 500000, NULL, '$5000+')
ON CONFLICT (tier_id) DO NOTHING;

-- STEP 3: CREATE MIGRATION FUNCTION
-- -----------------------------------------------------
CREATE OR REPLACE FUNCTION migrate_to_enhanced_products()
RETURNS TABLE (
  migrated_count INTEGER,
  error_count INTEGER,
  status TEXT
) AS $$
DECLARE
  v_migrated_count INTEGER := 0;
  v_error_count INTEGER := 0;
  v_product RECORD;
  v_tier_id VARCHAR(50);
  v_images_json JSONB;
BEGIN
  -- Migrate each product
  FOR v_product IN 
    SELECT p.*, 
           array_agg(DISTINCT pi.image_url) FILTER (WHERE pi.image_url IS NOT NULL) as additional_images
    FROM products p
    LEFT JOIN product_images pi ON p.id = pi.product_id
    GROUP BY p.id
  LOOP
    BEGIN
      -- Determine price tier based on base_price
      SELECT tier_id INTO v_tier_id
      FROM price_tiers
      WHERE v_product.base_price >= min_price 
        AND (max_price IS NULL OR v_product.base_price <= max_price)
      LIMIT 1;
      
      -- If no tier found, default to TIER_1
      IF v_tier_id IS NULL THEN
        v_tier_id := 'TIER_1';
      END IF;
      
      -- Build images JSON structure
      v_images_json := jsonb_build_object(
        'hero', CASE 
          WHEN v_product.primary_image IS NOT NULL AND v_product.primary_image != '' 
          THEN jsonb_build_object(
            'url', v_product.primary_image,
            'alt', v_product.name || ' - Main Image'
          )
          ELSE null
        END,
        'flat', null,
        'lifestyle', COALESCE(
          (SELECT jsonb_agg(jsonb_build_object(
            'url', img,
            'alt', v_product.name || ' - Additional Image'
          ))
          FROM unnest(v_product.additional_images) AS img
          WHERE img IS NOT NULL AND img != v_product.primary_image),
          '[]'::jsonb
        ),
        'details', '[]'::jsonb,
        'variants', '{}'::jsonb,
        'video', null,
        'gallery_order', CASE 
          WHEN v_product.primary_image IS NOT NULL 
          THEN jsonb_build_array(v_product.primary_image)
          ELSE '[]'::jsonb
        END,
        'total_images', CASE
          WHEN v_product.primary_image IS NOT NULL 
          THEN 1 + COALESCE(array_length(v_product.additional_images, 1), 0)
          ELSE COALESCE(array_length(v_product.additional_images, 1), 0)
        END
      );
      
      -- Insert into enhanced products table
      INSERT INTO products_enhanced (
        id,
        name,
        sku,
        handle,
        style_code,
        category,
        price_tier,
        base_price,
        compare_at_price,
        description,
        images,
        status,
        stripe_product_id,
        stripe_active,
        created_at,
        updated_at
      ) VALUES (
        v_product.id,
        v_product.name,
        v_product.sku,
        COALESCE(v_product.handle, LOWER(REPLACE(v_product.name, ' ', '-'))),
        v_product.sku, -- Using SKU as style_code initially
        COALESCE(v_product.category, 'Uncategorized'),
        v_tier_id,
        v_product.base_price,
        v_product.compare_at_price,
        v_product.description,
        v_images_json,
        COALESCE(v_product.status, 'active'),
        v_product.stripe_product_id,
        v_product.stripe_active,
        v_product.created_at,
        v_product.updated_at
      ) ON CONFLICT (id) DO UPDATE SET
        images = EXCLUDED.images,
        price_tier = EXCLUDED.price_tier,
        updated_at = NOW();
      
      v_migrated_count := v_migrated_count + 1;
      
    EXCEPTION WHEN OTHERS THEN
      v_error_count := v_error_count + 1;
      RAISE NOTICE 'Error migrating product %: %', v_product.id, SQLERRM;
    END;
  END LOOP;
  
  RETURN QUERY SELECT v_migrated_count, v_error_count, 
    CASE 
      WHEN v_error_count = 0 THEN 'Success'
      WHEN v_error_count < v_migrated_count THEN 'Partial Success'
      ELSE 'Failed'
    END;
END;
$$ LANGUAGE plpgsql;

-- STEP 4: CREATE HELPER FUNCTIONS
-- -----------------------------------------------------

-- Function to get price tier for a given price
CREATE OR REPLACE FUNCTION get_price_tier(price_cents INTEGER)
RETURNS VARCHAR(50) AS $$
BEGIN
  RETURN (
    SELECT tier_id
    FROM price_tiers
    WHERE price_cents >= min_price 
      AND (max_price IS NULL OR price_cents <= max_price)
    LIMIT 1
  );
END;
$$ LANGUAGE plpgsql;

-- Function to add image to product
CREATE OR REPLACE FUNCTION add_product_image(
  p_product_id UUID,
  p_image_url TEXT,
  p_image_type TEXT, -- 'hero', 'flat', 'lifestyle', 'details'
  p_alt_text TEXT DEFAULT NULL
)
RETURNS BOOLEAN AS $$
DECLARE
  v_current_images JSONB;
  v_new_image JSONB;
BEGIN
  -- Get current images
  SELECT images INTO v_current_images
  FROM products_enhanced
  WHERE id = p_product_id;
  
  IF v_current_images IS NULL THEN
    RETURN FALSE;
  END IF;
  
  -- Create new image object
  v_new_image := jsonb_build_object(
    'url', p_image_url,
    'alt', COALESCE(p_alt_text, p_image_type || ' image')
  );
  
  -- Update based on image type
  CASE p_image_type
    WHEN 'hero', 'flat' THEN
      v_current_images := jsonb_set(v_current_images, ARRAY[p_image_type], v_new_image);
    WHEN 'lifestyle', 'details' THEN
      v_current_images := jsonb_set(
        v_current_images, 
        ARRAY[p_image_type],
        COALESCE(v_current_images->p_image_type, '[]'::jsonb) || jsonb_build_array(v_new_image)
      );
    ELSE
      RETURN FALSE;
  END CASE;
  
  -- Update total images count
  v_current_images := jsonb_set(
    v_current_images,
    '{total_images}',
    to_jsonb((v_current_images->>'total_images')::int + 1)
  );
  
  -- Update the product
  UPDATE products_enhanced
  SET images = v_current_images,
      updated_at = NOW()
  WHERE id = p_product_id;
  
  RETURN TRUE;
END;
$$ LANGUAGE plpgsql;

-- STEP 5: CREATE VIEWS FOR COMPATIBILITY
-- -----------------------------------------------------

-- Create a view that mimics the old products table structure
CREATE OR REPLACE VIEW products_legacy AS
SELECT 
  id,
  name,
  sku,
  handle,
  category,
  base_price,
  compare_at_price,
  description,
  images->>'hero'->>'url' as primary_image,
  status,
  stripe_product_id,
  stripe_active,
  created_at,
  updated_at
FROM products_enhanced;

-- Create a view for product analytics
CREATE OR REPLACE VIEW product_analytics AS
SELECT 
  pe.id,
  pe.name,
  pe.sku,
  pe.category,
  pe.price_tier,
  pt.display_range as price_range,
  pe.base_price,
  pe.status,
  pe.images->>'total_images' as image_count,
  pe.view_count,
  pe.add_to_cart_count,
  pe.purchase_count,
  pe.return_rate,
  CASE 
    WHEN pe.purchase_count > 0 
    THEN ROUND((pe.add_to_cart_count::numeric / pe.view_count::numeric) * 100, 2)
    ELSE 0 
  END as conversion_rate
FROM products_enhanced pe
LEFT JOIN price_tiers pt ON pe.price_tier = pt.tier_id;

-- STEP 6: CREATE RLS POLICIES
-- -----------------------------------------------------

ALTER TABLE products_enhanced ENABLE ROW LEVEL SECURITY;

-- Policy for public read access
CREATE POLICY "Products are viewable by everyone" 
ON products_enhanced FOR SELECT 
USING (status = 'active');

-- Policy for admin full access
CREATE POLICY "Admins can manage all products" 
ON products_enhanced FOR ALL 
USING (
  EXISTS (
    SELECT 1 FROM admin_users
    WHERE user_id = auth.uid()
    AND is_active = true
  )
);

-- STEP 7: CREATE TRIGGERS
-- -----------------------------------------------------

-- Auto-update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_products_enhanced_updated_at
BEFORE UPDATE ON products_enhanced
FOR EACH ROW
EXECUTE FUNCTION update_updated_at_column();

-- STEP 8: TEST DATA INSERTION
-- -----------------------------------------------------

-- Insert a test product to verify the structure
INSERT INTO products_enhanced (
  name,
  sku,
  handle,
  style_code,
  season,
  collection,
  category,
  subcategory,
  price_tier,
  base_price,
  compare_at_price,
  color_family,
  color_name,
  materials,
  fit_type,
  images,
  description,
  status
) VALUES (
  'Test Premium Velvet Blazer',
  'TEST-VB-001',
  'test-premium-velvet-blazer',
  'FW24-TEST-001',
  'FW24',
  'Luxury Essentials',
  'Outerwear',
  'Blazers',
  'TIER_8',
  34900,
  44900,
  'Blue',
  'Midnight Navy',
  '{"primary": "Velvet", "composition": {"Cotton Velvet": 85, "Silk": 15}}'::jsonb,
  'Modern Fit',
  '{
    "hero": {"url": "https://example.com/hero.jpg", "alt": "Test Blazer Hero"},
    "flat": {"url": "https://example.com/flat.jpg", "alt": "Test Blazer Flat"},
    "lifestyle": [
      {"url": "https://example.com/lifestyle1.jpg", "alt": "Lifestyle 1"},
      {"url": "https://example.com/lifestyle2.jpg", "alt": "Lifestyle 2"}
    ],
    "details": [
      {"url": "https://example.com/detail1.jpg", "alt": "Detail 1"}
    ],
    "total_images": 5
  }'::jsonb,
  'A luxurious velvet blazer perfect for formal occasions.',
  'active'
);

-- Output summary
SELECT 'Enhanced Products Table Created Successfully!' as status;
SELECT COUNT(*) as test_products_count FROM products_enhanced WHERE sku LIKE 'TEST-%';