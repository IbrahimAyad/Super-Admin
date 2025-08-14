# R2 Bucket Architecture Documentation

## Current Bucket Setup

You currently have **3 different R2 buckets** for images:

### 1. **kct-base-products** (142.74 MB, 381 objects)
- **Purpose**: Original product images from when the Supabase project started
- **Domain**: `pub-5cd8c531c0034986bf6282a223bd0564.r2.dev`
- **Status**: Active, working correctly

### 2. **kct-new-website-products** (170.11 MB, 596 objects)
- **Purpose**: Latest product imports (suits, tuxedos, blazers, vests)
- **Domain**: `pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev`
- **Status**: Active, but had URL issues (now fixed)

### 3. **suitshirttie** (221.72 MB, 518 objects)
- **Purpose**: Core images sent directly to the website
- **Domain**: Unknown (needs to be checked)
- **Status**: Active, main website images

## Is This a Problem?

### Short Answer: **It's manageable but not ideal**

### Issues:
1. **Complexity**: Managing 3 different buckets increases complexity
2. **URL Management**: Different products reference different buckets
3. **CORS Configuration**: Each bucket needs separate CORS setup
4. **Maintenance**: Triple the configuration and monitoring

### Benefits:
1. **Separation of Concerns**: Different buckets for different purposes
2. **Easier Migration**: Can migrate one bucket at a time
3. **Risk Isolation**: Issues in one bucket don't affect others

## Recommended Solution

### Option 1: Keep Current Setup (Quick Fix) ✅
```sql
-- Update all product images to use correct buckets
UPDATE products 
SET primary_image = REPLACE(
  primary_image, 
  'pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev',  -- Wrong bucket
  'pub-5cd8c531c0034986bf6282a223bd0564.r2.dev'   -- Correct bucket
)
WHERE primary_image LIKE '%pub-8ea%';
```

### Option 2: Consolidate to One Bucket (Long-term)
1. Choose `suitshirttie` as the main bucket (largest, most used)
2. Migrate all images to this single bucket
3. Update all database references
4. Benefits:
   - Single CORS configuration
   - Simplified URL management
   - Easier CDN setup
   - Single point of management

## Frontend Handling

The website should implement a smart fallback system:

```typescript
// Image URL resolver
function getImageUrl(imageUrl: string | null): string {
  if (!imageUrl) return '/default-product.jpg';
  
  // Map of bucket replacements
  const bucketMap = {
    'pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev': 'pub-5cd8c531c0034986bf6282a223bd0564.r2.dev',
    // Add other mappings as needed
  };
  
  // Replace any wrong bucket URLs
  let fixedUrl = imageUrl;
  for (const [wrong, correct] of Object.entries(bucketMap)) {
    fixedUrl = fixedUrl.replace(wrong, correct);
  }
  
  return fixedUrl;
}
```

## Database Image References

Current state in database:
- **kct-base-products**: Used by original products
- **kct-new-website-products**: Used by recent imports
- **suitshirttie**: Should be used for website display

## Action Items

### Immediate (Today):
1. ✅ Fix wrong bucket URLs in database (run the SQL above)
2. ✅ Ensure CORS is configured on all buckets
3. ✅ Update frontend to handle multiple buckets

### Short-term (This Week):
1. Audit all image references in database
2. Create a migration plan to consolidate buckets
3. Test image loading across all products

### Long-term (Next Month):
1. Consolidate to single bucket
2. Implement CDN (CloudFlare) for all images
3. Set up image optimization pipeline

## Current Image Distribution

```
Total Images: ~1,495 objects
Total Size: ~534.57 MB

By Bucket:
- kct-base-products: 381 images (25%)
- kct-new-website-products: 596 images (40%)
- suitshirttie: 518 images (35%)
```

## CORS Configuration Required

Each bucket needs this CORS configuration:

```json
[
  {
    "AllowedOrigins": [
      "http://localhost:3000",
      "http://localhost:5173",
      "https://your-website.com",
      "https://your-admin.vercel.app"
    ],
    "AllowedMethods": ["GET", "HEAD"],
    "AllowedHeaders": ["*"],
    "ExposeHeaders": ["ETag"],
    "MaxAgeSeconds": 3600
  }
]
```

## Summary

The multiple bucket setup is **not critical** but should be consolidated for better management. The immediate fix is to:
1. Update wrong URLs in the database
2. Ensure all buckets have proper CORS
3. Implement smart URL handling in frontend

This will make everything work while you plan the consolidation.