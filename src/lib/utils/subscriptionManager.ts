/**
 * Subscription Manager - Central cleanup utility for all WebSocket subscriptions
 * This utility helps prevent memory leaks and infinite loops from uncleaned subscriptions
 */

import { chatNotificationService } from '@/lib/services/chatNotificationService';
import { chatOrderIntegration } from '@/lib/services/chatOrderIntegration';
import { incidentResponseSystem } from '@/lib/services/incidentResponseSystem';
import { settingsSyncService } from '@/lib/services/settingsSync';
import { settingsService } from '@/lib/services/settings';

interface SubscriptionStatus {
  service: string;
  status: any;
  hasCleanup: boolean;
}

export class SubscriptionManager {
  private static instance: SubscriptionManager;
  
  private constructor() {}

  public static getInstance(): SubscriptionManager {
    if (!SubscriptionManager.instance) {
      SubscriptionManager.instance = new SubscriptionManager();
    }
    return SubscriptionManager.instance;
  }

  /**
   * Get status of all subscription services
   */
  public getAllSubscriptionStatus(): SubscriptionStatus[] {
    const statuses: SubscriptionStatus[] = [];

    try {
      // ChatNotificationService
      const chatNotificationStatus = chatNotificationService.getSubscriptionStatus();
      statuses.push({
        service: 'ChatNotificationService',
        status: chatNotificationStatus,
        hasCleanup: true
      });
    } catch (error) {
      statuses.push({
        service: 'ChatNotificationService',
        status: { error: error.message },
        hasCleanup: true
      });
    }

    try {
      // ChatOrderIntegrationService
      const chatOrderStatus = chatOrderIntegration.getSubscriptionStatus();
      statuses.push({
        service: 'ChatOrderIntegrationService',
        status: chatOrderStatus,
        hasCleanup: true
      });
    } catch (error) {
      statuses.push({
        service: 'ChatOrderIntegrationService',
        status: { error: error.message },
        hasCleanup: true
      });
    }

    try {
      // IncidentResponseSystem
      const incidentStatus = incidentResponseSystem.getMonitoringStatus();
      statuses.push({
        service: 'IncidentResponseSystem',
        status: incidentStatus,
        hasCleanup: true
      });
    } catch (error) {
      statuses.push({
        service: 'IncidentResponseSystem',
        status: { error: error.message },
        hasCleanup: true
      });
    }

    try {
      // SettingsSyncService
      const settingsSyncStatus = settingsSyncService.getSyncStatus();
      statuses.push({
        service: 'SettingsSyncService',
        status: settingsSyncStatus,
        hasCleanup: true
      });
    } catch (error) {
      statuses.push({
        service: 'SettingsSyncService',
        status: { error: error.message },
        hasCleanup: true
      });
    }

    try {
      // SettingsService
      const settingsStatus = settingsService.getSubscriptionStatus();
      statuses.push({
        service: 'SettingsService',
        status: settingsStatus,
        hasCleanup: true
      });
    } catch (error) {
      statuses.push({
        service: 'SettingsService',
        status: { error: error.message },
        hasCleanup: true
      });
    }

    return statuses;
  }

  /**
   * Cleanup all subscriptions across all services
   */
  public cleanupAllSubscriptions(): void {
    console.log('🧹 SubscriptionManager: Starting global cleanup of all subscriptions');

    const cleanupOperations = [
      {
        name: 'ChatNotificationService',
        cleanup: () => chatNotificationService.cleanup()
      },
      {
        name: 'ChatOrderIntegrationService', 
        cleanup: () => chatOrderIntegration.cleanup()
      },
      {
        name: 'IncidentResponseSystem',
        cleanup: () => incidentResponseSystem.cleanup()
      },
      {
        name: 'SettingsSyncService',
        cleanup: () => settingsSyncService.cleanup()
      },
      {
        name: 'SettingsService',
        cleanup: () => settingsService.cleanup()
      }
    ];

    cleanupOperations.forEach(({ name, cleanup }) => {
      try {
        cleanup();
        console.log(`✅ ${name}: Cleanup completed`);
      } catch (error) {
        console.error(`❌ ${name}: Cleanup failed:`, error);
      }
    });

    console.log('🧹 SubscriptionManager: Global cleanup completed');
  }

