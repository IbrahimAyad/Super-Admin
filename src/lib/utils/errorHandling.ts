/**
 * ERROR HANDLING UTILITIES
 * Comprehensive error handling and logging for production systems
 * Includes retry logic, error classification, and user-friendly messaging
 */

// ============================================
// TYPES AND INTERFACES
// ============================================

export interface AppError extends Error {
  code: string;
  statusCode: number;
  isOperational: boolean;
  context?: Record<string, any>;
  userMessage?: string;
  timestamp: Date;
}

export interface ErrorLogEntry {
  id: string;
  timestamp: Date;
  level: ErrorLevel;
  message: string;
  code: string;
  statusCode: number;
  stack?: string;
  context?: Record<string, any>;
  userId?: string;
  sessionId?: string;
  userAgent?: string;
  url?: string;
}

export interface RetryConfig {
  maxRetries: number;
  baseDelay: number;
  maxDelay: number;
  backoffMultiplier: number;
  retryCondition?: (error: Error) => boolean;
}

export type ErrorLevel = 'debug' | 'info' | 'warn' | 'error' | 'fatal';
export type ErrorCategory = 'validation' | 'authentication' | 'authorization' | 'network' | 'database' | 'business' | 'system' | 'unknown';

// ============================================
// ERROR CLASSES
// ============================================

export class OrderProcessingError extends Error implements AppError {
  public readonly code: string;
  public readonly statusCode: number;
  public readonly isOperational: boolean = true;
  public readonly context?: Record<string, any>;
  public readonly userMessage?: string;
  public readonly timestamp: Date;

  constructor(
    message: string,
    code: string,
    statusCode: number = 500,
    context?: Record<string, any>,
    userMessage?: string
  ) {
    super(message);
    this.name = 'OrderProcessingError';
    this.code = code;
    this.statusCode = statusCode;
    this.context = context;
    this.userMessage = userMessage;
    this.timestamp = new Date();

    // Maintains proper stack trace for where our error was thrown
    if (Error.captureStackTrace) {
      Error.captureStackTrace(this, OrderProcessingError);
    }
  }
}

export class ValidationError extends OrderProcessingError {
  constructor(message: string, field?: string, context?: Record<string, any>) {
    super(
      message,
      'VALIDATION_ERROR',
      400,
      { field, ...context },
      'Please check your input and try again.'
    );
    this.name = 'ValidationError';
  }
}

export class InventoryError extends OrderProcessingError {
  constructor(message: string, variantId?: string, context?: Record<string, any>) {
    super(
      message,
      'INVENTORY_ERROR',
      409,
      { variantId, ...context },
      'There was an issue with product availability. Please try again or contact support.'
    );
    this.name = 'InventoryError';
  }
}

export class PaymentError extends OrderProcessingError {
  constructor(message: string, paymentId?: string, context?: Record<string, any>) {
    super(
      message,
      'PAYMENT_ERROR',
      402,
      { paymentId, ...context },
      'Payment processing failed. Please verify your payment information and try again.'
    );
    this.name = 'PaymentError';
  }
}

export class ShippingError extends OrderProcessingError {
  constructor(message: string, carrier?: string, context?: Record<string, any>) {
    super(
      message,
      'SHIPPING_ERROR',
      503,
      { carrier, ...context },
      'Shipping service is temporarily unavailable. Please try again later.'
    );
    this.name = 'ShippingError';
  }
}

export class NotificationError extends OrderProcessingError {
  constructor(message: string, notificationType?: string, context?: Record<string, any>) {
    super(
      message,
      'NOTIFICATION_ERROR',
      503,
      { notificationType, ...context },
      'Notification could not be sent. The order was processed successfully.'
    );
    this.name = 'NotificationError';
  }
}

// ============================================
// ERROR HANDLER CLASS
// ============================================

export class ErrorHandler {
  private static instance: ErrorHandler;
  private errorLogs: ErrorLogEntry[] = [];

  private constructor() {}

  public static getInstance(): ErrorHandler {
    if (!ErrorHandler.instance) {
      ErrorHandler.instance = new ErrorHandler();
    }
    return ErrorHandler.instance;
  }

  /**
   * Handle application errors with proper logging and classification
   */
  public handleError(error: Error, context?: Record<string, any>): AppError {
    const appError = this.normalizeError(error, context);
    
    // Log the error
    this.logError(appError, context);

    // Send to external monitoring if configured
    this.reportError(appError, context);

    return appError;
  }

