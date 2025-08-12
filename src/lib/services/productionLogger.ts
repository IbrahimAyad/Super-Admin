import { supabase } from '@/lib/supabase-client';

interface LogEntry {
  level: 'debug' | 'info' | 'warn' | 'error' | 'fatal';
  message: string;
  context?: Record<string, any>;
  timestamp: string;
  userId?: string;
  sessionId?: string;
  environment: string;
  userAgent?: string;
  url?: string;
  stack?: string;
}

interface LogBuffer {
  entries: LogEntry[];
  timer: NodeJS.Timeout | null;
}

class ProductionLogger {
  private buffer: LogBuffer = {
    entries: [],
    timer: null
  };
  
  private readonly MAX_BUFFER_SIZE = 50;
  private readonly FLUSH_INTERVAL = 5000; // 5 seconds
  private readonly MAX_RETRIES = 3;
  private sessionId: string;
  private userId: string | null = null;

  constructor() {
    this.sessionId = this.generateSessionId();
    this.startBufferTimer();
    
    // Flush logs on page unload
    if (typeof window !== 'undefined') {
      window.addEventListener('beforeunload', () => {
        this.flush(true);
      });

      // Capture unhandled errors
      window.addEventListener('error', (event) => {
        this.error('Unhandled error', {
          message: event.message,
          filename: event.filename,
          lineno: event.lineno,
          colno: event.colno,
          error: event.error?.stack
        });
      });

      // Capture unhandled promise rejections
      window.addEventListener('unhandledrejection', (event) => {
        this.error('Unhandled promise rejection', {
          reason: event.reason,
          promise: event.promise
        });
      });
    }
  }

  private generateSessionId(): string {
    return `${Date.now()}-${Math.random().toString(36).substr(2, 9)}`;
  }

  private startBufferTimer(): void {
    if (this.buffer.timer) {
      clearInterval(this.buffer.timer);
    }

    this.buffer.timer = setInterval(() => {
      if (this.buffer.entries.length > 0) {
        this.flush();
      }
    }, this.FLUSH_INTERVAL);
  }

  setUserId(userId: string | null): void {
    this.userId = userId;
  }

  private createLogEntry(
    level: LogEntry['level'],
    message: string,
    context?: Record<string, any>
  ): LogEntry {
    const entry: LogEntry = {
      level,
      message,
      context,
      timestamp: new Date().toISOString(),
      sessionId: this.sessionId,
      environment: import.meta.env.MODE,
    };

    if (this.userId) {
      entry.userId = this.userId;
    }

    if (typeof window !== 'undefined') {
      entry.userAgent = navigator.userAgent;
      entry.url = window.location.href;
    }

    // Add stack trace for errors
    if (level === 'error' || level === 'fatal') {
      const error = new Error();
      entry.stack = error.stack;
    }

    return entry;
  }

  private addToBuffer(entry: LogEntry): void {
    this.buffer.entries.push(entry);

    // Flush if buffer is full
    if (this.buffer.entries.length >= this.MAX_BUFFER_SIZE) {
      this.flush();
    }

    // Immediately flush fatal errors
    if (entry.level === 'fatal') {
      this.flush(true);
    }
  }

  async flush(sync: boolean = false): Promise<void> {
    if (this.buffer.entries.length === 0) return;

    const entriesToFlush = [...this.buffer.entries];
    this.buffer.entries = [];

    if (sync) {
      // Synchronous flush for critical situations
      try {
        await this.sendLogs(entriesToFlush);
      } catch (error) {
        console.error('Failed to flush logs synchronously:', error);
      }
    } else {
      // Asynchronous flush with retry
      this.sendLogsWithRetry(entriesToFlush);
    }
  }

  private async sendLogsWithRetry(
    entries: LogEntry[],
    retryCount: number = 0
  ): Promise<void> {
    try {
      await this.sendLogs(entries);
    } catch (error) {
      if (retryCount < this.MAX_RETRIES) {
        // Exponential backoff
        const delay = Math.pow(2, retryCount) * 1000;
        setTimeout(() => {
          this.sendLogsWithRetry(entries, retryCount + 1);
        }, delay);
      } else {
        console.error('Failed to send logs after retries:', error);
        // Store failed logs in localStorage as fallback
        this.storeFailedLogs(entries);
      }
    }
  }

