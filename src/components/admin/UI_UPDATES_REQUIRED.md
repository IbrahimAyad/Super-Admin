# Admin UI Updates Required After Database Changes

## 1. **Switch to products_enhanced Table** 🔄
The admin should now use `products_enhanced` as the primary source:

### Files to Update:
- `src/lib/services/products.ts`
- `src/components/admin/ProductManagement.tsx`
- `src/components/admin/EnhancedProductManagement.tsx`

### Changes:
```typescript
// OLD
const { data } = await supabase.from('products')

// NEW
const { data } = await supabase.from('products_enhanced')
```

## 2. **Add Blazer Size Manager to Dashboard** 👔
Already created: `src/components/admin/BlazerSizeManager.tsx`

### Add to Admin Dashboard:
```tsx
import { BlazerSizeManager } from '@/components/admin/BlazerSizeManager';

// In your admin routes or dashboard
<Tab label="Blazer Sizes" value="blazer-sizes">
  <BlazerSizeManager />
</Tab>
```

## 3. **Update Product Categories & Filters** 📊

### New Categories to Support:
- **Blazers** (70 products) - $199-249
- **Double-Breasted Suits** (12 products) - $200-400
- **Stretch Suits** (10 products) - $200-400
- **Suits** (10 products) - $200-400
- **Tuxedos** (20 products) - $250-400
- **Mens Shirts** (13 products) - $49-69
- **Accessories** (37 products) - $49.99

### Update Filter Component:
```tsx
const CATEGORIES = [
  { value: 'all', label: 'All Products' },
  { value: 'Blazers', label: 'Blazers' },
  { value: 'Double-Breasted Suits', label: 'Double-Breasted Suits' },
  { value: 'Stretch Suits', label: 'Stretch Suits' },
  { value: 'Suits', label: 'Regular Suits' },
  { value: 'Tuxedos', label: 'Tuxedos' },
  { value: 'Mens Shirts', label: 'Shirts' },
  { value: 'Accessories', label: 'Accessories' }
];

const PRICE_RANGES = [
  { value: 'all', label: 'All Prices' },
  { value: '0-50', label: 'Under $50' },
  { value: '50-100', label: '$50 - $100' },
  { value: '100-200', label: '$100 - $200' },
  { value: '200-300', label: '$200 - $300' },
  { value: '300-500', label: '$300 - $500' }
];
```

## 4. **Variant Size Display Logic** 📏

Different products have different size systems:

```typescript
const getSizeDisplay = (category: string, variant: any) => {
  switch(category) {
    case 'Accessories':
      if (variant.sku?.includes('SBS')) return 'One Size';
      return variant.option1; // XS-6XL for vests
    
    case 'Blazers':
    case 'Suits':
    case 'Double-Breasted Suits':
    case 'Stretch Suits':
    case 'Tuxedos':
      return variant.option1; // 36R-54R, possibly S/L
    
    case 'Mens Shirts':
      return variant.option1; // 14.5-18 neck sizes
    
    default:
      return variant.option1;
  }
};
```

## 5. **New Fields in products_enhanced** 🆕

Update forms to include:
- `size_options` (JSON) - For blazer R/S/L configuration
- `price_tier` (TIER_1 through TIER_10)
- `color_name` & `color_family`
- `materials` (JSON)
- `fit_type`
- `subcategory`
- `style_code`
- `season` & `collection`
- `images` (JSON with hero and gallery)

## 6. **Product Form Updates** 📝

```tsx
// Add to ProductForm component
const [sizeOptions, setSizeOptions] = useState({
  regular: true,
  short: false,
  long: false
});

// Only show for blazers/suits
{(category === 'Blazers' || category.includes('Suits')) && (
  <div className="space-y-2">
    <Label>Available Size Types</Label>
    <div className="flex gap-4">
      <Checkbox
        checked={sizeOptions.regular}
        onCheckedChange={(checked) => 
          setSizeOptions(prev => ({ ...prev, regular: checked }))}
      />
      <Label>Regular (36R-54R)</Label>
      
      <Checkbox
        checked={sizeOptions.short}
        onCheckedChange={(checked) => 
          setSizeOptions(prev => ({ ...prev, short: checked }))}
      />
      <Label>Short (34S-54S)</Label>
      
      <Checkbox
        checked={sizeOptions.long}
        onCheckedChange={(checked) => 
          setSizeOptions(prev => ({ ...prev, long: checked }))}
      />
      <Label>Long (36L-54L)</Label>
    </div>
  </div>
)}
```

## 7. **Dashboard Statistics Update** 📈

```tsx
const getDashboardStats = async () => {
  // Total products from products_enhanced
  const { count: totalProducts } = await supabase
    .from('products_enhanced')
    .select('*', { count: 'exact', head: true });

  // Products by category
  const { data: categoryStats } = await supabase
    .from('products_enhanced')
    .select('category')
    .select('*', { count: 'exact' })
    .group('category');

  // Inventory from product_variants
  const { data: inventory } = await supabase
    .from('product_variants')
    .select('inventory_quantity')
    .sum('inventory_quantity');

  return {
    totalProducts,
    categoryBreakdown: categoryStats,
    totalInventory: inventory
  };
};
```

## 8. **Image Management Update** 🖼️

Products now use JSON for images:
```tsx
// Display primary image
<img src={product.images?.hero?.url || '/placeholder.jpg'} />

// Display gallery
{product.images?.gallery?.map((img, idx) => (
  <img key={idx} src={img.url} />
))}
```

## 9. **Price Display** 💰

All prices are now in cents/integer format:
```tsx
// Format price display
const formatPrice = (price: number) => {
  return `$${(price / 100).toFixed(2)}`;
};

// Or for whole dollar amounts
const formatPrice = (price: number) => {
  return `$${price.toFixed(2)}`;
};
```

## 10. **Required Component Updates** 🔧

### Priority Updates:
1. ✅ `BlazerSizeManager.tsx` - Already created
2. ⏳ `ProductManagement.tsx` - Switch to products_enhanced
3. ⏳ `ProductFilters.tsx` - Add new categories
4. ⏳ `ProductForm.tsx` - Add new fields
5. ⏳ `InventoryManagement.tsx` - Handle new variant structure
6. ⏳ `Dashboard.tsx` - Update statistics queries

### New Features to Add:
- Bulk price updater (by category)
- Size availability toggle (per product)
- Collection manager (Fall 2025, Accessories, etc.)
- SKU pattern validator
- Image CDN manager

## Quick Implementation Path:

1. **First**: Update all queries to use `products_enhanced`
2. **Second**: Add the BlazerSizeManager to admin
3. **Third**: Update filters and categories
4. **Fourth**: Fix price displays (handle new format)
5. **Fifth**: Add new form fields for enhanced products