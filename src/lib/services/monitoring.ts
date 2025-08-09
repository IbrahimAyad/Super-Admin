/**
 * Monitoring and Logging Service
 * Provides centralized logging, error tracking, and performance monitoring
 */

import { getEnv } from '@/lib/config/env';

// Log levels
export enum LogLevel {
  DEBUG = 'debug',
  INFO = 'info',
  WARN = 'warn',
  ERROR = 'error',
  FATAL = 'fatal'
}

// Log entry interface
interface LogEntry {
  level: LogLevel;
  message: string;
  timestamp: string;
  context?: Record<string, any>;
  error?: Error;
  userId?: string;
  sessionId?: string;
  requestId?: string;
}

// Performance metric interface
interface PerformanceMetric {
  name: string;
  value: number;
  unit: string;
  tags?: Record<string, string>;
  timestamp: string;
}

// Error tracking interface
interface ErrorReport {
  error: Error;
  context: Record<string, any>;
  severity: 'low' | 'medium' | 'high' | 'critical';
  userId?: string;
  userAgent?: string;
  url?: string;
}

/**
 * Monitoring Service Class
 */
class MonitoringService {
  private static instance: MonitoringService;
  private buffer: LogEntry[] = [];
  private metrics: PerformanceMetric[] = [];
  private flushInterval: number = 5000; // 5 seconds
  private maxBufferSize: number = 100;
  private sessionId: string;
  private isProduction: boolean;

  private constructor() {
    this.sessionId = this.generateSessionId();
    this.isProduction = getEnv().IS_PRODUCTION;
    this.startFlushInterval();
    this.setupGlobalErrorHandlers();
    this.setupPerformanceObserver();
  }

  /**
   * Get singleton instance
   */
  public static getInstance(): MonitoringService {
    if (!MonitoringService.instance) {
      MonitoringService.instance = new MonitoringService();
    }
    return MonitoringService.instance;
  }

  /**
   * Generate unique session ID
   */
  private generateSessionId(): string {
    return `${Date.now()}-${Math.random().toString(36).substr(2, 9)}`;
  }

  /**
   * Log a message
   */
  public log(level: LogLevel, message: string, context?: Record<string, any>): void {
    const entry: LogEntry = {
      level,
      message,
      timestamp: new Date().toISOString(),
      context,
      sessionId: this.sessionId,
      userId: this.getCurrentUserId()
    };

    // Console output in development
    if (!this.isProduction || level === LogLevel.ERROR || level === LogLevel.FATAL) {
      this.consoleLog(entry);
    }

    // Add to buffer
    this.buffer.push(entry);

    // Flush if buffer is full
    if (this.buffer.length >= this.maxBufferSize) {
      this.flush();
    }
  }

  /**
   * Convenience methods for different log levels
   */
  public debug(message: string, context?: Record<string, any>): void {
    this.log(LogLevel.DEBUG, message, context);
  }

  public info(message: string, context?: Record<string, any>): void {
    this.log(LogLevel.INFO, message, context);
  }

  public warn(message: string, context?: Record<string, any>): void {
    this.log(LogLevel.WARN, message, context);
  }

  public error(message: string, error?: Error, context?: Record<string, any>): void {
    this.log(LogLevel.ERROR, message, { ...context, error: error?.stack });
    
    if (error && this.isProduction) {
      this.reportError(error, context);
    }
  }

  public fatal(message: string, error?: Error, context?: Record<string, any>): void {
    this.log(LogLevel.FATAL, message, { ...context, error: error?.stack });
    
    if (error) {
      this.reportError(error, context, 'critical');
    }
    
    // Immediately flush on fatal errors
    this.flush();
  }

  /**
   * Track a performance metric
   */
  public metric(name: string, value: number, unit: string = 'ms', tags?: Record<string, string>): void {
    const metric: PerformanceMetric = {
      name,
      value,
      unit,
      tags,
      timestamp: new Date().toISOString()
    };

    this.metrics.push(metric);

    // Log slow operations
    if (unit === 'ms' && value > 3000) {
      this.warn(`Slow operation detected: ${name}`, { duration: value, tags });
    }
  }

