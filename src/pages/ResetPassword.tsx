import { useState, useEffect } from 'react';
import { useNavigate, useSearchParams } from 'react-router-dom';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { Label } from '@/components/ui/label';
import { Alert, AlertDescription } from '@/components/ui/alert';
// import { Progress } from '@/components/ui/progress'; // May not exist
import { Badge } from '@/components/ui/badge';
import { Lock, Eye, EyeOff, CheckCircle, XCircle, Loader2, Shield, AlertTriangle } from 'lucide-react';
import { usePasswordReset } from '@/hooks/usePasswordReset';
import { supabase } from '@/lib/supabase-client';

export default function ResetPassword() {
  const navigate = useNavigate();
  const [searchParams] = useSearchParams();
  const { resetPassword, isLoading } = usePasswordReset();
  
  const [password, setPassword] = useState('');
  const [confirmPassword, setConfirmPassword] = useState('');
  const [showPassword, setShowPassword] = useState(false);
  const [showConfirmPassword, setShowConfirmPassword] = useState(false);
  const [validationErrors, setValidationErrors] = useState<string[]>([]);
  const [tokenValid, setTokenValid] = useState<boolean | null>(null);
  const [passwordStrength, setPasswordStrength] = useState(0);
  const [strengthDetails, setStrengthDetails] = useState<{
    length: boolean;
    uppercase: boolean;
    lowercase: boolean;
    number: boolean;
    special: boolean;
    common: boolean;
  }>({
    length: false,
    uppercase: false,
    lowercase: false,
    number: false,
    special: false,
    common: true
  });

  useEffect(() => {
    // Check if we have a valid session from the reset link
    checkResetToken();
  }, []);

  const checkResetToken = async () => {
    try {
      const { data: { session }, error } = await supabase.auth.getSession();
      
      if (error || !session) {
        setTokenValid(false);
        return;
      }
      
      setTokenValid(true);
    } catch (error) {
      console.error('Error checking reset token:', error);
      setTokenValid(false);
    }
  };

  // Common weak passwords list (subset)
  const commonPasswords = [
    'password', '123456', '12345678', 'qwerty', 'abc123', 'password123',
    'admin', 'letmein', 'welcome', '123456789', 'password1', 'iloveyou'
  ];

  const calculatePasswordStrength = (pass: string) => {
    const checks = {
      length: pass.length >= 12,
      uppercase: /[A-Z]/.test(pass),
      lowercase: /[a-z]/.test(pass),
      number: /\d/.test(pass),
      special: /[!@#$%^&*()_+\-=\[\]{};':"\\|,.<>\/?~`]/.test(pass),
      common: !commonPasswords.includes(pass.toLowerCase()) && pass.length > 0
    };

    setStrengthDetails(checks);

    // Calculate strength score
    let score = 0;
    if (checks.length) score += 25;
    if (checks.uppercase && checks.lowercase) score += 20;
    if (checks.number) score += 15;
    if (checks.special) score += 20;
    if (checks.common) score += 20;

    // Bonus for longer passwords
    if (pass.length >= 16) score += 10;
    if (pass.length >= 20) score += 10;

    setPasswordStrength(Math.min(score, 100));
    return score;
  };

  const validatePassword = (pass: string): string[] => {
    const errors: string[] = [];
    
    if (pass.length < 8) {
      errors.push('Password must be at least 8 characters long');
    }
    if (!/[A-Z]/.test(pass)) {
      errors.push('Password must contain at least one uppercase letter');
    }
    if (!/[a-z]/.test(pass)) {
      errors.push('Password must contain at least one lowercase letter');
    }
    if (!/\d/.test(pass)) {
      errors.push('Password must contain at least one number');
    }
    if (!/[!@#$%^&*()_+\-=\[\]{};':"\\|,.<>\/?~`]/.test(pass)) {
      errors.push('Password should contain at least one special character');
    }
    if (commonPasswords.includes(pass.toLowerCase())) {
      errors.push('Password is too common, please choose a more secure password');
    }
    if (pass.length < 12) {
      errors.push('For better security, use at least 12 characters');
    }
    
    return errors;
  };

  const handlePasswordChange = (value: string) => {
    setPassword(value);
    calculatePasswordStrength(value);
    setValidationErrors(validatePassword(value));
  };

  const getStrengthLabel = (strength: number): { label: string; color: string } => {
    if (strength < 25) return { label: 'Very Weak', color: 'text-red-600' };
    if (strength < 50) return { label: 'Weak', color: 'text-orange-600' };
    if (strength < 75) return { label: 'Good', color: 'text-yellow-600' };
    if (strength < 90) return { label: 'Strong', color: 'text-green-600' };
    return { label: 'Very Strong', color: 'text-green-700' };
  };

  const getStrengthColor = (strength: number): string => {
    if (strength < 25) return 'bg-red-500';
    if (strength < 50) return 'bg-orange-500';
    if (strength < 75) return 'bg-yellow-500';
    return 'bg-green-500';
  };

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    
    if (password !== confirmPassword) {
      setValidationErrors(['Passwords do not match']);
      return;
    }

    const errors = validatePassword(password);
    if (errors.length > 0) {
      setValidationErrors(errors);
      return;
    }

    const token = searchParams.get('token') || '';
    const success = await resetPassword(token, password);
    
    if (success) {
      // Redirect handled by the hook
    }
  };

  if (tokenValid === false) {
    return (
      <div className="min-h-screen flex items-center justify-center bg-gray-50 p-4">
        <Card className="w-full max-w-md">
          <CardHeader className="text-center">
            <CardTitle className="text-2xl font-bold text-red-600">Invalid or Expired Link</CardTitle>
            <CardDescription>
              This password reset link is invalid or has expired.
            </CardDescription>
          </CardHeader>
          <CardContent className="space-y-4">
            <Alert variant="destructive">
              <XCircle className="h-4 w-4" />
              <AlertDescription>
                Password reset links expire after 1 hour for security reasons.
              </AlertDescription>
            </Alert>
            
            <Button 
              onClick={() => navigate('/forgot-password')}
              className="w-full"
            >
              Request New Reset Link
            </Button>
            
            <Button 
              variant="outline"
              onClick={() => navigate('/login')}
              className="w-full"
            >
              Back to Login
            </Button>
          </CardContent>
        </Card>
      </div>
    );
  }

  if (tokenValid === null) {
    return (
      <div className="min-h-screen flex items-center justify-center bg-gray-50">
        <Loader2 className="h-8 w-8 animate-spin text-primary" />
      </div>
    );
  }

  return (
    <div className="min-h-screen flex items-center justify-center bg-gray-50 p-4">
      <Card className="w-full max-w-md">
        <CardHeader className="text-center">
          <CardTitle className="text-2xl font-bold">Reset Your Password</CardTitle>
          <CardDescription>
            Enter your new password below
          </CardDescription>
        </CardHeader>
        <CardContent>
          <form onSubmit={handleSubmit} className="space-y-4">
            <div className="space-y-2">
              <Label htmlFor="password">New Password</Label>
              <div className="relative">
                <Input
                  id="password"
                  type={showPassword ? 'text' : 'password'}
                  value={password}
                  onChange={(e) => handlePasswordChange(e.target.value)}
                  required
                  disabled={isLoading}
                  className="pr-10"
                  placeholder="Enter new password"
                />
                <button
                  type="button"
                  onClick={() => setShowPassword(!showPassword)}
                  className="absolute right-3 top-1/2 -translate-y-1/2 text-gray-500 hover:text-gray-700"
                >
                  {showPassword ? <EyeOff className="h-4 w-4" /> : <Eye className="h-4 w-4" />}
                </button>
              </div>
            </div>

            <div className="space-y-2">
              <Label htmlFor="confirmPassword">Confirm Password</Label>
              <div className="relative">
                <Input
                  id="confirmPassword"
                  type={showConfirmPassword ? 'text' : 'password'}
                  value={confirmPassword}
                  onChange={(e) => setConfirmPassword(e.target.value)}
                  required
                  disabled={isLoading}
                  className="pr-10"
                  placeholder="Confirm new password"
                />
                <button
                  type="button"
                  onClick={() => setShowConfirmPassword(!showConfirmPassword)}
                  className="absolute right-3 top-1/2 -translate-y-1/2 text-gray-500 hover:text-gray-700"
                >
                  {showConfirmPassword ? <EyeOff className="h-4 w-4" /> : <Eye className="h-4 w-4" />}
                </button>
              </div>
            </div>

            {/* Password strength indicator */}
            {password && (
              <div className="space-y-3">
                <div className="space-y-2">
                  <div className="flex items-center justify-between">
                    <span className="text-sm font-medium">Password Strength</span>
                    <Badge 
                      variant={passwordStrength >= 75 ? 'default' : passwordStrength >= 50 ? 'secondary' : 'destructive'}
                      className={getStrengthLabel(passwordStrength).color}
                    >
                      {getStrengthLabel(passwordStrength).label}
                    </Badge>
                  </div>
                  <div className="w-full bg-gray-200 rounded-full h-2">
                    <div 
                      className={`h-2 rounded-full transition-all duration-300 ${getStrengthColor(passwordStrength)}`}
                      style={{ width: `${passwordStrength}%` }}
                    />
                  </div>
                </div>

                <div className="space-y-2 text-sm">
                  <p className="font-medium text-gray-700">Password requirements:</p>
                  <div className="grid grid-cols-2 gap-2">
                    <div className={`flex items-center gap-2 ${strengthDetails.length ? 'text-green-600' : 'text-gray-400'}`}>
                      {strengthDetails.length ? <CheckCircle className="h-3 w-3" /> : <XCircle className="h-3 w-3" />}
                      <span className="text-xs">12+ characters</span>
                    </div>
                    <div className={`flex items-center gap-2 ${strengthDetails.uppercase ? 'text-green-600' : 'text-gray-400'}`}>
                      {strengthDetails.uppercase ? <CheckCircle className="h-3 w-3" /> : <XCircle className="h-3 w-3" />}
                      <span className="text-xs">Uppercase (A-Z)</span>
                    </div>
                    <div className={`flex items-center gap-2 ${strengthDetails.lowercase ? 'text-green-600' : 'text-gray-400'}`}>
                      {strengthDetails.lowercase ? <CheckCircle className="h-3 w-3" /> : <XCircle className="h-3 w-3" />}
                      <span className="text-xs">Lowercase (a-z)</span>
                    </div>
                    <div className={`flex items-center gap-2 ${strengthDetails.number ? 'text-green-600' : 'text-gray-400'}`}>
                      {strengthDetails.number ? <CheckCircle className="h-3 w-3" /> : <XCircle className="h-3 w-3" />}
                      <span className="text-xs">Number (0-9)</span>
                    </div>
                    <div className={`flex items-center gap-2 ${strengthDetails.special ? 'text-green-600' : 'text-gray-400'}`}>
                      {strengthDetails.special ? <CheckCircle className="h-3 w-3" /> : <XCircle className="h-3 w-3" />}
                      <span className="text-xs">Special chars</span>
                    </div>
                    <div className={`flex items-center gap-2 ${strengthDetails.common ? 'text-green-600' : 'text-red-600'}`}>
                      {strengthDetails.common ? <CheckCircle className="h-3 w-3" /> : <AlertTriangle className="h-3 w-3" />}
                      <span className="text-xs">Not common</span>
                    </div>
                  </div>
                </div>

                {passwordStrength < 50 && (
                  <Alert variant="destructive">
                    <AlertTriangle className="h-4 w-4" />
                    <AlertDescription>
                      Weak password detected. Consider using a longer password with mixed characters.
                    </AlertDescription>
                  </Alert>
                )}
              </div>
            )}

            {/* Password mismatch alert */}
            {password && confirmPassword && password !== confirmPassword && (
              <Alert variant="destructive">
                <AlertTriangle className="h-4 w-4" />
                <AlertDescription>
                  Passwords do not match
                </AlertDescription>
              </Alert>
            )}

            {/* Security tips */}
            <Alert>
              <Shield className="h-4 w-4" />
              <AlertDescription>
                <strong>Security tips:</strong> Use a unique password you haven't used before. 
                Consider using a passphrase with mixed case, numbers, and symbols.
              </AlertDescription>
            </Alert>

            {validationErrors.length > 0 && password && confirmPassword && (
              <Alert variant="destructive">
                <AlertDescription>
                  {validationErrors[0]}
                </AlertDescription>
              </Alert>
            )}

            <Button 
              type="submit" 
              className="w-full"
              disabled={
                isLoading || 
                !password || 
                !confirmPassword || 
                password !== confirmPassword || 
                passwordStrength < 60 ||
                !strengthDetails.common
              }
            >
              {isLoading ? (
                <>
                  <Loader2 className="mr-2 h-4 w-4 animate-spin" />
                  Resetting Password...
                </>
              ) : (
                <>
                  <Lock className="mr-2 h-4 w-4" />
                  Reset Password
                </>
              )}
            </Button>

            {password && confirmPassword && password === confirmPassword && passwordStrength < 60 && (
              <p className="text-sm text-orange-600 text-center">
                Password strength must be at least "Good" to proceed
              </p>
            )}
          </form>
        </CardContent>
      </Card>
    </div>
  );
}