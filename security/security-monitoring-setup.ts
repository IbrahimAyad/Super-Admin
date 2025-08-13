/**
 * Enterprise Security Monitoring and Alerting System
 * Real-time threat detection and automated incident response
 * Version: 1.0.0
 * Date: 2025-08-13
 */

import { createClient } from '@supabase/supabase-js';

// Types for security monitoring
export interface SecurityAlert {
  id: string;
  level: 'info' | 'warning' | 'critical';
  type: string;
  message: string;
  data: Record<string, any>;
  timestamp: string;
  resolved: boolean;
  assignee?: string;
  actions_taken?: string[];
}

export interface ThreatIndicator {
  type: 'ip' | 'user' | 'pattern' | 'anomaly';
  value: string;
  risk_score: number;
  confidence: number;
  first_seen: string;
  last_seen: string;
  occurrences: number;
  context: Record<string, any>;
}

export interface SecurityMetric {
  name: string;
  value: number;
  unit: string;
  timestamp: string;
  tags: Record<string, string>;
  threshold?: {
    warning: number;
    critical: number;
  };
}

export interface IncidentResponse {
  incident_id: string;
  severity: 'low' | 'medium' | 'high' | 'critical';
  status: 'open' | 'investigating' | 'contained' | 'resolved';
  assigned_to: string;
  created_at: string;
  updated_at: string;
  timeline: Array<{
    timestamp: string;
    action: string;
    actor: string;
    details: string;
  }>;
}

/**
 * Security Monitoring Service
 */
export class SecurityMonitoringService {
  private supabase;
  private alertCallbacks: Map<string, Function[]> = new Map();
  private monitoringInterval: number = 30000; // 30 seconds
  private isMonitoring: boolean = false;
  private metrics: Map<string, SecurityMetric[]> = new Map();

  constructor(supabaseUrl: string, supabaseKey: string) {
    this.supabase = createClient(supabaseUrl, supabaseKey);
    this.startRealTimeMonitoring();
  }

  /**
   * Start real-time security monitoring
   */
  private startRealTimeMonitoring(): void {
    // Subscribe to security events
    this.supabase
      .channel('security-events')
      .on('postgres_changes', 
        { 
          event: 'INSERT', 
          schema: 'public', 
          table: 'security_audit_log',
          filter: 'risk_score.gte.70' 
        }, 
        (payload) => {
          this.handleHighRiskEvent(payload.new);
        }
      )
      .on('postgres_changes',
        {
          event: 'INSERT',
          schema: 'public', 
          table: 'access_violations'
        },
        (payload) => {
          this.handleAccessViolation(payload.new);
        }
      )
      .subscribe();

    // Start periodic monitoring
    this.isMonitoring = true;
    this.periodicMonitoring();
  }

  /**
   * Handle high-risk security events
   */
  private async handleHighRiskEvent(event: any): Promise<void> {
    const alert: SecurityAlert = {
      id: crypto.randomUUID(),
      level: event.risk_score >= 90 ? 'critical' : 'warning',
      type: event.event_type,
      message: `High-risk security event detected: ${event.event_type}`,
      data: {
        ...event.event_data,
        risk_score: event.risk_score,
        ip_address: event.ip_address,
        user_agent: event.user_agent
      },
      timestamp: new Date().toISOString(),
      resolved: false,
      actions_taken: []
    };

    // Execute immediate response
    await this.executeImmediateResponse(event);

    // Send alerts
    await this.sendAlert(alert);

    // Log to security dashboard
    console.error(`🚨 SECURITY ALERT [${alert.level.toUpperCase()}]:`, {
      type: alert.type,
      risk_score: event.risk_score,
      ip: event.ip_address,
      automated_response: event.automated_response
    });
  }

  /**
   * Handle access violations
   */
  private async handleAccessViolation(violation: any): Promise<void> {
    // Create threat indicator
    const indicator: ThreatIndicator = {
      type: 'ip',
      value: violation.ip_address,
      risk_score: this.calculateRiskScore(violation),
      confidence: 0.8,
      first_seen: violation.first_attempt_at,
      last_seen: violation.last_attempt_at,
      occurrences: violation.attempt_count,
      context: {
        violation_type: violation.violation_type,
        resource_type: violation.resource_type,
        user_agent: violation.user_agent
      }
    };

    // Store threat indicator
    await this.storeThreatIndicator(indicator);

    // Check if should be auto-blocked
    if (violation.attempt_count >= 10) {
      await this.autoBlockThreat(indicator);
    }
  }

