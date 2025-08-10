/**
 * QUICK PRODUCT ADD FORM
 * Streamlined interface for fast product creation
 * Pre-fills common data and validates in real-time
 */

import React, { useState, useEffect } from 'react';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { Textarea } from '@/components/ui/textarea';
import { Label } from '@/components/ui/label';
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from '@/components/ui/select';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Badge } from '@/components/ui/badge';
import { Switch } from '@/components/ui/switch';
import { Progress } from '@/components/ui/progress';
import { Separator } from '@/components/ui/separator';
import { toast } from 'sonner';
import { supabase } from '@/lib/supabase-client';
import { productCache } from '@/lib/cache';
import { 
  Save, 
  Zap, 
  CheckCircle, 
  AlertTriangle, 
  Copy,
  Wand2,
  DollarSign,
  Package,
  Tag,
  FileText
} from 'lucide-react';

interface ProductQuickAddProps {
  onSave?: (productId: string) => void;
  onCancel?: () => void;
  defaultCategory?: string;
  defaultData?: Partial<any>;
}

// Common product templates for quick setup
const PRODUCT_TEMPLATES = {
  'Men\'s Suits': {
    base_price: 199.99,
    sizes: ['34R', '36R', '38R', '40R', '42R', '44R', '46R'],
    description: 'Premium quality suit with modern fit and classic styling.',
    features: ['Modern Fit', 'Premium Fabric', 'Professional Styling']
  },
  'Dress Shirts': {
    base_price: 49.99,
    sizes: ['S', 'M', 'L', 'XL', 'XXL'],
    description: 'Crisp dress shirt perfect for business and formal occasions.',
    features: ['Wrinkle Resistant', 'Cotton Blend', 'Classic Collar']
  },
  'Ties': {
    base_price: 19.99,
    sizes: ['One Size'],
    description: 'Elegant tie to complement any formal outfit.',
    features: ['Silk Material', 'Classic Width', 'Hand-finished']
  },
  'Accessories': {
    base_price: 29.99,
    sizes: ['One Size'],
    description: 'Essential accessory to complete your formal look.',
    features: ['Premium Quality', 'Versatile Design', 'Durable']
  }
};

// SKU generation patterns
const SKU_PATTERNS = {
  'Men\'s Suits': (name: string) => `MS-${name.substring(0, 3).toUpperCase()}-${Date.now().toString().slice(-4)}`,
  'Dress Shirts': (name: string) => `DS-${name.substring(0, 3).toUpperCase()}-${Date.now().toString().slice(-4)}`,
  'Ties': (name: string) => `TIE-${name.substring(0, 3).toUpperCase()}-${Date.now().toString().slice(-4)}`,
  'Accessories': (name: string) => `ACC-${name.substring(0, 3).toUpperCase()}-${Date.now().toString().slice(-4)}`
};

