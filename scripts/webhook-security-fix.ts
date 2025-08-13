#!/usr/bin/env deno run --allow-net --allow-env

/**
 * Webhook Security Verification and Enhancement System
 * 
 * This script provides:
 * 1. Critical webhook security fixes
 * 2. IP whitelist validation
 * 3. Enhanced signature verification
 * 4. Webhook health monitoring
 * 5. Automatic retry mechanisms
 * 
 * Usage: deno run --allow-net --allow-env webhook-security-fix.ts
 */

import { createClient } from "https://esm.sh/@supabase/supabase-js@2.45.0";

const SUPABASE_URL = Deno.env.get("SUPABASE_URL");
const SUPABASE_SERVICE_ROLE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");

if (!SUPABASE_URL || !SUPABASE_SERVICE_ROLE_KEY) {
  console.error("❌ Missing required environment variables");
  Deno.exit(1);
}

const supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY);

/**
 * Enhanced webhook security implementation
 */
export const STRIPE_WEBHOOK_IPS = [
  "54.187.174.169",
  "54.187.205.235", 
  "54.187.216.72",
  "54.241.31.99",
  "54.241.31.102",
  "54.241.34.107"
];

export interface WebhookSecurityConfig {
  enableIPWhitelist: boolean;
  enableSignatureVerification: boolean;
  enableReplayProtection: boolean;
  enableRateLimit: boolean;
  maxRetries: number;
  retryDelayMs: number;
}

export const DEFAULT_SECURITY_CONFIG: WebhookSecurityConfig = {
  enableIPWhitelist: true,
  enableSignatureVerification: true,
  enableReplayProtection: true,
  enableRateLimit: true,
  maxRetries: 3,
  retryDelayMs: 1000
};

/**
 * Get the real client IP from request headers
 */
export function getClientIP(req: Request): string {
  // Check common headers in order of preference
  const headers = [
    'cf-connecting-ip',      // Cloudflare
    'x-real-ip',             // Nginx
    'x-forwarded-for',       // Load balancers
    'x-client-ip',           // Apache
    'x-cluster-client-ip',   // Cluster
    'forwarded-for',         // RFC 7239
    'forwarded'              // RFC 7239
  ];

  for (const header of headers) {
    const value = req.headers.get(header);
    if (value) {
      // x-forwarded-for can contain multiple IPs, take the first one
      const ip = value.split(',')[0].trim();
      if (isValidIP(ip)) {
        return ip;
      }
    }
  }

  // Fallback to connection info (may not be available in all environments)
  const connInfo = (req as any).connInfo?.remoteAddr;
  if (connInfo && connInfo.hostname) {
    return connInfo.hostname;
  }

  return '127.0.0.1'; // Default fallback
}

/**
 * Validate IP address format
 */
export function isValidIP(ip: string): boolean {
  const ipv4Regex = /^(\d{1,3}\.){3}\d{1,3}$/;
  const ipv6Regex = /^([0-9a-fA-F]{1,4}:){7}[0-9a-fA-F]{1,4}$/;
  
  if (ipv4Regex.test(ip)) {
    const parts = ip.split('.');
    return parts.every(part => {
      const num = parseInt(part, 10);
      return num >= 0 && num <= 255;
    });
  }
  
  return ipv6Regex.test(ip);
}

/**
 * Check if IP is in Stripe's webhook IP whitelist
 */
export function isStripeWebhookIP(clientIP: string): boolean {
  return STRIPE_WEBHOOK_IPS.includes(clientIP);
}

/**
 * Enhanced webhook signature verification with timing attack protection
 */
