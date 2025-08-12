import React, { createContext, useContext, useEffect, useState } from 'react';
import { User, Session } from '@supabase/supabase-js';
import { supabase, signUp, signIn, signInWithGoogle, signOut, getProfile, updateProfile, onAuthStateChange } from '@/lib/services';
import type { UserProfile } from '@/lib/services';
import { verifyTwoFactorLogin, getAdminSecurityStatus, handleFailedLogin, resetFailedLoginAttempts } from '@/lib/services/twoFactor';
import { authenticateUser, getUserSecurityStatus, sendEmailVerificationToken } from '@/lib/services/authService';
import { logger } from '@/utils/logger';
import { toast } from 'sonner';

interface AuthContextType {
  user: User | null;
  session: Session | null;
  profile: UserProfile | null;
  loading: boolean;
  twoFactorRequired: boolean;
  pendingUserId: string | null;
  emailVerificationRequired: boolean;
  accountLocked: boolean;
  signUp: (email: string, password: string, userData?: Partial<UserProfile>) => Promise<any>;
  signIn: (email: string, password: string, rememberMe?: boolean) => Promise<any>;
  signInWithGoogle: () => Promise<any>;
  signOut: () => Promise<void>;
  updateProfile: (updates: Partial<UserProfile>) => Promise<void>;
  refreshProfile: () => Promise<void>;
  verifyTwoFactor: (token: string) => Promise<{ success: boolean; error?: string }>;
  clearTwoFactorState: () => void;
  sendEmailVerification: () => Promise<boolean>;
  refreshSecurityStatus: () => Promise<void>;
  getSecurityStatus: () => Promise<any>;
}

const AuthContext = createContext<AuthContextType | undefined>(undefined);

