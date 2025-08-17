/**
 * SMART INVENTORY ALERTS
 * Automated inventory monitoring with intelligent alerts and reorder suggestions
 */

import React, { useState, useEffect } from 'react';
import { Button } from '@/components/ui/button';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Badge } from '@/components/ui/badge';
import { Alert, AlertDescription, AlertTitle } from '@/components/ui/alert';
import { Tabs, TabsContent, TabsList, TabsTrigger } from '@/components/ui/tabs';
import { Progress } from '@/components/ui/progress';
import { Switch } from '@/components/ui/switch';
import { Input } from '@/components/ui/input';
import { Label } from '@/components/ui/label';
import { Separator } from '@/components/ui/separator';
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from '@/components/ui/select';
import { toast } from 'sonner';
import { supabase } from '@/lib/supabase-client';
import { 
  Package,
  AlertTriangle,
  TrendingDown,
  TrendingUp,
  Bell,
  Settings,
  BarChart3,
  ShoppingCart,
  RefreshCw,
  Mail,
  MessageSquare,
  Clock,
  CheckCircle,
  XCircle,
  Activity,
  ArrowDown,
  ArrowUp,
  Zap
} from 'lucide-react';

interface InventoryAlert {
  id: string;
  type: 'low_stock' | 'out_of_stock' | 'overstock' | 'fast_moving' | 'slow_moving';
  severity: 'critical' | 'warning' | 'info';
  product_id: string;
  product_name: string;
  sku: string;
  current_stock: number;
  threshold: number;
  recommended_action: string;
  created_at: string;
  acknowledged: boolean;
  auto_resolved: boolean;
}

interface AlertRule {
  id: string;
  name: string;
  type: string;
  condition: string;
  threshold: number;
  action: 'email' | 'notification' | 'auto_reorder' | 'flag';
  enabled: boolean;
  category?: string;
  notify_emails?: string[];
}

interface InventoryMetrics {
  totalProducts: number;
  lowStockItems: number;
  outOfStockItems: number;
  overstockItems: number;
  totalValue: number;
  turnoverRate: number;
  averageStockLevel: number;
  criticalAlerts: number;
}

interface ReorderSuggestion {
  product_id: string;
  product_name: string;
  sku: string;
  current_stock: number;
  average_daily_sales: number;
  days_until_stockout: number;
  recommended_quantity: number;
  estimated_cost: number;
  priority: 'high' | 'medium' | 'low';
}

