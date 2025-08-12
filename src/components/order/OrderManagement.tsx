import React, { useState, useEffect } from 'react';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { Badge } from '@/components/ui/badge';
import { Input } from '@/components/ui/input';
import { Label } from '@/components/ui/label';
import { Tabs, TabsContent, TabsList, TabsTrigger } from '@/components/ui/tabs';
import { Alert, AlertDescription } from '@/components/ui/alert';
import { Separator } from '@/components/ui/separator';
import { useAuth } from '@/contexts/AuthContext';
import { supabase } from '@/lib/supabase-client';
import { toast } from 'sonner';
import {
  Package,
  Truck,
  CheckCircle,
  Clock,
  AlertCircle,
  User,
  MapPin,
  CreditCard,
  Calendar,
  DollarSign,
  ShoppingBag,
  Star,
  Download,
  RefreshCw,
  Eye,
  MessageSquare
} from 'lucide-react';

interface Order {
  id: string;
  order_number: string;
  status: string;
  payment_status: string;
  total_amount: number;
  currency: string;
  created_at: string;
  updated_at: string;
  shipping_address: any;
  billing_address: any;
  order_items: Array<{
    id: string;
    quantity: number;
    unit_price: number;
    total_price: number;
    products: {
      id: string;
      name: string;
      description: string;
      image_url: string;
    };
    product_variants: {
      id: string;
      title: string;
      sku: string;
    };
  }>;
  order_fulfillment: Array<{
    id: string;
    status: string;
    tracking_number: string;
    carrier: string;
    estimated_delivery: string;
    shipped_at: string;
  }>;
}

interface UserProfile {
  id: string;
  email: string;
  full_name: string;
  lifetime_value: number;
  total_orders: number;
  last_purchase_at: string;
  customer_segment: string;
}

