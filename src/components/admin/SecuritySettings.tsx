/**
 * SECURITY SETTINGS COMPONENT
 * Comprehensive security management interface
 * Created: 2025-08-07
 */

import React, { useState, useEffect } from 'react';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { Label } from '@/components/ui/label';
import { Alert, AlertDescription } from '@/components/ui/alert';
import { Badge } from '@/components/ui/badge';
import { Progress } from '@/components/ui/progress';
import { Separator } from '@/components/ui/separator';
import { Tabs, TabsContent, TabsList, TabsTrigger } from '@/components/ui/tabs';
import {
  Dialog,
  DialogContent,
  DialogDescription,
  DialogHeader,
  DialogTitle,
  DialogTrigger,
} from '@/components/ui/dialog';
import {
  Shield,
  ShieldCheck,
  Key,
  Clock,
  AlertTriangle,
  CheckCircle,
  RefreshCw,
  Eye,
  EyeOff,
  Calendar,
  Activity,
  Settings,
} from 'lucide-react';
import { useAuth } from '@/contexts/AuthContext';
import { useAdminAuth } from '@/hooks/useAdminAuth';
import { TwoFactorAuth } from './TwoFactorAuth';
import { SessionManager } from './SessionManager';
import { PasswordStrengthIndicator } from './PasswordStrengthIndicator';
import {
  validatePassword,
  changePassword,
  isPasswordExpired,
  getAccountStatus,
  generatePasswordSuggestions,
} from '@/lib/services/passwordPolicy';
import { toast } from 'sonner';
import { format } from 'date-fns';

interface SecuritySettingsProps {
  className?: string;
}

