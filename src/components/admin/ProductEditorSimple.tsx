/**
 * SIMPLE PRODUCT EDITOR
 * Clean, single-page interface matching website structure
 * No tabs, no complex features - just what works
 */

import React, { useState, useEffect } from 'react';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { Textarea } from '@/components/ui/textarea';
import { Label } from '@/components/ui/label';
import { Card } from '@/components/ui/card';
import { Checkbox } from '@/components/ui/checkbox';
import { toast } from 'sonner';
import { supabase } from '@/lib/supabase-client';
import { Upload, X, GripVertical, Plus, Save, Trash2 } from 'lucide-react';

interface ProductSize {
  size: string;
  sku: string;
  inventory: number;
  price?: number;
  enabled: boolean;
}

interface ProductEditorProps {
  productId?: string;
  onSave?: () => void;
  onCancel?: () => void;
}

// Standard size configurations for different product types
const SIZE_TEMPLATES = {
  suits: {
    regular: ['34R', '36R', '38R', '40R', '42R', '44R', '46R', '48R', '50R', '52R', '54R'],
    long: ['38L', '40L', '42L', '44L', '46L', '48L', '50L', '52L', '54L'],
  },
  shirts: ['XS', 'S', 'M', 'L', 'XL', 'XXL', '3XL', '4XL'],
  ties: ['Pre-tied', 'Classic', 'Skinny', 'Slim'],
  accessories: ['One Size'],
};

