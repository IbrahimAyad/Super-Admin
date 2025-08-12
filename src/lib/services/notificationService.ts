/**
 * NOTIFICATION SERVICE
 * Comprehensive customer notification system for order updates
 * Supports email, SMS, and push notifications with templating
 */

import { supabase } from '@/lib/supabase-client';

// ============================================
// TYPES AND INTERFACES
// ============================================

export interface NotificationTemplate {
  id: string;
  name: string;
  type: NotificationType;
  subject: string;
  html_content: string;
  text_content: string;
  variables: string[];
  is_active: boolean;
}

export interface NotificationRequest {
  order_id: string;
  notification_type: NotificationType;
  delivery_method: DeliveryMethod;
  recipient_email?: string;
  recipient_phone?: string;
  template_data: Record<string, any>;
  scheduled_for?: string;
  priority?: NotificationPriority;
}

export interface EmailTemplate {
  subject: string;
  html: string;
  text: string;
}

export type NotificationType = 
  | 'order_confirmation'
  | 'order_processing'
  | 'order_shipped'
  | 'order_delivered'
  | 'order_cancelled'
  | 'order_delayed'
  | 'refund_processed'
  | 'return_received'
  | 'custom';

export type DeliveryMethod = 'email' | 'sms' | 'push';
export type NotificationPriority = 'low' | 'normal' | 'high' | 'urgent';

// ============================================
// EMAIL TEMPLATES
// ============================================

