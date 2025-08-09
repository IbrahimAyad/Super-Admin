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
  return process.env.NEXT_PUBLIC_SUPABASE_URL || 'localhost';
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

  // HARDCODED VALUES - Environment variables not working in production
  const supabaseUrl = 'https://gvcswimqaxvylgxbklbz.supabase.co';
  const supabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imd2Y3N3aW1xYXh2eWxneGJrbGJ6Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTM3NjA1MzAsImV4cCI6MjA2OTMzNjUzMH0.UZdiGcJXUV5VYetjWXV26inmbj2yXdiT03Z6t_5Lg24';

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

  console.log(`✅ Public Supabase client initialized`);
  return supabaseInstance;
}

/**
 * Create and configure the admin Supabase client (service role key)
 * Used for: Admin operations, bypassing RLS, privileged data access
 */
function createAdminSupabaseClient(): SupabaseClient {
  if (adminSupabaseInstance) {
    return adminSupabaseInstance;
  }

  const supabaseUrl = 'https://gvcswimqaxvylgxbklbz.supabase.co';
  // Service role key should NEVER be in client-side code
  // This should only be set as an environment variable on the server
  const supabaseServiceKey = typeof process !== 'undefined' && process.env?.SUPABASE_SERVICE_ROLE_KEY 
    ? process.env.SUPABASE_SERVICE_ROLE_KEY
    : ''; // Never hardcode service role key in client code!

  adminSupabaseInstance = createClient(supabaseUrl, supabaseServiceKey, {
    auth: {
      persistSession: false, // Admin operations don't need session persistence
      autoRefreshToken: false,
    },
    global: {
      headers: {
        'X-Client-Info': 'kct-menswear-admin',
      },
    },
  });

  console.log(`✅ Admin Supabase client initialized with service role`);
  console.log(`   Using service key: ${supabaseServiceKey.substring(0, 20)}...`);
  
  // Decode and log JWT info for debugging
  try {
    const payload = JSON.parse(Buffer.from(supabaseServiceKey.split('.')[1], 'base64').toString());
    console.log(`   JWT role: ${payload.role}`);
    console.log(`   JWT project: ${payload.ref}`);
  } catch (e) {
    console.log(`   Could not decode JWT: ${e}`);
  }
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
 * WARNING: This bypasses RLS and has full database access
 * Use only for verified admin operations
 */
export function getAdminSupabaseClient(): SupabaseClient {
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
  if (process.env.NODE_ENV === 'test') {
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
      return getAdminSupabaseClient();
    case 'public':
    case 'auth':
    default:
      return getSupabaseClient();
  }
}

export default supabase;