export function AuthProvider({ children }: { children: React.ReactNode }) {
  const [user, setUser] = useState<User | null>(null);
  const [session, setSession] = useState<Session | null>(null);
  const [profile, setProfile] = useState<UserProfile | null>(null);
  const [loading, setLoading] = useState(true);
  const [twoFactorRequired, setTwoFactorRequired] = useState(false);
  const [pendingUserId, setPendingUserId] = useState<string | null>(null);
  const [emailVerificationRequired, setEmailVerificationRequired] = useState(false);
  const [accountLocked, setAccountLocked] = useState(false);
  const [rememberMe, setRememberMe] = useState(false);
  const [securityStatus, setSecurityStatus] = useState<any>(null);

  useEffect(() => {
    logger.debug('AuthContext: Initializing auth state check');
    
    // Get initial session
    supabase.auth.getSession().then(async ({ data: { session } }) => {
      logger.debug('AuthContext: Initial session check', { session: !!session, user: session?.user?.email });
      setSession(session);
      setUser(session?.user ?? null);
      
      if (session?.user) {
        await loadProfile(session.user.id);
      } else {
        setLoading(false);
      }
    });

    // Listen for auth changes
    const {
      data: { subscription },
    } = supabase.auth.onAuthStateChange(async (event, session) => {
      logger.debug('AuthContext: Auth state changed', { event, session: !!session, user: session?.user?.email });
      setSession(session);
      setUser(session?.user ?? null);
      
      if (session?.user) {
        await loadProfile(session.user.id);
      } else {
        setProfile(null);
        setTwoFactorRequired(false);
        setPendingUserId(null);
        setLoading(false);
      }
    });

    return () => subscription.unsubscribe();
  }, []);

  const loadProfile = async (userId: string) => {
    try {
      const result = await getProfile(userId);
      const profileData = result.success ? result.data : null;
      setProfile(profileData);
    } catch (error) {
      logger.error('Error loading profile:', error);
      // If profile doesn't exist, create one
      try {
        const result = await updateProfile(userId, {
          onboarding_completed: false,
          measurements: {},
          style_preferences: {}
        });
        const newProfile = result.success ? result.data : null;
        setProfile(newProfile);
      } catch (createError) {
        logger.error('Error creating profile:', createError);
      }
    } finally {
      setLoading(false);
    }
  };


  const handleSignUp = async (email: string, password: string, userData?: Partial<UserProfile>) => {
    const result = await signUp(email, password, userData);
    return result.success ? result.data : result;
  };

  const handleSignIn = async (email: string, password: string, rememberMeOption: boolean = false) => {
    setRememberMe(rememberMeOption);
    setLoading(true);
    
    // Reset states
    setEmailVerificationRequired(false);
    setAccountLocked(false);
    setTwoFactorRequired(false);
    setPendingUserId(null);
    
    try {
      // Use enhanced authentication service
      const result = await authenticateUser(
        email, 
        password,
        undefined, // ipAddress - could be added with a service
        navigator.userAgent,
        rememberMeOption
      );
      
      if (!result.success) {
        // Handle specific error types
        if (result.requiresVerification) {
          setEmailVerificationRequired(true);
        } else if (result.accountLocked) {
          setAccountLocked(true);
        } else if (result.twoFactorRequired) {
          setTwoFactorRequired(true);
          setPendingUserId(result.user?.id || null);
        }
        
        return result;
      }

      // Handle 2FA requirement
      if (result.twoFactorRequired) {
        setTwoFactorRequired(true);
        setPendingUserId(result.user?.id || null);
        return {
          success: true,
          requiresTwoFactor: true,
          message: 'Two-factor authentication required'
        };
      }
      
      // Successful login - load security status
      if (result.user?.id) {
        await loadSecurityStatus(result.user.id);
      }
      
      return result;
    } catch (error) {
      logger.error('Error during sign in:', error);
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
      // Simple sign out from Supabase
      await signOut();
      
      // Clear all state
      setProfile(null);
      setTwoFactorRequired(false);
      setPendingUserId(null);
      
      toast.success('Signed out successfully');
    } catch (error) {
      logger.error('Error during sign out:', error);
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

      // 2FA verified, complete the login process
      const { data: { user }, error } = await supabase.auth.getUser();
      if (error || !user) {
        return {
          success: false,
          error: 'Session expired, please login again'
        };
      }
      
      // Reset failed login attempts
      await resetFailedLoginAttempts(pendingUserId);
      
      // Clear 2FA state
      setTwoFactorRequired(false);
      setPendingUserId(null);
      
      toast.success('Two-factor authentication successful');
      
      return { success: true };
    } catch (error) {
      logger.error('Error verifying 2FA:', error);
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

  const loadSecurityStatus = async (userId: string) => {
    try {
      const status = await getUserSecurityStatus(userId);
      setSecurityStatus(status);
    } catch (error) {
      logger.error('Error loading security status:', error);
    }
  };

  const handleSendEmailVerification = async (): Promise<boolean> => {
    if (!user) {
      logger.error('No user found for email verification');
      return false;
    }

    try {
      const success = await sendEmailVerificationToken(
        user.id,
        user.email || '',
        user.user_metadata?.full_name || 'Admin'
      );

      if (success) {
        toast.success('Verification email sent successfully');
      } else {
        toast.error('Failed to send verification email');
      }

      return success;
    } catch (error) {
      logger.error('Error sending email verification:', error);
      toast.error('Failed to send verification email');
      return false;
    }
  };

  const refreshSecurityStatus = async () => {
    if (user?.id) {
      await loadSecurityStatus(user.id);
    }
  };

  const getSecurityStatus = async () => {
    if (!user?.id) return null;
    return await getUserSecurityStatus(user.id);
  };


  const value = {
    user,
    session,
    profile,
    loading,
    twoFactorRequired,
    pendingUserId,
    emailVerificationRequired,
    accountLocked,
    signUp: handleSignUp,
    signIn: handleSignIn,
    signInWithGoogle: handleSignInWithGoogle,
    signOut: handleSignOut,
    updateProfile: handleUpdateProfile,
    refreshProfile,
    verifyTwoFactor,
    clearTwoFactorState,
    sendEmailVerification: handleSendEmailVerification,
    refreshSecurityStatus,
    getSecurityStatus,
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