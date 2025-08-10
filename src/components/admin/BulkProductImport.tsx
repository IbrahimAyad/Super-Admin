/**
 * BULK PRODUCT IMPORT SYSTEM
 * Fast import of multiple products using templates and CSV
 */

import React, { useState, useRef } from 'react';
import { Button } from '@/components/ui/button';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Tabs, TabsContent, TabsList, TabsTrigger } from '@/components/ui/tabs';
import { Label } from '@/components/ui/label';
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from '@/components/ui/select';
import { Progress } from '@/components/ui/progress';
import { Badge } from '@/components/ui/badge';
import { Textarea } from '@/components/ui/textarea';
import { Separator } from '@/components/ui/separator';
import { toast } from 'sonner';
import { supabase } from '@/lib/supabase-client';
import { productCache } from '@/lib/cache';
import { 
  Upload, 
  Download, 
  FileSpreadsheet,
  Zap,
  CheckCircle,
  AlertTriangle,
  Copy,
  Plus,
  FileText
} from 'lucide-react';

interface BulkImportProduct {
  name: string;
  category: string;
  base_price: number;
  sku?: string;
  description?: string;
  sizes?: string[];
  colors?: string[];
  status: 'valid' | 'invalid' | 'duplicate';
  errors: string[];
}

const BULK_TEMPLATES = {
  'Tuxedo Collection': {
    category: 'Men\'s Suits',
    products: [
      { name: 'Classic Black Tuxedo', price: 299.99, colors: ['Black'] },
      { name: 'Navy Blue Tuxedo', price: 319.99, colors: ['Navy'] },
      { name: 'Charcoal Grey Tuxedo', price: 309.99, colors: ['Charcoal'] },
      { name: 'White Dinner Jacket', price: 279.99, colors: ['White'] },
      { name: 'Burgundy Tuxedo', price: 329.99, colors: ['Burgundy'] }
    ]
  },
  'Dress Shirt Basics': {
    category: 'Dress Shirts',
    products: [
      { name: 'White Dress Shirt', price: 49.99, colors: ['White'] },
      { name: 'Light Blue Dress Shirt', price: 49.99, colors: ['Light Blue'] },
      { name: 'French Cuff White Shirt', price: 69.99, colors: ['White'] },
      { name: 'Striped Dress Shirt', price: 54.99, colors: ['Blue/White', 'Black/White'] },
      { name: 'Solid Navy Dress Shirt', price: 49.99, colors: ['Navy'] }
    ]
  },
  'Essential Ties': {
    category: 'Ties',
    products: [
      { name: 'Solid Black Tie', price: 19.99, colors: ['Black'] },
      { name: 'Solid Navy Tie', price: 19.99, colors: ['Navy'] },
      { name: 'Silver Striped Tie', price: 24.99, colors: ['Silver/Black'] },
      { name: 'Red Paisley Tie', price: 22.99, colors: ['Red'] },
      { name: 'Gold Geometric Tie', price: 26.99, colors: ['Gold'] }
    ]
  }
};

