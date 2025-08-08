/**
 * UNIFIED SUPABASE CLIENT
 * Single source of truth for all Supabase operations
 * Implements singleton pattern with proper storage key prefixing
 * Last updated: 2025-08-07
 */

import { createClient, SupabaseClient } from '@supabase/supabase-js';

// Singleton Supabase client instance
let supabaseInstance: SupabaseClient | null = null;

// Get deployment URL for storage key prefixing to prevent conflicts
const getDeploymentUrl = (): string => {
  if (typeof window !== 'undefined') {
    return window.location.origin;
  }
  return process.env.NEXT_PUBLIC_SUPABASE_URL || 'localhost';
};

// Create storage key prefix based on deployment URL
const createStorageKeyPrefix = (): string => {
  const deploymentUrl = getDeploymentUrl();
  const cleanUrl = deploymentUrl.replace(/[^a-zA-Z0-9]/g, '').toLowerCase();
  return `sb-${cleanUrl}`;
};

/**
 * Create and configure the singleton Supabase client
 */
function createSupabaseClient(): SupabaseClient {
  if (supabaseInstance) {
    return supabaseInstance;
  }

  // Get environment variables (Next.js format)
  const supabaseUrl = process.env.NEXT_PUBLIC_SUPABASE_URL;
  const supabaseKey = process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY;

  // Validate environment variables
  if (!supabaseUrl || !supabaseKey) {
    throw new Error(
      'Missing Supabase environment variables. Please check your .env file and ensure NEXT_PUBLIC_SUPABASE_URL and NEXT_PUBLIC_SUPABASE_ANON_KEY are set.'
    );
  }

  const storageKeyPrefix = createStorageKeyPrefix();
  
  supabaseInstance = createClient(supabaseUrl, supabaseKey, {
    auth: {
      persistSession: true,
      autoRefreshToken: true,
      detectSessionInUrl: true,
      // Prefix storage keys with deployment URL to prevent conflicts
      storageKey: `${storageKeyPrefix}-auth-token`,
    },
    global: {
      headers: {
        'X-Client-Info': 'kct-menswear-admin',
      },
    },
  });

  // Log initialization for debugging
  console.log(`✅ Supabase client initialized with storage key: ${storageKeyPrefix}-auth-token`);

  return supabaseInstance;
}

/**
 * Get the singleton Supabase client instance
 */
export function getSupabaseClient(): SupabaseClient {
  return createSupabaseClient();
}

/**
 * Export the singleton instance (for backward compatibility)
 */
export const supabase = createSupabaseClient();

/**
 * Reset the singleton (for testing purposes only)
 */
export function resetSupabaseClient(): void {
  if (process.env.NODE_ENV === 'test') {
    supabaseInstance = null;
  }
}

export default supabase;