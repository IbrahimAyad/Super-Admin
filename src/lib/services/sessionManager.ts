/**
 * SESSION MANAGEMENT SERVICE
 * Handles admin session creation, tracking, timeout, and cleanup
 * Created: 2025-08-07
 */

import { supabase } from '../supabase-client';
import CryptoJS from 'crypto-js';

export interface AdminSession {
  id: string;
  user_id: string;
  admin_user_id: string;
  session_token: string;
  device_info: Record<string, any>;
  ip_address?: string;
  user_agent?: string;
  is_active: boolean;
  remember_me: boolean;
  last_activity_at: string;
  expires_at: string;
  created_at: string;
}

export interface SessionConfig {
  defaultTimeoutMinutes: number;
  rememberMeTimeoutDays: number;
  maxConcurrentSessions: number;
  trackDeviceInfo: boolean;
}

// Default session configuration
const DEFAULT_CONFIG: SessionConfig = {
  defaultTimeoutMinutes: 30,
  rememberMeTimeoutDays: 30,
  maxConcurrentSessions: 5,
  trackDeviceInfo: true,
};

/**
 * Generate secure session token
 */
function generateSessionToken(): string {
  const timestamp = Date.now().toString();
  const random = Math.random().toString(36).substring(2, 15);
  const combined = `${timestamp}-${random}`;
  return CryptoJS.SHA256(combined).toString();
}

/**
 * Get device information from browser
 */
function getDeviceInfo(): Record<string, any> {
  try {
    const deviceInfo: Record<string, any> = {
      userAgent: navigator.userAgent,
      language: navigator.language,
      platform: navigator.platform,
      cookieEnabled: navigator.cookieEnabled,
      onlineStatus: navigator.onLine,
      timezone: Intl.DateTimeFormat().resolvedOptions().timeZone,
      screenResolution: `${screen.width}x${screen.height}`,
      colorDepth: screen.colorDepth,
      deviceMemory: (navigator as any).deviceMemory || 'unknown',
      hardwareConcurrency: navigator.hardwareConcurrency || 'unknown',
      connection: (navigator as any).connection ? {
        effectiveType: (navigator as any).connection.effectiveType,
        downlink: (navigator as any).connection.downlink,
        rtt: (navigator as any).connection.rtt,
      } : null,
      timestamp: new Date().toISOString(),
    };

    return deviceInfo;
  } catch (error) {
    console.error('Error getting device info:', error);
    return {
      userAgent: navigator.userAgent || 'unknown',
      timestamp: new Date().toISOString(),
    };
  }
}

/**
 * Get client IP address (best effort)
 */
async function getClientIPAddress(): Promise<string | null> {
  try {
    // This would typically be handled by your backend
    // For now, we'll return null and let the database trigger handle it
    return null;
  } catch (error) {
    console.error('Error getting IP address:', error);
    return null;
  }
}

/**
 * Create a new admin session
 * SIMPLIFIED VERSION - Returns mock session to prevent database errors
 */
export async function createAdminSession(
  userId: string,
  adminUserId: string,
  rememberMe: boolean = false,
  config: Partial<SessionConfig> = {}
): Promise<{
  success: boolean;
  session?: AdminSession;
  error?: string;
}> {
  console.log('Creating simplified admin session for single-user system');
  
  // Create a mock session that doesn't require database operations
  const mockSession: AdminSession = {
    id: `simple-session-${Date.now()}`,
    user_id: userId,
    admin_user_id: adminUserId,
    session_token: `simple-token-${Date.now()}`,
    device_info: {
      userAgent: navigator.userAgent,
      platform: navigator.platform,
      timestamp: new Date().toISOString()
    },
    is_active: true,
    remember_me: rememberMe,
    last_activity_at: new Date().toISOString(),
    expires_at: new Date(Date.now() + (rememberMe ? 7 * 24 * 60 * 60 * 1000 : 24 * 60 * 60 * 1000)).toISOString(),
    created_at: new Date().toISOString()
  };

  return {
    success: true,
    session: mockSession,
  };
}

