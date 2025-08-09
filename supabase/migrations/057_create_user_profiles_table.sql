-- Create user_profiles table for registered/authenticated users
-- This table stores user preferences, size profiles, style preferences, and saved data
-- Separate from customers table which tracks all purchasers (guest + registered)

-- Create the user_profiles table
CREATE TABLE IF NOT EXISTS public.user_profiles (
  -- Primary key matches auth.users.id for 1:1 relationship
  id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  
  -- Basic profile information
  email TEXT NOT NULL,
  full_name TEXT,
  display_name TEXT,
  avatar_url TEXT,
  phone TEXT,
  date_of_birth DATE,
  
  -- Size profile (JSON for flexibility and future expansion)
  size_profile JSONB DEFAULT '{
    "chest": null,
    "waist": null,
    "inseam": null,
    "neck": null,
    "sleeve": null,
    "shoe_size": null,
    "preferred_fit": null,
    "notes": null
  }'::jsonb,
  
  -- Style preferences (JSON for AI recommendations in future)
  style_preferences JSONB DEFAULT '{
    "preferred_colors": [],
    "preferred_styles": [],
    "occasions": [],
    "brands": [],
    "avoid_materials": [],
    "price_range": null,
    "notes": null
  }'::jsonb,
  
  -- Saved data (arrays for multiple items)
  saved_addresses JSONB DEFAULT '[]'::jsonb,
  saved_payment_methods JSONB DEFAULT '[]'::jsonb, -- Tokenized, never store raw card data
  wishlist_items JSONB DEFAULT '[]'::jsonb,
  
  -- User preferences
  notification_preferences JSONB DEFAULT '{
    "email_marketing": true,
    "email_orders": true,
    "email_recommendations": true,
    "sms_marketing": false,
    "sms_orders": false
  }'::jsonb,
  
  -- Onboarding and account status
  onboarding_completed BOOLEAN DEFAULT false,
  profile_completed_at TIMESTAMPTZ,
  last_login_at TIMESTAMPTZ,
  
  -- Timestamps
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Create indexes for performance
CREATE INDEX idx_user_profiles_email ON public.user_profiles(email);
CREATE INDEX idx_user_profiles_created_at ON public.user_profiles(created_at);
CREATE INDEX idx_user_profiles_onboarding ON public.user_profiles(onboarding_completed);

-- Enable Row Level Security
ALTER TABLE public.user_profiles ENABLE ROW LEVEL SECURITY;

-- Create RLS policies

-- Users can view their own profile
CREATE POLICY "Users can view own profile" 
  ON public.user_profiles 
  FOR SELECT 
  USING (auth.uid() = id);

-- Users can update their own profile
CREATE POLICY "Users can update own profile" 
  ON public.user_profiles 
  FOR UPDATE 
  USING (auth.uid() = id);

-- Users can insert their own profile (on signup)
CREATE POLICY "Users can create own profile" 
  ON public.user_profiles 
  FOR INSERT 
  WITH CHECK (auth.uid() = id);

-- Admin users can view all profiles
CREATE POLICY "Admins can view all profiles" 
  ON public.user_profiles 
  FOR SELECT 
  USING (
    EXISTS (
      SELECT 1 FROM public.admin_users 
      WHERE admin_users.user_id = auth.uid() 
      AND admin_users.is_active = true
    )
  );

-- Admin users can update all profiles
CREATE POLICY "Admins can update all profiles" 
  ON public.user_profiles 
  FOR UPDATE 
  USING (
    EXISTS (
      SELECT 1 FROM public.admin_users 
      WHERE admin_users.user_id = auth.uid() 
      AND admin_users.is_active = true
      AND admin_users.role IN ('super_admin', 'admin')
    )
  );

-- Create function to automatically update updated_at
CREATE OR REPLACE FUNCTION update_user_profiles_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger for updated_at
CREATE TRIGGER update_user_profiles_updated_at
  BEFORE UPDATE ON public.user_profiles
  FOR EACH ROW
  EXECUTE FUNCTION update_user_profiles_updated_at();

-- Create function to auto-create profile on user signup
CREATE OR REPLACE FUNCTION create_profile_for_new_user()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO public.user_profiles (id, email)
  VALUES (NEW.id, NEW.email)
  ON CONFLICT (id) DO NOTHING;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create trigger to auto-create profile when user signs up
CREATE TRIGGER create_profile_on_signup
  AFTER INSERT ON auth.users
  FOR EACH ROW
  EXECUTE FUNCTION create_profile_for_new_user();

-- Create profiles for existing users (safe migration)
INSERT INTO public.user_profiles (id, email)
SELECT id, email FROM auth.users
ON CONFLICT (id) DO NOTHING;

-- Add helpful comments
COMMENT ON TABLE public.user_profiles IS 'Stores profile data for registered/authenticated users including size profiles and style preferences';
COMMENT ON COLUMN public.user_profiles.size_profile IS 'JSON object storing user measurements for personalized sizing recommendations';
COMMENT ON COLUMN public.user_profiles.style_preferences IS 'JSON object storing style preferences for AI-powered recommendations';
COMMENT ON COLUMN public.user_profiles.saved_addresses IS 'Array of saved shipping/billing addresses';
COMMENT ON COLUMN public.user_profiles.saved_payment_methods IS 'Array of tokenized payment methods - never store raw card data';
COMMENT ON COLUMN public.user_profiles.wishlist_items IS 'Array of product IDs saved to wishlist';

-- Grant necessary permissions
GRANT SELECT ON public.user_profiles TO anon;
GRANT ALL ON public.user_profiles TO authenticated;
GRANT ALL ON public.user_profiles TO service_role;

-- Create helper functions for the website

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
    size_profile = size_profile || new_size_profile,
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
    style_preferences = style_preferences || new_preferences,
    updated_at = NOW()
  WHERE id = user_id;
  
  RETURN new_preferences;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;