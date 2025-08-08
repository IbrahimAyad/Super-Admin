import { supabase } from '@/lib/supabase-client';

interface FinancialSummary {
  totalRevenue: number;
  pendingRefunds: number;
  processingFees: number;
  taxCollected: number;
  pendingPayouts: number;
  refundCount: number;
  orderCount: number;
  averageOrderValue: number;
}

interface RevenueData {
  date: string;
  revenue: number;
  orders: number;
  refunds: number;
}

interface Transaction {
  id: string;
  order_number: string;
  amount: number;
  status: string;
  payment_method: string;
  customer_name: string;
  customer_email: string;
  created_at: string;
  stripe_payment_intent_id?: string;
}

/**
 * Get financial summary for dashboard
 */
export async function getFinancialSummary(days: number = 30): Promise<FinancialSummary> {
  try {
    const startDate = new Date();
    startDate.setDate(startDate.getDate() - days);

    // Get orders data
    const { data: orders, error: ordersError } = await supabase
      .from('orders')
      .select('total_amount, financial_status, created_at')
      .gte('created_at', startDate.toISOString())
      .in('financial_status', ['paid', 'partially_refunded']);

    if (ordersError) throw ordersError;

    // Get pending refunds
    const { data: refunds, error: refundsError } = await supabase
      .from('refund_requests')
      .select('refund_amount, status')
      .eq('status', 'pending');

    if (refundsError) throw refundsError;

    // Calculate totals
    const totalRevenue = orders?.reduce((sum, order) => sum + (order.total_amount || 0), 0) || 0;
    const pendingRefunds = refunds?.reduce((sum, refund) => sum + (refund.refund_amount || 0), 0) || 0;
    
    // Estimate processing fees (2.9% + $0.30 per transaction for Stripe)
    const processingFees = orders?.reduce((sum, order) => {
      return sum + (order.total_amount * 0.029 + 30); // 2.9% + 30 cents
    }, 0) || 0;

    // Estimate tax (you might want to store actual tax in orders table)
    const taxCollected = orders?.reduce((sum, order) => {
      return sum + (order.total_amount * 0.085); // 8.5% estimate
    }, 0) || 0;

    // Pending payouts (revenue - fees - refunds)
    const pendingPayouts = totalRevenue - processingFees - pendingRefunds;

    return {
      totalRevenue: totalRevenue / 100, // Convert from cents
      pendingRefunds: pendingRefunds / 100,
      processingFees: processingFees / 100,
      taxCollected: taxCollected / 100,
      pendingPayouts: pendingPayouts / 100,
      refundCount: refunds?.length || 0,
      orderCount: orders?.length || 0,
      averageOrderValue: orders?.length ? (totalRevenue / orders.length) / 100 : 0
    };
  } catch (error) {
    console.error('Error fetching financial summary:', error);
    // Return default values on error
    return {
      totalRevenue: 0,
      pendingRefunds: 0,
      processingFees: 0,
      taxCollected: 0,
      pendingPayouts: 0,
      refundCount: 0,
      orderCount: 0,
      averageOrderValue: 0
    };
  }
}

/**
 * Get recent transactions
 */
export async function getRecentTransactions(limit: number = 10): Promise<Transaction[]> {
  try {
    const { data, error } = await supabase
      .from('orders')
      .select(`
        id,
        order_number,
        total_amount,
        financial_status,
        stripe_payment_intent_id,
        created_at,
        customers!left(
          first_name,
          last_name,
          email
        )
      `)
      .order('created_at', { ascending: false })
      .limit(limit);

    if (error) throw error;

    return (data || []).map(order => ({
      id: order.id,
      order_number: order.order_number,
      amount: order.total_amount / 100,
      status: order.financial_status || 'pending',
      payment_method: order.stripe_payment_intent_id ? 'stripe' : 'other',
      customer_name: order.customers 
        ? `${order.customers.first_name || ''} ${order.customers.last_name || ''}`.trim()
        : 'Guest',
      customer_email: order.customers?.email || 'N/A',
      created_at: order.created_at,
      stripe_payment_intent_id: order.stripe_payment_intent_id
    }));
  } catch (error) {
    console.error('Error fetching recent transactions:', error);
    return [];
  }
}

/**
 * Get revenue data for charts
 */
