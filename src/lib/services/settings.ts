/**
 * SETTINGS SERVICE
 * Handles all settings operations with caching, validation, and real-time sync
 * Last updated: 2025-08-07
 */

import { supabase } from '../supabase-client';
import type { Database } from '../database.types';

// Types
export interface Setting {
  id: string;
  key: string;
  value: any;
  category: string;
  description?: string;
  data_type: 'string' | 'number' | 'boolean' | 'json' | 'encrypted';
  is_public: boolean;
  is_sensitive: boolean;
  validation_schema?: any;
  created_at: string;
  updated_at: string;
  created_by?: string;
  updated_by?: string;
}

export interface SettingsAuditLog {
  id: string;
  setting_key: string;
  old_value?: any;
  new_value: any;
  action: 'insert' | 'update' | 'delete';
  changed_by?: string;
  changed_at: string;
  ip_address?: string;
  user_agent?: string;
}

export interface CachedSettings {
  data: Record<string, any>;
  timestamp: number;
  expires_at: number;
}

// Cache configuration
const CACHE_TTL = 5 * 60 * 1000; // 5 minutes in milliseconds
const CACHE_KEY_PREFIX = 'kct_settings_';

class SettingsCache {
  private cache = new Map<string, CachedSettings>();

  set(key: string, data: any, ttl: number = CACHE_TTL): void {
    const now = Date.now();
    this.cache.set(key, {
      data,
      timestamp: now,
      expires_at: now + ttl
    });
  }

  get(key: string): any | null {
    const cached = this.cache.get(key);
    if (!cached) return null;
    
    if (Date.now() > cached.expires_at) {
      this.cache.delete(key);
      return null;
    }
    
    return cached.data;
  }

  invalidate(pattern?: string): void {
    if (!pattern) {
      this.cache.clear();
      return;
    }
    
    for (const key of this.cache.keys()) {
      if (key.includes(pattern)) {
        this.cache.delete(key);
      }
    }
  }

  size(): number {
    return this.cache.size;
  }
}

// Global cache instance
const settingsCache = new SettingsCache();

// Encryption utilities (using Web Crypto API for sensitive settings)
class SettingsEncryption {
  private static async getKey(): Promise<CryptoKey> {
    // In production, this should be derived from a secure key
    const keyMaterial = await crypto.subtle.importKey(
      'raw',
      new TextEncoder().encode('your-encryption-key-here'),
      { name: 'PBKDF2' },
      false,
      ['deriveBits', 'deriveKey']
    );

    return crypto.subtle.deriveKey(
      {
        name: 'PBKDF2',
        salt: new TextEncoder().encode('settings-salt'),
        iterations: 100000,
        hash: 'SHA-256'
      },
      keyMaterial,
      { name: 'AES-GCM', length: 256 },
      true,
      ['encrypt', 'decrypt']
    );
  }

  static async encrypt(value: string): Promise<string> {
    try {
      const key = await this.getKey();
      const iv = crypto.getRandomValues(new Uint8Array(12));
      const encodedValue = new TextEncoder().encode(value);
      
      const encrypted = await crypto.subtle.encrypt(
        { name: 'AES-GCM', iv },
        key,
        encodedValue
      );

      // Combine IV and encrypted data
      const combined = new Uint8Array(iv.length + encrypted.byteLength);
      combined.set(iv);
      combined.set(new Uint8Array(encrypted), iv.length);
      
      return btoa(String.fromCharCode(...combined));
    } catch (error) {
      console.error('Encryption failed:', error);
      throw new Error('Failed to encrypt sensitive setting');
    }
  }

  static async decrypt(encryptedValue: string): Promise<string> {
    try {
      const key = await this.getKey();
      const combined = new Uint8Array(
        atob(encryptedValue).split('').map(char => char.charCodeAt(0))
      );
      
      const iv = combined.slice(0, 12);
      const encrypted = combined.slice(12);
      
      const decrypted = await crypto.subtle.decrypt(
        { name: 'AES-GCM', iv },
        key,
        encrypted
      );

      return new TextDecoder().decode(decrypted);
    } catch (error) {
      console.error('Decryption failed:', error);
      throw new Error('Failed to decrypt sensitive setting');
    }
  }
}

