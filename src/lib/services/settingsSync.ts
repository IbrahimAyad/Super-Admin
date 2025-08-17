/**
 * SETTINGS SYNC SERVICE
 * Handles real-time synchronization of settings to website and external clients
 * Last updated: 2025-08-07
 */

import { supabase } from '../supabase-client';
import { settingsService } from './settings';

// Sync event types
export enum SyncEventType {
  SETTINGS_UPDATED = 'settings_updated',
  SETTINGS_DELETED = 'settings_deleted',
  CACHE_INVALIDATED = 'cache_invalidated',
  MAINTENANCE_MODE_CHANGED = 'maintenance_mode_changed',
}

// Sync payload interface
export interface SyncPayload {
  type: SyncEventType;
  timestamp: string;
  settings?: Record<string, any>;
  keys?: string[];
  metadata?: {
    changed_by?: string;
    source: 'admin' | 'api' | 'system';
    batch_id?: string;
    critical?: boolean;
  };
}

// Real-time channels
const CHANNELS = {
  PUBLIC_SETTINGS: 'public_settings_sync',
  ADMIN_SETTINGS: 'admin_settings_sync',
  MAINTENANCE: 'maintenance_sync',
  WEBSITE_SYNC: 'website_settings_sync',
} as const;

// Broadcast configuration
interface BroadcastConfig {
  channel: string;
  reliable: boolean; // Whether to ensure delivery
  timeout: number; // Timeout in milliseconds
  retries: number; // Number of retry attempts
}

// Default configurations
const BROADCAST_CONFIGS: Record<string, BroadcastConfig> = {
  public: {
    channel: CHANNELS.PUBLIC_SETTINGS,
    reliable: true,
    timeout: 5000,
    retries: 3,
  },
  admin: {
    channel: CHANNELS.ADMIN_SETTINGS,
    reliable: false,
    timeout: 2000,
    retries: 1,
  },
  maintenance: {
    channel: CHANNELS.MAINTENANCE,
    reliable: true,
    timeout: 10000,
    retries: 5,
  },
  website: {
    channel: CHANNELS.WEBSITE_SYNC,
    reliable: true,
    timeout: 8000,
    retries: 3,
  },
};

export class SettingsSyncService {
  private static instance: SettingsSyncService;
  private static activeChannels = new Map<string, any>();
  private static syncQueue: Array<{ payload: SyncPayload; config: BroadcastConfig; attempt: number }> = [];
  private static isProcessingQueue = false;
  private static isInitialized = false;

  private constructor() {}

  /**
   * Get singleton instance
   */
  public static getInstance(): SettingsSyncService {
    if (!SettingsSyncService.instance) {
      SettingsSyncService.instance = new SettingsSyncService();
      SettingsSyncService.isInitialized = true;
      console.log('⚙️ SettingsSyncService: Singleton instance created');
    }
    return SettingsSyncService.instance;
  }

  /**
   * Broadcast settings update to specified audience
   */
  static async broadcastSettingsUpdate(
    settingKeys: string[],
    audience: 'public' | 'admin' | 'maintenance' | 'website' = 'public',
    metadata?: SyncPayload['metadata']
  ): Promise<void> {
    try {
      const config = BROADCAST_CONFIGS[audience];
      const settings = await this.getSettingsForAudience(settingKeys, audience);
      
      const payload: SyncPayload = {
        type: SyncEventType.SETTINGS_UPDATED,
        timestamp: new Date().toISOString(),
        settings,
        keys: settingKeys,
        metadata: {
          source: 'admin',
          critical: this.isCriticalUpdate(settingKeys),
          ...metadata,
        },
      };

      if (config.reliable) {
        await this.reliableBroadcast(payload, config);
      } else {
        await this.simpleBroadcast(payload, config.channel);
      }

      console.log(`Settings broadcasted to ${audience}:`, settingKeys);
    } catch (error) {
      console.error(`Failed to broadcast settings to ${audience}:`, error);
      throw error;
    }
  }

  /**
   * Broadcast settings deletion
   */
  static async broadcastSettingsDeletion(
    settingKeys: string[],
    audience: 'public' | 'admin' | 'website' = 'public',
    metadata?: SyncPayload['metadata']
  ): Promise<void> {
    try {
      const config = BROADCAST_CONFIGS[audience];
      
      const payload: SyncPayload = {
        type: SyncEventType.SETTINGS_DELETED,
        timestamp: new Date().toISOString(),
        keys: settingKeys,
        metadata: {
          source: 'admin',
          critical: true,
          ...metadata,
        },
      };

      if (config.reliable) {
        await this.reliableBroadcast(payload, config);
      } else {
        await this.simpleBroadcast(payload, config.channel);
      }

      console.log(`Settings deletion broadcasted to ${audience}:`, settingKeys);
    } catch (error) {
      console.error(`Failed to broadcast deletion to ${audience}:`, error);
      throw error;
    }
  }

