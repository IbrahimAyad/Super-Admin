/**
 * SESSION MANAGER HOOK
 * React hook for managing admin sessions with real-time tracking
 * Created: 2025-08-07
 */

import { useState, useEffect, useCallback, useRef } from 'react';
import { useAuth } from '@/contexts/AuthContext';
import {
  AdminSession,
  getCurrentAdminSession,
  updateSessionActivity,
  endAdminSession,
  endAllUserSessions,
  getUserSessions,
  isSessionExpiringSoon,
  extendCurrentSession,
  detectSuspiciousActivity,
  initializeSessionManager,
} from '@/lib/services/sessionManager';
import { toast } from 'sonner';

export interface UseSessionManagerReturn {
  // Session state
  currentSession: AdminSession | null;
  allSessions: AdminSession[];
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
  const { user } = useAuth();
  const [currentSession, setCurrentSession] = useState<AdminSession | null>(null);
  const [allSessions, setAllSessions] = useState<AdminSession[]>([]);
  const [isLoading, setIsLoading] = useState(true);
  const [isExpiring, setIsExpiring] = useState(false);
  const [minutesUntilExpiry, setMinutesUntilExpiry] = useState<number | null>(null);
  const [isSuspiciousActivity, setIsSuspiciousActivity] = useState(false);
  const [suspiciousReasons, setSuspiciousReasons] = useState<string[]>([]);
  const [riskLevel, setRiskLevel] = useState<'low' | 'medium' | 'high'>('low');
  
  // Refs to prevent memory leaks
  const sessionCheckInterval = useRef<NodeJS.Timeout | null>(null);
  const activityUpdateTimeout = useRef<NodeJS.Timeout | null>(null);
  const isInitialized = useRef(false);

  // Initialize session manager
  useEffect(() => {
    if (!isInitialized.current) {
      initializeSessionManager();
      isInitialized.current = true;
    }
  }, []);

  // Load current session
  const refreshSession = useCallback(async () => {
    if (!user) {
      setCurrentSession(null);
      setIsLoading(false);
      return;
    }

    try {
      setIsLoading(true);
      const result = await getCurrentAdminSession();
      
      if (result.success && result.session) {
        setCurrentSession(result.session);
        
        // Check for suspicious activity
        const deviceInfo = {
          userAgent: navigator.userAgent,
          platform: navigator.platform,
          language: navigator.language,
          timezone: Intl.DateTimeFormat().resolvedOptions().timeZone,
        };
        
        // Only check for suspicious activity if session management is working
        try {
          const suspiciousCheck = await detectSuspiciousActivity(user.id, deviceInfo);
          setIsSuspiciousActivity(suspiciousCheck.isSuspicious);
          setSuspiciousReasons(suspiciousCheck.reasons);
          setRiskLevel(suspiciousCheck.riskLevel);
          
          if (suspiciousCheck.isSuspicious && suspiciousCheck.riskLevel === 'high') {
            toast.warning('Suspicious activity detected on your account', {
              description: 'Please verify your recent login activity.',
            });
          }
        } catch (suspiciousError) {
          console.warn('Could not check for suspicious activity:', suspiciousError);
          // Set safe defaults
          setIsSuspiciousActivity(false);
          setSuspiciousReasons([]);
          setRiskLevel('low');
        }
      } else {
        setCurrentSession(null);
      }
    } catch (error) {
      console.error('Error refreshing session:', error);
      setCurrentSession(null);
    } finally {
      setIsLoading(false);
    }
  }, [user]);

  // Load all user sessions
  const loadAllSessions = useCallback(async () => {
    if (!user) {
      setAllSessions([]);
      return;
    }

    try {
      const result = await getUserSessions(user.id);
      if (result.success && result.sessions) {
        setAllSessions(result.sessions);
      }
    } catch (error) {
      console.error('Error loading all sessions:', error);
    }
  }, [user]);

  // Check if session is expiring
  const checkSessionExpiry = useCallback(async () => {
    if (!currentSession) {
      setIsExpiring(false);
      setMinutesUntilExpiry(null);
      return;
    }

    try {
      const expiryCheck = await isSessionExpiringSoon(5); // 5 minutes warning
      setIsExpiring(expiryCheck.isExpiring);
      setMinutesUntilExpiry(expiryCheck.minutesUntilExpiry || null);
      
      if (expiryCheck.isExpiring && expiryCheck.minutesUntilExpiry) {
        toast.warning('Session Expiring Soon', {
          description: `Your session will expire in ${expiryCheck.minutesUntilExpiry} minutes.`,
          action: {
            label: 'Extend Session',
            onClick: () => extendSession(),
          },
        });
      }
    } catch (error) {
      console.error('Error checking session expiry:', error);
    }
  }, [currentSession]);

  // Update session activity (throttled)
  const updateActivity = useCallback(async () => {
    if (!currentSession) return;

    // Clear existing timeout
    if (activityUpdateTimeout.current) {
      clearTimeout(activityUpdateTimeout.current);
    }

    // Throttle activity updates to prevent excessive API calls
    activityUpdateTimeout.current = setTimeout(async () => {
      try {
        await updateSessionActivity();
      } catch (error) {
        console.error('Error updating session activity:', error);
      }
    }, 30000); // Update every 30 seconds at most
  }, [currentSession]);

