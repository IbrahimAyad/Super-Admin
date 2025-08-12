import { useState } from 'react';
import { supabase } from '@/lib/supabase-client';
import { useToast } from '@/components/ui/use-toast';
import { useNavigate } from 'react-router-dom';
import { requestPasswordReset as requestReset, resetPasswordWithToken } from '@/lib/services/authService';

interface PasswordResetState {
  isLoading: boolean;
  error: string | null;
  requestPasswordReset: (email: string) => Promise<boolean>;
  resetPassword: (token: string, newPassword: string) => Promise<boolean>;
  updatePassword: (currentPassword: string, newPassword: string) => Promise<boolean>;
}

export function usePasswordReset(): PasswordResetState {
  const { toast } = useToast();
  const navigate = useNavigate();
  const [isLoading, setIsLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);

  const requestPasswordReset = async (email: string): Promise<boolean> => {
    try {
      setIsLoading(true);
      setError(null);

      // Validate email format
      const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
      if (!emailRegex.test(email)) {
        throw new Error('Please enter a valid email address');
      }

      // Use the enhanced authentication service
      const success = await requestReset({
        email,
        ipAddress: undefined, // Could be added with a service to detect IP
        userAgent: navigator.userAgent
      });

      if (success) {
        toast({
          title: "Reset email sent",
          description: "Check your email for password reset instructions.",
        });
        return true;
      } else {
        throw new Error('Failed to send reset email');
      }
    } catch (err) {
      console.error('Password reset request error:', err);
      const message = err instanceof Error ? err.message : 'Failed to send reset email';
      setError(message);
      toast({
        title: "Error",
        description: message,
        variant: "destructive"
      });
      return false;
    } finally {
      setIsLoading(false);
    }
  };

  const resetPassword = async (token: string, newPassword: string): Promise<boolean> => {
    try {
      setIsLoading(true);
      setError(null);

      // Validate password strength
      if (newPassword.length < 8) {
        throw new Error('Password must be at least 8 characters long');
      }

      if (!/(?=.*[a-z])(?=.*[A-Z])(?=.*\d)/.test(newPassword)) {
        throw new Error('Password must contain uppercase, lowercase, and numbers');
      }

      // Use the enhanced authentication service
      const result = await resetPasswordWithToken(
        token,
        newPassword,
        undefined, // ipAddress
        navigator.userAgent
      );

      if (result.success) {
        toast({
          title: "Password updated",
          description: "Your password has been successfully reset.",
        });

        // Redirect to login page after successful reset
        setTimeout(() => {
          navigate('/login');
        }, 2000);

        return true;
      } else {
        throw new Error(result.error || 'Failed to reset password');
      }
    } catch (err) {
      console.error('Password reset error:', err);
      const message = err instanceof Error ? err.message : 'Failed to reset password';
      setError(message);
      toast({
        title: "Reset failed",
        description: message,
        variant: "destructive"
      });
      return false;
    } finally {
      setIsLoading(false);
    }
  };

  const updatePassword = async (currentPassword: string, newPassword: string): Promise<boolean> => {
    try {
      setIsLoading(true);
      setError(null);

      // Validate new password
      if (newPassword.length < 8) {
        throw new Error('Password must be at least 8 characters long');
      }

      if (!/(?=.*[a-z])(?=.*[A-Z])(?=.*\d)/.test(newPassword)) {
        throw new Error('Password must contain uppercase, lowercase, and numbers');
      }

      if (currentPassword === newPassword) {
        throw new Error('New password must be different from current password');
      }

      // First verify current password by reauthenticating
      const { data: { user } } = await supabase.auth.getUser();
      if (!user?.email) {
        throw new Error('No authenticated user found');
      }

      // Try to sign in with current password to verify it
      const { error: signInError } = await supabase.auth.signInWithPassword({
        email: user.email,
        password: currentPassword
      });

      if (signInError) {
        throw new Error('Current password is incorrect');
      }

      // Update to new password
      const { error: updateError } = await supabase.auth.updateUser({
        password: newPassword
      });

      if (updateError) {
        throw updateError;
      }

      toast({
        title: "Password changed",
        description: "Your password has been successfully updated.",
      });

      return true;
    } catch (err) {
      console.error('Password update error:', err);
      const message = err instanceof Error ? err.message : 'Failed to update password';
      setError(message);
      toast({
        title: "Update failed",
        description: message,
        variant: "destructive"
      });
      return false;
    } finally {
      setIsLoading(false);
    }
  };

  return {
    isLoading,
    error,
    requestPasswordReset,
    resetPassword,
    updatePassword
  };
}