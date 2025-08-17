import React, { useEffect, useState } from 'react';
import { supabase } from '@/lib/supabase';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { Label } from '@/components/ui/label';
import { Textarea } from '@/components/ui/textarea';
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from '@/components/ui/select';
import { Dialog, DialogContent, DialogHeader, DialogTitle, DialogTrigger } from '@/components/ui/dialog';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Badge } from '@/components/ui/badge';
import { toast } from '@/components/ui/use-toast';
import { Pencil, Trash2, Plus, Save, X, Image as ImageIcon, Copy } from 'lucide-react';
import { Tabs, TabsContent, TabsList, TabsTrigger } from '@/components/ui/tabs';

interface EnhancedProduct {
  id: string;
  name: string;
  sku: string;
  handle: string;
  slug?: string;
  style_code?: string;
  season?: string;
  collection?: string;
  category: string;
  subcategory?: string;
  price_tier: string;
  base_price: number;
  compare_at_price?: number;
  color_family?: string;
  color_name?: string;
  materials?: any;
  fit_type?: string;
  images?: any;
  description?: string;
  status: string;
  stripe_product_id?: string;
  stripe_active?: boolean;
  // SEO Fields
  meta_title?: string;
  meta_description?: string;
  meta_keywords?: string[];
  og_title?: string;
  og_description?: string;
  og_image?: string;
  canonical_url?: string;
  structured_data?: any;
  tags?: string[];
  search_terms?: string;
  url_slug?: string;
  is_indexable?: boolean;
  sitemap_priority?: number;
  sitemap_change_freq?: string;
  created_at: string;
  updated_at: string;
}

const PRICE_TIERS = [
  { value: 'TIER_1', label: 'Tier 1 ($50-74)', min: 5000, max: 7499 },
  { value: 'TIER_2', label: 'Tier 2 ($75-99)', min: 7500, max: 9999 },
  { value: 'TIER_3', label: 'Tier 3 ($100-124)', min: 10000, max: 12499 },
  { value: 'TIER_4', label: 'Tier 4 ($125-149)', min: 12500, max: 14999 },
  { value: 'TIER_5', label: 'Tier 5 ($150-199)', min: 15000, max: 19999 },
  { value: 'TIER_6', label: 'Tier 6 ($200-249)', min: 20000, max: 24999 },
  { value: 'TIER_7', label: 'Tier 7 ($250-299)', min: 25000, max: 29999 },
  { value: 'TIER_8', label: 'Tier 8 ($300-399)', min: 30000, max: 39999 },
  { value: 'TIER_9', label: 'Tier 9 ($400-499)', min: 40000, max: 49999 },
  { value: 'TIER_10', label: 'Tier 10 ($500-599)', min: 50000, max: 59999 },
];

const CATEGORIES = ['Blazers', 'Suits', 'Shirts', 'Pants', 'Accessories', 'Outerwear', 'Tuxedos', 'Vests'];
const SUBCATEGORIES = ['Prom', 'Velvet', 'Summer', 'Sparkle', 'Formal', 'Casual', 'Wedding', 'Business'];
const STATUSES = ['active', 'draft', 'archived'];
const PRODUCT_TYPES = ['Blazer', 'Suit', 'Tuxedo', 'Shirt', 'Pants', 'Vest', 'Accessories', 'Outerwear'];
const OCCASIONS = ['Wedding', 'Prom', 'Business', 'Formal Event', 'Party', 'Casual', 'Interview', 'Date Night']

