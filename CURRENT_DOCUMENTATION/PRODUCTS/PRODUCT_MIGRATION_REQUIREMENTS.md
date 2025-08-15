# Product System Migration Requirements

## Executive Summary

The product system requires **focused fixes, not a complete overhaul**. The core infrastructure is solid, but data quality issues, image URL problems, and Stripe sync gaps need immediate attention. This document outlines the specific migration requirements to transform the current system into a production-ready e-commerce platform.

## 🎯 Migration Scope

### What Needs Migration ❌
1. **Stripe Product Sync**: 246 products need syncing to Stripe
2. **Image URL Standardization**: Fix bucket URL mismatches for 183 products
3. **Duplicate Product Cleanup**: Remove 209+ duplicate velvet blazers
4. **Admin Panel Schema Alignment**: Fix form field mismatches
5. **Missing Inventory System**: Add inventory table and functionality

### What Does NOT Need Migration ✅
- ✅ **Core Database Schema**: Products, variants, orders tables are solid
- ✅ **Customer Management**: Fully implemented and working
- ✅ **Order Processing**: Complete order lifecycle management exists
- ✅ **Email System**: Production-ready email infrastructure
- ✅ **Authentication & Security**: Enterprise-level security implemented
- ✅ **Analytics & Reporting**: Comprehensive analytics system exists

## 📋 Phase 1: Critical Revenue Fixes (Week 1)

### 1.1 Complete Stripe Product Sync ⚡ URGENT
**Objective**: Enable all 274 products to be purchasable

**Current State**:
- 28 products synced to Stripe (10.2% coverage)
- 246 products cannot be purchased
- Stripe sync infrastructure exists but incomplete

**Migration Tasks**:
```bash
# 1. Run bulk Stripe sync
./scripts/sync-products-to-stripe.ts

# 2. Verify sync coverage  
SELECT COUNT(*) as total, 
       COUNT(stripe_product_id) as synced,
       ROUND(COUNT(stripe_product_id) * 100.0 / COUNT(*), 1) as percentage
FROM products;

# 3. Create missing price variants for all sizes
# 4. Test checkout flow for newly synced products
```

**Success Criteria**:
- [ ] 100% of active products have `stripe_product_id`
- [ ] All product variants have `stripe_price_id`
- [ ] Checkout works for all product categories
- [ ] Stripe dashboard shows 274 products

**Time Estimate**: 2-3 hours (mostly automated)
**Business Impact**: Immediate revenue recovery

### 1.2 Fix Image URL Bucket Mapping ⚡ URGENT
**Objective**: Fix broken product images (183 products affected)

**Current State**:
- THREE different R2 buckets in use
- Incorrect bucket mapping causing 404 image errors
- 67% of products show placeholder images

**Migration Tasks**:
```sql
-- Fix batch images using wrong bucket
UPDATE products 
SET primary_image = REPLACE(
  primary_image,
  'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/batch_1/',
  'https://pub-5cd8c531c0034986bf6282a223bd0564.r2.dev/batch_1/'
)
WHERE primary_image LIKE '%pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/batch_1/%';

-- Fix product_images table
UPDATE product_images 
SET image_url = REPLACE(
  image_url,
  'https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/batch_1/',
  'https://pub-5cd8c531c0034986bf6282a223bd0564.r2.dev/batch_1/'
)
WHERE image_url LIKE '%pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/batch_1/%';

-- Remove placeholder images where real images exist
-- (Manual verification required)
```

**Success Criteria**:
- [ ] All `/batch_1/` images use correct bucket URL
- [ ] No products show placeholder when real images exist
- [ ] Image loading success rate >95%
- [ ] Admin panel displays all product images correctly

**Time Estimate**: 2-4 hours
**Business Impact**: Improved customer experience and conversion

## 📋 Phase 2: Data Quality Cleanup (Week 2)

### 2.1 Remove Duplicate Products 🧹
**Objective**: Clean up 209+ duplicate products cluttering the database

**Current State**:
- Multiple velvet blazers with identical names but different IDs
- Duplicates created during multiple CSV imports
- Confusing admin panel with duplicate listings

**Migration Strategy**:
```sql
-- Identify duplicates (keep oldest)
WITH duplicates AS (
  SELECT name, MIN(created_at) as keep_date, COUNT(*) as count
  FROM products
  GROUP BY name
  HAVING COUNT(*) > 1
)
SELECT p.id, p.name, p.created_at, d.count
FROM products p
INNER JOIN duplicates d ON p.name = d.name
WHERE p.created_at > d.keep_date
ORDER BY d.count DESC, p.name;

-- Delete newer duplicates (after verification)
DELETE FROM products
WHERE id IN (
  -- List of verified duplicate IDs
);
```

