import { supabase } from '@/lib/supabase-client';

// Email template types
export type EmailTemplate = 
  | 'order_confirmation'
  | 'order_shipped'
  | 'order_delivered'
  | 'order_cancelled'
  | 'refund_processed'
  | 'low_stock_alert'
  | 'daily_report'
  | 'customer_inquiry'
  | 'welcome';

// Email configuration
export interface EmailConfig {
  to: string | string[];
  subject: string;
  template: EmailTemplate;
  data: Record<string, any>;
  cc?: string[];
  bcc?: string[];
  replyTo?: string;
  attachments?: Array<{
    filename: string;
    content: string | Buffer;
    contentType?: string;
  }>;
}

// Email templates
const EMAIL_TEMPLATES: Record<EmailTemplate, (data: any) => { subject: string; html: string; text: string }> = {
  order_confirmation: (data) => ({
    subject: `Order Confirmation - #${data.orderNumber}`,
    html: `
      <!DOCTYPE html>
      <html>
        <head>
          <style>
            body { font-family: Arial, sans-serif; line-height: 1.6; color: #333; }
            .container { max-width: 600px; margin: 0 auto; padding: 20px; }
            .header { background: #000; color: white; padding: 20px; text-align: center; }
            .content { padding: 20px; background: #f9f9f9; }
            .order-details { background: white; padding: 15px; margin: 20px 0; border-radius: 5px; }
            .item { border-bottom: 1px solid #eee; padding: 10px 0; }
            .total { font-size: 18px; font-weight: bold; margin-top: 20px; }
            .footer { text-align: center; padding: 20px; color: #666; font-size: 12px; }
            .button { display: inline-block; padding: 12px 30px; background: #000; color: white; text-decoration: none; border-radius: 5px; margin: 20px 0; }
          </style>
        </head>
        <body>
          <div class="container">
            <div class="header">
              <h1>KCT Menswear</h1>
              <p>Thank You for Your Order!</p>
            </div>
            <div class="content">
              <h2>Hi ${data.customerName},</h2>
              <p>Your order has been confirmed and is being processed.</p>
              
              <div class="order-details">
                <h3>Order #${data.orderNumber}</h3>
                <p>Date: ${new Date(data.createdAt).toLocaleDateString()}</p>
                
                <h4>Items:</h4>
                ${data.items.map((item: any) => `
                  <div class="item">
                    <strong>${item.name}</strong><br>
                    Size: ${item.size || 'N/A'} | Color: ${item.color || 'N/A'}<br>
                    Quantity: ${item.quantity} × $${(item.unit_price / 100).toFixed(2)}
                  </div>
                `).join('')}
                
                <div class="total">
                  Total: $${(data.totalAmount / 100).toFixed(2)}
                </div>
              </div>
              
              <h4>Shipping Address:</h4>
              <p>
                ${data.shippingAddress.line1}<br>
                ${data.shippingAddress.line2 ? data.shippingAddress.line2 + '<br>' : ''}
                ${data.shippingAddress.city}, ${data.shippingAddress.state} ${data.shippingAddress.postal_code}<br>
                ${data.shippingAddress.country}
              </p>
              
              <center>
                <a href="${data.orderUrl}" class="button">View Order</a>
              </center>
            </div>
            <div class="footer">
              <p>© 2025 KCT Menswear. All rights reserved.</p>
              <p>Questions? Contact us at support@kctmenswear.com</p>
            </div>
          </div>
        </body>
      </html>
    `,
    text: `
      Order Confirmation - #${data.orderNumber}
      
      Hi ${data.customerName},
      
      Your order has been confirmed and is being processed.
      
      Order Details:
      ${data.items.map((item: any) => `- ${item.name} (${item.quantity}x)`).join('\n')}
      
      Total: $${(data.totalAmount / 100).toFixed(2)}
      
      View your order: ${data.orderUrl}
      
      Thank you for shopping with KCT Menswear!
    `
  }),

  order_shipped: (data) => ({
    subject: `Your Order Has Shipped - #${data.orderNumber}`,
    html: `
      <!DOCTYPE html>
      <html>
        <head>
          <style>
            body { font-family: Arial, sans-serif; line-height: 1.6; color: #333; }
            .container { max-width: 600px; margin: 0 auto; padding: 20px; }
            .header { background: #000; color: white; padding: 20px; text-align: center; }
            .content { padding: 20px; background: #f9f9f9; }
            .tracking-box { background: white; padding: 20px; margin: 20px 0; border-radius: 5px; border: 2px solid #4CAF50; }
            .button { display: inline-block; padding: 12px 30px; background: #4CAF50; color: white; text-decoration: none; border-radius: 5px; margin: 20px 0; }
            .footer { text-align: center; padding: 20px; color: #666; font-size: 12px; }
          </style>
        </head>
        <body>
          <div class="container">
            <div class="header">
              <h1>Your Order is On Its Way!</h1>
            </div>
            <div class="content">
              <h2>Hi ${data.customerName},</h2>
              <p>Great news! Your order #${data.orderNumber} has been shipped.</p>
              
              <div class="tracking-box">
                <h3>📦 Tracking Information</h3>
                <p><strong>Carrier:</strong> ${data.carrier}</p>
                <p><strong>Tracking Number:</strong> ${data.trackingNumber}</p>
                <p><strong>Estimated Delivery:</strong> ${data.estimatedDelivery || 'Within 3-5 business days'}</p>
                
                <center>
                  <a href="${data.trackingUrl}" class="button">Track Your Package</a>
                </center>
              </div>
              
              <p>You'll receive another email once your package has been delivered.</p>
            </div>
            <div class="footer">
              <p>© 2025 KCT Menswear. All rights reserved.</p>
            </div>
          </div>
        </body>
      </html>
    `,
    text: `
      Your Order Has Shipped!
      
      Hi ${data.customerName},
      
      Your order #${data.orderNumber} has been shipped.
      
      Tracking: ${data.trackingNumber}
      Carrier: ${data.carrier}
      
      Track your package: ${data.trackingUrl}
    `
  }),

  order_cancelled: (data) => ({
    subject: `Order Cancelled - #${data.orderNumber}`,
    html: `
      <!DOCTYPE html>
      <html>
        <head>
          <style>
            body { font-family: Arial, sans-serif; line-height: 1.6; color: #333; }
            .container { max-width: 600px; margin: 0 auto; padding: 20px; }
            .header { background: #f44336; color: white; padding: 20px; text-align: center; }
            .content { padding: 20px; background: #f9f9f9; }
            .footer { text-align: center; padding: 20px; color: #666; font-size: 12px; }
          </style>
        </head>
        <body>
          <div class="container">
            <div class="header">
              <h1>Order Cancelled</h1>
            </div>
            <div class="content">
              <h2>Hi ${data.customerName},</h2>
              <p>Your order #${data.orderNumber} has been cancelled.</p>
              <p><strong>Reason:</strong> ${data.reason || 'Customer request'}</p>
              <p>If you paid for this order, a refund will be processed within 3-5 business days.</p>
              <p>If you have any questions, please contact our support team.</p>
            </div>
            <div class="footer">
              <p>© 2025 KCT Menswear. All rights reserved.</p>
            </div>
          </div>
        </body>
      </html>
    `,
    text: `
      Order Cancelled - #${data.orderNumber}
      
      Hi ${data.customerName},
      
      Your order has been cancelled.
      Reason: ${data.reason || 'Customer request'}
      
      A refund will be processed if applicable.
    `
  }),

  refund_processed: (data) => ({
    subject: `Refund Processed - #${data.orderNumber}`,
    html: `
      <!DOCTYPE html>
      <html>
        <head>
          <style>
            body { font-family: Arial, sans-serif; line-height: 1.6; color: #333; }
            .container { max-width: 600px; margin: 0 auto; padding: 20px; }
            .header { background: #4CAF50; color: white; padding: 20px; text-align: center; }
            .content { padding: 20px; background: #f9f9f9; }
            .refund-box { background: white; padding: 20px; margin: 20px 0; border-radius: 5px; border: 2px solid #4CAF50; }
            .footer { text-align: center; padding: 20px; color: #666; font-size: 12px; }
          </style>
        </head>
        <body>
          <div class="container">
            <div class="header">
              <h1>Refund Processed</h1>
            </div>
            <div class="content">
              <h2>Hi ${data.customerName},</h2>
              <p>Your refund has been successfully processed.</p>
              
              <div class="refund-box">
                <h3>Refund Details</h3>
                <p><strong>Order Number:</strong> #${data.orderNumber}</p>
                <p><strong>Refund Amount:</strong> $${(data.refundAmount / 100).toFixed(2)}</p>
                <p><strong>Reason:</strong> ${data.reason}</p>
                <p><strong>Processing Time:</strong> 3-5 business days</p>
              </div>
              
              <p>The refund will appear on your original payment method within 3-5 business days.</p>
            </div>
            <div class="footer">
              <p>© 2025 KCT Menswear. All rights reserved.</p>
            </div>
          </div>
        </body>
      </html>
    `,
    text: `
      Refund Processed - #${data.orderNumber}
      
      Hi ${data.customerName},
      
      Your refund of $${(data.refundAmount / 100).toFixed(2)} has been processed.
      
      It will appear on your original payment method within 3-5 business days.
    `
  }),

  low_stock_alert: (data) => ({
    subject: `Low Stock Alert - ${data.productName}`,
    html: `
      <!DOCTYPE html>
      <html>
        <head>
          <style>
            body { font-family: Arial, sans-serif; line-height: 1.6; color: #333; }
            .container { max-width: 600px; margin: 0 auto; padding: 20px; }
            .header { background: #ff9800; color: white; padding: 20px; text-align: center; }
            .content { padding: 20px; background: #f9f9f9; }
            .alert-box { background: #fff3e0; padding: 15px; margin: 20px 0; border-left: 4px solid #ff9800; }
            .button { display: inline-block; padding: 12px 30px; background: #ff9800; color: white; text-decoration: none; border-radius: 5px; margin: 20px 0; }
          </style>
        </head>
        <body>
          <div class="container">
            <div class="header">
              <h1>⚠️ Low Stock Alert</h1>
            </div>
            <div class="content">
              <div class="alert-box">
                <h3>${data.productName}</h3>
                <p><strong>SKU:</strong> ${data.sku}</p>
                <p><strong>Current Stock:</strong> ${data.currentStock} units</p>
                <p><strong>Threshold:</strong> ${data.threshold} units</p>
              </div>
              
              <p>This product is running low on inventory. Consider reordering soon.</p>
              
              <center>
                <a href="${data.adminUrl}/admin/inventory" class="button">Manage Inventory</a>
              </center>
            </div>
          </div>
        </body>
      </html>
    `,
    text: `
      Low Stock Alert
      
      Product: ${data.productName}
      SKU: ${data.sku}
      Current Stock: ${data.currentStock} units
      
      Please reorder this product soon.
    `
  }),

  daily_report: (data) => ({
    subject: `Daily Report - ${new Date().toLocaleDateString()}`,
    html: `
      <!DOCTYPE html>
      <html>
        <head>
          <style>
            body { font-family: Arial, sans-serif; line-height: 1.6; color: #333; }
            .container { max-width: 600px; margin: 0 auto; padding: 20px; }
            .header { background: #000; color: white; padding: 20px; text-align: center; }
            .content { padding: 20px; background: #f9f9f9; }
            .stat-box { background: white; padding: 15px; margin: 10px 0; border-radius: 5px; display: inline-block; width: 45%; margin-right: 2%; }
            .footer { text-align: center; padding: 20px; color: #666; font-size: 12px; }
            table { width: 100%; border-collapse: collapse; margin: 20px 0; }
            th, td { padding: 10px; text-align: left; border-bottom: 1px solid #ddd; }
            th { background: #f0f0f0; }
          </style>
        </head>
        <body>
          <div class="container">
            <div class="header">
              <h1>Daily Business Report</h1>
              <p>${new Date().toLocaleDateString('en-US', { weekday: 'long', year: 'numeric', month: 'long', day: 'numeric' })}</p>
            </div>
            <div class="content">
              <h2>Today's Summary</h2>
              
              <div>
                <div class="stat-box">
                  <h3>📦 Orders</h3>
                  <p style="font-size: 24px; margin: 5px 0;">${data.ordersToday}</p>
                </div>
                <div class="stat-box">
                  <h3>💰 Revenue</h3>
                  <p style="font-size: 24px; margin: 5px 0;">$${data.revenueToday.toFixed(2)}</p>
                </div>
              </div>
              
              <h3>Order Breakdown</h3>
              <table>
                <tr>
                  <th>Status</th>
                  <th>Count</th>
                </tr>
                <tr>
                  <td>Pending</td>
                  <td>${data.pendingOrders}</td>
                </tr>
                <tr>
                  <td>Processing</td>
                  <td>${data.processingOrders}</td>
                </tr>
                <tr>
                  <td>Shipped Today</td>
                  <td>${data.shippedToday}</td>
                </tr>
              </table>
              
              ${data.lowStockProducts.length > 0 ? `
                <h3>⚠️ Low Stock Products</h3>
                <ul>
                  ${data.lowStockProducts.map((p: any) => `<li>${p.name} - ${p.stock} units left</li>`).join('')}
                </ul>
              ` : ''}
              
              ${data.pendingRefunds > 0 ? `
                <h3>📋 Pending Actions</h3>
                <ul>
                  <li>${data.pendingRefunds} refund requests pending approval</li>
                </ul>
              ` : ''}
            </div>
            <div class="footer">
              <p>This is an automated report from KCT Menswear Admin System</p>
            </div>
          </div>
        </body>
      </html>
    `,
    text: `
      Daily Report - ${new Date().toLocaleDateString()}
      
      Orders Today: ${data.ordersToday}
      Revenue Today: $${data.revenueToday.toFixed(2)}
      
      Pending Orders: ${data.pendingOrders}
      Processing Orders: ${data.processingOrders}
      Shipped Today: ${data.shippedToday}
      
      ${data.lowStockProducts.length > 0 ? 'Low stock products need attention.' : ''}
      ${data.pendingRefunds > 0 ? `${data.pendingRefunds} refunds pending.` : ''}
    `
  }),

  order_delivered: (data) => ({
    subject: `Your Order Has Been Delivered - #${data.orderNumber}`,
    html: `
      <!DOCTYPE html>
      <html>
        <body>
          <div style="max-width: 600px; margin: 0 auto; padding: 20px;">
            <h1>Order Delivered! 🎉</h1>
            <p>Hi ${data.customerName},</p>
            <p>Your order #${data.orderNumber} has been delivered.</p>
            <p>We hope you love your purchase!</p>
          </div>
        </body>
      </html>
    `,
    text: `Order Delivered! Your order #${data.orderNumber} has been delivered.`
  }),

  customer_inquiry: (data) => ({
    subject: `Customer Inquiry - ${data.subject}`,
    html: `<p>From: ${data.email}</p><p>Message: ${data.message}</p>`,
    text: `From: ${data.email}\nMessage: ${data.message}`
  }),

  welcome: (data) => ({
    subject: 'Welcome to KCT Menswear!',
    html: `
      <!DOCTYPE html>
      <html>
        <body>
          <div style="max-width: 600px; margin: 0 auto; padding: 20px;">
            <h1>Welcome to KCT Menswear!</h1>
            <p>Hi ${data.name},</p>
            <p>Thank you for joining our exclusive community.</p>
          </div>
        </body>
      </html>
    `,
    text: `Welcome to KCT Menswear! Thank you for joining us, ${data.name}.`
  })
};

/**
 * Send email using Resend (via Edge Function)
 */
export async function sendEmail(config: EmailConfig): Promise<boolean> {
  try {
    // Get the template
    const template = EMAIL_TEMPLATES[config.template];
    if (!template) {
      throw new Error(`Unknown email template: ${config.template}`);
    }

    const emailContent = template(config.data);

    // Call the Edge Function to send email
    const { data, error } = await supabase.functions.invoke('send-email', {
      body: {
        to: config.to,
        subject: config.subject || emailContent.subject,
        html: emailContent.html,
        text: emailContent.text,
        cc: config.cc,
        bcc: config.bcc,
        replyTo: config.replyTo,
        attachments: config.attachments
      }
    });

    if (error) throw error;

    // Log email sent
    await logEmail({
      to: Array.isArray(config.to) ? config.to.join(', ') : config.to,
      subject: emailContent.subject,
      template: config.template,
      status: 'sent',
      metadata: config.data
    });

    return true;
  } catch (error) {
    console.error('Error sending email:', error);
    
    // Log failed email
    await logEmail({
      to: Array.isArray(config.to) ? config.to.join(', ') : config.to,
      subject: config.subject,
      template: config.template,
      status: 'failed',
      error: error.message,
      metadata: config.data
    });

    return false;
  }
}

