/**
 * Production Monitoring Dashboard for KCT Menswear
 * Real-time monitoring and analytics dashboard for production environment
 */

import React, { useState, useEffect, useCallback } from 'react';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card';
import { Badge } from '@/components/ui/badge';
import { Button } from '@/components/ui/button';
import { Alert, AlertDescription, AlertTitle } from '@/components/ui/alert';
import { Tabs, TabsContent, TabsList, TabsTrigger } from '@/components/ui/tabs';
import { Progress } from '@/components/ui/progress';
import { Separator } from '@/components/ui/separator';
import { 
  AlertCircle, 
  CheckCircle, 
  TrendingUp, 
  TrendingDown, 
  Activity, 
  Database, 
  ShoppingCart, 
  Users, 
  DollarSign,
  Package,
  Clock,
  Wifi,
  AlertTriangle,
  RefreshCw,
  BarChart3,
  PieChart,
  LineChart
} from 'lucide-react';
import { getSupabaseClient } from '@/lib/supabase/client';
import { logger } from '@/lib/services/monitoring';

// Types
interface SystemHealthMetrics {
  overall_status: 'healthy' | 'warning' | 'critical';
  database_size_bytes: number;
  active_connections: number;
  max_connections: number;
  connection_usage_percent: number;
  cache_hit_ratio: number;
  error_rate_percent: number;
  orders_per_minute: number;
  revenue_per_hour: number;
  timestamp: string;
}

interface BusinessMetrics {
  date: string;
  daily_revenue: number;
  daily_orders: number;
  avg_order_value: number;
  new_customers: number;
  returning_customers: number;
  avg_conversion_rate: number;
  page_views: number;
  unique_visitors: number;
}

interface Alert {
  id: string;
  alert_type: string;
  severity: 'critical' | 'warning' | 'info';
  title: string;
  message: string;
  triggered_at: string;
  resolved_at?: string;
  current_value?: number;
  threshold_value?: number;
}

interface ProductPerformance {
  id: string;
  name: string;
  category: string;
  units_sold: number;
  revenue: number;
  current_stock: number;
  stock_status: 'in_stock' | 'low_stock' | 'out_of_stock';
  performance_score: number;
}

interface DashboardOverview {
  system_status: string;
  active_connections: number;
  cache_hit_ratio: number;
  error_rate: number;
  critical_alerts: number;
  warning_alerts: number;
  todays_revenue: number;
  todays_orders: number;
  inventory_alerts: number;
  recent_payment_failures: number;
}

