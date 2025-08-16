import React, { useState, useRef } from 'react';
import {
  DndContext,
  DragOverlay,
  closestCenter,
  KeyboardSensor,
  PointerSensor,
  TouchSensor,
  useSensor,
  useSensors,
  DragStartEvent,
  DragEndEvent,
} from '@dnd-kit/core';
import {
  arrayMove,
  SortableContext,
  sortableKeyboardCoordinates,
  verticalListSortingStrategy,
  rectSortingStrategy,
} from '@dnd-kit/sortable';
import {
  useSortable,
  SortableContext as SortableContextOriginal,
} from '@dnd-kit/sortable';
import { CSS } from '@dnd-kit/utilities';
import { Button } from '@/components/ui/button';
import { Badge } from '@/components/ui/badge';
import { Input } from '@/components/ui/input';
import { Label } from '@/components/ui/label';
import { Skeleton } from '@/components/ui/skeleton';
import { useToast } from '@/hooks/use-toast';
import {
  Upload,
  X,
  GripVertical,
  Image as ImageIcon,
  AlertTriangle,
  Eye,
} from 'lucide-react';
import { supabase } from '@/lib/supabase-client';

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

interface DraggableImageGalleryProps {
  images: ProductImage[];
  onImagesChange: (images: ProductImage[]) => void;
  productId?: string;
  maxImages?: number;
  allowUpload?: boolean;
}

interface SortableImageProps {
  image: ProductImage;
  index: number;
  onRemove: (index: number) => void;
  onAltTextChange: (index: number, altText: string) => void;
  onSetPrimary: (index: number) => void;
  isDragging?: boolean;
}

// Loading skeleton component
const ImageSkeleton = () => (
  <div className="relative group">
    <Skeleton className="w-full h-32 rounded-lg" />
    <div className="absolute inset-0 flex items-center justify-center">
      <ImageIcon className="h-8 w-8 text-muted-foreground animate-pulse" />
    </div>
  </div>
);

// Lazy loading image component with error handling
const LazyImage: React.FC<{
  src: string;
  alt: string;
  className?: string;
  onLoad?: () => void;
  onError?: () => void;
}> = ({ src, alt, className = "", onLoad, onError }) => {
  const [imageLoading, setImageLoading] = useState(true);
  const [imageError, setImageError] = useState(false);
  const imgRef = useRef<HTMLImageElement>(null);

  React.useEffect(() => {
    // Intersection Observer for lazy loading
    const observer = new IntersectionObserver(
      (entries) => {
        entries.forEach((entry) => {
          if (entry.isIntersecting && imgRef.current) {
            const img = imgRef.current;
            if (!img.src) {
              img.src = src;
            }
          }
        });
      },
      {
        threshold: 0.1,
        rootMargin: '50px',
      }
    );

    if (imgRef.current) {
      observer.observe(imgRef.current);
    }

    return () => {
      if (imgRef.current) {
        observer.unobserve(imgRef.current);
      }
    };
  }, [src]);

  const handleLoad = () => {
    setImageLoading(false);
    setImageError(false);
    onLoad?.();
  };

  const handleError = () => {
    setImageLoading(false);
    setImageError(true);
    onError?.();
  };

  if (imageError) {
    return (
      <div className={`${className} bg-muted rounded-lg flex items-center justify-center`}>
        <div className="text-center">
          <AlertTriangle className="h-6 w-6 text-muted-foreground mx-auto mb-2" />
          <p className="text-xs text-muted-foreground">Failed to load</p>
        </div>
      </div>
    );
  }

  return (
    <div className="relative">
      {imageLoading && (
        <div className={`absolute inset-0 ${className} bg-muted rounded-lg flex items-center justify-center`}>
          <ImageIcon className="h-8 w-8 text-muted-foreground animate-pulse" />
        </div>
      )}
      <img
        ref={imgRef}
        alt={alt}
        className={`${className} ${imageLoading ? 'opacity-0' : 'opacity-100'} transition-opacity duration-300`}
        loading="lazy"
        onLoad={handleLoad}
        onError={handleError}
      />
    </div>
  );
};

