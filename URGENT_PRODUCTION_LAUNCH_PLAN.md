# 🚨 URGENT: PRODUCTION LAUNCH ACTION PLAN
## Timeline: 2-3 Days to Production Ready

---

## ⛔ CRITICAL BLOCKERS (Day 1 - MUST FIX)

### 1. SECURITY VULNERABILITIES (4-6 hours)

#### 🔴 Issue #1: Hardcoded Credentials
**Files to fix:**
- `/src/lib/supabase-client.ts`
- All script files with SERVICE_ROLE_KEY
- `.env.example` (remove sensitive keys)

**Action:**
```typescript
// CHANGE FROM:
const supabaseUrl = 'https://gvcswimqaxvylgxbklbz.supabase.co';
const supabaseAnonKey = 'eyJhbGc...';

// CHANGE TO:
const supabaseUrl = import.meta.env.VITE_SUPABASE_URL;
const supabaseAnonKey = import.meta.env.VITE_SUPABASE_ANON_KEY;
```

#### 🔴 Issue #2: Rotate Keys
1. Go to Supabase Dashboard
2. Generate new anon key
3. Generate new service role key
4. Update Edge Functions secrets
5. Update local .env file

#### 🔴 Issue #3: Fix CORS
**Edge Functions to update:**
- All functions in `/supabase/functions/`

```typescript
// CHANGE FROM:
'Access-Control-Allow-Origin': '*'

// CHANGE TO:
'Access-Control-Allow-Origin': process.env.ALLOWED_ORIGINS || 'https://kctmenswear.com'
```

---

## 🟠 HIGH PRIORITY FIXES (Day 1-2)

### 2. FUNCTIONALITY COMPLETION (2-3 hours)

#### Issue #4: Complete Product Form
**File:** `/src/components/admin/EnhancedProductManagement.tsx`
- Implement full product creation/edit form
- Add image upload functionality
- Add validation

#### Issue #5: Verify Stripe Webhooks
**Files:** 
- `/supabase/functions/stripe-webhook-secure/`
- Verify signature validation is working

### 3. DATA CLEANUP (2-3 hours)

#### Check Product Data:
```sql
-- Run these checks in Supabase SQL Editor
-- 1. Find products without price tiers
SELECT COUNT(*) as missing_tiers FROM products_enhanced 
WHERE price_tier IS NULL OR price_tier = '';

-- 2. Find products without images
SELECT COUNT(*) as missing_images FROM products_enhanced 
WHERE images IS NULL OR images = '{}';

-- 3. Find duplicate SKUs
SELECT sku, COUNT(*) as count FROM products_enhanced 
GROUP BY sku HAVING COUNT(*) > 1;

-- 4. Verify Stripe product sync status
SELECT 
  COUNT(*) as total,
  COUNT(stripe_product_id) as synced,
  COUNT(*) - COUNT(stripe_product_id) as needs_sync
FROM products_enhanced;
```

---

## 🟡 CLEANUP TASKS (Day 2)

### 4. CODE CLEANUP (1-2 hours)

#### Remove Debug Code:
```bash
# Find all console.log statements
grep -r "console.log" src/

# Find all TODO comments
grep -r "TODO" src/

# Find unused imports (use ESLint)
npm run lint
```

#### Files to clean:
- Remove all test/debug files
- Clean up migration SQL files
- Remove `.env.example` with sensitive data

### 5. PERFORMANCE OPTIMIZATION (1-2 hours)

#### Bundle Size:
```bash
# Check bundle size
npm run build
# Look at dist folder size

# Analyze bundle
npm run build -- --analyze
```

#### Database Optimization:
```sql
-- Add missing indexes
CREATE INDEX IF NOT EXISTS idx_products_status_tier 
ON products_enhanced(status, price_tier);

-- Vacuum and analyze
VACUUM ANALYZE products_enhanced;
```

---

## ✅ PRE-LAUNCH TESTING (Day 2-3)

### 6. END-TO-END TESTING

#### Test Checkout Flows:
1. **Standard Checkout**
   - Add product to cart
   - Complete checkout
   - Verify order created
   - Check admin panel

2. **Chat Checkout**
   - Open chat widget
   - Search for product
   - Complete purchase
   - Verify order synced

#### Test Admin Functions:
- [ ] Product creation
- [ ] Product editing
- [ ] Order management
- [ ] Stripe sync
- [ ] Bulk operations

### 7. PRODUCTION CONFIGURATION

#### Environment Setup:
```bash
# Production .env file
VITE_SUPABASE_URL=https://gvcswimqaxvylgxbklbz.supabase.co
VITE_SUPABASE_ANON_KEY=new_anon_key_here
VITE_STRIPE_PUBLISHABLE_KEY=pk_live_xxx

# Never commit this file!
```

#### Supabase Settings:
1. Set allowed URLs for authentication
2. Configure CORS for your domain
3. Enable RLS on all tables
4. Set up database backups

---

## 📋 LAUNCH DAY CHECKLIST

### Pre-Launch (Day 3):
- [ ] All security fixes completed
- [ ] All tests passing
- [ ] Backup database
- [ ] Monitor setup ready
- [ ] Support team briefed

### Launch Steps:
1. **Deploy Admin Panel**
   ```bash
   npm run build
   # Deploy to hosting service
   ```

2. **Verify Edge Functions**
   ```bash
   npx supabase functions list
   # All should show "Active"
   ```

3. **Enable Production Mode**
   - Switch Stripe to live mode
   - Update DNS records
   - Enable SSL certificates

### Post-Launch Monitoring:
- [ ] Watch error logs
- [ ] Monitor checkout success rate
- [ ] Check order processing
- [ ] Review performance metrics

---

## 🎯 IMMEDIATE ACTIONS (DO NOW)

### Step 1: Fix Security (1 hour)
```bash
# 1. Create new .env file
cp .env.example .env.production

# 2. Remove sensitive data from .env.example
echo "VITE_SUPABASE_URL=your_url_here" > .env.example
echo "VITE_SUPABASE_ANON_KEY=your_key_here" >> .env.example

# 3. Update supabase-client.ts
# Use environment variables instead of hardcoded values

# 4. Commit security fixes
git add -A
git commit -m "SECURITY: Remove hardcoded credentials"
```

### Step 2: Rotate Keys (30 minutes)
1. Go to: https://supabase.com/dashboard/project/gvcswimqaxvylgxbklbz/settings/api
2. Regenerate anon key
3. Regenerate service role key
4. Update all .env files
5. Update Edge Function secrets

### Step 3: Test Everything (1 hour)
```bash
# Test locally with new keys
npm run dev

# Test checkout
# Test admin panel
# Test chat widget
```

---

## 📊 LAUNCH SUCCESS METRICS

### Day 1 Goals:
- 0 security vulnerabilities
- 100% checkout success rate
- <3s page load time

### Week 1 Goals:
- 50+ successful orders
- <1% error rate
- 95% uptime

### Month 1 Goals:
- 500+ orders processed
- 15-25% chat conversion rate
- Positive customer feedback

---

## 🚀 YOU'RE 2-3 DAYS FROM LAUNCH!

**Priority Order:**
1. **TODAY**: Fix security issues (4-6 hours)
2. **TOMORROW**: Complete functionality & testing (4-6 hours)
3. **DAY 3**: Final testing & deploy (2-4 hours)

**Total estimated work:** 10-16 hours of focused effort

The system is 85% ready. Focus on security first, then functionality, then optimization. You can launch with confidence once security is fixed!