  /**
   * Execute immediate response to security events
   */
  private async executeImmediateResponse(event: any): Promise<void> {
    const responses = [];

    switch (event.automated_response) {
      case 'block_user_immediate':
        await this.blockUser(event.user_id);
        responses.push('User blocked');
        break;

      case 'block_ip_and_alert':
        await this.blockIP(event.ip_address);
        await this.alertSecurityTeam(event);
        responses.push('IP blocked', 'Security team alerted');
        break;

      case 'revoke_access_and_alert':
        await this.revokeUserAccess(event.user_id);
        await this.alertSecurityTeam(event);
        responses.push('Access revoked', 'Security team alerted');
        break;

      case 'alert_security_team':
        await this.alertSecurityTeam(event);
        responses.push('Security team alerted');
        break;
    }

    // Update event with actions taken
    if (responses.length > 0) {
      await this.supabase
        .from('security_audit_log')
        .update({ 
          event_data: { 
            ...event.event_data, 
            actions_taken: responses 
          }
        })
        .eq('id', event.id);
    }
  }

  /**
   * Periodic monitoring for anomaly detection
   */
  private async periodicMonitoring(): Promise<void> {
    if (!this.isMonitoring) return;

    try {
      // Check for anomalies
      await this.detectAnomalies();
      
      // Update security metrics
      await this.updateSecurityMetrics();
      
      // Check threat indicators
      await this.checkThreatIndicators();
      
      // Cleanup old data
      await this.cleanupOldData();
      
    } catch (error) {
      console.error('Error in periodic monitoring:', error);
    }

    // Schedule next monitoring cycle
    setTimeout(() => this.periodicMonitoring(), this.monitoringInterval);
  }

  /**
   * Detect security anomalies using statistical analysis
   */
  private async detectAnomalies(): Promise<void> {
    // Check for unusual login patterns
    const { data: loginPatterns } = await this.supabase
      .rpc('detect_login_anomalies', {
        time_window: '1 hour',
        threshold_multiplier: 3.0
      });

    if (loginPatterns && loginPatterns.length > 0) {
      for (const pattern of loginPatterns) {
        await this.createAnomalyAlert(pattern);
      }
    }

    // Check for unusual API usage patterns
    const { data: apiAnomalies } = await this.supabase
      .rpc('detect_api_anomalies', {
        time_window: '1 hour',
        rate_threshold: 1000
      });

    if (apiAnomalies && apiAnomalies.length > 0) {
      for (const anomaly of apiAnomalies) {
        await this.createAnomalyAlert(anomaly);
      }
    }

    // Check for data exfiltration patterns
    const { data: dataAnomalies } = await this.supabase
      .rpc('detect_data_exfiltration', {
        size_threshold: 100 * 1024 * 1024, // 100MB
        request_threshold: 50
      });

    if (dataAnomalies && dataAnomalies.length > 0) {
      for (const anomaly of dataAnomalies) {
        await this.createCriticalAlert(anomaly);
      }
    }
  }

