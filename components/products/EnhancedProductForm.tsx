import React, { useState, useCallback, useRef } from 'react';
import {
  Save, X, Upload, Plus, Trash2, Image as ImageIcon, 
  Video, ChevronDown, ChevronRight, Info, AlertCircle,
  Sparkles, Package, Tag, DollarSign, Palette, Ruler,
  Calendar, Globe, Search, Loader, Check, Copy, Eye
} from 'lucide-react';

// Enhanced Product Form Types
interface ProductFormData {
  // Basic Information
  name: string;
  sku: string;
  handle: string;
  styleCode: string;
  
  // Categorization
  category: string;
  subcategory: string;
  collection: string;
  season: string;
  occasion: string[];
  
  // Pricing (20-tier system)
  priceTier: string;
  basePrice: number;
  compareAtPrice?: number;
  costPerUnit?: number;
  
  // Images (flexible 1-9+ system)
  images: {
    hero?: ImageUpload;
    flat?: ImageUpload;
    lifestyle: ImageUpload[];
    details: ImageUpload[];
    variants: Record<string, ImageUpload[]>;
    video?: VideoUpload;
  };
  
  // Product Details
  description: string;
  colorFamily: string;
  colorName: string;
  materials: {
    primary: string;
    composition: Record<string, number>;
  };
  careInstructions: string[];
  features: string[];
  fitType: string;
  
  // Variants & Inventory
  sizeRange: {
    min: string;
    max: string;
    available: string[];
  };
  variants: ProductVariant[];
  trackInventory: boolean;
  
  // SEO & Marketing
  metaTitle: string;
  metaDescription: string;
  tags: string[];
  
  // Status
  status: 'draft' | 'active' | 'archived';
  launchDate?: string;
}

interface ImageUpload {
  id: string;
  url: string;
  file?: File;
  alt: string;
  isPrimary?: boolean;
}

interface VideoUpload {
  url: string;
  thumbnail: string;
  duration?: number;
}

interface ProductVariant {
  id: string;
  color: string;
  size: string;
  sku: string;
  price?: number;
  inventory: number;
  images?: ImageUpload[];
}

// Price Tiers Configuration
const PRICE_TIERS = Array.from({ length: 20 }, (_, i) => ({
  id: `TIER_${i + 1}`,
  label: `Tier ${i + 1}`,
  range: getPriceRange(i + 1),
  value: i + 1
}));

function getPriceRange(tier: number): string {
  const ranges = [
    '$50-74', '$75-99', '$100-124', '$125-149', '$150-199',
    '$200-249', '$250-299', '$300-399', '$400-499', '$500-599',
    '$600-699', '$700-799', '$800-899', '$900-999', '$1000-1249',
    '$1250-1499', '$1500-1999', '$2000-2999', '$3000-4999', '$5000+'
  ];
  return ranges[tier - 1] || '';
}

