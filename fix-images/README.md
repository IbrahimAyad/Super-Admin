# 🖼️ Fix Product Images - Complete Solution

## The Problem
- Products are using old R2 bucket URL: `pub-8ea1de89-a731-488f-b407-5acfb4524ad7`
- Should be using new bucket: `pub-5cd73a21-13cf-48bd-8d3f-e0fdcbcb0db2`
- Some products have no images at all

## Quick Fix Steps

### Step 1: Analyze Current Situation
Run `analyze-images.sql` in Supabase SQL Editor to see:
- How many products have broken images
- Which buckets are being used
- Products without any images

### Step 2: Fix Database URLs
Run `FIX-ALL-IMAGES.sql` in Supabase SQL Editor to:
- Update all old bucket URLs to new bucket
- Fix both products and product_images tables
- Assign images from product_images table to products without primary_image

### Step 3: Implement Frontend Fallback
Use the provided components/utilities in your frontend:

#### Option A: Use the Image Component
```tsx
import { ProductImage } from '@/components/ProductImage';

<ProductImage 
  src={product.primary_image}
  alt={product.name}
  category={product.category}
/>
```

#### Option B: Use Utility Functions
```tsx
import { getProductImage } from '@/utils/image-utils';

const imageUrl = getProductImage(product.primary_image, product.category);
```

## R2 Bucket Information

### Current Buckets
1. **kct-base-products** - Original product images
2. **kct-new-website-products** - New imports
3. **suitshirttie** - Legacy bucket

### Bucket URLs
- Old (broken): `https://pub-8ea1de89-a731-488f-b407-5acfb4524ad7.r2.dev/`
- New (working): `https://pub-5cd73a21-13cf-48bd-8d3f-e0fdcbcb0db2.r2.dev/`

## Files in This Folder

1. **analyze-images.sql** - Check current image situation
2. **FIX-ALL-IMAGES.sql** - Fix all broken URLs in database
3. **frontend-image-component.tsx** - React component with fallback
4. **image-utils.ts** - Utility functions for image URLs
5. **README.md** - This file

## Implementation in Your Code

### In Product List/Grid
```tsx
import { getProductImage } from '@/utils/image-utils';

{products.map(product => (
  <img 
    src={getProductImage(product.primary_image, product.category)}
    alt={product.name}
    onError={(e) => {
      e.currentTarget.src = getFallbackImage(product.category);
    }}
  />
))}
```

### In Product Detail Page
```tsx
const productImage = getProductImage(product.primary_image, product.category);

<Image
  src={productImage}
  alt={product.name}
  width={600}
  height={800}
  priority
/>
```

## Testing

After implementing:
1. Check products that had broken images now display correctly
2. Check products without images show appropriate fallbacks
3. Test on both admin panel and customer-facing site

## Long-term Solution

Consider:
1. Upload actual placeholder images to R2 for each category
2. Re-import product images from original sources
3. Set up image optimization pipeline
4. Implement CDN for faster image delivery

## Emergency Fallback

If all else fails, use this generic placeholder:
```
https://via.placeholder.com/400x600/cccccc/666666?text=KCT+Menswear
```

---

Remember: **Customers can't buy what they can't see!** Fix images ASAP.