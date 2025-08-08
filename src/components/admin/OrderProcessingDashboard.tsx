import React, { useState, useEffect } from 'react';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { Badge } from '@/components/ui/badge';
import { Input } from '@/components/ui/input';
import { Label } from '@/components/ui/label';
import { Textarea } from '@/components/ui/textarea';
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from '@/components/ui/select';
import { Dialog, DialogContent, DialogDescription, DialogFooter, DialogHeader, DialogTitle } from '@/components/ui/dialog';
import { Tabs, TabsContent, TabsList, TabsTrigger } from '@/components/ui/tabs';
import { Alert, AlertDescription } from '@/components/ui/alert';
import { Separator } from '@/components/ui/separator';
import { ScrollArea } from '@/components/ui/scroll-area';
import { Checkbox } from '@/components/ui/checkbox';
import {
  Package,
  Truck,
  CheckCircle,
  XCircle,
  Clock,
  AlertCircle,
  RefreshCw,
  Download,
  Printer,
  Mail,
  FileText,
  Calendar,
  MapPin,
  User,
  Phone,
  CreditCard,
  ChevronRight,
  Loader2,
  PackageCheck,
  PackageX,
  TruckIcon,
  Home
} from 'lucide-react';
import { useToast } from '@/hooks/use-toast';
import { supabase } from '@/lib/supabase-client';
import {
  updateOrderStatus,
  updateTrackingInfo,
  generateShippingLabel,
  getOrderDetails,
  getOrderTimeline,
  bulkUpdateOrderStatus,
  exportOrdersToCSV,
  ORDER_STATUS_FLOW,
  ORDER_STATUS_DESCRIPTIONS
} from '@/lib/services/orderService';

interface Order {
  id: string;
  order_number: string;
  status: string;
  total_amount: number;
  created_at: string;
  customer?: any;
  items?: any[];
  shipping_address?: any;
  tracking_number?: string;
  carrier_name?: string;
  estimated_delivery?: string;
  priority?: string;
}