  /**
   * Track a custom event
   */
  public track(eventName: string, properties?: Record<string, any>): void {
    this.info(`Event: ${eventName}`, properties);
    
    // Send to analytics service if enabled
    if (getEnv().ENABLE_ANALYTICS && window.gtag) {
      window.gtag('event', eventName, properties);
    }
  }

  /**
   * Track page view
   */
  public pageView(path: string, title?: string): void {
    this.track('page_view', { path, title });
  }

  /**
   * Track user action
   */
  public userAction(action: string, category: string, label?: string, value?: number): void {
    this.track('user_action', { action, category, label, value });
  }

  /**
   * Report error to external service
   */
  private reportError(error: Error, context?: Record<string, any>, severity: ErrorReport['severity'] = 'medium'): void {
    const report: ErrorReport = {
      error,
      context: context || {},
      severity,
      userId: this.getCurrentUserId(),
      userAgent: navigator.userAgent,
      url: window.location.href
    };

    // In production, send to error tracking service
    if (this.isProduction) {
      // Example: Sentry integration
      // Sentry.captureException(error, {
      //   level: severity,
      //   extra: context,
      //   user: { id: report.userId }
      // });

      // For now, just send to our API
      this.sendToAPI('/api/errors', report);
    }
  }

  /**
   * Console log with formatting
   */
  private consoleLog(entry: LogEntry): void {
    const style = this.getLogStyle(entry.level);
    const prefix = `[${entry.level.toUpperCase()}] ${entry.timestamp}`;
    
    console.log(`%c${prefix}%c ${entry.message}`, style, 'color: inherit');
    
    if (entry.context) {
      console.log('Context:', entry.context);
    }
    
    if (entry.error) {
      console.error('Error:', entry.error);
    }
  }

  /**
   * Get console style for log level
   */
  private getLogStyle(level: LogLevel): string {
    switch (level) {
      case LogLevel.DEBUG:
        return 'color: gray';
      case LogLevel.INFO:
        return 'color: blue';
      case LogLevel.WARN:
        return 'color: orange';
      case LogLevel.ERROR:
        return 'color: red';
      case LogLevel.FATAL:
        return 'color: white; background: red; padding: 2px 4px';
      default:
        return '';
    }
  }

  /**
   * Setup global error handlers
   */
  private setupGlobalErrorHandlers(): void {
    // Handle unhandled promise rejections
    window.addEventListener('unhandledrejection', (event) => {
      this.error('Unhandled promise rejection', new Error(event.reason), {
        promise: event.promise,
        reason: event.reason
      });
    });

    // Handle global errors
    window.addEventListener('error', (event) => {
      this.error('Global error', event.error, {
        message: event.message,
        filename: event.filename,
        lineno: event.lineno,
        colno: event.colno
      });
    });
  }

  /**
   * Setup performance observer
   */
  private setupPerformanceObserver(): void {
    if ('PerformanceObserver' in window) {
      // Observe long tasks
      try {
        const observer = new PerformanceObserver((list) => {
          for (const entry of list.getEntries()) {
            if (entry.duration > 50) { // Long task threshold
              this.metric('long_task', entry.duration, 'ms', {
                name: entry.name,
                startTime: entry.startTime.toString()
              });
            }
          }
        });
        observer.observe({ entryTypes: ['longtask'] });
      } catch (e) {
        // Long task observer not supported
      }

      // Observe navigation timing
      try {
        const navObserver = new PerformanceObserver((list) => {
          for (const entry of list.getEntries()) {
            const nav = entry as PerformanceNavigationTiming;
            this.metric('page_load', nav.loadEventEnd - nav.fetchStart, 'ms');
            this.metric('dom_ready', nav.domContentLoadedEventEnd - nav.fetchStart, 'ms');
            this.metric('first_byte', nav.responseStart - nav.fetchStart, 'ms');
          }
        });
        navObserver.observe({ entryTypes: ['navigation'] });
      } catch (e) {
        // Navigation observer not supported
      }
    }
  }

  /**
   * Start flush interval
   */
  private startFlushInterval(): void {
    setInterval(() => {
      if (this.buffer.length > 0 || this.metrics.length > 0) {
        this.flush();
      }
    }, this.flushInterval);
  }

