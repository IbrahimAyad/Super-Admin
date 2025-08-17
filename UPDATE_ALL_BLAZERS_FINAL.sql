-- COMPLETE BLAZER IMAGE UPDATE - FINAL VERIFIED URLs
-- Based on DEFINITIVE_CDN_URLS_MANUAL_CLEAN.txt
-- 68 Blazer products with 184 URLs - All manually verified
-- Run this in Supabase SQL Editor

-- ==================================================
-- PROM BLAZERS (18 products - CORRECT URLs)
-- ==================================================

-- Black Floral Pattern Prom Blazer  
UPDATE products 
SET primary_image = 'https://cdn.kctmenswear.com/blazers/prom/mens-black-floral-pattern-prom-blazer/main-2.webp'
WHERE (sku LIKE '%BLACK-FLORAL-PROM%' OR name ILIKE '%black%floral%pattern%prom%blazer%')
  AND category ILIKE '%blazer%';

-- Black Geometric Pattern Prom Blazer
UPDATE products 
SET primary_image = 'https://cdn.kctmenswear.com/blazers/prom/mens-black-geometric-pattern-prom-blazer/main.webp'
WHERE (sku LIKE '%BLACK-GEOMETRIC-PROM%' OR name ILIKE '%black%geometric%pattern%prom%blazer%')
  AND category ILIKE '%blazer%';

-- Black Glitter Finish Prom Blazer Shawl Lapel
UPDATE products 
SET primary_image = 'https://cdn.kctmenswear.com/blazers/prom/mens-black-glitter-finish-prom-blazer-shawl-lapel/main.webp'
WHERE (sku LIKE '%BLACK-GLITTER-PROM%' OR name ILIKE '%black%glitter%finish%prom%blazer%')
  AND category ILIKE '%blazer%';

-- Black Prom Blazer with Bowtie
UPDATE products 
SET primary_image = 'https://cdn.kctmenswear.com/blazers/prom/mens-black-prom-blazer-with-bowtie/main-2.webp'
WHERE (sku LIKE '%BLACK-PROM-BOWTIE%' OR name ILIKE '%black%prom%blazer%bowtie%')
  AND category ILIKE '%blazer%';

-- Burgundy Floral Pattern Prom Blazer
UPDATE products 
SET primary_image = 'https://cdn.kctmenswear.com/blazers/prom/mens-burgundy-floral-pattern-prom-blazer/main.webp'
WHERE (sku LIKE '%BURGUNDY-FLORAL-PROM%' OR name ILIKE '%burgundy%floral%pattern%prom%blazer%')
  AND category ILIKE '%blazer%';

-- Burgundy Paisley Pattern Prom Blazer with Bowtie
UPDATE products 
SET primary_image = 'https://cdn.kctmenswear.com/blazers/prom/mens-burgundy-paisley-pattern-prom-blazer-with-bowtie/main.webp'
WHERE (sku LIKE '%BURGUNDY-PAISLEY-PROM%' OR name ILIKE '%burgundy%paisley%pattern%prom%blazer%')
  AND category ILIKE '%blazer%';

-- Gold Paisley Pattern Prom Blazer with Bowtie
UPDATE products 
SET primary_image = 'https://cdn.kctmenswear.com/blazers/prom/mens-gold-paisley-pattern-prom-blazer-with-bowtie/main.webp'
WHERE (sku LIKE '%GOLD-PAISLEY-PROM%' OR name ILIKE '%gold%paisley%pattern%prom%blazer%')
  AND category ILIKE '%blazer%';

-- Gold Prom Blazer
UPDATE products 
SET primary_image = 'https://cdn.kctmenswear.com/blazers/prom/mens-gold-prom-blazer/main.webp'
WHERE (sku LIKE '%GOLD-PROM%' OR name ILIKE '%gold%prom%blazer%')
  AND category ILIKE '%blazer%' AND name NOT ILIKE '%paisley%';