export function OrderManagement() {
  const { user } = useAuth();
  const [orders, setOrders] = useState<Order[]>([]);
  const [userProfile, setUserProfile] = useState<UserProfile | null>(null);
  const [loading, setLoading] = useState(true);
  const [selectedOrder, setSelectedOrder] = useState<Order | null>(null);
  const [filterStatus, setFilterStatus] = useState<string>('all');
  const [searchTerm, setSearchTerm] = useState('');

  useEffect(() => {
    if (user?.id) {
      loadOrdersAndProfile();
    }
  }, [user?.id, filterStatus]);

  const loadOrdersAndProfile = async () => {
    setLoading(true);
    try {
      // Load user profile
      const { data: profile, error: profileError } = await supabase
        .from('user_profiles')
        .select('*')
        .eq('id', user!.id)
        .single();

      if (profileError && profileError.code !== 'PGRST116') {
        throw profileError;
      }

      if (profile) {
        setUserProfile(profile);
      }

      // Load orders
      let query = supabase
        .from('orders')
        .select(`
          *,
          order_items (
            *,
            products (
              id,
              name,
              description,
              image_url
            ),
            product_variants (
              id,
              title,
              sku
            )
          ),
          order_fulfillment (
            *
          )
        `)
        .eq('user_id', user!.id)
        .order('created_at', { ascending: false });

      if (filterStatus !== 'all') {
        query = query.eq('status', filterStatus);
      }

      const { data: ordersData, error: ordersError } = await query;

      if (ordersError) {
        throw ordersError;
      }

      let filteredOrders = ordersData || [];

      // Apply search filter
      if (searchTerm) {
        filteredOrders = filteredOrders.filter(order =>
          order.order_number.toLowerCase().includes(searchTerm.toLowerCase()) ||
          order.order_items.some((item: any) =>
            item.products.name.toLowerCase().includes(searchTerm.toLowerCase())
          )
        );
      }

      setOrders(filteredOrders);

    } catch (error) {
      console.error('Error loading orders and profile:', error);
      toast.error('Failed to load order information');
    } finally {
      setLoading(false);
    }
  };

  const getStatusIcon = (status: string) => {
    switch (status) {
      case 'pending':
        return <Clock className="h-4 w-4" />;
      case 'processing':
        return <Package className="h-4 w-4" />;
      case 'shipped':
        return <Truck className="h-4 w-4" />;
      case 'delivered':
        return <CheckCircle className="h-4 w-4" />;
      case 'cancelled':
        return <AlertCircle className="h-4 w-4" />;
      default:
        return <Clock className="h-4 w-4" />;
    }
  };

  const getStatusColor = (status: string) => {
    switch (status) {
      case 'pending':
        return 'bg-yellow-100 text-yellow-800';
      case 'processing':
        return 'bg-blue-100 text-blue-800';
      case 'shipped':
        return 'bg-purple-100 text-purple-800';
      case 'delivered':
        return 'bg-green-100 text-green-800';
      case 'cancelled':
        return 'bg-red-100 text-red-800';
      default:
        return 'bg-gray-100 text-gray-800';
    }
  };

  const formatCurrency = (amount: number, currency: string = 'USD') => {
    return new Intl.NumberFormat('en-US', {
      style: 'currency',
      currency: currency.toUpperCase(),
    }).format(amount);
  };

  const formatDate = (dateString: string) => {
    return new Date(dateString).toLocaleDateString('en-US', {
      year: 'numeric',
      month: 'long',
      day: 'numeric',
      hour: '2-digit',
      minute: '2-digit',
    });
  };

  const handleViewOrder = (order: Order) => {
    setSelectedOrder(order);
  };

  const handleDownloadInvoice = async (order: Order) => {
    try {
      // This would call an Edge Function to generate and download invoice
      toast.success('Invoice download will be implemented');
    } catch (error) {
      toast.error('Failed to download invoice');
    }
  };

  const handleTrackOrder = (order: Order) => {
    const fulfillment = order.order_fulfillment?.[0];
    if (fulfillment?.tracking_number) {
      // Open tracking page in new tab
      const trackingUrl = `https://www.ups.com/track?tracknum=${fulfillment.tracking_number}`;
      window.open(trackingUrl, '_blank');
    } else {
      toast.info('Tracking information not yet available');
    }
  };

  const handleReorder = async (order: Order) => {
    try {
      // Add order items to cart
      for (const item of order.order_items) {
        // This would call the cart service to add items
        console.log('Adding to cart:', item);
      }
      toast.success('Items added to cart!');
    } catch (error) {
      toast.error('Failed to add items to cart');
    }
  };

  if (loading) {
    return (
      <div className="flex items-center justify-center p-8">
        <RefreshCw className="h-8 w-8 animate-spin" />
        <span className="ml-2">Loading orders...</span>
      </div>
    );
  }

  return (
    <div className="space-y-6">
      {/* User Profile Summary */}
      {userProfile && (
        <Card>
          <CardHeader>
            <CardTitle className="flex items-center gap-2">
              <User className="h-5 w-5" />
              Account Overview
            </CardTitle>
          </CardHeader>
          <CardContent>
            <div className="grid grid-cols-1 md:grid-cols-4 gap-4">
              <div className="flex items-center gap-3">
                <div className="bg-blue-100 p-2 rounded-lg">
                  <ShoppingBag className="h-5 w-5 text-blue-600" />
                </div>
                <div>
                  <p className="text-sm text-muted-foreground">Total Orders</p>
                  <p className="text-lg font-semibold">{userProfile.total_orders || 0}</p>
                </div>
              </div>
              
              <div className="flex items-center gap-3">
                <div className="bg-green-100 p-2 rounded-lg">
                  <DollarSign className="h-5 w-5 text-green-600" />
                </div>
                <div>
                  <p className="text-sm text-muted-foreground">Lifetime Value</p>
                  <p className="text-lg font-semibold">
                    {formatCurrency(userProfile.lifetime_value || 0)}
                  </p>
                </div>
              </div>
              
              <div className="flex items-center gap-3">
                <div className="bg-purple-100 p-2 rounded-lg">
                  <Star className="h-5 w-5 text-purple-600" />
                </div>
                <div>
                  <p className="text-sm text-muted-foreground">Member Tier</p>
                  <Badge variant="outline" className="capitalize">
                    {userProfile.customer_segment || 'Bronze'}
                  </Badge>
                </div>
              </div>
              
              <div className="flex items-center gap-3">
                <div className="bg-orange-100 p-2 rounded-lg">
                  <Calendar className="h-5 w-5 text-orange-600" />
                </div>
                <div>
                  <p className="text-sm text-muted-foreground">Last Purchase</p>
                  <p className="text-sm">
                    {userProfile.last_purchase_at
                      ? new Date(userProfile.last_purchase_at).toLocaleDateString()
                      : 'Never'
                    }
                  </p>
                </div>
              </div>
            </div>
          </CardContent>
        </Card>
      )}

      {/* Filters and Search */}
      <Card>
        <CardContent className="pt-6">
          <div className="flex flex-col sm:flex-row gap-4">
            <div className="flex-1">
              <Label htmlFor="search">Search Orders</Label>
              <Input
                id="search"
                placeholder="Search by order number or product name..."
                value={searchTerm}
                onChange={(e) => setSearchTerm(e.target.value)}
              />
            </div>
            
            <div>
              <Label htmlFor="status">Filter by Status</Label>
              <select
                id="status"
                value={filterStatus}
                onChange={(e) => setFilterStatus(e.target.value)}
                className="flex h-10 w-full rounded-md border border-input bg-background px-3 py-2 text-sm ring-offset-background"
              >
                <option value="all">All Orders</option>
                <option value="pending">Pending</option>
                <option value="processing">Processing</option>
                <option value="shipped">Shipped</option>
                <option value="delivered">Delivered</option>
                <option value="cancelled">Cancelled</option>
              </select>
            </div>
          </div>
        </CardContent>
      </Card>

      {/* Orders List */}
      {orders.length === 0 ? (
        <Card>
          <CardContent className="flex flex-col items-center py-8">
            <ShoppingBag className="h-12 w-12 text-muted-foreground mb-4" />
            <h3 className="text-lg font-semibold mb-2">No orders found</h3>
            <p className="text-muted-foreground text-center">
              {searchTerm || filterStatus !== 'all'
                ? 'Try adjusting your search or filter criteria.'
                : 'You haven\'t placed any orders yet. Start shopping to see your orders here!'
              }
            </p>
          </CardContent>
        </Card>
      ) : (
        <div className="space-y-4">
          {orders.map((order) => (
            <Card key={order.id} className="cursor-pointer hover:shadow-md transition-shadow">
              <CardContent className="p-6">
                <div className="flex items-start justify-between">
                  <div className="flex-1">
                    <div className="flex items-center gap-3 mb-2">
                      <h3 className="font-semibold text-lg">#{order.order_number}</h3>
                      <Badge className={`${getStatusColor(order.status)} flex items-center gap-1`}>
                        {getStatusIcon(order.status)}
                        {order.status.charAt(0).toUpperCase() + order.status.slice(1)}
                      </Badge>
                      {order.payment_status === 'paid' && (
                        <Badge variant="outline" className="text-green-600">
                          <CheckCircle className="h-3 w-3 mr-1" />
                          Paid
                        </Badge>
                      )}
                    </div>
                    
                    <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4 text-sm text-muted-foreground">
                      <div>
                        <p className="font-medium">Order Date</p>
                        <p>{formatDate(order.created_at)}</p>
                      </div>
                      
                      <div>
                        <p className="font-medium">Total</p>
                        <p className="text-lg font-semibold text-foreground">
                          {formatCurrency(order.total_amount, order.currency)}
                        </p>
                      </div>
                      
                      <div>
                        <p className="font-medium">Items</p>
                        <p>{order.order_items.reduce((sum, item) => sum + item.quantity, 0)} items</p>
                      </div>
                      
                      <div>
                        <p className="font-medium">Delivery</p>
                        <p>
                          {order.order_fulfillment?.[0]?.estimated_delivery
                            ? formatDate(order.order_fulfillment[0].estimated_delivery)
                            : 'Estimated 3-5 days'
                          }
                        </p>
                      </div>
                    </div>

                    {/* Order Items Preview */}
                    <div className="mt-4">
                      <div className="flex flex-wrap gap-2">
                        {order.order_items.slice(0, 3).map((item) => (
                          <div key={item.id} className="flex items-center gap-2 text-sm">
                            <div className="w-8 h-8 bg-muted rounded overflow-hidden">
                              {item.products.image_url && (
                                <img
                                  src={item.products.image_url}
                                  alt={item.products.name}
                                  className="w-full h-full object-cover"
                                />
                              )}
                            </div>
                            <span>{item.products.name}</span>
                            <span className="text-muted-foreground">×{item.quantity}</span>
                          </div>
                        ))}
                        {order.order_items.length > 3 && (
                          <span className="text-sm text-muted-foreground">
                            +{order.order_items.length - 3} more items
                          </span>
                        )}
                      </div>
                    </div>
                  </div>

                  {/* Action Buttons */}
                  <div className="flex flex-col gap-2 ml-4">
                    <Button
                      variant="outline"
                      size="sm"
                      onClick={() => handleViewOrder(order)}
                    >
                      <Eye className="h-4 w-4 mr-1" />
                      View
                    </Button>
                    
                    {order.order_fulfillment?.[0]?.tracking_number && (
                      <Button
                        variant="outline"
                        size="sm"
                        onClick={() => handleTrackOrder(order)}
                      >
                        <Truck className="h-4 w-4 mr-1" />
                        Track
                      </Button>
                    )}
                    
                    <Button
                      variant="outline"
                      size="sm"
                      onClick={() => handleDownloadInvoice(order)}
                    >
                      <Download className="h-4 w-4 mr-1" />
                      Invoice
                    </Button>
                    
                    {order.status === 'delivered' && (
                      <Button
                        variant="outline"
                        size="sm"
                        onClick={() => handleReorder(order)}
                      >
                        <RefreshCw className="h-4 w-4 mr-1" />
                        Reorder
                      </Button>
                    )}
                  </div>
                </div>
              </CardContent>
            </Card>
          ))}
        </div>
      )}

      {/* Order Detail Modal/Drawer would go here */}
      {selectedOrder && (
        <OrderDetailModal
          order={selectedOrder}
          onClose={() => setSelectedOrder(null)}
        />
      )}
    </div>
  );
}

