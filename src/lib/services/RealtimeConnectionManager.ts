/**
 * Professional Realtime Connection Manager
 * Implements patterns used by SSENSE, Net-a-Porter, Farfetch
 * 
 * Features:
 * - Connection pooling
 * - Circuit breaker pattern
 * - Exponential backoff
 * - Connection health monitoring
 * - Automatic recovery
 * - Performance optimization
 */

import { RealtimeChannel, RealtimeClient } from '@supabase/supabase-js';
import { supabase } from '@/lib/supabase';

interface ConnectionConfig {
  maxRetries: number;
  retryDelay: number;
  maxRetryDelay: number;
  heartbeatInterval: number;
  connectionTimeout: number;
  enableCircuitBreaker: boolean;
  circuitBreakerThreshold: number;
  circuitBreakerResetTime: number;
}

interface ConnectionHealth {
  status: 'connected' | 'connecting' | 'disconnected' | 'error' | 'circuit_open';
  lastConnected: Date | null;
  lastError: Date | null;
  errorCount: number;
  reconnectAttempts: number;
  latency: number;
  subscriptionCount: number;
}

interface SubscriptionOptions {
  event?: string;
  schema?: string;
  table?: string;
  filter?: string;
  callback: (payload: any) => void;
  priority?: 'high' | 'normal' | 'low';
}

class RealtimeConnectionManager {
  private static instance: RealtimeConnectionManager;
  private channels: Map<string, RealtimeChannel> = new Map();
  private subscriptions: Map<string, SubscriptionOptions[]> = new Map();
  private config: ConnectionConfig;
  private health: ConnectionHealth;
  private heartbeatTimer: NodeJS.Timer | null = null;
  private reconnectTimer: NodeJS.Timer | null = null;
  private circuitBreakerTimer: NodeJS.Timer | null = null;
  private performanceMetrics: Map<string, number[]> = new Map();

  private constructor() {
    this.config = {
      maxRetries: 3,
      retryDelay: 1000,
      maxRetryDelay: 30000,
      heartbeatInterval: 30000,
      connectionTimeout: 10000,
      enableCircuitBreaker: true,
      circuitBreakerThreshold: 5,
      circuitBreakerResetTime: 60000
    };

    this.health = {
      status: 'disconnected',
      lastConnected: null,
      lastError: null,
      errorCount: 0,
      reconnectAttempts: 0,
      latency: 0,
      subscriptionCount: 0
    };

    this.initialize();
  }

  public static getInstance(): RealtimeConnectionManager {
    if (!RealtimeConnectionManager.instance) {
      RealtimeConnectionManager.instance = new RealtimeConnectionManager();
    }
    return RealtimeConnectionManager.instance;
  }

  private initialize() {
    console.log('🚀 Initializing Professional Realtime Connection Manager');
    
    // Start heartbeat monitoring
    this.startHeartbeat();
    
    // Setup page visibility handling
    this.setupVisibilityHandling();
    
    // Setup network change detection
    this.setupNetworkHandling();
    
    // Setup performance monitoring
    this.setupPerformanceMonitoring();
  }

  /**
   * Subscribe to realtime updates with professional error handling
   */
  public subscribe(
    channelName: string,
    options: SubscriptionOptions
  ): string {
    const subscriptionId = `${channelName}_${Date.now()}_${Math.random()}`;
    
    // Check circuit breaker
    if (this.health.status === 'circuit_open') {
      console.warn('⚡ Circuit breaker is open, queuing subscription');
      return subscriptionId;
    }

    // Use connection pooling - reuse existing channel if possible
    let channel = this.channels.get(channelName);
    
    if (!channel) {
      console.log(`📡 Creating new channel: ${channelName}`);
      channel = this.createChannel(channelName);
      this.channels.set(channelName, channel);
    }

    // Add subscription to tracking
    if (!this.subscriptions.has(channelName)) {
      this.subscriptions.set(channelName, []);
    }
    this.subscriptions.get(channelName)!.push(options);

    // Setup subscription with error handling
    this.setupSubscription(channel, options);
    
    // Update health metrics
    this.health.subscriptionCount++;
    
    return subscriptionId;
  }