/**
 * Log email activity
 */
async function logEmail(log: {
  to: string;
  subject: string;
  template: string;
  status: 'sent' | 'failed';
  error?: string;
  metadata?: any;
}) {
  try {
    await supabase.from('email_logs').insert({
      ...log,
      created_at: new Date().toISOString()
    });
  } catch (error) {
    console.error('Error logging email:', error);
  }
}

/**
 * Send order confirmation email
 */
export async function sendOrderConfirmation(orderId: string) {
  try {
    // Get order details
    const { data: order } = await supabase
      .from('orders')
      .select(`
        *,
        customers!left(first_name, last_name, email)
      `)
      .eq('id', orderId)
      .single();

    if (!order) return false;

    const customerEmail = order.customers?.email || order.guest_email;
    const customerName = order.customers 
      ? `${order.customers.first_name} ${order.customers.last_name}`
      : 'Valued Customer';

    return await sendEmail({
      to: customerEmail,
      subject: `Order Confirmation - #${order.order_number}`,
      template: 'order_confirmation',
      data: {
        orderNumber: order.order_number,
        customerName,
        items: order.items || [],
        totalAmount: order.total_amount,
        shippingAddress: order.shipping_address,
        createdAt: order.created_at,
        orderUrl: `https://kctmenswear.com/orders/${order.order_number}`
      }
    });
  } catch (error) {
    console.error('Error sending order confirmation:', error);
    return false;
  }
}