  /**
   * Broadcast cache invalidation
   */
  static async broadcastCacheInvalidation(
    cacheKeys?: string[],
    audience: 'public' | 'admin' | 'website' = 'public'
  ): Promise<void> {
    try {
      const config = BROADCAST_CONFIGS[audience];
      
      const payload: SyncPayload = {
        type: SyncEventType.CACHE_INVALIDATED,
        timestamp: new Date().toISOString(),
        keys: cacheKeys,
        metadata: {
          source: 'admin',
          critical: false,
        },
      };

      await this.simpleBroadcast(payload, config.channel);
      console.log(`Cache invalidation broadcasted to ${audience}`);
    } catch (error) {
      console.error(`Failed to broadcast cache invalidation to ${audience}:`, error);
    }
  }

  /**
   * Broadcast maintenance mode changes (high priority)
   */
  static async broadcastMaintenanceMode(
    enabled: boolean,
    message?: string,
    scheduledDowntime?: { start: string; end: string }
  ): Promise<void> {
    try {
      const config = BROADCAST_CONFIGS.maintenance;
      
      const payload: SyncPayload = {
        type: SyncEventType.MAINTENANCE_MODE_CHANGED,
        timestamp: new Date().toISOString(),
        settings: {
          maintenance_mode: enabled,
          maintenance_message: message,
          scheduled_downtime: scheduledDowntime,
        },
        keys: ['maintenance_mode'],
        metadata: {
          source: 'admin',
          critical: true,
        },
      };

      // Always use reliable broadcast for maintenance mode
      await this.reliableBroadcast(payload, config);
      
      // Also notify all other channels
      await Promise.all([
        this.simpleBroadcast(payload, CHANNELS.PUBLIC_SETTINGS),
        this.simpleBroadcast(payload, CHANNELS.WEBSITE_SYNC),
        this.simpleBroadcast(payload, CHANNELS.ADMIN_SETTINGS),
      ]);

      console.log(`Maintenance mode broadcasted: ${enabled}`);
    } catch (error) {
      console.error('Failed to broadcast maintenance mode:', error);
      throw error;
    }
  }

  /**
   * Subscribe to settings changes from a specific channel
   */
  static subscribeToChannel(
    channelName: string,
    callback: (payload: SyncPayload) => void,
    errorCallback?: (error: any) => void
  ): any {
    try {
      // Check if already subscribed to prevent duplicates
      if (this.activeChannels.has(channelName)) {
        console.log(`⚙️ SettingsSyncService: Already subscribed to channel ${channelName}`);
        return this.activeChannels.get(channelName);
      }

      console.log(`⚙️ SettingsSyncService: Subscribing to channel ${channelName}`);
      const channel = supabase.channel(channelName);
      
      channel
        .on('broadcast', { event: '*' }, ({ payload }) => {
          console.log(`⚙️ SettingsSyncService: Received sync event on ${channelName}:`, payload);
          callback(payload as SyncPayload);
        })
        .subscribe((status) => {
          console.log(`⚙️ SettingsSyncService: Channel ${channelName} subscription status:`, status);
        });

      // Store active channel for cleanup
      this.activeChannels.set(channelName, channel);
      return channel;
    } catch (error) {
      console.error(`⚙️ SettingsSyncService: Failed to subscribe to channel ${channelName}:`, error);
      errorCallback?.(error);
      return null;
    }
  }

  /**
   * Unsubscribe from a channel
   */
  static unsubscribeFromChannel(channelName: string): void {
    const channel = this.activeChannels.get(channelName);
    if (channel) {
      console.log(`⚙️ SettingsSyncService: Unsubscribing from channel: ${channelName}`);
      if (typeof channel.unsubscribe === 'function') {
        channel.unsubscribe();
      }
      supabase.removeChannel(channel);
      this.activeChannels.delete(channelName);
      console.log(`⚙️ SettingsSyncService: Successfully unsubscribed from channel: ${channelName}`);
    }
  }

  /**
   * Subscribe to public settings changes (for website)
   */
  static subscribeToPublicSettings(
    callback: (settings: Record<string, any>) => void,
    errorCallback?: (error: any) => void
  ): any {
    return this.subscribeToChannel(
      CHANNELS.PUBLIC_SETTINGS,
      (payload) => {
        if (payload.settings && payload.type === SyncEventType.SETTINGS_UPDATED) {
          callback(payload.settings);
        }
      },
      errorCallback
    );
  }

