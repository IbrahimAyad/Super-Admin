-- =====================================================
-- ADD REMAINING COLUMNS TO CUSTOMERS TABLE
-- Run this to add the missing columns
-- =====================================================

-- Add missing marketing and tier columns
ALTER TABLE customers 
ADD COLUMN IF NOT EXISTS accepts_email_marketing BOOLEAN DEFAULT false,
ADD COLUMN IF NOT EXISTS accepts_sms_marketing BOOLEAN DEFAULT false,
ADD COLUMN IF NOT EXISTS customer_tier VARCHAR(50) DEFAULT 'Bronze',
ADD COLUMN IF NOT EXISTS engagement_score INTEGER DEFAULT 0,
ADD COLUMN IF NOT EXISTS repeat_customer BOOLEAN DEFAULT false,
ADD COLUMN IF NOT EXISTS vip_status BOOLEAN DEFAULT false,
ADD COLUMN IF NOT EXISTS primary_occasion VARCHAR(50),
ADD COLUMN IF NOT EXISTS first_purchase_date DATE,
ADD COLUMN IF NOT EXISTS last_purchase_date DATE,
ADD COLUMN IF NOT EXISTS days_since_last_purchase INTEGER,
ADD COLUMN IF NOT EXISTS tags TEXT,
ADD COLUMN IF NOT EXISTS shipping_address JSONB;

-- Verify columns were added
SELECT 
  column_name,
  data_type
FROM information_schema.columns
WHERE table_name = 'customers'
AND column_name IN (
  'accepts_email_marketing',
  'accepts_sms_marketing', 
  'customer_tier',
  'vip_status'
)
ORDER BY ordinal_position;