export const ProductionMonitoringDashboard: React.FC = () => {
  const [isLoading, setIsLoading] = useState(true);
  const [lastUpdated, setLastUpdated] = useState<Date>(new Date());
  const [autoRefresh, setAutoRefresh] = useState(true);
  
  // Data states
  const [overview, setOverview] = useState<DashboardOverview | null>(null);
  const [systemHealth, setSystemHealth] = useState<SystemHealthMetrics | null>(null);
  const [businessMetrics, setBusinessMetrics] = useState<BusinessMetrics[]>([]);
  const [alerts, setAlerts] = useState<Alert[]>([]);
  const [productPerformance, setProductPerformance] = useState<ProductPerformance[]>([]);
  
  const supabase = getSupabaseClient();

  // Fetch dashboard overview
  const fetchOverview = useCallback(async () => {
    try {
      const { data, error } = await supabase
        .from('v_system_dashboard')
        .select('*')
        .single();

      if (error) throw error;
      setOverview(data);
    } catch (error) {
      logger.error('Failed to fetch dashboard overview:', error);
    }
  }, [supabase]);

  // Fetch system health metrics
  const fetchSystemHealth = useCallback(async () => {
    try {
      const { data, error } = await supabase
        .from('system_health_metrics')
        .select('*')
        .order('timestamp', { ascending: false })
        .limit(1)
        .single();

      if (error) throw error;
      setSystemHealth(data);
    } catch (error) {
      logger.error('Failed to fetch system health:', error);
    }
  }, [supabase]);

  // Fetch business metrics
  const fetchBusinessMetrics = useCallback(async () => {
    try {
      const { data, error } = await supabase
        .from('v_business_dashboard')
        .select('*')
        .order('date', { ascending: false })
        .limit(7);

      if (error) throw error;
      setBusinessMetrics(data || []);
    } catch (error) {
      logger.error('Failed to fetch business metrics:', error);
    }
  }, [supabase]);

  // Fetch active alerts
  const fetchAlerts = useCallback(async () => {
    try {
      const { data, error } = await supabase
        .from('monitoring_alerts')
        .select('*')
        .is('resolved_at', null)
        .order('triggered_at', { ascending: false })
        .limit(20);

      if (error) throw error;
      setAlerts(data || []);
    } catch (error) {
      logger.error('Failed to fetch alerts:', error);
    }
  }, [supabase]);

  // Fetch product performance
  const fetchProductPerformance = useCallback(async () => {
    try {
      const { data, error } = await supabase
        .from('v_product_performance')
        .select('*')
        .order('performance_score', { ascending: false })
        .limit(10);

      if (error) throw error;
      setProductPerformance(data || []);
    } catch (error) {
      logger.error('Failed to fetch product performance:', error);
    }
  }, [supabase]);

  // Fetch all data
  const fetchAllData = useCallback(async () => {
    setIsLoading(true);
    try {
      await Promise.all([
        fetchOverview(),
        fetchSystemHealth(),
        fetchBusinessMetrics(),
        fetchAlerts(),
        fetchProductPerformance()
      ]);
      setLastUpdated(new Date());
    } catch (error) {
      logger.error('Failed to fetch dashboard data:', error);
    } finally {
      setIsLoading(false);
    }
  }, [fetchOverview, fetchSystemHealth, fetchBusinessMetrics, fetchAlerts, fetchProductPerformance]);

  // Auto-refresh effect
  useEffect(() => {
    fetchAllData();
    
    if (autoRefresh) {
      const interval = setInterval(fetchAllData, 30000); // Refresh every 30 seconds
      return () => clearInterval(interval);
    }
  }, [fetchAllData, autoRefresh]);

  // Utility functions
  const formatCurrency = (amount: number) => {
    return new Intl.NumberFormat('en-GB', {
      style: 'currency',
      currency: 'GBP'
    }).format(amount);
  };

  const formatNumber = (num: number) => {
    return new Intl.NumberFormat('en-GB').format(num);
  };

  const formatBytes = (bytes: number) => {
    const sizes = ['Bytes', 'KB', 'MB', 'GB', 'TB'];
    if (bytes === 0) return '0 Bytes';
    const i = Math.floor(Math.log(bytes) / Math.log(1024));
    return Math.round(bytes / Math.pow(1024, i) * 100) / 100 + ' ' + sizes[i];
  };

  const getStatusColor = (status: string) => {
    switch (status) {
      case 'healthy': return 'text-green-600';
      case 'warning': return 'text-yellow-600';
      case 'critical': return 'text-red-600';
      default: return 'text-gray-600';
    }
  };

  const getSeverityColor = (severity: string) => {
    switch (severity) {
      case 'critical': return 'bg-red-100 text-red-800 border-red-200';
      case 'warning': return 'bg-yellow-100 text-yellow-800 border-yellow-200';
      case 'info': return 'bg-blue-100 text-blue-800 border-blue-200';
      default: return 'bg-gray-100 text-gray-800 border-gray-200';
    }
  };

  const getStockStatusColor = (status: string) => {
    switch (status) {
      case 'in_stock': return 'bg-green-100 text-green-800';
      case 'low_stock': return 'bg-yellow-100 text-yellow-800';
      case 'out_of_stock': return 'bg-red-100 text-red-800';
      default: return 'bg-gray-100 text-gray-800';
    }
  };

  if (isLoading) {
    return (
      <div className="flex items-center justify-center h-96">
        <div className="text-center">
          <RefreshCw className="h-8 w-8 animate-spin mx-auto mb-4" />
          <p>Loading production monitoring dashboard...</p>
        </div>
      </div>
    );
  }

  return (
    <div className="space-y-6">
      {/* Header */}
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-3xl font-bold tracking-tight">Production Monitoring</h1>
          <p className="text-gray-600">Real-time system and business analytics</p>
        </div>
        <div className="flex items-center gap-4">
          <div className="text-sm text-gray-500">
            Last updated: {lastUpdated.toLocaleTimeString()}
          </div>
          <Button
            variant="outline"
            size="sm"
            onClick={fetchAllData}
            disabled={isLoading}
          >
            <RefreshCw className={`h-4 w-4 mr-2 ${isLoading ? 'animate-spin' : ''}`} />
            Refresh
          </Button>
          <Button
            variant={autoRefresh ? "default" : "outline"}
            size="sm"
            onClick={() => setAutoRefresh(!autoRefresh)}
          >
            <Wifi className="h-4 w-4 mr-2" />
            Auto-refresh
          </Button>
        </div>
      </div>

      {/* System Status Overview */}
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6">
        <Card>
          <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
            <CardTitle className="text-sm font-medium">System Status</CardTitle>
            <Activity className="h-4 w-4 text-gray-600" />
          </CardHeader>
          <CardContent>
            <div className="flex items-center space-x-2">
              {overview?.system_status === 'healthy' ? (
                <CheckCircle className="h-5 w-5 text-green-600" />
              ) : (
                <AlertCircle className="h-5 w-5 text-red-600" />
              )}
              <span className={`text-lg font-semibold capitalize ${getStatusColor(overview?.system_status || 'unknown')}`}>
                {overview?.system_status || 'Unknown'}
              </span>
            </div>
            <p className="text-xs text-gray-600 mt-1">
              {overview?.cache_hit_ratio?.toFixed(1)}% cache hit ratio
            </p>
          </CardContent>
        </Card>

        <Card>
          <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
            <CardTitle className="text-sm font-medium">Today's Revenue</CardTitle>
            <DollarSign className="h-4 w-4 text-gray-600" />
          </CardHeader>
          <CardContent>
            <div className="text-2xl font-bold">
              {formatCurrency(overview?.todays_revenue || 0)}
            </div>
            <p className="text-xs text-gray-600">
              {formatNumber(overview?.todays_orders || 0)} orders
            </p>
          </CardContent>
        </Card>

        <Card>
          <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
            <CardTitle className="text-sm font-medium">Active Alerts</CardTitle>
            <AlertTriangle className="h-4 w-4 text-gray-600" />
          </CardHeader>
          <CardContent>
            <div className="flex items-center space-x-4">
              <div className="text-center">
                <div className="text-lg font-bold text-red-600">
                  {overview?.critical_alerts || 0}
                </div>
                <div className="text-xs text-gray-600">Critical</div>
              </div>
              <div className="text-center">
                <div className="text-lg font-bold text-yellow-600">
                  {overview?.warning_alerts || 0}
                </div>
                <div className="text-xs text-gray-600">Warning</div>
              </div>
            </div>
          </CardContent>
        </Card>

        <Card>
          <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
            <CardTitle className="text-sm font-medium">Database Health</CardTitle>
            <Database className="h-4 w-4 text-gray-600" />
          </CardHeader>
          <CardContent>
            <div className="space-y-2">
              <div className="flex justify-between text-sm">
                <span>Connections</span>
                <span>{overview?.active_connections || 0}</span>
              </div>
              <Progress 
                value={systemHealth?.connection_usage_percent || 0} 
                className="h-2"
              />
              <div className="text-xs text-gray-600">
                {systemHealth?.connection_usage_percent?.toFixed(1)}% usage
              </div>
            </div>
          </CardContent>
        </Card>
      </div>

      {/* Main Dashboard Tabs */}
      <Tabs defaultValue="overview" className="space-y-6">
        <TabsList className="grid w-full grid-cols-5">
          <TabsTrigger value="overview">Overview</TabsTrigger>
          <TabsTrigger value="alerts">Alerts</TabsTrigger>
          <TabsTrigger value="business">Business</TabsTrigger>
          <TabsTrigger value="performance">Performance</TabsTrigger>
          <TabsTrigger value="products">Products</TabsTrigger>
        </TabsList>

        {/* Overview Tab */}
        <TabsContent value="overview" className="space-y-6">
          <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
            {/* System Health Details */}
            <Card>
              <CardHeader>
                <CardTitle>System Health Metrics</CardTitle>
                <CardDescription>Real-time system performance indicators</CardDescription>
              </CardHeader>
              <CardContent className="space-y-4">
                {systemHealth && (
                  <>
                    <div className="grid grid-cols-2 gap-4">
                      <div>
                        <div className="text-sm font-medium">Database Size</div>
                        <div className="text-lg">{formatBytes(systemHealth.database_size_bytes)}</div>
                      </div>
                      <div>
                        <div className="text-sm font-medium">Error Rate</div>
                        <div className="text-lg">{systemHealth.error_rate_percent.toFixed(2)}%</div>
                      </div>
                      <div>
                        <div className="text-sm font-medium">Orders/Min</div>
                        <div className="text-lg">{systemHealth.orders_per_minute.toFixed(1)}</div>
                      </div>
                      <div>
                        <div className="text-sm font-medium">Revenue/Hour</div>
                        <div className="text-lg">{formatCurrency(systemHealth.revenue_per_hour)}</div>
                      </div>
                    </div>
                    
                    <Separator />
                    
                    <div className="space-y-2">
                      <div className="flex justify-between text-sm">
                        <span>Cache Hit Ratio</span>
                        <span>{systemHealth.cache_hit_ratio.toFixed(1)}%</span>
                      </div>
                      <Progress value={systemHealth.cache_hit_ratio} className="h-2" />
                    </div>
                  </>
                )}
              </CardContent>
            </Card>

            {/* Business Metrics Summary */}
            <Card>
              <CardHeader>
                <CardTitle>Business Metrics (7 Days)</CardTitle>
                <CardDescription>Key performance indicators</CardDescription>
              </CardHeader>
              <CardContent>
                {businessMetrics.length > 0 && (
                  <div className="space-y-4">
                    <div className="grid grid-cols-2 gap-4">
                      <div>
                        <div className="text-sm font-medium">Total Revenue</div>
                        <div className="text-lg font-bold">
                          {formatCurrency(businessMetrics.reduce((sum, m) => sum + m.daily_revenue, 0))}
                        </div>
                      </div>
                      <div>
                        <div className="text-sm font-medium">Total Orders</div>
                        <div className="text-lg font-bold">
                          {formatNumber(businessMetrics.reduce((sum, m) => sum + m.daily_orders, 0))}
                        </div>
                      </div>
                      <div>
                        <div className="text-sm font-medium">Avg Order Value</div>
                        <div className="text-lg">
                          {formatCurrency(businessMetrics.reduce((sum, m) => sum + m.avg_order_value, 0) / businessMetrics.length)}
                        </div>
                      </div>
                      <div>
                        <div className="text-sm font-medium">New Customers</div>
                        <div className="text-lg">
                          {formatNumber(businessMetrics.reduce((sum, m) => sum + m.new_customers, 0))}
                        </div>
                      </div>
                    </div>
                    
                    <Separator />
                    
                    <div className="text-xs text-gray-600">
                      Data from {businessMetrics[businessMetrics.length - 1]?.date} to {businessMetrics[0]?.date}
                    </div>
                  </div>
                )}
              </CardContent>
            </Card>
          </div>
        </TabsContent>

        {/* Alerts Tab */}
        <TabsContent value="alerts" className="space-y-4">
          {alerts.length === 0 ? (
            <Card>
              <CardContent className="flex flex-col items-center justify-center h-48">
                <CheckCircle className="h-12 w-12 text-green-600 mb-4" />
                <h3 className="text-lg font-medium">No Active Alerts</h3>
                <p className="text-gray-600">All systems are operating normally</p>
              </CardContent>
            </Card>
          ) : (
            <div className="space-y-3">
              {alerts.map((alert) => (
                <Alert key={alert.id} className={getSeverityColor(alert.severity)}>
                  <AlertCircle className="h-4 w-4" />
                  <AlertTitle className="flex items-center justify-between">
                    <span>{alert.title}</span>
                    <Badge variant="outline" className={getSeverityColor(alert.severity)}>
                      {alert.severity}
                    </Badge>
                  </AlertTitle>
                  <AlertDescription>
                    <p>{alert.message}</p>
                    {alert.current_value && alert.threshold_value && (
                      <p className="text-xs mt-1">
                        Current: {alert.current_value} | Threshold: {alert.threshold_value}
                      </p>
                    )}
                    <p className="text-xs text-gray-600 mt-1">
                      Triggered: {new Date(alert.triggered_at).toLocaleString()}
                    </p>
                  </AlertDescription>
                </Alert>
              ))}
            </div>
          )}
        </TabsContent>

        {/* Business Tab */}
        <TabsContent value="business" className="space-y-6">
          <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
            <Card>
              <CardHeader>
                <CardTitle>Revenue Trend</CardTitle>
              </CardHeader>
              <CardContent>
                <div className="space-y-2">
                  {businessMetrics.slice(0, 7).map((metric, index) => (
                    <div key={metric.date} className="flex justify-between items-center">
                      <span className="text-sm">{new Date(metric.date).toLocaleDateString()}</span>
                      <span className="font-medium">{formatCurrency(metric.daily_revenue)}</span>
                    </div>
                  ))}
                </div>
              </CardContent>
            </Card>

            <Card>
              <CardHeader>
                <CardTitle>Customer Metrics</CardTitle>
              </CardHeader>
              <CardContent>
                <div className="space-y-4">
                  <div>
                    <div className="text-sm font-medium">New vs Returning (7 days)</div>
                    <div className="flex justify-between mt-1">
                      <span>New: {businessMetrics.reduce((sum, m) => sum + m.new_customers, 0)}</span>
                      <span>Returning: {businessMetrics.reduce((sum, m) => sum + m.returning_customers, 0)}</span>
                    </div>
                  </div>
                  <div>
                    <div className="text-sm font-medium">Avg Conversion Rate</div>
                    <div className="text-lg">
                      {((businessMetrics.reduce((sum, m) => sum + m.avg_conversion_rate, 0) / businessMetrics.length) || 0).toFixed(2)}%
                    </div>
                  </div>
                </div>
              </CardContent>
            </Card>

            <Card>
              <CardHeader>
                <CardTitle>Traffic Overview</CardTitle>
              </CardHeader>
              <CardContent>
                <div className="space-y-4">
                  <div>
                    <div className="text-sm font-medium">Page Views (7 days)</div>
                    <div className="text-lg">{formatNumber(businessMetrics.reduce((sum, m) => sum + m.page_views, 0))}</div>
                  </div>
                  <div>
                    <div className="text-sm font-medium">Unique Visitors</div>
                    <div className="text-lg">{formatNumber(businessMetrics.reduce((sum, m) => sum + m.unique_visitors, 0))}</div>
                  </div>
                </div>
              </CardContent>
            </Card>
          </div>
        </TabsContent>

        {/* Performance Tab */}
        <TabsContent value="performance" className="space-y-6">
          <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
            <Card>
              <CardHeader>
                <CardTitle>Database Performance</CardTitle>
              </CardHeader>
              <CardContent>
                {systemHealth && (
                  <div className="space-y-4">
                    <div className="space-y-2">
                      <div className="flex justify-between text-sm">
                        <span>Connection Usage</span>
                        <span>{systemHealth.connection_usage_percent.toFixed(1)}%</span>
                      </div>
                      <Progress value={systemHealth.connection_usage_percent} className="h-2" />
                      <div className="text-xs text-gray-600">
                        {systemHealth.active_connections} / {systemHealth.max_connections} connections
                      </div>
                    </div>
                    
                    <div className="space-y-2">
                      <div className="flex justify-between text-sm">
                        <span>Cache Hit Ratio</span>
                        <span>{systemHealth.cache_hit_ratio.toFixed(1)}%</span>
                      </div>
                      <Progress value={systemHealth.cache_hit_ratio} className="h-2" />
                    </div>
                  </div>
                )}
              </CardContent>
            </Card>

            <Card>
              <CardHeader>
                <CardTitle>System Alerts Summary</CardTitle>
              </CardHeader>
              <CardContent>
                <div className="space-y-4">
                  <div className="flex items-center justify-between">
                    <span>Inventory Alerts</span>
                    <Badge variant={overview?.inventory_alerts ? "destructive" : "secondary"}>
                      {overview?.inventory_alerts || 0}
                    </Badge>
                  </div>
                  <div className="flex items-center justify-between">
                    <span>Payment Failures (1h)</span>
                    <Badge variant={overview?.recent_payment_failures ? "destructive" : "secondary"}>
                      {overview?.recent_payment_failures || 0}
                    </Badge>
                  </div>
                  <div className="flex items-center justify-between">
                    <span>System Error Rate</span>
                    <Badge variant={overview?.error_rate && overview.error_rate > 2 ? "destructive" : "secondary"}>
                      {overview?.error_rate?.toFixed(2)}%
                    </Badge>
                  </div>
                </div>
              </CardContent>
            </Card>
          </div>
        </TabsContent>

        {/* Products Tab */}
        <TabsContent value="products" className="space-y-6">
          <Card>
            <CardHeader>
              <CardTitle>Top Performing Products</CardTitle>
              <CardDescription>Based on performance score (revenue + sales volume)</CardDescription>
            </CardHeader>
            <CardContent>
              <div className="space-y-3">
                {productPerformance.map((product, index) => (
                  <div key={product.id} className="flex items-center justify-between p-3 border rounded-lg">
                    <div className="flex-1">
                      <div className="font-medium">{product.name}</div>
                      <div className="text-sm text-gray-600">{product.category}</div>
                    </div>
                    <div className="flex items-center space-x-4">
                      <div className="text-center">
                        <div className="text-sm font-medium">{formatNumber(product.units_sold)}</div>
                        <div className="text-xs text-gray-600">Units</div>
                      </div>
                      <div className="text-center">
                        <div className="text-sm font-medium">{formatCurrency(product.revenue)}</div>
                        <div className="text-xs text-gray-600">Revenue</div>
                      </div>
                      <div className="text-center">
                        <div className="text-sm font-medium">{product.current_stock}</div>
                        <div className="text-xs text-gray-600">Stock</div>
                      </div>
                      <Badge className={getStockStatusColor(product.stock_status)}>
                        {product.stock_status.replace('_', ' ')}
                      </Badge>
                    </div>
                  </div>
                ))}
              </div>
            </CardContent>
          </Card>
        </TabsContent>
      </Tabs>
    </div>
  );
};

export default ProductionMonitoringDashboard;