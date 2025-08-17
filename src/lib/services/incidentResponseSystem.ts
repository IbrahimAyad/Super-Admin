/**
 * Incident Response System for KCT Menswear
 * Automated error detection, logging, escalation, and response coordination
 */

import { getSupabaseClient } from '@/lib/supabase/client';
import { logger } from './monitoring';

// Incident types and severity levels
export enum IncidentSeverity {
  CRITICAL = 'critical',
  HIGH = 'high', 
  MEDIUM = 'medium',
  LOW = 'low'
}

export enum IncidentStatus {
  OPEN = 'open',
  INVESTIGATING = 'investigating',
  RESOLVED = 'resolved',
  CLOSED = 'closed'
}

export enum IncidentCategory {
  PAYMENT_FAILURE = 'payment_failure',
  DATABASE_ERROR = 'database_error',
  API_ERROR = 'api_error',
  SECURITY_BREACH = 'security_breach',
  PERFORMANCE_DEGRADATION = 'performance_degradation',
  INVENTORY_ISSUE = 'inventory_issue',
  USER_EXPERIENCE = 'user_experience',
  EXTERNAL_SERVICE = 'external_service'
}

// Incident interfaces
export interface Incident {
  id: string;
  title: string;
  description: string;
  category: IncidentCategory;
  severity: IncidentSeverity;
  status: IncidentStatus;
  
  // Occurrence details
  first_occurred_at: string;
  last_occurred_at: string;
  occurrence_count: number;
  
  // Technical details
  error_message?: string;
  stack_trace?: string;
  affected_endpoints?: string[];
  affected_users?: string[];
  error_code?: string;
  
  // Business impact
  estimated_revenue_impact?: number;
  affected_orders?: number;
  customer_complaints?: number;
  
  // Response tracking
  detected_at: string;
  acknowledged_at?: string;
  resolved_at?: string;
  assigned_to?: string;
  resolution_notes?: string;
  
  // Escalation
  escalation_level: number;
  escalated_at?: string;
  escalated_to?: string[];
  
  // Metadata
  metadata: Record<string, any>;
  related_alerts?: string[];
  related_incidents?: string[];
}

export interface IncidentRule {
  id: string;
  name: string;
  category: IncidentCategory;
  severity: IncidentSeverity;
  
  // Detection criteria
  error_pattern?: string;
  metric_threshold?: {
    metric_name: string;
    operator: 'gt' | 'lt' | 'eq';
    value: number;
    duration_minutes: number;
  };
  
  // Response actions
  auto_create_incident: boolean;
  notify_channels: string[];
  assign_to_team?: string;
  escalation_rules: EscalationRule[];
  
  // Conditions
  conditions: {
    time_window_minutes: number;
    minimum_occurrences: number;
    ignore_resolved_duplicates: boolean;
  };
  
  enabled: boolean;
  created_by: string;
  last_modified: string;
}

export interface EscalationRule {
  level: number;
  delay_minutes: number;
  notify_channels: string[];
  assign_to: string[];
  actions: string[];
}

export interface NotificationChannel {
  id: string;
  name: string;
  type: 'slack' | 'email' | 'sms' | 'webhook';
  config: Record<string, any>;
  enabled: boolean;
}

export interface IncidentMetrics {
  total_incidents: number;
  open_incidents: number;
  critical_incidents: number;
  mean_time_to_detection: number; // minutes
  mean_time_to_resolution: number; // minutes
  incidents_by_category: Record<IncidentCategory, number>;
  incidents_by_severity: Record<IncidentSeverity, number>;
  resolution_rate_24h: number;
  escalation_rate: number;
}

export class IncidentResponseSystem {
  private static instance: IncidentResponseSystem;
  private supabase = getSupabaseClient();
  private notificationChannels: Map<string, NotificationChannel> = new Map();
  private activeRules: Map<string, IncidentRule> = new Map();
  private realtimeSubscriptions: any[] = [];
  private isMonitoringActive: boolean = false;
  
