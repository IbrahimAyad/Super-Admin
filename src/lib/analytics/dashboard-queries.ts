/**
 * KCT Menswear Dashboard Analytics Queries
 * TypeScript functions for retrieving real-time analytics data
 */

import { getSupabaseClient } from '../supabase/client';
import { logger } from '../../utils/logger';

// Types for analytics data
export interface RevenueMetrics {
  total_revenue: number;
  order_count: number;
  avg_order_value: number;
  conversion_rate: number;
  sessions: number;
  revenue_growth: number;
}

export interface OrderAnalytics {
  total_orders: number;
  completed_orders: number;
  pending_orders: number;
  cancelled_orders: number;
  avg_order_value: number;
  avg_items_per_order: number;
  top_payment_methods: any[];
  order_status_distribution: Record<string, number>;
  daily_order_trend: any[];
}

export interface ProductPerformance {
  product_id: string;
  product_name: string;
  category: string;
  price: number;
  metric_value: number;
  views: number;
  add_to_cart_count: number;
  orders: number;
  revenue: number;
  units_sold: number;
  conversion_rate: number;
}

export interface CustomerLTVAnalytics {
  total_customers: number;
  avg_ltv: number;
  ltv_segments: {
    high_value: number;
    medium_value: number;
    low_value: number;
  };
  top_customers: Array<{
    customer_id: string;
    lifetime_value: number;
    total_orders: number;
  }>;
  customer_retention: {
    repeat_customers: number;
    one_time_customers: number;
    avg_orders_per_customer: number;
    avg_customer_lifespan_days: number;
  };
}

export interface TrafficSource {
  source: string;
  sessions: number;
  users: number;
  page_views: number;
  avg_session_duration: number;
  bounce_rate: number;
  conversions: number;
  revenue: number;
  conversion_rate: number;
}

export interface RealTimeMetrics {
  current_online_users: number;
  page_views_last_hour: number;
  sessions_last_hour: number;
  top_pages_now: Array<{
    page_url: string;
    views: number;
  }>;
  active_countries: Array<{
    country: string;
    sessions: number;
  }>;
  device_breakdown: {
    desktop: number;
    mobile: number;
    tablet: number;
  };
  recent_conversions: Array<{
    created_at: string;
    revenue: number;
    customer_email?: string;
    product_name?: string;
  }>;
}

export interface AdminActivity {
  total_admin_actions: number;
  active_admins: number;
  top_actions: Array<{
    admin_action_type: string;
    action_count: number;
  }>;
  hourly_activity: Array<{
    hour: number;
    actions: number;
  }>;
  admin_performance: Array<{
    admin_user_id: string;
    action_count: number;
    unique_actions: number;
    last_active: string;
  }>;
}

export class DashboardAnalytics {
  private static supabase = getSupabaseClient();

  // =======================================================
  // REVENUE ANALYTICS
  // =======================================================

  static async getRevenueMetrics(
    periodType: 'today' | 'week' | 'month' | 'year' | 'custom' = 'today',
    startDate?: string,
    endDate?: string
  ): Promise<RevenueMetrics | null> {
    try {
      const { data, error } = await this.supabase
        .rpc('get_revenue_metrics', {
          period_type: periodType,
          start_date: startDate || null,
          end_date: endDate || null
        });

      if (error) {
        logger.error('Error fetching revenue metrics:', error);
        return null;
      }

      return data?.[0] || null;
    } catch (error) {
      logger.error('Failed to fetch revenue metrics:', error);
      return null;
    }
  }

  static async getHourlyRevenueTrend(): Promise<Array<{
    hour: string;
    revenue: number;
    orders: number;
    sessions: number;
  }> | null> {
    try {
      const { data, error } = await this.supabase
        .rpc('get_hourly_revenue_trend');

      if (error) {
        logger.error('Error fetching hourly revenue trend:', error);
        return null;
      }

      return data || [];
    } catch (error) {
      logger.error('Failed to fetch hourly revenue trend:', error);
      return null;
    }
  }

  static async getRevenueComparison(): Promise<{
    current: RevenueMetrics;
    previous: RevenueMetrics;
    growth: {
      revenue: number;
      orders: number;
      sessions: number;
      conversion: number;
    };
  } | null> {
    try {
      const [currentPeriod, previousPeriod] = await Promise.all([
        this.getRevenueMetrics('today'),
        this.getRevenueMetrics('custom', 
          new Date(Date.now() - 24 * 60 * 60 * 1000).toISOString().split('T')[0],
          new Date().toISOString().split('T')[0]
        )
      ]);

      if (!currentPeriod || !previousPeriod) return null;

      return {
        current: currentPeriod,
        previous: previousPeriod,
        growth: {
          revenue: this.calculateGrowth(currentPeriod.total_revenue, previousPeriod.total_revenue),
          orders: this.calculateGrowth(currentPeriod.order_count, previousPeriod.order_count),
          sessions: this.calculateGrowth(currentPeriod.sessions, previousPeriod.sessions),
          conversion: this.calculateGrowth(currentPeriod.conversion_rate, previousPeriod.conversion_rate)
        }
      };
    } catch (error) {
      logger.error('Failed to fetch revenue comparison:', error);
      return null;
    }
  }