  /**
   * Update security metrics dashboard
   */
  private async updateSecurityMetrics(): Promise<void> {
    const now = new Date().toISOString();

    // Failed login attempts (last hour)
    const { count: failedLogins } = await this.supabase
      .from('security_audit_log')
      .select('*', { count: 'exact' })
      .eq('event_type', 'login_failure')
      .gte('created_at', new Date(Date.now() - 3600000).toISOString());

    this.recordMetric({
      name: 'failed_logins_hourly',
      value: failedLogins || 0,
      unit: 'count',
      timestamp: now,
      tags: { time_window: '1h' },
      threshold: { warning: 100, critical: 500 }
    });

    // High-risk events (last hour)
    const { count: highRiskEvents } = await this.supabase
      .from('security_audit_log')
      .select('*', { count: 'exact' })
      .gte('risk_score', 70)
      .gte('created_at', new Date(Date.now() - 3600000).toISOString());

    this.recordMetric({
      name: 'high_risk_events_hourly',
      value: highRiskEvents || 0,
      unit: 'count',
      timestamp: now,
      tags: { time_window: '1h' },
      threshold: { warning: 10, critical: 50 }
    });

    // Blocked IPs (total active)
    const { count: blockedIPs } = await this.supabase
      .from('access_violations')
      .select('*', { count: 'exact' })
      .eq('is_permanently_blocked', true);

    this.recordMetric({
      name: 'blocked_ips_total',
      value: blockedIPs || 0,
      unit: 'count',
      timestamp: now,
      tags: { type: 'cumulative' }
    });

    // Average risk score (last 24h)
    const { data: avgRisk } = await this.supabase
      .from('security_audit_log')
      .select('risk_score')
      .gte('created_at', new Date(Date.now() - 86400000).toISOString());

    if (avgRisk && avgRisk.length > 0) {
      const avgRiskScore = avgRisk.reduce((sum, item) => sum + item.risk_score, 0) / avgRisk.length;
      this.recordMetric({
        name: 'average_risk_score_daily',
        value: Math.round(avgRiskScore),
        unit: 'score',
        timestamp: now,
        tags: { time_window: '24h' },
        threshold: { warning: 30, critical: 50 }
      });
    }
  }

  /**
   * Record a security metric
   */
  private recordMetric(metric: SecurityMetric): void {
    const key = `${metric.name}_${metric.tags?.time_window || 'default'}`;
    if (!this.metrics.has(key)) {
      this.metrics.set(key, []);
    }
    
    const metrics = this.metrics.get(key)!;
    metrics.push(metric);
    
    // Keep only last 100 metrics
    if (metrics.length > 100) {
      metrics.shift();
    }

    // Check thresholds
    this.checkMetricThresholds(metric);
  }

  /**
   * Check metric thresholds and send alerts
   */
  private checkMetricThresholds(metric: SecurityMetric): void {
    if (!metric.threshold) return;

    let alertLevel: 'warning' | 'critical' | null = null;
    
    if (metric.value >= metric.threshold.critical) {
      alertLevel = 'critical';
    } else if (metric.value >= metric.threshold.warning) {
      alertLevel = 'warning';
    }

    if (alertLevel) {
      const alert: SecurityAlert = {
        id: crypto.randomUUID(),
        level: alertLevel,
        type: 'metric_threshold',
        message: `Security metric threshold exceeded: ${metric.name}`,
        data: {
          metric: metric.name,
          value: metric.value,
          threshold: metric.threshold,
          unit: metric.unit,
          tags: metric.tags
        },
        timestamp: new Date().toISOString(),
        resolved: false
      };

      this.sendAlert(alert);
    }
  }

  /**
   * Create anomaly alert
   */
  private async createAnomalyAlert(anomaly: any): Promise<void> {
    const alert: SecurityAlert = {
      id: crypto.randomUUID(),
      level: 'warning',
      type: 'anomaly_detected',
      message: `Security anomaly detected: ${anomaly.type}`,
      data: anomaly,
      timestamp: new Date().toISOString(),
      resolved: false
    };

    await this.sendAlert(alert);
  }

  /**
   * Create critical alert
   */
  private async createCriticalAlert(event: any): Promise<void> {
    const alert: SecurityAlert = {
      id: crypto.randomUUID(),
      level: 'critical',
      type: 'critical_threat',
      message: `Critical security threat detected: ${event.type}`,
      data: event,
      timestamp: new Date().toISOString(),
      resolved: false
    };

    await this.sendAlert(alert);
    
    // Immediately notify security team
    await this.alertSecurityTeam(event);
  }

