/**
 * SETTINGS SECURITY SERVICE
 * Handles encryption, role-based access, and audit logging for settings
 * Last updated: 2025-08-07
 */

import { supabase } from '../supabase-client';
import type { Setting } from './settings';

// Security levels
export enum SecurityLevel {
  PUBLIC = 'public',
  ADMIN = 'admin', 
  SUPER_ADMIN = 'super_admin',
  SYSTEM = 'system',
}

// Sensitive setting categories that require extra protection
const SENSITIVE_CATEGORIES = [
  'security',
  'payment',
  'api_keys',
  'smtp',
  'oauth',
  'encryption',
];

// Critical settings that require confirmation
const CRITICAL_SETTINGS = [
  'maintenance_mode',
  'site_name',
  'currency',
  'tax_rate',
  'smtp_password',
  'stripe_secret_key',
  'jwt_secret',
];

// Settings that require super admin access
const SUPER_ADMIN_SETTINGS = [
  'jwt_secret',
  'encryption_key',
  'database_url',
  'admin_api_key',
  'webhook_secret',
];

// Audit event types
export enum AuditEventType {
  VIEW = 'view',
  CREATE = 'create',
  UPDATE = 'update',
  DELETE = 'delete',
  DECRYPT = 'decrypt',
  EXPORT = 'export',
  BULK_UPDATE = 'bulk_update',
}

// Audit log entry
export interface AuditLogEntry {
  id: string;
  event_type: AuditEventType;
  setting_key?: string;
  user_id?: string;
  user_email?: string;
  ip_address?: string;
  user_agent?: string;
  old_value?: any;
  new_value?: any;
  metadata?: Record<string, any>;
  created_at: string;
  risk_level: 'low' | 'medium' | 'high' | 'critical';
}

// Permission result
export interface PermissionResult {
  allowed: boolean;
  reason?: string;
  required_role?: string;
  requires_confirmation?: boolean;
}

export class SettingsSecurityService {
  /**
   * Check if user has permission to access/modify a setting
   */
  static async checkPermission(
    settingKey: string,
    action: 'read' | 'write' | 'delete',
    setting?: Setting
  ): Promise<PermissionResult> {
    try {
      // Get current user and their role
      const { data: { user } } = await supabase.auth.getUser();
      if (!user) {
        return { allowed: false, reason: 'User not authenticated' };
      }

      // Get user profile with role
      const { data: profile, error } = await supabase
        .from('user_profiles')
        .select('role, permissions')
        .eq('user_id', user.id)
        .single();

      if (error || !profile) {
        return { allowed: false, reason: 'User profile not found' };
      }

      const userRole = profile.role as string;
      
      // Check if setting requires super admin access
      if (SUPER_ADMIN_SETTINGS.includes(settingKey) && userRole !== 'super_admin') {
        return { 
          allowed: false, 
          reason: 'Super admin access required',
          required_role: 'super_admin'
        };
      }

      // Check if setting is sensitive and requires admin access
      const isSensitive = setting?.is_sensitive || 
                         setting?.category && SENSITIVE_CATEGORIES.includes(setting.category);
      
      if (isSensitive && !['admin', 'super_admin'].includes(userRole)) {
        return { 
          allowed: false, 
          reason: 'Admin access required for sensitive settings',
          required_role: 'admin'
        };
      }

      // Check if action requires elevated permissions
      if (action === 'delete' && !['admin', 'super_admin'].includes(userRole)) {
        return { 
          allowed: false, 
          reason: 'Admin access required to delete settings',
          required_role: 'admin'
        };
      }

      // Check for critical settings that require confirmation
      const requiresConfirmation = CRITICAL_SETTINGS.includes(settingKey) && 
                                  action === 'write';

      return { 
        allowed: true, 
        requires_confirmation: requiresConfirmation 
      };

    } catch (error) {
      console.error('Permission check failed:', error);
      return { allowed: false, reason: 'Permission check failed' };
    }
  }

