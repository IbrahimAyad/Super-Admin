-- Add missing fields to product_variants table
-- These fields are expected by the frontend

-- Add option1 field (for sizes)
ALTER TABLE public.product_variants 
ADD COLUMN IF NOT EXISTS option1 TEXT;

-- Add option2 field (for colors)
ALTER TABLE public.product_variants 
ADD COLUMN IF NOT EXISTS option2 TEXT;

-- Note: The product_variants table doesn't have size/color or name columns
-- The frontend will need to populate option1/option2 when creating variants
-- For now, we'll leave these fields NULL and they can be populated later

-- Add available boolean field (computed based on inventory)
ALTER TABLE public.product_variants
ADD COLUMN IF NOT EXISTS available BOOLEAN GENERATED ALWAYS AS (
    COALESCE(inventory_quantity, 0) > 0
) STORED;

-- Create index for better performance on product detail queries
CREATE INDEX IF NOT EXISTS idx_product_variants_product_id 
ON public.product_variants(product_id);

-- Create index for slug-based lookups
CREATE INDEX IF NOT EXISTS idx_products_slug 
ON public.products(slug);

-- Verify the changes
SELECT 
    column_name,
    data_type,
    is_nullable,
    is_generated
FROM 
    information_schema.columns
WHERE 
    table_name = 'product_variants'
    AND table_schema = 'public'
ORDER BY 
    ordinal_position;

-- Show sample variant data with new fields
SELECT 
    pv.sku,
    pv.option1 as size,
    pv.option2 as color,
    pv.inventory_quantity,
    pv.available,
    p.name as product_name
FROM 
    public.product_variants pv
JOIN 
    public.products p ON pv.product_id = p.id
LIMIT 10;