  /**
   * Send security alert through various channels
   */
  private async sendAlert(alert: SecurityAlert): Promise<void> {
    try {
      // Store alert in database
      await this.supabase
        .from('security_alerts')
        .insert({
          id: alert.id,
          level: alert.level,
          type: alert.type,
          message: alert.message,
          data: alert.data,
          resolved: alert.resolved,
          created_at: alert.timestamp
        });

      // Execute registered callbacks
      const callbacks = this.alertCallbacks.get(alert.type) || [];
      callbacks.forEach(callback => {
        try {
          callback(alert);
        } catch (error) {
          console.error('Error in alert callback:', error);
        }
      });

      // Send to external services based on level
      if (alert.level === 'critical') {
        await this.sendCriticalAlert(alert);
      } else if (alert.level === 'warning') {
        await this.sendWarningAlert(alert);
      }

    } catch (error) {
      console.error('Error sending security alert:', error);
    }
  }

  /**
   * Send critical alert to immediate notification channels
   */
  private async sendCriticalAlert(alert: SecurityAlert): Promise<void> {
    // Send to PagerDuty, Slack, Email, SMS, etc.
    // Implementation depends on available services
    
    // Example: Send to webhook endpoint
    try {
      const webhookUrl = process.env.CRITICAL_ALERT_WEBHOOK;
      if (webhookUrl) {
        await fetch(webhookUrl, {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify({
            alert_type: 'critical_security',
            message: alert.message,
            data: alert.data,
            timestamp: alert.timestamp
          })
        });
      }
    } catch (error) {
      console.error('Error sending critical alert:', error);
    }
  }

  /**
   * Send warning alert to standard notification channels
   */
  private async sendWarningAlert(alert: SecurityAlert): Promise<void> {
    // Send to standard notification channels
    console.warn(`⚠️ SECURITY WARNING: ${alert.message}`, alert.data);
  }

  /**
   * Block a user account
   */
  private async blockUser(userId: string): Promise<void> {
    if (!userId) return;

    try {
      await this.supabase.auth.admin.updateUserById(userId, {
        banned_until: new Date(Date.now() + 24 * 60 * 60 * 1000).toISOString() // 24 hours
      });

      console.log(`User ${userId} has been blocked for 24 hours`);
    } catch (error) {
      console.error('Error blocking user:', error);
    }
  }

  /**
   * Block an IP address
   */
  private async blockIP(ipAddress: string): Promise<void> {
    if (!ipAddress) return;

    try {
      await this.supabase
        .from('access_violations')
        .upsert({
          violation_type: 'automated_security_block',
          resource_type: 'ip_address',
          ip_address: ipAddress,
          is_permanently_blocked: true,
          notes: 'Automatically blocked due to high-risk security event',
          blocked_until: new Date(Date.now() + 7 * 24 * 60 * 60 * 1000).toISOString(), // 7 days
          first_attempt_at: new Date().toISOString(),
          last_attempt_at: new Date().toISOString(),
          attempt_count: 1
        });

      console.log(`IP ${ipAddress} has been blocked`);
    } catch (error) {
      console.error('Error blocking IP:', error);
    }
  }

  /**
   * Revoke user access
   */
  private async revokeUserAccess(userId: string): Promise<void> {
    if (!userId) return;

    try {
      // Sign out all sessions
      await this.supabase.auth.admin.signOut(userId, 'global');
      
      // Mark user as requiring re-verification
      await this.supabase
        .from('user_profiles')
        .update({ 
          account_locked_at: new Date().toISOString(),
          account_locked_reason: 'Security violation - manual review required'
        })
        .eq('id', userId);

      console.log(`Access revoked for user ${userId}`);
    } catch (error) {
      console.error('Error revoking user access:', error);
    }
  }

  /**
   * Alert security team
   */
  private async alertSecurityTeam(event: any): Promise<void> {
    try {
      // Send alert to Edge Function
      const { error } = await this.supabase.functions.invoke('send-security-alert', {
        body: {
          event_type: event.event_type,
          risk_score: event.risk_score,
          event_data: event.event_data,
          ip_address: event.ip_address,
          timestamp: event.created_at
        }
      });

      if (error) {
        console.error('Error alerting security team:', error);
      }
    } catch (error) {
      console.error('Error sending security team alert:', error);
    }
  }