  /**
   * Subscribe to maintenance mode changes
   */
  static subscribeToMaintenanceMode(
    callback: (enabled: boolean, message?: string, scheduledDowntime?: any) => void,
    errorCallback?: (error: any) => void
  ): any {
    return this.subscribeToChannel(
      CHANNELS.MAINTENANCE,
      (payload) => {
        if (payload.type === SyncEventType.MAINTENANCE_MODE_CHANGED && payload.settings) {
          callback(
            payload.settings.maintenance_mode,
            payload.settings.maintenance_message,
            payload.settings.scheduled_downtime
          );
        }
      },
      errorCallback
    );
  }

  /**
   * Get settings appropriate for the target audience
   */
  private static async getSettingsForAudience(
    settingKeys: string[],
    audience: 'public' | 'admin' | 'maintenance' | 'website'
  ): Promise<Record<string, any>> {
    switch (audience) {
      case 'public':
      case 'website':
        // Only return public settings
        return await settingsService.getPublicSettings();
      
      case 'admin':
        // Return all requested settings for admin
        const allSettings = await settingsService.getSettings();
        return Object.fromEntries(
          allSettings
            .filter(setting => settingKeys.includes(setting.key))
            .map(setting => [setting.key, setting.value])
        );
      
      case 'maintenance':
        // Return maintenance-related settings
        const maintenanceSettings = await settingsService.getSettings('system');
        return Object.fromEntries(
          maintenanceSettings
            .filter(setting => settingKeys.includes(setting.key))
            .map(setting => [setting.key, setting.value])
        );
      
      default:
        return {};
    }
  }

  /**
   * Simple broadcast (fire and forget)
   */
  private static async simpleBroadcast(payload: SyncPayload, channelName: string): Promise<void> {
    const channel = supabase.channel(channelName);
    
    await channel.send({
      type: 'broadcast',
      event: payload.type,
      payload,
    });
  }

  /**
   * Reliable broadcast with retries and queue
   */
  private static async reliableBroadcast(
    payload: SyncPayload,
    config: BroadcastConfig
  ): Promise<void> {
    const queueItem = { payload, config, attempt: 0 };
    this.syncQueue.push(queueItem);
    
    if (!this.isProcessingQueue) {
      await this.processQueue();
    }
  }

  /**
   * Process the sync queue with retries
   */
  private static async processQueue(): Promise<void> {
    this.isProcessingQueue = true;

    while (this.syncQueue.length > 0) {
      const item = this.syncQueue.shift();
      if (!item) continue;

      try {
        await Promise.race([
          this.simpleBroadcast(item.payload, item.config.channel),
          new Promise((_, reject) => 
            setTimeout(() => reject(new Error('Broadcast timeout')), item.config.timeout)
          ),
        ]);
        
        console.log(`Reliable broadcast successful: ${item.payload.type}`);
      } catch (error) {
        console.warn(`Broadcast attempt ${item.attempt + 1} failed:`, error);
        
        if (item.attempt < item.config.retries) {
          item.attempt++;
          this.syncQueue.unshift(item); // Retry
          await new Promise(resolve => setTimeout(resolve, 1000 * item.attempt)); // Exponential backoff
        } else {
          console.error(`Failed to broadcast after ${item.config.retries} attempts:`, item.payload);
        }
      }
    }

    this.isProcessingQueue = false;
  }

  /**
   * Check if a settings update is critical
   */
  private static isCriticalUpdate(settingKeys: string[]): boolean {
    const criticalSettings = [
      'maintenance_mode',
      'site_name',
      'currency',
      'tax_rate',
      'free_shipping_threshold',
    ];
    
    return settingKeys.some(key => criticalSettings.includes(key));
  }

  /**
   * Get sync status and statistics
   */
  static getSyncStatus(): {
    activeChannels: string[];
    queueSize: number;
    isProcessing: boolean;
  } {
    return {
      activeChannels: Array.from(this.activeChannels.keys()),
      queueSize: this.syncQueue.length,
      isProcessing: this.isProcessingQueue,
    };
  }

  /**
   * Cleanup all channels and queues
   */
  static cleanup(): void {
    console.log('⚙️ SettingsSyncService: Cleaning up subscriptions and resources');
    
    // Unsubscribe from all channels
    const channelNames = Array.from(this.activeChannels.keys());
    console.log(`⚙️ SettingsSyncService: Unsubscribing from ${channelNames.length} channels`);
    
    for (const channelName of channelNames) {
      this.unsubscribeFromChannel(channelName);
    }
    
    // Clear queue
    this.syncQueue.length = 0;
    this.isProcessingQueue = false;
    
    console.log('⚙️ SettingsSyncService: Cleanup completed');
  }

  /**
   * Reset the singleton instance (for testing purposes)
   */
  static resetInstance(): void {
    if (SettingsSyncService.isInitialized) {
      SettingsSyncService.cleanup();
      SettingsSyncService.instance = null as any;
      SettingsSyncService.isInitialized = false;
    }
  }
}

// Export singleton instance for convenience
export const settingsSyncService = SettingsSyncService.getInstance();