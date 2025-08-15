import { supabase } from '@/lib/supabase';
import { toast } from '@/components/ui/use-toast';

export interface ChatNotification {
  id: string;
  type: 'message' | 'product_update' | 'cart_reminder' | 'order_update' | 'promotion';
  title: string;
  message: string;
  data?: any;
  timestamp: Date;
  read: boolean;
  priority: 'low' | 'medium' | 'high';
}

export interface NotificationPreferences {
  enableSound: boolean;
  enableDesktop: boolean;
  enableInApp: boolean;
  enableEmail: boolean;
  enableSMS: boolean;
  quietHours: {
    enabled: boolean;
    start: string; // "22:00"
    end: string;   // "08:00"
  };
}

class ChatNotificationService {
  private notifications: ChatNotification[] = [];
  private preferences: NotificationPreferences;
  private permissionGranted: boolean = false;
  private audioContext: AudioContext | null = null;
  private notificationSound: HTMLAudioElement | null = null;
  private subscribers: Map<string, (notification: ChatNotification) => void> = new Map();

  constructor() {
    this.preferences = this.loadPreferences();
    this.initializeNotifications();
    this.setupRealtimeSubscription();
  }

  private loadPreferences(): NotificationPreferences {
    const saved = localStorage.getItem('chat_notification_preferences');
    if (saved) {
      return JSON.parse(saved);
    }
    
    return {
      enableSound: true,
      enableDesktop: true,
      enableInApp: true,
      enableEmail: false,
      enableSMS: false,
      quietHours: {
        enabled: false,
        start: '22:00',
        end: '08:00'
      }
    };
  }

  private async initializeNotifications() {
    // Request browser notification permission
    if ('Notification' in window && Notification.permission === 'default') {
      const permission = await Notification.requestPermission();
      this.permissionGranted = permission === 'granted';
    } else {
      this.permissionGranted = Notification.permission === 'granted';
    }

    // Initialize audio for notification sounds
    if (this.preferences.enableSound) {
      this.notificationSound = new Audio('/notification.mp3');
      this.notificationSound.volume = 0.5;
    }

    // Load existing notifications from localStorage
    const saved = localStorage.getItem('chat_notifications');
    if (saved) {
      this.notifications = JSON.parse(saved);
    }
  }

  private setupRealtimeSubscription() {
    // Subscribe to realtime notifications from Supabase
    const channel = supabase
      .channel('chat_notifications')
      .on('postgres_changes', {
        event: 'INSERT',
        schema: 'public',
        table: 'chat_notifications'
      }, (payload) => {
        this.handleIncomingNotification(payload.new as any);
      })
      .subscribe();
  }

  private handleIncomingNotification(data: any) {
    const notification: ChatNotification = {
      id: data.id || `notif_${Date.now()}`,
      type: data.type || 'message',
      title: data.title,
      message: data.message,
      data: data.data,
      timestamp: new Date(data.created_at || Date.now()),
      read: false,
      priority: data.priority || 'medium'
    };

    this.addNotification(notification);
  }

  public async sendNotification(notification: Omit<ChatNotification, 'id' | 'timestamp' | 'read'>) {
    const newNotification: ChatNotification = {
      ...notification,
      id: `notif_${Date.now()}`,
      timestamp: new Date(),
      read: false
    };

    this.addNotification(newNotification);
    return newNotification;
  }

  private addNotification(notification: ChatNotification) {
    // Check quiet hours
    if (this.isQuietHours()) {
      console.log('Notification suppressed during quiet hours');
      this.notifications.push({ ...notification, read: true });
      this.saveNotifications();
      return;
    }

    this.notifications.unshift(notification);
    this.saveNotifications();

    // Send to all subscribers
    this.subscribers.forEach(callback => callback(notification));

    // Show different types of notifications based on preferences
    if (this.preferences.enableInApp) {
      this.showInAppNotification(notification);
    }

    if (this.preferences.enableDesktop && this.permissionGranted) {
      this.showDesktopNotification(notification);
    }

    if (this.preferences.enableSound && this.notificationSound) {
      this.playNotificationSound();
    }

    // Handle special notification types
    this.handleSpecialNotifications(notification);
  }