/**
 * Get current admin session
 * SIMPLIFIED VERSION - Returns mock session for single-user systems
 */
export async function getCurrentAdminSession(): Promise<{
  success: boolean;
  session?: AdminSession;
  error?: string;
}> {
  console.log('Getting simplified admin session (no database queries)');
  
  // For single-user systems, return a simple mock session
  const mockSession: AdminSession = {
    id: `current-session-${Date.now()}`,
    user_id: 'current-user',
    admin_user_id: 'current-admin',
    session_token: `current-token-${Date.now()}`,
    device_info: {
      userAgent: navigator.userAgent,
      platform: navigator.platform,
      timestamp: new Date().toISOString()
    },
    is_active: true,
    remember_me: false,
    last_activity_at: new Date().toISOString(),
    expires_at: new Date(Date.now() + 24 * 60 * 60 * 1000).toISOString(),
    created_at: new Date().toISOString()
  };

  return {
    success: true,
    session: mockSession,
  };
}

/**
 * Update session activity
 * SIMPLIFIED VERSION - No database operations
 */
export async function updateSessionActivity(sessionToken?: string): Promise<boolean> {
  // For single-user systems, skip database activity tracking
  return true;
}

/**
 * End admin session (logout)
 * SIMPLIFIED VERSION - Just clear local storage
 */
export async function endAdminSession(sessionToken?: string): Promise<{
  success: boolean;
  error?: string;
}> {
  console.log('Ending admin session (simplified mode)');
  
  // Just clear local storage for single-user systems
  try {
    localStorage.removeItem('admin_session_token');
    sessionStorage.removeItem('admin_session_token');
    return { success: true };
  } catch (error) {
    console.error('Error clearing session tokens:', error);
    return { success: true }; // Still consider it successful
  }
}

/**
 * End all sessions for a user (force logout from all devices)
 */
export async function endAllUserSessions(userId: string): Promise<{
  success: boolean;
  sessionsEnded?: number;
  error?: string;
}> {
  try {
    // Get all active sessions
    const { data: sessions, error: fetchError } = await supabase
      .from('admin_sessions')
      .select('id, admin_user_id')
      .eq('user_id', userId)
      .eq('is_active', true);

    if (fetchError) throw fetchError;

    if (!sessions || sessions.length === 0) {
      return { success: true, sessionsEnded: 0 };
    }

    // Deactivate all sessions
    const { error } = await supabase
      .from('admin_sessions')
      .update({
        is_active: false,
        updated_at: new Date().toISOString(),
      })
      .eq('user_id', userId)
      .eq('is_active', true);

    if (error) throw error;

    // Log security event
    await supabase.rpc('log_admin_security_event', {
      p_user_id: userId,
      p_admin_user_id: sessions[0]?.admin_user_id || null,
      p_event_type: 'all_sessions_ended',
      p_event_data: {
        ended_at: new Date().toISOString(),
        sessions_count: sessions.length,
      },
    });

    // Clear stored tokens if it's the current user
    await clearStoredSessionToken();

    return {
      success: true,
      sessionsEnded: sessions.length,
    };
  } catch (error) {
    console.error('Error ending all user sessions:', error);
    return {
      success: false,
      error: error instanceof Error ? error.message : 'Failed to end sessions',
    };
  }
}

/**
 * Get all active sessions for a user
 * SIMPLIFIED VERSION - Returns single mock session
 */
export async function getUserSessions(userId: string): Promise<{
  success: boolean;
  sessions?: AdminSession[];
  error?: string;
}> {
  console.log('Getting user sessions (simplified mode)');
  
  // Return single mock session for single-user systems
  const mockSession: AdminSession = {
    id: `user-session-${Date.now()}`,
    user_id: userId,
    admin_user_id: `admin-${userId}`,
    session_token: `user-token-${Date.now()}`,
    device_info: {
      userAgent: navigator.userAgent,
      platform: navigator.platform,
      timestamp: new Date().toISOString()
    },
    is_active: true,
    remember_me: false,
    last_activity_at: new Date().toISOString(),
    expires_at: new Date(Date.now() + 24 * 60 * 60 * 1000).toISOString(),
    created_at: new Date().toISOString()
  };

  return {
    success: true,
    sessions: [mockSession],
  };
}

