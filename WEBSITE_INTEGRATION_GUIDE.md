# Website Integration Guide - New Products

## Quick Setup for Website Team

### 1. Environment Variables (Add to your website):
```env
NEXT_PUBLIC_SUPABASE_URL=https://gvcswimqaxvylgxbklbz.supabase.co
NEXT_PUBLIC_SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imd2Y3N3aW1xYXh2eWxneGJrbGJ6Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTM3NjA1MzAsImV4cCI6MjA2OTMzNjUzMH0.UZdiGcJXUV5VYetjWXV26inmbj2yXdiT03Z6t_5Lg24
```

### 2. Database Connection:
```javascript
import { createClient } from '@supabase/supabase-js'

const supabase = createClient(
  process.env.NEXT_PUBLIC_SUPABASE_URL,
  process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY
)
```

### 3. Fetch All Products:
```javascript
async function getProducts() {
  const { data } = await supabase
    .from('products')
    .select(`
      id, sku, name, base_price, category, primary_image, 
      featured, variant_count,
      product_variants (id, title, option1, option2, price, inventory_quantity)
    `)
    .eq('status', 'active')
    .eq('visibility', true)

  return data
}
```

### 4. NEW Categories Available:
- **Tuxedos** (31 products) - $295-$485
- **Luxury Velvet Blazers** (33 products) - $285-$425  
- **Sparkle & Sequin Blazers** (26 products) - $345-$425
- **Prom & Formal Blazers** (14 products) - $245-$365
- **Casual Summer Blazers** (7 products) - $175-$245
- **Men's Suits** (64 products) - $245-$485
- **Vest & Tie Sets** (61 products) - $65
- **Accessories** (38 products) - $45-$85

### 5. Price Format:
**CRITICAL**: Prices are stored in CENTS
```javascript
// Database: 32500 = $325.00
// Display: (price / 100).toFixed(2)
<p>${(product.base_price / 100).toFixed(2)}</p>
```

### 6. Simple Product Display:
```javascript
{products.map(product => (
  <div key={product.id}>
    <img src={product.primary_image} alt={product.name} />
    <h3>{product.name}</h3>
    <p>${(product.base_price / 100).toFixed(2)}</p>
    <span>{product.category}</span>
    {product.featured && <span>⭐ Featured</span>}
  </div>
))}
```

### 7. Get Products by Category:
```javascript
// Tuxedos
const { data } = await supabase
  .from('products')
  .select('*')
  .eq('category', 'Tuxedos')
  .eq('status', 'active')

// Blazers  
const { data } = await supabase
  .from('products')  
  .select('*')
  .eq('category', 'Luxury Velvet Blazers')
  .eq('status', 'active')
```

### 8. Featured Products:
```javascript
const { data } = await supabase
  .from('products')
  .select('*')
  .eq('featured', true)
  .eq('status', 'active')
  .limit(8)
```

### 9. Product with Sizes:
```javascript
// Get product with all size variants
const { data } = await supabase
  .from('products')
  .select(`
    *,
    product_variants (
      id, title, option1, option2, sku, price, inventory_quantity
    )
  `)
  .eq('id', productId)
  .single()

// Variants have:
// option1 = Size (40R, 42R, etc.)
// option2 = Color 
// price = Price in cents
// inventory_quantity = Stock level
```

### 10. Search Products:
```javascript
const { data } = await supabase
  .from('products')
  .select('*')
  .or(`name.ilike.%${searchTerm}%,category.ilike.%${searchTerm}%`)
  .eq('status', 'active')
```

## Summary
- **300+ products** ready to display
- All have **high-quality images**
- **Proper pricing** in cents
- **Size variants** for suits/tuxedos/blazers  
- **Categories** for filtering
- **Featured products** for homepage

Your database is production-ready! Just connect and start displaying products.