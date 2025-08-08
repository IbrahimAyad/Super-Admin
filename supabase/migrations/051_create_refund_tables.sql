-- ============================================
-- REFUND MANAGEMENT TABLES
-- Complete refund processing system
-- ============================================

-- Create refund_requests table if it doesn't exist
CREATE TABLE IF NOT EXISTS public.refund_requests (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    order_id UUID REFERENCES public.orders(id) ON DELETE CASCADE,
    customer_id UUID REFERENCES public.customers(id),
    
    -- Refund details
    refund_amount INTEGER NOT NULL, -- Amount in cents
    reason TEXT NOT NULL,
    status VARCHAR(20) DEFAULT 'pending' CHECK (status IN ('pending', 'approved', 'rejected', 'completed', 'failed')),
    
    -- Processing information
    stripe_refund_id VARCHAR(255),
    processed_amount INTEGER, -- Actual amount refunded (might be partial)
    processed_at TIMESTAMPTZ,
    processed_by UUID REFERENCES auth.users(id),
    processing_notes TEXT,
    internal_notes TEXT,
    
    -- Timestamps
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Create indexes for performance
CREATE INDEX IF NOT EXISTS idx_refund_requests_status ON public.refund_requests(status);
CREATE INDEX IF NOT EXISTS idx_refund_requests_order ON public.refund_requests(order_id);
CREATE INDEX IF NOT EXISTS idx_refund_requests_customer ON public.refund_requests(customer_id);
CREATE INDEX IF NOT EXISTS idx_refund_requests_created ON public.refund_requests(created_at DESC);

-- Add refund tracking columns to orders table if they don't exist
ALTER TABLE public.orders 
ADD COLUMN IF NOT EXISTS refund_status VARCHAR(20) DEFAULT 'none' CHECK (refund_status IN ('none', 'partial', 'full'));

ALTER TABLE public.orders 
ADD COLUMN IF NOT EXISTS total_refunded INTEGER DEFAULT 0;

-- Create payment_transactions table if it doesn't exist
CREATE TABLE IF NOT EXISTS public.payment_transactions (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    order_id UUID REFERENCES public.orders(id) ON DELETE CASCADE,
    
    -- Transaction details
    transaction_type VARCHAR(20) NOT NULL CHECK (transaction_type IN ('payment', 'refund', 'partial_refund', 'chargeback')),
    amount INTEGER NOT NULL, -- Amount in cents
    currency VARCHAR(3) DEFAULT 'usd',
    status VARCHAR(20) DEFAULT 'pending',
    
    -- Gateway information
    gateway VARCHAR(50) DEFAULT 'stripe',
    gateway_transaction_id VARCHAR(255),
    gateway_response JSONB,
    
    -- Metadata
    metadata JSONB DEFAULT '{}',
    
    -- Timestamps
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Create indexes for payment_transactions
CREATE INDEX IF NOT EXISTS idx_payment_transactions_order ON public.payment_transactions(order_id);
CREATE INDEX IF NOT EXISTS idx_payment_transactions_type ON public.payment_transactions(transaction_type);
CREATE INDEX IF NOT EXISTS idx_payment_transactions_gateway ON public.payment_transactions(gateway, gateway_transaction_id);

-- Enable RLS
ALTER TABLE public.refund_requests ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.payment_transactions ENABLE ROW LEVEL SECURITY;

-- RLS Policies for refund_requests
CREATE POLICY "Admin users can manage refund requests" ON public.refund_requests
    FOR ALL USING (auth.role() = 'authenticated');

CREATE POLICY "Customers can view their own refund requests" ON public.refund_requests
    FOR SELECT USING (
        auth.uid() = customer_id OR
        auth.uid() IN (
            SELECT customer_id FROM public.orders WHERE id = refund_requests.order_id
        )
    );

-- RLS Policies for payment_transactions
CREATE POLICY "Admin users can manage payment transactions" ON public.payment_transactions
    FOR ALL USING (auth.role() = 'authenticated');

CREATE POLICY "Customers can view their own payment transactions" ON public.payment_transactions
    FOR SELECT USING (
        auth.uid() IN (
            SELECT customer_id FROM public.orders WHERE id = payment_transactions.order_id
        )
    );

-- Function to update order refund status
CREATE OR REPLACE FUNCTION update_order_refund_status()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.status = 'completed' THEN
        UPDATE public.orders
        SET 
            total_refunded = COALESCE(total_refunded, 0) + NEW.processed_amount,
            refund_status = CASE 
                WHEN COALESCE(total_refunded, 0) + NEW.processed_amount >= total_amount THEN 'full'
                ELSE 'partial'
            END,
            updated_at = NOW()
        WHERE id = NEW.order_id;
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger for updating order refund status
DROP TRIGGER IF EXISTS trigger_update_order_refund_status ON public.refund_requests;
CREATE TRIGGER trigger_update_order_refund_status
    AFTER UPDATE OF status ON public.refund_requests
    FOR EACH ROW
    WHEN (NEW.status = 'completed')
    EXECUTE FUNCTION update_order_refund_status();

-- Insert some test data (optional - comment out in production)
-- INSERT INTO public.refund_requests (order_id, customer_id, refund_amount, reason, status)
-- SELECT 
--     o.id,
--     o.customer_id,
--     FLOOR(o.total_amount * 0.5), -- 50% refund for testing
--     'Customer requested refund',
--     'pending'
-- FROM public.orders o
-- LIMIT 2;