-- Check if user_profiles table already exists and its structure
DO $$
BEGIN
    -- Check if table exists
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'user_profiles') THEN
        RAISE NOTICE 'user_profiles table already exists';
        
        -- Show current columns
        RAISE NOTICE 'Current columns in user_profiles:';
        FOR rec IN 
            SELECT column_name, data_type, is_nullable 
            FROM information_schema.columns 
            WHERE table_schema = 'public' AND table_name = 'user_profiles'
            ORDER BY ordinal_position
        LOOP
            RAISE NOTICE '  - %: % (nullable: %)', rec.column_name, rec.data_type, rec.is_nullable;
        END LOOP;
    ELSE
        RAISE NOTICE 'user_profiles table does NOT exist';
    END IF;
END $$;

-- Check existing policies
SELECT 
    schemaname,
    tablename,
    policyname,
    permissive,
    roles,
    cmd,
    qual
FROM pg_policies
WHERE tablename = 'user_profiles'
ORDER BY policyname;

-- Check current table structure
SELECT 
    column_name,
    data_type,
    column_default,
    is_nullable
FROM information_schema.columns
WHERE table_schema = 'public' 
AND table_name = 'user_profiles'
ORDER BY ordinal_position;