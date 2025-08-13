/**
 * COMPREHENSIVE CACHING STRATEGY FOR KCT MENSWEAR
 * Multi-layer caching system for optimal performance at scale
 * 
 * Supports:
 * - In-memory caching (Redis/Memory)
 * - Database query caching
 * - CDN caching for static assets
 * - Browser caching optimization
 * - Cache invalidation strategies
 */

// ============================================
// CACHE CONFIGURATION
// ============================================

export interface CacheConfig {
  // Redis configuration (if available)
  redis?: {
    host: string;
    port: number;
    password?: string;
    db: number;
    maxRetriesPerRequest: number;
    retryDelayOnFailover: number;
    enableOfflineQueue: boolean;
  };
  
  // Memory cache configuration
  memory: {
    maxSize: number;        // Maximum memory usage in MB
    ttlMs: number;         // Default TTL in milliseconds
    checkPeriodMs: number; // Cleanup interval
    maxKeys: number;       // Maximum number of keys
  };
  
  // Cache strategies per data type
  strategies: {
    products: CacheStrategy;
    categories: CacheStrategy;
    orders: CacheStrategy;
    users: CacheStrategy;
    analytics: CacheStrategy;
    images: CacheStrategy;
  };
  
  // Global settings
  enableCompression: boolean;
  enableMetrics: boolean;
  debugMode: boolean;
}

export interface CacheStrategy {
  ttlMs: number;           // Time to live
  staleWhileRevalidate: number; // Grace period for stale data
  maxAge: number;          // Browser cache max age
  sWR: boolean;            // Stale-while-revalidate enabled
  tags: string[];          // Cache tags for invalidation
  compression: boolean;    // Enable compression for this data type
}

// Production-optimized cache configuration
export const PRODUCTION_CACHE_CONFIG: CacheConfig = {
  redis: {
    host: process.env.REDIS_HOST || 'localhost',
    port: parseInt(process.env.REDIS_PORT || '6379'),
    password: process.env.REDIS_PASSWORD,
    db: parseInt(process.env.REDIS_DB || '0'),
    maxRetriesPerRequest: 3,
    retryDelayOnFailover: 100,
    enableOfflineQueue: false,
  },
  
  memory: {
    maxSize: 256,          // 256MB max memory usage
    ttlMs: 300000,         // 5 minutes default TTL
    checkPeriodMs: 60000,  // Check every minute
    maxKeys: 10000,        // Maximum 10k keys
  },
  
  strategies: {
    products: {
      ttlMs: 900000,         // 15 minutes (products change infrequently)
      staleWhileRevalidate: 300000, // 5 minutes grace
      maxAge: 3600,          // 1 hour browser cache
      sWR: true,
      tags: ['products', 'catalog'],
      compression: true,
    },
    
    categories: {
      ttlMs: 3600000,        // 1 hour (categories rarely change)
      staleWhileRevalidate: 600000, // 10 minutes grace
      maxAge: 7200,          // 2 hours browser cache
      sWR: true,
      tags: ['categories', 'navigation'],
      compression: false,
    },
    
    orders: {
      ttlMs: 60000,          // 1 minute (orders change frequently)
      staleWhileRevalidate: 30000, // 30 seconds grace
      maxAge: 0,             // No browser cache
      sWR: false,
      tags: ['orders', 'fulfillment'],
      compression: true,
    },
    
    users: {
      ttlMs: 300000,         // 5 minutes
      staleWhileRevalidate: 60000, // 1 minute grace
      maxAge: 300,           // 5 minutes browser cache
      sWR: true,
      tags: ['users', 'profiles'],
      compression: false,
    },
    
    analytics: {
      ttlMs: 1800000,        // 30 minutes (analytics can be slightly stale)
      staleWhileRevalidate: 900000, // 15 minutes grace
      maxAge: 1800,          // 30 minutes browser cache
      sWR: true,
      tags: ['analytics', 'reporting'],
      compression: true,
    },
    
    images: {
      ttlMs: 86400000,       // 24 hours (images rarely change)
      staleWhileRevalidate: 3600000, // 1 hour grace
      maxAge: 86400,         // 24 hours browser cache
      sWR: true,
      tags: ['images', 'media'],
      compression: false,
    },
  },
  
  enableCompression: true,
  enableMetrics: true,
  debugMode: false,
};

