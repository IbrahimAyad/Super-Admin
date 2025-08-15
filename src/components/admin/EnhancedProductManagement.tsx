import React, { useState, useEffect } from 'react';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { Badge } from '@/components/ui/badge';
import { Input } from '@/components/ui/input';
import { Label } from '@/components/ui/label';
import { Textarea } from '@/components/ui/textarea';
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from '@/components/ui/select';
import { Dialog, DialogContent, DialogHeader, DialogTitle, DialogFooter } from '@/components/ui/dialog';
import { Tabs, TabsContent, TabsList, TabsTrigger } from '@/components/ui/tabs';
import { Table, TableBody, TableCell, TableHead, TableHeader, TableRow } from '@/components/ui/table';
import { Switch } from '@/components/ui/switch';
import { Separator } from '@/components/ui/separator';
import { ScrollArea } from '@/components/ui/scroll-area';
import { 
  Plus, 
  Edit, 
  Trash2, 
  Search, 
  Filter,
  Upload,
  Download,
  Copy,
  Eye,
  DollarSign,
  Package,
  Tag,
  BarChart,
  Settings,
  Zap,
  Image as ImageIcon,
  ChevronDown,
  ChevronUp,
  AlertCircle,
  CheckCircle,
  X
} from 'lucide-react';
import { useToast } from '@/hooks/use-toast';
import { supabase } from '@/lib/supabase-client';
import { cn } from '@/lib/utils';
import { ProductForm } from './ProductForm';

interface PriceTier {
  tier_id: string;
  tier_number: number;
  min_price: number;
  max_price: number | null;
  display_range: string;
  tier_name: string;
  tier_label: string;
  color_code: string;
  positioning: string;
}

interface EnhancedProduct {
  id: string;
  name: string;
  sku: string;
  handle: string;
  style_code?: string;
  season?: string;
  collection?: string;
  category: string;
  subcategory?: string;
  product_type?: string;
  price_tier: string;
  base_price: number;
  compare_at_price?: number;
  cost_per_unit?: number;
  color_family?: string;
  color_name?: string;
  materials?: any;
  fit_type?: string;
  images?: any;
  description?: string;
  meta_title?: string;
  meta_description?: string;
  tags?: string[];
  status: string;
  is_available: boolean;
  stripe_product_id?: string;
  stripe_price_id?: string;
  stripe_active?: boolean;
  view_count?: number;
  add_to_cart_count?: number;
  purchase_count?: number;
  return_rate?: number;
  created_at: string;
  updated_at: string;
}

