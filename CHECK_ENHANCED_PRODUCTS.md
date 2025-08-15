# How to Check Enhanced Products in Admin

## Option 1: Direct Database View (FASTEST)
1. Go to **Supabase Dashboard**
2. Click **Table Editor** in left sidebar
3. Select **products_enhanced** table
4. You'll see all 3 products with their data

## Option 2: SQL Query Check
Run this in Supabase SQL Editor:
```sql
-- View all enhanced products with details
SELECT 
  name,
  sku,
  category || '/' || COALESCE(subcategory, '') as category_path,
  price_tier,
  '$' || (base_price / 100.0) as price,
  images->>'total_images' as total_images,
  status
FROM products_enhanced
ORDER BY created_at DESC;

-- Check specific product images
SELECT 
  name,
  jsonb_pretty(images) as image_structure
FROM products_enhanced;
```

## Option 3: Use Admin UI (If Connected)

### If your admin is at localhost:3000 or deployed:
1. Navigate to `/admin/enhanced-products`
2. You should see the Enhanced Products page

### To add the route to your admin:
1. Copy the `enhanced-products.tsx` file to your admin pages folder
2. Add a menu item linking to `/admin/enhanced-products`
3. The page will show:
   - Product count stats
   - Table with all products
   - Image gallery preview
   - Price tier information

## Option 4: Quick API Test
If you have the API running, test with:
```javascript
// In browser console or API client
fetch('/api/products/enhanced')
  .then(res => res.json())
  .then(data => console.log(data));
```

## What You Should See:

### 3 Products:
1. **Premium Velvet Blazer - Midnight Navy** (Test product)
   - 4 images (hero, flat, 1 lifestyle, 1 detail)
   - TIER_8 ($349.99)

2. **Men's Black Paisley Pattern Velvet Blazer**
   - 1 image (hero only)
   - TIER_8 ($349.99)
   - Real CDN image

3. **Men's Blue Casual Summer Blazer**
   - 5 images (hero, 2 lifestyle, 2 details)
   - TIER_6 ($229.99)
   - All real CDN images

## Visual Check in Browser:
The CDN images should load from:
- `https://cdn.kctmenswear.com/blazers/velvet/...`
- `https://cdn.kctmenswear.com/blazers/summer/...`

## If Images Don't Load:
- Check CORS settings on R2 bucket
- Verify files exist in bucket at correct paths
- Check browser console for errors
- Try accessing image URL directly in browser