/**
 * CACHING UTILITIES
 * Optimizes performance by caching frequently accessed data
 * Created: 2025-08-10
 */

interface CacheItem<T> {
  data: T;
  timestamp: number;
  ttl: number;
}

class MemoryCache {
  private cache = new Map<string, CacheItem<any>>();
  private maxSize: number;

  constructor(maxSize: number = 1000) {
    this.maxSize = maxSize;
  }

  set<T>(key: string, data: T, ttlMs: number = 5 * 60 * 1000): void {
    // Remove oldest items if cache is full
    if (this.cache.size >= this.maxSize) {
      const oldestKey = this.cache.keys().next().value;
      this.cache.delete(oldestKey);
    }

    this.cache.set(key, {
      data,
      timestamp: Date.now(),
      ttl: ttlMs
    });
  }

  get<T>(key: string): T | null {
    const item = this.cache.get(key);
    if (!item) return null;

    // Check if item has expired
    if (Date.now() - item.timestamp > item.ttl) {
      this.cache.delete(key);
      return null;
    }

    return item.data;
  }

  delete(key: string): void {
    this.cache.delete(key);
  }

  clear(): void {
    this.cache.clear();
  }

  size(): number {
    return this.cache.size;
  }

  // Clean up expired items
  cleanup(): number {
    const now = Date.now();
    let removed = 0;

    for (const [key, item] of this.cache.entries()) {
      if (now - item.timestamp > item.ttl) {
        this.cache.delete(key);
        removed++;
      }
    }

    return removed;
  }

  // Get cache statistics
  getStats(): {
    size: number;
    maxSize: number;
    keys: string[];
    oldestItem?: { key: string; age: number };
  } {
    let oldestItem: { key: string; age: number } | undefined;
    let oldestTime = Date.now();

    for (const [key, item] of this.cache.entries()) {
      if (item.timestamp < oldestTime) {
        oldestTime = item.timestamp;
        oldestItem = {
          key,
          age: Date.now() - item.timestamp
        };
      }
    }

    return {
      size: this.cache.size,
      maxSize: this.maxSize,
      keys: Array.from(this.cache.keys()),
      oldestItem
    };
  }
}

// Global cache instance
const globalCache = new MemoryCache(2000);

// Product-specific cache utilities
export const productCache = {
  // Cache products by category
  setProductsByCategory: (category: string, products: any[], ttlMs: number = 5 * 60 * 1000) => {
    globalCache.set(`products:category:${category}`, products, ttlMs);
  },

  getProductsByCategory: (category: string): any[] | null => {
    return globalCache.get(`products:category:${category}`);
  },

  // Cache individual product
  setProduct: (productId: string, product: any, ttlMs: number = 10 * 60 * 1000) => {
    globalCache.set(`product:${productId}`, product, ttlMs);
  },

  getProduct: (productId: string): any | null => {
    return globalCache.get(`product:${productId}`);
  },

  // Cache product images
  setProductImages: (productId: string, images: any[], ttlMs: number = 30 * 60 * 1000) => {
    globalCache.set(`product:images:${productId}`, images, ttlMs);
  },

  getProductImages: (productId: string): any[] | null => {
    return globalCache.get(`product:images:${productId}`);
  },

  // Cache search results
  setSearchResults: (query: string, results: any[], ttlMs: number = 2 * 60 * 1000) => {
    const searchKey = `search:${query.toLowerCase().trim()}`;
    globalCache.set(searchKey, results, ttlMs);
  },

  getSearchResults: (query: string): any[] | null => {
    const searchKey = `search:${query.toLowerCase().trim()}`;
    return globalCache.get(searchKey);
  },

  // Cache all products
  setAllProducts: (products: any[], ttlMs: number = 3 * 60 * 1000) => {
    globalCache.set('products:all', products, ttlMs);
  },

  getAllProducts: (): any[] | null => {
    return globalCache.get('products:all');
  },

  // Invalidate product-related caches
  invalidateProduct: (productId: string) => {
    globalCache.delete(`product:${productId}`);
    globalCache.delete(`product:images:${productId}`);
    
    // Clear category and search caches when a product is updated
    const stats = globalCache.getStats();
    stats.keys.forEach(key => {
      if (key.startsWith('products:category:') || 
          key.startsWith('search:') || 
          key === 'products:all') {
        globalCache.delete(key);
      }
    });
  },

  // Clear all caches
  clearAll: () => {
    globalCache.clear();
  },

  // Get cache statistics
  getStats: () => {
    return globalCache.getStats();
  },

  // Run cleanup
  cleanup: () => {
    return globalCache.cleanup();
  }
};

// Browser storage cache for persistence across sessions
export const persistentCache = {
  set: (key: string, data: any, ttlMs: number = 10 * 60 * 1000) => {
    try {
      const item = {
        data,
        timestamp: Date.now(),
        ttl: ttlMs
      };
      localStorage.setItem(`cache:${key}`, JSON.stringify(item));
    } catch (error) {
      console.warn('Failed to set persistent cache:', error);
    }
  },

  get: <T>(key: string): T | null => {
    try {
      const cached = localStorage.getItem(`cache:${key}`);
      if (!cached) return null;

      const item = JSON.parse(cached);
      
      // Check if expired
      if (Date.now() - item.timestamp > item.ttl) {
        localStorage.removeItem(`cache:${key}`);
        return null;
      }

      return item.data;
    } catch (error) {
      console.warn('Failed to get persistent cache:', error);
      return null;
    }
  },

  delete: (key: string) => {
    try {
      localStorage.removeItem(`cache:${key}`);
    } catch (error) {
      console.warn('Failed to delete persistent cache:', error);
    }
  },

  clear: () => {
    try {
      const keys = Object.keys(localStorage).filter(key => key.startsWith('cache:'));
      keys.forEach(key => localStorage.removeItem(key));
    } catch (error) {
      console.warn('Failed to clear persistent cache:', error);
    }
  },

  cleanup: () => {
    try {
      const now = Date.now();
      let removed = 0;

      const keys = Object.keys(localStorage).filter(key => key.startsWith('cache:'));
      
      keys.forEach(key => {
        try {
          const item = JSON.parse(localStorage.getItem(key) || '{}');
          if (now - (item.timestamp || 0) > (item.ttl || 0)) {
            localStorage.removeItem(key);
            removed++;
          }
        } catch {
          // Invalid cache item, remove it
          localStorage.removeItem(key);
          removed++;
        }
      });

      return removed;
    } catch (error) {
      console.warn('Failed to cleanup persistent cache:', error);
      return 0;
    }
  }
};

// Auto-cleanup expired items every 5 minutes
if (typeof window !== 'undefined') {
  setInterval(() => {
    const memoryRemoved = globalCache.cleanup();
    const persistentRemoved = persistentCache.cleanup();
    
    if (memoryRemoved > 0 || persistentRemoved > 0) {
      console.debug(`Cache cleanup: removed ${memoryRemoved} memory items, ${persistentRemoved} persistent items`);
    }
  }, 5 * 60 * 1000);
}