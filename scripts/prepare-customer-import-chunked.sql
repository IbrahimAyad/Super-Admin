-- =====================================================
-- CHUNKED VERSION FOR SLOW EXECUTION
-- Run each section one at a time if the full script is slow
-- =====================================================

-- STEP 1: Add basic columns first (run this first)
ALTER TABLE customers 
ADD COLUMN IF NOT EXISTS first_name VARCHAR(255),
ADD COLUMN IF NOT EXISTS last_name VARCHAR(255),
ADD COLUMN IF NOT EXISTS accepts_email_marketing BOOLEAN DEFAULT false,
ADD COLUMN IF NOT EXISTS accepts_sms_marketing BOOLEAN DEFAULT false;

-- Wait for completion, then run STEP 2

-- STEP 2: Add numeric columns
ALTER TABLE customers 
ADD COLUMN IF NOT EXISTS total_spent DECIMAL(10,2) DEFAULT 0,
ADD COLUMN IF NOT EXISTS total_orders INTEGER DEFAULT 0,
ADD COLUMN IF NOT EXISTS engagement_score INTEGER DEFAULT 0,
ADD COLUMN IF NOT EXISTS average_order_value DECIMAL(10,2) DEFAULT 0;

-- Wait for completion, then run STEP 3

-- STEP 3: Add status and tier columns
ALTER TABLE customers 
ADD COLUMN IF NOT EXISTS customer_tier VARCHAR(50) DEFAULT 'Bronze',
ADD COLUMN IF NOT EXISTS repeat_customer BOOLEAN DEFAULT false,
ADD COLUMN IF NOT EXISTS vip_status BOOLEAN DEFAULT false,
ADD COLUMN IF NOT EXISTS primary_occasion VARCHAR(50);

-- Wait for completion, then run STEP 4

-- STEP 4: Add date columns
ALTER TABLE customers 
ADD COLUMN IF NOT EXISTS first_purchase_date DATE,
ADD COLUMN IF NOT EXISTS last_purchase_date DATE,
ADD COLUMN IF NOT EXISTS days_since_last_purchase INTEGER;

-- Wait for completion, then run STEP 5

-- STEP 5: Add text columns
ALTER TABLE customers 
ADD COLUMN IF NOT EXISTS notes TEXT,
ADD COLUMN IF NOT EXISTS tags TEXT;

-- Wait for completion, then run STEP 6

-- STEP 6: Create basic indexes (one at a time if needed)
CREATE INDEX IF NOT EXISTS idx_customers_email ON customers(email);
CREATE INDEX IF NOT EXISTS idx_customers_tier ON customers(customer_tier);

-- Wait for completion, then run STEP 7

-- STEP 7: Create remaining indexes
CREATE INDEX IF NOT EXISTS idx_customers_vip ON customers(vip_status);
CREATE INDEX IF NOT EXISTS idx_customers_last_purchase ON customers(last_purchase_date DESC);

-- Wait for completion, then run STEP 8

-- STEP 8: Quick check - see what columns exist
SELECT 
  column_name,
  data_type
FROM information_schema.columns
WHERE table_name = 'customers'
AND column_name IN (
  'first_name', 'last_name', 'accepts_email_marketing',
  'total_spent', 'customer_tier', 'vip_status'
)
ORDER BY ordinal_position;

-- If all columns show, you're ready to import!