-- SQL script to add performance indexes for better query speed
-- Run this in your Supabase SQL Editor

-- Products table indexes
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_products_category 
ON products(category);

CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_products_name_search 
ON products USING gin(to_tsvector('english', name));

CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_products_active 
ON products(active) WHERE active = true;

CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_products_category_active 
ON products(category, active) WHERE active = true;

CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_products_base_price 
ON products(base_price) WHERE active = true;

-- Product images indexes
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_product_images_product_id 
ON product_images(product_id);

CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_product_images_position 
ON product_images(product_id, position);

CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_product_images_type 
ON product_images(image_type);

-- Orders table indexes (if exists)
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_orders_user_id 
ON orders(user_id) WHERE EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'orders');

CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_orders_status 
ON orders(status) WHERE EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'orders');

CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_orders_created_at 
ON orders(created_at DESC) WHERE EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'orders');

-- User profiles indexes
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_user_profiles_email 
ON user_profiles(email) WHERE EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'user_profiles');

-- Show created indexes
SELECT 
  schemaname,
  tablename,
  indexname,
  indexdef
FROM pg_indexes 
WHERE schemaname = 'public' 
  AND indexname LIKE 'idx_%'
ORDER BY tablename, indexname;