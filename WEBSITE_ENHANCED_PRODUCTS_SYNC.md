# Website Preparation for Enhanced Products System

## 🚨 IMPORTANT: Admin & Website Synchronization Plan

The admin panel is implementing a new enhanced products system. The website needs to prepare to consume this new structure. Here's everything you need to know.

## 📋 Overview of Changes

### What's Changing:
1. **New Database Table**: `products_enhanced` (running parallel to old `products` table initially)
2. **New Image Structure**: JSONB format with categorized images
3. **New CDN**: `cdn.kctmenswear.com` with organized folder structure
4. **20-Tier Pricing System**: Standardized price tiers instead of individual prices
5. **Enhanced Image Support**: 1-9+ images per product with specific types

### What's Staying the Same:
- Supabase database connection
- Authentication system
- Order processing
- Customer management

## 🗄️ New Database Schema

### products_enhanced Table Structure:
```sql
CREATE TABLE products_enhanced (
  id UUID PRIMARY KEY,
  
  -- Core Fields (Similar to old)
  name VARCHAR(255) NOT NULL,
  sku VARCHAR(100) UNIQUE NOT NULL,
  handle VARCHAR(255) UNIQUE NOT NULL,
  
  -- New Fashion-Specific Fields
  style_code VARCHAR(50),
  season VARCHAR(50),           -- 'SS24', 'FW24', etc.
  collection VARCHAR(100),      -- 'Luxury Essentials', etc.
  
  -- Categories (Enhanced)
  category VARCHAR(100),         -- 'Blazers', 'Suits', 'Shirts'
  subcategory VARCHAR(100),      -- 'Formal', 'Casual', 'Summer'
  occasion JSONB,               -- ['formal', 'business', 'wedding']
  
  -- New 20-Tier Pricing
  price_tier VARCHAR(50),        -- 'TIER_1' through 'TIER_20'
  base_price INTEGER,           -- Still in cents
  compare_at_price INTEGER,
  
  -- Fashion Attributes
  color_family VARCHAR(50),      -- 'Blue', 'Black', 'Grey'
  color_name VARCHAR(100),       -- 'Midnight Navy', 'Charcoal'
  materials JSONB,              -- {"primary": "Velvet", "composition": {"Cotton": 85, "Silk": 15}}
  care_instructions TEXT[],
  fit_type VARCHAR(50),         -- 'Slim', 'Regular', 'Relaxed'
  size_range JSONB,             -- {"min": "XS", "max": "3XL", "available": ["S","M","L","XL"]}
  
  -- CRITICAL: New Image Structure (JSONB)
  images JSONB,                 -- See structure below
  
  -- SEO
  description TEXT,
  meta_title VARCHAR(70),
  meta_description VARCHAR(160),
  tags TEXT[],
  
  -- Status
  status VARCHAR(20),           -- 'draft', 'active', 'archived'
  
  -- Stripe (Same as before)
  stripe_product_id VARCHAR(255),
  stripe_active BOOLEAN,
  
  -- Timestamps
  created_at TIMESTAMPTZ,
  updated_at TIMESTAMPTZ
);
```

## 🖼️ New Image Structure (CRITICAL CHANGE)

### JSONB Image Format:
```javascript
{
  "hero": {
    "url": "https://cdn.kctmenswear.com/blazers/summer/mens-blue-casual-blazer/main.webp",
    "alt": "Men's Blue Casual Blazer - Main View"
  },
  "flat": {
    "url": "https://cdn.kctmenswear.com/blazers/summer/mens-blue-casual-blazer/flat.webp",
    "alt": "Men's Blue Casual Blazer - Flat Lay"
  },
  "lifestyle": [
    {
      "url": "https://cdn.kctmenswear.com/blazers/summer/mens-blue-casual-blazer/back.webp",
      "alt": "Back View"
    },
    {
      "url": "https://cdn.kctmenswear.com/blazers/summer/mens-blue-casual-blazer/side.webp",
      "alt": "Side View"
    }
  ],
  "details": [
    {
      "url": "https://cdn.kctmenswear.com/blazers/summer/mens-blue-casual-blazer/front-close.webp",
      "alt": "Front Close-up"
    },
    {
      "url": "https://cdn.kctmenswear.com/blazers/summer/mens-blue-casual-blazer/close-side.webp",
      "alt": "Side Detail"
    }
  ],
  "variants": {
    "navy": [
      {"url": "...", "alt": "Navy variant"}
    ],
    "black": [
      {"url": "...", "alt": "Black variant"}
    ]
  },
  "video": {
    "url": "https://cdn.kctmenswear.com/blazers/summer/mens-blue-casual-blazer/showcase.mp4",
    "thumbnail": "https://cdn.kctmenswear.com/blazers/summer/mens-blue-casual-blazer/video-thumb.jpg"
  },
  "gallery_order": ["hero", "flat", "lifestyle", "details"],
  "total_images": 6
}
```

