# R2 Bucket Structure Documentation

## Two Separate R2 Buckets

### Bucket 1: kct-base-products
**URL:** `https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/`

**Organized Folders:**
- `double_breasted/` - Double breasted suits
- `main-solid-vest-tie/` - Vests and ties
- `velvet-blazer/` - Velvet blazers
- `prom_blazer/` - Prom blazers
- `main-suspender-bowtie-set/` - Suspender and bowtie sets
- `dress_shirts/` - Dress shirts
- `sparkle-blazer/` - Sparkle blazers
- `summer-blazer/` - Summer blazers
- `suits/` - Regular suits
- `tuxedos/` - Tuxedos

### Bucket 2: kct-new-website-products
**URL:** `https://pub-5cd8c531c0034986bf6282a223bd0564.r2.dev/`

**Batch Folders (Main ones we use):**
- `batch_1/` - Main batch folder
  - `batch_1/batch_2/` - Sub-batch 2
  - `batch_1/batch_3/` - Sub-batch 3
  - `batch_1/batch_4/` - Sub-batch 4
- `tie_clean_batch_01/` - (Not really used)
- `tie_clean_batch_02/` - (Not really used)
- `tie_clean_batch_03/` - (Not really used)
- `tie_clean_batch_04/` - (Not really used)

## Image URL Rules

1. **For organized product types** (vests, blazers, suits, etc.):
   - Use: `https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/[folder]/[image]`
   - Example: `https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/double_breasted/mens_double_breasted_suit_model_2024_0.webp`

2. **For batch imported products**:
   - Use: `https://pub-5cd8c531c0034986bf6282a223bd0564.r2.dev/batch_1/[image]`
   - Example: `https://pub-5cd8c531c0034986bf6282a223bd0564.r2.dev/batch_1/nan_elegant-black-paisley-three-piece-tuxedo-with-velvet-lapel-a-modern-classic-for-2024-prom-and-wedding-seasons_2.0.webp`

## Current Issue
We incorrectly updated ALL product images to use the first bucket URL (`pub-8ea0502158a94b8ca8a7abb9e18a57e8`), but products with batch images need to use the second bucket URL (`pub-5cd8c531c0034986bf6282a223bd0564`).

## Fix Required
- Products with paths containing `batch_1` should use: `pub-5cd8c531c0034986bf6282a223bd0564.r2.dev`
- Products with organized folder paths should use: `pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev`