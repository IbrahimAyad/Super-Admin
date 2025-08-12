import React from 'react';
import { Card, CardContent } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { Table, TableBody, TableCell, TableHead, TableHeader, TableRow } from '@/components/ui/table';
import { Badge } from '@/components/ui/badge';
import { Checkbox } from '@/components/ui/checkbox';
import { Eye, EyeOff, Copy, Edit2 } from 'lucide-react';
import { Product, getProductImageUrl } from '@/lib/services';
import styles from '../ProductManagement.module.css';

interface ProductListProps {
  products: Product[];
  viewMode: 'table' | 'grid';
  selectedProducts: string[];
  onProductSelect: (productId: string) => void;
  onSelectAll: () => void;
  onProductEdit: (product: Product) => void;
  onProductToggle: (productId: string) => void;
  onProductDuplicate: (productId: string) => void;
  loading?: boolean;
}

export const ProductList = React.memo(function ProductList({
  products,
  viewMode,
  selectedProducts,
  onProductSelect,
  onSelectAll,
  onProductEdit,
  onProductToggle,
  onProductDuplicate,
  loading = false
}: ProductListProps) {
  if (loading) {
    return (
      <div className="space-y-4">
        <div className="animate-pulse">
          <div className="h-4 bg-gray-200 rounded w-1/4 mb-4"></div>
          <div className="space-y-2">
            {[...Array(5)].map((_, i) => (
              <div key={i} className="h-16 bg-gray-200 rounded"></div>
            ))}
          </div>
        </div>
      </div>
    );
  }

  if (products.length === 0) {
    return (
      <div className="text-center py-12">
        <p className="text-muted-foreground mb-4">No products found</p>
        <p className="text-sm text-muted-foreground">Try adjusting your filters or search terms</p>
      </div>
    );
  }

  const ProductTableView = () => (
    <div className="overflow-x-auto">
      <Table>
        <TableHeader>
          <TableRow>
            <TableHead className="w-12">
              <Checkbox
                checked={selectedProducts.length === products.length && products.length > 0}
                onCheckedChange={onSelectAll}
              />
            </TableHead>
            <TableHead className="w-20">Image</TableHead>
            <TableHead>Product</TableHead>
            <TableHead>Category</TableHead>
            <TableHead>Price</TableHead>
            <TableHead>Status</TableHead>
            <TableHead>Stock</TableHead>
            <TableHead className="w-32">Quick Actions</TableHead>
          </TableRow>
        </TableHeader>
        <TableBody>
          {products.map((product) => (
            <TableRow key={product.id}>
              <TableCell>
                <Checkbox
                  checked={selectedProducts.includes(product.id)}
                  onCheckedChange={() => onProductSelect(product.id)}
                />
              </TableCell>
              <TableCell>
                <div className="w-16 h-16 rounded-md overflow-hidden bg-gray-100">
                  <img
                    src={getProductImageUrl(product)}
                    alt={product.name}
                    className="w-full h-full object-cover"
                    loading="lazy"
                    onError={(e) => {
                      const target = e.target as HTMLImageElement;
                      target.src = '/placeholder.svg';
                    }}
                  />
                </div>
              </TableCell>
              <TableCell>
                <div className="space-y-1">
                  <p className="font-medium">{product.name}</p>
                  <p className="text-sm text-muted-foreground">{product.description?.slice(0, 60)}...</p>
                </div>
              </TableCell>
              <TableCell>{product.category}</TableCell>
              <TableCell>${product.base_price}</TableCell>
              <TableCell>
                <Badge variant={product.status === 'active' ? "default" : "secondary"}>
                  {product.status}
                </Badge>
              </TableCell>
              <TableCell>
                <Badge variant="outline">
                  {(product as any).total_inventory || 0}
                </Badge>
              </TableCell>
              <TableCell>
                <div className="flex items-center gap-1">
                  <Button
                    variant="ghost"
                    size="sm"
                    onClick={() => onProductToggle(product.id)}
                    title={product.status === 'active' ? 'Deactivate' : 'Activate'}
                  >
                    {product.status === 'active' ? <EyeOff className="h-4 w-4" /> : <Eye className="h-4 w-4" />}
                  </Button>
                  <Button
                    variant="ghost"
                    size="sm"
                    onClick={() => onProductDuplicate(product.id)}
                    title="Duplicate"
                  >
                    <Copy className="h-4 w-4" />
                  </Button>
                  <Button
                    variant="ghost"
                    size="sm"
                    onClick={() => onProductEdit(product)}
                    title="Edit"
                  >
                    <Edit2 className="h-4 w-4" />
                  </Button>
                </div>
              </TableCell>
            </TableRow>
          ))}
        </TableBody>
      </Table>
    </div>
  );

  const ProductGridView = () => (
    <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4 gap-4">
      {products.map((product) => (
        <Card key={product.id} className="group hover:shadow-md transition-shadow">
          <CardContent className="p-4">
            <div className="relative">
              <div className="aspect-square rounded-md overflow-hidden bg-gray-100 mb-3">
                <img
                  src={getProductImageUrl(product)}
                  alt={product.name}
                  className="w-full h-full object-cover group-hover:scale-105 transition-transform"
                  loading="lazy"
                  onError={(e) => {
                    const target = e.target as HTMLImageElement;
                    target.src = '/placeholder.svg';
                  }}
                />
              </div>
              <div className="absolute top-2 right-2 opacity-0 group-hover:opacity-100 transition-opacity">
                <Checkbox
                  checked={selectedProducts.includes(product.id)}
                  onCheckedChange={() => onProductSelect(product.id)}
                />
              </div>
            </div>
            <div className="space-y-2">
              <h3 className="font-medium text-sm line-clamp-2">{product.name}</h3>
              <div className="flex items-center justify-between">
                <p className="text-lg font-bold">${product.base_price}</p>
                <Badge variant={product.status === 'active' ? "default" : "secondary"} className="text-xs">
                  {product.status}
                </Badge>
              </div>
              <p className="text-xs text-muted-foreground">{product.category}</p>
              <div className="flex justify-between items-center pt-2">
                <div className="flex items-center gap-1">
                  <Button
                    variant="ghost"
                    size="sm"
                    onClick={() => onProductToggle(product.id)}
                  >
                    {product.status === 'active' ? <EyeOff className="h-4 w-4" /> : <Eye className="h-4 w-4" />}
                  </Button>
                  <Button
                    variant="ghost"
                    size="sm"
                    onClick={() => onProductDuplicate(product.id)}
                  >
                    <Copy className="h-4 w-4" />
                  </Button>
                  <Button
                    variant="ghost"
                    size="sm"
                    onClick={() => onProductEdit(product)}
                  >
                    <Edit2 className="h-4 w-4" />
                  </Button>
                </div>
                <Badge variant="outline" className="text-xs">
                  Stock: {(product as any).total_inventory || 0}
                </Badge>
              </div>
            </div>
          </CardContent>
        </Card>
      ))}
    </div>
  );

  const MobileCardsView = () => (
    <div className={styles.mobileCards}>
      {products.map((product) => (
        <div key={product.id} className={styles.mobileCard}>
          <div className={styles.mobileCardHeader}>
            <Checkbox
              checked={selectedProducts.includes(product.id)}
              onCheckedChange={() => onProductSelect(product.id)}
            />
            <div className={styles.mobileCardImage}>
              <img
                src={getProductImageUrl(product)}
                alt={product.name}
                onError={(e) => {
                  const target = e.target as HTMLImageElement;
                  target.src = '/placeholder.svg';
                }}
              />
            </div>
            <div className={styles.mobileCardInfo}>
              <h3 className={styles.mobileCardTitle}>{product.name}</h3>
              <p className={styles.mobileCardDescription}>
                {product.description?.slice(0, 50)}...
              </p>
              <div className={styles.mobileCardMeta}>
                <span className={`${styles.mobileCardBadge} text-xs px-2 py-1 rounded ${product.status === 'active' ? 'bg-green-100 text-green-800' : 'bg-gray-100 text-gray-800'}`}>
                  {product.status}
                </span>
                <span className={`${styles.mobileCardBadge} text-xs px-2 py-1 rounded bg-blue-100 text-blue-800`}>
                  {product.category}
                </span>
              </div>
            </div>
          </div>
          <div className={styles.mobileCardActions}>
            <div className={styles.mobilePrice}>${product.base_price}</div>
            <div className={styles.mobileActionButtons}>
              <button
                className={styles.mobileActionButton}
                onClick={() => onProductToggle(product.id)}
                title={product.status === 'active' ? 'Deactivate' : 'Activate'}
              >
                {product.status === 'active' ? <EyeOff size={16} /> : <Eye size={16} />}
              </button>
              <button
                className={styles.mobileActionButton}
                onClick={() => onProductDuplicate(product.id)}
                title="Duplicate"
              >
                <Copy size={16} />
              </button>
              <button
                className={styles.mobileActionButton}
                onClick={() => onProductEdit(product)}
                title="Edit"
              >
                <Edit2 size={16} />
              </button>
            </div>
          </div>
          <div className="text-xs text-gray-500 mt-2 flex justify-between">
            <span>Stock: {(product as any).total_inventory || 0}</span>
            <span>{product.category}</span>
          </div>
        </div>
      ))}
    </div>
  );

  return (
    <>
      {/* Desktop/Tablet Views */}
      <div className="hidden sm:block">
        {viewMode === 'table' ? <ProductTableView /> : <ProductGridView />}
      </div>
      
      {/* Mobile View - Always use cards */}
      <div className="sm:hidden">
        <MobileCardsView />
      </div>
    </>
  );
}, (prevProps, nextProps) => {
  // Custom comparison for React.memo optimization
  return (
    prevProps.products === nextProps.products &&
    prevProps.viewMode === nextProps.viewMode &&
    prevProps.selectedProducts === nextProps.selectedProducts &&
    prevProps.loading === nextProps.loading &&
    // Compare callback functions by reference (parent should memoize them)
    prevProps.onProductSelect === nextProps.onProductSelect &&
    prevProps.onSelectAll === nextProps.onSelectAll &&
    prevProps.onProductEdit === nextProps.onProductEdit &&
    prevProps.onProductToggle === nextProps.onProductToggle &&
    prevProps.onProductDuplicate === nextProps.onProductDuplicate
  );
});