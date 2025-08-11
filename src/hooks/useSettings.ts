/**
 * SETTINGS HOOKS
 * React Query hooks for settings management with caching and real-time updates
 * Last updated: 2025-08-07
 */

import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { useCallback, useEffect } from 'react';
import { settingsService, type Setting, type SettingsAuditLog } from '../lib/services/settings';
import { supabase } from '../lib/supabase-client';

// Query keys
export const SETTINGS_QUERY_KEYS = {
  all: ['settings'] as const,
  list: (category?: string) => [...SETTINGS_QUERY_KEYS.all, 'list', category] as const,
  detail: (key: string) => [...SETTINGS_QUERY_KEYS.all, 'detail', key] as const,
  public: () => [...SETTINGS_QUERY_KEYS.all, 'public'] as const,
  audit: (key?: string) => [...SETTINGS_QUERY_KEYS.all, 'audit', key] as const,
} as const;

// Cache configuration
const CACHE_TIME = 5 * 60 * 1000; // 5 minutes
const STALE_TIME = 2 * 60 * 1000; // 2 minutes

/**
 * Hook to get all settings or settings by category
 */
export function useSettings(category?: string) {
  return useQuery({
    queryKey: SETTINGS_QUERY_KEYS.list(category),
    queryFn: () => settingsService.getSettings(category),
    staleTime: STALE_TIME,
    gcTime: CACHE_TIME,
    retry: 2,
    retryDelay: (attemptIndex) => Math.min(1000 * 2 ** attemptIndex, 30000),
  });
}

/**
 * Hook to get a single setting by key
 */
export function useSetting(key: string) {
  return useQuery({
    queryKey: SETTINGS_QUERY_KEYS.detail(key),
    queryFn: () => settingsService.getSetting(key),
    staleTime: STALE_TIME,
    gcTime: CACHE_TIME,
    retry: 2,
    enabled: !!key,
  });
}

/**
 * Hook to get public settings (for website consumption)
 */
export function usePublicSettings() {
  return useQuery({
    queryKey: SETTINGS_QUERY_KEYS.public(),
    queryFn: () => settingsService.getPublicSettings(),
    staleTime: STALE_TIME,
    gcTime: CACHE_TIME,
    retry: 3,
    refetchOnWindowFocus: false,
  });
}

/**
 * Hook to get settings audit log
 */
export function useSettingsAuditLog(settingKey?: string, limit: number = 100) {
  return useQuery({
    queryKey: SETTINGS_QUERY_KEYS.audit(settingKey),
    queryFn: () => settingsService.getAuditLog(settingKey, limit),
    staleTime: 30 * 1000, // 30 seconds (audit logs should be relatively fresh)
    gcTime: 2 * 60 * 1000, // 2 minutes
    enabled: true, // Always enabled for admin users
  });
}

/**
 * Hook to update a setting with optimistic updates
 */