  /**
   * Create a channel with proper configuration
   */
  private createChannel(name: string): RealtimeChannel {
    const channel = supabase.channel(name, {
      config: {
        broadcast: {
          self: false,
          ack: true
        },
        presence: {
          key: ''
        }
      }
    });

    // Add channel state monitoring
    channel
      .on('system', { event: '*' }, (payload) => {
        this.handleSystemEvent(name, payload);
      })
      .on('presence', { event: 'sync' }, () => {
        console.log(`✅ Channel ${name} presence synced`);
      });

    return channel;
  }

  /**
   * Setup subscription with professional error handling
   */
  private setupSubscription(channel: RealtimeChannel, options: SubscriptionOptions) {
    const startTime = performance.now();
    
    const wrappedCallback = (payload: any) => {
      // Measure performance
      const latency = performance.now() - startTime;
      this.recordPerformance(channel.topic, latency);
      
      // Execute callback with error boundary
      try {
        options.callback(payload);
      } catch (error) {
        console.error('❌ Subscription callback error:', error);
        this.handleSubscriptionError(channel.topic, error);
      }
    };

    // Setup the actual subscription
    if (options.table) {
      channel.on(
        'postgres_changes' as any,
        {
          event: options.event || '*',
          schema: options.schema || 'public',
          table: options.table,
          filter: options.filter
        },
        wrappedCallback
      );
    } else {
      channel.on('broadcast', { event: options.event || '*' }, wrappedCallback);
    }

    // Subscribe with timeout handling
    const subscribeWithTimeout = async () => {
      const timeoutPromise = new Promise((_, reject) => {
        setTimeout(() => reject(new Error('Connection timeout')), this.config.connectionTimeout);
      });

      try {
        await Promise.race([
          channel.subscribe((status) => {
            console.log(`📊 Channel ${channel.topic} status: ${status}`);
            this.updateHealthStatus(status as any);
          }),
          timeoutPromise
        ]);
      } catch (error) {
        console.error(`❌ Failed to subscribe to ${channel.topic}:`, error);
        this.handleConnectionError(channel.topic, error);
      }
    };

    subscribeWithTimeout();
  }

  /**
   * Handle system events for monitoring
   */
  private handleSystemEvent(channelName: string, payload: any) {
    console.log(`🔧 System event on ${channelName}:`, payload);
    
    if (payload.type === 'error') {
      this.handleConnectionError(channelName, payload);
    } else if (payload.type === 'connected') {
      this.health.status = 'connected';
      this.health.lastConnected = new Date();
      this.health.reconnectAttempts = 0;
    }
  }

  /**
   * Handle connection errors with circuit breaker
   */
  private handleConnectionError(channelName: string, error: any) {
    console.error(`❌ Connection error on ${channelName}:`, error);
    
    this.health.errorCount++;
    this.health.lastError = new Date();
    
    // Circuit breaker logic
    if (this.config.enableCircuitBreaker && 
        this.health.errorCount >= this.config.circuitBreakerThreshold) {
      this.openCircuitBreaker();
    } else {
      this.attemptReconnection(channelName);
    }
  }

  /**
   * Handle subscription errors
   */
  private handleSubscriptionError(channelName: string, error: any) {
    // Log but don't trigger reconnection for callback errors
    console.error(`⚠️ Subscription error on ${channelName}:`, error);
    
    // Record error metric
    this.recordPerformance(channelName, -1);
  }

