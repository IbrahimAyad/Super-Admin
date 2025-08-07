-- ============================================
-- QUICK FIX FOR SUBCATEGORY COLUMN ISSUE
-- This addresses the immediate "subcategory column not found" error
-- ============================================

-- Check if subcategory column exists
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' 
        AND table_name = 'products' 
        AND column_name = 'subcategory'
    ) THEN
        -- Add the missing subcategory column
        ALTER TABLE public.products ADD COLUMN subcategory text;
        RAISE NOTICE 'SUCCESS: Added subcategory column to products table';
        
        -- Set a default value for existing products if needed
        UPDATE public.products 
        SET subcategory = category 
        WHERE subcategory IS NULL AND category IS NOT NULL;
        
        RAISE NOTICE 'SUCCESS: Set default subcategory values based on category';
    ELSE
        RAISE NOTICE 'INFO: subcategory column already exists';
    END IF;
END $$;

-- Verify the fix
SELECT 
    'Column Verification' as check_type,
    column_name,
    data_type,
    is_nullable
FROM information_schema.columns
WHERE table_schema = 'public' 
AND table_name = 'products' 
AND column_name IN ('category', 'subcategory')
ORDER BY column_name;