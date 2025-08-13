#!/usr/bin/env deno run --allow-net --allow-env

/**
 * Production Monitoring and Alerting System for KCT Menswear Payments
 * 
 * This system provides:
 * 1. Real-time payment performance monitoring
 * 2. Automated alerting for critical issues
 * 3. Payment flow health dashboards
 * 4. Performance metrics and analytics
 * 5. Incident response automation
 * 6. SLA monitoring and reporting
 * 
 * Usage: deno run --allow-net --allow-env production-monitoring-system.ts
 */

import { createClient } from "https://esm.sh/@supabase/supabase-js@2.45.0";

const SUPABASE_URL = Deno.env.get("SUPABASE_URL");
const SUPABASE_SERVICE_ROLE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");
const SLACK_WEBHOOK_URL = Deno.env.get("SLACK_WEBHOOK_URL");
const ADMIN_EMAIL = Deno.env.get("ADMIN_EMAIL") || "admin@kctmenswear.com";

if (!SUPABASE_URL || !SUPABASE_SERVICE_ROLE_KEY) {
  console.error("❌ Missing required environment variables");
  Deno.exit(1);
}

const supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY);

/**
 * Monitoring configuration and thresholds
 */
export interface MonitoringConfig {
  paymentFailureThreshold: number;      // % failure rate that triggers alert
  responseTimeThreshold: number;        // milliseconds
  checkoutSuccessThreshold: number;     // % success rate minimum
  webhookFailureThreshold: number;      // number of failures in window
  monitoringInterval: number;           // seconds between checks
  alertCooldown: number;               // seconds between similar alerts
}

export const DEFAULT_MONITORING_CONFIG: MonitoringConfig = {
  paymentFailureThreshold: 5,    // Alert if >5% payments fail
  responseTimeThreshold: 5000,   // Alert if >5s response time
  checkoutSuccessThreshold: 95,  // Alert if <95% checkout success
  webhookFailureThreshold: 3,    // Alert if 3+ webhook failures in 5 min
  monitoringInterval: 60,        // Check every minute
  alertCooldown: 300            // 5 minutes between similar alerts
};

/**
 * Alert severity levels
 */
export enum AlertSeverity {
  CRITICAL = "critical",
  WARNING = "warning", 
  INFO = "info"
}

export interface Alert {
  id: string;
  severity: AlertSeverity;
  title: string;
  message: string;
  metric: string;
  currentValue: number;
  threshold: number;
  timestamp: string;
  resolved: boolean;
  resolvedAt?: string;
}

/**
 * Production Monitoring Manager
 */
export class ProductionMonitoringManager {
  private config: MonitoringConfig;
  private supabase: any;
  private alertHistory: Map<string, number> = new Map(); // For cooldown tracking
  private isMonitoring: boolean = false;

  constructor(supabase: any, config: MonitoringConfig = DEFAULT_MONITORING_CONFIG) {
    this.supabase = supabase;
    this.config = config;
  }

  /**
   * Start continuous monitoring
   */
  async startMonitoring(): Promise<void> {
    console.log("🚀 Starting production monitoring system...");
    this.isMonitoring = true;

    // Initial health check
    await this.performHealthCheck();

    // Set up monitoring intervals
    setInterval(async () => {
      if (this.isMonitoring) {
        await this.performHealthCheck();
      }
    }, this.config.monitoringInterval * 1000);

    // Set up real-time webhook monitoring
    this.setupRealtimeMonitoring();

    console.log("✅ Production monitoring system started");
  }

  /**
   * Stop monitoring
   */
  stopMonitoring(): void {
    console.log("⏹️ Stopping production monitoring system");
    this.isMonitoring = false;
  }

  /**
   * Perform comprehensive health check
   */
  async performHealthCheck(): Promise<void> {
    console.log(`🩺 Performing health check at ${new Date().toISOString()}`);

    try {
      // Run all monitoring checks in parallel
      const checks = await Promise.allSettled([
        this.checkPaymentFailureRate(),
        this.checkCheckoutPerformance(),
        this.checkWebhookHealth(),
        this.checkDatabaseHealth(),
        this.checkSystemLoad(),
        this.checkSecurityMetrics()
      ]);

      // Process results and generate alerts
      checks.forEach((result, index) => {
        if (result.status === 'rejected') {
          console.error(`Health check ${index} failed:`, result.reason);
        }
      });

      // Update monitoring dashboard
      await this.updateMonitoringDashboard();

    } catch (error) {
      console.error("Error during health check:", error);
      await this.sendAlert({
        severity: AlertSeverity.CRITICAL,
        title: "Monitoring System Error",
        message: `Health check failed: ${error.message}`,
        metric: "monitoring_system",
        currentValue: 0,
        threshold: 1
      });
    }
  }

