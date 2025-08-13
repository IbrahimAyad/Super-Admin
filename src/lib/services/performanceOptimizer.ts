/**
 * Performance Optimizer for KCT Menswear E-commerce Platform
 * Automated performance tracking, analysis, and optimization recommendations
 */

import { getSupabaseClient } from '@/lib/supabase/client';
import { logger } from './monitoring';

// Performance metrics interfaces
export interface PerformanceMetric {
  id: string;
  metric_name: string;
  metric_value: number;
  metric_unit: string;
  threshold_warning: number;
  threshold_critical: number;
  timestamp: string;
  metadata?: Record<string, any>;
}

export interface PerformanceAnalysis {
  overall_score: number;
  category_scores: {
    database: number;
    frontend: number;
    api: number;
    business: number;
  };
  recommendations: PerformanceRecommendation[];
  critical_issues: string[];
  optimization_opportunities: string[];
}

export interface PerformanceRecommendation {
  id: string;
  category: 'database' | 'frontend' | 'api' | 'business';
  priority: 'high' | 'medium' | 'low';
  title: string;
  description: string;
  impact_estimate: string;
  implementation_effort: 'easy' | 'medium' | 'hard';
  sql_query?: string;
  code_changes?: string[];
  monitoring_metric?: string;
}

export interface QueryPerformanceMetrics {
  query_hash: string;
  query_text: string;
  avg_execution_time: number;
  max_execution_time: number;
  calls_count: number;
  total_time: number;
  cache_hit_ratio: number;
  optimization_potential: number;
}

export interface BusinessPerformanceMetrics {
  conversion_rate: number;
  cart_abandonment_rate: number;
  page_load_time: number;
  api_response_time: number;
  revenue_per_visitor: number;
  customer_satisfaction_score: number;
}

export class PerformanceOptimizer {
  private supabase = getSupabaseClient();
  
  // Performance thresholds
  private readonly THRESHOLDS = {
    database: {
      query_time_warning: 100,    // ms
      query_time_critical: 500,   // ms
      cache_hit_warning: 90,      // %
      cache_hit_critical: 80,     // %
      connection_warning: 70,     // %
      connection_critical: 85,    // %
    },
    frontend: {
      page_load_warning: 3000,    // ms
      page_load_critical: 5000,   // ms
      bundle_size_warning: 500,   // KB
      bundle_size_critical: 1000, // KB
      fcp_warning: 1500,          // ms (First Contentful Paint)
      fcp_critical: 2500,         // ms
    },
    api: {
      response_time_warning: 200,  // ms
      response_time_critical: 500, // ms
      error_rate_warning: 1,       // %
      error_rate_critical: 3,      // %
      throughput_warning: 100,     // requests/min
    },
    business: {
      conversion_warning: 2,       // %
      conversion_critical: 1,      // %
      cart_abandonment_warning: 70, // %
      cart_abandonment_critical: 80, // %
      revenue_drop_warning: 10,    // %
      revenue_drop_critical: 20,   // %
    }
  };

  /**
   * Collect comprehensive performance metrics
   */
  async collectPerformanceMetrics(): Promise<void> {
    try {
      logger.info('Starting performance metrics collection');

      // Collect database metrics
      await this.collectDatabaseMetrics();
      
      // Collect API metrics
      await this.collectAPIMetrics();
      
      // Collect business metrics
      await this.collectBusinessMetrics();
      
      // Analyze and store recommendations
      await this.generateRecommendations();

      logger.info('Performance metrics collection completed');
    } catch (error) {
      logger.error('Failed to collect performance metrics:', error);
      throw error;
    }
  }

