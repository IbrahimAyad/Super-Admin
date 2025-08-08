import { serve } from "https://deno.land/std@0.190.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.45.0";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};

interface DailyReportData {
  ordersToday: number;
  revenueToday: number;
  pendingOrders: number;
  processingOrders: number;
  shippedToday: number;
  deliveredToday: number;
  cancelledToday: number;
  refundsToday: number;
  newCustomers: number;
  returningCustomers: number;
  lowStockProducts: Array<{
    name: string;
    sku: string;
    stock: number;
    threshold: number;
  }>;
  pendingRefunds: number;
  topProducts: Array<{
    name: string;
    quantity: number;
    revenue: number;
  }>;
  hourlyBreakdown: Array<{
    hour: number;
    orders: number;
    revenue: number;
  }>;
  comparisonWithYesterday: {
    orders: { today: number; yesterday: number; change: number };
    revenue: { today: number; yesterday: number; change: number };
  };
}

async function generateDailyReport(supabase: any): Promise<DailyReportData> {
  const today = new Date();
  today.setHours(0, 0, 0, 0);
  
  const yesterday = new Date(today);
  yesterday.setDate(yesterday.getDate() - 1);
  
  const tomorrow = new Date(today);
  tomorrow.setDate(tomorrow.getDate() + 1);

  // Get today's orders
  const { data: todayOrders } = await supabase
    .from('orders')
    .select('*')
    .gte('created_at', today.toISOString())
    .lt('created_at', tomorrow.toISOString());

  // Get yesterday's orders for comparison
  const { data: yesterdayOrders } = await supabase
    .from('orders')
    .select('*')
    .gte('created_at', yesterday.toISOString())
    .lt('created_at', today.toISOString());

  // Calculate today's metrics
  const ordersToday = todayOrders?.length || 0;
  const revenueToday = todayOrders?.reduce((sum, order) => 
    order.financial_status === 'paid' ? sum + (order.total_amount || 0) : sum, 0
  ) || 0;

  const pendingOrders = todayOrders?.filter(o => o.status === 'pending').length || 0;
  const processingOrders = todayOrders?.filter(o => o.status === 'processing').length || 0;
  const shippedToday = todayOrders?.filter(o => o.status === 'shipped').length || 0;
  const deliveredToday = todayOrders?.filter(o => o.status === 'delivered').length || 0;
  const cancelledToday = todayOrders?.filter(o => o.status === 'cancelled').length || 0;

  // Get refunds processed today
  const { data: refundsToday } = await supabase
    .from('refund_requests')
    .select('*')
    .eq('status', 'approved')
    .gte('updated_at', today.toISOString())
    .lt('updated_at', tomorrow.toISOString());

  // Get pending refunds
  const { data: pendingRefundsList } = await supabase
    .from('refund_requests')
    .select('*')
    .eq('status', 'pending');

  // Get new vs returning customers
  const customerEmails = new Set();
  const newCustomersSet = new Set();
  
  for (const order of todayOrders || []) {
    const email = order.customer_email || order.guest_email;
    if (email) {
      // Check if this customer has ordered before today
      const { data: previousOrders } = await supabase
        .from('orders')
        .select('id')
        .or(`customer_email.eq.${email},guest_email.eq.${email}`)
        .lt('created_at', today.toISOString())
        .limit(1);
      
      if (!previousOrders || previousOrders.length === 0) {
        newCustomersSet.add(email);
      }
      customerEmails.add(email);
    }
  }

  const newCustomers = newCustomersSet.size;
  const returningCustomers = customerEmails.size - newCustomers;

  // Get low stock products
  const { data: lowStockItems } = await supabase
    .from('inventory')
    .select(`
      available_quantity,
      product_variants!inner(
        sku,
        products!inner(name)
      ),
      inventory_thresholds!left(low_stock_threshold)
    `)
    .lt('available_quantity', 20)
    .order('available_quantity', { ascending: true })
    .limit(10);

  const lowStockProducts = (lowStockItems || []).map(item => ({
    name: item.product_variants.products.name,
    sku: item.product_variants.sku,
    stock: item.available_quantity,
    threshold: item.inventory_thresholds?.low_stock_threshold || 10
  }));

  // Calculate top products of the day
  const productSales = new Map();
  
  for (const order of todayOrders || []) {
    if (order.items && order.financial_status === 'paid') {
      const items = typeof order.items === 'string' ? JSON.parse(order.items) : order.items;
      for (const item of items) {
        const key = item.name || item.product_name;
        if (key) {
          const existing = productSales.get(key) || { quantity: 0, revenue: 0 };
          existing.quantity += item.quantity || 1;
          existing.revenue += item.total_price || item.unit_price || 0;
          productSales.set(key, existing);
        }
      }
    }
  }

  const topProducts = Array.from(productSales.entries())
    .map(([name, data]) => ({ name, ...data }))
    .sort((a, b) => b.revenue - a.revenue)
    .slice(0, 5);

  // Calculate hourly breakdown
  const hourlyMap = new Map();
  
  for (let hour = 0; hour < 24; hour++) {
    hourlyMap.set(hour, { orders: 0, revenue: 0 });
  }
  
  for (const order of todayOrders || []) {
    const hour = new Date(order.created_at).getHours();
    const existing = hourlyMap.get(hour);
    if (existing) {
      existing.orders++;
      if (order.financial_status === 'paid') {
        existing.revenue += order.total_amount || 0;
      }
    }
  }

  const hourlyBreakdown = Array.from(hourlyMap.entries())
    .map(([hour, data]) => ({ hour, ...data }))
    .filter(h => h.orders > 0);

  // Calculate yesterday's metrics for comparison
  const ordersYesterday = yesterdayOrders?.length || 0;
  const revenueYesterday = yesterdayOrders?.reduce((sum, order) => 
    order.financial_status === 'paid' ? sum + (order.total_amount || 0) : sum, 0
  ) || 0;

  return {
    ordersToday,
    revenueToday: revenueToday / 100, // Convert from cents
    pendingOrders,
    processingOrders,
    shippedToday,
    deliveredToday,
    cancelledToday,
    refundsToday: refundsToday?.length || 0,
    newCustomers,
    returningCustomers,
    lowStockProducts,
    pendingRefunds: pendingRefundsList?.length || 0,
    topProducts: topProducts.map(p => ({ ...p, revenue: p.revenue / 100 })),
    hourlyBreakdown: hourlyBreakdown.map(h => ({ ...h, revenue: h.revenue / 100 })),
    comparisonWithYesterday: {
      orders: {
        today: ordersToday,
        yesterday: ordersYesterday,
        change: ordersYesterday > 0 
          ? ((ordersToday - ordersYesterday) / ordersYesterday) * 100 
          : 0
      },
      revenue: {
        today: revenueToday / 100,
        yesterday: revenueYesterday / 100,
        change: revenueYesterday > 0 
          ? ((revenueToday - revenueYesterday) / revenueYesterday) * 100 
          : 0
      }
    }
  };
}