  // =======================================================
  // ORDER ANALYTICS
  // =======================================================

  static async getOrderAnalytics(daysBack: number = 30): Promise<OrderAnalytics | null> {
    try {
      const { data, error } = await this.supabase
        .rpc('get_order_analytics', { days_back: daysBack });

      if (error) {
        logger.error('Error fetching order analytics:', error);
        return null;
      }

      return data?.[0] || null;
    } catch (error) {
      logger.error('Failed to fetch order analytics:', error);
      return null;
    }
  }

  // =======================================================
  // PRODUCT PERFORMANCE
  // =======================================================

  static async getTopProducts(
    metricType: 'revenue' | 'views' | 'conversions' | 'units_sold' = 'revenue',
    limit: number = 10,
    daysBack: number = 30
  ): Promise<ProductPerformance[] | null> {
    try {
      const { data, error } = await this.supabase
        .rpc('get_top_products', {
          metric_type: metricType,
          limit_count: limit,
          days_back: daysBack
        });

      if (error) {
        logger.error('Error fetching top products:', error);
        return null;
      }

      return data || [];
    } catch (error) {
      logger.error('Failed to fetch top products:', error);
      return null;
    }
  }

  static async getProductConversionFunnel(
    productId: string,
    daysBack: number = 30
  ): Promise<{
    product_id: string;
    product_name: string;
    views: number;
    add_to_cart: number;
    checkout_starts: number;
    purchases: number;
    view_to_cart_rate: number;
    cart_to_checkout_rate: number;
    checkout_to_purchase_rate: number;
    overall_conversion_rate: number;
  } | null> {
    try {
      const { data, error } = await this.supabase
        .rpc('get_product_conversion_funnel', {
          input_product_id: productId,
          days_back: daysBack
        });

      if (error) {
        logger.error('Error fetching product conversion funnel:', error);
        return null;
      }

      return data?.[0] || null;
    } catch (error) {
      logger.error('Failed to fetch product conversion funnel:', error);
      return null;
    }
  }

  static async getProductPerformanceFromView(): Promise<any[] | null> {
    try {
      const { data, error } = await this.supabase
        .from('mv_product_performance')
        .select('*')
        .order('performance_score', { ascending: false })
        .limit(20);

      if (error) {
        logger.error('Error fetching product performance from view:', error);
        return null;
      }

      return data || [];
    } catch (error) {
      logger.error('Failed to fetch product performance from view:', error);
      return null;
    }
  }

  // =======================================================
  // CUSTOMER BEHAVIOR ANALYTICS
  // =======================================================

  static async getCustomerLTVAnalytics(): Promise<CustomerLTVAnalytics | null> {
    try {
      const { data, error } = await this.supabase
        .rpc('get_customer_ltv_analytics');

      if (error) {
        logger.error('Error fetching customer LTV analytics:', error);
        return null;
      }

      return data?.[0] || null;
    } catch (error) {
      logger.error('Failed to fetch customer LTV analytics:', error);
      return null;
    }
  }

  static async getCustomerBehaviorFromView(): Promise<any | null> {
    try {
      const { data, error } = await this.supabase
        .from('mv_customer_behavior')
        .select('*')
        .single();

      if (error) {
        logger.error('Error fetching customer behavior from view:', error);
        return null;
      }

      return data?.metrics || null;
    } catch (error) {
      logger.error('Failed to fetch customer behavior from view:', error);
      return null;
    }
  }

  static async getRealTimeCustomerActivity(minutesBack: number = 60): Promise<{
    active_sessions: number;
    active_customers: number;
    recent_events: any[];
    current_cart_value: number;
    conversion_events: number;
  } | null> {
    try {
      const { data, error } = await this.supabase
        .rpc('get_realtime_customer_activity', {
          minutes_back: minutesBack
        });

      if (error) {
        logger.error('Error fetching real-time customer activity:', error);
        return null;
      }

      return data?.[0] || null;
    } catch (error) {
      logger.error('Failed to fetch real-time customer activity:', error);
      return null;
    }
  }

  // =======================================================
  // TRAFFIC ANALYTICS
  // =======================================================

  static async getTrafficSourcePerformance(daysBack: number = 30): Promise<TrafficSource[] | null> {
    try {
      const { data, error } = await this.supabase
        .rpc('get_traffic_source_performance', {
          days_back: daysBack
        });

      if (error) {
        logger.error('Error fetching traffic source performance:', error);
        return null;
      }

      return data || [];
    } catch (error) {
      logger.error('Failed to fetch traffic source performance:', error);
      return null;
    }
  }

  static async getRealTimeWebsiteMetrics(): Promise<RealTimeMetrics | null> {
    try {
      const { data, error } = await this.supabase
        .rpc('get_realtime_website_metrics');

      if (error) {
        logger.error('Error fetching real-time website metrics:', error);
        return null;
      }

      return data?.[0] || null;
    } catch (error) {
      logger.error('Failed to fetch real-time website metrics:', error);
      return null;
    }
  }