export function BulkProductImport({ onComplete }: { onComplete?: () => void }) {
  const [importMode, setImportMode] = useState<'template' | 'csv' | 'manual'>('template');
  const [selectedTemplate, setSelectedTemplate] = useState('');
  const [products, setProducts] = useState<BulkImportProduct[]>([]);
  const [isProcessing, setIsProcessing] = useState(false);
  const [progress, setProgress] = useState(0);
  const [csvData, setCsvData] = useState('');
  const [manualText, setManualText] = useState('');
  const fileInputRef = useRef<HTMLInputElement>(null);

  const handleTemplateSelect = (templateKey: string) => {
    setSelectedTemplate(templateKey);
    const template = BULK_TEMPLATES[templateKey as keyof typeof BULK_TEMPLATES];
    
    if (template) {
      const templateProducts: BulkImportProduct[] = template.products.map((prod, index) => ({
        name: prod.name,
        category: template.category,
        base_price: prod.price,
        sku: generateSKU(prod.name, template.category),
        description: generateDescription(prod.name, template.category),
        colors: prod.colors,
        sizes: getDefaultSizes(template.category),
        status: 'valid',
        errors: []
      }));
      
      setProducts(templateProducts);
      validateProducts(templateProducts);
    }
  };

  const generateSKU = (name: string, category: string) => {
    const prefix = category === 'Men\'s Suits' ? 'MS' : 
                   category === 'Dress Shirts' ? 'DS' : 
                   category === 'Ties' ? 'TIE' : 'PROD';
    const code = name.substring(0, 3).toUpperCase().replace(/\s/g, '');
    const suffix = Date.now().toString().slice(-4);
    return `${prefix}-${code}-${suffix}`;
  };

  const generateDescription = (name: string, category: string) => {
    const templates = {
      'Men\'s Suits': `Premium quality ${name.toLowerCase()} with modern fit and classic styling. Perfect for formal events and special occasions.`,
      'Dress Shirts': `Crisp ${name.toLowerCase()} crafted from premium cotton blend. Professional styling for business and formal wear.`,
      'Ties': `Elegant ${name.toLowerCase()} to complement any formal outfit. High-quality construction with sophisticated design.`
    };
    return templates[category as keyof typeof templates] || `Quality ${name.toLowerCase()} for your formal wardrobe needs.`;
  };

  const getDefaultSizes = (category: string) => {
    const sizeMap = {
      'Men\'s Suits': ['34R', '36R', '38R', '40R', '42R', '44R', '46R'],
      'Dress Shirts': ['S', 'M', 'L', 'XL', 'XXL'],
      'Ties': ['One Size'],
      'Accessories': ['One Size']
    };
    return sizeMap[category as keyof typeof sizeMap] || ['One Size'];
  };

  const validateProducts = (productList: BulkImportProduct[]) => {
    const validated = productList.map(product => {
      const errors: string[] = [];
      
      if (!product.name || product.name.length < 3) {
        errors.push('Name too short');
      }
      if (!product.category) {
        errors.push('Category required');
      }
      if (!product.base_price || product.base_price <= 0) {
        errors.push('Valid price required');
      }
      if (!product.sku) {
        errors.push('SKU required');
      }

      return {
        ...product,
        status: errors.length === 0 ? 'valid' : 'invalid',
        errors
      } as BulkImportProduct;
    });

    setProducts(validated);
  };

  const parseCsvData = (csvText: string) => {
    const lines = csvText.split('\n').filter(line => line.trim());
    if (lines.length < 2) {
      toast.error('CSV must have header row and at least one product');
      return;
    }

    const headers = lines[0].split(',').map(h => h.trim().toLowerCase());
    const nameIndex = headers.findIndex(h => h.includes('name'));
    const categoryIndex = headers.findIndex(h => h.includes('category'));
    const priceIndex = headers.findIndex(h => h.includes('price'));
    const descIndex = headers.findIndex(h => h.includes('description'));

    if (nameIndex === -1 || categoryIndex === -1 || priceIndex === -1) {
      toast.error('CSV must include name, category, and price columns');
      return;
    }

    const csvProducts: BulkImportProduct[] = lines.slice(1).map((line, index) => {
      const cols = line.split(',').map(col => col.trim().replace(/"/g, ''));
      
      return {
        name: cols[nameIndex] || `Product ${index + 1}`,
        category: cols[categoryIndex] || 'Accessories',
        base_price: parseFloat(cols[priceIndex]) || 0,
        sku: generateSKU(cols[nameIndex] || `Product ${index + 1}`, cols[categoryIndex] || 'Accessories'),
        description: cols[descIndex] || '',
        sizes: getDefaultSizes(cols[categoryIndex] || 'Accessories'),
        status: 'valid',
        errors: []
      } as BulkImportProduct;
    });

    setProducts(csvProducts);
    validateProducts(csvProducts);
  };

  const parseManualText = (text: string) => {
    const lines = text.split('\n').filter(line => line.trim());
    
    const manualProducts: BulkImportProduct[] = lines.map((line, index) => {
      // Expected format: "Product Name | Category | Price"
      const parts = line.split('|').map(p => p.trim());
      
      const name = parts[0] || `Product ${index + 1}`;
      const category = parts[1] || 'Accessories';
      const price = parts[2] ? parseFloat(parts[2].replace('$', '')) : 0;

      return {
        name,
        category,
        base_price: price,
        sku: generateSKU(name, category),
        description: generateDescription(name, category),
        sizes: getDefaultSizes(category),
        status: 'valid',
        errors: []
      } as BulkImportProduct;
    });

    setProducts(manualProducts);
    validateProducts(manualProducts);
  };

  const handleFileUpload = (event: React.ChangeEvent<HTMLInputElement>) => {
    const file = event.target.files?.[0];
    if (!file) return;

    const reader = new FileReader();
    reader.onload = (e) => {
      const text = e.target?.result as string;
      setCsvData(text);
      parseCsvData(text);
    };
    reader.readAsText(file);
  };

  const downloadTemplate = () => {
    const csvContent = 'Name,Category,Price,Description\n' +
      'Sample Product,"Men\'s Suits",199.99,"Sample description"\n' +
      'Another Product,"Dress Shirts",49.99,"Another description"';
    
    const blob = new Blob([csvContent], { type: 'text/csv' });
    const url = URL.createObjectURL(blob);
    const a = document.createElement('a');
    a.href = url;
    a.download = 'product_import_template.csv';
    a.click();
    URL.revokeObjectURL(url);
  };

  const handleBulkImport = async () => {
    const validProducts = products.filter(p => p.status === 'valid');
    if (validProducts.length === 0) {
      toast.error('No valid products to import');
      return;
    }

    setIsProcessing(true);
    setProgress(0);

    try {
      const batchSize = 10;
      let imported = 0;

      for (let i = 0; i < validProducts.length; i += batchSize) {
        const batch = validProducts.slice(i, i + batchSize);
        
        // Insert products
        const productInserts = batch.map(product => ({
          name: product.name,
          category: product.category,
          base_price: product.base_price,
          sku: product.sku,
          description: product.description,
          status: 'active',
          created_at: new Date().toISOString(),
          updated_at: new Date().toISOString()
        }));

        const { data: insertedProducts, error: productError } = await supabase
          .from('products')
          .insert(productInserts)
          .select();

        if (productError) throw productError;

        // Create variants for each product
        for (const [index, insertedProduct] of insertedProducts.entries()) {
          const originalProduct = batch[index];
          
          if (originalProduct.sizes && originalProduct.sizes.length > 0) {
            const variants = originalProduct.sizes.flatMap(size => 
              (originalProduct.colors || ['Default']).map(color => ({
                product_id: insertedProduct.id,
                name: `${originalProduct.name} - ${size}${color !== 'Default' ? ` - ${color}` : ''}`,
                sku: `${originalProduct.sku}-${size}${color !== 'Default' ? `-${color.replace(/[^A-Z0-9]/g, '')}` : ''}`,
                price: originalProduct.base_price,
                size,
                color: color !== 'Default' ? color : undefined,
                inventory_quantity: 0,
                status: 'active',
                created_at: new Date().toISOString(),
                updated_at: new Date().toISOString()
              }))
            );

            await supabase.from('product_variants').insert(variants);
          }
        }

        imported += batch.length;
        setProgress((imported / validProducts.length) * 100);
      }

      // Clear cache
      productCache.clearAll();

      toast.success(`Successfully imported ${imported} products`);
      onComplete?.();
      
    } catch (error) {
      console.error('Bulk import error:', error);
      toast.error('Import failed. Please try again.');
    } finally {
      setIsProcessing(false);
      setProgress(0);
    }
  };

  const validCount = products.filter(p => p.status === 'valid').length;
  const invalidCount = products.filter(p => p.status === 'invalid').length;

  return (
    <div className="max-w-6xl mx-auto space-y-6">
      <div className="flex items-center justify-between">
        <div>
          <h2 className="text-2xl font-bold">Bulk Product Import</h2>
          <p className="text-muted-foreground">Import multiple products quickly using templates or CSV</p>
        </div>

        {products.length > 0 && (
          <div className="flex items-center gap-4">
            <Badge variant="default" className="bg-green-100 text-green-800">
              {validCount} Valid
            </Badge>
            {invalidCount > 0 && (
              <Badge variant="destructive">
                {invalidCount} Invalid
              </Badge>
            )}
          </div>
        )}
      </div>

      <Tabs value={importMode} onValueChange={(value) => setImportMode(value as any)}>
        <TabsList className="grid w-full grid-cols-3">
          <TabsTrigger value="template" className="flex items-center gap-2">
            <Zap className="h-4 w-4" />
            Templates
          </TabsTrigger>
          <TabsTrigger value="csv" className="flex items-center gap-2">
            <FileSpreadsheet className="h-4 w-4" />
            CSV Upload
          </TabsTrigger>
          <TabsTrigger value="manual" className="flex items-center gap-2">
            <FileText className="h-4 w-4" />
            Manual Entry
          </TabsTrigger>
        </TabsList>

        <TabsContent value="template" className="space-y-4">
          <Card>
            <CardHeader>
              <CardTitle>Choose a Template</CardTitle>
            </CardHeader>
            <CardContent>
              <Select value={selectedTemplate} onValueChange={handleTemplateSelect}>
                <SelectTrigger>
                  <SelectValue placeholder="Select product template..." />
                </SelectTrigger>
                <SelectContent>
                  {Object.entries(BULK_TEMPLATES).map(([key, template]) => (
                    <SelectItem key={key} value={key}>
                      {key} ({template.products.length} products)
                    </SelectItem>
                  ))}
                </SelectContent>
              </Select>
            </CardContent>
          </Card>
        </TabsContent>

        <TabsContent value="csv" className="space-y-4">
          <Card>
            <CardHeader>
              <CardTitle className="flex items-center justify-between">
                CSV File Upload
                <Button variant="outline" size="sm" onClick={downloadTemplate}>
                  <Download className="h-4 w-4 mr-2" />
                  Download Template
                </Button>
              </CardTitle>
            </CardHeader>
            <CardContent className="space-y-4">
              <div>
                <input
                  type="file"
                  accept=".csv"
                  onChange={handleFileUpload}
                  ref={fileInputRef}
                  className="hidden"
                />
                <Button
                  variant="outline"
                  onClick={() => fileInputRef.current?.click()}
                  className="w-full"
                >
                  <Upload className="h-4 w-4 mr-2" />
                  Choose CSV File
                </Button>
              </div>
              
              {csvData && (
                <div>
                  <Label>CSV Preview</Label>
                  <Textarea
                    value={csvData.substring(0, 500) + (csvData.length > 500 ? '...' : '')}
                    readOnly
                    rows={5}
                    className="mt-1 font-mono text-xs"
                  />
                </div>
              )}
            </CardContent>
          </Card>
        </TabsContent>

        <TabsContent value="manual" className="space-y-4">
          <Card>
            <CardHeader>
              <CardTitle>Manual Entry</CardTitle>
            </CardHeader>
            <CardContent className="space-y-4">
              <div>
                <Label htmlFor="manual-text">Product List (Format: Name | Category | Price)</Label>
                <Textarea
                  id="manual-text"
                  placeholder="Classic Black Tuxedo | Men's Suits | 299.99&#10;Navy Blue Tuxedo | Men's Suits | 319.99&#10;White Dress Shirt | Dress Shirts | 49.99"
                  value={manualText}
                  onChange={(e) => setManualText(e.target.value)}
                  rows={8}
                  className="mt-1 font-mono"
                />
              </div>
              <Button
                onClick={() => parseManualText(manualText)}
                disabled={!manualText.trim()}
              >
                Parse Products
              </Button>
            </CardContent>
          </Card>
        </TabsContent>
      </Tabs>

      {/* Products Preview */}
      {products.length > 0 && (
        <Card>
          <CardHeader>
            <CardTitle>Import Preview ({products.length} products)</CardTitle>
          </CardHeader>
          <CardContent>
            <div className="space-y-2 max-h-96 overflow-y-auto">
              {products.map((product, index) => (
                <div
                  key={index}
                  className={`p-3 rounded-lg border ${
                    product.status === 'valid' ? 'border-green-200 bg-green-50' :
                    'border-red-200 bg-red-50'
                  }`}
                >
                  <div className="flex items-center justify-between">
                    <div>
                      <div className="font-medium">{product.name}</div>
                      <div className="text-sm text-muted-foreground">
                        {product.category} • ${product.base_price} • {product.sku}
                      </div>
                    </div>
                    <div className="flex items-center gap-2">
                      {product.status === 'valid' ? (
                        <CheckCircle className="h-4 w-4 text-green-600" />
                      ) : (
                        <AlertTriangle className="h-4 w-4 text-red-600" />
                      )}
                    </div>
                  </div>
                  {product.errors.length > 0 && (
                    <div className="mt-2 text-xs text-red-600">
                      {product.errors.join(', ')}
                    </div>
                  )}
                </div>
              ))}
            </div>
          </CardContent>
        </Card>
      )}

      {/* Import Actions */}
      {products.length > 0 && (
        <Card>
          <CardContent className="pt-6">
            {isProcessing && (
              <div className="mb-4">
                <div className="flex items-center justify-between mb-2">
                  <span className="text-sm font-medium">Importing products...</span>
                  <span className="text-sm text-muted-foreground">{Math.round(progress)}%</span>
                </div>
                <Progress value={progress} />
              </div>
            )}
            
            <div className="flex items-center justify-between">
              <div className="text-sm text-muted-foreground">
                Ready to import {validCount} valid products
                {invalidCount > 0 && ` (${invalidCount} invalid items will be skipped)`}
              </div>
              
              <Button
                onClick={handleBulkImport}
                disabled={validCount === 0 || isProcessing}
                className="min-w-32"
              >
                {isProcessing ? (
                  <>
                    <div className="animate-spin rounded-full h-4 w-4 border-b-2 border-white mr-2" />
                    Importing...
                  </>
                ) : (
                  <>
                    <Plus className="h-4 w-4 mr-2" />
                    Import Products
                  </>
                )}
              </Button>
            </div>
          </CardContent>
        </Card>
      )}
    </div>
  );
}