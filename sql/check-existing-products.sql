-- Check what products already exist
SELECT handle, name, sku, category, base_price 
FROM products_enhanced 
WHERE handle IN (
    'black-suspender-bowtie-set',
    'brown-suspender-bowtie-set',
    'black-strip-shawl-lapel'
)
ORDER BY handle;

-- Get count of existing products by category
SELECT 
    category,
    COUNT(*) as count
FROM products_enhanced
GROUP BY category
ORDER BY category;

-- Check for any Fall 2025 or Accessories products
SELECT COUNT(*) as existing_count
FROM products_enhanced
WHERE sku LIKE 'F25-%' OR sku LIKE 'ACC-%';