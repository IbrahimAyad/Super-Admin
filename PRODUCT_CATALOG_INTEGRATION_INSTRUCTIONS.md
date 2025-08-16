# Product Catalog Integration Instructions

## Overview
This document provides instructions for integrating two new product catalogs into Supabase: **Fall 2025 Collection** and **Vest Accessories Collection**. All CDN URLs have been generated and organized for immediate database integration.

## 📁 File Locations
All files are located in this Super-Admin folder:

### Fall 2025 Collection Files:
- **`fall_2025_all_cdn_urls.txt`** - Complete list of 111 CDN URLs
- **`fall_2025_cdn_urls.json`** - Structured JSON with categories and metadata
- **`generate_fall_2025_cdn_urls.py`** - Python script used to generate URLs

### Vest Accessories Collection Files:
- **`all_vest_accessories_cdn_urls.txt`** - Complete list of 76 CDN URLs  
- **`suspender_bowtie_set_cdn_urls.txt`** - 24 suspender-bowtie set URLs
- **`vest_tie_set_cdn_urls.txt`** - 52 vest-tie set URLs
- **`vest_accessories_cdn_urls.json`** - Structured JSON with metadata
- **`generate_vest_accessories_cdn_urls.py`** - Python script used to generate URLs

## 🎯 Integration Tasks

### Task 1: Fall 2025 Collection Integration
**Source Data:** `fall_2025_cdn_urls.json` and `fall_2025_all_cdn_urls.txt`

**Product Categories to Add:**
- **Double-Breasted Suits** (15 images, 10 products)
- **Mens Shirts** (23 images, 13 products)  
- **Stretch Suits** (22 images, 9 products)
- **Suits** (16 images, 10 products)
- **Tuxedos** (35 images, 19 products)

**CDN URL Pattern:** `https://cdn.kctmenswear.com/{category}/{product-slug}/{image-name}.webp`

**Image Types:**
- `main.webp` - Primary product image
- `front-close.webp` - Close-up front view
- `close-side.webp` - Close-up side view  
- `side.webp` - Side view
- `back.webp` - Back view
- `lifestyle.webp` - Lifestyle/model shots

### Task 2: Vest Accessories Integration
**Source Data:** `vest_accessories_cdn_urls.json` and category-specific txt files

**Product Categories to Add:**
- **Suspender-Bowtie Sets** (24 images, 10 products)
- **Vest-Tie Sets** (52 images, 26 products)

**CDN URL Pattern:** `https://cdn.kctmenswear.com/menswear-accessories/{category}/{product-name}/{image-name}`

**Image Types:**
- `model.webp` - Model wearing the item
- `main.webp` - Alternative model image (some folders)
- `vest.jpg` - Vest product image
- `product.jpg` - Product set image
- Various color-specific variants

## 🔧 Technical Implementation

### Database Schema Requirements
Ensure your Supabase tables support:

1. **Products Table:**
   - `name` (text) - Product name
   - `handle` (text) - SEO-friendly slug
   - `category` (text) - Product category
   - `subcategory` (text) - Product subcategory
   - `sku` (text) - Product SKU
   - `collection_id` (uuid) - Reference to collections table

2. **Product Images Table:**
   - `product_id` (uuid) - Reference to products table
   - `image_url` (text) - CDN URL
   - `image_type` (text) - Type of image (main, front-close, side, etc.)
   - `alt_text` (text) - SEO alt text
   - `sort_order` (integer) - Display order

3. **Collections Table:**
   - `name` (text) - Collection name
   - `handle` (text) - Collection slug
   - `description` (text) - Collection description

### Implementation Steps

#### Step 1: Create Collections
```sql
-- Fall 2025 Collections
INSERT INTO collections (name, handle, description) VALUES
('Fall 2025 Double-Breasted Suits', 'fall-2025-double-breasted-suits', 'Elegant double-breasted suits for Fall 2025'),
('Fall 2025 Mens Shirts', 'fall-2025-mens-shirts', 'Stylish mens shirts for Fall 2025'),
('Fall 2025 Stretch Suits', 'fall-2025-stretch-suits', 'Comfortable stretch suits for Fall 2025'),
('Fall 2025 Suits', 'fall-2025-suits', 'Classic suits for Fall 2025'),
('Fall 2025 Tuxedos', 'fall-2025-tuxedos', 'Formal tuxedos for Fall 2025');

-- Vest Accessories Collections  
INSERT INTO collections (name, handle, description) VALUES
('Suspender-Bowtie Sets', 'suspender-bowtie-sets', 'Coordinated suspender and bowtie accessories'),
('Vest-Tie Sets', 'vest-tie-sets', 'Matching vest and tie combinations');
```

#### Step 2: Process JSON Data
Use the provided JSON files to extract product information:

```javascript
// Example for Fall 2025
const fall2025Data = JSON.parse(fs.readFileSync('fall_2025_cdn_urls.json', 'utf8'));

for (const [category, products] of Object.entries(fall2025Data.categories)) {
  for (const [productName, productData] of Object.entries(products)) {
    // Create product record
    const product = {
      name: convertToDisplayName(productName),
      handle: productName,
      category: 'clothing',
      subcategory: category,
      sku: generateSKU(category, productName)
    };
    
    // Insert product images
    productData.images.forEach((image, index) => {
      const imageRecord = {
        product_id: product.id,
        image_url: image.cdn_url,
        image_type: determineImageType(image.image_name),
        alt_text: generateAltText(product.name, image.image_name),
        sort_order: index
      };
    });
  }
}
```

#### Step 3: Handle Special Cases
- **"Main" vs "Model" files:** Some vest accessories have `main.webp` instead of `model.webp` - treat both as primary model images
- **Duplicate files:** Some products have multiple model variants (e.g., `model.webp` and `model-2.webp`) - use sort_order to prioritize
- **Mixed file extensions:** Handle both `.webp` and `.jpg` files appropriately

### Data Validation Checklist
- [ ] All 111 Fall 2025 images properly categorized
- [ ] All 76 vest accessories images properly categorized  
- [ ] Product names converted from slugs to display names
- [ ] Image types correctly identified
- [ ] Alt text generated for SEO
- [ ] CDN URLs validated and accessible
- [ ] Collections properly linked to products

## 🚀 Next Steps
1. Review the JSON files to understand the data structure
2. Update your Supabase schema if needed
3. Create the import scripts based on the patterns above
4. Test with a small subset before full import
5. Validate all CDN URLs are accessible
6. Update your frontend to display the new categories

## 📞 Support
If you need clarification on any product categorization or CDN URL patterns, refer to the original folder structures in the AWS-Web-Scraper-Shopify project:
- Fall 2025 images: `Fall 2025/` folder
- Vest accessories: `vest-clean/` folder

All URLs follow the established Cloudflare R2 pattern and are ready for immediate database integration.
