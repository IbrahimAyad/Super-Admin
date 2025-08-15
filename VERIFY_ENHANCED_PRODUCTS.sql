-- COMPREHENSIVE VERIFICATION OF ENHANCED PRODUCTS

-- 1. Count all products
SELECT 
  'Total Enhanced Products' as metric,
  COUNT(*) as count
FROM products_enhanced;

-- 2. Count by subcategory
SELECT 
  subcategory,
  COUNT(*) as count,
  STRING_AGG(name, ', ' ORDER BY name) as sample_products
FROM products_enhanced
WHERE category = 'Blazers'
GROUP BY subcategory
ORDER BY count DESC;

-- 3. Check image coverage
SELECT 
  'Products with hero image' as metric,
  COUNT(CASE WHEN images->'hero' IS NOT NULL THEN 1 END) as count,
  ROUND(COUNT(CASE WHEN images->'hero' IS NOT NULL THEN 1 END) * 100.0 / COUNT(*), 2) as percentage
FROM products_enhanced
UNION ALL
SELECT 
  'Products with lifestyle images' as metric,
  COUNT(CASE WHEN jsonb_array_length(COALESCE(images->'lifestyle', '[]'::jsonb)) > 0 THEN 1 END) as count,
  ROUND(COUNT(CASE WHEN jsonb_array_length(COALESCE(images->'lifestyle', '[]'::jsonb)) > 0 THEN 1 END) * 100.0 / COUNT(*), 2) as percentage
FROM products_enhanced
UNION ALL
SELECT 
  'Products with detail images' as metric,
  COUNT(CASE WHEN jsonb_array_length(COALESCE(images->'details', '[]'::jsonb)) > 0 THEN 1 END) as count,
  ROUND(COUNT(CASE WHEN jsonb_array_length(COALESCE(images->'details', '[]'::jsonb)) > 0 THEN 1 END) * 100.0 / COUNT(*), 2) as percentage
FROM products_enhanced;

-- 4. Price tier distribution
SELECT 
  price_tier,
  COUNT(*) as product_count,
  '$' || MIN(base_price/100.0) || ' - $' || MAX(base_price/100.0) as price_range
FROM products_enhanced
GROUP BY price_tier
ORDER BY price_tier;

-- 5. Check for missing critical data
SELECT 
  'Missing SKU' as issue,
  COUNT(CASE WHEN sku IS NULL OR sku = '' THEN 1 END) as count
FROM products_enhanced
UNION ALL
SELECT 
  'Missing price' as issue,
  COUNT(CASE WHEN base_price IS NULL OR base_price = 0 THEN 1 END) as count
FROM products_enhanced
UNION ALL
SELECT 
  'Missing hero image' as issue,
  COUNT(CASE WHEN images->'hero' IS NULL THEN 1 END) as count
FROM products_enhanced
UNION ALL
SELECT 
  'Missing status' as issue,
  COUNT(CASE WHEN status IS NULL OR status = '' THEN 1 END) as count
FROM products_enhanced;

-- 6. Sample of products with all images
SELECT 
  name,
  sku,
  subcategory,
  price_tier,
  '$' || (base_price/100.0) as price,
  images->'hero'->>'url' as hero_url,
  jsonb_array_length(COALESCE(images->'lifestyle', '[]'::jsonb)) as lifestyle_count,
  jsonb_array_length(COALESCE(images->'details', '[]'::jsonb)) as detail_count,
  (images->>'total_images')::int as total_images
FROM products_enhanced
WHERE images->'hero' IS NOT NULL
ORDER BY created_at DESC
LIMIT 10;

-- 7. Products that need Stripe mapping
SELECT 
  'Products without Stripe ID' as metric,
  COUNT(*) as count
FROM products_enhanced
WHERE stripe_product_id IS NULL OR stripe_product_id = '';

-- 8. Verify handle/slug consistency
SELECT 
  'Has handle' as field,
  COUNT(CASE WHEN handle IS NOT NULL THEN 1 END) as count
FROM products_enhanced
UNION ALL
SELECT 
  'Has slug' as field,
  COUNT(CASE WHEN slug IS NOT NULL THEN 1 END) as count
FROM products_enhanced
UNION ALL
SELECT 
  'Handle matches slug' as field,
  COUNT(CASE WHEN handle = slug THEN 1 END) as count
FROM products_enhanced;