export const EMAIL_TEMPLATES: Record<NotificationType, EmailTemplate> = {
  order_confirmation: {
    subject: 'Order Confirmation - {{order_number}}',
    html: `
      <!DOCTYPE html>
      <html>
      <head>
        <meta charset="utf-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <title>Order Confirmation</title>
        <style>
          body { font-family: Arial, sans-serif; line-height: 1.6; color: #333; }
          .container { max-width: 600px; margin: 0 auto; padding: 20px; }
          .header { background: #2563eb; color: white; padding: 20px; text-align: center; }
          .content { padding: 20px; }
          .order-summary { background: #f8f9fa; padding: 15px; border-radius: 5px; margin: 20px 0; }
          .item { display: flex; justify-content: space-between; padding: 10px 0; border-bottom: 1px solid #eee; }
          .total { font-weight: bold; font-size: 18px; }
          .footer { text-align: center; padding: 20px; color: #666; font-size: 14px; }
        </style>
      </head>
      <body>
        <div class="container">
          <div class="header">
            <h1>Order Confirmed!</h1>
            <p>Thank you for your order, {{customer_name}}</p>
          </div>
          
          <div class="content">
            <h2>Order #{{order_number}}</h2>
            <p>Your order has been confirmed and is being prepared for shipment.</p>
            
            <div class="order-summary">
              <h3>Order Summary</h3>
              {{#each items}}
              <div class="item">
                <div>
                  <strong>{{product_name}}</strong>
                  {{#if variant_name}}<br><small>{{variant_name}}</small>{{/if}}
                  <br><small>Qty: {{quantity}}</small>
                </div>
                <div>\${{total_price}}</div>
              </div>
              {{/each}}
              
              <div class="item">
                <div><strong>Subtotal</strong></div>
                <div>\${{subtotal}}</div>
              </div>
              <div class="item">
                <div><strong>Shipping</strong></div>
                <div>\${{shipping_amount}}</div>
              </div>
              <div class="item">
                <div><strong>Tax</strong></div>
                <div>\${{tax_amount}}</div>
              </div>
              <div class="item total">
                <div>Total</div>
                <div>\${{total_amount}}</div>
              </div>
            </div>
            
            <h3>Shipping Address</h3>
            <p>
              {{shipping_address.line1}}<br>
              {{#if shipping_address.line2}}{{shipping_address.line2}}<br>{{/if}}
              {{shipping_address.city}}, {{shipping_address.state}} {{shipping_address.postal_code}}<br>
              {{shipping_address.country}}
            </p>
            
            <p>We'll send you another email when your order ships with tracking information.</p>
          </div>
          
          <div class="footer">
            <p>Questions? Contact us at support@kctmenswear.com</p>
            <p>&copy; 2024 KCT Menswear. All rights reserved.</p>
          </div>
        </div>
      </body>
      </html>
    `,
    text: `
Order Confirmed!

Thank you for your order, {{customer_name}}.

Order #{{order_number}}
Your order has been confirmed and is being prepared for shipment.

Order Summary:
{{#each items}}
{{product_name}} {{#if variant_name}}({{variant_name}}){{/if}} - Qty: {{quantity}} - \${{total_price}}
{{/each}}

Subtotal: \${{subtotal}}
Shipping: \${{shipping_amount}}
Tax: \${{tax_amount}}
Total: \${{total_amount}}

Shipping Address:
{{shipping_address.line1}}
{{#if shipping_address.line2}}{{shipping_address.line2}}{{/if}}
{{shipping_address.city}}, {{shipping_address.state}} {{shipping_address.postal_code}}
{{shipping_address.country}}

We'll send you another email when your order ships with tracking information.

Questions? Contact us at support@kctmenswear.com
    `
  },

  order_processing: {
    subject: 'Your Order is Being Processed - {{order_number}}',
    html: `
      <!DOCTYPE html>
      <html>
      <head>
        <meta charset="utf-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <title>Order Processing</title>
        <style>
          body { font-family: Arial, sans-serif; line-height: 1.6; color: #333; }
          .container { max-width: 600px; margin: 0 auto; padding: 20px; }
          .header { background: #f59e0b; color: white; padding: 20px; text-align: center; }
          .content { padding: 20px; }
          .status-bar { background: #fef3c7; padding: 15px; border-radius: 5px; margin: 20px 0; }
          .footer { text-align: center; padding: 20px; color: #666; font-size: 14px; }
        </style>
      </head>
      <body>
        <div class="container">
          <div class="header">
            <h1>Order in Progress</h1>
            <p>Hi {{customer_name}}, your order is being processed</p>
          </div>
          
          <div class="content">
            <h2>Order #{{order_number}}</h2>
            
            <div class="status-bar">
              <h3>🚀 Processing Started</h3>
              <p>Your order is currently being picked and packed in our warehouse. We expect to ship it within {{estimated_ship_days}} business days.</p>
            </div>
            
            <p>You'll receive another email with tracking information once your order ships.</p>
            
            {{#if special_instructions}}
            <h3>Special Instructions</h3>
            <p>{{special_instructions}}</p>
            {{/if}}
          </div>
          
          <div class="footer">
            <p>Questions? Contact us at support@kctmenswear.com</p>
          </div>
        </div>
      </body>
      </html>
    `,
    text: `
Order in Progress

Hi {{customer_name}}, your order is being processed.

Order #{{order_number}}

Processing Started
Your order is currently being picked and packed in our warehouse. We expect to ship it within {{estimated_ship_days}} business days.

You'll receive another email with tracking information once your order ships.

{{#if special_instructions}}
Special Instructions: {{special_instructions}}
{{/if}}

Questions? Contact us at support@kctmenswear.com
    `
  },

  order_shipped: {
    subject: 'Your Order Has Shipped! - {{order_number}}',
    html: `
      <!DOCTYPE html>
      <html>
      <head>
        <meta charset="utf-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <title>Order Shipped</title>
        <style>
          body { font-family: Arial, sans-serif; line-height: 1.6; color: #333; }
          .container { max-width: 600px; margin: 0 auto; padding: 20px; }
          .header { background: #10b981; color: white; padding: 20px; text-align: center; }
          .content { padding: 20px; }
          .tracking-info { background: #ecfdf5; padding: 20px; border-radius: 5px; margin: 20px 0; text-align: center; }
          .tracking-button { display: inline-block; background: #10b981; color: white; padding: 12px 24px; text-decoration: none; border-radius: 5px; margin: 10px 0; }
          .footer { text-align: center; padding: 20px; color: #666; font-size: 14px; }
        </style>
      </head>
      <body>
        <div class="container">
          <div class="header">
            <h1>📦 Order Shipped!</h1>
            <p>Your package is on its way, {{customer_name}}</p>
          </div>
          
          <div class="content">
            <h2>Order #{{order_number}}</h2>
            
            <div class="tracking-info">
              <h3>Tracking Information</h3>
              <p><strong>Carrier:</strong> {{carrier}}</p>
              <p><strong>Tracking Number:</strong> {{tracking_number}}</p>
              <p><strong>Estimated Delivery:</strong> {{estimated_delivery}}</p>
              
              <a href="{{tracking_url}}" class="tracking-button">Track Your Package</a>
            </div>
            
            <h3>What's Next?</h3>
            <ul>
              <li>Your package will be delivered to: {{shipping_address.line1}}, {{shipping_address.city}}, {{shipping_address.state}}</li>
              <li>You'll receive updates as your package moves through the delivery network</li>
              <li>Most packages arrive within the estimated timeframe, but delays can occasionally occur</li>
            </ul>
            
            <p>Thank you for choosing KCT Menswear!</p>
          </div>
          
          <div class="footer">
            <p>Questions about your delivery? Contact us at support@kctmenswear.com</p>
          </div>
        </div>
      </body>
      </html>
    `,
    text: `
Order Shipped!

Your package is on its way, {{customer_name}}.

Order #{{order_number}}

Tracking Information:
Carrier: {{carrier}}
Tracking Number: {{tracking_number}}
Estimated Delivery: {{estimated_delivery}}

Track your package: {{tracking_url}}

What's Next?
- Your package will be delivered to: {{shipping_address.line1}}, {{shipping_address.city}}, {{shipping_address.state}}
- You'll receive updates as your package moves through the delivery network
- Most packages arrive within the estimated timeframe, but delays can occasionally occur

Thank you for choosing KCT Menswear!

Questions about your delivery? Contact us at support@kctmenswear.com
    `
  },

  order_delivered: {
    subject: 'Order Delivered - {{order_number}}',
    html: `
      <!DOCTYPE html>
      <html>
      <head>
        <meta charset="utf-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <title>Order Delivered</title>
        <style>
          body { font-family: Arial, sans-serif; line-height: 1.6; color: #333; }
          .container { max-width: 600px; margin: 0 auto; padding: 20px; }
          .header { background: #059669; color: white; padding: 20px; text-align: center; }
          .content { padding: 20px; }
          .delivery-confirmation { background: #ecfdf5; padding: 20px; border-radius: 5px; margin: 20px 0; text-align: center; }
          .review-button { display: inline-block; background: #2563eb; color: white; padding: 12px 24px; text-decoration: none; border-radius: 5px; margin: 10px 0; }
          .footer { text-align: center; padding: 20px; color: #666; font-size: 14px; }
        </style>
      </head>
      <body>
        <div class="container">
          <div class="header">
            <h1>🎉 Delivered!</h1>
            <p>Your order has arrived, {{customer_name}}</p>
          </div>
          
          <div class="content">
            <h2>Order #{{order_number}}</h2>
            
            <div class="delivery-confirmation">
              <h3>✅ Delivery Confirmed</h3>
              <p><strong>Delivered on:</strong> {{delivery_date}}</p>
              <p><strong>Location:</strong> {{delivery_location}}</p>
            </div>
            
            <h3>How was your experience?</h3>
            <p>We'd love to hear about your experience with your recent purchase. Your feedback helps us continue to improve.</p>
            
            <div style="text-align: center;">
              <a href="{{review_url}}" class="review-button">Leave a Review</a>
            </div>
            
            <h3>Need Help?</h3>
            <ul>
              <li>If you have any issues with your order, contact us within 30 days</li>
              <li>Keep your order number handy for faster support</li>
              <li>Check out our return policy if you need to make an exchange</li>
            </ul>
            
            <p>Thank you for being a valued customer!</p>
          </div>
          
          <div class="footer">
            <p>Questions? Contact us at support@kctmenswear.com</p>
          </div>
        </div>
      </body>
      </html>
    `,
    text: `
Delivered!

Your order has arrived, {{customer_name}}.

Order #{{order_number}}

Delivery Confirmed
Delivered on: {{delivery_date}}
Location: {{delivery_location}}

How was your experience?
We'd love to hear about your experience with your recent purchase. Your feedback helps us continue to improve.

Leave a review: {{review_url}}

Need Help?
- If you have any issues with your order, contact us within 30 days
- Keep your order number handy for faster support
- Check out our return policy if you need to make an exchange

Thank you for being a valued customer!

Questions? Contact us at support@kctmenswear.com
    `
  },

  order_cancelled: {
    subject: 'Order Cancelled - {{order_number}}',
    html: `
      <!DOCTYPE html>
      <html>
      <head>
        <meta charset="utf-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <title>Order Cancelled</title>
        <style>
          body { font-family: Arial, sans-serif; line-height: 1.6; color: #333; }
          .container { max-width: 600px; margin: 0 auto; padding: 20px; }
          .header { background: #dc2626; color: white; padding: 20px; text-align: center; }
          .content { padding: 20px; }
          .cancellation-info { background: #fef2f2; padding: 20px; border-radius: 5px; margin: 20px 0; }
          .footer { text-align: center; padding: 20px; color: #666; font-size: 14px; }
        </style>
      </head>
      <body>
        <div class="container">
          <div class="header">
            <h1>Order Cancelled</h1>
            <p>{{customer_name}}, your order has been cancelled</p>
          </div>
          
          <div class="content">
            <h2>Order #{{order_number}}</h2>
            
            <div class="cancellation-info">
              <h3>Cancellation Details</h3>
              <p><strong>Cancelled on:</strong> {{cancellation_date}}</p>
              {{#if cancellation_reason}}
              <p><strong>Reason:</strong> {{cancellation_reason}}</p>
              {{/if}}
              <p><strong>Refund Amount:</strong> \${{refund_amount}}</p>
            </div>
            
            <h3>What happens next?</h3>
            <ul>
              <li>Any charges will be refunded to your original payment method</li>
              <li>Refunds typically process within 3-5 business days</li>
              <li>You'll receive a separate email confirmation when the refund is processed</li>
            </ul>
            
            <p>We apologize for any inconvenience. If you have questions about this cancellation, please don't hesitate to contact us.</p>
          </div>
          
          <div class="footer">
            <p>Questions? Contact us at support@kctmenswear.com</p>
          </div>
        </div>
      </body>
      </html>
    `,
    text: `
Order Cancelled

{{customer_name}}, your order has been cancelled.

Order #{{order_number}}

Cancellation Details:
Cancelled on: {{cancellation_date}}
{{#if cancellation_reason}}Reason: {{cancellation_reason}}{{/if}}
Refund Amount: \${{refund_amount}}

What happens next?
- Any charges will be refunded to your original payment method
- Refunds typically process within 3-5 business days
- You'll receive a separate email confirmation when the refund is processed

We apologize for any inconvenience. If you have questions about this cancellation, please don't hesitate to contact us.

Questions? Contact us at support@kctmenswear.com
    `
  },

  order_delayed: {
    subject: 'Order Update - Delay Notification - {{order_number}}',
    html: `
      <!DOCTYPE html>
      <html>
      <head>
        <meta charset="utf-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <title>Order Delayed</title>
        <style>
          body { font-family: Arial, sans-serif; line-height: 1.6; color: #333; }
          .container { max-width: 600px; margin: 0 auto; padding: 20px; }
          .header { background: #f59e0b; color: white; padding: 20px; text-align: center; }
          .content { padding: 20px; }
          .delay-info { background: #fef3c7; padding: 20px; border-radius: 5px; margin: 20px 0; }
          .footer { text-align: center; padding: 20px; color: #666; font-size: 14px; }
        </style>
      </head>
      <body>
        <div class="container">
          <div class="header">
            <h1>Order Update</h1>
            <p>Important information about your order, {{customer_name}}</p>
          </div>
          
          <div class="content">
            <h2>Order #{{order_number}}</h2>
            
            <div class="delay-info">
              <h3>⏰ Delivery Delay</h3>
              <p>We want to keep you informed about your order status. Unfortunately, your order will be delayed.</p>
              <p><strong>Original Estimated Delivery:</strong> {{original_delivery_date}}</p>
              <p><strong>New Estimated Delivery:</strong> {{new_delivery_date}}</p>
              {{#if delay_reason}}
              <p><strong>Reason:</strong> {{delay_reason}}</p>
              {{/if}}
            </div>
            
            <h3>What we're doing</h3>
            <ul>
              <li>We're working closely with our shipping partners to get your order to you as quickly as possible</li>
              <li>We'll continue to monitor your shipment and provide updates</li>
              <li>Our customer service team is available if you have any concerns</li>
            </ul>
            
            <p>We sincerely apologize for this delay and appreciate your patience.</p>
          </div>
          
          <div class="footer">
            <p>Questions? Contact us at support@kctmenswear.com</p>
          </div>
        </div>
      </body>
      </html>
    `,
    text: `
Order Update

Important information about your order, {{customer_name}}.

Order #{{order_number}}

Delivery Delay
We want to keep you informed about your order status. Unfortunately, your order will be delayed.

Original Estimated Delivery: {{original_delivery_date}}
New Estimated Delivery: {{new_delivery_date}}
{{#if delay_reason}}Reason: {{delay_reason}}{{/if}}

What we're doing:
- We're working closely with our shipping partners to get your order to you as quickly as possible
- We'll continue to monitor your shipment and provide updates
- Our customer service team is available if you have any concerns

We sincerely apologize for this delay and appreciate your patience.

Questions? Contact us at support@kctmenswear.com
    `
  },

  refund_processed: {
    subject: 'Refund Processed - {{order_number}}',
    html: `
      <!DOCTYPE html>
      <html>
      <head>
        <meta charset="utf-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <title>Refund Processed</title>
        <style>
          body { font-family: Arial, sans-serif; line-height: 1.6; color: #333; }
          .container { max-width: 600px; margin: 0 auto; padding: 20px; }
          .header { background: #059669; color: white; padding: 20px; text-align: center; }
          .content { padding: 20px; }
          .refund-info { background: #ecfdf5; padding: 20px; border-radius: 5px; margin: 20px 0; }
          .footer { text-align: center; padding: 20px; color: #666; font-size: 14px; }
        </style>
      </head>
      <body>
        <div class="container">
          <div class="header">
            <h1>💳 Refund Processed</h1>
            <p>Your refund has been processed, {{customer_name}}</p>
          </div>
          
          <div class="content">
            <h2>Order #{{order_number}}</h2>
            
            <div class="refund-info">
              <h3>Refund Details</h3>
              <p><strong>Refund Amount:</strong> \${{refund_amount}}</p>
              <p><strong>Processed Date:</strong> {{processed_date}}</p>
              <p><strong>Refund Method:</strong> {{refund_method}}</p>
              <p><strong>Transaction ID:</strong> {{transaction_id}}</p>
            </div>
            
            <h3>When will I see the refund?</h3>
            <ul>
              <li><strong>Credit/Debit Cards:</strong> 3-5 business days</li>
              <li><strong>PayPal:</strong> 1-2 business days</li>
              <li><strong>Bank Transfer:</strong> 5-7 business days</li>
            </ul>
            
            <p>The exact timing depends on your bank or payment provider. If you don't see the refund after the expected timeframe, please contact your bank first, then reach out to us if needed.</p>
          </div>
          
          <div class="footer">
            <p>Questions? Contact us at support@kctmenswear.com</p>
          </div>
        </div>
      </body>
      </html>
    `,
    text: `
Refund Processed

Your refund has been processed, {{customer_name}}.

Order #{{order_number}}

Refund Details:
Refund Amount: \${{refund_amount}}
Processed Date: {{processed_date}}
Refund Method: {{refund_method}}
Transaction ID: {{transaction_id}}

When will I see the refund?
- Credit/Debit Cards: 3-5 business days
- PayPal: 1-2 business days
- Bank Transfer: 5-7 business days

The exact timing depends on your bank or payment provider. If you don't see the refund after the expected timeframe, please contact your bank first, then reach out to us if needed.

Questions? Contact us at support@kctmenswear.com
    `
  },

  return_received: {
    subject: 'Return Received - {{order_number}}',
    html: `
      <!DOCTYPE html>
      <html>
      <head>
        <meta charset="utf-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <title>Return Received</title>
        <style>
          body { font-family: Arial, sans-serif; line-height: 1.6; color: #333; }
          .container { max-width: 600px; margin: 0 auto; padding: 20px; }
          .header { background: #2563eb; color: white; padding: 20px; text-align: center; }
          .content { padding: 20px; }
          .return-info { background: #eff6ff; padding: 20px; border-radius: 5px; margin: 20px 0; }
          .footer { text-align: center; padding: 20px; color: #666; font-size: 14px; }
        </style>
      </head>
      <body>
        <div class="container">
          <div class="header">
            <h1>📦 Return Received</h1>
            <p>We've received your return, {{customer_name}}</p>
          </div>
          
          <div class="content">
            <h2>Order #{{order_number}}</h2>
            
            <div class="return-info">
              <h3>Return Details</h3>
              <p><strong>Return Number:</strong> {{return_number}}</p>
              <p><strong>Received Date:</strong> {{received_date}}</p>
              <p><strong>Items Returned:</strong> {{item_count}} item(s)</p>
            </div>
            
            <h3>What happens next?</h3>
            <ol>
              <li><strong>Inspection:</strong> We'll inspect your returned items (1-2 business days)</li>
              <li><strong>Processing:</strong> Once approved, we'll process your refund or exchange</li>
              <li><strong>Notification:</strong> You'll receive an email confirmation when complete</li>
            </ol>
            
            <p>Most returns are processed within 3-5 business days of receipt. We'll keep you updated throughout the process.</p>
          </div>
          
          <div class="footer">
            <p>Questions about your return? Contact us at support@kctmenswear.com</p>
          </div>
        </div>
      </body>
      </html>
    `,
    text: `
Return Received

We've received your return, {{customer_name}}.

Order #{{order_number}}

Return Details:
Return Number: {{return_number}}
Received Date: {{received_date}}
Items Returned: {{item_count}} item(s)

What happens next?
1. Inspection: We'll inspect your returned items (1-2 business days)
2. Processing: Once approved, we'll process your refund or exchange
3. Notification: You'll receive an email confirmation when complete

Most returns are processed within 3-5 business days of receipt. We'll keep you updated throughout the process.

Questions about your return? Contact us at support@kctmenswear.com
    `
  },

  custom: {
    subject: '{{custom_subject}}',
    html: '{{custom_html}}',
    text: '{{custom_text}}'
  }
};

