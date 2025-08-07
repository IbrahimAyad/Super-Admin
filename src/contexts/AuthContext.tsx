import React, { createContext, useContext, useEffect, useState } from 'react';
import { User, Session } from '@supabase/supabase-js';
import { supabase, signUp, signIn, signInWithGoogle, signOut, getProfile, updateProfile, onAuthStateChange } from '@/lib/services';
import type { UserProfile } from '@/lib/services';

interface AuthContextType {
  user: User | null;
  session: Session | null;
  profile: UserProfile | null;
  loading: boolean;
  signUp: (email: string, password: string, userData?: Partial<UserProfile>) => Promise<any>;
  signIn: (email: string, password: string) => Promise<any>;
  signInWithGoogle: () => Promise<any>;
  signOut: () => Promise<void>;
  updateProfile: (updates: Partial<UserProfile>) => Promise<void>;
  refreshProfile: () => Promise<void>;
}

const AuthContext = createContext<AuthContextType | undefined>(undefined);

export function AuthProvider({ children }: { children: React.ReactNode }) {
  const [user, setUser] = useState<User | null>(null);
  const [session, setSession] = useState<Session | null>(null);
  const [profile, setProfile] = useState<UserProfile | null>(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    console.log('AuthContext: Initializing auth state check');
    // Get initial session
    supabase.auth.getSession().then(({ data: { session } }) => {
      console.log('AuthContext: Initial session check', { session: !!session, user: session?.user?.email });
      setSession(session);
      setUser(session?.user ?? null);
      if (session?.user) {
        loadProfile(session.user.id);
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
      } else {
        setProfile(null);
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

  const handleSignUp = async (email: string, password: string, userData?: Partial<UserProfile>) => {
    const result = await signUp(email, password, userData);
    return result.success ? result.data : result;
  };

  const handleSignIn = async (email: string, password: string) => {
    const result = await signIn(email, password);
    return result.success ? result.data : result;
  };

  const handleSignInWithGoogle = async () => {
    const result = await signInWithGoogle();
    return result.success ? result.data : result;
  };

  const handleSignOut = async () => {
    await signOut();
    setProfile(null);
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

  const value = {
    user,
    session,
    profile,
    loading,
    signUp: handleSignUp,
    signIn: handleSignIn,
    signInWithGoogle: handleSignInWithGoogle,
    signOut: handleSignOut,
    updateProfile: handleUpdateProfile,
    refreshProfile,
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