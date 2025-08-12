import { useState, useEffect } from 'react';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { Label } from '@/components/ui/label';
import { Alert, AlertDescription } from '@/components/ui/alert';
import { HelpCircle, Shield, Loader2, AlertTriangle, CheckCircle } from 'lucide-react';
import { useToast } from '@/components/ui/use-toast';
import { verifySecurityQuestions } from '@/lib/services/authService';

interface SecurityQuestionsVerifyProps {
  email: string;
  onSuccess?: (userId: string) => void;
  onCancel?: () => void;
}

// Mock security questions - in real app, fetch from API based on email
const MOCK_QUESTIONS = [
  { id: '1', question: "What was the name of your first pet?" },
  { id: '2', question: "What city were you born in?" },
  { id: '3', question: "What was the name of your elementary school?" }
];

export default function SecurityQuestionsVerify({ email, onSuccess, onCancel }: SecurityQuestionsVerifyProps) {
  const { toast } = useToast();
  const [answers, setAnswers] = useState<{ [key: string]: string }>({});
  const [isLoading, setIsLoading] = useState(false);
  const [attempts, setAttempts] = useState(0);
  const [isLocked, setIsLocked] = useState(false);
  const [questions, setQuestions] = useState(MOCK_QUESTIONS);

  const MAX_ATTEMPTS = 3;

  useEffect(() => {
    // In real implementation, fetch security questions for the email
    // For now, using mock data
    setQuestions(MOCK_QUESTIONS);
  }, [email]);

  const updateAnswer = (questionId: string, value: string) => {
    setAnswers(prev => ({ ...prev, [questionId]: value }));
  };

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    
    if (isLocked) {
      toast({
        title: "Account temporarily locked",
        description: "Too many failed attempts. Please try again later or use another recovery method.",
        variant: "destructive"
      });
      return;
    }

    setIsLoading(true);

    try {
      const answerArray = questions.map(q => ({
        questionId: q.id,
        answer: answers[q.id] || ''
      }));

      const result = await verifySecurityQuestions(email, answerArray);

      if (result.success && result.userId) {
        toast({
          title: "Verification successful",
          description: "Your identity has been verified. You can now reset your password.",
        });
        onSuccess?.(result.userId);
      } else {
        const newAttempts = attempts + 1;
        setAttempts(newAttempts);

        if (newAttempts >= MAX_ATTEMPTS) {
          setIsLocked(true);
          toast({
            title: "Too many failed attempts",
            description: "Account temporarily locked for security. Please try another recovery method.",
            variant: "destructive"
          });
        } else {
          toast({
            title: "Verification failed",
            description: `${result.error}. ${MAX_ATTEMPTS - newAttempts} attempts remaining.`,
            variant: "destructive"
          });
        }
      }
    } catch (error) {
      console.error('Error verifying security questions:', error);
      toast({
        title: "Verification error",
        description: "An error occurred during verification. Please try again.",
        variant: "destructive"
      });
    } finally {
      setIsLoading(false);
    }
  };

  const canSubmit = questions.every(q => answers[q.id]?.trim()) && !isLocked;

  return (
    <Card className="w-full max-w-lg">
      <CardHeader className="text-center">
        <div className={`rounded-full p-3 w-16 h-16 mx-auto flex items-center justify-center mb-4 ${
          isLocked ? 'bg-red-100' : 'bg-blue-100'
        }`}>
          {isLocked ? (
            <AlertTriangle className="h-8 w-8 text-red-600" />
          ) : (
            <HelpCircle className="h-8 w-8 text-blue-600" />
          )}
        </div>
        <CardTitle className="text-2xl font-bold">
          {isLocked ? 'Account Temporarily Locked' : 'Answer Security Questions'}
        </CardTitle>
        <CardDescription>
          {isLocked ? (
            "Too many failed attempts. Please use another recovery method."
          ) : (
            `Answer these security questions to verify your identity for ${email}`
          )}
        </CardDescription>
      </CardHeader>
      <CardContent>
        {attempts > 0 && attempts < MAX_ATTEMPTS && (
          <Alert variant="destructive" className="mb-4">
            <AlertTriangle className="h-4 w-4" />
            <AlertDescription>
              {attempts === 1 ? '1 failed attempt' : `${attempts} failed attempts`}. 
              {` ${MAX_ATTEMPTS - attempts} attempts remaining.`}
            </AlertDescription>
          </Alert>
        )}

        {isLocked ? (
          <div className="space-y-4">
            <Alert variant="destructive">
              <AlertTriangle className="h-4 w-4" />
              <AlertDescription>
                Your account has been temporarily locked due to too many failed verification attempts.
                This is a security measure to protect your account.
              </AlertDescription>
            </Alert>

            <div className="space-y-3">
              <p className="text-sm text-muted-foreground">
                You can try the following alternatives:
              </p>
              <ul className="text-sm space-y-2">
                <li className="flex items-center gap-2">
                  <CheckCircle className="h-4 w-4 text-green-600" />
                  Wait 15 minutes and try again
                </li>
                <li className="flex items-center gap-2">
                  <CheckCircle className="h-4 w-4 text-green-600" />
                  Use email reset link instead
                </li>
                <li className="flex items-center gap-2">
                  <CheckCircle className="h-4 w-4 text-green-600" />
                  Contact support for assistance
                </li>
              </ul>
            </div>

            {onCancel && (
              <Button
                variant="outline"
                className="w-full"
                onClick={onCancel}
              >
                Try Another Method
              </Button>
            )}
          </div>
        ) : (
          <>
            <Alert className="mb-6">
              <Shield className="h-4 w-4" />
              <AlertDescription>
                Your answers are case-insensitive. Enter them exactly as you set them up.
              </AlertDescription>
            </Alert>

            <form onSubmit={handleSubmit} className="space-y-6">
              {questions.map((question, index) => (
                <div key={question.id} className="space-y-2">
                  <Label htmlFor={`answer-${question.id}`}>
                    Security Question {index + 1}
                  </Label>
                  <p className="text-sm font-medium text-gray-700 mb-2">
                    {question.question}
                  </p>
                  <Input
                    id={`answer-${question.id}`}
                    type="text"
                    placeholder="Enter your answer"
                    value={answers[question.id] || ''}
                    onChange={(e) => updateAnswer(question.id, e.target.value)}
                    disabled={isLoading}
                    className="w-full"
                    autoComplete="off"
                  />
                </div>
              ))}

              <div className="space-y-3 pt-4">
                <Button
                  type="submit"
                  className="w-full"
                  disabled={!canSubmit || isLoading}
                >
                  {isLoading ? (
                    <>
                      <Loader2 className="mr-2 h-4 w-4 animate-spin" />
                      Verifying answers...
                    </>
                  ) : (
                    'Verify Identity'
                  )}
                </Button>

                {onCancel && (
                  <Button
                    type="button"
                    variant="outline"
                    className="w-full"
                    onClick={onCancel}
                    disabled={isLoading}
                  >
                    Use Different Method
                  </Button>
                )}
              </div>
            </form>

            <div className="mt-6 p-4 bg-gray-50 rounded-lg">
              <h4 className="font-medium text-sm mb-2">Having trouble?</h4>
              <ul className="text-xs text-muted-foreground space-y-1">
                <li>• Answers are not case-sensitive</li>
                <li>• Make sure to enter answers exactly as you set them</li>
                <li>• If you can't remember, try the email reset option</li>
                <li>• Contact support if you need additional help</li>
              </ul>
            </div>
          </>
        )}
      </CardContent>
    </Card>
  );
}