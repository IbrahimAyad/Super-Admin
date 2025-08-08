# KCT Menswear Real-Time Analytics System Integration Guide

## Overview

This guide provides complete instructions for implementing the KCT Menswear real-time analytics system, including database setup, frontend integration, and usage examples.

## 🗄️ Database Setup

### 1. Run SQL Migrations

Execute the following migrations in order:

```bash
# 1. Create analytics system tables
supabase db push --local # If using local development
# OR run the SQL files directly in Supabase dashboard:
# - supabase/migrations/050_create_analytics_system.sql
# - supabase/migrations/051_create_analytics_materialized_views.sql  
# - supabase/migrations/052_create_analytics_functions.sql
```

### 2. Verify Database Structure

```sql
-- Check if tables were created successfully
SELECT table_name FROM information_schema.tables 
WHERE table_schema = 'public' 
AND table_name LIKE '%analytics%';

-- Verify materialized views
SELECT matviewname FROM pg_matviews 
WHERE schemaname = 'public';

-- Check functions
SELECT routine_name FROM information_schema.routines 
WHERE routine_schema = 'public' 
AND routine_name LIKE '%analytics%';
```

### 3. Set up Automated Refresh (Optional)

If you have pg_cron extension available:

```sql
-- Refresh materialized views every 15 minutes
SELECT cron.schedule('refresh-analytics-views', '*/15 * * * *', 'SELECT refresh_analytics_views();');

-- Update daily summary every hour
SELECT cron.schedule('update-daily-summary', '0 * * * *', 'SELECT update_daily_analytics_summary();');
```

## 📊 Frontend Integration

### 1. Install Analytics Tracking

```typescript
// In your main App component or layout
import AnalyticsTracker from './lib/analytics/tracking';

// Initialize tracking
useEffect(() => {
  AnalyticsTracker.initialize({
    userId: user?.id,
    customerId: customer?.id,
    adminUserId: isAdmin ? user?.id : undefined,
    enabled: process.env.NODE_ENV === 'production' // Enable in production
  });
}, [user, customer, isAdmin]);
```

### 2. Track Page Views (Automatic)

The tracker automatically tracks page views when initialized. For manual tracking:

```typescript
// Manual page view tracking
AnalyticsTracker.trackPageView(window.location.pathname, document.title);
```

### 3. Track E-commerce Events

```typescript
// Product view
AnalyticsTracker.trackProductView(productId, {
  category: product.category,
  price: product.price,
  name: product.name
});

// Add to cart
AnalyticsTracker.trackAddToCart(productId, variantId, quantity, price);

// Remove from cart
AnalyticsTracker.trackRemoveFromCart(productId, variantId, quantity);

// Checkout start
AnalyticsTracker.trackCheckoutStart(orderId, cartTotal);

// Purchase completion
AnalyticsTracker.trackPurchase(orderId, totalAmount, orderItems);
```

### 4. Track Admin Actions

```typescript
// Admin login
AnalyticsTracker.trackAdminLogin();

// Admin actions
AnalyticsTracker.trackAdminAction('product_update', `product:${productId}`, {
  action: 'update',
  fields_changed: ['price', 'inventory']
});

// Bulk actions
AnalyticsTracker.trackAdminAction('bulk_export', 'orders', {
  export_type: 'csv',
  date_range: '30_days',
  record_count: 150
});
```

### 5. Track Customer Events

```typescript
// User registration
AnalyticsTracker.trackUserRegistration();

// User login
AnalyticsTracker.trackUserLogin();

// Search
AnalyticsTracker.trackSearch('mens suits', 25);

// Filter application
AnalyticsTracker.trackFilterApplied({
  category: 'suits',
  size: 'medium',
  color: 'navy',
  price_range: '200-500'
});
```

## 📈 Dashboard Integration

### 1. Add Analytics Dashboard to Admin

```typescript
// In your admin routes
import RealTimeDashboard from './components/analytics/RealTimeDashboard';

// Add to your router
<Route path="/admin/analytics" element={<RealTimeDashboard />} />
```

### 2. Custom Analytics Queries

