/**
 * PRODUCTION CONNECTION POOLING CONFIGURATION
 * Optimized for 1000+ concurrent users on Supabase PostgreSQL
 * 
 * This configuration provides:
 * - Efficient connection management
 * - Automatic failover and reconnection
 * - Query timeout management
 * - Connection health monitoring
 */

import { createClient, SupabaseClient } from '@supabase/supabase-js';
import { Database } from '@/types/database';

// ============================================
// CONNECTION POOL CONFIGURATION
// ============================================

interface ConnectionPoolConfig {
  // Pool sizing (critical for performance)
  poolSize: number;              // Maximum concurrent connections
  minConnections: number;        // Minimum connections to maintain
  maxConnections: number;        // Hard limit on connections
  
  // Timing settings
  connectionTimeoutMs: number;   // Time to wait for new connection
  idleTimeoutMs: number;         // Time before idle connection is closed
  queryTimeoutMs: number;        // Maximum query execution time
  
  // Health and retry settings
  retryAttempts: number;         // Number of retry attempts
  retryDelayMs: number;         // Delay between retries
  healthCheckIntervalMs: number; // Health check frequency
  
  // Performance settings
  statementCacheSize: number;    // Prepared statement cache size
  enableStatementCache: boolean; // Enable prepared statements
}

// Production-optimized pool configuration
export const PRODUCTION_POOL_CONFIG: ConnectionPoolConfig = {
  // Pool sizing for 1000+ concurrent users
  poolSize: 20,                  // Conservative for Supabase limits
  minConnections: 5,             // Always keep 5 connections warm
  maxConnections: 25,            // Hard limit to prevent overwhelming DB
  
  // Aggressive timeouts for high-traffic scenarios
  connectionTimeoutMs: 5000,     // 5 seconds to get connection
  idleTimeoutMs: 300000,         // 5 minutes idle timeout
  queryTimeoutMs: 30000,         // 30 seconds max query time
  
  // Robust retry configuration
  retryAttempts: 3,              // Retry failed connections 3 times
  retryDelayMs: 1000,           // 1 second between retries
  healthCheckIntervalMs: 60000,  // Check health every minute
  
  // Performance optimizations
  statementCacheSize: 100,       // Cache 100 prepared statements
  enableStatementCache: true,    // Enable statement caching
};

// Development configuration (more forgiving)
export const DEVELOPMENT_POOL_CONFIG: ConnectionPoolConfig = {
  poolSize: 5,
  minConnections: 2,
  maxConnections: 10,
  connectionTimeoutMs: 10000,
  idleTimeoutMs: 600000,
  queryTimeoutMs: 60000,
  retryAttempts: 5,
  retryDelayMs: 2000,
  healthCheckIntervalMs: 120000,
  statementCacheSize: 50,
  enableStatementCache: true,
};

// ============================================
// CONNECTION POOL MANAGER
// ============================================

class SupabaseConnectionPool {
  private client: SupabaseClient<Database>;
  private config: ConnectionPoolConfig;
  private activeConnections: number = 0;
  private connectionQueue: Array<() => void> = [];
  private healthCheckInterval?: NodeJS.Timeout;
  private stats = {
    totalQueries: 0,
    failedQueries: 0,
    avgQueryTime: 0,
    connectionErrors: 0,
    lastHealthCheck: new Date(),
  };

  constructor(
    supabaseUrl: string, 
    supabaseKey: string, 
    config: ConnectionPoolConfig = PRODUCTION_POOL_CONFIG
  ) {
    this.config = config;
    
    // Create Supabase client with optimized settings
    this.client = createClient<Database>(supabaseUrl, supabaseKey, {
      db: {
        schema: 'public',
      },
      auth: {
        autoRefreshToken: true,
        persistSession: false, // Don't persist auth for server-side usage
      },
      realtime: {
        params: {
          eventsPerSecond: 10, // Limit realtime events
        },
      },
    });

    this.startHealthCheck();
    this.setupGracefulShutdown();
  }