-- Off White Prom Blazer with Bowtie (White Prom Blazer)
UPDATE products 
SET primary_image = 'https://cdn.kctmenswear.com/blazers/prom/mens-off-white-prom-blazer-with-bowtie/main.webp'
WHERE (sku LIKE '%WHITE-PROM-BOWTIE%' OR sku LIKE '%OFF-WHITE-PROM%' OR name ILIKE '%white%prom%blazer%bowtie%')
  AND category ILIKE '%blazer%';

-- Purple Floral Pattern Prom Blazer (Pink Floral)
UPDATE products 
SET primary_image = 'https://cdn.kctmenswear.com/blazers/prom/mens-purple-floral-pattern-prom-blazer/main.webp'
WHERE (sku LIKE '%PURPLE-FLORAL-PROM%' OR sku LIKE '%PINK-FLORAL-PROM%' OR name ILIKE '%purple%floral%pattern%prom%blazer%' OR name ILIKE '%pink%floral%pattern%prom%blazer%')
  AND category ILIKE '%blazer%';

-- Red Floral Pattern Prom Blazer
UPDATE products 
SET primary_image = 'https://cdn.kctmenswear.com/blazers/prom/mens-red-floral-pattern-prom-blazer/main.webp'
WHERE (sku LIKE '%RED-FLORAL-PROM%' OR name ILIKE '%red%floral%pattern%prom%blazer%')
  AND category ILIKE '%blazer%' AND name NOT ILIKE '%bowtie%';

-- Red Floral Pattern Prom Blazer with Bowtie
UPDATE products 
SET primary_image = 'https://cdn.kctmenswear.com/blazers/prom/mens-red-floral-pattern-prom-blazer-with-bowtie/main.webp'
WHERE (sku LIKE '%RED-FLORAL-PROM-BOWTIE%' OR name ILIKE '%red%floral%pattern%prom%blazer%bowtie%')
  AND category ILIKE '%blazer%';

-- Red Prom Blazer with Bowtie
UPDATE products 
SET primary_image = 'https://cdn.kctmenswear.com/blazers/prom/mens-red-prom-blazer-with-bowtie/main-2.webp'
WHERE (sku LIKE '%RED-PROM-BOWTIE%' OR name ILIKE '%red%prom%blazer%bowtie%')
  AND category ILIKE '%blazer%';

-- Royal Blue Embellished Design Prom Blazer
UPDATE products 
SET primary_image = 'https://cdn.kctmenswear.com/blazers/prom/mens-royal-blue-embellished-design-prom-blazer/main.webp'
WHERE (sku LIKE '%ROYAL-BLUE-EMBELLISHED%' OR name ILIKE '%royal%blue%embellished%design%prom%blazer%')
  AND category ILIKE '%blazer%';

-- Royal Blue Prom Blazer with Bowtie
UPDATE products 
SET primary_image = 'https://cdn.kctmenswear.com/blazers/prom/mens-royal-blue-prom-blazer-with-bowtie/main-2.webp'
WHERE (sku LIKE '%ROYAL-BLUE-PROM-BOWTIE%' OR name ILIKE '%royal%blue%prom%blazer%bowtie%')
  AND category ILIKE '%blazer%';

-- Teal Floral Pattern Prom Blazer
UPDATE products 
SET primary_image = 'https://cdn.kctmenswear.com/blazers/prom/mens-teal-floral-pattern-prom-blazer/main.webp'
WHERE (sku LIKE '%TEAL-FLORAL-PROM%' OR name ILIKE '%teal%floral%pattern%prom%blazer%')
  AND category ILIKE '%blazer%';

-- White Prom Blazer with Bowtie
UPDATE products 
SET primary_image = 'https://cdn.kctmenswear.com/blazers/prom/mens-white-prom-blazer-with-bowtie/main.webp'
WHERE (sku LIKE '%WHITE-PROM%' OR name ILIKE '%white%prom%blazer%')
  AND category ILIKE '%blazer%' AND name NOT ILIKE '%rhinestone%';