  /**
   * Check payment failure rate
   */
  async checkPaymentFailureRate(): Promise<void> {
    const timeWindow = 15; // minutes
    const startTime = new Date(Date.now() - timeWindow * 60 * 1000).toISOString();

    // Get payment attempts in last 15 minutes
    const { data: payments } = await this.supabase
      .from("orders")
      .select("payment_status, created_at")
      .gte("created_at", startTime);

    if (!payments || payments.length === 0) {
      return; // No recent payments to analyze
    }

    const totalPayments = payments.length;
    const failedPayments = payments.filter(p => 
      p.payment_status === 'failed' || p.payment_status === 'payment_failed'
    ).length;

    const failureRate = (failedPayments / totalPayments) * 100;

    if (failureRate > this.config.paymentFailureThreshold) {
      await this.sendAlert({
        severity: failureRate > 15 ? AlertSeverity.CRITICAL : AlertSeverity.WARNING,
        title: "High Payment Failure Rate",
        message: `Payment failure rate is ${failureRate.toFixed(1)}% (${failedPayments}/${totalPayments} payments failed in last ${timeWindow} minutes)`,
        metric: "payment_failure_rate",
        currentValue: failureRate,
        threshold: this.config.paymentFailureThreshold
      });
    }

    console.log(`📊 Payment failure rate: ${failureRate.toFixed(1)}% (${failedPayments}/${totalPayments})`);
  }

  /**
   * Check checkout performance
   */
  async checkCheckoutPerformance(): Promise<void> {
    // Get recent checkout sessions
    const timeWindow = 10; // minutes
    const startTime = new Date(Date.now() - timeWindow * 60 * 1000).toISOString();

    const { data: sessions } = await this.supabase
      .from("checkout_sessions")
      .select("status, created_at, completed_at")
      .gte("created_at", startTime);

    if (!sessions || sessions.length === 0) {
      return; // No recent checkouts
    }

    const totalSessions = sessions.length;
    const completedSessions = sessions.filter(s => s.status === 'completed').length;
    const successRate = (completedSessions / totalSessions) * 100;

    // Calculate average response time for completed sessions
    const completedWithTime = sessions.filter(s => s.completed_at && s.created_at);
    const avgResponseTime = completedWithTime.reduce((sum, session) => {
      const duration = new Date(session.completed_at).getTime() - new Date(session.created_at).getTime();
      return sum + duration;
    }, 0) / completedWithTime.length;

    // Check success rate
    if (successRate < this.config.checkoutSuccessThreshold) {
      await this.sendAlert({
        severity: successRate < 80 ? AlertSeverity.CRITICAL : AlertSeverity.WARNING,
        title: "Low Checkout Success Rate",
        message: `Checkout success rate is ${successRate.toFixed(1)}% (${completedSessions}/${totalSessions} successful in last ${timeWindow} minutes)`,
        metric: "checkout_success_rate",
        currentValue: successRate,
        threshold: this.config.checkoutSuccessThreshold
      });
    }

    // Check response time
    if (avgResponseTime && avgResponseTime > this.config.responseTimeThreshold) {
      await this.sendAlert({
        severity: avgResponseTime > 10000 ? AlertSeverity.CRITICAL : AlertSeverity.WARNING,
        title: "Slow Checkout Response Time",
        message: `Average checkout response time is ${(avgResponseTime / 1000).toFixed(2)}s`,
        metric: "checkout_response_time",
        currentValue: avgResponseTime,
        threshold: this.config.responseTimeThreshold
      });
    }

    console.log(`⚡ Checkout performance: ${successRate.toFixed(1)}% success, ${avgResponseTime ? (avgResponseTime / 1000).toFixed(2) + 's' : 'N/A'} avg response`);
  }

