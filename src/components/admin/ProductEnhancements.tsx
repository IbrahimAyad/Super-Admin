import React, { useState, useEffect } from 'react';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { Textarea } from '@/components/ui/textarea';
import { Input } from '@/components/ui/input';
import { Alert, AlertDescription } from '@/components/ui/alert';
import { Badge } from '@/components/ui/badge';
import { Progress } from '@/components/ui/progress';
import { Tabs, TabsContent, TabsList, TabsTrigger } from '@/components/ui/tabs';
import { ScrollArea } from '@/components/ui/scroll-area';
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from '@/components/ui/select';
import { Checkbox } from '@/components/ui/checkbox';
import { supabase } from '@/lib/supabase';
import { toast } from 'sonner';
import {
  FileText,
  Image,
  CheckCircle2,
  AlertTriangle,
  Wand2,
  Search,
  Shield,
  RefreshCw,
  Eye,
  Save,
  Download,
  Upload,
  Link,
  XCircle
} from 'lucide-react';

interface Product {
  id: string;
  name: string;
  description: string;
  price: number;
  category: string;
  image_url?: string;
  additional_images?: string[];
  tags?: string[];
  sku?: string;
  brand?: string;
  in_stock: boolean;
  stripe_product_id?: string;
}

interface ValidationIssue {
  productId: string;
  productName: string;
  field: string;
  issue: string;
  severity: 'error' | 'warning' | 'info';
  suggestion?: string;
}

interface ImageMatch {
  productId: string;
  productName: string;
  currentImage?: string;
  suggestedImages: string[];
  confidence: number;
}