  private constructor() {
    this.initializeSystem();
  }

  /**
   * Get singleton instance
   */
  public static getInstance(): IncidentResponseSystem {
    if (!IncidentResponseSystem.instance) {
      IncidentResponseSystem.instance = new IncidentResponseSystem();
    }
    return IncidentResponseSystem.instance;
  }

  /**
   * Initialize the incident response system
   */
  private async initializeSystem(): Promise<void> {
    try {
      // Load notification channels
      await this.loadNotificationChannels();
      
      // Load incident rules
      await this.loadIncidentRules();
      
      // Set up real-time monitoring
      this.setupRealTimeMonitoring();
      
      logger.info('Incident Response System initialized');
    } catch (error) {
      logger.error('Failed to initialize Incident Response System:', error);
    }
  }

  /**
   * Load notification channels from database
   */
  private async loadNotificationChannels(): Promise<void> {
    try {
      const { data: channels, error } = await this.supabase
        .from('notification_channels')
        .select('*')
        .eq('enabled', true);

      if (error) throw error;

      this.notificationChannels.clear();
      (channels || []).forEach(channel => {
        this.notificationChannels.set(channel.id, channel);
      });

      logger.info(`Loaded ${channels?.length || 0} notification channels`);
    } catch (error) {
      logger.error('Failed to load notification channels:', error);
    }
  }

  /**
   * Load incident detection rules
   */
  private async loadIncidentRules(): Promise<void> {
    try {
      const { data: rules, error } = await this.supabase
        .from('incident_rules')
        .select('*')
        .eq('enabled', true);

      if (error) throw error;

      this.activeRules.clear();
      (rules || []).forEach(rule => {
        this.activeRules.set(rule.id, rule);
      });

      logger.info(`Loaded ${rules?.length || 0} incident rules`);
    } catch (error) {
      logger.error('Failed to load incident rules:', error);
    }
  }

  /**
   * Set up real-time monitoring for automatic incident detection
   */
  private setupRealTimeMonitoring(): void {
    // Prevent duplicate subscriptions
    if (this.isMonitoringActive || this.realtimeSubscriptions.length > 0) {
      console.log('🚀 IncidentResponseSystem: Already monitoring realtime events');
      return;
    }

    console.log('🚀 IncidentResponseSystem: Setting up realtime monitoring');
    
    // Monitor performance logs for errors
    const performanceChannel = this.supabase
      .channel('incident_monitoring_performance')
      .on('postgres_changes', 
        { 
          event: 'INSERT', 
          schema: 'public', 
          table: 'performance_logs',
          filter: 'status_code=gte.400'
        }, 
        async (payload: any) => {
          console.log('🚀 IncidentResponseSystem: Performance error detected:', payload.new);
          await this.processErrorLog(payload.new);
        }
      )
      .subscribe((status) => {
        console.log('🚀 IncidentResponseSystem: Performance monitoring status:', status);
      });

    // Monitor monitoring alerts for escalation
    const alertsChannel = this.supabase
      .channel('incident_monitoring_alerts')
      .on('postgres_changes',
        {
          event: 'INSERT',
          schema: 'public', 
          table: 'monitoring_alerts',
          filter: 'severity=eq.critical'
        },
        async (payload: any) => {
          console.log('🚀 IncidentResponseSystem: Critical alert detected:', payload.new);
          await this.processCriticalAlert(payload.new);
        }
      )
      .subscribe((status) => {
        console.log('🚀 IncidentResponseSystem: Alerts monitoring status:', status);
      });

    // Monitor payment failures
    const paymentsChannel = this.supabase
      .channel('incident_monitoring_payments')
      .on('postgres_changes',
        {
          event: 'INSERT',
          schema: 'public',
          table: 'payment_monitoring',
          filter: 'status=eq.failed'
        },
        async (payload: any) => {
          console.log('🚀 IncidentResponseSystem: Payment failure detected:', payload.new);
          await this.processPaymentFailure(payload.new);
        }
      )
      .subscribe((status) => {
        console.log('🚀 IncidentResponseSystem: Payments monitoring status:', status);
      });

    // Store subscription references
    this.realtimeSubscriptions.push(performanceChannel, alertsChannel, paymentsChannel);
    this.isMonitoringActive = true;

    logger.info('🚀 IncidentResponseSystem: Real-time incident monitoring channels established');
  }

  /**
   * Process error log entry for potential incident creation
   */
  private async processErrorLog(errorLog: any): Promise<void> {
    try {
      // Check if this error matches any incident rules
      for (const rule of this.activeRules.values()) {
        if (this.matchesRule(errorLog, rule)) {
          await this.createOrUpdateIncident(errorLog, rule);
        }
      }
    } catch (error) {
      logger.error('Failed to process error log:', error);
    }
  }

  /**
   * Process critical alert for incident escalation
   */
  private async processCriticalAlert(alert: any): Promise<void> {
    try {
      // Auto-create incident for critical alerts
      const incident: Partial<Incident> = {
        title: `Critical Alert: ${alert.title}`,
        description: alert.message,
        category: this.mapAlertTypeToCategory(alert.alert_type),
        severity: IncidentSeverity.CRITICAL,
        status: IncidentStatus.OPEN,
        first_occurred_at: alert.triggered_at,
        last_occurred_at: alert.triggered_at,
        occurrence_count: 1,
        error_message: alert.message,
        escalation_level: 1,
        metadata: {
          alert_id: alert.id,
          alert_type: alert.alert_type,
          metric_name: alert.metric_name,
          current_value: alert.current_value,
          threshold_value: alert.threshold_value
        }
      };

      await this.createIncident(incident);
    } catch (error) {
      logger.error('Failed to process critical alert:', error);
    }
  }

  /**
   * Process payment failure for incident creation
   */
  private async processPaymentFailure(paymentData: any): Promise<void> {
    try {
      // Check for payment failure patterns
      const recentFailures = await this.getRecentPaymentFailures(15); // Last 15 minutes
      
      if (recentFailures >= 5) { // Threshold for incident creation
        const incident: Partial<Incident> = {
          title: 'Multiple Payment Failures Detected',
          description: `${recentFailures} payment failures detected in the last 15 minutes`,
          category: IncidentCategory.PAYMENT_FAILURE,
          severity: recentFailures >= 10 ? IncidentSeverity.CRITICAL : IncidentSeverity.HIGH,
          status: IncidentStatus.OPEN,
          first_occurred_at: new Date().toISOString(),
          last_occurred_at: new Date().toISOString(),
          occurrence_count: recentFailures,
          error_message: paymentData.failure_reason,
          escalation_level: 1,
          metadata: {
            payment_method: paymentData.payment_method,
            failure_code: paymentData.failure_code,
            recent_failures: recentFailures
          }
        };

        await this.createIncident(incident);
      }
    } catch (error) {
      logger.error('Failed to process payment failure:', error);
    }
  }

  /**
   * Check if error log matches incident rule
   */
  private matchesRule(errorLog: any, rule: IncidentRule): boolean {
    // Check error pattern matching
    if (rule.error_pattern) {
      const pattern = new RegExp(rule.error_pattern, 'i');
      if (!pattern.test(errorLog.error_message || '')) {
        return false;
      }
    }

    // Check status code for API errors
    if (rule.category === IncidentCategory.API_ERROR) {
      return errorLog.status_code >= 400;
    }

    // Check response time for performance issues
    if (rule.category === IncidentCategory.PERFORMANCE_DEGRADATION) {
      return errorLog.response_time_ms > 5000; // 5 second threshold
    }

    return true;
  }