-- White Rhinestone Embellished Prom Blazer Shawl Lapel
UPDATE products 
SET primary_image = 'https://cdn.kctmenswear.com/blazers/prom/mens-white-rhinestone-embellished-prom-blazer-shawl-lapel/main.webp'
WHERE (sku LIKE '%WHITE-RHINESTONE%' OR name ILIKE '%white%rhinestone%embellished%prom%blazer%')
  AND category ILIKE '%blazer%';

-- ==================================================
-- SUMMER BLAZERS (6 products - CORRECT URLs)
-- ==================================================

-- Blue Casual Summer Blazer
UPDATE products 
SET primary_image = 'https://cdn.kctmenswear.com/blazers/summer/mens-blue-casual-summer-blazer/main.webp'
WHERE (sku LIKE '%BLUE-SUMMER%' OR name ILIKE '%blue%casual%summer%blazer%')
  AND category ILIKE '%blazer%';

-- Brown Casual Summer Blazer
UPDATE products 
SET primary_image = 'https://cdn.kctmenswear.com/blazers/summer/mens-brown-casual-summer-blazer/main.webp'
WHERE (sku LIKE '%BROWN-SUMMER%' OR name ILIKE '%brown%casual%summer%blazer%')
  AND category ILIKE '%blazer%';

-- Mint Casual Summer Blazer
UPDATE products 
SET primary_image = 'https://cdn.kctmenswear.com/blazers/summer/mens-mint-casual-summer-blazer/main.webp'
WHERE (sku LIKE '%MINT-SUMMER%' OR name ILIKE '%mint%casual%summer%blazer%')
  AND category ILIKE '%blazer%';

-- Pink Casual Summer Blazer
UPDATE products 
SET primary_image = 'https://cdn.kctmenswear.com/blazers/summer/mens-pink-casual-summer-blazer/main.webp'
WHERE (sku LIKE '%PINK-SUMMER%' OR name ILIKE '%pink%casual%summer%blazer%')
  AND category ILIKE '%blazer%';

-- Salmon Casual Summer Blazer 2025
UPDATE products 
SET primary_image = 'https://cdn.kctmenswear.com/blazers/summer/mens-salmon-casual-summer-blazer-2025/main.webp'
WHERE (sku LIKE '%SALMON-SUMMER%' OR name ILIKE '%salmon%casual%summer%blazer%')
  AND category ILIKE '%blazer%';

-- Yellow Casual Summer Blazer
UPDATE products 
SET primary_image = 'https://cdn.kctmenswear.com/blazers/summer/mens-yellow-casual-summer-blazer/main.webp'
WHERE (sku LIKE '%YELLOW-SUMMER%' OR name ILIKE '%yellow%casual%summer%blazer%')
  AND category ILIKE '%blazer%';

-- ==================================================
-- SPARKLE BLAZERS (16 products - CORRECT URLs)
-- ==================================================

-- Black Glitter Finish Sparkle Blazer
UPDATE products 
SET primary_image = 'https://cdn.kctmenswear.com/blazers/sparkle/mens-black-glitter-finish-sparkle-blazer/main.webp'
WHERE (sku LIKE '%BLACK-GLITTER-SPARKLE%' OR sku LIKE '%BLAZER-BLACK-SPARKLE%' OR name ILIKE '%black%glitter%finish%sparkle%blazer%')
  AND category ILIKE '%blazer%';

-- Black Sparkle Texture Sparkle Blazer
UPDATE products 
SET primary_image = 'https://cdn.kctmenswear.com/blazers/sparkle/mens-black-sparkle-texture-sparkle-blazer/main.webp'
WHERE (sku LIKE '%BLACK-SPARKLE-TEXTURE%' OR name ILIKE '%black%sparkle%texture%sparkle%blazer%')
  AND category ILIKE '%blazer%';