  /**
   * Collect database performance metrics
   */
  private async collectDatabaseMetrics(): Promise<void> {
    try {
      // Get database size and growth
      const { data: dbSize } = await this.supabase.rpc('get_database_size_metrics');
      
      // Get slow queries
      const { data: slowQueries } = await this.supabase.rpc('get_slow_queries_analysis');
      
      // Get connection metrics
      const { data: connections } = await this.supabase.rpc('get_connection_metrics');
      
      // Get cache performance
      const { data: cacheMetrics } = await this.supabase.rpc('get_cache_performance');

      // Store metrics
      const metrics = [
        {
          metric_name: 'database_size_gb',
          metric_value: dbSize?.[0]?.size_gb || 0,
          metric_unit: 'GB',
          threshold_warning: 10,
          threshold_critical: 50
        },
        {
          metric_name: 'active_connections',
          metric_value: connections?.[0]?.active_count || 0,
          metric_unit: 'count',
          threshold_warning: this.THRESHOLDS.database.connection_warning,
          threshold_critical: this.THRESHOLDS.database.connection_critical
        },
        {
          metric_name: 'cache_hit_ratio',
          metric_value: cacheMetrics?.[0]?.hit_ratio || 0,
          metric_unit: 'percent',
          threshold_warning: this.THRESHOLDS.database.cache_hit_warning,
          threshold_critical: this.THRESHOLDS.database.cache_hit_critical
        }
      ];

      await this.storeMetrics(metrics, 'database');
    } catch (error) {
      logger.error('Failed to collect database metrics:', error);
    }
  }

  /**
   * Collect API performance metrics
   */
  private async collectAPIMetrics(): Promise<void> {
    try {
      // Get API response times from performance logs
      const { data: apiMetrics } = await this.supabase
        .from('performance_logs')
        .select('endpoint, response_time_ms, status_code')
        .gte('timestamp', new Date(Date.now() - 60 * 60 * 1000).toISOString())
        .order('timestamp', { ascending: false })
        .limit(1000);

      if (!apiMetrics || apiMetrics.length === 0) return;

      // Calculate average response times by endpoint
      const endpointMetrics = apiMetrics.reduce((acc, log) => {
        const endpoint = log.endpoint || 'unknown';
        if (!acc[endpoint]) {
          acc[endpoint] = { times: [], errors: 0, total: 0 };
        }
        acc[endpoint].times.push(log.response_time_ms);
        acc[endpoint].total++;
        if (log.status_code >= 400) {
          acc[endpoint].errors++;
        }
        return acc;
      }, {} as Record<string, any>);

      // Store API performance metrics
      const metrics = Object.entries(endpointMetrics).map(([endpoint, data]: [string, any]) => {
        const avgResponseTime = data.times.reduce((sum: number, time: number) => sum + time, 0) / data.times.length;
        const errorRate = (data.errors / data.total) * 100;

        return [
          {
            metric_name: `api_response_time_${endpoint.replace(/[^a-zA-Z0-9]/g, '_')}`,
            metric_value: avgResponseTime,
            metric_unit: 'ms',
            threshold_warning: this.THRESHOLDS.api.response_time_warning,
            threshold_critical: this.THRESHOLDS.api.response_time_critical,
            metadata: { endpoint, sample_size: data.total }
          },
          {
            metric_name: `api_error_rate_${endpoint.replace(/[^a-zA-Z0-9]/g, '_')}`,
            metric_value: errorRate,
            metric_unit: 'percent',
            threshold_warning: this.THRESHOLDS.api.error_rate_warning,
            threshold_critical: this.THRESHOLDS.api.error_rate_critical,
            metadata: { endpoint, total_requests: data.total, errors: data.errors }
          }
        ];
      }).flat();

      await this.storeMetrics(metrics, 'api');
    } catch (error) {
      logger.error('Failed to collect API metrics:', error);
    }
  }

