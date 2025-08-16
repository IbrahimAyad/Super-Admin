import React from 'react';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { Label } from '@/components/ui/label';
import { Textarea } from '@/components/ui/textarea';
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from '@/components/ui/select';
import { Badge } from '@/components/ui/badge';
import { Checkbox } from '@/components/ui/checkbox';
import { Tabs, TabsContent, TabsList, TabsTrigger } from '@/components/ui/tabs';
import { Card, CardContent } from '@/components/ui/card';
import { Progress } from '@/components/ui/progress';
import { useToast } from '@/hooks/use-toast';
import { 
  Package, 
  Image, 
  Ruler, 
  Shirt, 
  Globe, 
  Eye, 
  Palette,
  Clock,
  AlertTriangle,
  Tag,
  X,
  DollarSign,
  Trash2
} from 'lucide-react';
import { Table, TableBody, TableCell, TableHead, TableHeader, TableRow } from '@/components/ui/table';
import { DraggableImageGallery } from '../DraggableImageGallery';
import { fashionClip, type ImageAnalysisResult } from '@/lib/services/fashionClip';
import { kctIntelligence } from '@/lib/services/kctIntelligence';
import { Product } from '@/lib/services';

interface ProductFormData {
  // Basic Info
  sku: string;
  name: string;
  description: string;
  category: string;
  product_type: 'core' | 'catalog';
  base_price: number;
  stripe_product_id?: string;
  status: 'active' | 'inactive' | 'archived';
  is_bundleable: boolean;
  
  // Images
  images: ProductImage[];
  
  // Colors & Sizes
  available_colors: string[];
  variants: ProductVariant[];
  
  // Materials & Attributes
  materials: string;
  care_instructions: string;
  fit_type: string;
  occasion: string;
  features: string[];
  
  // SEO
  meta_title: string;
  meta_description: string;
  url_slug: string;
}

interface ProductVariant {
  id?: string;
  size: string;
  color: string;
  sku: string;
  price: number;
  stock_quantity: number;
  image_url?: string;
  barcode?: string;
  weight?: number;
  cost_price?: number;
  compare_at_price?: number;
  inventory_policy?: 'deny' | 'continue';
  status?: 'active' | 'inactive' | 'archived';
  position?: number;
}

interface ProductImage {
  id?: string;
  url: string;
  alt_text?: string;
  position: number;
  is_primary?: boolean;
  image_type?: 'primary' | 'gallery' | 'thumbnail' | 'detail';
  loading?: boolean;
  error?: boolean;
}

interface ProductFormProps {
  product?: Product | null;
  isOpen: boolean;
  onClose: () => void;
  onSubmit: (productData: Partial<Product>) => Promise<void>;
  categories: string[];
}

const productTypes = [
  '3-piece-suit',
  '2-piece-suit',
  'blazer',
  'dress-shirt',
  'casual-shirt',
  'trousers',
  'vest',
  'tie',
  'pocket-square',
  'cufflinks',
  'shoes'
];

const availableColors = [
  'Navy', 'Black', 'Charcoal', 'Grey', 'Brown', 'White', 'Blue', 
  'Burgundy', 'Green', 'Beige', 'Tan', 'Cream', 'Silver'
];

const fitTypes = [
  'Slim Fit', 'Classic Fit', 'Regular Fit', 'Tailored Fit', 'Modern Fit'
];

const occasions = [
  'Business', 'Formal', 'Wedding', 'Casual', 'Evening', 'Special Events'
];

const commonFeatures = [
  'Wrinkle Resistant', 'Moisture Wicking', 'Stretch Fabric', 'Easy Care',
  'Breathable', 'Stain Resistant', 'Non-Iron', 'Quick Dry'
];