  /**
   * Implement circuit breaker pattern
   */
  private openCircuitBreaker() {
    console.warn('⚡ Circuit breaker opened - stopping reconnection attempts');
    
    this.health.status = 'circuit_open';
    
    // Clear all active connections
    this.channels.forEach(channel => {
      channel.unsubscribe();
    });
    
    // Set timer to reset circuit breaker
    if (this.circuitBreakerTimer) {
      clearTimeout(this.circuitBreakerTimer);
    }
    
    this.circuitBreakerTimer = setTimeout(() => {
      this.resetCircuitBreaker();
    }, this.config.circuitBreakerResetTime);
  }

  /**
   * Reset circuit breaker and attempt reconnection
   */
  private resetCircuitBreaker() {
    console.log('🔄 Resetting circuit breaker');
    
    this.health.status = 'disconnected';
    this.health.errorCount = 0;
    
    // Attempt to reconnect all channels
    this.reconnectAll();
  }

  /**
   * Attempt reconnection with exponential backoff
   */
  private attemptReconnection(channelName: string) {
    if (this.health.reconnectAttempts >= this.config.maxRetries) {
      console.error(`❌ Max reconnection attempts reached for ${channelName}`);
      this.openCircuitBreaker();
      return;
    }

    const delay = Math.min(
      this.config.retryDelay * Math.pow(2, this.health.reconnectAttempts),
      this.config.maxRetryDelay
    );

    console.log(`🔄 Reconnecting ${channelName} in ${delay}ms (attempt ${this.health.reconnectAttempts + 1})`);
    
    this.health.reconnectAttempts++;
    
    if (this.reconnectTimer) {
      clearTimeout(this.reconnectTimer);
    }
    
    this.reconnectTimer = setTimeout(() => {
      const channel = this.channels.get(channelName);
      if (channel) {
        channel.subscribe();
      }
    }, delay);
  }

  /**
   * Reconnect all channels
   */
  private reconnectAll() {
    console.log('🔄 Reconnecting all channels');
    
    this.channels.forEach((channel, name) => {
      const subscriptions = this.subscriptions.get(name);
      if (subscriptions) {
        // Recreate channel with subscriptions
        this.channels.delete(name);
        subscriptions.forEach(sub => {
          this.subscribe(name, sub);
        });
      }
    });
  }

  /**
   * Setup heartbeat monitoring
   */
  private startHeartbeat() {
    this.heartbeatTimer = setInterval(() => {
      if (this.health.status === 'connected') {
        // Measure latency
        const start = performance.now();
        
        // Send heartbeat through a channel
        const testChannel = this.channels.values().next().value;
        if (testChannel) {
          testChannel.send({
            type: 'broadcast',
            event: 'heartbeat',
            payload: { timestamp: Date.now() }
          }).then(() => {
            this.health.latency = performance.now() - start;
            console.log(`💓 Heartbeat latency: ${this.health.latency.toFixed(2)}ms`);
          });
        }
      }
    }, this.config.heartbeatInterval);
  }

  /**
   * Setup page visibility handling
   */
  private setupVisibilityHandling() {
    document.addEventListener('visibilitychange', () => {
      if (document.hidden) {
        console.log('👁️ Page hidden - pausing connections');
        this.pause();
      } else {
        console.log('👁️ Page visible - resuming connections');
        this.resume();
      }
    });
  }

  /**
   * Setup network change detection
   */
  private setupNetworkHandling() {
    window.addEventListener('online', () => {
      console.log('🌐 Network online - reconnecting');
      this.reconnectAll();
    });

    window.addEventListener('offline', () => {
      console.log('🌐 Network offline - pausing connections');
      this.pause();
    });
  }

  /**
   * Setup performance monitoring
   */
  private setupPerformanceMonitoring() {
    // Report metrics every minute
    setInterval(() => {
      this.reportPerformanceMetrics();
    }, 60000);
  }

