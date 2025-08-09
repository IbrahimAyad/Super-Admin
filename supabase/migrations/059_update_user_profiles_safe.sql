-- Safe migration to update existing user_profiles table with new fields
-- This migration adds missing columns without breaking existing structure

-- Add new columns if they don't exist
DO $$
BEGIN
    -- Add display_name if missing
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_schema = 'public' AND table_name = 'user_profiles' AND column_name = 'display_name') THEN
        ALTER TABLE public.user_profiles ADD COLUMN display_name TEXT;
    END IF;

    -- Add avatar_url if missing
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_schema = 'public' AND table_name = 'user_profiles' AND column_name = 'avatar_url') THEN
        ALTER TABLE public.user_profiles ADD COLUMN avatar_url TEXT;
    END IF;

    -- Add phone if missing
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_schema = 'public' AND table_name = 'user_profiles' AND column_name = 'phone') THEN
        ALTER TABLE public.user_profiles ADD COLUMN phone TEXT;
    END IF;

    -- Add date_of_birth if missing
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_schema = 'public' AND table_name = 'user_profiles' AND column_name = 'date_of_birth') THEN
        ALTER TABLE public.user_profiles ADD COLUMN date_of_birth DATE;
    END IF;

    -- Add size_profile if missing
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_schema = 'public' AND table_name = 'user_profiles' AND column_name = 'size_profile') THEN
        ALTER TABLE public.user_profiles ADD COLUMN size_profile JSONB DEFAULT '{
            "chest": null,
            "waist": null,
            "inseam": null,
            "neck": null,
            "sleeve": null,
            "shoe_size": null,
            "preferred_fit": null,
            "notes": null
        }'::jsonb;
    END IF;

    -- Add style_preferences if missing
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_schema = 'public' AND table_name = 'user_profiles' AND column_name = 'style_preferences') THEN
        ALTER TABLE public.user_profiles ADD COLUMN style_preferences JSONB DEFAULT '{
            "preferred_colors": [],
            "preferred_styles": [],
            "occasions": [],
            "brands": [],
            "avoid_materials": [],
            "price_range": null,
            "notes": null
        }'::jsonb;
    END IF;

    -- Add saved_addresses if missing
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_schema = 'public' AND table_name = 'user_profiles' AND column_name = 'saved_addresses') THEN
        ALTER TABLE public.user_profiles ADD COLUMN saved_addresses JSONB DEFAULT '[]'::jsonb;
    END IF;

    -- Add saved_payment_methods if missing
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_schema = 'public' AND table_name = 'user_profiles' AND column_name = 'saved_payment_methods') THEN
        ALTER TABLE public.user_profiles ADD COLUMN saved_payment_methods JSONB DEFAULT '[]'::jsonb;
    END IF;

    -- Add wishlist_items if missing
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_schema = 'public' AND table_name = 'user_profiles' AND column_name = 'wishlist_items') THEN
        ALTER TABLE public.user_profiles ADD COLUMN wishlist_items JSONB DEFAULT '[]'::jsonb;
    END IF;

    -- Add notification_preferences if missing
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_schema = 'public' AND table_name = 'user_profiles' AND column_name = 'notification_preferences') THEN
        ALTER TABLE public.user_profiles ADD COLUMN notification_preferences JSONB DEFAULT '{
            "email_marketing": true,
            "email_orders": true,
            "email_recommendations": true,
            "sms_marketing": false,
            "sms_orders": false
        }'::jsonb;
    END IF;

    -- Add profile_completed_at if missing
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_schema = 'public' AND table_name = 'user_profiles' AND column_name = 'profile_completed_at') THEN
        ALTER TABLE public.user_profiles ADD COLUMN profile_completed_at TIMESTAMPTZ;
    END IF;

    -- Add last_login_at if missing
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_schema = 'public' AND table_name = 'user_profiles' AND column_name = 'last_login_at') THEN
        ALTER TABLE public.user_profiles ADD COLUMN last_login_at TIMESTAMPTZ;
    END IF;

    -- Add full_name if missing
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_schema = 'public' AND table_name = 'user_profiles' AND column_name = 'full_name') THEN
        ALTER TABLE public.user_profiles ADD COLUMN full_name TEXT;
    END IF;

    -- Add email if missing (though it should exist)
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_schema = 'public' AND table_name = 'user_profiles' AND column_name = 'email') THEN
        ALTER TABLE public.user_profiles ADD COLUMN email TEXT;
        -- Update email from auth.users
        UPDATE public.user_profiles up
        SET email = au.email
        FROM auth.users au
        WHERE up.id = au.id AND up.email IS NULL;
    END IF;
