/**
 * KCT Menswear Analytics Tracking System
 * Real-time event tracking for website and admin analytics
 */

import { getSupabaseClient } from '../supabase/client';

// Types for analytics events
export interface AnalyticsEvent {
  event_type: EventType;
  event_category: EventCategory;
  session_id: string;
  user_id?: string;
  customer_id?: string;
  properties?: Record<string, any>;
  page_url?: string;
  page_title?: string;
  referrer?: string;
  utm_source?: string;
  utm_medium?: string;
  utm_campaign?: string;
  user_agent?: string;
  ip_address?: string;
  device_type?: DeviceType;
  browser?: string;
  os?: string;
  country?: string;
  city?: string;
  product_id?: string;
  variant_id?: string;
  order_id?: string;
  revenue?: number;
  currency?: string;
  quantity?: number;
  admin_user_id?: string;
  admin_action_type?: string;
  affected_resource?: string;
  page_load_time?: number;
  time_on_page?: number;
}

export type EventType = 
  // Website events
  | 'page_view' | 'session_start' | 'session_end'
  // E-commerce events  
  | 'product_view' | 'add_to_cart' | 'remove_from_cart' | 'checkout_start' 
  | 'checkout_complete' | 'purchase_complete'
  // Admin events
  | 'admin_login' | 'admin_action' | 'admin_export' | 'admin_bulk_action'
  // Customer events
  | 'user_register' | 'user_login' | 'user_logout' | 'profile_update'
  // Search and navigation
  | 'search' | 'filter_applied' | 'category_view'
  // Marketing
  | 'email_open' | 'email_click' | 'campaign_view';

export type EventCategory = 'website' | 'ecommerce' | 'admin' | 'customer' | 'marketing' | 'system';

export type DeviceType = 'desktop' | 'mobile' | 'tablet';

// Session management
class SessionManager {
  private static instance: SessionManager;
  private sessionId: string | null = null;
  private sessionStartTime: number | null = null;
  private lastActivityTime: number = Date.now();
  private pageStartTime: number = Date.now();
  private sessionTimeout: number = 30 * 60 * 1000; // 30 minutes

  static getInstance(): SessionManager {
    if (!SessionManager.instance) {
      SessionManager.instance = new SessionManager();
    }
    return SessionManager.instance;
  }

  getSessionId(): string {
    if (!this.sessionId || this.isSessionExpired()) {
      this.startNewSession();
    }
    this.updateLastActivity();
    return this.sessionId!;
  }

  private startNewSession(): void {
    this.sessionId = this.generateUUID();
    this.sessionStartTime = Date.now();
    this.lastActivityTime = Date.now();
    
    // Track session start
    AnalyticsTracker.track({
      event_type: 'session_start',
      event_category: 'website',
      session_id: this.sessionId,
      properties: {
        session_start_time: new Date().toISOString()
      }
    });
  }

  private isSessionExpired(): boolean {
    if (!this.lastActivityTime) return true;
    return (Date.now() - this.lastActivityTime) > this.sessionTimeout;
  }

  private updateLastActivity(): void {
    this.lastActivityTime = Date.now();
  }

  endSession(): void {
    if (this.sessionId && this.sessionStartTime) {
      const sessionDuration = Date.now() - this.sessionStartTime;
      
      AnalyticsTracker.track({
        event_type: 'session_end',
        event_category: 'website', 
        session_id: this.sessionId,
        properties: {
          session_duration: sessionDuration,
          session_end_time: new Date().toISOString()
        }
      });
    }
  }

  getTimeOnPage(): number {
    return Date.now() - this.pageStartTime;
  }

  resetPageTimer(): void {
    this.pageStartTime = Date.now();
  }

  private generateUUID(): string {
    return 'xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx'.replace(/[xy]/g, function(c) {
      const r = Math.random() * 16 | 0;
      const v = c == 'x' ? r : (r & 0x3 | 0x8);
      return v.toString(16);
    });
  }
}

// Device and browser detection
class DeviceDetector {
  static getDeviceType(): DeviceType {
    const userAgent = navigator.userAgent.toLowerCase();
    if (/tablet|ipad/i.test(userAgent)) return 'tablet';
    if (/mobile|android|iphone/i.test(userAgent)) return 'mobile';
    return 'desktop';
  }