  /**
   * Collect business performance metrics
   */
  private async collectBusinessMetrics(): Promise<void> {
    try {
      // Get order conversion metrics
      const { data: conversionData } = await this.supabase.rpc('get_conversion_metrics');
      
      // Get cart abandonment rate
      const { data: cartData } = await this.supabase.rpc('get_cart_abandonment_rate');
      
      // Get revenue per visitor
      const { data: revenueData } = await this.supabase.rpc('get_revenue_per_visitor');

      const metrics = [
        {
          metric_name: 'conversion_rate',
          metric_value: conversionData?.[0]?.conversion_rate || 0,
          metric_unit: 'percent',
          threshold_warning: this.THRESHOLDS.business.conversion_warning,
          threshold_critical: this.THRESHOLDS.business.conversion_critical
        },
        {
          metric_name: 'cart_abandonment_rate',
          metric_value: cartData?.[0]?.abandonment_rate || 0,
          metric_unit: 'percent',
          threshold_warning: this.THRESHOLDS.business.cart_abandonment_warning,
          threshold_critical: this.THRESHOLDS.business.cart_abandonment_critical
        },
        {
          metric_name: 'revenue_per_visitor',
          metric_value: revenueData?.[0]?.revenue_per_visitor || 0,
          metric_unit: 'gbp',
          threshold_warning: 50,
          threshold_critical: 25
        }
      ];

      await this.storeMetrics(metrics, 'business');
    } catch (error) {
      logger.error('Failed to collect business metrics:', error);
    }
  }

  /**
   * Store performance metrics
   */
  private async storeMetrics(metrics: any[], category: string): Promise<void> {
    try {
      const { error } = await this.supabase
        .from('performance_metrics')
        .insert(
          metrics.map(metric => ({
            ...metric,
            category,
            timestamp: new Date().toISOString()
          }))
        );

      if (error) throw error;
    } catch (error) {
      logger.error('Failed to store performance metrics:', error);
    }
  }

  /**
   * Generate optimization recommendations
   */
  async generateRecommendations(): Promise<PerformanceRecommendation[]> {
    try {
      const recommendations: PerformanceRecommendation[] = [];
      
      // Get recent metrics
      const { data: recentMetrics } = await this.supabase
        .from('performance_metrics')
        .select('*')
        .gte('timestamp', new Date(Date.now() - 60 * 60 * 1000).toISOString())
        .order('timestamp', { ascending: false });

      if (!recentMetrics) return recommendations;

      // Analyze database performance
      const dbRecommendations = await this.analyzeDatabasePerformance(recentMetrics);
      recommendations.push(...dbRecommendations);

      // Analyze API performance
      const apiRecommendations = await this.analyzeAPIPerformance(recentMetrics);
      recommendations.push(...apiRecommendations);

      // Analyze business performance
      const businessRecommendations = await this.analyzeBusinessPerformance(recentMetrics);
      recommendations.push(...businessRecommendations);

      // Store recommendations
      await this.storeRecommendations(recommendations);

      return recommendations;
    } catch (error) {
      logger.error('Failed to generate recommendations:', error);
      return [];
    }
  }