  /**
   * Flush logs and metrics to backend
   */
  private async flush(): Promise<void> {
    if (this.buffer.length === 0 && this.metrics.length === 0) {
      return;
    }

    const logsToSend = [...this.buffer];
    const metricsToSend = [...this.metrics];
    
    // Clear buffers
    this.buffer = [];
    this.metrics = [];

    // Send to backend
    try {
      await Promise.all([
        logsToSend.length > 0 ? this.sendToAPI('/api/logs', { logs: logsToSend }) : null,
        metricsToSend.length > 0 ? this.sendToAPI('/api/metrics', { metrics: metricsToSend }) : null
      ]);
    } catch (error) {
      // Re-add to buffer if send fails (with limit to prevent infinite growth)
      if (this.buffer.length < this.maxBufferSize * 2) {
        this.buffer.unshift(...logsToSend.slice(0, this.maxBufferSize));
      }
      if (this.metrics.length < this.maxBufferSize * 2) {
        this.metrics.unshift(...metricsToSend.slice(0, this.maxBufferSize));
      }
    }
  }

  /**
   * Send data to API endpoint
   */
  private async sendToAPI(endpoint: string, data: any): Promise<void> {
    // Skip in development unless explicitly enabled
    if (!this.isProduction && !getEnv().ENABLE_ANALYTICS) {
      return;
    }

    try {
      const response = await fetch(endpoint, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'X-Session-Id': this.sessionId
        },
        body: JSON.stringify(data)
      });

      if (!response.ok) {
        throw new Error(`Failed to send to ${endpoint}: ${response.statusText}`);
      }
    } catch (error) {
      // Silently fail to avoid infinite error loops
      console.error(`Failed to send monitoring data to ${endpoint}:`, error);
    }
  }

  /**
   * Get current user ID from auth context
   */
  private getCurrentUserId(): string | undefined {
    try {
      // Get from localStorage or session
      const authData = localStorage.getItem('supabase.auth.token');
      if (authData) {
        const parsed = JSON.parse(authData);
        return parsed?.currentSession?.user?.id;
      }
    } catch {
      // Ignore errors
    }
    return undefined;
  }

  /**
   * Create a timed operation
   */
  public startTimer(name: string): () => void {
    const startTime = performance.now();
    
    return () => {
      const duration = performance.now() - startTime;
      this.metric(name, duration, 'ms');
    };
  }

  /**
   * Measure async operation
   */
  public async measureAsync<T>(
    name: string,
    operation: () => Promise<T>
  ): Promise<T> {
    const endTimer = this.startTimer(name);
    
    try {
      const result = await operation();
      endTimer();
      return result;
    } catch (error) {
      endTimer();
      this.error(`Operation failed: ${name}`, error as Error);
      throw error;
    }
  }
}

// Export singleton instance
export const monitoring = MonitoringService.getInstance();

// Export convenience functions
export const logger = {
  debug: (message: string, context?: Record<string, any>) => monitoring.debug(message, context),
  info: (message: string, context?: Record<string, any>) => monitoring.info(message, context),
  warn: (message: string, context?: Record<string, any>) => monitoring.warn(message, context),
  error: (message: string, error?: Error, context?: Record<string, any>) => monitoring.error(message, error, context),
  fatal: (message: string, error?: Error, context?: Record<string, any>) => monitoring.fatal(message, error, context)
};

// Export tracking functions
export const track = {
  event: (name: string, properties?: Record<string, any>) => monitoring.track(name, properties),
  pageView: (path: string, title?: string) => monitoring.pageView(path, title),
  userAction: (action: string, category: string, label?: string, value?: number) => 
    monitoring.userAction(action, category, label, value),
  metric: (name: string, value: number, unit?: string, tags?: Record<string, string>) => 
    monitoring.metric(name, value, unit, tags)
};

// Export timer functions
export const timer = {
  start: (name: string) => monitoring.startTimer(name),
  measureAsync: <T>(name: string, operation: () => Promise<T>) => 
    monitoring.measureAsync(name, operation)
};