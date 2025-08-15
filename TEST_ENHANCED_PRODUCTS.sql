-- =====================================================
-- TEST ENHANCED PRODUCT SYSTEM
-- Safe testing before full migration
-- =====================================================

-- STEP 1: CHECK CURRENT STATE
-- -----------------------------------------------------
SELECT 'Current Products Count' as check_type, COUNT(*) as count 
FROM products;

SELECT 'Products with Stripe Integration' as check_type, COUNT(*) as count 
FROM products 
WHERE stripe_product_id IS NOT NULL;

SELECT 'Products with Images' as check_type, COUNT(*) as count 
FROM products 
WHERE primary_image IS NOT NULL AND primary_image != '';

-- STEP 2: TEST MIGRATION WITH SAMPLE DATA
-- -----------------------------------------------------

-- Test with 5 random products first
WITH sample_products AS (
  SELECT p.*, 
         array_agg(DISTINCT pi.image_url) FILTER (WHERE pi.image_url IS NOT NULL) as additional_images
  FROM products p
  LEFT JOIN product_images pi ON p.id = pi.product_id
  GROUP BY p.id
  LIMIT 5
)
SELECT 
  name,
  sku,
  category,
  base_price,
  CASE 
    WHEN base_price BETWEEN 5000 AND 7499 THEN 'TIER_1'
    WHEN base_price BETWEEN 7500 AND 9999 THEN 'TIER_2'
    WHEN base_price BETWEEN 10000 AND 12499 THEN 'TIER_3'
    WHEN base_price BETWEEN 12500 AND 14999 THEN 'TIER_4'
    WHEN base_price BETWEEN 15000 AND 19999 THEN 'TIER_5'
    WHEN base_price BETWEEN 20000 AND 24999 THEN 'TIER_6'
    WHEN base_price BETWEEN 25000 AND 29999 THEN 'TIER_7'
    WHEN base_price BETWEEN 30000 AND 39999 THEN 'TIER_8'
    WHEN base_price BETWEEN 40000 AND 49999 THEN 'TIER_9'
    WHEN base_price BETWEEN 50000 AND 59999 THEN 'TIER_10'
    WHEN base_price BETWEEN 60000 AND 69999 THEN 'TIER_11'
    WHEN base_price BETWEEN 70000 AND 79999 THEN 'TIER_12'
    WHEN base_price BETWEEN 80000 AND 89999 THEN 'TIER_13'
    WHEN base_price BETWEEN 90000 AND 99999 THEN 'TIER_14'
    WHEN base_price BETWEEN 100000 AND 124999 THEN 'TIER_15'
    WHEN base_price BETWEEN 125000 AND 149999 THEN 'TIER_16'
    WHEN base_price BETWEEN 150000 AND 199999 THEN 'TIER_17'
    WHEN base_price BETWEEN 200000 AND 299999 THEN 'TIER_18'
    WHEN base_price BETWEEN 300000 AND 499999 THEN 'TIER_19'
    WHEN base_price >= 500000 THEN 'TIER_20'
    ELSE 'TIER_1'
  END as suggested_tier,
  primary_image,
  array_length(additional_images, 1) as additional_image_count
FROM sample_products;

-- STEP 3: VERIFY IMAGE URL PATTERNS
-- -----------------------------------------------------
SELECT 
  CASE 
    WHEN primary_image LIKE '%pub-8ea0502158a94b8ca8a7abb9e18a57e8%' THEN 'Bucket 1'
    WHEN primary_image LIKE '%pub-5cd8c531c0034986bf6282a223bd0564%' THEN 'Bucket 2'
    WHEN primary_image LIKE '%placeholder%' THEN 'Placeholder'
    WHEN primary_image IS NULL OR primary_image = '' THEN 'No Image'
    ELSE 'Other'
  END as image_source,
  COUNT(*) as count
FROM products
GROUP BY image_source;

