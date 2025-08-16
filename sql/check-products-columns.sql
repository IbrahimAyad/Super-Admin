-- Check what columns exist in the products table
SELECT 
    column_name, 
    data_type, 
    character_maximum_length,
    is_nullable
FROM information_schema.columns 
WHERE table_name = 'products'
ORDER BY ordinal_position;

-- Check if color_name exists anywhere
SELECT table_name, column_name
FROM information_schema.columns 
WHERE column_name IN ('color_name', 'color_family')
ORDER BY table_name;