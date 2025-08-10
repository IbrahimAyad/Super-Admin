/**
 * ENHANCED PRODUCT MANAGEMENT
 * Advanced product management with bulk actions, filters, and better UX
 */

import React, { useState, useEffect, useMemo } from 'react';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Badge } from '@/components/ui/badge';
import { Checkbox } from '@/components/ui/checkbox';
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from '@/components/ui/select';
import { DropdownMenu, DropdownMenuContent, DropdownMenuItem, DropdownMenuTrigger, DropdownMenuSeparator } from '@/components/ui/dropdown-menu';
import { Tabs, TabsContent, TabsList, TabsTrigger } from '@/components/ui/tabs';
import { Alert, AlertDescription } from '@/components/ui/alert';
import { Separator } from '@/components/ui/separator';
import { Label } from '@/components/ui/label';
import { ProductEditorSimple } from './ProductEditorSimple';
import { ImageMigrationHelper } from './ImageMigrationHelper';
import { supabase } from '@/lib/supabase-client';
import { toast } from 'sonner';
import { 
  Plus, 
  Search, 
  Edit, 
  Trash2, 
  Package,
  DollarSign,
  Hash,
  Filter,
  Download,
  Upload,
  Copy,
  MoreVertical,
  ChevronDown,
  ArrowUpDown,
  Eye,
  EyeOff,
  AlertTriangle,
  CheckCircle,
  Clock,
  Grid,
  List,
  Image,
  Tag,
  TrendingUp,
  TrendingDown,
  BarChart3,
  RefreshCw,
  Archive,
  Settings,
  Zap,
  X
} from 'lucide-react';

interface Product {
  id: string;
  name: string;
  sku: string;
  category: string;
  base_price: number;
  status: string;
  total_inventory?: number;
  image_url?: string;
  variant_count?: number;
  created_at?: string;
  updated_at?: string;
  vendor_id?: string;
  tags?: string[];
  sale_price?: number;
  cost_price?: number;
  margin?: number;
}

interface FilterState {
  category: string;
  status: string;
  priceRange: string;
  inventory: string;
  vendor: string;
  tags: string[];
}

interface SortState {
  field: string;
  direction: 'asc' | 'desc';
}