export default function EnhancedProductsAdmin() {
  const [products, setProducts] = useState<EnhancedProduct[]>([]);
  const [loading, setLoading] = useState(true);
  const [editingProduct, setEditingProduct] = useState<EnhancedProduct | null>(null);
  const [isEditDialogOpen, setIsEditDialogOpen] = useState(false);
  const [isCreateDialogOpen, setIsCreateDialogOpen] = useState(false);
  const [searchTerm, setSearchTerm] = useState('');
  const [selectedCategory, setSelectedCategory] = useState<string>('all');
  const [selectedSubcategory, setSelectedSubcategory] = useState<string>('all');
  const [authError, setAuthError] = useState<string | null>(null);

  useEffect(() => {
    // Check authentication and fetch products
    checkAuthAndFetchProducts();
  }, []);

  async function checkAuthAndFetchProducts() {
    try {
      console.log('🔐 Checking authentication...');
      
      // Try to get current session
      const { data: { session }, error: sessionError } = await supabase.auth.getSession();
      
      if (sessionError) {
        console.log('⚠️ Session error:', sessionError.message);
      }
      
      if (!session) {
        console.log('🔓 No active session, attempting automatic login...');
        
        // Try automatic login with admin credentials
        const { data: loginData, error: loginError } = await supabase.auth.signInWithPassword({
          email: 'admin@kctmenswear.com',
          password: 'admin123'
        });
        
        if (loginError) {
          console.log('❌ Auto-login failed:', loginError.message);
          setAuthError(`Authentication required. ${loginError.message}`);
        } else {
          console.log('✅ Auto-login successful');
          setAuthError(null);
        }
      } else {
        console.log('✅ Valid session found');
        setAuthError(null);
      }
      
      // Always try to fetch products regardless of auth status
      await fetchEnhancedProducts();
      
    } catch (error) {
      console.error('💥 Auth check error:', error);
      setAuthError('Authentication check failed');
      // Still try to fetch products
      await fetchEnhancedProducts();
    }
  }

  async function fetchEnhancedProducts() {
    try {
      setLoading(true);
      console.log('🔍 Fetching products_enhanced...');
      
      // Try multiple approaches to fetch data
      let data = null;
      let error = null;
      
      // Approach 1: Direct Supabase query
      try {
        console.log('🔍 Attempt 1: Direct Supabase query...');
        const response = await supabase
          .from('products_enhanced')
          .select('*')
          .order('created_at', { ascending: false });
          
        console.log('📊 Response 1:', { data: response.data?.length, error: response.error, status: response.status });
        
        if (!response.error) {
          data = response.data;
          console.log('✅ Approach 1 successful:', data?.length, 'records');
        } else {
          error = response.error;
          console.log('❌ Approach 1 failed:', error.message);
        }
      } catch (directError: any) {
        console.log('❌ Approach 1 exception:', directError.message);
        error = directError;
      }
      
      // Approach 2: Use existing products service if direct query fails
      if (!data && error) {
        try {
          console.log('🔍 Attempt 2: Using products service...');
          const { fetchProductsWithImages } = await import('@/lib/services/products');
          const result = await fetchProductsWithImages({ limit: 100 });
          
          if (result.success && result.data) {
            data = result.data;
            error = null;
            console.log('✅ Approach 2 successful:', data?.length, 'records');
          } else {
            console.log('❌ Approach 2 failed:', result.error);
          }
        } catch (serviceError: any) {
          console.log('❌ Approach 2 exception:', serviceError.message);
        }
      }
      
      if (error && !data) {
        throw error;
      }
      
      setProducts(data || []);
    } catch (err: any) {
      console.error('💥 fetchEnhancedProducts error:', err);
      toast({
        title: 'Error fetching products',
        description: `${err.message} (Code: ${err.code || 'unknown'})`,
        variant: 'destructive'
      });
      // Set empty array so UI doesn't break
      setProducts([]);
    } finally {
      setLoading(false);
    }
  }

  async function handleSaveProduct(product: Partial<EnhancedProduct>) {
    try {
      // Ensure prices are in the correct format for database
      // If database expects dollars, convert from cents
      const priceInDatabase = product.base_price && product.base_price > 1000 
        ? product.base_price / 100  // Convert cents to dollars
        : product.base_price;  // Already in dollars
      
      const compareAtPriceInDatabase = product.compare_at_price && product.compare_at_price > 1000
        ? product.compare_at_price / 100
        : product.compare_at_price;
        
      const costPerUnitInDatabase = product.cost_per_unit && product.cost_per_unit > 1000
        ? product.cost_per_unit / 100
        : product.cost_per_unit;

      const productData = {
        ...product,
        base_price: priceInDatabase,
        compare_at_price: compareAtPriceInDatabase,
        cost_per_unit: costPerUnitInDatabase
      };

      if (editingProduct?.id) {
        // Update existing product
        const { error } = await supabase
          .from('products_enhanced')
          .update({
            ...productData,
            updated_at: new Date().toISOString()
          })
          .eq('id', editingProduct.id);

        if (error) throw error;
        
        toast({
          title: 'Product updated',
          description: 'Product has been successfully updated'
        });
      } else {
        // Create new product
        const handle = product.name?.toLowerCase().replace(/[^a-z0-9]+/g, '-') || '';
        const { error } = await supabase
          .from('products_enhanced')
          .insert({
            ...productData,
            handle,
            slug: handle,
            created_at: new Date().toISOString(),
            updated_at: new Date().toISOString()
          });

        if (error) throw error;
        
        toast({
          title: 'Product created',
          description: 'New product has been successfully created'
        });
      }

      setIsEditDialogOpen(false);
      setIsCreateDialogOpen(false);
      setEditingProduct(null);
      fetchEnhancedProducts();
    } catch (err: any) {
      toast({
        title: 'Error saving product',
        description: err.message,
        variant: 'destructive'
      });
    }
  }

  async function handleDeleteProduct(id: string) {
    if (!confirm('Are you sure you want to delete this product?')) return;

    try {
      const { error } = await supabase
        .from('products_enhanced')
        .delete()
        .eq('id', id);

      if (error) throw error;
      
      toast({
        title: 'Product deleted',
        description: 'Product has been successfully deleted'
      });
      
      fetchEnhancedProducts();
    } catch (err: any) {
      toast({
        title: 'Error deleting product',
        description: err.message,
        variant: 'destructive'
      });
    }
  }

  async function handleDuplicateProduct(product: EnhancedProduct) {
    try {
      const newProduct = {
        ...product,
        id: undefined,
        name: `${product.name} (Copy)`,
        sku: `${product.sku}-COPY-${Date.now()}`,
        handle: `${product.handle}-copy-${Date.now()}`,
        slug: `${product.slug || product.handle}-copy-${Date.now()}`,
        created_at: new Date().toISOString(),
        updated_at: new Date().toISOString()
      };

      delete newProduct.id;

      const { error } = await supabase
        .from('products_enhanced')
        .insert(newProduct);

      if (error) throw error;
      
      toast({
        title: 'Product duplicated',
        description: 'Product has been successfully duplicated'
      });
      
      fetchEnhancedProducts();
    } catch (err: any) {
      toast({
        title: 'Error duplicating product',
        description: err.message,
        variant: 'destructive'
      });
    }
  }

  const filteredProducts = products.filter(product => {
    const matchesSearch = product.name.toLowerCase().includes(searchTerm.toLowerCase()) ||
                          product.sku.toLowerCase().includes(searchTerm.toLowerCase());
    const matchesCategory = selectedCategory === 'all' || product.category === selectedCategory;
    const matchesSubcategory = selectedSubcategory === 'all' || product.subcategory === selectedSubcategory;
    
    return matchesSearch && matchesCategory && matchesSubcategory;
  });

  const stats = {
    total: products.length,
    active: products.filter(p => p.status === 'active').length,
    totalImages: products.reduce((sum, p) => sum + (p.images?.total_images || 0), 0),
    uniqueTiers: new Set(products.map(p => p.price_tier)).size
  };

  return (
    <div className="container mx-auto p-6">
      <div className="flex justify-between items-center mb-6">
        <h1 className="text-3xl font-bold">Enhanced Products Admin</h1>
        <div className="flex gap-2">
          {authError && (
            <Button 
              variant="outline" 
              onClick={() => checkAuthAndFetchProducts()}
              className="text-orange-600 border-orange-600"
            >
              Retry Login
            </Button>
          )}
          <Button onClick={() => {
            setEditingProduct(null);
            setIsCreateDialogOpen(true);
          }}>
            <Plus className="mr-2 h-4 w-4" />
            Add Product
          </Button>
        </div>
      </div>

      {authError && (
        <div className="mb-6 p-4 bg-orange-50 border border-orange-200 rounded-lg">
          <div className="flex items-center gap-2">
            <span className="text-orange-600 font-medium">⚠️ Authentication Issue</span>
          </div>
          <p className="text-orange-700 mt-1">{authError}</p>
          <p className="text-orange-600 text-sm mt-2">
            Note: Product data may still load if RLS policies allow anonymous access.
          </p>
        </div>
      )}

      {/* Stats Cards */}
      <div className="grid grid-cols-4 gap-4 mb-6">
        <Card>
          <CardHeader className="pb-2">
            <CardTitle className="text-sm font-medium text-muted-foreground">Total Products</CardTitle>
          </CardHeader>
          <CardContent>
            <div className="text-2xl font-bold">{stats.total}</div>
          </CardContent>
        </Card>
        <Card>
          <CardHeader className="pb-2">
            <CardTitle className="text-sm font-medium text-muted-foreground">Active</CardTitle>
          </CardHeader>
          <CardContent>
            <div className="text-2xl font-bold">{stats.active}</div>
          </CardContent>
        </Card>
        <Card>
          <CardHeader className="pb-2">
            <CardTitle className="text-sm font-medium text-muted-foreground">Total Images</CardTitle>
          </CardHeader>
          <CardContent>
            <div className="text-2xl font-bold">{stats.totalImages}</div>
          </CardContent>
        </Card>
        <Card>
          <CardHeader className="pb-2">
            <CardTitle className="text-sm font-medium text-muted-foreground">Price Tiers</CardTitle>
          </CardHeader>
          <CardContent>
            <div className="text-2xl font-bold">{stats.uniqueTiers}</div>
          </CardContent>
        </Card>
      </div>

      {/* Filters */}
      <div className="flex gap-4 mb-6">
        <Input
          placeholder="Search products..."
          value={searchTerm}
          onChange={(e) => setSearchTerm(e.target.value)}
          className="max-w-sm"
        />
        <Select value={selectedCategory} onValueChange={setSelectedCategory}>
          <SelectTrigger className="w-[180px]">
            <SelectValue placeholder="Category" />
          </SelectTrigger>
          <SelectContent>
            <SelectItem value="all">All Categories</SelectItem>
            {CATEGORIES.map(cat => (
              <SelectItem key={cat} value={cat}>{cat}</SelectItem>
            ))}
          </SelectContent>
        </Select>
        <Select value={selectedSubcategory} onValueChange={setSelectedSubcategory}>
          <SelectTrigger className="w-[180px]">
            <SelectValue placeholder="Subcategory" />
          </SelectTrigger>
          <SelectContent>
            <SelectItem value="all">All Subcategories</SelectItem>
            {SUBCATEGORIES.map(sub => (
              <SelectItem key={sub} value={sub}>{sub}</SelectItem>
            ))}
          </SelectContent>
        </Select>
      </div>

      {/* Products Table */}
      <Card>
        <CardContent className="p-0">
          <div className="overflow-x-auto">
            <table className="w-full">
              <thead className="bg-muted/50">
                <tr>
                  <th className="text-left p-4">Image</th>
                  <th className="text-left p-4">Product</th>
                  <th className="text-left p-4">SKU</th>
                  <th className="text-left p-4">Category</th>
                  <th className="text-left p-4">Price</th>
                  <th className="text-left p-4">Images</th>
                  <th className="text-left p-4">Status</th>
                  <th className="text-left p-4">Actions</th>
                </tr>
              </thead>
              <tbody>
                {loading ? (
                  <tr>
                    <td colSpan={8} className="text-center p-8">Loading...</td>
                  </tr>
                ) : filteredProducts.length === 0 ? (
                  <tr>
                    <td colSpan={8} className="text-center p-8">No products found</td>
                  </tr>
                ) : (
                  filteredProducts.map((product) => (
                    <tr key={product.id} className="border-t hover:bg-muted/30">
                      <td className="p-4">
                        {product.images?.hero?.url ? (
                          <img 
                            src={product.images.hero.url} 
                            alt={product.name}
                            className="w-16 h-16 object-cover rounded"
                            onError={(e) => {
                              console.log('❌ Image failed to load:', product.images.hero.url);
                              (e.target as HTMLImageElement).src = '/placeholder.svg';
                              (e.target as HTMLImageElement).classList.add('opacity-50');
                            }}
                            onLoad={() => {
                              console.log('✅ Image loaded successfully:', product.images.hero.url);
                            }}
                          />
                        ) : (
                          <div className="w-16 h-16 bg-muted rounded flex items-center justify-center">
                            <ImageIcon className="h-6 w-6 text-muted-foreground" />
                          </div>
                        )}
                      </td>
                      <td className="p-4">
                        <div>
                          <div className="font-medium">{product.name}</div>
                          <div className="text-sm text-muted-foreground">{product.handle}</div>
                        </div>
                      </td>
                      <td className="p-4">{product.sku}</td>
                      <td className="p-4">
                        <div>
                          <div>{product.category}</div>
                          {product.subcategory && (
                            <div className="text-sm text-muted-foreground">{product.subcategory}</div>
                          )}
                        </div>
                      </td>
                      <td className="p-4">
                        <div>
                          <Badge variant="secondary">{product.price_tier}</Badge>
                          <div className="text-sm mt-1">${(product.base_price / 100).toFixed(2)}</div>
                        </div>
                      </td>
                      <td className="p-4">
                        <span className="text-sm">{product.images?.total_images || 0} images</span>
                      </td>
                      <td className="p-4">
                        <Badge variant={product.status === 'active' ? 'default' : 'secondary'}>
                          {product.status}
                        </Badge>
                      </td>
                      <td className="p-4">
                        <div className="flex gap-2">
                          <Button
                            size="sm"
                            variant="ghost"
                            onClick={() => {
                              try {
                                console.log('📝 Editing product:', product.name, product);
                                setEditingProduct(product);
                                setIsEditDialogOpen(true);
                              } catch (error) {
                                console.error('❌ Error opening edit dialog:', error);
                                toast({
                                  title: 'Error opening editor',
                                  description: 'Failed to load product data for editing',
                                  variant: 'destructive'
                                });
                              }
                            }}
                          >
                            <Pencil className="h-4 w-4" />
                          </Button>
                          <Button
                            size="sm"
                            variant="ghost"
                            onClick={() => handleDuplicateProduct(product)}
                          >
                            <Copy className="h-4 w-4" />
                          </Button>
                          <Button
                            size="sm"
                            variant="ghost"
                            onClick={() => handleDeleteProduct(product.id)}
                            className="text-destructive hover:text-destructive"
                          >
                            <Trash2 className="h-4 w-4" />
                          </Button>
                        </div>
                      </td>
                    </tr>
                  ))
                )}
              </tbody>
            </table>
          </div>
        </CardContent>
      </Card>

      {/* Edit/Create Dialog */}
      <Dialog open={isEditDialogOpen || isCreateDialogOpen} onOpenChange={(open) => {
        if (!open) {
          setIsEditDialogOpen(false);
          setIsCreateDialogOpen(false);
          setEditingProduct(null);
        }
      }}>
        <DialogContent className="max-w-3xl max-h-[90vh] overflow-y-auto">
          <DialogHeader>
            <DialogTitle>
              {editingProduct?.id ? 'Edit Product' : 'Create New Product'}
            </DialogTitle>
          </DialogHeader>
          
          <ProductForm
            product={editingProduct}
            onSave={handleSaveProduct}
            onCancel={() => {
              setIsEditDialogOpen(false);
              setIsCreateDialogOpen(false);
              setEditingProduct(null);
            }}
          />
        </DialogContent>
      </Dialog>
    </div>
  );
}