  /**
   * Reset all singleton instances (useful for testing)
   */
  public resetAllSingletons(): void {
    console.log('🔄 SubscriptionManager: Resetting all singleton instances');

    try {
      (chatNotificationService.constructor as any).resetInstance?.();
      console.log('✅ ChatNotificationService: Singleton reset');
    } catch (error) {
      console.error('❌ ChatNotificationService: Reset failed:', error);
    }

    try {
      (chatOrderIntegration.constructor as any).resetInstance?.();
      console.log('✅ ChatOrderIntegrationService: Singleton reset');
    } catch (error) {
      console.error('❌ ChatOrderIntegrationService: Reset failed:', error);
    }

    try {
      (incidentResponseSystem.constructor as any).resetInstance?.();
      console.log('✅ IncidentResponseSystem: Singleton reset');
    } catch (error) {
      console.error('❌ IncidentResponseSystem: Reset failed:', error);
    }

    try {
      (settingsSyncService.constructor as any).resetInstance?.();
      console.log('✅ SettingsSyncService: Singleton reset');
    } catch (error) {
      console.error('❌ SettingsSyncService: Reset failed:', error);
    }

    try {
      (settingsService.constructor as any).resetInstance?.();
      console.log('✅ SettingsService: Singleton reset');
    } catch (error) {
      console.error('❌ SettingsService: Reset failed:', error);
    }

    console.log('🔄 SubscriptionManager: All singletons reset completed');
  }

  /**
   * Monitor subscription health and log warnings
   */
  public monitorSubscriptionHealth(): void {
    const statuses = this.getAllSubscriptionStatus();
    
    console.log('📊 Subscription Health Report:');
    console.table(statuses);

    // Check for potential issues
    statuses.forEach(({ service, status }) => {
      if (status.error) {
        console.warn(`⚠️ ${service}: Has errors - ${status.error}`);
      }
      
      if (status.activeChannels && status.activeChannels.length > 5) {
        console.warn(`⚠️ ${service}: High number of active channels (${status.activeChannels.length})`);
      }
      
      if (status.subscriptionCount && status.subscriptionCount > 3) {
        console.warn(`⚠️ ${service}: High number of subscriptions (${status.subscriptionCount})`);
      }
    });
  }

  /**
   * Setup automatic cleanup on page unload
   */
  public setupAutomaticCleanup(): void {
    if (typeof window !== 'undefined') {
      // Cleanup on page unload
      window.addEventListener('beforeunload', () => {
        this.cleanupAllSubscriptions();
      });

      // Cleanup on visibility change (when tab becomes hidden)
      document.addEventListener('visibilitychange', () => {
        if (document.visibilityState === 'hidden') {
          console.log('🌙 Page hidden, running subscription cleanup');
          this.cleanupAllSubscriptions();
        }
      });

      console.log('🔧 Automatic cleanup handlers registered');
    }
  }
}

// Export singleton instance
export const subscriptionManager = SubscriptionManager.getInstance();

// Auto-setup cleanup handlers
if (typeof window !== 'undefined') {
  subscriptionManager.setupAutomaticCleanup();
}

// Development helpers (only in development)
if (process.env.NODE_ENV === 'development') {
  // Add to window for debugging
  (window as any).subscriptionManager = subscriptionManager;
  
  // Log subscription status periodically in development
  setInterval(() => {
    const statuses = subscriptionManager.getAllSubscriptionStatus();
    const totalActiveSubscriptions = statuses.reduce((sum, status) => {
      return sum + (status.status.subscriptionCount || status.status.activeChannels?.length || 0);
    }, 0);
    
    if (totalActiveSubscriptions > 0) {
      console.log(`🔍 Development: ${totalActiveSubscriptions} active subscriptions`);
    }
  }, 30000); // Check every 30 seconds
}