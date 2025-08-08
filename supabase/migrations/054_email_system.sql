-- ============================================
-- EMAIL SYSTEM SETUP
-- ============================================

-- Email Logs Table
CREATE TABLE IF NOT EXISTS email_logs (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  to_email TEXT NOT NULL,
  subject TEXT NOT NULL,
  template VARCHAR(50),
  status VARCHAR(20) DEFAULT 'pending',
  resend_id TEXT,
  error TEXT,
  metadata JSONB DEFAULT '{}',
  created_at TIMESTAMPTZ DEFAULT NOW(),
  sent_at TIMESTAMPTZ,
  
  -- Indexes
  INDEX idx_email_logs_status (status),
  INDEX idx_email_logs_created (created_at DESC),
  INDEX idx_email_logs_template (template)
);

-- Email Templates Table (for custom templates)
CREATE TABLE IF NOT EXISTS email_templates (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  name VARCHAR(50) UNIQUE NOT NULL,
  subject TEXT NOT NULL,
  html_template TEXT NOT NULL,
  text_template TEXT,
  variables JSONB DEFAULT '[]',
  active BOOLEAN DEFAULT true,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Email Queue Table (for scheduled emails)
CREATE TABLE IF NOT EXISTS email_queue (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  to_email TEXT NOT NULL,
  subject TEXT NOT NULL,
  template VARCHAR(50),
  data JSONB DEFAULT '{}',
  scheduled_for TIMESTAMPTZ DEFAULT NOW(),
  status VARCHAR(20) DEFAULT 'pending',
  attempts INTEGER DEFAULT 0,
  last_attempt_at TIMESTAMPTZ,
  sent_at TIMESTAMPTZ,
  error TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  
  -- Indexes
  INDEX idx_email_queue_status (status),
  INDEX idx_email_queue_scheduled (scheduled_for),
  INDEX idx_email_queue_attempts (attempts)
);

-- Insert default email templates
INSERT INTO email_templates (name, subject, html_template, variables) VALUES
(
  'order_confirmation',
  'Order Confirmation - #{orderNumber}',
  '<h1>Thank you for your order!</h1><p>Order #{orderNumber} has been confirmed.</p>',
  '["orderNumber", "customerName", "items", "totalAmount"]'::jsonb
),
(
  'order_shipped',
  'Your Order Has Shipped - #{orderNumber}',
  '<h1>Your order is on its way!</h1><p>Track your package: {trackingUrl}</p>',
  '["orderNumber", "trackingNumber", "trackingUrl", "carrier"]'::jsonb
),
(
  'low_stock_alert',
  'Low Stock Alert - {productName}',
  '<h1>Low Stock Warning</h1><p>{productName} has only {currentStock} units remaining.</p>',
  '["productName", "sku", "currentStock", "threshold"]'::jsonb
)
ON CONFLICT (name) DO NOTHING;

-- Function to queue an email
CREATE OR REPLACE FUNCTION queue_email(
  p_to_email TEXT,
  p_subject TEXT,
  p_template VARCHAR(50),
  p_data JSONB,
  p_scheduled_for TIMESTAMPTZ DEFAULT NOW()
)
RETURNS UUID AS $$
DECLARE
  v_email_id UUID;
BEGIN
  INSERT INTO email_queue (
    to_email,
    subject,
    template,
    data,
    scheduled_for
  ) VALUES (
    p_to_email,
    p_subject,
    p_template,
    p_data,
    p_scheduled_for
  ) RETURNING id INTO v_email_id;
  
  RETURN v_email_id;
END;
$$ LANGUAGE plpgsql;

-- Function to process email queue
CREATE OR REPLACE FUNCTION process_email_queue()
RETURNS INTEGER AS $$
DECLARE
  v_processed INTEGER := 0;
  v_email RECORD;
BEGIN
  -- Get pending emails that are due
  FOR v_email IN 
    SELECT * FROM email_queue 
    WHERE status = 'pending' 
      AND scheduled_for <= NOW()
      AND attempts < 3
    ORDER BY scheduled_for
    LIMIT 10
  LOOP
    -- Update attempt count
    UPDATE email_queue 
    SET 
      attempts = attempts + 1,
      last_attempt_at = NOW()
    WHERE id = v_email.id;
    
    -- Here you would trigger the Edge Function to send the email
    -- For now, we just mark it as ready to send
    
    v_processed := v_processed + 1;
  END LOOP;
  
  RETURN v_processed;
END;
$$ LANGUAGE plpgsql;

-- Trigger to send email notifications on order status changes
CREATE OR REPLACE FUNCTION send_order_status_email()
RETURNS TRIGGER AS $$
BEGIN
  -- Send email when order is confirmed
  IF NEW.status = 'confirmed' AND OLD.status != 'confirmed' THEN
    PERFORM queue_email(
      COALESCE(
        (SELECT email FROM customers WHERE id = NEW.customer_id),
        NEW.guest_email
      ),
      'Order Confirmation - #' || NEW.order_number,
      'order_confirmation',
      jsonb_build_object(
        'orderId', NEW.id,
        'orderNumber', NEW.order_number,
        'totalAmount', NEW.total_amount
      )
    );
  END IF;
  
  -- Send email when order is shipped
  IF NEW.status = 'shipped' AND OLD.status != 'shipped' AND NEW.tracking_number IS NOT NULL THEN
    PERFORM queue_email(
      COALESCE(
        (SELECT email FROM customers WHERE id = NEW.customer_id),
        NEW.guest_email
      ),
      'Your Order Has Shipped - #' || NEW.order_number,
      'order_shipped',
      jsonb_build_object(
        'orderId', NEW.id,
        'orderNumber', NEW.order_number,
        'trackingNumber', NEW.tracking_number,
        'carrier', NEW.carrier_name
      )
    );
  END IF;
  
  -- Send email when order is cancelled
  IF NEW.status = 'cancelled' AND OLD.status != 'cancelled' THEN
    PERFORM queue_email(
      COALESCE(
        (SELECT email FROM customers WHERE id = NEW.customer_id),
        NEW.guest_email
      ),
      'Order Cancelled - #' || NEW.order_number,
      'order_cancelled',
      jsonb_build_object(
        'orderId', NEW.id,
        'orderNumber', NEW.order_number,
        'reason', NEW.cancellation_reason
      )
    );
  END IF;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create the trigger
CREATE TRIGGER trigger_send_order_status_email
AFTER UPDATE OF status ON orders
FOR EACH ROW
EXECUTE FUNCTION send_order_status_email();

-- RLS Policies
ALTER TABLE email_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE email_templates ENABLE ROW LEVEL SECURITY;
ALTER TABLE email_queue ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Admin can manage email logs" ON email_logs
  FOR ALL USING (true);

CREATE POLICY "Admin can manage email templates" ON email_templates
  FOR ALL USING (true);

CREATE POLICY "Admin can manage email queue" ON email_queue
  FOR ALL USING (true);

-- Grants
GRANT ALL ON email_logs TO authenticated;
GRANT ALL ON email_templates TO authenticated;
GRANT ALL ON email_queue TO authenticated;
GRANT EXECUTE ON FUNCTION queue_email(TEXT, TEXT, VARCHAR(50), JSONB, TIMESTAMPTZ) TO authenticated;
GRANT EXECUTE ON FUNCTION process_email_queue() TO authenticated;