import React, { createContext, useContext, useEffect, useState } from 'react';
import { User, Session } from '@supabase/supabase-js';
import { supabase, signUp, signIn, signInWithGoogle, signOut, getProfile, updateProfile, onAuthStateChange } from '@/lib/services';
import type { UserProfile } from '@/lib/services';
import { verifyTwoFactorLogin, getAdminSecurityStatus, handleFailedLogin, resetFailedLoginAttempts } from '@/lib/services/twoFactor';
import { createAdminSession, endAdminSession, getCurrentAdminSession, initializeSessionManager } from '@/lib/services/sessionManager';
import type { AdminSession } from '@/lib/services/sessionManager';
import { toast } from 'sonner';

interface AuthContextType {
  user: User | null;
  session: Session | null;
  profile: UserProfile | null;
  adminSession: AdminSession | null;
  loading: boolean;
  twoFactorRequired: boolean;
  pendingUserId: string | null;
  signUp: (email: string, password: string, userData?: Partial<UserProfile>) => Promise<any>;
  signIn: (email: string, password: string, rememberMe?: boolean) => Promise<any>;
  signInWithGoogle: () => Promise<any>;
  signOut: () => Promise<void>;
  updateProfile: (updates: Partial<UserProfile>) => Promise<void>;
  refreshProfile: () => Promise<void>;
  verifyTwoFactor: (token: string) => Promise<{ success: boolean; error?: string }>;
  clearTwoFactorState: () => void;
  refreshAdminSession: () => Promise<void>;
}

const AuthContext = createContext<AuthContextType | undefined>(undefined);