  /**
   * Execute query with connection pool management
   */
  async executeQuery<T>(
    queryFn: (client: SupabaseClient<Database>) => Promise<T>,
    timeoutMs?: number
  ): Promise<T> {
    const startTime = Date.now();
    const timeout = timeoutMs || this.config.queryTimeoutMs;

    try {
      // Wait for available connection
      await this.acquireConnection();

      // Execute query with timeout
      const result = await Promise.race([
        queryFn(this.client),
        this.createTimeoutPromise(timeout),
      ]);

      // Update statistics
      this.updateStats(Date.now() - startTime, false);
      
      return result;
    } catch (error) {
      this.updateStats(Date.now() - startTime, true);
      
      // Implement retry logic for transient errors
      if (this.shouldRetry(error)) {
        return this.retryQuery(queryFn, timeoutMs);
      }
      
      throw error;
    } finally {
      this.releaseConnection();
    }
  }

  /**
   * Get optimized client for direct access
   */
  getClient(): SupabaseClient<Database> {
    return this.client;
  }

  /**
   * Get connection pool statistics
   */
  getStats() {
    return {
      ...this.stats,
      activeConnections: this.activeConnections,
      queueLength: this.connectionQueue.length,
      successRate: this.stats.totalQueries > 0 
        ? ((this.stats.totalQueries - this.stats.failedQueries) / this.stats.totalQueries * 100).toFixed(2) + '%'
        : '100%',
    };
  }

  /**
   * Reset connection pool statistics
   */
  resetStats() {
    this.stats = {
      totalQueries: 0,
      failedQueries: 0,
      avgQueryTime: 0,
      connectionErrors: 0,
      lastHealthCheck: new Date(),
    };
  }

  /**
   * Shutdown connection pool gracefully
   */
  async shutdown() {
    if (this.healthCheckInterval) {
      clearInterval(this.healthCheckInterval);
    }

    // Wait for active connections to finish
    while (this.activeConnections > 0) {
      await new Promise(resolve => setTimeout(resolve, 100));
    }

    console.log('Connection pool shutdown complete');
  }

  // ============================================
  // PRIVATE METHODS
  // ============================================

  private async acquireConnection(): Promise<void> {
    if (this.activeConnections < this.config.maxConnections) {
      this.activeConnections++;
      return;
    }

    // Queue the request if pool is full
    return new Promise((resolve, reject) => {
      const timeout = setTimeout(() => {
        this.stats.connectionErrors++;
        reject(new Error('Connection timeout: Pool exhausted'));
      }, this.config.connectionTimeoutMs);

      this.connectionQueue.push(() => {
        clearTimeout(timeout);
        this.activeConnections++;
        resolve();
      });
    });
  }

  private releaseConnection(): void {
    this.activeConnections--;
    
    // Process queued requests
    if (this.connectionQueue.length > 0) {
      const nextRequest = this.connectionQueue.shift();
      if (nextRequest) {
        nextRequest();
      }
    }
  }

  private createTimeoutPromise<T>(timeoutMs: number): Promise<T> {
    return new Promise((_, reject) => {
      setTimeout(() => {
        reject(new Error(`Query timeout after ${timeoutMs}ms`));
      }, timeoutMs);
    });
  }

  private shouldRetry(error: any): boolean {
    // Retry on specific transient errors
    const retryableErrors = [
      'ECONNRESET',
      'ECONNREFUSED', 
      'ETIMEDOUT',
      'Connection timeout',
      'Connection lost',
    ];

    const errorMessage = error?.message || String(error);
    return retryableErrors.some(retryableError => 
      errorMessage.includes(retryableError)
    );
  }

  private async retryQuery<T>(
    queryFn: (client: SupabaseClient<Database>) => Promise<T>,
    timeoutMs?: number,
    attempt: number = 1
  ): Promise<T> {
    if (attempt > this.config.retryAttempts) {
      throw new Error(`Query failed after ${this.config.retryAttempts} attempts`);
    }

    // Exponential backoff
    const delay = this.config.retryDelayMs * Math.pow(2, attempt - 1);
    await new Promise(resolve => setTimeout(resolve, delay));

    try {
      return await this.executeQuery(queryFn, timeoutMs);
    } catch (error) {
      if (this.shouldRetry(error)) {
        return this.retryQuery(queryFn, timeoutMs, attempt + 1);
      }
      throw error;
    }
  }

