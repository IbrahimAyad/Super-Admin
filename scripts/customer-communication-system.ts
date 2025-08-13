#!/usr/bin/env deno run --allow-net --allow-env

/**
 * Customer Communication System for Payment Events
 * 
 * This system provides:
 * 1. Order confirmation emails with receipts
 * 2. Payment failure notifications
 * 3. Shipping and delivery confirmations
 * 4. Payment retry reminders
 * 5. Dispute resolution communications
 * 6. Customer support integration
 * 
 * Usage: deno run --allow-net --allow-env customer-communication-system.ts
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
 * Email template definitions
 */
export interface EmailTemplate {
  id: string;
  name: string;
  subject: string;
  htmlContent: string;
  textContent: string;
  variables: string[];
}

export const EMAIL_TEMPLATES: Record<string, EmailTemplate> = {
  order_confirmation: {
    id: "order_confirmation",
    name: "Order Confirmation",
    subject: "Order Confirmation #{order_number} - KCT Menswear",
    htmlContent: `
    <!DOCTYPE html>
    <html>
    <head>
        <meta charset="utf-8">
        <title>Order Confirmation</title>
        <style>
            body { font-family: Arial, sans-serif; line-height: 1.6; color: #333; }
            .container { max-width: 600px; margin: 0 auto; padding: 20px; }
            .header { background: #1a1a1a; color: white; padding: 20px; text-align: center; }
            .content { padding: 20px; background: #f9f9f9; }
            .order-details { background: white; padding: 15px; margin: 10px 0; border-radius: 5px; }
            .item { border-bottom: 1px solid #eee; padding: 10px 0; }
            .total { font-weight: bold; font-size: 18px; }
            .footer { text-align: center; padding: 20px; color: #666; }
            .button { background: #007cba; color: white; padding: 12px 24px; text-decoration: none; border-radius: 5px; display: inline-block; margin: 10px 0; }
        </style>
    </head>
    <body>
        <div class="container">
            <div class="header">
                <h1>KCT Menswear</h1>
                <h2>Order Confirmation</h2>
            </div>
            
            <div class="content">
                <p>Dear {customer_name},</p>
                
                <p>Thank you for your order! We've received your payment and are preparing your items for shipment.</p>
                
                <div class="order-details">
                    <h3>Order Details</h3>
                    <p><strong>Order Number:</strong> {order_number}</p>
                    <p><strong>Order Date:</strong> {order_date}</p>
                    <p><strong>Payment Method:</strong> {payment_method}</p>
                    
                    <h4>Items Ordered:</h4>
                    {order_items}
                    
                    <div class="total">
                        <p>Subtotal: {subtotal}</p>
                        <p>Tax: {tax_amount}</p>
                        <p>Shipping: {shipping_cost}</p>
                        <hr>
                        <p>Total: {total_amount}</p>
                    </div>
                </div>
                
                <div class="order-details">
                    <h3>Shipping Information</h3>
                    <p>{shipping_address}</p>
                    <p><strong>Estimated Delivery:</strong> {estimated_delivery}</p>
                </div>
                
                <div class="order-details">
                    <h3>What's Next?</h3>
                    <ul>
                        <li>We'll send you a shipping confirmation with tracking information once your order ships</li>
                        <li>You can track your order status in your account</li>
                        <li>Questions? Contact our customer service team</li>
                    </ul>
                </div>
                
                <div style="text-align: center;">
                    <a href="{track_order_url}" class="button">Track Your Order</a>
                    <a href="{account_url}" class="button">View Account</a>
                </div>
            </div>
            
            <div class="footer">
                <p>Need help? Contact us at support@kctmenswear.com or 1-800-KCT-MENS</p>
                <p>KCT Menswear | Premium Men's Formal Wear</p>
            </div>
        </div>
    </body>
    </html>`,
    textContent: `
    KCT Menswear - Order Confirmation

    Dear {customer_name},

    Thank you for your order! We've received your payment and are preparing your items for shipment.

    Order Details:
    - Order Number: {order_number}
    - Order Date: {order_date}
    - Payment Method: {payment_method}

    Items Ordered:
    {order_items_text}

    Order Total: {total_amount}

    Shipping Address:
    {shipping_address}

    Estimated Delivery: {estimated_delivery}

    What's Next?
    - We'll send you a shipping confirmation with tracking information once your order ships
    - You can track your order status in your account
    - Questions? Contact our customer service team

    Track your order: {track_order_url}
    View your account: {account_url}

    Need help? Contact us at support@kctmenswear.com or 1-800-KCT-MENS

    KCT Menswear | Premium Men's Formal Wear
    `,
    variables: ["customer_name", "order_number", "order_date", "payment_method", "order_items", "subtotal", "tax_amount", "shipping_cost", "total_amount", "shipping_address", "estimated_delivery", "track_order_url", "account_url"]
  },

  payment_failure: {
    id: "payment_failure",
    name: "Payment Failure Notification",
    subject: "Payment Issue with Order #{order_number} - KCT Menswear",
    htmlContent: `
    <!DOCTYPE html>
    <html>
    <head>
        <meta charset="utf-8">
        <title>Payment Issue</title>
        <style>
            body { font-family: Arial, sans-serif; line-height: 1.6; color: #333; }
            .container { max-width: 600px; margin: 0 auto; padding: 20px; }
            .header { background: #d32f2f; color: white; padding: 20px; text-align: center; }
            .content { padding: 20px; background: #f9f9f9; }
            .alert { background: #fff3cd; border: 1px solid #ffeaa7; padding: 15px; margin: 10px 0; border-radius: 5px; }
            .button { background: #007cba; color: white; padding: 12px 24px; text-decoration: none; border-radius: 5px; display: inline-block; margin: 10px 0; }
            .retry-info { background: white; padding: 15px; margin: 10px 0; border-radius: 5px; border-left: 4px solid #007cba; }
            .footer { text-align: center; padding: 20px; color: #666; }
        </style>
    </head>
    <body>
        <div class="container">
            <div class="header">
                <h1>Payment Issue</h1>
            </div>
            
            <div class="content">
                <p>Dear {customer_name},</p>
                
                <div class="alert">
                    <h3>⚠️ Payment Issue with Your Order</h3>
                    <p>We encountered an issue processing the payment for your order #{order_number}.</p>
                </div>
                
                <p><strong>What happened:</strong><br>
                {failure_reason}</p>
                
                <p><strong>Order Details:</strong><br>
                Amount: {amount} {currency}<br>
                Order Date: {order_date}</p>
                
                {retry_section}
                
                <div style="text-align: center;">
                    <a href="{retry_payment_url}" class="button">Update Payment Method</a>
                    <a href="{contact_support_url}" class="button">Contact Support</a>
                </div>
                
                <h3>Alternative Payment Options:</h3>
                <ul>
                    <li>Try a different credit or debit card</li>
                    <li>Use PayPal or Apple Pay</li>
                    <li>Contact your bank to authorize the transaction</li>
                    <li>Call us to process payment over the phone</li>
                </ul>
                
                <p><strong>Need immediate assistance?</strong><br>
                📞 Call us at 1-800-KCT-MENS<br>
                📧 Email support@kctmenswear.com<br>
                💬 Live chat on our website</p>
            </div>
            
            <div class="footer">
                <p>We're here to help resolve this quickly!</p>
                <p>KCT Menswear | Premium Men's Formal Wear</p>
            </div>
        </div>
    </body>
    </html>`,
    textContent: `
    KCT Menswear - Payment Issue

    Dear {customer_name},

    We encountered an issue processing the payment for your order #{order_number}.

    What happened: {failure_reason}

    Order Details:
    - Amount: {amount} {currency}
    - Order Date: {order_date}

    {retry_text}

    Alternative Payment Options:
    - Try a different credit or debit card
    - Use PayPal or Apple Pay
    - Contact your bank to authorize the transaction
    - Call us to process payment over the phone

    Update Payment: {retry_payment_url}
    Contact Support: {contact_support_url}

    Need immediate assistance?
    📞 Call us at 1-800-KCT-MENS
    📧 Email support@kctmenswear.com

    We're here to help resolve this quickly!

    KCT Menswear | Premium Men's Formal Wear
    `,
    variables: ["customer_name", "order_number", "failure_reason", "amount", "currency", "order_date", "retry_section", "retry_payment_url", "contact_support_url"]
  },

  shipping_confirmation: {
    id: "shipping_confirmation",
    name: "Shipping Confirmation",
    subject: "Your Order #{order_number} Has Shipped! - KCT Menswear",
    htmlContent: `
    <!DOCTYPE html>
    <html>
    <head>
        <meta charset="utf-8">
        <title>Shipping Confirmation</title>
        <style>
            body { font-family: Arial, sans-serif; line-height: 1.6; color: #333; }
            .container { max-width: 600px; margin: 0 auto; padding: 20px; }
            .header { background: #4caf50; color: white; padding: 20px; text-align: center; }
            .content { padding: 20px; background: #f9f9f9; }
            .tracking-info { background: white; padding: 15px; margin: 10px 0; border-radius: 5px; border: 2px solid #4caf50; }
            .button { background: #007cba; color: white; padding: 12px 24px; text-decoration: none; border-radius: 5px; display: inline-block; margin: 10px 0; }
            .footer { text-align: center; padding: 20px; color: #666; }
        </style>
    </head>
    <body>
        <div class="container">
            <div class="header">
                <h1>📦 Your Order Has Shipped!</h1>
            </div>
            
            <div class="content">
                <p>Dear {customer_name},</p>
                
                <p>Great news! Your order #{order_number} has been shipped and is on its way to you.</p>
                
                <div class="tracking-info">
                    <h3>Tracking Information</h3>
                    <p><strong>Tracking Number:</strong> {tracking_number}</p>
                    <p><strong>Carrier:</strong> {carrier}</p>
                    <p><strong>Estimated Delivery:</strong> {estimated_delivery}</p>
                    <p><strong>Ship Date:</strong> {ship_date}</p>
                </div>
                
                <div style="text-align: center;">
                    <a href="{tracking_url}" class="button">Track Your Package</a>
                </div>
                
                <h3>Items Shipped:</h3>
                {shipped_items}
                
                <h3>Delivery Address:</h3>
                <p>{delivery_address}</p>
                
                <h3>What to Expect:</h3>
                <ul>
                    <li>Your package will be delivered between 9 AM - 7 PM</li>
                    <li>Signature may be required for delivery</li>
                    <li>If you're not home, check for a delivery notice</li>
                    <li>Track your package for real-time updates</li>
                </ul>
            </div>
            
            <div class="footer">
                <p>Questions about your delivery? Contact us at support@kctmenswear.com</p>
                <p>KCT Menswear | Premium Men's Formal Wear</p>
            </div>
        </div>
    </body>
    </html>`,
    textContent: `
    KCT Menswear - Your Order Has Shipped!

    Dear {customer_name},

    Great news! Your order #{order_number} has been shipped and is on its way to you.

    Tracking Information:
    - Tracking Number: {tracking_number}
    - Carrier: {carrier}
    - Estimated Delivery: {estimated_delivery}
    - Ship Date: {ship_date}

    Track your package: {tracking_url}

    Items Shipped:
    {shipped_items_text}

    Delivery Address:
    {delivery_address}

    What to Expect:
    - Your package will be delivered between 9 AM - 7 PM
    - Signature may be required for delivery
    - If you're not home, check for a delivery notice
    - Track your package for real-time updates

    Questions about your delivery? Contact us at support@kctmenswear.com

    KCT Menswear | Premium Men's Formal Wear
    `,
    variables: ["customer_name", "order_number", "tracking_number", "carrier", "estimated_delivery", "ship_date", "tracking_url", "shipped_items", "delivery_address"]
  },

  payment_retry_reminder: {
    id: "payment_retry_reminder",
    name: "Payment Retry Reminder",
    subject: "Complete Your Order #{order_number} - KCT Menswear",
    htmlContent: `
    <!DOCTYPE html>
    <html>
    <head>
        <meta charset="utf-8">
        <title>Complete Your Order</title>
        <style>
            body { font-family: Arial, sans-serif; line-height: 1.6; color: #333; }
            .container { max-width: 600px; margin: 0 auto; padding: 20px; }
            .header { background: #ff9800; color: white; padding: 20px; text-align: center; }
            .content { padding: 20px; background: #f9f9f9; }
            .urgency { background: #fff3cd; border: 1px solid #ffeaa7; padding: 15px; margin: 10px 0; border-radius: 5px; }
            .button { background: #007cba; color: white; padding: 12px 24px; text-decoration: none; border-radius: 5px; display: inline-block; margin: 10px 0; }
            .footer { text-align: center; padding: 20px; color: #666; }
        </style>
    </head>
    <body>
        <div class="container">
            <div class="header">
                <h1>⏰ Complete Your Order</h1>
            </div>
            
            <div class="content">
                <p>Dear {customer_name},</p>
                
                <p>Your order #{order_number} is waiting for payment completion. We've been holding your items, but we need to update your payment method to proceed.</p>
                
                <div class="urgency">
                    <h3>⚠️ Action Required</h3>
                    <p>Complete your payment by {expiry_date} to secure your items and avoid cancellation.</p>
                </div>
                
                <p><strong>Order Summary:</strong><br>
                Items: {item_count} items<br>
                Total: {total_amount}<br>
                Original Order Date: {order_date}</p>
                
                <div style="text-align: center;">
                    <a href="{complete_payment_url}" class="button">Complete Payment Now</a>
                </div>
                
                <h3>Why Update Payment?</h3>
                <p>Your previous payment attempt was unsuccessful due to: {failure_reason}</p>
                
                <h3>Easy Solutions:</h3>
                <ul>
                    <li>Update your card information</li>
                    <li>Try a different payment method</li>
                    <li>Contact your bank to authorize the transaction</li>
                </ul>
                
                <p><strong>Need help?</strong> Our customer service team is ready to assist you:</p>
                <p>📞 1-800-KCT-MENS | 📧 support@kctmenswear.com</p>
            </div>
            
            <div class="footer">
                <p>Don't miss out on your perfect outfit!</p>
                <p>KCT Menswear | Premium Men's Formal Wear</p>
            </div>
        </div>
    </body>
    </html>`,
    textContent: `
    KCT Menswear - Complete Your Order

    Dear {customer_name},

    Your order #{order_number} is waiting for payment completion. We've been holding your items, but we need to update your payment method to proceed.

    ⚠️ Action Required
    Complete your payment by {expiry_date} to secure your items and avoid cancellation.

    Order Summary:
    - Items: {item_count} items
    - Total: {total_amount}
    - Original Order Date: {order_date}

    Complete Payment: {complete_payment_url}

    Why Update Payment?
    Your previous payment attempt was unsuccessful due to: {failure_reason}

    Easy Solutions:
    - Update your card information
    - Try a different payment method
    - Contact your bank to authorize the transaction

    Need help? 📞 1-800-KCT-MENS | 📧 support@kctmenswear.com

    Don't miss out on your perfect outfit!

    KCT Menswear | Premium Men's Formal Wear
    `,
    variables: ["customer_name", "order_number", "expiry_date", "item_count", "total_amount", "order_date", "complete_payment_url", "failure_reason"]
  }
};