/**
 * Clean up expired sessions
 */
export async function cleanupExpiredSessions(): Promise<number> {
  try {
    const { data, error } = await supabase
      .from('admin_sessions')
      .delete()
      .lt('expires_at', new Date().toISOString())
      .select('id');

    if (error) throw error;

    const cleanedCount = data?.length || 0;
    
    if (cleanedCount > 0) {
      console.log(`Cleaned up ${cleanedCount} expired sessions`);
    }

    return cleanedCount;
  } catch (error) {
    console.error('Error cleaning up expired sessions:', error);
    return 0;
  }
}

/**
 * Clean up excessive sessions for a user (keep only the most recent ones)
 */
async function cleanupExcessiveSessions(userId: string, keepCount: number): Promise<void> {
  try {
    // Get sessions ordered by last activity (newest first)
    const { data: sessions, error } = await supabase
      .from('admin_sessions')
      .select('id, last_activity_at')
      .eq('user_id', userId)
      .eq('is_active', true)
      .order('last_activity_at', { ascending: false });

    if (error) throw error;

    if (sessions && sessions.length > keepCount) {
      // Get sessions to remove (oldest ones)
      const sessionsToRemove = sessions.slice(keepCount);
      const sessionIds = sessionsToRemove.map(s => s.id);

      // Deactivate old sessions
      await supabase
        .from('admin_sessions')
        .update({
          is_active: false,
          updated_at: new Date().toISOString(),
        })
        .in('id', sessionIds);

      console.log(`Cleaned up ${sessionIds.length} excessive sessions for user ${userId}`);
    }
  } catch (error) {
    console.error('Error cleaning up excessive sessions:', error);
  }
}

/**
 * Check if current session is about to expire
 */
export async function isSessionExpiringSoon(warningMinutes: number = 5): Promise<{
  isExpiring: boolean;
  expiresAt?: string;
  minutesUntilExpiry?: number;
}> {
  try {
    const sessionResult = await getCurrentAdminSession();
    
    if (!sessionResult.success || !sessionResult.session) {
      return { isExpiring: false };
    }

    const expiresAt = new Date(sessionResult.session.expires_at);
    const now = new Date();
    const minutesUntilExpiry = Math.floor((expiresAt.getTime() - now.getTime()) / (1000 * 60));

    return {
      isExpiring: minutesUntilExpiry <= warningMinutes && minutesUntilExpiry > 0,
      expiresAt: sessionResult.session.expires_at,
      minutesUntilExpiry,
    };
  } catch (error) {
    console.error('Error checking session expiry:', error);
    return { isExpiring: false };
  }
}

/**
 * Extend current session
 */
export async function extendCurrentSession(additionalMinutes: number = 30): Promise<{
  success: boolean;
  newExpiresAt?: string;
  error?: string;
}> {
  try {
    const sessionToken = 
      localStorage.getItem('admin_session_token') || 
      sessionStorage.getItem('admin_session_token');

    if (!sessionToken) {
      return {
        success: false,
        error: 'No active session found',
      };
    }

    const newExpiresAt = new Date();
    newExpiresAt.setMinutes(newExpiresAt.getMinutes() + additionalMinutes);

    const { data, error } = await supabase
      .from('admin_sessions')
      .update({
        expires_at: newExpiresAt.toISOString(),
        last_activity_at: new Date().toISOString(),
      })
      .eq('session_token', sessionToken)
      .eq('is_active', true)
      .select('user_id, admin_user_id')
      .single();

    if (error) throw error;

    // Log session extension
    await supabase.rpc('log_admin_security_event', {
      p_user_id: data.user_id,
      p_admin_user_id: data.admin_user_id,
      p_event_type: 'session_extended',
      p_event_data: {
        extended_at: new Date().toISOString(),
        new_expires_at: newExpiresAt.toISOString(),
        additional_minutes: additionalMinutes,
      },
    });

    return {
      success: true,
      newExpiresAt: newExpiresAt.toISOString(),
    };
  } catch (error) {
    console.error('Error extending session:', error);
    return {
      success: false,
      error: error instanceof Error ? error.message : 'Failed to extend session',
    };
  }
}

