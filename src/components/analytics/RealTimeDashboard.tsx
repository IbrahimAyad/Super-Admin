/**
 * KCT Menswear Real-Time Analytics Dashboard
 * Complete analytics dashboard with real-time updates
 */

import React, { useState, useEffect } from 'react';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '../ui/card';
import { Badge } from '../ui/badge';
import { Button } from '../ui/button';
import { Tabs, TabsContent, TabsList, TabsTrigger } from '../ui/tabs';
import { Progress } from '../ui/progress';
import { 
  TrendingUp, 
  TrendingDown, 
  Users, 
  ShoppingCart, 
  Eye, 
  CreditCard,
  Activity,
  Globe,
  Smartphone,
  Monitor,
  Tablet,
  RefreshCw
} from 'lucide-react';
import { LineChart, Line, XAxis, YAxis, CartesianGrid, Tooltip, ResponsiveContainer, BarChart, Bar, PieChart, Pie, Cell, AreaChart, Area } from 'recharts';
import DashboardAnalytics, { 
  RevenueMetrics, 
  OrderAnalytics, 
  ProductPerformance, 
  TrafficSource, 
  RealTimeMetrics 
} from '../../lib/analytics/dashboard-queries';

interface DashboardData {
  revenue: RevenueMetrics | null;
  orders: OrderAnalytics | null;
  traffic: RealTimeMetrics | null;
  topProducts: ProductPerformance[] | null;
  customerActivity: any | null;
  trafficSources: TrafficSource[] | null;
}

const COLORS = ['#0088FE', '#00C49F', '#FFBB28', '#FF8042', '#8884D8'];

