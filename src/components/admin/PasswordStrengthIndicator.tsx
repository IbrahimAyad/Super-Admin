/**
 * PASSWORD STRENGTH INDICATOR COMPONENT
 * Visual password strength indicator with policy validation
 * Created: 2025-08-07
 */

import React, { useMemo } from 'react';
import { Progress } from '@/components/ui/progress';
import { Badge } from '@/components/ui/badge';
import { Alert, AlertDescription } from '@/components/ui/alert';
import {
  Tooltip,
  TooltipContent,
  TooltipProvider,
  TooltipTrigger,
} from '@/components/ui/tooltip';
import {
  CheckCircle,
  XCircle,
  Shield,
  AlertTriangle,
  Eye,
  EyeOff,
  Info,
} from 'lucide-react';
import { Button } from '@/components/ui/button';

export interface PasswordPolicy {
  minLength: number;
  requireUppercase: boolean;
  requireLowercase: boolean;
  requireNumbers: boolean;
  requireSpecialChars: boolean;
  prohibitCommonPasswords: boolean;
  prohibitPersonalInfo: boolean;
  maxRepeatingChars: number;
}

export interface PasswordStrength {
  score: number; // 0-100
  level: 'very-weak' | 'weak' | 'fair' | 'good' | 'strong';
  feedback: string[];
  isValid: boolean;
  requirements: {
    name: string;
    met: boolean;
    description: string;
  }[];
}

interface PasswordStrengthIndicatorProps {
  password: string;
  policy?: Partial<PasswordPolicy>;
  personalInfo?: string[];
  showRequirements?: boolean;
  showVisibilityToggle?: boolean;
  className?: string;
}

// Default password policy
const DEFAULT_POLICY: PasswordPolicy = {
  minLength: 12,
  requireUppercase: true,
  requireLowercase: true,
  requireNumbers: true,
  requireSpecialChars: true,
  prohibitCommonPasswords: true,
  prohibitPersonalInfo: true,
  maxRepeatingChars: 2,
};

// Common weak passwords (subset for demo - in production use a comprehensive list)
const COMMON_WEAK_PASSWORDS = [
  'password', '123456', 'password123', 'admin', 'qwerty', 'letmein',
  'welcome', 'monkey', '1234567890', 'abc123', 'password1', 'admin123',
];

/**
 * Analyze password strength and policy compliance
 */