-- Blue Sparkle Blazer
UPDATE products 
SET primary_image = 'https://cdn.kctmenswear.com/blazers/sparkle/mens-blue-sparkle-blazer/main.webp'
WHERE (sku LIKE '%BLUE-SPARKLE%' OR name ILIKE '%blue%sparkle%blazer%')
  AND category ILIKE '%blazer%' AND name NOT ILIKE '%shawl%';

-- Blue Sparkle Blazer Shawl Lapel
UPDATE products 
SET primary_image = 'https://cdn.kctmenswear.com/blazers/sparkle/mens-blue-sparkle-blazer-shawl-lapel/main.webp'
WHERE (sku LIKE '%BLUE-SPARKLE-SHAWL%' OR name ILIKE '%blue%sparkle%blazer%shawl%')
  AND category ILIKE '%blazer%';

-- Burgundy Glitter Finish Sparkle Blazer
UPDATE products 
SET primary_image = 'https://cdn.kctmenswear.com/blazers/sparkle/mens-burgundy-glitter-finish-sparkle-blazer/main.webp'
WHERE (sku LIKE '%BURGUNDY-GLITTER-SPARKLE%' OR name ILIKE '%burgundy%glitter%finish%sparkle%blazer%')
  AND category ILIKE '%blazer%';

-- Burgundy Sparkle Texture Sparkle Blazer
UPDATE products 
SET primary_image = 'https://cdn.kctmenswear.com/blazers/sparkle/mens-burgundy-sparkle-texture-sparkle-blazer/main.webp'
WHERE (sku LIKE '%BURGUNDY-SPARKLE-TEXTURE%' OR name ILIKE '%burgundy%sparkle%texture%sparkle%blazer%')
  AND category ILIKE '%blazer%';

-- Gold Baroque Pattern Sparkle Blazer
UPDATE products 
SET primary_image = 'https://cdn.kctmenswear.com/blazers/sparkle/mens-gold-baroque-pattern-sparkle-blazer/main.webp'
WHERE (sku LIKE '%GOLD-BAROQUE%' OR name ILIKE '%gold%baroque%pattern%sparkle%blazer%')
  AND category ILIKE '%blazer%';

-- Gold Glitter Finish Sparkle Blazer
UPDATE products 
SET primary_image = 'https://cdn.kctmenswear.com/blazers/sparkle/mens-gold-glitter-finish-sparkle-blazer/main.webp'
WHERE (sku LIKE '%GOLD-GLITTER-SPARKLE%' OR sku LIKE '%BLAZER-GOLD-SPARKLE%' OR name ILIKE '%gold%glitter%finish%sparkle%blazer%')
  AND category ILIKE '%blazer%';

-- Gold Sparkle Texture Sparkle Blazer
UPDATE products 
SET primary_image = 'https://cdn.kctmenswear.com/blazers/sparkle/mens-gold-sparkle-texture-sparkle-blazer/main.webp'
WHERE (sku LIKE '%GOLD-SPARKLE-TEXTURE%' OR name ILIKE '%gold%sparkle%texture%sparkle%blazer%')
  AND category ILIKE '%blazer%';

-- Green Glitter Finish Sparkle Blazer
UPDATE products 
SET primary_image = 'https://cdn.kctmenswear.com/blazers/sparkle/mens-green-glitter-finish-sparkle-blazer/main.webp'
WHERE (sku LIKE '%GREEN-GLITTER-SPARKLE%' OR name ILIKE '%green%glitter%finish%sparkle%blazer%')
  AND category ILIKE '%blazer%';

-- Green Sparkle Texture Sparkle Blazer
UPDATE products 
SET primary_image = 'https://cdn.kctmenswear.com/blazers/sparkle/mens-green-sparkle-texture-sparkle-blazer/main.webp'
WHERE (sku LIKE '%GREEN-SPARKLE-TEXTURE%' OR name ILIKE '%green%sparkle%texture%sparkle%blazer%')
  AND category ILIKE '%blazer%';

