import React, { useState, useEffect, useCallback } from 'react';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { Textarea } from '@/components/ui/textarea';
import { Alert, AlertDescription } from '@/components/ui/alert';
import { Badge } from '@/components/ui/badge';
import { Tabs, TabsContent, TabsList, TabsTrigger } from '@/components/ui/tabs';
import { ScrollArea } from '@/components/ui/scroll-area';
import { Checkbox } from '@/components/ui/checkbox';
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from '@/components/ui/select';
import { supabase } from '@/lib/supabase';
import { toast } from 'sonner';
import {
  Download,
  Upload,
  Save,
  AlertCircle,
  CheckCircle,
  Eye,
  Edit,
  Image,
  DollarSign,
  Type,
  Package,
  Undo,
  FileSpreadsheet,
  Search,
  Filter
} from 'lucide-react';

interface Product {
  id: string;
  name: string;
  description: string;
  price: number;
  compare_at_price?: number;
  category: string;
  brand?: string;
  image_url?: string;
  additional_images?: string[];
  in_stock: boolean;
  featured: boolean;
  tags?: string[];
  stripe_product_id?: string;
  product_variants?: any[];
}

interface ProductChange {
  id: string;
  field: string;
  oldValue: any;
  newValue: any;
  productName: string;
}

export function BulkProductEditor() {
  const [products, setProducts] = useState<Product[]>([]);
  const [selectedProducts, setSelectedProducts] = useState<Set<string>>(new Set());
  const [changes, setChanges] = useState<Map<string, Partial<Product>>>(new Map());
  const [loading, setLoading] = useState(false);
  const [searchTerm, setSearchTerm] = useState('');
  const [filterCategory, setFilterCategory] = useState('all');
  const [previewMode, setPreviewMode] = useState(false);
  const [backupCreated, setBackupCreated] = useState(false);
  const [categories, setCategories] = useState<string[]>([]);

  // Bulk edit states
  const [bulkPrice, setBulkPrice] = useState('');
  const [bulkPriceMode, setBulkPriceMode] = useState<'fixed' | 'percentage' | 'increase' | 'decrease'>('fixed');
  const [bulkCategory, setBulkCategory] = useState('');
  const [bulkImagePrefix, setBulkImagePrefix] = useState('');

  useEffect(() => {
    fetchProducts();
  }, []);

  const fetchProducts = async () => {
    setLoading(true);
    try {
      const { data, error } = await supabase
        .from('products')
        .select('*, product_variants(*)')
        .order('name');

      if (error) throw error;

      setProducts(data || []);
      
      // Extract unique categories
      const uniqueCategories = [...new Set(data?.map(p => p.category).filter(Boolean))];
      setCategories(uniqueCategories);
      
      toast.success(`Loaded ${data?.length || 0} products`);
    } catch (error) {
      console.error('Error fetching products:', error);
      toast.error('Failed to load products');
    }
    setLoading(false);
  };

  const createBackup = async () => {
    setLoading(true);
    try {
      // Create a backup in a new table
      const timestamp = new Date().toISOString();
      const backupData = products.map(p => ({
        ...p,
        backup_timestamp: timestamp
      }));

      const { error } = await supabase
        .from('products_backup')
        .insert(backupData);

      if (error) {
        // If backup table doesn't exist, export as JSON
        const blob = new Blob([JSON.stringify(products, null, 2)], { type: 'application/json' });
        const url = URL.createObjectURL(blob);
        const a = document.createElement('a');
        a.href = url;
        a.download = `products_backup_${Date.now()}.json`;
        a.click();
      }

      setBackupCreated(true);
      toast.success('Backup created successfully');
    } catch (error) {
      console.error('Error creating backup:', error);
      toast.error('Failed to create backup');
    }
    setLoading(false);
  };

  const handleSelectAll = () => {
    if (selectedProducts.size === filteredProducts.length) {
      setSelectedProducts(new Set());
    } else {
      setSelectedProducts(new Set(filteredProducts.map(p => p.id)));
    }
  };

  const handleSelectProduct = (productId: string) => {
    const newSelected = new Set(selectedProducts);
    if (newSelected.has(productId)) {
      newSelected.delete(productId);
    } else {
      newSelected.add(productId);
    }
    setSelectedProducts(newSelected);
  };

  const handleFieldChange = (productId: string, field: string, value: any) => {
    const productChanges = changes.get(productId) || {};
    productChanges[field] = value;
    
    const newChanges = new Map(changes);
    newChanges.set(productId, productChanges);
    setChanges(newChanges);
  };

  const applyBulkPrice = () => {
    if (!bulkPrice || selectedProducts.size === 0) return;

    const priceValue = parseFloat(bulkPrice);
    if (isNaN(priceValue)) {
      toast.error('Invalid price value');
      return;
    }

    selectedProducts.forEach(productId => {
      const product = products.find(p => p.id === productId);
      if (!product) return;

      let newPrice = product.price;

      switch (bulkPriceMode) {
        case 'fixed':
          newPrice = priceValue;
          break;
        case 'percentage':
          newPrice = product.price * (1 + priceValue / 100);
          break;
        case 'increase':
          newPrice = product.price + priceValue;
          break;
        case 'decrease':
          newPrice = product.price - priceValue;
          break;
      }

      handleFieldChange(productId, 'price', Math.max(0, newPrice));
    });

    toast.success(`Applied bulk price to ${selectedProducts.size} products`);
  };

  const applyBulkCategory = () => {
    if (!bulkCategory || selectedProducts.size === 0) return;

    selectedProducts.forEach(productId => {
      handleFieldChange(productId, 'category', bulkCategory);
    });

    toast.success(`Applied category to ${selectedProducts.size} products`);
  };

  const applyBulkImageUpdate = () => {
    if (!bulkImagePrefix || selectedProducts.size === 0) return;

    selectedProducts.forEach(productId => {
      const product = products.find(p => p.id === productId);
      if (!product) return;

      // Smart image URL generation based on product name or SKU
      const imageName = product.name.toLowerCase().replace(/\s+/g, '-');
      const newImageUrl = `${bulkImagePrefix}/${imageName}.jpg`;
      
      handleFieldChange(productId, 'image_url', newImageUrl);
    });

    toast.success(`Updated image URLs for ${selectedProducts.size} products`);
  };

  const previewChanges = () => {
    setPreviewMode(true);
  };

  const saveChanges = async () => {
    if (changes.size === 0) {
      toast.error('No changes to save');
      return;
    }

    if (!backupCreated) {
      toast.error('Please create a backup before saving changes');
      return;
    }

    setLoading(true);
    const updates: any[] = [];
    
    changes.forEach((productChanges, productId) => {
      updates.push({
        id: productId,
        ...productChanges,
        updated_at: new Date().toISOString()
      });
    });

    try {
      // Batch update in chunks to avoid timeout
      const chunkSize = 10;
      for (let i = 0; i < updates.length; i += chunkSize) {
        const chunk = updates.slice(i, i + chunkSize);
        
        for (const update of chunk) {
          const { error } = await supabase
            .from('products')
            .update(update)
            .eq('id', update.id);

          if (error) throw error;
        }
        
        // Show progress
        const progress = Math.min(100, ((i + chunkSize) / updates.length) * 100);
        toast.success(`Progress: ${Math.round(progress)}%`);
      }

      toast.success(`Successfully updated ${updates.length} products`);
      setChanges(new Map());
      setSelectedProducts(new Set());
      fetchProducts(); // Reload products
    } catch (error) {
      console.error('Error saving changes:', error);
      toast.error('Failed to save some changes');
    }
    setLoading(false);
  };

  const exportToCSV = () => {
    const headers = ['ID', 'Name', 'Description', 'Price', 'Category', 'Image URL', 'In Stock'];
    const rows = filteredProducts.map(p => [
      p.id,
      p.name,
      p.description,
      p.price,
      p.category,
      p.image_url,
      p.in_stock
    ]);

    const csvContent = [
      headers.join(','),
      ...rows.map(row => row.map(cell => `"${cell || ''}"`).join(','))
    ].join('\n');

    const blob = new Blob([csvContent], { type: 'text/csv' });
    const url = URL.createObjectURL(blob);
    const a = document.createElement('a');
    a.href = url;
    a.download = `products_export_${Date.now()}.csv`;
    a.click();
  };

  const importFromCSV = async (event: React.ChangeEvent<HTMLInputElement>) => {
    const file = event.target.files?.[0];
    if (!file) return;

    const reader = new FileReader();
    reader.onload = async (e) => {
      try {
        const text = e.target?.result as string;
        const lines = text.split('\n');
        const headers = lines[0].split(',');
        
        for (let i = 1; i < lines.length; i++) {
          if (!lines[i]) continue;
          
          const values = lines[i].split(',').map(v => v.replace(/^"|"$/g, ''));
          const productId = values[0];
          
          if (productId && selectedProducts.has(productId)) {
            // Update only selected products
            handleFieldChange(productId, 'name', values[1]);
            handleFieldChange(productId, 'description', values[2]);
            handleFieldChange(productId, 'price', parseFloat(values[3]));
            handleFieldChange(productId, 'category', values[4]);
            handleFieldChange(productId, 'image_url', values[5]);
          }
        }
        
        toast.success('CSV imported successfully');
      } catch (error) {
        console.error('Error importing CSV:', error);
        toast.error('Failed to import CSV');
      }
    };
    reader.readAsText(file);
  };

  const filteredProducts = products.filter(product => {
    const matchesSearch = product.name.toLowerCase().includes(searchTerm.toLowerCase()) ||
                         product.description?.toLowerCase().includes(searchTerm.toLowerCase());
    const matchesCategory = filterCategory === 'all' || product.category === filterCategory;
    return matchesSearch && matchesCategory;
  });

  const getChangesSummary = (): ProductChange[] => {
    const summary: ProductChange[] = [];
    
    changes.forEach((productChanges, productId) => {
      const product = products.find(p => p.id === productId);
      if (!product) return;
      
      Object.entries(productChanges).forEach(([field, newValue]) => {
        summary.push({
          id: productId,
          field,
          oldValue: product[field as keyof Product],
          newValue,
          productName: product.name
        });
      });
    });
    
    return summary;
  };

  return (
    <Card className="w-full">
      <CardHeader>
        <div className="flex items-center justify-between">
          <CardTitle className="flex items-center gap-2">
            <Package className="h-5 w-5" />
            Bulk Product Editor
          </CardTitle>
          <div className="flex gap-2">
            {!backupCreated && (
              <Button onClick={createBackup} variant="outline">
                <Download className="h-4 w-4 mr-2" />
                Create Backup
              </Button>
            )}
            <Button onClick={exportToCSV} variant="outline">
              <FileSpreadsheet className="h-4 w-4 mr-2" />
              Export CSV
            </Button>
            <label htmlFor="csv-import">
              <Button variant="outline" asChild>
                <span>
                  <Upload className="h-4 w-4 mr-2" />
                  Import CSV
                </span>
              </Button>
            </label>
            <input
              id="csv-import"
              type="file"
              accept=".csv"
              className="hidden"
              onChange={importFromCSV}
            />
          </div>
        </div>
      </CardHeader>

      <CardContent className="space-y-6">
        {/* Search and Filter */}
        <div className="flex gap-4">
          <div className="flex-1 relative">
            <Search className="absolute left-3 top-1/2 transform -translate-y-1/2 h-4 w-4 text-muted-foreground" />
            <Input
              placeholder="Search products..."
              value={searchTerm}
              onChange={(e) => setSearchTerm(e.target.value)}
              className="pl-10"
            />
          </div>
          <Select value={filterCategory} onValueChange={setFilterCategory}>
            <SelectTrigger className="w-[200px]">
              <SelectValue placeholder="All Categories" />
            </SelectTrigger>
            <SelectContent>
              <SelectItem value="all">All Categories</SelectItem>
              {categories.map(cat => (
                <SelectItem key={cat} value={cat}>{cat}</SelectItem>
              ))}
            </SelectContent>
          </Select>
        </div>

        {/* Alerts */}
        {backupCreated && (
          <Alert className="bg-green-50">
            <CheckCircle className="h-4 w-4 text-green-600" />
            <AlertDescription>
              Backup created. You can safely proceed with bulk edits.
            </AlertDescription>
          </Alert>
        )}

        <Tabs defaultValue="bulk-actions">
          <TabsList className="grid w-full grid-cols-3">
            <TabsTrigger value="bulk-actions">Bulk Actions</TabsTrigger>
            <TabsTrigger value="individual">Individual Edits</TabsTrigger>
            <TabsTrigger value="preview">Preview Changes</TabsTrigger>
          </TabsList>

          <TabsContent value="bulk-actions" className="space-y-4">
            <Alert>
              <AlertCircle className="h-4 w-4" />
              <AlertDescription>
                Select products below, then apply bulk actions. All changes are previewed before saving.
              </AlertDescription>
            </Alert>

            {/* Bulk Price Update */}
            <Card>
              <CardHeader>
                <CardTitle className="text-lg flex items-center gap-2">
                  <DollarSign className="h-4 w-4" />
                  Bulk Price Update
                </CardTitle>
              </CardHeader>
              <CardContent className="space-y-4">
                <div className="flex gap-2">
                  <Select value={bulkPriceMode} onValueChange={(v: any) => setBulkPriceMode(v)}>
                    <SelectTrigger className="w-[150px]">
                      <SelectValue />
                    </SelectTrigger>
                    <SelectContent>
                      <SelectItem value="fixed">Set Fixed Price</SelectItem>
                      <SelectItem value="percentage">Adjust by %</SelectItem>
                      <SelectItem value="increase">Increase by $</SelectItem>
                      <SelectItem value="decrease">Decrease by $</SelectItem>
                    </SelectContent>
                  </Select>
                  <Input
                    type="number"
                    placeholder="Enter value"
                    value={bulkPrice}
                    onChange={(e) => setBulkPrice(e.target.value)}
                    className="w-[150px]"
                  />
                  <Button onClick={applyBulkPrice} disabled={selectedProducts.size === 0}>
                    Apply to {selectedProducts.size} Products
                  </Button>
                </div>
              </CardContent>
            </Card>

            {/* Bulk Category Update */}
            <Card>
              <CardHeader>
                <CardTitle className="text-lg flex items-center gap-2">
                  <Filter className="h-4 w-4" />
                  Bulk Category Update
                </CardTitle>
              </CardHeader>
              <CardContent>
                <div className="flex gap-2">
                  <Input
                    placeholder="Enter category name"
                    value={bulkCategory}
                    onChange={(e) => setBulkCategory(e.target.value)}
                    className="w-[250px]"
                  />
                  <Button onClick={applyBulkCategory} disabled={selectedProducts.size === 0}>
                    Apply to {selectedProducts.size} Products
                  </Button>
                </div>
              </CardContent>
            </Card>

            {/* Bulk Image Update */}
            <Card>
              <CardHeader>
                <CardTitle className="text-lg flex items-center gap-2">
                  <Image className="h-4 w-4" />
                  Bulk Image URL Update
                </CardTitle>
              </CardHeader>
              <CardContent>
                <div className="flex gap-2">
                  <Input
                    placeholder="Enter image URL prefix (e.g., https://cdn.example.com/products)"
                    value={bulkImagePrefix}
                    onChange={(e) => setBulkImagePrefix(e.target.value)}
                    className="flex-1"
                  />
                  <Button onClick={applyBulkImageUpdate} disabled={selectedProducts.size === 0}>
                    Apply to {selectedProducts.size} Products
                  </Button>
                </div>
                <p className="text-sm text-muted-foreground mt-2">
                  Images will be named based on product names (e.g., product-name.jpg)
                </p>
              </CardContent>
            </Card>
          </TabsContent>

          <TabsContent value="individual">
            <ScrollArea className="h-[400px]">
              <div className="space-y-2">
                {filteredProducts.map(product => {
                  const productChanges = changes.get(product.id) || {};
                  const hasChanges = Object.keys(productChanges).length > 0;
                  
                  return (
                    <Card key={product.id} className={hasChanges ? 'border-blue-500' : ''}>
                      <CardContent className="p-4">
                        <div className="grid grid-cols-12 gap-4 items-center">
                          <div className="col-span-1">
                            <Checkbox
                              checked={selectedProducts.has(product.id)}
                              onCheckedChange={() => handleSelectProduct(product.id)}
                            />
                          </div>
                          <div className="col-span-3">
                            <Input
                              value={productChanges.name !== undefined ? productChanges.name : product.name}
                              onChange={(e) => handleFieldChange(product.id, 'name', e.target.value)}
                              placeholder="Product name"
                            />
                          </div>
                          <div className="col-span-2">
                            <Input
                              type="number"
                              value={productChanges.price !== undefined ? productChanges.price : product.price}
                              onChange={(e) => handleFieldChange(product.id, 'price', parseFloat(e.target.value))}
                              placeholder="Price"
                            />
                          </div>
                          <div className="col-span-2">
                            <Input
                              value={productChanges.category !== undefined ? productChanges.category : product.category}
                              onChange={(e) => handleFieldChange(product.id, 'category', e.target.value)}
                              placeholder="Category"
                            />
                          </div>
                          <div className="col-span-3">
                            <Input
                              value={productChanges.image_url !== undefined ? productChanges.image_url : product.image_url}
                              onChange={(e) => handleFieldChange(product.id, 'image_url', e.target.value)}
                              placeholder="Image URL"
                            />
                          </div>
                          <div className="col-span-1">
                            {hasChanges && <Badge className="bg-blue-500">Modified</Badge>}
                          </div>
                        </div>
                      </CardContent>
                    </Card>
                  );
                })}
              </div>
            </ScrollArea>
          </TabsContent>

          <TabsContent value="preview">
            {changes.size > 0 ? (
              <div className="space-y-4">
                <Alert>
                  <AlertCircle className="h-4 w-4" />
                  <AlertDescription>
                    Review all changes before saving. {changes.size} products will be updated.
                  </AlertDescription>
                </Alert>
                
                <ScrollArea className="h-[400px]">
                  <div className="space-y-2">
                    {getChangesSummary().map((change, idx) => (
                      <Card key={idx}>
                        <CardContent className="p-4">
                          <div className="flex items-center justify-between">
                            <div>
                              <p className="font-medium">{change.productName}</p>
                              <p className="text-sm text-muted-foreground">
                                {change.field}: {JSON.stringify(change.oldValue)} → {JSON.stringify(change.newValue)}
                              </p>
                            </div>
                            <Button
                              variant="ghost"
                              size="sm"
                              onClick={() => {
                                const productChanges = changes.get(change.id);
                                if (productChanges) {
                                  delete productChanges[change.field];
                                  if (Object.keys(productChanges).length === 0) {
                                    changes.delete(change.id);
                                  }
                                  setChanges(new Map(changes));
                                }
                              }}
                            >
                              <Undo className="h-4 w-4" />
                            </Button>
                          </div>
                        </CardContent>
                      </Card>
                    ))}
                  </div>
                </ScrollArea>
              </div>
            ) : (
              <Alert>
                <AlertDescription>No changes to preview</AlertDescription>
              </Alert>
            )}
          </TabsContent>
        </Tabs>

        {/* Product Selection List */}
        <div className="border rounded-lg p-4">
          <div className="flex items-center justify-between mb-4">
            <h3 className="font-medium">
              Products ({filteredProducts.length})
            </h3>
            <Button variant="outline" size="sm" onClick={handleSelectAll}>
              {selectedProducts.size === filteredProducts.length ? 'Deselect All' : 'Select All'}
            </Button>
          </div>
          
          <ScrollArea className="h-[200px]">
            <div className="space-y-2">
              {filteredProducts.map(product => (
                <div key={product.id} className="flex items-center gap-2">
                  <Checkbox
                    checked={selectedProducts.has(product.id)}
                    onCheckedChange={() => handleSelectProduct(product.id)}
                  />
                  <span className="text-sm">{product.name}</span>
                  {product.stripe_product_id && (
                    <Badge variant="outline" className="text-xs">Synced</Badge>
                  )}
                </div>
              ))}
            </div>
          </ScrollArea>
        </div>

        {/* Action Buttons */}
        <div className="flex justify-between">
          <div>
            <Badge variant="outline">
              {selectedProducts.size} products selected
            </Badge>
            {changes.size > 0 && (
              <Badge variant="default" className="ml-2">
                {changes.size} products modified
              </Badge>
            )}
          </div>
          <div className="flex gap-2">
            <Button
              variant="outline"
              onClick={() => {
                setChanges(new Map());
                setSelectedProducts(new Set());
              }}
              disabled={changes.size === 0}
            >
              Clear Changes
            </Button>
            <Button
              onClick={saveChanges}
              disabled={changes.size === 0 || !backupCreated || loading}
            >
              {loading ? 'Saving...' : `Save ${changes.size} Changes`}
            </Button>
          </div>
        </div>
      </CardContent>
    </Card>
  );
}