export async function verifyWebhookSignature(
  payload: string,
  signature: string,
  secret: string,
  timestamp?: string
): Promise<{ isValid: boolean; error?: string }> {
  if (!signature || !secret) {
    return { isValid: false, error: "Missing signature or secret" };
  }

  // Extract timestamp and signature from Stripe header format
  const elements = signature.split(',');
  let receivedTimestamp: string | undefined;
  let receivedSignature: string | undefined;

  for (const element of elements) {
    const [key, value] = element.split('=');
    if (key === 't') {
      receivedTimestamp = value;
    } else if (key === 'v1') {
      receivedSignature = value;
    }
  }

  if (!receivedSignature) {
    return { isValid: false, error: "Invalid signature format" };
  }

  // Verify timestamp (prevent replay attacks)
  if (receivedTimestamp) {
    const timestampMs = parseInt(receivedTimestamp) * 1000;
    const currentMs = Date.now();
    
    if (isNaN(timestampMs)) {
      return { isValid: false, error: "Invalid timestamp format" };
    }
    
    const tolerance = 5 * 60 * 1000; // 5 minutes
    if (Math.abs(currentMs - timestampMs) > tolerance) {
      return { isValid: false, error: "Webhook timestamp too old or too far in future" };
    }
  }

  try {
    // Create the signed payload
    const signedPayload = `${receivedTimestamp}.${payload}`;
    
    // Calculate expected signature using Web Crypto API
    const encoder = new TextEncoder();
    const key = await crypto.subtle.importKey(
      "raw",
      encoder.encode(secret),
      { name: "HMAC", hash: "SHA-256" },
      false,
      ["sign"]
    );
    
    const signatureBytes = await crypto.subtle.sign(
      "HMAC",
      key,
      encoder.encode(signedPayload)
    );
    
    const expectedSignature = Array.from(new Uint8Array(signatureBytes))
      .map(b => b.toString(16).padStart(2, '0'))
      .join('');
    
    // Timing-safe comparison
    const receivedSig = receivedSignature.toLowerCase();
    const expectedSig = expectedSignature.toLowerCase();
    
    if (receivedSig.length !== expectedSig.length) {
      return { isValid: false, error: "Invalid signature length" };
    }
    
    let isValid = true;
    for (let i = 0; i < receivedSig.length; i++) {
      if (receivedSig[i] !== expectedSig[i]) {
        isValid = false;
      }
    }
    
    return { isValid };
    
  } catch (error) {
    return { isValid: false, error: "Signature verification failed" };
  }
}

/**
 * Enhanced webhook processing with retry logic
 */
export class WebhookProcessor {
  private config: WebhookSecurityConfig;
  private supabase: any;

  constructor(supabase: any, config: WebhookSecurityConfig = DEFAULT_SECURITY_CONFIG) {
    this.config = config;
    this.supabase = supabase;
  }

  async processWebhook(
    req: Request,
    webhookSecret: string,
    handler: (payload: any) => Promise<any>
  ): Promise<Response> {
    const startTime = Date.now();
    let webhookId: string | undefined;
    let clientIP: string | undefined;

    try {
      // Get client IP
      clientIP = getClientIP(req);
      
      // IP whitelist validation
      if (this.config.enableIPWhitelist && !isStripeWebhookIP(clientIP)) {
        console.warn(`Webhook from unauthorized IP: ${clientIP}`);
        
        await this.logWebhookAttempt({
          status: 'rejected_ip',
          ip_address: clientIP,
          error_message: 'Unauthorized IP address'
        });
        
        return new Response("Unauthorized", { status: 403 });
      }

      // Read and validate payload
      const payload = await req.text();
      const signature = req.headers.get("stripe-signature");
      
      if (!signature) {
        throw new Error("Missing webhook signature");
      }

      // Verify signature
      if (this.config.enableSignatureVerification) {
        const verification = await verifyWebhookSignature(payload, signature, webhookSecret);
        if (!verification.isValid) {
          throw new Error(`Signature verification failed: ${verification.error}`);
        }
      }

      // Parse webhook event
      let event: any;
      try {
        event = JSON.parse(payload);
        webhookId = event.id;
      } catch {
        throw new Error("Invalid JSON payload");
      }

      // Replay protection
      if (this.config.enableReplayProtection && webhookId) {
        const isDuplicate = await this.checkDuplicateWebhook(webhookId);
        if (isDuplicate) {
          console.warn(`Duplicate webhook detected: ${webhookId}`);
          return new Response("Duplicate webhook", { status: 409 });
        }
      }

      // Log webhook receipt
      await this.logWebhookAttempt({
        webhook_id: webhookId,
        event_type: event.type,
        status: 'processing',
        ip_address: clientIP,
        payload: event
      });

      // Process webhook with retry logic
      const result = await this.processWithRetry(handler, event);
      
      // Log success
      await this.updateWebhookLog(webhookId, {
        status: 'completed',
        processed_at: new Date().toISOString(),
        processing_time_ms: Date.now() - startTime
      });

      return new Response(JSON.stringify({ received: true }), {
        status: 200,
        headers: { "Content-Type": "application/json" }
      });

    } catch (error) {
      console.error("Webhook processing error:", error);
      
      // Log failure
      if (webhookId) {
        await this.updateWebhookLog(webhookId, {
          status: 'failed',
          error_message: error.message,
          processed_at: new Date().toISOString(),
          processing_time_ms: Date.now() - startTime
        });
      }

      // Return appropriate error response
      const statusCode = error.message?.includes("signature") ? 401 :
                        error.message?.includes("Unauthorized") ? 403 :
                        error.message?.includes("Duplicate") ? 409 : 500;

      return new Response(JSON.stringify({ 
        error: this.sanitizeError(error.message) 
      }), {
        status: statusCode,
        headers: { "Content-Type": "application/json" }
      });
    }
  }

  private async processWithRetry(handler: Function, event: any): Promise<any> {
    let lastError: Error | undefined;

    for (let attempt = 1; attempt <= this.config.maxRetries; attempt++) {
      try {
        return await handler(event);
      } catch (error) {
        lastError = error;
        console.error(`Webhook processing attempt ${attempt} failed:`, error);
        
        if (attempt < this.config.maxRetries) {
          // Exponential backoff
          const delay = this.config.retryDelayMs * Math.pow(2, attempt - 1);
          await new Promise(resolve => setTimeout(resolve, delay));
        }
      }
    }

    throw lastError || new Error("All retry attempts failed");
  }

  private async checkDuplicateWebhook(webhookId: string): Promise<boolean> {
    const { data } = await this.supabase
      .from("webhook_logs")
      .select("id")
      .eq("webhook_id", webhookId)
      .single();

    return !!data;
  }

  private async logWebhookAttempt(logData: any): Promise<void> {
    try {
      await this.supabase
        .from("webhook_logs")
        .insert({
          webhook_id: logData.webhook_id || crypto.randomUUID(),
          source: "stripe",
          event_type: logData.event_type || "unknown",
          payload: logData.payload || {},
          status: logData.status,
          error_message: logData.error_message,
          ip_address: logData.ip_address,
          created_at: new Date().toISOString()
        });
    } catch (error) {
      console.error("Failed to log webhook attempt:", error);
    }
  }

  private async updateWebhookLog(webhookId: string, updates: any): Promise<void> {
    try {
      await this.supabase
        .from("webhook_logs")
        .update(updates)
        .eq("webhook_id", webhookId);
    } catch (error) {
      console.error("Failed to update webhook log:", error);
    }
  }

  private sanitizeError(errorMessage: string): string {
    // Remove sensitive information from error messages
    if (errorMessage?.includes('signature')) {
      return 'Invalid webhook signature';
    } else if (errorMessage?.includes('IP')) {
      return 'Unauthorized request';
    } else if (errorMessage?.includes('Duplicate')) {
      return 'Duplicate webhook';
    }
    
    return 'Webhook processing failed';
  }
}

/**
 * Webhook health monitoring
 */
export class WebhookMonitor {
  private supabase: any;

  constructor(supabase: any) {
    this.supabase = supabase;
  }