```typescript
import DashboardAnalytics from './lib/analytics/dashboard-queries';

// Get revenue for different periods
const todayRevenue = await DashboardAnalytics.getRevenueMetrics('today');
const weekRevenue = await DashboardAnalytics.getRevenueMetrics('week');
const monthRevenue = await DashboardAnalytics.getRevenueMetrics('month');

// Get top products
const topProducts = await DashboardAnalytics.getTopProducts('revenue', 10, 30);

// Get real-time metrics
const realTimeMetrics = await DashboardAnalytics.getRealTimeWebsiteMetrics();

// Get customer analytics
const customerLTV = await DashboardAnalytics.getCustomerLTVAnalytics();
```

### 3. Custom Dashboard Widgets

```typescript
// Revenue widget
const RevenueWidget: React.FC = () => {
  const [revenue, setRevenue] = useState<RevenueMetrics | null>(null);

  useEffect(() => {
    const loadRevenue = async () => {
      const data = await DashboardAnalytics.getRevenueMetrics('today');
      setRevenue(data);
    };
    
    loadRevenue();
    const interval = setInterval(loadRevenue, 30000); // Refresh every 30s
    return () => clearInterval(interval);
  }, []);

  if (!revenue) return <div>Loading...</div>;

  return (
    <Card>
      <CardHeader>
        <CardTitle>Today's Revenue</CardTitle>
      </CardHeader>
      <CardContent>
        <div className="text-2xl font-bold">
          {DashboardAnalytics.formatCurrency(revenue.total_revenue)}
        </div>
        <p className="text-sm text-muted-foreground">
          {revenue.order_count} orders • {DashboardAnalytics.formatPercentage(revenue.conversion_rate)} conversion
        </p>
      </CardContent>
    </Card>
  );
};
```

## 🔍 Usage Examples

### E-commerce Website Integration

```typescript
// Product page component
const ProductPage: React.FC<{ productId: string }> = ({ productId }) => {
  useEffect(() => {
    // Track product view
    AnalyticsTracker.trackProductView(productId, {
      category: product.category,
      price: product.price,
      name: product.name,
      in_stock: product.inventory > 0
    });
  }, [productId]);

  const handleAddToCart = (variantId: string, quantity: number) => {
    // Your add to cart logic
    addToCart(productId, variantId, quantity);
    
    // Track the event
    AnalyticsTracker.trackAddToCart(productId, variantId, quantity, variant.price);
  };

  return (
    // Your product page JSX
  );
};
```

### Checkout Process Tracking

```typescript
// Checkout component
const CheckoutPage: React.FC = () => {
  useEffect(() => {
    // Track checkout start
    AnalyticsTracker.trackCheckoutStart(cart.id, cart.total);
  }, []);

  const handlePaymentSuccess = (orderId: string, amount: number) => {
    // Track successful purchase
    AnalyticsTracker.trackPurchase(orderId, amount, cart.items);
  };

  return (
    // Your checkout JSX
  );
};
```

### Admin Dashboard Integration

```typescript
// Admin product management
const ProductManagement: React.FC = () => {
  const handleBulkUpdate = async (productIds: string[], updates: any) => {
    try {
      // Your bulk update logic
      await bulkUpdateProducts(productIds, updates);
      
      // Track admin action
      AnalyticsTracker.trackAdminAction('bulk_update', 'products', {
        affected_count: productIds.length,
        update_fields: Object.keys(updates),
        success: true
      });
    } catch (error) {
      // Track failed action
      AnalyticsTracker.trackAdminAction('bulk_update', 'products', {
        affected_count: productIds.length,
        success: false,
        error: error.message
      });
    }
  };

  return (
    // Your admin interface JSX
  );
};
```

### Search and Navigation Tracking

```typescript
// Search component
const SearchBar: React.FC = () => {
  const handleSearch = async (query: string) => {
    const results = await searchProducts(query);
    
    // Track search
    AnalyticsTracker.trackSearch(query, results.length);
    
    return results;
  };

  return (
    // Your search JSX
  );
};

// Category filter component
const CategoryFilter: React.FC = () => {
  const handleFilterChange = (filters: any) => {
    // Apply filters
    applyFilters(filters);
    
    // Track filter application
    AnalyticsTracker.trackFilterApplied(filters);
  };

  return (
    // Your filter JSX
  );
};
```

## 📊 Dashboard Queries Reference

### Revenue Analytics

