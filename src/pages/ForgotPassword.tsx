import { useState } from 'react';
import { Link } from 'react-router-dom';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { Label } from '@/components/ui/label';
import { Alert, AlertDescription } from '@/components/ui/alert';
import { Mail, ArrowLeft, Loader2, Shield, Key, HelpCircle } from 'lucide-react';
import { usePasswordReset } from '@/hooks/usePasswordReset';
import { getAccountRecoveryOptions } from '@/lib/services/authService';

export default function ForgotPassword() {
  const { requestPasswordReset, isLoading } = usePasswordReset();
  const [email, setEmail] = useState('');
  const [submitted, setSubmitted] = useState(false);
  const [recoveryStep, setRecoveryStep] = useState<'email' | 'options' | 'security_questions'>('email');
  const [recoveryOptions, setRecoveryOptions] = useState<any>(null);
  const [securityAnswers, setSecurityAnswers] = useState<{ [key: string]: string }>({});

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    
    // First check if account has recovery options
    if (recoveryStep === 'email') {
      const options = await getAccountRecoveryOptions(email);
      if (options && (options.hasSecurityQuestions || options.hasBackupEmail)) {
        setRecoveryOptions(options);
        setRecoveryStep('options');
        return;
      }
    }

    // Default email reset
    const success = await requestPasswordReset(email);
    if (success) {
      setSubmitted(true);
    }
  };

  const handleSecurityQuestions = () => {
    setRecoveryStep('security_questions');
  };

  const handleBackupEmail = async () => {
    // TODO: Implement backup email reset
    const success = await requestPasswordReset(email);
    if (success) {
      setSubmitted(true);
    }
  };

  const renderEmailStep = () => (
    <form onSubmit={handleSubmit} className="space-y-4">
      <div className="space-y-2">
        <Label htmlFor="email">Email Address</Label>
        <Input
          id="email"
          type="email"
          placeholder="admin@kctmenswear.com"
          value={email}
          onChange={(e) => setEmail(e.target.value)}
          required
          disabled={isLoading}
          className="w-full"
        />
      </div>

      <Button 
        type="submit" 
        className="w-full"
        disabled={isLoading || !email}
      >
        {isLoading ? (
          <>
            <Loader2 className="mr-2 h-4 w-4 animate-spin" />
            Checking account...
          </>
        ) : (
          <>
            <Mail className="mr-2 h-4 w-4" />
            Continue
          </>
        )}
      </Button>

      <div className="text-center text-sm">
        <Link 
          to="/login" 
          className="text-primary hover:underline inline-flex items-center"
        >
          <ArrowLeft className="mr-1 h-3 w-3" />
          Back to Login
        </Link>
      </div>
    </form>
  );

  const renderRecoveryOptions = () => (
    <div className="space-y-4">
      <Alert>
        <Shield className="h-4 w-4" />
        <AlertDescription>
          Multiple recovery options are available for your account. Choose your preferred method:
        </AlertDescription>
      </Alert>

      <div className="space-y-3">
        <Button 
          variant="outline"
          className="w-full justify-start h-auto p-4"
          onClick={() => handleSubmit(new Event('submit') as any)}
          disabled={isLoading}
        >
          <div className="flex items-center space-x-3">
            <Mail className="h-5 w-5 text-blue-500" />
            <div className="text-left">
              <div className="font-medium">Email Reset Link</div>
              <div className="text-sm text-muted-foreground">Send reset link to {email}</div>
            </div>
          </div>
        </Button>

        {recoveryOptions?.hasSecurityQuestions && (
          <Button 
            variant="outline"
            className="w-full justify-start h-auto p-4"
            onClick={handleSecurityQuestions}
            disabled={isLoading}
          >
            <div className="flex items-center space-x-3">
              <HelpCircle className="h-5 w-5 text-green-500" />
              <div className="text-left">
                <div className="font-medium">Security Questions</div>
                <div className="text-sm text-muted-foreground">Answer your security questions</div>
              </div>
            </div>
          </Button>
        )}

        {recoveryOptions?.hasBackupEmail && recoveryOptions?.backupEmailVerified && (
          <Button 
            variant="outline"
            className="w-full justify-start h-auto p-4"
            onClick={handleBackupEmail}
            disabled={isLoading}
          >
            <div className="flex items-center space-x-3">
              <Key className="h-5 w-5 text-purple-500" />
              <div className="text-left">
                <div className="font-medium">Backup Email</div>
                <div className="text-sm text-muted-foreground">Send reset link to backup email</div>
              </div>
            </div>
          </Button>
        )}
      </div>

      <div className="text-center text-sm">
        <Button 
          variant="ghost"
          onClick={() => setRecoveryStep('email')}
          className="text-muted-foreground"
        >
          <ArrowLeft className="mr-1 h-3 w-3" />
          Back
        </Button>
      </div>
    </div>
  );

  const renderSecurityQuestions = () => (
    <div className="space-y-4">
      <Alert>
        <HelpCircle className="h-4 w-4" />
        <AlertDescription>
          Answer your security questions to reset your password.
        </AlertDescription>
      </Alert>

      <div className="space-y-4">
        {/* Mock security questions - in real implementation, fetch from API */}
        <div className="space-y-2">
          <Label>What was the name of your first pet?</Label>
          <Input
            type="text"
            placeholder="Enter your answer"
            value={securityAnswers['pet'] || ''}
            onChange={(e) => setSecurityAnswers({...securityAnswers, pet: e.target.value})}
            disabled={isLoading}
          />
        </div>

        <div className="space-y-2">
          <Label>What city were you born in?</Label>
          <Input
            type="text"
            placeholder="Enter your answer"
            value={securityAnswers['city'] || ''}
            onChange={(e) => setSecurityAnswers({...securityAnswers, city: e.target.value})}
            disabled={isLoading}
          />
        </div>

        <Button 
          className="w-full"
          disabled={isLoading || !securityAnswers.pet || !securityAnswers.city}
        >
          {isLoading ? (
            <>
              <Loader2 className="mr-2 h-4 w-4 animate-spin" />
              Verifying...
            </>
          ) : (
            'Verify Answers'
          )}
        </Button>
      </div>

      <div className="text-center text-sm">
        <Button 
          variant="ghost"
          onClick={() => setRecoveryStep('options')}
          className="text-muted-foreground"
        >
          <ArrowLeft className="mr-1 h-3 w-3" />
          Back to options
        </Button>
      </div>
    </div>
  );

  const renderSuccess = () => (
    <div className="text-center space-y-4">
      <div className="rounded-full bg-green-100 p-3 w-16 h-16 mx-auto flex items-center justify-center">
        <Mail className="h-8 w-8 text-green-600" />
      </div>
      
      <div className="space-y-2">
        <h3 className="font-semibold">Check your email</h3>
        <p className="text-sm text-muted-foreground">
          We've sent password reset instructions to:
        </p>
        <p className="font-medium">{email}</p>
      </div>

      <Alert>
        <AlertDescription>
          The reset link will expire in 1 hour for security reasons.
        </AlertDescription>
      </Alert>

      <div className="space-y-3 pt-4">
        <p className="text-xs text-muted-foreground">
          Didn't receive the email? Check your spam folder or
        </p>
        <Button
          variant="outline"
          onClick={() => {
            setSubmitted(false);
            setRecoveryStep('email');
            setEmail('');
            setRecoveryOptions(null);
          }}
          className="w-full"
        >
          Try another method
        </Button>
      </div>
    </div>
  );

  return (
    <div className="min-h-screen flex items-center justify-center bg-gray-50 p-4">
      <Card className="w-full max-w-md">
        <CardHeader className="text-center">
          <CardTitle className="text-2xl font-bold">
            {recoveryStep === 'email' ? 'Forgot Password?' : 
             recoveryStep === 'options' ? 'Account Recovery' :
             recoveryStep === 'security_questions' ? 'Security Questions' :
             'Password Reset'}
          </CardTitle>
          <CardDescription>
            {!submitted ? (
              recoveryStep === 'email' ? "Enter your email address to recover your account" :
              recoveryStep === 'options' ? "Choose your preferred recovery method" :
              recoveryStep === 'security_questions' ? "Answer these questions to verify your identity" :
              "Select a recovery option"
            ) : (
              "Check your email for reset instructions"
            )}
          </CardDescription>
        </CardHeader>
        <CardContent>
          {!submitted ? (
            recoveryStep === 'email' ? renderEmailStep() :
            recoveryStep === 'options' ? renderRecoveryOptions() :
            recoveryStep === 'security_questions' ? renderSecurityQuestions() :
            null
          ) : (
            renderSuccess()
          )}
        </CardContent>
      </Card>
    </div>
  );
}