/**
 * UNIFIED SERVICES INDEX
 * Single import point for all service modules
 * Last updated: 2025-08-07
 */

// Export all services
export * from './auth';
export * from './products';
export * from './business';
export * from './settings';
export * from './settingsSync';
export * from './settingsSecurity';

// Export the unified Supabase client
export { supabase, getSupabaseClient } from '../supabase-client';