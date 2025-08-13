# Fix Cloudflare R2 CORS Errors

## Problem
Images from Cloudflare R2 are being blocked due to CORS (Cross-Origin Resource Sharing) policy.

## Solution

### 1. Add CORS Rules to Your R2 Bucket

Go to Cloudflare Dashboard → R2 → Your Bucket → Settings → CORS

Add this CORS configuration:

```json
[
  {
    "AllowedOrigins": [
      "https://super-admin-ruby.vercel.app",
      "https://localhost:3000",
      "http://localhost:3000",
      "https://localhost:8080",
      "http://localhost:8080",
      "https://kctmenswear.com",
      "https://www.kctmenswear.com"
    ],
    "AllowedMethods": [
      "GET",
      "HEAD"
    ],
    "AllowedHeaders": [
      "*"
    ],
    "ExposeHeaders": [
      "ETag"
    ],
    "MaxAgeSeconds": 3600
  }
]
```

### 2. Alternative: Make Bucket Public

If the images don't contain sensitive data:

1. Go to R2 → Your Bucket → Settings
2. Under "Public Access", enable "Allow public access"
3. Update your domain settings

### 3. Update Image URLs in Database

For the 404 errors (missing images), you need to either:

**Option A: Upload Missing Images**
Upload the missing tuxedo images to your R2 bucket:
- mens_black_tuxedo_model_2001.webp
- mens_tuxedo_model_2002.webp
- etc.

**Option B: Update Database with Placeholder**
```sql
-- Update products with missing images to use a placeholder
UPDATE product_images 
SET image_url = 'https://via.placeholder.com/400x600/ccc/666?text=Image+Coming+Soon'
WHERE image_url LIKE '%404%' 
   OR image_url LIKE '%mens_tuxedo_model%'
   OR image_url LIKE '%emerlad-green-model%';
```

### 4. Fix Image Upload Path

Ensure new uploads go to the correct path:

```javascript
// In your image upload code
const uploadPath = `products/${productId}/${filename}`;
// Not just the filename alone
```

## Quick Fixes Applied

1. **Database tables created** - metrics, logs, refund_requests
2. **Functions fixed** - get_recent_orders now handles missing data
3. **RLS policies added** - proper permissions for new tables

## Action Items

1. ✅ Run the SQL script in Supabase
2. ⚠️ Configure CORS in Cloudflare R2
3. ⚠️ Upload missing product images or use placeholders
4. ✅ Verify admin panel loads without errors