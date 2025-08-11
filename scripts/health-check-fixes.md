# System Health Check - Safe Optimizations Guide

## 🚨 CRITICAL FIXES (Do Immediately)

### 1. Security Vulnerabilities
Run these commands to fix security issues:
```bash
npm audit fix
npm audit fix --force  # Only if needed
```

### 2. Remove Hardcoded Stripe Key
The Stripe key is hardcoded in `src/lib/services/stripeSync.ts` line 412.
This should use the environment variable instead.

### 3. ESLint Configuration
Create `eslint.config.js` for ESLint v9 compatibility.

## ⚠️ HIGH PRIORITY OPTIMIZATIONS

### 4. Large Component Files to Refactor
- `ProductManagement.tsx` (2,699 lines) - Break into smaller components
- `CustomerManagementOptimized.tsx` (1,177 lines) - Already optimized but could be split
- `ManualOrderCreation.tsx` (1,066 lines) - Split into sub-components
- `SettingsManagement.tsx` (1,022 lines) - Modularize settings sections

### 5. Environment Variables Needed
Move these hardcoded values to .env:
- Email addresses (support@kctmenswear.com, admin@kctmenswear.com)
- API endpoints (TaxJar URL)
- Default image URLs

## 📊 PERFORMANCE OPTIMIZATIONS

### 6. Database Indexes (Already Applied)
✅ Customer indexes
✅ Product indexes
✅ Order indexes
✅ Inventory indexes

### 7. Component Optimizations Needed
- Add React.memo to heavy components
- Use useMemo for expensive calculations
- Implement virtual scrolling for large lists
- Add debouncing to search inputs (already done in most places)

## 🔧 CODE QUALITY IMPROVEMENTS

### 8. Console Statements
164+ console statements found. Consider:
- Using a logging service for production
- Removing debug statements
- Implementing conditional logging based on environment

### 9. Error Handling Pattern
Create a unified error handler hook:
```typescript
const useErrorHandler = () => {
  const { toast } = useToast();
  return (error: Error, context?: string) => {
    console.error(`Error in ${context}:`, error);
    toast({
      title: "Error",
      description: error.message,
      variant: "destructive"
    });
  };
};
```

### 10. Loading State Pattern
Create a unified loading hook:
```typescript
const useLoadingState = () => {
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<Error | null>(null);
  
  const execute = async (fn: () => Promise<void>) => {
    setLoading(true);
    setError(null);
    try {
      await fn();
    } catch (err) {
      setError(err as Error);
    } finally {
      setLoading(false);
    }
  };
  
  return { loading, error, execute };
};
```

## ✅ ALREADY OPTIMIZED
- Database indexes
- Image lazy loading
- Search debouncing
- Product caching
- Customer pagination
- Bulk operations
- Performance monitoring

## 📋 SAFE TO IMPLEMENT NOW
1. Run `npm audit fix`
2. Fix Stripe key hardcoding
3. Create ESLint config
4. Add custom hooks for common patterns
5. Split large components
6. Add React.memo to heavy components
7. Implement production logging

## 🚀 SYSTEM STATUS
- **Products**: 183 ✅
- **Customers**: 2,822 ✅
- **Inventory**: Tracked ✅
- **Orders**: Ready ✅
- **Performance**: Good, but can be improved
- **Security**: Needs immediate attention for Stripe key