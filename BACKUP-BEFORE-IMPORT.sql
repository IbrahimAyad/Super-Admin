-- BACKUP BEFORE KCT MASTER IMPORT
-- Run this in Supabase SQL Editor BEFORE importing!

-- 1. Create backup tables with timestamp
CREATE TABLE IF NOT EXISTS products_backup_2025_01_14 AS 
SELECT * FROM products;

CREATE TABLE IF NOT EXISTS product_variants_backup_2025_01_14 AS 
SELECT * FROM product_variants;

CREATE TABLE IF NOT EXISTS product_images_backup_2025_01_14 AS 
SELECT * FROM product_images;

-- 2. Verify backups were created
SELECT 
    'products_backup' as table_name,
    COUNT(*) as row_count
FROM products_backup_2025_01_14
UNION ALL
SELECT 
    'variants_backup',
    COUNT(*)
FROM product_variants_backup_2025_01_14
UNION ALL
SELECT 
    'images_backup',
    COUNT(*)
FROM product_images_backup_2025_01_14;

-- 3. Current state before import
SELECT 
    'Current State Before Import' as status,
    (SELECT COUNT(*) FROM products) as products,
    (SELECT COUNT(*) FROM product_variants) as variants,
    (SELECT COUNT(*) FROM product_images) as images,
    (SELECT COUNT(*) FROM product_variants WHERE stripe_price_id IS NOT NULL) as variants_with_stripe;

-- Success message
DO $$
BEGIN
  RAISE NOTICE '✅ Backup complete!';
  RAISE NOTICE 'Tables backed up:';
  RAISE NOTICE '  - products_backup_2025_01_14';
  RAISE NOTICE '  - product_variants_backup_2025_01_14';
  RAISE NOTICE '  - product_images_backup_2025_01_14';
  RAISE NOTICE '';
  RAISE NOTICE 'You can now safely run the import';
END $$;