-- =====================================================
-- SETUP 20-TIER PRICING SYSTEM & STRIPE INTEGRATION
-- =====================================================

-- STEP 1: CREATE PRICE TIERS TABLE (IF NOT EXISTS)
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS price_tiers (
  tier_id VARCHAR(50) PRIMARY KEY,
  tier_number INTEGER UNIQUE NOT NULL CHECK (tier_number BETWEEN 1 AND 20),
  min_price INTEGER NOT NULL,
  max_price INTEGER,
  display_range VARCHAR(50) NOT NULL,
  tier_name VARCHAR(50) NOT NULL,
  tier_label VARCHAR(100),
  description TEXT,
  color_code VARCHAR(7),
  icon VARCHAR(50),
  marketing_message TEXT,
  typical_occasions TEXT[],
  target_audience TEXT,
  positioning VARCHAR(50),
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- STEP 2: INSERT 20-TIER PRICING CONFIGURATION
-- -----------------------------------------------------
INSERT INTO price_tiers (tier_id, tier_number, min_price, max_price, display_range, tier_name, tier_label, description, color_code, icon, marketing_message, typical_occasions, target_audience, positioning) VALUES
-- Entry Level Tiers (1-5)
('tier_1_essential', 1, 0, 9900, '$0-$99', 'Essential', 'Essential Collection', 'Entry-level basics for everyday wear', '#9CA3AF', 'tag', 'Affordable style for everyone', ARRAY['casual', 'daily_wear'], 'Budget-conscious shoppers', 'value'),
('tier_2_starter', 2, 10000, 14900, '$100-$149', 'Starter', 'Starter Collection', 'Quality basics for building a wardrobe', '#6B7280', 'shopping-bag', 'Start your style journey', ARRAY['work', 'casual'], 'Young professionals', 'entry'),
('tier_3_everyday', 3, 15000, 19900, '$150-$199', 'Everyday', 'Everyday Essentials', 'Versatile pieces for daily rotation', '#4B5563', 'calendar', 'Your daily style companion', ARRAY['work', 'social'], 'Regular customers', 'standard'),
('tier_4_smart', 4, 20000, 24900, '$200-$249', 'Smart', 'Smart Selection', 'Polished looks for work and weekends', '#374151', 'briefcase', 'Smart choices for smart people', ARRAY['business_casual', 'dinner'], 'Career-focused individuals', 'standard_plus'),
('tier_5_classic', 5, 25000, 29900, '$250-$299', 'Classic', 'Classic Range', 'Timeless pieces that never go out of style', '#1F2937', 'award', 'Timeless elegance', ARRAY['business', 'formal_events'], 'Style-conscious professionals', 'mid_range'),

-- Mid-Range Tiers (6-10)
('tier_6_refined', 6, 30000, 34900, '$300-$349', 'Refined', 'Refined Collection', 'Elevated style with attention to detail', '#991B1B', 'star', 'Refined taste, refined style', ARRAY['cocktail', 'business'], 'Established professionals', 'premium_entry'),
('tier_7_premium', 7, 35000, 39900, '$350-$399', 'Premium', 'Premium Line', 'Superior quality and sophisticated design', '#7C2D12', 'gem', 'Premium quality, lasting value', ARRAY['wedding_guest', 'galas'], 'Discerning customers', 'premium'),
('tier_8_distinguished', 8, 40000, 44900, '$400-$449', 'Distinguished', 'Distinguished Series', 'For those who appreciate fine craftsmanship', '#78350F', 'crown', 'Distinguished by design', ARRAY['special_occasions', 'corporate'], 'Affluent professionals', 'premium_plus'),
('tier_9_prestige', 9, 45000, 49900, '$450-$499', 'Prestige', 'Prestige Collection', 'Prestigious pieces for important moments', '#713F12', 'diamond', 'Where prestige meets style', ARRAY['black_tie_optional', 'ceremonies'], 'High achievers', 'upper_premium'),
('tier_10_exclusive', 10, 50000, 59900, '$500-$599', 'Exclusive', 'Exclusive Range', 'Limited availability, exceptional quality', '#581C87', 'lock', 'Exclusively yours', ARRAY['vip_events', 'premieres'], 'Exclusive clientele', 'luxury_entry'),

-- Luxury Tiers (11-15)
('tier_11_signature', 11, 60000, 69900, '$600-$699', 'Signature', 'Signature Collection', 'Our signature style statements', '#6B21A8', 'pen', 'Make your signature statement', ARRAY['red_carpet', 'galas'], 'Fashion enthusiasts', 'luxury'),
('tier_12_elite', 12, 70000, 79900, '$700-$799', 'Elite', 'Elite Series', 'For the elite few who demand the best', '#7C3AED', 'shield', 'Elite style, elite status', ARRAY['charity_galas', 'premieres'], 'Elite professionals', 'luxury_plus'),
('tier_13_luxe', 13, 80000, 89900, '$800-$899', 'Luxe', 'Luxe Collection', 'Luxurious fabrics and impeccable tailoring', '#8B5CF6', 'sparkles', 'Luxury redefined', ARRAY['black_tie', 'yacht_parties'], 'Luxury consumers', 'high_luxury'),
('tier_14_opulent', 14, 90000, 99900, '$900-$999', 'Opulent', 'Opulent Line', 'Opulent designs for extraordinary occasions', '#A78BFA', 'flame', 'Opulence in every detail', ARRAY['state_dinners', 'royal_events'], 'Ultra-affluent', 'ultra_luxury'),
('tier_15_imperial', 15, 100000, 119900, '$1000-$1199', 'Imperial', 'Imperial Collection', 'Imperial quality for those who rule their world', '#C4B5FD', 'castle', 'Imperial elegance', ARRAY['diplomatic_events', 'exclusive_gatherings'], 'Global elite', 'super_luxury'),

-- Ultra-Luxury Tiers (16-20)
('tier_16_majestic', 16, 120000, 139900, '$1200-$1399', 'Majestic', 'Majestic Series', 'Majestic pieces for momentous occasions', '#DDD6FE', 'crown-2', 'Majestically crafted', ARRAY['royal_weddings', 'state_occasions'], 'Royalty adjacent', 'ultra_premium'),
('tier_17_sovereign', 17, 140000, 159900, '$1400-$1599', 'Sovereign', 'Sovereign Collection', 'Sovereign style for sovereign individuals', '#EDE9FE', 'throne', 'Sovereign sophistication', ARRAY['coronations', 'nobel_ceremonies'], 'Sovereign wealth', 'extreme_luxury'),
('tier_18_regal', 18, 160000, 179900, '$1600-$1799', 'Regal', 'Regal Line', 'Regal bearing, regal wearing', '#F3F4F6', 'scepter', 'Regally yours', ARRAY['royal_investitures', 'palace_events'], 'Royal circles', 'royal_tier'),
('tier_19_pinnacle', 19, 180000, 199900, '$1800-$1999', 'Pinnacle', 'Pinnacle Collection', 'The pinnacle of fashion excellence', '#F9FAFB', 'mountain', 'The pinnacle of perfection', ARRAY['once_in_lifetime', 'historic_events'], 'Pinnacle achievers', 'pinnacle'),
('tier_20_bespoke', 20, 200000, NULL, '$2000+', 'Bespoke', 'Bespoke Atelier', 'Custom-made perfection, no limits', '#FFFFFF', 'infinity', 'Beyond luxury, truly bespoke', ARRAY['custom_events', 'personal_milestones'], 'Bespoke clientele', 'bespoke')
ON CONFLICT (tier_id) DO NOTHING;

-- STEP 3: ADD STRIPE FIELDS TO PRODUCTS_ENHANCED (IF NOT EXISTS)
-- -----------------------------------------------------
ALTER TABLE products_enhanced 
ADD COLUMN IF NOT EXISTS stripe_product_id VARCHAR(255),
ADD COLUMN IF NOT EXISTS stripe_price_id VARCHAR(255),
ADD COLUMN IF NOT EXISTS stripe_active BOOLEAN DEFAULT false,
ADD COLUMN IF NOT EXISTS stripe_metadata JSONB DEFAULT '{}'::jsonb;

-- Create indexes for Stripe fields
CREATE INDEX IF NOT EXISTS idx_products_stripe_product ON products_enhanced(stripe_product_id) WHERE stripe_product_id IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_products_stripe_price ON products_enhanced(stripe_price_id) WHERE stripe_price_id IS NOT NULL;

-- STEP 4: CREATE STRIPE SYNC TRACKING TABLE
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS stripe_sync_log (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  product_id UUID REFERENCES products_enhanced(id),
  action VARCHAR(50) NOT NULL, -- 'create', 'update', 'delete', 'sync'
  stripe_product_id VARCHAR(255),
  stripe_price_id VARCHAR(255),
  status VARCHAR(20) NOT NULL, -- 'success', 'failed', 'pending'
  error_message TEXT,
  metadata JSONB DEFAULT '{}'::jsonb,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- STEP 5: CREATE FUNCTION TO ASSIGN PRICE TIERS
-- -----------------------------------------------------
CREATE OR REPLACE FUNCTION assign_price_tier(price_cents INTEGER)
RETURNS VARCHAR(50) AS $$
BEGIN
  RETURN (
    SELECT tier_id 
    FROM price_tiers 
    WHERE price_cents >= min_price 
      AND (max_price IS NULL OR price_cents <= max_price)
    ORDER BY tier_number DESC
    LIMIT 1
  );
END;
$$ LANGUAGE plpgsql;

-- STEP 6: UPDATE EXISTING PRODUCTS WITH PRICE TIERS
-- -----------------------------------------------------
UPDATE products_enhanced 
SET price_tier = assign_price_tier(base_price)
WHERE price_tier IS NULL OR price_tier = '';

-- STEP 7: CREATE TRIGGER TO AUTO-ASSIGN PRICE TIERS
-- -----------------------------------------------------
CREATE OR REPLACE FUNCTION update_price_tier()
RETURNS TRIGGER AS $$
BEGIN
  IF NEW.base_price IS NOT NULL THEN
    NEW.price_tier = assign_price_tier(NEW.base_price);
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS auto_assign_price_tier ON products_enhanced;
CREATE TRIGGER auto_assign_price_tier
BEFORE INSERT OR UPDATE OF base_price ON products_enhanced
FOR EACH ROW
EXECUTE FUNCTION update_price_tier();

-- STEP 8: CREATE VIEW FOR TIER ANALYTICS
-- -----------------------------------------------------
CREATE OR REPLACE VIEW product_tier_analytics AS
SELECT 
  pt.tier_name,
  pt.tier_number,
  pt.display_range,
  pt.color_code,
  COUNT(pe.id) as product_count,
  AVG(pe.base_price) as avg_price,
  MIN(pe.base_price) as min_price,
  MAX(pe.base_price) as max_price,
  SUM(pe.view_count) as total_views,
  SUM(pe.purchase_count) as total_purchases,
  AVG(pe.return_rate) as avg_return_rate
FROM price_tiers pt
LEFT JOIN products_enhanced pe ON pe.price_tier = pt.tier_id
GROUP BY pt.tier_id, pt.tier_name, pt.tier_number, pt.display_range, pt.color_code
ORDER BY pt.tier_number;

-- STEP 9: CREATE FUNCTION FOR STRIPE PRODUCT CREATION
-- -----------------------------------------------------
CREATE OR REPLACE FUNCTION prepare_stripe_product_data(product_id UUID)
RETURNS JSONB AS $$
DECLARE
  product_data JSONB;
BEGIN
  SELECT jsonb_build_object(
    'name', name,
    'description', description,
    'metadata', jsonb_build_object(
      'product_id', id::text,
      'sku', sku,
      'category', category,
      'price_tier', price_tier,
      'collection', collection,
      'season', season
    ),
    'images', CASE 
      WHEN images->'hero'->>'url' IS NOT NULL 
      THEN ARRAY[images->'hero'->>'url']
      ELSE '{}'::text[]
    END,
    'active', stripe_active,
    'default_price_data', jsonb_build_object(
      'currency', 'usd',
      'unit_amount', base_price,
      'product', stripe_product_id
    )
  ) INTO product_data
  FROM products_enhanced
  WHERE id = product_id;
  
  RETURN product_data;
END;
$$ LANGUAGE plpgsql;

-- STEP 10: GRANT PERMISSIONS
-- -----------------------------------------------------
GRANT ALL ON price_tiers TO authenticated, anon;
GRANT ALL ON stripe_sync_log TO authenticated;
GRANT SELECT ON product_tier_analytics TO authenticated, anon;

-- VERIFICATION QUERIES
-- -----------------------------------------------------
-- Check price tiers are loaded
SELECT tier_number, tier_name, display_range, positioning FROM price_tiers ORDER BY tier_number;

-- Check products have tiers assigned
SELECT 
  COUNT(*) as total_products,
  COUNT(price_tier) as products_with_tiers,
  COUNT(stripe_product_id) as products_in_stripe
FROM products_enhanced;

-- View tier distribution
SELECT * FROM product_tier_analytics;

-- Check if triggers are active
SELECT 
  trigger_name,
  event_manipulation,
  event_object_table
FROM information_schema.triggers
WHERE trigger_name = 'auto_assign_price_tier';