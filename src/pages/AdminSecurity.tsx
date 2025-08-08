/**
 * ADMIN SECURITY PAGE
 * Demonstration page for all security features
 * Created: 2025-08-07
 */

import React from 'react';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card';
import { Badge } from '@/components/ui/badge';
import { Alert, AlertDescription } from '@/components/ui/alert';
import { SecuritySettings } from '@/components/admin/SecuritySettings';
import { useAdminAuth } from '@/hooks/useAdminAuth';
import {
  Shield,
  ShieldCheck,
  AlertTriangle,
  Activity,
  Clock,
  Users,
} from 'lucide-react';

export function AdminSecurity() {
  const { 
    isAdmin, 
    adminUser, 
    loading, 
    getSecurityScore,
    getAccountStatus,
    isSuspiciousActivity,
    riskLevel,
  } = useAdminAuth();

  // Simplified session data for single-user system
  const currentSession = { active: true };
  const allSessions = [currentSession]; // Single session for overview
  const isExpiring = false;
  const minutesUntilExpiry = null;

  if (loading) {
    return (
      <div className="container mx-auto py-8">
        <div className="flex items-center justify-center min-h-[400px]">
          <div className="text-center">
            <Shield className="h-12 w-12 animate-pulse mx-auto mb-4" />
            <p className="text-muted-foreground">Loading security dashboard...</p>
          </div>
        </div>
      </div>
    );
  }

  if (!isAdmin || !adminUser) {
    return (
      <div className="container mx-auto py-8">
        <Alert variant="destructive">
          <AlertTriangle className="h-4 w-4" />
          <AlertDescription>
            Access denied. Admin privileges required.
          </AlertDescription>
        </Alert>
      </div>
    );
  }

  const securityScore = getSecurityScore();
  const accountStatus = getAccountStatus();

  return (
    <div className="container mx-auto py-8 space-y-8">
      {/* Page Header */}
      <div className="space-y-2">
        <h1 className="text-3xl font-bold tracking-tight">Security Dashboard</h1>
        <p className="text-muted-foreground">
          Manage your admin account security, authentication, and session monitoring.
        </p>
      </div>

      {/* Security Status Overview */}
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6">
        <Card>
          <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
            <CardTitle className="text-sm font-medium">Security Score</CardTitle>
            <Shield className="h-4 w-4 text-muted-foreground" />
          </CardHeader>
          <CardContent>
            <div className="text-2xl font-bold">{securityScore}/100</div>
            <p className="text-xs text-muted-foreground">
              {securityScore >= 80 ? 'Excellent' : 
               securityScore >= 60 ? 'Good' : 
               securityScore >= 40 ? 'Fair' : 'Poor'} security level
            </p>
          </CardContent>
        </Card>

        <Card>
          <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
            <CardTitle className="text-sm font-medium">Account Status</CardTitle>
            <Activity className="h-4 w-4 text-muted-foreground" />
          </CardHeader>
          <CardContent>
            <div className="flex items-center gap-2">
              {accountStatus === 'active' ? (
                <ShieldCheck className="h-5 w-5 text-green-600" />
              ) : (
                <AlertTriangle className="h-5 w-5 text-red-600" />
              )}
              <Badge 
                variant={accountStatus === 'active' ? 'default' : 'destructive'}
                className="capitalize"
              >
                {accountStatus.replace('_', ' ')}
              </Badge>
            </div>
          </CardContent>
        </Card>

        <Card>
          <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
            <CardTitle className="text-sm font-medium">Active Sessions</CardTitle>
            <Users className="h-4 w-4 text-muted-foreground" />
          </CardHeader>
          <CardContent>
            <div className="text-2xl font-bold">1</div>
            <p className="text-xs text-muted-foreground">
              Current device
            </p>
          </CardContent>
        </Card>

        <Card>
          <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
            <CardTitle className="text-sm font-medium">Session Status</CardTitle>
            <Clock className="h-4 w-4 text-muted-foreground" />
          </CardHeader>
          <CardContent>
            <div className="space-y-1">
              <div className="text-green-600">
                <div className="text-sm font-medium">Active</div>
                <div className="text-xs">Simplified mode</div>
              </div>
            </div>
          </CardContent>
        </Card>
      </div>

      {/* Security Alerts */}
      {isSuspiciousActivity && (
        <Alert variant="destructive">
          <AlertTriangle className="h-4 w-4" />
          <AlertDescription>
            <div className="space-y-1">
              <div className="font-medium">Suspicious Activity Detected</div>
              <div className="text-sm">
                Risk Level: <span className="font-medium capitalize">{riskLevel}</span>
              </div>
              <div className="text-sm">
                Please review your recent account activity and ensure your account is secure.
              </div>
            </div>
          </AlertDescription>
        </Alert>
      )}


      {/* Main Security Settings */}
      <SecuritySettings />

      {/* Admin Information */}
      <Card>
        <CardHeader>
          <CardTitle>Admin Account Information</CardTitle>
          <CardDescription>
            Your current admin account details and permissions
          </CardDescription>
        </CardHeader>
        <CardContent>
          <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
            <div className="space-y-2">
              <p className="text-sm font-medium">Role</p>
              <Badge variant="outline" className="capitalize">
                {adminUser.role.replace('_', ' ')}
              </Badge>
            </div>
            <div className="space-y-2">
              <p className="text-sm font-medium">Status</p>
              <Badge variant={adminUser.is_active ? 'default' : 'destructive'}>
                {adminUser.is_active ? 'Active' : 'Inactive'}
              </Badge>
            </div>
            <div className="space-y-2">
              <p className="text-sm font-medium">Permissions</p>
              <div className="flex flex-wrap gap-1">
                {adminUser.permissions.length > 0 ? (
                  adminUser.permissions.map((permission, index) => (
                    <Badge key={index} variant="secondary" className="text-xs">
                      {permission}
                    </Badge>
                  ))
                ) : (
                  <p className="text-sm text-muted-foreground">No specific permissions</p>
                )}
              </div>
            </div>
            <div className="space-y-2">
              <p className="text-sm font-medium">Account Created</p>
              <p className="text-sm text-muted-foreground">
                {new Date(adminUser.created_at).toLocaleDateString('en-US', {
                  year: 'numeric',
                  month: 'long',
                  day: 'numeric',
                  hour: '2-digit',
                  minute: '2-digit',
                })}
              </p>
            </div>
          </div>
        </CardContent>
      </Card>
    </div>
  );
}