  static getBrowser(): string {
    const userAgent = navigator.userAgent;
    if (userAgent.includes('Chrome')) return 'Chrome';
    if (userAgent.includes('Firefox')) return 'Firefox';
    if (userAgent.includes('Safari')) return 'Safari';
    if (userAgent.includes('Edge')) return 'Edge';
    return 'Unknown';
  }

  static getOS(): string {
    const userAgent = navigator.userAgent;
    if (userAgent.includes('Windows')) return 'Windows';
    if (userAgent.includes('Mac OS')) return 'macOS';
    if (userAgent.includes('Linux')) return 'Linux';
    if (userAgent.includes('Android')) return 'Android';
    if (userAgent.includes('iOS')) return 'iOS';
    return 'Unknown';
  }
}

// URL parameter extraction
class URLParser {
  static getUTMParameters(): { utm_source?: string; utm_medium?: string; utm_campaign?: string } {
    const urlParams = new URLSearchParams(window.location.search);
    return {
      utm_source: urlParams.get('utm_source') || undefined,
      utm_medium: urlParams.get('utm_medium') || undefined,
      utm_campaign: urlParams.get('utm_campaign') || undefined,
    };
  }
}

// Main Analytics Tracker
export class AnalyticsTracker {
  private static supabase = getSupabaseClient();
  private static sessionManager = SessionManager.getInstance();
  private static isEnabled = true;
  private static userId?: string;
  private static customerId?: string;
  private static adminUserId?: string;

  // Initialize tracking
  static initialize(options: {
    userId?: string;
    customerId?: string;
    adminUserId?: string;
    enabled?: boolean;
  } = {}) {
    this.userId = options.userId;
    this.customerId = options.customerId;
    this.adminUserId = options.adminUserId;
    this.isEnabled = options.enabled !== false;

    // Set up automatic page tracking
    this.setupPageTracking();
    this.setupBeforeUnloadTracking();

    // Track initial page view
    this.trackPageView();
  }

  // Core tracking method
  static async track(event: Partial<AnalyticsEvent>): Promise<void> {
    if (!this.isEnabled) return;

    try {
      const fullEvent: AnalyticsEvent = {
        // Required fields
        event_type: event.event_type!,
        event_category: event.event_category!,
        session_id: this.sessionManager.getSessionId(),
        
        // Optional context
        user_id: event.user_id || this.userId,
        customer_id: event.customer_id || this.customerId,
        admin_user_id: event.admin_user_id || this.adminUserId,
        
        // Page context
        page_url: event.page_url || window.location.href,
        page_title: event.page_title || document.title,
        referrer: event.referrer || document.referrer,
        
        // UTM parameters
        ...URLParser.getUTMParameters(),
        
        // Device context
        user_agent: navigator.userAgent,
        device_type: DeviceDetector.getDeviceType(),
        browser: DeviceDetector.getBrowser(),
        os: DeviceDetector.getOS(),
        
        // Custom properties
        properties: event.properties || {},
        
        // E-commerce fields
        product_id: event.product_id,
        variant_id: event.variant_id,
        order_id: event.order_id,
        revenue: event.revenue,
        currency: event.currency || 'GBP',
        quantity: event.quantity,
        
        // Admin fields
        admin_action_type: event.admin_action_type,
        affected_resource: event.affected_resource,
        
        // Performance fields
        page_load_time: event.page_load_time,
        time_on_page: event.time_on_page,
      };

      const { error } = await this.supabase
        .from('analytics_events')
        .insert(fullEvent);

      if (error) {
        console.error('Analytics tracking error:', error);
      }
    } catch (error) {
      console.error('Analytics tracking failed:', error);
    }
  }

  // Page tracking
  static trackPageView(pageUrl?: string, pageTitle?: string): void {
    this.sessionManager.resetPageTimer();
    
    this.track({
      event_type: 'page_view',
      event_category: 'website',
      page_url: pageUrl,
      page_title: pageTitle,
      page_load_time: performance.now(),
      properties: {
        viewport_width: window.innerWidth,
        viewport_height: window.innerHeight,
        screen_width: screen.width,
        screen_height: screen.height
      }
    });
  }

  // E-commerce tracking
  static trackProductView(productId: string, productData?: any): void {
    this.track({
      event_type: 'product_view',
      event_category: 'ecommerce',
      product_id: productId,
      properties: productData
    });
  }

