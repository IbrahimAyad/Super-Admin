# Fix CORS and Image Issues

## 1. Fix Cloudflare R2 CORS

You have multiple R2 buckets with CORS issues:
- `pub-5cd8c531c0034986bf6282a223bd0564.r2.dev` (working)
- `pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev` (CORS blocked)

### Add CORS to the second bucket:

```json
[
  {
    "AllowedOrigins": [
      "*"
    ],
    "AllowedMethods": [
      "GET"
    ],
    "AllowedHeaders": [
      "*"
    ]
  }
]
```

## 2. Missing Images (404s)

These images are missing from your R2 bucket:
- `tuxedo-jacket_burgundy-velvet-tuxedo-jacket_1.0.jpg`
- `mens-suits_royal-blue-three-piece-suit_1.0.jpg`
- `tuxedo-jacket_turquoise-tuxedo-jacket_1.0.jpg`
- `mens-suits_charcoal-grey-executive-suit_1.0.jpg`
- `mens-suits_classic-navy-business-suit_1.0.jpg`
- `vest-tie_lavender-vest-and-tie-set_1.0.jpg`
- `mens-suits_burgundy-velvet-dinner-jacket_1.0.jpg`

## 3. Fix Authentication

The 401 error suggests the user session expired or lacks permissions.

### Check RLS Policies:

```sql
-- Check if admin user has proper permissions
SELECT * FROM auth.users WHERE email = 'your-admin-email';

-- Update products policy to allow admin updates
CREATE POLICY "Admins can update products" ON products
FOR UPDATE USING (
  auth.uid() IN (
    SELECT id FROM auth.users 
    WHERE email IN ('your-admin-email@domain.com')
  )
);
```

## 4. Fix Product Variants 400 Error

The 400 error on product_variants suggests a validation issue. Check:

1. **Required fields**: title, option1, option2, sku, price
2. **Unique constraints**: SKU must be unique
3. **Data types**: price should be integer (cents)

## 5. Quick Fixes

### Update missing image URLs in database:
```sql
UPDATE products 
SET primary_image = 'https://pub-5cd8c531c0034986bf6282a223bd0564.r2.dev/batch_1/default-product.jpg'
WHERE primary_image LIKE '%tuxedo-jacket_burgundy-velvet%'
   OR primary_image LIKE '%mens-suits_royal-blue-three%'
   OR primary_image LIKE '%tuxedo-jacket_turquoise%';
```

### Switch to working R2 bucket:
```sql
UPDATE products 
SET primary_image = REPLACE(
  primary_image, 
  'pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev', 
  'pub-5cd8c531c0034986bf6282a223bd0564.r2.dev'
);

UPDATE product_images 
SET image_url = REPLACE(
  image_url, 
  'pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev', 
  'pub-5cd8c531c0034986bf6282a223bd0564.r2.dev'
);
```