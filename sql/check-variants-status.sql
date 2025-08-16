-- Check current status of product variants

-- 1. Count of products vs variants
SELECT 'Total Products' as metric, COUNT(*) as count FROM products
UNION ALL
SELECT 'Total Product Variants' as metric, COUNT(*) as count FROM product_variants
UNION ALL
SELECT 'Products with Variants' as metric, COUNT(DISTINCT product_id) FROM product_variants;

-- 2. Sample of products and their variant counts
SELECT 
  p.name,
  p.category,
  COUNT(pv.id) as variant_count,
  STRING_AGG(DISTINCT pv.option1, ', ' ORDER BY pv.option1) as sizes
FROM products p
LEFT JOIN product_variants pv ON p.id = pv.product_id
GROUP BY p.id, p.name, p.category
ORDER BY COUNT(pv.id) DESC, p.name
LIMIT 10;

-- 3. Check specific product (Velvet Blazer)
SELECT 
  p.name,
  pv.option1 as size,
  pv.option2 as color,
  pv.inventory_quantity,
  pv.sku
FROM products p
LEFT JOIN product_variants pv ON p.id = pv.product_id
WHERE LOWER(p.name) LIKE '%velvet%'
ORDER BY p.name, pv.option1;