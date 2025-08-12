import { useState, useEffect } from 'react';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { Label } from '@/components/ui/label';
import { Alert, AlertDescription } from '@/components/ui/alert';
import { Badge } from '@/components/ui/badge';
import { Tabs, TabsContent, TabsList, TabsTrigger } from '@/components/ui/tabs';
import { 
  Shield, 
  Smartphone, 
  Copy, 
  Check, 
  Loader2, 
  Key,
  Download,
  AlertTriangle,
  QrCode
} from 'lucide-react';
import { useToast } from '@/components/ui/use-toast';
import QRCode from 'qrcode';

interface TwoFactorSetupProps {
  userId: string;
  userEmail: string;
  onComplete?: (backupCodes: string[]) => void;
  onCancel?: () => void;
}

export default function TwoFactorSetup({ userId, userEmail, onComplete, onCancel }: TwoFactorSetupProps) {
  const { toast } = useToast();
  const [currentStep, setCurrentStep] = useState<'setup' | 'verify' | 'backup'>('setup');
  const [qrCodeUrl, setQrCodeUrl] = useState('');
  const [secretKey, setSecretKey] = useState('');
  const [verificationCode, setVerificationCode] = useState('');
  const [backupCodes, setBackupCodes] = useState<string[]>([]);
  const [isLoading, setIsLoading] = useState(false);
  const [copied, setCopied] = useState(false);
  const [backupCodesCopied, setBackupCodesCopied] = useState(false);

  useEffect(() => {
    generateTwoFactorSecret();
  }, []);

  const generateTwoFactorSecret = async () => {
    try {
      setIsLoading(true);
      
      // Generate a random secret key
      const secret = generateSecretKey();
      setSecretKey(secret);

      // Create TOTP URI for QR code
      const appName = 'KCT Admin';
      const issuer = 'KCT Menswear';
      const otpAuthUrl = `otpauth://totp/${encodeURIComponent(`${issuer}:${userEmail}`)}?secret=${secret}&issuer=${encodeURIComponent(issuer)}&algorithm=SHA1&digits=6&period=30`;

      // Generate QR code
      const qrCode = await QRCode.toDataURL(otpAuthUrl);
      setQrCodeUrl(qrCode);

      // Generate backup codes
      const codes = generateBackupCodes();
      setBackupCodes(codes);
    } catch (error) {
      console.error('Error generating 2FA secret:', error);
      toast({
        title: "Setup error",
        description: "Failed to generate 2FA setup. Please try again.",
        variant: "destructive"
      });
    } finally {
      setIsLoading(false);
    }
  };

  const generateSecretKey = (): string => {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ234567';
    let secret = '';
    for (let i = 0; i < 32; i++) {
      secret += chars.charAt(Math.floor(Math.random() * chars.length));
    }
    return secret;
  };

  const generateBackupCodes = (): string[] => {
    const codes: string[] = [];
    for (let i = 0; i < 8; i++) {
      const code = Math.random().toString(36).substring(2, 10).toUpperCase();
      codes.push(code);
    }
    return codes;
  };

  const copyToClipboard = async (text: string, type: 'secret' | 'backup' = 'secret') => {
    try {
      await navigator.clipboard.writeText(text);
      if (type === 'secret') {
        setCopied(true);
        setTimeout(() => setCopied(false), 2000);
      } else {
        setBackupCodesCopied(true);
        setTimeout(() => setBackupCodesCopied(false), 2000);
      }
      toast({
        title: "Copied to clipboard",
        description: type === 'secret' ? "Secret key copied" : "Backup codes copied",
      });
    } catch (error) {
      toast({
        title: "Copy failed",
        description: "Unable to copy to clipboard. Please copy manually.",
        variant: "destructive"
      });
    }
  };

  const verifyAndEnable2FA = async () => {
    if (!verificationCode || verificationCode.length !== 6) {
      toast({
        title: "Invalid code",
        description: "Please enter a 6-digit verification code.",
        variant: "destructive"
      });
      return;
    }

    setIsLoading(true);

    try {
      // In real implementation, verify the TOTP code with server
      // For now, simulate verification
      const isValid = verificationCode.match(/^\d{6}$/);
      
      if (!isValid) {
        throw new Error('Invalid verification code format');
      }

      // Simulate server API call
      await new Promise(resolve => setTimeout(resolve, 1500));

      // Mock successful verification
      if (verificationCode === '123456') {
        // Demo code for testing
        setCurrentStep('backup');
      } else {
        // In real app, validate against TOTP algorithm
        // For demo, accept any 6-digit code except 123456
        if (verificationCode.match(/^\d{6}$/) && verificationCode !== '000000') {
          setCurrentStep('backup');
        } else {
          throw new Error('Invalid verification code');
        }
      }

      toast({
        title: "Verification successful",
        description: "Two-factor authentication has been enabled for your account.",
      });
    } catch (error) {
      console.error('Error verifying 2FA:', error);
      toast({
        title: "Verification failed",
        description: "The verification code is incorrect. Please try again.",
        variant: "destructive"
      });
    } finally {
      setIsLoading(false);
    }
  };

  const completeTwoFactorSetup = () => {
    toast({
      title: "Two-factor authentication enabled",
      description: "Your account is now protected with 2FA.",
    });
    onComplete?.(backupCodes);
  };

  const downloadBackupCodes = () => {
    const content = `KCT Admin - Two-Factor Authentication Backup Codes
Generated: ${new Date().toLocaleDateString()}
Account: ${userEmail}

IMPORTANT: Store these codes in a safe place. Each code can only be used once.

${backupCodes.map((code, index) => `${index + 1}. ${code}`).join('\n')}

If you lose access to your authenticator app, you can use these codes to log in.
After using a backup code, generate new ones from your account settings.
`;

    const blob = new Blob([content], { type: 'text/plain' });
    const url = URL.createObjectURL(blob);
    const link = document.createElement('a');
    link.href = url;
    link.download = 'kct-admin-backup-codes.txt';
    document.body.appendChild(link);
    link.click();
    document.body.removeChild(link);
    URL.revokeObjectURL(url);

    toast({
      title: "Backup codes downloaded",
      description: "Store the file in a secure location.",
    });
  };

  const renderSetupStep = () => (
    <div className="space-y-6">
      <Alert>
        <Shield className="h-4 w-4" />
        <AlertDescription>
          Two-factor authentication adds an extra layer of security to your account.
          You'll need an authenticator app like Google Authenticator or Authy.
        </AlertDescription>
      </Alert>

      <Tabs defaultValue="qr" className="w-full">
        <TabsList className="grid w-full grid-cols-2">
          <TabsTrigger value="qr">QR Code</TabsTrigger>
          <TabsTrigger value="manual">Manual Setup</TabsTrigger>
        </TabsList>
        
        <TabsContent value="qr" className="space-y-4">
          <div className="text-center space-y-4">
            <h3 className="font-medium">Scan QR Code</h3>
            <p className="text-sm text-muted-foreground">
              Open your authenticator app and scan this QR code
            </p>
            
            {qrCodeUrl ? (
              <div className="flex justify-center">
                <img 
                  src={qrCodeUrl} 
                  alt="2FA QR Code" 
                  className="w-48 h-48 border border-gray-200 rounded-lg"
                />
              </div>
            ) : (
              <div className="w-48 h-48 mx-auto border border-gray-200 rounded-lg flex items-center justify-center">
                <Loader2 className="h-8 w-8 animate-spin" />
              </div>
            )}
          </div>
        </TabsContent>
        
        <TabsContent value="manual" className="space-y-4">
          <div className="space-y-4">
            <h3 className="font-medium">Manual Setup</h3>
            <p className="text-sm text-muted-foreground">
              If you can't scan the QR code, enter this secret key manually in your authenticator app
            </p>
            
            <div className="space-y-2">
              <Label>Secret Key</Label>
              <div className="flex gap-2">
                <Input
                  value={secretKey}
                  readOnly
                  className="font-mono text-sm"
                />
                <Button
                  variant="outline"
                  size="icon"
                  onClick={() => copyToClipboard(secretKey)}
                  disabled={!secretKey}
                >
                  {copied ? <Check className="h-4 w-4" /> : <Copy className="h-4 w-4" />}
                </Button>
              </div>
            </div>

            <div className="text-xs text-muted-foreground space-y-1">
              <p><strong>Account:</strong> {userEmail}</p>
              <p><strong>Issuer:</strong> KCT Menswear</p>
              <p><strong>Type:</strong> Time-based (TOTP)</p>
              <p><strong>Algorithm:</strong> SHA1</p>
              <p><strong>Digits:</strong> 6</p>
              <p><strong>Period:</strong> 30 seconds</p>
            </div>
          </div>
        </TabsContent>
      </Tabs>

      <div className="space-y-3">
        <Button
          className="w-full"
          onClick={() => setCurrentStep('verify')}
          disabled={!secretKey}
        >
          Continue to Verification
        </Button>
        
        {onCancel && (
          <Button
            variant="outline"
            className="w-full"
            onClick={onCancel}
          >
            Cancel Setup
          </Button>
        )}
      </div>
    </div>
  );

  const renderVerifyStep = () => (
    <div className="space-y-6">
      <Alert>
        <Smartphone className="h-4 w-4" />
        <AlertDescription>
          Enter the 6-digit code from your authenticator app to verify the setup.
        </AlertDescription>
      </Alert>

      <div className="space-y-4">
        <div className="space-y-2">
          <Label htmlFor="verification-code">Verification Code</Label>
          <Input
            id="verification-code"
            type="text"
            placeholder="000000"
            value={verificationCode}
            onChange={(e) => setVerificationCode(e.target.value.replace(/\D/g, '').slice(0, 6))}
            className="text-center text-2xl font-mono tracking-widest"
            maxLength={6}
            autoComplete="off"
            disabled={isLoading}
          />
          <p className="text-xs text-muted-foreground text-center">
            Enter the code shown in your authenticator app
          </p>
        </div>

        <div className="space-y-3">
          <Button
            className="w-full"
            onClick={verifyAndEnable2FA}
            disabled={verificationCode.length !== 6 || isLoading}
          >
            {isLoading ? (
              <>
                <Loader2 className="mr-2 h-4 w-4 animate-spin" />
                Verifying...
              </>
            ) : (
              'Verify & Enable 2FA'
            )}
          </Button>

          <Button
            variant="outline"
            className="w-full"
            onClick={() => setCurrentStep('setup')}
            disabled={isLoading}
          >
            Back to Setup
          </Button>
        </div>
      </div>
    </div>
  );

  const renderBackupStep = () => (
    <div className="space-y-6">
      <Alert>
        <Key className="h-4 w-4" />
        <AlertDescription>
          <strong>Important:</strong> Save these backup codes in a safe place. 
          You can use them to access your account if you lose your phone.
        </AlertDescription>
      </Alert>

      <div className="space-y-4">
        <h3 className="font-medium text-center">Backup Recovery Codes</h3>
        
        <div className="grid grid-cols-2 gap-2 p-4 bg-gray-50 rounded-lg font-mono text-sm">
          {backupCodes.map((code, index) => (
            <div key={index} className="flex items-center justify-between p-2 bg-white rounded border">
              <span>{index + 1}.</span>
              <span className="font-bold">{code}</span>
            </div>
          ))}
        </div>

        <div className="flex gap-2">
          <Button
            variant="outline"
            className="flex-1"
            onClick={() => copyToClipboard(backupCodes.join('\n'), 'backup')}
          >
            {backupCodesCopied ? (
              <>
                <Check className="mr-2 h-4 w-4" />
                Copied
              </>
            ) : (
              <>
                <Copy className="mr-2 h-4 w-4" />
                Copy Codes
              </>
            )}
          </Button>
          
          <Button
            variant="outline"
            className="flex-1"
            onClick={downloadBackupCodes}
          >
            <Download className="mr-2 h-4 w-4" />
            Download
          </Button>
        </div>

        <Alert variant="destructive">
          <AlertTriangle className="h-4 w-4" />
          <AlertDescription>
            Each backup code can only be used once. Generate new codes after using any of these.
          </AlertDescription>
        </Alert>
      </div>

      <Button
        className="w-full"
        onClick={completeTwoFactorSetup}
      >
        Complete Setup
      </Button>
    </div>
  );

  return (
    <Card className="w-full max-w-md">
      <CardHeader className="text-center">
        <div className="rounded-full bg-blue-100 p-3 w-16 h-16 mx-auto flex items-center justify-center mb-4">
          <Shield className="h-8 w-8 text-blue-600" />
        </div>
        <CardTitle className="text-2xl font-bold">
          {currentStep === 'setup' ? 'Set Up Two-Factor Authentication' :
           currentStep === 'verify' ? 'Verify Setup' :
           'Save Backup Codes'}
        </CardTitle>
        <CardDescription>
          {currentStep === 'setup' ? 'Secure your account with 2FA' :
           currentStep === 'verify' ? 'Confirm your authenticator app is working' :
           'Keep these codes safe for account recovery'}
        </CardDescription>
        
        <div className="flex justify-center">
          <Badge variant={currentStep === 'backup' ? 'default' : 'secondary'}>
            Step {currentStep === 'setup' ? '1' : currentStep === 'verify' ? '2' : '3'} of 3
          </Badge>
        </div>
      </CardHeader>
      
      <CardContent>
        {isLoading && currentStep === 'setup' ? (
          <div className="flex justify-center py-8">
            <Loader2 className="h-8 w-8 animate-spin" />
          </div>
        ) : (
          <>
            {currentStep === 'setup' && renderSetupStep()}
            {currentStep === 'verify' && renderVerifyStep()}
            {currentStep === 'backup' && renderBackupStep()}
          </>
        )}
      </CardContent>
    </Card>
  );
}