  static trackAddToCart(productId: string, variantId?: string, quantity = 1, price?: number): void {
    this.track({
      event_type: 'add_to_cart',
      event_category: 'ecommerce',
      product_id: productId,
      variant_id: variantId,
      quantity: quantity,
      revenue: price ? price * quantity : undefined,
      properties: {
        action: 'add',
        cart_quantity: quantity
      }
    });
  }

  static trackRemoveFromCart(productId: string, variantId?: string, quantity = 1): void {
    this.track({
      event_type: 'remove_from_cart',
      event_category: 'ecommerce',
      product_id: productId,
      variant_id: variantId,
      quantity: quantity,
      properties: {
        action: 'remove',
        cart_quantity: quantity
      }
    });
  }

  static trackCheckoutStart(orderId?: string, cartValue?: number): void {
    this.track({
      event_type: 'checkout_start',
      event_category: 'ecommerce',
      order_id: orderId,
      revenue: cartValue,
      properties: {
        checkout_step: 1
      }
    });
  }

  static trackPurchase(orderId: string, revenue: number, items?: any[]): void {
    this.track({
      event_type: 'purchase_complete',
      event_category: 'ecommerce',
      order_id: orderId,
      revenue: revenue,
      properties: {
        items: items,
        payment_method: 'stripe', // Could be dynamic
        purchase_timestamp: new Date().toISOString()
      }
    });
  }

  // Admin tracking
  static trackAdminAction(actionType: string, affectedResource?: string, properties?: any): void {
    this.track({
      event_type: 'admin_action',
      event_category: 'admin',
      admin_action_type: actionType,
      affected_resource: affectedResource,
      properties: properties
    });
  }

  static trackAdminLogin(): void {
    this.track({
      event_type: 'admin_login',
      event_category: 'admin',
      properties: {
        login_timestamp: new Date().toISOString()
      }
    });
  }

  // Customer tracking
  static trackUserRegistration(): void {
    this.track({
      event_type: 'user_register',
      event_category: 'customer',
      properties: {
        registration_timestamp: new Date().toISOString()
      }
    });
  }

  static trackUserLogin(): void {
    this.track({
      event_type: 'user_login',
      event_category: 'customer',
      properties: {
        login_timestamp: new Date().toISOString()
      }
    });
  }

  // Search and navigation
  static trackSearch(query: string, results?: number): void {
    this.track({
      event_type: 'search',
      event_category: 'website',
      properties: {
        search_query: query,
        search_results_count: results,
        search_timestamp: new Date().toISOString()
      }
    });
  }

  static trackFilterApplied(filters: Record<string, any>): void {
    this.track({
      event_type: 'filter_applied',
      event_category: 'website',
      properties: {
        filters: filters,
        filter_timestamp: new Date().toISOString()
      }
    });
  }

  // Setup automatic tracking
  private static setupPageTracking(): void {
    // Track page views on history changes
    const originalPushState = history.pushState;
    const originalReplaceState = history.replaceState;

    history.pushState = function(...args) {
      originalPushState.apply(history, args);
      setTimeout(() => AnalyticsTracker.trackPageView(), 0);
    };

    history.replaceState = function(...args) {
      originalReplaceState.apply(history, args);  
      setTimeout(() => AnalyticsTracker.trackPageView(), 0);
    };

    window.addEventListener('popstate', () => {
      setTimeout(() => AnalyticsTracker.trackPageView(), 0);
    });
  }

  private static setupBeforeUnloadTracking(): void {
    window.addEventListener('beforeunload', () => {
      // Track time on page before leaving
      const timeOnPage = this.sessionManager.getTimeOnPage();
      
      this.track({
        event_type: 'page_view',
        event_category: 'website',
        time_on_page: Math.round(timeOnPage / 1000), // Convert to seconds
        properties: {
          page_exit: true
        }
      });

      // End session
      this.sessionManager.endSession();
    });
  }

  // Utility methods
  static setUserId(userId: string): void {
    this.userId = userId;
  }

  static setCustomerId(customerId: string): void {
    this.customerId = customerId;
  }

  static setAdminUserId(adminUserId: string): void {
    this.adminUserId = adminUserId;
  }

  static enable(): void {
    this.isEnabled = true;
  }

  static disable(): void {
    this.isEnabled = false;
  }

  static isTrackingEnabled(): boolean {
    return this.isEnabled;
  }
}

// Export a default instance for easy use
export default AnalyticsTracker;