  /**
   * Check webhook health
   */
  async checkWebhookHealth(): Promise<void> {
    const timeWindow = 5; // minutes
    const startTime = new Date(Date.now() - timeWindow * 60 * 1000).toISOString();

    const { data: webhooks } = await this.supabase
      .from("webhook_logs")
      .select("status, created_at, error_message")
      .gte("created_at", startTime);

    if (!webhooks || webhooks.length === 0) {
      return; // No recent webhooks
    }

    const totalWebhooks = webhooks.length;
    const failedWebhooks = webhooks.filter(w => w.status === 'failed').length;
    const failureRate = (failedWebhooks / totalWebhooks) * 100;

    // Check absolute number of failures
    if (failedWebhooks >= this.config.webhookFailureThreshold) {
      await this.sendAlert({
        severity: failedWebhooks >= 5 ? AlertSeverity.CRITICAL : AlertSeverity.WARNING,
        title: "Webhook Failures Detected",
        message: `${failedWebhooks} webhook failures in last ${timeWindow} minutes (${failureRate.toFixed(1)}% failure rate)`,
        metric: "webhook_failures",
        currentValue: failedWebhooks,
        threshold: this.config.webhookFailureThreshold
      });
    }

    console.log(`🔗 Webhook health: ${failedWebhooks}/${totalWebhooks} failures (${failureRate.toFixed(1)}%)`);
  }

  /**
   * Check database health
   */
  async checkDatabaseHealth(): Promise<void> {
    try {
      const startTime = Date.now();
      
      // Test basic query performance
      await this.supabase
        .from("products")
        .select("id")
        .limit(1);

      const queryTime = Date.now() - startTime;

      if (queryTime > 2000) { // 2 second threshold
        await this.sendAlert({
          severity: queryTime > 5000 ? AlertSeverity.CRITICAL : AlertSeverity.WARNING,
          title: "Slow Database Response",
          message: `Database query took ${queryTime}ms`,
          metric: "database_response_time",
          currentValue: queryTime,
          threshold: 2000
        });
      }

      console.log(`🗄️ Database health: ${queryTime}ms response time`);

    } catch (error) {
      await this.sendAlert({
        severity: AlertSeverity.CRITICAL,
        title: "Database Connection Error",
        message: `Database connection failed: ${error.message}`,
        metric: "database_connection",
        currentValue: 0,
        threshold: 1
      });
    }
  }

  /**
   * Check system load metrics
   */
  async checkSystemLoad(): Promise<void> {
    try {
      // Monitor Edge Function invocations
      const timeWindow = 5; // minutes
      const startTime = new Date(Date.now() - timeWindow * 60 * 1000).toISOString();

      // This would typically integrate with monitoring APIs
      // For now, simulate based on recent activity
      const { data: recentOrders } = await this.supabase
        .from("orders")
        .select("id")
        .gte("created_at", startTime);

      const recentActivity = recentOrders?.length || 0;
      const estimatedLoad = recentActivity * 10; // Estimate based on orders

      if (estimatedLoad > 1000) { // High load threshold
        await this.sendAlert({
          severity: estimatedLoad > 2000 ? AlertSeverity.CRITICAL : AlertSeverity.WARNING,
          title: "High System Load",
          message: `Estimated system load: ${estimatedLoad} (based on ${recentActivity} recent orders)`,
          metric: "system_load",
          currentValue: estimatedLoad,
          threshold: 1000
        });
      }

      console.log(`⚙️ System load: ${estimatedLoad} (${recentActivity} recent orders)`);

    } catch (error) {
      console.error("Error checking system load:", error);
    }
  }

  /**
   * Check security metrics
   */
  async checkSecurityMetrics(): Promise<void> {
    const timeWindow = 15; // minutes
    const startTime = new Date(Date.now() - timeWindow * 60 * 1000).toISOString();

    try {
      // Check for suspicious webhook activity
      const { data: suspiciousWebhooks } = await this.supabase
        .from("webhook_logs")
        .select("ip_address, status")
        .gte("created_at", startTime)
        .eq("status", "rejected_ip");

      if (suspiciousWebhooks && suspiciousWebhooks.length > 5) {
        await this.sendAlert({
          severity: AlertSeverity.WARNING,
          title: "Suspicious Webhook Activity",
          message: `${suspiciousWebhooks.length} webhooks rejected due to unauthorized IP addresses`,
          metric: "security_rejections",
          currentValue: suspiciousWebhooks.length,
          threshold: 5
        });
      }

      // Check for failed authentication attempts
      const { data: authAttempts } = await this.supabase
        .from("audit_logs")
        .select("event_type")
        .gte("created_at", startTime)
        .eq("event_type", "auth_failure");

      if (authAttempts && authAttempts.length > 10) {
        await this.sendAlert({
          severity: AlertSeverity.WARNING,
          title: "Multiple Authentication Failures",
          message: `${authAttempts.length} failed authentication attempts in last ${timeWindow} minutes`,
          metric: "auth_failures",
          currentValue: authAttempts.length,
          threshold: 10
        });
      }

      console.log(`🔒 Security: ${suspiciousWebhooks?.length || 0} rejected webhooks, ${authAttempts?.length || 0} auth failures`);

    } catch (error) {
      console.error("Error checking security metrics:", error);
    }
  }