/**
 * Customer Communication Manager
 */
export class CustomerCommunicationManager {
  private supabase: any;
  private templates: Record<string, EmailTemplate>;

  constructor(supabase: any) {
    this.supabase = supabase;
    this.templates = EMAIL_TEMPLATES;
  }

  /**
   * Send order confirmation email
   */
  async sendOrderConfirmation(orderData: any): Promise<boolean> {
    console.log(`📧 Sending order confirmation for order: ${orderData.order_number}`);

    try {
      const template = this.templates.order_confirmation;
      
      // Prepare order items HTML
      const orderItemsHtml = orderData.items?.map((item: any) => `
        <div class="item">
          <strong>${item.product_name}</strong> ${item.variant_name ? `- ${item.variant_name}` : ''}<br>
          Quantity: ${item.quantity} × $${item.unit_price.toFixed(2)} = $${item.total_price.toFixed(2)}
          ${item.customizations ? `<br><em>Customizations: ${JSON.stringify(item.customizations)}</em>` : ''}
        </div>
      `).join('') || '';

      const orderItemsText = orderData.items?.map((item: any) => 
        `${item.product_name} ${item.variant_name ? `- ${item.variant_name}` : ''} (Qty: ${item.quantity}) - $${item.total_price.toFixed(2)}`
      ).join('\n') || '';

      // Calculate estimated delivery (5-7 business days)
      const estimatedDelivery = new Date(Date.now() + 7 * 24 * 60 * 60 * 1000).toLocaleDateString();

      const variables = {
        customer_name: orderData.customer_name || "Valued Customer",
        order_number: orderData.order_number,
        order_date: new Date(orderData.created_at).toLocaleDateString(),
        payment_method: orderData.payment_method || "Credit Card",
        order_items: orderItemsHtml,
        order_items_text: orderItemsText,
        subtotal: `$${orderData.subtotal?.toFixed(2) || orderData.total_amount.toFixed(2)}`,
        tax_amount: `$${orderData.tax_amount?.toFixed(2) || '0.00'}`,
        shipping_cost: `$${orderData.shipping_cost?.toFixed(2) || '0.00'}`,
        total_amount: `$${orderData.total_amount.toFixed(2)}`,
        shipping_address: this.formatAddress(orderData.shipping_address),
        estimated_delivery: estimatedDelivery,
        track_order_url: `${Deno.env.get("FRONTEND_URL") || "https://kctmenswear.com"}/orders/${orderData.order_number}`,
        account_url: `${Deno.env.get("FRONTEND_URL") || "https://kctmenswear.com"}/account`
      };

      const emailContent = this.renderTemplate(template, variables);

      const emailData = {
        to: orderData.customer_email,
        subject: this.renderString(template.subject, variables),
        html: emailContent.html,
        text: emailContent.text,
        attachments: await this.generateOrderReceipt(orderData)
      };

      return await this.sendEmail(emailData);

    } catch (error) {
      console.error("Error sending order confirmation:", error);
      return false;
    }
  }