export function ProductManagementEnhanced() {
  const [products, setProducts] = useState<Product[]>([]);
  const [loading, setLoading] = useState(true);
  const [searchTerm, setSearchTerm] = useState('');
  const [showEditor, setShowEditor] = useState(false);
  const [editingProductId, setEditingProductId] = useState<string | null>(null);
  const [selectedProducts, setSelectedProducts] = useState<Set<string>>(new Set());
  const [viewMode, setViewMode] = useState<'grid' | 'list'>('grid');
  
  // Filters and sorting
  const [filters, setFilters] = useState<FilterState>({
    category: 'all',
    status: 'all',
    priceRange: 'all',
    inventory: 'all',
    vendor: 'all',
    tags: []
  });
  
  const [sort, setSort] = useState<SortState>({
    field: 'created_at',
    direction: 'desc'
  });

  // Stats
  const [stats, setStats] = useState({
    totalProducts: 0,
    activeProducts: 0,
    totalVariants: 0,
    avgPrice: 0,
    lowStock: 0,
    outOfStock: 0,
    totalValue: 0
  });

  // Categories and vendors for filters
  const [categories, setCategories] = useState<string[]>([]);
  const [vendors, setVendors] = useState<any[]>([]);
  const [allTags, setAllTags] = useState<string[]>([]);

  useEffect(() => {
    loadProducts();
    loadFilterOptions();
  }, []);

  useEffect(() => {
    calculateStats();
  }, [products]);

  const loadFilterOptions = async () => {
    try {
      // Load categories
      const { data: catData } = await supabase
        .from('products')
        .select('category')
        .not('category', 'is', null);
      
      const uniqueCategories = [...new Set(catData?.map(p => p.category) || [])];
      setCategories(uniqueCategories);

      // Load vendors
      const { data: vendorData } = await supabase
        .from('vendors')
        .select('id, name')
        .eq('status', 'active');
      
      setVendors(vendorData || []);

      // Load tags
      const { data: tagData } = await supabase
        .from('products')
        .select('tags');
      
      const allProductTags = tagData?.flatMap(p => p.tags || []) || [];
      const uniqueTags = [...new Set(allProductTags)];
      setAllTags(uniqueTags);
    } catch (error) {
      console.error('Error loading filter options:', error);
    }
  };

  const loadProducts = async () => {
    setLoading(true);
    try {
      const { data: productsData, error } = await supabase
        .from('products')
        .select(`
          *,
          product_images (image_url),
          product_variants (id, inventory_quantity),
          vendors (name)
        `)
        .order('created_at', { ascending: false });

      if (error) throw error;

      const processedProducts = productsData?.map(product => {
        const totalInventory = product.product_variants?.reduce((sum: number, v: any) => 
          sum + (v.inventory_quantity || 0), 0) || 0;
        
        const margin = product.base_price && product.cost_price 
          ? ((product.base_price - product.cost_price) / product.base_price * 100)
          : 0;

        return {
          ...product,
          image_url: product.product_images?.[0]?.image_url,
          variant_count: product.product_variants?.length || 0,
          total_inventory: totalInventory,
          vendor_name: product.vendors?.name,
          margin
        };
      }) || [];

      setProducts(processedProducts);
    } catch (error) {
      console.error('Error loading products:', error);
      toast.error('Failed to load products');
    } finally {
      setLoading(false);
    }
  };

  const calculateStats = () => {
    const activeProducts = products.filter(p => p.status === 'active');
    const totalVariants = products.reduce((sum, p) => sum + (p.variant_count || 0), 0);
    const avgPrice = products.length > 0 
      ? products.reduce((sum, p) => sum + (p.base_price || 0), 0) / products.length 
      : 0;
    const lowStock = products.filter(p => p.total_inventory && p.total_inventory > 0 && p.total_inventory < 10);
    const outOfStock = products.filter(p => p.total_inventory === 0);
    const totalValue = products.reduce((sum, p) => sum + ((p.total_inventory || 0) * (p.base_price || 0)), 0);

    setStats({
      totalProducts: products.length,
      activeProducts: activeProducts.length,
      totalVariants,
      avgPrice,
      lowStock: lowStock.length,
      outOfStock: outOfStock.length,
      totalValue
    });
  };

  // Filtering and sorting logic
  const filteredAndSortedProducts = useMemo(() => {
    let filtered = [...products];

    // Apply search
    if (searchTerm) {
      filtered = filtered.filter(product =>
        product.name?.toLowerCase().includes(searchTerm.toLowerCase()) ||
        product.sku?.toLowerCase().includes(searchTerm.toLowerCase()) ||
        product.category?.toLowerCase().includes(searchTerm.toLowerCase())
      );
    }

    // Apply filters
    if (filters.category !== 'all') {
      filtered = filtered.filter(p => p.category === filters.category);
    }

    if (filters.status !== 'all') {
      filtered = filtered.filter(p => p.status === filters.status);
    }

    if (filters.inventory !== 'all') {
      switch (filters.inventory) {
        case 'in_stock':
          filtered = filtered.filter(p => (p.total_inventory || 0) > 10);
          break;
        case 'low_stock':
          filtered = filtered.filter(p => p.total_inventory && p.total_inventory > 0 && p.total_inventory <= 10);
          break;
        case 'out_of_stock':
          filtered = filtered.filter(p => p.total_inventory === 0);
          break;
      }
    }

    if (filters.priceRange !== 'all') {
      switch (filters.priceRange) {
        case 'under_50':
          filtered = filtered.filter(p => p.base_price < 5000);
          break;
        case '50_100':
          filtered = filtered.filter(p => p.base_price >= 5000 && p.base_price < 10000);
          break;
        case '100_200':
          filtered = filtered.filter(p => p.base_price >= 10000 && p.base_price < 20000);
          break;
        case 'over_200':
          filtered = filtered.filter(p => p.base_price >= 20000);
          break;
      }
    }

    // Apply sorting
    filtered.sort((a, b) => {
      let aVal = a[sort.field as keyof Product];
      let bVal = b[sort.field as keyof Product];

      if (aVal === undefined) return 1;
      if (bVal === undefined) return -1;

      if (typeof aVal === 'string' && typeof bVal === 'string') {
        return sort.direction === 'asc' 
          ? aVal.localeCompare(bVal)
          : bVal.localeCompare(aVal);
      }

      if (typeof aVal === 'number' && typeof bVal === 'number') {
        return sort.direction === 'asc' ? aVal - bVal : bVal - aVal;
      }

      return 0;
    });

    return filtered;
  }, [products, searchTerm, filters, sort]);

  // Bulk actions
  const handleSelectAll = (checked: boolean) => {
    if (checked) {
      setSelectedProducts(new Set(filteredAndSortedProducts.map(p => p.id)));
    } else {
      setSelectedProducts(new Set());
    }
  };

  const handleSelectProduct = (productId: string, checked: boolean) => {
    const newSelected = new Set(selectedProducts);
    if (checked) {
      newSelected.add(productId);
    } else {
      newSelected.delete(productId);
    }
    setSelectedProducts(newSelected);
  };

  const handleBulkDelete = async () => {
    if (selectedProducts.size === 0) return;
    
    if (!confirm(`Delete ${selectedProducts.size} products? This cannot be undone.`)) return;

    try {
      const { error } = await supabase
        .from('products')
        .delete()
        .in('id', Array.from(selectedProducts));

      if (error) throw error;

      toast.success(`Deleted ${selectedProducts.size} products`);
      setSelectedProducts(new Set());
      loadProducts();
    } catch (error) {
      console.error('Error deleting products:', error);
      toast.error('Failed to delete products');
    }
  };

  const handleBulkStatusChange = async (status: string) => {
    if (selectedProducts.size === 0) return;

    try {
      const { error } = await supabase
        .from('products')
        .update({ status, updated_at: new Date().toISOString() })
        .in('id', Array.from(selectedProducts));

      if (error) throw error;

      toast.success(`Updated ${selectedProducts.size} products to ${status}`);
      setSelectedProducts(new Set());
      loadProducts();
    } catch (error) {
      console.error('Error updating products:', error);
      toast.error('Failed to update products');
    }
  };

  const handleExport = async () => {
    const dataToExport = selectedProducts.size > 0 
      ? products.filter(p => selectedProducts.has(p.id))
      : filteredAndSortedProducts;

    const csv = [
      ['SKU', 'Name', 'Category', 'Price', 'Status', 'Inventory', 'Variants'],
      ...dataToExport.map(p => [
        p.sku,
        p.name,
        p.category,
        `$${(p.base_price / 100).toFixed(2)}`,
        p.status,
        p.total_inventory || 0,
        p.variant_count || 0
      ])
    ].map(row => row.join(',')).join('\n');

    const blob = new Blob([csv], { type: 'text/csv' });
    const url = window.URL.createObjectURL(blob);
    const a = document.createElement('a');
    a.href = url;
    a.download = `products-${new Date().toISOString().split('T')[0]}.csv`;
    a.click();
    window.URL.revokeObjectURL(url);
    
    toast.success('Products exported successfully');
  };

  const handleDuplicate = async (productId: string) => {
    try {
      const product = products.find(p => p.id === productId);
      if (!product) return;

      const { data: newProduct, error } = await supabase
        .from('products')
        .insert({
          ...product,
          id: undefined,
          sku: `${product.sku}-COPY`,
          name: `${product.name} (Copy)`,
          created_at: new Date().toISOString(),
          updated_at: new Date().toISOString()
        })
        .select()
        .single();

      if (error) throw error;

      toast.success('Product duplicated successfully');
      loadProducts();
    } catch (error) {
      console.error('Error duplicating product:', error);
      toast.error('Failed to duplicate product');
    }
  };

  const handleDelete = async (productId: string) => {
    if (!confirm('Are you sure you want to delete this product?')) return;

    try {
      const { error } = await supabase
        .from('products')
        .delete()
        .eq('id', productId);

      if (error) throw error;

      toast.success('Product deleted successfully');
      loadProducts();
    } catch (error) {
      console.error('Error deleting product:', error);
      toast.error('Failed to delete product');
    }
  };

  const handleEdit = (productId: string) => {
    setEditingProductId(productId);
    setShowEditor(true);
  };

  const handleNewProduct = () => {
    setEditingProductId(null);
    setShowEditor(true);
  };

  const handleEditorClose = () => {
    setShowEditor(false);
    setEditingProductId(null);
    loadProducts();
  };

  if (showEditor) {
    return (
      <ProductEditorSimple
        productId={editingProductId || undefined}
        onSave={handleEditorClose}
        onCancel={() => setShowEditor(false)}
      />
    );
  }

  return (
    <div className="p-6 max-w-full mx-auto">
      {/* Header */}
      <div className="mb-6">
        <h1 className="text-3xl font-bold mb-2">Products</h1>
        <p className="text-muted-foreground">Manage your product catalog with advanced features</p>
      </div>

      {/* Stats Overview */}
      <div className="grid grid-cols-2 md:grid-cols-4 lg:grid-cols-7 gap-4 mb-6">
        <Card className="p-4">
          <div className="flex items-center justify-between">
            <div>
              <p className="text-xs text-muted-foreground">Total</p>
              <p className="text-xl font-bold">{stats.totalProducts}</p>
            </div>
            <Package className="h-6 w-6 text-muted-foreground" />
          </div>
        </Card>
        <Card className="p-4">
          <div className="flex items-center justify-between">
            <div>
              <p className="text-xs text-muted-foreground">Active</p>
              <p className="text-xl font-bold">{stats.activeProducts}</p>
            </div>
            <CheckCircle className="h-6 w-6 text-green-500" />
          </div>
        </Card>
        <Card className="p-4">
          <div className="flex items-center justify-between">
            <div>
              <p className="text-xs text-muted-foreground">Low Stock</p>
              <p className="text-xl font-bold">{stats.lowStock}</p>
            </div>
            <AlertTriangle className="h-6 w-6 text-yellow-500" />
          </div>
        </Card>
        <Card className="p-4">
          <div className="flex items-center justify-between">
            <div>
              <p className="text-xs text-muted-foreground">Out of Stock</p>
              <p className="text-xl font-bold">{stats.outOfStock}</p>
            </div>
            <X className="h-6 w-6 text-red-500" />
          </div>
        </Card>
        <Card className="p-4">
          <div className="flex items-center justify-between">
            <div>
              <p className="text-xs text-muted-foreground">Variants</p>
              <p className="text-xl font-bold">{stats.totalVariants}</p>
            </div>
            <Hash className="h-6 w-6 text-muted-foreground" />
          </div>
        </Card>
        <Card className="p-4">
          <div className="flex items-center justify-between">
            <div>
              <p className="text-xs text-muted-foreground">Avg Price</p>
              <p className="text-xl font-bold">${(stats.avgPrice / 100).toFixed(0)}</p>
            </div>
            <DollarSign className="h-6 w-6 text-muted-foreground" />
          </div>
        </Card>
        <Card className="p-4">
          <div className="flex items-center justify-between">
            <div>
              <p className="text-xs text-muted-foreground">Total Value</p>
              <p className="text-xl font-bold">${(stats.totalValue / 100).toFixed(0)}</p>
            </div>
            <TrendingUp className="h-6 w-6 text-green-500" />
          </div>
        </Card>
      </div>

      {/* Actions Bar */}
      <div className="flex flex-col lg:flex-row gap-4 mb-6">
        <div className="flex-1 flex gap-2">
          {/* Search */}
          <div className="relative flex-1 max-w-md">
            <Search className="absolute left-3 top-1/2 transform -translate-y-1/2 h-4 w-4 text-muted-foreground" />
            <Input
              type="text"
              placeholder="Search products by name, SKU, or category..."
              value={searchTerm}
              onChange={(e) => setSearchTerm(e.target.value)}
              className="pl-10"
            />
          </div>

          {/* Filters */}
          <DropdownMenu>
            <DropdownMenuTrigger asChild>
              <Button variant="outline">
                <Filter className="h-4 w-4 mr-2" />
                Filters
                {Object.values(filters).some(v => v !== 'all' && (Array.isArray(v) ? v.length > 0 : true)) && (
                  <Badge className="ml-2" variant="secondary">Active</Badge>
                )}
              </Button>
            </DropdownMenuTrigger>
            <DropdownMenuContent align="start" className="w-80">
              <div className="p-4 space-y-4">
                <div>
                  <Label>Category</Label>
                  <Select value={filters.category} onValueChange={(value) => setFilters(prev => ({ ...prev, category: value }))}>
                    <SelectTrigger>
                      <SelectValue />
                    </SelectTrigger>
                    <SelectContent>
                      <SelectItem value="all">All Categories</SelectItem>
                      {categories.map(cat => (
                        <SelectItem key={cat} value={cat}>{cat}</SelectItem>
                      ))}
                    </SelectContent>
                  </Select>
                </div>
                
                <div>
                  <Label>Status</Label>
                  <Select value={filters.status} onValueChange={(value) => setFilters(prev => ({ ...prev, status: value }))}>
                    <SelectTrigger>
                      <SelectValue />
                    </SelectTrigger>
                    <SelectContent>
                      <SelectItem value="all">All Status</SelectItem>
                      <SelectItem value="active">Active</SelectItem>
                      <SelectItem value="draft">Draft</SelectItem>
                      <SelectItem value="archived">Archived</SelectItem>
                    </SelectContent>
                  </Select>
                </div>

                <div>
                  <Label>Inventory</Label>
                  <Select value={filters.inventory} onValueChange={(value) => setFilters(prev => ({ ...prev, inventory: value }))}>
                    <SelectTrigger>
                      <SelectValue />
                    </SelectTrigger>
                    <SelectContent>
                      <SelectItem value="all">All Inventory</SelectItem>
                      <SelectItem value="in_stock">In Stock</SelectItem>
                      <SelectItem value="low_stock">Low Stock (≤10)</SelectItem>
                      <SelectItem value="out_of_stock">Out of Stock</SelectItem>
                    </SelectContent>
                  </Select>
                </div>

                <div>
                  <Label>Price Range</Label>
                  <Select value={filters.priceRange} onValueChange={(value) => setFilters(prev => ({ ...prev, priceRange: value }))}>
                    <SelectTrigger>
                      <SelectValue />
                    </SelectTrigger>
                    <SelectContent>
                      <SelectItem value="all">All Prices</SelectItem>
                      <SelectItem value="under_50">Under $50</SelectItem>
                      <SelectItem value="50_100">$50 - $100</SelectItem>
                      <SelectItem value="100_200">$100 - $200</SelectItem>
                      <SelectItem value="over_200">Over $200</SelectItem>
                    </SelectContent>
                  </Select>
                </div>

                <Button
                  variant="outline"
                  size="sm"
                  className="w-full"
                  onClick={() => setFilters({
                    category: 'all',
                    status: 'all',
                    priceRange: 'all',
                    inventory: 'all',
                    vendor: 'all',
                    tags: []
                  })}
                >
                  Clear Filters
                </Button>
              </div>
            </DropdownMenuContent>
          </DropdownMenu>

          {/* Sort */}
          <DropdownMenu>
            <DropdownMenuTrigger asChild>
              <Button variant="outline">
                <ArrowUpDown className="h-4 w-4 mr-2" />
                Sort
              </Button>
            </DropdownMenuTrigger>
            <DropdownMenuContent align="start">
              <DropdownMenuItem onClick={() => setSort({ field: 'name', direction: 'asc' })}>
                Name (A-Z)
              </DropdownMenuItem>
              <DropdownMenuItem onClick={() => setSort({ field: 'name', direction: 'desc' })}>
                Name (Z-A)
              </DropdownMenuItem>
              <DropdownMenuSeparator />
              <DropdownMenuItem onClick={() => setSort({ field: 'base_price', direction: 'asc' })}>
                Price (Low to High)
              </DropdownMenuItem>
              <DropdownMenuItem onClick={() => setSort({ field: 'base_price', direction: 'desc' })}>
                Price (High to Low)
              </DropdownMenuItem>
              <DropdownMenuSeparator />
              <DropdownMenuItem onClick={() => setSort({ field: 'total_inventory', direction: 'asc' })}>
                Inventory (Low to High)
              </DropdownMenuItem>
              <DropdownMenuItem onClick={() => setSort({ field: 'total_inventory', direction: 'desc' })}>
                Inventory (High to Low)
              </DropdownMenuItem>
              <DropdownMenuSeparator />
              <DropdownMenuItem onClick={() => setSort({ field: 'created_at', direction: 'desc' })}>
                Newest First
              </DropdownMenuItem>
              <DropdownMenuItem onClick={() => setSort({ field: 'created_at', direction: 'asc' })}>
                Oldest First
              </DropdownMenuItem>
            </DropdownMenuContent>
          </DropdownMenu>
        </div>

        <div className="flex gap-2">
          {/* View Mode */}
          <div className="flex border rounded-lg">
            <Button
              variant={viewMode === 'grid' ? 'default' : 'ghost'}
              size="sm"
              className="rounded-r-none"
              onClick={() => setViewMode('grid')}
            >
              <Grid className="h-4 w-4" />
            </Button>
            <Button
              variant={viewMode === 'list' ? 'default' : 'ghost'}
              size="sm"
              className="rounded-l-none"
              onClick={() => setViewMode('list')}
            >
              <List className="h-4 w-4" />
            </Button>
          </div>

          {/* Bulk Actions */}
          {selectedProducts.size > 0 && (
            <DropdownMenu>
              <DropdownMenuTrigger asChild>
                <Button variant="outline">
                  <Zap className="h-4 w-4 mr-2" />
                  Bulk Actions ({selectedProducts.size})
                </Button>
              </DropdownMenuTrigger>
              <DropdownMenuContent align="end">
                <DropdownMenuItem onClick={() => handleBulkStatusChange('active')}>
                  <CheckCircle className="h-4 w-4 mr-2" />
                  Set Active
                </DropdownMenuItem>
                <DropdownMenuItem onClick={() => handleBulkStatusChange('draft')}>
                  <EyeOff className="h-4 w-4 mr-2" />
                  Set Draft
                </DropdownMenuItem>
                <DropdownMenuItem onClick={() => handleBulkStatusChange('archived')}>
                  <Archive className="h-4 w-4 mr-2" />
                  Archive
                </DropdownMenuItem>
                <DropdownMenuSeparator />
                <DropdownMenuItem onClick={handleExport}>
                  <Download className="h-4 w-4 mr-2" />
                  Export Selected
                </DropdownMenuItem>
                <DropdownMenuSeparator />
                <DropdownMenuItem onClick={handleBulkDelete} className="text-red-600">
                  <Trash2 className="h-4 w-4 mr-2" />
                  Delete Selected
                </DropdownMenuItem>
              </DropdownMenuContent>
            </DropdownMenu>
          )}

          {/* Actions */}
          <Button variant="outline" onClick={handleExport}>
            <Download className="h-4 w-4 mr-2" />
            Export
          </Button>
          
          <Button variant="outline" onClick={loadProducts}>
            <RefreshCw className="h-4 w-4 mr-2" />
            Refresh
          </Button>

          <Button onClick={handleNewProduct}>
            <Plus className="h-4 w-4 mr-2" />
            Add Product
          </Button>
        </div>
      </div>

      {/* Image Migration Helper */}
      <div className="mb-6">
        <ImageMigrationHelper />
      </div>

      {/* Product List/Grid */}
      {loading ? (
        <div className="text-center py-12">
          <div className="inline-block animate-spin rounded-full h-8 w-8 border-b-2 border-primary"></div>
          <p className="mt-2 text-muted-foreground">Loading products...</p>
        </div>
      ) : filteredAndSortedProducts.length === 0 ? (
        <Card className="p-12 text-center">
          <Package className="h-12 w-12 text-muted-foreground mx-auto mb-4" />
          <h3 className="text-lg font-semibold mb-2">No products found</h3>
          <p className="text-muted-foreground mb-4">
            {searchTerm || Object.values(filters).some(v => v !== 'all') 
              ? 'Try adjusting your search or filters' 
              : 'Get started by adding your first product'}
          </p>
          {!searchTerm && (
            <Button onClick={handleNewProduct}>
              <Plus className="h-4 w-4 mr-2" />
              Add Product
            </Button>
          )}
        </Card>
      ) : viewMode === 'grid' ? (
        <>
          {/* Select All for Grid */}
          {filteredAndSortedProducts.length > 0 && (
            <div className="flex items-center gap-2 mb-4">
              <Checkbox
                checked={selectedProducts.size === filteredAndSortedProducts.length && filteredAndSortedProducts.length > 0}
                onCheckedChange={handleSelectAll}
              />
              <Label className="text-sm text-muted-foreground">
                Select all {filteredAndSortedProducts.length} products
              </Label>
            </div>
          )}
          
          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4 2xl:grid-cols-5 gap-4">
            {filteredAndSortedProducts.map((product) => (
              <Card key={product.id} className="overflow-hidden hover:shadow-lg transition relative group">
                {/* Selection Checkbox */}
                <div className="absolute top-2 left-2 z-10">
                  <Checkbox
                    checked={selectedProducts.has(product.id)}
                    onCheckedChange={(checked) => handleSelectProduct(product.id, checked as boolean)}
                    className="bg-white"
                  />
                </div>

                {/* Product Image */}
                <div className="h-48 bg-gray-100 relative">
                  {product.image_url ? (
                    <img
                      src={product.image_url}
                      alt={product.name}
                      className="w-full h-full object-cover"
                      loading="lazy"
                    />
                  ) : (
                    <div className="w-full h-full flex items-center justify-center">
                      <Package className="h-12 w-12 text-muted-foreground" />
                    </div>
                  )}
                  
                  {/* Status Badge */}
                  <Badge 
                    className="absolute top-2 right-2"
                    variant={product.status === 'active' ? 'success' : 'secondary'}
                  >
                    {product.status}
                  </Badge>

                  {/* Inventory Badge */}
                  {product.total_inventory !== undefined && (
                    <Badge 
                      className="absolute bottom-2 right-2"
                      variant={
                        product.total_inventory === 0 ? 'destructive' :
                        product.total_inventory < 10 ? 'warning' : 'default'
                      }
                    >
                      {product.total_inventory} in stock
                    </Badge>
                  )}

                  {/* Quick Actions (visible on hover) */}
                  <div className="absolute inset-0 bg-black/60 opacity-0 group-hover:opacity-100 transition-opacity flex items-center justify-center gap-2">
                    <Button size="sm" variant="secondary" onClick={() => handleEdit(product.id)}>
                      <Edit className="h-4 w-4" />
                    </Button>
                    <Button size="sm" variant="secondary" onClick={() => handleDuplicate(product.id)}>
                      <Copy className="h-4 w-4" />
                    </Button>
                    <Button size="sm" variant="secondary" onClick={() => handleDelete(product.id)}>
                      <Trash2 className="h-4 w-4" />
                    </Button>
                  </div>
                </div>

                {/* Product Info */}
                <CardContent className="p-4">
                  <h3 className="font-semibold text-sm mb-1 line-clamp-1">{product.name}</h3>
                  <p className="text-xs text-muted-foreground mb-2">SKU: {product.sku}</p>
                  
                  <div className="flex items-center justify-between mb-2">
                    <span className="text-lg font-bold">${(product.base_price / 100).toFixed(2)}</span>
                    {product.sale_price && (
                      <span className="text-sm text-muted-foreground line-through">
                        ${(product.sale_price / 100).toFixed(2)}
                      </span>
                    )}
                  </div>

                  <div className="flex items-center justify-between text-xs text-muted-foreground">
                    <span>{product.category}</span>
                    <span>{product.variant_count} variants</span>
                  </div>

                  {product.margin !== undefined && product.margin > 0 && (
                    <div className="mt-2 pt-2 border-t">
                      <div className="flex items-center justify-between text-xs">
                        <span className="text-muted-foreground">Margin</span>
                        <Badge variant={product.margin > 50 ? 'success' : product.margin > 30 ? 'default' : 'warning'}>
                          {product.margin.toFixed(0)}%
                        </Badge>
                      </div>
                    </div>
                  )}
                </CardContent>
              </Card>
            ))}
          </div>
        </>
      ) : (
        /* List View */
        <Card>
          <div className="overflow-x-auto">
            <table className="w-full">
              <thead className="border-b">
                <tr>
                  <th className="p-4 text-left">
                    <Checkbox
                      checked={selectedProducts.size === filteredAndSortedProducts.length && filteredAndSortedProducts.length > 0}
                      onCheckedChange={handleSelectAll}
                    />
                  </th>
                  <th className="p-4 text-left">Product</th>
                  <th className="p-4 text-left">SKU</th>
                  <th className="p-4 text-left">Category</th>
                  <th className="p-4 text-right">Price</th>
                  <th className="p-4 text-center">Status</th>
                  <th className="p-4 text-right">Inventory</th>
                  <th className="p-4 text-center">Variants</th>
                  <th className="p-4 text-right">Actions</th>
                </tr>
              </thead>
              <tbody>
                {filteredAndSortedProducts.map((product) => (
                  <tr key={product.id} className="border-b hover:bg-muted/50">
                    <td className="p-4">
                      <Checkbox
                        checked={selectedProducts.has(product.id)}
                        onCheckedChange={(checked) => handleSelectProduct(product.id, checked as boolean)}
                      />
                    </td>
                    <td className="p-4">
                      <div className="flex items-center gap-3">
                        {product.image_url ? (
                          <img
                            src={product.image_url}
                            alt={product.name}
                            className="h-10 w-10 rounded object-cover"
                          />
                        ) : (
                          <div className="h-10 w-10 rounded bg-muted flex items-center justify-center">
                            <Package className="h-5 w-5 text-muted-foreground" />
                          </div>
                        )}
                        <div>
                          <p className="font-medium">{product.name}</p>
                          {product.vendor_name && (
                            <p className="text-xs text-muted-foreground">{product.vendor_name}</p>
                          )}
                        </div>
                      </div>
                    </td>
                    <td className="p-4 text-sm">{product.sku}</td>
                    <td className="p-4 text-sm">{product.category}</td>
                    <td className="p-4 text-right">
                      <div>
                        <p className="font-medium">${(product.base_price / 100).toFixed(2)}</p>
                        {product.sale_price && (
                          <p className="text-xs text-muted-foreground line-through">
                            ${(product.sale_price / 100).toFixed(2)}
                          </p>
                        )}
                      </div>
                    </td>
                    <td className="p-4 text-center">
                      <Badge variant={product.status === 'active' ? 'success' : 'secondary'}>
                        {product.status}
                      </Badge>
                    </td>
                    <td className="p-4 text-right">
                      <Badge variant={
                        product.total_inventory === 0 ? 'destructive' :
                        product.total_inventory && product.total_inventory < 10 ? 'warning' : 'default'
                      }>
                        {product.total_inventory || 0}
                      </Badge>
                    </td>
                    <td className="p-4 text-center text-sm">{product.variant_count || 0}</td>
                    <td className="p-4">
                      <DropdownMenu>
                        <DropdownMenuTrigger asChild>
                          <Button variant="ghost" size="sm">
                            <MoreVertical className="h-4 w-4" />
                          </Button>
                        </DropdownMenuTrigger>
                        <DropdownMenuContent align="end">
                          <DropdownMenuItem onClick={() => handleEdit(product.id)}>
                            <Edit className="h-4 w-4 mr-2" />
                            Edit
                          </DropdownMenuItem>
                          <DropdownMenuItem onClick={() => handleDuplicate(product.id)}>
                            <Copy className="h-4 w-4 mr-2" />
                            Duplicate
                          </DropdownMenuItem>
                          <DropdownMenuSeparator />
                          <DropdownMenuItem onClick={() => handleDelete(product.id)} className="text-red-600">
                            <Trash2 className="h-4 w-4 mr-2" />
                            Delete
                          </DropdownMenuItem>
                        </DropdownMenuContent>
                      </DropdownMenu>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        </Card>
      )}
    </div>
  );
}