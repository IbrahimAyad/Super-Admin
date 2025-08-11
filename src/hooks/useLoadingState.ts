import { useState, useCallback } from 'react';
import { useToast } from '@/hooks/use-toast';

interface UseLoadingStateOptions {
  showErrorToast?: boolean;
  errorTitle?: string;
  context?: string;
}

export function useLoadingState(options: UseLoadingStateOptions = {}) {
  const { showErrorToast = true, errorTitle = 'Error', context } = options;
  const { toast } = useToast();
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<Error | null>(null);

  const execute = useCallback(async <T>(
    fn: () => Promise<T>
  ): Promise<T | undefined> => {
    setLoading(true);
    setError(null);
    
    try {
      const result = await fn();
      return result;
    } catch (err) {
      const error = err as Error;
      setError(error);
      
      if (showErrorToast) {
        console.error(`Error in ${context || 'operation'}:`, error);
        toast({
          title: errorTitle,
          description: error.message || 'An unexpected error occurred',
          variant: 'destructive',
        });
      }
      
      return undefined;
    } finally {
      setLoading(false);
    }
  }, [showErrorToast, errorTitle, context, toast]);

  const reset = useCallback(() => {
    setLoading(false);
    setError(null);
  }, []);

  return {
    loading,
    error,
    execute,
    reset,
    setLoading,
    setError,
  };
}