  /**
   * Analyze database performance and generate recommendations
   */
  private async analyzeDatabasePerformance(metrics: any[]): Promise<PerformanceRecommendation[]> {
    const recommendations: PerformanceRecommendation[] = [];
    
    // Check cache hit ratio
    const cacheMetric = metrics.find(m => m.metric_name === 'cache_hit_ratio');
    if (cacheMetric && cacheMetric.metric_value < this.THRESHOLDS.database.cache_hit_warning) {
      recommendations.push({
        id: `cache_hit_${Date.now()}`,
        category: 'database',
        priority: cacheMetric.metric_value < this.THRESHOLDS.database.cache_hit_critical ? 'high' : 'medium',
        title: 'Improve Database Cache Hit Ratio',
        description: `Cache hit ratio is ${cacheMetric.metric_value.toFixed(1)}%, which is below optimal levels. This indicates potential memory configuration issues or inefficient queries.`,
        impact_estimate: 'High - Can improve query response times by 30-50%',
        implementation_effort: 'medium',
        sql_query: `
          -- Analyze cache usage
          SELECT schemaname, tablename, heap_blks_read, heap_blks_hit,
                 heap_blks_hit * 100 / (heap_blks_hit + heap_blks_read) as hit_ratio
          FROM pg_statio_user_tables 
          WHERE heap_blks_read > 0
          ORDER BY hit_ratio ASC;
        `,
        code_changes: [
          'Increase shared_buffers in PostgreSQL configuration',
          'Add indexes for frequently queried columns',
          'Implement query result caching in application layer',
          'Review and optimize slow queries'
        ],
        monitoring_metric: 'cache_hit_ratio'
      });
    }

    // Check for connection usage
    const connectionMetric = metrics.find(m => m.metric_name === 'active_connections');
    if (connectionMetric && connectionMetric.metric_value > this.THRESHOLDS.database.connection_warning) {
      recommendations.push({
        id: `connections_${Date.now()}`,
        category: 'database',
        priority: connectionMetric.metric_value > this.THRESHOLDS.database.connection_critical ? 'high' : 'medium',
        title: 'Optimize Database Connection Usage',
        description: `Active connections are at ${connectionMetric.metric_value}%, approaching limits. This can lead to connection pool exhaustion.`,
        impact_estimate: 'Medium - Prevents connection timeouts and improves scalability',
        implementation_effort: 'easy',
        code_changes: [
          'Implement connection pooling with pgBouncer',
          'Review and optimize connection lifecycle in application',
          'Add connection monitoring and alerting',
          'Consider read replicas for read-heavy operations'
        ],
        monitoring_metric: 'active_connections'
      });
    }

    return recommendations;
  }

  /**
   * Analyze API performance and generate recommendations
   */
  private async analyzeAPIPerformance(metrics: any[]): Promise<PerformanceRecommendation[]> {
    const recommendations: PerformanceRecommendation[] = [];
    
    // Check for slow API endpoints
    const slowEndpoints = metrics.filter(m => 
      m.metric_name.startsWith('api_response_time_') && 
      m.metric_value > this.THRESHOLDS.api.response_time_warning
    );

    if (slowEndpoints.length > 0) {
      recommendations.push({
        id: `slow_api_${Date.now()}`,
        category: 'api',
        priority: slowEndpoints.some(e => e.metric_value > this.THRESHOLDS.api.response_time_critical) ? 'high' : 'medium',
        title: 'Optimize Slow API Endpoints',
        description: `Found ${slowEndpoints.length} API endpoints with response times above ${this.THRESHOLDS.api.response_time_warning}ms. Slow APIs impact user experience and conversion rates.`,
        impact_estimate: 'High - Can improve user experience and reduce bounce rate',
        implementation_effort: 'medium',
        code_changes: [
          'Add database query optimization for slow endpoints',
          'Implement response caching for frequently requested data',
          'Add pagination for large dataset endpoints',
          'Optimize serialization and data transformation',
          'Consider CDN for static content'
        ],
        monitoring_metric: 'api_response_time'
      });
    }

    // Check for high error rates
    const errorEndpoints = metrics.filter(m => 
      m.metric_name.startsWith('api_error_rate_') && 
      m.metric_value > this.THRESHOLDS.api.error_rate_warning
    );

    if (errorEndpoints.length > 0) {
      recommendations.push({
        id: `api_errors_${Date.now()}`,
        category: 'api',
        priority: 'high',
        title: 'Reduce API Error Rates',
        description: `Found ${errorEndpoints.length} API endpoints with error rates above ${this.THRESHOLDS.api.error_rate_warning}%. High error rates indicate system instability.`,
        impact_estimate: 'Critical - Affects system reliability and user trust',
        implementation_effort: 'hard',
        code_changes: [
          'Add comprehensive error handling and retry logic',
          'Implement circuit breaker pattern for external dependencies',
          'Add input validation and sanitization',
          'Improve error logging and monitoring',
          'Add graceful degradation for non-critical features'
        ],
        monitoring_metric: 'api_error_rate'
      });
    }

    return recommendations;
  }

