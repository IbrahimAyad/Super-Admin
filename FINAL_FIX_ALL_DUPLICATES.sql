-- FINAL FIX FOR ALL REMAINING DUPLICATES
-- Using exact product IDs to ensure updates work

BEGIN;

-- ========================================
-- BLAZERS - Fix the duplicate images
-- ========================================

-- 3 blazers sharing the same black floral pattern image - give them unique velvet images
UPDATE products 
SET primary_image = 'https://cdn.kctmenswear.com/blazers/velvet/navy-blue-velvet-blazer/main.webp'
WHERE id = '7525d50c-3bd6-4706-9c5d-593e456c4220'; -- Men's All Navy Velvet Jacker

UPDATE products 
SET primary_image = 'https://cdn.kctmenswear.com/blazers/velvet/red-velvet-blazer/main.webp'
WHERE id = '49beed7c-ecaa-4fd5-a699-c4954cfa0be7'; -- Men's All Red Velvet Jacker

UPDATE products 
SET primary_image = 'https://cdn.kctmenswear.com/blazers/velvet/midnight-navy-velvet-blazer/main.webp'
WHERE id = '7e401c21-3c32-41af-8591-67427cd2b993'; -- Premium Velvet Blazer - Midnight Navy

-- 2 red prom blazers sharing same image - use different red blazer images
UPDATE products 
SET primary_image = 'https://cdn.kctmenswear.com/blazers/prom/mens-red-floral-gold-shiny-prom-blazer/main.webp'
WHERE id = 'ed19f82b-367f-46dd-bd18-0c84b6550aff'; -- Men's Red Floral Pattern Prom Blazer

-- Keep the other red one as is (3f5d1791-76c7-4fdf-9aca-90f104164a50)

-- 2 white prom blazers sharing same image - use different white blazer image
UPDATE products 
SET primary_image = 'https://cdn.kctmenswear.com/blazers/sparkle/white-black-geometric-sparkle-blazer/main.webp'
WHERE id = '3e0e6c6b-02b8-466e-b4cc-ffacc4b507a6'; -- Men's Off White Prom Blazer

-- Keep the other white one as is (d4854896-00fa-47dd-8ba1-48e919fc6ec3)

-- 2 navy velvet blazers sharing same image - use alternate navy image
UPDATE products 
SET primary_image = 'https://cdn.kctmenswear.com/blazers/velvet/dark-green-velvet-blazer/main.webp'
WHERE id = 'd4310852-1f65-4138-8c4c-51bcb3a1772f'; -- Men's All Navy Velvet Blazer (use dark color as substitute)

-- Keep the other navy one as is (d52a8599-c01b-40f8-9bbd-1bc4bae81bf9)

-- ========================================
-- Now get the other categories that need fixing
-- ========================================

-- Get all Accessories with their current images
SELECT 'ACCESSORIES TO FIX' as category,
    id, name, sku, primary_image
FROM products 
WHERE category = 'Accessories'
ORDER BY primary_image, name
LIMIT 40;

-- Get all Tuxedos with their current images
SELECT 'TUXEDOS TO FIX' as category,
    id, name, sku, primary_image
FROM products 
WHERE category = 'Tuxedos'
ORDER BY primary_image, name
LIMIT 25;

-- Verify blazer fixes
SELECT 'BLAZERS AFTER FIX' as status,
    COUNT(*) as total,
    COUNT(DISTINCT primary_image) as unique_images,
    COUNT(*) - COUNT(DISTINCT primary_image) as duplicates
FROM products
WHERE category = 'Blazers';

COMMIT;