// Sortable image item component
const SortableImage: React.FC<SortableImageProps> = ({
  image,
  index,
  onRemove,
  onAltTextChange,
  onSetPrimary,
  isDragging = false,
}) => {
  const {
    attributes,
    listeners,
    setNodeRef,
    transform,
    transition,
    isDragging: isSortableDragging,
  } = useSortable({ id: image.url });

  const style = {
    transform: CSS.Transform.toString(transform),
    transition,
    opacity: isSortableDragging ? 0.5 : 1,
  };

  const [altText, setAltText] = useState(image.alt_text || '');
  const [showAltInput, setShowAltInput] = useState(false);

  const handleAltTextSave = () => {
    onAltTextChange(index, altText);
    setShowAltInput(false);
  };

  return (
    <div
      ref={setNodeRef}
      style={{
        ...style,
        // Ensure proper positioning context for drag operations
        position: 'relative',
        // Prevent any transform issues during drag
        transformOrigin: 'top left',
      }}
      className="relative group bg-white border rounded-lg p-2 space-y-2"
    >
      {/* Drag Handle */}
      <div
        {...attributes}
        {...listeners}
        className="absolute top-2 left-2 z-10 opacity-0 group-hover:opacity-100 transition-opacity cursor-grab active:cursor-grabbing bg-white/90 rounded p-1"
        style={{
          // Ensure the drag handle doesn't interfere with coordinate calculations
          touchAction: 'none',
          userSelect: 'none',
          transform: 'translate3d(0, 0, 0)', // Force GPU acceleration and proper positioning
        }}
      >
        <GripVertical className="h-4 w-4 text-muted-foreground" />
      </div>

      {/* Remove Button */}
      <Button
        size="sm"
        variant="destructive"
        className="absolute top-2 right-2 z-10 opacity-0 group-hover:opacity-100 transition-opacity h-6 w-6 p-0"
        onClick={() => onRemove(index)}
      >
        <X className="h-3 w-3" />
      </Button>

      {/* Primary Badge and Set Primary Button */}
      <div className="absolute bottom-2 left-2 z-10 flex items-center gap-2">
        <Badge 
          variant={image.is_primary ? "default" : "secondary"}
          className="text-xs"
        >
          {image.is_primary ? "Primary" : `Position ${image.position}`}
        </Badge>
        {!image.is_primary && (
          <Button
            size="sm"
            variant="outline"
            className="h-6 px-2 text-xs opacity-0 group-hover:opacity-100 transition-opacity"
            onClick={() => onSetPrimary(index)}
            title="Set as primary image"
          >
            <Eye className="h-3 w-3 mr-1" />
            Set Primary
          </Button>
        )}
      </div>

      {/* Image */}
      <div className="aspect-square">
        <LazyImage
          src={image.url}
          alt={image.alt_text || `Product image ${index + 1}`}
          className="w-full h-full object-cover rounded-md border"
        />
      </div>

      {/* Alt Text Section */}
      <div className="space-y-2">
        {showAltInput ? (
          <div className="flex gap-1">
            <Input
              value={altText}
              onChange={(e) => setAltText(e.target.value)}
              placeholder="Image description..."
              className="text-xs h-7"
              onKeyDown={(e) => {
                if (e.key === 'Enter') handleAltTextSave();
                if (e.key === 'Escape') setShowAltInput(false);
              }}
            />
            <Button size="sm" onClick={handleAltTextSave} className="h-7 px-2">
              Save
            </Button>
          </div>
        ) : (
          <div 
            className="cursor-pointer text-xs text-muted-foreground truncate hover:text-foreground transition-colors"
            onClick={() => setShowAltInput(true)}
            title="Click to edit alt text"
          >
            {image.alt_text || 'Add description...'}
          </div>
        )}
      </div>
    </div>
  );
};