**Success Criteria**:
- [ ] Each product name appears only once
- [ ] ~150-200 unique products remain (not 274)
- [ ] All Stripe integrations preserved for kept products
- [ ] Admin panel shows clean product listings

**Time Estimate**: 4-6 hours (includes manual verification)
**Business Impact**: Simplified product management

### 2.2 Standardize Product Categories 📊
**Objective**: Fix inconsistent category naming

**Current Issues**:
- "Blazers" vs "Blazer"
- Inconsistent capitalization
- Mixed naming conventions

**Migration Tasks**:
```sql
-- Standardize category names
UPDATE products SET category = 'Luxury Velvet Blazers' 
WHERE category IN ('Velvet Blazers', 'velvet blazers', 'Velvet Blazer');

UPDATE products SET category = 'Men''s Suits'
WHERE category IN ('Suits', 'suits', 'Men Suits');

-- Full category standardization script needed
```

**Success Criteria**:
- [ ] Consistent category naming across all products
- [ ] Category filter works properly in admin panel
- [ ] Analytics reports use standardized categories

## 📋 Phase 3: Admin Panel Fixes (Week 3)

### 3.1 Fix Product Form Schema Mismatch 🔧
**Objective**: Align admin panel forms with actual database schema

**Current Issues**:
- Form expects fields that don't exist in database
- Update operations fail due to schema mismatches
- Complex interfaces not matching simple database structure

**Migration Tasks**:
```typescript
// Simplify ProductForm interface to match database
interface ProductFormData {
  // ✅ Keep (these exist in database)
  name: string;
  description: string;
  category: string;
  sku: string;
  handle: string; // NOT url_slug
  base_price: number;
  status: 'active' | 'inactive' | 'archived';
  is_bundleable: boolean;
  primary_image: string;
  
  // ❌ Remove (these don't exist)
  // product_type, materials, care_instructions, 
  // fit_type, occasion, features, meta_title, meta_description
}
```

**Success Criteria**:
- [ ] Product creation form submits successfully
- [ ] Product updates complete without errors
- [ ] Form validation matches database constraints
- [ ] No more "column does not exist" errors

**Time Estimate**: 6-8 hours
**Business Impact**: Functional admin panel for product management

### 3.2 Implement Missing Inventory System 📦
**Objective**: Add inventory management functionality expected by admin panel

**Current State**:
- Admin panel imports inventory functions but table doesn't exist
- No stock tracking capability
- Variant management incomplete

**Migration Tasks**:
```sql
-- Create inventory table
CREATE TABLE inventory (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  product_variant_id UUID NOT NULL REFERENCES product_variants(id) ON DELETE CASCADE,
  quantity_available INTEGER NOT NULL DEFAULT 0,
  quantity_reserved INTEGER DEFAULT 0,
  quantity_sold INTEGER DEFAULT 0,
  reorder_point INTEGER DEFAULT 5,
  last_restock_date DATE,
  cost_per_unit INTEGER, -- Cost in CENTS
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Add inventory tracking to variants
ALTER TABLE product_variants 
ADD COLUMN IF NOT EXISTS inventory_quantity INTEGER DEFAULT 0,
ADD COLUMN IF NOT EXISTS low_stock_threshold INTEGER DEFAULT 5;

-- Create inventory management functions
CREATE OR REPLACE FUNCTION update_inventory_quantity(
  variant_id UUID,
  quantity_change INTEGER
) RETURNS BOOLEAN;
```

**Success Criteria**:
- [ ] Inventory table exists and functions
- [ ] Admin panel inventory management works
- [ ] Stock levels tracked per variant
- [ ] Low stock alerts functional

**Time Estimate**: 8-12 hours
**Business Impact**: Proper inventory management capability

## 📋 Phase 4: Production Hardening (Week 4)

### 4.1 Automated Stripe Sync 🔄
**Objective**: Implement automatic Stripe sync on product changes

**Current State**:
- Manual Stripe sync required for new products
- No automatic sync on product updates
- Sync failures not handled gracefully

**Migration Tasks**:
```typescript
// Add Stripe sync triggers
- Product creation → automatic Stripe product creation
- Product update → automatic Stripe product update  
- Variant creation → automatic Stripe price creation
- Status changes → Stripe product activation/deactivation

// Error handling and retry logic
- Failed sync retry mechanism
- Admin notification on sync failures
- Bulk re-sync tools for failed products
```

