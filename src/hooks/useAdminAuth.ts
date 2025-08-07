import { useEffect, useState } from 'react';
import { useAuth } from '@/contexts/AuthContext';
import { supabase } from '@/lib/supabase-client';
import { useNavigate } from 'react-router-dom';
import { toast } from 'sonner';
import { getAdminSecurityStatus, isAccountLocked } from '@/lib/services/twoFactor';
import type { AdminUserSecurity } from '@/lib/services/twoFactor';
import { useSessionManager } from '@/hooks/useSessionManager';

interface AdminUser {
  id: string;
  user_id: string;
  role: 'super_admin' | 'admin' | 'manager';
  permissions: string[];
  created_at: string;
  is_active: boolean;
  two_factor_enabled?: boolean;
  failed_login_attempts?: number;
  account_locked_until?: string;
  last_login_at?: string;
}

export function useAdminAuth() {
  const { user, adminSession, twoFactorRequired, loading: authLoading } = useAuth();
  const { currentSession, isSuspiciousActivity, riskLevel } = useSessionManager();
  const navigate = useNavigate();
  const [isAdmin, setIsAdmin] = useState(false);
  const [adminUser, setAdminUser] = useState<AdminUser | null>(null);
  const [securityStatus, setSecurityStatus] = useState<AdminUserSecurity | null>(null);
  const [loading, setLoading] = useState(true);
  const [accountLocked, setAccountLocked] = useState(false);

  useEffect(() => {
    checkAdminStatus();
  }, [user, adminSession]);

  const checkAdminStatus = async () => {
    if (!user) {
      setIsAdmin(false);
      setAdminUser(null);
      setSecurityStatus(null);
      setAccountLocked(false);
      setLoading(false);
      return;
    }

    try {
      setLoading(true);
      
      // If 2FA is required, don't proceed with admin checks
      if (twoFactorRequired) {
        setIsAdmin(false);
        setAdminUser(null);
        setLoading(false);
        return;
      }

      // Get admin user data
      const { data: adminData, error } = await supabase
        .from('admin_users')
        .select(`
          *,
          two_factor_enabled,
          failed_login_attempts,
          account_locked_until,
          last_login_at
        `)
        .eq('user_id', user.id)
        .eq('is_active', true)
        .single();

      if (error || !adminData) {
        console.log('User is not an admin');
        setIsAdmin(false);
        setAdminUser(null);
        setSecurityStatus(null);
        
        // Only redirect if we're not already on the login page
        if (window.location.pathname !== '/login' && window.location.pathname !== '/auth/callback') {
          toast.error('Unauthorized: Admin access required');
          navigate('/login');
        }
        return;
      }

      // Check if account is locked
      const securityResult = await getAdminSecurityStatus(user.id);
      if (securityResult.success && securityResult.data) {
        setSecurityStatus(securityResult.data);
        const locked = isAccountLocked(securityResult.data);
        setAccountLocked(locked);
        
        if (locked) {
          const lockUntil = new Date(securityResult.data.account_locked_until!);
          toast.error('Account Locked', {
            description: `Your account is locked until ${lockUntil.toLocaleString()} due to repeated failed login attempts.`,
          });
          navigate('/login');
          return;
        }
      }

      // Check if admin session exists for enhanced security
      if (!adminSession && !authLoading) {
        console.log('No valid admin session found');
        setIsAdmin(false);
        setAdminUser(null);
        toast.error('Session expired or invalid. Please log in again.');
        navigate('/login');
        return;
      }

      console.log('Admin user verified:', adminData);
      setIsAdmin(true);
      setAdminUser(adminData);
      
      // Show security warnings if needed
      if (isSuspiciousActivity && riskLevel === 'high') {
        toast.warning('Security Alert', {
          description: 'Suspicious activity detected on your account. Please verify your recent activity.',
        });
      }
      
    } catch (error) {
      console.error('Error checking admin status:', error);
      setIsAdmin(false);
      setAdminUser(null);
      setSecurityStatus(null);
    } finally {
      setLoading(false);
    }
  };

  const hasPermission = (permission: string): boolean => {
    if (!adminUser) return false;
    if (adminUser.role === 'super_admin') return true; // Super admins have all permissions
    return adminUser.permissions.includes(permission);
  };

  const requirePermission = (permission: string): void => {
    if (!hasPermission(permission)) {
      toast.error(`Insufficient permissions: ${permission} required`);
      navigate('/admin');
    }
  };

  const isSecure = (): boolean => {
    return !!adminSession && !accountLocked && !twoFactorRequired;
  };

  const getSecurityScore = (): number => {
    let score = 0;
    
    if (adminUser?.two_factor_enabled) score += 30;
    if (adminSession?.remember_me === false) score += 20; // Session-only login is more secure
    if (!isSuspiciousActivity) score += 25;
    if (currentSession && new Date(currentSession.last_activity_at) > new Date(Date.now() - 5 * 60 * 1000)) score += 15; // Recent activity
    if (securityStatus && securityStatus.failed_login_attempts === 0) score += 10;
    
    return Math.min(100, score);
  };

  const getAccountStatus = (): 'active' | 'locked' | 'requires_2fa' | 'suspicious' => {
    if (accountLocked) return 'locked';
    if (twoFactorRequired) return 'requires_2fa';
    if (isSuspiciousActivity && riskLevel === 'high') return 'suspicious';
    return 'active';
  };

  const refreshSecurityStatus = async (): Promise<void> => {
    if (!user) return;
    
    try {
      const result = await getAdminSecurityStatus(user.id);
      if (result.success && result.data) {
        setSecurityStatus(result.data);
        setAccountLocked(isAccountLocked(result.data));
      }
    } catch (error) {
      console.error('Error refreshing security status:', error);
    }
  };

  return {
    isAdmin,
    adminUser,
    adminSession,
    securityStatus,
    loading,
    accountLocked,
    twoFactorRequired,
    isSuspiciousActivity,
    riskLevel,
    hasPermission,
    requirePermission,
    checkAdminStatus,
    isSecure,
    getSecurityScore,
    getAccountStatus,
    refreshSecurityStatus,
  };
}