## 🔄 Website Implementation Tasks

### 1. Update Product Queries

**Old Query:**
```javascript
const { data: products } = await supabase
  .from('products')
  .select('*')
  .eq('status', 'active');
```

**New Query:**
```javascript
const { data: products } = await supabase
  .from('products_enhanced')
  .select(`
    *,
    price_tiers!inner(
      display_range,
      min_price,
      max_price
    )
  `)
  .eq('status', 'active');
```

### 2. Update Image Display Components

**Old Image Handling:**
```jsx
<img src={product.primary_image} alt={product.name} />
```

**New Image Handling:**
```jsx
// Product Gallery Component
function ProductGallery({ product }) {
  const images = product.images;
  
  return (
    <div className="gallery">
      {/* Hero Image */}
      {images.hero && (
        <img 
          src={images.hero.url} 
          alt={images.hero.alt}
          className="hero-image"
        />
      )}
      
      {/* Flat Lay (Fashion Standard) */}
      {images.flat && (
        <img 
          src={images.flat.url} 
          alt={images.flat.alt}
          className="flat-image"
        />
      )}
      
      {/* Lifestyle Images */}
      {images.lifestyle?.map((img, index) => (
        <img 
          key={index}
          src={img.url} 
          alt={img.alt}
          className="lifestyle-image"
        />
      ))}
      
      {/* Detail Shots */}
      {images.details?.map((img, index) => (
        <img 
          key={index}
          src={img.url} 
          alt={img.alt}
          className="detail-image"
        />
      ))}
    </div>
  );
}
```

### 3. Handle 20-Tier Pricing System

**Price Tier Mapping:**
```javascript
const PRICE_TIERS = {
  'TIER_1': { min: 50, max: 74, display: '$50-74' },
  'TIER_2': { min: 75, max: 99, display: '$75-99' },
  'TIER_3': { min: 100, max: 124, display: '$100-124' },
  'TIER_4': { min: 125, max: 149, display: '$125-149' },
  'TIER_5': { min: 150, max: 199, display: '$150-199' },
  'TIER_6': { min: 200, max: 249, display: '$200-249' },
  'TIER_7': { min: 250, max: 299, display: '$250-299' },
  'TIER_8': { min: 300, max: 399, display: '$300-399' },
  'TIER_9': { min: 400, max: 499, display: '$400-499' },
  'TIER_10': { min: 500, max: 599, display: '$500-599' },
  'TIER_11': { min: 600, max: 699, display: '$600-699' },
  'TIER_12': { min: 700, max: 799, display: '$700-799' },
  'TIER_13': { min: 800, max: 899, display: '$800-899' },
  'TIER_14': { min: 900, max: 999, display: '$900-999' },
  'TIER_15': { min: 1000, max: 1249, display: '$1000-1249' },
  'TIER_16': { min: 1250, max: 1499, display: '$1250-1499' },
  'TIER_17': { min: 1500, max: 1999, display: '$1500-1999' },
  'TIER_18': { min: 2000, max: 2999, display: '$2000-2999' },
  'TIER_19': { min: 3000, max: 4999, display: '$3000-4999' },
  'TIER_20': { min: 5000, max: null, display: '$5000+' }
};

// Display price
function ProductPrice({ product }) {
  const tier = PRICE_TIERS[product.price_tier];
  
  return (
    <div className="price">
      <span className="actual-price">
        ${(product.base_price / 100).toFixed(2)}
      </span>
      {product.compare_at_price && (
        <span className="compare-price">
          ${(product.compare_at_price / 100).toFixed(2)}
        </span>
      )}
      <span className="tier-badge">{tier.display}</span>
    </div>
  );
}
```

### 4. Update Product Detail Page

```jsx
function ProductDetailPage({ product }) {
  // New fields available
  const {
    style_code,      // Display style code
    season,          // Show season badge
    collection,      // Collection name
    color_family,    // Color grouping
    color_name,      // Specific color
    materials,       // Material composition
    care_instructions, // Care guide
    fit_type,        // Fit information
    size_range       // Available sizes
  } = product;
  
  return (
    <div>
      {/* Product Info */}
      <h1>{product.name}</h1>
      <p className="style-code">Style: {style_code}</p>
      <p className="season">{season} Collection</p>
      
      {/* Material Info */}
      {materials && (
        <div className="materials">
          <h3>Materials</h3>
          <p>{materials.primary}</p>
          {materials.composition && (
            <ul>
              {Object.entries(materials.composition).map(([mat, percent]) => (
                <li key={mat}>{mat}: {percent}%</li>
              ))}
            </ul>
          )}
        </div>
      )}
      
      {/* Size Selection */}
      <div className="sizes">
        {size_range?.available?.map(size => (
          <button key={size}>{size}</button>
        ))}
      </div>
      
      {/* Care Instructions */}
      {care_instructions && (
        <div className="care">
          <h3>Care Instructions</h3>
          <ul>
            {care_instructions.map((instruction, i) => (
              <li key={i}>{instruction}</li>
            ))}
          </ul>
        </div>
      )}
    </div>
  );
}
```

