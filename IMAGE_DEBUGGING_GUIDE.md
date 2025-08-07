# Image Loading Debug Guide

## Quick Debug Steps

### 1. Enable Debugging Functions
In your browser console, first enable the debugging functions:

```javascript
// Import the service in your component or page first
import { enableImageDebugging } from '@/lib/services/products';

// Then call it (or add this to a useEffect)
enableImageDebugging();
```

### 2. Run Comprehensive Test
```javascript
await testImageLoading();
```

This will:
- Test database connection
- Show URLs stored in product_images table
- Test image URL generation for sample products
- Check storage bucket accessibility

### 3. Check Specific Issues

#### Check what URLs are in your database:
```javascript
await debugImageUrls(10); // Check first 10 images
```

#### Test URL generation for a specific product:
```javascript
// Get some products first
const products = await fetchProductsWithImages({ limit: 1 });
const product = products.data[0];

// Test URL generation (with debug output)
const url = getProductImageUrl(product, undefined, true);
console.log('Generated URL:', url);
```

## Common Issues & Solutions

### Issue 1: Storage Bucket Not Created
**Symptom**: Network requests to storage URLs return 404
**Solution**: Create the storage bucket in Supabase Dashboard:
1. Go to Storage > Buckets
2. Create bucket named `product-images`
3. Make it public
4. Set file size limit to 5MB

### Issue 2: Wrong URL Format in Database
**Symptom**: URLs in database don't match expected format
**Check**: Run `debugImageUrls()` to see what's stored
**Solution**: Update URLs in database:

```sql
-- Check current URLs
SELECT DISTINCT substring(url from 1 for 50) as url_preview, COUNT(*) 
FROM product_images 
GROUP BY url_preview;

-- Update to correct format if needed
UPDATE product_images 
SET url = 'path/to/correct/format' 
WHERE url LIKE 'old-pattern%';
```

### Issue 3: Images Field is `r2_url` not `url`
**Symptom**: getProductImageUrl returns placeholder despite having images
**Solution**: Already handled in updated function - checks both `url` and `r2_url` fields

### Issue 4: RLS Policies Block Access
**Symptom**: Database queries return empty results or permission errors
**Solution**: Check RLS policies allow anonymous read access:

```sql
-- Enable RLS
ALTER TABLE product_images ENABLE ROW LEVEL SECURITY;

-- Allow public read
CREATE POLICY "allow_read_product_images" ON product_images
FOR SELECT USING (true);
```

## Current Implementation Details

### URL Processing Logic:
1. **Absolute URLs**: `https://...` → returned as-is
2. **Relative paths**: `path/file.jpg` → `https://gvcswimqaxvylgxbklbz.supabase.co/storage/v1/object/public/product-images/path/file.jpg`
3. **Root paths**: `/path/file.jpg` → removes leading slash then processes

### Field Priority:
1. `product.primary_image`
2. `product.image_gallery[0]`
3. `product.images[0]` (if string array)
4. `product.images` (ProductImage array):
   - Primary image with `url` field
   - Primary image with `r2_url` field
   - First image with `url` field
   - First image with `r2_url` field
5. `/placeholder.svg` (fallback)

### Debug Mode:
- `getProductImageUrl(product, variant, true)` - shows detailed console logs
- `getProductImageUrl(product, variant, false)` - production mode, no logs