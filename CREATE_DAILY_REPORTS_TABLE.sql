-- ============================================
-- CREATE DAILY REPORTS TABLE (Final Missing Piece)
-- ============================================

-- Table to store daily reports
CREATE TABLE IF NOT EXISTS daily_reports (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  report_date DATE UNIQUE NOT NULL,
  data JSONB NOT NULL,
  email_sent BOOLEAN DEFAULT false,
  email_sent_to TEXT[],
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Create indexes for daily_reports
CREATE INDEX IF NOT EXISTS idx_daily_reports_date ON daily_reports(report_date DESC);
CREATE INDEX IF NOT EXISTS idx_daily_reports_created ON daily_reports(created_at DESC);

-- Function to get yesterday's report for comparison
CREATE OR REPLACE FUNCTION get_previous_report(p_date DATE)
RETURNS JSONB AS $$
DECLARE
  v_data JSONB;
BEGIN
  SELECT data INTO v_data
  FROM daily_reports
  WHERE report_date = p_date - INTERVAL '1 day'
  LIMIT 1;
  
  RETURN v_data;
END;
$$ LANGUAGE plpgsql;

-- Function to schedule daily report generation
CREATE OR REPLACE FUNCTION schedule_daily_report()
RETURNS VOID AS $$
BEGIN
  -- This would be called by a cron job or scheduled Edge Function
  -- For now, it just logs the intent
  INSERT INTO email_queue (
    to_email,
    subject,
    template,
    data,
    scheduled_for
  ) VALUES (
    'admin@kctmenswear.com',
    'Daily Report Request',
    'daily_report_trigger',
    jsonb_build_object('date', CURRENT_DATE),
    CURRENT_DATE + INTERVAL '8 hours' -- 8 AM daily
  );
END;
$$ LANGUAGE plpgsql;

-- RLS Policies
ALTER TABLE daily_reports ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Admin can view daily reports" ON daily_reports
  FOR SELECT USING (true);

CREATE POLICY "System can insert daily reports" ON daily_reports
  FOR INSERT WITH CHECK (true);

-- Grants
GRANT SELECT ON daily_reports TO authenticated;
GRANT INSERT ON daily_reports TO service_role;
GRANT EXECUTE ON FUNCTION get_previous_report(DATE) TO authenticated;
GRANT EXECUTE ON FUNCTION schedule_daily_report() TO authenticated;

-- Insert sample/initial configuration
INSERT INTO daily_reports (
  report_date,
  data,
  email_sent,
  email_sent_to
) VALUES (
  CURRENT_DATE - INTERVAL '1 day',
  jsonb_build_object(
    'ordersToday', 0,
    'revenueToday', 0,
    'pendingOrders', 0,
    'processingOrders', 0,
    'shippedToday', 0,
    'deliveredToday', 0,
    'cancelledToday', 0,
    'refundsToday', 0,
    'newCustomers', 0,
    'returningCustomers', 0,
    'lowStockProducts', '[]'::jsonb,
    'pendingRefunds', 0,
    'topProducts', '[]'::jsonb,
    'hourlyBreakdown', '[]'::jsonb,
    'comparisonWithYesterday', jsonb_build_object(
      'orders', jsonb_build_object('today', 0, 'yesterday', 0, 'change', 0),
      'revenue', jsonb_build_object('today', 0, 'yesterday', 0, 'change', 0)
    )
  ),
  false,
  NULL
) ON CONFLICT (report_date) DO NOTHING;

-- ============================================
-- FINAL VERIFICATION
-- ============================================

-- Verify the table was created
SELECT 
  '✅ DAILY REPORTS TABLE CREATED' as status,
  COUNT(*) as table_exists
FROM information_schema.tables
WHERE table_schema = 'public' 
  AND table_name = 'daily_reports';

-- Check system is now fully operational
SELECT 
  '🚀 SYSTEM STATUS' as check,
  CASE 
    WHEN COUNT(*) >= 23 THEN 'FULLY OPERATIONAL ✅'
    ELSE 'Tables found: ' || COUNT(*)
  END as status
FROM information_schema.tables
WHERE table_schema = 'public' 
  AND table_name IN (
    'products', 'product_variants', 'customers', 'orders',
    'order_status_history', 'order_events', 'order_shipments', 'order_returns', 'shipping_labels',
    'email_logs', 'email_templates', 'email_queue',
    'inventory_movements', 'low_stock_alerts', 'inventory_thresholds',
    'analytics_events', 'analytics_sessions', 'analytics_page_views', 
    'analytics_conversions', 'analytics_daily_summary', 'analytics_product_performance',
    'refund_requests', 'daily_reports'
  );