export function EnhancedProductManagement() {
  const { toast } = useToast();
  const [products, setProducts] = useState<EnhancedProduct[]>([]);
  const [priceTiers, setPriceTiers] = useState<PriceTier[]>([]);
  const [loading, setLoading] = useState(true);
  const [selectedProduct, setSelectedProduct] = useState<EnhancedProduct | null>(null);
  const [showProductDialog, setShowProductDialog] = useState(false);
  const [showStripeSync, setShowStripeSync] = useState(false);
  const [showBulkActions, setShowBulkActions] = useState(false);
  const [selectedProducts, setSelectedProducts] = useState<string[]>([]);
  const [searchTerm, setSearchTerm] = useState('');
  const [filterCategory, setFilterCategory] = useState('all');
  const [filterStatus, setFilterStatus] = useState('all');
  const [filterPriceTier, setFilterPriceTier] = useState('all');
  const [sortBy, setSortBy] = useState('created_at');
  const [sortOrder, setSortOrder] = useState<'asc' | 'desc'>('desc');

  useEffect(() => {
    loadProducts();
    loadPriceTiers();
  }, []);

  const loadProducts = async () => {
    try {
      setLoading(true);
      const { data, error } = await supabase
        .from('products_enhanced')
        .select('*')
        .order('created_at', { ascending: false });

      if (error) throw error;
      setProducts(data || []);
    } catch (error) {
      console.error('Error loading products:', error);
      toast({
        title: "Error",
        description: "Failed to load products",
        variant: "destructive"
      });
    } finally {
      setLoading(false);
    }
  };

  const loadPriceTiers = async () => {
    try {
      const { data, error } = await supabase
        .from('price_tiers')
        .select('*')
        .order('tier_number');

      if (error) throw error;
      setPriceTiers(data || []);
    } catch (error) {
      console.error('Error loading price tiers:', error);
    }
  };

  const syncWithStripe = async (productId?: string) => {
    try {
      const productsToSync = productId 
        ? [products.find(p => p.id === productId)]
        : selectedProducts.length > 0 
          ? products.filter(p => selectedProducts.includes(p.id))
          : products;

      for (const product of productsToSync.filter(Boolean)) {
        if (!product) continue;

        const { data, error } = await supabase.functions.invoke('sync-stripe-product', {
          body: { 
            product_id: product.id,
            action: product.stripe_product_id ? 'update' : 'create'
          }
        });

        if (error) throw error;

        // Update local state
        setProducts(prev => prev.map(p => 
          p.id === product.id 
            ? { ...p, stripe_product_id: data.stripe_product_id, stripe_price_id: data.stripe_price_id }
            : p
        ));
      }

      toast({
        title: "Success",
        description: `Synced ${productsToSync.length} product(s) with Stripe`
      });
    } catch (error) {
      console.error('Stripe sync error:', error);
      toast({
        title: "Error",
        description: "Failed to sync with Stripe",
        variant: "destructive"
      });
    }
  };

  const updateProduct = async (product: Partial<EnhancedProduct>) => {
    try {
      const { error } = await supabase
        .from('products_enhanced')
        .update(product)
        .eq('id', product.id);

      if (error) throw error;

      await loadProducts();
      setShowProductDialog(false);
      
      toast({
        title: "Success",
        description: "Product updated successfully"
      });
    } catch (error) {
      console.error('Error updating product:', error);
      toast({
        title: "Error",
        description: "Failed to update product",
        variant: "destructive"
      });
    }
  };

  const handleSaveProduct = async (productData: Partial<EnhancedProduct>) => {
    try {
      if (selectedProduct?.id) {
        // Update existing product
        const { error } = await supabase
          .from('products_enhanced')
          .update({
            ...productData,
            updated_at: new Date().toISOString()
          })
          .eq('id', selectedProduct.id);

        if (error) throw error;
        
        toast({
          title: "Product updated",
          description: "Product has been successfully updated"
        });
      } else {
        // Create new product
        const handle = productData.name?.toLowerCase().replace(/[^a-z0-9]+/g, '-') || '';
        const { error } = await supabase
          .from('products_enhanced')
          .insert({
            ...productData,
            handle,
            created_at: new Date().toISOString(),
            updated_at: new Date().toISOString(),
            is_available: true
          });

        if (error) throw error;
        
        toast({
          title: "Product created",
          description: "New product has been successfully created"
        });
      }

      setShowProductDialog(false);
      setSelectedProduct(null);
      await loadProducts();
    } catch (error) {
      console.error('Error saving product:', error);
      toast({
        title: "Error",
        description: "Failed to save product",
        variant: "destructive"
      });
    }
  };

  const deleteProduct = async (productId: string) => {
    if (!confirm('Are you sure you want to delete this product?')) return;

    try {
      const { error } = await supabase
        .from('products_enhanced')
        .delete()
        .eq('id', productId);

      if (error) throw error;

      setProducts(prev => prev.filter(p => p.id !== productId));
      
      toast({
        title: "Success",
        description: "Product deleted successfully"
      });
    } catch (error) {
      console.error('Error deleting product:', error);
      toast({
        title: "Error",
        description: "Failed to delete product",
        variant: "destructive"
      });
    }
  };

  const bulkUpdateStatus = async (status: string) => {
    try {
      const { error } = await supabase
        .from('products_enhanced')
        .update({ status })
        .in('id', selectedProducts);

      if (error) throw error;

      await loadProducts();
      setSelectedProducts([]);
      
      toast({
        title: "Success",
        description: `Updated ${selectedProducts.length} products`
      });
    } catch (error) {
      console.error('Error bulk updating:', error);
      toast({
        title: "Error",
        description: "Failed to update products",
        variant: "destructive"
      });
    }
  };

  const filteredProducts = products.filter(product => {
    const matchesSearch = product.name.toLowerCase().includes(searchTerm.toLowerCase()) ||
                          product.sku.toLowerCase().includes(searchTerm.toLowerCase());
    const matchesCategory = filterCategory === 'all' || product.category === filterCategory;
    const matchesStatus = filterStatus === 'all' || product.status === filterStatus;
    const matchesPriceTier = filterPriceTier === 'all' || product.price_tier === filterPriceTier;
    
    return matchesSearch && matchesCategory && matchesStatus && matchesPriceTier;
  });

  const sortedProducts = [...filteredProducts].sort((a, b) => {
    const aVal = a[sortBy as keyof EnhancedProduct];
    const bVal = b[sortBy as keyof EnhancedProduct];
    
    if (sortOrder === 'asc') {
      return aVal > bVal ? 1 : -1;
    } else {
      return aVal < bVal ? 1 : -1;
    }
  });

  const getTierColor = (tierId: string) => {
    const tier = priceTiers.find(t => t.tier_id === tierId);
    return tier?.color_code || '#6B7280';
  };

  const getTierName = (tierId: string) => {
    const tier = priceTiers.find(t => t.tier_id === tierId);
    return tier?.tier_name || tierId;
  };

  const formatCurrency = (cents: number) => {
    return new Intl.NumberFormat('en-US', {
      style: 'currency',
      currency: 'USD'
    }).format(cents / 100);
  };

  const getStatusColor = (status: string) => {
    switch (status) {
      case 'active': return 'bg-green-100 text-green-800';
      case 'draft': return 'bg-yellow-100 text-yellow-800';
      case 'archived': return 'bg-gray-100 text-gray-800';
      default: return 'bg-gray-100 text-gray-800';
    }
  };

  if (loading) {
    return (
      <div className="flex items-center justify-center h-96">
        <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-primary"></div>
      </div>
    );
  }

  return (
    <div className="space-y-6">
      {/* Header & Stats */}
      <div className="flex flex-col md:flex-row justify-between items-start md:items-center gap-4">
        <div>
          <h2 className="text-3xl font-bold">Enhanced Product Management</h2>
          <p className="text-muted-foreground">Manage products with 20-tier pricing and Stripe integration</p>
        </div>
        
        <div className="flex gap-2">
          <Button onClick={() => setShowStripeSync(true)} variant="outline">
            <Zap className="h-4 w-4 mr-2" />
            Stripe Sync
          </Button>
          <Button onClick={() => {
            setSelectedProduct(null);
            setShowProductDialog(true);
          }}>
            <Plus className="h-4 w-4 mr-2" />
            Add Product
          </Button>
        </div>
      </div>

      {/* Statistics Cards */}
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-5 gap-4">
        <Card>
          <CardContent className="p-4">
            <div className="flex items-center gap-3">
              <Package className="h-8 w-8 text-blue-500" />
              <div>
                <p className="text-sm text-muted-foreground">Total Products</p>
                <p className="text-2xl font-bold">{products.length}</p>
              </div>
            </div>
          </CardContent>
        </Card>

        <Card>
          <CardContent className="p-4">
            <div className="flex items-center gap-3">
              <CheckCircle className="h-8 w-8 text-green-500" />
              <div>
                <p className="text-sm text-muted-foreground">Active</p>
                <p className="text-2xl font-bold">
                  {products.filter(p => p.status === 'active').length}
                </p>
              </div>
            </div>
          </CardContent>
        </Card>

        <Card>
          <CardContent className="p-4">
            <div className="flex items-center gap-3">
              <Zap className="h-8 w-8 text-purple-500" />
              <div>
                <p className="text-sm text-muted-foreground">In Stripe</p>
                <p className="text-2xl font-bold">
                  {products.filter(p => p.stripe_product_id).length}
                </p>
              </div>
            </div>
          </CardContent>
        </Card>

        <Card>
          <CardContent className="p-4">
            <div className="flex items-center gap-3">
              <DollarSign className="h-8 w-8 text-emerald-500" />
              <div>
                <p className="text-sm text-muted-foreground">Avg Price</p>
                <p className="text-2xl font-bold">
                  {formatCurrency(
                    products.reduce((sum, p) => sum + p.base_price, 0) / products.length || 0
                  )}
                </p>
              </div>
            </div>
          </CardContent>
        </Card>

        <Card>
          <CardContent className="p-4">
            <div className="flex items-center gap-3">
              <Tag className="h-8 w-8 text-orange-500" />
              <div>
                <p className="text-sm text-muted-foreground">Price Tiers</p>
                <p className="text-2xl font-bold">{priceTiers.length}</p>
              </div>
            </div>
          </CardContent>
        </Card>
      </div>

      {/* Filters & Search */}
      <Card>
        <CardContent className="p-4">
          <div className="flex flex-wrap gap-4 items-center">
            <div className="flex-1 min-w-64">
              <div className="relative">
                <Search className="absolute left-3 top-1/2 transform -translate-y-1/2 h-4 w-4 text-muted-foreground" />
                <Input
                  placeholder="Search products..."
                  value={searchTerm}
                  onChange={(e) => setSearchTerm(e.target.value)}
                  className="pl-10"
                />
              </div>
            </div>

            <Select value={filterCategory} onValueChange={setFilterCategory}>
              <SelectTrigger className="w-40">
                <SelectValue />
              </SelectTrigger>
              <SelectContent>
                <SelectItem value="all">All Categories</SelectItem>
                <SelectItem value="Blazers">Blazers</SelectItem>
                <SelectItem value="Suits">Suits</SelectItem>
                <SelectItem value="Shirts">Shirts</SelectItem>
                <SelectItem value="Pants">Pants</SelectItem>
                <SelectItem value="Accessories">Accessories</SelectItem>
              </SelectContent>
            </Select>

            <Select value={filterStatus} onValueChange={setFilterStatus}>
              <SelectTrigger className="w-32">
                <SelectValue />
              </SelectTrigger>
              <SelectContent>
                <SelectItem value="all">All Status</SelectItem>
                <SelectItem value="active">Active</SelectItem>
                <SelectItem value="draft">Draft</SelectItem>
                <SelectItem value="archived">Archived</SelectItem>
              </SelectContent>
            </Select>

            <Select value={filterPriceTier} onValueChange={setFilterPriceTier}>
              <SelectTrigger className="w-40">
                <SelectValue />
              </SelectTrigger>
              <SelectContent>
                <SelectItem value="all">All Tiers</SelectItem>
                {priceTiers.map(tier => (
                  <SelectItem key={tier.tier_id} value={tier.tier_id}>
                    {tier.tier_name} ({tier.display_range})
                  </SelectItem>
                ))}
              </SelectContent>
            </Select>

            {selectedProducts.length > 0 && (
              <Button 
                variant="outline" 
                onClick={() => setShowBulkActions(!showBulkActions)}
              >
                Bulk Actions ({selectedProducts.length})
              </Button>
            )}
          </div>

          {/* Bulk Actions */}
          {showBulkActions && selectedProducts.length > 0 && (
            <div className="mt-4 p-4 bg-muted rounded-lg flex gap-2">
              <Button size="sm" onClick={() => bulkUpdateStatus('active')}>
                Set Active
              </Button>
              <Button size="sm" variant="outline" onClick={() => bulkUpdateStatus('draft')}>
                Set Draft
              </Button>
              <Button size="sm" variant="outline" onClick={() => bulkUpdateStatus('archived')}>
                Archive
              </Button>
              <Button size="sm" variant="outline" onClick={() => syncWithStripe()}>
                Sync to Stripe
              </Button>
              <Button 
                size="sm" 
                variant="destructive" 
                onClick={() => setSelectedProducts([])}
              >
                Clear Selection
              </Button>
            </div>
          )}
        </CardContent>
      </Card>

      {/* Products Table */}
      <Card>
        <CardContent className="p-0">
          <div className="overflow-x-auto">
            <Table>
              <TableHeader>
                <TableRow>
                  <TableHead className="w-12">
                    <input
                      type="checkbox"
                      checked={selectedProducts.length === filteredProducts.length && filteredProducts.length > 0}
                      onChange={(e) => {
                        if (e.target.checked) {
                          setSelectedProducts(filteredProducts.map(p => p.id));
                        } else {
                          setSelectedProducts([]);
                        }
                      }}
                    />
                  </TableHead>
                  <TableHead>Product</TableHead>
                  <TableHead>SKU</TableHead>
                  <TableHead>Category</TableHead>
                  <TableHead>Price Tier</TableHead>
                  <TableHead>Price</TableHead>
                  <TableHead>Status</TableHead>
                  <TableHead>Stripe</TableHead>
                  <TableHead>Analytics</TableHead>
                  <TableHead>Actions</TableHead>
                </TableRow>
              </TableHeader>
              <TableBody>
                {sortedProducts.map(product => (
                  <TableRow key={product.id}>
                    <TableCell>
                      <input
                        type="checkbox"
                        checked={selectedProducts.includes(product.id)}
                        onChange={(e) => {
                          if (e.target.checked) {
                            setSelectedProducts([...selectedProducts, product.id]);
                          } else {
                            setSelectedProducts(selectedProducts.filter(id => id !== product.id));
                          }
                        }}
                      />
                    </TableCell>
                    
                    <TableCell>
                      <div className="flex items-center gap-3">
                        {product.images?.hero?.url ? (
                          <img 
                            src={product.images.hero.url} 
                            alt={product.name}
                            className="w-12 h-12 object-cover rounded"
                          />
                        ) : (
                          <div className="w-12 h-12 bg-muted rounded flex items-center justify-center">
                            <ImageIcon className="h-6 w-6 text-muted-foreground" />
                          </div>
                        )}
                        <div>
                          <p className="font-medium">{product.name}</p>
                          {product.collection && (
                            <p className="text-xs text-muted-foreground">{product.collection}</p>
                          )}
                        </div>
                      </div>
                    </TableCell>
                    
                    <TableCell className="font-mono text-sm">{product.sku}</TableCell>
                    
                    <TableCell>
                      <div>
                        <p>{product.category}</p>
                        {product.subcategory && (
                          <p className="text-xs text-muted-foreground">{product.subcategory}</p>
                        )}
                      </div>
                    </TableCell>
                    
                    <TableCell>
                      <Badge 
                        style={{ backgroundColor: getTierColor(product.price_tier) + '20' }}
                        className="border-0"
                      >
                        <div 
                          className="w-2 h-2 rounded-full mr-1"
                          style={{ backgroundColor: getTierColor(product.price_tier) }}
                        />
                        {getTierName(product.price_tier)}
                      </Badge>
                    </TableCell>
                    
                    <TableCell>
                      <div>
                        <p className="font-medium">{formatCurrency(product.base_price)}</p>
                        {product.compare_at_price && (
                          <p className="text-xs text-muted-foreground line-through">
                            {formatCurrency(product.compare_at_price)}
                          </p>
                        )}
                      </div>
                    </TableCell>
                    
                    <TableCell>
                      <Badge className={cn(getStatusColor(product.status))}>
                        {product.status}
                      </Badge>
                    </TableCell>
                    
                    <TableCell>
                      {product.stripe_product_id ? (
                        <Badge variant="outline" className="text-xs">
                          <Zap className="h-3 w-3 mr-1" />
                          Synced
                        </Badge>
                      ) : (
                        <Button 
                          size="sm" 
                          variant="ghost"
                          onClick={() => syncWithStripe(product.id)}
                        >
                          Sync
                        </Button>
                      )}
                    </TableCell>
                    
                    <TableCell>
                      <div className="text-xs space-y-1">
                        <p>Views: {product.view_count || 0}</p>
                        <p>Carts: {product.add_to_cart_count || 0}</p>
                        <p>Sales: {product.purchase_count || 0}</p>
                      </div>
                    </TableCell>
                    
                    <TableCell>
                      <div className="flex gap-1">
                        <Button
                          size="sm"
                          variant="ghost"
                          onClick={() => {
                            setSelectedProduct(product);
                            setShowProductDialog(true);
                          }}
                        >
                          <Edit className="h-4 w-4" />
                        </Button>
                        <Button
                          size="sm"
                          variant="ghost"
                          onClick={() => deleteProduct(product.id)}
                        >
                          <Trash2 className="h-4 w-4 text-destructive" />
                        </Button>
                      </div>
                    </TableCell>
                  </TableRow>
                ))}
              </TableBody>
            </Table>
            
            {sortedProducts.length === 0 && (
              <div className="text-center py-12">
                <Package className="h-12 w-12 mx-auto text-muted-foreground mb-4" />
                <p className="text-muted-foreground">No products found</p>
              </div>
            )}
          </div>
        </CardContent>
      </Card>

      {/* Product Edit/Create Dialog */}
      <Dialog open={showProductDialog} onOpenChange={setShowProductDialog}>
        <DialogContent className="max-w-4xl max-h-[90vh] overflow-y-auto">
          <DialogHeader>
            <DialogTitle>
              {selectedProduct ? 'Edit Product' : 'Create Product'}
            </DialogTitle>
          </DialogHeader>
          
          <ProductForm
            product={selectedProduct}
            onSave={handleSaveProduct}
            onCancel={() => setShowProductDialog(false)}
          />
        </DialogContent>
      </Dialog>

      {/* Stripe Sync Dialog */}
      <Dialog open={showStripeSync} onOpenChange={setShowStripeSync}>
        <DialogContent>
          <DialogHeader>
            <DialogTitle>Stripe Product Sync</DialogTitle>
          </DialogHeader>
          
          <div className="space-y-4">
            <div className="p-4 bg-muted rounded-lg">
              <h4 className="font-medium mb-2">Sync Status</h4>
              <div className="space-y-2 text-sm">
                <p>Total Products: {products.length}</p>
                <p>Synced to Stripe: {products.filter(p => p.stripe_product_id).length}</p>
                <p>Not Synced: {products.filter(p => !p.stripe_product_id).length}</p>
              </div>
            </div>
            
            <div className="space-y-2">
              <Button 
                className="w-full" 
                onClick={() => {
                  syncWithStripe();
                  setShowStripeSync(false);
                }}
              >
                Sync All Products
              </Button>
              <Button 
                variant="outline" 
                className="w-full"
                onClick={() => setShowStripeSync(false)}
              >
                Cancel
              </Button>
            </div>
          </div>
        </DialogContent>
      </Dialog>
    </div>
  );
}