// Settings service class
export class SettingsService {
  private static instance: SettingsService;
  private static activeSubscriptions = new Map<string, any>();

  private constructor() {}

  /**
   * Get singleton instance
   */
  public static getInstance(): SettingsService {
    if (!SettingsService.instance) {
      SettingsService.instance = new SettingsService();
      console.log('⚙️ SettingsService: Singleton instance created');
    }
    return SettingsService.instance;
  }
  /**
   * Get settings by category or all settings
   */
  static async getSettings(category?: string): Promise<Setting[]> {
    try {
      const cacheKey = category ? `${CACHE_KEY_PREFIX}category_${category}` : `${CACHE_KEY_PREFIX}all`;
      const cached = settingsCache.get(cacheKey);
      
      if (cached) {
        return cached;
      }

      let query = supabase
        .from('settings')
        .select('*')
        .order('category', { ascending: true })
        .order('key', { ascending: true });

      if (category) {
        query = query.eq('category', category);
      }

      const { data, error } = await query;
      
      if (error) throw error;

      // Decrypt sensitive settings
      const processedData = await Promise.all(
        (data || []).map(async (setting) => {
          if (setting.is_sensitive && setting.data_type === 'encrypted') {
            try {
              const decryptedValue = await SettingsEncryption.decrypt(setting.value);
              return { ...setting, value: decryptedValue };
            } catch (error) {
              console.warn(`Failed to decrypt setting ${setting.key}`);
              return setting;
            }
          }
          return setting;
        })
      );

      settingsCache.set(cacheKey, processedData);
      return processedData;
    } catch (error) {
      console.error('Error fetching settings:', error);
      throw new Error('Failed to fetch settings');
    }
  }

  /**
   * Get a single setting by key
   */
  static async getSetting(key: string): Promise<Setting | null> {
    try {
      const cacheKey = `${CACHE_KEY_PREFIX}key_${key}`;
      const cached = settingsCache.get(cacheKey);
      
      if (cached) {
        return cached;
      }

      const { data, error } = await supabase
        .from('settings')
        .select('*')
        .eq('key', key)
        .single();
      
      if (error) {
        if (error.code === 'PGRST116') {
          return null; // Setting not found
        }
        throw error;
      }

      // Decrypt if sensitive
      if (data.is_sensitive && data.data_type === 'encrypted') {
        try {
          data.value = await SettingsEncryption.decrypt(data.value);
        } catch (error) {
          console.warn(`Failed to decrypt setting ${key}`);
        }
      }

      settingsCache.set(cacheKey, data);
      return data;
    } catch (error) {
      console.error(`Error fetching setting ${key}:`, error);
      throw new Error(`Failed to fetch setting: ${key}`);
    }
  }

  /**
   * Update or create a setting
   */
  static async updateSetting(
    key: string, 
    value: any, 
    options: {
      category?: string;
      description?: string;
      data_type?: Setting['data_type'];
      is_public?: boolean;
      is_sensitive?: boolean;
      validation_schema?: any;
    } = {}
  ): Promise<Setting> {
    try {
      // Validate the setting value
      const isValid = await this.validateSettingValue(key, value);
      if (!isValid) {
        throw new Error(`Invalid value for setting: ${key}`);
      }

      // Encrypt sensitive values
      let processedValue = value;
      if (options.is_sensitive && options.data_type === 'encrypted') {
        processedValue = await SettingsEncryption.encrypt(String(value));
      }

      // Get current user info for audit trail
      const { data: { user } } = await supabase.auth.getUser();
      
      // Use the database function for atomic update with audit logging
      const { error } = await supabase.rpc('update_setting_with_audit', {
        p_key: key,
        p_value: processedValue,
        p_user_id: user?.id || null
      });

      if (error) throw error;

      // Invalidate cache
      settingsCache.invalidate(key);
      settingsCache.invalidate('all');
      settingsCache.invalidate(`category_${options.category || 'general'}`);

      // Fetch and return the updated setting
      const updatedSetting = await this.getSetting(key);
      if (!updatedSetting) {
        throw new Error('Failed to retrieve updated setting');
      }

      return updatedSetting;
    } catch (error) {
      console.error(`Error updating setting ${key}:`, error);
      throw new Error(`Failed to update setting: ${key}`);
    }
  }