export const ProductForm = React.memo(function ProductForm({ product, isOpen, onClose, onSubmit, categories }: ProductFormProps) {
  const { toast } = useToast();
  const [formData, setFormData] = React.useState<ProductFormData>({
    sku: '',
    name: '',
    description: '',
    category: '',
    product_type: 'catalog',
    base_price: 0,
    stripe_product_id: '',
    status: 'active',
    is_bundleable: true,
    images: [],
    available_colors: [],
    variants: [],
    materials: '',
    care_instructions: '',
    fit_type: '',
    occasion: '',
    features: [],
    meta_title: '',
    meta_description: '',
    url_slug: ''
  });

  // Size options for suit-type products (blazers, suits, tuxedos)
  const [sizeOptions, setSizeOptions] = React.useState({
    regular: true,
    short: false,
    long: false
  });

  // AI Analysis state
  const [aiAnalyzing, setAiAnalyzing] = React.useState(false);
  const [analysisResults, setAnalysisResults] = React.useState<ImageAnalysisResult | null>(null);
  const [validationResults, setValidationResults] = React.useState<any>(null);
  const [generatingContent, setGeneratingContent] = React.useState(false);

  // Initialize form data when product changes
  React.useEffect(() => {
    if (product) {
      // Convert product images to form format
      const productImages: ProductImage[] = product.images?.map((img: any, index: number) => ({
        id: img.id,
        url: img.image_url || img.url || '',
        alt_text: img.alt_text || '',
        position: img.position || index,
        is_primary: img.image_type === 'primary' || index === 0,
        image_type: img.image_type || (index === 0 ? 'primary' : 'gallery')
      })) || [];

      setFormData({
        sku: product.sku || '',
        name: product.name,
        description: product.description || '',
        category: product.category,
        product_type: product.product_type,
        base_price: product.base_price,
        stripe_product_id: product.stripe_product_id || '',
        status: product.status,
        is_bundleable: product.is_bundleable,
        images: productImages,
        available_colors: [],
        variants: [],
        materials: '',
        care_instructions: '',
        fit_type: '',
        occasion: '',
        features: [],
        meta_title: '',
        meta_description: '',
        url_slug: ''
      });

      // Load existing size options if product has them
      if (product.size_options) {
        setSizeOptions(product.size_options);
      }
    } else {
      // Reset for new product
      setFormData({
        sku: '',
        name: '',
        description: '',
        category: '',
        product_type: 'catalog',
        base_price: 0,
        stripe_product_id: '',
        status: 'active',
        is_bundleable: true,
        images: [],
        available_colors: [],
        variants: [],
        materials: '',
        care_instructions: '',
        fit_type: '',
        occasion: '',
        features: [],
        meta_title: '',
        meta_description: '',
        url_slug: ''
      });
    }
  }, [product]);

  // Auto-generate URL slug from product name
  const generateSlug = (name: string) => {
    return name
      .toLowerCase()
      .replace(/[^a-z0-9]+/g, '-')
      .replace(/(^-|-$)/g, '');
  };

  // Check if product category uses jacket sizing (R/S/L system)
  const usesJacketSizing = (category: string): boolean => {
    const jacketCategories = [
      'Blazers',
      'Suits', 
      'Double-Breasted Suits',
      'Stretch Suits',
      'Tuxedos',
      'Sport Coats',
      'Dinner Jackets'
    ];
    return jacketCategories.some(cat => 
      category?.toLowerCase().includes(cat.toLowerCase())
    );
  };

  // Handle color selection
  const handleColorChange = (color: string, checked: boolean) => {
    setFormData(prev => ({
      ...prev,
      available_colors: checked 
        ? [...prev.available_colors, color]
        : prev.available_colors.filter(c => c !== color)
    }));
  };

  // Handle features selection
  const handleFeatureChange = (feature: string, checked: boolean) => {
    setFormData(prev => ({
      ...prev,
      features: checked 
        ? [...prev.features, feature]
        : prev.features.filter(f => f !== feature)
    }));
  };

  // Handle image changes from the draggable gallery
  const handleImagesChange = (newImages: ProductImage[]) => {
    setFormData(prev => ({
      ...prev,
      images: newImages
    }));
  };

  // Size template generation functions
  const generateSizeTemplate = (productType: string) => {
    const templates: Record<string, ProductVariant[]> = {
      '3-piece-suit': generateSuitSizes(true),
      '2-piece-suit': generateSuitSizes(false),
      'blazer': generateBlazerSizes(),
      'dress-shirt': generateDressShirtSizes()
    };
    
    return templates[productType] || [];
  };

  const generateSuitSizes = (isThreePiece: boolean): ProductVariant[] => {
    const jacketSizes = [36, 38, 40, 42, 44, 46, 48, 50, 52, 54]; // Start at 36 for suits
    const lengths = [];
    
    // Only include enabled size options
    if (sizeOptions.short) lengths.push('S');
    if (sizeOptions.regular) lengths.push('R');
    if (sizeOptions.long) lengths.push('L');
    
    // Default to Regular if nothing selected
    if (lengths.length === 0) lengths.push('R');
    
    const variants: ProductVariant[] = [];

    jacketSizes.forEach(size => {
      lengths.forEach(length => {
        // Check availability based on length restrictions
        if (length === 'S' && size > 50) return;
        if (length === 'L' && size < 36) return;

        const jacketSize = `${size}${length}`;
        const pantSize = `${size - 6}W`; // 6 drop for pants
        
        // Jacket variant
        variants.push({
          size: jacketSize,
          color: 'Navy', // Default color
          sku: `JACKET-${jacketSize}-NAV`,
          price: formData.base_price,
          stock_quantity: 0
        });

        // Pants variant
        variants.push({
          size: `${jacketSize} + ${pantSize}`,
          color: 'Navy',
          sku: `PANTS-${pantSize}-NAV`,
          price: 0, // Usually included with jacket
          stock_quantity: 0
        });

        // Vest variant for 3-piece suits
        if (isThreePiece) {
          variants.push({
            size: jacketSize,
            color: 'Navy',
            sku: `VEST-${jacketSize}-NAV`,
            price: 0, // Usually included
            stock_quantity: 0
          });
        }
      });
    });

    return variants;
  };

  const generateBlazerSizes = (): ProductVariant[] => {
    const jacketSizes = [36, 38, 40, 42, 44, 46, 48, 50, 52, 54]; // No 34 for blazers
    const lengths = [];
    
    // Only include enabled size options
    if (sizeOptions.short) lengths.push('S');
    if (sizeOptions.regular) lengths.push('R');
    if (sizeOptions.long) lengths.push('L');
    
    // Default to Regular if nothing selected
    if (lengths.length === 0) lengths.push('R');
    
    const variants: ProductVariant[] = [];

    jacketSizes.forEach(size => {
      lengths.forEach(length => {
        // Check availability based on length restrictions
        if (length === 'S' && size > 50) return;
        if (length === 'L' && size < 36) return;

        const blazerSize = `${size}${length}`;
        
        variants.push({
          size: blazerSize,
          color: 'Navy', // Default color
          sku: `BLAZER-${blazerSize}-NAV`,
          price: formData.base_price,
          stock_quantity: 0
        });
      });
    });

    return variants;
  };

  const generateDressShirtSizes = (): ProductVariant[] => {
    const variants: ProductVariant[] = [];
    
    // Slim Fit Sizes
    const slimFitSizes = [
      { neck: '15"', size: 'S' },
      { neck: '15.5"', size: 'M' },
      { neck: '16"', size: 'L' },
      { neck: '16.5"', size: 'XL' },
      { neck: '17"', size: 'XXL' }
    ];

    slimFitSizes.forEach(({ neck, size }) => {
      variants.push({
        size: `${neck} Slim ${size}`,
        color: 'White', // Default color
        sku: `SHIRT-SLIM-${neck.replace('"', '')}-WHT`,
        price: formData.base_price,
        stock_quantity: 0
      });
    });

    // Classic Fit Sizes
    const classicFitNecks = ['15"', '15.5"', '16"', '16.5"', '17"', '17.5"', '18"', '18.5"', '19"', '19.5"', '20"', '22"'];
    const sleeveLengths = ['32-33', '34-35', '36-37'];

    classicFitNecks.forEach(neck => {
      sleeveLengths.forEach(sleeve => {
        variants.push({
          size: `${neck} ${sleeve} Classic`,
          color: 'White',
          sku: `SHIRT-CLASSIC-${neck.replace('"', '')}-${sleeve.replace('-', '')}-WHT`,
          price: formData.base_price,
          stock_quantity: 0
        });
      });
    });

    return variants;
  };

  const handleApplySizeTemplate = () => {
    const templateVariants = generateSizeTemplate(formData.product_type);
    setFormData(prev => ({
      ...prev,
      variants: templateVariants
    }));
    
    toast({
      title: "Size Template Applied",
      description: `Added ${templateVariants.length} size variants for ${formData.product_type}`
    });
  };

  // Variant management functions
  const updateVariant = (index: number, updates: Partial<ProductVariant>) => {
    setFormData(prev => ({
      ...prev,
      variants: prev.variants.map((variant, i) => 
        i === index ? { ...variant, ...updates } : variant
      )
    }));
  };

  const deleteVariant = (index: number) => {
    setFormData(prev => ({
      ...prev,
      variants: prev.variants.filter((_, i) => i !== index)
    }));
  };

  const bulkUpdateVariantPrices = (newPrice: number, applyMarkup?: number) => {
    setFormData(prev => ({
      ...prev,
      variants: prev.variants.map(variant => ({
        ...variant,
        price: applyMarkup ? newPrice * (1 + applyMarkup / 100) : newPrice
      }))
    }));
  };

  const bulkUpdateInventory = (quantity: number) => {
    setFormData(prev => ({
      ...prev,
      variants: prev.variants.map(variant => ({
        ...variant,
        stock_quantity: quantity
      }))
    }));
  };

  // Generate variants from colors and sizes
  const generateVariants = () => {
    if (formData.available_colors.length === 0) {
      toast({
        title: "No Colors Selected",
        description: "Please select colors before generating variants",
        variant: "destructive"
      });
      return;
    }
    
    // Get base sizes from existing variants or generate standard sizes
    const baseSizes = formData.variants.length > 0 
      ? [...new Set(formData.variants.map(v => v.size))]
      : ['S', 'M', 'L', 'XL', 'XXL']; // Default sizes if none exist
    
    bulkCreateSizes(baseSizes, formData.available_colors);
  };

  const bulkCreateSizes = (sizes: string[], colors: string[]) => {
    const newVariants: ProductVariant[] = [];
    
    sizes.forEach(size => {
      colors.forEach(color => {
        // Check if variant already exists
        const exists = formData.variants.some(v => v.size === size && v.color === color);
        if (!exists) {
          newVariants.push({
            size,
            color,
            sku: `${formData.sku}-${size.replace(/\s+/g, '')}-${color.substring(0, 3).toUpperCase()}`,
            price: formData.base_price,
            stock_quantity: 0,
            inventory_policy: 'deny',
            status: 'active',
            position: formData.variants.length + newVariants.length
          });
        }
      });
    });

    setFormData(prev => ({
      ...prev,
      variants: [...prev.variants, ...newVariants]
    }));

    toast({
      title: "Bulk Variants Created",
      description: `Created ${newVariants.length} new variants`,
    });
  };

  // AI Analysis functions
  const analyzeProductImages = async () => {
    if (!formData.images || formData.images.length === 0) {
      toast({
        title: "No Images",
        description: "Please add product images before analyzing",
        variant: "destructive"
      });
      return;
    }

    try {
      setAiAnalyzing(true);
      const primaryImage = formData.images.find(img => img.is_primary) || formData.images[0];
      
      const result = await fashionClip.analyzeImage(primaryImage.url, {
        includeDescription: true,
        includeSuggestions: true,
        category: formData.category
      });

      if (result.success && result.data) {
        setAnalysisResults(result.data);
        
        toast({
          title: "Analysis Complete",
          description: "AI analysis completed successfully. Review the suggestions.",
        });
      } else {
        throw new Error(result.error || 'Analysis failed');
      }
    } catch (error) {
      console.error('AI analysis failed:', error);
      toast({
        title: "Analysis Failed",
        description: error instanceof Error ? error.message : 'Unknown error occurred',
        variant: "destructive"
      });
    } finally {
      setAiAnalyzing(false);
    }
  };

  const generateProductContent = async () => {
    if (!formData.name || !formData.category) {
      toast({
        title: "Missing Information",
        description: "Please enter product name and category first",
        variant: "destructive"
      });
      return;
    }

    try {
      setGeneratingContent(true);
      
      const result = await kctIntelligence.generateDescriptionEnhanced({
        name: formData.name,
        category: formData.category,
        materials: formData.materials ? [formData.materials] : undefined,
        fit_type: formData.fit_type,
        price: formData.base_price,
        images: formData.images.map(img => img.url)
      });

      if (result.success && result.data) {
        setFormData(prev => ({
          ...prev,
          description: result.data.description || prev.description,
          meta_description: result.data.seo_description || prev.meta_description,
          features: [...prev.features, ...result.data.key_features],
        }));

        toast({
          title: "Content Generated",
          description: `AI-generated content applied (${result.data.generated_by}, ${Math.round(result.data.confidence * 100)}% confidence)`,
        });
      }
    } catch (error) {
      console.error('Content generation failed:', error);
      toast({
        title: "Generation Failed",
        description: "Failed to generate content. Please try again.",
        variant: "destructive"
      });
    } finally {
      setGeneratingContent(false);
    }
  };

  const validateProduct = async () => {
    try {
      const result = await kctIntelligence.validateProductEnhanced(formData);
      if (result.success) {
        setValidationResults(result.data);
        toast({
          title: "Validation Complete",
          description: `Quality score: ${result.data.quality_score}% (${result.data.completeness * 100}% complete)`,
          variant: result.data.isValid ? "default" : "destructive"
        });
      }
    } catch (error) {
      console.error('Validation failed:', error);
    }
  };

  const handleSubmit = async () => {
    // Validation with null checks
    if (!formData.name || typeof formData.name !== 'string' || !formData.name.trim()) {
      toast({
        title: "Validation Error",
        description: "Product name is required",
        variant: "destructive"
      });
      return;
    }

    if (!formData.category || typeof formData.category !== 'string' || !formData.category.trim()) {
      toast({
        title: "Validation Error", 
        description: "Product category is required",
        variant: "destructive"
      });
      return;
    }

    if (!formData.base_price || formData.base_price <= 0) {
      toast({
        title: "Validation Error",
        description: "Base price must be greater than 0",
        variant: "destructive"
      });
      return;
    }

    try {
      // Prepare product data with proper field mapping and null checks
      const productData: any = {
        sku: formData.sku || (product?.sku || `SKU-${Date.now()}`),
        name: formData.name && typeof formData.name === 'string' ? formData.name.trim() : '',
        description: formData.description && typeof formData.description === 'string' ? formData.description.trim() : null,
        category: formData.category && typeof formData.category === 'string' ? formData.category.trim() : '',
        // Map product_type to correct field - use subcategory if it exists in schema
        ...(formData.product_type && { subcategory: formData.product_type }),
        base_price: formData.base_price,
        status: formData.status || 'active',
        stripe_product_id: formData.stripe_product_id,
        is_bundleable: formData.is_bundleable,
        updated_at: new Date().toISOString(),
        images: formData.images.map((img, index) => ({
          url: img.url,
          position: img.position ?? index,
          alt_text: img.alt_text || '',
          image_type: img.is_primary ? 'primary' : 'gallery'
        })),
        variants: formData.variants,
        materials: formData.materials,
        care_instructions: formData.care_instructions,
        fit_type: formData.fit_type,
        occasion: formData.occasion,
        features: formData.features,
        meta_title: formData.meta_title,
        meta_description: formData.meta_description,
        url_slug: formData.url_slug,
        available_colors: formData.available_colors
      };

      // Add size_options for jacket-type products
      if (usesJacketSizing(formData.category)) {
        productData.size_options = sizeOptions;
      }

      // Add created_at only for new products
      if (!product) {
        productData.created_at = new Date().toISOString();
      }

      await onSubmit(productData);
    } catch (error) {
      console.error('Form submission error:', error);
      toast({
        title: "Error",
        description: error instanceof Error ? error.message : 'Failed to submit form',
        variant: "destructive"
      });
    }
  };

  return (
    <Tabs defaultValue="basic" className="space-y-6">
      <TabsList className="grid w-full grid-cols-6">
        <TabsTrigger value="basic" className="flex items-center gap-2">
          <Package className="h-4 w-4" />
          Basic
        </TabsTrigger>
        <TabsTrigger value="images" className="flex items-center gap-2">
          <Image className="h-4 w-4" />
          Images
        </TabsTrigger>
        <TabsTrigger value="variants" className="flex items-center gap-2">
          <Ruler className="h-4 w-4" />
          Variants
        </TabsTrigger>
        <TabsTrigger value="attributes" className="flex items-center gap-2">
          <Shirt className="h-4 w-4" />
          Details
        </TabsTrigger>
        <TabsTrigger value="seo" className="flex items-center gap-2">
          <Globe className="h-4 w-4" />
          SEO
        </TabsTrigger>
        <TabsTrigger value="preview" className="flex items-center gap-2">
          <Eye className="h-4 w-4" />
          Preview
        </TabsTrigger>
      </TabsList>

      {/* Basic Information Tab */}
      <TabsContent value="basic" className="space-y-6">
        <div className="grid grid-cols-2 gap-4">
          <div className="space-y-2">
            <Label htmlFor="sku">SKU *</Label>
            <Input
              id="sku"
              type="text"
              value={formData.sku}
              onChange={(e) => setFormData(prev => ({ ...prev, sku: e.target.value }))}
              placeholder="Enter unique SKU"
            />
          </div>
          <div className="space-y-2">
            <Label htmlFor="name">Product Name *</Label>
            <Input
              id="name"
              value={formData.name}
              onChange={(e) => {
                const name = e.target.value;
                setFormData(prev => ({ 
                  ...prev, 
                  name,
                  meta_title: prev.meta_title || name,
                  url_slug: prev.url_slug || generateSlug(name)
                }));
              }}
              placeholder="Enter product name"
            />
          </div>
        </div>

        <div className="grid grid-cols-2 gap-4">
          <div className="space-y-2">
            <Label htmlFor="category">Category *</Label>
            <Select
              value={formData.category}
              onValueChange={(value) => setFormData(prev => ({ ...prev, category: value }))}
            >
              <SelectTrigger>
                <SelectValue placeholder="Select category" />
              </SelectTrigger>
              <SelectContent>
                {categories.map(category => (
                  <SelectItem key={category} value={category}>{category}</SelectItem>
                ))}
              </SelectContent>
            </Select>
          </div>
          <div className="space-y-2">
            <Label htmlFor="product_type">Product Type *</Label>
            <Select
              value={formData.product_type}
              onValueChange={(value: any) => setFormData(prev => ({ ...prev, product_type: value }))}
            >
              <SelectTrigger>
                <SelectValue placeholder="Select type" />
              </SelectTrigger>
              <SelectContent>
                {productTypes.map(type => (
                  <SelectItem key={type} value={type}>{type}</SelectItem>
                ))}
              </SelectContent>
            </Select>
          </div>
        </div>

        <div className="grid grid-cols-2 gap-4">
          <div className="space-y-2">
            <Label htmlFor="base_price">Base Price ($) *</Label>
            <Input
              id="base_price"
              type="number"
              step="0.01"
              value={formData.base_price}
              onChange={(e) => setFormData(prev => ({ ...prev, base_price: parseFloat(e.target.value) || 0 }))}
              placeholder="0.00"
            />
          </div>
          <div className="space-y-2">
            <Label htmlFor="stripe_product_id">Stripe Product ID</Label>
            <Input
              id="stripe_product_id"
              value={formData.stripe_product_id}
              onChange={(e) => setFormData(prev => ({ ...prev, stripe_product_id: e.target.value }))}
              placeholder="prod_1234567890"
            />
          </div>
        </div>

        <div className="space-y-2">
          <Label htmlFor="description">Description</Label>
          <Textarea
            id="description"
            value={formData.description}
            onChange={(e) => setFormData(prev => ({ ...prev, description: e.target.value }))}
            placeholder="Enter detailed product description"
            rows={4}
          />
        </div>

        <div className="flex items-center space-x-6">
          <div className="flex items-center space-x-2">
            <Checkbox
              id="is_bundleable"
              checked={formData.is_bundleable}
              onCheckedChange={(checked) => setFormData(prev => ({ ...prev, is_bundleable: checked as boolean }))}
            />
            <Label htmlFor="is_bundleable">Bundleable</Label>
          </div>
          <div className="space-y-2">
            <Label htmlFor="status">Status</Label>
            <Select
              value={formData.status}
              onValueChange={(value: 'active' | 'inactive' | 'archived') => setFormData(prev => ({ ...prev, status: value }))}
            >
              <SelectTrigger className="w-32">
                <SelectValue />
              </SelectTrigger>
              <SelectContent>
                <SelectItem value="active">Active</SelectItem>
                <SelectItem value="inactive">Inactive</SelectItem>
                <SelectItem value="archived">Archived</SelectItem>
              </SelectContent>
            </Select>
          </div>
        </div>
      </TabsContent>

      {/* Images Tab */}
      <TabsContent value="images" className="space-y-6">
        <DraggableImageGallery
          images={formData.images}
          onImagesChange={handleImagesChange}
          productId={product?.id}
          maxImages={10}
          allowUpload={true}
        />
      </TabsContent>

      {/* Enhanced Variants Tab */}
      <TabsContent value="variants" className="space-y-6">
        <div className="space-y-6">
          {/* AI-Powered Analysis Section */}
          <div className="p-4 bg-gradient-to-r from-blue-50 to-purple-50 rounded-lg border">
            <div className="flex items-center justify-between mb-4">
              <div>
                <h3 className="text-lg font-medium flex items-center gap-2">
                  <Palette className="h-5 w-5" />
                  AI-Powered Product Analysis
                </h3>
                <p className="text-sm text-muted-foreground">
                  Let AI analyze your product images to suggest colors, materials, and features
                </p>
              </div>
              <div className="flex gap-2">
                <Button 
                  variant="outline" 
                  size="sm" 
                  onClick={analyzeProductImages}
                  disabled={aiAnalyzing || formData.images.length === 0}
                >
                  {aiAnalyzing ? <Clock className="h-4 w-4 mr-2 animate-spin" /> : <Eye className="h-4 w-4 mr-2" />}
                  {aiAnalyzing ? 'Analyzing...' : 'Analyze Images'}
                </Button>
                <Button 
                  variant="outline" 
                  size="sm" 
                  onClick={generateProductContent}
                  disabled={generatingContent || !formData.name}
                >
                  {generatingContent ? <Clock className="h-4 w-4 mr-2 animate-spin" /> : <Tag className="h-4 w-4 mr-2" />}
                  {generatingContent ? 'Generating...' : 'Generate Content'}
                </Button>
                <Button 
                  variant="outline" 
                  size="sm" 
                  onClick={validateProduct}
                >
                  <AlertTriangle className="h-4 w-4 mr-2" />
                  Validate
                </Button>
              </div>
            </div>
            
            {validationResults && (
              <div className="bg-white rounded p-3 border">
                <div className="flex items-center justify-between mb-2">
                  <span className="font-medium">Quality Score: {validationResults.quality_score}%</span>
                  <Badge variant={validationResults.isValid ? "default" : "destructive"}>
                    {Math.round(validationResults.completeness * 100)}% Complete
                  </Badge>
                </div>
                {validationResults.recommendations?.length > 0 && (
                  <div className="text-sm text-muted-foreground">
                    <strong>Recommendations:</strong>
                    <ul className="list-disc list-inside mt-1">
                      {validationResults.recommendations.slice(0, 3).map((rec: string, idx: number) => (
                        <li key={idx}>{rec}</li>
                      ))}
                    </ul>
                  </div>
                )}
              </div>
            )}
          </div>

          {/* Color Selection */}
          <div className="space-y-4">
            <div className="flex items-center justify-between">
              <div>
                <h3 className="text-lg font-medium">Available Colors</h3>
                <p className="text-sm text-muted-foreground">Select colors available for this product</p>
              </div>
              {analysisResults && (
                <Button variant="outline" size="sm" onClick={() => {
                  setFormData(prev => ({
                    ...prev,
                    available_colors: [...new Set([...prev.available_colors, ...analysisResults.colors.all_colors])]
                  }));
                }}>
                  Apply AI Colors
                </Button>
              )}
            </div>
            
            <div className="grid grid-cols-4 gap-3">
              {availableColors.map(color => (
                <div key={color} className="flex items-center space-x-2">
                  <Checkbox
                    id={`color-${color}`}
                    checked={formData.available_colors.includes(color)}
                    onCheckedChange={(checked) => handleColorChange(color, checked as boolean)}
                  />
                  <Label htmlFor={`color-${color}`} className="flex items-center space-x-2">
                    <div className={`w-4 h-4 rounded-full border ${color === 'White' ? 'border-gray-300' : 'border-gray-200'}`} 
                         style={{backgroundColor: color.toLowerCase()}} />
                    <span>{color}</span>
                  </Label>
                </div>
              ))}
            </div>
          </div>

          {/* Size Options for Jacket-type Products */}
          {usesJacketSizing(formData.category) && (
            <Card className="p-4">
              <div className="space-y-4">
                <div>
                  <h3 className="text-lg font-medium">Size Options</h3>
                  <p className="text-sm text-muted-foreground">
                    Select which size variants are available for this product
                  </p>
                </div>
                <div className="flex gap-6">
                  <div className="flex items-center space-x-2">
                    <Checkbox
                      id="size-regular"
                      checked={sizeOptions.regular}
                      onCheckedChange={(checked) => 
                        setSizeOptions(prev => ({ ...prev, regular: checked as boolean }))}
                    />
                    <Label htmlFor="size-regular">Regular (36R-54R)</Label>
                  </div>
                  <div className="flex items-center space-x-2">
                    <Checkbox
                      id="size-short"
                      checked={sizeOptions.short}
                      onCheckedChange={(checked) => 
                        setSizeOptions(prev => ({ ...prev, short: checked as boolean }))}
                    />
                    <Label htmlFor="size-short">Short (36S-54S)</Label>
                  </div>
                  <div className="flex items-center space-x-2">
                    <Checkbox
                      id="size-long"
                      checked={sizeOptions.long}
                      onCheckedChange={(checked) => 
                        setSizeOptions(prev => ({ ...prev, long: checked as boolean }))}
                    />
                    <Label htmlFor="size-long">Long (36L-54L)</Label>
                  </div>
                </div>
                <Button
                  type="button"
                  variant="outline"
                  size="sm"
                  onClick={handleApplySizeTemplate}
                  disabled={!sizeOptions.regular && !sizeOptions.short && !sizeOptions.long}
                >
                  <Package className="h-4 w-4 mr-2" />
                  Regenerate Variants with Selected Sizes
                </Button>
              </div>
            </Card>
          )}

          {/* Size Templates and Bulk Operations */}
          <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
            {/* Size Templates */}
            <div className="space-y-4">
              <h3 className="text-lg font-medium">Size Templates</h3>
              {['3-piece-suit', '2-piece-suit', 'blazer', 'dress-shirt'].includes(formData.product_type) ? (
                <div className="space-y-2">
                  <p className="text-sm text-muted-foreground">
                    Apply pre-configured sizes for {formData.product_type.replace('-', ' ')}
                  </p>
                  <Button
                    type="button"
                    variant="outline"
                    onClick={handleApplySizeTemplate}
                    disabled={!formData.base_price}
                    size="sm"
                  >
                    <Package className="h-4 w-4 mr-2" />
                    Apply Size Template
                  </Button>
                </div>
              ) : (
                <div className="space-y-2">
                  <p className="text-sm text-muted-foreground">Manual size entry for {formData.product_type}</p>
                  <div className="flex gap-2">
                    <Input placeholder="Enter size (e.g., S, M, L)" className="flex-1" />
                    <Button size="sm" onClick={() => {
                      // This would add a custom size
                      toast({ title: "Custom sizes", description: "Feature coming soon" });
                    }}>
                      Add
                    </Button>
                  </div>
                </div>
              )}
            </div>

            {/* Bulk Operations */}
            <div className="space-y-4">
              <h3 className="text-lg font-medium">Bulk Operations</h3>
              <div className="space-y-2">
                <div className="flex gap-2">
                  <Input 
                    type="number" 
                    placeholder="Price" 
                    className="w-24" 
                    step="0.01"
                  />
                  <Button 
                    size="sm" 
                    variant="outline"
                    onClick={(e) => {
                      const input = e.currentTarget.previousElementSibling as HTMLInputElement;
                      const price = parseFloat(input.value);
                      if (price > 0) {
                        bulkUpdateVariantPrices(price);
                        toast({ title: "Updated", description: "All variant prices updated" });
                      }
                    }}
                  >
                    Update All Prices
                  </Button>
                </div>
                
                <div className="flex gap-2">
                  <Input 
                    type="number" 
                    placeholder="Inventory" 
                    className="w-24" 
                  />
                  <Button 
                    size="sm" 
                    variant="outline"
                    onClick={(e) => {
                      const input = e.currentTarget.previousElementSibling as HTMLInputElement;
                      const qty = parseInt(input.value);
                      if (qty >= 0) {
                        bulkUpdateInventory(qty);
                        toast({ title: "Updated", description: "All variant inventory updated" });
                      }
                    }}
                  >
                    Update All Inventory
                  </Button>
                </div>

                <Button 
                  variant="outline" 
                  size="sm" 
                  onClick={generateVariants}
                  disabled={formData.available_colors.length === 0}
                >
                  <DollarSign className="h-4 w-4 mr-2" />
                  Generate All Variants
                </Button>
              </div>
            </div>
          </div>

          {/* Enhanced Variants List */}
          {formData.variants.length > 0 && (
            <div className="space-y-4">
              <div className="flex items-center justify-between">
                <h4 className="font-medium">Product Variants ({formData.variants.length})</h4>
                <div className="flex gap-2">
                  <Button
                    type="button"
                    variant="outline"
                    size="sm"
                    onClick={() => setFormData(prev => ({ ...prev, variants: [] }))}
                  >
                    <X className="h-4 w-4 mr-2" />
                    Clear All
                  </Button>
                </div>
              </div>
              
              <div className="max-h-80 overflow-y-auto border rounded-md">
                <Table>
                  <TableHeader className="sticky top-0 bg-white">
                    <TableRow>
                      <TableHead>Size</TableHead>
                      <TableHead>Color</TableHead>
                      <TableHead>SKU</TableHead>
                      <TableHead>Price</TableHead>
                      <TableHead>Cost</TableHead>
                      <TableHead>Inventory</TableHead>
                      <TableHead>Status</TableHead>
                      <TableHead>Actions</TableHead>
                    </TableRow>
                  </TableHeader>
                  <TableBody>
                    {formData.variants.map((variant, index) => (
                      <TableRow key={index} className="hover:bg-muted/50">
                        <TableCell className="font-medium">{variant.size}</TableCell>
                        <TableCell>
                          <div className="flex items-center gap-2">
                            <div 
                              className="w-4 h-4 rounded-full border" 
                              style={{backgroundColor: variant.color.toLowerCase()}} 
                            />
                            {variant.color}
                          </div>
                        </TableCell>
                        <TableCell className="font-mono text-xs">{variant.sku}</TableCell>
                        <TableCell>
                          <Input
                            type="number"
                            step="0.01"
                            value={variant.price}
                            onChange={(e) => updateVariant(index, { price: parseFloat(e.target.value) || 0 })}
                            className="w-20"
                          />
                        </TableCell>
                        <TableCell>
                          <Input
                            type="number"
                            step="0.01"
                            value={variant.cost_price || ''}
                            onChange={(e) => updateVariant(index, { cost_price: parseFloat(e.target.value) || undefined })}
                            className="w-20"
                            placeholder="Cost"
                          />
                        </TableCell>
                        <TableCell>
                          <Input
                            type="number"
                            value={variant.stock_quantity}
                            onChange={(e) => updateVariant(index, { stock_quantity: parseInt(e.target.value) || 0 })}
                            className="w-20"
                          />
                        </TableCell>
                        <TableCell>
                          <Select 
                            value={variant.status || 'active'} 
                            onValueChange={(value: 'active' | 'inactive' | 'archived') => updateVariant(index, { status: value })}
                          >
                            <SelectTrigger className="w-24">
                              <SelectValue />
                            </SelectTrigger>
                            <SelectContent>
                              <SelectItem value="active">Active</SelectItem>
                              <SelectItem value="inactive">Inactive</SelectItem>
                              <SelectItem value="archived">Archived</SelectItem>
                            </SelectContent>
                          </Select>
                        </TableCell>
                        <TableCell>
                          <Button
                            variant="ghost"
                            size="sm"
                            onClick={() => deleteVariant(index)}
                          >
                            <Trash2 className="h-4 w-4" />
                          </Button>
                        </TableCell>
                      </TableRow>
                    ))}
                  </TableBody>
                </Table>
              </div>
            </div>
          )}
        </div>
      </TabsContent>

      {/* Details Tab */}
      <TabsContent value="attributes" className="space-y-6">
        <div className="grid grid-cols-2 gap-6">
          <div className="space-y-4">
            <div className="space-y-2">
              <Label htmlFor="materials">Materials & Fabric</Label>
              <Textarea
                id="materials"
                value={formData.materials}
                onChange={(e) => setFormData(prev => ({ ...prev, materials: e.target.value }))}
                placeholder="e.g., 100% Wool, Super 120s"
                rows={3}
              />
            </div>

            <div className="space-y-2">
              <Label htmlFor="care_instructions">Care Instructions</Label>
              <Textarea
                id="care_instructions"
                value={formData.care_instructions}
                onChange={(e) => setFormData(prev => ({ ...prev, care_instructions: e.target.value }))}
                placeholder="e.g., Dry clean only"
                rows={3}
              />
            </div>
          </div>

          <div className="space-y-4">
            <div className="space-y-2">
              <Label htmlFor="fit_type">Fit Type</Label>
              <Select
                value={formData.fit_type}
                onValueChange={(value) => setFormData(prev => ({ ...prev, fit_type: value }))}
              >
                <SelectTrigger>
                  <SelectValue placeholder="Select fit type" />
                </SelectTrigger>
                <SelectContent>
                  {fitTypes.map(fit => (
                    <SelectItem key={fit} value={fit}>{fit}</SelectItem>
                  ))}
                </SelectContent>
              </Select>
            </div>

            <div className="space-y-2">
              <Label htmlFor="occasion">Occasion</Label>
              <Select
                value={formData.occasion}
                onValueChange={(value) => setFormData(prev => ({ ...prev, occasion: value }))}
              >
                <SelectTrigger>
                  <SelectValue placeholder="Select occasion" />
                </SelectTrigger>
                <SelectContent>
                  {occasions.map(occasion => (
                    <SelectItem key={occasion} value={occasion}>{occasion}</SelectItem>
                  ))}
                </SelectContent>
              </Select>
            </div>

            <div className="space-y-2">
              <Label>Features</Label>
              <div className="grid grid-cols-2 gap-2">
                {commonFeatures.map(feature => (
                  <div key={feature} className="flex items-center space-x-2">
                    <Checkbox
                      id={`feature-${feature}`}
                      checked={formData.features.includes(feature)}
                      onCheckedChange={(checked) => handleFeatureChange(feature, checked as boolean)}
                    />
                    <Label htmlFor={`feature-${feature}`} className="text-sm">{feature}</Label>
                  </div>
                ))}
              </div>
            </div>
          </div>
        </div>
      </TabsContent>

      {/* SEO Tab */}
      <TabsContent value="seo" className="space-y-6">
        <div className="space-y-4">
          <div className="space-y-2">
            <Label htmlFor="meta_title">Meta Title (0-60 characters)</Label>
            <Input
              id="meta_title"
              value={formData.meta_title}
              onChange={(e) => setFormData(prev => ({ ...prev, meta_title: e.target.value }))}
              placeholder="SEO optimized title"
              maxLength={60}
            />
            <div className="text-xs text-muted-foreground">
              {formData.meta_title.length}/60 characters
            </div>
          </div>

          <div className="space-y-2">
            <Label htmlFor="meta_description">Meta Description (0-160 characters)</Label>
            <Textarea
              id="meta_description"
              value={formData.meta_description}
              onChange={(e) => setFormData(prev => ({ ...prev, meta_description: e.target.value }))}
              placeholder="Brief description for search engines"
              maxLength={160}
              rows={3}
            />
            <div className="text-xs text-muted-foreground">
              {formData.meta_description.length}/160 characters
            </div>
          </div>

          <div className="space-y-2">
            <Label htmlFor="url_slug">URL Slug</Label>
            <div className="flex items-center space-x-2">
              <span className="text-sm text-muted-foreground">/products/</span>
              <Input
                id="url_slug"
                value={formData.url_slug}
                onChange={(e) => setFormData(prev => ({ ...prev, url_slug: e.target.value }))}
                placeholder="product-url-slug"
              />
              <Button 
                type="button" 
                variant="outline" 
                size="sm"
                onClick={() => setFormData(prev => ({ ...prev, url_slug: generateSlug(formData.name) }))}
              >
                Generate
              </Button>
            </div>
          </div>
        </div>
      </TabsContent>

      {/* Preview Tab */}
      <TabsContent value="preview" className="space-y-6">
        <div className="space-y-4">
          <h3 className="text-lg font-medium">Product Preview</h3>
          <Card className="p-6">
            <div className="space-y-4">
              <div className="flex items-start justify-between">
                <div className="space-y-2">
                  <h4 className="text-xl font-semibold">{formData.name || 'Product Name'}</h4>
                  <Badge variant="outline">{formData.category}</Badge>
                  <p className="text-2xl font-bold">${formData.base_price}</p>
                </div>
                <div className="w-32 h-32 bg-muted rounded-lg flex items-center justify-center">
                  <Image className="h-8 w-8 text-muted-foreground" />
                </div>
              </div>

              <p className="text-muted-foreground">{formData.description || 'Product description will appear here'}</p>

              {formData.available_colors.length > 0 && (
                <div className="space-y-2">
                  <Label>Available Colors:</Label>
                  <div className="flex gap-2">
                    {formData.available_colors.map(color => (
                      <div key={color} className="flex items-center space-x-1">
                        <div className={`w-4 h-4 rounded-full border`} 
                             style={{backgroundColor: color.toLowerCase()}} />
                        <span className="text-sm">{color}</span>
                      </div>
                    ))}
                  </div>
                </div>
              )}

              {formData.features.length > 0 && (
                <div className="space-y-2">
                  <Label>Features:</Label>
                  <div className="flex flex-wrap gap-1">
                    {formData.features.map(feature => (
                      <Badge key={feature} variant="secondary">{feature}</Badge>
                    ))}
                  </div>
                </div>
              )}

              {formData.variants.length > 0 && (
                <div className="space-y-2">
                  <Label>Available Sizes:</Label>
                  <div className="text-sm text-muted-foreground">
                    {formData.variants.length} variants available
                  </div>
                </div>
              )}
            </div>
          </Card>
        </div>
      </TabsContent>

      {/* Form Actions */}
      <div className="flex justify-end space-x-2 pt-6 border-t">
        <Button variant="outline" onClick={onClose}>
          Cancel
        </Button>
        <Button onClick={handleSubmit}>
          {product ? 'Update Product' : 'Add Product'}
        </Button>
      </div>
    </Tabs>
  );
}, (prevProps, nextProps) => {
  // Custom comparison for React.memo optimization
  return (
    prevProps.product === nextProps.product &&
    prevProps.isOpen === nextProps.isOpen &&
    prevProps.categories === nextProps.categories &&
    // Compare callback functions by reference (parent should memoize them)
    prevProps.onClose === nextProps.onClose &&
    prevProps.onSubmit === nextProps.onSubmit
  );
});