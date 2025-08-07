/**
 * TWO-FACTOR AUTHENTICATION COMPONENT
 * Complete 2FA setup and management interface
 * Created: 2025-08-07
 */

import React, { useState, useEffect } from 'react';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { Label } from '@/components/ui/label';
import { Alert, AlertDescription } from '@/components/ui/alert';
import { Badge } from '@/components/ui/badge';
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
  AlertDialog,
  AlertDialogAction,
  AlertDialogCancel,
  AlertDialogContent,
  AlertDialogDescription,
  AlertDialogFooter,
  AlertDialogHeader,
  AlertDialogTitle,
  AlertDialogTrigger,
} from '@/components/ui/alert-dialog';
import { InputOTP, InputOTPGroup, InputOTPSeparator, InputOTPSlot } from 'input-otp';
import {
  Shield,
  ShieldCheck,
  ShieldAlert,
  QrCode,
  Copy,
  Download,
  RefreshCw,
  Smartphone,
  Key,
  AlertTriangle,
  CheckCircle,
  XCircle,
} from 'lucide-react';
import { useAuth } from '@/contexts/AuthContext';
import { toast } from 'sonner';
import {
  setupTwoFactor,
  enableTwoFactor,
  disableTwoFactor,
  regenerateBackupCodes,
  getAdminSecurityStatus,
  TwoFactorSetupData,
  AdminUserSecurity,
} from '@/lib/services/twoFactor';

interface TwoFactorAuthProps {
  className?: string;
}