// Main draggable image gallery component
export const DraggableImageGallery = React.memo<DraggableImageGalleryProps>(({
  images = [],
  onImagesChange,
  productId,
  maxImages = 10,
  allowUpload = true,
}) => {
  const { toast } = useToast();
  const [activeId, setActiveId] = useState<string | null>(null);
  const [isUploading, setIsUploading] = useState(false);
  const fileInputRef = useRef<HTMLInputElement>(null);

  const sensors = useSensors(
    useSensor(PointerSensor, {
      activationConstraint: {
        distance: 8,
      },
    }),
    useSensor(TouchSensor, {
      activationConstraint: {
        delay: 250,
        tolerance: 5,
      },
    }),
    useSensor(KeyboardSensor, {
      coordinateGetter: sortableKeyboardCoordinates,
    })
  );

  // Handle drag start
  const handleDragStart = (event: DragStartEvent) => {
    setActiveId(event.active.id as string);
  };

  // Handle drag end with position updates
  const handleDragEnd = async (event: DragEndEvent) => {
    const { active, over } = event;
    
    if (!over || active.id === over.id) {
      setActiveId(null);
      return;
    }

    const oldIndex = images.findIndex((img) => img.url === active.id);
    const newIndex = images.findIndex((img) => img.url === over.id);

    if (oldIndex !== -1 && newIndex !== -1) {
      // Reorder images
      const newImages = arrayMove(images, oldIndex, newIndex);
      
      // Update positions and primary status
      const updatedImages = newImages.map((img, index) => ({
        ...img,
        position: index,
        is_primary: index === 0, // First image is primary
      }));

      // Optimistic UI update
      onImagesChange(updatedImages);

      // Update positions in database if productId exists
      if (productId && updatedImages.some(img => img.id)) {
        try {
          await updateImagePositions(productId, updatedImages);
          toast({
            title: "Images reordered",
            description: `Image moved to position ${newIndex + 1}. Primary image updated.`,
          });
        } catch (error) {
          console.error('Failed to update image positions:', error);
          toast({
            title: "Error",
            description: "Failed to save image order. Changes may not persist.",
            variant: "destructive",
          });
          // Revert optimistic update
          onImagesChange(images);
        }
      } else {
        toast({
          title: "Images reordered",
          description: `Image moved to position ${newIndex + 1}. Primary image updated.`,
        });
      }
    }

    setActiveId(null);
  };

  // Update image positions in database
  const updateImagePositions = async (productId: string, updatedImages: ProductImage[]) => {
    try {
      console.log('🔄 Updating image positions for product:', productId);
      console.log('📋 Updated images:', updatedImages);

      const updates = updatedImages
        .filter(img => img.id) // Only update images that exist in DB
        .map(img => ({
          id: img.id,
          position: img.position,
          image_type: img.is_primary ? 'primary' : 'gallery'
        }));

      console.log('📝 Position updates to apply:', updates);

      if (updates.length === 0) {
        console.log('ℹ️ No database images to update');
        return;
      }

      // Update positions in batch - use Promise.all for better performance
      const updatePromises = updates.map(update => 
        supabase
          .from('product_images')
          .update({ 
            position: update.position,
            image_type: update.image_type,
            updated_at: new Date().toISOString()
          })
          .eq('id', update.id)
      );

      const results = await Promise.all(updatePromises);
      
      // Check for any errors
      const errors = results.filter(result => result.error);
      if (errors.length > 0) {
        console.error('❌ Some position updates failed:', errors);
        throw new Error(`Failed to update ${errors.length} image positions`);
      }

      console.log('✅ All image positions updated successfully');
    } catch (error) {
      console.error('💥 Error updating image positions:', error);
      throw error;
    }
  };

  // Handle file upload
  const handleFileUpload = async (files: FileList | null) => {
    if (!files || files.length === 0) return;

    if (images.length + files.length > maxImages) {
      toast({
        title: "Too many images",
        description: `Maximum ${maxImages} images allowed. You can upload ${maxImages - images.length} more.`,
        variant: "destructive",
      });
      return;
    }

    setIsUploading(true);
    let currentImages = [...images];

    try {
      const newImages: ProductImage[] = [];

      for (let i = 0; i < files.length; i++) {
        const file = files[i];
        
        if (!file.type.startsWith('image/')) {
          toast({
            title: "Invalid file type",
            description: `${file.name} is not an image file.`,
            variant: "destructive",
          });
          continue;
        }

        // Create preview URL
        const previewUrl = URL.createObjectURL(file);
        const position = currentImages.length + newImages.length;
        
        // Add loading image to UI
        const loadingImage: ProductImage = {
          url: previewUrl,
          alt_text: file.name,
          position,
          is_primary: position === 0,
          loading: true,
        };

        newImages.push(loadingImage);
      }

      // Update UI with loading images
      currentImages = [...currentImages, ...newImages];
      onImagesChange(currentImages);

      // If we have a productId, upload to Supabase Storage
      if (productId) {
        for (let i = 0; i < files.length; i++) {
          const file = files[i];
          const imageIndex = images.length + i;
          
          try {
            // Upload to Supabase Storage
            const fileExt = file.name.split('.').pop();
            const fileName = `${productId}/${Date.now()}-${Math.random().toString(36).substring(2)}.${fileExt}`;
            
            const { data: uploadData, error: uploadError } = await supabase.storage
              .from('product-images')
              .upload(fileName, file);

            if (uploadError) throw uploadError;

            // Get public URL
            const { data: { publicUrl } } = supabase.storage
              .from('product-images')
              .getPublicUrl(fileName);

            // Save to product_images table
            const { data: imageData, error: insertError } = await supabase
              .from('product_images')
              .insert({
                product_id: productId,
                image_url: publicUrl,
                position: imageIndex,
                image_type: imageIndex === 0 ? 'primary' : 'gallery',
                alt_text: file.name,
              })
              .select()
              .single();

            if (insertError) throw insertError;

            // Update the loading image with final data
            const loadingImageIndex = images.length + i;
            if (currentImages[loadingImageIndex]) {
              currentImages[loadingImageIndex] = {
                ...currentImages[loadingImageIndex],
                id: imageData.id,
                url: publicUrl,
                loading: false,
                error: false,
              };
              onImagesChange([...currentImages]);
            }

          } catch (error) {
            console.error('Upload error for file:', file.name, error);
            
            // Mark image as error
            const errorImageIndex = images.length + i;
            if (currentImages[errorImageIndex]) {
              currentImages[errorImageIndex] = {
                ...currentImages[errorImageIndex],
                loading: false,
                error: true,
              };
              onImagesChange([...currentImages]);
            }

            toast({
              title: "Upload failed",
              description: `Failed to upload ${file.name}. Please try again.`,
              variant: "destructive",
            });
          }
        }
      }

      toast({
        title: "Images uploaded",
        description: `Successfully uploaded ${files.length} image(s).`,
      });

    } catch (error) {
      console.error('Upload error:', error);
      toast({
        title: "Upload failed",
        description: "Failed to upload images. Please try again.",
        variant: "destructive",
      });
    } finally {
      setIsUploading(false);
    }
  };

  // Handle remove image
  const handleRemoveImage = useCallback(async (index: number) => {
    const imageToRemove = images[index];
    const newImages = images.filter((_, i) => i !== index);
    
    // Update positions and primary status
    const updatedImages = newImages.map((img, i) => ({
      ...img,
      position: i,
      is_primary: i === 0,
    }));

    // Optimistic UI update
    onImagesChange(updatedImages);

    // Remove from database if it has an ID
    if (imageToRemove.id && productId) {
      try {
        const { error } = await supabase
          .from('product_images')
          .delete()
          .eq('id', imageToRemove.id);

        if (error) throw error;

        // Update remaining image positions
        await updateImagePositions(productId, updatedImages);

        toast({
          title: "Image removed",
          description: "Image deleted successfully.",
        });
      } catch (error) {
        console.error('Failed to remove image:', error);
        toast({
          title: "Error",
          description: "Failed to delete image from database.",
          variant: "destructive",
        });
        // Revert optimistic update
        onImagesChange(images);
      }
    }

    // Clean up object URL if it's a preview
    if (imageToRemove.url.startsWith('blob:')) {
      URL.revokeObjectURL(imageToRemove.url);
    }
  }, [images, productId]);

  // Handle alt text change
  const handleAltTextChange = useCallback(async (index: number, altText: string) => {
    const updatedImages = [...images];
    updatedImages[index] = { ...updatedImages[index], alt_text: altText };
    onImagesChange(updatedImages);

    // Update in database if image has ID
    const image = updatedImages[index];
    if (image.id) {
      try {
        const { error } = await supabase
          .from('product_images')
          .update({ alt_text: altText })
          .eq('id', image.id);

        if (error) throw error;

        toast({
          title: "Alt text updated",
          description: "Image description saved.",
        });
      } catch (error) {
        console.error('Failed to update alt text:', error);
        toast({
          title: "Error",
          description: "Failed to save image description.",
          variant: "destructive",
        });
      }
    }
  }, [images, onImagesChange]);

  // Handle set primary image
  const handleSetPrimary = useCallback(async (index: number) => {
    // Update all images - set selected as primary, others as gallery
    const updatedImages = images.map((img, i) => ({
      ...img,
      is_primary: i === index,
      image_type: i === index ? 'primary' : 'gallery' as const
    }));

    // Optimistic UI update
    onImagesChange(updatedImages);

    // Update in database if productId exists
    if (productId) {
      try {
        // Update all images in batch
        const updatePromises = updatedImages
          .filter(img => img.id)
          .map(img => 
            supabase
              .from('product_images')
              .update({ 
                image_type: img.image_type,
                updated_at: new Date().toISOString()
              })
              .eq('id', img.id)
          );

        const results = await Promise.all(updatePromises);
        
        // Check for errors
        const errors = results.filter(result => result.error);
        if (errors.length > 0) {
          throw new Error('Failed to update image types');
        }

        toast({
          title: "Primary image updated",
          description: `Image ${index + 1} is now the primary image.`,
        });
      } catch (error) {
        console.error('Failed to set primary image:', error);
        toast({
          title: "Error",
          description: "Failed to update primary image. Please try again.",
          variant: "destructive",
        });
        // Revert on error
        onImagesChange(images);
      }
    } else {
      toast({
        title: "Primary image updated",
        description: `Image ${index + 1} is now the primary image.`,
      });
    }
  }, [images, productId, onImagesChange]);

  return (
    <div className="space-y-4">
      {/* Upload Area */}
      {allowUpload && images.length < maxImages && (
        <div className="space-y-4">
          <div className="flex items-center justify-between">
            <div>
              <h3 className="text-lg font-medium">Product Images</h3>
              <p className="text-sm text-muted-foreground">
                Drag to reorder • Click "Set Primary" to change featured image • {images.length}/{maxImages} images
              </p>
            </div>
            <Button 
              variant="outline" 
              onClick={() => fileInputRef.current?.click()}
              disabled={isUploading}
            >
              <Upload className="h-4 w-4 mr-2" />
              {isUploading ? 'Uploading...' : 'Upload Images'}
            </Button>
          </div>
          
          <div 
            className="border-2 border-dashed border-muted rounded-lg p-6 text-center hover:border-muted-foreground/50 transition-colors cursor-pointer"
            onClick={() => fileInputRef.current?.click()}
            onDragOver={(e) => {
              e.preventDefault();
              e.currentTarget.classList.add('border-primary');
            }}
            onDragLeave={(e) => {
              e.preventDefault();
              e.currentTarget.classList.remove('border-primary');
            }}
            onDrop={(e) => {
              e.preventDefault();
              e.currentTarget.classList.remove('border-primary');
              handleFileUpload(e.dataTransfer.files);
            }}
          >
            <Upload className="h-8 w-8 text-muted-foreground mx-auto mb-2" />
            <p className="text-sm font-medium">Drag & drop images here</p>
            <p className="text-xs text-muted-foreground">or click to browse • JPG, PNG, WebP up to 10MB</p>
          </div>

          <input
            ref={fileInputRef}
            type="file"
            accept="image/*"
            multiple
            className="hidden"
            onChange={(e) => handleFileUpload(e.target.files)}
          />
        </div>
      )}

      {/* Images Grid */}
      {images.length > 0 && (
        <DndContext
          sensors={sensors}
          collisionDetection={closestCenter}
          onDragStart={handleDragStart}
          onDragEnd={handleDragEnd}
          // Fix coordinate system issues by ensuring proper measuring
          measuring={{
            droppable: {
              strategy: 'always',
            },
          }}
        >
          <SortableContext items={images.map(img => img.url)} strategy={rectSortingStrategy}>
            <div 
              className="grid grid-cols-1 sm:grid-cols-2 md:grid-cols-3 lg:grid-cols-4 gap-4"
              style={{
                // Ensure the grid container doesn't interfere with drag calculations
                position: 'relative',
                isolation: 'isolate',
              }}
            >
              {images.map((image, index) => (
                <SortableImage
                  key={image.url}
                  image={image}
                  index={index}
                  onRemove={handleRemoveImage}
                  onAltTextChange={handleAltTextChange}
                  onSetPrimary={handleSetPrimary}
                />
              ))}
            </div>
          </SortableContext>

          <DragOverlay>
            {activeId ? (
              <div className="bg-white border rounded-lg p-2 shadow-lg opacity-90">
                <div className="aspect-square w-24">
                  <img
                    src={activeId}
                    alt="Dragging"
                    className="w-full h-full object-cover rounded-md"
                  />
                </div>
              </div>
            ) : null}
          </DragOverlay>
        </DndContext>
      )}

      {/* Empty State */}
      {images.length === 0 && !allowUpload && (
        <div className="text-center py-8">
          <ImageIcon className="h-12 w-12 text-muted-foreground mx-auto mb-4" />
          <p className="text-lg font-medium">No images uploaded</p>
          <p className="text-sm text-muted-foreground">Upload images to see them here</p>
        </div>
      )}
    </div>
  );
}, (prevProps, nextProps) => {
  // Custom comparison for React.memo optimization
  return (
    prevProps.images === nextProps.images &&
    prevProps.productId === nextProps.productId &&
    prevProps.maxImages === nextProps.maxImages &&
    prevProps.allowUpload === nextProps.allowUpload &&
    // Compare callback functions by reference (parent should memoize them)
    prevProps.onImagesChange === nextProps.onImagesChange
  );
});

export default DraggableImageGallery;