// Development configuration (shorter TTLs for testing)
export const DEVELOPMENT_CACHE_CONFIG: CacheConfig = {
  memory: {
    maxSize: 64,           // 64MB for development
    ttlMs: 60000,          // 1 minute default
    checkPeriodMs: 30000,  // Check every 30 seconds
    maxKeys: 1000,
  },
  
  strategies: {
    products: {
      ttlMs: 60000,          // 1 minute
      staleWhileRevalidate: 30000,
      maxAge: 60,
      sWR: true,
      tags: ['products'],
      compression: false,
    },
    
    categories: {
      ttlMs: 120000,         // 2 minutes
      staleWhileRevalidate: 60000,
      maxAge: 120,
      sWR: true,
      tags: ['categories'],
      compression: false,
    },
    
    orders: {
      ttlMs: 30000,          // 30 seconds
      staleWhileRevalidate: 15000,
      maxAge: 0,
      sWR: false,
      tags: ['orders'],
      compression: false,
    },
    
    users: {
      ttlMs: 60000,
      staleWhileRevalidate: 30000,
      maxAge: 60,
      sWR: true,
      tags: ['users'],
      compression: false,
    },
    
    analytics: {
      ttlMs: 300000,         // 5 minutes
      staleWhileRevalidate: 120000,
      maxAge: 300,
      sWR: true,
      tags: ['analytics'],
      compression: false,
    },
    
    images: {
      ttlMs: 3600000,        // 1 hour
      staleWhileRevalidate: 1800000,
      maxAge: 3600,
      sWR: true,
      tags: ['images'],
      compression: false,
    },
  },
  
  enableCompression: false,
  enableMetrics: true,
  debugMode: true,
};

// ============================================
// CACHE MANAGER
// ============================================

interface CacheItem<T> {
  data: T;
  timestamp: number;
  ttl: number;
  tags: string[];
  compressed?: boolean;
  hits: number;
  lastAccessed: number;
}

export class AdvancedCacheManager {
  private memoryCache = new Map<string, CacheItem<any>>();
  private config: CacheConfig;
  private metrics = {
    hits: 0,
    misses: 0,
    sets: 0,
    deletes: 0,
    evictions: 0,
    memoryUsage: 0,
  };
  private cleanupInterval?: NodeJS.Timeout;

  constructor(config: CacheConfig = PRODUCTION_CACHE_CONFIG) {
    this.config = config;
    this.startCleanupInterval();
  }

  /**
   * Get item from cache with stale-while-revalidate support
   */
  async get<T>(key: string, dataType: keyof CacheConfig['strategies']): Promise<{
    data: T | null;
    isStale: boolean;
    shouldRevalidate: boolean;
  }> {
    const item = this.memoryCache.get(key);
    
    if (!item) {
      this.metrics.misses++;
      return { data: null, isStale: false, shouldRevalidate: true };
    }

    const now = Date.now();
    const age = now - item.timestamp;
    const strategy = this.config.strategies[dataType];
    
    // Update access tracking
    item.hits++;
    item.lastAccessed = now;
    this.metrics.hits++;

    // Check if data is fresh
    if (age <= strategy.ttlMs) {
      return {
        data: this.decompressIfNeeded(item.data, item.compressed),
        isStale: false,
        shouldRevalidate: false,
      };
    }

    // Check if within stale-while-revalidate window
    if (strategy.sWR && age <= (strategy.ttlMs + strategy.staleWhileRevalidate)) {
      return {
        data: this.decompressIfNeeded(item.data, item.compressed),
        isStale: true,
        shouldRevalidate: true,
      };
    }

    // Data is too old
    this.memoryCache.delete(key);
    this.metrics.misses++;
    return { data: null, isStale: false, shouldRevalidate: true };
  }

  /**
   * Set item in cache with compression if enabled
   */
  async set<T>(
    key: string, 
    data: T, 
    dataType: keyof CacheConfig['strategies'],
    customTtl?: number
  ): Promise<void> {
    const strategy = this.config.strategies[dataType];
    const ttl = customTtl || strategy.ttlMs;
    const shouldCompress = strategy.compression && this.config.enableCompression;
    
    const item: CacheItem<T> = {
      data: shouldCompress ? this.compressData(data) : data,
      timestamp: Date.now(),
      ttl,
      tags: strategy.tags,
      compressed: shouldCompress,
      hits: 0,
      lastAccessed: Date.now(),
    };

    // Check memory limits before setting
    await this.enforceMemoryLimits();
    
    this.memoryCache.set(key, item);
    this.metrics.sets++;
  }

  /**
   * Delete specific cache item
   */
  async delete(key: string): Promise<boolean> {
    const deleted = this.memoryCache.delete(key);
    if (deleted) {
      this.metrics.deletes++;
    }
    return deleted;
  }

