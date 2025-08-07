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
  try {
    const finalConfig = { ...DEFAULT_CONFIG, ...config };
    const sessionToken = generateSessionToken();
    const deviceInfo = finalConfig.trackDeviceInfo ? getDeviceInfo() : {};
    const ipAddress = await getClientIPAddress();

    // Calculate expiration time
    const expiresAt = new Date();
    if (rememberMe) {
      expiresAt.setDate(expiresAt.getDate() + finalConfig.rememberMeTimeoutDays);
    } else {
      expiresAt.setMinutes(expiresAt.getMinutes() + finalConfig.defaultTimeoutMinutes);
    }

    // Check and cleanup old sessions if we're at the limit
    await cleanupExcessiveSessions(userId, finalConfig.maxConcurrentSessions - 1);

    // Create new session
    const sessionData = {
      user_id: userId,
      admin_user_id: adminUserId,
      session_token: sessionToken,
      device_info: deviceInfo,
      ip_address: ipAddress,
      user_agent: navigator.userAgent,
      is_active: true,
      remember_me: rememberMe,
      expires_at: expiresAt.toISOString(),
    };

    const { data, error } = await supabase
      .from('admin_sessions')
      .insert(sessionData)
      .select()
      .single();

    if (error) throw error;

    // Log session creation
    await supabase.rpc('log_admin_security_event', {
      p_user_id: userId,
      p_admin_user_id: adminUserId,
      p_event_type: 'login_success',
      p_event_data: {
        session_id: data.id,
        remember_me: rememberMe,
        device_info: deviceInfo,
        created_at: new Date().toISOString(),
      },
      p_ip_address: ipAddress,
      p_user_agent: navigator.userAgent,
    });

    // Store session token in localStorage/sessionStorage
    const storage = rememberMe ? localStorage : sessionStorage;
    storage.setItem('admin_session_token', sessionToken);

    return {
      success: true,
      session: data as AdminSession,
    };
  } catch (error) {
    console.error('Error creating admin session:', error);
    return {
      success: false,
      error: error instanceof Error ? error.message : 'Failed to create session',
    };
  }
}

/**
 * Get current admin session
 */
export async function getCurrentAdminSession(): Promise<{
  success: boolean;
  session?: AdminSession;
  error?: string;
}> {
  try {
    const sessionToken = 
      localStorage.getItem('admin_session_token') || 
      sessionStorage.getItem('admin_session_token');

    if (!sessionToken) {
      return {
        success: false,
        error: 'No session token found',
      };
    }

    const { data, error } = await supabase
      .from('admin_sessions')
      .select('*')
      .eq('session_token', sessionToken)
      .eq('is_active', true)
      .gte('expires_at', new Date().toISOString())
      .single();

    if (error) {
      if (error.code === 'PGRST116') {
        // Session not found or expired
        await clearStoredSessionToken();
        return {
          success: false,
          error: 'Session not found or expired',
        };
      }
      throw error;
    }

    return {
      success: true,
      session: data as AdminSession,
    };
  } catch (error) {
    console.error('Error getting current session:', error);
    return {
      success: false,
      error: error instanceof Error ? error.message : 'Failed to get session',
    };
  }
}

/**
 * Update session activity
 */
export async function updateSessionActivity(sessionToken?: string): Promise<boolean> {
  try {
    const token = sessionToken || 
      localStorage.getItem('admin_session_token') || 
      sessionStorage.getItem('admin_session_token');

    if (!token) return false;

    const result = await supabase.rpc('update_session_activity', {
      session_token: token,
    });

    return result.data === true;
  } catch (error) {
    console.error('Error updating session activity:', error);
    return false;
  }
}

/**
 * End admin session (logout)
 */
export async function endAdminSession(sessionToken?: string): Promise<{
  success: boolean;
  error?: string;
}> {
  try {
    const token = sessionToken || 
      localStorage.getItem('admin_session_token') || 
      sessionStorage.getItem('admin_session_token');

    if (!token) {
      return { success: true }; // Already logged out
    }

    // Get session info for logging
    const { data: session } = await supabase
      .from('admin_sessions')
      .select('user_id, admin_user_id, id')
      .eq('session_token', token)
      .single();

    // Deactivate session
    const { error } = await supabase
      .from('admin_sessions')
      .update({
        is_active: false,
        updated_at: new Date().toISOString(),
      })
      .eq('session_token', token);

    if (error) throw error;

    // Log logout event
    if (session) {
      await supabase.rpc('log_admin_security_event', {
        p_user_id: session.user_id,
        p_admin_user_id: session.admin_user_id,
        p_event_type: 'logout',
        p_event_data: {
          session_id: session.id,
          logged_out_at: new Date().toISOString(),
        },
      });
    }

    // Clear stored tokens
    await clearStoredSessionToken();

    return { success: true };
  } catch (error) {
    console.error('Error ending admin session:', error);
    return {
      success: false,
      error: error instanceof Error ? error.message : 'Failed to end session',
    };
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
 */
export async function getUserSessions(userId: string): Promise<{
  success: boolean;
  sessions?: AdminSession[];
  error?: string;
}> {
  try {
    const { data, error } = await supabase
      .from('admin_sessions')
      .select('*')
      .eq('user_id', userId)
      .eq('is_active', true)
      .gte('expires_at', new Date().toISOString())
      .order('last_activity_at', { ascending: false });

    if (error) throw error;

    return {
      success: true,
      sessions: data as AdminSession[],
    };
  } catch (error) {
    console.error('Error getting user sessions:', error);
    return {
      success: false,
      error: error instanceof Error ? error.message : 'Failed to get sessions',
    };
  }
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
 */
export async function initializeSessionManager(): Promise<void> {
  try {
    // Clean up expired sessions periodically
    await cleanupExpiredSessions();
    
    // Set up periodic cleanup (every 15 minutes)
    setInterval(async () => {
      await cleanupExpiredSessions();
    }, 15 * 60 * 1000);

    // Set up activity tracking
    const updateActivity = () => updateSessionActivity();
    
    // Update activity on user interaction
    const events = ['click', 'keypress', 'scroll', 'mousemove'];
    events.forEach(event => {
      document.addEventListener(event, updateActivity, { passive: true });
    });

    // Check for session expiry warning
    setInterval(async () => {
      const expiryCheck = await isSessionExpiringSoon();
      if (expiryCheck.isExpiring) {
        // Emit custom event for UI to handle
        const event = new CustomEvent('sessionExpiring', {
          detail: {
            expiresAt: expiryCheck.expiresAt,
            minutesUntilExpiry: expiryCheck.minutesUntilExpiry,
          },
        });
        window.dispatchEvent(event);
      }
    }, 60 * 1000); // Check every minute

  } catch (error) {
    console.error('Error initializing session manager:', error);
  }
}