export default function EnhancedProductForm({ 
  initialData,
  onSave,
  onCancel 
}: {
  initialData?: Partial<ProductFormData>;
  onSave: (data: ProductFormData) => void;
  onCancel: () => void;
}) {
  const [formData, setFormData] = useState<ProductFormData>({
    name: '',
    sku: '',
    handle: '',
    styleCode: '',
    category: '',
    subcategory: '',
    collection: '',
    season: 'FW24',
    occasion: [],
    priceTier: 'TIER_1',
    basePrice: 0,
    images: {
      lifestyle: [],
      details: [],
      variants: {}
    },
    description: '',
    colorFamily: '',
    colorName: '',
    materials: {
      primary: '',
      composition: {}
    },
    careInstructions: [],
    features: [],
    fitType: 'Regular',
    sizeRange: {
      min: 'XS',
      max: '3XL',
      available: []
    },
    variants: [],
    trackInventory: true,
    metaTitle: '',
    metaDescription: '',
    tags: [],
    status: 'draft',
    ...initialData
  });

  const [activeSection, setActiveSection] = useState<string>('basic');
  const [errors, setErrors] = useState<Record<string, string>>({});
  const [isSaving, setIsSaving] = useState(false);
  const [showPreview, setShowPreview] = useState(false);
  
  const fileInputRef = useRef<HTMLInputElement>(null);

  // Handle form field changes
  const handleChange = useCallback((field: string, value: any) => {
    setFormData(prev => ({
      ...prev,
      [field]: value
    }));
    
    // Clear error for this field
    if (errors[field]) {
      setErrors(prev => {
        const newErrors = { ...prev };
        delete newErrors[field];
        return newErrors;
      });
    }
  }, [errors]);

  // Handle image upload
  const handleImageUpload = useCallback((type: string, files: FileList) => {
    const newImages: ImageUpload[] = Array.from(files).map(file => ({
      id: Math.random().toString(36).substr(2, 9),
      url: URL.createObjectURL(file),
      file,
      alt: file.name
    }));

    setFormData(prev => {
      const updatedImages = { ...prev.images };
      
      if (type === 'hero' || type === 'flat') {
        updatedImages[type] = newImages[0];
      } else if (type === 'lifestyle' || type === 'details') {
        updatedImages[type] = [...(updatedImages[type] || []), ...newImages];
      }
      
      return { ...prev, images: updatedImages };
    });
  }, []);

  // Validate form
  const validateForm = useCallback((): boolean => {
    const newErrors: Record<string, string> = {};
    
    if (!formData.name) newErrors.name = 'Product name is required';
    if (!formData.sku) newErrors.sku = 'SKU is required';
    if (!formData.category) newErrors.category = 'Category is required';
    if (!formData.priceTier) newErrors.priceTier = 'Price tier is required';
    if (!formData.basePrice || formData.basePrice <= 0) {
      newErrors.basePrice = 'Base price must be greater than 0';
    }
    
    // Check for at least one image
    const hasImages = formData.images.hero || 
                     formData.images.flat || 
                     formData.images.lifestyle.length > 0;
    if (!hasImages) {
      newErrors.images = 'At least one product image is required';
    }
    
    setErrors(newErrors);
    return Object.keys(newErrors).length === 0;
  }, [formData]);

  // Handle form submission
  const handleSubmit = useCallback(async () => {
    if (!validateForm()) {
      return;
    }
    
    setIsSaving(true);
    try {
      await onSave(formData);
    } catch (error) {
      console.error('Error saving product:', error);
    } finally {
      setIsSaving(false);
    }
  }, [formData, validateForm, onSave]);

  return (
    <div className="min-h-screen bg-gray-50">
      {/* Header */}
      <div className="bg-white border-b border-gray-200 sticky top-0 z-30">
        <div className="px-6 py-4">
          <div className="flex items-center justify-between">
            <div className="flex items-center space-x-4">
              <button
                onClick={onCancel}
                className="p-2 hover:bg-gray-100 rounded-lg"
              >
                <X className="w-5 h-5" />
              </button>
              <h1 className="text-2xl font-bold text-gray-900">
                {initialData ? 'Edit Product' : 'Add New Product'}
              </h1>
              <span className={`px-3 py-1 rounded-full text-sm font-medium ${
                formData.status === 'active' 
                  ? 'bg-green-100 text-green-800'
                  : formData.status === 'draft'
                  ? 'bg-gray-100 text-gray-800'
                  : 'bg-red-100 text-red-800'
              }`}>
                {formData.status}
              </span>
            </div>
            
            <div className="flex items-center space-x-3">
              <button
                onClick={() => setShowPreview(!showPreview)}
                className="flex items-center px-4 py-2 border border-gray-300 rounded-lg hover:bg-gray-50"
              >
                <Eye className="w-4 h-4 mr-2" />
                Preview
              </button>
              <button
                onClick={() => handleChange('status', 'draft')}
                className="px-4 py-2 border border-gray-300 rounded-lg hover:bg-gray-50"
              >
                Save as Draft
              </button>
              <button
                onClick={handleSubmit}
                disabled={isSaving}
                className="flex items-center px-4 py-2 bg-black text-white rounded-lg hover:bg-gray-800 disabled:opacity-50"
              >
                {isSaving ? (
                  <Loader className="w-4 h-4 mr-2 animate-spin" />
                ) : (
                  <Save className="w-4 h-4 mr-2" />
                )}
                {isSaving ? 'Saving...' : 'Save Product'}
              </button>
            </div>
          </div>
        </div>
      </div>

      <div className="flex">
        {/* Sidebar Navigation */}
        <div className="w-64 bg-white border-r border-gray-200 min-h-screen">
          <nav className="p-4 space-y-1">
            {[
              { id: 'basic', label: 'Basic Information', icon: Package },
              { id: 'images', label: 'Images & Media', icon: ImageIcon },
              { id: 'categorization', label: 'Categorization', icon: Tag },
              { id: 'pricing', label: 'Pricing & Inventory', icon: DollarSign },
              { id: 'details', label: 'Product Details', icon: Sparkles },
              { id: 'variants', label: 'Variants & Sizes', icon: Ruler },
              { id: 'seo', label: 'SEO & Marketing', icon: Globe }
            ].map(section => (
              <button
                key={section.id}
                onClick={() => setActiveSection(section.id)}
                className={`w-full flex items-center px-3 py-2 rounded-lg text-sm font-medium transition ${
                  activeSection === section.id
                    ? 'bg-black text-white'
                    : 'text-gray-700 hover:bg-gray-100'
                }`}
              >
                <section.icon className="w-4 h-4 mr-3" />
                {section.label}
                {errors[section.id] && (
                  <AlertCircle className="w-4 h-4 ml-auto text-red-500" />
                )}
              </button>
            ))}
          </nav>
        </div>

        {/* Main Form Content */}
        <div className="flex-1 p-6">
          <div className="max-w-4xl mx-auto">
            {/* Basic Information Section */}
            {activeSection === 'basic' && (
              <FormSection title="Basic Information">
                <div className="grid grid-cols-2 gap-6">
                  <FormField
                    label="Product Name"
                    required
                    error={errors.name}
                  >
                    <input
                      type="text"
                      value={formData.name}
                      onChange={(e) => handleChange('name', e.target.value)}
                      placeholder="Premium Velvet Blazer"
                      className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-black focus:border-transparent"
                    />
                  </FormField>

                  <FormField
                    label="Style Code"
                    tooltip="Internal style number for tracking"
                  >
                    <input
                      type="text"
                      value={formData.styleCode}
                      onChange={(e) => handleChange('styleCode', e.target.value)}
                      placeholder="FW24-VB-001"
                      className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-black focus:border-transparent"
                    />
                  </FormField>

                  <FormField
                    label="SKU"
                    required
                    error={errors.sku}
                  >
                    <input
                      type="text"
                      value={formData.sku}
                      onChange={(e) => handleChange('sku', e.target.value)}
                      placeholder="VB-001-NVY"
                      className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-black focus:border-transparent"
                    />
                  </FormField>

                  <FormField
                    label="URL Handle"
                    tooltip="URL-friendly version of the product name"
                  >
                    <input
                      type="text"
                      value={formData.handle}
                      onChange={(e) => handleChange('handle', e.target.value)}
                      placeholder="premium-velvet-blazer"
                      className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-black focus:border-transparent"
                    />
                  </FormField>
                </div>

                <FormField
                  label="Description"
                  className="mt-6"
                >
                  <textarea
                    value={formData.description}
                    onChange={(e) => handleChange('description', e.target.value)}
                    rows={4}
                    placeholder="Enter product description..."
                    className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-black focus:border-transparent"
                  />
                </FormField>
              </FormSection>
            )}

            {/* Images & Media Section */}
            {activeSection === 'images' && (
              <FormSection title="Images & Media">
                {errors.images && (
                  <div className="mb-4 p-3 bg-red-50 border border-red-200 rounded-lg text-red-700 text-sm">
                    {errors.images}
                  </div>
                )}

                {/* Hero Image */}
                <div className="mb-6">
                  <label className="block text-sm font-medium text-gray-700 mb-2">
                    Hero Image (Primary)
                    <span className="text-red-500 ml-1">*</span>
                  </label>
                  <ImageUploadZone
                    images={formData.images.hero ? [formData.images.hero] : []}
                    onUpload={(files) => handleImageUpload('hero', files)}
                    onRemove={() => handleChange('images', { ...formData.images, hero: undefined })}
                    maxImages={1}
                    label="Main product image - shown in listings"
                  />
                </div>

                {/* Flat Lay Image */}
                <div className="mb-6">
                  <label className="block text-sm font-medium text-gray-700 mb-2">
                    Flat Lay Image
                    <span className="text-amber-500 ml-1">(Recommended)</span>
                  </label>
                  <ImageUploadZone
                    images={formData.images.flat ? [formData.images.flat] : []}
                    onUpload={(files) => handleImageUpload('flat', files)}
                    onRemove={() => handleChange('images', { ...formData.images, flat: undefined })}
                    maxImages={1}
                    label="Product laid flat - industry standard for fashion"
                  />
                </div>

                {/* Lifestyle Images */}
                <div className="mb-6">
                  <label className="block text-sm font-medium text-gray-700 mb-2">
                    Lifestyle Images (2-4 recommended)
                  </label>
                  <ImageUploadZone
                    images={formData.images.lifestyle}
                    onUpload={(files) => handleImageUpload('lifestyle', files)}
                    onRemove={(id) => {
                      const updated = formData.images.lifestyle.filter(img => img.id !== id);
                      handleChange('images', { ...formData.images, lifestyle: updated });
                    }}
                    maxImages={9}
                    label="Styled shots showing the product in context"
                  />
                </div>

                {/* Detail Shots */}
                <div className="mb-6">
                  <label className="block text-sm font-medium text-gray-700 mb-2">
                    Detail Shots (3-5 recommended)
                  </label>
                  <ImageUploadZone
                    images={formData.images.details}
                    onUpload={(files) => handleImageUpload('details', files)}
                    onRemove={(id) => {
                      const updated = formData.images.details.filter(img => img.id !== id);
                      handleChange('images', { ...formData.images, details: updated });
                    }}
                    maxImages={9}
                    label="Close-ups of fabric, stitching, buttons, patterns"
                  />
                </div>

                {/* Video Upload */}
                <div className="mb-6">
                  <label className="block text-sm font-medium text-gray-700 mb-2">
                    Product Video (Optional)
                  </label>
                  <div className="border-2 border-dashed border-gray-300 rounded-lg p-6 text-center hover:border-gray-400 transition">
                    <Video className="w-8 h-8 mx-auto text-gray-400 mb-2" />
                    <p className="text-sm text-gray-600">
                      Upload video showing movement and texture
                    </p>
                    <button className="mt-3 px-4 py-2 bg-gray-100 text-gray-700 rounded-lg hover:bg-gray-200 text-sm">
                      Choose Video
                    </button>
                  </div>
                </div>

                {/* Image Count Summary */}
                <div className="bg-gray-50 rounded-lg p-4">
                  <h4 className="text-sm font-medium text-gray-700 mb-2">Image Summary</h4>
                  <div className="grid grid-cols-2 gap-2 text-sm">
                    <div>Hero: {formData.images.hero ? '✓' : '—'}</div>
                    <div>Flat: {formData.images.flat ? '✓' : '—'}</div>
                    <div>Lifestyle: {formData.images.lifestyle.length}</div>
                    <div>Details: {formData.images.details.length}</div>
                    <div className="col-span-2 font-medium mt-2">
                      Total Images: {
                        (formData.images.hero ? 1 : 0) +
                        (formData.images.flat ? 1 : 0) +
                        formData.images.lifestyle.length +
                        formData.images.details.length
                      }
                    </div>
                  </div>
                </div>
              </FormSection>
            )}

            {/* Pricing & Inventory Section */}
            {activeSection === 'pricing' && (
              <FormSection title="Pricing & Inventory">
                <div className="space-y-6">
                  {/* Price Tier Selector */}
                  <FormField
                    label="Price Tier"
                    required
                    error={errors.priceTier}
                  >
                    <PriceTierSelector
                      value={formData.priceTier}
                      onChange={(tier) => handleChange('priceTier', tier)}
                    />
                  </FormField>

                  <div className="grid grid-cols-3 gap-6">
                    <FormField
                      label="Base Price"
                      required
                      error={errors.basePrice}
                    >
                      <div className="relative">
                        <span className="absolute left-3 top-1/2 transform -translate-y-1/2 text-gray-500">
                          $
                        </span>
                        <input
                          type="number"
                          value={(formData.basePrice / 100).toFixed(2)}
                          onChange={(e) => handleChange('basePrice', Math.round(parseFloat(e.target.value) * 100))}
                          placeholder="0.00"
                          className="w-full pl-8 pr-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-black focus:border-transparent"
                        />
                      </div>
                    </FormField>

                    <FormField
                      label="Compare at Price"
                      tooltip="Original price for showing discounts"
                    >
                      <div className="relative">
                        <span className="absolute left-3 top-1/2 transform -translate-y-1/2 text-gray-500">
                          $
                        </span>
                        <input
                          type="number"
                          value={formData.compareAtPrice ? (formData.compareAtPrice / 100).toFixed(2) : ''}
                          onChange={(e) => handleChange('compareAtPrice', e.target.value ? Math.round(parseFloat(e.target.value) * 100) : undefined)}
                          placeholder="0.00"
                          className="w-full pl-8 pr-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-black focus:border-transparent"
                        />
                      </div>
                    </FormField>

                    <FormField
                      label="Cost per Unit"
                      tooltip="Your cost for margin calculations"
                    >
                      <div className="relative">
                        <span className="absolute left-3 top-1/2 transform -translate-y-1/2 text-gray-500">
                          $
                        </span>
                        <input
                          type="number"
                          value={formData.costPerUnit ? (formData.costPerUnit / 100).toFixed(2) : ''}
                          onChange={(e) => handleChange('costPerUnit', e.target.value ? Math.round(parseFloat(e.target.value) * 100) : undefined)}
                          placeholder="0.00"
                          className="w-full pl-8 pr-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-black focus:border-transparent"
                        />
                      </div>
                    </FormField>
                  </div>

                  {/* Inventory Tracking */}
                  <div className="border border-gray-200 rounded-lg p-4">
                    <div className="flex items-center justify-between mb-4">
                      <label className="flex items-center">
                        <input
                          type="checkbox"
                          checked={formData.trackInventory}
                          onChange={(e) => handleChange('trackInventory', e.target.checked)}
                          className="rounded border-gray-300 text-black focus:ring-black"
                        />
                        <span className="ml-2 text-sm font-medium text-gray-700">
                          Track inventory for this product
                        </span>
                      </label>
                    </div>

                    {formData.trackInventory && (
                      <div className="grid grid-cols-2 gap-4 text-sm">
                        <div className="p-3 bg-gray-50 rounded-lg">
                          <div className="text-gray-600">Total Stock</div>
                          <div className="text-2xl font-bold text-gray-900">0</div>
                        </div>
                        <div className="p-3 bg-gray-50 rounded-lg">
                          <div className="text-gray-600">Reserved</div>
                          <div className="text-2xl font-bold text-gray-900">0</div>
                        </div>
                      </div>
                    )}
                  </div>
                </div>
              </FormSection>
            )}
          </div>
        </div>
      </div>
    </div>
  );
}