// Order Detail Modal Component
function OrderDetailModal({ order, onClose }: { order: Order; onClose: () => void }) {
  return (
    <div className="fixed inset-0 bg-black/50 flex items-center justify-center p-4 z-50">
      <div className="bg-white rounded-lg max-w-4xl w-full max-h-[90vh] overflow-auto">
        <div className="p-6">
          <div className="flex items-center justify-between mb-6">
            <h2 className="text-2xl font-bold">Order #{order.order_number}</h2>
            <Button variant="outline" onClick={onClose}>
              ×
            </Button>
          </div>

          <Tabs defaultValue="details" className="w-full">
            <TabsList className="grid w-full grid-cols-3">
              <TabsTrigger value="details">Order Details</TabsTrigger>
              <TabsTrigger value="tracking">Tracking</TabsTrigger>
              <TabsTrigger value="support">Support</TabsTrigger>
            </TabsList>

            <TabsContent value="details" className="space-y-6">
              {/* Order Status */}
              <Card>
                <CardHeader>
                  <CardTitle>Order Status</CardTitle>
                </CardHeader>
                <CardContent>
                  <div className="flex items-center gap-2 mb-4">
                    <Badge className={`${getStatusColor(order.status)} flex items-center gap-1`}>
                      {getStatusIcon(order.status)}
                      {order.status.charAt(0).toUpperCase() + order.status.slice(1)}
                    </Badge>
                    <Badge variant="outline" className="text-green-600">
                      <CheckCircle className="h-3 w-3 mr-1" />
                      Payment Confirmed
                    </Badge>
                  </div>
                  
                  <div className="grid grid-cols-2 gap-4 text-sm">
                    <div>
                      <p className="font-medium">Order Date</p>
                      <p>{formatDate(order.created_at)}</p>
                    </div>
                    <div>
                      <p className="font-medium">Last Updated</p>
                      <p>{formatDate(order.updated_at)}</p>
                    </div>
                  </div>
                </CardContent>
              </Card>

              {/* Order Items */}
              <Card>
                <CardHeader>
                  <CardTitle>Items Ordered</CardTitle>
                </CardHeader>
                <CardContent>
                  <div className="space-y-4">
                    {order.order_items.map((item) => (
                      <div key={item.id} className="flex items-center gap-4 p-4 border rounded-lg">
                        <div className="w-16 h-16 bg-muted rounded overflow-hidden">
                          {item.products.image_url && (
                            <img
                              src={item.products.image_url}
                              alt={item.products.name}
                              className="w-full h-full object-cover"
                            />
                          )}
                        </div>
                        
                        <div className="flex-1">
                          <h4 className="font-medium">{item.products.name}</h4>
                          {item.product_variants.title && (
                            <p className="text-sm text-muted-foreground">
                              {item.product_variants.title}
                            </p>
                          )}
                          {item.product_variants.sku && (
                            <p className="text-xs text-muted-foreground">
                              SKU: {item.product_variants.sku}
                            </p>
                          )}
                        </div>
                        
                        <div className="text-right">
                          <p className="font-medium">
                            ${item.unit_price.toFixed(2)} × {item.quantity}
                          </p>
                          <p className="text-lg font-semibold">
                            ${item.total_price.toFixed(2)}
                          </p>
                        </div>
                      </div>
                    ))}
                  </div>
                  
                  <Separator className="my-4" />
                  
                  <div className="text-right">
                    <p className="text-xl font-bold">
                      Total: ${order.total_amount.toFixed(2)}
                    </p>
                  </div>
                </CardContent>
              </Card>

              {/* Addresses */}
              <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
                {order.shipping_address && (
                  <Card>
                    <CardHeader>
                      <CardTitle className="flex items-center gap-2">
                        <MapPin className="h-4 w-4" />
                        Shipping Address
                      </CardTitle>
                    </CardHeader>
                    <CardContent>
                      <div className="text-sm space-y-1">
                        <p>{order.shipping_address.name}</p>
                        <p>{order.shipping_address.address.line1}</p>
                        {order.shipping_address.address.line2 && (
                          <p>{order.shipping_address.address.line2}</p>
                        )}
                        <p>
                          {order.shipping_address.address.city}, {order.shipping_address.address.state} {order.shipping_address.address.postal_code}
                        </p>
                        <p>{order.shipping_address.address.country}</p>
                      </div>
                    </CardContent>
                  </Card>
                )}

                {order.billing_address && (
                  <Card>
                    <CardHeader>
                      <CardTitle className="flex items-center gap-2">
                        <CreditCard className="h-4 w-4" />
                        Billing Address
                      </CardTitle>
                    </CardHeader>
                    <CardContent>
                      <div className="text-sm space-y-1">
                        <p>{order.billing_address.name}</p>
                        <p>{order.billing_address.line1}</p>
                        {order.billing_address.line2 && (
                          <p>{order.billing_address.line2}</p>
                        )}
                        <p>
                          {order.billing_address.city}, {order.billing_address.state} {order.billing_address.postal_code}
                        </p>
                        <p>{order.billing_address.country}</p>
                      </div>
                    </CardContent>
                  </Card>
                )}
              </div>
            </TabsContent>

            <TabsContent value="tracking">
              <Card>
                <CardHeader>
                  <CardTitle>Order Tracking</CardTitle>
                </CardHeader>
                <CardContent>
                  {order.order_fulfillment?.[0] ? (
                    <div className="space-y-4">
                      <div className="grid grid-cols-2 gap-4">
                        <div>
                          <p className="font-medium">Tracking Number</p>
                          <p className="font-mono text-sm">
                            {order.order_fulfillment[0].tracking_number}
                          </p>
                        </div>
                        <div>
                          <p className="font-medium">Carrier</p>
                          <p>{order.order_fulfillment[0].carrier}</p>
                        </div>
                      </div>
                      
                      {order.order_fulfillment[0].estimated_delivery && (
                        <div>
                          <p className="font-medium">Estimated Delivery</p>
                          <p>{formatDate(order.order_fulfillment[0].estimated_delivery)}</p>
                        </div>
                      )}
                      
                      <Button
                        onClick={() => {
                          const trackingUrl = `https://www.ups.com/track?tracknum=${order.order_fulfillment[0].tracking_number}`;
                          window.open(trackingUrl, '_blank');
                        }}
                      >
                        Track with Carrier
                      </Button>
                    </div>
                  ) : (
                    <Alert>
                      <Clock className="h-4 w-4" />
                      <AlertDescription>
                        Your order is being prepared for shipment. Tracking information will be available once your order ships.
                      </AlertDescription>
                    </Alert>
                  )}
                </CardContent>
              </Card>
            </TabsContent>

            <TabsContent value="support">
              <Card>
                <CardHeader>
                  <CardTitle className="flex items-center gap-2">
                    <MessageSquare className="h-4 w-4" />
                    Customer Support
                  </CardTitle>
                </CardHeader>
                <CardContent>
                  <div className="space-y-4">
                    <Alert>
                      <AlertCircle className="h-4 w-4" />
                      <AlertDescription>
                        Need help with your order? Our customer service team is here to assist you.
                      </AlertDescription>
                    </Alert>
                    
                    <div className="space-y-2">
                      <p><strong>Email:</strong> support@kctmenswear.com</p>
                      <p><strong>Phone:</strong> 1-800-KCT-WEAR</p>
                      <p><strong>Hours:</strong> Monday-Friday 9AM-6PM EST</p>
                    </div>
                    
                    <div className="space-y-2">
                      <Button variant="outline" className="w-full">
                        Start Live Chat
                      </Button>
                      <Button variant="outline" className="w-full">
                        Request Return/Exchange
                      </Button>
                    </div>
                  </div>
                </CardContent>
              </Card>
            </TabsContent>
          </Tabs>
        </div>
      </div>
    </div>
  );
}

const getStatusIcon = (status: string) => {
  switch (status) {
    case 'pending':
      return <Clock className="h-4 w-4" />;
    case 'processing':
      return <Package className="h-4 w-4" />;
    case 'shipped':
      return <Truck className="h-4 w-4" />;
    case 'delivered':
      return <CheckCircle className="h-4 w-4" />;
    case 'cancelled':
      return <AlertCircle className="h-4 w-4" />;
    default:
      return <Clock className="h-4 w-4" />;
  }
};

const getStatusColor = (status: string) => {
  switch (status) {
    case 'pending':
      return 'bg-yellow-100 text-yellow-800';
    case 'processing':
      return 'bg-blue-100 text-blue-800';
    case 'shipped':
      return 'bg-purple-100 text-purple-800';
    case 'delivered':
      return 'bg-green-100 text-green-800';
    case 'cancelled':
      return 'bg-red-100 text-red-800';
    default:
      return 'bg-gray-100 text-gray-800';
  }
};