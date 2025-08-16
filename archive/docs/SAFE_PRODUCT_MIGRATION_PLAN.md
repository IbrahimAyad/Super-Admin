# 🔄 SAFE PRODUCT SYSTEM MIGRATION PLAN
## Switch from Old Products → Enhanced Products (Clean Start)

---

## 📊 Current Situation

### OLD System (`products` table):
- Has inaccurate data
- Wrong titles
- Missing/wrong images
- Not worth migrating

### NEW System (`products_enhanced` table):
- Ready with 20-tier pricing
- Proper structure
- Clean slate to add accurate products

---

## ✅ SAFE MIGRATION STRATEGY

### Phase 1: Preparation (Today - 15 mins)

#### 1. Backup Current State
```sql
-- Create backup of old products (just in case)
CREATE TABLE products_backup_2025_01_15 AS 
SELECT * FROM products;

-- Verify backup
SELECT COUNT(*) FROM products_backup_2025_01_15;
```

#### 2. Add Test Products to Enhanced
```sql
-- Add a few test products to products_enhanced
INSERT INTO products_enhanced (
  name, sku, handle, category, base_price, status, 
  description, price_tier, images
) VALUES 
(
  'Classic Navy Blazer',
  'TEST-001',
  'classic-navy-blazer',
  'Blazers',
  34900, -- $349.00
  'active',
  'Premium wool blazer perfect for any occasion',
  'tier_7_premium',
  '{"hero": {"url": "https://placeholder.com/blazer1.jpg"}}'::jsonb
),
(
  'Velvet Dinner Jacket',
  'TEST-002',
  'velvet-dinner-jacket',
  'Blazers',
  44900, -- $449.00
  'active',
  'Luxurious velvet jacket for special events',
  'tier_8_distinguished',
  '{"hero": {"url": "https://placeholder.com/blazer2.jpg"}}'::jsonb
);
```

---

### Phase 2: Switch Admin UI (30 mins)

#### Step 1: Create Toggle Component
```typescript
// src/components/admin/ProductSystemToggle.tsx
import { useState, useEffect } from 'react';
import { Button } from '@/components/ui/button';
import { Alert } from '@/components/ui/alert';

export function ProductSystemToggle({ onSystemChange }: { onSystemChange: (system: 'old' | 'new') => void }) {
  const [currentSystem, setCurrentSystem] = useState<'old' | 'new'>('old');
  
  useEffect(() => {
    // Check localStorage for preference
    const saved = localStorage.getItem('product_system');
    if (saved === 'new') {
      setCurrentSystem('new');
      onSystemChange('new');
    }
  }, []);
  
  const switchSystem = (system: 'old' | 'new') => {
    setCurrentSystem(system);
    localStorage.setItem('product_system', system);
    onSystemChange(system);
  };
  
  return (
    <Alert className="mb-4">
      <div className="flex items-center justify-between">
        <div>
          <p className="font-medium">Product System</p>
          <p className="text-sm text-muted-foreground">
            Currently using: {currentSystem === 'old' ? 'Legacy Products' : 'Enhanced Products (20-tier)'}
          </p>
        </div>
        <div className="flex gap-2">
          <Button 
            variant={currentSystem === 'old' ? 'default' : 'outline'}
            size="sm"
            onClick={() => switchSystem('old')}
          >
            Old System
          </Button>
          <Button 
            variant={currentSystem === 'new' ? 'default' : 'outline'}
            size="sm"
            onClick={() => switchSystem('new')}
          >
            New Enhanced
          </Button>
        </div>
      </div>
    </Alert>
  );
}
```

