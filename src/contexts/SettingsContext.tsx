/**
 * SETTINGS CONTEXT
 * Provides settings state management across admin components
 * Last updated: 2025-08-07
 */

import React, { createContext, useContext, useEffect, useState, ReactNode } from 'react';
import { QueryClient, QueryClientProvider } from '@tanstack/react-query';
import { ReactQueryDevtools } from '@tanstack/react-query-devtools';
import { 
  useSettings, 
  usePublicSettings, 
  useSettingsSubscription,
  useSettingValue,
  type Setting 
} from '../hooks/useSettings';
import { settingsService } from '../lib/services/settings';
import { useToast } from '../hooks/use-toast';

// Settings context interface
interface SettingsContextType {
  // Settings data
  settings: Setting[];
  publicSettings: Record<string, any>;
  isLoading: boolean;
  error: Error | null;
  
  // Quick access to common settings
  siteName: string;
  currency: string;
  taxRate: number;
  freeShippingThreshold: number;
  maintenanceMode: boolean;
  maxCartItems: number;
  
  // Actions
  refreshSettings: () => Promise<void>;
  getSetting: (key: string, fallback?: any) => any;
  getPublicSetting: (key: string, fallback?: any) => any;
  
  // Cache management
  clearCache: () => void;
  getCacheStats: () => any;
}

// Create context
const SettingsContext = createContext<SettingsContextType | undefined>(undefined);

// Query client configuration for settings
const createSettingsQueryClient = () => {
  return new QueryClient({
    defaultOptions: {
      queries: {
        staleTime: 2 * 60 * 1000, // 2 minutes
        gcTime: 5 * 60 * 1000, // 5 minutes
        retry: 2,
        refetchOnWindowFocus: false,
        refetchOnReconnect: true,
      },
      mutations: {
        retry: 1,
        retryDelay: (attemptIndex) => Math.min(1000 * 2 ** attemptIndex, 30000),
      },
    },
  });
};

// Internal settings provider (needs to be inside QueryClient)
function InternalSettingsProvider({ children }: { children: ReactNode }) {
  const { toast } = useToast();
  const [isInitialized, setIsInitialized] = useState(false);
  
  // Fetch all settings and public settings
  const { 
    data: settings = [], 
    isLoading: settingsLoading, 
    error: settingsError,
    refetch: refetchSettings 
  } = useSettings();
  
  const { 
    data: publicSettings = {}, 
    isLoading: publicLoading, 
    error: publicError,
    refetch: refetchPublicSettings 
  } = usePublicSettings();

  // Subscribe to real-time changes
  useSettingsSubscription();

  // Quick access to common settings with fallbacks
  const siteName = useSettingValue('site_name', 'KCT Menswear');
  const currency = useSettingValue('currency', 'USD');
  const taxRate = useSettingValue('tax_rate', 0.08, parseFloat);
  const freeShippingThreshold = useSettingValue('free_shipping_threshold', 100, parseFloat);
  const maintenanceMode = useSettingValue('maintenance_mode', false, Boolean);
  const maxCartItems = useSettingValue('max_cart_items', 50, parseInt);

  // Combined loading and error states
  const isLoading = settingsLoading || publicLoading || !isInitialized;
  const error = settingsError || publicError;

  // Initialize settings
  useEffect(() => {
    if (!isInitialized && !isLoading && !error) {
      setIsInitialized(true);
      console.log('Settings initialized:', {
        settingsCount: settings.length,
        publicSettingsCount: Object.keys(publicSettings).length
      });
    }
  }, [isInitialized, isLoading, error, settings.length, publicSettings]);

  // Error handling
  useEffect(() => {
    if (error && isInitialized) {
      console.error('Settings error:', error);
      toast({
        title: 'Settings Error',
        description: 'Failed to load settings. Some features may not work correctly.',
        variant: 'destructive',
      });
    }
  }, [error, isInitialized, toast]);

  // Maintenance mode notification
  useEffect(() => {
    if (maintenanceMode && isInitialized) {
      toast({
        title: 'Maintenance Mode Active',
        description: 'The website is currently in maintenance mode.',
        variant: 'destructive',
      });
    }
  }, [maintenanceMode, isInitialized, toast]);

  // Helper functions
  const refreshSettings = async () => {
    try {
      await Promise.all([
        refetchSettings(),
        refetchPublicSettings()
      ]);
      toast({
        title: 'Settings Refreshed',
        description: 'All settings have been updated.',
      });
    } catch (error) {
      console.error('Failed to refresh settings:', error);
      toast({
        title: 'Refresh Failed',
        description: 'Failed to refresh settings. Please try again.',
        variant: 'destructive',
      });
    }
  };

  const getSetting = (key: string, fallback: any = null) => {
    const setting = settings.find(s => s.key === key);
    return setting ? setting.value : fallback;
  };

  const getPublicSetting = (key: string, fallback: any = null) => {
    return publicSettings[key] ?? fallback;
  };

  const clearCache = () => {
    settingsService.clearCache();
    toast({
      title: 'Cache Cleared',
      description: 'Settings cache has been cleared.',
    });
  };

  const getCacheStats = () => {
    return settingsService.getCacheStats();
  };

  // Context value
  const contextValue: SettingsContextType = {
    // Data
    settings,
    publicSettings,
    isLoading,
    error,
    
    // Quick access settings
    siteName,
    currency,
    taxRate,
    freeShippingThreshold,
    maintenanceMode,
    maxCartItems,
    
    // Actions
    refreshSettings,
    getSetting,
    getPublicSetting,
    clearCache,
    getCacheStats,
  };

  return (
    <SettingsContext.Provider value={contextValue}>
      {children}
    </SettingsContext.Provider>
  );
}

