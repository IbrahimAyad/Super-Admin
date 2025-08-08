import React, { useState, useEffect } from 'react';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { Badge } from '@/components/ui/badge';
import { Input } from '@/components/ui/input';
import { Label } from '@/components/ui/label';
import { Alert, AlertDescription, AlertTitle } from '@/components/ui/alert';
import { Dialog, DialogContent, DialogDescription, DialogFooter, DialogHeader, DialogTitle } from '@/components/ui/dialog';
import { Tabs, TabsContent, TabsList, TabsTrigger } from '@/components/ui/tabs';
import { ScrollArea } from '@/components/ui/scroll-area';
import { Progress } from '@/components/ui/progress';
import {
  AlertTriangle,
  Package,
  TrendingDown,
  RefreshCw,
  Settings,
  Bell,
  BellOff,
  ShoppingCart,
  Loader2,
  CheckCircle,
  XCircle,
  ArrowUp,
  ArrowDown,
  Mail,
  BarChart3
} from 'lucide-react';
import { useToast } from '@/hooks/use-toast';
import { supabase } from '@/lib/supabase-client';
import { sendLowStockAlert } from '@/lib/services/emailService';

interface InventoryItem {
  id: string;
  variant_id: string;
  product_id: string;
  product_name: string;
  sku: string;
  available_quantity: number;
  reserved_quantity: number;
  low_stock_threshold: number;
  reorder_point: number;
  reorder_quantity: number;
  auto_reorder: boolean;
  last_restocked?: string;
  price: number;
  category?: string;
}

interface LowStockAlert {
  id: string;
  variant_id: string;
  product_id: string;
  current_stock: number;
  threshold: number;
  alert_sent: boolean;
  alert_sent_at?: string;
  resolved: boolean;
  resolved_at?: string;
  created_at: string;
  product?: {
    name: string;
    sku: string;
  };
}

interface InventoryStats {
  total_products: number;
  total_variants: number;
  low_stock_items: number;
  out_of_stock_items: number;
  total_stock_value: number;
  items_on_order: number;
}