**Success Criteria**:
- [ ] New products automatically sync to Stripe
- [ ] Product updates reflect in Stripe immediately
- [ ] Failed syncs are retried automatically
- [ ] Admin alerts for persistent sync failures

### 4.2 Image Management Optimization 📸
**Objective**: Streamline image upload and management

**Current Issues**:
- Upload attempts go to Supabase storage instead of R2
- Manual URL entry required
- No automatic bucket selection

**Migration Tasks**:
```typescript
// Implement smart image upload
- Auto-detect product category
- Select appropriate R2 bucket based on category
- Direct upload to correct bucket
- Automatic URL generation and database update

// Image management tools
- Bulk image validation
- Broken image detection and replacement
- Image optimization pipeline
```

**Success Criteria**:
- [ ] Image uploads work directly from admin panel
- [ ] Correct bucket selected automatically
- [ ] No manual URL entry required
- [ ] Bulk image management tools available

## 📋 Phase 5: Performance & Monitoring (Week 5)

### 5.1 Performance Optimization 🚀
**Objective**: Optimize database queries and admin panel performance

**Migration Tasks**:
```sql
-- Add missing indexes for common queries
CREATE INDEX CONCURRENTLY idx_products_category_status 
ON products(category, status) WHERE status = 'active';

CREATE INDEX CONCURRENTLY idx_product_variants_product_id_active
ON product_variants(product_id) WHERE stripe_active = true;

-- Optimize materialized views refresh
REFRESH MATERIALIZED VIEW CONCURRENTLY product_performance;
REFRESH MATERIALIZED VIEW CONCURRENTLY customer_analytics;
```

### 5.2 Monitoring & Alerting 📊
**Objective**: Implement production monitoring for the product system

**Migration Tasks**:
- Set up product sync monitoring
- Image load failure alerting
- Database performance monitoring
- Admin panel error tracking

## 🔍 Migration Validation

### Pre-Migration Checklist
- [ ] Complete database backup
- [ ] Verify Stripe API credentials
- [ ] Test R2 bucket access
- [ ] Admin panel access confirmed
- [ ] Document current product count and categories

### Post-Migration Validation
```sql
-- Product system health check
SELECT 
  COUNT(*) as total_products,
  COUNT(stripe_product_id) as stripe_synced,
  COUNT(CASE WHEN primary_image NOT LIKE '%placeholder%' THEN 1 END) as real_images,
  COUNT(DISTINCT category) as categories
FROM products
WHERE status = 'active';

-- Verify no duplicate names
SELECT name, COUNT(*) as count
FROM products
GROUP BY name
HAVING COUNT(*) > 1;

-- Check image URL validity
SELECT 
  CASE 
    WHEN primary_image LIKE '%pub-8ea0502158a94b8ca8a7abb9e18a57e8%' THEN 'Bucket 1'
    WHEN primary_image LIKE '%pub-5cd8c531c0034986bf6282a223bd0564%' THEN 'Bucket 2'
    WHEN primary_image LIKE '%placeholder%' THEN 'Placeholder'
    ELSE 'Other'
  END as image_source,
  COUNT(*) as count
FROM products
GROUP BY image_source;
```

## 📊 Success Metrics

### Immediate Success (Week 1)
- **Revenue**: 100% of products purchasable (vs 10% current)
- **Images**: <5% placeholder images (vs 67% current)
- **Admin UX**: 95% form success rate (vs 20% current)

### Medium-term Success (Week 4)
- **Data Quality**: Zero duplicate products
- **Performance**: <2s admin panel load times
- **Reliability**: 99% Stripe sync success rate

### Long-term Success (Month 3)
- **Automation**: Zero manual intervention for product management
- **Scalability**: System handles 1000+ products efficiently
- **Maintainability**: Clean, documented, and monitored system

## 🚨 Risk Mitigation

### High Risks
1. **Data Loss During Cleanup**: Comprehensive backups before any deletions
2. **Stripe Sync Failures**: Rate limiting and retry mechanisms
3. **Image URL Breakage**: Validation before bulk updates
4. **Admin Panel Downtime**: Staged deployment and rollback plans

### Contingency Plans
- **Rollback Scripts**: For each migration phase
- **Data Recovery**: Point-in-time database restoration
- **Service Degradation**: Fallback to manual processes
- **Communication Plan**: Stakeholder updates on any issues

---

**Last Updated**: August 14, 2025  
**Priority**: Critical - Required for production readiness  
**Estimated Total Time**: 3-4 weeks with proper planning  
**Business Impact**: Transforms system from 10% functional to 100% production-ready