export async function getRevenueData(days: number = 30): Promise<RevenueData[]> {
  try {
    const startDate = new Date();
    startDate.setDate(startDate.getDate() - days);

    const { data: orders, error } = await supabase
      .from('orders')
      .select('total_amount, financial_status, created_at')
      .gte('created_at', startDate.toISOString())
      .order('created_at', { ascending: true });

    if (error) throw error;

    // Group by date
    const revenueByDate = new Map<string, { revenue: number; orders: number; refunds: number }>();

    orders?.forEach(order => {
      const date = new Date(order.created_at).toISOString().split('T')[0];
      const existing = revenueByDate.get(date) || { revenue: 0, orders: 0, refunds: 0 };
      
      if (order.financial_status === 'refunded') {
        existing.refunds += order.total_amount / 100;
      } else if (order.financial_status === 'paid' || order.financial_status === 'partially_refunded') {
        existing.revenue += order.total_amount / 100;
        existing.orders += 1;
      }
      
      revenueByDate.set(date, existing);
    });

    // Convert to array and fill missing dates
    const result: RevenueData[] = [];
    const currentDate = new Date(startDate);
    
    while (currentDate <= new Date()) {
      const dateStr = currentDate.toISOString().split('T')[0];
      const data = revenueByDate.get(dateStr) || { revenue: 0, orders: 0, refunds: 0 };
      
      result.push({
        date: dateStr,
        revenue: data.revenue,
        orders: data.orders,
        refunds: data.refunds
      });
      
      currentDate.setDate(currentDate.getDate() + 1);
    }

    return result;
  } catch (error) {
    console.error('Error fetching revenue data:', error);
    return [];
  }
}

/**
 * Get payment method breakdown
 */
export async function getPaymentMethodBreakdown(): Promise<Record<string, number>> {
  try {
    const { data, error } = await supabase
      .from('orders')
      .select('stripe_payment_intent_id, total_amount')
      .in('financial_status', ['paid', 'partially_refunded']);

    if (error) throw error;

    const breakdown: Record<string, number> = {
      stripe: 0,
      other: 0
    };

    data?.forEach(order => {
      if (order.stripe_payment_intent_id) {
        breakdown.stripe += order.total_amount / 100;
      } else {
        breakdown.other += order.total_amount / 100;
      }
    });

    return breakdown;
  } catch (error) {
    console.error('Error fetching payment method breakdown:', error);
    return { stripe: 0, other: 0 };
  }
}

/**
 * Get tax summary by region
 */
export async function getTaxSummary(): Promise<Record<string, number>> {
  try {
    const { data, error } = await supabase
      .from('orders')
      .select('total_amount, shipping_address')
      .in('financial_status', ['paid', 'partially_refunded']);

    if (error) throw error;

    const taxByState: Record<string, number> = {};

    data?.forEach(order => {
      const state = order.shipping_address?.state || 'Unknown';
      const estimatedTax = (order.total_amount * 0.085) / 100; // 8.5% estimate
      taxByState[state] = (taxByState[state] || 0) + estimatedTax;
    });

    return taxByState;
  } catch (error) {
    console.error('Error fetching tax summary:', error);
    return {};
  }
}

/**
 * Calculate and update processing fees for an order
 */
export async function calculateProcessingFees(amount: number, paymentMethod: string = 'stripe'): number {
  // Stripe: 2.9% + $0.30
  // PayPal: 2.99% + $0.49
  // Others: 3% flat estimate
  
  switch (paymentMethod.toLowerCase()) {
    case 'stripe':
      return amount * 0.029 + 0.30;
    case 'paypal':
      return amount * 0.0299 + 0.49;
    default:
      return amount * 0.03;
  }
}

/**
 * Get financial metrics for a specific date range
 */
export async function getFinancialMetrics(startDate: Date, endDate: Date) {
  try {
    const { data: orders, error } = await supabase
      .from('orders')
      .select('*')
      .gte('created_at', startDate.toISOString())
      .lte('created_at', endDate.toISOString());

    if (error) throw error;

    // Calculate various metrics
    const metrics = {
      grossRevenue: 0,
      netRevenue: 0,
      totalOrders: 0,
      completedOrders: 0,
      refundedAmount: 0,
      averageOrderValue: 0,
      conversionRate: 0,
      processingFees: 0
    };

    orders?.forEach(order => {
      metrics.totalOrders++;
      
      if (order.financial_status === 'paid') {
        metrics.grossRevenue += order.total_amount / 100;
        metrics.completedOrders++;
        const fees = calculateProcessingFees(order.total_amount / 100);
        metrics.processingFees += fees;
        metrics.netRevenue += (order.total_amount / 100) - fees;
      } else if (order.financial_status === 'refunded') {
        metrics.refundedAmount += order.total_amount / 100;
      } else if (order.financial_status === 'partially_refunded') {
        metrics.grossRevenue += order.total_amount / 100;
        metrics.completedOrders++;
        // You might want to track partial refund amounts separately
      }
    });

    if (metrics.completedOrders > 0) {
      metrics.averageOrderValue = metrics.grossRevenue / metrics.completedOrders;
      metrics.conversionRate = (metrics.completedOrders / metrics.totalOrders) * 100;
    }

    return metrics;
  } catch (error) {
    console.error('Error fetching financial metrics:', error);
    throw error;
  }
}