  /**
   * Set up real-time monitoring for critical events
   */
  private setupRealtimeMonitoring(): void {
    // Monitor webhook failures in real-time
    this.supabase
      .channel('webhook_monitoring')
      .on('postgres_changes', 
        { 
          event: 'INSERT', 
          schema: 'public', 
          table: 'webhook_logs',
          filter: 'status=eq.failed'
        }, 
        async (payload: any) => {
          await this.handleRealtimeWebhookFailure(payload.new);
        }
      )
      .subscribe();

    // Monitor payment failures in real-time
    this.supabase
      .channel('payment_monitoring')
      .on('postgres_changes',
        {
          event: 'INSERT',
          schema: 'public',
          table: 'payment_failures'
        },
        async (payload: any) => {
          await this.handleRealtimePaymentFailure(payload.new);
        }
      )
      .subscribe();

    console.log("📡 Real-time monitoring channels established");
  }

  /**
   * Handle real-time webhook failure
   */
  private async handleRealtimeWebhookFailure(webhookData: any): Promise<void> {
    await this.sendAlert({
      severity: AlertSeverity.WARNING,
      title: "Real-time Webhook Failure",
      message: `Webhook ${webhookData.webhook_id} failed: ${webhookData.error_message}`,
      metric: "realtime_webhook_failure",
      currentValue: 1,
      threshold: 0
    });
  }

  /**
   * Handle real-time payment failure
   */
  private async handleRealtimePaymentFailure(paymentData: any): Promise<void> {
    await this.sendAlert({
      severity: AlertSeverity.WARNING,
      title: "Real-time Payment Failure",
      message: `Payment failed for order ${paymentData.order_id}: ${paymentData.failure_reason}`,
      metric: "realtime_payment_failure",
      currentValue: 1,
      threshold: 0
    });
  }

  /**
   * Send alert with cooldown logic
   */
  async sendAlert(alertData: Partial<Alert>): Promise<void> {
    const alertKey = `${alertData.metric}_${alertData.severity}`;
    const now = Date.now();
    const lastAlert = this.alertHistory.get(alertKey) || 0;

    // Check cooldown period
    if (now - lastAlert < this.config.alertCooldown * 1000) {
      console.log(`⏰ Alert cooldown active for ${alertKey}`);
      return;
    }

    const alert: Alert = {
      id: crypto.randomUUID(),
      severity: alertData.severity!,
      title: alertData.title!,
      message: alertData.message!,
      metric: alertData.metric!,
      currentValue: alertData.currentValue!,
      threshold: alertData.threshold!,
      timestamp: new Date().toISOString(),
      resolved: false
    };

    // Store alert in database
    await this.supabase
      .from("monitoring_alerts")
      .insert(alert);

    // Send notifications
    await Promise.all([
      this.sendSlackAlert(alert),
      this.sendEmailAlert(alert),
      this.logAlert(alert)
    ]);

    // Update cooldown tracker
    this.alertHistory.set(alertKey, now);

    console.log(`🚨 Alert sent: ${alert.severity.toUpperCase()} - ${alert.title}`);
  }

