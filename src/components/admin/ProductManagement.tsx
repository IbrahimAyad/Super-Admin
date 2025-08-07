import { useState, useEffect, useMemo } from 'react';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { Label } from '@/components/ui/label';
import { Textarea } from '@/components/ui/textarea';
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from '@/components/ui/select';
import { Dialog, DialogContent, DialogHeader, DialogTitle, DialogTrigger } from '@/components/ui/dialog';
import { Table, TableBody, TableCell, TableHead, TableHeader, TableRow } from '@/components/ui/table';
import { Badge } from '@/components/ui/badge';
import { Checkbox } from '@/components/ui/checkbox';
import { Tabs, TabsContent, TabsList, TabsTrigger } from '@/components/ui/tabs';
import { Separator } from '@/components/ui/separator';
import { Progress } from '@/components/ui/progress';
import { Skeleton } from '@/components/ui/skeleton';
import { useToast } from '@/hooks/use-toast';
import { 
  Plus, 
  Search, 
  Filter, 
  Edit2, 
  Trash2, 
  Upload,
  Download,
  Package,
  Eye,
  Copy,
  MoreHorizontal,
  AlertTriangle,
  Image,
  Palette,
  Ruler,
  Shirt,
  DollarSign,
  Globe,
  Tag,
  X,
  GripVertical,
  Grid,
  List,
  ChevronLeft,
  ChevronRight,
  EyeOff,
  Clock,
  ImageOff
} from 'lucide-react';
import { DropdownMenu, DropdownMenuContent, DropdownMenuItem, DropdownMenuTrigger } from '@/components/ui/dropdown-menu';
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
import { DraggableImageGallery } from './DraggableImageGallery';
import { supabase } from '@/lib/supabase-client';
import { testStorageBucket } from '@/lib/storage';
import styles from './ProductManagement.module.css';

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
  size: string;
  color: string;
  sku: string;
  price: number;
  stock_quantity: number;
  image_url?: string;
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

