/**
 * MANUAL ORDER CREATION & DROPSHIP MANAGEMENT
 * Create orders manually for vendor dropshipping and special fulfillment
 */

import React, { useState, useEffect } from 'react';
import { Button } from '@/components/ui/button';
import { Card, CardContent, CardHeader, CardTitle, CardDescription } from '@/components/ui/card';
import { Input } from '@/components/ui/input';
import { Label } from '@/components/ui/label';
import { Textarea } from '@/components/ui/textarea';
import { Badge } from '@/components/ui/badge';
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from '@/components/ui/select';
import { Tabs, TabsContent, TabsList, TabsTrigger } from '@/components/ui/tabs';
import { Alert, AlertDescription } from '@/components/ui/alert';
import { Separator } from '@/components/ui/separator';
import { Switch } from '@/components/ui/switch';
import { Checkbox } from '@/components/ui/checkbox';
import { toast } from 'sonner';
import { supabase } from '@/lib/supabase-client';
import { 
  Package, 
  Truck, 
  User,
  Plus,
  Minus,
  Search,
  MapPin,
  Phone,
  Mail,
  Building,
  CreditCard,
  ShoppingCart,
  Send,
  Save,
  Copy,
  FileText,
  AlertTriangle,
  CheckCircle,
  X,
  ChevronRight,
  Factory,
  Zap,
  DollarSign,
  Clock,
  RefreshCw
} from 'lucide-react';

interface Vendor {
  id: string;
  name: string;
  email: string;
  phone?: string;
  address?: any;
  dropship_enabled: boolean;
  auto_send_orders: boolean;
  products: string[]; // Product IDs this vendor supplies
  lead_time_days: number;
  notes?: string;
}

interface Customer {
  id: string;
  name: string;
  email: string;
  phone?: string;
  shipping_address?: any;
  billing_address?: any;
  order_count?: number;
}

interface Product {
  id: string;
  name: string;
  sku: string;
  base_price: number;
  vendor_id?: string;
  vendor_price?: number;
  variants?: any[];
}

interface OrderItem {
  product_id: string;
  product_name: string;
  variant_id?: string;
  variant_name?: string;
  quantity: number;
  price: number;
  vendor_id?: string;
  dropship: boolean;
}