/**
 * Send shipping notification
 */
export async function sendShippingNotification(orderId: string) {
  try {
    const { data: order } = await supabase
      .from('orders')
      .select(`
        *,
        customers!left(first_name, last_name, email)
      `)
      .eq('id', orderId)
      .single();

    if (!order || !order.tracking_number) return false;

    const customerEmail = order.customers?.email || order.guest_email;
    const customerName = order.customers 
      ? `${order.customers.first_name} ${order.customers.last_name}`
      : 'Valued Customer';

    // Generate tracking URL based on carrier
    const trackingUrl = getTrackingUrl(order.carrier_name, order.tracking_number);

    return await sendEmail({
      to: customerEmail,
      subject: `Your Order Has Shipped - #${order.order_number}`,
      template: 'order_shipped',
      data: {
        orderNumber: order.order_number,
        customerName,
        carrier: order.carrier_name || 'USPS',
        trackingNumber: order.tracking_number,
        trackingUrl,
        estimatedDelivery: order.estimated_delivery
      }
    });
  } catch (error) {
    console.error('Error sending shipping notification:', error);
    return false;
  }
}

/**
 * Get tracking URL for carrier
 */
function getTrackingUrl(carrier: string, trackingNumber: string): string {
  const carriers: Record<string, string> = {
    usps: `https://tools.usps.com/go/TrackConfirmAction?qtc_tLabels1=${trackingNumber}`,
    ups: `https://www.ups.com/track?tracknum=${trackingNumber}`,
    fedex: `https://www.fedex.com/fedextrack/?tracknumbers=${trackingNumber}`,
    dhl: `https://www.dhl.com/en/express/tracking.html?AWB=${trackingNumber}`
  };

  return carriers[carrier?.toLowerCase()] || '#';
}