  private async sendLogs(entries: LogEntry[]): Promise<void> {
    // Skip in development unless explicitly enabled
    if (import.meta.env.MODE === 'development' && !import.meta.env.VITE_ENABLE_DEV_LOGGING) {
      entries.forEach(entry => {
        const method = entry.level === 'error' || entry.level === 'fatal' ? 'error' : 'log';
        console[method](`[${entry.level.toUpperCase()}]`, entry.message, entry.context);
      });
      return;
    }

    // Send to Supabase logs table
    const { error } = await supabase
      .from('application_logs')
      .insert(
        entries.map(entry => ({
          level: entry.level,
          message: entry.message,
          context: entry.context,
          timestamp: entry.timestamp,
          session_id: entry.sessionId,
          user_id: entry.userId,
          environment: entry.environment,
          user_agent: entry.userAgent,
          url: entry.url,
          stack_trace: entry.stack,
        }))
      );

    if (error) {
      throw error;
    }

    // Also send critical errors to an external service (optional)
    const criticalEntries = entries.filter(e => e.level === 'error' || e.level === 'fatal');
    if (criticalEntries.length > 0 && import.meta.env.VITE_EXTERNAL_LOGGING_ENDPOINT) {
      try {
        await fetch(import.meta.env.VITE_EXTERNAL_LOGGING_ENDPOINT, {
          method: 'POST',
          headers: {
            'Content-Type': 'application/json',
          },
          body: JSON.stringify({
            service: 'super-admin',
            entries: criticalEntries,
          }),
        });
      } catch (error) {
        console.error('Failed to send to external logging service:', error);
      }
    }
  }

  private storeFailedLogs(entries: LogEntry[]): void {
    try {
      const existingLogs = localStorage.getItem('failed_logs');
      const logs = existingLogs ? JSON.parse(existingLogs) : [];
      logs.push(...entries);
      
      // Keep only last 100 failed logs
      const trimmedLogs = logs.slice(-100);
      localStorage.setItem('failed_logs', JSON.stringify(trimmedLogs));
    } catch (error) {
      console.error('Failed to store logs in localStorage:', error);
    }
  }

  // Retry sending failed logs from localStorage
  async retryFailedLogs(): Promise<void> {
    try {
      const failedLogs = localStorage.getItem('failed_logs');
      if (!failedLogs) return;

      const logs = JSON.parse(failedLogs) as LogEntry[];
      if (logs.length === 0) return;

      await this.sendLogs(logs);
      localStorage.removeItem('failed_logs');
    } catch (error) {
      console.error('Failed to retry failed logs:', error);
    }
  }

  // Logging methods
  debug(message: string, context?: Record<string, any>): void {
    const entry = this.createLogEntry('debug', message, context);
    this.addToBuffer(entry);
  }

  info(message: string, context?: Record<string, any>): void {
    const entry = this.createLogEntry('info', message, context);
    this.addToBuffer(entry);
  }

  warn(message: string, context?: Record<string, any>): void {
    const entry = this.createLogEntry('warn', message, context);
    this.addToBuffer(entry);
  }

  error(message: string, context?: Record<string, any>): void {
    const entry = this.createLogEntry('error', message, context);
    this.addToBuffer(entry);
  }

  fatal(message: string, context?: Record<string, any>): void {
    const entry = this.createLogEntry('fatal', message, context);
    this.addToBuffer(entry);
  }

  // Performance logging
  logPerformance(metrics: {
    name: string;
    duration: number;
    metadata?: Record<string, any>;
  }): void {
    this.info(`Performance: ${metrics.name}`, {
      duration: metrics.duration,
      ...metrics.metadata,
    });
  }

  // User action logging
  logUserAction(action: string, details?: Record<string, any>): void {
    this.info(`User Action: ${action}`, details);
  }

  // API call logging
  logApiCall(endpoint: string, method: string, status: number, duration: number): void {
    const level = status >= 400 ? 'error' : 'info';
    const entry = this.createLogEntry(level, `API Call: ${method} ${endpoint}`, {
      endpoint,
      method,
      status,
      duration,
    });
    this.addToBuffer(entry);
  }

  // Clean up
  destroy(): void {
    if (this.buffer.timer) {
      clearInterval(this.buffer.timer);
    }
    this.flush(true);
  }
}

// Create singleton instance
export const productionLogger = new ProductionLogger();

// Export convenience functions
export const logDebug = (message: string, context?: Record<string, any>) => 
  productionLogger.debug(message, context);

export const logInfo = (message: string, context?: Record<string, any>) => 
  productionLogger.info(message, context);

export const logWarn = (message: string, context?: Record<string, any>) => 
  productionLogger.warn(message, context);

export const logError = (message: string, context?: Record<string, any>) => 
  productionLogger.error(message, context);

export const logFatal = (message: string, context?: Record<string, any>) => 
  productionLogger.fatal(message, context);

export const logPerformance = (metrics: {
  name: string;
  duration: number;
  metadata?: Record<string, any>;
}) => productionLogger.logPerformance(metrics);

export const logUserAction = (action: string, details?: Record<string, any>) => 
  productionLogger.logUserAction(action, details);

export const logApiCall = (endpoint: string, method: string, status: number, duration: number) => 
  productionLogger.logApiCall(endpoint, method, status, duration);