  /**
   * Get public settings only (for website consumption)
   */
  static async getPublicSettings(): Promise<Record<string, any>> {
    try {
      const cacheKey = `${CACHE_KEY_PREFIX}public`;
      const cached = settingsCache.get(cacheKey);
      
      if (cached) {
        return cached;
      }

      // Use the cached database function
      const { data, error } = await supabase.rpc('get_public_settings_cached');
      
      if (error) throw error;

      const publicSettings = data || {};
      settingsCache.set(cacheKey, publicSettings);
      return publicSettings;
    } catch (error) {
      console.error('Error fetching public settings:', error);
      throw new Error('Failed to fetch public settings');
    }
  }

  /**
   * Sync settings to website via broadcast channel
   */
  static async syncSettingsToWebsite(settingKeys?: string[]): Promise<void> {
    try {
      const publicSettings = await this.getPublicSettings();
      
      // Filter to specific keys if provided
      const settingsToSync = settingKeys 
        ? Object.fromEntries(
            Object.entries(publicSettings).filter(([key]) => settingKeys.includes(key))
          )
        : publicSettings;

      // Broadcast to realtime channel
      const channel = supabase.channel('settings-sync');
      
      await channel.send({
        type: 'broadcast',
        event: 'settings_updated',
        payload: {
          settings: settingsToSync,
          timestamp: new Date().toISOString(),
          keys: settingKeys || Object.keys(settingsToSync)
        }
      });

      console.log('Settings synced to website:', Object.keys(settingsToSync));
    } catch (error) {
      console.error('Error syncing settings to website:', error);
      throw new Error('Failed to sync settings to website');
    }
  }

  /**
   * Validate setting value based on data type and schema
   */
  static async validateSettingValue(key: string, value: any): Promise<boolean> {
    try {
      // Use database validation function
      const { data, error } = await supabase.rpc('validate_setting_value', {
        p_key: key,
        p_value: value
      });

      if (error) {
        console.error(`Validation error for ${key}:`, error);
        return false;
      }

      return data === true;
    } catch (error) {
      console.error(`Error validating setting ${key}:`, error);
      return false;
    }
  }

  /**
   * Get settings audit log
   */
  static async getAuditLog(
    settingKey?: string,
    limit: number = 100
  ): Promise<SettingsAuditLog[]> {
    try {
      let query = supabase
        .from('settings_audit_log')
        .select('*')
        .order('changed_at', { ascending: false })
        .limit(limit);

      if (settingKey) {
        query = query.eq('setting_key', settingKey);
      }

      const { data, error } = await query;
      
      if (error) throw error;

      return data || [];
    } catch (error) {
      console.error('Error fetching audit log:', error);
      throw new Error('Failed to fetch settings audit log');
    }
  }

  /**
   * Delete a setting (with audit trail)
   */
  static async deleteSetting(key: string): Promise<void> {
    try {
      // Get current setting for audit
      const currentSetting = await this.getSetting(key);
      
      if (!currentSetting) {
        throw new Error(`Setting ${key} not found`);
      }

      // Get current user
      const { data: { user } } = await supabase.auth.getUser();

      // Delete the setting
      const { error } = await supabase
        .from('settings')
        .delete()
        .eq('key', key);

      if (error) throw error;

      // Log the deletion
      await supabase
        .from('settings_audit_log')
        .insert({
          setting_key: key,
          old_value: currentSetting.value,
          new_value: null,
          action: 'delete',
          changed_by: user?.id || null
        });

      // Invalidate cache
      settingsCache.invalidate(key);
      settingsCache.invalidate('all');
      settingsCache.invalidate(`category_${currentSetting.category}`);

    } catch (error) {
      console.error(`Error deleting setting ${key}:`, error);
      throw new Error(`Failed to delete setting: ${key}`);
    }
  }