// Form Section Component
function FormSection({ title, children }: { title: string; children: React.ReactNode }) {
  return (
    <div className="bg-white rounded-lg shadow-sm border border-gray-200 p-6">
      <h2 className="text-lg font-semibold text-gray-900 mb-6">{title}</h2>
      {children}
    </div>
  );
}

// Form Field Component
function FormField({ 
  label, 
  required, 
  error, 
  tooltip, 
  className = '',
  children 
}: { 
  label: string;
  required?: boolean;
  error?: string;
  tooltip?: string;
  className?: string;
  children: React.ReactNode;
}) {
  return (
    <div className={className}>
      <label className="block text-sm font-medium text-gray-700 mb-2">
        {label}
        {required && <span className="text-red-500 ml-1">*</span>}
        {tooltip && (
          <span className="ml-2 inline-flex">
            <Info className="w-4 h-4 text-gray-400" />
          </span>
        )}
      </label>
      {children}
      {error && (
        <p className="mt-1 text-sm text-red-600">{error}</p>
      )}
    </div>
  );
}

// Image Upload Zone Component
function ImageUploadZone({
  images = [],
  onUpload,
  onRemove,
  maxImages = 9,
  label
}: {
  images: ImageUpload[];
  onUpload: (files: FileList) => void;
  onRemove: (id?: string) => void;
  maxImages?: number;
  label?: string;
}) {
  const inputRef = useRef<HTMLInputElement>(null);
  
  return (
    <div>
      <div className="grid grid-cols-4 gap-4">
        {images.map((image) => (
          <div key={image.id} className="relative group">
            <img
              src={image.url}
              alt={image.alt}
              className="w-full aspect-square object-cover rounded-lg"
            />
            <button
              onClick={() => onRemove(image.id)}
              className="absolute top-2 right-2 p-1 bg-red-500 text-white rounded-lg opacity-0 group-hover:opacity-100 transition"
            >
              <Trash2 className="w-4 h-4" />
            </button>
          </div>
        ))}
        
        {images.length < maxImages && (
          <button
            onClick={() => inputRef.current?.click()}
            className="aspect-square border-2 border-dashed border-gray-300 rounded-lg hover:border-gray-400 transition flex flex-col items-center justify-center"
          >
            <Plus className="w-6 h-6 text-gray-400 mb-1" />
            <span className="text-xs text-gray-500">Add Image</span>
          </button>
        )}
      </div>
      
      {label && (
        <p className="mt-2 text-xs text-gray-500">{label}</p>
      )}
      
      <input
        ref={inputRef}
        type="file"
        multiple
        accept="image/*"
        onChange={(e) => e.target.files && onUpload(e.target.files)}
        className="hidden"
      />
    </div>
  );
}