// ============================================
// NOTIFICATION FUNCTIONS
// ============================================

/**
 * Send order notification
 */
export async function sendOrderNotification(request: NotificationRequest): Promise<void> {
  try {
    // Get order details
    const { data: order, error: orderError } = await supabase
      .from('orders')
      .select(`
        *,
        customers!left(*),
        order_items!left(*)
      `)
      .eq('id', request.order_id)
      .single();

    if (orderError) throw orderError;

    // Prepare template data
    const templateData = {
      ...request.template_data,
      order_number: order.order_number,
      customer_name: order.customers?.first_name ? 
        `${order.customers.first_name} ${order.customers.last_name}` : 
        'Valued Customer',
      subtotal: (order.subtotal / 100).toFixed(2),
      tax_amount: (order.tax_amount / 100).toFixed(2),
      shipping_amount: (order.shipping_amount / 100).toFixed(2),
      total_amount: (order.total_amount / 100).toFixed(2),
      shipping_address: order.shipping_address,
      items: order.order_items?.map((item: any) => ({
        ...item,
        total_price: (item.total_price / 100).toFixed(2)
      })) || []
    };

    // Generate email content
    const template = EMAIL_TEMPLATES[request.notification_type];
    const subject = compileTemplate(template.subject, templateData);
    const htmlContent = compileTemplate(template.html, templateData);
    const textContent = compileTemplate(template.text, templateData);

    // Create notification record
    const { data: notification, error: notificationError } = await supabase
      .from('order_notifications')
      .insert({
        order_id: request.order_id,
        notification_type: request.notification_type,
        delivery_method: request.delivery_method,
        recipient_email: request.recipient_email || order.customers?.email || order.guest_email,
        recipient_phone: request.recipient_phone,
        subject,
        message: htmlContent,
        template_id: request.notification_type,
        template_data: templateData,
        status: 'pending',
        scheduled_for: request.scheduled_for || new Date().toISOString()
      })
      .select()
      .single();

    if (notificationError) throw notificationError;

    // Send the notification based on delivery method
    switch (request.delivery_method) {
      case 'email':
        await sendEmail(notification, { subject, html: htmlContent, text: textContent });
        break;
      case 'sms':
        await sendSMS(notification, textContent);
        break;
      case 'push':
        await sendPushNotification(notification);
        break;
    }

  } catch (error) {
    console.error('Error sending notification:', error);
    throw error;
  }
}

