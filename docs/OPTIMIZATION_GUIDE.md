# Optimization Implementation Guide

This guide documents all optimizations implemented in the Super Admin dashboard and how to use them.

## Table of Contents
1. [Virtual Scrolling](#virtual-scrolling)
2. [Lazy Loading Routes](#lazy-loading-routes)
3. [Error Boundaries](#error-boundaries)
4. [Production Logging](#production-logging)
5. [Performance Hooks](#performance-hooks)
6. [React.memo Optimization](#reactmemo-optimization)

---

## Virtual Scrolling

### When to Use
Use virtual scrolling for lists with 100+ items to prevent DOM bloat.

### Implementation
```tsx
import { VirtualCustomerList } from '@/components/admin/VirtualCustomerList';

// In your component
<VirtualCustomerList
  customers={customers}
  selectedCustomers={selectedIds}
  onCustomerSelect={handleSelect}
  onCustomerAction={handleAction}
  searchTerm={searchTerm}
/>
```

### How It Works
- Only renders visible items + 5 overscan
- Reduces 2,822 DOM nodes to ~15
- Maintains scroll position during re-renders
- Supports dynamic item heights

### Creating New Virtual Lists
```tsx
import { useVirtualizer } from '@tanstack/react-virtual';

const MyVirtualList = ({ items }) => {
  const parentRef = useRef(null);
  
  const virtualizer = useVirtualizer({
    count: items.length,
    getScrollElement: () => parentRef.current,
    estimateSize: () => 100, // Estimated item height
    overscan: 5,
  });

  return (
    <div ref={parentRef} className="h-[600px] overflow-auto">
      <div style={{ height: `${virtualizer.getTotalSize()}px` }}>
        {virtualizer.getVirtualItems().map((virtualItem) => (
          <div
            key={virtualItem.key}
            style={{
              position: 'absolute',
              top: 0,
              left: 0,
              width: '100%',
              transform: `translateY(${virtualItem.start}px)`,
            }}
          >
            {/* Render your item */}
          </div>
        ))}
      </div>
    </div>
  );
};
```

---

## Lazy Loading Routes

### Setup
Use `App.lazy.tsx` instead of `App.tsx` for production builds.

### Adding New Routes
```tsx
// 1. Lazy load the component
const MyNewPage = lazy(() => import('./pages/MyNewPage'));

// 2. Add route with Suspense wrapper (automatic in App.lazy.tsx)
<Route path="/my-page" element={<MyNewPage />} />
```

### Custom Loading States
```tsx
const RouteLoadingFallback = () => (
  <div className="flex items-center justify-center min-h-screen">
    <YourCustomLoader />
  </div>
);
```

### Preloading Routes
```tsx
// Preload a route before user navigates
const preloadDashboard = () => {
  import('./pages/AdminDashboard');
};

// Call on hover or other trigger
<Link onMouseEnter={preloadDashboard} to="/admin">
  Dashboard
</Link>
```

---

## Error Boundaries

### Basic Usage
```tsx
import { RouteErrorBoundary } from '@/components/error/RouteErrorBoundary';

// Wrap components
<RouteErrorBoundary componentName="ProductList">
  <ProductList />
</RouteErrorBoundary>
```

### With Custom Fallback
```tsx
<RouteErrorBoundary 
  fallback={<div>Something went wrong. Please refresh.</div>}
  onError={(error, errorInfo) => {
    // Log to external service
    console.error('Component error:', error);
  }}
>
  <YourComponent />
</RouteErrorBoundary>
```

### Isolated Errors
For non-critical components that shouldn't break the page:
```tsx
<RouteErrorBoundary isolate={true}>
  <OptionalWidget />
</RouteErrorBoundary>
```

### HOC Pattern
```tsx
import { withErrorBoundary } from '@/components/error/RouteErrorBoundary';

const SafeComponent = withErrorBoundary(MyComponent, {
  componentName: 'MyComponent',
  resetKeys: ['userId'], // Reset on prop change
});
```

---

## Production Logging

### Basic Logging
```tsx
import { logger } from '@/utils/logger';

// Development only
logger.debug('Debug info', { data });

// All environments
logger.info('User action', { action: 'clicked' });
logger.warn('Warning', { issue: 'slow_query' });
logger.error('Error occurred', { error });
```

### Production Logger (with buffering)
```tsx
import { 
  productionLogger,
  logUserAction,
  logPerformance,
  logApiCall 
} from '@/lib/services/productionLogger';

// Log user actions
logUserAction('product_added', {
  productId: '123',
  name: 'Test Product'
});

// Log performance metrics
const startTime = performance.now();
// ... operation ...
logPerformance({
  name: 'database_query',
  duration: performance.now() - startTime,
  metadata: { query: 'SELECT * FROM products' }
});

// Log API calls
logApiCall('/api/products', 'POST', 201, 234);

// Set user context
productionLogger.setUserId(user.id);
```

### Database Logs
View logs in Supabase:
```sql
-- Recent errors
SELECT * FROM get_recent_errors(20);

-- Log statistics
SELECT * FROM get_log_statistics(
  NOW() - INTERVAL '7 days',
  NOW()
);

-- Search logs
SELECT * FROM application_logs
WHERE to_tsvector('english', message) @@ to_tsquery('error');
```

---

## Performance Hooks

### useLoadingState Hook
Replace repetitive loading patterns:

**Before:**
```tsx
const [loading, setLoading] = useState(false);
const [error, setError] = useState(null);

const fetchData = async () => {
  try {
    setLoading(true);
    setError(null);
    const data = await api.getData();
    // process data
  } catch (err) {
    setError(err.message);
    toast.error('Failed to load');
  } finally {
    setLoading(false);
  }
};
```

**After:**
```tsx
import { useLoadingState } from '@/hooks/useLoadingState';

const { loading, error, execute } = useLoadingState({
  context: 'ProductList',
  errorTitle: 'Failed to load products'
});

const fetchData = () => execute(async () => {
  const data = await api.getData();
  // process data
});
```

### useDebounce Hook
```tsx
import { useDebounce } from '@/hooks/useDebounce';

const SearchComponent = () => {
  const [searchTerm, setSearchTerm] = useState('');
  const debouncedSearch = useDebounce(searchTerm, 500);

  useEffect(() => {
    if (debouncedSearch) {
      // Perform search
    }
  }, [debouncedSearch]);
};
```

---

## React.memo Optimization

### Basic Memoization
```tsx
export const MyComponent = React.memo(({ data, onUpdate }) => {
  return <div>{/* Component content */}</div>;
});
```

### Custom Comparison
```tsx
export const ProductList = React.memo(
  ({ products, filters }) => {
    // Component implementation
  },
  (prevProps, nextProps) => {
    // Return true if props are equal (skip re-render)
    return (
      prevProps.products === nextProps.products &&
      JSON.stringify(prevProps.filters) === JSON.stringify(nextProps.filters)
    );
  }
);
```

### useCallback for Event Handlers
```tsx
const ParentComponent = () => {
  // Memoize callbacks to prevent child re-renders
  const handleClick = useCallback((id) => {
    // Handle click
  }, []); // Empty deps if function doesn't use props/state

  const handleUpdate = useCallback((id, data) => {
    // Handle update
  }, [currentUser]); // Include deps that function uses

  return (
    <MemoizedChild 
      onClick={handleClick}
      onUpdate={handleUpdate}
    />
  );
};
```

### useMemo for Expensive Calculations
```tsx
const ExpensiveComponent = ({ items, filters }) => {
  // Only recalculate when items or filters change
  const filteredItems = useMemo(() => {
    return items.filter(item => {
      // Expensive filtering logic
      return matchesAllFilters(item, filters);
    });
  }, [items, filters]);

  const stats = useMemo(() => {
    return calculateStatistics(filteredItems);
  }, [filteredItems]);

  return <div>{/* Render filtered items and stats */}</div>;
};
```

---

## Performance Best Practices

### 1. Identify Performance Issues
```tsx
// Use React DevTools Profiler
// Enable "Highlight Updates" to see re-renders
// Check the Profiler tab for render times
```

### 2. Measure Before Optimizing
```tsx
console.time('Operation');
// ... operation ...
console.timeEnd('Operation');

// Or use Performance API
performance.mark('myOperation-start');
// ... operation ...
performance.mark('myOperation-end');
performance.measure('myOperation', 'myOperation-start', 'myOperation-end');
```

### 3. Common Patterns

**Prevent Inline Functions:**
```tsx
// Bad - creates new function every render
<Button onClick={() => handleClick(id)}>Click</Button>

// Good - stable reference
const handleButtonClick = useCallback(() => {
  handleClick(id);
}, [id]);
<Button onClick={handleButtonClick}>Click</Button>
```

**Prevent Inline Objects:**
```tsx
// Bad - creates new object every render
<Component style={{ color: 'red' }} />

// Good - stable reference
const style = useMemo(() => ({ color: 'red' }), []);
<Component style={style} />
```

**Split Large Components:**
```tsx
// Instead of one 2000-line component
// Split into logical sub-components
<ProductFilters />
<ProductList />
<ProductForm />
```

---

## Monitoring Performance

### Development
```tsx
// Enable React strict mode warnings
<React.StrictMode>
  <App />
</React.StrictMode>

// Use React DevTools Profiler
// Chrome DevTools Performance tab
```

### Production
```tsx
// Monitor with production logger
import { logPerformance } from '@/lib/services/productionLogger';

// Track component mount time
useEffect(() => {
  const mountTime = performance.now();
  
  return () => {
    logPerformance({
      name: 'ComponentMount',
      duration: performance.now() - mountTime,
      metadata: { component: 'ProductList' }
    });
  };
}, []);
```

### Metrics to Track
- Time to Interactive (TTI)
- First Contentful Paint (FCP)
- Largest Contentful Paint (LCP)
- Component render times
- API response times
- Database query times

---

## Troubleshooting

### Virtual Scrolling Issues
- **Items jumping**: Ensure consistent `estimateSize`
- **Scroll position lost**: Add `key` to virtualizer
- **Performance issues**: Reduce `overscan` value

### Lazy Loading Issues
- **Flash of content**: Add better loading states
- **Route not found**: Check import path and default export
- **Slow loading**: Consider preloading critical routes

### Error Boundary Issues
- **Not catching errors**: Must be class component errors
- **Infinite loops**: Check `errorCount` logic
- **Missing errors**: Async errors need try/catch

### Performance Issues
- **Still slow**: Profile with React DevTools
- **Memory leaks**: Check useEffect cleanup
- **Re-renders**: Verify memo dependencies

---

## Additional Resources

- [React Performance Docs](https://react.dev/learn/render-and-commit)
- [TanStack Virtual Docs](https://tanstack.com/virtual/latest)
- [Web Vitals](https://web.dev/vitals/)
- [React DevTools](https://react.dev/learn/react-developer-tools)