  /**
   * Create new incident or update existing one
   */
  private async createOrUpdateIncident(errorLog: any, rule: IncidentRule): Promise<void> {
    try {
      // Check for existing similar incident in last hour
      const existingIncident = await this.findSimilarIncident(errorLog, rule);

      if (existingIncident) {
        // Update existing incident
        await this.updateIncidentOccurrence(existingIncident.id, errorLog);
      } else if (rule.auto_create_incident) {
        // Create new incident
        const incident: Partial<Incident> = {
          title: this.generateIncidentTitle(errorLog, rule),
          description: this.generateIncidentDescription(errorLog, rule),
          category: rule.category,
          severity: rule.severity,
          status: IncidentStatus.OPEN,
          first_occurred_at: errorLog.timestamp,
          last_occurred_at: errorLog.timestamp,
          occurrence_count: 1,
          error_message: errorLog.error_message,
          stack_trace: errorLog.stack_trace,
          affected_endpoints: errorLog.endpoint ? [errorLog.endpoint] : [],
          escalation_level: 1,
          metadata: {
            rule_id: rule.id,
            rule_name: rule.name,
            user_id: errorLog.user_id,
            session_id: errorLog.session_id,
            ip_address: errorLog.ip_address
          }
        };

        await this.createIncident(incident);
      }
    } catch (error) {
      logger.error('Failed to create or update incident:', error);
    }
  }

  /**
   * Create new incident
   */
  async createIncident(incident: Partial<Incident>): Promise<string> {
    try {
      const incidentId = crypto.randomUUID();
      const fullIncident: Incident = {
        id: incidentId,
        detected_at: new Date().toISOString(),
        escalation_level: 1,
        metadata: {},
        ...incident
      } as Incident;

      // Store incident in database
      const { error } = await this.supabase
        .from('incidents')
        .insert(fullIncident);

      if (error) throw error;

      // Send notifications
      await this.sendIncidentNotifications(fullIncident);

      // Log incident creation
      logger.info('Incident created:', { 
        id: incidentId, 
        title: fullIncident.title, 
        severity: fullIncident.severity 
      });

      return incidentId;
    } catch (error) {
      logger.error('Failed to create incident:', error);
      throw error;
    }
  }

  /**
   * Update incident with new occurrence
   */
  private async updateIncidentOccurrence(incidentId: string, errorLog: any): Promise<void> {
    try {
      const { error } = await this.supabase
        .from('incidents')
        .update({
          last_occurred_at: errorLog.timestamp,
          occurrence_count: this.supabase.sql`occurrence_count + 1`
        })
        .eq('id', incidentId);

      if (error) throw error;

      logger.info('Updated incident occurrence:', { incidentId });
    } catch (error) {
      logger.error('Failed to update incident occurrence:', error);
    }
  }

  /**
   * Send incident notifications
   */
  private async sendIncidentNotifications(incident: Incident): Promise<void> {
    try {
      // Get notification rules for incident category and severity
      const { data: notificationRules } = await this.supabase
        .from('incident_notification_rules')
        .select('notification_channels')
        .eq('category', incident.category)
        .eq('severity', incident.severity)
        .eq('enabled', true);

      if (!notificationRules || notificationRules.length === 0) return;

      const channels = notificationRules.flatMap(rule => rule.notification_channels);

      // Send to each channel
      await Promise.all(
        channels.map(channelId => this.sendNotificationToChannel(channelId, incident))
      );
    } catch (error) {
      logger.error('Failed to send incident notifications:', error);
    }
  }

  /**
   * Send notification to specific channel
   */
  private async sendNotificationToChannel(channelId: string, incident: Incident): Promise<void> {
    const channel = this.notificationChannels.get(channelId);
    if (!channel) return;

    try {
      switch (channel.type) {
        case 'slack':
          await this.sendSlackNotification(channel, incident);
          break;
        case 'email':
          await this.sendEmailNotification(channel, incident);
          break;
        case 'webhook':
          await this.sendWebhookNotification(channel, incident);
          break;
        default:
          logger.warn('Unknown notification channel type:', channel.type);
      }
    } catch (error) {
      logger.error(`Failed to send notification to ${channel.type} channel:`, error);
    }
  }

