-- Add New Accessories and Pants Products
-- Run this AFTER fixing Stripe to add new products

BEGIN;

-- Add Socks (4 colors at $10.00 each)
INSERT INTO products (sku, name, description, category, base_price, status, visibility, featured, primary_image, created_at, updated_at)
VALUES 
('SOCK-BLK-001', 'Black Solid Dress Socks', 'Premium black dress socks for formal wear', 'Accessories', 1000, 'active', true, false, NULL, NOW(), NOW()),
('SOCK-WHT-001', 'White Solid Dress Socks', 'Premium white dress socks for formal wear', 'Accessories', 1000, 'active', true, false, NULL, NOW(), NOW()),
('SOCK-NAV-001', 'Navy Solid Dress Socks', 'Premium navy dress socks for formal wear', 'Accessories', 1000, 'active', true, false, NULL, NOW(), NOW()),
('SOCK-GRY-001', 'Grey Solid Dress Socks', 'Premium grey dress socks for formal wear', 'Accessories', 1000, 'active', true, false, NULL, NOW(), NOW());

-- Add sock variants (one size fits most)
INSERT INTO product_variants (product_id, title, sku, price, option1, option2, inventory_quantity, created_at, updated_at)
SELECT 
  p.id,
  p.name || ' - One Size',
  p.sku || '-OS',
  1000,
  'One Size',
  NULL,
  100,
  NOW(),
  NOW()
FROM products p
WHERE p.sku IN ('SOCK-BLK-001', 'SOCK-WHT-001', 'SOCK-NAV-001', 'SOCK-GRY-001');

-- Add Belts (2 colors at $29.99 each)
INSERT INTO products (sku, name, description, category, base_price, status, visibility, featured, primary_image, created_at, updated_at)
VALUES 
('BELT-BLK-001', 'Black Leather Dress Belt', 'Premium black leather dress belt', 'Accessories', 2999, 'active', true, false, NULL, NOW(), NOW()),
('BELT-BRN-001', 'Brown Leather Dress Belt', 'Premium brown leather dress belt', 'Accessories', 2999, 'active', true, false, NULL, NOW(), NOW());

-- Add belt variants (sizes 30-44)
WITH belt_sizes AS (
  SELECT unnest(ARRAY['30', '32', '34', '36', '38', '40', '42', '44']) as size
)
INSERT INTO product_variants (product_id, title, sku, price, option1, option2, inventory_quantity, created_at, updated_at)
SELECT 
  p.id,
  p.name || ' - Size ' || bs.size,
  p.sku || '-' || bs.size,
  2999,
  bs.size,
  NULL,
  50,
  NOW(),
  NOW()
FROM products p
CROSS JOIN belt_sizes bs
WHERE p.sku IN ('BELT-BLK-001', 'BELT-BRN-001');

-- Add Dress Pants - Slim Fit (5 colors at $59.99 each)
INSERT INTO products (sku, name, description, category, base_price, status, visibility, featured, primary_image, created_at, updated_at)
VALUES 
('PANT-BLK-SLIM-001', 'Black Slim Dress Pants', 'Premium black slim fit dress pants', 'Men''s Pants', 5999, 'active', true, false, NULL, NOW(), NOW()),
('PANT-NAV-SLIM-001', 'Navy Slim Dress Pants', 'Premium navy slim fit dress pants', 'Men''s Pants', 5999, 'active', true, false, NULL, NOW(), NOW()),
('PANT-GRY-SLIM-001', 'Grey Slim Dress Pants', 'Premium grey slim fit dress pants', 'Men''s Pants', 5999, 'active', true, false, NULL, NOW(), NOW()),
('PANT-MDB-SLIM-001', 'Midnight Blue Slim Dress Pants', 'Premium midnight blue slim fit dress pants', 'Men''s Pants', 5999, 'active', true, false, NULL, NOW(), NOW()),
('PANT-LGY-SLIM-001', 'Light Grey Slim Dress Pants', 'Premium light grey slim fit dress pants', 'Men''s Pants', 5999, 'active', true, false, NULL, NOW(), NOW());

