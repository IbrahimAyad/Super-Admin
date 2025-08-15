# Cloudflare R2 Storage Architecture

## Overview

KCT Menswear uses **TWO separate Cloudflare R2 buckets** for image storage with different organizational structures. This dual-bucket architecture was created to separate organized product categories from batch-imported products.

## 🪣 Bucket Architecture

### Bucket 1: kct-base-products
- **URL**: `https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/`
- **Purpose**: Organized product categories with logical folder structure
- **Products**: 137 products use this bucket
- **File Format**: Primarily PNG images
- **Organization**: Category-based folders

**Folder Structure**:
```
kct-base-products/
├── double_breasted/          # Double breasted suits
├── main-solid-vest-tie/      # Vest and tie sets
├── velvet-blazer/            # Velvet blazers
├── prom_blazer/              # Prom blazers  
├── main-suspender-bowtie-set/ # Suspender sets
├── dress_shirts/             # Dress shirts
├── sparkle-blazer/           # Sparkle blazers
├── summer-blazer/            # Summer blazers
├── suits/                    # Regular suits
└── tuxedos/                  # Tuxedos
```

### Bucket 2: kct-new-website-products  
- **URL**: `https://pub-5cd8c531c0034986bf6282a223bd0564.r2.dev/`
- **Purpose**: Batch-imported products from CSV uploads
- **Products**: 91 products use this bucket
- **File Format**: Primarily WebP images
- **Organization**: Batch-based folders

**Folder Structure**:
```
kct-new-website-products/
├── batch_1/                  # Main batch folder (MOST USED)
│   ├── batch_2/             # Sub-batch 2
│   ├── batch_3/             # Sub-batch 3
│   └── batch_4/             # Sub-batch 4
├── tie_clean_batch_01/       # Rarely used
├── tie_clean_batch_02/       # Rarely used  
├── tie_clean_batch_03/       # Rarely used
└── tie_clean_batch_04/       # Rarely used
```

### Bucket 3: Legacy (DEPRECATED)
- **URL**: `https://pub-5cd73a21-13cf-48bd-8d3f-e0fdcbcb0db2.r2.dev/`
- **Status**: DEPRECATED - being phased out
- **Products**: Some legacy products still reference this
- **Action**: Migrate remaining products to appropriate bucket

## 🔗 URL Mapping Rules

### Rule 1: Organized Categories → Bucket 1
```
IF image_path contains:
  - /double_breasted/
  - /main-solid-vest-tie/
  - /velvet-blazer/
  - /prom_blazer/
  - /main-suspender-bowtie-set/
  - /dress_shirts/
  - /sparkle-blazer/
  - /summer-blazer/
  - /suits/
  - /tuxedos/

THEN use: https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/[path]
```

### Rule 2: Batch Imports → Bucket 2
```
IF image_path contains:
  - /batch_1/
  - /batch_1/batch_2/
  - /batch_1/batch_3/
  - /batch_1/batch_4/
  - /tie_clean_batch_*/

THEN use: https://pub-5cd8c531c0034986bf6282a223bd0564.r2.dev/[path]
```

## 📊 Current Usage Statistics

### Bucket 1 (kct-base-products)
- **Active Products**: 137
- **Average File Size**: 200KB - 500KB
- **Total Storage**: ~50-70GB
- **File Types**: PNG (primary), some JPG
- **Performance**: Fast CDN delivery

### Bucket 2 (kct-new-website-products)  
- **Active Products**: 91
- **Average File Size**: 150KB - 300KB
- **Total Storage**: ~30-40GB
- **File Types**: WebP (primary), optimized for web
- **Performance**: Fast CDN delivery

### Legacy Bucket (DEPRECATED)
- **Active Products**: <10 (being migrated)
- **Status**: Phase out in progress

## 🚨 Current Issues

### 1. URL Mapping Chaos ❌
**Problem**: Many products have incorrect bucket URLs
- Products with `/batch_1/` paths using Bucket 1 URL (wrong)
- Results in 404 errors and broken images
- 183 products showing placeholder images

**Impact**: 
- 67% of products have broken image URLs
- Customer experience degraded
- Admin panel shows placeholder images

### 2. Mixed Database References ❌
**Problem**: Database contains URLs from all three buckets
```sql
-- Current distribution in database:
✅ Bucket 1 (correct): 137 products 
❌ Bucket 2 (mixed): 91 products (some wrong URLs)
❌ Legacy (should be 0): ~46 products still referencing old bucket
```

### 3. Upload Configuration Issues ❌
**Problem**: Admin panel upload system confusion
- Upload attempts go to Supabase storage (not R2)
- No automatic bucket selection logic
- Manual URL updates required

