import React, { useState, useEffect } from 'react';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { Label } from '@/components/ui/label';
import { Textarea } from '@/components/ui/textarea';
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from '@/components/ui/select';
import { Tabs, TabsContent, TabsList, TabsTrigger } from '@/components/ui/tabs';
import { Save, X } from 'lucide-react';
import { DraggableImageGallery } from './DraggableImageGallery';

interface EnhancedProduct {
  id: string;
  name: string;
  sku: string;
  handle: string;
  slug?: string;
  style_code?: string;
  season?: string;
  collection?: string;
  category: string;
  subcategory?: string;
  price_tier: string;
  base_price: number;
  compare_at_price?: number;
  color_family?: string;
  color_name?: string;
  materials?: any;
  fit_type?: string;
  images?: any;
  description?: string;
  status: string;
  stripe_product_id?: string;
  stripe_active?: boolean;
  // SEO Fields
  meta_title?: string;
  meta_description?: string;
  meta_keywords?: string[];
  og_title?: string;
  og_description?: string;
  og_image?: string;
  canonical_url?: string;
  structured_data?: any;
  tags?: string[];
  search_terms?: string;
  url_slug?: string;
  is_indexable?: boolean;
  sitemap_priority?: number;
  sitemap_change_freq?: string;
  created_at: string;
  updated_at: string;
}

const PRICE_TIERS = [
  { value: 'TIER_1', label: 'Tier 1 ($50-74)', min: 5000, max: 7499 },
  { value: 'TIER_2', label: 'Tier 2 ($75-99)', min: 7500, max: 9999 },
  { value: 'TIER_3', label: 'Tier 3 ($100-124)', min: 10000, max: 12499 },
  { value: 'TIER_4', label: 'Tier 4 ($125-149)', min: 12500, max: 14999 },
  { value: 'TIER_5', label: 'Tier 5 ($150-199)', min: 15000, max: 19999 },
  { value: 'TIER_6', label: 'Tier 6 ($200-249)', min: 20000, max: 24999 },
  { value: 'TIER_7', label: 'Tier 7 ($250-299)', min: 25000, max: 29999 },
  { value: 'TIER_8', label: 'Tier 8 ($300-399)', min: 30000, max: 39999 },
  { value: 'TIER_9', label: 'Tier 9 ($400-499)', min: 40000, max: 49999 },
  { value: 'TIER_10', label: 'Tier 10 ($500-599)', min: 50000, max: 59999 },
];

const CATEGORIES = ['Blazers', 'Suits', 'Shirts', 'Pants', 'Accessories'];
const SUBCATEGORIES = ['Prom', 'Velvet', 'Summer', 'Sparkle', 'Formal', 'Casual'];
const STATUSES = ['active', 'draft', 'archived'];

interface ProductFormProps {
  product: EnhancedProduct | null;
  onSave: (product: Partial<EnhancedProduct>) => void;
  onCancel: () => void;
}

