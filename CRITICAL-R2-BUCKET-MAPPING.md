# 🚨 CRITICAL: R2 Bucket Mapping Rules

## THE PROBLEM WE'RE FIXING
We incorrectly changed ALL product images to use one bucket URL, but KCT uses TWO different R2 buckets for different types of products.

## CORRECT BUCKET MAPPING

### Bucket 1: kct-base-products 
**URL:** `https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/`
**Contains:** Organized product folders
```
✅ USE THIS FOR:
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
```

### Bucket 2: kct-new-website-products
**URL:** `https://pub-5cd8c531c0034986bf6282a223bd0564.r2.dev/`
**Contains:** Batch import folders
```
✅ USE THIS FOR:
- /batch_1/*
- /batch_1/batch_2/*
- /batch_1/batch_3/*
- /batch_1/batch_4/*
- /tie_clean_batch_01/* (rarely used)
- /tie_clean_batch_02/* (rarely used)
- /tie_clean_batch_03/* (rarely used)
- /tie_clean_batch_04/* (rarely used)
```

## THE FIX WE'RE IMPLEMENTING

1. **KEEP AS IS** - Products with organized folders stay with Bucket 1
   - Example: `https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/double_breasted/black-model.png` ✅

2. **NEED TO FIX** - Products with batch folders must use Bucket 2
   - Wrong: `https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/batch_1/image.webp` ❌
   - Right: `https://pub-5cd8c531c0034986bf6282a223bd0564.r2.dev/batch_1/image.webp` ✅

## IMPORTANT NOTES
- Both buckets are active and serving images
- CORS must be configured on BOTH buckets
- Never mix bucket URLs - each product must use the correct bucket based on its folder path
- The batch folders primarily use webp format images
- The organized folders primarily use png format images

## Last Updated: 2025-08-14
This is the definitive guide for R2 bucket mapping. DO NOT change all products to use a single bucket!