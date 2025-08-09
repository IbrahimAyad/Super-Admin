import React, { Component, ErrorInfo, ReactNode } from 'react';
import { Loader2, AlertCircle } from 'lucide-react';
import { Alert, AlertDescription, AlertTitle } from '@/components/ui/alert';
import { Button } from '@/components/ui/button';

interface Props {
  children: ReactNode;
  fallbackComponent?: React.ComponentType<{ error: Error; retry: () => void }>;
  onError?: (error: Error) => void;
  showError?: boolean;
}

interface State {
  hasError: boolean;
  error: Error | null;
  isRetrying: boolean;
}

/**
 * Error boundary specifically for async operations and data fetching
 */
export class AsyncErrorBoundary extends Component<Props, State> {
  private retryCount = 0;
  private maxRetries = 3;

  constructor(props: Props) {
    super(props);
    this.state = {
      hasError: false,
      error: null,
      isRetrying: false
    };
  }

  static getDerivedStateFromError(error: Error): Partial<State> {
    return { hasError: true, error };
  }

  componentDidCatch(error: Error, errorInfo: ErrorInfo) {
    // Check if it's a network/async error
    const isAsyncError = this.isAsyncError(error);
    
    if (import.meta.env.DEV) {
      console.error('AsyncErrorBoundary caught:', error, errorInfo);
    }

    if (this.props.onError) {
      this.props.onError(error);
    }

    // Auto-retry for network errors
    if (isAsyncError && this.retryCount < this.maxRetries) {
      this.scheduleRetry();
    }
  }

  isAsyncError(error: Error): boolean {
    // Check for common async/network error patterns
    const errorMessage = error.message.toLowerCase();
    return (
      errorMessage.includes('fetch') ||
      errorMessage.includes('network') ||
      errorMessage.includes('timeout') ||
      errorMessage.includes('supabase') ||
      errorMessage.includes('stripe') ||
      error.name === 'NetworkError' ||
      error.name === 'TimeoutError'
    );
  }

  scheduleRetry = () => {
    const delay = Math.min(1000 * Math.pow(2, this.retryCount), 10000); // Exponential backoff
    
    setTimeout(() => {
      this.handleRetry();
    }, delay);
  };

  handleRetry = () => {
    this.retryCount++;
    this.setState({
      hasError: false,
      error: null,
      isRetrying: true
    });

    // Force re-render children
    setTimeout(() => {
      this.setState({ isRetrying: false });
    }, 100);
  };

  handleManualRetry = () => {
    this.retryCount = 0;
    this.handleRetry();
  };

  render() {
    const { hasError, error, isRetrying } = this.state;
    const { children, fallbackComponent: FallbackComponent, showError = true } = this.props;

    if (isRetrying) {
      return (
        <div className="flex items-center justify-center p-8">
          <Loader2 className="h-8 w-8 animate-spin text-gray-400" />
          <span className="ml-2 text-gray-600">Retrying...</span>
        </div>
      );
    }

    if (hasError && error) {
      // Use custom fallback component if provided
      if (FallbackComponent) {
        return <FallbackComponent error={error} retry={this.handleManualRetry} />;
      }

      // Don't show error UI if disabled
      if (!showError) {
        return null;
      }

      // Default error UI for async errors
      return (
        <Alert variant="destructive" className="m-4">
          <AlertCircle className="h-4 w-4" />
          <AlertTitle>Failed to load data</AlertTitle>
          <AlertDescription className="space-y-2">
            <p>{this.getErrorMessage(error)}</p>
            {this.retryCount >= this.maxRetries && (
              <p className="text-sm">
                Maximum retry attempts reached. Please check your connection and try again.
              </p>
            )}
            <Button
              onClick={this.handleManualRetry}
              size="sm"
              variant="outline"
              className="mt-2"
            >
              Try Again
            </Button>
          </AlertDescription>
        </Alert>
      );
    }

    return children;
  }

  getErrorMessage(error: Error): string {
    // Provide user-friendly error messages
    const message = error.message.toLowerCase();
    
    if (message.includes('network')) {
      return 'Network error. Please check your internet connection.';
    }
    if (message.includes('timeout')) {
      return 'Request timed out. Please try again.';
    }
    if (message.includes('supabase')) {
      return 'Database connection error. Please try again later.';
    }
    if (message.includes('stripe')) {
      return 'Payment service error. Please try again later.';
    }
    if (message.includes('unauthorized') || message.includes('401')) {
      return 'Authentication error. Please log in again.';
    }
    if (message.includes('forbidden') || message.includes('403')) {
      return 'You do not have permission to access this resource.';
    }
    if (message.includes('not found') || message.includes('404')) {
      return 'The requested resource was not found.';
    }
    
    // Generic message for unknown errors
    return 'An unexpected error occurred. Please try again.';
  }
}

/**
 * Hook to use with React Query for error handling
 */
export function useAsyncError() {
  const [, setError] = React.useState();
  
  return React.useCallback(
    (error: Error) => {
      setError(() => {
        throw error;
      });
    },
    [setError]
  );
}