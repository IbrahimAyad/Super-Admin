import { useState, useEffect, useMemo } from 'react';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { Dialog, DialogContent, DialogHeader, DialogTitle, DialogTrigger } from '@/components/ui/dialog';
import { Table, TableBody, TableCell, TableHead, TableHeader, TableRow } from '@/components/ui/table';
import { Badge } from '@/components/ui/badge';
import { Skeleton } from '@/components/ui/skeleton';
import { useToast } from '@/hooks/use-toast';
import { 
  Plus, 
  Trash2, 
  Package,
  ChevronLeft,
  ChevronRight
} from 'lucide-react';
import { DropdownMenu, DropdownMenuContent, DropdownMenuItem, DropdownMenuTrigger } from '@/components/ui/dropdown-menu';
import { ProductFilters } from './ProductManagement/ProductFilters';
import { ProductList } from './ProductManagement/ProductList';
import { ProductForm } from './ProductManagement/ProductForm';
import { 
  fetchProductsWithImages, 
  getProductImageUrl, 
  createProductWithImages, 
  updateProductWithImages, 
  toggleProductStatus,
  duplicateProduct,
  getRecentlyUpdatedProducts,
  Product 
} from '@/lib/services';
import { supabase } from '@/lib/supabase-client';
import { testStorageBucket } from '@/lib/storage';
import { logger } from '@/utils/logger';
import styles from './ProductManagement.module.css';


const categories = [
  'Suits & Blazers',
  'Shirts & Tops',
  'Trousers & Pants',
  'Accessories',
  'Footwear',
  'Formal Wear',
  'Casual Wear'
];