-- Add dress pants variants (waist 28-42, length 28-36)
WITH pant_sizes AS (
  SELECT 
    waist::text || 'x' || length::text as size,
    waist,
    length
  FROM 
    generate_series(28, 42, 2) as waist,
    generate_series(28, 36, 2) as length
  WHERE 
    -- Common size combinations only
    (waist BETWEEN 28 AND 32 AND length BETWEEN 28 AND 32) OR
    (waist BETWEEN 32 AND 36 AND length BETWEEN 30 AND 34) OR
    (waist BETWEEN 36 AND 42 AND length BETWEEN 32 AND 36)
)
INSERT INTO product_variants (product_id, title, sku, price, option1, option2, inventory_quantity, created_at, updated_at)
SELECT 
  p.id,
  p.name || ' - ' || ps.size,
  p.sku || '-' || ps.size,
  5999,
  ps.size,
  'Slim Fit',
  25,
  NOW(),
  NOW()
FROM products p
CROSS JOIN pant_sizes ps
WHERE p.sku IN ('PANT-BLK-SLIM-001', 'PANT-NAV-SLIM-001', 'PANT-GRY-SLIM-001', 'PANT-MDB-SLIM-001', 'PANT-LGY-SLIM-001');

-- Add Stretch Pants - Black Slim Flex ($69.99)
INSERT INTO products (sku, name, description, category, base_price, status, visibility, featured, primary_image, created_at, updated_at)
VALUES 
('PANT-BLK-FLEX-001', 'Black Slim Stretch Flex Pants', 'Premium black slim stretch pants with flex technology', 'Men''s Pants', 6999, 'active', true, false, NULL, NOW(), NOW());

-- Add stretch pants variants
WITH pant_sizes AS (
  SELECT 
    waist::text || 'x' || length::text as size
  FROM 
    generate_series(28, 42, 2) as waist,
    generate_series(28, 36, 2) as length
  WHERE 
    (waist BETWEEN 28 AND 32 AND length BETWEEN 28 AND 32) OR
    (waist BETWEEN 32 AND 36 AND length BETWEEN 30 AND 34) OR
    (waist BETWEEN 36 AND 42 AND length BETWEEN 32 AND 36)
)
INSERT INTO product_variants (product_id, title, sku, price, option1, option2, inventory_quantity, created_at, updated_at)
SELECT 
  p.id,
  p.name || ' - ' || ps.size,
  p.sku || '-' || ps.size,
  6999,
  ps.size,
  'Slim Flex',
  30,
  NOW(),
  NOW()
FROM products p
CROSS JOIN pant_sizes ps
WHERE p.sku = 'PANT-BLK-FLEX-001';

-- Add Tuxedo Pants - Black ($69.99)
INSERT INTO products (sku, name, description, category, base_price, status, visibility, featured, primary_image, created_at, updated_at)
VALUES 
('PANT-TUX-BLK-001', 'Black Tuxedo Pants - Slim', 'Premium black tuxedo pants with satin stripe', 'Men''s Pants', 6999, 'active', true, false, NULL, NOW(), NOW());

-- Add tuxedo pants variants
WITH pant_sizes AS (
  SELECT 
    waist::text || 'x' || length::text as size
  FROM 
    generate_series(28, 42, 2) as waist,
    generate_series(28, 36, 2) as length
  WHERE 
    (waist BETWEEN 28 AND 32 AND length BETWEEN 28 AND 32) OR
    (waist BETWEEN 32 AND 36 AND length BETWEEN 30 AND 34) OR
    (waist BETWEEN 36 AND 42 AND length BETWEEN 32 AND 36)
)
INSERT INTO product_variants (product_id, title, sku, price, option1, option2, inventory_quantity, created_at, updated_at)
SELECT 
  p.id,
  p.name || ' - ' || ps.size,
  p.sku || '-' || ps.size,
  6999,
  ps.size,
  'Slim Fit',
  20,
  NOW(),
  NOW()
FROM products p
CROSS JOIN pant_sizes ps
WHERE p.sku = 'PANT-TUX-BLK-001';

-- Add Satin Pants - Black ($69.99)
INSERT INTO products (sku, name, description, category, base_price, status, visibility, featured, primary_image, created_at, updated_at)
VALUES 
('PANT-SAT-BLK-001', 'Black Satin Dress Pants - Slim', 'Luxurious black satin dress pants', 'Men''s Pants', 6999, 'active', true, false, NULL, NOW(), NOW());