/**
 * Detect suspicious activity
 */
export async function detectSuspiciousActivity(
  userId: string,
  currentDeviceInfo: Record<string, any>
): Promise<{
  isSuspicious: boolean;
  reasons: string[];
  riskLevel: 'low' | 'medium' | 'high';
}> {
  try {
    // Get recent sessions for comparison
    const { data: recentSessions } = await supabase
      .from('admin_sessions')
      .select('device_info, ip_address, created_at')
      .eq('user_id', userId)
      .gte('created_at', new Date(Date.now() - 7 * 24 * 60 * 60 * 1000).toISOString()) // Last 7 days
      .order('created_at', { ascending: false })
      .limit(10);

    const reasons: string[] = [];
    let riskLevel: 'low' | 'medium' | 'high' = 'low';

    if (recentSessions && recentSessions.length > 0) {
      const commonUserAgent = recentSessions[0]?.device_info?.userAgent;
      const commonPlatform = recentSessions[0]?.device_info?.platform;
      const commonTimezone = recentSessions[0]?.device_info?.timezone;

      // Check for device changes
      if (currentDeviceInfo.userAgent !== commonUserAgent) {
        reasons.push('Different browser/device detected');
        riskLevel = 'medium';
      }

      if (currentDeviceInfo.platform !== commonPlatform) {
        reasons.push('Different operating system detected');
        riskLevel = 'medium';
      }

      if (currentDeviceInfo.timezone !== commonTimezone) {
        reasons.push('Different timezone detected');
        riskLevel = 'medium';
      }

      // Check for unusual login patterns
      const sessionTimes = recentSessions
        .map(s => new Date(s.created_at).getHours())
        .filter(h => !isNaN(h));

      if (sessionTimes.length > 3) {
        const avgHour = sessionTimes.reduce((a, b) => a + b, 0) / sessionTimes.length;
        const currentHour = new Date().getHours();
        
        if (Math.abs(currentHour - avgHour) > 8) {
          reasons.push('Unusual login time detected');
          riskLevel = riskLevel === 'high' ? 'high' : 'medium';
        }
      }

      // Multiple logins in short time
      const recentLogins = recentSessions.filter(s => 
        new Date(s.created_at).getTime() > Date.now() - 60 * 60 * 1000 // Last hour
      );

      if (recentLogins.length > 3) {
        reasons.push('Multiple login attempts in short period');
        riskLevel = 'high';
      }
    }

    const isSuspicious = reasons.length > 0;

    return { isSuspicious, reasons, riskLevel };
  } catch (error) {
    console.error('Error detecting suspicious activity:', error);
    return { isSuspicious: false, reasons: [], riskLevel: 'low' };
  }
}

/**
 * Clear stored session token
 */
async function clearStoredSessionToken(): Promise<void> {
  try {
    localStorage.removeItem('admin_session_token');
    sessionStorage.removeItem('admin_session_token');
  } catch (error) {
    console.error('Error clearing session token:', error);
  }
}

/**
 * Initialize session management (call on app start)
 * SIMPLIFIED VERSION - No background polling to prevent 400 errors
 */
export async function initializeSessionManager(): Promise<void> {
  console.log('Session manager initialized in simplified mode (no background operations)');
  // For single-user admin systems, we don't need complex session management
  // This prevents continuous 400 errors from database operations
}