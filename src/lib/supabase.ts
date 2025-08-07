/**
 * UNIFIED SUPABASE MODULE
 * Main entry point - redirects to the new unified services architecture
 * Last updated: 2025-08-07
 */

// Export everything from the new unified services
export * from './services';

// For backward compatibility, also export the legacy API wrapper
export { KCTMenswearAPI } from './supabase-legacy';

// Default export is the supabase client
export { supabase as default } from './services';