## 🔧 CORS Configuration

Both buckets require CORS configuration for admin panel access:

```json
// Required CORS for both buckets
{
  "AllowedOrigins": [
    "https://*.vercel.app",
    "https://kct-super-admin.vercel.app",
    "http://localhost:*",
    "https://localhost:*"
  ],
  "AllowedMethods": ["GET", "POST", "PUT", "DELETE", "HEAD"],
  "AllowedHeaders": ["*"],
  "ExposedHeaders": ["ETag"],
  "MaxAgeSeconds": 3600
}
```

## 🛠️ Image Management Workflow

### Current Workflow (BROKEN)
1. Admin uploads image via admin panel ❌
2. Upload attempts to go to Supabase storage ❌  
3. URL generation fails ❌
4. Manual URL entry required ❌
5. Bucket selection guesswork ❌

### Proposed Fixed Workflow  
1. Admin uploads image via admin panel ✅
2. System detects product category ✅
3. Auto-selects appropriate R2 bucket ✅
4. Uploads directly to correct bucket ✅
5. Updates database with correct URL ✅

## 📋 Database Schema Integration

### Products Table Integration
```sql
products:
  primary_image TEXT -- Full URL to R2 bucket
  image_gallery JSONB -- Array of R2 URLs
```

### Product Images Table Integration  
```sql
product_images:
  image_url TEXT -- Full URL to R2 bucket
  image_type TEXT -- 'primary', 'gallery', 'thumbnail', 'detail'
  position INTEGER -- Sort order
```

## 🔍 Image URL Validation

### Valid URL Patterns
```regex
// Bucket 1 URLs (organized categories)
^https://pub-8ea0502158a94b8ca8a7abb9e18a57e8\.r2\.dev/(double_breasted|main-solid-vest-tie|velvet-blazer|prom_blazer|main-suspender-bowtie-set|dress_shirts|sparkle-blazer|summer-blazer|suits|tuxedos)/.*\.(png|jpg|webp)$

// Bucket 2 URLs (batch imports)  
^https://pub-5cd8c531c0034986bf6282a223bd0564\.r2\.dev/(batch_1|tie_clean_batch_\d+)/.*\.(png|jpg|webp)$
```

### Invalid URL Patterns (Need Fixing)
```regex
// Wrong bucket for batch images
^https://pub-8ea0502158a94b8ca8a7abb9e18a57e8\.r2\.dev/batch_1/.*

// Legacy bucket URLs  
^https://pub-5cd73a21-13cf-48bd-8d3f-e0fdcbcb0db2\.r2\.dev/.*

// Placeholder images
^.*placeholder.*\.(png|jpg|webp)$
```

## 🎯 Immediate Fix Required

### Priority 1: Fix Batch Image URLs
```sql
-- Fix batch images pointing to wrong bucket
UPDATE products 
SET primary_image = REPLACE(
  primary_image,
  'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/batch_1/',
  'https://pub-5cd8c531c0034986bf6282a223bd0564.r2.dev/batch_1/'
)
WHERE primary_image LIKE '%pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/batch_1/%';

UPDATE product_images 
SET image_url = REPLACE(
  image_url,
  'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/batch_1/',
  'https://pub-5cd8c531c0034986bf6282a223bd0564.r2.dev/batch_1/'
)
WHERE image_url LIKE '%pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/batch_1/%';
```

### Priority 2: Migrate Legacy URLs
```sql
-- Identify products still using legacy bucket
SELECT id, name, primary_image 
FROM products 
WHERE primary_image LIKE '%pub-5cd73a21-13cf-48bd-8d3f-e0fdcbcb0db2%';
```

### Priority 3: Validate All URLs
```sql
-- Check for placeholder images that could be replaced
SELECT id, name, primary_image
FROM products 
WHERE primary_image LIKE '%placeholder%'
   OR primary_image IS NULL;
```

## 🚀 Future Enhancements

### Automatic Bucket Selection
- Implement logic to auto-select bucket based on product category
- Category mapping: velvet blazers → organized folder → Bucket 1
- Import source: CSV batch → batch folder → Bucket 2

### Image Optimization Pipeline
- Automatic WebP conversion for new uploads
- Image resizing for thumbnails and galleries
- CDN cache optimization

### Admin Panel Integration
- Visual bucket indicator in admin panel
- One-click bucket migration for incorrect URLs
- Bulk image validation and fixing tools

---

**Last Updated**: August 14, 2025  
**Status**: Critical fixes required for image URL mapping  
**Next Review**: After bucket URL fixes are applied