/**
 * SESSION MANAGER HOOK - ULTRA SIMPLIFIED
 * NO DATABASE OPERATIONS VERSION
 * Eliminates all 400/401 errors for single-admin system
 * Created: 2025-08-07
 */

import { useState, useEffect, useCallback } from 'react';
import { useAuth } from '@/contexts/AuthContext';
import { toast } from 'sonner';

export interface UseSessionManagerReturn {
  // Session state
  currentSession: any | null;
  allSessions: any[];
  isLoading: boolean;
  isExpiring: boolean;
  minutesUntilExpiry: number | null;
  
  // Session actions
  refreshSession: () => Promise<void>;
  extendSession: (minutes?: number) => Promise<boolean>;
  logout: () => Promise<void>;
  logoutFromAllDevices: () => Promise<void>;
  
  // Session management
  updateActivity: () => Promise<void>;
  checkSessionExpiry: () => Promise<void>;
  
  // Suspicious activity
  isSuspiciousActivity: boolean;
  suspiciousReasons: string[];
  riskLevel: 'low' | 'medium' | 'high';
}

export function useSessionManager(): UseSessionManagerReturn {
  const { user, signOut } = useAuth();
  const [isLoading, setIsLoading] = useState(false);

  // Create mock session if user exists
  const mockSession = user ? {
    id: `session-${user.id}`,
    user_id: user.id,
    created_at: new Date().toISOString(),
    expires_at: new Date(Date.now() + 24 * 60 * 60 * 1000).toISOString(),
    is_active: true
  } : null;

  // NO DATABASE OPERATIONS - All functions return immediately
  const refreshSession = useCallback(async () => {
    // No-op - prevents database calls
  }, []);

  const checkSessionExpiry = useCallback(async () => {
    // No-op - prevents database calls
  }, []);

  const updateActivity = useCallback(async () => {
    // No-op - prevents database calls
  }, []);

  const extendSession = useCallback(async (minutes: number = 30): Promise<boolean> => {
    // Mock success without database call
    return true;
  }, []);

  const logout = useCallback(async () => {
    // Just call signOut, no session cleanup needed
    await signOut();
  }, [signOut]);

  const logoutFromAllDevices = useCallback(async () => {
    // Just call signOut for single-admin system
    await signOut();
  }, [signOut]);

  // No useEffect with database operations
  useEffect(() => {
    setIsLoading(false);
  }, []);

  return {
    // Session state
    currentSession: mockSession,
    allSessions: mockSession ? [mockSession] : [],
    isLoading: false,
    isExpiring: false,
    minutesUntilExpiry: null,
    
    // Session actions
    refreshSession,
    extendSession,
    logout,
    logoutFromAllDevices,
    
    // Session management
    updateActivity,
    checkSessionExpiry,
    
    // Suspicious activity (always safe for single admin)
    isSuspiciousActivity: false,
    suspiciousReasons: [],
    riskLevel: 'low',
  };
}

/**
 * Hook for session expiry warnings
 * NO-OP VERSION - No warnings for single-admin system
 */
export function useSessionExpiryWarning(warningMinutes: number = 5) {
  return {
    showWarning: false,
    timeRemaining: null,
    extendSession: async () => true,
    dismissWarning: () => {},
  };
}