  /**
   * Log audit event
   */
  static async logAuditEvent(
    eventType: AuditEventType,
    settingKey?: string,
    oldValue?: any,
    newValue?: any,
    metadata?: Record<string, any>
  ): Promise<void> {
    try {
      const { data: { user } } = await supabase.auth.getUser();
      
      // Determine risk level
      let riskLevel: AuditLogEntry['risk_level'] = 'low';
      
      if (SUPER_ADMIN_SETTINGS.includes(settingKey || '')) {
        riskLevel = 'critical';
      } else if (CRITICAL_SETTINGS.includes(settingKey || '')) {
        riskLevel = 'high';
      } else if (settingKey && SENSITIVE_CATEGORIES.some(cat => settingKey.includes(cat))) {
        riskLevel = 'medium';
      }

      // Get client info (in a real app, you'd get this from the request)
      const clientInfo = this.getClientInfo();

      const auditEntry = {
        event_type: eventType,
        setting_key: settingKey,
        user_id: user?.id,
        user_email: user?.email,
        ip_address: clientInfo.ip,
        user_agent: clientInfo.userAgent,
        old_value: oldValue ? JSON.stringify(oldValue) : null,
        new_value: newValue ? JSON.stringify(newValue) : null,
        metadata: metadata ? JSON.stringify(metadata) : null,
        risk_level: riskLevel,
      };

      const { error } = await supabase
        .from('settings_audit_log')
        .insert(auditEntry);

      if (error) {
        console.error('Failed to log audit event:', error);
        // Don't throw here as audit logging shouldn't break the main operation
      }

      // For critical events, also log to external monitoring
      if (riskLevel === 'critical') {
        this.logCriticalEvent(auditEntry);
      }

    } catch (error) {
      console.error('Audit logging failed:', error);
    }
  }

  /**
   * Encrypt sensitive setting value
   */
  static async encryptValue(value: string): Promise<string> {
    try {
      // Use Web Crypto API for encryption
      const key = await this.getDerivedKey();
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
      throw new Error('Failed to encrypt sensitive value');
    }
  }

  /**
   * Decrypt sensitive setting value
   */
  static async decryptValue(encryptedValue: string): Promise<string> {
    try {
      const key = await this.getDerivedKey();
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

      // Log decryption event
      await this.logAuditEvent(AuditEventType.DECRYPT, undefined, undefined, undefined, {
        encrypted_length: encryptedValue.length,
        decrypted_at: new Date().toISOString(),
      });

      return new TextDecoder().decode(decrypted);
    } catch (error) {
      console.error('Decryption failed:', error);
      throw new Error('Failed to decrypt sensitive value');
    }
  }