export function useUpdateSetting() {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: ({ key, value, options }: {
      key: string;
      value: any;
      options?: {
        category?: string;
        description?: string;
        data_type?: Setting['data_type'];
        is_public?: boolean;
        is_sensitive?: boolean;
        validation_schema?: any;
      };
    }) => settingsService.updateSetting(key, value, options),

    onMutate: async ({ key, value, options }) => {
      // Cancel any outgoing refetches
      await queryClient.cancelQueries({ queryKey: SETTINGS_QUERY_KEYS.detail(key) });
      await queryClient.cancelQueries({ queryKey: SETTINGS_QUERY_KEYS.list(options?.category) });
      await queryClient.cancelQueries({ queryKey: SETTINGS_QUERY_KEYS.all });

      // Snapshot the previous value
      const previousSetting = queryClient.getQueryData<Setting>(
        SETTINGS_QUERY_KEYS.detail(key)
      );
      const previousSettings = queryClient.getQueryData<Setting[]>(
        SETTINGS_QUERY_KEYS.list(options?.category)
      );

      // Optimistically update individual setting
      if (previousSetting) {
        const optimisticSetting: Setting = {
          ...previousSetting,
          value,
          updated_at: new Date().toISOString(),
          ...options,
        };
        queryClient.setQueryData(SETTINGS_QUERY_KEYS.detail(key), optimisticSetting);
      }

      // Optimistically update settings list
      if (previousSettings) {
        const updatedSettings = previousSettings.map(setting =>
          setting.key === key
            ? { ...setting, value, updated_at: new Date().toISOString(), ...options }
            : setting
        );
        queryClient.setQueryData(SETTINGS_QUERY_KEYS.list(options?.category), updatedSettings);
      }

      // If setting is public, invalidate public settings
      if (options?.is_public || previousSetting?.is_public) {
        queryClient.invalidateQueries({ queryKey: SETTINGS_QUERY_KEYS.public() });
      }

      return { previousSetting, previousSettings };
    },

    onError: (err, variables, context) => {
      // Rollback optimistic update on error
      if (context?.previousSetting) {
        queryClient.setQueryData(
          SETTINGS_QUERY_KEYS.detail(variables.key),
          context.previousSetting
        );
      }
      if (context?.previousSettings) {
        queryClient.setQueryData(
          SETTINGS_QUERY_KEYS.list(variables.options?.category),
          context.previousSettings
        );
      }
    },

    onSuccess: (updatedSetting, { key, options }) => {
      // Update the cache with the actual server response
      queryClient.setQueryData(SETTINGS_QUERY_KEYS.detail(key), updatedSetting);
      
      // Invalidate related queries to ensure consistency
      queryClient.invalidateQueries({ queryKey: SETTINGS_QUERY_KEYS.list(options?.category) });
      queryClient.invalidateQueries({ queryKey: SETTINGS_QUERY_KEYS.all });
      queryClient.invalidateQueries({ queryKey: SETTINGS_QUERY_KEYS.audit() });
      queryClient.invalidateQueries({ queryKey: SETTINGS_QUERY_KEYS.audit(key) });

      // If setting is public, invalidate and sync to website
      if (updatedSetting.is_public) {
        queryClient.invalidateQueries({ queryKey: SETTINGS_QUERY_KEYS.public() });
        settingsService.syncSettingsToWebsite([key]).catch(console.error);
      }
    },
  });
}

/**
 * Hook to bulk update settings
 */
export function useBulkUpdateSettings() {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: (settings: Array<{ key: string; value: any; options?: any }>) =>
      settingsService.bulkUpdateSettings(settings),

    onSuccess: (updatedSettings, variables) => {
      // Invalidate all settings queries
      queryClient.invalidateQueries({ queryKey: SETTINGS_QUERY_KEYS.all });
      
      // Update individual setting caches
      updatedSettings.forEach(setting => {
        queryClient.setQueryData(SETTINGS_QUERY_KEYS.detail(setting.key), setting);
      });

      // Check if any public settings were updated
      const hasPublicSettings = updatedSettings.some(setting => setting.is_public);
      if (hasPublicSettings) {
        queryClient.invalidateQueries({ queryKey: SETTINGS_QUERY_KEYS.public() });
      }
    },
  });
}

/**
 * Hook to delete a setting
 */
export function useDeleteSetting() {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: (key: string) => settingsService.deleteSetting(key),

    onSuccess: (_, deletedKey) => {
      // Remove from individual cache
      queryClient.removeQueries({ queryKey: SETTINGS_QUERY_KEYS.detail(deletedKey) });
      
      // Invalidate all related queries
      queryClient.invalidateQueries({ queryKey: SETTINGS_QUERY_KEYS.all });
      queryClient.invalidateQueries({ queryKey: SETTINGS_QUERY_KEYS.public() });
      queryClient.invalidateQueries({ queryKey: SETTINGS_QUERY_KEYS.audit() });
    },
  });
}

/**
 * Hook to subscribe to real-time setting changes
 */
