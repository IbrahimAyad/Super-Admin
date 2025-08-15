# Website Query Updates for Enhanced Products

## Quick Fix for Current Errors

The website needs to update its queries to handle both the permission issues and the slug/handle difference. Here's the immediate fix:

### 1. Update Product Query (Use handle OR slug)

```javascript
// Option A: Query using handle (our primary field)
const { data: products, error } = await supabase
  .from('products_enhanced')
  .select('*')
  .eq('handle', productHandle);

// Option B: Query using slug (for backward compatibility)
const { data: products, error } = await supabase
  .from('products_enhanced')
  .select('*')
  .eq('slug', productSlug);

// Option C: Flexible query (handles both)
const { data: products, error } = await supabase
  .from('products_enhanced')
  .select('*')
  .or(`handle.eq.${identifier},slug.eq.${identifier}`);
```

### 2. List All Products Query

```javascript
const { data: products, error } = await supabase
  .from('products_enhanced')
  .select('*')
  .order('created_at', { ascending: false });

// No need for status filter - RLS now allows all reads
```

### 3. Product Card Component Update

```javascript
function ProductCard({ product }) {
  // Use slug OR handle for URLs
  const productUrl = `/products/${product.slug || product.handle}`;
  
  // Extract hero image from JSONB
  const heroImage = product.images?.hero?.url;
  
  return (
    <Link to={productUrl}>
      <div className="product-card">
        {heroImage && (
          <img src={heroImage} alt={product.images?.hero?.alt || product.name} />
        )}
        <h3>{product.name}</h3>
        <p className="price">${(product.base_price / 100).toFixed(2)}</p>
        <span className="tier">{product.price_tier}</span>
      </div>
    </Link>
  );
}
```

### 4. Product Detail Page Query

```javascript
// Get single product by slug or handle
async function getProduct(identifier) {
  const { data, error } = await supabase
    .from('products_enhanced')
    .select(`
      *,
      price_tiers!inner(
        display_range,
        min_price,
        max_price
      )
    `)
    .or(`handle.eq.${identifier},slug.eq.${identifier}`)
    .single();
    
  if (error) {
    console.error('Product fetch error:', error);
    return null;
  }
  
  return data;
}
```

## Database Changes Applied

1. **RLS Fixed**: Public read access now allowed for all products
2. **Slug Column Added**: All products now have both `handle` and `slug` fields
3. **Status Updated**: All products set to 'active'
4. **Permissions Granted**: anon and authenticated roles have SELECT access

## Testing Checklist

- [ ] Products load without permission errors
- [ ] Both slug and handle fields work for queries
- [ ] Images display correctly from JSONB structure
- [ ] Price tier information shows properly
- [ ] No authentication required for viewing products

## Next Steps

1. Update all product queries to use the new table
2. Update components to handle JSONB image structure
3. Test with the real products we inserted
4. Implement fallback for old products table during transition