  // Extend current session
  const extendSession = useCallback(async (minutes: number = 30): Promise<boolean> => {
    try {
      const result = await extendCurrentSession(minutes);
      
      if (result.success) {
        toast.success('Session Extended', {
          description: `Your session has been extended by ${minutes} minutes.`,
        });
        await refreshSession(); // Refresh to get updated expiry time
        return true;
      } else {
        toast.error('Failed to extend session', {
          description: result.error,
        });
        return false;
      }
    } catch (error) {
      console.error('Error extending session:', error);
      toast.error('Failed to extend session');
      return false;
    }
  }, [refreshSession]);

  // Logout from current device
  const logout = useCallback(async () => {
    try {
      const result = await endAdminSession();
      
      if (result.success) {
        setCurrentSession(null);
        toast.success('Logged out successfully');
      } else {
        toast.error('Logout failed', {
          description: result.error,
        });
      }
    } catch (error) {
      console.error('Error during logout:', error);
      toast.error('Logout failed');
    }
  }, []);

  // Logout from all devices
  const logoutFromAllDevices = useCallback(async () => {
    if (!user) return;

    try {
      const result = await endAllUserSessions(user.id);
      
      if (result.success) {
        setCurrentSession(null);
        setAllSessions([]);
        toast.success('Logged out from all devices', {
          description: `Ended ${result.sessionsEnded} active sessions.`,
        });
      } else {
        toast.error('Failed to logout from all devices', {
          description: result.error,
        });
      }
    } catch (error) {
      console.error('Error logging out from all devices:', error);
      toast.error('Failed to logout from all devices');
    }
  }, [user]);

  // Set up session monitoring
  useEffect(() => {
    if (user) {
      refreshSession();
      loadAllSessions();

      // Check session expiry every minute
      sessionCheckInterval.current = setInterval(() => {
        checkSessionExpiry();
      }, 60000);

      return () => {
        if (sessionCheckInterval.current) {
          clearInterval(sessionCheckInterval.current);
        }
      };
    } else {
      setCurrentSession(null);
      setAllSessions([]);
      setIsExpiring(false);
      setMinutesUntilExpiry(null);
    }
  }, [user, refreshSession, loadAllSessions, checkSessionExpiry]);

  // Listen for session expiring events
  useEffect(() => {
    const handleSessionExpiring = (event: CustomEvent) => {
      setIsExpiring(true);
      setMinutesUntilExpiry(event.detail.minutesUntilExpiry);
    };

    window.addEventListener('sessionExpiring', handleSessionExpiring as EventListener);

    return () => {
      window.removeEventListener('sessionExpiring', handleSessionExpiring as EventListener);
    };
  }, []);

  // Set up activity tracking
  useEffect(() => {
    if (!currentSession) return;

    const handleActivity = () => {
      updateActivity();
    };

    // Track user activity
    const events = ['mousedown', 'mousemove', 'keypress', 'scroll', 'touchstart'];
    events.forEach(event => {
      document.addEventListener(event, handleActivity, { passive: true });
    });

    return () => {
      events.forEach(event => {
        document.removeEventListener(event, handleActivity);
      });
    };
  }, [currentSession, updateActivity]);

  // Cleanup timeouts on unmount
  useEffect(() => {
    return () => {
      if (sessionCheckInterval.current) {
        clearInterval(sessionCheckInterval.current);
      }
      if (activityUpdateTimeout.current) {
        clearTimeout(activityUpdateTimeout.current);
      }
    };
  }, []);

  return {
    // Session state
    currentSession,
    allSessions,
    isLoading,
    isExpiring,
    minutesUntilExpiry,
    
    // Session actions
    refreshSession,
    extendSession,
    logout,
    logoutFromAllDevices,
    
    // Session management
    updateActivity,
    checkSessionExpiry,
    
    // Suspicious activity
    isSuspiciousActivity,
    suspiciousReasons,
    riskLevel,
  };
}

/**
 * Hook for session expiry warnings
 */
export function useSessionExpiryWarning(warningMinutes: number = 5) {
  const [showWarning, setShowWarning] = useState(false);
  const [timeRemaining, setTimeRemaining] = useState<number | null>(null);
  
  useEffect(() => {
    const checkExpiry = async () => {
      const expiryCheck = await isSessionExpiringSoon(warningMinutes);
      setShowWarning(expiryCheck.isExpiring);
      setTimeRemaining(expiryCheck.minutesUntilExpiry || null);
    };

    // Check immediately
    checkExpiry();
    
    // Check every 30 seconds
    const interval = setInterval(checkExpiry, 30000);
    
    return () => clearInterval(interval);
  }, [warningMinutes]);

  const extendSession = async (minutes: number = 30): Promise<boolean> => {
    const result = await extendCurrentSession(minutes);
    if (result.success) {
      setShowWarning(false);
      setTimeRemaining(null);
      toast.success(`Session extended by ${minutes} minutes`);
      return true;
    } else {
      toast.error('Failed to extend session');
      return false;
    }
  };

  const dismissWarning = () => {
    setShowWarning(false);
  };

  return {
    showWarning,
    timeRemaining,
    extendSession,
    dismissWarning,
  };
}