export function LowStockAlerts() {
  const [activeTab, setActiveTab] = useState('alerts');
  const [loading, setLoading] = useState(true);
  const [lowStockItems, setLowStockItems] = useState<InventoryItem[]>([]);
  const [alerts, setAlerts] = useState<LowStockAlert[]>([]);
  const [stats, setStats] = useState<InventoryStats>({
    total_products: 0,
    total_variants: 0,
    low_stock_items: 0,
    out_of_stock_items: 0,
    total_stock_value: 0,
    items_on_order: 0
  });
  const [selectedItem, setSelectedItem] = useState<InventoryItem | null>(null);
  const [showThresholdDialog, setShowThresholdDialog] = useState(false);
  const [showRestockDialog, setShowRestockDialog] = useState(false);
  const [thresholdForm, setThresholdForm] = useState({
    low_stock_threshold: 10,
    reorder_point: 20,
    reorder_quantity: 50,
    auto_reorder: false
  });
  const [restockForm, setRestockForm] = useState({
    quantity: 0,
    notes: ''
  });
  const { toast } = useToast();

  useEffect(() => {
    loadInventoryData();
    loadAlerts();
    const interval = setInterval(() => {
      loadInventoryData();
      loadAlerts();
    }, 60000); // Refresh every minute
    return () => clearInterval(interval);
  }, []);

  const loadInventoryData = async () => {
    try {
      setLoading(true);
      
      // Get inventory items with low stock
      const { data: inventory, error: invError } = await supabase
        .from('inventory')
        .select(`
          *,
          product_variants!inner(
            id,
            sku,
            price,
            products!inner(
              id,
              name,
              category
            )
          ),
          inventory_thresholds!left(
            low_stock_threshold,
            reorder_point,
            reorder_quantity,
            auto_reorder
          )
        `)
        .lte('available_quantity', 20)
        .order('available_quantity', { ascending: true });

      if (invError) throw invError;

      // Transform data
      const transformedItems = (inventory || []).map(item => ({
        id: item.id,
        variant_id: item.variant_id,
        product_id: item.product_variants.products.id,
        product_name: item.product_variants.products.name,
        sku: item.product_variants.sku,
        available_quantity: item.available_quantity,
        reserved_quantity: item.reserved_quantity || 0,
        low_stock_threshold: item.inventory_thresholds?.low_stock_threshold || 10,
        reorder_point: item.inventory_thresholds?.reorder_point || 20,
        reorder_quantity: item.inventory_thresholds?.reorder_quantity || 50,
        auto_reorder: item.inventory_thresholds?.auto_reorder || false,
        price: item.product_variants.price,
        category: item.product_variants.products.category
      }));

      setLowStockItems(transformedItems);

      // Get inventory stats
      const { data: statsData, error: statsError } = await supabase
        .rpc('get_inventory_status');

      if (!statsError && statsData && statsData.length > 0) {
        setStats(statsData[0]);
      }
    } catch (error) {
      console.error('Error loading inventory data:', error);
      toast({
        title: 'Error',
        description: 'Failed to load inventory data',
        variant: 'destructive'
      });
    } finally {
      setLoading(false);
    }
  };

  const loadAlerts = async () => {
    try {
      const { data, error } = await supabase
        .from('low_stock_alerts')
        .select(`
          *,
          product_variants!inner(
            sku,
            products!inner(
              name
            )
          )
        `)
        .eq('resolved', false)
        .order('created_at', { ascending: false });

      if (error) throw error;

      const transformedAlerts = (data || []).map(alert => ({
        ...alert,
        product: {
          name: alert.product_variants.products.name,
          sku: alert.product_variants.sku
        }
      }));

      setAlerts(transformedAlerts);
    } catch (error) {
      console.error('Error loading alerts:', error);
    }
  };

  const updateThresholds = async () => {
    if (!selectedItem) return;

    try {
      // Check if threshold record exists
      const { data: existing } = await supabase
        .from('inventory_thresholds')
        .select('id')
        .eq('variant_id', selectedItem.variant_id)
        .single();

      if (existing) {
        // Update existing
        const { error } = await supabase
          .from('inventory_thresholds')
          .update({
            low_stock_threshold: thresholdForm.low_stock_threshold,
            reorder_point: thresholdForm.reorder_point,
            reorder_quantity: thresholdForm.reorder_quantity,
            auto_reorder: thresholdForm.auto_reorder,
            updated_at: new Date().toISOString()
          })
          .eq('variant_id', selectedItem.variant_id);

        if (error) throw error;
      } else {
        // Insert new
        const { error } = await supabase
          .from('inventory_thresholds')
          .insert({
            variant_id: selectedItem.variant_id,
            low_stock_threshold: thresholdForm.low_stock_threshold,
            reorder_point: thresholdForm.reorder_point,
            reorder_quantity: thresholdForm.reorder_quantity,
            auto_reorder: thresholdForm.auto_reorder
          });

        if (error) throw error;
      }

      toast({
        title: 'Success',
        description: 'Inventory thresholds updated'
      });

      setShowThresholdDialog(false);
      loadInventoryData();
    } catch (error) {
      console.error('Error updating thresholds:', error);
      toast({
        title: 'Error',
        description: 'Failed to update thresholds',
        variant: 'destructive'
      });
    }
  };

  const restockItem = async () => {
    if (!selectedItem || restockForm.quantity <= 0) return;

    try {
      // Update inventory
      const { error: invError } = await supabase
        .from('inventory')
        .update({
          available_quantity: selectedItem.available_quantity + restockForm.quantity,
          updated_at: new Date().toISOString()
        })
        .eq('variant_id', selectedItem.variant_id);

      if (invError) throw invError;

      // Record movement
      const { error: moveError } = await supabase
        .from('inventory_movements')
        .insert({
          variant_id: selectedItem.variant_id,
          movement_type: 'restock',
          quantity: restockForm.quantity,
          reference_type: 'manual',
          notes: restockForm.notes || 'Manual restock'
        });

      if (moveError) throw moveError;

      // Resolve any low stock alerts
      await supabase
        .from('low_stock_alerts')
        .update({
          resolved: true,
          resolved_at: new Date().toISOString()
        })
        .eq('variant_id', selectedItem.variant_id)
        .eq('resolved', false);

      toast({
        title: 'Success',
        description: `Added ${restockForm.quantity} units to inventory`
      });

      setShowRestockDialog(false);
      setRestockForm({ quantity: 0, notes: '' });
      loadInventoryData();
      loadAlerts();
    } catch (error) {
      console.error('Error restocking item:', error);
      toast({
        title: 'Error',
        description: 'Failed to restock item',
        variant: 'destructive'
      });
    }
  };

  const sendAlertEmail = async (item: InventoryItem) => {
    try {
      await sendLowStockAlert(item.product_id, item.available_quantity);
      
      // Mark alert as sent
      await supabase
        .from('low_stock_alerts')
        .update({
          alert_sent: true,
          alert_sent_at: new Date().toISOString()
        })
        .eq('variant_id', item.variant_id)
        .eq('resolved', false);

      toast({
        title: 'Alert Sent',
        description: 'Low stock alert email has been sent'
      });

      loadAlerts();
    } catch (error) {
      console.error('Error sending alert:', error);
      toast({
        title: 'Error',
        description: 'Failed to send alert',
        variant: 'destructive'
      });
    }
  };

  const resolveAlert = async (alertId: string) => {
    try {
      const { error } = await supabase
        .from('low_stock_alerts')
        .update({
          resolved: true,
          resolved_at: new Date().toISOString()
        })
        .eq('id', alertId);

      if (error) throw error;

      toast({
        title: 'Alert Resolved',
        description: 'The alert has been marked as resolved'
      });

      loadAlerts();
    } catch (error) {
      console.error('Error resolving alert:', error);
      toast({
        title: 'Error',
        description: 'Failed to resolve alert',
        variant: 'destructive'
      });
    }
  };

  const getStockStatus = (available: number, threshold: number) => {
    if (available === 0) return { color: 'destructive', text: 'Out of Stock', icon: XCircle };
    if (available <= threshold / 2) return { color: 'destructive', text: 'Critical', icon: AlertTriangle };
    if (available <= threshold) return { color: 'warning', text: 'Low Stock', icon: TrendingDown };
    return { color: 'default', text: 'In Stock', icon: CheckCircle };
  };

  const getStockPercentage = (available: number, threshold: number) => {
    const target = threshold * 3; // Assume healthy stock is 3x threshold
    return Math.min(100, (available / target) * 100);
  };

  return (
    <div className="space-y-6">
      {/* Header */}
      <div className="flex justify-between items-center">
        <div>
          <h2 className="text-2xl font-bold">Inventory & Low Stock Alerts</h2>
          <p className="text-muted-foreground">Monitor stock levels and manage alerts</p>
        </div>
        <Button onClick={loadInventoryData}>
          <RefreshCw className="h-4 w-4 mr-2" />
          Refresh
        </Button>
      </div>

      {/* Stats Cards */}
      <div className="grid grid-cols-1 md:grid-cols-6 gap-4">
        <Card>
          <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
            <CardTitle className="text-sm font-medium">Total Products</CardTitle>
            <Package className="h-4 w-4 text-muted-foreground" />
          </CardHeader>
          <CardContent>
            <div className="text-2xl font-bold">{stats.total_products}</div>
          </CardContent>
        </Card>

        <Card>
          <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
            <CardTitle className="text-sm font-medium">Total Variants</CardTitle>
            <BarChart3 className="h-4 w-4 text-muted-foreground" />
          </CardHeader>
          <CardContent>
            <div className="text-2xl font-bold">{stats.total_variants}</div>
          </CardContent>
        </Card>

        <Card>
          <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
            <CardTitle className="text-sm font-medium">Low Stock</CardTitle>
            <TrendingDown className="h-4 w-4 text-yellow-500" />
          </CardHeader>
          <CardContent>
            <div className="text-2xl font-bold text-yellow-600">{stats.low_stock_items}</div>
          </CardContent>
        </Card>

        <Card>
          <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
            <CardTitle className="text-sm font-medium">Out of Stock</CardTitle>
            <XCircle className="h-4 w-4 text-red-500" />
          </CardHeader>
          <CardContent>
            <div className="text-2xl font-bold text-red-600">{stats.out_of_stock_items}</div>
          </CardContent>
        </Card>

        <Card>
          <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
            <CardTitle className="text-sm font-medium">Stock Value</CardTitle>
            <TrendingDown className="h-4 w-4 text-muted-foreground" />
          </CardHeader>
          <CardContent>
            <div className="text-2xl font-bold">${(stats.total_stock_value / 100).toFixed(0)}</div>
          </CardContent>
        </Card>

        <Card>
          <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
            <CardTitle className="text-sm font-medium">On Order</CardTitle>
            <ShoppingCart className="h-4 w-4 text-muted-foreground" />
          </CardHeader>
          <CardContent>
            <div className="text-2xl font-bold">{stats.items_on_order}</div>
          </CardContent>
        </Card>
      </div>

      {/* Active Alerts */}
      {alerts.length > 0 && (
        <Alert>
          <AlertTriangle className="h-4 w-4" />
          <AlertTitle>Active Low Stock Alerts</AlertTitle>
          <AlertDescription>
            You have {alerts.length} unresolved low stock alerts that need attention.
          </AlertDescription>
        </Alert>
      )}

      {/* Main Content */}
      <Tabs value={activeTab} onValueChange={setActiveTab}>
        <TabsList className="grid w-full grid-cols-2">
          <TabsTrigger value="alerts">Low Stock Items</TabsTrigger>
          <TabsTrigger value="history">Alert History</TabsTrigger>
        </TabsList>

        <TabsContent value="alerts" className="space-y-4">
          {loading ? (
            <div className="flex justify-center py-8">
              <Loader2 className="h-8 w-8 animate-spin" />
            </div>
          ) : lowStockItems.length === 0 ? (
            <Card>
              <CardContent className="text-center py-8">
                <CheckCircle className="h-12 w-12 mx-auto mb-4 text-green-500" />
                <p className="text-muted-foreground">All products are well stocked!</p>
              </CardContent>
            </Card>
          ) : (
            <div className="space-y-4">
              {lowStockItems.map(item => {
                const status = getStockStatus(item.available_quantity, item.low_stock_threshold);
                const StatusIcon = status.icon;
                const percentage = getStockPercentage(item.available_quantity, item.low_stock_threshold);

                return (
                  <Card key={item.id}>
                    <CardContent className="pt-6">
                      <div className="flex items-start justify-between">
                        <div className="flex-1 space-y-3">
                          <div className="flex items-center gap-2">
                            <StatusIcon className={`h-5 w-5 ${
                              status.color === 'destructive' ? 'text-red-500' :
                              status.color === 'warning' ? 'text-yellow-500' :
                              'text-green-500'
                            }`} />
                            <h3 className="font-semibold">{item.product_name}</h3>
                            <Badge variant={status.color as any}>
                              {status.text}
                            </Badge>
                            {item.auto_reorder && (
                              <Badge variant="outline">
                                Auto-reorder
                              </Badge>
                            )}
                          </div>
                          
                          <div className="grid grid-cols-2 md:grid-cols-4 gap-4 text-sm">
                            <div>
                              <p className="text-muted-foreground">SKU</p>
                              <p className="font-medium">{item.sku}</p>
                            </div>
                            <div>
                              <p className="text-muted-foreground">Available</p>
                              <p className="font-medium">{item.available_quantity} units</p>
                            </div>
                            <div>
                              <p className="text-muted-foreground">Reserved</p>
                              <p className="font-medium">{item.reserved_quantity} units</p>
                            </div>
                            <div>
                              <p className="text-muted-foreground">Threshold</p>
                              <p className="font-medium">{item.low_stock_threshold} units</p>
                            </div>
                          </div>

                          <div className="space-y-1">
                            <div className="flex justify-between text-sm">
                              <span>Stock Level</span>
                              <span>{percentage.toFixed(0)}%</span>
                            </div>
                            <Progress value={percentage} className="h-2" />
                          </div>

                          {item.available_quantity <= item.reorder_point && (
                            <Alert className="mt-2">
                              <AlertTriangle className="h-4 w-4" />
                              <AlertDescription>
                                Reorder point reached. Suggested order: {item.reorder_quantity} units
                              </AlertDescription>
                            </Alert>
                          )}
                        </div>

                        <div className="flex gap-2 ml-4">
                          <Button
                            size="sm"
                            variant="outline"
                            onClick={() => {
                              setSelectedItem(item);
                              setThresholdForm({
                                low_stock_threshold: item.low_stock_threshold,
                                reorder_point: item.reorder_point,
                                reorder_quantity: item.reorder_quantity,
                                auto_reorder: item.auto_reorder
                              });
                              setShowThresholdDialog(true);
                            }}
                          >
                            <Settings className="h-4 w-4" />
                          </Button>
                          <Button
                            size="sm"
                            variant="outline"
                            onClick={() => sendAlertEmail(item)}
                          >
                            <Mail className="h-4 w-4" />
                          </Button>
                          <Button
                            size="sm"
                            onClick={() => {
                              setSelectedItem(item);
                              setShowRestockDialog(true);
                            }}
                          >
                            <ArrowUp className="h-4 w-4 mr-1" />
                            Restock
                          </Button>
                        </div>
                      </div>
                    </CardContent>
                  </Card>
                );
              })}
            </div>
          )}
        </TabsContent>

        <TabsContent value="history" className="space-y-4">
          <Card>
            <CardHeader>
              <CardTitle>Recent Alerts</CardTitle>
              <CardDescription>History of low stock alerts</CardDescription>
            </CardHeader>
            <CardContent>
              <ScrollArea className="h-96">
                <div className="space-y-4">
                  {alerts.map(alert => (
                    <div key={alert.id} className="flex items-center justify-between p-3 border rounded">
                      <div className="space-y-1">
                        <p className="font-medium">{alert.product?.name}</p>
                        <p className="text-sm text-muted-foreground">
                          SKU: {alert.product?.sku} • Stock: {alert.current_stock}/{alert.threshold}
                        </p>
                        <p className="text-xs text-muted-foreground">
                          {new Date(alert.created_at).toLocaleString()}
                        </p>
                      </div>
                      <div className="flex items-center gap-2">
                        {alert.alert_sent ? (
                          <Badge variant="outline">
                            <Bell className="h-3 w-3 mr-1" />
                            Sent
                          </Badge>
                        ) : (
                          <Badge variant="secondary">
                            <BellOff className="h-3 w-3 mr-1" />
                            Pending
                          </Badge>
                        )}
                        {!alert.resolved && (
                          <Button
                            size="sm"
                            variant="outline"
                            onClick={() => resolveAlert(alert.id)}
                          >
                            Resolve
                          </Button>
                        )}
                      </div>
                    </div>
                  ))}
                </div>
              </ScrollArea>
            </CardContent>
          </Card>
        </TabsContent>
      </Tabs>

      {/* Update Thresholds Dialog */}
      <Dialog open={showThresholdDialog} onOpenChange={setShowThresholdDialog}>
        <DialogContent>
          <DialogHeader>
            <DialogTitle>Update Inventory Thresholds</DialogTitle>
            <DialogDescription>
              {selectedItem?.product_name} - {selectedItem?.sku}
            </DialogDescription>
          </DialogHeader>
          
          <div className="space-y-4">
            <div className="space-y-2">
              <Label>Low Stock Threshold</Label>
              <Input
                type="number"
                value={thresholdForm.low_stock_threshold}
                onChange={(e) => setThresholdForm({
                  ...thresholdForm,
                  low_stock_threshold: parseInt(e.target.value)
                })}
                min="1"
              />
              <p className="text-xs text-muted-foreground">
                Alert when stock falls below this level
              </p>
            </div>

            <div className="space-y-2">
              <Label>Reorder Point</Label>
              <Input
                type="number"
                value={thresholdForm.reorder_point}
                onChange={(e) => setThresholdForm({
                  ...thresholdForm,
                  reorder_point: parseInt(e.target.value)
                })}
                min="1"
              />
              <p className="text-xs text-muted-foreground">
                Suggest reordering when stock reaches this level
              </p>
            </div>

            <div className="space-y-2">
              <Label>Reorder Quantity</Label>
              <Input
                type="number"
                value={thresholdForm.reorder_quantity}
                onChange={(e) => setThresholdForm({
                  ...thresholdForm,
                  reorder_quantity: parseInt(e.target.value)
                })}
                min="1"
              />
              <p className="text-xs text-muted-foreground">
                Suggested quantity to order
              </p>
            </div>

            <div className="flex items-center space-x-2">
              <input
                type="checkbox"
                id="auto-reorder"
                checked={thresholdForm.auto_reorder}
                onChange={(e) => setThresholdForm({
                  ...thresholdForm,
                  auto_reorder: e.target.checked
                })}
                className="rounded"
              />
              <Label htmlFor="auto-reorder">Enable automatic reordering</Label>
            </div>
          </div>

          <DialogFooter>
            <Button variant="outline" onClick={() => setShowThresholdDialog(false)}>
              Cancel
            </Button>
            <Button onClick={updateThresholds}>
              Update Thresholds
            </Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>

      {/* Restock Dialog */}
      <Dialog open={showRestockDialog} onOpenChange={setShowRestockDialog}>
        <DialogContent>
          <DialogHeader>
            <DialogTitle>Restock Item</DialogTitle>
            <DialogDescription>
              {selectedItem?.product_name} - {selectedItem?.sku}
            </DialogDescription>
          </DialogHeader>
          
          <div className="space-y-4">
            <div className="p-3 bg-muted rounded-lg">
              <p className="text-sm">Current Stock: {selectedItem?.available_quantity} units</p>
              <p className="text-sm">Suggested Reorder: {selectedItem?.reorder_quantity} units</p>
            </div>

            <div className="space-y-2">
              <Label>Quantity to Add</Label>
              <Input
                type="number"
                value={restockForm.quantity}
                onChange={(e) => setRestockForm({
                  ...restockForm,
                  quantity: parseInt(e.target.value) || 0
                })}
                min="1"
                placeholder="Enter quantity"
              />
            </div>

            <div className="space-y-2">
              <Label>Notes (Optional)</Label>
              <Input
                value={restockForm.notes}
                onChange={(e) => setRestockForm({
                  ...restockForm,
                  notes: e.target.value
                })}
                placeholder="e.g., Purchase order #12345"
              />
            </div>

            {restockForm.quantity > 0 && (
              <Alert>
                <CheckCircle className="h-4 w-4" />
                <AlertDescription>
                  New stock level will be: {(selectedItem?.available_quantity || 0) + restockForm.quantity} units
                </AlertDescription>
              </Alert>
            )}
          </div>

          <DialogFooter>
            <Button variant="outline" onClick={() => setShowRestockDialog(false)}>
              Cancel
            </Button>
            <Button onClick={restockItem} disabled={restockForm.quantity <= 0}>
              Add to Inventory
            </Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>
    </div>
  );
}