// Product Form Component
function ProductForm({ 
  product, 
  onSave, 
  onCancel 
}: { 
  product: EnhancedProduct | null;
  onSave: (product: Partial<EnhancedProduct>) => void;
  onCancel: () => void;
}) {
  // Helper function to ensure price is in cents
  const ensurePriceInCents = (price: number | undefined): number => {
    if (!price) return 0;
    // If price is less than 1000, it's likely in dollars, convert to cents
    if (price < 1000) {
      return Math.round(price * 100);
    }
    return Math.round(price);
  };

  const basePriceInCents = ensurePriceInCents(product?.base_price) || 27999;
  const compareAtPriceInCents = ensurePriceInCents(product?.compare_at_price) || 0;

  const [formData, setFormData] = useState<Partial<EnhancedProduct>>({
    name: product?.name || '',
    sku: product?.sku || '',
    category: product?.category || 'Blazers',
    subcategory: product?.subcategory || '',
    product_type: product?.category || '',  // Use category as product_type fallback
    occasion: product?.tags || [],  // Use tags as occasions
    price_tier: product?.price_tier || 'TIER_7',
    base_price: basePriceInCents,
    compare_at_price: compareAtPriceInCents,
    cost_per_unit: Math.round(basePriceInCents * 0.4),  // Estimate 40% cost
    description: product?.description || '',
    status: product?.status || 'active',
    is_available: product?.status === 'active',  // Derive from status
    launch_date: product?.created_at || '',  // Use created_at as launch_date
    discontinue_date: '',  // Empty initially
    style_code: product?.style_code || '',
    season: product?.season || 'SS24',
    collection: product?.collection || '',
    color_family: product?.color_family || '',
    color_name: product?.color_name || '',
    fit_type: product?.fit_type || 'Slim Fit',
    size_range: product?.available_sizes ? { available: product.available_sizes } : {},
    measurements: {},  // Empty initially
    materials: (typeof product?.materials === 'object' && product?.materials) || {},
    care_instructions: Array.isArray(product?.care_instructions) ? product.care_instructions : [],
    view_count: product?.view_count || 0,
    add_to_cart_count: product?.add_to_cart_count || 0,
    purchase_count: product?.purchase_count || 0,
    return_rate: product?.return_rate || 0,
    images: (typeof product?.images === 'object' && product?.images) || {
      hero: null,
      flat: null,
      lifestyle: [],
      details: [],
      total_images: 0
    },
    // Include all existing fields from database
    meta_title: product?.meta_title || '',
    meta_description: product?.meta_description || '',
    meta_keywords: product?.meta_keywords || [],
    og_title: product?.og_title || '',
    og_description: product?.og_description || '',
    og_image: product?.og_image || '',
    canonical_url: product?.canonical_url || '',
    structured_data: product?.structured_data || {},
    tags: product?.tags || [],
    search_terms: product?.search_terms || '',
    url_slug: product?.url_slug || product?.slug || '',
    is_indexable: product?.is_indexable !== false,
    sitemap_priority: product?.sitemap_priority || 0.8,
    sitemap_change_freq: product?.sitemap_change_freq || 'weekly',
    size_options: product?.size_options || { regular: true, short: false, long: false },
    available_sizes: product?.available_sizes || []
  });

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    onSave(formData);
  };

  const updateImages = (field: string, value: any) => {
    setFormData(prev => ({
      ...prev,
      images: {
        ...prev.images,
        [field]: value,
        total_images: calculateTotalImages({ ...prev.images, [field]: value })
      }
    }));
  };

  const calculateTotalImages = (images: any) => {
    let count = 0;
    if (images?.hero) count++;
    if (images?.flat) count++;
    count += (images?.lifestyle?.length || 0);
    count += (images?.details?.length || 0);
    return count;
  };

  return (
    <form onSubmit={handleSubmit} className="space-y-6">
      <Tabs defaultValue="basic" className="w-full">
        <TabsList className="grid w-full grid-cols-7">
          <TabsTrigger value="basic">Basic</TabsTrigger>
          <TabsTrigger value="pricing">Pricing</TabsTrigger>
          <TabsTrigger value="images">Images</TabsTrigger>
          <TabsTrigger value="details">Details</TabsTrigger>
          <TabsTrigger value="inventory">Inventory</TabsTrigger>
          <TabsTrigger value="analytics">Analytics</TabsTrigger>
          <TabsTrigger value="seo">SEO</TabsTrigger>
        </TabsList>
        
        <TabsContent value="basic" className="space-y-4">
          <div className="grid grid-cols-2 gap-4">
            <div>
              <Label htmlFor="name">Product Name*</Label>
              <Input
                id="name"
                value={formData.name}
                onChange={(e) => setFormData({...formData, name: e.target.value})}
                required
              />
            </div>
            <div>
              <Label htmlFor="sku">SKU*</Label>
              <Input
                id="sku"
                value={formData.sku}
                onChange={(e) => setFormData({...formData, sku: e.target.value})}
                required
              />
            </div>
          </div>

          <div className="grid grid-cols-2 gap-4">
            <div>
              <Label htmlFor="category">Category*</Label>
              <Select 
                value={formData.category} 
                onValueChange={(value) => setFormData({...formData, category: value})}
              >
                <SelectTrigger>
                  <SelectValue />
                </SelectTrigger>
                <SelectContent>
                  {CATEGORIES.map(cat => (
                    <SelectItem key={cat} value={cat}>{cat}</SelectItem>
                  ))}
                </SelectContent>
              </Select>
            </div>
            <div>
              <Label htmlFor="subcategory">Subcategory</Label>
              <Select 
                value={formData.subcategory} 
                onValueChange={(value) => setFormData({...formData, subcategory: value})}
              >
                <SelectTrigger>
                  <SelectValue />
                </SelectTrigger>
                <SelectContent>
                  {SUBCATEGORIES.map(sub => (
                    <SelectItem key={sub} value={sub}>{sub}</SelectItem>
                  ))}
                </SelectContent>
              </Select>
            </div>
          </div>

          <div className="grid grid-cols-2 gap-4">
            <div>
              <Label htmlFor="product_type">Product Type</Label>
              <Select 
                value={formData.product_type} 
                onValueChange={(value) => setFormData({...formData, product_type: value})}
              >
                <SelectTrigger>
                  <SelectValue placeholder="Select product type" />
                </SelectTrigger>
                <SelectContent>
                  {PRODUCT_TYPES.map(type => (
                    <SelectItem key={type} value={type}>{type}</SelectItem>
                  ))}
                </SelectContent>
              </Select>
            </div>
            <div>
              <Label htmlFor="occasion">Occasions (stored in tags)</Label>
              <div className="flex flex-wrap gap-2 mt-2">
                {OCCASIONS.map(occ => (
                  <label key={occ} className="flex items-center gap-1">
                    <input
                      type="checkbox"
                      checked={Array.isArray(formData.tags) && formData.tags.includes(occ)}
                      onChange={(e) => {
                        const tags = Array.isArray(formData.tags) ? [...formData.tags] : [];
                        if (e.target.checked) {
                          tags.push(occ);
                        } else {
                          const index = tags.indexOf(occ);
                          if (index > -1) tags.splice(index, 1);
                        }
                        setFormData({...formData, tags});
                      }}
                      className="h-4 w-4"
                    />
                    <span className="text-sm">{occ}</span>
                  </label>
                ))}
              </div>
            </div>
          </div>

          <div>
            <Label htmlFor="description">Description</Label>
            <Textarea
              id="description"
              value={formData.description}
              onChange={(e) => setFormData({...formData, description: e.target.value})}
              rows={4}
            />
          </div>

          <div>
            <Label htmlFor="status">Status</Label>
            <Select 
              value={formData.status} 
              onValueChange={(value) => setFormData({...formData, status: value})}
            >
              <SelectTrigger>
                <SelectValue />
              </SelectTrigger>
              <SelectContent>
                {STATUSES.map(status => (
                  <SelectItem key={status} value={status}>{status}</SelectItem>
                ))}
              </SelectContent>
            </Select>
          </div>
        </TabsContent>
        
        <TabsContent value="pricing" className="space-y-4">
          <div>
            <Label htmlFor="price_tier">Price Tier*</Label>
            <Select 
              value={formData.price_tier} 
              onValueChange={(value) => {
                const tier = PRICE_TIERS.find(t => t.value === value);
                if (tier) {
                  setFormData({
                    ...formData, 
                    price_tier: value,
                    base_price: tier.min
                  });
                }
              }}
            >
              <SelectTrigger>
                <SelectValue />
              </SelectTrigger>
              <SelectContent>
                {PRICE_TIERS.map(tier => (
                  <SelectItem key={tier.value} value={tier.value}>
                    {tier.label}
                  </SelectItem>
                ))}
              </SelectContent>
            </Select>
          </div>

          <div className="grid grid-cols-2 gap-4">
            <div>
              <Label htmlFor="base_price">Base Price (cents)*</Label>
              <Input
                id="base_price"
                type="number"
                value={formData.base_price}
                onChange={(e) => setFormData({...formData, base_price: parseInt(e.target.value)})}
                required
              />
              <p className="text-sm text-muted-foreground mt-1">
                ${((formData.base_price || 0) / 100).toFixed(2)}
              </p>
            </div>
            <div>
              <Label htmlFor="compare_at_price">Compare at Price (cents)</Label>
              <Input
                id="compare_at_price"
                type="number"
                value={formData.compare_at_price}
                onChange={(e) => setFormData({...formData, compare_at_price: parseInt(e.target.value)})}
              />
              {formData.compare_at_price ? (
                <p className="text-sm text-muted-foreground mt-1">
                  ${((formData.compare_at_price || 0) / 100).toFixed(2)}
                </p>
              ) : null}
            </div>
          </div>

          <div className="grid grid-cols-2 gap-4">
            <div>
              <Label htmlFor="cost_per_unit">Estimated Cost Per Unit (cents)</Label>
              <Input
                id="cost_per_unit"
                type="number"
                value={formData.cost_per_unit}
                onChange={(e) => setFormData({...formData, cost_per_unit: parseInt(e.target.value)})}
              />
              <p className="text-sm text-muted-foreground mt-1">
                Cost: ${((formData.cost_per_unit || 0) / 100).toFixed(2)} (estimated at 40% of base price)
              </p>
            </div>
            <div>
              <Label>Profit Margin</Label>
              <div className="p-3 bg-muted rounded-md mt-2">
                <p className="text-sm font-medium">
                  {formData.base_price && formData.cost_per_unit ? 
                    `${(((formData.base_price - formData.cost_per_unit) / formData.base_price) * 100).toFixed(1)}%` : 
                    'N/A'}
                </p>
                {formData.base_price && formData.cost_per_unit ? (
                  <p className="text-xs text-muted-foreground mt-1">
                    Profit: ${((formData.base_price - formData.cost_per_unit) / 100).toFixed(2)}
                  </p>
                ) : null}
              </div>
            </div>
          </div>
        </TabsContent>
        
        <TabsContent value="images" className="space-y-4">
          <div>
            <Label htmlFor="hero_image">Hero Image URL</Label>
            <Input
              id="hero_image"
              value={formData.images?.hero?.url || ''}
              onChange={(e) => updateImages('hero', e.target.value ? { url: e.target.value } : null)}
              placeholder="https://cdn.kctmenswear.com/..."
            />
          </div>

          <div>
            <Label htmlFor="flat_image">Flat Image URL</Label>
            <Input
              id="flat_image"
              value={formData.images?.flat?.url || ''}
              onChange={(e) => updateImages('flat', e.target.value ? { url: e.target.value } : null)}
              placeholder="https://cdn.kctmenswear.com/..."
            />
          </div>

          <div>
            <Label>Lifestyle Images (comma-separated URLs)</Label>
            <Textarea
              value={formData.images?.lifestyle?.map((img: any) => img.url).join(', ') || ''}
              onChange={(e) => {
                const urls = e.target.value.split(',').map(url => url.trim()).filter(url => url);
                updateImages('lifestyle', urls.map(url => ({ url })));
              }}
              placeholder="URL 1, URL 2, URL 3..."
              rows={3}
            />
          </div>

          <div>
            <Label>Detail Images (comma-separated URLs)</Label>
            <Textarea
              value={formData.images?.details?.map((img: any) => img.url).join(', ') || ''}
              onChange={(e) => {
                const urls = e.target.value.split(',').map(url => url.trim()).filter(url => url);
                updateImages('details', urls.map(url => ({ url })));
              }}
              placeholder="URL 1, URL 2, URL 3..."
              rows={3}
            />
          </div>

          <div className="text-sm text-muted-foreground">
            Total Images: {formData.images?.total_images || 0}
          </div>
        </TabsContent>
        
        <TabsContent value="details" className="space-y-4">
          <div className="grid grid-cols-2 gap-4">
            <div>
              <Label htmlFor="style_code">Style Code</Label>
              <Input
                id="style_code"
                value={formData.style_code}
                onChange={(e) => setFormData({...formData, style_code: e.target.value})}
              />
            </div>
            <div>
              <Label htmlFor="season">Season</Label>
              <Input
                id="season"
                value={formData.season}
                onChange={(e) => setFormData({...formData, season: e.target.value})}
                placeholder="SS24, FW24, etc."
              />
            </div>
          </div>

          <div className="grid grid-cols-2 gap-4">
            <div>
              <Label htmlFor="collection">Collection</Label>
              <Input
                id="collection"
                value={formData.collection}
                onChange={(e) => setFormData({...formData, collection: e.target.value})}
              />
            </div>
            <div>
              <Label htmlFor="fit_type">Fit Type</Label>
              <Select 
                value={formData.fit_type} 
                onValueChange={(value) => setFormData({...formData, fit_type: value})}
              >
                <SelectTrigger>
                  <SelectValue />
                </SelectTrigger>
                <SelectContent>
                  <SelectItem value="Slim Fit">Slim Fit</SelectItem>
                  <SelectItem value="Regular Fit">Regular Fit</SelectItem>
                  <SelectItem value="Relaxed Fit">Relaxed Fit</SelectItem>
                  <SelectItem value="Modern Fit">Modern Fit</SelectItem>
                </SelectContent>
              </Select>
            </div>
          </div>

          <div className="grid grid-cols-2 gap-4">
            <div>
              <Label htmlFor="color_family">Color Family</Label>
              <Input
                id="color_family"
                value={formData.color_family}
                onChange={(e) => setFormData({...formData, color_family: e.target.value})}
                placeholder="Black, Blue, Red, etc."
              />
            </div>
            <div>
              <Label htmlFor="color_name">Color Name</Label>
              <Input
                id="color_name"
                value={formData.color_name}
                onChange={(e) => setFormData({...formData, color_name: e.target.value})}
                placeholder="Midnight Navy, Burgundy, etc."
              />
            </div>
          </div>

          <div>
            <Label htmlFor="materials">Materials (JSON format)</Label>
            <Textarea
              id="materials"
              value={typeof formData.materials === 'object' ? JSON.stringify(formData.materials, null, 2) : ''}
              onChange={(e) => {
                try {
                  const materials = JSON.parse(e.target.value);
                  setFormData({...formData, materials});
                } catch {
                  // Invalid JSON, don't update
                }
              }}
              placeholder='{"primary": "Cotton", "composition": {"Cotton": 60, "Polyester": 40}}'
              rows={4}
              className="font-mono text-sm"
            />
          </div>

          <div>
            <Label htmlFor="care_instructions">Care Instructions (one per line)</Label>
            <Textarea
              id="care_instructions"
              value={Array.isArray(formData.care_instructions) ? formData.care_instructions.join('\n') : ''}
              onChange={(e) => setFormData({
                ...formData, 
                care_instructions: e.target.value.split('\n').filter(line => line.trim())
              })}
              placeholder="Machine wash cold\nTumble dry low\nDo not bleach\nIron on low heat"
              rows={4}
            />
          </div>

          <div className="grid grid-cols-2 gap-4">
            <div>
              <Label htmlFor="size_range">Available Sizes (comma-separated)</Label>
              <Textarea
                id="size_range"
                value={Array.isArray(formData.available_sizes) ? formData.available_sizes.join(', ') : ''}
                onChange={(e) => {
                  const sizes = e.target.value.split(',').map(s => s.trim()).filter(s => s);
                  setFormData({...formData, available_sizes: sizes});
                }}
                placeholder="36R, 38R, 40R, 42R, 44R, 46R, 48R, 50R, 52R, 54R"
                rows={3}
              />
              <p className="text-sm text-muted-foreground mt-1">
                {Array.isArray(formData.available_sizes) ? formData.available_sizes.length : 0} sizes available
              </p>
            </div>
            <div>
              <Label htmlFor="measurements">Measurements (JSON)</Label>
              <Textarea
                id="measurements"
                value={typeof formData.measurements === 'object' ? JSON.stringify(formData.measurements, null, 2) : ''}
                onChange={(e) => {
                  try {
                    const measurements = JSON.parse(e.target.value);
                    setFormData({...formData, measurements});
                  } catch {
                    // Invalid JSON
                  }
                }}
                placeholder='{"chest": "42 inches", "length": "30 inches", "sleeve": "34 inches"}'
                rows={3}
                className="font-mono text-sm"
              />
            </div>
          </div>
        </TabsContent>
        
        <TabsContent value="inventory" className="space-y-4">
          <div className="grid grid-cols-2 gap-4">
            <div className="flex items-center space-x-2">
              <input
                type="checkbox"
                id="is_available"
                checked={formData.is_available !== false}
                onChange={(e) => setFormData({...formData, is_available: e.target.checked})}
                className="h-4 w-4"
              />
              <Label htmlFor="is_available">Product Available for Sale</Label>
            </div>
          </div>

          <div className="grid grid-cols-2 gap-4">
            <div>
              <Label htmlFor="launch_date">Launch Date (Created Date)</Label>
              <Input
                id="launch_date"
                type="datetime-local"
                value={formData.launch_date ? new Date(formData.launch_date).toISOString().slice(0, 16) : ''}
                readOnly
                className="bg-muted"
              />
              <p className="text-sm text-muted-foreground mt-1">Based on product creation date</p>
            </div>
            <div>
              <Label htmlFor="discontinue_date">Discontinue Date</Label>
              <Input
                id="discontinue_date"
                type="datetime-local"
                value={formData.discontinue_date ? new Date(formData.discontinue_date).toISOString().slice(0, 16) : ''}
                onChange={(e) => setFormData({...formData, discontinue_date: e.target.value ? new Date(e.target.value).toISOString() : ''})}
              />
            </div>
          </div>

          <div className="p-4 bg-muted rounded-lg">
            <h4 className="font-medium mb-2">Product Lifecycle</h4>
            <div className="space-y-2 text-sm">
              <div className="flex justify-between">
                <span>Status:</span>
                <Badge variant={formData.status === 'active' ? 'default' : 'secondary'}>
                  {formData.status}
                </Badge>
              </div>
              <div className="flex justify-between">
                <span>Available:</span>
                <Badge variant={formData.is_available ? 'default' : 'destructive'}>
                  {formData.is_available ? 'Yes' : 'No'}
                </Badge>
              </div>
              {formData.launch_date && (
                <div className="flex justify-between">
                  <span>Launch:</span>
                  <span>{new Date(formData.launch_date).toLocaleDateString()}</span>
                </div>
              )}
              {formData.discontinue_date && (
                <div className="flex justify-between">
                  <span>Discontinue:</span>
                  <span>{new Date(formData.discontinue_date).toLocaleDateString()}</span>
                </div>
              )}
            </div>
          </div>
        </TabsContent>
        
        <TabsContent value="analytics" className="space-y-4">
          <div className="grid grid-cols-2 gap-4">
            <div>
              <Label htmlFor="view_count">View Count</Label>
              <Input
                id="view_count"
                type="number"
                value={formData.view_count}
                onChange={(e) => setFormData({...formData, view_count: parseInt(e.target.value) || 0})}
                readOnly
                className="bg-muted"
              />
            </div>
            <div>
              <Label htmlFor="add_to_cart_count">Add to Cart Count</Label>
              <Input
                id="add_to_cart_count"
                type="number"
                value={formData.add_to_cart_count}
                onChange={(e) => setFormData({...formData, add_to_cart_count: parseInt(e.target.value) || 0})}
                readOnly
                className="bg-muted"
              />
            </div>
          </div>

          <div className="grid grid-cols-2 gap-4">
            <div>
              <Label htmlFor="purchase_count">Purchase Count</Label>
              <Input
                id="purchase_count"
                type="number"
                value={formData.purchase_count}
                onChange={(e) => setFormData({...formData, purchase_count: parseInt(e.target.value) || 0})}
                readOnly
                className="bg-muted"
              />
            </div>
            <div>
              <Label htmlFor="return_rate">Return Rate (%)</Label>
              <Input
                id="return_rate"
                type="number"
                step="0.1"
                max="100"
                value={formData.return_rate}
                onChange={(e) => setFormData({...formData, return_rate: parseFloat(e.target.value) || 0})}
                readOnly
                className="bg-muted"
              />
            </div>
          </div>

          <div className="grid grid-cols-3 gap-4">
            <Card>
              <CardHeader className="pb-2">
                <CardTitle className="text-sm font-medium text-muted-foreground">Conversion Rate</CardTitle>
              </CardHeader>
              <CardContent>
                <div className="text-2xl font-bold">
                  {formData.view_count && formData.purchase_count ? 
                    ((formData.purchase_count / formData.view_count) * 100).toFixed(2) + '%' : 
                    'N/A'}
                </div>
              </CardContent>
            </Card>
            <Card>
              <CardHeader className="pb-2">
                <CardTitle className="text-sm font-medium text-muted-foreground">Cart Rate</CardTitle>
              </CardHeader>
              <CardContent>
                <div className="text-2xl font-bold">
                  {formData.view_count && formData.add_to_cart_count ? 
                    ((formData.add_to_cart_count / formData.view_count) * 100).toFixed(2) + '%' : 
                    'N/A'}
                </div>
              </CardContent>
            </Card>
            <Card>
              <CardHeader className="pb-2">
                <CardTitle className="text-sm font-medium text-muted-foreground">Revenue Impact</CardTitle>
              </CardHeader>
              <CardContent>
                <div className="text-2xl font-bold">
                  {formData.purchase_count && formData.base_price ? 
                    '$' + ((formData.purchase_count * formData.base_price) / 100).toLocaleString() : 
                    'N/A'}
                </div>
              </CardContent>
            </Card>
          </div>

          <div className="text-sm text-muted-foreground p-3 bg-yellow-50 rounded-md border">
            📊 Analytics data is read-only and automatically updated by the system based on customer interactions.
          </div>
        </TabsContent>
        
        <TabsContent value="seo" className="space-y-4">
          <div>
            <Label htmlFor="meta_title">Meta Title (max 70 chars)</Label>
            <Input
              id="meta_title"
              value={formData.meta_title || ''}
              onChange={(e) => setFormData({...formData, meta_title: e.target.value})}
              maxLength={70}
              placeholder="Page title for search engines"
            />
            <p className="text-sm text-muted-foreground mt-1">
              {(formData.meta_title || '').length}/70 characters
            </p>
          </div>

          <div>
            <Label htmlFor="meta_description">Meta Description (max 160 chars)</Label>
            <Textarea
              id="meta_description"
              value={formData.meta_description || ''}
              onChange={(e) => setFormData({...formData, meta_description: e.target.value})}
              maxLength={160}
              rows={3}
              placeholder="Description for search engine results"
            />
            <p className="text-sm text-muted-foreground mt-1">
              {(formData.meta_description || '').length}/160 characters
            </p>
          </div>

          <div className="grid grid-cols-2 gap-4">
            <div>
              <Label htmlFor="tags">Tags (comma-separated)</Label>
              <Input
                id="tags"
                value={formData.tags?.join(', ') || ''}
                onChange={(e) => setFormData({
                  ...formData, 
                  tags: e.target.value.split(',').map(tag => tag.trim()).filter(tag => tag)
                })}
                placeholder="blazer, velvet, formal, wedding"
              />
            </div>
            <div>
              <Label htmlFor="meta_keywords">Meta Keywords (comma-separated)</Label>
              <Input
                id="meta_keywords"
                value={formData.meta_keywords?.join(', ') || ''}
                onChange={(e) => setFormData({
                  ...formData, 
                  meta_keywords: e.target.value.split(',').map(tag => tag.trim()).filter(tag => tag)
                })}
                placeholder="men's blazer, formal wear, wedding attire"
              />
            </div>
          </div>

          <div className="grid grid-cols-2 gap-4">
            <div>
              <Label htmlFor="url_slug">URL Slug</Label>
              <Input
                id="url_slug"
                value={formData.url_slug || formData.handle || ''}
                onChange={(e) => setFormData({...formData, url_slug: e.target.value})}
                placeholder="product-url-slug"
              />
            </div>
            <div>
              <Label htmlFor="canonical_url">Canonical URL</Label>
              <Input
                id="canonical_url"
                value={formData.canonical_url || ''}
                onChange={(e) => setFormData({...formData, canonical_url: e.target.value})}
                placeholder="https://kctmenswear.com/products/..."
              />
            </div>
          </div>

          <div>
            <Label htmlFor="og_title">Open Graph Title</Label>
            <Input
              id="og_title"
              value={formData.og_title || ''}
              onChange={(e) => setFormData({...formData, og_title: e.target.value})}
              placeholder="Title for social media sharing"
            />
          </div>

          <div>
            <Label htmlFor="og_description">Open Graph Description</Label>
            <Textarea
              id="og_description"
              value={formData.og_description || ''}
              onChange={(e) => setFormData({...formData, og_description: e.target.value})}
              rows={2}
              placeholder="Description for social media sharing"
            />
          </div>

          <div>
            <Label htmlFor="og_image">Open Graph Image URL</Label>
            <Input
              id="og_image"
              value={formData.og_image || formData.images?.hero?.url || ''}
              onChange={(e) => setFormData({...formData, og_image: e.target.value})}
              placeholder="Image URL for social media sharing"
            />
          </div>

          <div className="grid grid-cols-2 gap-4">
            <div>
              <Label htmlFor="sitemap_priority">Sitemap Priority (0.0 - 1.0)</Label>
              <Input
                id="sitemap_priority"
                type="number"
                step="0.1"
                min="0"
                max="1"
                value={formData.sitemap_priority || 0.8}
                onChange={(e) => setFormData({...formData, sitemap_priority: parseFloat(e.target.value)})}
              />
            </div>
            <div>
              <Label htmlFor="sitemap_change_freq">Sitemap Change Frequency</Label>
              <Select 
                value={formData.sitemap_change_freq || 'weekly'} 
                onValueChange={(value) => setFormData({...formData, sitemap_change_freq: value})}
              >
                <SelectTrigger>
                  <SelectValue />
                </SelectTrigger>
                <SelectContent>
                  <SelectItem value="always">Always</SelectItem>
                  <SelectItem value="hourly">Hourly</SelectItem>
                  <SelectItem value="daily">Daily</SelectItem>
                  <SelectItem value="weekly">Weekly</SelectItem>
                  <SelectItem value="monthly">Monthly</SelectItem>
                  <SelectItem value="yearly">Yearly</SelectItem>
                  <SelectItem value="never">Never</SelectItem>
                </SelectContent>
              </Select>
            </div>
          </div>

          <div className="flex items-center space-x-2">
            <input
              type="checkbox"
              id="is_indexable"
              checked={formData.is_indexable !== false}
              onChange={(e) => setFormData({...formData, is_indexable: e.target.checked})}
              className="h-4 w-4"
            />
            <Label htmlFor="is_indexable">Allow search engines to index this product</Label>
          </div>
        </TabsContent>
      </Tabs>

      <div className="flex justify-end gap-4">
        <Button type="button" variant="outline" onClick={onCancel}>
          <X className="mr-2 h-4 w-4" />
          Cancel
        </Button>
        <Button type="submit">
          <Save className="mr-2 h-4 w-4" />
          {product?.id ? 'Update Product' : 'Create Product'}
        </Button>
      </div>
    </form>
  );
}