  private isQuietHours(): boolean {
    if (!this.preferences.quietHours.enabled) return false;

    const now = new Date();
    const currentTime = now.getHours() * 60 + now.getMinutes();
    
    const [startHour, startMin] = this.preferences.quietHours.start.split(':').map(Number);
    const [endHour, endMin] = this.preferences.quietHours.end.split(':').map(Number);
    
    const startTime = startHour * 60 + startMin;
    const endTime = endHour * 60 + endMin;

    if (startTime <= endTime) {
      return currentTime >= startTime && currentTime <= endTime;
    } else {
      return currentTime >= startTime || currentTime <= endTime;
    }
  }

  private showInAppNotification(notification: ChatNotification) {
    // Use toast for in-app notifications
    toast({
      title: notification.title,
      description: notification.message,
      duration: notification.priority === 'high' ? 10000 : 5000
    });
  }

  private showDesktopNotification(notification: ChatNotification) {
    if (!this.permissionGranted) return;

    const options: NotificationOptions = {
      body: notification.message,
      icon: '/logo.png',
      badge: '/badge.png',
      tag: notification.id,
      requireInteraction: notification.priority === 'high',
      data: notification.data,
      actions: this.getNotificationActions(notification.type)
    };

    const desktopNotification = new Notification(notification.title, options);

    desktopNotification.onclick = () => {
      window.focus();
      this.handleNotificationClick(notification);
      desktopNotification.close();
    };
  }

  private getNotificationActions(type: string): NotificationAction[] {
    switch (type) {
      case 'message':
        return [
          { action: 'reply', title: 'Reply' },
          { action: 'dismiss', title: 'Dismiss' }
        ];
      case 'cart_reminder':
        return [
          { action: 'checkout', title: 'Checkout' },
          { action: 'later', title: 'Later' }
        ];
      case 'order_update':
        return [
          { action: 'track', title: 'Track Order' },
          { action: 'dismiss', title: 'OK' }
        ];
      default:
        return [];
    }
  }

  private playNotificationSound() {
    if (this.notificationSound) {
      this.notificationSound.play().catch(err => {
        console.log('Could not play notification sound:', err);
      });
    }
  }

  private handleSpecialNotifications(notification: ChatNotification) {
    switch (notification.type) {
      case 'cart_reminder':
        this.scheduleCartReminder(notification);
        break;
      case 'product_update':
        this.handleProductUpdate(notification);
        break;
      case 'promotion':
        this.handlePromotion(notification);
        break;
    }
  }

  private scheduleCartReminder(notification: ChatNotification) {
    // Schedule a follow-up reminder if cart is still abandoned
    setTimeout(() => {
      const cart = this.getCartFromStorage();
      if (cart && cart.items.length > 0 && !cart.checkedOut) {
        this.sendNotification({
          type: 'cart_reminder',
          title: 'Complete Your Purchase',
          message: `You still have ${cart.items.length} items in your cart. Complete your order now and get free shipping!`,
          priority: 'medium',
          data: { cart }
        });
      }
    }, 3600000); // 1 hour later
  }

  private handleProductUpdate(notification: ChatNotification) {
    // Update UI with new product information
    if (notification.data?.productId) {
      // Trigger product refresh in chat
      window.dispatchEvent(new CustomEvent('product-update', {
        detail: notification.data
      }));
    }
  }

  private handlePromotion(notification: ChatNotification) {
    // Show special promotion UI
    if (notification.data?.promoCode) {
      localStorage.setItem('active_promo', JSON.stringify(notification.data));
    }
  }

