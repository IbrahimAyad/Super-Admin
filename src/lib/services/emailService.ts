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
  | 'welcome'
  | 'email_verification'
  | 'password_reset'
  | 'account_locked'
  | 'suspicious_activity'
  | 'password_changed'
  | 'two_factor_enabled'
  | 'security_question_reset'
  | 'backup_email_verification';

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
  }),

  email_verification: (data) => ({
    subject: 'Verify Your Email Address - KCT Admin',
    html: `
      <!DOCTYPE html>
      <html>
        <head>
          <style>
            body { font-family: Arial, sans-serif; line-height: 1.6; color: #333; }
            .container { max-width: 600px; margin: 0 auto; padding: 20px; }
            .header { background: #000; color: white; padding: 20px; text-align: center; }
            .content { padding: 30px; background: #f9f9f9; }
            .verification-box { background: white; padding: 25px; margin: 20px 0; border-radius: 8px; border: 2px solid #4CAF50; text-align: center; }
            .button { display: inline-block; padding: 15px 30px; background: #4CAF50; color: white; text-decoration: none; border-radius: 5px; margin: 20px 0; font-weight: bold; }
            .code { font-family: monospace; font-size: 24px; font-weight: bold; background: #f0f0f0; padding: 15px; border-radius: 5px; margin: 15px 0; letter-spacing: 5px; }
            .footer { text-align: center; padding: 20px; color: #666; font-size: 12px; }
            .security-note { background: #fff3e0; padding: 15px; margin: 20px 0; border-left: 4px solid #ff9800; font-size: 14px; }
          </style>
        </head>
        <body>
          <div class="container">
            <div class="header">
              <h1>Email Verification Required</h1>
            </div>
            <div class="content">
              <h2>Hi ${data.name || 'Admin'},</h2>
              <p>Please verify your email address to complete your account setup and enhance security.</p>
              
              <div class="verification-box">
                <h3>🔒 Verify Your Email</h3>
                <p>Click the button below to verify your email address:</p>
                
                <a href="${data.verificationUrl}" class="button">Verify Email Address</a>
                
                <p style="margin-top: 20px; color: #666; font-size: 14px;">
                  Or copy and paste this link into your browser:<br>
                  <span style="word-break: break-all;">${data.verificationUrl}</span>
                </p>
                
                ${data.verificationCode ? `
                  <p>Alternatively, you can use this verification code:</p>
                  <div class="code">${data.verificationCode}</div>
                ` : ''}
              </div>
              
              <div class="security-note">
                <strong>Security Notice:</strong> This verification link will expire in ${data.expiryHours || 24} hours for your security. 
                If you didn't request this verification, please ignore this email.
              </div>
              
              <p>If you're having trouble with the button above, copy and paste the URL into your web browser.</p>
              
              <p>Need help? Contact our support team at support@kctmenswear.com</p>
            </div>
            <div class="footer">
              <p>© 2025 KCT Menswear Admin System. All rights reserved.</p>
              <p>This is an automated message, please do not reply to this email.</p>
            </div>
          </div>
        </body>
      </html>
    `,
    text: `
      Email Verification Required
      
      Hi ${data.name || 'Admin'},
      
      Please verify your email address by clicking this link:
      ${data.verificationUrl}
      
      ${data.verificationCode ? `Or use this verification code: ${data.verificationCode}` : ''}
      
      This link expires in ${data.expiryHours || 24} hours.
      
      If you didn't request this verification, please ignore this email.
      
      Need help? Contact support@kctmenswear.com
    `
  }),

  password_reset: (data) => ({
    subject: 'Reset Your Password - KCT Admin',
    html: `
      <!DOCTYPE html>
      <html>
        <head>
          <style>
            body { font-family: Arial, sans-serif; line-height: 1.6; color: #333; }
            .container { max-width: 600px; margin: 0 auto; padding: 20px; }
            .header { background: #ff5722; color: white; padding: 20px; text-align: center; }
            .content { padding: 30px; background: #f9f9f9; }
            .reset-box { background: white; padding: 25px; margin: 20px 0; border-radius: 8px; border: 2px solid #ff5722; text-align: center; }
            .button { display: inline-block; padding: 15px 30px; background: #ff5722; color: white; text-decoration: none; border-radius: 5px; margin: 20px 0; font-weight: bold; }
            .footer { text-align: center; padding: 20px; color: #666; font-size: 12px; }
            .security-note { background: #ffebee; padding: 15px; margin: 20px 0; border-left: 4px solid #f44336; font-size: 14px; }
          </style>
        </head>
        <body>
          <div class="container">
            <div class="header">
              <h1>🔑 Password Reset Request</h1>
            </div>
            <div class="content">
              <h2>Hi ${data.name || 'Admin'},</h2>
              <p>We received a request to reset your password for your KCT Admin account.</p>
              
              <div class="reset-box">
                <h3>Reset Your Password</h3>
                <p>Click the button below to reset your password:</p>
                
                <a href="${data.resetUrl}" class="button">Reset Password</a>
                
                <p style="margin-top: 20px; color: #666; font-size: 14px;">
                  Or copy and paste this link into your browser:<br>
                  <span style="word-break: break-all;">${data.resetUrl}</span>
                </p>
              </div>
              
              <div class="security-note">
                <strong>Security Information:</strong>
                <ul style="text-align: left; margin: 10px 0;">
                  <li>This link will expire in ${data.expiryHours || 1} hour(s)</li>
                  <li>Request initiated from: ${data.ipAddress || 'Unknown location'}</li>
                  <li>Time: ${new Date().toLocaleString()}</li>
                </ul>
                <strong>If you didn't request this reset, please ignore this email and contact support immediately.</strong>
              </div>
              
              <p>For your security, never share this reset link with anyone.</p>
            </div>
            <div class="footer">
              <p>© 2025 KCT Menswear Admin System. All rights reserved.</p>
              <p>If you need help, contact support@kctmenswear.com</p>
            </div>
          </div>
        </body>
      </html>
    `,
    text: `
      Password Reset Request
      
      Hi ${data.name || 'Admin'},
      
      Click this link to reset your password:
      ${data.resetUrl}
      
      This link expires in ${data.expiryHours || 1} hour(s).
      
      Request from: ${data.ipAddress || 'Unknown location'}
      Time: ${new Date().toLocaleString()}
      
      If you didn't request this, please ignore this email.
      
      Need help? Contact support@kctmenswear.com
    `
  }),

  account_locked: (data) => ({
    subject: 'Account Locked - KCT Admin',
    html: `
      <!DOCTYPE html>
      <html>
        <head>
          <style>
            body { font-family: Arial, sans-serif; line-height: 1.6; color: #333; }
            .container { max-width: 600px; margin: 0 auto; padding: 20px; }
            .header { background: #f44336; color: white; padding: 20px; text-align: center; }
            .content { padding: 30px; background: #f9f9f9; }
            .alert-box { background: white; padding: 25px; margin: 20px 0; border-radius: 8px; border: 2px solid #f44336; }
            .button { display: inline-block; padding: 15px 30px; background: #4CAF50; color: white; text-decoration: none; border-radius: 5px; margin: 20px 0; font-weight: bold; }
            .footer { text-align: center; padding: 20px; color: #666; font-size: 12px; }
          </style>
        </head>
        <body>
          <div class="container">
            <div class="header">
              <h1>🚨 Account Locked</h1>
            </div>
            <div class="content">
              <h2>Hi ${data.name || 'Admin'},</h2>
              
              <div class="alert-box">
                <h3>Your account has been temporarily locked</h3>
                <p><strong>Reason:</strong> ${data.reason}</p>
                <p><strong>Time:</strong> ${new Date().toLocaleString()}</p>
                <p><strong>Location:</strong> ${data.location || 'Unknown'}</p>
                
                <h4>What happened?</h4>
                <p>${data.details}</p>
                
                <h4>What should you do?</h4>
                <p>If this was you, you can unlock your account using the link below. If this wasn't you, please contact support immediately.</p>
                
                <center>
                  <a href="${data.unlockUrl}" class="button">Unlock Account</a>
                </center>
              </div>
              
              <p><strong>Security Tip:</strong> Always use strong, unique passwords and enable two-factor authentication.</p>
            </div>
            <div class="footer">
              <p>© 2025 KCT Menswear Admin System. All rights reserved.</p>
              <p>If you need immediate assistance, contact support@kctmenswear.com</p>
            </div>
          </div>
        </body>
      </html>
    `,
    text: `
      Account Locked
      
      Hi ${data.name || 'Admin'},
      
      Your account has been locked due to: ${data.reason}
      
      Time: ${new Date().toLocaleString()}
      Location: ${data.location || 'Unknown'}
      
      To unlock your account: ${data.unlockUrl}
      
      If this wasn't you, contact support@kctmenswear.com immediately.
    `
  }),

  suspicious_activity: (data) => ({
    subject: 'Suspicious Activity Detected - KCT Admin',
    html: `
      <!DOCTYPE html>
      <html>
        <head>
          <style>
            body { font-family: Arial, sans-serif; line-height: 1.6; color: #333; }
            .container { max-width: 600px; margin: 0 auto; padding: 20px; }
            .header { background: #ff9800; color: white; padding: 20px; text-align: center; }
            .content { padding: 30px; background: #f9f9f9; }
            .activity-box { background: white; padding: 25px; margin: 20px 0; border-radius: 8px; border: 2px solid #ff9800; }
            .button { display: inline-block; padding: 15px 30px; background: #f44336; color: white; text-decoration: none; border-radius: 5px; margin: 10px 5px; font-weight: bold; }
            .button.secondary { background: #4CAF50; }
            .footer { text-align: center; padding: 20px; color: #666; font-size: 12px; }
          </style>
        </head>
        <body>
          <div class="container">
            <div class="header">
              <h1>⚠️ Suspicious Activity Alert</h1>
            </div>
            <div class="content">
              <h2>Hi ${data.name || 'Admin'},</h2>
              
              <div class="activity-box">
                <h3>Unusual activity detected on your account</h3>
                <p><strong>Activity:</strong> ${data.activityType}</p>
                <p><strong>Time:</strong> ${new Date(data.timestamp).toLocaleString()}</p>
                <p><strong>Location:</strong> ${data.location || 'Unknown location'}</p>
                <p><strong>IP Address:</strong> ${data.ipAddress}</p>
                <p><strong>Device:</strong> ${data.userAgent || 'Unknown device'}</p>
                
                <h4>Was this you?</h4>
                <center>
                  <a href="${data.confirmUrl}" class="button secondary">Yes, this was me</a>
                  <a href="${data.secureUrl}" class="button">No, secure my account</a>
                </center>
              </div>
              
              <p>If you didn't perform this activity, please click "No, secure my account" immediately to protect your account.</p>
            </div>
            <div class="footer">
              <p>© 2025 KCT Menswear Admin System. All rights reserved.</p>
              <p>Report suspicious activity: security@kctmenswear.com</p>
            </div>
          </div>
        </body>
      </html>
    `,
    text: `
      Suspicious Activity Alert
      
      Hi ${data.name || 'Admin'},
      
      Unusual activity detected: ${data.activityType}
      Time: ${new Date(data.timestamp).toLocaleString()}
      Location: ${data.location || 'Unknown'}
      IP: ${data.ipAddress}
      
      If this was you: ${data.confirmUrl}
      If this wasn't you: ${data.secureUrl}
      
      Contact security@kctmenswear.com if needed.
    `
  }),

  password_changed: (data) => ({
    subject: 'Password Changed - KCT Admin',
    html: `
      <!DOCTYPE html>
      <html>
        <head>
          <style>
            body { font-family: Arial, sans-serif; line-height: 1.6; color: #333; }
            .container { max-width: 600px; margin: 0 auto; padding: 20px; }
            .header { background: #4CAF50; color: white; padding: 20px; text-align: center; }
            .content { padding: 30px; background: #f9f9f9; }
            .confirmation-box { background: white; padding: 25px; margin: 20px 0; border-radius: 8px; border: 2px solid #4CAF50; }
            .button { display: inline-block; padding: 15px 30px; background: #f44336; color: white; text-decoration: none; border-radius: 5px; margin: 20px 0; font-weight: bold; }
            .footer { text-align: center; padding: 20px; color: #666; font-size: 12px; }
          </style>
        </head>
        <body>
          <div class="container">
            <div class="header">
              <h1>✅ Password Changed Successfully</h1>
            </div>
            <div class="content">
              <h2>Hi ${data.name || 'Admin'},</h2>
              
              <div class="confirmation-box">
                <h3>Your password has been changed</h3>
                <p><strong>Time:</strong> ${new Date().toLocaleString()}</p>
                <p><strong>Location:</strong> ${data.location || 'Unknown location'}</p>
                <p><strong>IP Address:</strong> ${data.ipAddress}</p>
                
                <p>If you didn't make this change, please contact support immediately and secure your account.</p>
                
                <center>
                  <a href="${data.supportUrl}" class="button">Report Unauthorized Change</a>
                </center>
              </div>
              
              <p><strong>Security Reminders:</strong></p>
              <ul>
                <li>Use a strong, unique password</li>
                <li>Enable two-factor authentication</li>
                <li>Never share your login credentials</li>
              </ul>
            </div>
            <div class="footer">
              <p>© 2025 KCT Menswear Admin System. All rights reserved.</p>
              <p>Security concerns? Contact security@kctmenswear.com</p>
            </div>
          </div>
        </body>
      </html>
    `,
    text: `
      Password Changed Successfully
      
      Hi ${data.name || 'Admin'},
      
      Your password was changed at ${new Date().toLocaleString()}
      Location: ${data.location || 'Unknown'}
      IP: ${data.ipAddress}
      
      If you didn't make this change, contact support immediately:
      ${data.supportUrl}
      
      Security concerns? Email security@kctmenswear.com
    `
  }),

  two_factor_enabled: (data) => ({
    subject: 'Two-Factor Authentication Enabled - KCT Admin',
    html: `
      <!DOCTYPE html>
      <html>
        <head>
          <style>
            body { font-family: Arial, sans-serif; line-height: 1.6; color: #333; }
            .container { max-width: 600px; margin: 0 auto; padding: 20px; }
            .header { background: #2196F3; color: white; padding: 20px; text-align: center; }
            .content { padding: 30px; background: #f9f9f9; }
            .security-box { background: white; padding: 25px; margin: 20px 0; border-radius: 8px; border: 2px solid #2196F3; }
            .backup-codes { background: #f0f0f0; padding: 15px; border-radius: 5px; font-family: monospace; margin: 15px 0; }
            .footer { text-align: center; padding: 20px; color: #666; font-size: 12px; }
          </style>
        </head>
        <body>
          <div class="container">
            <div class="header">
              <h1>🔐 Two-Factor Authentication Enabled</h1>
            </div>
            <div class="content">
              <h2>Hi ${data.name || 'Admin'},</h2>
              
              <div class="security-box">
                <h3>Your account is now more secure!</h3>
                <p>Two-factor authentication has been successfully enabled for your account.</p>
                <p><strong>Enabled at:</strong> ${new Date().toLocaleString()}</p>
                
                ${data.backupCodes ? `
                  <h4>🔑 Backup Recovery Codes</h4>
                  <p>Save these backup codes in a safe place. You can use them to access your account if you lose access to your authenticator app:</p>
                  
                  <div class="backup-codes">
                    ${data.backupCodes.map(code => code).join('<br>')}
                  </div>
                  
                  <p><strong>Important:</strong> Each code can only be used once. Store them securely!</p>
                ` : ''}
                
                <h4>What's Next?</h4>
                <ul>
                  <li>Use your authenticator app to generate codes when logging in</li>
                  <li>Keep your backup codes in a safe, accessible place</li>
                  <li>Consider enabling backup email for account recovery</li>
                </ul>
              </div>
            </div>
            <div class="footer">
              <p>© 2025 KCT Menswear Admin System. All rights reserved.</p>
              <p>Questions about 2FA? Contact support@kctmenswear.com</p>
            </div>
          </div>
        </body>
      </html>
    `,
    text: `
      Two-Factor Authentication Enabled
      
      Hi ${data.name || 'Admin'},
      
      2FA has been enabled for your account at ${new Date().toLocaleString()}
      
      ${data.backupCodes ? `Backup codes:\n${data.backupCodes.join('\n')}\n\nSave these codes securely!` : ''}
      
      Questions? Contact support@kctmenswear.com
    `
  }),

  security_question_reset: (data) => ({
    subject: 'Security Questions Updated - KCT Admin',
    html: `
      <!DOCTYPE html>
      <html>
        <head>
          <style>
            body { font-family: Arial, sans-serif; line-height: 1.6; color: #333; }
            .container { max-width: 600px; margin: 0 auto; padding: 20px; }
            .header { background: #9C27B0; color: white; padding: 20px; text-align: center; }
            .content { padding: 30px; background: #f9f9f9; }
            .update-box { background: white; padding: 25px; margin: 20px 0; border-radius: 8px; border: 2px solid #9C27B0; }
            .footer { text-align: center; padding: 20px; color: #666; font-size: 12px; }
          </style>
        </head>
        <body>
          <div class="container">
            <div class="header">
              <h1>🔒 Security Questions Updated</h1>
            </div>
            <div class="content">
              <h2>Hi ${data.name || 'Admin'},</h2>
              
              <div class="update-box">
                <h3>Your security questions have been updated</h3>
                <p><strong>Updated at:</strong> ${new Date().toLocaleString()}</p>
                <p><strong>Location:</strong> ${data.location || 'Unknown location'}</p>
                
                <p>These security questions can be used to recover your account if you forget your password.</p>
                
                <p>If you didn't make this change, please contact support immediately.</p>
              </div>
            </div>
            <div class="footer">
              <p>© 2025 KCT Menswear Admin System. All rights reserved.</p>
              <p>Security concerns? Contact security@kctmenswear.com</p>
            </div>
          </div>
        </body>
      </html>
    `,
    text: `
      Security Questions Updated
      
      Hi ${data.name || 'Admin'},
      
      Your security questions were updated at ${new Date().toLocaleString()}
      Location: ${data.location || 'Unknown'}
      
      If you didn't make this change, contact security@kctmenswear.com
    `
  }),

  backup_email_verification: (data) => ({
    subject: 'Verify Backup Email - KCT Admin',
    html: `
      <!DOCTYPE html>
      <html>
        <head>
          <style>
            body { font-family: Arial, sans-serif; line-height: 1.6; color: #333; }
            .container { max-width: 600px; margin: 0 auto; padding: 20px; }
            .header { background: #607D8B; color: white; padding: 20px; text-align: center; }
            .content { padding: 30px; background: #f9f9f9; }
            .verification-box { background: white; padding: 25px; margin: 20px 0; border-radius: 8px; border: 2px solid #607D8B; text-align: center; }
            .button { display: inline-block; padding: 15px 30px; background: #607D8B; color: white; text-decoration: none; border-radius: 5px; margin: 20px 0; font-weight: bold; }
            .footer { text-align: center; padding: 20px; color: #666; font-size: 12px; }
          </style>
        </head>
        <body>
          <div class="container">
            <div class="header">
              <h1>📧 Verify Backup Email</h1>
            </div>
            <div class="content">
              <h2>Hi ${data.name || 'Admin'},</h2>
              <p>Please verify this email address as your backup email for account recovery.</p>
              
              <div class="verification-box">
                <h3>Verify Backup Email Address</h3>
                <p>Click the button below to verify this email address:</p>
                
                <a href="${data.verificationUrl}" class="button">Verify Backup Email</a>
                
                <p style="margin-top: 20px; color: #666; font-size: 14px;">
                  This verification link expires in ${data.expiryHours || 24} hours.
                </p>
              </div>
              
              <p>This backup email can be used to recover your account if you lose access to your primary email.</p>
            </div>
            <div class="footer">
              <p>© 2025 KCT Menswear Admin System. All rights reserved.</p>
              <p>Questions? Contact support@kctmenswear.com</p>
            </div>
          </div>
        </body>
      </html>
    `,
    text: `
      Verify Backup Email
      
      Hi ${data.name || 'Admin'},
      
      Please verify this backup email address: ${data.verificationUrl}
      
      This link expires in ${data.expiryHours || 24} hours.
      
      Questions? Contact support@kctmenswear.com
    `
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

/**
 * Send email verification email
 */
export async function sendEmailVerification(userId: string, email: string, verificationToken: string, name?: string) {
  try {
    const verificationUrl = `${window.location.origin}/verify-email?token=${verificationToken}`;
    
    return await sendEmail({
      to: email,
      subject: 'Verify Your Email Address - KCT Admin',
      template: 'email_verification',
      data: {
        name: name || 'Admin',
        verificationUrl,
        verificationToken,
        expiryHours: 24
      }
    });
  } catch (error) {
    console.error('Error sending email verification:', error);
    return false;
  }
}

/**
 * Send password reset email
 */
export async function sendPasswordReset(email: string, resetToken: string, name?: string, ipAddress?: string) {
  try {
    const resetUrl = `${window.location.origin}/reset-password?token=${resetToken}`;
    
    return await sendEmail({
      to: email,
      subject: 'Reset Your Password - KCT Admin',
      template: 'password_reset',
      data: {
        name: name || 'Admin',
        resetUrl,
        expiryHours: 1,
        ipAddress
      }
    });
  } catch (error) {
    console.error('Error sending password reset:', error);
    return false;
  }
}

/**
 * Send account locked notification
 */
export async function sendAccountLocked(email: string, reason: string, details: string, unlockToken?: string, name?: string, location?: string) {
  try {
    const unlockUrl = unlockToken ? `${window.location.origin}/unlock-account?token=${unlockToken}` : '#';
    
    return await sendEmail({
      to: email,
      subject: 'Account Locked - KCT Admin',
      template: 'account_locked',
      data: {
        name: name || 'Admin',
        reason,
        details,
        unlockUrl,
        location
      }
    });
  } catch (error) {
    console.error('Error sending account locked notification:', error);
    return false;
  }
}

/**
 * Send suspicious activity alert
 */
export async function sendSuspiciousActivity(
  email: string, 
  activityType: string, 
  timestamp: Date,
  ipAddress: string,
  userAgent?: string,
  location?: string,
  name?: string
) {
  try {
    const baseUrl = window.location.origin;
    const confirmUrl = `${baseUrl}/security/confirm-activity?type=${encodeURIComponent(activityType)}&time=${timestamp.getTime()}`;
    const secureUrl = `${baseUrl}/security/secure-account`;
    
    return await sendEmail({
      to: email,
      subject: 'Suspicious Activity Detected - KCT Admin',
      template: 'suspicious_activity',
      data: {
        name: name || 'Admin',
        activityType,
        timestamp,
        ipAddress,
        userAgent,
        location,
        confirmUrl,
        secureUrl
      }
    });
  } catch (error) {
    console.error('Error sending suspicious activity alert:', error);
    return false;
  }
}

/**
 * Send password changed notification
 */
export async function sendPasswordChanged(email: string, ipAddress: string, location?: string, name?: string) {
  try {
    const supportUrl = `${window.location.origin}/support/unauthorized-change`;
    
    return await sendEmail({
      to: email,
      subject: 'Password Changed - KCT Admin',
      template: 'password_changed',
      data: {
        name: name || 'Admin',
        ipAddress,
        location,
        supportUrl
      }
    });
  } catch (error) {
    console.error('Error sending password changed notification:', error);
    return false;
  }
}

/**
 * Send 2FA enabled notification
 */
export async function sendTwoFactorEnabled(email: string, backupCodes?: string[], name?: string) {
  try {
    return await sendEmail({
      to: email,
      subject: 'Two-Factor Authentication Enabled - KCT Admin',
      template: 'two_factor_enabled',
      data: {
        name: name || 'Admin',
        backupCodes
      }
    });
  } catch (error) {
    console.error('Error sending 2FA enabled notification:', error);
    return false;
  }
}

/**
 * Send backup email verification
 */
export async function sendBackupEmailVerification(email: string, verificationToken: string, name?: string) {
  try {
    const verificationUrl = `${window.location.origin}/verify-backup-email?token=${verificationToken}`;
    
    return await sendEmail({
      to: email,
      subject: 'Verify Backup Email - KCT Admin',
      template: 'backup_email_verification',
      data: {
        name: name || 'Admin',
        verificationUrl,
        expiryHours: 24
      }
    });
  } catch (error) {
    console.error('Error sending backup email verification:', error);
    return false;
  }
}