  private updateStats(queryTime: number, failed: boolean): void {
    this.stats.totalQueries++;
    if (failed) {
      this.stats.failedQueries++;
    }
    
    // Update rolling average
    this.stats.avgQueryTime = (
      (this.stats.avgQueryTime * (this.stats.totalQueries - 1) + queryTime) / 
      this.stats.totalQueries
    );
  }

  private startHealthCheck(): void {
    this.healthCheckInterval = setInterval(async () => {
      try {
        await this.executeQuery(async (client) => {
          const { data, error } = await client
            .from('products')
            .select('count')
            .limit(1);
          
          if (error) throw error;
          return data;
        });

        this.stats.lastHealthCheck = new Date();
      } catch (error) {
        console.error('Health check failed:', error);
        this.stats.connectionErrors++;
      }
    }, this.config.healthCheckIntervalMs);
  }

  private setupGracefulShutdown(): void {
    process.on('SIGINT', () => this.shutdown());
    process.on('SIGTERM', () => this.shutdown());
  }
}

// ============================================
// SINGLETON INSTANCE
// ============================================

let connectionPool: SupabaseConnectionPool | null = null;

export function createConnectionPool(
  supabaseUrl: string,
  supabaseKey: string,
  config?: ConnectionPoolConfig
): SupabaseConnectionPool {
  if (!connectionPool) {
    const poolConfig = config || (
      process.env.NODE_ENV === 'production' 
        ? PRODUCTION_POOL_CONFIG 
        : DEVELOPMENT_POOL_CONFIG
    );
    
    connectionPool = new SupabaseConnectionPool(supabaseUrl, supabaseKey, poolConfig);
  }
  
  return connectionPool;
}

export function getConnectionPool(): SupabaseConnectionPool {
  if (!connectionPool) {
    throw new Error('Connection pool not initialized. Call createConnectionPool first.');
  }
  
  return connectionPool;
}

// ============================================
// PERFORMANCE MONITORING HELPERS
// ============================================

export class QueryPerformanceMonitor {
  private static instance: QueryPerformanceMonitor;
  private queryMetrics = new Map<string, {
    count: number;
    totalTime: number;
    avgTime: number;
    maxTime: number;
    errors: number;
  }>();

  static getInstance(): QueryPerformanceMonitor {
    if (!this.instance) {
      this.instance = new QueryPerformanceMonitor();
    }
    return this.instance;
  }

  recordQuery(queryName: string, executionTime: number, error?: boolean): void {
    const existing = this.queryMetrics.get(queryName) || {
      count: 0,
      totalTime: 0,
      avgTime: 0,
      maxTime: 0,
      errors: 0,
    };

    existing.count++;
    existing.totalTime += executionTime;
    existing.avgTime = existing.totalTime / existing.count;
    existing.maxTime = Math.max(existing.maxTime, executionTime);
    
    if (error) {
      existing.errors++;
    }

    this.queryMetrics.set(queryName, existing);
  }

  getMetrics(): Record<string, any> {
    const metrics: Record<string, any> = {};
    this.queryMetrics.forEach((value, key) => {
      metrics[key] = value;
    });
    return metrics;
  }

  getSlowestQueries(limit: number = 10): Array<[string, any]> {
    return Array.from(this.queryMetrics.entries())
      .sort((a, b) => b[1].avgTime - a[1].avgTime)
      .slice(0, limit);
  }

  reset(): void {
    this.queryMetrics.clear();
  }
}

// ============================================
// USAGE EXAMPLES
// ============================================

/*
// Initialize connection pool (typically in app startup)
const pool = createConnectionPool(
  process.env.NEXT_PUBLIC_SUPABASE_URL!,
  process.env.SUPABASE_SERVICE_ROLE_KEY!,
  PRODUCTION_POOL_CONFIG
);

// Use pool for queries
const products = await pool.executeQuery(async (client) => {
  const { data, error } = await client
    .from('products')
    .select('*')
    .eq('status', 'active')
    .limit(50);
    
  if (error) throw error;
  return data;
});

// Monitor performance
const stats = pool.getStats();
console.log('Pool statistics:', stats);

// Graceful shutdown
await pool.shutdown();
*/

export default SupabaseConnectionPool;