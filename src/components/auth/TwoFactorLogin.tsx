/**
 * TWO-FACTOR LOGIN COMPONENT
 * Handles 2FA verification during login process
 * Created: 2025-08-07
 */

import React, { useState, useEffect, useRef } from 'react';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { Label } from '@/components/ui/label';
import { Alert, AlertDescription } from '@/components/ui/alert';
import { Separator } from '@/components/ui/separator';
import { Tabs, TabsContent, TabsList, TabsTrigger } from '@/components/ui/tabs';
import { InputOTP, InputOTPGroup, InputOTPSeparator, InputOTPSlot } from '@/components/ui/input-otp';
import {
  Shield,
  Smartphone,
  Key,
  RefreshCw,
  AlertTriangle,
  CheckCircle,
  Clock,
  ArrowLeft,
  HelpCircle,
} from 'lucide-react';
import { useAuth } from '@/contexts/AuthContext';
import { verifyBackupCode } from '@/lib/services/twoFactor';
import { toast } from 'sonner';

interface TwoFactorLoginProps {
  onBack?: () => void;
  onSuccess?: () => void;
  className?: string;
}

export function TwoFactorLogin({ onBack, onSuccess, className }: TwoFactorLoginProps) {
  const { verifyTwoFactor, clearTwoFactorState, pendingUserId, loading } = useAuth();
  const [verificationCode, setVerificationCode] = useState('');
  const [backupCode, setBackupCode] = useState('');
  const [verifying, setVerifying] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [activeTab, setActiveTab] = useState<'app' | 'backup'>('app');
  const [attemptsRemaining, setAttemptsRemaining] = useState<number | null>(null);
  const [timeRemaining, setTimeRemaining] = useState<number | null>(null);
  
  // Auto-focus the first input
  const firstInputRef = useRef<HTMLInputElement>(null);

  useEffect(() => {
    if (firstInputRef.current) {
      firstInputRef.current.focus();
    }
  }, [activeTab]);

  // Countdown timer for rate limiting (if implemented)
  useEffect(() => {
    if (timeRemaining && timeRemaining > 0) {
      const timer = setTimeout(() => {
        setTimeRemaining(timeRemaining - 1);
      }, 1000);
      return () => clearTimeout(timer);
    }
  }, [timeRemaining]);

  const handleVerifyAuthenticator = async () => {
    if (!verificationCode || verificationCode.length !== 6) {
      setError('Please enter a valid 6-digit code');
      return;
    }

    setVerifying(true);
    setError(null);

    try {
      const result = await verifyTwoFactor(verificationCode);
      
      if (result.success) {
        toast.success('Two-factor authentication successful');
        setVerificationCode('');
        onSuccess?.();
      } else {
        setError(result.error || 'Invalid verification code');
        setVerificationCode('');
        
        // Handle rate limiting or account lockout
        if (result.error?.includes('locked')) {
          setTimeRemaining(300); // 5 minutes
        } else if (result.error?.includes('attempts')) {
          // Extract remaining attempts if provided
          const match = result.error.match(/(\d+)\s+attempts?\s+remaining/i);
          if (match) {
            setAttemptsRemaining(parseInt(match[1]));
          }
        }
      }
    } catch (error) {
      console.error('Error verifying 2FA:', error);
      setError('Verification failed. Please try again.');
      setVerificationCode('');
    } finally {
      setVerifying(false);
    }
  };

  const handleVerifyBackupCode = async () => {
    if (!backupCode || backupCode.length !== 8) {
      setError('Please enter a valid 8-character backup code');
      return;
    }

    if (!pendingUserId) {
      setError('No pending authentication');
      return;
    }

    setVerifying(true);
    setError(null);

    try {
      const isValid = await verifyBackupCode(pendingUserId, backupCode);
      
      if (isValid) {
        // Complete the authentication process
        const result = await verifyTwoFactor(backupCode);
        
        if (result.success) {
          toast.success('Backup code verification successful');
          setBackupCode('');
          onSuccess?.();
        } else {
          setError('Authentication failed after backup code verification');
        }
      } else {
        setError('Invalid backup code or code already used');
        setBackupCode('');
      }
    } catch (error) {
      console.error('Error verifying backup code:', error);
      setError('Verification failed. Please try again.');
      setBackupCode('');
    } finally {
      setVerifying(false);
    }
  };

  const handleBack = () => {
    clearTwoFactorState();
    onBack?.();
  };

  const handleKeyPress = (e: React.KeyboardEvent) => {
    if (e.key === 'Enter') {
      e.preventDefault();
      if (activeTab === 'app' && verificationCode.length === 6) {
        handleVerifyAuthenticator();
      } else if (activeTab === 'backup' && backupCode.length === 8) {
        handleVerifyBackupCode();
      }
    }
  };

  return (
    <Card className={className}>
      <CardHeader className="text-center">
        <div className="flex items-center justify-center mb-2">
          <div className="p-3 bg-blue-100 rounded-full">
            <Shield className="h-6 w-6 text-blue-600" />
          </div>
        </div>
        <CardTitle>Two-Factor Authentication</CardTitle>
        <CardDescription>
          Enter the verification code from your authenticator app or use a backup code
        </CardDescription>
      </CardHeader>
      
      <CardContent className="space-y-6">
        {error && (
          <Alert variant="destructive">
            <AlertTriangle className="h-4 w-4" />
            <AlertDescription>{error}</AlertDescription>
          </Alert>
        )}

        {attemptsRemaining !== null && attemptsRemaining <= 3 && (
          <Alert variant="destructive">
            <AlertTriangle className="h-4 w-4" />
            <AlertDescription>
              <strong>Warning:</strong> {attemptsRemaining} attempt{attemptsRemaining !== 1 ? 's' : ''} remaining before account lockout.
            </AlertDescription>
          </Alert>
        )}

        {timeRemaining && timeRemaining > 0 && (
          <Alert>
            <Clock className="h-4 w-4" />
            <AlertDescription>
              Too many failed attempts. Please wait {Math.floor(timeRemaining / 60)}:
              {(timeRemaining % 60).toString().padStart(2, '0')} before trying again.
            </AlertDescription>
          </Alert>
        )}

        <Tabs value={activeTab} onValueChange={(value) => setActiveTab(value as 'app' | 'backup')}>
          <TabsList className="grid w-full grid-cols-2">
            <TabsTrigger value="app" className="flex items-center gap-2">
              <Smartphone className="h-4 w-4" />
              Authenticator App
            </TabsTrigger>
            <TabsTrigger value="backup" className="flex items-center gap-2">
              <Key className="h-4 w-4" />
              Backup Code
            </TabsTrigger>
          </TabsList>

          <TabsContent value="app" className="space-y-4">
            <div className="space-y-2">
              <Label className="text-center block">
                Enter the 6-digit code from your authenticator app
              </Label>
              <div className="flex justify-center">
                <InputOTP
                  value={verificationCode}
                  onChange={setVerificationCode}
                  maxLength={6}
                  onKeyDown={handleKeyPress}
                  disabled={verifying || (timeRemaining !== null && timeRemaining > 0)}
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
              <p className="text-xs text-center text-muted-foreground">
                Codes refresh every 30 seconds
              </p>
            </div>

            <Button
              onClick={handleVerifyAuthenticator}
              disabled={verifying || verificationCode.length !== 6 || (timeRemaining !== null && timeRemaining > 0)}
              className="w-full"
              size="lg"
            >
              {verifying ? (
                <>
                  <RefreshCw className="h-4 w-4 mr-2 animate-spin" />
                  Verifying...
                </>
              ) : (
                <>
                  <CheckCircle className="h-4 w-4 mr-2" />
                  Verify Code
                </>
              )}
            </Button>
          </TabsContent>

          <TabsContent value="backup" className="space-y-4">
            <div className="space-y-2">
              <Label htmlFor="backup-code">
                Enter an 8-character backup code
              </Label>
              <Input
                id="backup-code"
                ref={firstInputRef}
                value={backupCode}
                onChange={(e) => setBackupCode(e.target.value.toUpperCase())}
                onKeyDown={handleKeyPress}
                placeholder="XXXXXXXX"
                maxLength={8}
                className="text-center font-mono text-lg tracking-wider"
                disabled={verifying || (timeRemaining !== null && timeRemaining > 0)}
              />
              <p className="text-xs text-muted-foreground">
                Each backup code can only be used once
              </p>
            </div>

            <Button
              onClick={handleVerifyBackupCode}
              disabled={verifying || backupCode.length !== 8 || (timeRemaining !== null && timeRemaining > 0)}
              className="w-full"
              size="lg"
            >
              {verifying ? (
                <>
                  <RefreshCw className="h-4 w-4 mr-2 animate-spin" />
                  Verifying...
                </>
              ) : (
                <>
                  <CheckCircle className="h-4 w-4 mr-2" />
                  Verify Backup Code
                </>
              )}
            </Button>
          </TabsContent>
        </Tabs>

        <Separator />

        <div className="space-y-4">
          {/* Help section */}
          <div className="bg-muted/50 rounded-lg p-4">
            <div className="flex items-start gap-3">
              <HelpCircle className="h-5 w-5 text-muted-foreground mt-0.5" />
              <div className="space-y-2">
                <h4 className="font-medium text-sm">Need help?</h4>
                <ul className="text-xs text-muted-foreground space-y-1">
                  <li>• Check that your device's time is correct</li>
                  <li>• Try generating a new code if the current one doesn't work</li>
                  <li>• Use a backup code if you can't access your authenticator</li>
                </ul>
              </div>
            </div>
          </div>

          {/* Back button */}
          <Button
            variant="ghost"
            onClick={handleBack}
            disabled={verifying}
            className="w-full"
          >
            <ArrowLeft className="h-4 w-4 mr-2" />
            Back to Login
          </Button>
        </div>
      </CardContent>
    </Card>
  );
}