  /**
   * Invalidate cache by tags
   */
  async invalidateByTags(tags: string[]): Promise<number> {
    let deletedCount = 0;
    
    for (const [key, item] of this.memoryCache.entries()) {
      if (item.tags.some(tag => tags.includes(tag))) {
        this.memoryCache.delete(key);
        deletedCount++;
      }
    }
    
    this.metrics.deletes += deletedCount;
    return deletedCount;
  }

  /**
   * Clear all cache
   */
  async clear(): Promise<void> {
    const size = this.memoryCache.size;
    this.memoryCache.clear();
    this.metrics.deletes += size;
  }

  /**
   * Get cache statistics
   */
  getStats() {
    const totalOperations = this.metrics.hits + this.metrics.misses;
    const hitRate = totalOperations > 0 ? (this.metrics.hits / totalOperations * 100).toFixed(2) : '0';
    
    return {
      ...this.metrics,
      hitRate: `${hitRate}%`,
      totalKeys: this.memoryCache.size,
      avgMemoryPerKey: this.memoryCache.size > 0 
        ? Math.round(this.getMemoryUsage() / this.memoryCache.size) 
        : 0,
    };
  }

  /**
   * Get top accessed cache keys
   */
  getTopKeys(limit: number = 10): Array<{ key: string; hits: number; lastAccessed: Date }> {
    return Array.from(this.memoryCache.entries())
      .map(([key, item]) => ({
        key,
        hits: item.hits,
        lastAccessed: new Date(item.lastAccessed),
      }))
      .sort((a, b) => b.hits - a.hits)
      .slice(0, limit);
  }

  /**
   * Shutdown cache manager
   */
  shutdown(): void {
    if (this.cleanupInterval) {
      clearInterval(this.cleanupInterval);
    }
    this.memoryCache.clear();
  }

  // ============================================
  // PRIVATE METHODS
  // ============================================

  private startCleanupInterval(): void {
    this.cleanupInterval = setInterval(() => {
      this.cleanup();
    }, this.config.memory.checkPeriodMs);
  }

  private cleanup(): void {
    const now = Date.now();
    let evicted = 0;

    for (const [key, item] of this.memoryCache.entries()) {
      const age = now - item.timestamp;
      
      // Remove expired items (beyond stale-while-revalidate window)
      if (age > (item.ttl + 300000)) { // 5 minutes grace period
        this.memoryCache.delete(key);
        evicted++;
      }
    }

    this.metrics.evictions += evicted;
    
    // Enforce memory limits
    this.enforceMemoryLimits();
  }

  private async enforceMemoryLimits(): Promise<void> {
    const memoryUsage = this.getMemoryUsage();
    const maxMemoryBytes = this.config.memory.maxSize * 1024 * 1024;
    
    if (memoryUsage > maxMemoryBytes || this.memoryCache.size > this.config.memory.maxKeys) {
      // LRU eviction: remove least recently accessed items
      const entries = Array.from(this.memoryCache.entries())
        .sort((a, b) => a[1].lastAccessed - b[1].lastAccessed);
      
      const targetSize = Math.floor(this.config.memory.maxKeys * 0.8); // Remove 20%
      const toEvict = entries.length - targetSize;
      
      for (let i = 0; i < toEvict; i++) {
        this.memoryCache.delete(entries[i][0]);
        this.metrics.evictions++;
      }
    }
  }

  private getMemoryUsage(): number {
    // Rough estimate of memory usage
    let totalSize = 0;
    for (const [key, item] of this.memoryCache.entries()) {
      totalSize += key.length * 2; // String character size
      totalSize += JSON.stringify(item).length * 2; // Approximate item size
    }
    return totalSize;
  }

  private compressData<T>(data: T): string {
    // Simple JSON compression (in production, use actual compression library)
    return JSON.stringify(data);
  }

  private decompressIfNeeded<T>(data: any, compressed?: boolean): T {
    if (compressed && typeof data === 'string') {
      return JSON.parse(data);
    }
    return data;
  }
}

// ============================================
// CACHE HELPERS AND UTILITIES
// ============================================

/**
 * Cache key generator for consistent naming
 */
export class CacheKeyGenerator {
  static product(id: string): string {
    return `product:${id}`;
  }

  static productList(filters: Record<string, any>): string {
    const filterString = Object.entries(filters)
      .sort(([a], [b]) => a.localeCompare(b))
      .map(([key, value]) => `${key}:${value}`)
      .join('|');
    return `products:list:${filterString}`;
  }