const RealTimeDashboard: React.FC = () => {
  const [data, setData] = useState<DashboardData>({
    revenue: null,
    orders: null,
    traffic: null,
    topProducts: null,
    customerActivity: null,
    trafficSources: null
  });
  const [loading, setLoading] = useState(true);
  const [lastUpdated, setLastUpdated] = useState<Date>(new Date());
  const [autoRefresh, setAutoRefresh] = useState(true);
  const [selectedPeriod, setSelectedPeriod] = useState<'today' | 'week' | 'month'>('today');

  // Load dashboard data
  const loadDashboardData = async () => {
    try {
      setLoading(true);
      
      const [overview, trafficSources] = await Promise.all([
        DashboardAnalytics.getDashboardOverview(),
        DashboardAnalytics.getTrafficSourcePerformance(30)
      ]);

      setData({
        ...overview,
        trafficSources
      });
      
      setLastUpdated(new Date());
    } catch (error) {
      console.error('Failed to load dashboard data:', error);
    } finally {
      setLoading(false);
    }
  };

  // Auto-refresh every 30 seconds
  useEffect(() => {
    loadDashboardData();
    
    if (autoRefresh) {
      const interval = setInterval(loadDashboardData, 30000);
      return () => clearInterval(interval);
    }
  }, [autoRefresh, selectedPeriod]);

  // Format currency
  const formatCurrency = (amount: number) => DashboardAnalytics.formatCurrency(amount);
  const formatNumber = (value: number) => DashboardAnalytics.formatNumber(value);
  const formatPercentage = (value: number) => DashboardAnalytics.formatPercentage(value);

  // Metric card component
  const MetricCard: React.FC<{
    title: string;
    value: string | number;
    change?: number;
    icon: React.ReactNode;
    description?: string;
    trend?: 'up' | 'down' | 'neutral';
  }> = ({ title, value, change, icon, description, trend }) => (
    <Card>
      <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
        <CardTitle className="text-sm font-medium">{title}</CardTitle>
        {icon}
      </CardHeader>
      <CardContent>
        <div className="text-2xl font-bold">{value}</div>
        {change !== undefined && (
          <div className="flex items-center space-x-1 text-xs text-muted-foreground">
            {trend === 'up' ? (
              <TrendingUp className="h-4 w-4 text-green-500" />
            ) : trend === 'down' ? (
              <TrendingDown className="h-4 w-4 text-red-500" />
            ) : null}
            <span className={trend === 'up' ? 'text-green-500' : trend === 'down' ? 'text-red-500' : ''}>
              {change > 0 ? '+' : ''}{formatPercentage(change)}
            </span>
            <span>from yesterday</span>
          </div>
        )}
        {description && (
          <p className="text-xs text-muted-foreground">{description}</p>
        )}
      </CardContent>
    </Card>
  );

  // Loading skeleton
  if (loading && !data.revenue) {
    return (
      <div className="space-y-6 p-6">
        <div className="flex items-center justify-between">
          <h1 className="text-3xl font-bold">Analytics Dashboard</h1>
          <div className="flex items-center space-x-2">
            <RefreshCw className="h-4 w-4 animate-spin" />
            <span className="text-sm text-muted-foreground">Loading...</span>
          </div>
        </div>
        <div className="grid gap-4 md:grid-cols-2 lg:grid-cols-4">
          {[...Array(4)].map((_, i) => (
            <Card key={i} className="animate-pulse">
              <CardHeader className="space-y-0 pb-2">
                <div className="h-4 bg-gray-200 rounded"></div>
              </CardHeader>
              <CardContent>
                <div className="h-8 bg-gray-200 rounded mb-2"></div>
                <div className="h-3 bg-gray-200 rounded w-3/4"></div>
              </CardContent>
            </Card>
          ))}
        </div>
      </div>
    );
  }

  return (
    <div className="space-y-6 p-6">
      {/* Header */}
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-3xl font-bold">Analytics Dashboard</h1>
          <p className="text-muted-foreground">
            Last updated: {lastUpdated.toLocaleTimeString()}
          </p>
        </div>
        <div className="flex items-center space-x-2">
          <Button
            variant="outline"
            size="sm"
            onClick={() => setAutoRefresh(!autoRefresh)}
          >
            <Activity className={`h-4 w-4 mr-2 ${autoRefresh ? 'text-green-500' : ''}`} />
            {autoRefresh ? 'Auto-refresh ON' : 'Auto-refresh OFF'}
          </Button>
          <Button
            variant="outline"
            size="sm"
            onClick={loadDashboardData}
            disabled={loading}
          >
            <RefreshCw className={`h-4 w-4 mr-2 ${loading ? 'animate-spin' : ''}`} />
            Refresh
          </Button>
        </div>
      </div>

      {/* Key Metrics */}
      <div className="grid gap-4 md:grid-cols-2 lg:grid-cols-4">
        <MetricCard
          title="Revenue Today"
          value={data.revenue ? formatCurrency(data.revenue.total_revenue) : '£0.00'}
          change={data.revenue?.revenue_growth}
          trend={data.revenue && data.revenue.revenue_growth > 0 ? 'up' : 'down'}
          icon={<CreditCard className="h-4 w-4 text-muted-foreground" />}
          description={`${data.revenue?.order_count || 0} orders`}
        />
        
        <MetricCard
          title="Online Users"
          value={data.traffic?.current_online_users || 0}
          icon={<Users className="h-4 w-4 text-muted-foreground" />}
          description={`${data.traffic?.sessions_last_hour || 0} sessions last hour`}
        />
        
        <MetricCard
          title="Conversion Rate"
          value={data.revenue ? formatPercentage(data.revenue.conversion_rate) : '0%'}
          icon={<TrendingUp className="h-4 w-4 text-muted-foreground" />}
          description={`${data.revenue?.sessions || 0} total sessions`}
        />
        
        <MetricCard
          title="Avg Order Value"
          value={data.revenue ? formatCurrency(data.revenue.avg_order_value) : '£0.00'}
          icon={<ShoppingCart className="h-4 w-4 text-muted-foreground" />}
          description="Average per order"
        />
      </div>

      {/* Main Dashboard Tabs */}
      <Tabs defaultValue="overview" className="space-y-4">
        <TabsList>
          <TabsTrigger value="overview">Overview</TabsTrigger>
          <TabsTrigger value="products">Products</TabsTrigger>
          <TabsTrigger value="customers">Customers</TabsTrigger>
          <TabsTrigger value="traffic">Traffic</TabsTrigger>
          <TabsTrigger value="realtime">Real-time</TabsTrigger>
        </TabsList>

        {/* Overview Tab */}
        <TabsContent value="overview" className="space-y-4">
          <div className="grid gap-4 md:grid-cols-2 lg:grid-cols-3">
            {/* Revenue Chart */}
            <Card className="col-span-2">
              <CardHeader>
                <CardTitle>Revenue Trend</CardTitle>
                <CardDescription>Daily revenue for the last 7 days</CardDescription>
              </CardHeader>
              <CardContent>
                <ResponsiveContainer width="100%" height={350}>
                  <AreaChart data={data.orders?.daily_order_trend || []}>
                    <CartesianGrid strokeDasharray="3 3" />
                    <XAxis dataKey="day" />
                    <YAxis />
                    <Tooltip formatter={(value) => [formatCurrency(Number(value)), 'Revenue']} />
                    <Area type="monotone" dataKey="revenue" stroke="#8884d8" fill="#8884d8" fillOpacity={0.3} />
                  </AreaChart>
                </ResponsiveContainer>
              </CardContent>
            </Card>

            {/* Order Status Distribution */}
            <Card>
              <CardHeader>
                <CardTitle>Order Status</CardTitle>
                <CardDescription>Current order distribution</CardDescription>
              </CardHeader>
              <CardContent>
                <div className="space-y-3">
                  {data.orders?.order_status_distribution && Object.entries(data.orders.order_status_distribution).map(([status, count]) => (
                    <div key={status} className="flex items-center justify-between">
                      <div className="flex items-center">
                        <Badge variant="outline" className="mr-2">
                          {status.charAt(0).toUpperCase() + status.slice(1)}
                        </Badge>
                        <span className="text-sm">{formatNumber(Number(count))}</span>
                      </div>
                      <Progress 
                        value={(Number(count) / (data.orders?.total_orders || 1)) * 100} 
                        className="w-20" 
                      />
                    </div>
                  ))}
                </div>
              </CardContent>
            </Card>
          </div>

          {/* Traffic Sources */}
          <Card>
            <CardHeader>
              <CardTitle>Traffic Sources</CardTitle>
              <CardDescription>Where your visitors are coming from</CardDescription>
            </CardHeader>
            <CardContent>
              <ResponsiveContainer width="100%" height={300}>
                <BarChart data={data.trafficSources?.slice(0, 8) || []}>
                  <CartesianGrid strokeDasharray="3 3" />
                  <XAxis dataKey="source" />
                  <YAxis />
                  <Tooltip />
                  <Bar dataKey="sessions" fill="#8884d8" />
                  <Bar dataKey="conversions" fill="#82ca9d" />
                </BarChart>
              </ResponsiveContainer>
            </CardContent>
          </Card>
        </TabsContent>

        {/* Products Tab */}
        <TabsContent value="products" className="space-y-4">
          <div className="grid gap-4 md:grid-cols-2">
            {/* Top Products */}
            <Card>
              <CardHeader>
                <CardTitle>Top Products by Revenue</CardTitle>
                <CardDescription>Best performing products</CardDescription>
              </CardHeader>
              <CardContent>
                <div className="space-y-4">
                  {data.topProducts?.slice(0, 5).map((product, index) => (
                    <div key={product.product_id} className="flex items-center justify-between">
                      <div className="flex items-center space-x-3">
                        <Badge variant="secondary">{index + 1}</Badge>
                        <div>
                          <p className="font-medium text-sm">{product.product_name}</p>
                          <p className="text-xs text-muted-foreground">{product.category}</p>
                        </div>
                      </div>
                      <div className="text-right">
                        <p className="font-medium">{formatCurrency(product.revenue)}</p>
                        <p className="text-xs text-muted-foreground">{product.orders} orders</p>
                      </div>
                    </div>
                  ))}
                </div>
              </CardContent>
            </Card>

            {/* Product Performance Chart */}
            <Card>
              <CardHeader>
                <CardTitle>Product Views vs Sales</CardTitle>
                <CardDescription>Conversion performance</CardDescription>
              </CardHeader>
              <CardContent>
                <ResponsiveContainer width="100%" height={350}>
                  <LineChart data={data.topProducts?.slice(0, 10) || []}>
                    <CartesianGrid strokeDasharray="3 3" />
                    <XAxis dataKey="product_name" angle={-45} textAnchor="end" height={100} />
                    <YAxis yAxisId="left" />
                    <YAxis yAxisId="right" orientation="right" />
                    <Tooltip />
                    <Bar yAxisId="left" dataKey="views" fill="#8884d8" />
                    <Line yAxisId="right" type="monotone" dataKey="orders" stroke="#ff7300" />
                  </LineChart>
                </ResponsiveContainer>
              </CardContent>
            </Card>
          </div>
        </TabsContent>

        {/* Customers Tab */}
        <TabsContent value="customers" className="space-y-4">
          <div className="grid gap-4 md:grid-cols-3">
            <Card>
              <CardHeader>
                <CardTitle>Customer Activity</CardTitle>
                <CardDescription>Last hour activity</CardDescription>
              </CardHeader>
              <CardContent>
                <div className="space-y-3">
                  <div className="flex justify-between">
                    <span>Active Sessions</span>
                    <span className="font-medium">{data.customerActivity?.active_sessions || 0}</span>
                  </div>
                  <div className="flex justify-between">
                    <span>Active Customers</span>
                    <span className="font-medium">{data.customerActivity?.active_customers || 0}</span>
                  </div>
                  <div className="flex justify-between">
                    <span>Cart Value</span>
                    <span className="font-medium">{formatCurrency(data.customerActivity?.current_cart_value || 0)}</span>
                  </div>
                </div>
              </CardContent>
            </Card>

            <Card className="col-span-2">
              <CardHeader>
                <CardTitle>Recent Customer Events</CardTitle>
                <CardDescription>Latest customer activities</CardDescription>
              </CardHeader>
              <CardContent>
                <div className="space-y-2 max-h-64 overflow-y-auto">
                  {data.customerActivity?.recent_events?.slice(0, 10).map((event: any, index: number) => (
                    <div key={index} className="flex items-center justify-between text-sm border-b pb-2">
                      <div>
                        <Badge variant="outline" className="mr-2">{event.event_type}</Badge>
                        {event.product_name && <span>{event.product_name}</span>}
                      </div>
                      <span className="text-muted-foreground">
                        {new Date(event.created_at).toLocaleTimeString()}
                      </span>
                    </div>
                  ))}
                </div>
              </CardContent>
            </Card>
          </div>
        </TabsContent>

        {/* Traffic Tab */}
        <TabsContent value="traffic" className="space-y-4">
          <div className="grid gap-4 md:grid-cols-2">
            {/* Device Breakdown */}
            <Card>
              <CardHeader>
                <CardTitle>Device Types</CardTitle>
                <CardDescription>Sessions by device type</CardDescription>
              </CardHeader>
              <CardContent>
                <div className="space-y-3">
                  <div className="flex items-center justify-between">
                    <div className="flex items-center">
                      <Monitor className="h-4 w-4 mr-2" />
                      <span>Desktop</span>
                    </div>
                    <span className="font-medium">{data.traffic?.device_breakdown?.desktop || 0}</span>
                  </div>
                  <div className="flex items-center justify-between">
                    <div className="flex items-center">
                      <Smartphone className="h-4 w-4 mr-2" />
                      <span>Mobile</span>
                    </div>
                    <span className="font-medium">{data.traffic?.device_breakdown?.mobile || 0}</span>
                  </div>
                  <div className="flex items-center justify-between">
                    <div className="flex items-center">
                      <Tablet className="h-4 w-4 mr-2" />
                      <span>Tablet</span>
                    </div>
                    <span className="font-medium">{data.traffic?.device_breakdown?.tablet || 0}</span>
                  </div>
                </div>
              </CardContent>
            </Card>

            {/* Top Pages */}
            <Card>
              <CardHeader>
                <CardTitle>Popular Pages</CardTitle>
                <CardDescription>Most viewed pages right now</CardDescription>
              </CardHeader>
              <CardContent>
                <div className="space-y-2 max-h-64 overflow-y-auto">
                  {data.traffic?.top_pages_now?.map((page, index) => (
                    <div key={index} className="flex items-center justify-between text-sm">
                      <div className="flex items-center">
                        <Eye className="h-3 w-3 mr-2 text-muted-foreground" />
                        <span className="truncate">{page.page_url}</span>
                      </div>
                      <Badge variant="secondary">{page.views}</Badge>
                    </div>
                  ))}
                </div>
              </CardContent>
            </Card>
          </div>

          {/* Geographic Data */}
          <Card>
            <CardHeader>
              <CardTitle>Active Countries</CardTitle>
              <CardDescription>Current sessions by country</CardDescription>
            </CardHeader>
            <CardContent>
              <div className="grid grid-cols-2 md:grid-cols-4 gap-4">
                {data.traffic?.active_countries?.map((country, index) => (
                  <div key={index} className="flex items-center justify-between p-3 border rounded-lg">
                    <div className="flex items-center">
                      <Globe className="h-4 w-4 mr-2 text-muted-foreground" />
                      <span className="text-sm">{country.country}</span>
                    </div>
                    <Badge variant="outline">{country.sessions}</Badge>
                  </div>
                ))}
              </div>
            </CardContent>
          </Card>
        </TabsContent>

        {/* Real-time Tab */}
        <TabsContent value="realtime" className="space-y-4">
          <div className="grid gap-4 md:grid-cols-2">
            {/* Live Activity */}
            <Card>
              <CardHeader>
                <CardTitle>Live Activity</CardTitle>
                <CardDescription>Real-time user activity</CardDescription>
              </CardHeader>
              <CardContent>
                <div className="space-y-4">
                  <div className="flex items-center justify-between text-lg">
                    <span>Online Users</span>
                    <div className="flex items-center">
                      <div className="h-2 w-2 bg-green-500 rounded-full mr-2 animate-pulse"></div>
                      <span className="font-bold">{data.traffic?.current_online_users || 0}</span>
                    </div>
                  </div>
                  <div className="text-sm text-muted-foreground space-y-2">
                    <p>Page views (last hour): {data.traffic?.page_views_last_hour || 0}</p>
                    <p>Sessions (last hour): {data.traffic?.sessions_last_hour || 0}</p>
                  </div>
                </div>
              </CardContent>
            </Card>

            {/* Recent Conversions */}
            <Card>
              <CardHeader>
                <CardTitle>Recent Conversions</CardTitle>
                <CardDescription>Latest purchases</CardDescription>
              </CardHeader>
              <CardContent>
                <div className="space-y-2 max-h-64 overflow-y-auto">
                  {data.traffic?.recent_conversions?.map((conversion, index) => (
                    <div key={index} className="flex items-center justify-between text-sm border-b pb-2">
                      <div>
                        <p className="font-medium">{formatCurrency(conversion.revenue)}</p>
                        {conversion.product_name && (
                          <p className="text-xs text-muted-foreground">{conversion.product_name}</p>
                        )}
                      </div>
                      <span className="text-muted-foreground">
                        {new Date(conversion.created_at).toLocaleTimeString()}
                      </span>
                    </div>
                  ))}
                </div>
              </CardContent>
            </Card>
          </div>
        </TabsContent>
      </Tabs>
    </div>
  );
};

export default RealTimeDashboard;