const categories = [
  'Suits & Blazers',
  'Shirts & Tops',
  'Trousers & Pants',
  'Accessories',
  'Footwear',
  'Formal Wear',
  'Casual Wear'
];

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
  const [formData, setFormData] = useState<ProductFormData>({
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

  useEffect(() => {
    loadProducts();
    loadRecentProducts();
    
    // Test storage bucket on component mount
    testStorageBucket().then(result => {
      if (!result.success) {
        console.error('🚨 Storage bucket test failed:', result.error);
        toast({
          title: "Storage Configuration Issue",
          description: `Storage test failed: ${result.error}`,
          variant: "destructive"
        });
      } else {
        console.log('✅ Storage bucket test passed:', result.message);
      }
    }).catch(error => {
      console.error('Storage test error:', error);
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
      console.log('🔍 Loading products with pagination...');
      
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
        console.error('❌ Products fetch error:', result.error);
        setProducts([]);
        setTotalCount(0);
        toast({
          title: "Database Error",
          description: `Error: ${result.error}`,
          variant: "destructive"
        });
        return;
      }
      
      console.log('✅ Products loaded successfully:', result.data?.length || 0, 'items (total:', result.totalCount, ')');
      
      setProducts(result.data || []);
      setTotalCount(result.totalCount || 0);
      
      if (result.totalCount === 0) {
        toast({
          title: "No Products Found",
          description: searchTerm || hasActiveSmartFilters ? "No products match your filters" : "Products table is empty. Add some products to get started!",
        });
      }
      
    } catch (error) {
      console.error('💥 Error loading products:', error);
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
      console.error('Error loading recent products:', error);
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
      console.error('Quick toggle error:', error);
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
      console.error('Quick duplicate error:', error);
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
      console.error('Bulk action error:', error);
      const errorMessage = error instanceof Error ? error.message : 'Unknown error occurred';
      toast({
        title: "Error",
        description: `Failed to perform bulk action: ${errorMessage}`,
        variant: "destructive"
      });
    }
  };

  const handleAddProduct = async () => {
    // Validation with null checks
    if (!formData.name || !formData.name.trim()) {
      toast({
        title: "Validation Error",
        description: "Product name is required",
        variant: "destructive"
      });
      return;
    }

    if (!formData.category || !formData.category.trim()) {
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
      const productData = {
        sku: formData.sku || `SKU-${Date.now()}`,
        name: formData.name.trim(),
        description: formData.description ? formData.description.trim() : null,
        category: formData.category.trim(),
        // Map product_type to correct field - use subcategory if it exists in schema
        ...(formData.product_type && { subcategory: formData.product_type }),
        base_price: formData.base_price,
        status: formData.status || 'active',
        created_at: new Date().toISOString(),
        updated_at: new Date().toISOString(),
        images: formData.images.map((img, index) => ({
          url: img.url,
          position: img.position ?? index,
          alt_text: img.alt_text || '',
          image_type: img.is_primary ? 'primary' : 'gallery'
        }))
      };

      console.log('🔄 Creating product with data:', productData);

      const result = await createProductWithImages(productData);

      if (!result.success || !result.data) {
        console.error('❌ Create failed:', result.error);
        throw new Error(result.error || 'Failed to create product');
      }

      console.log('✅ Product created successfully:', result.data);

      // Add variants if any
      if (formData.variants && formData.variants.length > 0) {
        const { error: variantsError } = await supabase
          .from('product_variants')
          .insert(
            formData.variants.map(variant => ({
              product_id: result.data.id,
              ...variant
            }))
          );

        if (variantsError) {
          console.warn('Failed to add variants:', variantsError);
          toast({
            title: "Partial Success",
            description: "Product created but some variants failed to save",
            variant: "default"
          });
        }
      }

      toast({
        title: "Success",
        description: `Product "${formData.name}" added successfully`
      });

      setShowAddDialog(false);
      resetForm();
      await loadProducts(); // Reload products to show the new one
    } catch (error) {
      console.error('💥 Error adding product:', error);
      const errorMessage = error instanceof Error ? error.message : 'Unknown error occurred';
      toast({
        title: "Error",
        description: `Failed to add product: ${errorMessage}`,
        variant: "destructive"
      });
    }
  };

  const handleEditProduct = async () => {
    if (!editingProduct) return;

    // Validation with null checks
    if (!formData.name || !formData.name.trim()) {
      toast({
        title: "Validation Error",
        description: "Product name is required",
        variant: "destructive"
      });
      return;
    }

    if (!formData.category || !formData.category.trim()) {
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
      // Prepare update data with null checks and proper field mapping
      const updateData = {
        name: formData.name.trim(),
        description: formData.description ? formData.description.trim() : null,
        category: formData.category.trim(),
        // Map product_type to correct field - use subcategory if it exists in schema
        ...(formData.product_type && { subcategory: formData.product_type }),
        base_price: formData.base_price,
        status: formData.status || 'active',
        sku: formData.sku || editingProduct.sku,
        updated_at: new Date().toISOString(),
        images: formData.images.map((img, index) => ({
          url: img.url,
          position: img.position ?? index,
          alt_text: img.alt_text || '',
          image_type: img.is_primary ? 'primary' : 'gallery'
        }))
      };

      console.log('🔄 Updating product with data:', updateData);

      const result = await updateProductWithImages(editingProduct.id, updateData);

      if (!result.success) {
        console.error('❌ Update failed:', result.error);
        throw new Error(result.error || 'Failed to update product');
      }

      console.log('✅ Product updated successfully:', result.data);

      toast({
        title: "Success",
        description: `Product "${formData.name}" updated successfully`
      });

      setEditingProduct(null);
      resetForm();
      setShowAddDialog(false);
      await loadProducts(); // Reload products to show changes
    } catch (error) {
      console.error('💥 Error updating product:', error);
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
      console.error('Error deleting product:', error);
      toast({
        title: "Error",
        description: "Failed to delete product",
        variant: "destructive"
      });
    }
  };

  // Size templates for different product types
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
    const jacketSizes = [34, 36, 38, 40, 42, 44, 46, 48, 50, 52, 54];
    const lengths = ['S', 'R', 'L'];
    const variants: ProductVariant[] = [];

    jacketSizes.forEach(size => {
      lengths.forEach(length => {
        // Check availability based on length restrictions
        if (length === 'S' && size > 50) return;
        if (length === 'L' && size < 38) return;

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
    const jacketSizes = [34, 36, 38, 40, 42, 44, 46, 48, 50, 52, 54];
    const lengths = ['S', 'R', 'L'];
    const variants: ProductVariant[] = [];

    jacketSizes.forEach(size => {
      lengths.forEach(length => {
        // Check availability based on length restrictions
        if (length === 'S' && size > 50) return;
        if (length === 'L' && size < 38) return;

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

  // Generate variants from colors and sizes
  const generateVariants = () => {
    if (formData.available_colors.length === 0) return;
    
    const variants: ProductVariant[] = [];
    formData.available_colors.forEach(color => {
      formData.variants.forEach(variant => {
        variants.push({
          ...variant,
          color,
          sku: `${formData.sku}-${variant.size.replace(/\s+/g, '')}-${color.substring(0, 3).toUpperCase()}`,
          price: formData.base_price
        });
      });
    });
    
    setFormData(prev => ({ ...prev, variants }));
    toast({
      title: "Variants Generated",
      description: `Created ${variants.length} variants from color and size combinations`
    });
  };

  // Auto-generate URL slug from product name
  const generateSlug = (name: string) => {
    return name
      .toLowerCase()
      .replace(/[^a-z0-9]+/g, '-')
      .replace(/(^-|-$)/g, '');
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

  // Bulk edit variant prices
  const bulkEditVariantPrices = (newPrice: number) => {
    setFormData(prev => ({
      ...prev,
      variants: prev.variants.map(variant => ({
        ...variant,
        price: newPrice
      }))
    }));
  };

  // Handle image changes from the draggable gallery
  const handleImagesChange = (newImages: ProductImage[]) => {
    setFormData(prev => ({
      ...prev,
      images: newImages
    }));
  };

  const resetForm = () => {
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
  };

  const openEditDialog = (product: Product) => {
    setEditingProduct(product);
    
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
    setShowAddDialog(true);
  };

  const ProductForm = () => (
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
          productId={editingProduct?.id}
          maxImages={10}
          allowUpload={true}
        />
      </TabsContent>

      {/* Variants Tab */}
      <TabsContent value="variants" className="space-y-6">
        <div className="space-y-6">
          {/* Color Selection */}
          <div className="space-y-4">
            <div className="flex items-center justify-between">
              <div>
                <h3 className="text-lg font-medium">Available Colors</h3>
                <p className="text-sm text-muted-foreground">Select colors available for this product</p>
              </div>
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

          <Separator />

          {/* Size Templates */}
          {['3-piece-suit', '2-piece-suit', 'blazer', 'dress-shirt'].includes(formData.product_type) && (
            <div className="space-y-4">
              <div className="flex items-center justify-between">
                <div>
                  <h3 className="text-lg font-medium">Size Templates</h3>
                  <p className="text-sm text-muted-foreground">
                    Apply pre-configured sizes for {formData.product_type.replace('-', ' ')}
                  </p>
                </div>
                <Button
                  type="button"
                  variant="outline"
                  onClick={handleApplySizeTemplate}
                  disabled={!formData.base_price}
                >
                  <Package className="h-4 w-4 mr-2" />
                  Apply Size Template
                </Button>
              </div>
            </div>
          )}

          {/* Variant Generation */}
          {formData.available_colors.length > 0 && formData.variants.length > 0 && (
            <div className="space-y-4">
              <div className="flex items-center justify-between">
                <div>
                  <h3 className="text-lg font-medium">Generate Variants</h3>
                  <p className="text-sm text-muted-foreground">Create variants from color × size combinations</p>
                </div>
                <Button variant="outline" onClick={generateVariants}>
                  <DollarSign className="h-4 w-4 mr-2" />
                  Generate All Variants
                </Button>
              </div>
            </div>
          )}

          {/* Bulk Edit Prices */}
          {formData.variants.length > 0 && (
            <div className="space-y-4">
              <div className="flex items-center gap-4">
                <h3 className="text-lg font-medium">Bulk Edit Prices</h3>
                <div className="flex items-center gap-2">
                  <Input
                    type="number"
                    step="0.01"
                    placeholder="New price"
                    className="w-32"
                    onChange={(e) => {
                      const price = parseFloat(e.target.value);
                      if (!isNaN(price)) {
                        bulkEditVariantPrices(price);
                      }
                    }}
                  />
                  <span className="text-sm text-muted-foreground">Apply to all variants</span>
                </div>
              </div>
            </div>
          )}

          {/* Variants List */}
          {formData.variants.length > 0 && (
            <div className="space-y-4">
              <h4 className="font-medium">Generated Variants ({formData.variants.length})</h4>
              <div className="max-h-64 overflow-y-auto border rounded-md">
                <Table>
                  <TableHeader>
                    <TableRow>
                      <TableHead>Size</TableHead>
                      <TableHead>Color</TableHead>
                      <TableHead>SKU</TableHead>
                      <TableHead>Price</TableHead>
                      <TableHead>Stock</TableHead>
                    </TableRow>
                  </TableHeader>
                  <TableBody>
                    {formData.variants.map((variant, index) => (
                      <TableRow key={index}>
                        <TableCell>{variant.size}</TableCell>
                        <TableCell>{variant.color}</TableCell>
                        <TableCell className="font-mono text-xs">{variant.sku}</TableCell>
                        <TableCell>${variant.price}</TableCell>
                        <TableCell>
                          <Input
                            type="number"
                            value={variant.stock_quantity}
                            onChange={(e) => {
                              const stock = parseInt(e.target.value) || 0;
                              setFormData(prev => ({
                                ...prev,
                                variants: prev.variants.map((v, i) => 
                                  i === index ? { ...v, stock_quantity: stock } : v
                                )
                              }));
                            }}
                            className="w-20"
                          />
                        </TableCell>
                      </TableRow>
                    ))}
                  </TableBody>
                </Table>
              </div>
              <Button
                type="button"
                variant="outline"
                size="sm"
                onClick={() => setFormData(prev => ({ ...prev, variants: [] }))}
              >
                Clear All Variants
              </Button>
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
        <Button variant="outline" onClick={() => { setShowAddDialog(false); setEditingProduct(null); resetForm(); }}>
          Cancel
        </Button>
        <Button onClick={editingProduct ? handleEditProduct : handleAddProduct}>
          {editingProduct ? 'Update Product' : 'Add Product'}
        </Button>
      </div>
    </Tabs>
  );

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

  const SmartFiltersBar = () => (
    <div className="flex flex-wrap gap-2">
      <Button
        variant={smartFilters.lowStock ? "default" : "outline"}
        size="sm"
        onClick={() => handleSmartFilterToggle('lowStock')}
      >
        <AlertTriangle className="h-4 w-4 mr-1" />
        Low Stock ({smartFilterCounts.lowStock})
      </Button>
      <Button
        variant={smartFilters.noImages ? "default" : "outline"}
        size="sm"
        onClick={() => handleSmartFilterToggle('noImages')}
      >
        <ImageOff className="h-4 w-4 mr-1" />
        No Images ({smartFilterCounts.noImages})
      </Button>
      <Button
        variant={smartFilters.inactive ? "default" : "outline"}
        size="sm"
        onClick={() => handleSmartFilterToggle('inactive')}
      >
        <EyeOff className="h-4 w-4 mr-1" />
        Inactive ({smartFilterCounts.inactive})
      </Button>
      <Button
        variant={smartFilters.recentlyUpdated ? "default" : "outline"}
        size="sm"
        onClick={() => handleSmartFilterToggle('recentlyUpdated')}
      >
        <Clock className="h-4 w-4 mr-1" />
        Recent ({smartFilterCounts.recentlyUpdated})
      </Button>
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

  const ProductTableView = () => (
    <div className="overflow-x-auto">
      <Table>
        <TableHeader>
          <TableRow>
            <TableHead className="w-12">
              <Checkbox
                checked={selectedProducts.length === products.length && products.length > 0}
                onCheckedChange={handleSelectAll}
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
                  onCheckedChange={() => handleSelectProduct(product.id)}
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
                    onClick={() => handleQuickToggle(product.id)}
                    title={product.status === 'active' ? 'Deactivate' : 'Activate'}
                  >
                    {product.status === 'active' ? <EyeOff className="h-4 w-4" /> : <Eye className="h-4 w-4" />}
                  </Button>
                  <Button
                    variant="ghost"
                    size="sm"
                    onClick={() => handleQuickDuplicate(product.id)}
                    title="Duplicate"
                  >
                    <Copy className="h-4 w-4" />
                  </Button>
                  <Button
                    variant="ghost"
                    size="sm"
                    onClick={() => openEditDialog(product)}
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
                  onCheckedChange={() => handleSelectProduct(product.id)}
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
                    onClick={() => handleQuickToggle(product.id)}
                  >
                    {product.status === 'active' ? <EyeOff className="h-4 w-4" /> : <Eye className="h-4 w-4" />}
                  </Button>
                  <Button
                    variant="ghost"
                    size="sm"
                    onClick={() => handleQuickDuplicate(product.id)}
                  >
                    <Copy className="h-4 w-4" />
                  </Button>
                  <Button
                    variant="ghost"
                    size="sm"
                    onClick={() => openEditDialog(product)}
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
              onCheckedChange={() => handleSelectProduct(product.id)}
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
                onClick={() => handleQuickToggle(product.id)}
                title={product.status === 'active' ? 'Deactivate' : 'Activate'}
              >
                {product.status === 'active' ? <EyeOff size={16} /> : <Eye size={16} />}
              </button>
              <button
                className={styles.mobileActionButton}
                onClick={() => handleQuickDuplicate(product.id)}
                title="Duplicate"
              >
                <Copy size={16} />
              </button>
              <button
                className={styles.mobileActionButton}
                onClick={() => openEditDialog(product)}
                title="Edit"
              >
                <Edit2 size={16} />
              </button>
            </div>
          </div>
          <div className="text-xs text-gray-500 mt-2 flex justify-between">
            <span>Stock: {(product as any).total_inventory || 0}</span>
            <span>Updated: {new Date(product.updated_at).toLocaleDateString()}</span>
          </div>
        </div>
      ))}
    </div>
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
            <Button onClick={() => { resetForm(); setEditingProduct(null); }}>
              <Plus className="h-4 w-4 mr-2" />
              Add Product
            </Button>
          </DialogTrigger>
          <DialogContent className="max-w-2xl max-h-[90vh] overflow-y-auto">
            <DialogHeader>
              <DialogTitle>{editingProduct ? 'Edit Product' : 'Add New Product'}</DialogTitle>
            </DialogHeader>
            <ProductForm />
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
            {/* Search and Filters */}
            <div className="flex flex-col lg:flex-row lg:items-center gap-4">
              <div className="relative flex-1 max-w-sm">
                <Search className="absolute left-3 top-1/2 h-4 w-4 -translate-y-1/2 text-muted-foreground" />
                <Input
                  placeholder="Search products..."
                  value={searchTerm}
                  onChange={(e) => setSearchTerm(e.target.value)}
                  className="pl-9"
                />
              </div>
              <div className="flex flex-col sm:flex-row gap-2">
                <Select value={categoryFilter} onValueChange={setCategoryFilter}>
                  <SelectTrigger className="w-full sm:w-48">
                    <SelectValue placeholder="All Categories" />
                  </SelectTrigger>
                  <SelectContent>
                    <SelectItem value="all">All Categories</SelectItem>
                    {categories.map(category => (
                      <SelectItem key={category} value={category}>{category}</SelectItem>
                    ))}
                  </SelectContent>
                </Select>
                <div className="flex items-center gap-2">
                  <Button
                    variant={viewMode === 'table' ? "default" : "outline"}
                    size="sm"
                    onClick={() => setViewMode('table')}
                    className="hidden sm:flex"
                  >
                    <List className="h-4 w-4" />
                  </Button>
                  <Button
                    variant={viewMode === 'grid' ? "default" : "outline"}
                    size="sm"
                    onClick={() => setViewMode('grid')}
                    className="hidden sm:flex"
                  >
                    <Grid className="h-4 w-4" />
                  </Button>
                </div>
              </div>
            </div>

            {/* Smart Filters */}
            <div className={`${styles.smartFiltersWrap || ''}`}>
              <SmartFiltersBar />
            </div>

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
                {/* Desktop/Tablet Views */}
                <div className="hidden sm:block">
                  {viewMode === 'table' ? <ProductTableView /> : <ProductGridView />}
                </div>
                
                {/* Mobile View - Always use cards */}
                <div className="sm:hidden">
                  <MobileCardsView />
                </div>
                
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