/**
 * Send email notification
 */
async function sendEmail(notification: any, content: EmailTemplate): Promise<void> {
  try {
    // In production, integrate with email service (Resend, SendGrid, etc.)
    // For now, we'll just log and mark as sent
    console.log('Email would be sent:', {
      to: notification.recipient_email,
      subject: content.subject,
      html: content.html.substring(0, 100) + '...',
      text: content.text.substring(0, 100) + '...'
    });

    // Mark as sent
    await supabase
      .from('order_notifications')
      .update({
        status: 'sent',
        sent_at: new Date().toISOString()
      })
      .eq('id', notification.id);

    // TODO: Replace with actual email service integration
    // Example with Resend:
    // const { data, error } = await resend.emails.send({
    //   from: 'orders@kctmenswear.com',
    //   to: notification.recipient_email,
    //   subject: content.subject,
    //   html: content.html,
    //   text: content.text
    // });

  } catch (error) {
    console.error('Error sending email:', error);
    
    // Mark as failed
    await supabase
      .from('order_notifications')
      .update({
        status: 'failed',
        error_message: error instanceof Error ? error.message : 'Unknown error'
      })
      .eq('id', notification.id);
      
    throw error;
  }
}

/**
 * Send SMS notification
 */
async function sendSMS(notification: any, message: string): Promise<void> {
  try {
    // In production, integrate with SMS service (Twilio, etc.)
    console.log('SMS would be sent:', {
      to: notification.recipient_phone,
      message: message.substring(0, 100) + '...'
    });

    // Mark as sent
    await supabase
      .from('order_notifications')
      .update({
        status: 'sent',
        sent_at: new Date().toISOString()
      })
      .eq('id', notification.id);

    // TODO: Replace with actual SMS service integration

  } catch (error) {
    console.error('Error sending SMS:', error);
    
    await supabase
      .from('order_notifications')
      .update({
        status: 'failed',
        error_message: error instanceof Error ? error.message : 'Unknown error'
      })
      .eq('id', notification.id);
      
    throw error;
  }
}

