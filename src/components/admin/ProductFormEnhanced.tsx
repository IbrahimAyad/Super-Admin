/**
 * ENHANCED PRODUCT FORM WITH AI FEATURES
 * Integrates KCT Intelligence for smart product management
 */

import React, { useState, useEffect } from 'react';
import { Button } from '@/components/ui/button';
import { Textarea } from '@/components/ui/textarea';
import { Input } from '@/components/ui/input';
import { Label } from '@/components/ui/label';
import { Tabs, TabsContent, TabsList, TabsTrigger } from '@/components/ui/tabs';
import { Badge } from '@/components/ui/badge';
import { Progress } from '@/components/ui/progress';
import { toast } from 'sonner';
import { kctIntelligence } from '@/lib/services/kctIntelligence';
import { 
  Sparkles, 
  Wand2, 
  CheckCircle, 
  AlertCircle, 
  Brain,
  Zap,
  Loader2
} from 'lucide-react';

interface ProductFormEnhancedProps {
  formData: any;
  setFormData: (data: any) => void;
  onSave: () => void;
  isEditMode?: boolean;
}

export function ProductFormEnhanced({ 
  formData, 
  setFormData, 
  onSave,
  isEditMode = false 
}: ProductFormEnhancedProps) {
  const [isGenerating, setIsGenerating] = useState(false);
  const [qualityScore, setQualityScore] = useState<number | null>(null);
  const [validationWarnings, setValidationWarnings] = useState<string[]>([]);
  const [aiSuggestions, setAiSuggestions] = useState<string[]>([]);

  // Generate AI Description
  const handleGenerateDescription = async () => {
    setIsGenerating(true);
    try {
      const result = await kctIntelligence.generateDescription({
        name: formData.name,
        category: formData.category,
        materials: formData.materials,
        occasion: formData.occasion,
        fit_type: formData.fit_type,
        features: formData.features
      });

      if (result.success && result.data) {
        setFormData(prev => ({
          ...prev,
          description: result.data.description,
          features: [...(prev.features || []), ...(result.data.key_features || [])]
        }));
        
        toast.success('AI Description Generated', {
          description: 'Review and customize as needed'
        });

        if (result.data.styling_tips) {
          setAiSuggestions(prev => [...prev, `Styling tip: ${result.data.styling_tips}`]);
        }
      }
    } catch (error) {
      toast.error('Failed to generate description');
    } finally {
      setIsGenerating(false);
    }
  };

  // Generate SEO Content
  const handleGenerateSEO = async () => {
    setIsGenerating(true);
    try {
      const result = await kctIntelligence.generateSEO({
        name: formData.name,
        category: formData.category,
        description: formData.description,
        features: formData.features
      });

      if (result.success && result.data) {
        setFormData(prev => ({
          ...prev,
          meta_title: result.data.meta_title,
          meta_description: result.data.meta_description,
          url_slug: result.data.suggested_slug,
          seo_keywords: result.data.keywords
        }));
        
        toast.success('SEO Content Generated');
      }
    } catch (error) {
      toast.error('Failed to generate SEO content');
    } finally {
      setIsGenerating(false);
    }
  };

  // Validate Product Data
  const validateProduct = async () => {
    const result = await kctIntelligence.validateProduct(formData);
    
    if (result.success && result.data) {
      setQualityScore(result.data.quality_score);
      setValidationWarnings(result.data.warnings);
      setAiSuggestions(result.data.suggestions);
      
      if (result.data.errors.length > 0) {
        toast.error('Validation Errors', {
          description: result.data.errors.join(', ')
        });
      }
    }
  };

  // Smart Defaults
  const applySmartDefaults = async () => {
    if (!formData.name || !formData.category) return;
    
    const result = await kctIntelligence.getSmartDefaults({
      name: formData.name,
      category: formData.category,
      product_type: formData.product_type
    });

    if (result.success && result.data) {
      setFormData(prev => ({
        ...prev,
        materials: prev.materials?.length ? prev.materials : result.data.materials,
        care_instructions: prev.care_instructions || result.data.care_instructions,
        fit_type: prev.fit_type || result.data.fit_type,
        occasion: prev.occasion?.length ? prev.occasion : result.data.occasion,
        features: prev.features?.length ? prev.features : result.data.features
      }));
      
      toast.success('Smart defaults applied');
    }
  };

  // Auto-apply smart defaults when category changes
  useEffect(() => {
    if (formData.category && !isEditMode) {
      const timer = setTimeout(() => {
        applySmartDefaults();
      }, 1000);
      return () => clearTimeout(timer);
    }
  }, [formData.category]);

  // Validate on significant changes
  useEffect(() => {
    if (formData.name && formData.category && formData.description) {
      const timer = setTimeout(() => {
        validateProduct();
      }, 2000);
      return () => clearTimeout(timer);
    }
  }, [formData.name, formData.category, formData.description]);

  return (
    <div className="space-y-6">
      {/* Quality Score Display */}
      {qualityScore !== null && (
        <div className="bg-card p-4 rounded-lg border">
          <div className="flex items-center justify-between mb-2">
            <span className="text-sm font-medium">Product Quality Score</span>
            <Badge variant={qualityScore >= 80 ? "success" : qualityScore >= 60 ? "warning" : "destructive"}>
              {qualityScore}%
            </Badge>
          </div>
          <Progress value={qualityScore} className="h-2" />
          {validationWarnings.length > 0 && (
            <div className="mt-2 space-y-1">
              {validationWarnings.map((warning, i) => (
                <div key={i} className="flex items-center gap-2 text-xs text-yellow-600">
                  <AlertCircle className="h-3 w-3" />
                  {warning}
                </div>
              ))}
            </div>
          )}
        </div>
      )}

      <Tabs defaultValue="basic" className="w-full">
        <TabsList className="grid w-full grid-cols-6">
          <TabsTrigger value="basic">Basic</TabsTrigger>
          <TabsTrigger value="images">Images</TabsTrigger>
          <TabsTrigger value="variants">Variants</TabsTrigger>
          <TabsTrigger value="details">Details</TabsTrigger>
          <TabsTrigger value="seo">SEO</TabsTrigger>
          <TabsTrigger value="preview">Preview</TabsTrigger>
        </TabsList>

        {/* Basic Tab with AI Description */}
        <TabsContent value="basic" className="space-y-4">
          <div className="grid grid-cols-2 gap-4">
            <div>
              <Label htmlFor="sku">SKU *</Label>
              <Input
                id="sku"
                value={formData.sku}
                onChange={(e) => setFormData(prev => ({ ...prev, sku: e.target.value }))}
                placeholder="KCT-XXXX"
              />
            </div>
            <div>
              <Label htmlFor="name">Product Name *</Label>
              <Input
                id="name"
                value={formData.name}
                onChange={(e) => setFormData(prev => ({ ...prev, name: e.target.value }))}
                placeholder="Enter product name"
              />
            </div>
          </div>

          <div className="grid grid-cols-2 gap-4">
            <div>
              <Label htmlFor="category">Category *</Label>
              <Input
                id="category"
                value={formData.category}
                onChange={(e) => setFormData(prev => ({ ...prev, category: e.target.value }))}
                placeholder="e.g., Suits, Shirts"
              />
            </div>
            <div>
              <Label htmlFor="product_type">Product Type</Label>
              <Input
                id="product_type"
                value={formData.product_type}
                onChange={(e) => setFormData(prev => ({ ...prev, product_type: e.target.value }))}
                placeholder="e.g., Two-piece, Dress Shirt"
              />
            </div>
          </div>

          <div>
            <div className="flex items-center justify-between mb-2">
              <Label htmlFor="description">Description</Label>
              <Button
                type="button"
                size="sm"
                variant="outline"
                onClick={handleGenerateDescription}
                disabled={isGenerating || !formData.name || !formData.category}
              >
                {isGenerating ? (
                  <Loader2 className="h-4 w-4 mr-2 animate-spin" />
                ) : (
                  <Sparkles className="h-4 w-4 mr-2" />
                )}
                Generate with AI
              </Button>
            </div>
            <Textarea
              id="description"
              value={formData.description}
              onChange={(e) => setFormData(prev => ({ ...prev, description: e.target.value }))}
              placeholder="Enter detailed product description"
              rows={6}
              className="resize-none"
            />
          </div>

          {/* AI Suggestions */}
          {aiSuggestions.length > 0 && (
            <div className="bg-blue-50 dark:bg-blue-950 p-3 rounded-lg">
              <div className="flex items-center gap-2 mb-2">
                <Brain className="h-4 w-4 text-blue-600" />
                <span className="text-sm font-medium">AI Suggestions</span>
              </div>
              <ul className="space-y-1">
                {aiSuggestions.map((suggestion, i) => (
                  <li key={i} className="text-xs text-blue-700 dark:text-blue-300">
                    • {suggestion}
                  </li>
                ))}
              </ul>
            </div>
          )}
        </TabsContent>

        {/* SEO Tab with AI Generation */}
        <TabsContent value="seo" className="space-y-4">
          <div className="flex justify-end mb-4">
            <Button
              type="button"
              size="sm"
              variant="outline"
              onClick={handleGenerateSEO}
              disabled={isGenerating || !formData.name}
            >
              {isGenerating ? (
                <Loader2 className="h-4 w-4 mr-2 animate-spin" />
              ) : (
                <Wand2 className="h-4 w-4 mr-2" />
              )}
              Generate SEO Content
            </Button>
          </div>

          <div>
            <Label htmlFor="meta_title">Meta Title</Label>
            <Input
              id="meta_title"
              value={formData.meta_title}
              onChange={(e) => setFormData(prev => ({ ...prev, meta_title: e.target.value }))}
              placeholder="SEO title (60 characters max)"
              maxLength={60}
            />
            <span className="text-xs text-muted-foreground">
              {formData.meta_title?.length || 0}/60 characters
            </span>
          </div>

          <div>
            <Label htmlFor="meta_description">Meta Description</Label>
            <Textarea
              id="meta_description"
              value={formData.meta_description}
              onChange={(e) => setFormData(prev => ({ ...prev, meta_description: e.target.value }))}
              placeholder="SEO description (160 characters max)"
              maxLength={160}
              rows={3}
            />
            <span className="text-xs text-muted-foreground">
              {formData.meta_description?.length || 0}/160 characters
            </span>
          </div>

          <div>
            <Label htmlFor="url_slug">URL Slug</Label>
            <Input
              id="url_slug"
              value={formData.url_slug}
              onChange={(e) => setFormData(prev => ({ ...prev, url_slug: e.target.value }))}
              placeholder="product-url-slug"
            />
          </div>

          {formData.seo_keywords?.length > 0 && (
            <div>
              <Label>Keywords</Label>
              <div className="flex flex-wrap gap-2 mt-2">
                {formData.seo_keywords.map((keyword, i) => (
                  <Badge key={i} variant="secondary">
                    {keyword}
                  </Badge>
                ))}
              </div>
            </div>
          )}
        </TabsContent>

        {/* Other tabs remain the same */}
        <TabsContent value="images">
          {/* Existing image management */}
        </TabsContent>

        <TabsContent value="variants">
          {/* Existing variant management */}
        </TabsContent>

        <TabsContent value="details">
          {/* Existing detail fields */}
        </TabsContent>

        <TabsContent value="preview">
          {/* Existing preview */}
        </TabsContent>
      </Tabs>

      {/* Smart Actions Bar */}
      <div className="flex items-center justify-between p-4 bg-muted rounded-lg">
        <div className="flex items-center gap-4">
          <Button
            type="button"
            size="sm"
            variant="ghost"
            onClick={applySmartDefaults}
          >
            <Zap className="h-4 w-4 mr-2" />
            Apply Smart Defaults
          </Button>
          <Button
            type="button"
            size="sm"
            variant="ghost"
            onClick={validateProduct}
          >
            <CheckCircle className="h-4 w-4 mr-2" />
            Validate Product
          </Button>
        </div>
        <Button onClick={onSave}>
          {isEditMode ? 'Update Product' : 'Create Product'}
        </Button>
      </div>
    </div>
  );
}