```typescript
// Basic revenue metrics
const revenue = await DashboardAnalytics.getRevenueMetrics('today');
console.log(revenue.total_revenue, revenue.order_count, revenue.conversion_rate);

// Revenue comparison with growth
const comparison = await DashboardAnalytics.getRevenueComparison();
console.log(comparison.growth.revenue); // % growth

// Hourly trend
const hourlyTrend = await DashboardAnalytics.getHourlyRevenueTrend();
```

### Product Analytics

```typescript
// Top products by different metrics
const topByRevenue = await DashboardAnalytics.getTopProducts('revenue', 10);
const topByViews = await DashboardAnalytics.getTopProducts('views', 10);
const topByConversions = await DashboardAnalytics.getTopProducts('conversions', 10);

// Product conversion funnel
const funnel = await DashboardAnalytics.getProductConversionFunnel(productId);
console.log(funnel.view_to_cart_rate, funnel.overall_conversion_rate);
```

### Customer Analytics

```typescript
// Customer lifetime value
const customerLTV = await DashboardAnalytics.getCustomerLTVAnalytics();
console.log(customerLTV.avg_ltv, customerLTV.ltv_segments);

// Real-time customer activity
const activity = await DashboardAnalytics.getRealTimeCustomerActivity(60);
console.log(activity.active_sessions, activity.recent_events);
```

### Traffic Analytics

```typescript
// Traffic sources
const sources = await DashboardAnalytics.getTrafficSourcePerformance(30);
sources.forEach(source => {
  console.log(source.source, source.conversion_rate, source.revenue);
});

// Real-time website metrics
const realTime = await DashboardAnalytics.getRealTimeWebsiteMetrics();
console.log(realTime.current_online_users, realTime.top_pages_now);
```

## 🔧 Performance Optimization

### 1. Database Optimization

```sql
-- Monitor slow queries
SELECT query, mean_exec_time, calls 
FROM pg_stat_statements 
ORDER BY mean_exec_time DESC 
LIMIT 10;

-- Check index usage
SELECT schemaname, tablename, indexname, idx_tup_read, idx_tup_fetch 
FROM pg_stat_user_indexes 
WHERE schemaname = 'public';
```

### 2. Materialized View Refresh Strategy

```typescript
// Refresh views periodically in your admin
const refreshAnalytics = async () => {
  const success = await DashboardAnalytics.refreshAnalyticsViews();
  if (success) {
    console.log('Analytics views refreshed successfully');
  }
};

// Call every 15 minutes
setInterval(refreshAnalytics, 15 * 60 * 1000);
```

### 3. Frontend Performance

```typescript
// Use React Query for caching
import { useQuery } from 'react-query';

const useRevenueMetrics = (period: string) => {
  return useQuery(
    ['revenue', period],
    () => DashboardAnalytics.getRevenueMetrics(period as any),
    {
      refetchInterval: 30000, // 30 seconds
      staleTime: 30000
    }
  );
};
```

## 🚀 Deployment Checklist

- [ ] SQL migrations applied to production database
- [ ] Materialized views created and indexed
- [ ] Analytics functions deployed
- [ ] Frontend tracking initialized
- [ ] Dashboard component integrated
- [ ] RLS policies configured for admin access
- [ ] Performance monitoring enabled
- [ ] Automated view refresh scheduled (optional)

## 📝 Monitoring and Maintenance

### 1. Check Analytics Health

```sql
-- Check recent events
SELECT COUNT(*), event_category 
FROM analytics_events 
WHERE created_at >= NOW() - INTERVAL '1 hour' 
GROUP BY event_category;

-- Check materialized view freshness
SELECT matviewname, last_refresh 
FROM pg_stat_user_tables 
WHERE relname LIKE 'mv_%';
```

### 2. Performance Metrics

```sql
-- Check table sizes
SELECT schemaname, tablename, pg_size_pretty(pg_total_relation_size(schemaname||'.'||tablename)) as size
FROM pg_tables 
WHERE schemaname = 'public' 
AND tablename LIKE '%analytics%'
ORDER BY pg_total_relation_size(schemaname||'.'||tablename) DESC;
```

This analytics system provides comprehensive real-time tracking and reporting for KCT Menswear with sub-second query performance through optimized indexes and materialized views.