/**
 * Send push notification
 */
async function sendPushNotification(notification: any): Promise<void> {
  try {
    // In production, integrate with push notification service
    console.log('Push notification would be sent:', {
      user: notification.recipient_user_id,
      title: notification.subject,
      body: notification.message.substring(0, 100) + '...'
    });

    // Mark as sent
    await supabase
      .from('order_notifications')
      .update({
        status: 'sent',
        sent_at: new Date().toISOString()
      })
      .eq('id', notification.id);

  } catch (error) {
    console.error('Error sending push notification:', error);
    
    await supabase
      .from('order_notifications')
      .update({
        status: 'failed',
        error_message: error instanceof Error ? error.message : 'Unknown error'
      })
      .eq('id', notification.id);
      
    throw error;
  }
}

/**
 * Simple template compilation (replace with Handlebars in production)
 */
function compileTemplate(template: string, data: Record<string, any>): string {
  let compiled = template;
  
  // Replace simple variables {{variable}}
  Object.keys(data).forEach(key => {
    const regex = new RegExp(`\\{\\{${key}\\}\\}`, 'g');
    compiled = compiled.replace(regex, String(data[key] || ''));
  });
  
  // Handle nested object properties {{object.property}}
  const nestedRegex = /\{\{([^}]+\.[^}]+)\}\}/g;
  compiled = compiled.replace(nestedRegex, (match, path) => {
    const value = path.split('.').reduce((obj: any, key: string) => obj?.[key], data);
    return String(value || '');
  });
  
  // Handle simple conditionals {{#if condition}}content{{/if}}
  const ifRegex = /\{\{#if\s+([^}]+)\}\}(.*?)\{\{\/if\}\}/gs;
  compiled = compiled.replace(ifRegex, (match, condition, content) => {
    const value = condition.split('.').reduce((obj: any, key: string) => obj?.[key], data);
    return value ? content : '';
  });
  
  // Handle simple loops {{#each array}}content{{/each}}
  const eachRegex = /\{\{#each\s+([^}]+)\}\}(.*?)\{\{\/each\}\}/gs;
  compiled = compiled.replace(eachRegex, (match, arrayPath, itemTemplate) => {
    const array = arrayPath.split('.').reduce((obj: any, key: string) => obj?.[key], data);
    if (!Array.isArray(array)) return '';
    
    return array.map(item => {
      let itemContent = itemTemplate;
      Object.keys(item).forEach(key => {
        const regex = new RegExp(`\\{\\{${key}\\}\\}`, 'g');
        itemContent = itemContent.replace(regex, String(item[key] || ''));
      });
      return itemContent;
    }).join('');
  });
  
  return compiled;
}

// ============================================
// NOTIFICATION PREFERENCES
// ============================================

/**
 * Get customer notification preferences
 */
export async function getNotificationPreferences(customerId: string): Promise<any> {
  try {
    const { data, error } = await supabase
      .from('notification_preferences')
      .select('*')
      .eq('customer_id', customerId)
      .single();

    if (error && error.code !== 'PGRST116') throw error;

    // Return default preferences if none exist
    return data || {
      email_order_confirmation: true,
      email_order_shipped: true,
      email_order_delivered: true,
      email_marketing: false,
      sms_order_shipped: false,
      sms_order_delivered: false,
      sms_marketing: false,
      push_order_updates: true,
      push_marketing: false
    };
  } catch (error) {
    console.error('Error getting notification preferences:', error);
    throw error;
  }
}

/**
 * Update customer notification preferences
 */
export async function updateNotificationPreferences(
  customerId: string, 
  preferences: Record<string, boolean>
): Promise<void> {
  try {
    const { error } = await supabase
      .from('notification_preferences')
      .upsert({
        customer_id: customerId,
        ...preferences,
        updated_at: new Date().toISOString()
      });

    if (error) throw error;
  } catch (error) {
    console.error('Error updating notification preferences:', error);
    throw error;
  }
}

// ============================================
// NOTIFICATION QUEUE MANAGEMENT
// ============================================

/**
 * Process pending notifications
 */
export async function processPendingNotifications(): Promise<void> {
  try {
    const { data: pendingNotifications, error } = await supabase
      .from('order_notifications')
      .select('*')
      .eq('status', 'pending')
      .lte('scheduled_for', new Date().toISOString())
      .limit(50);

    if (error) throw error;

    for (const notification of pendingNotifications || []) {
      try {
        // Process the notification based on delivery method
        const template = EMAIL_TEMPLATES[notification.notification_type as NotificationType];
        const content = {
          subject: notification.subject,
          html: notification.message,
          text: compileTemplate(template.text, notification.template_data)
        };

        switch (notification.delivery_method) {
          case 'email':
            await sendEmail(notification, content);
            break;
          case 'sms':
            await sendSMS(notification, content.text);
            break;
          case 'push':
            await sendPushNotification(notification);
            break;
        }
      } catch (notificationError) {
        console.error(`Error processing notification ${notification.id}:`, notificationError);
      }
    }
  } catch (error) {
    console.error('Error processing pending notifications:', error);
  }
}

/**
 * Retry failed notifications
 */
export async function retryFailedNotifications(): Promise<void> {
  try {
    const { data: failedNotifications, error } = await supabase
      .from('order_notifications')
      .select('*')
      .eq('status', 'failed')
      .lt('retry_count', 3)
      .order('created_at', { ascending: true })
      .limit(20);

    if (error) throw error;

    for (const notification of failedNotifications || []) {
      try {
        // Increment retry count
        await supabase
          .from('order_notifications')
          .update({
            retry_count: notification.retry_count + 1,
            status: 'pending'
          })
          .eq('id', notification.id);

        // The notification will be picked up by processPendingNotifications
      } catch (retryError) {
        console.error(`Error setting up retry for notification ${notification.id}:`, retryError);
      }
    }
  } catch (error) {
    console.error('Error retrying failed notifications:', error);
  }
}