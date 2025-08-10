-- SQL script to update all suspender & bowtie products to "Accessories" category
-- Run this in your Supabase SQL Editor

-- First, let's see what we're going to update
SELECT id, name, category 
FROM products 
WHERE (name ILIKE '%suspender%' OR name ILIKE '%bowtie%')
  AND category != 'Accessories'
ORDER BY name;

-- Update all suspender & bowtie products to Accessories category
UPDATE products 
SET 
  category = 'Accessories',
  updated_at = NOW()
WHERE (name ILIKE '%suspender%' OR name ILIKE '%bowtie%')
  AND category != 'Accessories';

-- Show the results after update
SELECT 
  name,
  category,
  CASE 
    WHEN category = 'Accessories' THEN '✅ Fixed'
    ELSE '❌ Still needs fixing'
  END as status
FROM products 
WHERE name ILIKE '%suspender%' OR name ILIKE '%bowtie%'
ORDER BY name;

-- Summary
SELECT 
  COUNT(*) as total_updated,
  'Accessories' as new_category
FROM products 
WHERE (name ILIKE '%suspender%' OR name ILIKE '%bowtie%')
  AND category = 'Accessories';