export function TwoFactorAuth({ className }: TwoFactorAuthProps) {
  const { user } = useAuth();
  const [loading, setLoading] = useState(false);
  const [securityStatus, setSecurityStatus] = useState<AdminUserSecurity | null>(null);
  const [setupData, setSetupData] = useState<TwoFactorSetupData | null>(null);
  const [verificationCode, setVerificationCode] = useState('');
  const [backupCode, setBackupCode] = useState('');
  const [showQRCode, setShowQRCode] = useState(false);
  const [showBackupCodes, setShowBackupCodes] = useState(false);
  const [newBackupCodes, setNewBackupCodes] = useState<string[]>([]);
  const [step, setStep] = useState<'status' | 'setup' | 'verify' | 'complete'>('status');

  // Load security status
  useEffect(() => {
    loadSecurityStatus();
  }, [user]);

  const loadSecurityStatus = async () => {
    if (!user) return;

    setLoading(true);
    try {
      const result = await getAdminSecurityStatus(user.id);
      if (result.success && result.data) {
        setSecurityStatus(result.data);
      }
    } catch (error) {
      console.error('Error loading security status:', error);
      toast.error('Failed to load security status');
    } finally {
      setLoading(false);
    }
  };

  const handleSetup2FA = async () => {
    if (!user?.email) return;

    setLoading(true);
    try {
      const result = await setupTwoFactor(user.email);
      if (result.success && result.data) {
        setSetupData(result.data);
        setStep('setup');
      } else {
        toast.error('Failed to setup 2FA', {
          description: result.error,
        });
      }
    } catch (error) {
      console.error('Error setting up 2FA:', error);
      toast.error('Failed to setup 2FA');
    } finally {
      setLoading(false);
    }
  };

  const handleEnable2FA = async () => {
    if (!user || !setupData || !verificationCode) return;

    setLoading(true);
    try {
      const result = await enableTwoFactor(
        user.id,
        setupData.secret,
        setupData.backupCodes,
        verificationCode,
        user.email || ''
      );

      if (result.success) {
        toast.success('Two-Factor Authentication Enabled', {
          description: 'Your account is now protected with 2FA.',
        });
        setStep('complete');
        setShowBackupCodes(true);
        await loadSecurityStatus();
      } else {
        toast.error('Failed to enable 2FA', {
          description: result.error,
        });
      }
    } catch (error) {
      console.error('Error enabling 2FA:', error);
      toast.error('Failed to enable 2FA');
    } finally {
      setLoading(false);
    }
  };

  const handleDisable2FA = async () => {
    if (!user) return;

    setLoading(true);
    try {
      const result = await disableTwoFactor(
        user.id,
        verificationCode || undefined,
        backupCode || undefined
      );

      if (result.success) {
        toast.success('Two-Factor Authentication Disabled', {
          description: 'Your account is no longer protected with 2FA.',
        });
        setVerificationCode('');
        setBackupCode('');
        await loadSecurityStatus();
      } else {
        toast.error('Failed to disable 2FA', {
          description: result.error,
        });
      }
    } catch (error) {
      console.error('Error disabling 2FA:', error);
      toast.error('Failed to disable 2FA');
    } finally {
      setLoading(false);
    }
  };

  const handleRegenerateBackupCodes = async () => {
    if (!user || !verificationCode) return;

    setLoading(true);
    try {
      const result = await regenerateBackupCodes(user.id, verificationCode);

      if (result.success && result.backupCodes) {
        setNewBackupCodes(result.backupCodes);
        setShowBackupCodes(true);
        setVerificationCode('');
        toast.success('Backup codes regenerated', {
          description: 'Please save your new backup codes.',
        });
      } else {
        toast.error('Failed to regenerate backup codes', {
          description: result.error,
        });
      }
    } catch (error) {
      console.error('Error regenerating backup codes:', error);
      toast.error('Failed to regenerate backup codes');
    } finally {
      setLoading(false);
    }
  };

  const copyToClipboard = (text: string) => {
    navigator.clipboard.writeText(text);
    toast.success('Copied to clipboard');
  };

  const downloadBackupCodes = (codes: string[]) => {
    const content = `KCT Menswear Admin - Backup Codes\nGenerated: ${new Date().toLocaleString()}\n\n${codes.join('\n')}\n\nKeep these codes safe and secure!`;
    const blob = new Blob([content], { type: 'text/plain' });
    const url = URL.createObjectURL(blob);
    const a = document.createElement('a');
    a.href = url;
    a.download = `kct-admin-backup-codes-${Date.now()}.txt`;
    document.body.appendChild(a);
    a.click();
    document.body.removeChild(a);
    URL.revokeObjectURL(url);
  };

  const resetSetup = () => {
    setSetupData(null);
    setVerificationCode('');
    setBackupCode('');
    setStep('status');
    setShowQRCode(false);
    setShowBackupCodes(false);
    setNewBackupCodes([]);
  };

  if (loading && !securityStatus) {
    return (
      <Card className={className}>
        <CardHeader>
          <CardTitle className="flex items-center gap-2">
            <Shield className="h-5 w-5" />
            Two-Factor Authentication
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

  if (step === 'status') {
    return (
      <Card className={className}>
        <CardHeader>
          <CardTitle className="flex items-center gap-2">
            <Shield className="h-5 w-5" />
            Two-Factor Authentication
          </CardTitle>
          <CardDescription>
            Add an extra layer of security to your admin account
          </CardDescription>
        </CardHeader>
        <CardContent className="space-y-6">
          {securityStatus ? (
            <div className="space-y-4">
              <div className="flex items-center justify-between">
                <div className="flex items-center gap-3">
                  {securityStatus.two_factor_enabled ? (
                    <ShieldCheck className="h-5 w-5 text-green-600" />
                  ) : (
                    <ShieldAlert className="h-5 w-5 text-yellow-600" />
                  )}
                  <div>
                    <p className="font-medium">
                      Two-Factor Authentication
                    </p>
                    <p className="text-sm text-muted-foreground">
                      {securityStatus.two_factor_enabled
                        ? 'Enabled and protecting your account'
                        : 'Not enabled - your account is at risk'
                      }
                    </p>
                  </div>
                </div>
                <Badge variant={securityStatus.two_factor_enabled ? 'default' : 'destructive'}>
                  {securityStatus.two_factor_enabled ? 'Enabled' : 'Disabled'}
                </Badge>
              </div>

              {securityStatus.two_factor_enabled ? (
                <div className="space-y-4">
                  <Alert>
                    <CheckCircle className="h-4 w-4" />
                    <AlertDescription>
                      Your account is protected with two-factor authentication. 
                      You'll need your authenticator app or backup codes to sign in.
                    </AlertDescription>
                  </Alert>

                  <div className="flex flex-wrap gap-2">
                    <Dialog>
                      <DialogTrigger asChild>
                        <Button variant="outline" size="sm">
                          <RefreshCw className="h-4 w-4 mr-2" />
                          Regenerate Backup Codes
                        </Button>
                      </DialogTrigger>
                      <DialogContent>
                        <DialogHeader>
                          <DialogTitle>Regenerate Backup Codes</DialogTitle>
                          <DialogDescription>
                            Enter your 6-digit code from your authenticator app to generate new backup codes.
                            This will invalidate all existing backup codes.
                          </DialogDescription>
                        </DialogHeader>
                        <div className="space-y-4">
                          <div className="space-y-2">
                            <Label>Verification Code</Label>
                            <InputOTP
                              value={verificationCode}
                              onChange={setVerificationCode}
                              maxLength={6}
                            >
                              <InputOTPGroup>
                                <InputOTPSlot index={0} />
                                <InputOTPSlot index={1} />
                                <InputOTPSlot index={2} />
                              </InputOTPGroup>
                              <InputOTPSeparator />
                              <InputOTPGroup>
                                <InputOTPSlot index={3} />
                                <InputOTPSlot index={4} />
                                <InputOTPSlot index={5} />
                              </InputOTPGroup>
                            </InputOTP>
                          </div>
                          <Button
                            onClick={handleRegenerateBackupCodes}
                            disabled={loading || verificationCode.length !== 6}
                            className="w-full"
                          >
                            {loading ? (
                              <RefreshCw className="h-4 w-4 mr-2 animate-spin" />
                            ) : (
                              <RefreshCw className="h-4 w-4 mr-2" />
                            )}
                            Generate New Codes
                          </Button>
                        </div>
                      </DialogContent>
                    </Dialog>

                    <AlertDialog>
                      <AlertDialogTrigger asChild>
                        <Button variant="destructive" size="sm">
                          <XCircle className="h-4 w-4 mr-2" />
                          Disable 2FA
                        </Button>
                      </AlertDialogTrigger>
                      <AlertDialogContent>
                        <AlertDialogHeader>
                          <AlertDialogTitle>Disable Two-Factor Authentication</AlertDialogTitle>
                          <AlertDialogDescription>
                            This will remove two-factor authentication from your account and make it less secure.
                            You'll need to verify with either your authenticator app or a backup code.
                          </AlertDialogDescription>
                        </AlertDialogHeader>
                        <div className="space-y-4">
                          <Tabs defaultValue="app">
                            <TabsList className="grid w-full grid-cols-2">
                              <TabsTrigger value="app">Authenticator App</TabsTrigger>
                              <TabsTrigger value="backup">Backup Code</TabsTrigger>
                            </TabsList>
                            <TabsContent value="app" className="space-y-2">
                              <Label>6-digit code from your authenticator app</Label>
                              <InputOTP
                                value={verificationCode}
                                onChange={setVerificationCode}
                                maxLength={6}
                              >
                                <InputOTPGroup>
                                  <InputOTPSlot index={0} />
                                  <InputOTPSlot index={1} />
                                  <InputOTPSlot index={2} />
                                </InputOTPGroup>
                                <InputOTPSeparator />
                                <InputOTPGroup>
                                  <InputOTPSlot index={3} />
                                  <InputOTPSlot index={4} />
                                  <InputOTPSlot index={5} />
                                </InputOTPGroup>
                              </InputOTP>
                            </TabsContent>
                            <TabsContent value="backup" className="space-y-2">
                              <Label>8-character backup code</Label>
                              <Input
                                value={backupCode}
                                onChange={(e) => setBackupCode(e.target.value.toUpperCase())}
                                placeholder="Enter backup code"
                                maxLength={8}
                              />
                            </TabsContent>
                          </Tabs>
                        </div>
                        <AlertDialogFooter>
                          <AlertDialogCancel onClick={() => {
                            setVerificationCode('');
                            setBackupCode('');
                          }}>
                            Cancel
                          </AlertDialogCancel>
                          <AlertDialogAction
                            onClick={handleDisable2FA}
                            disabled={!verificationCode && !backupCode}
                          >
                            Disable 2FA
                          </AlertDialogAction>
                        </AlertDialogFooter>
                      </AlertDialogContent>
                    </AlertDialog>
                  </div>
                </div>
              ) : (
                <div className="space-y-4">
                  <Alert variant="destructive">
                    <AlertTriangle className="h-4 w-4" />
                    <AlertDescription>
                      Your account is not protected with two-factor authentication. 
                      We strongly recommend enabling 2FA to secure your admin access.
                    </AlertDescription>
                  </Alert>

                  <Button onClick={handleSetup2FA} disabled={loading}>
                    {loading ? (
                      <RefreshCw className="h-4 w-4 mr-2 animate-spin" />
                    ) : (
                      <Shield className="h-4 w-4 mr-2" />
                    )}
                    Enable Two-Factor Authentication
                  </Button>
                </div>
              )}
            </div>
          ) : (
            <Alert>
              <AlertTriangle className="h-4 w-4" />
              <AlertDescription>
                Unable to load security status. Please refresh the page.
              </AlertDescription>
            </Alert>
          )}
        </CardContent>
      </Card>
    );
  }

  if (step === 'setup' && setupData) {
    return (
      <Card className={className}>
        <CardHeader>
          <CardTitle className="flex items-center gap-2">
            <Smartphone className="h-5 w-5" />
            Setup Two-Factor Authentication
          </CardTitle>
          <CardDescription>
            Scan the QR code with your authenticator app
          </CardDescription>
        </CardHeader>
        <CardContent className="space-y-6">
          <div className="space-y-4">
            <Alert>
              <AlertTriangle className="h-4 w-4" />
              <AlertDescription>
                <strong>Important:</strong> Save your backup codes before continuing. 
                You'll need them if you lose access to your authenticator app.
              </AlertDescription>
            </Alert>

            <Tabs defaultValue="qr">
              <TabsList className="grid w-full grid-cols-2">
                <TabsTrigger value="qr">QR Code</TabsTrigger>
                <TabsTrigger value="manual">Manual Entry</TabsTrigger>
              </TabsList>
              
              <TabsContent value="qr" className="space-y-4">
                <div className="flex flex-col items-center space-y-4">
                  <div className="p-4 bg-white rounded-lg">
                    <img
                      src={setupData.qrCodeUrl}
                      alt="2FA QR Code"
                      className="w-48 h-48"
                    />
                  </div>
                  <p className="text-sm text-center text-muted-foreground">
                    Scan this QR code with Google Authenticator, Authy, or any compatible TOTP app
                  </p>
                </div>
              </TabsContent>
              
              <TabsContent value="manual" className="space-y-4">
                <div className="space-y-2">
                  <Label>Manual Entry Key</Label>
                  <div className="flex items-center gap-2">
                    <Input
                      value={setupData.manualEntryKey}
                      readOnly
                      className="font-mono"
                    />
                    <Button
                      variant="outline"
                      size="icon"
                      onClick={() => copyToClipboard(setupData.manualEntryKey)}
                    >
                      <Copy className="h-4 w-4" />
                    </Button>
                  </div>
                  <p className="text-sm text-muted-foreground">
                    Enter this key manually in your authenticator app if you can't scan the QR code
                  </p>
                </div>
              </TabsContent>
            </Tabs>

            <Separator />

            <div className="space-y-4">
              <div className="flex items-center justify-between">
                <h4 className="font-medium">Backup Codes</h4>
                <Button
                  variant="outline"
                  size="sm"
                  onClick={() => downloadBackupCodes(setupData.backupCodes)}
                >
                  <Download className="h-4 w-4 mr-2" />
                  Download
                </Button>
              </div>
              
              <div className="grid grid-cols-2 gap-2 p-4 bg-muted rounded-lg">
                {setupData.backupCodes.map((code, index) => (
                  <div
                    key={index}
                    className="flex items-center justify-between p-2 bg-white rounded font-mono text-sm"
                  >
                    <span>{code}</span>
                    <Button
                      variant="ghost"
                      size="icon"
                      className="h-6 w-6"
                      onClick={() => copyToClipboard(code)}
                    >
                      <Copy className="h-3 w-3" />
                    </Button>
                  </div>
                ))}
              </div>
              
              <Alert>
                <Key className="h-4 w-4" />
                <AlertDescription>
                  These backup codes can be used to access your account if you lose your authenticator device. 
                  Each code can only be used once. Store them in a safe place!
                </AlertDescription>
              </Alert>
            </div>

            <Separator />

            <div className="space-y-4">
              <div className="space-y-2">
                <Label>Verify Setup</Label>
                <p className="text-sm text-muted-foreground">
                  Enter the 6-digit code from your authenticator app to verify the setup
                </p>
                <InputOTP
                  value={verificationCode}
                  onChange={setVerificationCode}
                  maxLength={6}
                >
                  <InputOTPGroup>
                    <InputOTPSlot index={0} />
                    <InputOTPSlot index={1} />
                    <InputOTPSlot index={2} />
                  </InputOTPGroup>
                  <InputOTPSeparator />
                  <InputOTPGroup>
                    <InputOTPSlot index={3} />
                    <InputOTPSlot index={4} />
                    <InputOTPSlot index={5} />
                  </InputOTPGroup>
                </InputOTP>
              </div>

              <div className="flex gap-2">
                <Button
                  onClick={handleEnable2FA}
                  disabled={loading || verificationCode.length !== 6}
                  className="flex-1"
                >
                  {loading ? (
                    <RefreshCw className="h-4 w-4 mr-2 animate-spin" />
                  ) : (
                    <ShieldCheck className="h-4 w-4 mr-2" />
                  )}
                  Enable 2FA
                </Button>
                <Button
                  variant="outline"
                  onClick={resetSetup}
                  disabled={loading}
                >
                  Cancel
                </Button>
              </div>
            </div>
          </div>
        </CardContent>
      </Card>
    );
  }

  if (step === 'complete') {
    return (
      <Card className={className}>
        <CardHeader>
          <CardTitle className="flex items-center gap-2">
            <CheckCircle className="h-5 w-5 text-green-600" />
            Two-Factor Authentication Enabled
          </CardTitle>
          <CardDescription>
            Your account is now protected with 2FA
          </CardDescription>
        </CardHeader>
        <CardContent className="space-y-6">
          <Alert>
            <ShieldCheck className="h-4 w-4" />
            <AlertDescription>
              Two-factor authentication has been successfully enabled for your account. 
              You'll now need your authenticator app to sign in.
            </AlertDescription>
          </Alert>

          <Button onClick={resetSetup} className="w-full">
            Continue to Security Dashboard
          </Button>
        </CardContent>
      </Card>
    );
  }

  // Backup codes display dialog
  return (
    <>
      {showBackupCodes && (
        <Dialog open={showBackupCodes} onOpenChange={setShowBackupCodes}>
          <DialogContent className="max-w-md">
            <DialogHeader>
              <DialogTitle>Your New Backup Codes</DialogTitle>
              <DialogDescription>
                These codes replace your previous backup codes. Save them securely.
              </DialogDescription>
            </DialogHeader>
            <div className="space-y-4">
              <div className="grid grid-cols-1 gap-2">
                {newBackupCodes.map((code, index) => (
                  <div
                    key={index}
                    className="flex items-center justify-between p-3 bg-muted rounded font-mono text-sm"
                  >
                    <span>{code}</span>
                    <Button
                      variant="ghost"
                      size="icon"
                      className="h-6 w-6"
                      onClick={() => copyToClipboard(code)}
                    >
                      <Copy className="h-3 w-3" />
                    </Button>
                  </div>
                ))}
              </div>
              <div className="flex gap-2">
                <Button
                  variant="outline"
                  onClick={() => downloadBackupCodes(newBackupCodes)}
                  className="flex-1"
                >
                  <Download className="h-4 w-4 mr-2" />
                  Download
                </Button>
                <Button
                  onClick={() => setShowBackupCodes(false)}
                  className="flex-1"
                >
                  Done
                </Button>
              </div>
            </div>
          </DialogContent>
        </Dialog>
      )}
    </>
  );
}