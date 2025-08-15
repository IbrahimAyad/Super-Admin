-- ADD SEO FIELDS TO ENHANCED PRODUCTS TABLE
-- Run this in Supabase SQL Editor

-- Add SEO columns if they don't exist
ALTER TABLE products_enhanced 
ADD COLUMN IF NOT EXISTS meta_title VARCHAR(70),
ADD COLUMN IF NOT EXISTS meta_description VARCHAR(160),
ADD COLUMN IF NOT EXISTS meta_keywords TEXT[],
ADD COLUMN IF NOT EXISTS og_title VARCHAR(70),
ADD COLUMN IF NOT EXISTS og_description VARCHAR(200),
ADD COLUMN IF NOT EXISTS og_image VARCHAR(500),
ADD COLUMN IF NOT EXISTS canonical_url VARCHAR(500),
ADD COLUMN IF NOT EXISTS structured_data JSONB,
ADD COLUMN IF NOT EXISTS tags TEXT[],
ADD COLUMN IF NOT EXISTS search_terms TEXT,
ADD COLUMN IF NOT EXISTS url_slug VARCHAR(255),
ADD COLUMN IF NOT EXISTS is_indexable BOOLEAN DEFAULT true,
ADD COLUMN IF NOT EXISTS sitemap_priority DECIMAL(2,1) DEFAULT 0.8,
ADD COLUMN IF NOT EXISTS sitemap_change_freq VARCHAR(20) DEFAULT 'weekly';

-- Create indexes for SEO fields
CREATE INDEX IF NOT EXISTS idx_products_enhanced_meta_title ON products_enhanced(meta_title);
CREATE INDEX IF NOT EXISTS idx_products_enhanced_tags ON products_enhanced USING gin(tags);
CREATE INDEX IF NOT EXISTS idx_products_enhanced_search_terms ON products_enhanced USING gin(to_tsvector('english', search_terms));
CREATE INDEX IF NOT EXISTS idx_products_enhanced_is_indexable ON products_enhanced(is_indexable);

-- Update existing products with auto-generated SEO data
UPDATE products_enhanced
SET 
  meta_title = CASE 
    WHEN meta_title IS NULL THEN 
      LEFT(name || ' | KCT Menswear', 70)
    ELSE meta_title
  END,
  meta_description = CASE 
    WHEN meta_description IS NULL THEN 
      LEFT(COALESCE(description, name || ' - Premium ' || category || ' from KCT Menswear. Shop our ' || LOWER(collection) || ' collection.'), 160)
    ELSE meta_description
  END,
  og_title = CASE 
    WHEN og_title IS NULL THEN 
      LEFT(name, 70)
    ELSE og_title
  END,
  og_description = CASE 
    WHEN og_description IS NULL THEN 
      LEFT(COALESCE(description, name || ' from KCT Menswear'), 200)
    ELSE og_description
  END,
  og_image = CASE 
    WHEN og_image IS NULL THEN 
      images->'hero'->>'url'
    ELSE og_image
  END,
  canonical_url = CASE 
    WHEN canonical_url IS NULL THEN 
      'https://kctmenswear.com/products/' || handle
    ELSE canonical_url
  END,
  url_slug = CASE 
    WHEN url_slug IS NULL THEN 
      handle
    ELSE url_slug
  END,
  tags = CASE 
    WHEN tags IS NULL OR array_length(tags, 1) IS NULL THEN 
      ARRAY[
        LOWER(category),
        LOWER(COALESCE(subcategory, '')),
        LOWER(COALESCE(color_family, '')),
        LOWER(COALESCE(season, '')),
        LOWER(COALESCE(collection, ''))
      ]
    ELSE tags
  END,
  search_terms = CASE 
    WHEN search_terms IS NULL THEN 
      LOWER(
        name || ' ' || 
        COALESCE(sku, '') || ' ' || 
        COALESCE(category, '') || ' ' || 
        COALESCE(subcategory, '') || ' ' || 
        COALESCE(color_name, '') || ' ' || 
        COALESCE(description, '')
      )
    ELSE search_terms
  END,
  structured_data = CASE 
    WHEN structured_data IS NULL THEN 
      jsonb_build_object(
        '@context', 'https://schema.org',
        '@type', 'Product',
        'name', name,
        'description', COALESCE(description, ''),
        'sku', sku,
        'brand', jsonb_build_object(
          '@type', 'Brand',
          'name', 'KCT Menswear'
        ),
        'offers', jsonb_build_object(
          '@type', 'Offer',
          'priceCurrency', 'USD',
          'price', ROUND(base_price / 100.0, 2),
          'availability', CASE 
            WHEN status = 'active' THEN 'https://schema.org/InStock'
            ELSE 'https://schema.org/OutOfStock'
          END,
          'seller', jsonb_build_object(
            '@type', 'Organization',
            'name', 'KCT Menswear'
          )
        ),
        'image', CASE 
          WHEN images->'hero'->>'url' IS NOT NULL THEN 
            jsonb_build_array(images->'hero'->>'url')
          ELSE 
            '[]'::jsonb
        END,
        'category', category
      )
    ELSE structured_data
  END