export function OrderProcessingDashboard() {
  const [orders, setOrders] = useState<Order[]>([]);
  const [selectedOrders, setSelectedOrders] = useState<string[]>([]);
  const [selectedOrder, setSelectedOrder] = useState<Order | null>(null);
  const [orderTimeline, setOrderTimeline] = useState<any[]>([]);
  const [loading, setLoading] = useState(false);
  const [processingOrder, setProcessingOrder] = useState<string | null>(null);
  const [statusFilter, setStatusFilter] = useState('all');
  const [showBulkActions, setShowBulkActions] = useState(false);
  const [showTrackingDialog, setShowTrackingDialog] = useState(false);
  const [showStatusDialog, setShowStatusDialog] = useState(false);
  const [showShippingDialog, setShowShippingDialog] = useState(false);
  
  // Form states
  const [trackingForm, setTrackingForm] = useState({
    trackingNumber: '',
    carrier: 'usps',
    estimatedDelivery: ''
  });
  
  const [statusForm, setStatusForm] = useState({
    newStatus: '',
    notes: ''
  });

  const [shippingForm, setShippingForm] = useState({
    carrier: 'usps',
    serviceType: 'standard',
    weight: 1,
    length: 10,
    width: 8,
    height: 6
  });

  const { toast } = useToast();

  useEffect(() => {
    loadOrders();
  }, [statusFilter]);

  const loadOrders = async () => {
    try {
      setLoading(true);
      let query = supabase
        .from('orders')
        .select(`
          *,
          customers!left(
            id,
            first_name,
            last_name,
            email,
            phone
          )
        `)
        .order('created_at', { ascending: false });

      if (statusFilter !== 'all') {
        query = query.eq('status', statusFilter);
      }

      const { data, error } = await query;
      if (error) throw error;

      setOrders(data || []);
    } catch (error) {
      console.error('Error loading orders:', error);
      toast({
        title: 'Error',
        description: 'Failed to load orders',
        variant: 'destructive'
      });
    } finally {
      setLoading(false);
    }
  };

  const handleStatusUpdate = async () => {
    if (!selectedOrder || !statusForm.newStatus) return;

    try {
      setProcessingOrder(selectedOrder.id);
      
      await updateOrderStatus({
        orderId: selectedOrder.id,
        newStatus: statusForm.newStatus,
        notes: statusForm.notes
      });

      toast({
        title: 'Success',
        description: `Order ${selectedOrder.order_number} status updated to ${statusForm.newStatus}`
      });

      setShowStatusDialog(false);
      setStatusForm({ newStatus: '', notes: '' });
      loadOrders();
    } catch (error: any) {
      toast({
        title: 'Error',
        description: error.message || 'Failed to update order status',
        variant: 'destructive'
      });
    } finally {
      setProcessingOrder(null);
    }
  };

  const handleTrackingUpdate = async () => {
    if (!selectedOrder || !trackingForm.trackingNumber) return;

    try {
      setProcessingOrder(selectedOrder.id);
      
      await updateTrackingInfo(
        selectedOrder.id,
        trackingForm.trackingNumber,
        trackingForm.carrier,
        trackingForm.estimatedDelivery
      );

      // Also update status to shipped if it's not already
      if (selectedOrder.status === 'processing' || selectedOrder.status === 'confirmed') {
        await updateOrderStatus({
          orderId: selectedOrder.id,
          newStatus: 'shipped',
          trackingNumber: trackingForm.trackingNumber,
          carrierName: trackingForm.carrier,
          estimatedDelivery: trackingForm.estimatedDelivery
        });
      }

      toast({
        title: 'Success',
        description: 'Tracking information updated'
      });

      setShowTrackingDialog(false);
      setTrackingForm({ trackingNumber: '', carrier: 'usps', estimatedDelivery: '' });
      loadOrders();
    } catch (error: any) {
      toast({
        title: 'Error',
        description: error.message || 'Failed to update tracking',
        variant: 'destructive'
      });
    } finally {
      setProcessingOrder(null);
    }
  };

  const handleGenerateLabel = async () => {
    if (!selectedOrder) return;

    try {
      setProcessingOrder(selectedOrder.id);
      
      const label = await generateShippingLabel({
        orderId: selectedOrder.id,
        carrier: shippingForm.carrier as any,
        serviceType: shippingForm.serviceType,
        weight: shippingForm.weight,
        dimensions: {
          length: shippingForm.length,
          width: shippingForm.width,
          height: shippingForm.height
        }
      });

      toast({
        title: 'Success',
        description: 'Shipping label generated successfully'
      });

      setShowShippingDialog(false);
      loadOrders();
    } catch (error: any) {
      toast({
        title: 'Error',
        description: error.message || 'Failed to generate shipping label',
        variant: 'destructive'
      });
    } finally {
      setProcessingOrder(null);
    }
  };

  const handleBulkStatusUpdate = async (newStatus: string) => {
    if (selectedOrders.length === 0) return;

    try {
      setLoading(true);
      const results = await bulkUpdateOrderStatus(selectedOrders, newStatus);
      
      toast({
        title: 'Bulk Update Complete',
        description: `${results.successful.length} orders updated, ${results.failed.length} failed`
      });

      setSelectedOrders([]);
      setShowBulkActions(false);
      loadOrders();
    } catch (error) {
      toast({
        title: 'Error',
        description: 'Failed to update orders',
        variant: 'destructive'
      });
    } finally {
      setLoading(false);
    }
  };

  const loadOrderDetails = async (orderId: string) => {
    try {
      const [details, timeline] = await Promise.all([
        getOrderDetails(orderId),
        getOrderTimeline(orderId)
      ]);
      
      setSelectedOrder(details);
      setOrderTimeline(timeline);
    } catch (error) {
      console.error('Error loading order details:', error);
    }
  };

  const getStatusColor = (status: string) => {
    const colors: Record<string, string> = {
      pending: 'bg-yellow-500',
      confirmed: 'bg-blue-500',
      processing: 'bg-indigo-500',
      shipped: 'bg-purple-500',
      delivered: 'bg-green-500',
      cancelled: 'bg-red-500',
      refunded: 'bg-gray-500'
    };
    return colors[status] || 'bg-gray-500';
  };

  const getStatusIcon = (status: string) => {
    const icons: Record<string, any> = {
      pending: Clock,
      confirmed: CheckCircle,
      processing: Package,
      shipped: Truck,
      delivered: Home,
      cancelled: XCircle,
      refunded: RefreshCw
    };
    const Icon = icons[status] || AlertCircle;
    return <Icon className="h-4 w-4" />;
  };

  const getPriorityColor = (priority: string) => {
    const colors: Record<string, string> = {
      urgent: 'destructive',
      high: 'default',
      normal: 'secondary',
      low: 'outline'
    };
    return colors[priority] || 'secondary';
  };

  return (
    <div className="space-y-6">
      {/* Header */}
      <div className="flex justify-between items-center">
        <div>
          <h2 className="text-2xl font-bold">Order Processing</h2>
          <p className="text-muted-foreground">Manage order fulfillment and shipping</p>
        </div>
        <div className="flex gap-2">
          <Button
            variant="outline"
            onClick={() => exportOrdersToCSV(orders)}
          >
            <Download className="h-4 w-4 mr-2" />
            Export
          </Button>
          <Button onClick={loadOrders}>
            <RefreshCw className="h-4 w-4 mr-2" />
            Refresh
          </Button>
        </div>
      </div>

      {/* Status Filters */}
      <div className="flex gap-2 flex-wrap">
        <Button
          variant={statusFilter === 'all' ? 'default' : 'outline'}
          size="sm"
          onClick={() => setStatusFilter('all')}
        >
          All Orders
        </Button>
        {['pending', 'confirmed', 'processing', 'shipped', 'delivered'].map(status => (
          <Button
            key={status}
            variant={statusFilter === status ? 'default' : 'outline'}
            size="sm"
            onClick={() => setStatusFilter(status)}
          >
            {status.charAt(0).toUpperCase() + status.slice(1)}
          </Button>
        ))}
      </div>

      {/* Bulk Actions */}
      {selectedOrders.length > 0 && (
        <Alert>
          <AlertDescription className="flex items-center justify-between">
            <span>{selectedOrders.length} orders selected</span>
            <div className="flex gap-2">
              <Button
                size="sm"
                variant="outline"
                onClick={() => handleBulkStatusUpdate('processing')}
              >
                Mark Processing
              </Button>
              <Button
                size="sm"
                variant="outline"
                onClick={() => handleBulkStatusUpdate('shipped')}
              >
                Mark Shipped
              </Button>
              <Button
                size="sm"
                variant="ghost"
                onClick={() => setSelectedOrders([])}
              >
                Clear Selection
              </Button>
            </div>
          </AlertDescription>
        </Alert>
      )}

      {/* Orders List */}
      <div className="space-y-4">
        {loading ? (
          <div className="flex justify-center py-8">
            <Loader2 className="h-8 w-8 animate-spin" />
          </div>
        ) : orders.length === 0 ? (
          <Card>
            <CardContent className="text-center py-8">
              <Package className="h-12 w-12 mx-auto mb-4 text-muted-foreground" />
              <p className="text-muted-foreground">No orders to process</p>
            </CardContent>
          </Card>
        ) : (
          orders.map(order => (
            <Card key={order.id} className="relative">
              <CardContent className="pt-6">
                <div className="flex items-start justify-between">
                  <div className="flex items-start gap-4">
                    <Checkbox
                      checked={selectedOrders.includes(order.id)}
                      onCheckedChange={(checked) => {
                        if (checked) {
                          setSelectedOrders([...selectedOrders, order.id]);
                        } else {
                          setSelectedOrders(selectedOrders.filter(id => id !== order.id));
                        }
                      }}
                    />
                    <div className="space-y-2">
                      <div className="flex items-center gap-2">
                        <h3 className="font-semibold">#{order.order_number}</h3>
                        <Badge className={`${getStatusColor(order.status)} text-white`}>
                          <span className="flex items-center gap-1">
                            {getStatusIcon(order.status)}
                            {order.status}
                          </span>
                        </Badge>
                        {order.priority && order.priority !== 'normal' && (
                          <Badge variant={getPriorityColor(order.priority) as any}>
                            {order.priority}
                          </Badge>
                        )}
                      </div>
                      <div className="text-sm text-muted-foreground space-y-1">
                        <div className="flex items-center gap-4">
                          <span className="flex items-center gap-1">
                            <User className="h-3 w-3" />
                            {order.customer?.first_name} {order.customer?.last_name}
                          </span>
                          <span className="flex items-center gap-1">
                            <Mail className="h-3 w-3" />
                            {order.customer?.email}
                          </span>
                        </div>
                        <div className="flex items-center gap-4">
                          <span className="flex items-center gap-1">
                            <Calendar className="h-3 w-3" />
                            {new Date(order.created_at).toLocaleDateString()}
                          </span>
                          <span className="flex items-center gap-1">
                            <CreditCard className="h-3 w-3" />
                            ${(order.total_amount / 100).toFixed(2)}
                          </span>
                          {order.tracking_number && (
                            <span className="flex items-center gap-1">
                              <Truck className="h-3 w-3" />
                              {order.carrier_name}: {order.tracking_number}
                            </span>
                          )}
                        </div>
                      </div>
                    </div>
                  </div>
                  <div className="flex gap-2">
                    {order.status === 'confirmed' && (
                      <Button
                        size="sm"
                        variant="outline"
                        onClick={() => {
                          setSelectedOrder(order);
                          setShowShippingDialog(true);
                        }}
                        disabled={processingOrder === order.id}
                      >
                        <Printer className="h-4 w-4 mr-1" />
                        Generate Label
                      </Button>
                    )}
                    {['confirmed', 'processing'].includes(order.status) && (
                      <Button
                        size="sm"
                        variant="outline"
                        onClick={() => {
                          setSelectedOrder(order);
                          setShowTrackingDialog(true);
                        }}
                        disabled={processingOrder === order.id}
                      >
                        <Truck className="h-4 w-4 mr-1" />
                        Add Tracking
                      </Button>
                    )}
                    <Button
                      size="sm"
                      variant="outline"
                      onClick={() => {
                        setSelectedOrder(order);
                        loadOrderDetails(order.id);
                        setShowStatusDialog(true);
                      }}
                      disabled={processingOrder === order.id}
                    >
                      {processingOrder === order.id ? (
                        <Loader2 className="h-4 w-4 animate-spin" />
                      ) : (
                        <>
                          <RefreshCw className="h-4 w-4 mr-1" />
                          Update Status
                        </>
                      )}
                    </Button>
                  </div>
                </div>
              </CardContent>
            </Card>
          ))
        )}
      </div>

      {/* Update Status Dialog */}
      <Dialog open={showStatusDialog} onOpenChange={setShowStatusDialog}>
        <DialogContent className="max-w-2xl">
          <DialogHeader>
            <DialogTitle>Update Order Status</DialogTitle>
            <DialogDescription>
              Order #{selectedOrder?.order_number}
            </DialogDescription>
          </DialogHeader>
          
          {selectedOrder && (
            <div className="space-y-4">
              <div className="flex items-center gap-2">
                <Badge className={`${getStatusColor(selectedOrder.status)} text-white`}>
                  Current: {selectedOrder.status}
                </Badge>
                <ChevronRight className="h-4 w-4" />
                <Select
                  value={statusForm.newStatus}
                  onValueChange={(value) => setStatusForm({ ...statusForm, newStatus: value })}
                >
                  <SelectTrigger className="w-48">
                    <SelectValue placeholder="Select new status" />
                  </SelectTrigger>
                  <SelectContent>
                    {ORDER_STATUS_FLOW[selectedOrder.status as keyof typeof ORDER_STATUS_FLOW].map(status => (
                      <SelectItem key={status} value={status}>
                        {status.charAt(0).toUpperCase() + status.slice(1)}
                      </SelectItem>
                    ))}
                  </SelectContent>
                </Select>
              </div>

              <div className="space-y-2">
                <Label>Notes (Optional)</Label>
                <Textarea
                  value={statusForm.notes}
                  onChange={(e) => setStatusForm({ ...statusForm, notes: e.target.value })}
                  placeholder="Add any notes about this status change..."
                  rows={3}
                />
              </div>

              {orderTimeline.length > 0 && (
                <>
                  <Separator />
                  <div>
                    <h4 className="font-medium mb-2">Order Timeline</h4>
                    <ScrollArea className="h-48">
                      <div className="space-y-2">
                        {orderTimeline.map((event, index) => (
                          <div key={event.id} className="flex items-start gap-3 text-sm">
                            <div className={`w-2 h-2 rounded-full mt-1.5 ${index === 0 ? 'bg-primary' : 'bg-muted-foreground'}`} />
                            <div className="flex-1">
                              <div className="flex items-center gap-2">
                                <span className="font-medium">{event.status}</span>
                                <span className="text-muted-foreground">
                                  {new Date(event.created_at).toLocaleString()}
                                </span>
                              </div>
                              {event.notes && (
                                <p className="text-muted-foreground">{event.notes}</p>
                              )}
                            </div>
                          </div>
                        ))}
                      </div>
                    </ScrollArea>
                  </div>
                </>
              )}
            </div>
          )}

          <DialogFooter>
            <Button variant="outline" onClick={() => setShowStatusDialog(false)}>
              Cancel
            </Button>
            <Button onClick={handleStatusUpdate} disabled={!statusForm.newStatus || processingOrder !== null}>
              Update Status
            </Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>

      {/* Add Tracking Dialog */}
      <Dialog open={showTrackingDialog} onOpenChange={setShowTrackingDialog}>
        <DialogContent>
          <DialogHeader>
            <DialogTitle>Add Tracking Information</DialogTitle>
            <DialogDescription>
              Order #{selectedOrder?.order_number}
            </DialogDescription>
          </DialogHeader>
          
          <div className="space-y-4">
            <div className="space-y-2">
              <Label>Tracking Number</Label>
              <Input
                value={trackingForm.trackingNumber}
                onChange={(e) => setTrackingForm({ ...trackingForm, trackingNumber: e.target.value })}
                placeholder="Enter tracking number"
              />
            </div>

            <div className="space-y-2">
              <Label>Carrier</Label>
              <Select
                value={trackingForm.carrier}
                onValueChange={(value) => setTrackingForm({ ...trackingForm, carrier: value })}
              >
                <SelectTrigger>
                  <SelectValue />
                </SelectTrigger>
                <SelectContent>
                  <SelectItem value="usps">USPS</SelectItem>
                  <SelectItem value="ups">UPS</SelectItem>
                  <SelectItem value="fedex">FedEx</SelectItem>
                  <SelectItem value="dhl">DHL</SelectItem>
                </SelectContent>
              </Select>
            </div>

            <div className="space-y-2">
              <Label>Estimated Delivery (Optional)</Label>
              <Input
                type="date"
                value={trackingForm.estimatedDelivery}
                onChange={(e) => setTrackingForm({ ...trackingForm, estimatedDelivery: e.target.value })}
              />
            </div>
          </div>

          <DialogFooter>
            <Button variant="outline" onClick={() => setShowTrackingDialog(false)}>
              Cancel
            </Button>
            <Button onClick={handleTrackingUpdate} disabled={!trackingForm.trackingNumber || processingOrder !== null}>
              Add Tracking
            </Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>

      {/* Generate Shipping Label Dialog */}
      <Dialog open={showShippingDialog} onOpenChange={setShowShippingDialog}>
        <DialogContent>
          <DialogHeader>
            <DialogTitle>Generate Shipping Label</DialogTitle>
            <DialogDescription>
              Order #{selectedOrder?.order_number}
            </DialogDescription>
          </DialogHeader>
          
          <div className="space-y-4">
            <div className="grid grid-cols-2 gap-4">
              <div className="space-y-2">
                <Label>Carrier</Label>
                <Select
                  value={shippingForm.carrier}
                  onValueChange={(value) => setShippingForm({ ...shippingForm, carrier: value })}
                >
                  <SelectTrigger>
                    <SelectValue />
                  </SelectTrigger>
                  <SelectContent>
                    <SelectItem value="usps">USPS</SelectItem>
                    <SelectItem value="ups">UPS</SelectItem>
                    <SelectItem value="fedex">FedEx</SelectItem>
                    <SelectItem value="dhl">DHL</SelectItem>
                  </SelectContent>
                </Select>
              </div>

              <div className="space-y-2">
                <Label>Service Type</Label>
                <Select
                  value={shippingForm.serviceType}
                  onValueChange={(value) => setShippingForm({ ...shippingForm, serviceType: value })}
                >
                  <SelectTrigger>
                    <SelectValue />
                  </SelectTrigger>
                  <SelectContent>
                    <SelectItem value="standard">Standard</SelectItem>
                    <SelectItem value="express">Express</SelectItem>
                    <SelectItem value="overnight">Overnight</SelectItem>
                  </SelectContent>
                </Select>
              </div>
            </div>

            <div className="space-y-2">
              <Label>Package Weight (lbs)</Label>
              <Input
                type="number"
                value={shippingForm.weight}
                onChange={(e) => setShippingForm({ ...shippingForm, weight: parseFloat(e.target.value) })}
                min="0.1"
                step="0.1"
              />
            </div>

            <div className="space-y-2">
              <Label>Package Dimensions (inches)</Label>
              <div className="grid grid-cols-3 gap-2">
                <Input
                  type="number"
                  value={shippingForm.length}
                  onChange={(e) => setShippingForm({ ...shippingForm, length: parseFloat(e.target.value) })}
                  placeholder="Length"
                  min="1"
                />
                <Input
                  type="number"
                  value={shippingForm.width}
                  onChange={(e) => setShippingForm({ ...shippingForm, width: parseFloat(e.target.value) })}
                  placeholder="Width"
                  min="1"
                />
                <Input
                  type="number"
                  value={shippingForm.height}
                  onChange={(e) => setShippingForm({ ...shippingForm, height: parseFloat(e.target.value) })}
                  placeholder="Height"
                  min="1"
                />
              </div>
            </div>

            {selectedOrder?.shipping_address && (
              <div className="p-3 bg-muted rounded-lg">
                <p className="text-sm font-medium mb-1">Shipping To:</p>
                <p className="text-sm">
                  {selectedOrder.shipping_address.line1}<br />
                  {selectedOrder.shipping_address.line2 && <>{selectedOrder.shipping_address.line2}<br /></>}
                  {selectedOrder.shipping_address.city}, {selectedOrder.shipping_address.state} {selectedOrder.shipping_address.postal_code}<br />
                  {selectedOrder.shipping_address.country}
                </p>
              </div>
            )}
          </div>

          <DialogFooter>
            <Button variant="outline" onClick={() => setShowShippingDialog(false)}>
              Cancel
            </Button>
            <Button onClick={handleGenerateLabel} disabled={processingOrder !== null}>
              Generate Label
            </Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>
    </div>
  );
}