/**
 * Send low stock alert
 */
export async function sendLowStockAlert(productId: string, currentStock: number) {
  try {
    const { data: product } = await supabase
      .from('products')
      .select('name, sku')
      .eq('id', productId)
      .single();

    if (!product) return false;

    // Send to admin email (configure this)
    return await sendEmail({
      to: 'admin@kctmenswear.com',
      subject: `Low Stock Alert - ${product.name}`,
      template: 'low_stock_alert',
      data: {
        productName: product.name,
        sku: product.sku,
        currentStock,
        threshold: 10,
        adminUrl: 'https://admin.kctmenswear.com'
      }
    });
  } catch (error) {
    console.error('Error sending low stock alert:', error);
    return false;
  }
}

/**
 * Send daily report
 */
export async function sendDailyReport() {
  try {
    const today = new Date();
    today.setHours(0, 0, 0, 0);

    // Get today's orders
    const { data: orders } = await supabase
      .from('orders')
      .select('status, total_amount')
      .gte('created_at', today.toISOString());

    // Get low stock products
    const { data: lowStock } = await supabase
      .from('inventory')
      .select('*, product_variants!inner(*, products!inner(name, sku))')
      .lt('available_quantity', 10);

    // Get pending refunds
    const { data: refunds } = await supabase
      .from('refund_requests')
      .select('id')
      .eq('status', 'pending');

    const reportData = {
      ordersToday: orders?.length || 0,
      revenueToday: (orders?.reduce((sum, o) => sum + o.total_amount, 0) || 0) / 100,
      pendingOrders: orders?.filter(o => o.status === 'pending').length || 0,
      processingOrders: orders?.filter(o => o.status === 'processing').length || 0,
      shippedToday: orders?.filter(o => o.status === 'shipped').length || 0,
      lowStockProducts: lowStock?.map(item => ({
        name: item.product_variants.products.name,
        stock: item.available_quantity
      })) || [],
      pendingRefunds: refunds?.length || 0
    };

    return await sendEmail({
      to: 'admin@kctmenswear.com',
      subject: `Daily Report - ${today.toLocaleDateString()}`,
      template: 'daily_report',
      data: reportData
    });
  } catch (error) {
    console.error('Error sending daily report:', error);
    return false;
  }
}