export function SmartInventoryAlerts() {
  const [alerts, setAlerts] = useState<InventoryAlert[]>([]);
  const [alertRules, setAlertRules] = useState<AlertRule[]>([]);
  const [metrics, setMetrics] = useState<InventoryMetrics>({
    totalProducts: 0,
    lowStockItems: 0,
    outOfStockItems: 0,
    overstockItems: 0,
    totalValue: 0,
    turnoverRate: 0,
    averageStockLevel: 0,
    criticalAlerts: 0
  });
  const [reorderSuggestions, setReorderSuggestions] = useState<ReorderSuggestion[]>([]);
  const [isProcessing, setIsProcessing] = useState(false);
  const [selectedAlerts, setSelectedAlerts] = useState<Set<string>>(new Set());
  const [subscriptionRef, setSubscriptionRef] = useState<any>(null);
  
  // Alert settings
  const [alertSettings, setAlertSettings] = useState({
    lowStockThreshold: 10,
    criticalStockThreshold: 5,
    overstockMultiplier: 3,
    emailNotifications: true,
    autoReorder: false,
    reorderLeadTime: 7
  });

  // New rule form
  const [newRule, setNewRule] = useState({
    name: '',
    type: 'low_stock',
    threshold: 10,
    action: 'notification' as const,
    category: 'all'
  });

  useEffect(() => {
    loadAlerts();
    loadAlertRules();
    calculateMetrics();
    generateReorderSuggestions();
    
    // Set up real-time subscription only if not already subscribed
    if (!subscriptionRef) {
      console.log('📦 SmartInventoryAlerts: Setting up realtime subscription');
      const subscription = supabase
        .channel('inventory_changes')
        .on('postgres_changes', {
          event: '*',
          schema: 'public',
          table: 'product_variants'
        }, handleInventoryChange)
        .subscribe((status) => {
          console.log('📦 SmartInventoryAlerts: Subscription status:', status);
        });

      setSubscriptionRef(subscription);
    }

    return () => {
      if (subscriptionRef) {
        console.log('📦 SmartInventoryAlerts: Cleaning up subscription');
        subscriptionRef.unsubscribe();
        setSubscriptionRef(null);
      }
    };
  }, []);

  const handleInventoryChange = (payload: any) => {
    // Real-time inventory update
    console.log('📦 SmartInventoryAlerts: Inventory changed:', payload);
    checkInventoryLevels();
  };

  const loadAlerts = async () => {
    try {
      const { data, error } = await supabase
        .from('inventory_alerts')
        .select(`
          *,
          products (
            name,
            sku
          )
        `)
        .eq('acknowledged', false)
        .order('created_at', { ascending: false });

      if (!error && data) {
        const formattedAlerts = data.map(alert => ({
          ...alert,
          product_name: alert.products?.name || 'Unknown',
          sku: alert.products?.sku || 'N/A'
        }));
        setAlerts(formattedAlerts);
      }
    } catch (error) {
      console.error('Failed to load alerts:', error);
    }
  };

  const loadAlertRules = async () => {
    try {
      const { data, error } = await supabase
        .from('alert_rules')
        .select('*')
        .order('name');

      if (!error && data) {
        setAlertRules(data);
      }
    } catch (error) {
      console.error('Failed to load alert rules:', error);
    }
  };

  const calculateMetrics = async () => {
    try {
      // Get all products with variants
      const { data: products } = await supabase
        .from('products')
        .select(`
          *,
          product_variants (
            inventory_quantity,
            price
          )
        `);

      if (products) {
        let lowStock = 0;
        let outOfStock = 0;
        let overstock = 0;
        let totalValue = 0;
        let totalStock = 0;

        products.forEach(product => {
          const variants = product.product_variants || [];
          const totalInventory = variants.reduce((sum: number, v: any) => sum + v.inventory_quantity, 0);
          const productValue = variants.reduce((sum: number, v: any) => sum + (v.inventory_quantity * v.price), 0);
          
          totalStock += totalInventory;
          totalValue += productValue;

          if (totalInventory === 0) {
            outOfStock++;
          } else if (totalInventory < alertSettings.lowStockThreshold) {
            lowStock++;
          } else if (totalInventory > alertSettings.overstockMultiplier * 50) {
            overstock++;
          }
        });

        // Get critical alerts count
        const { count: criticalCount } = await supabase
          .from('inventory_alerts')
          .select('*', { count: 'exact', head: true })
          .eq('severity', 'critical')
          .eq('acknowledged', false);

        setMetrics({
          totalProducts: products.length,
          lowStockItems: lowStock,
          outOfStockItems: outOfStock,
          overstockItems: overstock,
          totalValue,
          turnoverRate: 2.5, // Calculate from sales data
          averageStockLevel: totalStock / products.length,
          criticalAlerts: criticalCount || 0
        });
      }
    } catch (error) {
      console.error('Failed to calculate metrics:', error);
    }
  };

  const generateReorderSuggestions = async () => {
    try {
      // Get products with low stock and sales history
      const { data: products } = await supabase
        .from('products')
        .select(`
          *,
          product_variants (
            id,
            inventory_quantity,
            price
          )
        `);

      // Get sales data for the last 30 days
      const thirtyDaysAgo = new Date();
      thirtyDaysAgo.setDate(thirtyDaysAgo.getDate() - 30);

      const { data: salesData } = await supabase
        .from('order_items')
        .select('product_id, quantity')
        .gte('created_at', thirtyDaysAgo.toISOString());

      if (products && salesData) {
        const suggestions: ReorderSuggestion[] = [];

        products.forEach(product => {
          const totalInventory = product.product_variants?.reduce(
            (sum: number, v: any) => sum + v.inventory_quantity, 0
          ) || 0;

          // Calculate average daily sales
          const productSales = salesData.filter(sale => sale.product_id === product.id);
          const totalSold = productSales.reduce((sum, sale) => sum + sale.quantity, 0);
          const avgDailySales = totalSold / 30;

          if (avgDailySales > 0) {
            const daysUntilStockout = totalInventory / avgDailySales;
            
            if (daysUntilStockout < alertSettings.reorderLeadTime + 7) {
              // Need to reorder soon
              const recommendedQuantity = Math.ceil(avgDailySales * 60); // 60 days of stock
              const estimatedCost = recommendedQuantity * (product.base_price || 0) * 0.6; // Assume 40% margin

              suggestions.push({
                product_id: product.id,
                product_name: product.name,
                sku: product.sku,
                current_stock: totalInventory,
                average_daily_sales: avgDailySales,
                days_until_stockout: Math.round(daysUntilStockout),
                recommended_quantity: recommendedQuantity,
                estimated_cost: estimatedCost,
                priority: daysUntilStockout < 7 ? 'high' : daysUntilStockout < 14 ? 'medium' : 'low'
              });
            }
          }
        });

        setReorderSuggestions(suggestions.sort((a, b) => a.days_until_stockout - b.days_until_stockout));
      }
    } catch (error) {
      console.error('Failed to generate reorder suggestions:', error);
    }
  };

  const checkInventoryLevels = async () => {
    setIsProcessing(true);

    try {
      // Get all products with current inventory
      const { data: products } = await supabase
        .from('products')
        .select(`
          *,
          product_variants (
            inventory_quantity
          )
        `);

      if (products) {
        const newAlerts: any[] = [];

        for (const product of products) {
          const totalInventory = product.product_variants?.reduce(
            (sum: number, v: any) => sum + v.inventory_quantity, 0
          ) || 0;

          // Check for out of stock
          if (totalInventory === 0) {
            newAlerts.push({
              type: 'out_of_stock',
              severity: 'critical',
              product_id: product.id,
              current_stock: 0,
              threshold: 0,
              recommended_action: 'Reorder immediately or mark as unavailable',
              created_at: new Date().toISOString()
            });
          }
          // Check for low stock
          else if (totalInventory < alertSettings.criticalStockThreshold) {
            newAlerts.push({
              type: 'low_stock',
              severity: 'critical',
              product_id: product.id,
              current_stock: totalInventory,
              threshold: alertSettings.criticalStockThreshold,
              recommended_action: 'Urgent reorder required',
              created_at: new Date().toISOString()
            });
          }
          else if (totalInventory < alertSettings.lowStockThreshold) {
            newAlerts.push({
              type: 'low_stock',
              severity: 'warning',
              product_id: product.id,
              current_stock: totalInventory,
              threshold: alertSettings.lowStockThreshold,
              recommended_action: 'Consider reordering soon',
              created_at: new Date().toISOString()
            });
          }
          // Check for overstock
          else if (totalInventory > alertSettings.overstockMultiplier * 100) {
            newAlerts.push({
              type: 'overstock',
              severity: 'info',
              product_id: product.id,
              current_stock: totalInventory,
              threshold: alertSettings.overstockMultiplier * 100,
              recommended_action: 'Consider promotional pricing or reduced ordering',
              created_at: new Date().toISOString()
            });
          }
        }

        // Insert new alerts
        if (newAlerts.length > 0) {
          await supabase.from('inventory_alerts').insert(newAlerts);
          toast.success(`Generated ${newAlerts.length} new inventory alerts`);
        }

        loadAlerts();
        calculateMetrics();
      }
    } catch (error) {
      console.error('Failed to check inventory levels:', error);
      toast.error('Failed to check inventory levels');
    } finally {
      setIsProcessing(false);
    }
  };

  const acknowledgeAlert = async (alertId: string) => {
    try {
      await supabase
        .from('inventory_alerts')
        .update({ acknowledged: true })
        .eq('id', alertId);

      setAlerts(prev => prev.filter(a => a.id !== alertId));
      toast.success('Alert acknowledged');
    } catch (error) {
      console.error('Failed to acknowledge alert:', error);
    }
  };

  const bulkAcknowledge = async () => {
    if (selectedAlerts.size === 0) return;

    try {
      await supabase
        .from('inventory_alerts')
        .update({ acknowledged: true })
        .in('id', Array.from(selectedAlerts));

      setAlerts(prev => prev.filter(a => !selectedAlerts.has(a.id)));
      setSelectedAlerts(new Set());
      toast.success(`Acknowledged ${selectedAlerts.size} alerts`);
    } catch (error) {
      console.error('Failed to acknowledge alerts:', error);
    }
  };

  const createAlertRule = async () => {
    try {
      const { error } = await supabase
        .from('alert_rules')
        .insert({
          name: newRule.name,
          type: newRule.type,
          condition: `stock < ${newRule.threshold}`,
          threshold: newRule.threshold,
          action: newRule.action,
          category: newRule.category,
          enabled: true
        });

      if (!error) {
        toast.success('Alert rule created');
        loadAlertRules();
        setNewRule({ name: '', type: 'low_stock', threshold: 10, action: 'notification', category: 'all' });
      }
    } catch (error) {
      console.error('Failed to create alert rule:', error);
    }
  };

  const toggleAlertRule = async (ruleId: string, enabled: boolean) => {
    try {
      await supabase
        .from('alert_rules')
        .update({ enabled })
        .eq('id', ruleId);

      setAlertRules(prev => prev.map(rule => 
        rule.id === ruleId ? { ...rule, enabled } : rule
      ));
    } catch (error) {
      console.error('Failed to toggle alert rule:', error);
    }
  };

  const processReorder = async (suggestion: ReorderSuggestion) => {
    try {
      // Create purchase order
      await supabase
        .from('purchase_orders')
        .insert({
          product_id: suggestion.product_id,
          quantity: suggestion.recommended_quantity,
          estimated_cost: suggestion.estimated_cost,
          status: 'pending',
          created_at: new Date().toISOString()
        });

      toast.success(`Reorder created for ${suggestion.product_name}`);
      generateReorderSuggestions();
    } catch (error) {
      console.error('Failed to process reorder:', error);
      toast.error('Failed to create reorder');
    }
  };

  const getSeverityColor = (severity: string) => {
    switch (severity) {
      case 'critical': return 'destructive';
      case 'warning': return 'secondary';
      case 'info': return 'outline';
      default: return 'default';
    }
  };

  const getPriorityIcon = (priority: string) => {
    switch (priority) {
      case 'high': return <ArrowUp className="h-4 w-4 text-red-500" />;
      case 'medium': return <ArrowDown className="h-4 w-4 text-yellow-500" />;
      case 'low': return <ArrowDown className="h-4 w-4 text-green-500" />;
      default: return null;
    }
  };

  return (
    <div className="space-y-6">
      {/* Header */}
      <div className="flex items-center justify-between">
        <div>
          <h2 className="text-2xl font-bold">Smart Inventory Alerts</h2>
          <p className="text-muted-foreground">Automated monitoring and reorder suggestions</p>
        </div>
        
        <div className="flex items-center gap-2">
          <Button 
            onClick={checkInventoryLevels}
            disabled={isProcessing}
            variant="outline"
          >
            {isProcessing ? (
              <>
                <RefreshCw className="h-4 w-4 mr-2 animate-spin" />
                Checking...
              </>
            ) : (
              <>
                <RefreshCw className="h-4 w-4 mr-2" />
                Check Now
              </>
            )}
          </Button>
        </div>
      </div>

      {/* Metrics Overview */}
      <div className="grid grid-cols-4 gap-4">
        <Card>
          <CardContent className="p-4">
            <div className="flex items-center justify-between">
              <div>
                <p className="text-sm text-muted-foreground">Critical Alerts</p>
                <p className="text-2xl font-bold text-red-600">{metrics.criticalAlerts}</p>
              </div>
              <AlertTriangle className="h-8 w-8 text-red-500" />
            </div>
          </CardContent>
        </Card>

        <Card>
          <CardContent className="p-4">
            <div className="flex items-center justify-between">
              <div>
                <p className="text-sm text-muted-foreground">Low Stock Items</p>
                <p className="text-2xl font-bold text-yellow-600">{metrics.lowStockItems}</p>
              </div>
              <TrendingDown className="h-8 w-8 text-yellow-500" />
            </div>
          </CardContent>
        </Card>

        <Card>
          <CardContent className="p-4">
            <div className="flex items-center justify-between">
              <div>
                <p className="text-sm text-muted-foreground">Out of Stock</p>
                <p className="text-2xl font-bold text-red-600">{metrics.outOfStockItems}</p>
              </div>
              <XCircle className="h-8 w-8 text-red-500" />
            </div>
          </CardContent>
        </Card>

        <Card>
          <CardContent className="p-4">
            <div className="flex items-center justify-between">
              <div>
                <p className="text-sm text-muted-foreground">Inventory Value</p>
                <p className="text-2xl font-bold">${metrics.totalValue.toFixed(0)}</p>
              </div>
              <Package className="h-8 w-8 text-blue-500" />
            </div>
          </CardContent>
        </Card>
      </div>

      <Tabs defaultValue="alerts" className="w-full">
        <TabsList className="grid w-full grid-cols-4">
          <TabsTrigger value="alerts">Active Alerts</TabsTrigger>
          <TabsTrigger value="reorder">Reorder Suggestions</TabsTrigger>
          <TabsTrigger value="rules">Alert Rules</TabsTrigger>
          <TabsTrigger value="settings">Settings</TabsTrigger>
        </TabsList>

        {/* Active Alerts Tab */}
        <TabsContent value="alerts" className="space-y-4">
          {alerts.length > 0 && (
            <div className="flex items-center justify-between">
              <p className="text-sm text-muted-foreground">
                {selectedAlerts.size} of {alerts.length} selected
              </p>
              <Button
                variant="outline"
                size="sm"
                onClick={bulkAcknowledge}
                disabled={selectedAlerts.size === 0}
              >
                Acknowledge Selected
              </Button>
            </div>
          )}

          {alerts.length === 0 ? (
            <Card>
              <CardContent className="text-center py-12">
                <CheckCircle className="h-12 w-12 mx-auto mb-4 text-green-500" />
                <h3 className="text-lg font-semibold mb-2">All Clear!</h3>
                <p className="text-muted-foreground">
                  No active inventory alerts at this time
                </p>
              </CardContent>
            </Card>
          ) : (
            <div className="space-y-2">
              {alerts.map((alert) => (
                <Card key={alert.id}>
                  <CardContent className="p-4">
                    <div className="flex items-center justify-between">
                      <div className="flex items-center gap-4">
                        <input
                          type="checkbox"
                          checked={selectedAlerts.has(alert.id)}
                          onChange={(e) => {
                            const newSelected = new Set(selectedAlerts);
                            if (e.target.checked) {
                              newSelected.add(alert.id);
                            } else {
                              newSelected.delete(alert.id);
                            }
                            setSelectedAlerts(newSelected);
                          }}
                          className="h-4 w-4"
                        />
                        
                        <div>
                          <div className="flex items-center gap-2">
                            <span className="font-medium">{alert.product_name}</span>
                            <Badge variant={getSeverityColor(alert.severity) as any}>
                              {alert.severity}
                            </Badge>
                            <Badge variant="outline">
                              {alert.type.replace(/_/g, ' ')}
                            </Badge>
                          </div>
                          <p className="text-sm text-muted-foreground">
                            SKU: {alert.sku} • Stock: {alert.current_stock} / {alert.threshold}
                          </p>
                          <p className="text-sm">
                            <strong>Action:</strong> {alert.recommended_action}
                          </p>
                        </div>
                      </div>

                      <Button
                        variant="outline"
                        size="sm"
                        onClick={() => acknowledgeAlert(alert.id)}
                      >
                        Acknowledge
                      </Button>
                    </div>
                  </CardContent>
                </Card>
              ))}
            </div>
          )}
        </TabsContent>

        {/* Reorder Suggestions Tab */}
        <TabsContent value="reorder" className="space-y-4">
          {reorderSuggestions.length === 0 ? (
            <Card>
              <CardContent className="text-center py-12">
                <Package className="h-12 w-12 mx-auto mb-4 text-muted-foreground" />
                <h3 className="text-lg font-semibold mb-2">No Reorders Needed</h3>
                <p className="text-muted-foreground">
                  All products have sufficient inventory levels
                </p>
              </CardContent>
            </Card>
          ) : (
            <div className="space-y-4">
              {reorderSuggestions.map((suggestion) => (
                <Card key={suggestion.product_id}>
                  <CardContent className="p-4">
                    <div className="flex items-center justify-between">
                      <div>
                        <div className="flex items-center gap-2">
                          {getPriorityIcon(suggestion.priority)}
                          <span className="font-medium">{suggestion.product_name}</span>
                          <Badge variant={
                            suggestion.priority === 'high' ? 'destructive' :
                            suggestion.priority === 'medium' ? 'secondary' : 'outline'
                          }>
                            {suggestion.priority} priority
                          </Badge>
                        </div>
                        <div className="grid grid-cols-2 gap-4 mt-2 text-sm">
                          <div>
                            <span className="text-muted-foreground">Current Stock:</span> {suggestion.current_stock}
                          </div>
                          <div>
                            <span className="text-muted-foreground">Days Until Stockout:</span> {suggestion.days_until_stockout}
                          </div>
                          <div>
                            <span className="text-muted-foreground">Avg Daily Sales:</span> {suggestion.average_daily_sales.toFixed(1)}
                          </div>
                          <div>
                            <span className="text-muted-foreground">Recommended Qty:</span> {suggestion.recommended_quantity}
                          </div>
                        </div>
                      </div>

                      <div className="text-right">
                        <p className="text-lg font-bold">${suggestion.estimated_cost.toFixed(2)}</p>
                        <Button
                          size="sm"
                          onClick={() => processReorder(suggestion)}
                          className="mt-2"
                        >
                          <ShoppingCart className="h-4 w-4 mr-2" />
                          Create Reorder
                        </Button>
                      </div>
                    </div>
                  </CardContent>
                </Card>
              ))}
            </div>
          )}
        </TabsContent>

        {/* Alert Rules Tab */}
        <TabsContent value="rules" className="space-y-4">
          <Card>
            <CardHeader>
              <CardTitle>Create Alert Rule</CardTitle>
            </CardHeader>
            <CardContent>
              <div className="grid grid-cols-5 gap-4">
                <Input
                  placeholder="Rule name"
                  value={newRule.name}
                  onChange={(e) => setNewRule(prev => ({ ...prev, name: e.target.value }))}
                />
                <Select
                  value={newRule.type}
                  onValueChange={(value) => setNewRule(prev => ({ ...prev, type: value }))}
                >
                  <SelectTrigger>
                    <SelectValue />
                  </SelectTrigger>
                  <SelectContent>
                    <SelectItem value="low_stock">Low Stock</SelectItem>
                    <SelectItem value="out_of_stock">Out of Stock</SelectItem>
                    <SelectItem value="overstock">Overstock</SelectItem>
                    <SelectItem value="fast_moving">Fast Moving</SelectItem>
                  </SelectContent>
                </Select>
                <Input
                  type="number"
                  placeholder="Threshold"
                  value={newRule.threshold}
                  onChange={(e) => setNewRule(prev => ({ ...prev, threshold: parseInt(e.target.value) }))}
                />
                <Select
                  value={newRule.action}
                  onValueChange={(value: any) => setNewRule(prev => ({ ...prev, action: value }))}
                >
                  <SelectTrigger>
                    <SelectValue />
                  </SelectTrigger>
                  <SelectContent>
                    <SelectItem value="notification">Notification</SelectItem>
                    <SelectItem value="email">Email</SelectItem>
                    <SelectItem value="auto_reorder">Auto Reorder</SelectItem>
                  </SelectContent>
                </Select>
                <Button onClick={createAlertRule} disabled={!newRule.name}>
                  Add Rule
                </Button>
              </div>
            </CardContent>
          </Card>

          <div className="space-y-2">
            {alertRules.map((rule) => (
              <Card key={rule.id}>
                <CardContent className="p-4">
                  <div className="flex items-center justify-between">
                    <div>
                      <h3 className="font-medium">{rule.name}</h3>
                      <p className="text-sm text-muted-foreground">
                        {rule.type} • {rule.condition} • Action: {rule.action}
                      </p>
                    </div>
                    <Switch
                      checked={rule.enabled}
                      onCheckedChange={(checked) => toggleAlertRule(rule.id, checked)}
                    />
                  </div>
                </CardContent>
              </Card>
            ))}
          </div>
        </TabsContent>

        {/* Settings Tab */}
        <TabsContent value="settings" className="space-y-4">
          <Card>
            <CardHeader>
              <CardTitle>Alert Thresholds</CardTitle>
            </CardHeader>
            <CardContent className="space-y-4">
              <div className="grid grid-cols-2 gap-4">
                <div>
                  <Label htmlFor="low-stock">Low Stock Threshold</Label>
                  <Input
                    id="low-stock"
                    type="number"
                    value={alertSettings.lowStockThreshold}
                    onChange={(e) => setAlertSettings(prev => ({
                      ...prev,
                      lowStockThreshold: parseInt(e.target.value)
                    }))}
                  />
                </div>
                <div>
                  <Label htmlFor="critical-stock">Critical Stock Threshold</Label>
                  <Input
                    id="critical-stock"
                    type="number"
                    value={alertSettings.criticalStockThreshold}
                    onChange={(e) => setAlertSettings(prev => ({
                      ...prev,
                      criticalStockThreshold: parseInt(e.target.value)
                    }))}
                  />
                </div>
                <div>
                  <Label htmlFor="overstock">Overstock Multiplier</Label>
                  <Input
                    id="overstock"
                    type="number"
                    value={alertSettings.overstockMultiplier}
                    onChange={(e) => setAlertSettings(prev => ({
                      ...prev,
                      overstockMultiplier: parseInt(e.target.value)
                    }))}
                  />
                </div>
                <div>
                  <Label htmlFor="lead-time">Reorder Lead Time (days)</Label>
                  <Input
                    id="lead-time"
                    type="number"
                    value={alertSettings.reorderLeadTime}
                    onChange={(e) => setAlertSettings(prev => ({
                      ...prev,
                      reorderLeadTime: parseInt(e.target.value)
                    }))}
                  />
                </div>
              </div>
            </CardContent>
          </Card>

          <Card>
            <CardHeader>
              <CardTitle>Notification Settings</CardTitle>
            </CardHeader>
            <CardContent className="space-y-4">
              <div className="flex items-center justify-between">
                <div>
                  <h3 className="font-medium">Email Notifications</h3>
                  <p className="text-sm text-muted-foreground">
                    Send email alerts for critical inventory issues
                  </p>
                </div>
                <Switch
                  checked={alertSettings.emailNotifications}
                  onCheckedChange={(checked) => setAlertSettings(prev => ({
                    ...prev,
                    emailNotifications: checked
                  }))}
                />
              </div>
              
              <Separator />
              
              <div className="flex items-center justify-between">
                <div>
                  <h3 className="font-medium">Auto Reorder</h3>
                  <p className="text-sm text-muted-foreground">
                    Automatically create purchase orders for critical items
                  </p>
                </div>
                <Switch
                  checked={alertSettings.autoReorder}
                  onCheckedChange={(checked) => setAlertSettings(prev => ({
                    ...prev,
                    autoReorder: checked
                  }))}
                />
              </div>
            </CardContent>
          </Card>
        </TabsContent>
      </Tabs>
    </div>
  );
}