/**
 * Simplified 2FA prompt for use in modals or inline
 */
export function TwoFactorPrompt({ 
  onVerify, 
  onCancel, 
  loading = false,
  className = '' 
}: {
  onVerify: (code: string) => Promise<void>;
  onCancel?: () => void;
  loading?: boolean;
  className?: string;
}) {
  const [code, setCode] = useState('');
  const [error, setError] = useState<string | null>(null);

  const handleSubmit = async () => {
    if (code.length !== 6) {
      setError('Please enter a valid 6-digit code');
      return;
    }

    setError(null);
    try {
      await onVerify(code);
    } catch (error) {
      setError('Verification failed. Please try again.');
    }
  };

  return (
    <div className={`space-y-4 ${className}`}>
      <div className="text-center">
        <div className="p-3 bg-blue-100 rounded-full w-fit mx-auto mb-3">
          <Shield className="h-6 w-6 text-blue-600" />
        </div>
        <h3 className="font-semibold">Two-Factor Authentication</h3>
        <p className="text-sm text-muted-foreground">
          Enter the code from your authenticator app
        </p>
      </div>

      {error && (
        <Alert variant="destructive">
          <AlertTriangle className="h-4 w-4" />
          <AlertDescription>{error}</AlertDescription>
        </Alert>
      )}

      <div className="space-y-3">
        <div className="flex justify-center">
          <InputOTP
            value={code}
            onChange={setCode}
            maxLength={6}
            disabled={loading}
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
            onClick={handleSubmit}
            disabled={loading || code.length !== 6}
            className="flex-1"
          >
            {loading ? (
              <>
                <RefreshCw className="h-4 w-4 mr-2 animate-spin" />
                Verifying...
              </>
            ) : (
              'Verify'
            )}
          </Button>
          {onCancel && (
            <Button
              variant="outline"
              onClick={onCancel}
              disabled={loading}
            >
              Cancel
            </Button>
          )}
        </div>
      </div>
    </div>
  );
}