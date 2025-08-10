/**
 * ORDER PROCESSING AUTOMATION
 * Streamlined order management with bulk operations and automation
 */

import React, { useState, useEffect } from 'react';
import { Button } from '@/components/ui/button';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Badge } from '@/components/ui/badge';
import { Checkbox } from '@/components/ui/checkbox';
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from '@/components/ui/select';
import { Tabs, TabsContent, TabsList, TabsTrigger } from '@/components/ui/tabs';
import { Progress } from '@/components/ui/progress';
import { Alert, AlertDescription } from '@/components/ui/alert';
import { Separator } from '@/components/ui/separator';
import { Label } from '@/components/ui/label';
import { Input } from '@/components/ui/input';
import { toast } from 'sonner';
import { supabase } from '@/lib/supabase-client';
import { 
  Package, 
  Truck, 
  CheckCircle,
  AlertTriangle,
  Clock,
  Send,
  Download,
  Printer,
  Mail,
  RefreshCw,
  Filter,
  ChevronRight,
  FileText,
  DollarSign,
  Users,
  Calendar,
  MapPin,
  CreditCard
} from 'lucide-react';

interface Order {
  id: string;
  order_number: string;
  customer_id: string;
  customer_name: string;
  customer_email: string;
  status: 'pending' | 'processing' | 'shipped' | 'delivered' | 'cancelled';
  payment_status: 'pending' | 'paid' | 'refunded';
  total_amount: number;
  shipping_address: any;
  tracking_number?: string;
  carrier?: string;
  created_at: string;
  updated_at: string;
  items: OrderItem[];
  selected?: boolean;
}

interface OrderItem {
  id: string;
  product_name: string;
  variant_name: string;
  quantity: number;
  price: number;
}

interface BulkAction {
  type: 'status' | 'shipping' | 'email' | 'label' | 'invoice';
  value?: any;
}