export function ManualOrderCreation() {
  const [orderType, setOrderType] = useState<'regular' | 'dropship'>('regular');
  const [isCreating, setIsCreating] = useState(false);
  
  // Customer data
  const [customerSearch, setCustomerSearch] = useState('');
  const [customers, setCustomers] = useState<Customer[]>([]);
  const [selectedCustomer, setSelectedCustomer] = useState<Customer | null>(null);
  const [createNewCustomer, setCreateNewCustomer] = useState(false);
  const [newCustomer, setNewCustomer] = useState({
    name: '',
    email: '',
    phone: '',
    shipping_address: {
      line1: '',
      line2: '',
      city: '',
      state: '',
      postal_code: '',
      country: 'US'
    }
  });

  // Product selection
  const [productSearch, setProductSearch] = useState('');
  const [products, setProducts] = useState<Product[]>([]);
  const [orderItems, setOrderItems] = useState<OrderItem[]>([]);
  
  // Vendor management
  const [vendors, setVendors] = useState<Vendor[]>([]);
  const [selectedVendors, setSelectedVendors] = useState<Set<string>>(new Set());
  
  // Order details
  const [orderNotes, setOrderNotes] = useState('');
  const [sendCustomerNotification, setSendCustomerNotification] = useState(true);
  const [sendVendorNotification, setSendVendorNotification] = useState(true);
  const [paymentStatus, setPaymentStatus] = useState<'paid' | 'pending'>('paid');
  const [shippingMethod, setShippingMethod] = useState('standard');
  const [customShippingCost, setCustomShippingCost] = useState(0);
  
  // Quick templates
  const [orderTemplates] = useState([
    { id: 1, name: 'Single Item Dropship', type: 'dropship', items: 1 },
    { id: 2, name: 'Multi-Vendor Order', type: 'dropship', items: 3 },
    { id: 3, name: 'Rush Fulfillment', type: 'regular', priority: true }
  ]);

  useEffect(() => {
    loadVendors();
    loadProducts();
  }, []);

  useEffect(() => {
    if (customerSearch.length > 2) {
      searchCustomers();
    }
  }, [customerSearch]);

  useEffect(() => {
    if (productSearch.length > 2) {
      searchProducts();
    }
  }, [productSearch]);

  const loadVendors = async () => {
    try {
      const { data, error } = await supabase
        .from('vendors')
        .select('*')
        .eq('dropship_enabled', true)
        .order('name');

      if (!error && data) {
        setVendors(data);
      }
    } catch (error) {
      console.error('Failed to load vendors:', error);
    }
  };

  const loadProducts = async () => {
    try {
      const { data, error } = await supabase
        .from('products')
        .select(`
          *,
          product_variants (*)
        `)
        .eq('status', 'active')
        .limit(100);

      if (!error && data) {
        setProducts(data);
      }
    } catch (error) {
      console.error('Failed to load products:', error);
    }
  };

  const searchCustomers = async () => {
    try {
      const { data, error } = await supabase
        .from('customers')
        .select('*')
        .or(`name.ilike.%${customerSearch}%,email.ilike.%${customerSearch}%`)
        .limit(10);

      if (!error && data) {
        setCustomers(data);
      }
    } catch (error) {
      console.error('Failed to search customers:', error);
    }
  };

  const searchProducts = async () => {
    try {
      const { data, error } = await supabase
        .from('products')
        .select(`
          *,
          product_variants (*)
        `)
        .or(`name.ilike.%${productSearch}%,sku.ilike.%${productSearch}%`)
        .eq('status', 'active')
        .limit(20);

      if (!error && data) {
        setProducts(data);
      }
    } catch (error) {
      console.error('Failed to search products:', error);
    }
  };

  const addProductToOrder = (product: Product, variant?: any) => {
    const existingItem = orderItems.find(item => 
      item.product_id === product.id && 
      item.variant_id === variant?.id
    );

    if (existingItem) {
      // Increase quantity
      setOrderItems(prev => prev.map(item => 
        item.product_id === product.id && item.variant_id === variant?.id
          ? { ...item, quantity: item.quantity + 1 }
          : item
      ));
    } else {
      // Add new item
      const newItem: OrderItem = {
        product_id: product.id,
        product_name: product.name,
        variant_id: variant?.id,
        variant_name: variant ? `${variant.size || ''} ${variant.color || ''}`.trim() : '',
        quantity: 1,
        price: variant?.price || product.base_price,
        vendor_id: product.vendor_id,
        dropship: orderType === 'dropship' && !!product.vendor_id
      };
      
      setOrderItems(prev => [...prev, newItem]);
      
      // Auto-select vendor if dropship
      if (product.vendor_id && orderType === 'dropship') {
        setSelectedVendors(prev => new Set([...prev, product.vendor_id!]));
      }
    }

    toast.success(`Added ${product.name} to order`);
  };

  const updateItemQuantity = (index: number, delta: number) => {
    setOrderItems(prev => prev.map((item, i) => {
      if (i === index) {
        const newQuantity = Math.max(1, item.quantity + delta);
        return { ...item, quantity: newQuantity };
      }
      return item;
    }));
  };

  const removeItem = (index: number) => {
    setOrderItems(prev => prev.filter((_, i) => i !== index));
  };

  const calculateTotals = () => {
    const subtotal = orderItems.reduce((sum, item) => sum + (item.price * item.quantity), 0);
    const shipping = customShippingCost || (shippingMethod === 'express' ? 15 : 5);
    const tax = subtotal * 0.08; // 8% tax
    const total = subtotal + shipping + tax;

    return { subtotal, shipping, tax, total };
  };

  const createOrder = async () => {
    // Validation
    if (!selectedCustomer && !createNewCustomer) {
      toast.error('Please select or create a customer');
      return;
    }

    if (orderItems.length === 0) {
      toast.error('Please add at least one product');
      return;
    }

    setIsCreating(true);

    try {
      // Create or get customer
      let customerId = selectedCustomer?.id;
      
      if (createNewCustomer) {
        const { data: newCustomerData, error: customerError } = await supabase
          .from('customers')
          .insert({
            name: newCustomer.name,
            email: newCustomer.email,
            phone: newCustomer.phone,
            shipping_address: newCustomer.shipping_address,
            billing_address: newCustomer.shipping_address
          })
          .select()
          .single();

        if (customerError) throw customerError;
        customerId = newCustomerData.id;
      }

      const totals = calculateTotals();
      const orderNumber = `ORD-${Date.now().toString().slice(-8)}`;

      // Create main order
      const { data: order, error: orderError } = await supabase
        .from('orders')
        .insert({
          order_number: orderNumber,
          customer_id: customerId,
          status: 'processing',
          payment_status: paymentStatus,
          total_amount: totals.total,
          subtotal: totals.subtotal,
          tax_amount: totals.tax,
          shipping_amount: totals.shipping,
          shipping_address: selectedCustomer?.shipping_address || newCustomer.shipping_address,
          billing_address: selectedCustomer?.billing_address || newCustomer.shipping_address,
          notes: orderNotes,
          order_type: orderType,
          created_at: new Date().toISOString()
        })
        .select()
        .single();

      if (orderError) throw orderError;

      // Create order items
      const orderItemsData = orderItems.map(item => ({
        order_id: order.id,
        product_id: item.product_id,
        product_name: item.product_name,
        variant_id: item.variant_id,
        variant_name: item.variant_name,
        quantity: item.quantity,
        price: item.price
      }));

      const { error: itemsError } = await supabase
        .from('order_items')
        .insert(orderItemsData);

      if (itemsError) throw itemsError;

      // Handle dropship orders
      if (orderType === 'dropship' && selectedVendors.size > 0) {
        // Group items by vendor
        const vendorOrders = new Map<string, OrderItem[]>();
        
        orderItems.forEach(item => {
          if (item.vendor_id && item.dropship) {
            if (!vendorOrders.has(item.vendor_id)) {
              vendorOrders.set(item.vendor_id, []);
            }
            vendorOrders.get(item.vendor_id)!.push(item);
          }
        });

        // Create dropship orders for each vendor
        for (const [vendorId, items] of vendorOrders.entries()) {
          const vendor = vendors.find(v => v.id === vendorId);
          if (!vendor) continue;

          const dropshipOrder = {
            parent_order_id: order.id,
            vendor_id: vendorId,
            order_number: `${orderNumber}-${vendor.name.substring(0, 3).toUpperCase()}`,
            items: items,
            status: 'pending',
            customer_shipping: selectedCustomer?.shipping_address || newCustomer.shipping_address,
            created_at: new Date().toISOString()
          };

          const { error: dropshipError } = await supabase
            .from('dropship_orders')
            .insert(dropshipOrder);

          if (dropshipError) throw dropshipError;

          // Send vendor notification if enabled
          if (sendVendorNotification && vendor.auto_send_orders) {
            await sendVendorOrderNotification(vendor, dropshipOrder);
          }
        }
      }

      // Send customer notification
      if (sendCustomerNotification) {
        await sendCustomerOrderNotification(
          selectedCustomer?.email || newCustomer.email,
          orderNumber,
          totals
        );
      }

      toast.success(`Order ${orderNumber} created successfully`);
      
      // Reset form
      resetForm();

    } catch (error) {
      console.error('Failed to create order:', error);
      toast.error('Failed to create order. Please try again.');
    } finally {
      setIsCreating(false);
    }
  };

  const sendVendorOrderNotification = async (vendor: Vendor, dropshipOrder: any) => {
    try {
      await supabase
        .from('email_queue')
        .insert({
          to_email: vendor.email,
          template_id: 'vendor_dropship_order',
          data: {
            vendor_name: vendor.name,
            order_number: dropshipOrder.order_number,
            items: dropshipOrder.items,
            shipping_address: dropshipOrder.customer_shipping
          },
          status: 'pending',
          scheduled_for: new Date().toISOString()
        });
    } catch (error) {
      console.error('Failed to queue vendor notification:', error);
    }
  };

  const sendCustomerOrderNotification = async (email: string, orderNumber: string, totals: any) => {
    try {
      await supabase
        .from('email_queue')
        .insert({
          to_email: email,
          template_id: 'order_confirmation',
          data: {
            order_number: orderNumber,
            subtotal: totals.subtotal,
            shipping: totals.shipping,
            tax: totals.tax,
            total: totals.total
          },
          status: 'pending',
          scheduled_for: new Date().toISOString()
        });
    } catch (error) {
      console.error('Failed to queue customer notification:', error);
    }
  };

  const resetForm = () => {
    setSelectedCustomer(null);
    setCreateNewCustomer(false);
    setNewCustomer({
      name: '',
      email: '',
      phone: '',
      shipping_address: {
        line1: '',
        line2: '',
        city: '',
        state: '',
        postal_code: '',
        country: 'US'
      }
    });
    setOrderItems([]);
    setSelectedVendors(new Set());
    setOrderNotes('');
    setCustomerSearch('');
    setProductSearch('');
  };

  const applyTemplate = (template: any) => {
    setOrderType(template.type);
    if (template.priority) {
      setShippingMethod('express');
    }
    toast.success(`Applied "${template.name}" template`);
  };

  const totals = calculateTotals();

  return (
    <div className="max-w-7xl mx-auto space-y-6">
      {/* Header */}
      <div className="flex items-center justify-between">
        <div>
          <h2 className="text-2xl font-bold">Create Manual Order</h2>
          <p className="text-muted-foreground">Create orders for dropshipping or manual fulfillment</p>
        </div>
        
        <div className="flex items-center gap-2">
          {orderTemplates.map(template => (
            <Button
              key={template.id}
              variant="outline"
              size="sm"
              onClick={() => applyTemplate(template)}
            >
              <Zap className="h-4 w-4 mr-2" />
              {template.name}
            </Button>
          ))}
        </div>
      </div>

      {/* Order Type Selection */}
      <Card>
        <CardHeader>
          <CardTitle>Order Type</CardTitle>
        </CardHeader>
        <CardContent>
          <div className="flex items-center gap-4">
            <Button
              variant={orderType === 'regular' ? 'default' : 'outline'}
              onClick={() => setOrderType('regular')}
            >
              <Package className="h-4 w-4 mr-2" />
              Regular Order
            </Button>
            <Button
              variant={orderType === 'dropship' ? 'default' : 'outline'}
              onClick={() => setOrderType('dropship')}
            >
              <Factory className="h-4 w-4 mr-2" />
              Dropship Order
            </Button>
          </div>
          
          {orderType === 'dropship' && (
            <Alert className="mt-4">
              <AlertTriangle className="h-4 w-4" />
              <AlertDescription>
                Dropship orders will be automatically routed to vendors based on product assignments.
                Each vendor will receive their portion of the order.
              </AlertDescription>
            </Alert>
          )}
        </CardContent>
      </Card>

      <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
        {/* Left Column - Customer & Products */}
        <div className="lg:col-span-2 space-y-6">
          {/* Customer Selection */}
          <Card>
            <CardHeader>
              <CardTitle className="flex items-center gap-2">
                <User className="h-5 w-5" />
                Customer Information
              </CardTitle>
            </CardHeader>
            <CardContent className="space-y-4">
              <div className="flex items-center gap-2">
                <div className="flex-1 relative">
                  <Search className="absolute left-3 top-1/2 transform -translate-y-1/2 h-4 w-4 text-muted-foreground" />
                  <Input
                    placeholder="Search customer by name or email..."
                    value={customerSearch}
                    onChange={(e) => setCustomerSearch(e.target.value)}
                    className="pl-10"
                    disabled={createNewCustomer}
                  />
                </div>
                <Button
                  variant="outline"
                  onClick={() => setCreateNewCustomer(!createNewCustomer)}
                >
                  {createNewCustomer ? 'Search Existing' : 'Create New'}
                </Button>
              </div>

              {/* Customer search results */}
              {!createNewCustomer && customers.length > 0 && !selectedCustomer && (
                <div className="border rounded-lg p-2 space-y-1">
                  {customers.map(customer => (
                    <div
                      key={customer.id}
                      className="flex items-center justify-between p-2 hover:bg-muted rounded cursor-pointer"
                      onClick={() => {
                        setSelectedCustomer(customer);
                        setCustomers([]);
                        setCustomerSearch('');
                      }}
                    >
                      <div>
                        <p className="font-medium">{customer.name}</p>
                        <p className="text-sm text-muted-foreground">{customer.email}</p>
                      </div>
                      {customer.order_count && (
                        <Badge variant="outline">{customer.order_count} orders</Badge>
                      )}
                    </div>
                  ))}
                </div>
              )}

              {/* Selected customer display */}
              {selectedCustomer && !createNewCustomer && (
                <div className="border rounded-lg p-4 bg-muted/50">
                  <div className="flex items-start justify-between">
                    <div className="space-y-1">
                      <p className="font-medium">{selectedCustomer.name}</p>
                      <p className="text-sm text-muted-foreground">{selectedCustomer.email}</p>
                      {selectedCustomer.phone && (
                        <p className="text-sm text-muted-foreground">{selectedCustomer.phone}</p>
                      )}
                    </div>
                    <Button
                      variant="ghost"
                      size="sm"
                      onClick={() => setSelectedCustomer(null)}
                    >
                      <X className="h-4 w-4" />
                    </Button>
                  </div>
                </div>
              )}

              {/* New customer form */}
              {createNewCustomer && (
                <div className="space-y-4">
                  <div className="grid grid-cols-2 gap-4">
                    <div>
                      <Label htmlFor="name">Name *</Label>
                      <Input
                        id="name"
                        value={newCustomer.name}
                        onChange={(e) => setNewCustomer(prev => ({ ...prev, name: e.target.value }))}
                      />
                    </div>
                    <div>
                      <Label htmlFor="email">Email *</Label>
                      <Input
                        id="email"
                        type="email"
                        value={newCustomer.email}
                        onChange={(e) => setNewCustomer(prev => ({ ...prev, email: e.target.value }))}
                      />
                    </div>
                  </div>
                  
                  <div>
                    <Label htmlFor="phone">Phone</Label>
                    <Input
                      id="phone"
                      value={newCustomer.phone}
                      onChange={(e) => setNewCustomer(prev => ({ ...prev, phone: e.target.value }))}
                    />
                  </div>

                  <Separator />

                  <div className="space-y-4">
                    <h3 className="font-medium">Shipping Address</h3>
                    <div>
                      <Label htmlFor="line1">Address Line 1 *</Label>
                      <Input
                        id="line1"
                        value={newCustomer.shipping_address.line1}
                        onChange={(e) => setNewCustomer(prev => ({
                          ...prev,
                          shipping_address: { ...prev.shipping_address, line1: e.target.value }
                        }))}
                      />
                    </div>
                    <div>
                      <Label htmlFor="line2">Address Line 2</Label>
                      <Input
                        id="line2"
                        value={newCustomer.shipping_address.line2}
                        onChange={(e) => setNewCustomer(prev => ({
                          ...prev,
                          shipping_address: { ...prev.shipping_address, line2: e.target.value }
                        }))}
                      />
                    </div>
                    <div className="grid grid-cols-3 gap-4">
                      <div>
                        <Label htmlFor="city">City *</Label>
                        <Input
                          id="city"
                          value={newCustomer.shipping_address.city}
                          onChange={(e) => setNewCustomer(prev => ({
                            ...prev,
                            shipping_address: { ...prev.shipping_address, city: e.target.value }
                          }))}
                        />
                      </div>
                      <div>
                        <Label htmlFor="state">State *</Label>
                        <Input
                          id="state"
                          value={newCustomer.shipping_address.state}
                          onChange={(e) => setNewCustomer(prev => ({
                            ...prev,
                            shipping_address: { ...prev.shipping_address, state: e.target.value }
                          }))}
                        />
                      </div>
                      <div>
                        <Label htmlFor="postal">ZIP *</Label>
                        <Input
                          id="postal"
                          value={newCustomer.shipping_address.postal_code}
                          onChange={(e) => setNewCustomer(prev => ({
                            ...prev,
                            shipping_address: { ...prev.shipping_address, postal_code: e.target.value }
                          }))}
                        />
                      </div>
                    </div>
                  </div>
                </div>
              )}
            </CardContent>
          </Card>

          {/* Product Selection */}
          <Card>
            <CardHeader>
              <CardTitle className="flex items-center gap-2">
                <ShoppingCart className="h-5 w-5" />
                Add Products
              </CardTitle>
            </CardHeader>
            <CardContent className="space-y-4">
              <div className="relative">
                <Search className="absolute left-3 top-1/2 transform -translate-y-1/2 h-4 w-4 text-muted-foreground" />
                <Input
                  placeholder="Search products by name or SKU..."
                  value={productSearch}
                  onChange={(e) => setProductSearch(e.target.value)}
                  className="pl-10"
                />
              </div>

              {/* Product search results */}
              {products.length > 0 && productSearch && (
                <div className="border rounded-lg max-h-96 overflow-y-auto">
                  {products.map(product => (
                    <div key={product.id} className="border-b last:border-0">
                      <div className="p-4">
                        <div className="flex items-start justify-between">
                          <div className="flex-1">
                            <p className="font-medium">{product.name}</p>
                            <p className="text-sm text-muted-foreground">
                              SKU: {product.sku} • ${product.base_price}
                            </p>
                            {orderType === 'dropship' && product.vendor_id && (
                              <Badge variant="outline" className="mt-1">
                                <Factory className="h-3 w-3 mr-1" />
                                {vendors.find(v => v.id === product.vendor_id)?.name}
                              </Badge>
                            )}
                          </div>
                          <Button
                            size="sm"
                            onClick={() => addProductToOrder(product)}
                          >
                            <Plus className="h-4 w-4" />
                          </Button>
                        </div>

                        {/* Variants */}
                        {product.variants && product.variants.length > 0 && (
                          <div className="mt-2 flex flex-wrap gap-2">
                            {product.variants.map((variant: any) => (
                              <Button
                                key={variant.id}
                                variant="outline"
                                size="sm"
                                onClick={() => addProductToOrder(product, variant)}
                              >
                                {variant.size || variant.color || variant.name}
                                {variant.price && ` - $${variant.price}`}
                              </Button>
                            ))}
                          </div>
                        )}
                      </div>
                    </div>
                  ))}
                </div>
              )}

              {/* Order items */}
              {orderItems.length > 0 && (
                <>
                  <Separator />
                  <div className="space-y-2">
                    <h3 className="font-medium">Order Items</h3>
                    {orderItems.map((item, index) => (
                      <div key={index} className="flex items-center justify-between p-3 border rounded-lg">
                        <div className="flex-1">
                          <p className="font-medium">{item.product_name}</p>
                          {item.variant_name && (
                            <p className="text-sm text-muted-foreground">{item.variant_name}</p>
                          )}
                          <p className="text-sm text-muted-foreground">
                            ${item.price} each
                          </p>
                          {item.dropship && item.vendor_id && (
                            <Badge variant="outline" className="mt-1">
                              <Truck className="h-3 w-3 mr-1" />
                              Dropship
                            </Badge>
                          )}
                        </div>
                        
                        <div className="flex items-center gap-2">
                          <Button
                            variant="outline"
                            size="sm"
                            onClick={() => updateItemQuantity(index, -1)}
                          >
                            <Minus className="h-4 w-4" />
                          </Button>
                          <span className="w-12 text-center font-medium">{item.quantity}</span>
                          <Button
                            variant="outline"
                            size="sm"
                            onClick={() => updateItemQuantity(index, 1)}
                          >
                            <Plus className="h-4 w-4" />
                          </Button>
                          <Button
                            variant="ghost"
                            size="sm"
                            onClick={() => removeItem(index)}
                          >
                            <X className="h-4 w-4" />
                          </Button>
                        </div>
                      </div>
                    ))}
                  </div>
                </>
              )}
            </CardContent>
          </Card>

          {/* Order Notes */}
          <Card>
            <CardHeader>
              <CardTitle className="flex items-center gap-2">
                <FileText className="h-5 w-5" />
                Order Notes
              </CardTitle>
            </CardHeader>
            <CardContent>
              <Textarea
                placeholder="Add any special instructions or notes..."
                value={orderNotes}
                onChange={(e) => setOrderNotes(e.target.value)}
                rows={4}
              />
            </CardContent>
          </Card>
        </div>

        {/* Right Column - Summary & Settings */}
        <div className="space-y-6">
          {/* Order Summary */}
          <Card>
            <CardHeader>
              <CardTitle>Order Summary</CardTitle>
            </CardHeader>
            <CardContent className="space-y-4">
              <div className="space-y-2">
                <div className="flex justify-between text-sm">
                  <span>Subtotal</span>
                  <span>${totals.subtotal.toFixed(2)}</span>
                </div>
                <div className="flex justify-between text-sm">
                  <span>Shipping</span>
                  <span>${totals.shipping.toFixed(2)}</span>
                </div>
                <div className="flex justify-between text-sm">
                  <span>Tax</span>
                  <span>${totals.tax.toFixed(2)}</span>
                </div>
                <Separator />
                <div className="flex justify-between font-semibold">
                  <span>Total</span>
                  <span>${totals.total.toFixed(2)}</span>
                </div>
              </div>

              {orderType === 'dropship' && selectedVendors.size > 0 && (
                <>
                  <Separator />
                  <div>
                    <h3 className="font-medium mb-2">Vendor Distribution</h3>
                    {Array.from(selectedVendors).map(vendorId => {
                      const vendor = vendors.find(v => v.id === vendorId);
                      const vendorItems = orderItems.filter(item => item.vendor_id === vendorId);
                      const vendorTotal = vendorItems.reduce((sum, item) => sum + (item.price * item.quantity), 0);
                      
                      return vendor ? (
                        <div key={vendorId} className="flex justify-between text-sm mb-1">
                          <span>{vendor.name}</span>
                          <span>${vendorTotal.toFixed(2)}</span>
                        </div>
                      ) : null;
                    })}
                  </div>
                </>
              )}
            </CardContent>
          </Card>

          {/* Settings */}
          <Card>
            <CardHeader>
              <CardTitle>Order Settings</CardTitle>
            </CardHeader>
            <CardContent className="space-y-4">
              <div>
                <Label htmlFor="payment-status">Payment Status</Label>
                <Select
                  value={paymentStatus}
                  onValueChange={(value: 'paid' | 'pending') => setPaymentStatus(value)}
                >
                  <SelectTrigger>
                    <SelectValue />
                  </SelectTrigger>
                  <SelectContent>
                    <SelectItem value="paid">
                      <div className="flex items-center gap-2">
                        <CheckCircle className="h-4 w-4 text-green-500" />
                        Paid
                      </div>
                    </SelectItem>
                    <SelectItem value="pending">
                      <div className="flex items-center gap-2">
                        <Clock className="h-4 w-4 text-yellow-500" />
                        Pending
                      </div>
                    </SelectItem>
                  </SelectContent>
                </Select>
              </div>

              <div>
                <Label htmlFor="shipping-method">Shipping Method</Label>
                <Select
                  value={shippingMethod}
                  onValueChange={setShippingMethod}
                >
                  <SelectTrigger>
                    <SelectValue />
                  </SelectTrigger>
                  <SelectContent>
                    <SelectItem value="standard">Standard ($5)</SelectItem>
                    <SelectItem value="express">Express ($15)</SelectItem>
                    <SelectItem value="custom">Custom</SelectItem>
                  </SelectContent>
                </Select>
              </div>

              {shippingMethod === 'custom' && (
                <div>
                  <Label htmlFor="custom-shipping">Custom Shipping Cost</Label>
                  <Input
                    id="custom-shipping"
                    type="number"
                    step="0.01"
                    value={customShippingCost}
                    onChange={(e) => setCustomShippingCost(parseFloat(e.target.value) || 0)}
                  />
                </div>
              )}

              <Separator />

              <div className="space-y-3">
                <div className="flex items-center justify-between">
                  <Label htmlFor="customer-notification" className="flex items-center gap-2">
                    <Mail className="h-4 w-4" />
                    Send customer notification
                  </Label>
                  <Switch
                    id="customer-notification"
                    checked={sendCustomerNotification}
                    onCheckedChange={setSendCustomerNotification}
                  />
                </div>

                {orderType === 'dropship' && (
                  <div className="flex items-center justify-between">
                    <Label htmlFor="vendor-notification" className="flex items-center gap-2">
                      <Send className="h-4 w-4" />
                      Send vendor notifications
                    </Label>
                    <Switch
                      id="vendor-notification"
                      checked={sendVendorNotification}
                      onCheckedChange={setSendVendorNotification}
                    />
                  </div>
                )}
              </div>
            </CardContent>
          </Card>

          {/* Actions */}
          <Card>
            <CardContent className="pt-6">
              <div className="space-y-2">
                <Button
                  className="w-full"
                  size="lg"
                  onClick={createOrder}
                  disabled={isCreating || orderItems.length === 0 || (!selectedCustomer && !createNewCustomer)}
                >
                  {isCreating ? (
                    <>
                      <RefreshCw className="h-4 w-4 mr-2 animate-spin" />
                      Creating Order...
                    </>
                  ) : (
                    <>
                      <CheckCircle className="h-4 w-4 mr-2" />
                      Create Order
                    </>
                  )}
                </Button>
                
                <Button
                  variant="outline"
                  className="w-full"
                  onClick={resetForm}
                >
                  Reset Form
                </Button>
              </div>
            </CardContent>
          </Card>
        </div>
      </div>
    </div>
  );
}