export function SecuritySettings({ className }: SecuritySettingsProps) {
  const { user } = useAuth();
  const { 
    adminUser, 
    securityStatus, 
    getSecurityScore, 
    getAccountStatus: getAdminAccountStatus,
    refreshSecurityStatus 
  } = useAdminAuth();
  
  const [activeTab, setActiveTab] = useState('overview');
  const [loading, setLoading] = useState(false);
  const [passwordExpiry, setPasswordExpiry] = useState<{
    isExpired: boolean;
    daysRemaining?: number;
    expiresAt?: Date;
  } | null>(null);

  // Password change state
  const [showPasswordDialog, setShowPasswordDialog] = useState(false);
  const [currentPassword, setCurrentPassword] = useState('');
  const [newPassword, setNewPassword] = useState('');
  const [confirmPassword, setConfirmPassword] = useState('');
  const [showPasswords, setShowPasswords] = useState({
    current: false,
    new: false,
    confirm: false,
  });
  const [passwordError, setPasswordError] = useState<string | null>(null);
  const [changingPassword, setChangingPassword] = useState(false);

  useEffect(() => {
    loadSecurityData();
  }, [user]);

  const loadSecurityData = async () => {
    if (!user) return;

    setLoading(true);
    try {
      // Check password expiry
      const expiry = await isPasswordExpired(user.id);
      setPasswordExpiry(expiry);
      
      // Refresh security status
      await refreshSecurityStatus();
    } catch (error) {
      console.error('Error loading security data:', error);
      toast.error('Failed to load security information');
    } finally {
      setLoading(false);
    }
  };

  const handlePasswordChange = async () => {
    if (!user) return;

    if (newPassword !== confirmPassword) {
      setPasswordError('Passwords do not match');
      return;
    }

    if (newPassword.length < 12) {
      setPasswordError('Password must be at least 12 characters long');
      return;
    }

    setChangingPassword(true);
    setPasswordError(null);

    try {
      const personalInfo = [
        user.email || '',
        adminUser?.role || '',
      ].filter(Boolean);

      const result = await changePassword(
        user.id,
        currentPassword,
        newPassword,
        personalInfo
      );

      if (result.success) {
        toast.success('Password changed successfully', {
          description: 'Your password has been updated securely.',
        });
        setShowPasswordDialog(false);
        setCurrentPassword('');
        setNewPassword('');
        setConfirmPassword('');
        await loadSecurityData();
      } else {
        setPasswordError(result.error || 'Failed to change password');
      }
    } catch (error) {
      console.error('Error changing password:', error);
      setPasswordError('An unexpected error occurred');
    } finally {
      setChangingPassword(false);
    }
  };

  const generateSuggestedPasswords = () => {
    const personalInfo = [user?.email || '', adminUser?.role || ''].filter(Boolean);
    return generatePasswordSuggestions(16, personalInfo);
  };

  const getSecurityLevel = (): { level: string; color: string; description: string } => {
    const score = getSecurityScore();
    
    if (score >= 80) {
      return { 
        level: 'Excellent', 
        color: 'text-green-600', 
        description: 'Your account has strong security protections' 
      };
    } else if (score >= 60) {
      return { 
        level: 'Good', 
        color: 'text-blue-600', 
        description: 'Your account has good security, but could be improved' 
      };
    } else if (score >= 40) {
      return { 
        level: 'Fair', 
        color: 'text-yellow-600', 
        description: 'Your account security needs improvement' 
      };
    } else {
      return { 
        level: 'Poor', 
        color: 'text-red-600', 
        description: 'Your account security is at risk and needs immediate attention' 
      };
    }
  };

  const securityLevel = getSecurityLevel();
  const securityScore = getSecurityScore();
  const accountStatus = getAdminAccountStatus();

  if (loading && !securityStatus) {
    return (
      <Card className={className}>
        <CardHeader>
          <CardTitle className="flex items-center gap-2">
            <Settings className="h-5 w-5" />
            Security Settings
          </CardTitle>
        </CardHeader>
        <CardContent>
          <div className="flex items-center justify-center p-8">
            <RefreshCw className="h-6 w-6 animate-spin" />
          </div>
        </CardContent>
      </Card>
    );
  }

  return (
    <div className={`space-y-6 ${className}`}>
      <Card>
        <CardHeader>
          <CardTitle className="flex items-center gap-2">
            <Settings className="h-5 w-5" />
            Security Settings
          </CardTitle>
          <CardDescription>
            Manage your account security, passwords, and authentication methods
          </CardDescription>
        </CardHeader>
      </Card>

      <Tabs value={activeTab} onValueChange={setActiveTab}>
        <TabsList className="grid w-full grid-cols-4">
          <TabsTrigger value="overview">Overview</TabsTrigger>
          <TabsTrigger value="2fa">Two-Factor Auth</TabsTrigger>
          <TabsTrigger value="passwords">Passwords</TabsTrigger>
          <TabsTrigger value="sessions">Sessions</TabsTrigger>
        </TabsList>

        <TabsContent value="overview" className="space-y-6">
          {/* Security Score */}
          <Card>
            <CardHeader>
              <CardTitle className="flex items-center gap-2">
                <Shield className="h-5 w-5" />
                Security Score
              </CardTitle>
              <CardDescription>
                Overall security rating for your account
              </CardDescription>
            </CardHeader>
            <CardContent className="space-y-4">
              <div className="flex items-center justify-between">
                <div className="space-y-1">
                  <p className={`text-lg font-semibold ${securityLevel.color}`}>
                    {securityLevel.level}
                  </p>
                  <p className="text-sm text-muted-foreground">
                    {securityLevel.description}
                  </p>
                </div>
                <div className="text-2xl font-bold text-right">
                  {securityScore}/100
                </div>
              </div>
              <Progress value={securityScore} className="w-full" />
            </CardContent>
          </Card>

          {/* Account Status */}
          <Card>
            <CardHeader>
              <CardTitle className="flex items-center gap-2">
                <Activity className="h-5 w-5" />
                Account Status
              </CardTitle>
            </CardHeader>
            <CardContent className="space-y-4">
              <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                <div className="space-y-2">
                  <Label>Account Status</Label>
                  <div className="flex items-center gap-2">
                    {accountStatus === 'active' ? (
                      <CheckCircle className="h-4 w-4 text-green-600" />
                    ) : (
                      <AlertTriangle className="h-4 w-4 text-red-600" />
                    )}
                    <span className="capitalize">{accountStatus.replace('_', ' ')}</span>
                  </div>
                </div>

                <div className="space-y-2">
                  <Label>Two-Factor Authentication</Label>
                  <div className="flex items-center gap-2">
                    {securityStatus?.two_factor_enabled ? (
                      <>
                        <ShieldCheck className="h-4 w-4 text-green-600" />
                        <Badge variant="default">Enabled</Badge>
                      </>
                    ) : (
                      <>
                        <AlertTriangle className="h-4 w-4 text-yellow-600" />
                        <Badge variant="destructive">Disabled</Badge>
                      </>
                    )}
                  </div>
                </div>

                {securityStatus?.last_login_at && (
                  <div className="space-y-2">
                    <Label>Last Login</Label>
                    <p className="text-sm">
                      {format(new Date(securityStatus.last_login_at), 'PPpp')}
                    </p>
                  </div>
                )}

                <div className="space-y-2">
                  <Label>Failed Login Attempts</Label>
                  <p className="text-sm">
                    {securityStatus?.failed_login_attempts || 0}
                  </p>
                </div>
              </div>
            </CardContent>
          </Card>

          {/* Password Status */}
          <Card>
            <CardHeader>
              <CardTitle className="flex items-center gap-2">
                <Key className="h-5 w-5" />
                Password Status
              </CardTitle>
            </CardHeader>
            <CardContent className="space-y-4">
              {passwordExpiry && (
                <div className="space-y-2">
                  {passwordExpiry.isExpired ? (
                    <Alert variant="destructive">
                      <AlertTriangle className="h-4 w-4" />
                      <AlertDescription>
                        <strong>Password Expired</strong>
                        <p className="mt-1">Your password has expired and must be changed immediately.</p>
                      </AlertDescription>
                    </Alert>
                  ) : passwordExpiry.daysRemaining && passwordExpiry.daysRemaining <= 14 ? (
                    <Alert>
                      <Clock className="h-4 w-4" />
                      <AlertDescription>
                        <strong>Password Expires Soon</strong>
                        <p className="mt-1">
                          Your password will expire in {passwordExpiry.daysRemaining} days 
                          ({passwordExpiry.expiresAt && format(passwordExpiry.expiresAt, 'PPpp')})
                        </p>
                      </AlertDescription>
                    </Alert>
                  ) : (
                    <div className="flex items-center gap-2">
                      <CheckCircle className="h-4 w-4 text-green-600" />
                      <span className="text-sm">
                        Password expires in {passwordExpiry.daysRemaining} days
                      </span>
                    </div>
                  )}
                </div>
              )}

              <Dialog open={showPasswordDialog} onOpenChange={setShowPasswordDialog}>
                <DialogTrigger asChild>
                  <Button variant="outline">
                    <Key className="h-4 w-4 mr-2" />
                    Change Password
                  </Button>
                </DialogTrigger>
                <DialogContent className="max-w-md">
                  <DialogHeader>
                    <DialogTitle>Change Password</DialogTitle>
                    <DialogDescription>
                      Enter your current password and choose a strong new password.
                    </DialogDescription>
                  </DialogHeader>
                  <div className="space-y-4">
                    {passwordError && (
                      <Alert variant="destructive">
                        <AlertTriangle className="h-4 w-4" />
                        <AlertDescription>{passwordError}</AlertDescription>
                      </Alert>
                    )}

                    <div className="space-y-2">
                      <Label>Current Password</Label>
                      <div className="relative">
                        <Input
                          type={showPasswords.current ? 'text' : 'password'}
                          value={currentPassword}
                          onChange={(e) => setCurrentPassword(e.target.value)}
                          disabled={changingPassword}
                        />
                        <Button
                          type="button"
                          variant="ghost"
                          size="icon"
                          className="absolute right-2 top-1/2 -translate-y-1/2 h-8 w-8"
                          onClick={() => setShowPasswords(prev => ({ ...prev, current: !prev.current }))}
                        >
                          {showPasswords.current ? <EyeOff className="h-4 w-4" /> : <Eye className="h-4 w-4" />}
                        </Button>
                      </div>
                    </div>

                    <div className="space-y-2">
                      <Label>New Password</Label>
                      <div className="relative">
                        <Input
                          type={showPasswords.new ? 'text' : 'password'}
                          value={newPassword}
                          onChange={(e) => setNewPassword(e.target.value)}
                          disabled={changingPassword}
                        />
                        <Button
                          type="button"
                          variant="ghost"
                          size="icon"
                          className="absolute right-2 top-1/2 -translate-y-1/2 h-8 w-8"
                          onClick={() => setShowPasswords(prev => ({ ...prev, new: !prev.new }))}
                        >
                          {showPasswords.new ? <EyeOff className="h-4 w-4" /> : <Eye className="h-4 w-4" />}
                        </Button>
                      </div>
                      {newPassword && (
                        <PasswordStrengthIndicator 
                          password={newPassword}
                          personalInfo={[user?.email || '', adminUser?.role || '']}
                        />
                      )}
                    </div>

                    <div className="space-y-2">
                      <Label>Confirm New Password</Label>
                      <div className="relative">
                        <Input
                          type={showPasswords.confirm ? 'text' : 'password'}
                          value={confirmPassword}
                          onChange={(e) => setConfirmPassword(e.target.value)}
                          disabled={changingPassword}
                        />
                        <Button
                          type="button"
                          variant="ghost"
                          size="icon"
                          className="absolute right-2 top-1/2 -translate-y-1/2 h-8 w-8"
                          onClick={() => setShowPasswords(prev => ({ ...prev, confirm: !prev.confirm }))}
                        >
                          {showPasswords.confirm ? <EyeOff className="h-4 w-4" /> : <Eye className="h-4 w-4" />}
                        </Button>
                      </div>
                    </div>

                    <div className="flex gap-2">
                      <Button
                        onClick={handlePasswordChange}
                        disabled={changingPassword || !currentPassword || !newPassword || newPassword !== confirmPassword}
                        className="flex-1"
                      >
                        {changingPassword ? (
                          <>
                            <RefreshCw className="h-4 w-4 mr-2 animate-spin" />
                            Changing...
                          </>
                        ) : (
                          'Change Password'
                        )}
                      </Button>
                      <Button
                        variant="outline"
                        onClick={() => setShowPasswordDialog(false)}
                        disabled={changingPassword}
                      >
                        Cancel
                      </Button>
                    </div>
                  </div>
                </DialogContent>
              </Dialog>
            </CardContent>
          </Card>
        </TabsContent>

        <TabsContent value="2fa">
          <TwoFactorAuth />
        </TabsContent>

        <TabsContent value="passwords" className="space-y-6">
          <Card>
            <CardHeader>
              <CardTitle>Password Management</CardTitle>
              <CardDescription>
                Manage password policies and security requirements
              </CardDescription>
            </CardHeader>
            <CardContent className="space-y-4">
              <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                <div className="space-y-2">
                  <Label>Minimum Length</Label>
                  <p className="text-sm text-muted-foreground">12 characters</p>
                </div>
                <div className="space-y-2">
                  <Label>Password History</Label>
                  <p className="text-sm text-muted-foreground">Last 5 passwords remembered</p>
                </div>
                <div className="space-y-2">
                  <Label>Password Age</Label>
                  <p className="text-sm text-muted-foreground">Maximum 90 days</p>
                </div>
                <div className="space-y-2">
                  <Label>Change Frequency</Label>
                  <p className="text-sm text-muted-foreground">Minimum 24 hours between changes</p>
                </div>
              </div>
            </CardContent>
          </Card>
        </TabsContent>

        <TabsContent value="sessions">
          <SessionManager />
        </TabsContent>
      </Tabs>
    </div>
  );
}