export function OrderProcessingAutomation() {
  const [orders, setOrders] = useState<Order[]>([]);
  const [selectedOrders, setSelectedOrders] = useState<Set<string>>(new Set());
  const [isProcessing, setIsProcessing] = useState(false);
  const [processProgress, setProcessProgress] = useState(0);
  const [filters, setFilters] = useState({
    status: 'all',
    dateRange: '7days',
    paymentStatus: 'all'
  });
  
  // Automation rules
  const [automationRules, setAutomationRules] = useState([
    { id: 1, name: 'Auto-confirm paid orders', condition: 'payment_received', action: 'update_status_processing', enabled: true },
    { id: 2, name: 'Send tracking email', condition: 'tracking_added', action: 'send_tracking_email', enabled: true },
    { id: 3, name: 'Flag high-value orders', condition: 'order_over_500', action: 'flag_for_review', enabled: false },
    { id: 4, name: 'Auto-generate shipping labels', condition: 'status_processing', action: 'create_shipping_label', enabled: true }
  ]);

  // Statistics
  const [stats, setStats] = useState({
    pendingOrders: 0,
    processingOrders: 0,
    shippedToday: 0,
    revenue: 0
  });

  useEffect(() => {
    loadOrders();
    calculateStats();
  }, [filters]);

  const loadOrders = async () => {
    try {
      let query = supabase
        .from('orders')
        .select(`
          *,
          order_items (
            id,
            product_name,
            variant_name,
            quantity,
            price
          ),
          customers (
            name,
            email
          )
        `)
        .order('created_at', { ascending: false });

      // Apply filters
      if (filters.status !== 'all') {
        query = query.eq('status', filters.status);
      }

      if (filters.paymentStatus !== 'all') {
        query = query.eq('payment_status', filters.paymentStatus);
      }

      if (filters.dateRange !== 'all') {
        const date = new Date();
        if (filters.dateRange === '7days') {
          date.setDate(date.getDate() - 7);
        } else if (filters.dateRange === '30days') {
          date.setDate(date.getDate() - 30);
        }
        query = query.gte('created_at', date.toISOString());
      }

      const { data, error } = await query;

      if (!error && data) {
        const formattedOrders = data.map(order => ({
          ...order,
          customer_name: order.customers?.name || 'Unknown',
          customer_email: order.customers?.email || '',
          items: order.order_items || []
        }));
        setOrders(formattedOrders);
      }
    } catch (error) {
      console.error('Failed to load orders:', error);
      toast.error('Failed to load orders');
    }
  };

  const calculateStats = async () => {
    try {
      const today = new Date().toISOString().split('T')[0];
      
      const { data: pending } = await supabase
        .from('orders')
        .select('id', { count: 'exact' })
        .eq('status', 'pending');

      const { data: processing } = await supabase
        .from('orders')
        .select('id', { count: 'exact' })
        .eq('status', 'processing');

      const { data: shippedToday } = await supabase
        .from('orders')
        .select('id', { count: 'exact' })
        .eq('status', 'shipped')
        .gte('updated_at', today);

      const { data: revenue } = await supabase
        .from('orders')
        .select('total_amount')
        .eq('payment_status', 'paid')
        .gte('created_at', today);

      setStats({
        pendingOrders: pending?.length || 0,
        processingOrders: processing?.length || 0,
        shippedToday: shippedToday?.length || 0,
        revenue: revenue?.reduce((sum, order) => sum + order.total_amount, 0) || 0
      });
    } catch (error) {
      console.error('Failed to calculate stats:', error);
    }
  };

  const handleSelectAll = (checked: boolean) => {
    if (checked) {
      setSelectedOrders(new Set(orders.map(o => o.id)));
    } else {
      setSelectedOrders(new Set());
    }
  };

  const handleSelectOrder = (orderId: string, checked: boolean) => {
    const newSelected = new Set(selectedOrders);
    if (checked) {
      newSelected.add(orderId);
    } else {
      newSelected.delete(orderId);
    }
    setSelectedOrders(newSelected);
  };

  const processBulkAction = async (action: BulkAction) => {
    if (selectedOrders.size === 0) {
      toast.error('No orders selected');
      return;
    }

    setIsProcessing(true);
    setProcessProgress(0);

    try {
      const orderIds = Array.from(selectedOrders);
      const totalOrders = orderIds.length;

      for (let i = 0; i < orderIds.length; i++) {
        const orderId = orderIds[i];
        setProcessProgress((i / totalOrders) * 100);

        switch (action.type) {
          case 'status':
            await updateOrderStatus(orderId, action.value);
            break;
          case 'shipping':
            await generateShippingLabel(orderId);
            break;
          case 'email':
            await sendOrderEmail(orderId, action.value);
            break;
          case 'label':
            await printShippingLabel(orderId);
            break;
          case 'invoice':
            await generateInvoice(orderId);
            break;
        }
      }

      setProcessProgress(100);
      toast.success(`Processed ${totalOrders} orders successfully`);
      loadOrders();
      setSelectedOrders(new Set());

    } catch (error) {
      console.error('Bulk action failed:', error);
      toast.error('Some operations failed. Please try again.');
    } finally {
      setIsProcessing(false);
      setProcessProgress(0);
    }
  };

  const updateOrderStatus = async (orderId: string, newStatus: string) => {
    const { error } = await supabase
      .from('orders')
      .update({ 
        status: newStatus,
        updated_at: new Date().toISOString()
      })
      .eq('id', orderId);

    if (error) throw error;

    // Trigger automation rules
    if (newStatus === 'processing' && getAutomationRule('status_processing')?.enabled) {
      await generateShippingLabel(orderId);
    }
  };

  const generateShippingLabel = async (orderId: string) => {
    // Simulate shipping label generation
    const trackingNumber = `TRK${Date.now().toString().slice(-10)}`;
    
    await supabase
      .from('orders')
      .update({ 
        tracking_number: trackingNumber,
        carrier: 'USPS',
        updated_at: new Date().toISOString()
      })
      .eq('id', orderId);

    // Trigger tracking email if enabled
    if (getAutomationRule('tracking_added')?.enabled) {
      await sendOrderEmail(orderId, 'tracking');
    }
  };

  const sendOrderEmail = async (orderId: string, emailType: string) => {
    const order = orders.find(o => o.id === orderId);
    if (!order) return;

    // Queue email for sending
    await supabase
      .from('email_queue')
      .insert({
        to: order.customer_email,
        template: emailType,
        data: {
          order_number: order.order_number,
          customer_name: order.customer_name,
          tracking_number: order.tracking_number,
          carrier: order.carrier
        },
        status: 'pending',
        created_at: new Date().toISOString()
      });
  };

  const printShippingLabel = async (orderId: string) => {
    // Generate label PDF
    const order = orders.find(o => o.id === orderId);
    if (!order) return;

    // In production, this would generate actual PDF
    console.log('Printing label for order:', order.order_number);
    toast.success(`Label queued for printing: ${order.order_number}`);
  };

  const generateInvoice = async (orderId: string) => {
    const order = orders.find(o => o.id === orderId);
    if (!order) return;

    // Generate invoice PDF
    console.log('Generating invoice for order:', order.order_number);
    toast.success(`Invoice generated: ${order.order_number}`);
  };

  const getAutomationRule = (condition: string) => {
    return automationRules.find(rule => rule.condition === condition);
  };

  const toggleAutomationRule = async (ruleId: number) => {
    setAutomationRules(prev => prev.map(rule => 
      rule.id === ruleId ? { ...rule, enabled: !rule.enabled } : rule
    ));
    
    // Save to database
    const rule = automationRules.find(r => r.id === ruleId);
    if (rule) {
      await supabase
        .from('automation_rules')
        .upsert({
          id: rule.id,
          name: rule.name,
          condition: rule.condition,
          action: rule.action,
          enabled: !rule.enabled
        });
    }
  };

  const getStatusColor = (status: string) => {
    switch (status) {
      case 'pending': return 'secondary';
      case 'processing': return 'default';
      case 'shipped': return 'success';
      case 'delivered': return 'success';
      case 'cancelled': return 'destructive';
      default: return 'outline';
    }
  };

  return (
    <div className="space-y-6">
      {/* Header */}
      <div className="flex items-center justify-between">
        <div>
          <h2 className="text-2xl font-bold">Order Processing Automation</h2>
          <p className="text-muted-foreground">Streamline order fulfillment with bulk operations</p>
        </div>
        
        <Button onClick={() => loadOrders()} variant="outline">
          <RefreshCw className="h-4 w-4 mr-2" />
          Refresh
        </Button>
      </div>

      {/* Statistics */}
      <div className="grid grid-cols-4 gap-4">
        <Card>
          <CardContent className="p-4">
            <div className="flex items-center justify-between">
              <div>
                <p className="text-sm text-muted-foreground">Pending Orders</p>
                <p className="text-2xl font-bold">{stats.pendingOrders}</p>
              </div>
              <Clock className="h-8 w-8 text-yellow-500" />
            </div>
          </CardContent>
        </Card>
        
        <Card>
          <CardContent className="p-4">
            <div className="flex items-center justify-between">
              <div>
                <p className="text-sm text-muted-foreground">Processing</p>
                <p className="text-2xl font-bold">{stats.processingOrders}</p>
              </div>
              <Package className="h-8 w-8 text-blue-500" />
            </div>
          </CardContent>
        </Card>
        
        <Card>
          <CardContent className="p-4">
            <div className="flex items-center justify-between">
              <div>
                <p className="text-sm text-muted-foreground">Shipped Today</p>
                <p className="text-2xl font-bold">{stats.shippedToday}</p>
              </div>
              <Truck className="h-8 w-8 text-green-500" />
            </div>
          </CardContent>
        </Card>
        
        <Card>
          <CardContent className="p-4">
            <div className="flex items-center justify-between">
              <div>
                <p className="text-sm text-muted-foreground">Today's Revenue</p>
                <p className="text-2xl font-bold">${stats.revenue.toFixed(2)}</p>
              </div>
              <DollarSign className="h-8 w-8 text-green-600" />
            </div>
          </CardContent>
        </Card>
      </div>

      <Tabs defaultValue="orders" className="w-full">
        <TabsList className="grid w-full grid-cols-3">
          <TabsTrigger value="orders">Order Queue</TabsTrigger>
          <TabsTrigger value="bulk">Bulk Actions</TabsTrigger>
          <TabsTrigger value="automation">Automation Rules</TabsTrigger>
        </TabsList>

        {/* Orders Tab */}
        <TabsContent value="orders" className="space-y-4">
          {/* Filters */}
          <Card>
            <CardContent className="p-4">
              <div className="flex items-center gap-4">
                <Select
                  value={filters.status}
                  onValueChange={(value) => setFilters(prev => ({ ...prev, status: value }))}
                >
                  <SelectTrigger className="w-40">
                    <SelectValue />
                  </SelectTrigger>
                  <SelectContent>
                    <SelectItem value="all">All Status</SelectItem>
                    <SelectItem value="pending">Pending</SelectItem>
                    <SelectItem value="processing">Processing</SelectItem>
                    <SelectItem value="shipped">Shipped</SelectItem>
                    <SelectItem value="delivered">Delivered</SelectItem>
                  </SelectContent>
                </Select>

                <Select
                  value={filters.dateRange}
                  onValueChange={(value) => setFilters(prev => ({ ...prev, dateRange: value }))}
                >
                  <SelectTrigger className="w-40">
                    <SelectValue />
                  </SelectTrigger>
                  <SelectContent>
                    <SelectItem value="all">All Time</SelectItem>
                    <SelectItem value="7days">Last 7 Days</SelectItem>
                    <SelectItem value="30days">Last 30 Days</SelectItem>
                  </SelectContent>
                </Select>

                <Select
                  value={filters.paymentStatus}
                  onValueChange={(value) => setFilters(prev => ({ ...prev, paymentStatus: value }))}
                >
                  <SelectTrigger className="w-40">
                    <SelectValue />
                  </SelectTrigger>
                  <SelectContent>
                    <SelectItem value="all">All Payments</SelectItem>
                    <SelectItem value="paid">Paid</SelectItem>
                    <SelectItem value="pending">Payment Pending</SelectItem>
                  </SelectContent>
                </Select>
              </div>
            </CardContent>
          </Card>

          {/* Order List */}
          <Card>
            <CardHeader>
              <div className="flex items-center justify-between">
                <CardTitle>Orders ({orders.length})</CardTitle>
                <div className="flex items-center gap-2">
                  <Checkbox
                    checked={selectedOrders.size === orders.length && orders.length > 0}
                    onCheckedChange={handleSelectAll}
                  />
                  <span className="text-sm text-muted-foreground">
                    {selectedOrders.size} selected
                  </span>
                </div>
              </div>
            </CardHeader>
            <CardContent>
              <div className="space-y-2">
                {orders.map((order) => (
                  <div
                    key={order.id}
                    className="flex items-center justify-between p-4 border rounded-lg hover:bg-muted/50"
                  >
                    <div className="flex items-center gap-4">
                      <Checkbox
                        checked={selectedOrders.has(order.id)}
                        onCheckedChange={(checked) => handleSelectOrder(order.id, checked as boolean)}
                      />
                      
                      <div>
                        <div className="flex items-center gap-2">
                          <span className="font-medium">#{order.order_number}</span>
                          <Badge variant={getStatusColor(order.status) as any}>
                            {order.status}
                          </Badge>
                          {order.payment_status === 'paid' && (
                            <Badge variant="outline" className="text-green-600">
                              <CreditCard className="h-3 w-3 mr-1" />
                              Paid
                            </Badge>
                          )}
                        </div>
                        <div className="text-sm text-muted-foreground">
                          {order.customer_name} • {order.items.length} items • ${order.total_amount.toFixed(2)}
                        </div>
                        <div className="text-xs text-muted-foreground">
                          {new Date(order.created_at).toLocaleString()}
                        </div>
                      </div>
                    </div>

                    <div className="flex items-center gap-2">
                      {order.tracking_number && (
                        <Badge variant="outline">
                          <Truck className="h-3 w-3 mr-1" />
                          {order.tracking_number}
                        </Badge>
                      )}
                      <Button variant="outline" size="sm">
                        View
                      </Button>
                    </div>
                  </div>
                ))}
              </div>
            </CardContent>
          </Card>
        </TabsContent>

        {/* Bulk Actions Tab */}
        <TabsContent value="bulk" className="space-y-4">
          {isProcessing && (
            <Card>
              <CardContent className="p-4">
                <div className="space-y-2">
                  <div className="flex items-center justify-between">
                    <span className="text-sm font-medium">Processing orders...</span>
                    <span className="text-sm text-muted-foreground">{Math.round(processProgress)}%</span>
                  </div>
                  <Progress value={processProgress} />
                </div>
              </CardContent>
            </Card>
          )}

          <div className="grid grid-cols-2 gap-4">
            <Card>
              <CardHeader>
                <CardTitle className="text-lg">Status Updates</CardTitle>
              </CardHeader>
              <CardContent className="space-y-2">
                <Button
                  className="w-full justify-start"
                  variant="outline"
                  onClick={() => processBulkAction({ type: 'status', value: 'processing' })}
                  disabled={selectedOrders.size === 0 || isProcessing}
                >
                  <Package className="h-4 w-4 mr-2" />
                  Mark as Processing
                </Button>
                <Button
                  className="w-full justify-start"
                  variant="outline"
                  onClick={() => processBulkAction({ type: 'status', value: 'shipped' })}
                  disabled={selectedOrders.size === 0 || isProcessing}
                >
                  <Truck className="h-4 w-4 mr-2" />
                  Mark as Shipped
                </Button>
                <Button
                  className="w-full justify-start"
                  variant="outline"
                  onClick={() => processBulkAction({ type: 'status', value: 'delivered' })}
                  disabled={selectedOrders.size === 0 || isProcessing}
                >
                  <CheckCircle className="h-4 w-4 mr-2" />
                  Mark as Delivered
                </Button>
              </CardContent>
            </Card>

            <Card>
              <CardHeader>
                <CardTitle className="text-lg">Shipping & Labels</CardTitle>
              </CardHeader>
              <CardContent className="space-y-2">
                <Button
                  className="w-full justify-start"
                  variant="outline"
                  onClick={() => processBulkAction({ type: 'shipping' })}
                  disabled={selectedOrders.size === 0 || isProcessing}
                >
                  <FileText className="h-4 w-4 mr-2" />
                  Generate Shipping Labels
                </Button>
                <Button
                  className="w-full justify-start"
                  variant="outline"
                  onClick={() => processBulkAction({ type: 'label' })}
                  disabled={selectedOrders.size === 0 || isProcessing}
                >
                  <Printer className="h-4 w-4 mr-2" />
                  Print Labels
                </Button>
                <Button
                  className="w-full justify-start"
                  variant="outline"
                  onClick={() => processBulkAction({ type: 'invoice' })}
                  disabled={selectedOrders.size === 0 || isProcessing}
                >
                  <Download className="h-4 w-4 mr-2" />
                  Download Invoices
                </Button>
              </CardContent>
            </Card>

            <Card>
              <CardHeader>
                <CardTitle className="text-lg">Communications</CardTitle>
              </CardHeader>
              <CardContent className="space-y-2">
                <Button
                  className="w-full justify-start"
                  variant="outline"
                  onClick={() => processBulkAction({ type: 'email', value: 'confirmation' })}
                  disabled={selectedOrders.size === 0 || isProcessing}
                >
                  <Mail className="h-4 w-4 mr-2" />
                  Send Confirmations
                </Button>
                <Button
                  className="w-full justify-start"
                  variant="outline"
                  onClick={() => processBulkAction({ type: 'email', value: 'tracking' })}
                  disabled={selectedOrders.size === 0 || isProcessing}
                >
                  <Send className="h-4 w-4 mr-2" />
                  Send Tracking Info
                </Button>
                <Button
                  className="w-full justify-start"
                  variant="outline"
                  onClick={() => processBulkAction({ type: 'email', value: 'delivery' })}
                  disabled={selectedOrders.size === 0 || isProcessing}
                >
                  <CheckCircle className="h-4 w-4 mr-2" />
                  Send Delivery Notice
                </Button>
              </CardContent>
            </Card>

            <Card>
              <CardHeader>
                <CardTitle className="text-lg">Quick Actions</CardTitle>
              </CardHeader>
              <CardContent className="space-y-2">
                <Alert>
                  <AlertTriangle className="h-4 w-4" />
                  <AlertDescription>
                    {selectedOrders.size === 0 
                      ? 'Select orders to perform bulk actions'
                      : `${selectedOrders.size} orders selected for processing`
                    }
                  </AlertDescription>
                </Alert>
              </CardContent>
            </Card>
          </div>
        </TabsContent>

        {/* Automation Tab */}
        <TabsContent value="automation" className="space-y-4">
          <Card>
            <CardHeader>
              <CardTitle>Automation Rules</CardTitle>
              <p className="text-sm text-muted-foreground">
                Configure automatic actions based on order events
              </p>
            </CardHeader>
            <CardContent>
              <div className="space-y-4">
                {automationRules.map((rule) => (
                  <div
                    key={rule.id}
                    className="flex items-center justify-between p-4 border rounded-lg"
                  >
                    <div>
                      <h3 className="font-medium">{rule.name}</h3>
                      <p className="text-sm text-muted-foreground">
                        When: {rule.condition.replace(/_/g, ' ')} → 
                        Then: {rule.action.replace(/_/g, ' ')}
                      </p>
                    </div>
                    <Button
                      variant={rule.enabled ? 'default' : 'outline'}
                      size="sm"
                      onClick={() => toggleAutomationRule(rule.id)}
                    >
                      {rule.enabled ? 'Enabled' : 'Disabled'}
                    </Button>
                  </div>
                ))}
              </div>
            </CardContent>
          </Card>
        </TabsContent>
      </Tabs>
    </div>
  );
}