export function ProductEnhancements() {
  const [products, setProducts] = useState<Product[]>([]);
  const [selectedProducts, setSelectedProducts] = useState<Set<string>>(new Set());
  const [loading, setLoading] = useState(false);
  const [backupCreated, setBackupCreated] = useState(false);
  
  // Bulk Description Editor States
  const [descriptionTemplate, setDescriptionTemplate] = useState('');
  const [descriptionMode, setDescriptionMode] = useState<'replace' | 'append' | 'prepend'>('replace');
  const [useAI, setUseAI] = useState(false);
  
  // Image Matching States
  const [imageMatches, setImageMatches] = useState<ImageMatch[]>([]);
  const [imageUrlPattern, setImageUrlPattern] = useState('https://cdn.example.com/products/{sku}.jpg');
  const [imageSearchPattern, setImageSearchPattern] = useState('');
  
  // Validation States
  const [validationIssues, setValidationIssues] = useState<ValidationIssue[]>([]);
  const [validationProgress, setValidationProgress] = useState(0);
  const [autoFix, setAutoFix] = useState(false);

  useEffect(() => {
    fetchProducts();
  }, []);

  const fetchProducts = async () => {
    setLoading(true);
    try {
      const { data, error } = await supabase
        .from('products')
        .select('*')
        .order('name');

      if (error) throw error;
      setProducts(data || []);
    } catch (error) {
      console.error('Error fetching products:', error);
      toast.error('Failed to load products');
    }
    setLoading(false);
  };

  const createBackup = async () => {
    const blob = new Blob([JSON.stringify(products, null, 2)], { type: 'application/json' });
    const url = URL.createObjectURL(blob);
    const a = document.createElement('a');
    a.href = url;
    a.download = `products_backup_${Date.now()}.json`;
    a.click();
    setBackupCreated(true);
    toast.success('Backup created successfully');
  };

  // ============= BULK DESCRIPTION EDITOR =============
  
  const generateDescription = (product: Product, template: string): string => {
    // Replace placeholders in template
    let description = template
      .replace(/\{name\}/g, product.name)
      .replace(/\{category\}/g, product.category || '')
      .replace(/\{brand\}/g, product.brand || 'KCT')
      .replace(/\{price\}/g, product.price.toString())
      .replace(/\{sku\}/g, product.sku || '');
    
    // Add smart enhancements
    if (useAI) {
      // Add category-specific descriptions
      if (product.category?.toLowerCase().includes('suit')) {
        description += '\n\nPerfect for business meetings, weddings, and formal events.';
      } else if (product.category?.toLowerCase().includes('shirt')) {
        description += '\n\nMade from premium cotton for all-day comfort.';
      } else if (product.category?.toLowerCase().includes('tie')) {
        description += '\n\nThe perfect accessory to complete your professional look.';
      }
      
      // Add price-based descriptions
      if (product.price > 500) {
        description += ' This premium piece represents exceptional quality and craftsmanship.';
      } else if (product.price < 100) {
        description += ' Exceptional value without compromising on style.';
      }
    }
    
    return description;
  };

  const applyBulkDescriptions = async () => {
    if (!descriptionTemplate || selectedProducts.size === 0) {
      toast.error('Please select products and enter a description template');
      return;
    }

    if (!backupCreated) {
      toast.error('Please create a backup first');
      return;
    }

    setLoading(true);
    const updates: any[] = [];
    
    selectedProducts.forEach(productId => {
      const product = products.find(p => p.id === productId);
      if (!product) return;
      
      const newDescription = generateDescription(product, descriptionTemplate);
      let finalDescription = newDescription;
      
      if (descriptionMode === 'append') {
        finalDescription = (product.description || '') + '\n\n' + newDescription;
      } else if (descriptionMode === 'prepend') {
        finalDescription = newDescription + '\n\n' + (product.description || '');
      }
      
      updates.push({
        id: product.id,
        description: finalDescription,
        updated_at: new Date().toISOString()
      });
    });

    try {
      for (const update of updates) {
        const { error } = await supabase
          .from('products')
          .update(update)
          .eq('id', update.id);
        
        if (error) throw error;
      }
      
      toast.success(`Updated descriptions for ${updates.length} products`);
      fetchProducts();
    } catch (error) {
      console.error('Error updating descriptions:', error);
      toast.error('Failed to update some descriptions');
    }
    setLoading(false);
  };

  // ============= AUTOMATED IMAGE MATCHING =============
  
  const findImageMatches = async () => {
    setLoading(true);
    const matches: ImageMatch[] = [];
    
    for (const product of products) {
      const suggestedImages: string[] = [];
      
      // Method 1: SKU-based matching
      if (product.sku) {
        suggestedImages.push(
          imageUrlPattern.replace('{sku}', product.sku),
          imageUrlPattern.replace('{sku}', product.sku.toLowerCase()),
          imageUrlPattern.replace('{sku}', product.sku.toUpperCase())
        );
      }
      
      // Method 2: Name-based matching
      const cleanName = product.name
        .toLowerCase()
        .replace(/[^a-z0-9]/g, '-')
        .replace(/-+/g, '-')
        .replace(/^-|-$/g, '');
      
      suggestedImages.push(
        imageUrlPattern.replace('{sku}', cleanName),
        imageUrlPattern.replace('{sku}', cleanName.replace(/-/g, '_')),
        imageUrlPattern.replace('{sku}', cleanName.replace(/-/g, ''))
      );
      
      // Method 3: Category + Brand pattern
      if (product.category && product.brand) {
        const categorySlug = product.category.toLowerCase().replace(/\s+/g, '-');
        const brandSlug = product.brand.toLowerCase().replace(/\s+/g, '-');
        suggestedImages.push(
          `${imageUrlPattern.split('{sku}')[0]}${brandSlug}/${categorySlug}/${cleanName}.jpg`
        );
      }
      
      // Calculate confidence based on existing patterns
      const confidence = product.sku ? 0.9 : 0.6;
      
      if (suggestedImages.length > 0) {
        matches.push({
          productId: product.id,
          productName: product.name,
          currentImage: product.image_url,
          suggestedImages: [...new Set(suggestedImages)], // Remove duplicates
          confidence
        });
      }
    }
    
    setImageMatches(matches);
    setLoading(false);
    toast.success(`Found image suggestions for ${matches.length} products`);
  };

  const applyImageMatch = async (match: ImageMatch, imageUrl: string) => {
    try {
      const { error } = await supabase
        .from('products')
        .update({ 
          image_url: imageUrl,
          updated_at: new Date().toISOString()
        })
        .eq('id', match.productId);
      
      if (error) throw error;
      
      toast.success(`Updated image for ${match.productName}`);
      
      // Remove from matches
      setImageMatches(prev => prev.filter(m => m.productId !== match.productId));
      
      // Update local state
      setProducts(prev => prev.map(p => 
        p.id === match.productId ? { ...p, image_url: imageUrl } : p
      ));
    } catch (error) {
      console.error('Error updating image:', error);
      toast.error('Failed to update image');
    }
  };

  const applyAllHighConfidenceMatches = async () => {
    const highConfidenceMatches = imageMatches.filter(m => m.confidence >= 0.8);
    
    if (highConfidenceMatches.length === 0) {
      toast.error('No high confidence matches found');
      return;
    }

    setLoading(true);
    for (const match of highConfidenceMatches) {
      if (match.suggestedImages[0]) {
        await applyImageMatch(match, match.suggestedImages[0]);
      }
    }
    setLoading(false);
  };

  // ============= PRODUCT VALIDATION =============
  
  const validateProducts = async () => {
    setValidationProgress(0);
    const issues: ValidationIssue[] = [];
    const totalProducts = products.length;
    
    for (let i = 0; i < products.length; i++) {
      const product = products[i];
      
      // Check for missing required fields
      if (!product.name || product.name.trim() === '') {
        issues.push({
          productId: product.id,
          productName: product.name || 'Unknown',
          field: 'name',
          issue: 'Product name is missing',
          severity: 'error'
        });
      }
      
      if (!product.description || product.description.length < 10) {
        issues.push({
          productId: product.id,
          productName: product.name,
          field: 'description',
          issue: 'Description is missing or too short',
          severity: 'warning',
          suggestion: 'Add a detailed product description'
        });
      }
      
      if (!product.image_url) {
        issues.push({
          productId: product.id,
          productName: product.name,
          field: 'image_url',
          issue: 'Product image is missing',
          severity: 'warning',
          suggestion: 'Add a product image'
        });
      } else if (!product.image_url.startsWith('http')) {
        issues.push({
          productId: product.id,
          productName: product.name,
          field: 'image_url',
          issue: 'Invalid image URL format',
          severity: 'error',
          suggestion: 'URL should start with http:// or https://'
        });
      }
      
      if (product.price <= 0) {
        issues.push({
          productId: product.id,
          productName: product.name,
          field: 'price',
          issue: 'Invalid price',
          severity: 'error',
          suggestion: 'Price must be greater than 0'
        });
      }
      
      if (!product.category) {
        issues.push({
          productId: product.id,
          productName: product.name,
          field: 'category',
          issue: 'Category is missing',
          severity: 'warning',
          suggestion: 'Assign a product category'
        });
      }
      
      if (!product.sku) {
        issues.push({
          productId: product.id,
          productName: product.name,
          field: 'sku',
          issue: 'SKU is missing',
          severity: 'info',
          suggestion: 'Add a unique SKU for inventory tracking'
        });
      }
      
      // Check for Stripe sync
      if (!product.stripe_product_id) {
        issues.push({
          productId: product.id,
          productName: product.name,
          field: 'stripe_product_id',
          issue: 'Not synced with Stripe',
          severity: 'info',
          suggestion: 'Sync product with Stripe for payment processing'
        });
      }
      
      // Check for duplicate names
      const duplicates = products.filter(p => 
        p.id !== product.id && 
        p.name?.toLowerCase() === product.name?.toLowerCase()
      );
      
      if (duplicates.length > 0) {
        issues.push({
          productId: product.id,
          productName: product.name,
          field: 'name',
          issue: 'Duplicate product name found',
          severity: 'warning',
          suggestion: 'Make product names unique'
        });
      }
      
      setValidationProgress(((i + 1) / totalProducts) * 100);
    }
    
    setValidationIssues(issues);
    
    const errorCount = issues.filter(i => i.severity === 'error').length;
    const warningCount = issues.filter(i => i.severity === 'warning').length;
    
    if (errorCount > 0) {
      toast.error(`Found ${errorCount} errors and ${warningCount} warnings`);
    } else if (warningCount > 0) {
      toast.warning(`Found ${warningCount} warnings`);
    } else {
      toast.success('All products passed validation!');
    }
  };

  const autoFixIssues = async () => {
    if (!backupCreated) {
      toast.error('Please create a backup before auto-fixing');
      return;
    }

    setLoading(true);
    const fixableIssues = validationIssues.filter(issue => 
      issue.severity === 'warning' || issue.severity === 'info'
    );
    
    for (const issue of fixableIssues) {
      const product = products.find(p => p.id === issue.productId);
      if (!product) continue;
      
      const update: any = { updated_at: new Date().toISOString() };
      
      switch (issue.field) {
        case 'description':
          update.description = `High-quality ${product.category || 'product'} - ${product.name}. Premium materials and expert craftsmanship.`;
          break;
        case 'category':
          // Try to guess category from name
          if (product.name.toLowerCase().includes('suit')) update.category = 'Suits';
          else if (product.name.toLowerCase().includes('shirt')) update.category = 'Shirts';
          else if (product.name.toLowerCase().includes('tie')) update.category = 'Accessories';
          else update.category = 'Uncategorized';
          break;
        case 'sku':
          update.sku = `SKU-${product.id.substring(0, 8).toUpperCase()}`;
          break;
      }
      
      if (Object.keys(update).length > 1) {
        try {
          const { error } = await supabase
            .from('products')
            .update(update)
            .eq('id', product.id);
          
          if (error) throw error;
        } catch (error) {
          console.error('Error auto-fixing issue:', error);
        }
      }
    }
    
    toast.success(`Auto-fixed ${fixableIssues.length} issues`);
    fetchProducts();
    validateProducts(); // Re-validate
    setLoading(false);
  };

  const exportValidationReport = () => {
    const report = {
      timestamp: new Date().toISOString(),
      totalProducts: products.length,
      totalIssues: validationIssues.length,
      errors: validationIssues.filter(i => i.severity === 'error'),
      warnings: validationIssues.filter(i => i.severity === 'warning'),
      info: validationIssues.filter(i => i.severity === 'info')
    };
    
    const blob = new Blob([JSON.stringify(report, null, 2)], { type: 'application/json' });
    const url = URL.createObjectURL(blob);
    const a = document.createElement('a');
    a.href = url;
    a.download = `validation_report_${Date.now()}.json`;
    a.click();
  };

  return (
    <div className="space-y-6">
      {/* Header with Backup */}
      <Card>
        <CardHeader>
          <div className="flex items-center justify-between">
            <CardTitle>Product Enhancement Tools</CardTitle>
            {!backupCreated ? (
              <Button onClick={createBackup} variant="outline">
                <Download className="h-4 w-4 mr-2" />
                Create Backup First
              </Button>
            ) : (
              <Badge className="bg-green-500">
                <CheckCircle2 className="h-4 w-4 mr-1" />
                Backup Created
              </Badge>
            )}
          </div>
        </CardHeader>
      </Card>

      <Tabs defaultValue="descriptions" className="w-full">
        <TabsList className="grid w-full grid-cols-3">
          <TabsTrigger value="descriptions">
            <FileText className="h-4 w-4 mr-2" />
            Bulk Descriptions
          </TabsTrigger>
          <TabsTrigger value="images">
            <Image className="h-4 w-4 mr-2" />
            Image Matching
          </TabsTrigger>
          <TabsTrigger value="validation">
            <Shield className="h-4 w-4 mr-2" />
            Validation
          </TabsTrigger>
        </TabsList>

        {/* BULK DESCRIPTION EDITOR */}
        <TabsContent value="descriptions" className="space-y-4">
          <Card>
            <CardHeader>
              <CardTitle>Bulk Description Editor</CardTitle>
            </CardHeader>
            <CardContent className="space-y-4">
              <Alert>
                <Wand2 className="h-4 w-4" />
                <AlertDescription>
                  Use placeholders: {'{name}'}, {'{category}'}, {'{brand}'}, {'{price}'}, {'{sku}'}
                </AlertDescription>
              </Alert>
              
              <div className="space-y-4">
                <Textarea
                  placeholder="Enter description template..."
                  value={descriptionTemplate}
                  onChange={(e) => setDescriptionTemplate(e.target.value)}
                  rows={6}
                  className="font-mono"
                />
                
                <div className="flex gap-4">
                  <Select value={descriptionMode} onValueChange={(v: any) => setDescriptionMode(v)}>
                    <SelectTrigger className="w-[200px]">
                      <SelectValue />
                    </SelectTrigger>
                    <SelectContent>
                      <SelectItem value="replace">Replace Description</SelectItem>
                      <SelectItem value="append">Append to Description</SelectItem>
                      <SelectItem value="prepend">Prepend to Description</SelectItem>
                    </SelectContent>
                  </Select>
                  
                  <div className="flex items-center space-x-2">
                    <Checkbox
                      id="use-ai"
                      checked={useAI}
                      onCheckedChange={(checked) => setUseAI(checked as boolean)}
                    />
                    <label htmlFor="use-ai" className="text-sm">
                      Add smart enhancements
                    </label>
                  </div>
                </div>
                
                {/* Product Selection */}
                <Card>
                  <CardHeader>
                    <h4 className="text-sm font-medium">Select Products</h4>
                  </CardHeader>
                  <CardContent>
                    <ScrollArea className="h-[200px]">
                      <div className="space-y-2">
                        {products.map(product => (
                          <div key={product.id} className="flex items-center space-x-2">
                            <Checkbox
                              checked={selectedProducts.has(product.id)}
                              onCheckedChange={(checked) => {
                                const newSelected = new Set(selectedProducts);
                                if (checked) {
                                  newSelected.add(product.id);
                                } else {
                                  newSelected.delete(product.id);
                                }
                                setSelectedProducts(newSelected);
                              }}
                            />
                            <span className="text-sm">{product.name}</span>
                            {!product.description && (
                              <Badge variant="outline" className="text-xs">No description</Badge>
                            )}
                          </div>
                        ))}
                      </div>
                    </ScrollArea>
                  </CardContent>
                </Card>
                
                <div className="flex justify-between">
                  <Badge variant="outline">
                    {selectedProducts.size} products selected
                  </Badge>
                  <Button
                    onClick={applyBulkDescriptions}
                    disabled={!backupCreated || selectedProducts.size === 0 || !descriptionTemplate || loading}
                  >
                    {loading ? 'Updating...' : 'Apply Descriptions'}
                  </Button>
                </div>
              </div>
            </CardContent>
          </Card>
        </TabsContent>

        {/* IMAGE MATCHING */}
        <TabsContent value="images" className="space-y-4">
          <Card>
            <CardHeader>
              <CardTitle>Automated Image Matching</CardTitle>
            </CardHeader>
            <CardContent className="space-y-4">
              <div className="space-y-4">
                <div>
                  <label className="text-sm font-medium">Image URL Pattern</label>
                  <Input
                    placeholder="https://cdn.example.com/products/{sku}.jpg"
                    value={imageUrlPattern}
                    onChange={(e) => setImageUrlPattern(e.target.value)}
                    className="font-mono"
                  />
                  <p className="text-xs text-muted-foreground mt-1">
                    Use {'{sku}'} as placeholder for product SKU or name
                  </p>
                </div>
                
                <Button onClick={findImageMatches} disabled={loading}>
                  <Search className="h-4 w-4 mr-2" />
                  Find Image Matches
                </Button>
                
                {imageMatches.length > 0 && (
                  <>
                    <div className="flex justify-between items-center">
                      <span className="text-sm text-muted-foreground">
                        Found {imageMatches.length} products with image suggestions
                      </span>
                      <Button
                        onClick={applyAllHighConfidenceMatches}
                        variant="outline"
                        disabled={loading}
                      >
                        Apply High Confidence Matches
                      </Button>
                    </div>
                    
                    <ScrollArea className="h-[400px]">
                      <div className="space-y-4">
                        {imageMatches.map(match => (
                          <Card key={match.productId}>
                            <CardContent className="p-4">
                              <div className="space-y-2">
                                <div className="flex items-center justify-between">
                                  <span className="font-medium">{match.productName}</span>
                                  <Badge variant={match.confidence >= 0.8 ? 'default' : 'secondary'}>
                                    {Math.round(match.confidence * 100)}% confidence
                                  </Badge>
                                </div>
                                
                                {match.currentImage && (
                                  <div className="text-sm text-muted-foreground">
                                    Current: {match.currentImage}
                                  </div>
                                )}
                                
                                <div className="space-y-1">
                                  <p className="text-sm font-medium">Suggested Images:</p>
                                  {match.suggestedImages.map((url, idx) => (
                                    <div key={idx} className="flex items-center gap-2">
                                      <code className="text-xs flex-1">{url}</code>
                                      <Button
                                        size="sm"
                                        variant="outline"
                                        onClick={() => applyImageMatch(match, url)}
                                      >
                                        Apply
                                      </Button>
                                    </div>
                                  ))}
                                </div>
                              </div>
                            </CardContent>
                          </Card>
                        ))}
                      </div>
                    </ScrollArea>
                  </>
                )}
              </div>
            </CardContent>
          </Card>
        </TabsContent>

        {/* VALIDATION */}
        <TabsContent value="validation" className="space-y-4">
          <Card>
            <CardHeader>
              <CardTitle>Product Validation Tool</CardTitle>
            </CardHeader>
            <CardContent className="space-y-4">
              <div className="flex gap-4">
                <Button onClick={validateProducts} disabled={loading}>
                  <Shield className="h-4 w-4 mr-2" />
                  Validate All Products
                </Button>
                
                {validationIssues.length > 0 && (
                  <>
                    <Button
                      onClick={autoFixIssues}
                      variant="outline"
                      disabled={!backupCreated || loading}
                    >
                      <Wand2 className="h-4 w-4 mr-2" />
                      Auto-Fix Issues
                    </Button>
                    <Button
                      onClick={exportValidationReport}
                      variant="outline"
                    >
                      <Download className="h-4 w-4 mr-2" />
                      Export Report
                    </Button>
                  </>
                )}
              </div>
              
              {validationProgress > 0 && validationProgress < 100 && (
                <Progress value={validationProgress} />
              )}
              
              {validationIssues.length > 0 && (
                <div className="space-y-4">
                  <div className="flex gap-4">
                    <Badge variant="destructive">
                      {validationIssues.filter(i => i.severity === 'error').length} Errors
                    </Badge>
                    <Badge variant="secondary">
                      {validationIssues.filter(i => i.severity === 'warning').length} Warnings
                    </Badge>
                    <Badge variant="outline">
                      {validationIssues.filter(i => i.severity === 'info').length} Info
                    </Badge>
                  </div>
                  
                  <ScrollArea className="h-[400px]">
                    <div className="space-y-2">
                      {validationIssues.map((issue, idx) => (
                        <Card key={idx} className={
                          issue.severity === 'error' ? 'border-red-500' :
                          issue.severity === 'warning' ? 'border-yellow-500' :
                          'border-blue-500'
                        }>
                          <CardContent className="p-3">
                            <div className="flex items-start gap-2">
                              {issue.severity === 'error' ? (
                                <XCircle className="h-4 w-4 text-red-500 mt-0.5" />
                              ) : issue.severity === 'warning' ? (
                                <AlertTriangle className="h-4 w-4 text-yellow-500 mt-0.5" />
                              ) : (
                                <AlertCircle className="h-4 w-4 text-blue-500 mt-0.5" />
                              )}
                              <div className="flex-1">
                                <p className="font-medium text-sm">{issue.productName}</p>
                                <p className="text-sm text-muted-foreground">
                                  {issue.field}: {issue.issue}
                                </p>
                                {issue.suggestion && (
                                  <p className="text-xs text-muted-foreground mt-1">
                                    💡 {issue.suggestion}
                                  </p>
                                )}
                              </div>
                            </div>
                          </CardContent>
                        </Card>
                      ))}
                    </div>
                  </ScrollArea>
                </div>
              )}
              
              {validationIssues.length === 0 && validationProgress === 100 && (
                <Alert className="bg-green-50">
                  <CheckCircle2 className="h-4 w-4 text-green-600" />
                  <AlertDescription>
                    All products passed validation! Your catalog is in great shape.
                  </AlertDescription>
                </Alert>
              )}
            </CardContent>
          </Card>
        </TabsContent>
      </Tabs>
    </div>
  );
}