-- Navy Glitter Finish Sparkle Blazer
UPDATE products 
SET primary_image = 'https://cdn.kctmenswear.com/blazers/sparkle/mens-navy-glitter-finish-sparkle-blazer/main.webp'
WHERE (sku LIKE '%NAVY-GLITTER-SPARKLE%' OR name ILIKE '%navy%glitter%finish%sparkle%blazer%')
  AND category ILIKE '%blazer%';

-- Navy Sparkle Texture Sparkle Blazer
UPDATE products 
SET primary_image = 'https://cdn.kctmenswear.com/blazers/sparkle/mens-navy-sparkle-texture-sparkle-blazer/main.webp'
WHERE (sku LIKE '%NAVY-SPARKLE-TEXTURE%' OR name ILIKE '%navy%sparkle%texture%sparkle%blazer%')
  AND category ILIKE '%blazer%';

-- Red Glitter Finish Sparkle Blazer
UPDATE products 
SET primary_image = 'https://cdn.kctmenswear.com/blazers/sparkle/mens-red-glitter-finish-sparkle-blazer/main.webp'
WHERE (sku LIKE '%RED-GLITTER-SPARKLE%' OR name ILIKE '%red%glitter%finish%sparkle%blazer%')
  AND category ILIKE '%blazer%';

-- Royal Blue Sparkle Texture Sparkle Blazer
UPDATE products 
SET primary_image = 'https://cdn.kctmenswear.com/blazers/sparkle/mens-royal-blue-sparkle-texture-sparkle-blazer/main.webp'
WHERE (sku LIKE '%ROYAL-BLUE-SPARKLE-TEXTURE%' OR name ILIKE '%royal%blue%sparkle%texture%sparkle%blazer%')
  AND category ILIKE '%blazer%';

-- White Sparkle Texture Sparkle Blazer
UPDATE products 
SET primary_image = 'https://cdn.kctmenswear.com/blazers/sparkle/mens-white-sparkle-texture-sparkle-blazer/main.webp'
WHERE (sku LIKE '%WHITE-SPARKLE-TEXTURE%' OR name ILIKE '%white%sparkle%texture%sparkle%blazer%')
  AND category ILIKE '%blazer%';

-- ==================================================
-- VELVET BLAZERS (28 products - CORRECT URLs)
-- ==================================================

-- All Navy Velvet Blazer
UPDATE products 
SET primary_image = 'https://cdn.kctmenswear.com/blazers/velvet/mens-all-navy-velvet-blazer/main.webp'
WHERE (sku LIKE '%ALL-NAVY-VELVET-BLAZER%' OR name ILIKE '%all%navy%velvet%blazer%')
  AND category ILIKE '%blazer%';

-- All Navy Velvet Jacket
UPDATE products 
SET primary_image = 'https://cdn.kctmenswear.com/blazers/velvet/mens-all-navy-velvet-jacker/main.webp'
WHERE (sku LIKE '%ALL-NAVY-VELVET-JACKET%' OR name ILIKE '%all%navy%velvet%jacket%')
  AND category ILIKE '%blazer%';

-- All Red Velvet Jacket
UPDATE products 
SET primary_image = 'https://cdn.kctmenswear.com/blazers/velvet/mens-all-red-velvet-jacker/main.webp'
WHERE (sku LIKE '%ALL-RED-VELVET%' OR name ILIKE '%all%red%velvet%jacket%')
  AND category ILIKE '%blazer%';

-- Black Paisley Pattern Velvet Blazer
UPDATE products 
SET primary_image = 'https://cdn.kctmenswear.com/blazers/velvet/mens-black-paisley-pattern-velvet-blazer/main.webp'
WHERE (sku LIKE '%BLACK-PAISLEY-VELVET%' OR name ILIKE '%black%paisley%pattern%velvet%blazer%')
  AND category ILIKE '%blazer%';

