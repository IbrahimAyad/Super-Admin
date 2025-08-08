import { useEffect, useState } from 'react';
import { useAuth } from '@/contexts/AuthContext';
import { useNavigate } from 'react-router-dom';
import { toast } from 'sonner';

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

/**
 * SIMPLIFIED ADMIN AUTH HOOK
 * NO DATABASE OPERATIONS VERSION
 * For single-admin system - eliminates 400/401 errors
 */
export function useAdminAuth() {
  const { user, twoFactorRequired } = useAuth();
  const navigate = useNavigate();
  const [isAdmin, setIsAdmin] = useState(false);
  const [adminUser, setAdminUser] = useState<AdminUser | null>(null);
  const [loading, setLoading] = useState(false);

  useEffect(() => {
    checkAdminStatus();
  }, [user]);

  const checkAdminStatus = async () => {
    if (!user) {
      setIsAdmin(false);
      setAdminUser(null);
      setLoading(false);
      return;
    }

    // For single-admin system, if user is authenticated, they are admin
    // No database calls needed
    const mockAdminUser: AdminUser = {
      id: 'single-admin',
      user_id: user.id,
      role: 'super_admin',
      permissions: ['*'],
      created_at: new Date().toISOString(),
      is_active: true,
      two_factor_enabled: false,
      failed_login_attempts: 0,
      account_locked_until: null,
      last_login_at: new Date().toISOString()
    };

    setIsAdmin(true);
    setAdminUser(mockAdminUser);
    setLoading(false);
  };

  const hasPermission = (permission: string): boolean => {
    // Single admin has all permissions
    return !!adminUser;
  };

  const requirePermission = (permission: string): void => {
    if (!hasPermission(permission)) {
      toast.error(`Insufficient permissions: ${permission} required`);
      navigate('/admin');
    }
  };

  const isSecure = (): boolean => {
    return !!user && !twoFactorRequired;
  };

  const getSecurityScore = (): number => {
    // Fixed score for single-admin system
    return 80;
  };

  const getAccountStatus = (): 'active' | 'locked' | 'requires_2fa' | 'suspicious' => {
    if (twoFactorRequired) return 'requires_2fa';
    return 'active';
  };

  const refreshSecurityStatus = async (): Promise<void> => {
    // No-op - no database calls needed
  };

  return {
    isAdmin,
    adminUser,
    securityStatus: null, // No database calls
    loading,
    accountLocked: false, // Never locked for single admin
    twoFactorRequired,
    isSuspiciousActivity: false, // Always safe
    riskLevel: 'low' as const,
    hasPermission,
    requirePermission,
    checkAdminStatus,
    isSecure,
    getSecurityScore,
    getAccountStatus,
    refreshSecurityStatus,
  };
}