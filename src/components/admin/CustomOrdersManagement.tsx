import { useState, useEffect } from "react";
import { supabase } from '@/lib/supabase';
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Button } from "@/components/ui/button";
import { Badge } from "@/components/ui/badge";
import { Tabs, TabsContent, TabsList, TabsTrigger } from "@/components/ui/tabs";
import { UserCheck, Plus, Clock, CheckCircle, XCircle, Edit2 } from "lucide-react";
import { toast } from "@/hooks/use-toast";

interface CustomOrder {
  id: string;
  customer_name: string;
  customer_email: string;
  order_type: 'bespoke' | 'alteration' | 'fitting';
  status: 'pending' | 'in_progress' | 'completed' | 'cancelled';
  description: string;
  estimated_completion: string;
  price_estimate: number;
  created_at: string;
}

export const CustomOrdersManagement = () => {
  const [customOrders, setCustomOrders] = useState<CustomOrder[]>([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    loadCustomOrders();
  }, []);

  const loadCustomOrders = async () => {
    try {
      setLoading(true);
      
      // Load custom orders from database
      const { data: orders, error } = await supabase
        .from('custom_orders')
        .select('*')
        .order('created_at', { ascending: false });
      
      if (error) throw error;
      
      // If no orders exist, set empty array
      setCustomOrders(orders || []);
      
      // Only show toast if we have orders
      if (orders && orders.length > 0) {
        toast({
          title: "Custom Orders Loaded",
          description: `${orders.length} custom orders loaded`
        });
      }
    } catch (error) {
      console.error('Error loading custom orders:', error);
      toast({
        title: "Error",
        description: "Failed to load custom orders",
        variant: "destructive"
      });
    } finally {
      setLoading(false);
    }
  };

  const getStatusColor = (status: CustomOrder['status']) => {
    switch (status) {
      case 'pending': return 'secondary';
      case 'in_progress': return 'default';
      case 'completed': return 'outline';
      case 'cancelled': return 'destructive';
      default: return 'outline';
    }
  };

  const getStatusIcon = (status: CustomOrder['status']) => {
    switch (status) {
      case 'pending': return Clock;
      case 'in_progress': return UserCheck;
      case 'completed': return CheckCircle;
      case 'cancelled': return XCircle;
      default: return Clock;
    }
  };

  if (loading) {
    return (
      <div className="space-y-6">
        <div className="flex items-center justify-between">
          <div className="h-8 bg-muted rounded w-64 animate-pulse" />
        </div>
        <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
          {[1, 2, 3].map(i => (
            <div key={i} className="h-32 bg-muted rounded animate-pulse" />
          ))}
        </div>
      </div>
    );
  }

  return (
    <div className="space-y-6">
      <div className="flex items-center justify-between">
        <div className="flex items-center gap-2">
          <UserCheck className="h-6 w-6" />
          <h1 className="text-2xl font-bold">Custom Orders</h1>
        </div>
        <Button>
          <Plus className="h-4 w-4 mr-2" />
          New Custom Order
        </Button>
      </div>

      {/* Quick Stats */}
      <div className="grid grid-cols-1 md:grid-cols-4 gap-6">
        <Card>
          <CardContent className="p-6">
            <div className="flex items-center justify-between">
              <div>
                <p className="text-sm text-muted-foreground">Total Orders</p>
                <p className="text-2xl font-bold">{customOrders.length}</p>
              </div>
              <UserCheck className="h-8 w-8 text-muted-foreground" />
            </div>
          </CardContent>
        </Card>

        <Card>
          <CardContent className="p-6">
            <div className="flex items-center justify-between">
              <div>
                <p className="text-sm text-muted-foreground">In Progress</p>
                <p className="text-2xl font-bold">
                  {customOrders.filter(o => o.status === 'in_progress').length}
                </p>
              </div>
              <Clock className="h-8 w-8 text-yellow-500" />
            </div>
          </CardContent>
        </Card>

        <Card>
          <CardContent className="p-6">
            <div className="flex items-center justify-between">
              <div>
                <p className="text-sm text-muted-foreground">Completed</p>
                <p className="text-2xl font-bold">
                  {customOrders.filter(o => o.status === 'completed').length}
                </p>
              </div>
              <CheckCircle className="h-8 w-8 text-green-500" />
            </div>
          </CardContent>
        </Card>

        <Card>
          <CardContent className="p-6">
            <div className="flex items-center justify-between">
              <div>
                <p className="text-sm text-muted-foreground">Revenue</p>
                <p className="text-2xl font-bold">
                  ${customOrders.reduce((sum, order) => sum + order.price_estimate, 0).toLocaleString()}
                </p>
              </div>
              <UserCheck className="h-8 w-8 text-muted-foreground" />
            </div>
          </CardContent>
        </Card>
      </div>

      <Tabs defaultValue="all" className="space-y-4">
        <TabsList>
          <TabsTrigger value="all">All Orders</TabsTrigger>
          <TabsTrigger value="pending">Pending</TabsTrigger>
          <TabsTrigger value="in_progress">In Progress</TabsTrigger>
          <TabsTrigger value="completed">Completed</TabsTrigger>
        </TabsList>

        <TabsContent value="all" className="space-y-4">
          <Card>
            <CardHeader>
              <CardTitle>Custom Orders List</CardTitle>
            </CardHeader>
            <CardContent>
              <div className="space-y-4">
                {customOrders.map((order) => {
                  const StatusIcon = getStatusIcon(order.status);
                  return (
                    <div key={order.id} className="flex items-center justify-between p-4 border rounded-lg">
                      <div className="flex items-center space-x-4">
                        <StatusIcon className="h-6 w-6 text-muted-foreground" />
                        <div>
                          <div className="font-medium">{order.customer_name}</div>
                          <div className="text-sm text-muted-foreground">{order.customer_email}</div>
                          <div className="text-sm font-medium mt-1">{order.description}</div>
                          <div className="text-xs text-muted-foreground mt-1">
                            Est. completion: {new Date(order.estimated_completion).toLocaleDateString()}
                          </div>
                        </div>
                      </div>
                      <div className="flex items-center space-x-4">
                        <div className="text-right">
                          <div className="font-medium">${order.price_estimate.toLocaleString()}</div>
                          <Badge variant={getStatusColor(order.status)}>
                            {order.status.replace('_', ' ')}
                          </Badge>
                        </div>
                        <Button variant="ghost" size="sm">
                          <Edit2 className="h-4 w-4" />
                        </Button>
                      </div>
                    </div>
                  );
                })}
              </div>
            </CardContent>
          </Card>
        </TabsContent>

        {['pending', 'in_progress', 'completed'].map((status) => (
          <TabsContent key={status} value={status} className="space-y-4">
            <Card>
              <CardContent className="p-6">
                <div className="space-y-4">
                  {customOrders
                    .filter(order => order.status === status)
                    .map((order) => {
                      const StatusIcon = getStatusIcon(order.status);
                      return (
                        <div key={order.id} className="flex items-center justify-between p-4 border rounded-lg">
                          <div className="flex items-center space-x-4">
                            <StatusIcon className="h-6 w-6" />
                            <div>
                              <div className="font-medium">{order.customer_name}</div>
                              <div className="text-sm text-muted-foreground">{order.description}</div>
                            </div>
                          </div>
                          <div className="flex items-center space-x-2">
                            <span className="font-medium">${order.price_estimate.toLocaleString()}</span>
                            <Button variant="ghost" size="sm">
                              <Edit2 className="h-4 w-4" />
                            </Button>
                          </div>
                        </div>
                      );
                    })}
                </div>
              </CardContent>
            </Card>
          </TabsContent>
        ))}
      </Tabs>
    </div>
  );
};