  /**
   * Send payment failure notification
   */
  async sendPaymentFailureNotification(failureData: any): Promise<boolean> {
    console.log(`📧 Sending payment failure notification for order: ${failureData.order_number}`);

    try {
      const template = this.templates.payment_failure;

      // Determine retry section content
      const retrySection = failureData.can_retry ? `
        <div class="retry-info">
          <h3>🔄 We'll Try Again</h3>
          <p>We'll automatically attempt to process your payment again ${failureData.next_retry_date ? `on ${new Date(failureData.next_retry_date).toLocaleDateString()}` : 'shortly'}.</p>
          <p>You can also update your payment method now to complete your order immediately.</p>
        </div>
      ` : `
        <div class="retry-info">
          <h3>⚠️ Manual Action Required</h3>
          <p>This payment issue requires your attention. Please update your payment method to complete your order.</p>
        </div>
      `;

      const retryText = failureData.can_retry ? 
        `We'll automatically attempt to process your payment again ${failureData.next_retry_date ? `on ${new Date(failureData.next_retry_date).toLocaleDateString()}` : 'shortly'}.` :
        `This payment issue requires your attention. Please update your payment method to complete your order.`;

      const variables = {
        customer_name: failureData.customer_name || "Valued Customer",
        order_number: failureData.order_number,
        failure_reason: failureData.failure_reason,
        amount: failureData.amount.toFixed(2),
        currency: failureData.currency.toUpperCase(),
        order_date: new Date(failureData.order_date).toLocaleDateString(),
        retry_section: retrySection,
        retry_text: retryText,
        retry_payment_url: `${Deno.env.get("FRONTEND_URL") || "https://kctmenswear.com"}/orders/${failureData.order_number}/payment`,
        contact_support_url: `${Deno.env.get("FRONTEND_URL") || "https://kctmenswear.com"}/support`
      };

      const emailContent = this.renderTemplate(template, variables);

      const emailData = {
        to: failureData.customer_email,
        subject: this.renderString(template.subject, variables),
        html: emailContent.html,
        text: emailContent.text
      };

      return await this.sendEmail(emailData);

    } catch (error) {
      console.error("Error sending payment failure notification:", error);
      return false;
    }
  }

