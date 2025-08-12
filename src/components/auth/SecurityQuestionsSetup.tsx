import { useState } from 'react';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { Label } from '@/components/ui/label';
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from '@/components/ui/select';
import { Alert, AlertDescription } from '@/components/ui/alert';
import { HelpCircle, Shield, Check, Loader2 } from 'lucide-react';
import { useToast } from '@/components/ui/use-toast';
import { setupSecurityQuestions, type SecurityQuestion } from '@/lib/services/authService';

interface SecurityQuestionsSetupProps {
  userId: string;
  onComplete?: () => void;
  onSkip?: () => void;
}

// Predefined security questions
const SECURITY_QUESTIONS = [
  "What was the name of your first pet?",
  "What city were you born in?",
  "What was the name of your elementary school?",
  "What is your mother's maiden name?",
  "What was the make of your first car?",
  "What street did you grow up on?",
  "What was your favorite food as a child?",
  "What is the name of your best childhood friend?",
  "What was the name of your first employer?",
  "What is your father's middle name?",
  "What was your childhood nickname?",
  "What is the name of the town where you were married?",
  "What is your oldest sibling's middle name?",
  "What was the name of your first boss?",
  "What is your spouse's mother's maiden name?"
];

export default function SecurityQuestionsSetup({ userId, onComplete, onSkip }: SecurityQuestionsSetupProps) {
  const { toast } = useToast();
  const [questions, setQuestions] = useState<SecurityQuestion[]>([
    { id: '1', question: '', answer: '' },
    { id: '2', question: '', answer: '' },
    { id: '3', question: '', answer: '' }
  ]);
  const [isLoading, setIsLoading] = useState(false);
  const [errors, setErrors] = useState<string[]>([]);

  const updateQuestion = (id: string, field: 'question' | 'answer', value: string) => {
    setQuestions(prev => prev.map(q => 
      q.id === id ? { ...q, [field]: value } : q
    ));
    setErrors([]);
  };

  const validateQuestions = (): string[] => {
    const errors: string[] = [];
    
    // Check if all questions are filled
    questions.forEach((q, index) => {
      if (!q.question) {
        errors.push(`Question ${index + 1} is required`);
      }
      if (!q.answer || q.answer.trim().length < 3) {
        errors.push(`Answer ${index + 1} must be at least 3 characters`);
      }
    });

    // Check for duplicate questions
    const questionTexts = questions.map(q => q.question).filter(Boolean);
    const uniqueQuestions = new Set(questionTexts);
    if (questionTexts.length !== uniqueQuestions.size) {
      errors.push('Please select different questions for each field');
    }

    // Check for duplicate answers (case insensitive)
    const answerTexts = questions.map(q => q.answer.toLowerCase().trim()).filter(Boolean);
    const uniqueAnswers = new Set(answerTexts);
    if (answerTexts.length !== uniqueAnswers.size) {
      errors.push('Please provide different answers for each question');
    }

    return errors;
  };

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    
    const validationErrors = validateQuestions();
    if (validationErrors.length > 0) {
      setErrors(validationErrors);
      return;
    }

    setIsLoading(true);
    
    try {
      const success = await setupSecurityQuestions(userId, questions);
      
      if (success) {
        toast({
          title: "Security questions set up",
          description: "Your security questions have been configured successfully.",
        });
        onComplete?.();
      } else {
        throw new Error('Failed to set up security questions');
      }
    } catch (error) {
      console.error('Error setting up security questions:', error);
      toast({
        title: "Setup failed",
        description: "Failed to set up security questions. Please try again.",
        variant: "destructive"
      });
    } finally {
      setIsLoading(false);
    }
  };

  const canSubmit = questions.every(q => q.question && q.answer.trim().length >= 3) && 
                   errors.length === 0;

  return (
    <Card className="w-full max-w-2xl">
      <CardHeader className="text-center">
        <div className="rounded-full bg-blue-100 p-3 w-16 h-16 mx-auto flex items-center justify-center mb-4">
          <HelpCircle className="h-8 w-8 text-blue-600" />
        </div>
        <CardTitle className="text-2xl font-bold">Set Up Security Questions</CardTitle>
        <CardDescription>
          Security questions provide an additional way to recover your account if you forget your password.
          Choose questions with answers you'll remember but others can't easily guess.
        </CardDescription>
      </CardHeader>
      <CardContent>
        <Alert className="mb-6">
          <Shield className="h-4 w-4" />
          <AlertDescription>
            <strong>Important:</strong> Your answers are case-insensitive and stored securely. 
            Choose answers you'll remember exactly, but avoid information that's publicly available.
          </AlertDescription>
        </Alert>

        <form onSubmit={handleSubmit} className="space-y-6">
          {questions.map((q, index) => (
            <div key={q.id} className="space-y-4 p-4 border border-gray-200 rounded-lg">
              <h3 className="font-medium text-lg">Security Question {index + 1}</h3>
              
              <div className="space-y-2">
                <Label htmlFor={`question-${q.id}`}>Choose a question</Label>
                <Select
                  value={q.question}
                  onValueChange={(value) => updateQuestion(q.id, 'question', value)}
                  disabled={isLoading}
                >
                  <SelectTrigger id={`question-${q.id}`}>
                    <SelectValue placeholder="Select a security question" />
                  </SelectTrigger>
                  <SelectContent>
                    {SECURITY_QUESTIONS.map((question, qIndex) => (
                      <SelectItem 
                        key={qIndex} 
                        value={question}
                        disabled={questions.some(otherQ => otherQ.id !== q.id && otherQ.question === question)}
                      >
                        {question}
                      </SelectItem>
                    ))}
                  </SelectContent>
                </Select>
              </div>

              <div className="space-y-2">
                <Label htmlFor={`answer-${q.id}`}>Your answer</Label>
                <Input
                  id={`answer-${q.id}`}
                  type="text"
                  placeholder="Enter your answer"
                  value={q.answer}
                  onChange={(e) => updateQuestion(q.id, 'answer', e.target.value)}
                  disabled={isLoading}
                  className="w-full"
                />
                <p className="text-xs text-muted-foreground">
                  Minimum 3 characters. Your answer will be case-insensitive.
                </p>
              </div>
            </div>
          ))}

          {errors.length > 0 && (
            <Alert variant="destructive">
              <AlertDescription>
                <ul className="list-disc list-inside space-y-1">
                  {errors.map((error, index) => (
                    <li key={index}>{error}</li>
                  ))}
                </ul>
              </AlertDescription>
            </Alert>
          )}

          <div className="space-y-4 pt-4">
            <Button
              type="submit"
              className="w-full"
              disabled={!canSubmit || isLoading}
            >
              {isLoading ? (
                <>
                  <Loader2 className="mr-2 h-4 w-4 animate-spin" />
                  Setting up security questions...
                </>
              ) : (
                <>
                  <Check className="mr-2 h-4 w-4" />
                  Set Up Security Questions
                </>
              )}
            </Button>

            {onSkip && (
              <Button
                type="button"
                variant="outline"
                className="w-full"
                onClick={onSkip}
                disabled={isLoading}
              >
                Skip for now
              </Button>
            )}
          </div>
        </form>

        <div className="mt-6 p-4 bg-gray-50 rounded-lg">
          <h4 className="font-medium text-sm mb-2">Tips for good security question answers:</h4>
          <ul className="text-xs text-muted-foreground space-y-1">
            <li>• Use answers that are memorable to you but not easily guessable</li>
            <li>• Avoid information available on social media</li>
            <li>• Consider using modified versions (e.g., "Fluffy2010" instead of "Fluffy")</li>
            <li>• Don't use the same answer for multiple questions</li>
          </ul>
        </div>
      </CardContent>
    </Card>
  );
}