  async getWebhookHealth(timeframe: string = '1 hour'): Promise<any> {
    const { data: logs } = await this.supabase
      .from("webhook_logs")
      .select("*")
      .gte("created_at", new Date(Date.now() - this.parseTimeframe(timeframe)).toISOString())
      .order("created_at", { ascending: false });

    if (!logs || logs.length === 0) {
      return {
        status: "no_data",
        message: "No webhook activity in the specified timeframe"
      };
    }

    const total = logs.length;
    const completed = logs.filter(log => log.status === 'completed').length;
    const failed = logs.filter(log => log.status === 'failed').length;
    const processing = logs.filter(log => log.status === 'processing').length;

    const successRate = (completed / total) * 100;
    const avgProcessingTime = logs
      .filter(log => log.processing_time_ms)
      .reduce((sum, log) => sum + log.processing_time_ms, 0) / 
      logs.filter(log => log.processing_time_ms).length;

    return {
      status: successRate >= 95 ? "healthy" : successRate >= 80 ? "warning" : "critical",
      metrics: {
        total_webhooks: total,
        completed: completed,
        failed: failed,
        processing: processing,
        success_rate: successRate.toFixed(2) + "%",
        avg_processing_time: avgProcessingTime ? `${avgProcessingTime.toFixed(0)}ms` : "N/A"
      },
      recommendations: this.generateRecommendations(successRate, avgProcessingTime)
    };
  }

  async getFailedWebhooks(limit: number = 10): Promise<any[]> {
    const { data: logs } = await this.supabase
      .from("webhook_logs")
      .select("*")
      .eq("status", "failed")
      .order("created_at", { ascending: false })
      .limit(limit);

    return logs || [];
  }

  private parseTimeframe(timeframe: string): number {
    const match = timeframe.match(/(\d+)\s*(hour|day|minute)s?/);
    if (!match) return 60 * 60 * 1000; // Default 1 hour

    const value = parseInt(match[1]);
    const unit = match[2];

    switch (unit) {
      case 'minute': return value * 60 * 1000;
      case 'hour': return value * 60 * 60 * 1000;
      case 'day': return value * 24 * 60 * 60 * 1000;
      default: return 60 * 60 * 1000;
    }
  }

  private generateRecommendations(successRate: number, avgProcessingTime: number): string[] {
    const recommendations = [];

    if (successRate < 95) {
      recommendations.push("Investigate failed webhooks and implement fixes");
    }

    if (avgProcessingTime > 5000) {
      recommendations.push("Optimize webhook processing for better performance");
    }

    if (successRate < 80) {
      recommendations.push("Consider implementing alerting for webhook failures");
    }

    return recommendations;
  }
}

// Utility functions for webhook security testing
export async function testWebhookSecurity(): Promise<void> {
  console.log("🔒 Testing Webhook Security Implementation\n");

  // Test IP validation
  console.log("1. Testing IP Validation:");
  const testIPs = [
    "54.187.174.169", // Valid Stripe IP
    "192.168.1.1",    // Invalid IP
    "invalid-ip",     // Invalid format
  ];

  testIPs.forEach(ip => {
    const isValid = isValidIP(ip);
    const isStripe = isStripeWebhookIP(ip);
    console.log(`   ${ip}: Valid=${isValid}, Stripe=${isStripe}`);
  });

  // Test signature verification
  console.log("\n2. Testing Signature Verification:");
  const testPayload = '{"test": "data"}';
  const testSecret = "whsec_test_secret";
  const testSignature = "t=1234567890,v1=invalid_signature";

  const verification = await verifyWebhookSignature(testPayload, testSignature, testSecret);
  console.log(`   Signature verification: ${verification.isValid ? "✅" : "❌"} (${verification.error || "OK"})`);

  // Test webhook monitoring
  console.log("\n3. Testing Webhook Monitoring:");
  const monitor = new WebhookMonitor(supabase);
  const health = await monitor.getWebhookHealth("24 hours");
  console.log(`   Webhook Health: ${health.status}`);
  console.log(`   Metrics:`, health.metrics);

  console.log("\n✅ Webhook security testing completed");
}

// Main execution
if (import.meta.main) {
  await testWebhookSecurity();
}