  /**
   * Analyze business performance and generate recommendations
   */
  private async analyzeBusinessPerformance(metrics: any[]): Promise<PerformanceRecommendation[]> {
    const recommendations: PerformanceRecommendation[] = [];
    
    // Check conversion rate
    const conversionMetric = metrics.find(m => m.metric_name === 'conversion_rate');
    if (conversionMetric && conversionMetric.metric_value < this.THRESHOLDS.business.conversion_warning) {
      recommendations.push({
        id: `conversion_${Date.now()}`,
        category: 'business',
        priority: conversionMetric.metric_value < this.THRESHOLDS.business.conversion_critical ? 'high' : 'medium',
        title: 'Improve Conversion Rate',
        description: `Conversion rate is ${conversionMetric.metric_value.toFixed(2)}%, which is below industry standards. This directly impacts revenue generation.`,
        impact_estimate: 'Very High - Each 1% improvement can increase revenue by 10-20%',
        implementation_effort: 'medium',
        code_changes: [
          'Optimize checkout flow and reduce friction',
          'Implement abandoned cart recovery emails',
          'Add product recommendations and upselling',
          'Improve page load times and mobile experience',
          'A/B test different product page layouts',
          'Add customer reviews and trust signals'
        ],
        monitoring_metric: 'conversion_rate'
      });
    }

    // Check cart abandonment rate
    const cartAbandonmentMetric = metrics.find(m => m.metric_name === 'cart_abandonment_rate');
    if (cartAbandonmentMetric && cartAbandonmentMetric.metric_value > this.THRESHOLDS.business.cart_abandonment_warning) {
      recommendations.push({
        id: `cart_abandonment_${Date.now()}`,
        category: 'business',
        priority: 'high',
        title: 'Reduce Cart Abandonment Rate',
        description: `Cart abandonment rate is ${cartAbandonmentMetric.metric_value.toFixed(1)}%, indicating users are leaving during checkout process.`,
        impact_estimate: 'High - Reducing abandonment by 10% can increase revenue by 5-15%',
        implementation_effort: 'medium',
        code_changes: [
          'Simplify checkout process and reduce steps',
          'Add guest checkout option',
          'Display shipping costs and delivery times upfront',
          'Implement exit-intent popups with discounts',
          'Add multiple payment methods',
          'Improve checkout page load times',
          'Add progress indicators in checkout flow'
        ],
        monitoring_metric: 'cart_abandonment_rate'
      });
    }

    return recommendations;
  }

  /**
   * Store optimization recommendations
   */
  private async storeRecommendations(recommendations: PerformanceRecommendation[]): Promise<void> {
    try {
      const { error } = await this.supabase
        .from('performance_recommendations')
        .insert(
          recommendations.map(rec => ({
            ...rec,
            created_at: new Date().toISOString(),
            status: 'pending'
          }))
        );

      if (error) throw error;
    } catch (error) {
      logger.error('Failed to store recommendations:', error);
    }
  }

  /**
   * Get current performance analysis
   */
  async getPerformanceAnalysis(): Promise<PerformanceAnalysis> {
    try {
      // Get recent metrics
      const { data: metrics } = await this.supabase
        .from('performance_metrics')
        .select('*')
        .gte('timestamp', new Date(Date.now() - 60 * 60 * 1000).toISOString())
        .order('timestamp', { ascending: false });

      // Get recent recommendations
      const { data: recommendations } = await this.supabase
        .from('performance_recommendations')
        .select('*')
        .gte('created_at', new Date(Date.now() - 24 * 60 * 60 * 1000).toISOString())
        .eq('status', 'pending')
        .order('created_at', { ascending: false });

      // Calculate performance scores
      const categoryScores = this.calculateCategoryScores(metrics || []);
      const overallScore = Object.values(categoryScores).reduce((sum, score) => sum + score, 0) / 4;

      // Identify critical issues
      const criticalIssues = (recommendations || [])
        .filter(r => r.priority === 'high')
        .map(r => r.title);

      // Identify optimization opportunities
      const optimizationOpportunities = (recommendations || [])
        .filter(r => r.priority === 'medium')
        .map(r => r.title);

      return {
        overall_score: Math.round(overallScore),
        category_scores: categoryScores,
        recommendations: recommendations || [],
        critical_issues: criticalIssues,
        optimization_opportunities: optimizationOpportunities
      };
    } catch (error) {
      logger.error('Failed to get performance analysis:', error);
      return {
        overall_score: 0,
        category_scores: { database: 0, frontend: 0, api: 0, business: 0 },
        recommendations: [],
        critical_issues: [],
        optimization_opportunities: []
      };
    }
  }

