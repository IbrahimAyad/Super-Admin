/**
 * UNIFIED AUTH SERVICE
 * Centralized authentication operations using the singleton Supabase client
 * Last updated: 2025-08-07
 */

import { supabase } from '../supabase-client';

export interface UserProfile {
  id: string;
  username?: string;
  display_name?: string;
  avatar_url?: string;
  onboarding_completed: boolean;
  measurements: Record<string, any>;
  style_preferences: Record<string, any>;
  created_at: string;
  updated_at: string;
}

/**
 * Authentication Methods
 */
export async function signUp(email: string, password: string, userData?: Partial<UserProfile>) {
  try {
    const { data, error } = await supabase.auth.signUp({
      email,
      password,
      options: {
        data: userData || {}
      }
    });

    if (error) throw error;
    return {
      success: true,
      data,
      error: null
    };
  } catch (error) {
    console.error('signUp error:', error);
    return {
      success: false,
      data: null,
      error: error instanceof Error ? error.message : 'Unknown error'
    };
  }
}

export async function signIn(email: string, password: string) {
  try {
    const { data, error } = await supabase.auth.signInWithPassword({
      email,
      password
    });

    if (error) throw error;
    return {
      success: true,
      data,
      error: null
    };
  } catch (error) {
    console.error('signIn error:', error);
    return {
      success: false,
      data: null,
      error: error instanceof Error ? error.message : 'Unknown error'
    };
  }
}

export async function signInWithGoogle() {
  try {
    const { data, error } = await supabase.auth.signInWithOAuth({
      provider: 'google',
      options: {
        redirectTo: `${window.location.origin}/auth/callback`
      }
    });

    if (error) throw error;
    return {
      success: true,
      data,
      error: null
    };
  } catch (error) {
    console.error('signInWithGoogle error:', error);
    return {
      success: false,
      data: null,
      error: error instanceof Error ? error.message : 'Unknown error'
    };
  }
}

export async function signOut() {
  try {
    const { error } = await supabase.auth.signOut();
    if (error) throw error;
    
    return {
      success: true,
      error: null
    };
  } catch (error) {
    console.error('signOut error:', error);
    return {
      success: false,
      error: error instanceof Error ? error.message : 'Unknown error'
    };
  }
}

export async function resetPassword(email: string) {
  try {
    const { data, error } = await supabase.auth.resetPasswordForEmail(email, {
      redirectTo: `${window.location.origin}/auth/reset-password`
    });

    if (error) throw error;
    return {
      success: true,
      data,
      error: null
    };
  } catch (error) {
    console.error('resetPassword error:', error);
    return {
      success: false,
      data: null,
      error: error instanceof Error ? error.message : 'Unknown error'
    };
  }
}

/**
 * Get current session
 */
export async function getSession() {
  try {
    const { data, error } = await supabase.auth.getSession();
    if (error) throw error;
    
    return {
      success: true,
      data: data.session,
      error: null
    };
  } catch (error) {
    console.error('getSession error:', error);
    return {
      success: false,
      data: null,
      error: error instanceof Error ? error.message : 'Unknown error'
    };
  }
}

/**
 * Get current user
 */
export async function getCurrentUser() {
  try {
    const { data, error } = await supabase.auth.getUser();
    if (error) throw error;
    
    return {
      success: true,
      data: data.user,
      error: null
    };
  } catch (error) {
    console.error('getCurrentUser error:', error);
    return {
      success: false,
      data: null,
      error: error instanceof Error ? error.message : 'Unknown error'
    };
  }
}

/**
 * User Profile Methods
 */
export async function getProfile(userId: string) {
  try {
    const { data, error } = await supabase
      .from('user_profiles')
      .select('*')
      .eq('id', userId)
      .single();

    if (error) {
      // If no profile exists (404/406 error), return null instead of throwing
      if (error.code === 'PGRST116' || error.message.includes('no rows') || error.status === 406) {
        console.log('No profile found for user:', userId);
        return {
          success: false,
          data: null,
          error: 'Profile not found'
        };
      }
      throw error;
    }

    return {
      success: true,
      data,
      error: null
    };
  } catch (error) {
    console.error('getProfile error:', error);
    return {
      success: false,
      data: null,
      error: error instanceof Error ? error.message : 'Unknown error'
    };
  }
}

export async function updateProfile(userId: string, updates: Partial<UserProfile>) {
  try {
    const { data, error } = await supabase
      .from('user_profiles')
      .upsert({
        id: userId,
        ...updates,
        updated_at: new Date().toISOString()
      })
      .select()
      .single();

    if (error) throw error;

    return {
      success: true,
      data,
      error: null
    };
  } catch (error) {
    console.error('updateProfile error:', error);
    return {
      success: false,
      data: null,
      error: error instanceof Error ? error.message : 'Unknown error'
    };
  }
}

export async function updateMeasurements(userId: string, measurements: Record<string, any>) {
  try {
    const { data, error } = await supabase
      .from('user_profiles')
      .update({ 
        measurements,
        updated_at: new Date().toISOString()
      })
      .eq('id', userId)
      .select()
      .single();

    if (error) throw error;

    return {
      success: true,
      data,
      error: null
    };
  } catch (error) {
    console.error('updateMeasurements error:', error);
    return {
      success: false,
      data: null,
      error: error instanceof Error ? error.message : 'Unknown error'
    };
  }
}

/**
 * Auth state change listener
 */
export function onAuthStateChange(callback: (event: string, session: any) => void) {
  return supabase.auth.onAuthStateChange(callback);
}

/**
 * Admin authentication check
 */
export async function checkAdminAccess(userId?: string) {
  try {
    const { data, error } = await supabase
      .from('admin_users')
      .select('*')
      .eq('user_id', userId || 'unknown')
      .eq('is_active', true)
      .single();

    if (error) {
      if (error.code === 'PGRST116') {
        return {
          success: false,
          data: null,
          error: 'Admin access not found'
        };
      }
      throw error;
    }

    return {
      success: true,
      data,
      error: null
    };
  } catch (error) {
    console.error('checkAdminAccess error:', error);
    return {
      success: false,
      data: null,
      error: error instanceof Error ? error.message : 'Unknown error'
    };
  }
}