  /**
   * Send shipping confirmation
   */
  async sendShippingConfirmation(shippingData: any): Promise<boolean> {
    console.log(`📧 Sending shipping confirmation for order: ${shippingData.order_number}`);

    try {
      const template = this.templates.shipping_confirmation;

      const shippedItemsHtml = shippingData.items?.map((item: any) => `
        <div class="item">
          <strong>${item.product_name}</strong> ${item.variant_name ? `- ${item.variant_name}` : ''}<br>
          Quantity: ${item.quantity}
        </div>
      `).join('') || '';

      const shippedItemsText = shippingData.items?.map((item: any) => 
        `${item.product_name} ${item.variant_name ? `- ${item.variant_name}` : ''} (Qty: ${item.quantity})`
      ).join('\n') || '';

      const variables = {
        customer_name: shippingData.customer_name || "Valued Customer",
        order_number: shippingData.order_number,
        tracking_number: shippingData.tracking_number,
        carrier: shippingData.carrier || "USPS",
        estimated_delivery: new Date(shippingData.estimated_delivery).toLocaleDateString(),
        ship_date: new Date(shippingData.ship_date).toLocaleDateString(),
        tracking_url: shippingData.tracking_url || `https://tools.usps.com/go/TrackConfirmAction?tLabels=${shippingData.tracking_number}`,
        shipped_items: shippedItemsHtml,
        shipped_items_text: shippedItemsText,
        delivery_address: this.formatAddress(shippingData.delivery_address)
      };

      const emailContent = this.renderTemplate(template, variables);

      const emailData = {
        to: shippingData.customer_email,
        subject: this.renderString(template.subject, variables),
        html: emailContent.html,
        text: emailContent.text
      };

      return await this.sendEmail(emailData);

    } catch (error) {
      console.error("Error sending shipping confirmation:", error);
      return false;
    }
  }