  /**
   * Calculate performance scores by category
   */
  private calculateCategoryScores(metrics: any[]): PerformanceAnalysis['category_scores'] {
    const scores = { database: 100, frontend: 100, api: 100, business: 100 };

    metrics.forEach(metric => {
      let categoryScore = 100;
      
      // Calculate score based on thresholds
      if (metric.metric_value > metric.threshold_critical) {
        categoryScore = 30; // Critical issues
      } else if (metric.metric_value > metric.threshold_warning) {
        categoryScore = 60; // Warning issues
      }

      // Apply to category
      if (metric.category && scores[metric.category as keyof typeof scores] !== undefined) {
        scores[metric.category as keyof typeof scores] = Math.min(
          scores[metric.category as keyof typeof scores], 
          categoryScore
        );
      }
    });

    return scores;
  }

  /**
   * Get slow queries for optimization
   */
  async getSlowQueries(): Promise<QueryPerformanceMetrics[]> {
    try {
      const { data, error } = await this.supabase.rpc('get_slow_queries_detailed');
      
      if (error) throw error;
      
      return data || [];
    } catch (error) {
      logger.error('Failed to get slow queries:', error);
      return [];
    }
  }

  /**
   * Mark recommendation as implemented
   */
  async markRecommendationImplemented(recommendationId: string): Promise<void> {
    try {
      const { error } = await this.supabase
        .from('performance_recommendations')
        .update({ 
          status: 'implemented',
          implemented_at: new Date().toISOString()
        })
        .eq('id', recommendationId);

      if (error) throw error;
      
      logger.info('Recommendation marked as implemented:', { recommendationId });
    } catch (error) {
      logger.error('Failed to mark recommendation as implemented:', error);
    }
  }

  /**
   * Auto-optimize based on recommendations
   */
  async autoOptimize(): Promise<{ applied: string[], skipped: string[] }> {
    const applied: string[] = [];
    const skipped: string[] = [];

    try {
      // Get auto-applicable recommendations
      const { data: recommendations } = await this.supabase
        .from('performance_recommendations')
        .select('*')
        .eq('status', 'pending')
        .eq('implementation_effort', 'easy')
        .eq('priority', 'high');

      if (!recommendations) return { applied, skipped };

      for (const rec of recommendations) {
        try {
          // Apply automatic optimizations
          if (rec.sql_query) {
            // Execute optimization SQL if it's safe
            if (rec.sql_query.toLowerCase().includes('create index')) {
              await this.supabase.rpc('execute_safe_optimization', {
                sql_query: rec.sql_query
              });
              applied.push(rec.title);
              await this.markRecommendationImplemented(rec.id);
            } else {
              skipped.push(`${rec.title} (requires manual review)`);
            }
          } else {
            skipped.push(`${rec.title} (no automatic implementation)`);
          }
        } catch (error) {
          logger.error(`Failed to apply recommendation ${rec.id}:`, error);
          skipped.push(`${rec.title} (error during application)`);
        }
      }

      return { applied, skipped };
    } catch (error) {
      logger.error('Failed to auto-optimize:', error);
      return { applied, skipped };
    }
  }
}

// Export singleton instance
export const performanceOptimizer = new PerformanceOptimizer();