function analyzePassword(password: string, policy: PasswordPolicy, personalInfo: string[] = []): PasswordStrength {
  const requirements: PasswordStrength['requirements'] = [];
  const feedback: string[] = [];
  let score = 0;

  // Length check
  const lengthMet = password.length >= policy.minLength;
  requirements.push({
    name: 'length',
    met: lengthMet,
    description: `At least ${policy.minLength} characters`,
  });
  if (lengthMet) {
    score += 20;
  } else {
    feedback.push(`Password must be at least ${policy.minLength} characters long`);
  }

  // Uppercase check
  const hasUppercase = /[A-Z]/.test(password);
  if (policy.requireUppercase) {
    requirements.push({
      name: 'uppercase',
      met: hasUppercase,
      description: 'At least one uppercase letter',
    });
    if (hasUppercase) {
      score += 15;
    } else {
      feedback.push('Add uppercase letters');
    }
  }

  // Lowercase check
  const hasLowercase = /[a-z]/.test(password);
  if (policy.requireLowercase) {
    requirements.push({
      name: 'lowercase',
      met: hasLowercase,
      description: 'At least one lowercase letter',
    });
    if (hasLowercase) {
      score += 15;
    } else {
      feedback.push('Add lowercase letters');
    }
  }

  // Numbers check
  const hasNumbers = /\d/.test(password);
  if (policy.requireNumbers) {
    requirements.push({
      name: 'numbers',
      met: hasNumbers,
      description: 'At least one number',
    });
    if (hasNumbers) {
      score += 15;
    } else {
      feedback.push('Add numbers');
    }
  }

  // Special characters check
  const hasSpecialChars = /[!@#$%^&*()_+\-=\[\]{};':"\\|,.<>\/?]/.test(password);
  if (policy.requireSpecialChars) {
    requirements.push({
      name: 'special',
      met: hasSpecialChars,
      description: 'At least one special character',
    });
    if (hasSpecialChars) {
      score += 15;
    } else {
      feedback.push('Add special characters (!@#$%^&*)');
    }
  }

  // Common passwords check
  const isCommonPassword = COMMON_WEAK_PASSWORDS.includes(password.toLowerCase());
  if (policy.prohibitCommonPasswords) {
    requirements.push({
      name: 'common',
      met: !isCommonPassword,
      description: 'Not a common password',
    });
    if (isCommonPassword) {
      score -= 30;
      feedback.push('Avoid common passwords');
    } else {
      score += 10;
    }
  }

  // Personal info check
  const containsPersonalInfo = personalInfo.some(info => 
    info.length > 2 && password.toLowerCase().includes(info.toLowerCase())
  );
  if (policy.prohibitPersonalInfo && personalInfo.length > 0) {
    requirements.push({
      name: 'personal',
      met: !containsPersonalInfo,
      description: 'Does not contain personal information',
    });
    if (containsPersonalInfo) {
      score -= 20;
      feedback.push('Avoid using personal information');
    } else {
      score += 10;
    }
  }

  // Repeating characters check
  const hasExcessiveRepeating = checkRepeatingChars(password, policy.maxRepeatingChars);
  requirements.push({
    name: 'repeating',
    met: !hasExcessiveRepeating,
    description: `No more than ${policy.maxRepeatingChars} repeating characters`,
  });
  if (hasExcessiveRepeating) {
    score -= 15;
    feedback.push(`Avoid repeating characters more than ${policy.maxRepeatingChars} times`);
  } else {
    score += 5;
  }

  // Bonus points for variety and length
  const charTypes = [hasUppercase, hasLowercase, hasNumbers, hasSpecialChars].filter(Boolean).length;
  score += charTypes * 2;

  if (password.length > 16) score += 10;
  if (password.length > 20) score += 10;

  // Entropy bonus (character variety)
  const uniqueChars = new Set(password).size;
  const entropyBonus = Math.min(10, uniqueChars / 2);
  score += entropyBonus;

  // Ensure score is within bounds
  score = Math.max(0, Math.min(100, score));

  // Determine strength level
  let level: PasswordStrength['level'];
  if (score < 20) level = 'very-weak';
  else if (score < 40) level = 'weak';
  else if (score < 60) level = 'fair';
  else if (score < 80) level = 'good';
  else level = 'strong';

  // Check if all required policy items are met
  const isValid = requirements.every(req => req.met);

  // Add contextual feedback
  if (score >= 80) {
    feedback.unshift('Excellent password strength!');
  } else if (score >= 60) {
    feedback.unshift('Good password strength');
  } else if (score >= 40) {
    feedback.unshift('Fair password strength - consider improvements');
  } else {
    feedback.unshift('Weak password - significant improvements needed');
  }

  return {
    score,
    level,
    feedback,
    isValid,
    requirements,
  };
}

/**
 * Check for excessive repeating characters
 */
function checkRepeatingChars(password: string, maxRepeating: number): boolean {
  for (let i = 0; i < password.length - maxRepeating; i++) {
    const char = password[i];
    let count = 1;
    for (let j = i + 1; j < password.length && password[j] === char; j++) {
      count++;
      if (count > maxRepeating) {
        return true;
      }
    }
  }
  return false;
}

/**
 * Get color for strength level
 */
function getStrengthColor(level: PasswordStrength['level']): string {
  switch (level) {
    case 'very-weak': return 'bg-red-500';
    case 'weak': return 'bg-orange-500';
    case 'fair': return 'bg-yellow-500';
    case 'good': return 'bg-blue-500';
    case 'strong': return 'bg-green-500';
    default: return 'bg-gray-300';
  }
}

/**
 * Get strength level display text
 */
function getStrengthText(level: PasswordStrength['level']): string {
  switch (level) {
    case 'very-weak': return 'Very Weak';
    case 'weak': return 'Weak';
    case 'fair': return 'Fair';
    case 'good': return 'Good';
    case 'strong': return 'Strong';
    default: return 'Unknown';
  }
}

export function PasswordStrengthIndicator({
  password,
  policy = {},
  personalInfo = [],
  showRequirements = true,
  showVisibilityToggle = false,
  className = '',
}: PasswordStrengthIndicatorProps) {
  const [showPassword, setShowPassword] = React.useState(false);
  
  const finalPolicy = { ...DEFAULT_POLICY, ...policy };
  
  const strength = useMemo(() => 
    analyzePassword(password, finalPolicy, personalInfo),
    [password, finalPolicy, personalInfo]
  );

  if (!password) {
    return null;
  }

  return (
    <div className={`space-y-3 ${className}`}>
      {/* Password visibility toggle */}
      {showVisibilityToggle && (
        <div className="flex justify-end">
          <Button
            type="button"
            variant="ghost"
            size="sm"
            onClick={() => setShowPassword(!showPassword)}
            className="h-8 px-2"
          >
            {showPassword ? (
              <EyeOff className="h-4 w-4" />
            ) : (
              <Eye className="h-4 w-4" />
            )}
          </Button>
        </div>
      )}

      {/* Strength progress bar */}
      <div className="space-y-2">
        <div className="flex items-center justify-between">
          <span className="text-sm font-medium">Password Strength</span>
          <Badge
            variant={strength.isValid ? 'default' : 'destructive'}
            className={`text-xs ${!strength.isValid ? 'bg-red-100 text-red-800 border-red-200' : ''}`}
          >
            {getStrengthText(strength.level)}
          </Badge>
        </div>
        
        <div className="relative">
          <Progress value={strength.score} className="h-2" />
          <div 
            className={`absolute top-0 left-0 h-2 rounded-full transition-all duration-300 ${getStrengthColor(strength.level)}`}
            style={{ width: `${strength.score}%` }}
          />
        </div>
        
        <div className="flex justify-between text-xs text-muted-foreground">
          <span>Weak</span>
          <span>{strength.score}/100</span>
          <span>Strong</span>
        </div>
      </div>

      {/* Feedback */}
      {strength.feedback.length > 0 && (
        <Alert className={strength.isValid ? '' : 'border-yellow-200 bg-yellow-50'}>
          <Info className="h-4 w-4" />
          <AlertDescription>
            <ul className="list-disc list-inside space-y-1">
              {strength.feedback.map((feedback, index) => (
                <li key={index} className="text-sm">{feedback}</li>
              ))}
            </ul>
          </AlertDescription>
        </Alert>
      )}

      {/* Requirements checklist */}
      {showRequirements && (
        <div className="space-y-2">
          <h4 className="text-sm font-medium flex items-center gap-2">
            <Shield className="h-4 w-4" />
            Password Requirements
          </h4>
          <div className="space-y-1">
            {strength.requirements.map((req) => (
              <div key={req.name} className="flex items-center gap-2">
                {req.met ? (
                  <CheckCircle className="h-4 w-4 text-green-600" />
                ) : (
                  <XCircle className="h-4 w-4 text-red-600" />
                )}
                <span className={`text-sm ${req.met ? 'text-green-700' : 'text-red-700'}`}>
                  {req.description}
                </span>
              </div>
            ))}
          </div>
        </div>
      )}

      {/* Security tip */}
      <TooltipProvider>
        <Tooltip>
          <TooltipTrigger asChild>
            <div className="flex items-center gap-2 text-xs text-muted-foreground cursor-help">
              <AlertTriangle className="h-3 w-3" />
              <span>Security Tip</span>
            </div>
          </TooltipTrigger>
          <TooltipContent className="max-w-xs">
            <p className="text-sm">
              Use a unique password that you haven't used elsewhere. Consider using a password manager 
              to generate and store strong, unique passwords for all your accounts.
            </p>
          </TooltipContent>
        </Tooltip>
      </TooltipProvider>
    </div>
  );
}

/**
 * Hook for password validation
 */
export function usePasswordValidation(password: string, policy?: Partial<PasswordPolicy>, personalInfo?: string[]) {
  return useMemo(() => {
    const finalPolicy = { ...DEFAULT_POLICY, ...policy };
    return analyzePassword(password, finalPolicy, personalInfo);
  }, [password, policy, personalInfo]);
}

/**
 * Utility function to check if password meets policy
 */
export function validatePassword(password: string, policy?: Partial<PasswordPolicy>, personalInfo?: string[]): boolean {
  const finalPolicy = { ...DEFAULT_POLICY, ...policy };
  const strength = analyzePassword(password, finalPolicy, personalInfo);
  return strength.isValid;
}

/**
 * Generate password suggestions
 */
export function generatePasswordSuggestions(length: number = 16): string[] {
  const uppercase = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
  const lowercase = 'abcdefghijklmnopqrstuvwxyz';
  const numbers = '0123456789';
  const special = '!@#$%^&*()_+-=[]{}|;:,.<>?';
  
  const suggestions: string[] = [];
  
  for (let i = 0; i < 3; i++) {
    let password = '';
    const allChars = uppercase + lowercase + numbers + special;
    
    // Ensure at least one character from each category
    password += uppercase[Math.floor(Math.random() * uppercase.length)];
    password += lowercase[Math.floor(Math.random() * lowercase.length)];
    password += numbers[Math.floor(Math.random() * numbers.length)];
    password += special[Math.floor(Math.random() * special.length)];
    
    // Fill the rest randomly
    for (let j = password.length; j < length; j++) {
      password += allChars[Math.floor(Math.random() * allChars.length)];
    }
    
    // Shuffle the password
    password = password.split('').sort(() => Math.random() - 0.5).join('');
    suggestions.push(password);
  }
  
  return suggestions;
}