  /**
   * Validate setting value against security rules
   */
  static validateSettingValue(key: string, value: any, setting?: Setting): {
    valid: boolean;
    errors: string[];
    warnings: string[];
  } {
    const errors: string[] = [];
    const warnings: string[] = [];

    try {
      // Check for potential security issues
      const stringValue = typeof value === 'string' ? value : JSON.stringify(value);

      // Check for common injection patterns
      const injectionPatterns = [
        /<script/i,
        /javascript:/i,
        /on\w+=/i,
        /eval\(/i,
        /function\(/i,
        /<iframe/i,
      ];

      for (const pattern of injectionPatterns) {
        if (pattern.test(stringValue)) {
          errors.push(`Potentially dangerous content detected: ${pattern.source}`);
        }
      }

      // Check for sensitive data in non-encrypted fields
      if (!setting?.is_sensitive && setting?.data_type !== 'encrypted') {
        const sensitivePatterns = [
          /password/i,
          /secret/i,
          /key/i,
          /token/i,
          /credential/i,
        ];

        for (const pattern of sensitivePatterns) {
          if (pattern.test(key) && stringValue.length > 10) {
            warnings.push(`Setting key suggests sensitive data but is not marked as sensitive: ${key}`);
            break;
          }
        }
      }

      // Validate specific setting types
      if (key === 'site_name' && (!stringValue || stringValue.trim().length === 0)) {
        errors.push('Site name cannot be empty');
      }

      if (key === 'currency' && !/^[A-Z]{3}$/.test(stringValue)) {
        errors.push('Currency must be a valid 3-letter ISO code');
      }

      if (key === 'tax_rate') {
        const rate = parseFloat(stringValue);
        if (isNaN(rate) || rate < 0 || rate > 1) {
          errors.push('Tax rate must be a number between 0 and 1');
        }
      }

      if (key.includes('email') && stringValue && !/\S+@\S+\.\S+/.test(stringValue)) {
        errors.push('Invalid email format');
      }

      if (key.includes('url') && stringValue && !/^https?:\/\/.+/.test(stringValue)) {
        warnings.push('URL should start with http:// or https://');
      }

      return {
        valid: errors.length === 0,
        errors,
        warnings,
      };

    } catch (error) {
      return {
        valid: false,
        errors: ['Validation failed: ' + error.message],
        warnings: [],
      };
    }
  }

  /**
   * Get security recommendations for a setting
   */
  static getSecurityRecommendations(key: string, setting?: Setting): string[] {
    const recommendations: string[] = [];

    // Check if setting should be marked as sensitive
    const sensitiveKeywords = ['password', 'secret', 'key', 'token', 'credential'];
    if (sensitiveKeywords.some(keyword => key.toLowerCase().includes(keyword))) {
      if (!setting?.is_sensitive) {
        recommendations.push('Consider marking this setting as sensitive');
      }
      if (setting?.data_type !== 'encrypted') {
        recommendations.push('Consider encrypting this setting');
      }
    }

    // Check if setting should not be public
    if (setting?.is_public && setting?.is_sensitive) {
      recommendations.push('Sensitive settings should not be public');
    }

    // Check for proper categorization
    if (!setting?.category || setting.category === 'general') {
      if (SENSITIVE_CATEGORIES.some(cat => key.toLowerCase().includes(cat))) {
        recommendations.push('Consider using a more specific category for better organization');
      }
    }

    // Check for description
    if (!setting?.description) {
      recommendations.push('Add a description to help other administrators understand this setting');
    }

    return recommendations;
  }

  /**
   * Export settings with security filtering
   */
  static async exportSettings(
    includeEncrypted: boolean = false,
    categories?: string[]
  ): Promise<{
    settings: Setting[];
    metadata: {
      exported_at: string;
      exported_by: string;
      total_count: number;
      filtered_count: number;
      security_level: SecurityLevel;
    };
  }> {
    try {
      // Check permissions
      const { data: { user } } = await supabase.auth.getUser();
      if (!user) {
        throw new Error('Authentication required');
      }

      // Get user role
      const { data: profile } = await supabase
        .from('user_profiles')
        .select('role')
        .eq('user_id', user.id)
        .single();

      const userRole = profile?.role || '';
      const securityLevel = userRole === 'super_admin' ? SecurityLevel.SUPER_ADMIN : SecurityLevel.ADMIN;

      // Get all settings
      const { data: allSettings, error } = await supabase
        .from('settings')
        .select('*')
        .order('category', { ascending: true })
        .order('key', { ascending: true });

      if (error) throw error;

      let filteredSettings = allSettings || [];

      // Filter by categories if specified
      if (categories && categories.length > 0) {
        filteredSettings = filteredSettings.filter(setting => 
          categories.includes(setting.category)
        );
      }

      // Apply security filtering
      filteredSettings = filteredSettings.filter(setting => {
        // Filter super admin settings
        if (SUPER_ADMIN_SETTINGS.includes(setting.key) && securityLevel !== SecurityLevel.SUPER_ADMIN) {
          return false;
        }

        // Filter encrypted settings if not requested
        if (!includeEncrypted && setting.is_sensitive && setting.data_type === 'encrypted') {
          return false;
        }

        return true;
      });

      // Remove sensitive values from export (replace with placeholder)
      const exportSettings = filteredSettings.map(setting => {
        if (setting.is_sensitive && !includeEncrypted) {
          return {
            ...setting,
            value: '[SENSITIVE_DATA_HIDDEN]',
          };
        }
        return setting;
      });

      // Log export event
      await this.logAuditEvent(AuditEventType.EXPORT, undefined, undefined, undefined, {
        exported_count: exportSettings.length,
        include_encrypted: includeEncrypted,
        categories: categories || 'all',
        security_level: securityLevel,
      });

      return {
        settings: exportSettings,
        metadata: {
          exported_at: new Date().toISOString(),
          exported_by: user.email || user.id,
          total_count: allSettings?.length || 0,
          filtered_count: exportSettings.length,
          security_level: securityLevel,
        },
      };

    } catch (error) {
      console.error('Settings export failed:', error);
      throw new Error('Failed to export settings');
    }
  }

  /**
   * Get derived encryption key
   */
  private static async getDerivedKey(): Promise<CryptoKey> {
    // In production, this should use a proper key derivation function
    // with a secret key stored securely (not in code)
    const keyMaterial = await crypto.subtle.importKey(
      'raw',
      new TextEncoder().encode(import.meta.env.VITE_ENCRYPTION_KEY || 'default-key-change-me'),
      { name: 'PBKDF2' },
      false,
      ['deriveBits', 'deriveKey']
    );

    return crypto.subtle.deriveKey(
      {
        name: 'PBKDF2',
        salt: new TextEncoder().encode('kct-settings-salt'),
        iterations: 100000,
        hash: 'SHA-256'
      },
      keyMaterial,
      { name: 'AES-GCM', length: 256 },
      true,
      ['encrypt', 'decrypt']
    );
  }

  /**
   * Get client information (mock implementation)
   */
  private static getClientInfo(): { ip: string; userAgent: string } {
    // In a real implementation, this would come from the request context
    return {
      ip: '127.0.0.1', // Would be actual client IP
      userAgent: navigator.userAgent || 'Unknown',
    };
  }

  /**
   * Log critical events to external monitoring
   */
  private static logCriticalEvent(auditEntry: any): void {
    // In production, this would send to external monitoring service
    console.warn('CRITICAL SECURITY EVENT:', {
      timestamp: new Date().toISOString(),
      event: auditEntry.event_type,
      setting: auditEntry.setting_key,
      user: auditEntry.user_email,
      risk_level: auditEntry.risk_level,
    });

    // Example: Send to monitoring service
    // monitoringService.logCriticalEvent(auditEntry);
  }

  /**
   * Get security status overview
   */
  static async getSecurityStatus(): Promise<{
    total_settings: number;
    sensitive_settings: number;
    encrypted_settings: number;
    public_settings: number;
    critical_settings: number;
    recommendations_count: number;
    recent_audit_events: number;
  }> {
    try {
      const { data: allSettings, error } = await supabase
        .from('settings')
        .select('*');

      if (error) throw error;

      const settings = allSettings || [];
      
      const sensitiveCount = settings.filter(s => s.is_sensitive).length;
      const encryptedCount = settings.filter(s => s.data_type === 'encrypted').length;
      const publicCount = settings.filter(s => s.is_public).length;
      const criticalCount = settings.filter(s => CRITICAL_SETTINGS.includes(s.key)).length;

      // Count recommendations
      let recommendationsCount = 0;
      settings.forEach(setting => {
        recommendationsCount += this.getSecurityRecommendations(setting.key, setting).length;
      });

      // Get recent audit events (last 24 hours)
      const oneDayAgo = new Date(Date.now() - 24 * 60 * 60 * 1000).toISOString();
      const { count: recentAuditCount } = await supabase
        .from('settings_audit_log')
        .select('*', { count: 'exact', head: true })
        .gte('changed_at', oneDayAgo);

      return {
        total_settings: settings.length,
        sensitive_settings: sensitiveCount,
        encrypted_settings: encryptedCount,
        public_settings: publicCount,
        critical_settings: criticalCount,
        recommendations_count: recommendationsCount,
        recent_audit_events: recentAuditCount || 0,
      };

    } catch (error) {
      console.error('Failed to get security status:', error);
      throw error;
    }
  }
}

// Export for convenience
export const settingsSecurityService = SettingsSecurityService;