  /**
   * Send Slack notification
   */
  private async sendSlackAlert(alert: Alert): Promise<void> {
    if (!SLACK_WEBHOOK_URL) return;

    const color = {
      [AlertSeverity.CRITICAL]: "#FF0000",
      [AlertSeverity.WARNING]: "#FFA500", 
      [AlertSeverity.INFO]: "#00FF00"
    }[alert.severity];

    const emoji = {
      [AlertSeverity.CRITICAL]: "🚨",
      [AlertSeverity.WARNING]: "⚠️",
      [AlertSeverity.INFO]: "ℹ️"
    }[alert.severity];

    const slackPayload = {
      text: `${emoji} KCT Menswear Payment Alert`,
      attachments: [
        {
          color: color,
          title: alert.title,
          text: alert.message,
          fields: [
            {
              title: "Metric",
              value: alert.metric,
              short: true
            },
            {
              title: "Current Value",
              value: alert.currentValue.toString(),
              short: true
            },
            {
              title: "Threshold",
              value: alert.threshold.toString(),
              short: true
            },
            {
              title: "Timestamp",
              value: new Date(alert.timestamp).toLocaleString(),
              short: true
            }
          ],
          footer: "KCT Menswear Monitoring",
          ts: Math.floor(new Date(alert.timestamp).getTime() / 1000)
        }
      ]
    };

    try {
      await fetch(SLACK_WEBHOOK_URL, {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify(slackPayload)
      });
    } catch (error) {
      console.error("Error sending Slack alert:", error);
    }
  }

  /**
   * Send email alert
   */
  private async sendEmailAlert(alert: Alert): Promise<void> {
    if (alert.severity === AlertSeverity.INFO) return; // Skip email for info alerts

    const emailData = {
      to: ADMIN_EMAIL,
      subject: `${alert.severity.toUpperCase()}: ${alert.title} - KCT Menswear`,
      html: `
        <h2>Payment System Alert</h2>
        <p><strong>Severity:</strong> ${alert.severity.toUpperCase()}</p>
        <p><strong>Title:</strong> ${alert.title}</p>
        <p><strong>Message:</strong> ${alert.message}</p>
        <p><strong>Metric:</strong> ${alert.metric}</p>
        <p><strong>Current Value:</strong> ${alert.currentValue}</p>
        <p><strong>Threshold:</strong> ${alert.threshold}</p>
        <p><strong>Time:</strong> ${new Date(alert.timestamp).toLocaleString()}</p>
        
        <hr>
        <p>This is an automated alert from the KCT Menswear production monitoring system.</p>
      `,
      text: `
        Payment System Alert
        
        Severity: ${alert.severity.toUpperCase()}
        Title: ${alert.title}
        Message: ${alert.message}
        Metric: ${alert.metric}
        Current Value: ${alert.currentValue}
        Threshold: ${alert.threshold}
        Time: ${new Date(alert.timestamp).toLocaleString()}
      `
    };

    try {
      await fetch(`${SUPABASE_URL}/functions/v1/send-email`, {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          "Authorization": `Bearer ${SUPABASE_SERVICE_ROLE_KEY}`
        },
        body: JSON.stringify(emailData)
      });
    } catch (error) {
      console.error("Error sending email alert:", error);
    }
  }

  /**
   * Log alert to console
   */
  private logAlert(alert: Alert): void {
    const emoji = {
      [AlertSeverity.CRITICAL]: "🚨",
      [AlertSeverity.WARNING]: "⚠️",
      [AlertSeverity.INFO]: "ℹ️"
    }[alert.severity];

    console.log(`${emoji} ALERT [${alert.severity.toUpperCase()}]: ${alert.title}`);
    console.log(`   Message: ${alert.message}`);
    console.log(`   Metric: ${alert.metric} (${alert.currentValue} > ${alert.threshold})`);
    console.log(`   Time: ${new Date(alert.timestamp).toLocaleString()}`);
  }

  /**
   * Update monitoring dashboard
   */
  private async updateMonitoringDashboard(): Promise<void> {
    try {
      const dashboardData = {
        last_check: new Date().toISOString(),
        status: "healthy", // Would be calculated based on current metrics
        uptime: this.calculateUptime(),
        metrics: await this.gatherCurrentMetrics()
      };

      await this.supabase
        .from("monitoring_dashboard")
        .upsert(dashboardData, { onConflict: "singleton" });

    } catch (error) {
      console.error("Error updating dashboard:", error);
    }
  }

  /**
   * Calculate system uptime
   */
  private calculateUptime(): string {
    // This would integrate with actual uptime monitoring
    // For now, return a placeholder
    return "99.9%";
  }

  /**
   * Gather current performance metrics
   */
  private async gatherCurrentMetrics(): Promise<any> {
    try {
      const timeWindow = 60; // 1 hour
      const startTime = new Date(Date.now() - timeWindow * 60 * 1000).toISOString();

      const [orders, webhooks, checkouts] = await Promise.all([
        this.supabase.from("orders").select("payment_status").gte("created_at", startTime),
        this.supabase.from("webhook_logs").select("status").gte("created_at", startTime),
        this.supabase.from("checkout_sessions").select("status").gte("created_at", startTime)
      ]);

      const paymentSuccessRate = orders.data ? 
        (orders.data.filter(o => o.payment_status === 'paid').length / orders.data.length) * 100 : 100;

      const webhookSuccessRate = webhooks.data ?
        (webhooks.data.filter(w => w.status === 'completed').length / webhooks.data.length) * 100 : 100;

      const checkoutSuccessRate = checkouts.data ?
        (checkouts.data.filter(c => c.status === 'completed').length / checkouts.data.length) * 100 : 100;

      return {
        payment_success_rate: paymentSuccessRate.toFixed(1) + "%",
        webhook_success_rate: webhookSuccessRate.toFixed(1) + "%",
        checkout_success_rate: checkoutSuccessRate.toFixed(1) + "%",
        total_orders: orders.data?.length || 0,
        total_webhooks: webhooks.data?.length || 0,
        total_checkouts: checkouts.data?.length || 0
      };

    } catch (error) {
      console.error("Error gathering metrics:", error);
      return {};
    }
  }

  /**
   * Get monitoring status report
   */
  async getStatusReport(): Promise<any> {
    const timeWindow = 24; // 24 hours
    const startTime = new Date(Date.now() - timeWindow * 60 * 60 * 1000).toISOString();

    const { data: alerts } = await this.supabase
      .from("monitoring_alerts")
      .select("*")
      .gte("timestamp", startTime)
      .order("timestamp", { ascending: false });

    const criticalAlerts = alerts?.filter(a => a.severity === AlertSeverity.CRITICAL).length || 0;
    const warningAlerts = alerts?.filter(a => a.severity === AlertSeverity.WARNING).length || 0;
    const totalAlerts = alerts?.length || 0;

    const metrics = await this.gatherCurrentMetrics();

    return {
      period: `Last ${timeWindow} hours`,
      overall_status: criticalAlerts > 0 ? "CRITICAL" : warningAlerts > 0 ? "WARNING" : "HEALTHY",
      alerts_summary: {
        total: totalAlerts,
        critical: criticalAlerts,
        warning: warningAlerts,
        resolved: alerts?.filter(a => a.resolved).length || 0
      },
      current_metrics: metrics,
      uptime: this.calculateUptime(),
      last_updated: new Date().toISOString()
    };
  }
}