export function ProductEditorSimple({ productId, onSave, onCancel }: ProductEditorProps) {
  // Basic product data
  const [name, setName] = useState('');
  const [sku, setSku] = useState('');
  const [category, setCategory] = useState('');
  const [price, setPrice] = useState('');
  const [description, setDescription] = useState('');
  const [details, setDetails] = useState<string[]>(['']);
  
  // Images
  const [images, setImages] = useState<any[]>([]);
  const [uploadingImage, setUploadingImage] = useState(false);
  
  // Sizes/Variants
  const [productType, setProductType] = useState<'suits' | 'shirts' | 'ties' | 'accessories'>('suits');
  const [sizes, setSizes] = useState<ProductSize[]>([]);
  const [showLongSizes, setShowLongSizes] = useState(false);
  
  // Colors (for accessories/ties)
  const [colors, setColors] = useState<string[]>([]);
  const [selectedColor, setSelectedColor] = useState('');
  
  // Status
  const [isActive, setIsActive] = useState(true);
  const [isSaving, setIsSaving] = useState(false);

  // Initialize sizes based on product type
  useEffect(() => {
    initializeSizes();
  }, [productType]);

  // Load existing product if editing
  useEffect(() => {
    if (productId) {
      loadProduct();
    }
  }, [productId]);

  const initializeSizes = () => {
    let sizeList: string[] = [];
    
    if (productType === 'suits') {
      sizeList = SIZE_TEMPLATES.suits.regular;
      if (showLongSizes) {
        sizeList = [...sizeList, ...SIZE_TEMPLATES.suits.long];
      }
    } else if (productType === 'shirts') {
      sizeList = SIZE_TEMPLATES.shirts;
    } else if (productType === 'ties') {
      sizeList = SIZE_TEMPLATES.ties;
    } else {
      sizeList = SIZE_TEMPLATES.accessories;
    }

    const newSizes: ProductSize[] = sizeList.map(size => ({
      size,
      sku: sku ? `${sku}-${size}`.toUpperCase() : `SKU-${size}`.toUpperCase(),
      inventory: 0,
      price: parseFloat(price) || 0,
      enabled: false,
    }));

    setSizes(newSizes);
  };

  const loadProduct = async () => {
    if (!productId) return;

    try {
      // Load product data
      const { data: product, error } = await supabase
        .from('products')
        .select('*')
        .eq('id', productId)
        .single();

      if (error) throw error;

      // Set basic data
      setName(product.name || '');
      setSku(product.sku || '');
      setCategory(product.category || '');
      setPrice(product.base_price || '');
      setDescription(product.description || '');
      setIsActive(product.status === 'active');

      // Parse details if stored as JSON
      if (product.details) {
        const detailsList = typeof product.details === 'string' 
          ? JSON.parse(product.details) 
          : product.details;
        setDetails(Array.isArray(detailsList) ? detailsList : [detailsList]);
      }

      // Load images
      const { data: productImages } = await supabase
        .from('product_images')
        .select('*')
        .eq('product_id', productId)
        .order('position');

      if (productImages) {
        setImages(productImages);
      }

      // Load variants/sizes
      const { data: variants } = await supabase
        .from('product_variants')
        .select('*')
        .eq('product_id', productId)
        .order('position');

      if (variants && variants.length > 0) {
        const sizeData = variants.map(v => ({
          size: v.size,
          sku: v.sku,
          inventory: v.inventory_quantity || 0,
          price: v.price || product.base_price,
          enabled: v.is_active,
        }));
        setSizes(sizeData);
      }

    } catch (error) {
      console.error('Error loading product:', error);
      toast.error('Failed to load product');
    }
  };

  const handleImageUpload = async (e: React.ChangeEvent<HTMLInputElement>) => {
    const files = e.target.files;
    if (!files || files.length === 0) return;

    setUploadingImage(true);
    
    try {
      for (const file of Array.from(files)) {
        const fileName = `${Date.now()}-${file.name}`;
        
        // Upload to Supabase storage
        const { data, error } = await supabase.storage
          .from('product-images')
          .upload(fileName, file);

        if (error) throw error;

        // Get public URL
        const { data: { publicUrl } } = supabase.storage
          .from('product-images')
          .getPublicUrl(fileName);

        // Add to images array
        setImages(prev => [...prev, {
          image_url: publicUrl,
          position: prev.length,
        }]);
      }
      
      toast.success('Images uploaded successfully');
    } catch (error) {
      console.error('Error uploading images:', error);
      toast.error('Failed to upload images');
    } finally {
      setUploadingImage(false);
    }
  };

  const removeImage = (index: number) => {
    setImages(prev => prev.filter((_, i) => i !== index));
  };

  const moveImage = (fromIndex: number, toIndex: number) => {
    const newImages = [...images];
    const [movedImage] = newImages.splice(fromIndex, 1);
    newImages.splice(toIndex, 0, movedImage);
    
    // Update positions
    newImages.forEach((img, idx) => {
      img.position = idx;
    });
    
    setImages(newImages);
  };

  const toggleSize = (index: number) => {
    const newSizes = [...sizes];
    newSizes[index].enabled = !newSizes[index].enabled;
    setSizes(newSizes);
  };

  const updateSizeInventory = (index: number, value: string) => {
    const newSizes = [...sizes];
    newSizes[index].inventory = parseInt(value) || 0;
    setSizes(newSizes);
  };

  const addDetail = () => {
    setDetails(prev => [...prev, '']);
  };

  const updateDetail = (index: number, value: string) => {
    const newDetails = [...details];
    newDetails[index] = value;
    setDetails(newDetails);
  };

  const removeDetail = (index: number) => {
    setDetails(prev => prev.filter((_, i) => i !== index));
  };

  const handleSave = async () => {
    // Validation
    if (!name || !sku || !price) {
      toast.error('Please fill in required fields (Name, SKU, Price)');
      return;
    }

    setIsSaving(true);

    try {
      // Generate slug from name for new products
      const slug = name.toLowerCase()
        .replace(/[^a-z0-9]+/g, '-')
        .replace(/^-+|-+$/g, '');

      const productData = {
        name,
        sku,
        slug: productId ? undefined : slug, // Only add slug for new products
        category: category || 'Uncategorized',
        base_price: parseFloat(price),
        description,
        details: JSON.stringify(details.filter(d => d.trim())), // Ensure details is stringified
        status: isActive ? 'active' : 'inactive',
        product_type: productType,
        metadata: {}, // Add empty metadata object
        updated_at: new Date().toISOString(),
      };

      // Remove undefined fields
      Object.keys(productData).forEach(key => {
        if (productData[key as keyof typeof productData] === undefined) {
          delete productData[key as keyof typeof productData];
        }
      });

      let savedProductId = productId;

      if (productId) {
        // Update existing product
        const { error } = await supabase
          .from('products')
          .update(productData)
          .eq('id', productId);

        if (error) throw error;
      } else {
        // Create new product - add required fields for insert
        const newProductData = {
          ...productData,
          slug, // Ensure slug is included for new products
          created_at: new Date().toISOString(),
        };

        const { data, error } = await supabase
          .from('products')
          .insert(newProductData)
          .select()
          .single();

        if (error) {
          console.error('Error creating product:', error);
          throw error;
        }
        savedProductId = data.id;
      }

      // Save images
      if (savedProductId && images.length > 0) {
        // Delete existing images
        await supabase
          .from('product_images')
          .delete()
          .eq('product_id', savedProductId);

        // Insert new images
        const imageData = images.map((img, idx) => ({
          product_id: savedProductId,
          image_url: img.image_url,
          position: idx,
          image_type: idx === 0 ? 'primary' : 'additional',
        }));

        const { error: imageError } = await supabase
          .from('product_images')
          .insert(imageData);

        if (imageError) throw imageError;
      }

      // Save variants/sizes
      const enabledSizes = sizes.filter(s => s.enabled);
      if (savedProductId && enabledSizes.length > 0) {
        // Delete existing variants
        await supabase
          .from('product_variants')
          .delete()
          .eq('product_id', savedProductId);

        // Insert new variants with all required fields
        const variantData = enabledSizes.map((size, idx) => ({
          product_id: savedProductId,
          size: size.size,
          sku: size.sku || `${sku}-${size.size}`, // Ensure SKU is always present
          price: size.price || parseFloat(price),
          inventory_quantity: size.inventory || 0,
          is_active: true,
          position: idx,
          created_at: new Date().toISOString(),
          updated_at: new Date().toISOString(),
        }));

        const { error: variantError } = await supabase
          .from('product_variants')
          .insert(variantData);

        if (variantError) {
          console.error('Error saving variants:', variantError);
          throw variantError;
        }
      }

      toast.success(productId ? 'Product updated successfully' : 'Product created successfully');
      
      if (onSave) onSave();
    } catch (error) {
      console.error('Error saving product:', error);
      toast.error('Failed to save product');
    } finally {
      setIsSaving(false);
    }
  };

  return (
    <div className="max-w-6xl mx-auto p-6 space-y-6">
      {/* Header */}
      <div className="flex items-center justify-between">
        <h2 className="text-2xl font-bold">
          {productId ? 'Edit Product' : 'Add New Product'}
        </h2>
        <div className="flex gap-2">
          <Button variant="outline" onClick={onCancel}>
            Cancel
          </Button>
          <Button onClick={handleSave} disabled={isSaving}>
            <Save className="h-4 w-4 mr-2" />
            {isSaving ? 'Saving...' : 'Save Product'}
          </Button>
        </div>
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
        {/* Left Column - Basic Info & Images */}
        <div className="space-y-6">
          {/* Basic Information */}
          <Card className="p-6">
            <h3 className="text-lg font-semibold mb-4">Basic Information</h3>
            
            <div className="space-y-4">
              <div>
                <Label htmlFor="name">Product Name *</Label>
                <Input
                  id="name"
                  value={name}
                  onChange={(e) => setName(e.target.value)}
                  placeholder="e.g., Men's Classic Navy Suit"
                />
              </div>

              <div className="grid grid-cols-2 gap-4">
                <div>
                  <Label htmlFor="sku">SKU *</Label>
                  <Input
                    id="sku"
                    value={sku}
                    onChange={(e) => setSku(e.target.value)}
                    placeholder="e.g., SUIT-NAV-001"
                  />
                </div>
                <div>
                  <Label htmlFor="price">Base Price *</Label>
                  <Input
                    id="price"
                    type="number"
                    value={price}
                    onChange={(e) => setPrice(e.target.value)}
                    placeholder="229.99"
                  />
                </div>
              </div>

              <div className="grid grid-cols-2 gap-4">
                <div>
                  <Label htmlFor="category">Category</Label>
                  <Input
                    id="category"
                    value={category}
                    onChange={(e) => setCategory(e.target.value)}
                    placeholder="e.g., Suits"
                  />
                </div>
                <div>
                  <Label htmlFor="type">Product Type</Label>
                  <select
                    id="type"
                    className="w-full h-10 px-3 border rounded-md"
                    value={productType}
                    onChange={(e) => setProductType(e.target.value as any)}
                  >
                    <option value="suits">Suits</option>
                    <option value="shirts">Shirts</option>
                    <option value="ties">Ties</option>
                    <option value="accessories">Accessories</option>
                  </select>
                </div>
              </div>

              <div>
                <Label htmlFor="description">Description</Label>
                <Textarea
                  id="description"
                  value={description}
                  onChange={(e) => setDescription(e.target.value)}
                  placeholder="Product description..."
                  rows={4}
                />
              </div>

              <div className="flex items-center space-x-2">
                <Checkbox
                  id="active"
                  checked={isActive}
                  onCheckedChange={(checked) => setIsActive(checked as boolean)}
                />
                <Label htmlFor="active">Product is active</Label>
              </div>
            </div>
          </Card>

          {/* Product Images */}
          <Card className="p-6">
            <h3 className="text-lg font-semibold mb-4">Product Images</h3>
            
            <div className="space-y-4">
              {/* Upload area */}
              <div className="border-2 border-dashed rounded-lg p-4">
                <input
                  type="file"
                  id="image-upload"
                  multiple
                  accept="image/*"
                  onChange={handleImageUpload}
                  className="hidden"
                />
                <label
                  htmlFor="image-upload"
                  className="flex flex-col items-center cursor-pointer"
                >
                  <Upload className="h-8 w-8 text-gray-400 mb-2" />
                  <span className="text-sm text-gray-600">
                    {uploadingImage ? 'Uploading...' : 'Click to upload images'}
                  </span>
                </label>
              </div>

              {/* Image grid */}
              {images.length > 0 && (
                <div className="grid grid-cols-4 gap-2">
                  {images.map((image, index) => (
                    <div key={index} className="relative group">
                      <img
                        src={image.image_url}
                        alt={`Product ${index + 1}`}
                        className="w-full h-24 object-cover rounded border"
                      />
                      {index === 0 && (
                        <span className="absolute top-1 left-1 bg-black text-white text-xs px-1 rounded">
                          Main
                        </span>
                      )}
                      <button
                        onClick={() => removeImage(index)}
                        className="absolute top-1 right-1 bg-red-500 text-white p-1 rounded opacity-0 group-hover:opacity-100 transition"
                      >
                        <X className="h-3 w-3" />
                      </button>
                    </div>
                  ))}
                </div>
              )}
            </div>
          </Card>
        </div>

        {/* Right Column - Sizes & Details */}
        <div className="space-y-6">
          {/* Size Variants */}
          <Card className="p-6">
            <div className="flex items-center justify-between mb-4">
              <h3 className="text-lg font-semibold">Size Variants</h3>
              {productType === 'suits' && (
                <div className="flex items-center space-x-2">
                  <Checkbox
                    id="long-sizes"
                    checked={showLongSizes}
                    onCheckedChange={(checked) => {
                      setShowLongSizes(checked as boolean);
                    }}
                  />
                  <Label htmlFor="long-sizes">Include Long sizes</Label>
                </div>
              )}
            </div>

            <div className="space-y-4">
              {/* Size grid */}
              <div className="border rounded-lg p-4">
                <div className="grid grid-cols-3 gap-2">
                  {sizes.map((size, index) => (
                    <div key={size.size} className="flex items-center space-x-2">
                      <Checkbox
                        checked={size.enabled}
                        onCheckedChange={() => toggleSize(index)}
                      />
                      <Label className="flex-1">{size.size}</Label>
                      {size.enabled && (
                        <Input
                          type="number"
                          value={size.inventory}
                          onChange={(e) => updateSizeInventory(index, e.target.value)}
                          className="w-16 h-8"
                          placeholder="0"
                        />
                      )}
                    </div>
                  ))}
                </div>
              </div>

              {/* Quick actions */}
              <div className="flex gap-2">
                <Button
                  size="sm"
                  variant="outline"
                  onClick={() => {
                    const newSizes = sizes.map(s => ({ ...s, enabled: true }));
                    setSizes(newSizes);
                  }}
                >
                  Select All
                </Button>
                <Button
                  size="sm"
                  variant="outline"
                  onClick={() => {
                    const newSizes = sizes.map(s => ({ ...s, enabled: false }));
                    setSizes(newSizes);
                  }}
                >
                  Clear All
                </Button>
              </div>
            </div>
          </Card>

          {/* Product Details */}
          <Card className="p-6">
            <h3 className="text-lg font-semibold mb-4">Product Details</h3>
            
            <div className="space-y-2">
              {details.map((detail, index) => (
                <div key={index} className="flex gap-2">
                  <Input
                    value={detail}
                    onChange={(e) => updateDetail(index, e.target.value)}
                    placeholder="e.g., Premium wool blend fabric"
                  />
                  <Button
                    size="sm"
                    variant="ghost"
                    onClick={() => removeDetail(index)}
                  >
                    <X className="h-4 w-4" />
                  </Button>
                </div>
              ))}
              <Button
                size="sm"
                variant="outline"
                onClick={addDetail}
                className="w-full"
              >
                <Plus className="h-4 w-4 mr-2" />
                Add Detail
              </Button>
            </div>
          </Card>
        </div>
      </div>
    </div>
  );
}