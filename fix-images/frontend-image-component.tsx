// Image Component with Fallback System
// Place this in your frontend components folder

import { useState } from 'react';
import Image from 'next/image';

interface ProductImageProps {
  src?: string | null;
  alt: string;
  category?: string;
  className?: string;
  width?: number;
  height?: number;
  priority?: boolean;
}

// Fallback images by category
const FALLBACK_IMAGES: Record<string, string> = {
  "Men's Suits": '/images/fallback/suit.jpg',
  "Men's Blazers": '/images/fallback/blazer.jpg',
  "Men's Shirts": '/images/fallback/shirt.jpg',
  "Men's Pants": '/images/fallback/pants.jpg',
  "Accessories": '/images/fallback/accessories.jpg',
  "Vest & Tie Sets": '/images/fallback/vest-tie.jpg',
  "Men's Shoes": '/images/fallback/shoes.jpg',
  "Men's Tuxedos": '/images/fallback/tuxedo.jpg',
  "default": '/images/fallback/product.jpg'
};

export function ProductImage({ 
  src, 
  alt, 
  category = 'default',
  className = '',
  width = 400,
  height = 600,
  priority = false
}: ProductImageProps) {
  const [imgSrc, setImgSrc] = useState(src || '');
  const [hasError, setHasError] = useState(false);

  // Fix old bucket URLs
  const fixImageUrl = (url: string): string => {
    if (!url) return '';
    
    // Replace old bucket with new bucket
    if (url.includes('pub-8ea1de89-a731-488f-b407-5acfb4524ad7')) {
      return url.replace(
        'pub-8ea1de89-a731-488f-b407-5acfb4524ad7',
        'pub-5cd73a21-13cf-48bd-8d3f-e0fdcbcb0db2'
      );
    }
    
    return url;
  };

  const handleError = () => {
    if (!hasError) {
      setHasError(true);
      // Try category-specific fallback, then default
      const fallback = FALLBACK_IMAGES[category] || FALLBACK_IMAGES.default;
      setImgSrc(fallback);
    }
  };

  // Use fixed URL or fallback
  const imageUrl = hasError 
    ? imgSrc 
    : fixImageUrl(imgSrc) || FALLBACK_IMAGES[category] || FALLBACK_IMAGES.default;

  return (
    <div className={`relative ${className}`}>
      <Image
        src={imageUrl}
        alt={alt}
        width={width}
        height={height}
        priority={priority}
        onError={handleError}
        className="object-cover w-full h-full"
        placeholder="blur"
        blurDataURL="data:image/jpeg;base64,/9j/4AAQSkZJRgABAQAAAQ..."
      />
      {hasError && (
        <div className="absolute top-2 right-2 bg-yellow-100 text-yellow-800 text-xs px-2 py-1 rounded">
          No image
        </div>
      )}
    </div>
  );
}

// Usage example:
/*
<ProductImage 
  src={product.primary_image}
  alt={product.name}
  category={product.category}
  className="w-full h-64"
/>
*/