#### Step 2: Update AdminDashboard
```typescript
// src/pages/AdminDashboard.tsx
import { ProductSystemToggle } from '@/components/admin/ProductSystemToggle';
import { ProductManagementEnhanced } from '@/components/admin/ProductManagementEnhanced';
import { EnhancedProductManagement } from '@/components/admin/EnhancedProductManagement';

// In the Products tab:
<TabsContent value="products">
  <ProductSystemToggle 
    onSystemChange={(system) => {
      setProductSystem(system);
    }}
  />
  {productSystem === 'old' ? (
    <ProductManagementEnhanced /> // Old system
  ) : (
    <EnhancedProductManagement /> // New enhanced system
  )}
</TabsContent>
```

---

### Phase 3: Add Products to New System (1-2 hours)

#### Option A: Manual Entry via Admin
1. Switch to "New Enhanced" in admin
2. Click "Add Product"
3. Enter accurate product details
4. Products automatically get price tiers

#### Option B: Bulk Import Script
```typescript
// scripts/import-products.ts
const productsToImport = [
  {
    name: 'Midnight Navy Blazer',
    sku: 'MNB-001',
    category: 'Blazers',
    base_price: 34900,
    description: 'Sophisticated navy blazer',
    images: {
      hero: { url: 'https://your-cdn.com/navy-blazer.jpg' }
    }
  },
  // Add more products...
];

for (const product of productsToImport) {
  const { error } = await supabase
    .from('products_enhanced')
    .insert({
      ...product,
      handle: product.name.toLowerCase().replace(/ /g, '-'),
      status: 'active',
      price_tier: assign_price_tier(product.base_price)
    });
    
  if (error) console.error('Failed to import:', product.sku);
}
```

---

### Phase 4: Update Website Integration (30 mins)

#### Update Product Queries
```javascript
// On website frontend, change:
const { data } = await supabase
  .from('products')  // OLD
  .select('*');

// TO:
const { data } = await supabase
  .from('products_enhanced')  // NEW
  .select('*')
  .eq('status', 'active');
```

#### Update Chat Bot
The chat bot already uses `products_enhanced` ✅

#### Update Checkout
Checkout functions already support both tables ✅

---

### Phase 5: Final Cutover (When Ready)

#### 1. Verify New System
```sql
-- Check products in new system
SELECT 
  COUNT(*) as total,
  COUNT(CASE WHEN status = 'active' THEN 1 END) as active,
  COUNT(price_tier) as with_tiers
FROM products_enhanced;
```

#### 2. Hide Old Products (Don't Delete Yet)
```sql
-- Soft delete old products
UPDATE products SET active = false;

-- Or rename table to archive
ALTER TABLE products RENAME TO products_old_archive;
```

#### 3. Remove Toggle
Once confident, remove the toggle and use only enhanced system

---

## 🎯 SAFE ROLLBACK PLAN

If anything goes wrong:

### Quick Rollback:
1. Switch toggle back to "Old System"
2. Everything continues working
3. No data lost

### Database Rollback:
```sql
-- If needed, restore old products
ALTER TABLE products_old_archive RENAME TO products;
UPDATE products SET active = true;
```

---

## 📋 MIGRATION CHECKLIST

### Today:
- [ ] Backup old products table
- [ ] Add 2-3 test products to enhanced
- [ ] Implement toggle component
- [ ] Test both systems work

### Tomorrow:
- [ ] Start adding real products to enhanced
- [ ] Test checkout with new products
- [ ] Verify price tiers working

### Launch Day:
- [ ] All products in enhanced system
- [ ] Website using enhanced table
- [ ] Archive old products table
- [ ] Remove toggle

---

## ✅ BENEFITS OF THIS APPROACH

1. **No Downtime** - Both systems run in parallel
2. **Easy Testing** - Toggle between systems instantly
3. **Clean Data** - Start fresh with accurate products
4. **Safe Rollback** - Can switch back anytime
5. **Gradual Migration** - Add products at your pace

---

## 🚀 IMMEDIATE ACTION

1. **Add the toggle component** (I can do this now)
2. **Test with a few products**
3. **Start adding real products** when ready
4. **Switch over** when comfortable

This gives you complete control over the migration with zero risk!