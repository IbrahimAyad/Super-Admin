// Image URL Utility Functions
// Add this to your utils folder

/**
 * Fix broken R2 bucket URLs
 * Replaces old bucket ID with new bucket ID
 */
export function fixImageUrl(url: string | null | undefined): string {
  if (!url) return '';
  
  // Replace old bucket with new bucket
  if (url.includes('pub-8ea1de89-a731-488f-b407-5acfb4524ad7')) {
    return url.replace(
      'pub-8ea1de89-a731-488f-b407-5acfb4524ad7',
      'pub-5cd73a21-13cf-48bd-8d3f-e0fdcbcb0db2'
    );
  }
  
  return url;
}

/**
 * Get fallback image based on product category
 */
export function getFallbackImage(category?: string): string {
  const fallbacks: Record<string, string> = {
    "Men's Suits": 'https://pub-5cd73a21-13cf-48bd-8d3f-e0fdcbcb0db2.r2.dev/kct-base-products/suit-placeholder.jpg',
    "Men's Blazers": 'https://pub-5cd73a21-13cf-48bd-8d3f-e0fdcbcb0db2.r2.dev/kct-base-products/blazer-placeholder.jpg',
    "Men's Shirts": 'https://pub-5cd73a21-13cf-48bd-8d3f-e0fdcbcb0db2.r2.dev/kct-base-products/shirt-placeholder.jpg',
    "Men's Pants": 'https://pub-5cd73a21-13cf-48bd-8d3f-e0fdcbcb0db2.r2.dev/kct-base-products/pants-placeholder.jpg',
    "Accessories": 'https://pub-5cd73a21-13cf-48bd-8d3f-e0fdcbcb0db2.r2.dev/kct-base-products/accessories-placeholder.jpg',
    "Vest & Tie Sets": 'https://pub-5cd73a21-13cf-48bd-8d3f-e0fdcbcb0db2.r2.dev/kct-base-products/vest-tie-placeholder.jpg',
    "Men's Shoes": 'https://pub-5cd73a21-13cf-48bd-8d3f-e0fdcbcb0db2.r2.dev/kct-base-products/shoes-placeholder.jpg',
    "Men's Tuxedos": 'https://pub-5cd73a21-13cf-48bd-8d3f-e0fdcbcb0db2.r2.dev/kct-base-products/tuxedo-placeholder.jpg',
  };
  
  // Default fallback
  const defaultImage = 'https://pub-5cd73a21-13cf-48bd-8d3f-e0fdcbcb0db2.r2.dev/kct-base-products/product-placeholder.jpg';
  
  return fallbacks[category || ''] || defaultImage;
}

/**
 * Get product image with automatic fallback
 */
export function getProductImage(
  primaryImage?: string | null,
  category?: string
): string {
  // First try to fix the URL if it exists
  const fixedUrl = fixImageUrl(primaryImage);
  
  // If we have a fixed URL, return it
  if (fixedUrl) {
    return fixedUrl;
  }
  
  // Otherwise return category-specific fallback
  return getFallbackImage(category);
}

/**
 * Check if image URL is using old bucket
 */
export function isOldBucketUrl(url: string | null | undefined): boolean {
  if (!url) return false;
  return url.includes('pub-8ea1de89-a731-488f-b407-5acfb4524ad7');
}

/**
 * Validate if image URL is accessible
 * Can be used to pre-check images
 */
export async function validateImageUrl(url: string): Promise<boolean> {
  try {
    const response = await fetch(url, { method: 'HEAD' });
    return response.ok;
  } catch {
    return false;
  }
}

// Export all functions
export default {
  fixImageUrl,
  getFallbackImage,
  getProductImage,
  isOldBucketUrl,
  validateImageUrl
};