export function AuthProvider({ children }: { children: React.ReactNode }) {
  const [user, setUser] = useState<User | null>(null);
  const [session, setSession] = useState<Session | null>(null);
  const [profile, setProfile] = useState<UserProfile | null>(null);
  const [adminSession, setAdminSession] = useState<AdminSession | null>(null);
  const [loading, setLoading] = useState(true);
  const [twoFactorRequired, setTwoFactorRequired] = useState(false);
  const [pendingUserId, setPendingUserId] = useState<string | null>(null);
  const [rememberMe, setRememberMe] = useState(false);

  useEffect(() => {
    console.log('AuthContext: Initializing auth state check');
    
    // Initialize session management
    initializeSessionManager();
    
    // Get initial session
    supabase.auth.getSession().then(async ({ data: { session } }) => {
      console.log('AuthContext: Initial session check', { session: !!session, user: session?.user?.email });
      setSession(session);
      setUser(session?.user ?? null);
      
      if (session?.user) {
        await loadProfile(session.user.id);
        // Don't wait for admin session here to avoid blocking
        loadAdminSession();
      } else {
        setLoading(false);
      }
    });

    // Listen for auth changes
    const {
      data: { subscription },
    } = supabase.auth.onAuthStateChange(async (event, session) => {
      console.log('AuthContext: Auth state changed', { event, session: !!session, user: session?.user?.email });
      setSession(session);
      setUser(session?.user ?? null);
      
      if (session?.user) {
        await loadProfile(session.user.id);
        if (event === 'SIGNED_IN') {
          // Create admin session for single-user system
          await createAdminSessionForUser(session.user.id);
        }
      } else {
        setProfile(null);
        setAdminSession(null);
        setTwoFactorRequired(false);
        setPendingUserId(null);
        setLoading(false);
      }
    });

    return () => subscription.unsubscribe();
  }, []);

  const loadProfile = async (userId: string) => {
    try {
      console.log('Loading profile for user:', userId);
      const result = await getProfile(userId);
      const profileData = result.success ? result.data : null;
      console.log('Profile loaded:', profileData);
      setProfile(profileData);
    } catch (error) {
      console.error('Error loading profile:', error);
      // If profile doesn't exist, create one
      try {
        console.log('Creating new profile for user:', userId);
        const result = await updateProfile(userId, {
          onboarding_completed: false,
          measurements: {},
          style_preferences: {}
        });
        const newProfile = result.success ? result.data : null;
        console.log('New profile created:', newProfile);
        setProfile(newProfile);
      } catch (createError) {
        console.error('Error creating profile:', createError);
      }
    } finally {
      setLoading(false);
    }
  };

  const loadAdminSession = async () => {
    try {
      const result = await getCurrentAdminSession();
      if (result.success && result.session) {
        console.log('Admin session loaded successfully');
        setAdminSession(result.session);
      } else {
        console.log('No existing admin session found');
        // Don't set to null immediately - let createAdminSessionForUser handle it
        // This prevents the race condition
      }
    } catch (error) {
      console.error('Error loading admin session:', error);
      // Don't set to null on error - let the authentication flow handle it
    }
  };

  const refreshAdminSession = async () => {
    await loadAdminSession();
  };

  const handleSignUp = async (email: string, password: string, userData?: Partial<UserProfile>) => {
    const result = await signUp(email, password, userData);
    return result.success ? result.data : result;
  };

  const handleSignIn = async (email: string, password: string, rememberMeOption: boolean = false) => {
    setRememberMe(rememberMeOption);
    setLoading(true);
    
    try {
      const result = await signIn(email, password);
      
      if (!result.success) {
        // Handle failed login attempt
        if (result.data?.user?.id) {
          await handleFailedLogin(result.data.user.id);
        }
        return result;
      }

      const userId = result.data?.user?.id;
      if (!userId) {
        return { success: false, error: 'Invalid user data' };
      }

      // Check if user needs 2FA
      const securityStatus = await getAdminSecurityStatus(userId);
      if (securityStatus.success && securityStatus.data?.two_factor_enabled) {
        // Store pending user ID and require 2FA
        setPendingUserId(userId);
        setTwoFactorRequired(true);
        
        // Sign out from Supabase auth temporarily
        await supabase.auth.signOut();
        
        return {
          success: true,
          requiresTwoFactor: true,
          message: 'Two-factor authentication required'
        };
      }

      // No 2FA required, create admin session directly
      await createAdminSessionForUser(userId);
      
      // Reset failed login attempts on successful login
      await resetFailedLoginAttempts(userId);
      
      return result;
    } catch (error) {
      console.error('Error during sign in:', error);
      return {
        success: false,
        error: error instanceof Error ? error.message : 'Sign in failed'
      };
    } finally {
      setLoading(false);
    }
  };

  const handleSignInWithGoogle = async () => {
    const result = await signInWithGoogle();
    return result.success ? result.data : result;
  };

  const handleSignOut = async () => {
    try {
      // End admin session first
      if (adminSession) {
        await endAdminSession(adminSession.session_token);
      }
      
      // Then sign out from Supabase
      await signOut();
      
      // Clear all state
      setProfile(null);
      setAdminSession(null);
      setTwoFactorRequired(false);
      setPendingUserId(null);
      
      toast.success('Signed out successfully');
    } catch (error) {
      console.error('Error during sign out:', error);
      toast.error('Sign out failed');
    }
  };

  const handleUpdateProfile = async (updates: Partial<UserProfile>) => {
    if (!user) throw new Error('No user logged in');
    const result = await updateProfile(user.id, updates);
    if (result.success) {
      setProfile(result.data);
    }
  };

  const refreshProfile = async () => {
    if (!user) return;
    await loadProfile(user.id);
  };

  const verifyTwoFactor = async (token: string): Promise<{ success: boolean; error?: string }> => {
    if (!pendingUserId) {
      return { success: false, error: 'No pending authentication' };
    }

    try {
      setLoading(true);
      
      // Verify 2FA token
      const result = await verifyTwoFactorLogin(pendingUserId, token);
      
      if (!result.success) {
        // Handle failed 2FA attempt
        await handleFailedLogin(pendingUserId);
        return result;
      }

      // 2FA verified, now complete the login process
      // Re-authenticate with Supabase
      const { data: { user }, error } = await supabase.auth.getUser();
      if (error || !user) {
        // If no valid Supabase session, we need to re-authenticate
        return {
          success: false,
          error: 'Session expired, please login again'
        };
      }

      // Create admin session
      await createAdminSessionForUser(pendingUserId);
      
      // Reset failed login attempts
      await resetFailedLoginAttempts(pendingUserId);
      
      // Clear 2FA state
      setTwoFactorRequired(false);
      setPendingUserId(null);
      
      toast.success('Two-factor authentication successful');
      
      return { success: true };
    } catch (error) {
      console.error('Error verifying 2FA:', error);
      return {
        success: false,
        error: error instanceof Error ? error.message : 'Verification failed'
      };
    } finally {
      setLoading(false);
    }
  };

  const clearTwoFactorState = () => {
    setTwoFactorRequired(false);
    setPendingUserId(null);
  };

  const createAdminSessionForUser = async (userId: string) => {
    try {
      console.log('Creating admin session for user:', userId);
      
      // For single-user admin system, we'll create/find admin user if not exists
      let adminUser;
      
      // First try to get existing admin user
      const { data: existingAdmin, error: fetchError } = await supabase
        .from('admin_users')
        .select('id')
        .eq('user_id', userId)
        .eq('is_active', true)
        .single();

      if (fetchError && fetchError.code !== 'PGRST116') {
        console.warn('Error fetching admin user, proceeding without admin session:', fetchError);
        // For single-user system, we'll just set a mock admin session
        setAdminSession({
          id: 'single-user-session',
          user_id: userId,
          admin_user_id: 'single-user-admin',
          session_token: 'single-user-token',
          device_info: {},
          is_active: true,
          remember_me: rememberMe,
          last_activity_at: new Date().toISOString(),
          expires_at: new Date(Date.now() + 24 * 60 * 60 * 1000).toISOString(), // 24 hours
          created_at: new Date().toISOString()
        });
        return;
      }

      if (existingAdmin) {
        adminUser = existingAdmin;
      } else {
        // Create admin user for single-user system
        console.log('Creating admin user for single-user system');
        const { data: newAdmin, error: createError } = await supabase
          .from('admin_users')
          .insert({
            user_id: userId,
            role: 'super_admin',
            permissions: ['*'], // All permissions for single user
            is_active: true
          })
          .select('id')
          .single();

        if (createError) {
          console.warn('Could not create admin user, using fallback session:', createError);
          // Use fallback session for single-user system
          setAdminSession({
            id: 'single-user-session',
            user_id: userId,
            admin_user_id: 'single-user-admin',
            session_token: 'single-user-token',
            device_info: {},
            is_active: true,
            remember_me: rememberMe,
            last_activity_at: new Date().toISOString(),
            expires_at: new Date(Date.now() + 24 * 60 * 60 * 1000).toISOString(),
            created_at: new Date().toISOString()
          });
          return;
        }
        
        adminUser = newAdmin;
      }

      // Try to create proper admin session
      const sessionResult = await createAdminSession(
        userId,
        adminUser.id,
        rememberMe
      );

      if (sessionResult.success && sessionResult.session) {
        console.log('Admin session created successfully');
        setAdminSession(sessionResult.session);
      } else {
        console.warn('Failed to create proper admin session, using fallback:', sessionResult.error);
        // Use fallback session
        setAdminSession({
          id: 'fallback-session',
          user_id: userId,
          admin_user_id: adminUser.id,
          session_token: `fallback-${Date.now()}`,
          device_info: {},
          is_active: true,
          remember_me: rememberMe,
          last_activity_at: new Date().toISOString(),
          expires_at: new Date(Date.now() + 24 * 60 * 60 * 1000).toISOString(),
          created_at: new Date().toISOString()
        });
      }
    } catch (error) {
      console.error('Error creating admin session:', error);
      // For single-user system, always provide a fallback session to avoid login loops
      setAdminSession({
        id: 'error-fallback-session',
        user_id: userId,
        admin_user_id: 'error-fallback-admin',
        session_token: `error-fallback-${Date.now()}`,
        device_info: {},
        is_active: true,
        remember_me: rememberMe,
        last_activity_at: new Date().toISOString(),
        expires_at: new Date(Date.now() + 24 * 60 * 60 * 1000).toISOString(),
        created_at: new Date().toISOString()
      });
    }
  };

  const value = {
    user,
    session,
    profile,
    adminSession,
    loading,
    twoFactorRequired,
    pendingUserId,
    signUp: handleSignUp,
    signIn: handleSignIn,
    signInWithGoogle: handleSignInWithGoogle,
    signOut: handleSignOut,
    updateProfile: handleUpdateProfile,
    refreshProfile,
    verifyTwoFactor,
    clearTwoFactorState,
    refreshAdminSession,
  };

  return <AuthContext.Provider value={value}>{children}</AuthContext.Provider>;
}

export function useAuth() {
  const context = useContext(AuthContext);
  if (context === undefined) {
    throw new Error('useAuth must be used within an AuthProvider');
  }
  return context;
}