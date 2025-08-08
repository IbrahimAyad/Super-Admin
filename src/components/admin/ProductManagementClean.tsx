/**
 * CLEAN PRODUCT MANAGEMENT
 * Simple list view with the new simple editor
 */

import React, { useState, useEffect } from 'react';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { Card } from '@/components/ui/card';
import { Badge } from '@/components/ui/badge';
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
  Hash
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
}

export function ProductManagementClean() {
  const [products, setProducts] = useState<Product[]>([]);
  const [loading, setLoading] = useState(true);
  const [searchTerm, setSearchTerm] = useState('');
  const [showEditor, setShowEditor] = useState(false);
  const [editingProductId, setEditingProductId] = useState<string | null>(null);

  useEffect(() => {
    loadProducts();
  }, []);

  const loadProducts = async () => {
    setLoading(true);
    try {
      // Load products with variant counts and images
      const { data: productsData, error } = await supabase
        .from('products')
        .select(`
          *,
          product_images (image_url),
          product_variants (id)
        `)
        .order('created_at', { ascending: false });

      if (error) throw error;

      // Process products to include counts and first image
      const processedProducts = productsData?.map(product => ({
        ...product,
        image_url: product.product_images?.[0]?.image_url,
        variant_count: product.product_variants?.length || 0,
        total_inventory: product.product_variants?.reduce((sum: number, v: any) => 
          sum + (v.inventory_quantity || 0), 0) || 0
      })) || [];

      setProducts(processedProducts);
    } catch (error) {
      console.error('Error loading products:', error);
      toast.error('Failed to load products');
    } finally {
      setLoading(false);
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

  const filteredProducts = products.filter(product =>
    product.name?.toLowerCase().includes(searchTerm.toLowerCase()) ||
    product.sku?.toLowerCase().includes(searchTerm.toLowerCase()) ||
    product.category?.toLowerCase().includes(searchTerm.toLowerCase())
  );

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
    <div className="p-6 max-w-7xl mx-auto">
      {/* Header */}
      <div className="mb-6">
        <h1 className="text-3xl font-bold mb-2">Products</h1>
        <p className="text-gray-600">Manage your product catalog</p>
      </div>

      {/* Actions Bar */}
      <div className="flex justify-between items-center mb-6">
        <div className="relative flex-1 max-w-md">
          <Search className="absolute left-3 top-1/2 transform -translate-y-1/2 h-4 w-4 text-gray-400" />
          <Input
            type="text"
            placeholder="Search products..."
            value={searchTerm}
            onChange={(e) => setSearchTerm(e.target.value)}
            className="pl-10"
          />
        </div>
        <Button onClick={handleNewProduct}>
          <Plus className="h-4 w-4 mr-2" />
          Add Product
        </Button>
      </div>

      {/* Image Migration Helper */}
      <div className="mb-6">
        <ImageMigrationHelper />
      </div>

      {/* Stats Cards */}
      <div className="grid grid-cols-1 md:grid-cols-4 gap-4 mb-6">
        <Card className="p-4">
          <div className="flex items-center justify-between">
            <div>
              <p className="text-sm text-gray-600">Total Products</p>
              <p className="text-2xl font-bold">{products.length}</p>
            </div>
            <Package className="h-8 w-8 text-gray-400" />
          </div>
        </Card>
        <Card className="p-4">
          <div className="flex items-center justify-between">
            <div>
              <p className="text-sm text-gray-600">Active</p>
              <p className="text-2xl font-bold">
                {products.filter(p => p.status === 'active').length}
              </p>
            </div>
            <div className="h-8 w-8 rounded-full bg-green-100 flex items-center justify-center">
              <div className="h-3 w-3 rounded-full bg-green-500" />
            </div>
          </div>
        </Card>
        <Card className="p-4">
          <div className="flex items-center justify-between">
            <div>
              <p className="text-sm text-gray-600">Total Variants</p>
              <p className="text-2xl font-bold">
                {products.reduce((sum, p) => sum + (p.variant_count || 0), 0)}
              </p>
            </div>
            <Hash className="h-8 w-8 text-gray-400" />
          </div>
        </Card>
        <Card className="p-4">
          <div className="flex items-center justify-between">
            <div>
              <p className="text-sm text-gray-600">Avg Price</p>
              <p className="text-2xl font-bold">
                ${(products.reduce((sum, p) => sum + (p.base_price / 100), 0) / products.length || 0).toFixed(2)}
              </p>
            </div>
            <DollarSign className="h-8 w-8 text-gray-400" />
          </div>
        </Card>
      </div>

      {/* Product List */}
      {loading ? (
        <div className="text-center py-12">
          <div className="inline-block animate-spin rounded-full h-8 w-8 border-b-2 border-gray-900"></div>
          <p className="mt-2 text-gray-600">Loading products...</p>
        </div>
      ) : filteredProducts.length === 0 ? (
        <Card className="p-12 text-center">
          <Package className="h-12 w-12 text-gray-400 mx-auto mb-4" />
          <h3 className="text-lg font-semibold mb-2">No products found</h3>
          <p className="text-gray-600 mb-4">
            {searchTerm ? 'Try adjusting your search' : 'Get started by adding your first product'}
          </p>
          {!searchTerm && (
            <Button onClick={handleNewProduct}>
              <Plus className="h-4 w-4 mr-2" />
              Add Product
            </Button>
          )}
        </Card>
      ) : (
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4 gap-4">
          {filteredProducts.map((product) => (
            <Card key={product.id} className="overflow-hidden hover:shadow-lg transition">
              {/* Product Image */}
              <div className="h-48 bg-gray-100 relative">
                {product.image_url ? (
                  <img
                    src={product.image_url}
                    alt={product.name}
                    className="w-full h-full object-cover"
                  />
                ) : (
                  <div className="w-full h-full flex items-center justify-center">
                    <Package className="h-12 w-12 text-gray-400" />
                  </div>
                )}
                <Badge 
                  className="absolute top-2 right-2"
                  variant={product.status === 'active' ? 'default' : 'secondary'}
                >
                  {product.status}
                </Badge>
              </div>

              {/* Product Info */}
              <div className="p-4">
                <h3 className="font-semibold text-lg mb-1 line-clamp-1">
                  {product.name}
                </h3>
                <p className="text-sm text-gray-600 mb-2">{product.sku}</p>
                
                <div className="flex items-center justify-between mb-3">
                  <span className="text-xl font-bold">${(product.base_price / 100).toFixed(2)}</span>
                  <Badge variant="outline">{product.category}</Badge>
                </div>

                <div className="flex items-center justify-between text-sm text-gray-600 mb-3">
                  <span>{product.variant_count || 0} variants</span>
                  <span>{product.total_inventory || 0} in stock</span>
                </div>

                {/* Actions */}
                <div className="flex gap-2">
                  <Button
                    size="sm"
                    variant="outline"
                    onClick={() => handleEdit(product.id)}
                    className="flex-1"
                  >
                    <Edit className="h-4 w-4 mr-1" />
                    Edit
                  </Button>
                  <Button
                    size="sm"
                    variant="ghost"
                    onClick={() => handleDelete(product.id)}
                  >
                    <Trash2 className="h-4 w-4" />
                  </Button>
                </div>
              </div>
            </Card>
          ))}
        </div>
      )}
    </div>
  );
}