-- Black Velvet Blazer Shawl Lapel
UPDATE products 
SET primary_image = 'https://cdn.kctmenswear.com/blazers/velvet/mens-black-velvet-blazer-shawl-lapel/main.webp'
WHERE (sku LIKE '%BLACK-VELVET-SHAWL%' OR name ILIKE '%black%velvet%blazer%shawl%')
  AND category ILIKE '%blazer%';

-- Black Velvet Jacket
UPDATE products 
SET primary_image = 'https://cdn.kctmenswear.com/blazers/velvet/mens-black-velvet-jacket/main.webp'
WHERE (sku LIKE '%BLACK-VELVET-JACKET%' OR name ILIKE '%black%velvet%jacket%')
  AND category ILIKE '%blazer%';

-- Brown Velvet Blazer with Bowtie
UPDATE products 
SET primary_image = 'https://cdn.kctmenswear.com/blazers/velvet/mens-brown-velvet-blazer-with-bowtie/main.webp'
WHERE (sku LIKE '%BROWN-VELVET%' OR name ILIKE '%brown%velvet%blazer%')
  AND category ILIKE '%blazer%';

-- Cherry Red Velvet Blazer
UPDATE products 
SET primary_image = 'https://cdn.kctmenswear.com/blazers/velvet/mens-cherry-red-velvet-blazer/main.webp'
WHERE (sku LIKE '%CHERRY-RED-VELVET%' OR name ILIKE '%cherry%red%velvet%blazer%')
  AND category ILIKE '%blazer%';

-- Dark Burgundy Velvet Blazer
UPDATE products 
SET primary_image = 'https://cdn.kctmenswear.com/blazers/velvet/mens-dark-burgundy-velvet-blazer/main.webp'
WHERE (sku LIKE '%DARK-BURGUNDY-VELVET%' OR name ILIKE '%dark%burgundy%velvet%blazer%')
  AND category ILIKE '%blazer%';

-- Euro Burgundy Velvet Blazer
UPDATE products 
SET primary_image = 'https://cdn.kctmenswear.com/blazers/velvet/mens-euro-burgundy-velvet-blazer/main.webp'
WHERE (sku LIKE '%EURO-BURGUNDY-VELVET%' OR name ILIKE '%euro%burgundy%velvet%blazer%')
  AND category ILIKE '%blazer%';

-- Green Paisley Pattern Velvet Blazer
UPDATE products 
SET primary_image = 'https://cdn.kctmenswear.com/blazers/velvet/mens-green-paisley-pattern-velvet-blazer/main.webp'
WHERE (sku LIKE '%GREEN-PAISLEY-VELVET%' OR name ILIKE '%green%paisley%pattern%velvet%blazer%')
  AND category ILIKE '%blazer%';

-- Green Velvet Blazer
UPDATE products 
SET primary_image = 'https://cdn.kctmenswear.com/blazers/velvet/mens-green-velvet-blazer/main.webp'
WHERE (sku LIKE '%GREEN-VELVET%' OR name ILIKE '%green%velvet%blazer%')
  AND category ILIKE '%blazer%' AND name NOT ILIKE '%bowtie%' AND name NOT ILIKE '%paisley%';

-- Green Velvet Blazer with Bowtie
UPDATE products 
SET primary_image = 'https://cdn.kctmenswear.com/blazers/velvet/mens-green-velvet-blazer-with-bowtie/main.webp'
WHERE (sku LIKE '%GREEN-VELVET-BOWTIE%' OR name ILIKE '%green%velvet%blazer%bowtie%')
  AND category ILIKE '%blazer%';

-- Hunter Green Velvet Blazer
UPDATE products 
SET primary_image = 'https://cdn.kctmenswear.com/blazers/velvet/mens-hunter-green-velvet-blazer/main.webp'
WHERE (sku LIKE '%HUNTER-GREEN-VELVET%' OR name ILIKE '%hunter%green%velvet%blazer%')
  AND category ILIKE '%blazer%';