export function useSettingsSubscription(settingKeys?: string[]) {
  const queryClient = useQueryClient();

  useEffect(() => {
    const channel = settingsService.subscribeToSettings(
      (payload) => {
        
        // Invalidate affected queries based on the change
        if (payload.new?.key) {
          queryClient.invalidateQueries({ 
            queryKey: SETTINGS_QUERY_KEYS.detail(payload.new.key) 
          });
          queryClient.invalidateQueries({ 
            queryKey: SETTINGS_QUERY_KEYS.list(payload.new.category) 
          });
        }
        
        if (payload.old?.key) {
          queryClient.invalidateQueries({ 
            queryKey: SETTINGS_QUERY_KEYS.detail(payload.old.key) 
          });
        }

        // Always invalidate the main lists and audit logs
        queryClient.invalidateQueries({ queryKey: SETTINGS_QUERY_KEYS.all });
        queryClient.invalidateQueries({ queryKey: SETTINGS_QUERY_KEYS.audit() });
        
        // Invalidate public settings if a public setting changed
        if (payload.new?.is_public || payload.old?.is_public) {
          queryClient.invalidateQueries({ queryKey: SETTINGS_QUERY_KEYS.public() });
        }
      },
      settingKeys
    );

    return () => {
      supabase.removeChannel(channel);
    };
  }, [queryClient, settingKeys]);
}

/**
 * Hook to get setting value with fallback
 */
export function useSettingValue<T = any>(
  key: string, 
  fallback: T,
  transform?: (value: any) => T
): T {
  const { data: setting } = useSetting(key);
  
  return useCallback(() => {
    if (!setting?.value) return fallback;
    
    if (transform) {
      try {
        return transform(setting.value);
      } catch {
        return fallback;
      }
    }
    
    return setting.value as T;
  }, [setting, fallback, transform])();
}

/**
 * Hook to prefetch settings (useful for performance)
 */
export function usePrefetchSettings() {
  const queryClient = useQueryClient();

  const prefetchSettings = useCallback((category?: string) => {
    queryClient.prefetchQuery({
      queryKey: SETTINGS_QUERY_KEYS.list(category),
      queryFn: () => settingsService.getSettings(category),
      staleTime: STALE_TIME,
    });
  }, [queryClient]);

  const prefetchSetting = useCallback((key: string) => {
    queryClient.prefetchQuery({
      queryKey: SETTINGS_QUERY_KEYS.detail(key),
      queryFn: () => settingsService.getSetting(key),
      staleTime: STALE_TIME,
    });
  }, [queryClient]);

  const prefetchPublicSettings = useCallback(() => {
    queryClient.prefetchQuery({
      queryKey: SETTINGS_QUERY_KEYS.public(),
      queryFn: () => settingsService.getPublicSettings(),
      staleTime: STALE_TIME,
    });
  }, [queryClient]);

  return {
    prefetchSettings,
    prefetchSetting,
    prefetchPublicSettings,
  };
}

/**
 * Hook to get cache statistics and management
 */
export function useSettingsCacheManagement() {
  const queryClient = useQueryClient();

  const clearSettingsCache = useCallback(() => {
    queryClient.invalidateQueries({ queryKey: SETTINGS_QUERY_KEYS.all });
    settingsService.clearCache();
  }, [queryClient]);

  const getCacheStats = useCallback(() => {
    const queryCache = queryClient.getQueryCache();
    const settingsQueries = queryCache.findAll({ queryKey: SETTINGS_QUERY_KEYS.all });
    
    return {
      ...settingsService.getCacheStats(),
      reactQueryCacheSize: settingsQueries.length,
      reactQueryQueries: settingsQueries.map(q => ({
        queryKey: q.queryKey,
        state: q.state.status,
        dataUpdatedAt: q.state.dataUpdatedAt,
        staleTime: q.options.staleTime,
        gcTime: q.options.gcTime,
      })),
    };
  }, [queryClient]);

  return {
    clearSettingsCache,
    getCacheStats,
  };
}

// Export types for convenience
export type { Setting, SettingsAuditLog } from '../lib/services/settings';