-- STEP 4: CHECK PRICE DISTRIBUTION FOR TIERS
-- -----------------------------------------------------
WITH price_analysis AS (
  SELECT 
    base_price,
    CASE 
      WHEN base_price < 5000 THEN 'Below TIER_1 (<$50)'
      WHEN base_price BETWEEN 5000 AND 7499 THEN 'TIER_1 ($50-74)'
      WHEN base_price BETWEEN 7500 AND 9999 THEN 'TIER_2 ($75-99)'
      WHEN base_price BETWEEN 10000 AND 12499 THEN 'TIER_3 ($100-124)'
      WHEN base_price BETWEEN 12500 AND 14999 THEN 'TIER_4 ($125-149)'
      WHEN base_price BETWEEN 15000 AND 19999 THEN 'TIER_5 ($150-199)'
      WHEN base_price BETWEEN 20000 AND 24999 THEN 'TIER_6 ($200-249)'
      WHEN base_price BETWEEN 25000 AND 29999 THEN 'TIER_7 ($250-299)'
      WHEN base_price BETWEEN 30000 AND 39999 THEN 'TIER_8 ($300-399)'
      WHEN base_price BETWEEN 40000 AND 49999 THEN 'TIER_9 ($400-499)'
      WHEN base_price BETWEEN 50000 AND 59999 THEN 'TIER_10 ($500-599)'
      WHEN base_price >= 60000 THEN 'TIER_11+ ($600+)'
      ELSE 'Unknown'
    END as price_tier_range
  FROM products
  WHERE base_price IS NOT NULL
)
SELECT 
  price_tier_range,
  COUNT(*) as product_count,
  MIN(base_price) as min_price_cents,
  MAX(base_price) as max_price_cents,
  '$' || ROUND(AVG(base_price)/100.0, 2) as avg_price_dollars
FROM price_analysis
GROUP BY price_tier_range
ORDER BY MIN(base_price);

-- STEP 5: TEST IMAGE JSONB STRUCTURE
-- -----------------------------------------------------
SELECT jsonb_pretty(
  jsonb_build_object(
    'hero', jsonb_build_object(
      'url', 'https://pub-5cd8c531c0034986bf6282a223bd0564.r2.dev/batch_1/test.jpg',
      'alt', 'Test Product - Hero'
    ),
    'flat', null,
    'lifestyle', jsonb_build_array(
      jsonb_build_object('url', 'https://example.com/lifestyle1.jpg', 'alt', 'Lifestyle 1'),
      jsonb_build_object('url', 'https://example.com/lifestyle2.jpg', 'alt', 'Lifestyle 2')
    ),
    'details', '[]'::jsonb,
    'variants', '{}'::jsonb,
    'total_images', 3
  )
) as sample_image_structure;

-- STEP 6: CHECK FOR POTENTIAL MIGRATION ISSUES
-- -----------------------------------------------------

-- Check for duplicate SKUs
SELECT 'Duplicate SKUs' as issue_type, sku, COUNT(*) as count
FROM products
WHERE sku IS NOT NULL
GROUP BY sku
HAVING COUNT(*) > 1;

-- Check for missing required fields
SELECT 'Missing Required Fields' as issue_type, COUNT(*) as count
FROM products
WHERE name IS NULL OR name = ''
   OR sku IS NULL OR sku = ''
   OR base_price IS NULL OR base_price <= 0;

-- Check for invalid categories
SELECT 'Category Distribution' as check_type, 
       COALESCE(category, 'Uncategorized') as category, 
       COUNT(*) as count
FROM products
GROUP BY category
ORDER BY count DESC;

-- STEP 7: MIGRATION READINESS SUMMARY
-- -----------------------------------------------------
WITH readiness_check AS (
  SELECT 
    COUNT(*) as total_products,
    COUNT(CASE WHEN name IS NOT NULL AND name != '' THEN 1 END) as has_name,
    COUNT(CASE WHEN sku IS NOT NULL AND sku != '' THEN 1 END) as has_sku,
    COUNT(CASE WHEN base_price > 0 THEN 1 END) as has_valid_price,
    COUNT(CASE WHEN primary_image IS NOT NULL AND primary_image != '' THEN 1 END) as has_image,
    COUNT(CASE WHEN stripe_product_id IS NOT NULL THEN 1 END) as has_stripe
  FROM products
)
SELECT 
  'Total Products' as metric, total_products as count,
  '100%' as percentage
FROM readiness_check
UNION ALL
SELECT 
  'Has Name' as metric, has_name as count,
  ROUND(has_name * 100.0 / NULLIF(total_products, 0), 1) || '%' as percentage
FROM readiness_check
UNION ALL
SELECT 
  'Has SKU' as metric, has_sku as count,
  ROUND(has_sku * 100.0 / NULLIF(total_products, 0), 1) || '%' as percentage
FROM readiness_check
UNION ALL
SELECT 
  'Has Valid Price' as metric, has_valid_price as count,
  ROUND(has_valid_price * 100.0 / NULLIF(total_products, 0), 1) || '%' as percentage
FROM readiness_check
UNION ALL
SELECT 
  'Has Image' as metric, has_image as count,
  ROUND(has_image * 100.0 / NULLIF(total_products, 0), 1) || '%' as percentage
FROM readiness_check
UNION ALL
SELECT 
  'Has Stripe Integration' as metric, has_stripe as count,
  ROUND(has_stripe * 100.0 / NULLIF(total_products, 0), 1) || '%' as percentage
FROM readiness_check;