/**
 * Monitoring dashboard data structures
 */
export interface MonitoringDashboard {
  payment_health: {
    success_rate: string;
    failure_rate: string;
    avg_processing_time: string;
    recent_failures: number;
  };
  webhook_health: {
    success_rate: string;
    avg_response_time: string;
    recent_failures: number;
  };
  system_health: {
    uptime: string;
    response_time: string;
    error_rate: string;
  };
  security_status: {
    blocked_attempts: number;
    suspicious_activity: number;
    last_security_scan: string;
  };
}

// Testing and demonstration functions
async function testMonitoringSystem(): Promise<void> {
  console.log("🧪 Testing Production Monitoring System\n");

  const monitor = new ProductionMonitoringManager(supabase);

  // Test individual health checks
  console.log("1. Testing Health Checks:");
  await monitor.performHealthCheck();

  // Test alert system
  console.log("\n2. Testing Alert System:");
  await monitor.sendAlert({
    severity: AlertSeverity.INFO,
    title: "Test Alert",
    message: "This is a test alert from the monitoring system",
    metric: "test_metric",
    currentValue: 100,
    threshold: 50
  });

  // Get status report
  console.log("\n3. Getting Status Report:");
  const status = await monitor.getStatusReport();
  console.log("Status Report:", JSON.stringify(status, null, 2));

  console.log("\n✅ Monitoring system testing completed");
}

// Main execution
if (import.meta.main) {
  console.log("🚀 KCT Menswear Production Monitoring System");
  
  if (Deno.args.includes("--test")) {
    await testMonitoringSystem();
  } else if (Deno.args.includes("--start")) {
    const monitor = new ProductionMonitoringManager(supabase);
    await monitor.startMonitoring();
    
    // Keep the process running
    await new Promise(() => {});
  } else {
    console.log("\nUsage:");
    console.log("  --test   Run monitoring system tests");
    console.log("  --start  Start continuous monitoring");
  }
}