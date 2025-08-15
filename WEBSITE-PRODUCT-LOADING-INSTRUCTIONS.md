# 🛍️ Website Product Loading Instructions

## Current Status
✅ **270 out of 274 products** have working images
✅ All image URLs are now correctly mapped to existing R2 bucket files
✅ Database is properly configured with correct bucket URLs

## To Get Products Loading on Your Website

### 1. Verify Environment Variables
Make sure your website deployment has these environment variables:

```env
VITE_SUPABASE_URL=https://gvcswimqaxvylgxbklbz.supabase.co
VITE_SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imd2Y3N3aW1xYXh2eWxneGJrbGJ6Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTM3NjA1MzAsImV4cCI6MjA2OTMzNjUzMH0.UZdiGcJXUV5VYetjWXV26inmbj2yXdiT03Z6t_5Lg24
```

### 2. Update CORS on BOTH R2 Buckets

#### Bucket 1: kct-base-products
1. Go to Cloudflare R2 → `kct-base-products` bucket
2. Settings → CORS Policy
3. Add your website URL to allowed origins:
```json
{
  "AllowedOrigins": [
    "https://kct-menswear-ai-enhanced.vercel.app",
    "https://kctmenswear.com",
    "https://www.kctmenswear.com",
    "http://localhost:3000"
  ],
  "AllowedMethods": ["GET", "HEAD"],
  "AllowedHeaders": ["*"],
  "MaxAgeSeconds": 3600
}
```

#### Bucket 2: kct-new-website-products
Repeat the same CORS configuration for this bucket.

### 3. Website Code Requirements

Your website should fetch products like this:

```javascript
// Using Supabase client
const { data: products, error } = await supabase
  .from('products')
  .select('*')
  .eq('status', 'active')
  .order('name');

// Products will have primary_image URLs pointing to:
// - https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/ (organized folders)
// - https://pub-5cd8c531c0034986bf6282a223bd0564.r2.dev/ (batch folders)
```

### 4. Image Loading Best Practices

```jsx
// React component example
<img 
  src={product.primary_image}
  alt={product.name}
  loading="lazy"
  onError={(e) => {
    // Fallback to placeholder if image fails
    e.target.src = '/placeholder-product.png';
  }}
/>
```

### 5. Verify Product Data

Run this query in Supabase SQL editor to check your products:

```sql
-- Check product status
SELECT 
  COUNT(*) as total_products,
  COUNT(CASE WHEN primary_image IS NOT NULL THEN 1 END) as with_images,
  COUNT(CASE WHEN status = 'active' THEN 1 END) as active_products
FROM products;

-- Sample active products with images
SELECT name, primary_image, price, status
FROM products
WHERE status = 'active' 
  AND primary_image IS NOT NULL
LIMIT 10;
```

### 6. Common Issues & Solutions

| Issue | Solution |
|-------|----------|
| Images not loading | Check CORS settings on both R2 buckets |
| Products not showing | Verify products have `status = 'active'` |
| Wrong Supabase instance | Check VITE_SUPABASE_URL matches `gvcswimqaxvylgxbklbz` |
| Authentication errors | Use anon key for public website, not service role key |

### 7. Test Your Website

1. Open browser developer console (F12)
2. Go to Network tab
3. Load your website
4. Check for:
   - ✅ Successful requests to Supabase API
   - ✅ Images loading from R2 buckets
   - ❌ No CORS errors
   - ❌ No 404 errors on images

### 8. Products Missing Images

These 4 products still need images assigned:
- Men's Prom Burgundy Paisley Blazer with Matching Bowtie
- Men's Prom Gold Paisley Blazer with Matching Bowtie
- Men's Prom Royal Blue Blazer with Matching Bowtie
- Men's Velvet Purple Blazer with Matching Bowtie

You can either:
1. Upload images to R2 and update these products
2. Set them to `status = 'inactive'` to hide them
3. Assign placeholder images

## Summary

Your product database is ready! Just ensure:
1. ✅ Environment variables are set correctly
2. ✅ CORS is configured on both R2 buckets
3. ✅ Website code fetches from correct Supabase instance
4. ✅ Products are set to 'active' status

The website should now load all 270 products with working images!