-- Add satin pants variants
WITH pant_sizes AS (
  SELECT 
    waist::text || 'x' || length::text as size
  FROM 
    generate_series(28, 42, 2) as waist,
    generate_series(28, 36, 2) as length
  WHERE 
    (waist BETWEEN 28 AND 32 AND length BETWEEN 28 AND 32) OR
    (waist BETWEEN 32 AND 36 AND length BETWEEN 30 AND 34) OR
    (waist BETWEEN 36 AND 42 AND length BETWEEN 32 AND 36)
)
INSERT INTO product_variants (product_id, title, sku, price, option1, option2, inventory_quantity, created_at, updated_at)
SELECT 
  p.id,
  p.name || ' - ' || ps.size,
  p.sku || '-' || ps.size,
  6999,
  ps.size,
  'Slim Fit',
  15,
  NOW(),
  NOW()
FROM products p
CROSS JOIN pant_sizes ps
WHERE p.sku = 'PANT-SAT-BLK-001';

-- Add Tie Clips (2 colors at $15.00 each)
INSERT INTO products (sku, name, description, category, base_price, status, visibility, featured, primary_image, created_at, updated_at)
VALUES 
('CLIP-GLD-001', 'Gold Tie Clip', 'Premium gold-plated tie clip', 'Accessories', 1500, 'active', true, false, NULL, NOW(), NOW()),
('CLIP-SLV-001', 'Silver Tie Clip', 'Premium silver-plated tie clip', 'Accessories', 1500, 'active', true, false, NULL, NOW(), NOW());

-- Add tie clip variants (one size)
INSERT INTO product_variants (product_id, title, sku, price, option1, option2, inventory_quantity, created_at, updated_at)
SELECT 
  p.id,
  p.name,
  p.sku,
  1500,
  'One Size',
  NULL,
  75,
  NOW(),
  NOW()
FROM products p
WHERE p.sku IN ('CLIP-GLD-001', 'CLIP-SLV-001');

-- Add Cufflinks (2 colors at $39.99 each)
INSERT INTO products (sku, name, description, category, base_price, status, visibility, featured, primary_image, created_at, updated_at)
VALUES 
('CUFF-GLD-001', 'Gold Cufflinks', 'Premium gold-plated cufflinks', 'Accessories', 3999, 'active', true, false, NULL, NOW(), NOW()),
('CUFF-SLV-001', 'Silver Cufflinks', 'Premium silver-plated cufflinks', 'Accessories', 3999, 'active', true, false, NULL, NOW(), NOW());

-- Add cufflink variants (one size)
INSERT INTO product_variants (product_id, title, sku, price, option1, option2, inventory_quantity, created_at, updated_at)
SELECT 
  p.id,
  p.name,
  p.sku,
  3999,
  'One Size',
  NULL,
  60,
  NOW(),
  NOW()
FROM products p
WHERE p.sku IN ('CUFF-GLD-001', 'CUFF-SLV-001');

-- Summary of new products
SELECT 
  category,
  COUNT(DISTINCT p.id) as products,
  COUNT(pv.id) as variants,
  MIN(pv.price/100.0) as min_price,
  MAX(pv.price/100.0) as max_price
FROM products p
JOIN product_variants pv ON pv.product_id = p.id
WHERE p.created_at > NOW() - INTERVAL '1 hour'
GROUP BY category
ORDER BY category;

COMMIT;

-- Map these new products to Stripe prices (run after creating Stripe prices)
UPDATE product_variants pv
SET stripe_price_id = CASE
  WHEN pv.price = 1000 THEN 'YOUR_10_DOLLAR_PRICE_ID'  -- Socks
  WHEN pv.price = 1500 THEN 'YOUR_15_DOLLAR_PRICE_ID'  -- Tie clips
  WHEN pv.price = 2999 THEN 'YOUR_29_99_PRICE_ID'      -- Belts
  WHEN pv.price = 3999 THEN 'price_1RpvWnCHc12x7sCzzioA64qD' -- Cufflinks (use shirt price)
  WHEN pv.price = 5999 THEN 'YOUR_59_99_PRICE_ID'      -- Dress pants
  WHEN pv.price = 6999 THEN 'YOUR_69_99_PRICE_ID'      -- Premium pants
END,
stripe_active = true
FROM products p
WHERE p.id = pv.product_id
AND p.created_at > NOW() - INTERVAL '1 hour'
AND pv.stripe_price_id IS NULL;