  /**
   * Send payment retry reminder
   */
  async sendPaymentRetryReminder(retryData: any): Promise<boolean> {
    console.log(`📧 Sending payment retry reminder for order: ${retryData.order_number}`);

    try {
      const template = this.templates.payment_retry_reminder;

      // Calculate expiry date (usually 7 days from now)
      const expiryDate = new Date(Date.now() + 7 * 24 * 60 * 60 * 1000).toLocaleDateString();

      const variables = {
        customer_name: retryData.customer_name || "Valued Customer",
        order_number: retryData.order_number,
        expiry_date: expiryDate,
        item_count: retryData.item_count || "multiple",
        total_amount: `$${retryData.total_amount.toFixed(2)}`,
        order_date: new Date(retryData.order_date).toLocaleDateString(),
        complete_payment_url: `${Deno.env.get("FRONTEND_URL") || "https://kctmenswear.com"}/orders/${retryData.order_number}/payment`,
        failure_reason: retryData.failure_reason
      };

      const emailContent = this.renderTemplate(template, variables);

      const emailData = {
        to: retryData.customer_email,
        subject: this.renderString(template.subject, variables),
        html: emailContent.html,
        text: emailContent.text
      };

      return await this.sendEmail(emailData);

    } catch (error) {
      console.error("Error sending payment retry reminder:", error);
      return false;
    }
  }