export function ProductForm({ 
  product, 
  onSave, 
  onCancel 
}: ProductFormProps) {
  // State for gallery images
  const [galleryImages, setGalleryImages] = useState<any[]>([]);
  
  const [formData, setFormData] = useState<Partial<EnhancedProduct>>({
    name: product?.name || '',
    sku: product?.sku || '',
    category: product?.category || 'Blazers',
    subcategory: product?.subcategory || '',
    price_tier: product?.price_tier || 'TIER_7',
    base_price: product?.base_price || 27999,
    compare_at_price: product?.compare_at_price || 0,
    description: product?.description || '',
    status: product?.status || 'active',
    style_code: product?.style_code || '',
    season: product?.season || 'SS24',
    collection: product?.collection || '',
    color_family: product?.color_family || '',
    color_name: product?.color_name || '',
    fit_type: product?.fit_type || 'Slim Fit',
    materials: product?.materials || {},
    images: product?.images || {
      hero: null,
      flat: null,
      lifestyle: [],
      details: [],
      total_images: 0
    },
    meta_title: product?.meta_title || '',
    meta_description: product?.meta_description || '',
    tags: product?.tags || [],
    url_slug: product?.url_slug || product?.handle || '',
    canonical_url: product?.canonical_url || '',
    og_title: product?.og_title || '',
    og_description: product?.og_description || '',
    og_image: product?.og_image || '',
    sitemap_priority: product?.sitemap_priority || 0.8,
    sitemap_change_freq: product?.sitemap_change_freq || 'weekly',
    is_indexable: product?.is_indexable !== false
  });

  // Convert images when product loads
  useEffect(() => {
    if (product?.images) {
      const images = [];
      let position = 0;
      
      // Add hero image if exists
      if (product.images.hero?.url) {
        images.push({
          url: product.images.hero.url,
          position: position++,
          is_primary: true,
          image_type: 'primary',
          alt_text: product.images.hero.alt || ''
        });
      }
      
      // Add flat image if exists
      if (product.images.flat?.url) {
        images.push({
          url: product.images.flat.url,
          position: position++,
          is_primary: images.length === 0,
          image_type: images.length === 0 ? 'primary' : 'gallery',
          alt_text: product.images.flat.alt || ''
        });
      }
      
      // Add lifestyle images
      if (product.images.lifestyle?.length > 0) {
        product.images.lifestyle.forEach((img: any) => {
          if (img.url) {
            images.push({
              url: img.url,
              position: position++,
              is_primary: images.length === 0,
              image_type: images.length === 0 ? 'primary' : 'gallery',
              alt_text: img.alt || ''
            });
          }
        });
      }
      
      // Add detail images
      if (product.images.details?.length > 0) {
        product.images.details.forEach((img: any) => {
          if (img.url) {
            images.push({
              url: img.url,
              position: position++,
              is_primary: images.length === 0,
              image_type: images.length === 0 ? 'primary' : 'gallery',
              alt_text: img.alt || ''
            });
          }
        });
      }
      
      setGalleryImages(images);
    }
  }, [product]);

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    onSave(formData);
  };

  const updateImages = (field: string, value: any) => {
    setFormData(prev => ({
      ...prev,
      images: {
        ...prev.images,
        [field]: value,
        total_images: calculateTotalImages({ ...prev.images, [field]: value })
      }
    }));
  };

  const calculateTotalImages = (images: any) => {
    let count = 0;
    if (images?.hero) count++;
    if (images?.flat) count++;
    count += (images?.lifestyle?.length || 0);
    count += (images?.details?.length || 0);
    return count;
  };

  return (
    <form onSubmit={handleSubmit} className="space-y-6">
      <Tabs defaultValue="basic" className="w-full">
        <TabsList className="grid w-full grid-cols-5">
          <TabsTrigger value="basic">Basic Info</TabsTrigger>
          <TabsTrigger value="pricing">Pricing</TabsTrigger>
          <TabsTrigger value="images">Images</TabsTrigger>
          <TabsTrigger value="details">Details</TabsTrigger>
          <TabsTrigger value="seo">SEO</TabsTrigger>
        </TabsList>
        
        <TabsContent value="basic" className="space-y-4">
          <div className="grid grid-cols-2 gap-4">
            <div>
              <Label htmlFor="name">Product Name*</Label>
              <Input
                id="name"
                value={formData.name}
                onChange={(e) => setFormData({...formData, name: e.target.value})}
                required
              />
            </div>
            <div>
              <Label htmlFor="sku">SKU*</Label>
              <Input
                id="sku"
                value={formData.sku}
                onChange={(e) => setFormData({...formData, sku: e.target.value})}
                required
              />
            </div>
          </div>

          <div className="grid grid-cols-2 gap-4">
            <div>
              <Label htmlFor="category">Category*</Label>
              <Select 
                value={formData.category} 
                onValueChange={(value) => setFormData({...formData, category: value})}
              >
                <SelectTrigger>
                  <SelectValue />
                </SelectTrigger>
                <SelectContent>
                  {CATEGORIES.map(cat => (
                    <SelectItem key={cat} value={cat}>{cat}</SelectItem>
                  ))}
                </SelectContent>
              </Select>
            </div>
            <div>
              <Label htmlFor="subcategory">Subcategory</Label>
              <Select 
                value={formData.subcategory} 
                onValueChange={(value) => setFormData({...formData, subcategory: value})}
              >
                <SelectTrigger>
                  <SelectValue />
                </SelectTrigger>
                <SelectContent>
                  {SUBCATEGORIES.map(sub => (
                    <SelectItem key={sub} value={sub}>{sub}</SelectItem>
                  ))}
                </SelectContent>
              </Select>
            </div>
          </div>

          <div>
            <Label htmlFor="description">Description</Label>
            <Textarea
              id="description"
              value={formData.description}
              onChange={(e) => setFormData({...formData, description: e.target.value})}
              rows={4}
            />
          </div>

          <div>
            <Label htmlFor="status">Status</Label>
            <Select 
              value={formData.status} 
              onValueChange={(value) => setFormData({...formData, status: value})}
            >
              <SelectTrigger>
                <SelectValue />
              </SelectTrigger>
              <SelectContent>
                {STATUSES.map(status => (
                  <SelectItem key={status} value={status}>{status}</SelectItem>
                ))}
              </SelectContent>
            </Select>
          </div>
        </TabsContent>
        
        <TabsContent value="pricing" className="space-y-4">
          <div>
            <Label htmlFor="price_tier">Price Tier*</Label>
            <Select 
              value={formData.price_tier} 
              onValueChange={(value) => {
                const tier = PRICE_TIERS.find(t => t.value === value);
                if (tier) {
                  setFormData({
                    ...formData, 
                    price_tier: value,
                    base_price: tier.min
                  });
                }
              }}
            >
              <SelectTrigger>
                <SelectValue />
              </SelectTrigger>
              <SelectContent>
                {PRICE_TIERS.map(tier => (
                  <SelectItem key={tier.value} value={tier.value}>
                    {tier.label}
                  </SelectItem>
                ))}
              </SelectContent>
            </Select>
          </div>

          <div className="grid grid-cols-2 gap-4">
            <div>
              <Label htmlFor="base_price">Base Price (cents)*</Label>
              <Input
                id="base_price"
                type="number"
                value={formData.base_price}
                onChange={(e) => setFormData({...formData, base_price: parseInt(e.target.value)})}
                required
              />
              <p className="text-sm text-muted-foreground mt-1">
                ${((formData.base_price || 0) / 100).toFixed(2)}
              </p>
            </div>
            <div>
              <Label htmlFor="compare_at_price">Compare at Price (cents)</Label>
              <Input
                id="compare_at_price"
                type="number"
                value={formData.compare_at_price}
                onChange={(e) => setFormData({...formData, compare_at_price: parseInt(e.target.value)})}
              />
              {formData.compare_at_price ? (
                <p className="text-sm text-muted-foreground mt-1">
                  ${((formData.compare_at_price || 0) / 100).toFixed(2)}
                </p>
              ) : null}
            </div>
          </div>
        </TabsContent>
        
        <TabsContent value="images" className="space-y-4">
          <DraggableImageGallery
            images={galleryImages}
            onImagesChange={(newImages) => {
              setGalleryImages(newImages);
              
              // Convert back to the structured format for saving
              const hero = newImages.find(img => img.is_primary);
              const gallery = newImages.filter(img => !img.is_primary);
              
              setFormData(prev => ({
                ...prev,
                images: {
                  hero: hero ? { url: hero.url, alt: hero.alt_text } : null,
                  flat: gallery[0] ? { url: gallery[0].url, alt: gallery[0].alt_text } : null,
                  lifestyle: gallery.slice(1, 3).map(img => ({ url: img.url, alt: img.alt_text })),
                  details: gallery.slice(3).map(img => ({ url: img.url, alt: img.alt_text })),
                  total_images: newImages.length
                }
              }));
            }}
            productId={product?.id}
            maxImages={10}
            allowUpload={false} // Set to true if you want to enable upload
          />
        </TabsContent>
        
        <TabsContent value="details" className="space-y-4">
          <div className="grid grid-cols-2 gap-4">
            <div>
              <Label htmlFor="style_code">Style Code</Label>
              <Input
                id="style_code"
                value={formData.style_code}
                onChange={(e) => setFormData({...formData, style_code: e.target.value})}
              />
            </div>
            <div>
              <Label htmlFor="season">Season</Label>
              <Input
                id="season"
                value={formData.season}
                onChange={(e) => setFormData({...formData, season: e.target.value})}
                placeholder="SS24, FW24, etc."
              />
            </div>
          </div>

          <div className="grid grid-cols-2 gap-4">
            <div>
              <Label htmlFor="collection">Collection</Label>
              <Input
                id="collection"
                value={formData.collection}
                onChange={(e) => setFormData({...formData, collection: e.target.value})}
              />
            </div>
            <div>
              <Label htmlFor="fit_type">Fit Type</Label>
              <Select 
                value={formData.fit_type} 
                onValueChange={(value) => setFormData({...formData, fit_type: value})}
              >
                <SelectTrigger>
                  <SelectValue />
                </SelectTrigger>
                <SelectContent>
                  <SelectItem value="Slim Fit">Slim Fit</SelectItem>
                  <SelectItem value="Regular Fit">Regular Fit</SelectItem>
                  <SelectItem value="Relaxed Fit">Relaxed Fit</SelectItem>
                  <SelectItem value="Modern Fit">Modern Fit</SelectItem>
                </SelectContent>
              </Select>
            </div>
          </div>

          <div className="grid grid-cols-2 gap-4">
            <div>
              <Label htmlFor="color_family">Color Family</Label>
              <Input
                id="color_family"
                value={formData.color_family}
                onChange={(e) => setFormData({...formData, color_family: e.target.value})}
                placeholder="Black, Blue, Red, etc."
              />
            </div>
            <div>
              <Label htmlFor="color_name">Color Name</Label>
              <Input
                id="color_name"
                value={formData.color_name}
                onChange={(e) => setFormData({...formData, color_name: e.target.value})}
                placeholder="Midnight Navy, Burgundy, etc."
              />
            </div>
          </div>
        </TabsContent>
        
        <TabsContent value="seo" className="space-y-4">
          <div>
            <Label htmlFor="meta_title">Meta Title (max 70 chars)</Label>
            <Input
              id="meta_title"
              value={formData.meta_title || ''}
              onChange={(e) => setFormData({...formData, meta_title: e.target.value})}
              maxLength={70}
              placeholder="Page title for search engines"
            />
            <p className="text-sm text-muted-foreground mt-1">
              {(formData.meta_title || '').length}/70 characters
            </p>
          </div>

          <div>
            <Label htmlFor="meta_description">Meta Description (max 160 chars)</Label>
            <Textarea
              id="meta_description"
              value={formData.meta_description || ''}
              onChange={(e) => setFormData({...formData, meta_description: e.target.value})}
              maxLength={160}
              rows={3}
              placeholder="Description for search engine results"
            />
            <p className="text-sm text-muted-foreground mt-1">
              {(formData.meta_description || '').length}/160 characters
            </p>
          </div>

          <div>
            <Label htmlFor="tags">Tags (comma-separated)</Label>
            <Input
              id="tags"
              value={formData.tags?.join(', ') || ''}
              onChange={(e) => setFormData({
                ...formData, 
                tags: e.target.value.split(',').map(tag => tag.trim()).filter(tag => tag)
              })}
              placeholder="blazer, velvet, formal, wedding"
            />
          </div>

          <div className="grid grid-cols-2 gap-4">
            <div>
              <Label htmlFor="url_slug">URL Slug</Label>
              <Input
                id="url_slug"
                value={formData.url_slug || formData.handle || ''}
                onChange={(e) => setFormData({...formData, url_slug: e.target.value})}
                placeholder="product-url-slug"
              />
            </div>
            <div>
              <Label htmlFor="canonical_url">Canonical URL</Label>
              <Input
                id="canonical_url"
                value={formData.canonical_url || ''}
                onChange={(e) => setFormData({...formData, canonical_url: e.target.value})}
                placeholder="https://kctmenswear.com/products/..."
              />
            </div>
          </div>

          <div>
            <Label htmlFor="og_title">Open Graph Title</Label>
            <Input
              id="og_title"
              value={formData.og_title || ''}
              onChange={(e) => setFormData({...formData, og_title: e.target.value})}
              placeholder="Title for social media sharing"
            />
          </div>

          <div>
            <Label htmlFor="og_description">Open Graph Description</Label>
            <Textarea
              id="og_description"
              value={formData.og_description || ''}
              onChange={(e) => setFormData({...formData, og_description: e.target.value})}
              rows={2}
              placeholder="Description for social media sharing"
            />
          </div>

          <div>
            <Label htmlFor="og_image">Open Graph Image URL</Label>
            <Input
              id="og_image"
              value={formData.og_image || formData.images?.hero?.url || ''}
              onChange={(e) => setFormData({...formData, og_image: e.target.value})}
              placeholder="Image URL for social media sharing"
            />
          </div>

          <div className="grid grid-cols-2 gap-4">
            <div>
              <Label htmlFor="sitemap_priority">Sitemap Priority (0.0 - 1.0)</Label>
              <Input
                id="sitemap_priority"
                type="number"
                step="0.1"
                min="0"
                max="1"
                value={formData.sitemap_priority || 0.8}
                onChange={(e) => setFormData({...formData, sitemap_priority: parseFloat(e.target.value)})}
              />
            </div>
            <div>
              <Label htmlFor="sitemap_change_freq">Sitemap Change Frequency</Label>
              <Select 
                value={formData.sitemap_change_freq || 'weekly'} 
                onValueChange={(value) => setFormData({...formData, sitemap_change_freq: value})}
              >
                <SelectTrigger>
                  <SelectValue />
                </SelectTrigger>
                <SelectContent>
                  <SelectItem value="always">Always</SelectItem>
                  <SelectItem value="hourly">Hourly</SelectItem>
                  <SelectItem value="daily">Daily</SelectItem>
                  <SelectItem value="weekly">Weekly</SelectItem>
                  <SelectItem value="monthly">Monthly</SelectItem>
                  <SelectItem value="yearly">Yearly</SelectItem>
                  <SelectItem value="never">Never</SelectItem>
                </SelectContent>
              </Select>
            </div>
          </div>

          <div className="flex items-center space-x-2">
            <input
              type="checkbox"
              id="is_indexable"
              checked={formData.is_indexable !== false}
              onChange={(e) => setFormData({...formData, is_indexable: e.target.checked})}
              className="h-4 w-4"
            />
            <Label htmlFor="is_indexable">Allow search engines to index this product</Label>
          </div>
        </TabsContent>
      </Tabs>

      <div className="flex justify-end gap-4">
        <Button type="button" variant="outline" onClick={onCancel}>
          <X className="mr-2 h-4 w-4" />
          Cancel
        </Button>
        <Button type="submit">
          <Save className="mr-2 h-4 w-4" />
          {product?.id ? 'Update Product' : 'Create Product'}
        </Button>
      </div>
    </form>
  );
}