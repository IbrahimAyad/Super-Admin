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

const CATEGORIES = ['Blazers', 'Suits', 'Shirts', 'Pants', 'Accessories'];
const SUBCATEGORIES = ['Prom', 'Velvet', 'Summer', 'Sparkle', 'Formal', 'Casual'];
const STATUSES = ['active', 'draft', 'archived'];

export default function EnhancedProductsAdmin() {
  const [products, setProducts] = useState<EnhancedProduct[]>([]);
  const [loading, setLoading] = useState(true);
  const [editingProduct, setEditingProduct] = useState<EnhancedProduct | null>(null);
  const [isEditDialogOpen, setIsEditDialogOpen] = useState(false);
  const [isCreateDialogOpen, setIsCreateDialogOpen] = useState(false);
  const [searchTerm, setSearchTerm] = useState('');
  const [selectedCategory, setSelectedCategory] = useState<string>('all');
  const [selectedSubcategory, setSelectedSubcategory] = useState<string>('all');

  useEffect(() => {
    fetchEnhancedProducts();
  }, []);

  async function fetchEnhancedProducts() {
    try {
      setLoading(true);
      const { data, error } = await supabase
        .from('products_enhanced')
        .select('*')
        .order('created_at', { ascending: false });

      if (error) throw error;
      setProducts(data || []);
    } catch (err: any) {
      toast({
        title: 'Error fetching products',
        description: err.message,
        variant: 'destructive'
      });
    } finally {
      setLoading(false);
    }
  }

  async function handleSaveProduct(product: Partial<EnhancedProduct>) {
    try {
      if (editingProduct?.id) {
        // Update existing product
        const { error } = await supabase
          .from('products_enhanced')
          .update({
            ...product,
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
            ...product,
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
        <Button onClick={() => {
          setEditingProduct(null);
          setIsCreateDialogOpen(true);
        }}>
          <Plus className="mr-2 h-4 w-4" />
          Add Product
        </Button>
      </div>

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
                              (e.target as HTMLImageElement).src = '/placeholder.svg';
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
                              setEditingProduct(product);
                              setIsEditDialogOpen(true);
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
  const [formData, setFormData] = useState<Partial<EnhancedProduct>>({
    name: product?.name || '',
    sku: product?.sku || '',
    category: product?.category || 'Blazers',
    subcategory: product?.subcategory || '',
    price_tier: product?.price_tier || 'TIER_7',
    base_price: product?.base_price || 27999,
    compare_at_price: product?.compare_at_price || 0,
    description: product?.description || '',
    status: product?.status || 'active',
    style_code: product?.style_code || '',
    season: product?.season || 'SS24',
    collection: product?.collection || '',
    color_family: product?.color_family || '',
    color_name: product?.color_name || '',
    fit_type: product?.fit_type || 'Slim Fit',
    materials: product?.materials || {},
    images: product?.images || {
      hero: null,
      flat: null,
      lifestyle: [],
      details: [],
      total_images: 0
    }
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
        <TabsList className="grid w-full grid-cols-5">
          <TabsTrigger value="basic">Basic Info</TabsTrigger>
          <TabsTrigger value="pricing">Pricing</TabsTrigger>
          <TabsTrigger value="images">Images</TabsTrigger>
          <TabsTrigger value="details">Details</TabsTrigger>
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