export const ProductManagement = () => {
  const { toast } = useToast();
  const [products, setProducts] = useState<Product[]>([]);
  const [loading, setLoading] = useState(true);
  const [searchTerm, setSearchTerm] = useState('');
  const [categoryFilter, setCategoryFilter] = useState('all');
  const [selectedProducts, setSelectedProducts] = useState<string[]>([]);
  const [showAddDialog, setShowAddDialog] = useState(false);
  const [editingProduct, setEditingProduct] = useState<Product | null>(null);
  
  // Pagination state
  const [currentPage, setCurrentPage] = useState(1);
  const [totalCount, setTotalCount] = useState(0);
  const [pageSize] = useState(25);
  
  // View state
  const [viewMode, setViewMode] = useState<'table' | 'grid'>(() => 
    localStorage.getItem('productViewMode') as 'table' | 'grid' || 'table'
  );
  
  // Smart filters
  const [smartFilters, setSmartFilters] = useState({
    lowStock: false,
    noImages: false,
    inactive: false,
    recentlyUpdated: false
  });
  
  // Recent products
  const [recentProducts, setRecentProducts] = useState<any[]>([]);
  const [loadingRecent, setLoadingRecent] = useState(false);


  useEffect(() => {
    loadProducts();
    loadRecentProducts();
    
    // Test storage bucket on component mount
    testStorageBucket().then(result => {
      if (!result.success) {
        logger.error('Storage bucket test failed:', result.error);
        toast({
          title: "Storage Configuration Issue",
          description: `Storage test failed: ${result.error}`,
          variant: "destructive"
        });
      } else {
        logger.debug('Storage bucket test passed:', result.message);
      }
    }).catch(error => {
      logger.error('Storage test error:', error);
    });
  }, []);

  useEffect(() => {
    loadProducts();
  }, [currentPage, searchTerm, categoryFilter, smartFilters]);

  useEffect(() => {
    localStorage.setItem('productViewMode', viewMode);
  }, [viewMode]);

  const loadProducts = async () => {
    try {
      setLoading(true);
      
      const offset = (currentPage - 1) * pageSize;
      
      // Build filter options
      const hasActiveSmartFilters = Object.values(smartFilters).some(Boolean);
      const filterOptions = hasActiveSmartFilters ? { filters: smartFilters } : undefined;
      
      // Use shared service for fetching products with pagination
      const result = await fetchProductsWithImages({
        limit: pageSize,
        offset,
        category: categoryFilter === 'all' ? undefined : categoryFilter,
        search: searchTerm || undefined,
        ...filterOptions
      });

      if (!result.success) {
        logger.error('Products fetch error:', result.error);
        setProducts([]);
        setTotalCount(0);
        toast({
          title: "Database Error",
          description: `Error: ${result.error}`,
          variant: "destructive"
        });
        return;
      }
      
      
      setProducts(result.data || []);
      setTotalCount(result.totalCount || 0);
      
      if (result.totalCount === 0) {
        toast({
          title: "No Products Found",
          description: searchTerm || hasActiveSmartFilters ? "No products match your filters" : "Products table is empty. Add some products to get started!",
        });
      }
      
    } catch (error) {
      logger.error('Error loading products:', error);
      setProducts([]);
      setTotalCount(0);
      toast({
        title: "Error",
        description: "Failed to load products",
        variant: "destructive"
      });
    } finally {
      setLoading(false);
    }
  };

  const loadRecentProducts = async () => {
    try {
      setLoadingRecent(true);
      const result = await getRecentlyUpdatedProducts(5);
      if (result.success) {
        setRecentProducts(result.data);
      }
    } catch (error) {
      logger.error('Error loading recent products:', error);
    } finally {
      setLoadingRecent(false);
    }
  };

  // Quick action handlers
  const handleQuickToggle = async (productId: string) => {
    try {
      const result = await toggleProductStatus(productId);
      if (result.success) {
        toast({
          title: "Success",
          description: `Product status updated to ${result.data.status}`,
        });
        await loadProducts(); // Reload to show changes
      } else {
        throw new Error(result.error || 'Failed to toggle status');
      }
    } catch (error) {
      logger.error('Quick toggle error:', error);
      toast({
        title: "Error",
        description: error instanceof Error ? error.message : 'Failed to toggle product status',
        variant: "destructive"
      });
    }
  };

  const handleQuickDuplicate = async (productId: string) => {
    try {
      const result = await duplicateProduct(productId);
      if (result.success) {
        toast({
          title: "Success",
          description: `Product duplicated: ${result.data.name}`,
        });
        await loadProducts(); // Reload to show the new product
        setCurrentPage(1); // Go to first page to see the new product
      } else {
        throw new Error(result.error || 'Failed to duplicate product');
      }
    } catch (error) {
      logger.error('Quick duplicate error:', error);
      toast({
        title: "Error",
        description: error instanceof Error ? error.message : 'Failed to duplicate product',
        variant: "destructive"
      });
    }
  };

  // Pagination handlers
  const totalPages = Math.ceil(totalCount / pageSize);
  
  const handlePrevPage = () => {
    if (currentPage > 1) {
      setCurrentPage(currentPage - 1);
    }
  };

  const handleNextPage = () => {
    if (currentPage < totalPages) {
      setCurrentPage(currentPage + 1);
    }
  };

  const handlePageChange = (page: number) => {
    setCurrentPage(page);
  };

  // Smart filter handlers
  const handleSmartFilterToggle = (filterKey: keyof typeof smartFilters) => {
    setSmartFilters(prev => ({
      ...prev,
      [filterKey]: !prev[filterKey]
    }));
    setCurrentPage(1); // Reset to first page when filtering
  };

  // Calculate smart filter counts (for display)
  const smartFilterCounts = useMemo(() => {
    return {
      lowStock: products.filter(p => (p as any).total_inventory < 5).length,
      noImages: products.filter(p => !p.images || p.images.length === 0).length,
      inactive: products.filter(p => p.status !== 'active').length,
      recentlyUpdated: products.filter(p => {
        const sevenDaysAgo = new Date();
        sevenDaysAgo.setDate(sevenDaysAgo.getDate() - 7);
        return new Date(p.updated_at) > sevenDaysAgo;
      }).length
    };
  }, [products]);

  const handleSelectProduct = (productId: string) => {
    setSelectedProducts(prev =>
      prev.includes(productId)
        ? prev.filter(id => id !== productId)
        : [...prev, productId]
    );
  };

  const handleSelectAll = () => {
    if (selectedProducts.length === products.length) {
      setSelectedProducts([]);
    } else {
      setSelectedProducts(products.map(p => p.id));
    }
  };

  const handleBulkAction = async (action: 'activate' | 'deactivate' | 'delete' | 'feature' | 'unfeature') => {
    if (selectedProducts.length === 0) {
      toast({
        title: "No products selected",
        description: "Please select products to perform bulk actions",
        variant: "destructive"
      });
      return;
    }

    try {
      // Implement bulk actions
      // Use shared supabase instance
      
      switch (action) {
        case 'activate':
          await supabase
            .from('products')
            .update({ status: 'active' })
            .in('id', selectedProducts);
          break;
        case 'deactivate':
          await supabase
            .from('products')
            .update({ status: 'inactive' })
            .in('id', selectedProducts);
          break;
        case 'feature':
          await supabase
            .from('products')
            .update({ is_bundleable: true })
            .in('id', selectedProducts);
          break;
        case 'unfeature':
          await supabase
            .from('products')
            .update({ is_bundleable: false })
            .in('id', selectedProducts);
          break;
        case 'delete':
          if (confirm(`Are you sure you want to delete ${selectedProducts.length} products?`)) {
            await supabase
              .from('products')
              .delete()
              .in('id', selectedProducts);
          } else {
            return;
          }
          break;
      }

      toast({
        title: "Success",
        description: `Bulk action "${action}" completed for ${selectedProducts.length} product(s)`
      });

      await loadProducts(); // Reload to show changes
      setSelectedProducts([]);
    } catch (error) {
      logger.error('Bulk action error:', error);
      const errorMessage = error instanceof Error ? error.message : 'Unknown error occurred';
      toast({
        title: "Error",
        description: `Failed to perform bulk action: ${errorMessage}`,
        variant: "destructive"
      });
    }
  };

  const handleAddProductSubmit = async (productData: Partial<Product>) => {
    try {

      const result = await createProductWithImages(productData);

      if (!result.success || !result.data) {
        logger.error('Create failed:', result.error);
        throw new Error(result.error || 'Failed to create product');
      }


      // Add variants if any
      if (productData.variants && productData.variants.length > 0) {
        const variantsToInsert = productData.variants.map(variant => ({
          product_id: result.data.id,
          size: variant.size,
          color: variant.color,
          sku: variant.sku,
          price: variant.price,
          cost_price: variant.cost_price || null,
          compare_at_price: variant.compare_at_price || null,
          inventory_quantity: variant.stock_quantity,
          inventory_policy: variant.inventory_policy || 'deny',
          status: variant.status || 'active',
          position: variant.position || 0,
          barcode: variant.barcode || null,
          weight: variant.weight || null,
          image_url: variant.image_url || null
        }));

        const { error: variantsError } = await supabase
          .from('product_variants')
          .insert(variantsToInsert);

        if (variantsError) {
          logger.warn('Failed to add variants:', variantsError);
          toast({
            title: "Partial Success",
            description: "Product created but some variants failed to save",
            variant: "default"
          });
        } else {
        }
      }

      toast({
        title: "Success",
        description: `Product "${productData.name}" added successfully`
      });

      setShowAddDialog(false);
      setEditingProduct(null);
      await loadProducts(); // Reload products to show the new one
    } catch (error) {
      logger.error('Error adding product:', error);
      const errorMessage = error instanceof Error ? error.message : 'Unknown error occurred';
      toast({
        title: "Error",
        description: `Failed to add product: ${errorMessage}`,
        variant: "destructive"
      });
    }
  };

  const handleEditProductSubmit = async (productData: Partial<Product>) => {
    if (!editingProduct) return;

    try {

      const result = await updateProductWithImages(editingProduct.id, productData);

      if (!result.success) {
        logger.error('Update failed:', result.error);
        throw new Error(result.error || 'Failed to update product');
      }


      toast({
        title: "Success",
        description: `Product "${productData.name}" updated successfully`
      });

      setEditingProduct(null);
      setShowAddDialog(false);
      await loadProducts(); // Reload products to show changes
    } catch (error) {
      logger.error('Error updating product:', error);
      const errorMessage = error instanceof Error ? error.message : 'Unknown error occurred';
      toast({
        title: "Error",
        description: `Failed to update product: ${errorMessage}`,
        variant: "destructive"
      });
    }
  };

  const handleDeleteProduct = async (productId: string) => {
    if (!confirm('Are you sure you want to delete this product?')) return;

    try {
      // Use shared supabase instance
      
      const { error } = await supabase
        .from('products')
        .delete()
        .eq('id', productId);

      if (error) throw error;

      toast({
        title: "Success",
        description: "Product deleted successfully"
      });

      loadProducts();
    } catch (error) {
      logger.error('Error deleting product:', error);
      toast({
        title: "Error",
        description: "Failed to delete product",
        variant: "destructive"
      });
    }
  };

  const openEditDialog = (product: Product) => {
    setEditingProduct(product);
    setShowAddDialog(true);
  };


  // Loading skeleton component for product rows
  const ProductRowSkeleton = () => (
    <TableRow>
      <TableCell>
        <Skeleton className="h-4 w-4" />
      </TableCell>
      <TableCell>
        <Skeleton className="h-16 w-16 rounded-md" />
      </TableCell>
      <TableCell>
        <div className="space-y-2">
          <Skeleton className="h-4 w-32" />
          <Skeleton className="h-3 w-48" />
        </div>
      </TableCell>
      <TableCell>
        <Skeleton className="h-4 w-20" />
      </TableCell>
      <TableCell>
        <Skeleton className="h-5 w-16 rounded" />
      </TableCell>
      <TableCell>
        <Skeleton className="h-4 w-12" />
      </TableCell>
      <TableCell>
        <div className="flex gap-1">
          <Skeleton className="h-5 w-14 rounded" />
        </div>
      </TableCell>
      <TableCell>
        <Skeleton className="h-5 w-12 rounded" />
      </TableCell>
      <TableCell>
        <Skeleton className="h-8 w-8 rounded" />
      </TableCell>
    </TableRow>
  );

  if (loading) {
    return (
      <div className="space-y-6">
        {/* Header Skeleton */}
        <div className="flex items-center justify-between">
          <div className="space-y-2">
            <Skeleton className="h-8 w-64" />
            <Skeleton className="h-4 w-48" />
          </div>
          <Skeleton className="h-10 w-32" />
        </div>

        {/* Filters Skeleton */}
        <Card>
          <CardContent className="p-6">
            <div className="flex items-center gap-4 mb-6">
              <Skeleton className="h-10 flex-1 max-w-sm" />
              <Skeleton className="h-10 w-48" />
            </div>

            {/* Table Skeleton */}
            <Table>
              <TableHeader>
                <TableRow>
                  <TableHead className="w-12"><Skeleton className="h-4 w-4" /></TableHead>
                  <TableHead className="w-20"><Skeleton className="h-4 w-12" /></TableHead>
                  <TableHead><Skeleton className="h-4 w-16" /></TableHead>
                  <TableHead><Skeleton className="h-4 w-16" /></TableHead>
                  <TableHead><Skeleton className="h-4 w-12" /></TableHead>
                  <TableHead><Skeleton className="h-4 w-12" /></TableHead>
                  <TableHead><Skeleton className="h-4 w-12" /></TableHead>
                  <TableHead><Skeleton className="h-4 w-12" /></TableHead>
                  <TableHead className="w-24"><Skeleton className="h-4 w-16" /></TableHead>
                </TableRow>
              </TableHeader>
              <TableBody>
                {Array.from({ length: 5 }, (_, i) => (
                  <ProductRowSkeleton key={i} />
                ))}
              </TableBody>
            </Table>
          </CardContent>
        </Card>

        {/* Stats Skeleton */}
        <div className="grid grid-cols-1 md:grid-cols-4 gap-4">
          {Array.from({ length: 4 }, (_, i) => (
            <Card key={i}>
              <CardHeader className="pb-2">
                <Skeleton className="h-4 w-24" />
              </CardHeader>
              <CardContent>
                <Skeleton className="h-8 w-12" />
              </CardContent>
            </Card>
          ))}
        </div>
      </div>
    );
  }

  // Component definitions
  const PaginationControls = () => (
    <div className="flex items-center justify-between px-2">
      <div className="text-sm text-muted-foreground">
        Showing {Math.min((currentPage - 1) * pageSize + 1, totalCount)}-{Math.min(currentPage * pageSize, totalCount)} of {totalCount} products
      </div>
      <div className="flex items-center gap-2">
        <Button
          variant="outline"
          size="sm"
          onClick={handlePrevPage}
          disabled={currentPage <= 1}
        >
          <ChevronLeft className="h-4 w-4" />
          Previous
        </Button>
        <div className="flex items-center gap-1">
          {Array.from({ length: Math.min(totalPages, 5) }, (_, i) => {
            const pageNum = Math.max(1, currentPage - 2) + i;
            if (pageNum > totalPages) return null;
            return (
              <Button
                key={pageNum}
                variant={pageNum === currentPage ? "default" : "outline"}
                size="sm"
                onClick={() => handlePageChange(pageNum)}
              >
                {pageNum}
              </Button>
            );
          })}
        </div>
        <Button
          variant="outline"
          size="sm"
          onClick={handleNextPage}
          disabled={currentPage >= totalPages}
        >
          Next
          <ChevronRight className="h-4 w-4" />
        </Button>
      </div>
    </div>
  );


  const RecentProductsSection = () => (
    <Card>
      <CardHeader>
        <CardTitle className="text-lg">Recently Updated Products</CardTitle>
      </CardHeader>
      <CardContent>
        {loadingRecent ? (
          <div className="space-y-3">
            {Array.from({ length: 3 }, (_, i) => (
              <div key={i} className="flex items-center gap-3">
                <Skeleton className="h-10 w-10 rounded" />
                <div className="space-y-1 flex-1">
                  <Skeleton className="h-4 w-24" />
                  <Skeleton className="h-3 w-16" />
                </div>
              </div>
            ))}
          </div>
        ) : (
          <div className="space-y-3">
            {recentProducts.map((product) => (
              <div key={product.id} className="flex items-center gap-3 p-2 rounded hover:bg-muted/50 cursor-pointer"
                   onClick={() => openEditDialog(product)}>
                <div className="w-10 h-10 rounded overflow-hidden bg-muted">
                  <img
                    src={product.images?.[0]?.image_url || '/placeholder.svg'}
                    alt={product.name}
                    className="w-full h-full object-cover"
                  />
                </div>
                <div className="flex-1">
                  <p className="font-medium text-sm">{product.name}</p>
                  <p className="text-xs text-muted-foreground">
                    {new Date(product.updated_at).toLocaleDateString()}
                  </p>
                </div>
                <Badge variant={product.status === 'active' ? 'default' : 'secondary'}>
                  {product.status}
                </Badge>
              </div>
            ))}
          </div>
        )}
      </CardContent>
    </Card>
  );

  return (
    <div className="space-y-6">
      {/* Header */}
      <div className="flex items-center justify-between">
        <div>
          <h2 className="text-3xl font-bold tracking-tight">Product Management</h2>
          <p className="text-muted-foreground">Manage your product catalog and inventory ({totalCount} products)</p>
        </div>
        <Dialog open={showAddDialog} onOpenChange={setShowAddDialog}>
          <DialogTrigger asChild>
            <Button onClick={() => { setEditingProduct(null); }}>
              <Plus className="h-4 w-4 mr-2" />
              Add Product
            </Button>
          </DialogTrigger>
          <DialogContent className="max-w-2xl max-h-[90vh] overflow-y-auto">
            <DialogHeader>
              <DialogTitle>{editingProduct ? 'Edit Product' : 'Add New Product'}</DialogTitle>
            </DialogHeader>
            <ProductForm 
              product={editingProduct}
              isOpen={showAddDialog}
              onClose={() => { setShowAddDialog(false); setEditingProduct(null); }}
              onSubmit={editingProduct ? handleEditProductSubmit : handleAddProductSubmit}
              categories={categories}
            />
          </DialogContent>
        </Dialog>
      </div>

      {/* Recent Products Section - Only show on desktop */}
      <div className="hidden lg:block">
        <RecentProductsSection />
      </div>

      {/* Main Products Section */}
      <Card>
        <CardContent className="p-6">
          <div className="space-y-4">
            {/* Filters */}
            <ProductFilters
              searchTerm={searchTerm}
              onSearchChange={setSearchTerm}
              categoryFilter={categoryFilter}
              onCategoryChange={setCategoryFilter}
              categories={categories}
              viewMode={viewMode}
              onViewModeChange={setViewMode}
              smartFilters={smartFilters}
              onSmartFilterToggle={handleSmartFilterToggle}
              smartFilterCounts={smartFilterCounts}
              styles={styles}
            />

            {/* Bulk Actions */}
            {selectedProducts.length > 0 && (
              <div className="flex items-center gap-2 p-3 bg-muted/50 rounded-lg">
                <span className="text-sm font-medium">{selectedProducts.length} selected</span>
                <div className="flex gap-2 ml-auto">
                  <Button size="sm" variant="outline" onClick={() => handleBulkAction('activate')}>
                    Activate
                  </Button>
                  <Button size="sm" variant="outline" onClick={() => handleBulkAction('deactivate')}>
                    Deactivate
                  </Button>
                  <Button size="sm" variant="destructive" onClick={() => handleBulkAction('delete')}>
                    <Trash2 className="h-4 w-4 mr-1" />
                    Delete
                  </Button>
                </div>
              </div>
            )}

            {/* Products Display */}
            {loading ? (
              <div className="space-y-4">
                {Array.from({ length: 5 }, (_, i) => (
                  <div key={i} className="flex items-center gap-4">
                    <Skeleton className="h-16 w-16 rounded" />
                    <div className="space-y-2 flex-1">
                      <Skeleton className="h-4 w-32" />
                      <Skeleton className="h-3 w-48" />
                    </div>
                  </div>
                ))}
              </div>
            ) : products.length === 0 ? (
              <div className="text-center py-12">
                <Package className="h-12 w-12 text-muted-foreground mx-auto mb-4" />
                <h3 className="text-lg font-medium">No products found</h3>
                <p className="text-muted-foreground">Try adjusting your search or filters</p>
              </div>
            ) : (
              <>
                <ProductList
                  products={products}
                  viewMode={viewMode}
                  selectedProducts={selectedProducts}
                  onProductSelect={handleSelectProduct}
                  onSelectAll={handleSelectAll}
                  onProductEdit={openEditDialog}
                  onProductToggle={handleQuickToggle}
                  onProductDuplicate={handleQuickDuplicate}
                  loading={loading}
                />
                
                <div className={`pt-4 ${styles.paginationMobile || ''}`}>
                  <PaginationControls />
                </div>
              </>
            )}
          </div>
        </CardContent>
      </Card>

      {/* Stats */}
      <div className="grid grid-cols-1 md:grid-cols-4 gap-4">
        <Card>
          <CardHeader className="pb-2">
            <CardTitle className="text-sm font-medium">Total Products</CardTitle>
          </CardHeader>
          <CardContent>
            <div className="text-2xl font-bold">{totalCount}</div>
          </CardContent>
        </Card>
        <Card>
          <CardHeader className="pb-2">
            <CardTitle className="text-sm font-medium">Active Products</CardTitle>
          </CardHeader>
          <CardContent>
            <div className="text-2xl font-bold">{products.filter(p => p.status === 'active').length}</div>
          </CardContent>
        </Card>
        <Card>
          <CardHeader className="pb-2">
            <CardTitle className="text-sm font-medium">Low Stock Items</CardTitle>
          </CardHeader>
          <CardContent>
            <div className="text-2xl font-bold text-destructive">
              {smartFilterCounts.lowStock}
            </div>
          </CardContent>
        </Card>
        <Card>
          <CardHeader className="pb-2">
            <CardTitle className="text-sm font-medium">No Images</CardTitle>
          </CardHeader>
          <CardContent>
            <div className="text-2xl font-bold text-orange-600">
              {smartFilterCounts.noImages}
            </div>
          </CardContent>
        </Card>
      </div>
    </div>
  );
};