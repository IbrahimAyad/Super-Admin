/**
 * DUAL SUPABASE CLIENT ARCHITECTURE
 * Fixes 401/permission errors by using appropriate keys for different operations:
 * - Public client (anon key): For user authentication and public data
 * - Admin client (service key): For admin operations and privileged data access
 * Last updated: 2025-08-09
 */

import { createClient, SupabaseClient } from '@supabase/supabase-js';

// Singleton instances
let supabaseInstance: SupabaseClient | null = null;
let adminSupabaseInstance: SupabaseClient | null = null;

// Get deployment URL for storage key prefixing to prevent conflicts
const getDeploymentUrl = (): string => {
  if (typeof window !== 'undefined') {
    return window.location.origin;
  }
  return import.meta.env.VITE_SUPABASE_URL || 'localhost';
};

// Create storage key prefix based on deployment URL
const createStorageKeyPrefix = (): string => {
  const deploymentUrl = getDeploymentUrl();
  const cleanUrl = deploymentUrl.replace(/[^a-zA-Z0-9]/g, '').toLowerCase();
  return `sb-${cleanUrl}`;
};

/**
 * Create and configure the public Supabase client (anon key)
 * Used for: User authentication, public data access
 */
function createSupabaseClient(): SupabaseClient {
  if (supabaseInstance) {
    return supabaseInstance;
  }

  // Use environment variables for security
  const supabaseUrl = import.meta.env.VITE_SUPABASE_URL || 'https://gvcswimqaxvylgxbklbz.supabase.co';
  const supabaseAnonKey = import.meta.env.VITE_SUPABASE_ANON_KEY || '';

  const storageKeyPrefix = createStorageKeyPrefix();
  
  supabaseInstance = createClient(supabaseUrl, supabaseAnonKey, {
    auth: {
      persistSession: true,
      autoRefreshToken: true,
      detectSessionInUrl: true,
      // Prefix storage keys with deployment URL to prevent conflicts
      storageKey: `${storageKeyPrefix}-auth-token`,
    },
    global: {
      headers: {
        'X-Client-Info': 'kct-menswear-public',
      },
    },
  });

  return supabaseInstance;
}

/**
 * Create and configure the admin Supabase client (service role key)
 * WARNING: This should ONLY be used server-side, never in browser
 */
function createAdminSupabaseClient(): SupabaseClient | null {
  // Don't create admin client in browser environment
  if (typeof window !== 'undefined') {
    return null;
  }

  if (adminSupabaseInstance) {
    return adminSupabaseInstance;
  }

  const supabaseUrl = import.meta.env.VITE_SUPABASE_URL || 'https://gvcswimqaxvylgxbklbz.supabase.co';
  const supabaseServiceKey = import.meta.env.VITE_SUPABASE_SERVICE_ROLE_KEY || '';
  
  if (!supabaseServiceKey) {
    return null;
  }

  adminSupabaseInstance = createClient(supabaseUrl, supabaseServiceKey, {
    auth: {
      persistSession: false,
      autoRefreshToken: false,
    },
    global: {
      headers: {
        'X-Client-Info': 'kct-menswear-admin',
      },
    },
  });

  return adminSupabaseInstance;
}

/**
 * Get the public Supabase client instance
 */
export function getSupabaseClient(): SupabaseClient {
  return createSupabaseClient();
}

/**
 * Get the admin Supabase client instance
 * WARNING: Returns null in browser - use Edge Functions instead
 */
export function getAdminSupabaseClient(): SupabaseClient | null {
  return createAdminSupabaseClient();
}

/**
 * Export the singleton instance (for backward compatibility)
 */
export const supabase = createSupabaseClient();

/**
 * Reset the singletons (for testing purposes only)
 */
export function resetSupabaseClient(): void {
  if (import.meta.env.MODE === 'test') {
    supabaseInstance = null;
    adminSupabaseInstance = null;
  }
}

/**
 * Utility function to determine which client to use
 */
export function getClientForOperation(operationType: 'public' | 'admin' | 'auth'): SupabaseClient {
  switch (operationType) {
    case 'admin':
      // In browser, fall back to public client
      const adminClient = getAdminSupabaseClient();
      if (!adminClient) {
        return getSupabaseClient();
      }
      return adminClient;
    case 'public':
    case 'auth':
    default:
      return getSupabaseClient();
  }
}

export default supabase;