  private handleNotificationClick(notification: ChatNotification) {
    // Mark as read
    this.markAsRead(notification.id);

    // Handle click based on type
    switch (notification.type) {
      case 'message':
        // Open chat window
        window.dispatchEvent(new CustomEvent('open-chat'));
        break;
      case 'cart_reminder':
        // Navigate to cart
        window.location.href = '/cart';
        break;
      case 'order_update':
        // Navigate to order tracking
        if (notification.data?.orderId) {
          window.location.href = `/orders/${notification.data.orderId}`;
        }
        break;
      case 'product_update':
        // Navigate to product
        if (notification.data?.productId) {
          window.location.href = `/products/${notification.data.productId}`;
        }
        break;
    }
  }

  public markAsRead(notificationId: string) {
    const notification = this.notifications.find(n => n.id === notificationId);
    if (notification) {
      notification.read = true;
      this.saveNotifications();
    }
  }

  public markAllAsRead() {
    this.notifications.forEach(n => n.read = true);
    this.saveNotifications();
  }

  public getUnreadCount(): number {
    return this.notifications.filter(n => !n.read).length;
  }

  public getNotifications(limit?: number): ChatNotification[] {
    return limit ? this.notifications.slice(0, limit) : this.notifications;
  }

  public clearNotifications() {
    this.notifications = [];
    this.saveNotifications();
  }

  private saveNotifications() {
    localStorage.setItem('chat_notifications', JSON.stringify(this.notifications));
  }

  public updatePreferences(preferences: Partial<NotificationPreferences>) {
    this.preferences = { ...this.preferences, ...preferences };
    localStorage.setItem('chat_notification_preferences', JSON.stringify(this.preferences));
    
    // Re-initialize based on new preferences
    if (preferences.enableSound !== undefined) {
      if (preferences.enableSound && !this.notificationSound) {
        this.notificationSound = new Audio('/notification.mp3');
        this.notificationSound.volume = 0.5;
      } else if (!preferences.enableSound) {
        this.notificationSound = null;
      }
    }
  }

  public subscribe(id: string, callback: (notification: ChatNotification) => void) {
    this.subscribers.set(id, callback);
  }

  public unsubscribe(id: string) {
    this.subscribers.delete(id);
  }

  private getCartFromStorage(): any {
    const cart = localStorage.getItem('chat_cart');
    return cart ? JSON.parse(cart) : null;
  }

  // Send notifications for different chat events
  public async notifyNewMessage(message: string, fromUser: boolean = false) {
    if (!fromUser) {
      await this.sendNotification({
        type: 'message',
        title: 'KCT Style Assistant',
        message: message,
        priority: 'medium'
      });
    }
  }

  public async notifyCartAbandonment(cartItems: any[]) {
    const itemCount = cartItems.length;
    const totalValue = cartItems.reduce((sum, item) => sum + item.price, 0);
    
    await this.sendNotification({
      type: 'cart_reminder',
      title: 'Items in Your Cart',
      message: `You have ${itemCount} items worth $${totalValue.toFixed(2)} waiting for you. Complete your purchase now!`,
      priority: 'medium',
      data: { cartItems }
    });
  }

  public async notifyOrderUpdate(orderId: string, status: string) {
    await this.sendNotification({
      type: 'order_update',
      title: 'Order Update',
      message: `Your order #${orderId} is now ${status}`,
      priority: 'high',
      data: { orderId, status }
    });
  }

  public async notifyProductBack(product: any) {
    await this.sendNotification({
      type: 'product_update',
      title: 'Product Back in Stock!',
      message: `${product.name} is now available in your size`,
      priority: 'high',
      data: { productId: product.id, product }
    });
  }

  public async notifyPromotion(promoCode: string, discount: number, expiresAt: Date) {
    await this.sendNotification({
      type: 'promotion',
      title: `${discount}% OFF - Limited Time!`,
      message: `Use code ${promoCode} for ${discount}% off your order. Expires ${expiresAt.toLocaleDateString()}`,
      priority: 'high',
      data: { promoCode, discount, expiresAt }
    });
  }
}

// Export singleton instance
export const chatNotificationService = new ChatNotificationService();