  /**
   * Bulk update settings
   */
  static async bulkUpdateSettings(
    settings: Array<{ key: string; value: any; options?: any }>
  ): Promise<Setting[]> {
    try {
      const results = await Promise.all(
        settings.map(({ key, value, options }) => 
          this.updateSetting(key, value, options)
        )
      );

      // Sync all updated settings to website
      await this.syncSettingsToWebsite(settings.map(s => s.key));

      return results;
    } catch (error) {
      console.error('Error bulk updating settings:', error);
      throw new Error('Failed to bulk update settings');
    }
  }

  /**
   * Subscribe to real-time setting changes
   */
  static subscribeToSettings(
    callback: (payload: any) => void,
    settingKeys?: string[],
    subscriptionId?: string
  ) {
    const subId = subscriptionId || `settings_${Date.now()}`;
    
    // Check if already subscribed
    if (this.activeSubscriptions.has(subId)) {
      console.log(`⚙️ SettingsService: Already subscribed with ID ${subId}`);
      return this.activeSubscriptions.get(subId);
    }

    console.log(`⚙️ SettingsService: Creating subscription with ID ${subId}`);
    
    const channel = supabase
      .channel('settings-changes')
      .on(
        'postgres_changes',
        { 
          event: '*', 
          schema: 'public', 
          table: 'settings',
          filter: settingKeys ? `key=in.(${settingKeys.join(',')})` : undefined
        },
        (payload) => {
          console.log('⚙️ SettingsService: Settings change detected:', payload);
          
          // Invalidate relevant cache entries
          if (payload.new?.key) {
            settingsCache.invalidate(payload.new.key);
          }
          if (payload.old?.key) {
            settingsCache.invalidate(payload.old.key);
          }
          settingsCache.invalidate('all');
          settingsCache.invalidate('public');

          callback(payload);
        }
      )
      .subscribe((status) => {
        console.log(`⚙️ SettingsService: Subscription ${subId} status:`, status);
      });

    // Store subscription for cleanup
    this.activeSubscriptions.set(subId, channel);
    return channel;
  }

  /**
   * Clear all settings cache
   */
  static clearCache(): void {
    settingsCache.invalidate();
  }

  /**
   * Unsubscribe from settings changes
   */
  static unsubscribeFromSettings(subscriptionId?: string): void {
    if (subscriptionId) {
      const subscription = this.activeSubscriptions.get(subscriptionId);
      if (subscription) {
        console.log(`⚙️ SettingsService: Unsubscribing from ${subscriptionId}`);
        if (typeof subscription.unsubscribe === 'function') {
          subscription.unsubscribe();
        }
        supabase.removeChannel(subscription);
        this.activeSubscriptions.delete(subscriptionId);
      }
    } else {
      // Unsubscribe from all
      console.log(`⚙️ SettingsService: Unsubscribing from all ${this.activeSubscriptions.size} subscriptions`);
      for (const [id, subscription] of this.activeSubscriptions) {
        if (typeof subscription.unsubscribe === 'function') {
          subscription.unsubscribe();
        }
        supabase.removeChannel(subscription);
      }
      this.activeSubscriptions.clear();
    }
  }

  /**
   * Cleanup all subscriptions and cache
   */
  static cleanup(): void {
    console.log('⚙️ SettingsService: Cleaning up subscriptions and cache');
    this.unsubscribeFromSettings();
    settingsCache.invalidate();
    console.log('⚙️ SettingsService: Cleanup completed');
  }

  /**
   * Reset singleton instance
   */
  static resetInstance(): void {
    if (SettingsService.instance) {
      SettingsService.cleanup();
      SettingsService.instance = null as any;
    }
  }

  /**
   * Get subscription status
   */
  static getSubscriptionStatus(): { activeSubscriptions: number; subscriptionIds: string[] } {
    return {
      activeSubscriptions: this.activeSubscriptions.size,
      subscriptionIds: Array.from(this.activeSubscriptions.keys())
    };
  }

  /**
   * Get cache statistics
   */
  static getCacheStats(): { size: number; keys: string[] } {
    return {
      size: settingsCache.size(),
      keys: Array.from(settingsCache['cache'].keys())
    };
  }
}

// Export singleton instance
export const settingsService = SettingsService.getInstance();

// Export for backward compatibility
export default settingsService;