  static async getTrafficMetricsFromView(): Promise<any | null> {
    try {
      const { data, error } = await this.supabase
        .from('mv_traffic_metrics')
        .select('*')
        .single();

      if (error) {
        logger.error('Error fetching traffic metrics from view:', error);
        return null;
      }

      return data?.traffic_data || null;
    } catch (error) {
      logger.error('Failed to fetch traffic metrics from view:', error);
      return null;
    }
  }

  // =======================================================
  // ADMIN ACTIVITY ANALYTICS
  // =======================================================

  static async getAdminActivityAnalytics(daysBack: number = 7): Promise<AdminActivity | null> {
    try {
      const { data, error } = await this.supabase
        .rpc('get_admin_activity_analytics', {
          days_back: daysBack
        });

      if (error) {
        logger.error('Error fetching admin activity analytics:', error);
        return null;
      }

      return data?.[0] || null;
    } catch (error) {
      logger.error('Failed to fetch admin activity analytics:', error);
      return null;
    }
  }

  // =======================================================
  // DAILY SUMMARY DATA
  // =======================================================

  static async getDailySummary(daysBack: number = 30): Promise<any[] | null> {
    try {
      const { data, error } = await this.supabase
        .from('daily_analytics_summary')
        .select('*')
        .gte('date', new Date(Date.now() - daysBack * 24 * 60 * 60 * 1000).toISOString().split('T')[0])
        .order('date', { ascending: false });

      if (error) {
        logger.error('Error fetching daily summary:', error);
        return null;
      }

      return data || [];
    } catch (error) {
      logger.error('Failed to fetch daily summary:', error);
      return null;
    }
  }

  // =======================================================
  // MATERIALIZED VIEW REFRESH
  // =======================================================

  static async refreshAnalyticsViews(): Promise<boolean> {
    try {
      const { error } = await this.supabase
        .rpc('refresh_analytics_views');

      if (error) {
        logger.error('Error refreshing analytics views:', error);
        return false;
      }

      return true;
    } catch (error) {
      logger.error('Failed to refresh analytics views:', error);
      return false;
    }
  }

  // =======================================================
  // CUSTOM QUERIES
  // =======================================================

  // Get dashboard overview data in a single call
  static async getDashboardOverview(): Promise<{
    revenue: RevenueMetrics | null;
    orders: OrderAnalytics | null;
    traffic: RealTimeMetrics | null;
    topProducts: ProductPerformance[] | null;
    customerActivity: any | null;
  }> {
    try {
      const [revenue, orders, traffic, topProducts, customerActivity] = await Promise.all([
        this.getRevenueMetrics('today'),
        this.getOrderAnalytics(7),
        this.getRealTimeWebsiteMetrics(),
        this.getTopProducts('revenue', 5, 7),
        this.getRealTimeCustomerActivity(60)
      ]);

      return {
        revenue,
        orders,
        traffic,
        topProducts,
        customerActivity
      };
    } catch (error) {
      logger.error('Failed to fetch dashboard overview:', error);
      return {
        revenue: null,
        orders: null,
        traffic: null,
        topProducts: null,
        customerActivity: null
      };
    }
  }

  // Search analytics events
  static async searchAnalyticsEvents(
    filters: {
      event_type?: string;
      event_category?: string;
      user_id?: string;
      product_id?: string;
      start_date?: string;
      end_date?: string;
    } = {},
    limit: number = 100
  ): Promise<any[] | null> {
    try {
      let query = this.supabase
        .from('analytics_events')
        .select('*')
        .order('created_at', { ascending: false })
        .limit(limit);

      if (filters.event_type) {
        query = query.eq('event_type', filters.event_type);
      }

      if (filters.event_category) {
        query = query.eq('event_category', filters.event_category);
      }

      if (filters.user_id) {
        query = query.eq('user_id', filters.user_id);
      }

      if (filters.product_id) {
        query = query.eq('product_id', filters.product_id);
      }

      if (filters.start_date) {
        query = query.gte('created_at', filters.start_date);
      }

      if (filters.end_date) {
        query = query.lte('created_at', filters.end_date);
      }

      const { data, error } = await query;

      if (error) {
        logger.error('Error searching analytics events:', error);
        return null;
      }

      return data || [];
    } catch (error) {
      logger.error('Failed to search analytics events:', error);
      return null;
    }
  }

  // =======================================================
  // UTILITY METHODS
  // =======================================================

  private static calculateGrowth(current: number, previous: number): number {
    if (previous === 0) return current > 0 ? 100 : 0;
    return Math.round(((current - previous) / previous) * 100 * 100) / 100;
  }

  // Format currency
  static formatCurrency(amount: number, currency: string = 'GBP'): string {
    return new Intl.NumberFormat('en-GB', {
      style: 'currency',
      currency: currency
    }).format(amount);
  }

  // Format percentage
  static formatPercentage(value: number, decimals: number = 2): string {
    return `${value.toFixed(decimals)}%`;
  }

  // Format number with commas
  static formatNumber(value: number): string {
    return new Intl.NumberFormat('en-GB').format(value);
  }
}

export default DashboardAnalytics;