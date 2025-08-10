import React, { useState, useCallback } from 'react';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { Alert, AlertDescription } from '@/components/ui/alert';
import { Badge } from '@/components/ui/badge';
import { Progress } from '@/components/ui/progress';
import { Tabs, TabsContent, TabsList, TabsTrigger } from '@/components/ui/tabs';
import { supabase } from '@/lib/supabase';
import { toast } from 'sonner';
import {
  Upload,
  Link,
  Image as ImageIcon,
  X,
  CheckCircle,
  AlertCircle,
  Cloud,
  HardDrive,
  Globe,
  Loader2,
  Move
} from 'lucide-react';

interface ImageUploadManagerProps {
  images: Array<{ image_url: string; position: number }>;
  onImagesChange: (images: Array<{ image_url: string; position: number }>) => void;
  maxImages?: number;
}

export function ImageUploadManager({ 
  images, 
  onImagesChange,
  maxImages = 10 
}: ImageUploadManagerProps) {
  const [isDragging, setIsDragging] = useState(false);
  const [uploading, setUploading] = useState(false);
  const [uploadProgress, setUploadProgress] = useState(0);
  const [imageUrl, setImageUrl] = useState('');
  const [storageOption, setStorageOption] = useState<'supabase' | 'external'>('supabase');
  const [draggedIndex, setDraggedIndex] = useState<number | null>(null);

  // Handle file upload to Supabase Storage
  const uploadToSupabase = async (file: File) => {
    const fileName = `${Date.now()}-${file.name.replace(/[^a-zA-Z0-9.-]/g, '_')}`;
    
    try {
      // Upload to Supabase storage
      const { data, error } = await supabase.storage
        .from('product-images')
        .upload(fileName, file, {
          cacheControl: '3600',
          upsert: false
        });

      if (error) {
        // If bucket doesn't exist, show helpful message
        if (error.message.includes('bucket')) {
          toast.error('Storage bucket not configured. Please run the setup script in scripts/setup-storage-bucket.sql');
          throw new Error('Storage bucket not configured');
        }
        throw error;
      }

      // Get public URL
      const { data: { publicUrl } } = supabase.storage
        .from('product-images')
        .getPublicUrl(fileName);

      return publicUrl;
    } catch (error) {
      console.error('Upload error:', error);
      throw error;
    }
  };

  // Handle file drop/selection
  const handleFiles = useCallback(async (files: FileList) => {
    const validFiles = Array.from(files).filter(file => {
      const isImage = file.type.startsWith('image/');
      const isUnderLimit = file.size <= 10 * 1024 * 1024; // 10MB
      
      if (!isImage) {
        toast.error(`${file.name} is not an image file`);
        return false;
      }
      if (!isUnderLimit) {
        toast.error(`${file.name} exceeds 10MB limit`);
        return false;
      }
      return true;
    });

    if (validFiles.length === 0) return;
    if (images.length + validFiles.length > maxImages) {
      toast.error(`Maximum ${maxImages} images allowed`);
      return;
    }

    setUploading(true);
    setUploadProgress(0);

    try {
      const newImages = [...images];
      const totalFiles = validFiles.length;
      
      for (let i = 0; i < validFiles.length; i++) {
        const file = validFiles[i];
        setUploadProgress(((i + 1) / totalFiles) * 100);
        
        if (storageOption === 'supabase') {
          const url = await uploadToSupabase(file);
          newImages.push({
            image_url: url,
            position: newImages.length
          });
        } else {
          // For external storage, convert to base64 for preview
          // In production, you'd upload to Cloudflare/S3/etc
          const reader = new FileReader();
          const base64 = await new Promise<string>((resolve) => {
            reader.onload = (e) => resolve(e.target?.result as string);
            reader.readAsDataURL(file);
          });
          
          newImages.push({
            image_url: base64, // In production, this would be the CDN URL
            position: newImages.length
          });
          
          toast.info('Using local preview. Configure external storage for production.');
        }
      }
      
      onImagesChange(newImages);
      toast.success(`Uploaded ${validFiles.length} image${validFiles.length > 1 ? 's' : ''}`);
    } catch (error) {
      console.error('Upload failed:', error);
      toast.error('Failed to upload images');
    } finally {
      setUploading(false);
      setUploadProgress(0);
    }
  }, [images, onImagesChange, maxImages, storageOption]);

  // Drag and drop handlers
  const handleDragOver = (e: React.DragEvent) => {
    e.preventDefault();
    if (e.dataTransfer.types.includes('Files')) {
      setIsDragging(true);
    }
  };

  const handleDragLeave = (e: React.DragEvent) => {
    e.preventDefault();
    if (e.currentTarget === e.target) {
      setIsDragging(false);
    }
  };

  const handleDrop = (e: React.DragEvent) => {
    e.preventDefault();
    setIsDragging(false);
    
    const files = e.dataTransfer.files;
    if (files && files.length > 0) {
      handleFiles(files);
    }
  };

  // Add image from URL
  const handleAddUrl = async () => {
    if (!imageUrl) {
      toast.error('Please enter an image URL');
      return;
    }

    if (images.length >= maxImages) {
      toast.error(`Maximum ${maxImages} images allowed`);
      return;
    }

    // Basic URL validation
    try {
      const url = new URL(imageUrl);
      
      // Check if it's an image URL
      const imageExtensions = ['.jpg', '.jpeg', '.png', '.gif', '.webp', '.svg'];
      const hasImageExtension = imageExtensions.some(ext => url.pathname.toLowerCase().endsWith(ext));
      
      if (!hasImageExtension && !url.pathname.includes('image')) {
        toast.warning('URL might not be an image. Adding anyway...');
      }
      
      // For R2/Cloudflare URLs, ensure HTTPS
      if (url.hostname.includes('r2.dev') && url.protocol === 'http:') {
        url.protocol = 'https:';
        toast.info('Converted to HTTPS for Cloudflare R2');
      }
      
      const finalUrl = url.toString();
      
      const newImages = [...images, {
        image_url: finalUrl,
        position: images.length
      }];
      
      onImagesChange(newImages);
      setImageUrl('');
      toast.success('Image added from URL');
      
    } catch (error) {
      toast.error('Invalid URL format');
      return;
    }
  };

  // Remove image
  const removeImage = (index: number) => {
    const newImages = images.filter((_, i) => i !== index);
    // Reorder positions
    newImages.forEach((img, i) => {
      img.position = i;
    });
    onImagesChange(newImages);
  };

  // Drag to reorder images
  const handleImageDragStart = (index: number) => {
    setDraggedIndex(index);
  };

  const handleImageDragOver = (e: React.DragEvent, index: number) => {
    e.preventDefault();
    if (draggedIndex === null || draggedIndex === index) return;
    
    const newImages = [...images];
    const draggedImage = newImages[draggedIndex];
    
    // Remove dragged image
    newImages.splice(draggedIndex, 1);
    // Insert at new position
    newImages.splice(index, 0, draggedImage);
    
    // Update positions
    newImages.forEach((img, i) => {
      img.position = i;
    });
    
    onImagesChange(newImages);
    setDraggedIndex(index);
  };

  const handleImageDragEnd = () => {
    setDraggedIndex(null);
  };

  return (
    <Card>
      <CardHeader>
        <CardTitle className="flex items-center justify-between">
          <span>Product Images</span>
          <Badge variant="outline">
            {images.length} / {maxImages} images
          </Badge>
        </CardTitle>
      </CardHeader>
      <CardContent className="space-y-4">
        <Tabs defaultValue="upload" className="w-full">
          <TabsList className="grid w-full grid-cols-2">
            <TabsTrigger value="upload">Upload Images</TabsTrigger>
            <TabsTrigger value="url">Add from URL</TabsTrigger>
          </TabsList>

          <TabsContent value="upload" className="space-y-4">
            {/* Storage Option Selector */}
            <div className="flex gap-2">
              <Button
                variant={storageOption === 'supabase' ? 'default' : 'outline'}
                size="sm"
                onClick={() => setStorageOption('supabase')}
              >
                <HardDrive className="h-4 w-4 mr-2" />
                Supabase Storage
              </Button>
              <Button
                variant={storageOption === 'external' ? 'default' : 'outline'}
                size="sm"
                onClick={() => setStorageOption('external')}
              >
                <Cloud className="h-4 w-4 mr-2" />
                External CDN
              </Button>
            </div>

            {/* Drop Zone */}
            <div
              className={`
                border-2 border-dashed rounded-lg p-8 text-center transition-all
                ${isDragging 
                  ? 'border-blue-500 bg-blue-50 scale-[1.02]' 
                  : 'border-gray-300 hover:border-gray-400'
                }
                ${uploading ? 'opacity-50 pointer-events-none' : 'cursor-pointer'}
              `}
              onDragOver={handleDragOver}
              onDragLeave={handleDragLeave}
              onDrop={handleDrop}
              onClick={() => !uploading && document.getElementById('file-input')?.click()}
            >
              <input
                id="file-input"
                type="file"
                multiple
                accept="image/*"
                className="hidden"
                onChange={(e) => e.target.files && handleFiles(e.target.files)}
                disabled={uploading}
              />
              
              {uploading ? (
                <div className="space-y-3">
                  <Loader2 className="h-10 w-10 text-blue-500 animate-spin mx-auto" />
                  <p className="font-medium">Uploading images...</p>
                  <Progress value={uploadProgress} className="w-32 mx-auto" />
                </div>
              ) : (
                <>
                  <Upload className="h-10 w-10 text-gray-400 mx-auto mb-3" />
                  <p className="text-base font-medium text-gray-700">
                    Drop images here or click to browse
                  </p>
                  <p className="text-sm text-gray-500 mt-1">
                    PNG, JPG, GIF, WebP up to 10MB each
                  </p>
                </>
              )}
            </div>

            {storageOption === 'external' && (
              <Alert>
                <Cloud className="h-4 w-4" />
                <AlertDescription>
                  External CDN mode selected. In production, configure your Cloudflare, AWS S3, or other CDN settings.
                </AlertDescription>
              </Alert>
            )}
          </TabsContent>

          <TabsContent value="url" className="space-y-4">
            <div className="flex gap-2">
              <Input
                placeholder="https://example.com/image.jpg"
                value={imageUrl}
                onChange={(e) => setImageUrl(e.target.value)}
                onKeyPress={(e) => e.key === 'Enter' && handleAddUrl()}
              />
              <Button onClick={handleAddUrl}>
                <Link className="h-4 w-4 mr-2" />
                Add URL
              </Button>
            </div>
            <Alert>
              <AlertCircle className="h-4 w-4" />
              <AlertDescription>
                Make sure you have rights to use external images and they're hosted on a reliable CDN.
              </AlertDescription>
            </Alert>
          </TabsContent>
        </Tabs>

        {/* Image Grid */}
        {images.length > 0 && (
          <div className="space-y-2">
            <div className="flex items-center justify-between">
              <p className="text-sm font-medium text-gray-700">
                Drag images to reorder • First image is the main product image
              </p>
              {images.some(img => img.image_url?.includes('r2.dev')) && (
                <Badge variant="outline" className="text-xs">
                  <Cloud className="h-3 w-3 mr-1" />
                  Using Cloudflare R2
                </Badge>
              )}
            </div>
            <div className="grid grid-cols-2 sm:grid-cols-3 md:grid-cols-4 gap-3">
              {images.map((image, index) => (
                <div
                  key={index}
                  className="relative group cursor-move"
                  draggable
                  onDragStart={() => handleImageDragStart(index)}
                  onDragOver={(e) => handleImageDragOver(e, index)}
                  onDragEnd={handleImageDragEnd}
                >
                  <div className={`
                    relative overflow-hidden rounded-lg border-2 
                    ${draggedIndex === index ? 'border-blue-500 opacity-50' : 'border-gray-200'}
                  `}>
                    <img
                      src={image.image_url}
                      alt={`Product ${index + 1}`}
                      className="w-full h-32 object-cover"
                      onError={(e) => {
                        console.error('Failed to load image:', image.image_url);
                        // Set a fallback image
                        (e.target as HTMLImageElement).src = 'data:image/svg+xml;base64,PHN2ZyB3aWR0aD0iNDAwIiBoZWlnaHQ9IjMwMCIgeG1sbnM9Imh0dHA6Ly93d3cudzMub3JnLzIwMDAvc3ZnIj48cmVjdCB3aWR0aD0iNDAwIiBoZWlnaHQ9IjMwMCIgZmlsbD0iI2VlZSIvPjx0ZXh0IHRleHQtYW5jaG9yPSJtaWRkbGUiIHg9IjIwMCIgeT0iMTUwIiBzdHlsZT0iZmlsbDojYWFhO2ZvbnQtd2VpZ2h0OmJvbGQ7Zm9udC1zaXplOjE5cHg7Zm9udC1mYW1pbHk6QXJpYWwsSGVsdmV0aWNhLHNhbnMtc2VyaWY7ZG9taW5hbnQtYmFzZWxpbmU6Y2VudHJhbCI+SW1hZ2UgTm90IEZvdW5kPC90ZXh0Pjwvc3ZnPg==';
                      }}
                      loading="lazy"
                      crossOrigin="anonymous"
                    />
                    {index === 0 && (
                      <Badge className="absolute top-2 left-2 bg-black/75">
                        Main
                      </Badge>
                    )}
                    <div className="absolute inset-0 bg-black/50 opacity-0 group-hover:opacity-100 transition-opacity flex items-center justify-center gap-2">
                      <Button
                        size="sm"
                        variant="destructive"
                        onClick={(e) => {
                          e.stopPropagation();
                          removeImage(index);
                        }}
                      >
                        <X className="h-4 w-4" />
                      </Button>
                    </div>
                  </div>
                  <div className="absolute -top-1 -right-1 opacity-0 group-hover:opacity-100 transition-opacity">
                    <Move className="h-4 w-4 text-gray-600" />
                  </div>
                </div>
              ))}
            </div>
          </div>
        )}

        {/* Storage Info */}
        <Alert>
          <ImageIcon className="h-4 w-4" />
          <AlertDescription>
            Images are stored in {storageOption === 'supabase' ? 'Supabase Storage' : 'External CDN'}.
            {storageOption === 'supabase' && ' Run scripts/setup-storage-bucket.sql if you haven\'t set up the bucket yet.'}
          </AlertDescription>
        </Alert>
      </CardContent>
    </Card>
  );
}