/**
 * Performance monitoring utilities
 */

interface PerformanceMetric {
  name: string;
  duration: number;
  timestamp: number;
}

class PerformanceMonitor {
  private metrics: PerformanceMetric[] = [];
  private marks: Map<string, number> = new Map();

  /**
   * Start measuring a performance metric
   */
  startMeasure(name: string): void {
    this.marks.set(name, performance.now());
  }

  /**
   * End measuring and record the metric
   */
  endMeasure(name: string): number {
    const startTime = this.marks.get(name);
    if (!startTime) {
      console.warn(`No start mark found for ${name}`);
      return 0;
    }

    const duration = performance.now() - startTime;
    this.metrics.push({
      name,
      duration,
      timestamp: Date.now(),
    });

    this.marks.delete(name);

    // Log slow operations in development
    if (import.meta.env.DEV && duration > 100) {
      console.warn(`Slow operation detected: ${name} took ${duration.toFixed(2)}ms`);
    }

    return duration;
  }

  /**
   * Measure async function performance
   */
  async measureAsync<T>(
    name: string,
    fn: () => Promise<T>
  ): Promise<T> {
    this.startMeasure(name);
    try {
      const result = await fn();
      return result;
    } finally {
      this.endMeasure(name);
    }
  }

  /**
   * Get all recorded metrics
   */
  getMetrics(): PerformanceMetric[] {
    return [...this.metrics];
  }

  /**
   * Get average duration for a specific metric
   */
  getAverageDuration(name: string): number {
    const relevantMetrics = this.metrics.filter(m => m.name === name);
    if (relevantMetrics.length === 0) return 0;
    
    const total = relevantMetrics.reduce((sum, m) => sum + m.duration, 0);
    return total / relevantMetrics.length;
  }

  /**
   * Clear all metrics
   */
  clear(): void {
    this.metrics = [];
    this.marks.clear();
  }

  /**
   * Export metrics for analysis
   */
  exportMetrics(): string {
    const summary = this.metrics.reduce((acc, metric) => {
      if (!acc[metric.name]) {
        acc[metric.name] = {
          count: 0,
          totalDuration: 0,
          minDuration: Infinity,
          maxDuration: -Infinity,
        };
      }
      
      acc[metric.name].count++;
      acc[metric.name].totalDuration += metric.duration;
      acc[metric.name].minDuration = Math.min(acc[metric.name].minDuration, metric.duration);
      acc[metric.name].maxDuration = Math.max(acc[metric.name].maxDuration, metric.duration);
      
      return acc;
    }, {} as Record<string, any>);

    Object.keys(summary).forEach(key => {
      summary[key].averageDuration = summary[key].totalDuration / summary[key].count;
    });

    return JSON.stringify(summary, null, 2);
  }
}

// Singleton instance
export const performanceMonitor = new PerformanceMonitor();

/**
 * React hook for performance monitoring
 */
export function usePerformanceMonitor() {
  return performanceMonitor;
}

/**
 * HOC to measure component render performance
 */
export function withPerformanceMonitoring<P extends object>(
  Component: React.ComponentType<P>,
  componentName: string
) {
  return (props: P) => {
    const monitor = usePerformanceMonitor();
    
    React.useEffect(() => {
      monitor.startMeasure(`${componentName}-mount`);
      return () => {
        monitor.endMeasure(`${componentName}-mount`);
      };
    }, []);

    return <Component {...props} />;
  };
}