import { useState, useEffect } from 'react';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { Badge } from '@/components/ui/badge';
import { Input } from '@/components/ui/input';
import { Dialog, DialogContent, DialogHeader, DialogTitle } from '@/components/ui/dialog';
import { Table, TableBody, TableCell, TableHead, TableHeader, TableRow } from '@/components/ui/table';
import { 
  Package, 
  Plus,
  Minus,
  AlertTriangle,
  CheckCircle,
  Edit,
  Save,
  X
} from 'lucide-react';
import { useToast } from '@/hooks/use-toast';
import { supabase } from '@/lib/supabase-client';

interface ProductVariant {
  id: string;
  product_id: string;
  title?: string;
  option1?: string; // Size
  option2?: string; // Color
  option3?: string;
  sku: string;
  inventory_quantity: number;
  price: number;
  available?: boolean;
  available_quantity?: number;
  reserved_quantity?: number;
  product?: {
    name: string;
    category: string;
    base_price: number;
    images?: any;
  };
}

export function ProductInventoryView() {
  const { toast } = useToast();
  const [variants, setVariants] = useState<ProductVariant[]>([]);
  const [loading, setLoading] = useState(true);
  const [selectedVariant, setSelectedVariant] = useState<ProductVariant | null>(null);
  const [showAdjustDialog, setShowAdjustDialog] = useState(false);
  const [adjustmentQuantity, setAdjustmentQuantity] = useState(0);
  const [searchTerm, setSearchTerm] = useState('');

  useEffect(() => {
    loadVariants();
  }, []);

  const loadVariants = async () => {
    try {
      setLoading(true);
      
      // First, get products with variants
      const { data: variantsData, error: variantsError } = await supabase
        .from('product_variants')
        .select(`
          *,
          product:products_enhanced(
            name, 
            category, 
            base_price,
            images
          )
        `)
        .order('created_at', { ascending: false });

      if (variantsError) {
        console.error('Variants error:', variantsError);
        
        // If variants table doesn't work, try to get products directly
        const { data: productsData, error: productsError } = await supabase
          .from('products_enhanced')
          .select('*')
          .limit(50);

        if (productsError) {
          throw productsError;
        }

        // Create mock variants from products for display
        const mockVariants = productsData?.map(product => ({
          id: product.id,
          product_id: product.id,
          title: product.name,
          option1: 'One Size',
          option2: product.color_name || 'Default',
          sku: product.sku,
          inventory_quantity: 0, // No inventory data available
          price: product.base_price,
          available: true,
          product: {
            name: product.name,
            category: product.category,
            base_price: product.base_price,
            images: product.images
          }
        })) || [];

        setVariants(mockVariants);
        
        toast({
          title: "Note",
          description: "Showing products without variant data. Add variants to manage sizes and inventory.",
        });
      } else {
        setVariants(variantsData || []);
        
        if (!variantsData || variantsData.length === 0) {
          // If no variants exist, show products
          const { data: productsData } = await supabase
            .from('products_enhanced')
            .select('*')
            .limit(50);

          const mockVariants = productsData?.map(product => ({
            id: product.id,
            product_id: product.id,
            title: product.name,
            option1: 'One Size',
            option2: product.color_name || 'Default',
            sku: product.sku,
            inventory_quantity: 0,
            price: product.base_price,
            available: true,
            product: {
              name: product.name,
              category: product.category,
              base_price: product.base_price,
              images: product.images
            }
          })) || [];

          setVariants(mockVariants);
        }
      }
    } catch (error) {
      console.error('Error loading inventory:', error);
      toast({
        title: "Error",
        description: "Failed to load inventory data",
        variant: "destructive"
      });
    } finally {
      setLoading(false);
    }
  };

  const handleAdjustInventory = async () => {
    if (!selectedVariant || adjustmentQuantity === 0) return;

    try {
      const newQuantity = selectedVariant.inventory_quantity + adjustmentQuantity;
      
      const { error } = await supabase
        .from('product_variants')
        .update({ inventory_quantity: newQuantity })
        .eq('id', selectedVariant.id);

      if (error) throw error;

      setVariants(prev => prev.map(v => 
        v.id === selectedVariant.id 
          ? { ...v, inventory_quantity: newQuantity }
          : v
      ));

      toast({
        title: "Success",
        description: `Inventory adjusted by ${adjustmentQuantity > 0 ? '+' : ''}${adjustmentQuantity}`,
      });

      setShowAdjustDialog(false);
      setSelectedVariant(null);
      setAdjustmentQuantity(0);
    } catch (error) {
      console.error('Error adjusting inventory:', error);
      toast({
        title: "Error",
        description: "Failed to adjust inventory",
        variant: "destructive"
      });
    }
  };

  const getStockStatus = (quantity: number) => {
    if (quantity === 0) return { label: 'Out of Stock', color: 'destructive' };
    if (quantity < 10) return { label: 'Low Stock', color: 'warning' };
    return { label: 'In Stock', color: 'success' };
  };

  const filteredVariants = variants.filter(variant => {
    const searchLower = searchTerm.toLowerCase();
    return (
      variant.product?.name?.toLowerCase().includes(searchLower) ||
      variant.sku?.toLowerCase().includes(searchLower) ||
      variant.option1?.toLowerCase().includes(searchLower) ||
      variant.title?.toLowerCase().includes(searchLower)
    );
  });

  const totalInventory = variants.reduce((sum, v) => sum + v.inventory_quantity, 0);
  const outOfStock = variants.filter(v => v.inventory_quantity === 0).length;
  const lowStock = variants.filter(v => v.inventory_quantity > 0 && v.inventory_quantity < 10).length;

  if (loading) {
    return (
      <div className="flex items-center justify-center h-96">
        <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-primary"></div>
      </div>
    );
  }

  return (
    <div className="space-y-6">
      <div className="flex justify-between items-center">
        <div>
          <h2 className="text-3xl font-bold">Inventory Management</h2>
          <p className="text-muted-foreground">Manage product variants and stock levels</p>
        </div>
      </div>

      {/* Stats Cards */}
      <div className="grid grid-cols-1 md:grid-cols-4 gap-4">
        <Card>
          <CardContent className="p-6">
            <div className="flex items-center gap-3">
              <Package className="h-8 w-8 text-blue-500" />
              <div>
                <p className="text-sm text-muted-foreground">Total Items</p>
                <p className="text-2xl font-bold">{totalInventory}</p>
              </div>
            </div>
          </CardContent>
        </Card>

        <Card>
          <CardContent className="p-6">
            <div className="flex items-center gap-3">
              <CheckCircle className="h-8 w-8 text-green-500" />
              <div>
                <p className="text-sm text-muted-foreground">Products</p>
                <p className="text-2xl font-bold">{variants.length}</p>
              </div>
            </div>
          </CardContent>
        </Card>

        <Card>
          <CardContent className="p-6">
            <div className="flex items-center gap-3">
              <AlertTriangle className="h-8 w-8 text-yellow-500" />
              <div>
                <p className="text-sm text-muted-foreground">Low Stock</p>
                <p className="text-2xl font-bold">{lowStock}</p>
              </div>
            </div>
          </CardContent>
        </Card>

        <Card>
          <CardContent className="p-6">
            <div className="flex items-center gap-3">
              <X className="h-8 w-8 text-red-500" />
              <div>
                <p className="text-sm text-muted-foreground">Out of Stock</p>
                <p className="text-2xl font-bold">{outOfStock}</p>
              </div>
            </div>
          </CardContent>
        </Card>
      </div>

      {/* Search */}
      <Card>
        <CardContent className="p-4">
          <Input
            placeholder="Search products, SKUs, or sizes..."
            value={searchTerm}
            onChange={(e) => setSearchTerm(e.target.value)}
            className="max-w-md"
          />
        </CardContent>
      </Card>

      {/* Inventory Table */}
      <Card>
        <CardHeader>
          <CardTitle>Product Inventory</CardTitle>
        </CardHeader>
        <CardContent className="p-0">
          <div className="overflow-x-auto">
            <Table>
              <TableHeader>
                <TableRow>
                  <TableHead>Product</TableHead>
                  <TableHead>SKU</TableHead>
                  <TableHead>Size</TableHead>
                  <TableHead>Color</TableHead>
                  <TableHead>Stock</TableHead>
                  <TableHead>Status</TableHead>
                  <TableHead>Actions</TableHead>
                </TableRow>
              </TableHeader>
              <TableBody>
                {filteredVariants.length === 0 ? (
                  <TableRow>
                    <TableCell colSpan={7} className="text-center py-8">
                      <Package className="h-12 w-12 mx-auto text-muted-foreground mb-4" />
                      <p className="text-muted-foreground">No inventory items found</p>
                      <p className="text-sm text-muted-foreground mt-2">
                        Add product variants to manage inventory
                      </p>
                    </TableCell>
                  </TableRow>
                ) : (
                  filteredVariants.map((variant) => {
                    const stockStatus = getStockStatus(variant.inventory_quantity);
                    return (
                      <TableRow key={variant.id}>
                        <TableCell>
                          <div className="flex items-center gap-3">
                            {variant.product?.images?.hero?.url ? (
                              <img 
                                src={variant.product.images.hero.url} 
                                alt={variant.product?.name}
                                className="w-10 h-10 object-cover rounded"
                                onError={(e) => {
                                  (e.target as HTMLImageElement).style.display = 'none';
                                }}
                              />
                            ) : (
                              <div className="w-10 h-10 bg-muted rounded flex items-center justify-center">
                                <Package className="h-5 w-5 text-muted-foreground" />
                              </div>
                            )}
                            <div>
                              <p className="font-medium">{variant.product?.name || 'Unknown Product'}</p>
                              <p className="text-xs text-muted-foreground">
                                {variant.product?.category}
                              </p>
                            </div>
                          </div>
                        </TableCell>
                        <TableCell className="font-mono text-sm">{variant.sku}</TableCell>
                        <TableCell>{variant.option1 || 'One Size'}</TableCell>
                        <TableCell>{variant.option2 || 'Default'}</TableCell>
                        <TableCell>
                          <div className="flex items-center gap-2">
                            <span className="font-medium">{variant.inventory_quantity}</span>
                            <Badge variant={stockStatus.color as any}>
                              {stockStatus.label}
                            </Badge>
                          </div>
                        </TableCell>
                        <TableCell>
                          <Badge variant={variant.available ? 'default' : 'secondary'}>
                            {variant.available ? 'Active' : 'Inactive'}
                          </Badge>
                        </TableCell>
                        <TableCell>
                          <Button
                            size="sm"
                            variant="outline"
                            onClick={() => {
                              setSelectedVariant(variant);
                              setShowAdjustDialog(true);
                            }}
                          >
                            <Edit className="h-4 w-4 mr-1" />
                            Adjust
                          </Button>
                        </TableCell>
                      </TableRow>
                    );
                  })
                )}
              </TableBody>
            </Table>
          </div>
        </CardContent>
      </Card>

      {/* Adjustment Dialog */}
      <Dialog open={showAdjustDialog} onOpenChange={setShowAdjustDialog}>
        <DialogContent>
          <DialogHeader>
            <DialogTitle>Adjust Inventory</DialogTitle>
          </DialogHeader>
          {selectedVariant && (
            <div className="space-y-4">
              <div>
                <p className="font-medium">{selectedVariant.product?.name || selectedVariant.title}</p>
                <p className="text-sm text-muted-foreground">
                  SKU: {selectedVariant.sku} | Size: {selectedVariant.option1 || 'One Size'}
                </p>
              </div>
              
              <div>
                <p className="text-sm text-muted-foreground mb-2">Current Stock</p>
                <p className="text-2xl font-bold">{selectedVariant.inventory_quantity}</p>
              </div>

              <div>
                <p className="text-sm text-muted-foreground mb-2">Adjustment</p>
                <div className="flex items-center gap-2">
                  <Button
                    size="icon"
                    variant="outline"
                    onClick={() => setAdjustmentQuantity(prev => prev - 1)}
                  >
                    <Minus className="h-4 w-4" />
                  </Button>
                  <Input
                    type="number"
                    value={adjustmentQuantity}
                    onChange={(e) => setAdjustmentQuantity(parseInt(e.target.value) || 0)}
                    className="w-24 text-center"
                  />
                  <Button
                    size="icon"
                    variant="outline"
                    onClick={() => setAdjustmentQuantity(prev => prev + 1)}
                  >
                    <Plus className="h-4 w-4" />
                  </Button>
                </div>
              </div>

              <div>
                <p className="text-sm text-muted-foreground">New Stock Level</p>
                <p className="text-xl font-bold">
                  {selectedVariant.inventory_quantity + adjustmentQuantity}
                </p>
              </div>

              <div className="flex justify-end gap-2">
                <Button variant="outline" onClick={() => {
                  setShowAdjustDialog(false);
                  setSelectedVariant(null);
                  setAdjustmentQuantity(0);
                }}>
                  Cancel
                </Button>
                <Button onClick={handleAdjustInventory} disabled={adjustmentQuantity === 0}>
                  <Save className="h-4 w-4 mr-2" />
                  Save Changes
                </Button>
              </div>
            </div>
          )}
        </DialogContent>
      </Dialog>
    </div>
  );
}