  /**
   * Send Slack notification
   */
  private async sendSlackNotification(channel: NotificationChannel, incident: Incident): Promise<void> {
    const color = {
      [IncidentSeverity.CRITICAL]: '#FF0000',
      [IncidentSeverity.HIGH]: '#FF8C00',
      [IncidentSeverity.MEDIUM]: '#FFD700',
      [IncidentSeverity.LOW]: '#32CD32'
    }[incident.severity];

    const slackPayload = {
      text: `🚨 New Incident: ${incident.title}`,
      attachments: [
        {
          color: color,
          title: incident.title,
          text: incident.description,
          fields: [
            {
              title: 'Severity',
              value: incident.severity.toUpperCase(),
              short: true
            },
            {
              title: 'Category',
              value: incident.category.replace('_', ' '),
              short: true
            },
            {
              title: 'Incident ID',
              value: incident.id,
              short: true
            },
            {
              title: 'Detected At',
              value: new Date(incident.detected_at).toLocaleString(),
              short: true
            }
          ],
          actions: [
            {
              type: 'button',
              text: 'View Details',
              url: `${import.meta.env.VITE_FRONTEND_URL}/admin/incidents/${incident.id}`
            },
            {
              type: 'button',
              text: 'Acknowledge',
              name: 'acknowledge',
              value: incident.id
            }
          ]
        }
      ]
    };

    await fetch(channel.config.webhook_url, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(slackPayload)
    });
  }

  /**
   * Send email notification
   */
  private async sendEmailNotification(channel: NotificationChannel, incident: Incident): Promise<void> {
    const emailData = {
      to: channel.config.email_addresses,
      subject: `[${incident.severity.toUpperCase()}] ${incident.title} - KCT Menswear`,
      html: `
        <h2>Incident Alert</h2>
        <p><strong>Title:</strong> ${incident.title}</p>
        <p><strong>Severity:</strong> ${incident.severity.toUpperCase()}</p>
        <p><strong>Category:</strong> ${incident.category.replace('_', ' ')}</p>
        <p><strong>Description:</strong> ${incident.description}</p>
        <p><strong>Detected At:</strong> ${new Date(incident.detected_at).toLocaleString()}</p>
        
        ${incident.error_message ? `<p><strong>Error:</strong> ${incident.error_message}</p>` : ''}
        
        <hr>
        <p>Incident ID: ${incident.id}</p>
        <p><a href="${import.meta.env.VITE_FRONTEND_URL}/admin/incidents/${incident.id}">View Incident Details</a></p>
      `
    };

    await fetch(`${import.meta.env.VITE_SUPABASE_URL}/functions/v1/send-email`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Authorization': `Bearer ${import.meta.env.VITE_SUPABASE_SERVICE_ROLE_KEY}`
      },
      body: JSON.stringify(emailData)
    });
  }

  /**
   * Send webhook notification
   */
  private async sendWebhookNotification(channel: NotificationChannel, incident: Incident): Promise<void> {
    await fetch(channel.config.webhook_url, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Authorization': channel.config.auth_header || ''
      },
      body: JSON.stringify({
        event: 'incident.created',
        incident: incident
      })
    });
  }

  /**
   * Escalate incident to higher level
   */
  async escalateIncident(incidentId: string): Promise<void> {
    try {
      const { data: incident, error: fetchError } = await this.supabase
        .from('incidents')
        .select('*')
        .eq('id', incidentId)
        .single();

      if (fetchError) throw fetchError;
      if (!incident) throw new Error('Incident not found');

      const newEscalationLevel = incident.escalation_level + 1;

      // Update incident
      const { error: updateError } = await this.supabase
        .from('incidents')
        .update({
          escalation_level: newEscalationLevel,
          escalated_at: new Date().toISOString()
        })
        .eq('id', incidentId);

      if (updateError) throw updateError;

      // Send escalation notifications
      await this.sendEscalationNotifications(incident, newEscalationLevel);

      logger.info('Incident escalated:', { incidentId, level: newEscalationLevel });
    } catch (error) {
      logger.error('Failed to escalate incident:', error);
      throw error;
    }
  }

  /**
   * Send escalation notifications
   */
  private async sendEscalationNotifications(incident: any, escalationLevel: number): Promise<void> {
    // Implementation for escalation-specific notifications
    // This would typically notify senior staff, on-call engineers, etc.
  }

  /**
   * Acknowledge incident
   */
  async acknowledgeIncident(incidentId: string, userId: string): Promise<void> {
    try {
      const { error } = await this.supabase
        .from('incidents')
        .update({
          status: IncidentStatus.INVESTIGATING,
          acknowledged_at: new Date().toISOString(),
          assigned_to: userId
        })
        .eq('id', incidentId);

      if (error) throw error;

      logger.info('Incident acknowledged:', { incidentId, userId });
    } catch (error) {
      logger.error('Failed to acknowledge incident:', error);
      throw error;
    }
  }

  /**
   * Resolve incident
   */
  async resolveIncident(incidentId: string, userId: string, resolutionNotes: string): Promise<void> {
    try {
      const { error } = await this.supabase
        .from('incidents')
        .update({
          status: IncidentStatus.RESOLVED,
          resolved_at: new Date().toISOString(),
          resolved_by: userId,
          resolution_notes: resolutionNotes
        })
        .eq('id', incidentId);

      if (error) throw error;

      logger.info('Incident resolved:', { incidentId, userId });
    } catch (error) {
      logger.error('Failed to resolve incident:', error);
      throw error;
    }
  }

  /**
   * Get incident metrics
   */
  async getIncidentMetrics(days: number = 30): Promise<IncidentMetrics> {
    try {
      const startDate = new Date(Date.now() - days * 24 * 60 * 60 * 1000).toISOString();

      const { data: incidents, error } = await this.supabase
        .from('incidents')
        .select('*')
        .gte('detected_at', startDate);

      if (error) throw error;

      const metrics = this.calculateIncidentMetrics(incidents || []);
      return metrics;
    } catch (error) {
      logger.error('Failed to get incident metrics:', error);
      return {
        total_incidents: 0,
        open_incidents: 0,
        critical_incidents: 0,
        mean_time_to_detection: 0,
        mean_time_to_resolution: 0,
        incidents_by_category: {} as Record<IncidentCategory, number>,
        incidents_by_severity: {} as Record<IncidentSeverity, number>,
        resolution_rate_24h: 0,
        escalation_rate: 0
      };
    }
  }

  /**
   * Calculate incident metrics from incident data
   */
  private calculateIncidentMetrics(incidents: any[]): IncidentMetrics {
    const openIncidents = incidents.filter(i => i.status === IncidentStatus.OPEN).length;
    const criticalIncidents = incidents.filter(i => i.severity === IncidentSeverity.CRITICAL).length;
    const resolvedIncidents = incidents.filter(i => i.status === IncidentStatus.RESOLVED);
    
    // Calculate mean time to resolution
    const mttr = resolvedIncidents.length > 0 
      ? resolvedIncidents.reduce((sum, incident) => {
          const detectedAt = new Date(incident.detected_at).getTime();
          const resolvedAt = new Date(incident.resolved_at).getTime();
          return sum + (resolvedAt - detectedAt) / (1000 * 60); // minutes
        }, 0) / resolvedIncidents.length
      : 0;

    // Group by category and severity
    const byCategory = incidents.reduce((acc, incident) => {
      acc[incident.category] = (acc[incident.category] || 0) + 1;
      return acc;
    }, {} as Record<IncidentCategory, number>);

    const bySeverity = incidents.reduce((acc, incident) => {
      acc[incident.severity] = (acc[incident.severity] || 0) + 1;
      return acc;
    }, {} as Record<IncidentSeverity, number>);

    // Calculate resolution rate in last 24h
    const last24h = new Date(Date.now() - 24 * 60 * 60 * 1000).toISOString();
    const recentIncidents = incidents.filter(i => i.detected_at >= last24h);
    const recentResolved = recentIncidents.filter(i => i.status === IncidentStatus.RESOLVED);
    const resolutionRate24h = recentIncidents.length > 0 
      ? (recentResolved.length / recentIncidents.length) * 100 
      : 0;

    // Calculate escalation rate
    const escalatedIncidents = incidents.filter(i => i.escalation_level > 1).length;
    const escalationRate = incidents.length > 0 
      ? (escalatedIncidents / incidents.length) * 100 
      : 0;

    return {
      total_incidents: incidents.length,
      open_incidents: openIncidents,
      critical_incidents: criticalIncidents,
      mean_time_to_detection: 5, // This would come from alert detection times
      mean_time_to_resolution: mttr,
      incidents_by_category: byCategory,
      incidents_by_severity: bySeverity,
      resolution_rate_24h: resolutionRate24h,
      escalation_rate: escalationRate
    };
  }

  // Helper methods
  private async findSimilarIncident(errorLog: any, rule: IncidentRule): Promise<any> {
    const { data } = await this.supabase
      .from('incidents')
      .select('*')
      .eq('category', rule.category)
      .eq('status', IncidentStatus.OPEN)
      .gte('detected_at', new Date(Date.now() - 60 * 60 * 1000).toISOString()) // Last hour
      .limit(1);

    return data?.[0];
  }

  private async getRecentPaymentFailures(minutes: number): Promise<number> {
    const { data } = await this.supabase
      .from('payment_monitoring')
      .select('id')
      .eq('status', 'failed')
      .gte('timestamp', new Date(Date.now() - minutes * 60 * 1000).toISOString());

    return data?.length || 0;
  }

  private generateIncidentTitle(errorLog: any, rule: IncidentRule): string {
    return `${rule.name}: ${errorLog.endpoint || 'System Error'}`;
  }

  private generateIncidentDescription(errorLog: any, rule: IncidentRule): string {
    return `Incident detected by rule "${rule.name}". ${errorLog.error_message || 'System error occurred.'} Response time: ${errorLog.response_time_ms}ms`;
  }

  private mapAlertTypeToCategory(alertType: string): IncidentCategory {
    const mapping: Record<string, IncidentCategory> = {
      'system_error_rate': IncidentCategory.API_ERROR,
      'high_connection_usage': IncidentCategory.DATABASE_ERROR,
      'low_cache_hit_ratio': IncidentCategory.PERFORMANCE_DEGRADATION,
      'high_payment_failures': IncidentCategory.PAYMENT_FAILURE,
      'low_inventory': IncidentCategory.INVENTORY_ISSUE
    };

    return mapping[alertType] || IncidentCategory.API_ERROR;
  }

  /**
   * Cleanup all subscriptions and resources
   */
  public cleanup(): void {
    console.log('🚀 IncidentResponseSystem: Cleaning up subscriptions and resources');
    
    // Unsubscribe from all realtime channels
    if (this.realtimeSubscriptions.length > 0) {
      console.log(`🚀 IncidentResponseSystem: Unsubscribing from ${this.realtimeSubscriptions.length} channels`);
      this.realtimeSubscriptions.forEach(subscription => {
        if (subscription && typeof subscription.unsubscribe === 'function') {
          subscription.unsubscribe();
        }
      });
      this.realtimeSubscriptions = [];
      this.isMonitoringActive = false;
    }

    // Clear maps
    this.notificationChannels.clear();
    this.activeRules.clear();

    console.log('🚀 IncidentResponseSystem: Cleanup completed');
  }

  /**
   * Reset the singleton instance (for testing purposes)
   */
  public static resetInstance(): void {
    if (IncidentResponseSystem.instance) {
      IncidentResponseSystem.instance.cleanup();
      IncidentResponseSystem.instance = null as any;
    }
  }

  /**
   * Get monitoring status
   */
  public getMonitoringStatus(): { isActive: boolean; subscriptionCount: number } {
    return {
      isActive: this.isMonitoringActive,
      subscriptionCount: this.realtimeSubscriptions.length
    };
  }
}

// Export singleton instance
export const incidentResponseSystem = IncidentResponseSystem.getInstance();