async function sendReportEmail(supabase: any, reportData: DailyReportData) {
  const RESEND_API_KEY = Deno.env.get("RESEND_API_KEY");
  
  if (!RESEND_API_KEY) {
    console.error("RESEND_API_KEY not configured");
    return false;
  }

  const formatCurrency = (amount: number) => `$${amount.toFixed(2)}`;
  const formatPercent = (change: number) => {
    const sign = change >= 0 ? '+' : '';
    return `${sign}${change.toFixed(1)}%`;
  };

  const htmlContent = `
    <!DOCTYPE html>
    <html>
      <head>
        <style>
          body { font-family: Arial, sans-serif; line-height: 1.6; color: #333; }
          .container { max-width: 800px; margin: 0 auto; padding: 20px; }
          .header { background: #000; color: white; padding: 30px; text-align: center; border-radius: 10px 10px 0 0; }
          .content { padding: 30px; background: #f9f9f9; }
          .metric-grid { display: grid; grid-template-columns: repeat(auto-fit, minmax(200px, 1fr)); gap: 20px; margin: 20px 0; }
          .metric-card { background: white; padding: 20px; border-radius: 8px; box-shadow: 0 2px 4px rgba(0,0,0,0.1); }
          .metric-value { font-size: 28px; font-weight: bold; color: #000; }
          .metric-label { color: #666; font-size: 14px; margin-top: 5px; }
          .metric-change { font-size: 12px; margin-top: 5px; }
          .positive { color: #4CAF50; }
          .negative { color: #f44336; }
          .section { margin: 30px 0; }
          .section-title { font-size: 20px; font-weight: bold; margin-bottom: 15px; }
          table { width: 100%; border-collapse: collapse; background: white; }
          th, td { padding: 12px; text-align: left; border-bottom: 1px solid #eee; }
          th { background: #f5f5f5; font-weight: bold; }
          .alert-box { background: #fff3e0; border-left: 4px solid #ff9800; padding: 15px; margin: 20px 0; }
          .footer { text-align: center; padding: 20px; color: #666; font-size: 12px; }
        </style>
      </head>
      <body>
        <div class="container">
          <div class="header">
            <h1>Daily Business Report</h1>
            <p>${new Date().toLocaleDateString('en-US', { weekday: 'long', year: 'numeric', month: 'long', day: 'numeric' })}</p>
          </div>
          
          <div class="content">
            <!-- Key Metrics -->
            <div class="metric-grid">
              <div class="metric-card">
                <div class="metric-value">${reportData.ordersToday}</div>
                <div class="metric-label">Orders Today</div>
                <div class="metric-change ${reportData.comparisonWithYesterday.orders.change >= 0 ? 'positive' : 'negative'}">
                  ${formatPercent(reportData.comparisonWithYesterday.orders.change)} vs yesterday
                </div>
              </div>
              
              <div class="metric-card">
                <div class="metric-value">${formatCurrency(reportData.revenueToday)}</div>
                <div class="metric-label">Revenue Today</div>
                <div class="metric-change ${reportData.comparisonWithYesterday.revenue.change >= 0 ? 'positive' : 'negative'}">
                  ${formatPercent(reportData.comparisonWithYesterday.revenue.change)} vs yesterday
                </div>
              </div>
              
              <div class="metric-card">
                <div class="metric-value">${reportData.newCustomers}</div>
                <div class="metric-label">New Customers</div>
              </div>
              
              <div class="metric-card">
                <div class="metric-value">${reportData.shippedToday}</div>
                <div class="metric-label">Orders Shipped</div>
              </div>
            </div>

            <!-- Order Status Breakdown -->
            <div class="section">
              <div class="section-title">Order Status Summary</div>
              <table>
                <tr>
                  <th>Status</th>
                  <th>Count</th>
                </tr>
                <tr>
                  <td>Pending</td>
                  <td>${reportData.pendingOrders}</td>
                </tr>
                <tr>
                  <td>Processing</td>
                  <td>${reportData.processingOrders}</td>
                </tr>
                <tr>
                  <td>Shipped</td>
                  <td>${reportData.shippedToday}</td>
                </tr>
                <tr>
                  <td>Delivered</td>
                  <td>${reportData.deliveredToday}</td>
                </tr>
                <tr>
                  <td>Cancelled</td>
                  <td>${reportData.cancelledToday}</td>
                </tr>
              </table>
            </div>

            ${reportData.topProducts.length > 0 ? `
            <!-- Top Products -->
            <div class="section">
              <div class="section-title">Top Selling Products</div>
              <table>
                <tr>
                  <th>Product</th>
                  <th>Quantity</th>
                  <th>Revenue</th>
                </tr>
                ${reportData.topProducts.map(p => `
                <tr>
                  <td>${p.name}</td>
                  <td>${p.quantity}</td>
                  <td>${formatCurrency(p.revenue)}</td>
                </tr>
                `).join('')}
              </table>
            </div>
            ` : ''}

            ${reportData.lowStockProducts.length > 0 ? `
            <!-- Low Stock Alert -->
            <div class="alert-box">
              <div class="section-title">⚠️ Low Stock Products</div>
              <ul>
                ${reportData.lowStockProducts.slice(0, 5).map(p => 
                  `<li>${p.name} (SKU: ${p.sku}) - ${p.stock} units remaining</li>`
                ).join('')}
              </ul>
            </div>
            ` : ''}

            ${reportData.pendingRefunds > 0 ? `
            <!-- Pending Actions -->
            <div class="alert-box">
              <div class="section-title">📋 Pending Actions</div>
              <ul>
                <li>${reportData.pendingRefunds} refund requests awaiting approval</li>
                ${reportData.pendingOrders > 0 ? `<li>${reportData.pendingOrders} orders pending confirmation</li>` : ''}
                ${reportData.processingOrders > 0 ? `<li>${reportData.processingOrders} orders ready to ship</li>` : ''}
              </ul>
            </div>
            ` : ''}

            <!-- Hourly Performance -->
            ${reportData.hourlyBreakdown.length > 0 ? `
            <div class="section">
              <div class="section-title">Peak Hours Today</div>
              <table>
                <tr>
                  <th>Hour</th>
                  <th>Orders</th>
                  <th>Revenue</th>
                </tr>
                ${reportData.hourlyBreakdown
                  .sort((a, b) => b.revenue - a.revenue)
                  .slice(0, 5)
                  .map(h => `
                <tr>
                  <td>${h.hour}:00 - ${h.hour + 1}:00</td>
                  <td>${h.orders}</td>
                  <td>${formatCurrency(h.revenue)}</td>
                </tr>
                `).join('')}
              </table>
            </div>
            ` : ''}
          </div>
          
          <div class="footer">
            <p>This is an automated daily report from KCT Menswear Admin System</p>
            <p>Access your dashboard at <a href="https://admin.kctmenswear.com">admin.kctmenswear.com</a></p>
          </div>
        </div>
      </body>
    </html>
  `;

  const textContent = `
Daily Business Report - ${new Date().toLocaleDateString()}

KEY METRICS
Orders Today: ${reportData.ordersToday} (${formatPercent(reportData.comparisonWithYesterday.orders.change)} vs yesterday)
Revenue Today: ${formatCurrency(reportData.revenueToday)} (${formatPercent(reportData.comparisonWithYesterday.revenue.change)} vs yesterday)
New Customers: ${reportData.newCustomers}
Returning Customers: ${reportData.returningCustomers}

ORDER STATUS
Pending: ${reportData.pendingOrders}
Processing: ${reportData.processingOrders}
Shipped: ${reportData.shippedToday}
Delivered: ${reportData.deliveredToday}
Cancelled: ${reportData.cancelledToday}

${reportData.lowStockProducts.length > 0 ? `
LOW STOCK ALERTS
${reportData.lowStockProducts.slice(0, 5).map(p => 
  `- ${p.name}: ${p.stock} units remaining`
).join('\n')}
` : ''}

${reportData.pendingRefunds > 0 ? `
PENDING ACTIONS
- ${reportData.pendingRefunds} refund requests awaiting approval
` : ''}

Access your dashboard at https://admin.kctmenswear.com
  `;

  try {
    const response = await fetch("https://api.resend.com/emails", {
      method: "POST",
      headers: {
        "Authorization": `Bearer ${RESEND_API_KEY}`,
        "Content-Type": "application/json",
      },
      body: JSON.stringify({
        from: "KCT Admin <reports@kctmenswear.com>",
        to: ["admin@kctmenswear.com"], // Configure recipients
        subject: `Daily Report - ${new Date().toLocaleDateString()} - ${reportData.ordersToday} orders, ${formatCurrency(reportData.revenueToday)} revenue`,
        html: htmlContent,
        text: textContent
      }),
    });

    if (!response.ok) {
      const error = await response.json();
      console.error("Failed to send email:", error);
      return false;
    }

    // Log the report
    await supabase.from('email_logs').insert({
      to_email: 'admin@kctmenswear.com',
      subject: `Daily Report - ${new Date().toLocaleDateString()}`,
      template: 'daily_report',
      status: 'sent',
      metadata: reportData,
      created_at: new Date().toISOString()
    });

    return true;
  } catch (error) {
    console.error("Error sending report email:", error);
    return false;
  }
}

serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response(null, { headers: corsHeaders });
  }

  try {
    const supabase = createClient(
      Deno.env.get("SUPABASE_URL") ?? "",
      Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? ""
    );

    console.log("Generating daily report...");
    
    // Generate the report
    const reportData = await generateDailyReport(supabase);
    
    console.log("Report data:", {
      orders: reportData.ordersToday,
      revenue: reportData.revenueToday,
      lowStock: reportData.lowStockProducts.length
    });

    // Send the email
    const emailSent = await sendReportEmail(supabase, reportData);

    // Store the report in database
    const { error: storeError } = await supabase
      .from('daily_reports')
      .insert({
        report_date: new Date().toISOString().split('T')[0],
        data: reportData,
        email_sent: emailSent,
        created_at: new Date().toISOString()
      });

    if (storeError) {
      console.error("Error storing report:", storeError);
    }

    return new Response(JSON.stringify({ 
      success: true,
      message: "Daily report generated",
      emailSent,
      summary: {
        orders: reportData.ordersToday,
        revenue: reportData.revenueToday,
        pendingActions: reportData.pendingOrders + reportData.pendingRefunds
      }
    }), {
      headers: { ...corsHeaders, "Content-Type": "application/json" },
      status: 200,
    });

  } catch (error) {
    console.error("Report generation error:", error);
    
    return new Response(JSON.stringify({ 
      success: false,
      error: error.message 
    }), {
      headers: { ...corsHeaders, "Content-Type": "application/json" },
      status: 500,
    });
  }
});