  /**
   * Calculate risk score for violations
   */
  private calculateRiskScore(violation: any): number {
    let score = 30; // Base score

    // Increase based on attempt count
    if (violation.attempt_count > 50) score += 40;
    else if (violation.attempt_count > 20) score += 30;
    else if (violation.attempt_count > 10) score += 20;
    else if (violation.attempt_count > 5) score += 10;

    // Increase based on violation type
    switch (violation.violation_type) {
      case 'admin_access_attempt':
        score += 30;
        break;
      case 'payment_manipulation':
        score += 40;
        break;
      case 'data_extraction':
        score += 35;
        break;
      case 'injection_attempt':
        score += 35;
        break;
    }

    return Math.min(score, 100);
  }

  /**
   * Store threat indicator
   */
  private async storeThreatIndicator(indicator: ThreatIndicator): Promise<void> {
    try {
      await this.supabase
        .from('threat_indicators')
        .upsert({
          type: indicator.type,
          value: indicator.value,
          risk_score: indicator.risk_score,
          confidence: indicator.confidence,
          first_seen: indicator.first_seen,
          last_seen: indicator.last_seen,
          occurrences: indicator.occurrences,
          context: indicator.context
        });
    } catch (error) {
      console.error('Error storing threat indicator:', error);
    }
  }

  /**
   * Auto-block high-risk threats
   */
  private async autoBlockThreat(indicator: ThreatIndicator): Promise<void> {
    if (indicator.risk_score >= 80) {
      if (indicator.type === 'ip') {
        await this.blockIP(indicator.value);
      } else if (indicator.type === 'user') {
        await this.blockUser(indicator.value);
      }
    }
  }

  /**
   * Check threat indicators for escalation
   */
  private async checkThreatIndicators(): Promise<void> {
    const { data: indicators } = await this.supabase
      .from('threat_indicators')
      .select('*')
      .gte('risk_score', 70)
      .gte('last_seen', new Date(Date.now() - 3600000).toISOString()); // Last hour

    if (indicators && indicators.length > 0) {
      for (const indicator of indicators) {
        if (indicator.risk_score >= 90) {
          await this.createCriticalAlert({
            type: 'threat_indicator_escalation',
            indicator: indicator
          });
        }
      }
    }
  }

  /**
   * Cleanup old monitoring data
   */
  private async cleanupOldData(): Promise<void> {
    const cutoffDate = new Date(Date.now() - 30 * 24 * 60 * 60 * 1000).toISOString(); // 30 days

    try {
      // Cleanup old security events (keep critical events longer)
      await this.supabase
        .from('security_audit_log')
        .delete()
        .lt('created_at', cutoffDate)
        .lt('risk_score', 50);

      // Cleanup old metrics
      await this.supabase
        .from('security_metrics')
        .delete()
        .lt('recorded_at', cutoffDate);

      // Cleanup resolved alerts
      await this.supabase
        .from('security_alerts')
        .delete()
        .lt('created_at', cutoffDate)
        .eq('resolved', true);

    } catch (error) {
      console.error('Error in cleanup:', error);
    }
  }

  /**
   * Register alert callback
   */
  public onAlert(eventType: string, callback: (alert: SecurityAlert) => void): void {
    if (!this.alertCallbacks.has(eventType)) {
      this.alertCallbacks.set(eventType, []);
    }
    this.alertCallbacks.get(eventType)!.push(callback);
  }

  /**
   * Get security metrics
   */
  public getMetrics(): Map<string, SecurityMetric[]> {
    return this.metrics;
  }

  /**
   * Stop monitoring
   */
  public stopMonitoring(): void {
    this.isMonitoring = false;
  }
}

/**
 * Initialize security monitoring
 */
export function initializeSecurityMonitoring(
  supabaseUrl: string, 
  supabaseKey: string
): SecurityMonitoringService {
  const monitor = new SecurityMonitoringService(supabaseUrl, supabaseKey);
  
  // Register default alert handlers
  monitor.onAlert('critical_threat', (alert) => {
    console.error(`🚨 CRITICAL SECURITY THREAT:`, alert);
  });
  
  monitor.onAlert('anomaly_detected', (alert) => {
    console.warn(`⚠️ SECURITY ANOMALY:`, alert);
  });
  
  return monitor;
}

export default SecurityMonitoringService;