// Main settings provider component
interface SettingsProviderProps {
  children: ReactNode;
  queryClient?: QueryClient;
  enableDevtools?: boolean;
}

export function SettingsProvider({ 
  children, 
  queryClient,
  enableDevtools = process.env.NODE_ENV === 'development'
}: SettingsProviderProps) {
  const client = queryClient || createSettingsQueryClient();

  return (
    <QueryClientProvider client={client}>
      <InternalSettingsProvider>
        {children}
      </InternalSettingsProvider>
      {enableDevtools && <ReactQueryDevtools initialIsOpen={false} />}
    </QueryClientProvider>
  );
}

// Hook to use settings context
export function useSettingsContext(): SettingsContextType {
  const context = useContext(SettingsContext);
  if (!context) {
    throw new Error('useSettingsContext must be used within a SettingsProvider');
  }
  return context;
}

// Higher-order component for settings-dependent components
export function withSettings<P extends object>(
  Component: React.ComponentType<P>
) {
  return function SettingsWrappedComponent(props: P) {
    const settingsContext = useSettingsContext();
    
    if (settingsContext.isLoading) {
      return (
        <div className="flex items-center justify-center p-8">
          <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-primary"></div>
          <span className="ml-2">Loading settings...</span>
        </div>
      );
    }

    if (settingsContext.error) {
      return (
        <div className="flex items-center justify-center p-8 text-destructive">
          <div className="text-center">
            <p className="font-medium">Settings Error</p>
            <p className="text-sm text-muted-foreground mt-1">
              Failed to load settings. Please refresh the page.
            </p>
            <button 
              onClick={settingsContext.refreshSettings}
              className="mt-2 px-4 py-2 bg-primary text-primary-foreground rounded-md hover:bg-primary/90"
            >
              Retry
            </button>
          </div>
        </div>
      );
    }

    return <Component {...props} />;
  };
}

// Settings hook for components that need settings but aren't wrapped
export function useSettings() {
  try {
    return useSettingsContext();
  } catch {
    // Fallback when not wrapped in provider
    return {
      settings: [],
      publicSettings: {},
      isLoading: true,
      error: new Error('Settings provider not found'),
      siteName: 'KCT Menswear',
      currency: 'USD',
      taxRate: 0.08,
      freeShippingThreshold: 100,
      maintenanceMode: false,
      maxCartItems: 50,
      refreshSettings: async () => {},
      getSetting: () => null,
      getPublicSetting: () => null,
      clearCache: () => {},
      getCacheStats: () => ({ size: 0, keys: [] }),
    };
  }
}

// Settings loading component
export function SettingsLoadingSpinner() {
  const { isLoading, error, refreshSettings } = useSettingsContext();

  if (!isLoading && !error) return null;

  if (error) {
    return (
      <div className="fixed top-4 right-4 z-50 p-4 bg-destructive text-destructive-foreground rounded-lg shadow-lg">
        <div className="flex items-center space-x-2">
          <svg className="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M12 8v4m0 4h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z" />
          </svg>
          <span className="text-sm">Settings Error</span>
          <button 
            onClick={refreshSettings}
            className="ml-2 px-2 py-1 bg-destructive-foreground text-destructive rounded text-xs hover:bg-opacity-90"
          >
            Retry
          </button>
        </div>
      </div>
    );
  }

  if (isLoading) {
    return (
      <div className="fixed top-4 right-4 z-50 p-3 bg-background border rounded-lg shadow-lg">
        <div className="flex items-center space-x-2">
          <div className="animate-spin rounded-full h-4 w-4 border-2 border-primary border-t-transparent"></div>
          <span className="text-sm text-muted-foreground">Loading settings...</span>
        </div>
      </div>
    );
  }

  return null;
}

// Export types
export type { SettingsContextType, Setting } from '../hooks/useSettings';