## 🚀 Migration Strategy

### Phase 1: Parallel Running (NOW)
1. Admin creates products in `products_enhanced` table
2. Website checks BOTH tables:
```javascript
// Check enhanced table first, fallback to old
let products = await supabase
  .from('products_enhanced')
  .select('*')
  .eq('status', 'active');

if (!products.data || products.data.length === 0) {
  products = await supabase
    .from('products')
    .select('*')
    .eq('status', 'active');
}
```

### Phase 2: Gradual Migration
- New products only in `products_enhanced`
- Old products remain in `products` table
- Website handles both formats

### Phase 3: Full Migration
- All products in `products_enhanced`
- Deprecate old `products` table
- Single source of truth

## 🎯 Critical Website Updates Needed

### Immediate (Before First Test Products):
1. **Update Supabase queries** to handle products_enhanced table
2. **Create image gallery component** that handles JSONB structure
3. **Implement price tier display** logic
4. **Update product card** to show new image structure

### Next Week:
1. **Add filtering** by season, collection, fit type
2. **Implement size range** display
3. **Add material composition** display
4. **Update SEO** to use new meta fields

### Future:
1. **Video player** for product videos
2. **Color variant** switcher
3. **Advanced filtering** using new attributes

## 📊 Testing Checklist

When the first test products are ready:
- [ ] Products load from products_enhanced table
- [ ] All image types display correctly (hero, flat, lifestyle, details)
- [ ] Price displays with tier information
- [ ] Season and collection badges show
- [ ] Size range displays properly
- [ ] Materials and care instructions visible
- [ ] Product URLs use new handle field
- [ ] CDN images load from cdn.kctmenswear.com

## 🔗 New CDN Structure

All images now follow this pattern:
```
https://cdn.kctmenswear.com/{category}/{season}/{product-handle}/{image-name}.webp

Example:
https://cdn.kctmenswear.com/blazers/summer/mens-blue-casual-blazer/main.webp
https://cdn.kctmenswear.com/blazers/summer/mens-blue-casual-blazer/flat.webp
https://cdn.kctmenswear.com/suits/formal/mens-black-tuxedo/main.webp
```

## 🆘 Support & Questions

### Key Differences to Remember:
1. **Images are JSONB** not separate table
2. **Price tiers** not individual prices
3. **Multiple image types** not just primary/additional
4. **Fashion-specific fields** like fit, materials, care
5. **CDN organized by category** not random buckets

### Backward Compatibility:
- Old products remain untouched initially
- Both systems run in parallel
- Gradual migration when ready
- No breaking changes to existing orders

---

**Timeline**: First test products ready within 24-48 hours
**Priority**: Update product queries and image handling first
**Contact**: Coordinate through shared communication channel

## Sample Test Product Structure

Here's what to expect from the first test product:

```javascript
{
  id: "uuid-here",
  name: "Premium Velvet Blazer - Midnight Navy",
  sku: "VB-001-NVY",
  handle: "premium-velvet-blazer-navy",
  style_code: "FW24-VB-001",
  season: "FW24",
  collection: "Luxury Essentials",
  category: "Blazers",
  subcategory: "Formal",
  price_tier: "TIER_8",
  base_price: 34900, // $349.00
  compare_at_price: 44900, // $449.00
  color_family: "Blue",
  color_name: "Midnight Navy",
  materials: {
    primary: "Velvet",
    composition: {
      "Cotton Velvet": 85,
      "Silk": 15
    }
  },
  fit_type: "Modern Fit",
  size_range: {
    min: "XS",
    max: "3XL",
    available: ["XS", "S", "M", "L", "XL", "2XL", "3XL"]
  },
  images: {
    hero: {
      url: "https://cdn.kctmenswear.com/blazers/formal/premium-velvet-blazer-navy/main.webp",
      alt: "Premium Velvet Blazer Navy - Hero"
    },
    flat: {
      url: "https://cdn.kctmenswear.com/blazers/formal/premium-velvet-blazer-navy/flat.webp",
      alt: "Premium Velvet Blazer Navy - Flat Lay"
    },
    lifestyle: [
      // 2-4 lifestyle images
    ],
    details: [
      // 3-5 detail shots
    ],
    total_images: 8
  },
  status: "active",
  stripe_product_id: "prod_xxxxx",
  stripe_active: true
}
```

This is your comprehensive sync document. The website team should start preparing these changes immediately!