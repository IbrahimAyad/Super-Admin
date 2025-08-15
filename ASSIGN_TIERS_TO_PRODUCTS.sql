-- =====================================================
-- ASSIGN PRICE TIERS TO ALL EXISTING PRODUCTS
-- =====================================================

-- First, let's see what products we have and their prices
SELECT 
  COUNT(*) as total_products,
  MIN(base_price) as min_price,
  MAX(base_price) as max_price,
  AVG(base_price) as avg_price
FROM products_enhanced;

-- Update all products with appropriate price tiers
UPDATE products_enhanced 
SET price_tier = 
  CASE 
    WHEN base_price >= 0 AND base_price <= 9900 THEN 'tier_1_essential'
    WHEN base_price > 9900 AND base_price <= 14900 THEN 'tier_2_starter'
    WHEN base_price > 14900 AND base_price <= 19900 THEN 'tier_3_everyday'
    WHEN base_price > 19900 AND base_price <= 24900 THEN 'tier_4_smart'
    WHEN base_price > 24900 AND base_price <= 29900 THEN 'tier_5_classic'
    WHEN base_price > 29900 AND base_price <= 34900 THEN 'tier_6_refined'
    WHEN base_price > 34900 AND base_price <= 39900 THEN 'tier_7_premium'
    WHEN base_price > 39900 AND base_price <= 44900 THEN 'tier_8_distinguished'
    WHEN base_price > 44900 AND base_price <= 49900 THEN 'tier_9_prestige'
    WHEN base_price > 49900 AND base_price <= 59900 THEN 'tier_10_exclusive'
    WHEN base_price > 59900 AND base_price <= 69900 THEN 'tier_11_signature'
    WHEN base_price > 69900 AND base_price <= 79900 THEN 'tier_12_elite'
    WHEN base_price > 79900 AND base_price <= 89900 THEN 'tier_13_luxe'
    WHEN base_price > 89900 AND base_price <= 99900 THEN 'tier_14_opulent'
    WHEN base_price > 99900 AND base_price <= 119900 THEN 'tier_15_imperial'
    WHEN base_price > 119900 AND base_price <= 139900 THEN 'tier_16_majestic'
    WHEN base_price > 139900 AND base_price <= 159900 THEN 'tier_17_sovereign'
    WHEN base_price > 159900 AND base_price <= 179900 THEN 'tier_18_regal'
    WHEN base_price > 179900 AND base_price <= 199900 THEN 'tier_19_pinnacle'
    WHEN base_price > 199900 THEN 'tier_20_bespoke'
    ELSE 'tier_3_everyday' -- Default to tier 3 if something's wrong
  END
WHERE price_tier IS NULL OR price_tier = '';

-- Show results of tier assignment
SELECT 
  pt.tier_number,
  pt.tier_name,
  pt.display_range,
  COUNT(pe.id) as product_count,
  MIN(pe.base_price/100.0) as min_price_dollars,
  MAX(pe.base_price/100.0) as max_price_dollars
FROM price_tiers pt
LEFT JOIN products_enhanced pe ON pe.price_tier = pt.tier_id
GROUP BY pt.tier_number, pt.tier_name, pt.display_range
ORDER BY pt.tier_number;

-- Show summary
SELECT 
  'Tier Assignment Complete' as status,
  COUNT(*) as total_products,
  COUNT(price_tier) as products_with_tiers,
  COUNT(DISTINCT price_tier) as unique_tiers_used
FROM products_enhanced;