export function ProductQuickAdd({ onSave, onCancel, defaultCategory, defaultData }: ProductQuickAddProps) {
  const [formData, setFormData] = useState({
    name: '',
    category: defaultCategory || '',
    base_price: '',
    sku: '',
    description: '',
    status: 'active',
    ...defaultData
  });

  const [validationScore, setValidationScore] = useState(0);
  const [validationIssues, setValidationIssues] = useState<string[]>([]);
  const [isSaving, setIsSaving] = useState(false);
  const [useTemplate, setUseTemplate] = useState(true);
  const [duplicateCheck, setDuplicateCheck] = useState({ checked: false, duplicates: [] });

  // Auto-generate SKU when name or category changes
  useEffect(() => {
    if (formData.name && formData.category && !formData.sku.includes('MANUAL')) {
      const pattern = SKU_PATTERNS[formData.category as keyof typeof SKU_PATTERNS];
      if (pattern) {
        setFormData(prev => ({
          ...prev,
          sku: pattern(formData.name)
        }));
      }
    }
  }, [formData.name, formData.category]);

  // Apply template when category changes
  useEffect(() => {
    if (formData.category && useTemplate) {
      const template = PRODUCT_TEMPLATES[formData.category as keyof typeof PRODUCT_TEMPLATES];
      if (template) {
        setFormData(prev => ({
          ...prev,
          base_price: prev.base_price || template.base_price.toString(),
          description: prev.description || template.description
        }));
      }
    }
  }, [formData.category, useTemplate]);

  // Real-time validation
  useEffect(() => {
    validateForm();
  }, [formData]);

  // Check for duplicates
  useEffect(() => {
    if (formData.name && formData.name.length > 3) {
      checkDuplicates();
    }
  }, [formData.name]);

  const validateForm = () => {
    const issues: string[] = [];
    let score = 0;

    // Name validation
    if (formData.name.length > 0) score += 20;
    else issues.push('Product name is required');
    
    if (formData.name.length > 10) score += 10;
    else if (formData.name) issues.push('Name should be more descriptive');

    // Category validation
    if (formData.category) score += 20;
    else issues.push('Category is required');

    // Price validation
    if (formData.base_price && parseFloat(formData.base_price) > 0) score += 20;
    else issues.push('Valid price is required');

    // SKU validation
    if (formData.sku) score += 15;
    else issues.push('SKU is required');

    // Description validation
    if (formData.description) score += 10;
    if (formData.description.length > 50) score += 5;
    else if (formData.description) issues.push('Description should be more detailed');

    setValidationScore(score);
    setValidationIssues(issues);
  };

  const checkDuplicates = async () => {
    try {
      const { data, error } = await supabase
        .from('products')
        .select('id, name, sku')
        .or(`name.ilike.%${formData.name}%,sku.eq.${formData.sku}`)
        .limit(3);

      if (!error && data) {
        setDuplicateCheck({
          checked: true,
          duplicates: data.filter(p => 
            p.name.toLowerCase().includes(formData.name.toLowerCase()) ||
            p.sku === formData.sku
          )
        });
      }
    } catch (error) {
      console.error('Duplicate check failed:', error);
    }
  };

  const handleApplyTemplate = () => {
    if (formData.category) {
      const template = PRODUCT_TEMPLATES[formData.category as keyof typeof PRODUCT_TEMPLATES];
      if (template) {
        setFormData(prev => ({
          ...prev,
          base_price: template.base_price.toString(),
          description: template.description
        }));
        toast.success('Template applied');
      }
    }
  };

  const handleSave = async () => {
    if (validationScore < 70) {
      toast.error('Please fix validation issues before saving');
      return;
    }

    if (duplicateCheck.duplicates.length > 0) {
      const confirmed = window.confirm(
        `Found ${duplicateCheck.duplicates.length} similar products. Continue anyway?`
      );
      if (!confirmed) return;
    }

    setIsSaving(true);
    
    try {
      // Create the product
      const productData = {
        ...formData,
        base_price: parseFloat(formData.base_price),
        created_at: new Date().toISOString(),
        updated_at: new Date().toISOString()
      };

      const { data: product, error: productError } = await supabase
        .from('products')
        .insert(productData)
        .select()
        .single();

      if (productError) throw productError;

      // Create default variants if it's a sized product
      if (formData.category && PRODUCT_TEMPLATES[formData.category as keyof typeof PRODUCT_TEMPLATES]) {
        const template = PRODUCT_TEMPLATES[formData.category as keyof typeof PRODUCT_TEMPLATES];
        const variants = template.sizes.map((size, index) => ({
          product_id: product.id,
          name: `${formData.name} - ${size}`,
          sku: `${formData.sku}-${size}`,
          price: parseFloat(formData.base_price),
          size,
          inventory_quantity: 0,
          status: 'active',
          created_at: new Date().toISOString(),
          updated_at: new Date().toISOString()
        }));

        const { error: variantsError } = await supabase
          .from('product_variants')
          .insert(variants);

        if (variantsError) {
          console.error('Failed to create variants:', variantsError);
          // Don't fail the whole operation for variant errors
        }
      }

      // Clear cache to ensure fresh data
      productCache.clearAll();

      toast.success('Product created successfully');
      onSave?.(product.id);
      
    } catch (error) {
      console.error('Save error:', error);
      toast.error('Failed to save product');
    } finally {
      setIsSaving(false);
    }
  };

  const getValidationColor = () => {
    if (validationScore >= 85) return 'text-green-600';
    if (validationScore >= 70) return 'text-yellow-600';
    return 'text-red-600';
  };

  return (
    <div className="max-w-4xl mx-auto space-y-6">
      {/* Header */}
      <div className="flex items-center justify-between">
        <div>
          <h2 className="text-2xl font-bold">Quick Add Product</h2>
          <p className="text-muted-foreground">Fast product creation with smart defaults</p>
        </div>
        
        {/* Validation Score */}
        <Card className="w-64">
          <CardContent className="p-4">
            <div className="flex items-center justify-between mb-2">
              <span className="text-sm font-medium">Completion</span>
              <span className={`text-sm font-bold ${getValidationColor()}`}>
                {validationScore}%
              </span>
            </div>
            <Progress value={validationScore} className="h-2" />
          </CardContent>
        </Card>
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
        {/* Main Form */}
        <div className="lg:col-span-2 space-y-6">
          <Card>
            <CardHeader>
              <CardTitle className="flex items-center gap-2">
                <Package className="h-5 w-5" />
                Basic Information
              </CardTitle>
            </CardHeader>
            <CardContent className="space-y-4">
              {/* Product Name */}
              <div>
                <Label htmlFor="name">Product Name *</Label>
                <Input
                  id="name"
                  value={formData.name}
                  onChange={(e) => setFormData(prev => ({ ...prev, name: e.target.value }))}
                  placeholder="e.g., Classic Black Tuxedo"
                  className="mt-1"
                />
              </div>

              {/* Category and Template Toggle */}
              <div className="grid grid-cols-2 gap-4">
                <div>
                  <Label htmlFor="category">Category *</Label>
                  <Select
                    value={formData.category}
                    onValueChange={(value) => setFormData(prev => ({ ...prev, category: value }))}
                  >
                    <SelectTrigger className="mt-1">
                      <SelectValue placeholder="Select category" />
                    </SelectTrigger>
                    <SelectContent>
                      {Object.keys(PRODUCT_TEMPLATES).map(category => (
                        <SelectItem key={category} value={category}>
                          {category}
                        </SelectItem>
                      ))}
                    </SelectContent>
                  </Select>
                </div>

                <div className="flex items-end">
                  <div className="flex items-center space-x-2">
                    <Switch
                      id="template"
                      checked={useTemplate}
                      onCheckedChange={setUseTemplate}
                    />
                    <Label htmlFor="template" className="text-sm">Auto-template</Label>
                    {formData.category && (
                      <Button
                        type="button"
                        variant="outline"
                        size="sm"
                        onClick={handleApplyTemplate}
                      >
                        <Wand2 className="h-4 w-4" />
                      </Button>
                    )}
                  </div>
                </div>
              </div>

              {/* SKU and Price */}
              <div className="grid grid-cols-2 gap-4">
                <div>
                  <Label htmlFor="sku">SKU *</Label>
                  <div className="flex mt-1">
                    <Input
                      id="sku"
                      value={formData.sku}
                      onChange={(e) => setFormData(prev => ({ ...prev, sku: e.target.value.toUpperCase() }))}
                      placeholder="Auto-generated"
                    />
                    <Button
                      type="button"
                      variant="outline"
                      size="sm"
                      className="ml-2"
                      onClick={() => {
                        const manual = `MANUAL-${Date.now().toString().slice(-6)}`;
                        setFormData(prev => ({ ...prev, sku: manual }));
                      }}
                    >
                      <Copy className="h-4 w-4" />
                    </Button>
                  </div>
                </div>

                <div>
                  <Label htmlFor="price">Base Price *</Label>
                  <div className="relative mt-1">
                    <DollarSign className="absolute left-3 top-1/2 transform -translate-y-1/2 h-4 w-4 text-muted-foreground" />
                    <Input
                      id="price"
                      type="number"
                      step="0.01"
                      min="0"
                      value={formData.base_price}
                      onChange={(e) => setFormData(prev => ({ ...prev, base_price: e.target.value }))}
                      className="pl-10"
                      placeholder="0.00"
                    />
                  </div>
                </div>
              </div>

              {/* Description */}
              <div>
                <Label htmlFor="description">Description</Label>
                <Textarea
                  id="description"
                  value={formData.description}
                  onChange={(e) => setFormData(prev => ({ ...prev, description: e.target.value }))}
                  placeholder="Detailed product description..."
                  rows={3}
                  className="mt-1"
                />
              </div>
            </CardContent>
          </Card>
        </div>

        {/* Sidebar */}
        <div className="space-y-6">
          {/* Validation Issues */}
          {validationIssues.length > 0 && (
            <Card>
              <CardHeader>
                <CardTitle className="flex items-center gap-2 text-sm">
                  <AlertTriangle className="h-4 w-4" />
                  Issues to Fix
                </CardTitle>
              </CardHeader>
              <CardContent>
                <ul className="space-y-1">
                  {validationIssues.slice(0, 5).map((issue, index) => (
                    <li key={index} className="text-xs text-muted-foreground flex items-start gap-2">
                      <div className="w-1 h-1 rounded-full bg-red-500 mt-2 flex-shrink-0" />
                      {issue}
                    </li>
                  ))}
                </ul>
              </CardContent>
            </Card>
          )}

          {/* Duplicate Check */}
          {duplicateCheck.duplicates.length > 0 && (
            <Card className="border-yellow-200">
              <CardHeader>
                <CardTitle className="flex items-center gap-2 text-sm text-yellow-600">
                  <AlertTriangle className="h-4 w-4" />
                  Similar Products Found
                </CardTitle>
              </CardHeader>
              <CardContent>
                <ul className="space-y-1">
                  {duplicateCheck.duplicates.map((dup) => (
                    <li key={dup.id} className="text-xs">
                      <Badge variant="outline" className="text-xs">
                        {dup.name} ({dup.sku})
                      </Badge>
                    </li>
                  ))}
                </ul>
              </CardContent>
            </Card>
          )}

          {/* Template Info */}
          {formData.category && PRODUCT_TEMPLATES[formData.category as keyof typeof PRODUCT_TEMPLATES] && (
            <Card>
              <CardHeader>
                <CardTitle className="flex items-center gap-2 text-sm">
                  <Tag className="h-4 w-4" />
                  Template Applied
                </CardTitle>
              </CardHeader>
              <CardContent className="text-xs text-muted-foreground">
                <p>Auto-configured for {formData.category}</p>
                <p className="mt-1">
                  Will create {PRODUCT_TEMPLATES[formData.category as keyof typeof PRODUCT_TEMPLATES].sizes.length} size variants
                </p>
              </CardContent>
            </Card>
          )}
        </div>
      </div>

      {/* Actions */}
      <div className="flex items-center justify-between pt-4 border-t">
        <Button variant="outline" onClick={onCancel}>
          Cancel
        </Button>
        
        <div className="flex items-center gap-2">
          <Badge variant={validationScore >= 70 ? "default" : "destructive"}>
            {validationScore >= 70 ? 'Ready to Save' : 'Needs Work'}
          </Badge>
          
          <Button 
            onClick={handleSave}
            disabled={isSaving || validationScore < 70}
            className="min-w-32"
          >
            {isSaving ? (
              <>
                <div className="animate-spin rounded-full h-4 w-4 border-b-2 border-white mr-2" />
                Saving...
              </>
            ) : (
              <>
                <Save className="h-4 w-4 mr-2" />
                Save Product
              </>
            )}
          </Button>
        </div>
      </div>
    </div>
  );
}