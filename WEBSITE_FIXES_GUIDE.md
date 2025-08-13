# Website Frontend Fixes - Complete Solution Guide

## 🔴 Issue 1: Image 404 Errors (90+ broken images)

### Root Cause:
- Images exist in Cloudflare R2 but URLs in database have wrong paths
- Some using wrong bucket (pub-8ea... instead of pub-5cd...)

### ✅ Solution Ready:

#### Option A: Fix in Database (Recommended)
```sql
-- Run this in Supabase SQL Editor
-- File: sql/fixes/fix-missing-images.sql

-- Updates all products to use correct R2 bucket
UPDATE products 
SET primary_image = REPLACE(
  primary_image, 
  'pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev', 
  'pub-5cd8c531c0034986bf6282a223bd0564.r2.dev'
)
WHERE primary_image LIKE '%pub-8ea%';

-- Also update product_images table
UPDATE product_images 
SET image_url = REPLACE(
  image_url, 
  'pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev', 
  'pub-5cd8c531c0034986bf6282a223bd0564.r2.dev'
);
```

#### Option B: Frontend Fallback System
```typescript
// In your image component
const getProductImage = (imageUrl: string | null) => {
  if (!imageUrl) {
    return '/images/default-suit.jpg'; // Your branded placeholder
  }
  
  // Fix common URL issues
  let fixedUrl = imageUrl;
  
  // Replace wrong bucket
  fixedUrl = fixedUrl.replace(
    'pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev',
    'pub-5cd8c531c0034986bf6282a223bd0564.r2.dev'
  );
  
  return fixedUrl;
};

// With error handling
<img 
  src={getProductImage(product.primary_image)}
  onError={(e) => {
    e.currentTarget.src = `/images/fallback-${product.category}.jpg`;
  }}
  alt={product.name}
/>
```

## 🎯 Issue 2: Smart AI Categorization

### Current Database Structure:
```typescript
// Products have these fields for categorization:
{
  category: "Tuxedos",                    // Main category
  additional_info: {
    style: "Double Breasted",            // Style info
    color: "Midnight Blue",              // Color
    lapel_style: "Shawl",               // Specific attributes
    collection: "Velvet"                 // Collection type
  }
}
```

### ✅ Smart Categorization Implementation:

```typescript
// Smart categorization function
function categorizeProduct(product: Product): string[] {
  const categories = [product.category]; // Start with main category
  const name = product.name.toLowerCase();
  const info = product.additional_info || {};
  
  // Summer Suits (light colors, linen, cotton)
  if (name.includes('linen') || name.includes('cotton') || 
      name.includes('light') || name.includes('summer') ||
      ['cream', 'khaki', 'light blue', 'coral', 'tan'].includes(info.color?.toLowerCase())) {
    categories.push('Summer Suits');
  }
  
  // Tuxedos (formal, black tie)
  if (name.includes('tuxedo') || name.includes('tux') || 
      info.style === 'Tuxedo' || info.lapel_style) {
    categories.push('Tuxedos');
  }
  
  // Wedding Suits (special occasion)
  if (name.includes('wedding') || name.includes('groom') || 
      product.featured || product.base_price > 35000) { // Premium items
    categories.push('Wedding Suits');
  }
  
  // Luxury Suits (velvet, sequin, high price)
  if (info.collection === 'Velvet' || info.style === 'Velvet' ||
      name.includes('velvet') || name.includes('sequin') || 
      name.includes('luxury') || product.base_price > 40000) {
    categories.push('Luxury Suits');
  }
  
  // Three Piece (with vests)
  if (name.includes('three piece') || name.includes('3 piece') || 
      name.includes('with vest')) {
    categories.push('Three Piece');
  }
  
  // Slim Fit (modern cuts)
  if (name.includes('slim') || name.includes('skinny') || 
      name.includes('modern')) {
    categories.push('Slim Fit');
  }
  
  // Double Breasted (specific style)
  if (name.includes('double breasted') || info.style === 'Double Breasted') {
    categories.push('Double Breasted');
  }
  
  // Classic Suits (traditional)
  if (name.includes('classic') || name.includes('traditional') || 
      name.includes('business')) {
    categories.push('Classic Suits');
  }
  
  return [...new Set(categories)]; // Remove duplicates
}

// Category configuration for UI
const categoryConfig = {
  'Summer Suits': {
    icon: '☀️',
    image: '/images/categories/summer-suits.jpg',
    description: 'Light & breathable for warm weather'
  },
  'Tuxedos': {
    icon: '🎩',
    image: '/images/categories/tuxedos.jpg',
    description: 'Black tie & formal occasions'
  },
  'Wedding Suits': {
    icon: '💒',
    image: '/images/categories/wedding-suits.jpg',
    description: 'Perfect for your special day'
  },
  'Luxury Suits': {
    icon: '💎',
    image: '/images/categories/luxury-suits.jpg',
    description: 'Premium velvet & designer pieces'
  },
  'Three Piece': {
    icon: '🎭',
    image: '/images/categories/three-piece.jpg',
    description: 'Complete with matching vests'
  },
  'Slim Fit': {
    icon: '✨',
    image: '/images/categories/slim-fit.jpg',
    description: 'Modern tailored cuts'
  },
  'Double Breasted': {
    icon: '🤵',
    image: '/images/categories/double-breasted.jpg',
    description: 'Classic power suits'
  },
  'Classic Suits': {
    icon: '💼',
    image: '/images/categories/classic-suits.jpg',
    description: 'Timeless business attire'
  }
};
```