  /**
   * Normalize different error types to AppError
   */
  private normalizeError(error: Error, context?: Record<string, any>): AppError {
    // If it's already an AppError, return as-is
    if (this.isAppError(error)) {
      return error;
    }

    // Handle specific error types
    if (error.name === 'ValidationError') {
      return new ValidationError(error.message, undefined, context);
    }

    // Handle database errors
    if (this.isDatabaseError(error)) {
      return new OrderProcessingError(
        'Database operation failed',
        'DATABASE_ERROR',
        500,
        { originalError: error.message, ...context },
        'A system error occurred. Please try again later.'
      );
    }

    // Handle network errors
    if (this.isNetworkError(error)) {
      return new OrderProcessingError(
        'Network request failed',
        'NETWORK_ERROR',
        503,
        { originalError: error.message, ...context },
        'Service temporarily unavailable. Please try again later.'
      );
    }

    // Default to generic system error
    return new OrderProcessingError(
      error.message || 'An unexpected error occurred',
      'SYSTEM_ERROR',
      500,
      { originalError: error.message, stack: error.stack, ...context },
      'An unexpected error occurred. Please try again or contact support.'
    );
  }

  /**
   * Log error with appropriate level and detail
   */
  private logError(error: AppError, context?: Record<string, any>): void {
    const logEntry: ErrorLogEntry = {
      id: this.generateErrorId(),
      timestamp: new Date(),
      level: this.getErrorLevel(error),
      message: error.message,
      code: error.code,
      statusCode: error.statusCode,
      stack: error.stack,
      context: { ...error.context, ...context },
      userId: context?.userId,
      sessionId: context?.sessionId,
      userAgent: context?.userAgent,
      url: context?.url
    };

    this.errorLogs.push(logEntry);

    // Console logging for development
    if (import.meta.env.MODE === 'development') {
      console.error('Error:', logEntry);
    }

    // TODO: Send to external logging service (e.g., Sentry, LogRocket)
    // this.sendToExternalLogger(logEntry);
  }

  /**
   * Report error to external monitoring
   */
  private reportError(error: AppError, context?: Record<string, any>): void {
    // Only report operational errors to external services
    if (!error.isOperational) {
      return;
    }

    // TODO: Implement external error reporting
    // Examples: Sentry, Bugsnag, DataDog, etc.
    console.warn('Error reported:', {
      code: error.code,
      message: error.message,
      context
    });
  }

  /**
   * Get appropriate error level based on error type
   */
  private getErrorLevel(error: AppError): ErrorLevel {
    if (error.statusCode >= 500) return 'error';
    if (error.statusCode >= 400) return 'warn';
    return 'info';
  }

  /**
   * Check if error is an AppError
   */
  private isAppError(error: Error): error is AppError {
    return 'code' in error && 'statusCode' in error && 'isOperational' in error;
  }

  /**
   * Check if error is a database error
   */
  private isDatabaseError(error: Error): boolean {
    return error.message.includes('PGRST') || 
           error.message.includes('connection') ||
           error.message.includes('timeout') ||
           error.name === 'PostgrestError';
  }

  /**
   * Check if error is a network error
   */
  private isNetworkError(error: Error): boolean {
    return error.message.includes('fetch') ||
           error.message.includes('network') ||
           error.message.includes('ECONNREFUSED') ||
           error.name === 'NetworkError';
  }

  /**
   * Generate unique error ID
   */
  private generateErrorId(): string {
    return `err_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`;
  }

  /**
   * Get recent error logs
   */
  public getRecentErrors(limit: number = 50): ErrorLogEntry[] {
    return this.errorLogs
      .sort((a, b) => b.timestamp.getTime() - a.timestamp.getTime())
      .slice(0, limit);
  }

  /**
   * Clear error logs (for testing)
   */
  public clearLogs(): void {
    this.errorLogs = [];
  }
}

// ============================================
// RETRY UTILITIES
// ============================================

/**
 * Retry function with exponential backoff
 */
export async function withRetry<T>(
  operation: () => Promise<T>,
  config: Partial<RetryConfig> = {}
): Promise<T> {
  const {
    maxRetries = 3,
    baseDelay = 1000,
    maxDelay = 10000,
    backoffMultiplier = 2,
    retryCondition = (error: Error) => isRetryableError(error)
  } = config;

  let lastError: Error;
  
  for (let attempt = 0; attempt <= maxRetries; attempt++) {
    try {
      return await operation();
    } catch (error) {
      lastError = error as Error;
      
      // Don't retry if it's not a retryable error or we've exhausted attempts
      if (attempt === maxRetries || !retryCondition(lastError)) {
        throw lastError;
      }
      
      // Calculate delay with exponential backoff
      const delay = Math.min(
        baseDelay * Math.pow(backoffMultiplier, attempt),
        maxDelay
      );
      
      // Add jitter to prevent thundering herd
      const jitteredDelay = delay + Math.random() * 1000;
      
      await new Promise(resolve => setTimeout(resolve, jitteredDelay));
    }
  }
  
  throw lastError!;
}

/**
 * Check if error is retryable
 */