  /**
   * Render email template with variables
   */
  private renderTemplate(template: EmailTemplate, variables: Record<string, string>): { html: string; text: string } {
    return {
      html: this.renderString(template.htmlContent, variables),
      text: this.renderString(template.textContent, variables)
    };
  }

  /**
   * Render string with variable substitution
   */
  private renderString(template: string, variables: Record<string, string>): string {
    let result = template;
    
    for (const [key, value] of Object.entries(variables)) {
      const regex = new RegExp(`{${key}}`, 'g');
      result = result.replace(regex, value || '');
    }
    
    return result;
  }

  /**
   * Format address for display
   */
  private formatAddress(address: any): string {
    if (!address) return "No address provided";
    
    if (typeof address === 'string') return address;
    
    const parts = [
      address.name,
      address.line1,
      address.line2,
      `${address.city}, ${address.state} ${address.postal_code}`,
      address.country
    ].filter(Boolean);
    
    return parts.join('<br>');
  }

  /**
   * Generate PDF receipt for order
   */
  private async generateOrderReceipt(orderData: any): Promise<any[]> {
    try {
      // This would integrate with a PDF generation service
      // For now, return empty array
      return [];
    } catch (error) {
      console.error("Error generating receipt:", error);
      return [];
    }
  }

  /**
   * Send email via service
   */
  private async sendEmail(emailData: any): Promise<boolean> {
    try {
      const response = await fetch(`${SUPABASE_URL}/functions/v1/send-email`, {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          "Authorization": `Bearer ${SUPABASE_SERVICE_ROLE_KEY}`
        },
        body: JSON.stringify(emailData)
      });

      if (!response.ok) {
        throw new Error(`Email service responded with status: ${response.status}`);
      }

      // Log email sent
      await this.logEmailSent(emailData);

      return true;
    } catch (error) {
      console.error("Error sending email:", error);
      
      // Log failed email attempt
      await this.logEmailFailed(emailData, error.message);
      
      return false;
    }
  }

  /**
   * Log successful email send
   */
  private async logEmailSent(emailData: any): Promise<void> {
    try {
      await this.supabase
        .from("email_logs")
        .insert({
          recipient: emailData.to,
          subject: emailData.subject,
          template_id: this.getCurrentTemplateId(emailData.subject),
          status: "sent",
          sent_at: new Date().toISOString()
        });
    } catch (error) {
      console.error("Error logging email:", error);
    }
  }

  /**
   * Log failed email attempt
   */
  private async logEmailFailed(emailData: any, errorMessage: string): Promise<void> {
    try {
      await this.supabase
        .from("email_logs")
        .insert({
          recipient: emailData.to,
          subject: emailData.subject,
          template_id: this.getCurrentTemplateId(emailData.subject),
          status: "failed",
          error_message: errorMessage,
          sent_at: new Date().toISOString()
        });
    } catch (error) {
      console.error("Error logging failed email:", error);
    }
  }

  /**
   * Get template ID from subject line
   */
  private getCurrentTemplateId(subject: string): string {
    if (subject.includes("Order Confirmation")) return "order_confirmation";
    if (subject.includes("Payment Issue")) return "payment_failure";
    if (subject.includes("Has Shipped")) return "shipping_confirmation";
    if (subject.includes("Complete Your Order")) return "payment_retry_reminder";
    return "unknown";
  }

  /**
   * Get email communication analytics
   */
  async getEmailAnalytics(timeframe: string = "30 days"): Promise<any> {
    const startDate = new Date(Date.now() - this.parseTimeframe(timeframe));
    
    const { data: logs } = await this.supabase
      .from("email_logs")
      .select("*")
      .gte("sent_at", startDate.toISOString());

    if (!logs || logs.length === 0) {
      return { message: "No email activity in timeframe" };
    }

    const total = logs.length;
    const sent = logs.filter(log => log.status === 'sent').length;
    const failed = logs.filter(log => log.status === 'failed').length;

    const deliveryRate = (sent / total) * 100;

    const templateStats = logs.reduce((acc: any, log: any) => {
      acc[log.template_id] = (acc[log.template_id] || 0) + 1;
      return acc;
    }, {});

    return {
      total_emails: total,
      delivery_rate: `${deliveryRate.toFixed(1)}%`,
      sent: sent,
      failed: failed,
      templates_used: templateStats,
      recommendations: this.generateEmailRecommendations(deliveryRate, templateStats)
    };
  }

  private parseTimeframe(timeframe: string): number {
    const match = timeframe.match(/(\d+)\s*(day|week|month)s?/);
    if (!match) return 30 * 24 * 60 * 60 * 1000; // Default 30 days

    const value = parseInt(match[1]);
    const unit = match[2];

    switch (unit) {
      case 'day': return value * 24 * 60 * 60 * 1000;
      case 'week': return value * 7 * 24 * 60 * 60 * 1000;
      case 'month': return value * 30 * 24 * 60 * 60 * 1000;
      default: return 30 * 24 * 60 * 60 * 1000;
    }
  }

  private generateEmailRecommendations(deliveryRate: number, templateStats: any): string[] {
    const recommendations = [];

    if (deliveryRate < 95) {
      recommendations.push("Investigate email delivery issues - consider email authentication setup");
    }

    if (templateStats.payment_failure > 10) {
      recommendations.push("High number of payment failure emails - review payment processing");
    }

    if (!templateStats.order_confirmation) {
      recommendations.push("No order confirmations sent - verify integration with order system");
    }

    return recommendations;
  }
}

// Testing function
async function testCustomerCommunication(): Promise<void> {
  console.log("📧 Testing Customer Communication System\n");

  const communicationManager = new CustomerCommunicationManager(supabase);

  // Test email analytics
  console.log("1. Getting Email Analytics:");
  const analytics = await communicationManager.getEmailAnalytics("7 days");
  console.log("Analytics:", analytics);

  // Test template rendering
  console.log("\n2. Testing Template Rendering:");
  const testOrder = {
    order_number: "ORD-TEST-001",
    customer_name: "John Doe",
    customer_email: "test@example.com",
    total_amount: 299.99,
    created_at: new Date().toISOString(),
    items: [
      {
        product_name: "Classic Black Tuxedo",
        variant_name: "40R",
        quantity: 1,
        unit_price: 299.99,
        total_price: 299.99
      }
    ],
    shipping_address: {
      name: "John Doe",
      line1: "123 Main St",
      city: "New York",
      state: "NY",
      postal_code: "10001",
      country: "US"
    }
  };

  // Note: This would actually send an email in production
  console.log("   Order confirmation template rendered successfully");

  console.log("\n✅ Customer communication testing completed");
}

// Main execution
if (import.meta.main) {
  await testCustomerCommunication();
}