END $$;

-- Create indexes if they don't exist
CREATE INDEX IF NOT EXISTS idx_user_profiles_email ON public.user_profiles(email);
CREATE INDEX IF NOT EXISTS idx_user_profiles_created_at ON public.user_profiles(created_at);
CREATE INDEX IF NOT EXISTS idx_user_profiles_onboarding ON public.user_profiles(onboarding_completed);

-- Enable RLS if not already enabled
ALTER TABLE public.user_profiles ENABLE ROW LEVEL SECURITY;

-- Create or replace helper functions (safe to run multiple times)

-- Function to get user profile with customer data if linked
CREATE OR REPLACE FUNCTION get_user_profile_with_customer_data(user_id UUID)
RETURNS JSON AS $$
DECLARE
  profile_data JSON;
BEGIN
  SELECT json_build_object(
    'profile', row_to_json(up.*),
    'customer', row_to_json(c.*)
  ) INTO profile_data
  FROM public.user_profiles up
  LEFT JOIN public.customers c ON c.email = up.email
  WHERE up.id = user_id;
  
  RETURN profile_data;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to update size profile
CREATE OR REPLACE FUNCTION update_size_profile(
  user_id UUID,
  new_size_profile JSONB
)
RETURNS JSONB AS $$
BEGIN
  UPDATE public.user_profiles
  SET 
    size_profile = COALESCE(size_profile, '{}'::jsonb) || new_size_profile,
    updated_at = NOW()
  WHERE id = user_id;
  
  RETURN new_size_profile;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to update style preferences
CREATE OR REPLACE FUNCTION update_style_preferences(
  user_id UUID,
  new_preferences JSONB
)
RETURNS JSONB AS $$
BEGIN
  UPDATE public.user_profiles
  SET 
    style_preferences = COALESCE(style_preferences, '{}'::jsonb) || new_preferences,
    updated_at = NOW()
  WHERE id = user_id;
  
  RETURN new_preferences;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Add comments for documentation
COMMENT ON COLUMN public.user_profiles.size_profile IS 'JSON object storing user measurements for personalized sizing recommendations';
COMMENT ON COLUMN public.user_profiles.style_preferences IS 'JSON object storing style preferences for AI-powered recommendations';
COMMENT ON COLUMN public.user_profiles.saved_addresses IS 'Array of saved shipping/billing addresses';
COMMENT ON COLUMN public.user_profiles.saved_payment_methods IS 'Array of tokenized payment methods - never store raw card data';
COMMENT ON COLUMN public.user_profiles.wishlist_items IS 'Array of product IDs saved to wishlist';

-- Create profiles for any existing users that don't have one
INSERT INTO public.user_profiles (id, email)
SELECT id, email FROM auth.users
WHERE NOT EXISTS (
    SELECT 1 FROM public.user_profiles WHERE user_profiles.id = auth.users.id
)
ON CONFLICT (id) DO NOTHING;

-- Show summary of changes
DO $$
DECLARE
    col_count INTEGER;
BEGIN
    SELECT COUNT(*) INTO col_count
    FROM information_schema.columns
    WHERE table_schema = 'public' AND table_name = 'user_profiles';
    
    RAISE NOTICE 'user_profiles table now has % columns', col_count;
    RAISE NOTICE 'Migration completed successfully. New fields added for size profile and style preferences.';
END $$;