// Price Tier Selector Component
function PriceTierSelector({
  value,
  onChange
}: {
  value: string;
  onChange: (tier: string) => void;
}) {
  const currentTier = PRICE_TIERS.find(t => t.id === value) || PRICE_TIERS[0];
  
  return (
    <div className="space-y-4">
      <div className="flex items-center justify-between">
        <div className="flex items-center space-x-3">
          <span className="px-3 py-1 bg-black text-white rounded-lg text-sm font-medium">
            {currentTier.id}
          </span>
          <span className="text-lg font-semibold">{currentTier.range}</span>
        </div>
      </div>
      
      <div className="relative">
        <input
          type="range"
          min="1"
          max="20"
          value={currentTier.value}
          onChange={(e) => onChange(`TIER_${e.target.value}`)}
          className="w-full h-2 bg-gray-200 rounded-lg appearance-none cursor-pointer slider"
        />
        <div className="flex justify-between mt-2">
          {[1, 5, 10, 15, 20].map(tier => (
            <button
              key={tier}
              onClick={() => onChange(`TIER_${tier}`)}
              className="text-xs text-gray-500 hover:text-gray-700"
            >
              T{tier}
            </button>
          ))}
        </div>
      </div>
      
      <div className="grid grid-cols-4 gap-2">
        {PRICE_TIERS.map((tier) => (
          <button
            key={tier.id}
            onClick={() => onChange(tier.id)}
            className={`p-2 text-xs rounded-lg transition ${
              tier.id === value
                ? 'bg-black text-white'
                : 'bg-gray-100 text-gray-700 hover:bg-gray-200'
            }`}
          >
            {tier.label}
          </button>
        ))}
      </div>
    </div>
  );
}