  static productsByCategory(category: string, page: number = 1): string {
    return `products:category:${category}:page:${page}`;
  }

  static order(id: string): string {
    return `order:${id}`;
  }

  static orderList(userId: string, page: number = 1): string {
    return `orders:user:${userId}:page:${page}`;
  }

  static user(id: string): string {
    return `user:${id}`;
  }

  static analytics(query: string, dateRange: string): string {
    return `analytics:${query}:${dateRange}`;
  }

  static search(term: string, filters: Record<string, any>): string {
    const filterString = Object.entries(filters)
      .sort(([a], [b]) => a.localeCompare(b))
      .map(([key, value]) => `${key}:${value}`)
      .join('|');
    return `search:${term}:${filterString}`;
  }
}

/**
 * Cache wrapper for database queries
 */
export function withCache<T>(
  cacheManager: AdvancedCacheManager,
  key: string,
  dataType: keyof CacheConfig['strategies'],
  queryFn: () => Promise<T>
): Promise<T> {
  return async function cachedQuery(): Promise<T> {
    // Try to get from cache first
    const { data, shouldRevalidate } = await cacheManager.get<T>(key, dataType);
    
    if (data && !shouldRevalidate) {
      return data;
    }

    // Fetch fresh data
    const freshData = await queryFn();
    
    // Cache the result
    await cacheManager.set(key, freshData, dataType);
    
    return freshData;
  }();
}

// ============================================
// CACHE INVALIDATION STRATEGIES
// ============================================

export class CacheInvalidationManager {
  constructor(private cacheManager: AdvancedCacheManager) {}

  /**
   * Invalidate product-related caches when product changes
   */
  async onProductUpdate(productId: string): Promise<void> {
    await Promise.all([
      this.cacheManager.delete(CacheKeyGenerator.product(productId)),
      this.cacheManager.invalidateByTags(['products', 'catalog']),
    ]);
  }

  /**
   * Invalidate order caches when order changes
   */
  async onOrderUpdate(orderId: string, userId?: string): Promise<void> {
    const promises = [
      this.cacheManager.delete(CacheKeyGenerator.order(orderId)),
      this.cacheManager.invalidateByTags(['orders']),
    ];

    if (userId) {
      // Invalidate user's order lists
      for (let page = 1; page <= 10; page++) {
        promises.push(
          this.cacheManager.delete(CacheKeyGenerator.orderList(userId, page))
        );
      }
    }

    await Promise.all(promises);
  }

  /**
   * Invalidate user caches when user data changes
   */
  async onUserUpdate(userId: string): Promise<void> {
    await Promise.all([
      this.cacheManager.delete(CacheKeyGenerator.user(userId)),
      this.cacheManager.invalidateByTags(['users']),
    ]);
  }

  /**
   * Invalidate analytics caches (usually on schedule)
   */
  async onAnalyticsRefresh(): Promise<void> {
    await this.cacheManager.invalidateByTags(['analytics', 'reporting']);
  }
}

// ============================================
// SINGLETON INSTANCE
// ============================================

let cacheManager: AdvancedCacheManager | null = null;

export function createCacheManager(config?: CacheConfig): AdvancedCacheManager {
  if (!cacheManager) {
    const cacheConfig = config || (
      process.env.NODE_ENV === 'production' 
        ? PRODUCTION_CACHE_CONFIG 
        : DEVELOPMENT_CACHE_CONFIG
    );
    
    cacheManager = new AdvancedCacheManager(cacheConfig);
  }
  
  return cacheManager;
}

export function getCacheManager(): AdvancedCacheManager {
  if (!cacheManager) {
    throw new Error('Cache manager not initialized. Call createCacheManager first.');
  }
  
  return cacheManager;
}

// ============================================
// USAGE EXAMPLES
// ============================================

/*
// Initialize cache manager
const cache = createCacheManager(PRODUCTION_CACHE_CONFIG);

// Use with database query
const products = await withCache(
  cache,
  CacheKeyGenerator.productsByCategory('suits', 1),
  'products',
  async () => {
    return await fetchProductsFromDatabase({ category: 'suits' });
  }
);

// Manual cache operations
await cache.set('custom_key', { data: 'value' }, 'products');
const result = await cache.get('custom_key', 'products');

// Cache invalidation
const invalidationManager = new CacheInvalidationManager(cache);
await invalidationManager.onProductUpdate('product-123');

// Get cache statistics
const stats = cache.getStats();
console.log('Cache hit rate:', stats.hitRate);

// Cleanup
cache.shutdown();
*/

export default AdvancedCacheManager;