WHERE meta_title IS NULL OR meta_description IS NULL;

-- Create a function to auto-generate SEO fields for new products
CREATE OR REPLACE FUNCTION generate_product_seo()
RETURNS TRIGGER AS $$
BEGIN
  -- Auto-generate meta_title if not provided
  IF NEW.meta_title IS NULL OR NEW.meta_title = '' THEN
    NEW.meta_title := LEFT(NEW.name || ' | KCT Menswear', 70);
  END IF;
  
  -- Auto-generate meta_description if not provided
  IF NEW.meta_description IS NULL OR NEW.meta_description = '' THEN
    NEW.meta_description := LEFT(
      COALESCE(
        NEW.description, 
        NEW.name || ' - Premium ' || NEW.category || ' from KCT Menswear.'
      ), 
      160
    );
  END IF;
  
  -- Auto-generate OG fields
  IF NEW.og_title IS NULL OR NEW.og_title = '' THEN
    NEW.og_title := LEFT(NEW.name, 70);
  END IF;
  
  IF NEW.og_description IS NULL OR NEW.og_description = '' THEN
    NEW.og_description := LEFT(COALESCE(NEW.description, NEW.name), 200);
  END IF;
  
  IF NEW.og_image IS NULL OR NEW.og_image = '' THEN
    NEW.og_image := NEW.images->'hero'->>'url';
  END IF;
  
  -- Auto-generate canonical URL
  IF NEW.canonical_url IS NULL OR NEW.canonical_url = '' THEN
    NEW.canonical_url := 'https://kctmenswear.com/products/' || NEW.handle;
  END IF;
  
  -- Auto-generate URL slug
  IF NEW.url_slug IS NULL OR NEW.url_slug = '' THEN
    NEW.url_slug := NEW.handle;
  END IF;
  
  -- Auto-generate tags
  IF NEW.tags IS NULL OR array_length(NEW.tags, 1) IS NULL THEN
    NEW.tags := ARRAY[
      LOWER(NEW.category),
      LOWER(COALESCE(NEW.subcategory, '')),
      LOWER(COALESCE(NEW.color_family, '')),
      LOWER(COALESCE(NEW.season, '')),
      LOWER(COALESCE(NEW.collection, ''))
    ];
  END IF;
  
  -- Auto-generate search terms
  IF NEW.search_terms IS NULL OR NEW.search_terms = '' THEN
    NEW.search_terms := LOWER(
      NEW.name || ' ' || 
      COALESCE(NEW.sku, '') || ' ' || 
      COALESCE(NEW.category, '') || ' ' || 
      COALESCE(NEW.subcategory, '') || ' ' || 
      COALESCE(NEW.color_name, '') || ' ' || 
      COALESCE(NEW.description, '')
    );
  END IF;
  
  -- Auto-generate structured data
  IF NEW.structured_data IS NULL THEN
    NEW.structured_data := jsonb_build_object(
      '@context', 'https://schema.org',
      '@type', 'Product',
      'name', NEW.name,
      'description', COALESCE(NEW.description, ''),
      'sku', NEW.sku,
      'brand', jsonb_build_object(
        '@type', 'Brand',
        'name', 'KCT Menswear'
      ),
      'offers', jsonb_build_object(
        '@type', 'Offer',
        'priceCurrency', 'USD',
        'price', ROUND(NEW.base_price / 100.0, 2),
        'availability', CASE 
          WHEN NEW.status = 'active' THEN 'https://schema.org/InStock'
          ELSE 'https://schema.org/OutOfStock'
        END
      ),
      'image', CASE 
        WHEN NEW.images->'hero'->>'url' IS NOT NULL THEN 
          jsonb_build_array(NEW.images->'hero'->>'url')
        ELSE 
          '[]'::jsonb
      END,
      'category', NEW.category
    );
  END IF;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger for auto-generating SEO on insert/update
DROP TRIGGER IF EXISTS trigger_generate_product_seo ON products_enhanced;
CREATE TRIGGER trigger_generate_product_seo
BEFORE INSERT OR UPDATE ON products_enhanced
FOR EACH ROW
EXECUTE FUNCTION generate_product_seo();

-- Verify SEO fields were added
SELECT 
  column_name,
  data_type,
  character_maximum_length
FROM information_schema.columns
WHERE table_name = 'products_enhanced'
AND column_name IN (
  'meta_title', 'meta_description', 'meta_keywords',
  'og_title', 'og_description', 'og_image',
  'canonical_url', 'structured_data', 'tags',
  'search_terms', 'url_slug', 'is_indexable',
  'sitemap_priority', 'sitemap_change_freq'
)
ORDER BY column_name;

-- Sample check of SEO data
SELECT 
  name,
  meta_title,
  LEFT(meta_description, 50) || '...' as meta_desc_preview,
  og_image,
  canonical_url,
  tags
FROM products_enhanced
LIMIT 5;