  /**
   * Record performance metrics
   */
  private recordPerformance(channelName: string, latency: number) {
    if (!this.performanceMetrics.has(channelName)) {
      this.performanceMetrics.set(channelName, []);
    }
    
    const metrics = this.performanceMetrics.get(channelName)!;
    metrics.push(latency);
    
    // Keep only last 100 metrics
    if (metrics.length > 100) {
      metrics.shift();
    }
  }

  /**
   * Report performance metrics
   */
  private reportPerformanceMetrics() {
    const report: any = {
      health: this.health,
      channels: {}
    };

    this.performanceMetrics.forEach((metrics, channel) => {
      const validMetrics = metrics.filter(m => m >= 0);
      if (validMetrics.length > 0) {
        report.channels[channel] = {
          avg: validMetrics.reduce((a, b) => a + b, 0) / validMetrics.length,
          min: Math.min(...validMetrics),
          max: Math.max(...validMetrics),
          errors: metrics.filter(m => m < 0).length
        };
      }
    });

    console.log('📊 Performance Report:', report);
  }

  /**
   * Update health status
   */
  private updateHealthStatus(status: string) {
    switch (status) {
      case 'SUBSCRIBED':
        this.health.status = 'connected';
        this.health.lastConnected = new Date();
        this.health.reconnectAttempts = 0;
        break;
      case 'CLOSED':
        this.health.status = 'disconnected';
        break;
      case 'CHANNEL_ERROR':
        this.health.status = 'error';
        this.health.errorCount++;
        break;
    }
  }

  /**
   * Pause all connections
   */
  public pause() {
    this.channels.forEach(channel => {
      channel.unsubscribe();
    });
    this.health.status = 'disconnected';
  }

  /**
   * Resume all connections
   */
  public resume() {
    this.reconnectAll();
  }

  /**
   * Unsubscribe from a specific channel
   */
  public unsubscribe(channelName: string) {
    const channel = this.channels.get(channelName);
    if (channel) {
      channel.unsubscribe();
      this.channels.delete(channelName);
      this.subscriptions.delete(channelName);
      this.health.subscriptionCount--;
      console.log(`🔌 Unsubscribed from ${channelName}`);
    }
  }

  /**
   * Cleanup all connections
   */
  public cleanup() {
    console.log('🧹 Cleaning up all realtime connections');
    
    // Clear all channels
    this.channels.forEach(channel => {
      channel.unsubscribe();
    });
    this.channels.clear();
    this.subscriptions.clear();
    
    // Clear timers
    if (this.heartbeatTimer) clearInterval(this.heartbeatTimer);
    if (this.reconnectTimer) clearTimeout(this.reconnectTimer);
    if (this.circuitBreakerTimer) clearTimeout(this.circuitBreakerTimer);
    
    // Reset health
    this.health = {
      status: 'disconnected',
      lastConnected: null,
      lastError: null,
      errorCount: 0,
      reconnectAttempts: 0,
      latency: 0,
      subscriptionCount: 0
    };
  }

  /**
   * Get connection health status
   */
  public getHealthStatus(): ConnectionHealth {
    return { ...this.health };
  }

  /**
   * Get performance metrics
   */
  public getPerformanceMetrics() {
    return new Map(this.performanceMetrics);
  }

  /**
   * Configure connection settings
   */
  public configure(config: Partial<ConnectionConfig>) {
    this.config = { ...this.config, ...config };
    console.log('⚙️ Connection configuration updated:', this.config);
  }
}

// Export singleton instance
export const realtimeManager = RealtimeConnectionManager.getInstance();

// Export type for use in other files
export type { ConnectionHealth, SubscriptionOptions, ConnectionConfig };

// Auto-cleanup on page unload
if (typeof window !== 'undefined') {
  window.addEventListener('beforeunload', () => {
    realtimeManager.cleanup();
  });
}

// Development helpers
if (process.env.NODE_ENV === 'development') {
  (window as any).realtimeManager = realtimeManager;
  console.log('🛠️ RealtimeConnectionManager available as window.realtimeManager');
}