## 📊 Issue 3: Fallback Strategy for Missing Images

### Recommended Approach:

```typescript
// Fallback image mapping by category
const fallbackImages = {
  'Tuxedos': 'https://pub-5cd8c531c0034986bf6282a223bd0564.r2.dev/defaults/tuxedo-default.jpg',
  'Men\'s Suits': 'https://pub-5cd8c531c0034986bf6282a223bd0564.r2.dev/defaults/suit-default.jpg',
  'Luxury Velvet Blazers': 'https://pub-5cd8c531c0034986bf6282a223bd0564.r2.dev/defaults/velvet-blazer-default.jpg',
  'Vest & Tie Sets': 'https://pub-5cd8c531c0034986bf6282a223bd0564.r2.dev/defaults/vest-default.jpg',
  'default': 'https://pub-5cd8c531c0034986bf6282a223bd0564.r2.dev/defaults/product-default.jpg'
};

// Smart image component
function ProductImage({ product }) {
  const [imageSrc, setImageSrc] = useState(product.primary_image);
  const [hasError, setHasError] = useState(false);
  
  const handleError = () => {
    if (!hasError) {
      setHasError(true);
      setImageSrc(fallbackImages[product.category] || fallbackImages.default);
    }
  };
  
  return (
    <img 
      src={imageSrc}
      onError={handleError}
      alt={product.name}
      loading="lazy"
      className="product-image"
    />
  );
}
```

## 🚀 Implementation Priority:

### Step 1: Fix Images (Immediate)
1. Run the SQL fix script to update URLs
2. Implement frontend fallback system
3. Add lazy loading for performance

### Step 2: Smart Categories (Today)
1. Implement categorization function
2. Update category filter UI
3. Test with real product data

### Step 3: Optimize (This Week)
1. Add image CDN optimization
2. Implement category caching
3. Add product search

## 📝 Database Query for Frontend:

```javascript
// Get products with smart categorization
async function getProductsWithCategories() {
  const { data: products } = await supabase
    .from('products')
    .select(`
      *,
      product_variants (
        id, title, option1, option2, price, inventory_quantity
      )
    `)
    .eq('status', 'active')
    .eq('visibility', true);
  
  // Apply smart categorization
  return products.map(product => ({
    ...product,
    smart_categories: categorizeProduct(product),
    image_url: getProductImage(product.primary_image)
  }));
}
```

## ✅ Summary of Answers:

1. **Image Storage:** Cloudflare R2 (pub-5cd8c531c0034986bf6282a223bd0564.r2.dev)
2. **Admin Panel:** Yes, full access available
3. **Categorization Priority:** Use product name + metadata + price for smart AI logic
4. **Fallback Strategy:** Use category-specific default images
5. **Database has:** 300+ products with full metadata for categorization

The complete fix will resolve all 90+ image errors and create intelligent category filtering!