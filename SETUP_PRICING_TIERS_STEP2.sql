-- =====================================================
-- STEP 2: INSERT PRICING TIERS DATA
-- Run this after Step 1 succeeds
-- =====================================================

-- Clear existing tiers if any
TRUNCATE TABLE price_tiers;

-- Insert all 20 tiers
INSERT INTO price_tiers (tier_id, tier_number, min_price, max_price, display_range, tier_name, tier_label, description, color_code, icon, marketing_message, typical_occasions, target_audience, positioning) VALUES
('tier_1_essential', 1, 0, 9900, '$0-$99', 'Essential', 'Essential Collection', 'Entry-level basics for everyday wear', '#9CA3AF', 'tag', 'Affordable style for everyone', ARRAY['casual', 'daily_wear'], 'Budget-conscious shoppers', 'value'),
('tier_2_starter', 2, 10000, 14900, '$100-$149', 'Starter', 'Starter Collection', 'Quality basics for building a wardrobe', '#6B7280', 'shopping-bag', 'Start your style journey', ARRAY['work', 'casual'], 'Young professionals', 'entry'),
('tier_3_everyday', 3, 15000, 19900, '$150-$199', 'Everyday', 'Everyday Essentials', 'Versatile pieces for daily rotation', '#4B5563', 'calendar', 'Your daily style companion', ARRAY['work', 'social'], 'Regular customers', 'standard'),
('tier_4_smart', 4, 20000, 24900, '$200-$249', 'Smart', 'Smart Selection', 'Polished looks for work and weekends', '#374151', 'briefcase', 'Smart choices for smart people', ARRAY['business_casual', 'dinner'], 'Career-focused individuals', 'standard_plus'),
('tier_5_classic', 5, 25000, 29900, '$250-$299', 'Classic', 'Classic Range', 'Timeless pieces that never go out of style', '#1F2937', 'award', 'Timeless elegance', ARRAY['business', 'formal_events'], 'Style-conscious professionals', 'mid_range'),
('tier_6_refined', 6, 30000, 34900, '$300-$349', 'Refined', 'Refined Collection', 'Elevated style with attention to detail', '#991B1B', 'star', 'Refined taste, refined style', ARRAY['cocktail', 'business'], 'Established professionals', 'premium_entry'),
('tier_7_premium', 7, 35000, 39900, '$350-$399', 'Premium', 'Premium Line', 'Superior quality and sophisticated design', '#7C2D12', 'gem', 'Premium quality, lasting value', ARRAY['wedding_guest', 'galas'], 'Discerning customers', 'premium'),
('tier_8_distinguished', 8, 40000, 44900, '$400-$449', 'Distinguished', 'Distinguished Series', 'For those who appreciate fine craftsmanship', '#78350F', 'crown', 'Distinguished by design', ARRAY['special_occasions', 'corporate'], 'Affluent professionals', 'premium_plus'),
('tier_9_prestige', 9, 45000, 49900, '$450-$499', 'Prestige', 'Prestige Collection', 'Prestigious pieces for important moments', '#713F12', 'diamond', 'Where prestige meets style', ARRAY['black_tie_optional', 'ceremonies'], 'High achievers', 'upper_premium'),
('tier_10_exclusive', 10, 50000, 59900, '$500-$599', 'Exclusive', 'Exclusive Range', 'Limited availability, exceptional quality', '#581C87', 'lock', 'Exclusively yours', ARRAY['vip_events', 'premieres'], 'Exclusive clientele', 'luxury_entry');

-- Insert remaining tiers (11-20)
INSERT INTO price_tiers (tier_id, tier_number, min_price, max_price, display_range, tier_name, tier_label, description, color_code, icon, marketing_message, typical_occasions, target_audience, positioning) VALUES
('tier_11_signature', 11, 60000, 69900, '$600-$699', 'Signature', 'Signature Collection', 'Our signature style statements', '#6B21A8', 'pen', 'Make your signature statement', ARRAY['red_carpet', 'galas'], 'Fashion enthusiasts', 'luxury'),
('tier_12_elite', 12, 70000, 79900, '$700-$799', 'Elite', 'Elite Series', 'For the elite few who demand the best', '#7C3AED', 'shield', 'Elite style, elite status', ARRAY['charity_galas', 'premieres'], 'Elite professionals', 'luxury_plus'),
('tier_13_luxe', 13, 80000, 89900, '$800-$899', 'Luxe', 'Luxe Collection', 'Luxurious fabrics and impeccable tailoring', '#8B5CF6', 'sparkles', 'Luxury redefined', ARRAY['black_tie', 'yacht_parties'], 'Luxury consumers', 'high_luxury'),
('tier_14_opulent', 14, 90000, 99900, '$900-$999', 'Opulent', 'Opulent Line', 'Opulent designs for extraordinary occasions', '#A78BFA', 'flame', 'Opulence in every detail', ARRAY['state_dinners', 'royal_events'], 'Ultra-affluent', 'ultra_luxury'),
('tier_15_imperial', 15, 100000, 119900, '$1000-$1199', 'Imperial', 'Imperial Collection', 'Imperial quality for those who rule their world', '#C4B5FD', 'castle', 'Imperial elegance', ARRAY['diplomatic_events', 'exclusive_gatherings'], 'Global elite', 'super_luxury'),
('tier_16_majestic', 16, 120000, 139900, '$1200-$1399', 'Majestic', 'Majestic Series', 'Majestic pieces for momentous occasions', '#DDD6FE', 'crown-2', 'Majestically crafted', ARRAY['royal_weddings', 'state_occasions'], 'Royalty adjacent', 'ultra_premium'),
('tier_17_sovereign', 17, 140000, 159900, '$1400-$1599', 'Sovereign', 'Sovereign Collection', 'Sovereign style for sovereign individuals', '#EDE9FE', 'throne', 'Sovereign sophistication', ARRAY['coronations', 'nobel_ceremonies'], 'Sovereign wealth', 'extreme_luxury'),
('tier_18_regal', 18, 160000, 179900, '$1600-$1799', 'Regal', 'Regal Line', 'Regal bearing, regal wearing', '#F3F4F6', 'scepter', 'Regally yours', ARRAY['royal_investitures', 'palace_events'], 'Royal circles', 'royal_tier'),
('tier_19_pinnacle', 19, 180000, 199900, '$1800-$1999', 'Pinnacle', 'Pinnacle Collection', 'The pinnacle of fashion excellence', '#F9FAFB', 'mountain', 'The pinnacle of perfection', ARRAY['once_in_lifetime', 'historic_events'], 'Pinnacle achievers', 'pinnacle'),
('tier_20_bespoke', 20, 200000, NULL, '$2000+', 'Bespoke', 'Bespoke Atelier', 'Custom-made perfection, no limits', '#FFFFFF', 'infinity', 'Beyond luxury, truly bespoke', ARRAY['custom_events', 'personal_milestones'], 'Bespoke clientele', 'bespoke');

-- Verify all tiers inserted
SELECT COUNT(*) as tier_count, 'Tiers inserted successfully' as status FROM price_tiers;