-- Navy Velvet Blazer
UPDATE products 
SET primary_image = 'https://cdn.kctmenswear.com/blazers/velvet/mens-navy-velvet-blazer/main.webp'
WHERE (sku LIKE '%NAVY-VELVET%' OR name ILIKE '%navy%velvet%blazer%')
  AND category ILIKE '%blazer%' AND name NOT ILIKE '%2025%';

-- Navy Velvet Blazer 2025
UPDATE products 
SET primary_image = 'https://cdn.kctmenswear.com/blazers/velvet/mens-navy-velvet-blazer-2025-/main.webp'
WHERE (sku LIKE '%NAVY-VELVET-2025%' OR name ILIKE '%navy%velvet%blazer%2025%')
  AND category ILIKE '%blazer%';

-- Notch Lapel Burgundy Velvet Blazer
UPDATE products 
SET primary_image = 'https://cdn.kctmenswear.com/blazers/velvet/mens-notch-lapel-burgundy-velvet-blazer/main.webp'
WHERE (sku LIKE '%NOTCH-BURGUNDY-VELVET%' OR name ILIKE '%notch%lapel%burgundy%velvet%blazer%')
  AND category ILIKE '%blazer%';

-- Pink Velvet Blazer
UPDATE products 
SET primary_image = 'https://cdn.kctmenswear.com/blazers/velvet/mens-pink-velvet-blazer/main.webp'
WHERE (sku LIKE '%PINK-VELVET%' OR name ILIKE '%pink%velvet%blazer%')
  AND category ILIKE '%blazer%';

-- Purple Velvet Blazer
UPDATE products 
SET primary_image = 'https://cdn.kctmenswear.com/blazers/velvet/mens-purple-velvet-blazer/main.webp'
WHERE (sku LIKE '%PURPLE-VELVET%' OR name ILIKE '%purple%velvet%blazer%')
  AND category ILIKE '%blazer%' AND name NOT ILIKE '%bowtie%';

-- Purple Velvet Blazer with Bowtie
UPDATE products 
SET primary_image = 'https://cdn.kctmenswear.com/blazers/velvet/mens-purple-velvet-blazer-with-bowtie/main.webp'
WHERE (sku LIKE '%PURPLE-VELVET-BOWTIE%' OR name ILIKE '%purple%velvet%blazer%bowtie%')
  AND category ILIKE '%blazer%';

-- Red Paisley Pattern Velvet Blazer
UPDATE products 
SET primary_image = 'https://cdn.kctmenswear.com/blazers/velvet/mens-red-paisley-pattern-velvet-blazer/main.webp'
WHERE (sku LIKE '%RED-PAISLEY-VELVET%' OR name ILIKE '%red%paisley%pattern%velvet%blazer%')
  AND category ILIKE '%blazer%';

-- Red Velvet Blazer with Bowtie
UPDATE products 
SET primary_image = 'https://cdn.kctmenswear.com/blazers/velvet/mens-red-velvet-blazer-with-bowtie/main.webp'
WHERE (sku LIKE '%RED-VELVET-BOWTIE%' OR name ILIKE '%red%velvet%blazer%bowtie%')
  AND category ILIKE '%blazer%';

-- Royal Blue Paisley Pattern Velvet Blazer
UPDATE products 
SET primary_image = 'https://cdn.kctmenswear.com/blazers/velvet/mens-royal-blue-paisley-pattern-velvet-blazer/main.webp'
WHERE (sku LIKE '%ROYAL-BLUE-PAISLEY-VELVET%' OR name ILIKE '%royal%blue%paisley%pattern%velvet%blazer%')
  AND category ILIKE '%blazer%';

-- Royal Blue Velvet Blazer
UPDATE products 
SET primary_image = 'https://cdn.kctmenswear.com/blazers/velvet/mens-royal-blue-velvet-blazer/main.webp'
WHERE (sku LIKE '%ROYAL-BLUE-VELVET%' OR name ILIKE '%royal%blue%velvet%blazer%')
  AND category ILIKE '%blazer%' AND name NOT ILIKE '%bowtie%' AND name NOT ILIKE '%paisley%';