function isRetryableError(error: Error): boolean {
  // Don't retry validation errors or client errors
  if (error instanceof ValidationError) return false;
  if (error instanceof OrderProcessingError && error.statusCode < 500) return false;
  
  // Retry network and server errors
  if (error.message.includes('fetch') || 
      error.message.includes('network') ||
      error.message.includes('timeout') ||
      error.message.includes('ECONNREFUSED')) {
    return true;
  }
  
  // Retry 5xx errors but not 4xx errors
  if (error instanceof OrderProcessingError) {
    return error.statusCode >= 500;
  }
  
  return false;
}

// ============================================
// CIRCUIT BREAKER PATTERN
// ============================================

export class CircuitBreaker {
  private failures = 0;
  private lastFailure?: Date;
  private state: 'closed' | 'open' | 'half-open' = 'closed';

  constructor(
    private failureThreshold: number = 5,
    private recoveryTimeout: number = 60000 // 1 minute
  ) {}

  async execute<T>(operation: () => Promise<T>): Promise<T> {
    if (this.state === 'open') {
      if (this.shouldAttemptReset()) {
        this.state = 'half-open';
      } else {
        throw new OrderProcessingError(
          'Circuit breaker is open',
          'CIRCUIT_BREAKER_OPEN',
          503,
          undefined,
          'Service is temporarily unavailable. Please try again later.'
        );
      }
    }

    try {
      const result = await operation();
      this.onSuccess();
      return result;
    } catch (error) {
      this.onFailure();
      throw error;
    }
  }

  private shouldAttemptReset(): boolean {
    return this.lastFailure && 
           (Date.now() - this.lastFailure.getTime()) >= this.recoveryTimeout;
  }

  private onSuccess(): void {
    this.failures = 0;
    this.state = 'closed';
  }

  private onFailure(): void {
    this.failures++;
    this.lastFailure = new Date();
    
    if (this.failures >= this.failureThreshold) {
      this.state = 'open';
    }
  }

  getState(): string {
    return this.state;
  }

  getFailureCount(): number {
    return this.failures;
  }
}

// ============================================
// UTILITY FUNCTIONS
// ============================================

/**
 * Safe async operation wrapper
 */
export async function safeAsync<T>(
  operation: () => Promise<T>,
  fallback?: T,
  context?: Record<string, any>
): Promise<T | undefined> {
  try {
    return await operation();
  } catch (error) {
    const errorHandler = ErrorHandler.getInstance();
    errorHandler.handleError(error as Error, context);
    return fallback;
  }
}

/**
 * Create user-friendly error message
 */
export function getUserFriendlyMessage(error: Error): string {
  if (error instanceof OrderProcessingError && error.userMessage) {
    return error.userMessage;
  }

  // Default messages based on error type
  if (error instanceof ValidationError) {
    return 'Please check your input and try again.';
  }

  if (error instanceof InventoryError) {
    return 'The requested item is currently unavailable. Please try a different option.';
  }

  if (error instanceof PaymentError) {
    return 'Payment processing failed. Please verify your payment information.';
  }

  if (error instanceof ShippingError) {
    return 'Shipping service is temporarily unavailable. Please try again later.';
  }

  // Generic fallback
  return 'An unexpected error occurred. Please try again or contact support if the problem persists.';
}

/**
 * Extract error category for analytics
 */
export function getErrorCategory(error: Error): ErrorCategory {
  if (error instanceof ValidationError) return 'validation';
  if (error instanceof PaymentError) return 'business';
  if (error instanceof InventoryError) return 'business';
  if (error instanceof ShippingError) return 'network';
  
  if (error.message.includes('auth') || error.message.includes('token')) {
    return 'authentication';
  }
  
  if (error.message.includes('permission') || error.message.includes('forbidden')) {
    return 'authorization';
  }
  
  if (error.message.includes('database') || error.message.includes('PGRST')) {
    return 'database';
  }
  
  if (error.message.includes('network') || error.message.includes('fetch')) {
    return 'network';
  }
  
  return 'unknown';
}

/**
 * Check if error should be shown to user
 */
export function shouldShowToUser(error: Error): boolean {
  // Show operational errors to users
  if (error instanceof OrderProcessingError) {
    return error.isOperational && error.statusCode < 500;
  }
  
  // Don't show system errors to users
  return false;
}

/**
 * Create error response for API
 */
export function createErrorResponse(error: Error) {
  const appError = error instanceof OrderProcessingError ? 
    error : 
    ErrorHandler.getInstance().handleError(error);

  return {
    error: {
      code: appError.code,
      message: appError.userMessage || 'An error occurred',
      statusCode: appError.statusCode,
      timestamp: appError.timestamp.toISOString(),
      // Don't expose sensitive details in production
      ...(import.meta.env.MODE === 'development' && {
        details: appError.message,
        stack: appError.stack
      })
    }
  };
}

// Export singleton instance
export const errorHandler = ErrorHandler.getInstance();