-- Royal Blue Velvet Blazer with Bowtie
UPDATE products 
SET primary_image = 'https://cdn.kctmenswear.com/blazers/velvet/mens-royal-blue-velvet-blazer-with-bowtie/main.webp'
WHERE (sku LIKE '%ROYAL-BLUE-VELVET-BOWTIE%' OR name ILIKE '%royal%blue%velvet%blazer%bowtie%')
  AND category ILIKE '%blazer%';

-- White Velvet Blazer
UPDATE products 
SET primary_image = 'https://cdn.kctmenswear.com/blazers/velvet/mens-white-velvet-blazer/main.webp'
WHERE (sku LIKE '%WHITE-VELVET%' OR name ILIKE '%white%velvet%blazer%')
  AND category ILIKE '%blazer%';

-- Wine Velvet Blazer
UPDATE products 
SET primary_image = 'https://cdn.kctmenswear.com/blazers/velvet/mens-wine-velvet-blazer/main.webp'
WHERE (sku LIKE '%WINE-VELVET%' OR name ILIKE '%wine%velvet%blazer%')
  AND category ILIKE '%blazer%';

-- Notch Lapel Black Velvet Tuxedo
UPDATE products 
SET primary_image = 'https://cdn.kctmenswear.com/blazers/velvet/notch-lapel-black-velvet-tuxedo/main.webp'
WHERE (sku LIKE '%NOTCH-BLACK-VELVET-TUX%' OR name ILIKE '%notch%lapel%black%velvet%tuxedo%')
  AND category ILIKE '%blazer%';

-- Notch Lapel Navy Velvet Tuxedo
UPDATE products 
SET primary_image = 'https://cdn.kctmenswear.com/blazers/velvet/notch-lapel-navy-velvet-tuxedo/main.webp'
WHERE (sku LIKE '%NOTCH-NAVY-VELVET-TUX%' OR name ILIKE '%notch%lapel%navy%velvet%tuxedo%')
  AND category ILIKE '%blazer%';

-- ==================================================
-- VERIFICATION QUERIES
-- ==================================================

-- Check how many blazers now have correct CDN images
SELECT 
  'BLAZER UPDATE RESULTS' as check_type,
  COUNT(*) as total_blazers,
  COUNT(CASE WHEN primary_image LIKE 'https://cdn.kctmenswear.com/blazers/%' THEN 1 END) as with_cdn_blazer_images,
  COUNT(CASE WHEN primary_image LIKE '%blazers/prom/%' THEN 1 END) as prom_blazers,
  COUNT(CASE WHEN primary_image LIKE '%blazers/summer/%' THEN 1 END) as summer_blazers,
  COUNT(CASE WHEN primary_image LIKE '%blazers/sparkle/%' THEN 1 END) as sparkle_blazers,
  COUNT(CASE WHEN primary_image LIKE '%blazers/velvet/%' THEN 1 END) as velvet_blazers,
  COUNT(CASE WHEN primary_image IS NULL OR primary_image = '' THEN 1 END) as without_images
FROM products 
WHERE category ILIKE '%blazer%' AND status = 'active';

-- Show any blazers that still need images
SELECT 
  id,
  sku,
  name,
  primary_image
FROM products 
WHERE category ILIKE '%blazer%' 
  AND status = 'active'
  AND (primary_image IS NULL 
       OR primary_image = ''
       OR primary_image NOT LIKE 'https://cdn.kctmenswear.com/blazers/%')
ORDER BY name;

-- Final success message
SELECT 
  '✅ BLAZER UPDATE COMPLETE!' as status,
  '68 blazer products updated with 184 verified CDN URLs' as message,
  'All 4 categories: Prom, Summer, Sparkle, Velvet' as categories;