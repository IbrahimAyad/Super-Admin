-- =====================================================
-- KCT Menswear Wedding Management System
-- Database Schema Version 1.0.0
-- =====================================================

-- =====================================================
-- CORE WEDDING TABLES
-- =====================================================

-- Main wedding event table
CREATE TABLE IF NOT EXISTS public.weddings (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  
  -- Wedding identification
  wedding_code VARCHAR(10) UNIQUE NOT NULL, -- Unique code for groomsmen to join
  wedding_url_slug VARCHAR(100) UNIQUE, -- Custom URL slug (e.g., /wedding/smith-jones-2025)
  
  -- Couple information
  partner1_name VARCHAR(255) NOT NULL,
  partner1_email VARCHAR(255) NOT NULL,
  partner1_phone VARCHAR(20),
  partner2_name VARCHAR(255),
  partner2_email VARCHAR(255),
  partner2_phone VARCHAR(20),
  
  -- Wedding details
  wedding_date DATE NOT NULL,
  venue_name VARCHAR(255),
  venue_address TEXT,
  venue_city VARCHAR(100),
  venue_state VARCHAR(50),
  venue_country VARCHAR(50) DEFAULT 'US',
  venue_type VARCHAR(50), -- indoor, outdoor, beach, church, etc.
  
  -- Event details
  ceremony_time TIME,
  reception_time TIME,
  guest_count INTEGER,
  wedding_theme VARCHAR(100), -- classic, modern, rustic, beach, etc.
  color_scheme JSONB DEFAULT '[]', -- Array of color codes
  
  -- Style preferences
  formality_level VARCHAR(50), -- black-tie, formal, semi-formal, casual
  season VARCHAR(20), -- spring, summer, fall, winter
  preferred_styles JSONB DEFAULT '[]', -- Array of style preferences
  avoid_items JSONB DEFAULT '[]', -- Items/materials to avoid
  
  -- Budget and pricing
  estimated_budget DECIMAL(10,2),
  approved_budget DECIMAL(10,2),
  total_spent DECIMAL(10,2) DEFAULT 0,
  discount_percentage DECIMAL(5,2) DEFAULT 0,
  
  -- Status and timeline
  status VARCHAR(50) DEFAULT 'planning', -- planning, confirmed, in_production, ready, completed, cancelled
  created_by UUID REFERENCES auth.users(id),
  coordinator_id UUID REFERENCES public.admin_users(id), -- Assigned wedding coordinator
  
  -- Important dates
  selection_deadline DATE,
  measurement_deadline DATE,
  payment_deadline DATE,
  delivery_date DATE,
  
  -- Metadata
  notes TEXT,
  internal_notes TEXT, -- Staff only notes
  tags JSONB DEFAULT '[]',
  source VARCHAR(100), -- How they found us
  referral_code VARCHAR(50),
  
  -- Timestamps
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  completed_at TIMESTAMPTZ,
  cancelled_at TIMESTAMPTZ
);

-- Wedding party members (groomsmen, bridesmaids, etc.)
CREATE TABLE IF NOT EXISTS public.wedding_party_members (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  wedding_id UUID NOT NULL REFERENCES public.weddings(id) ON DELETE CASCADE,
  
  -- Member identification
  user_id UUID REFERENCES auth.users(id), -- If they create an account
  invite_code VARCHAR(20) UNIQUE, -- Unique code for joining
  
  -- Personal information
  first_name VARCHAR(100) NOT NULL,
  last_name VARCHAR(100) NOT NULL,
  email VARCHAR(255) NOT NULL,
  phone VARCHAR(20),
  
  -- Role in wedding
  role VARCHAR(50) NOT NULL, -- groom, best_man, groomsman, usher, father_of_bride, etc.
  party_side VARCHAR(20), -- partner1, partner2, both
  party_order INTEGER, -- Display order in lineup
  
  -- Status
  invitation_status VARCHAR(50) DEFAULT 'pending', -- pending, accepted, declined
  invitation_sent_at TIMESTAMPTZ,
  invitation_accepted_at TIMESTAMPTZ,
  
  -- Measurements and sizing
  measurement_status VARCHAR(50) DEFAULT 'pending', -- pending, submitted, confirmed, needs_update
  measurement_data JSONB DEFAULT '{}', -- Complete measurement profile
  size_profile JSONB DEFAULT '{}', -- Computed sizes for different items
  fit_preferences JSONB DEFAULT '{}',
  special_requirements TEXT,
  
  -- Outfit assignment
  outfit_status VARCHAR(50) DEFAULT 'pending', -- pending, selected, confirmed, ordered, delivered
  assigned_outfit JSONB DEFAULT '{}', -- Complete outfit details
  
  -- Financial
  individual_budget DECIMAL(10,2),
  amount_owed DECIMAL(10,2) DEFAULT 0,
  amount_paid DECIMAL(10,2) DEFAULT 0,
  payment_status VARCHAR(50) DEFAULT 'pending',
  
  -- Communication preferences
  communication_preferences JSONB DEFAULT '{
    "email": true,
    "sms": true,
    "reminders": true
  }',
  
  -- Timestamps
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  last_login_at TIMESTAMPTZ,
  
  UNIQUE(wedding_id, email)
);

-- Wedding outfits/looks - predefined or custom combinations
CREATE TABLE IF NOT EXISTS public.wedding_outfits (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  wedding_id UUID NOT NULL REFERENCES public.weddings(id) ON DELETE CASCADE,
  
  -- Outfit details
  name VARCHAR(255) NOT NULL,
  description TEXT,
  role_type VARCHAR(50), -- groom, groomsman, usher, etc.
  
  -- Items in outfit
  suit_product_id UUID REFERENCES public.products(id),
  shirt_product_id UUID REFERENCES public.products(id),
  tie_product_id UUID REFERENCES public.products(id),
  vest_product_id UUID REFERENCES public.products(id),
  shoes_product_id UUID REFERENCES public.products(id),
  accessories JSONB DEFAULT '[]', -- Array of accessory product IDs
  
  -- Styling details
  color_primary VARCHAR(50),
  color_secondary VARCHAR(50),
  color_accent VARCHAR(50),
  style_notes TEXT,
  
  -- Pricing
  rental_price DECIMAL(10,2),
  purchase_price DECIMAL(10,2),
  package_discount DECIMAL(5,2) DEFAULT 0,
  
  -- Status
  is_active BOOLEAN DEFAULT true,
  is_approved BOOLEAN DEFAULT false,
  approved_by UUID REFERENCES auth.users(id),
  approved_at TIMESTAMPTZ,
  
  -- Metadata
  image_urls JSONB DEFAULT '[]',
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Individual party member outfit selections
CREATE TABLE IF NOT EXISTS public.wedding_party_outfits (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  wedding_id UUID NOT NULL REFERENCES public.weddings(id) ON DELETE CASCADE,
  member_id UUID NOT NULL REFERENCES public.wedding_party_members(id) ON DELETE CASCADE,
  outfit_id UUID REFERENCES public.wedding_outfits(id),
  
  -- Individual item selections with sizes
  items JSONB NOT NULL DEFAULT '[]', -- Array of {product_id, variant_id, size, color, rental/purchase}
  
  -- Customizations
  alterations_needed JSONB DEFAULT '[]',
  monogram_text VARCHAR(10),
  special_requests TEXT,
  
  -- Pricing
  subtotal DECIMAL(10,2) NOT NULL DEFAULT 0,
  alterations_cost DECIMAL(10,2) DEFAULT 0,
  rush_fee DECIMAL(10,2) DEFAULT 0,
  discount_amount DECIMAL(10,2) DEFAULT 0,
  total_price DECIMAL(10,2) NOT NULL DEFAULT 0,
  
  -- Status
  status VARCHAR(50) DEFAULT 'draft', -- draft, confirmed, ordered, in_production, ready, delivered
  confirmed_at TIMESTAMPTZ,
  ordered_at TIMESTAMPTZ,
  
  -- Rental specific
  is_rental BOOLEAN DEFAULT false,
  rental_start_date DATE,
  rental_end_date DATE,
  return_status VARCHAR(50), -- pending, returned, late, damaged
  return_date DATE,
  
  -- Timestamps
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  
  UNIQUE(member_id)
);

-- Wedding orders - groups party member orders
CREATE TABLE IF NOT EXISTS public.wedding_orders (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  wedding_id UUID NOT NULL REFERENCES public.weddings(id) ON DELETE CASCADE,
  order_number VARCHAR(50) UNIQUE NOT NULL,
  
  -- Order details
  order_type VARCHAR(50) DEFAULT 'wedding', -- wedding, individual, mixed
  status VARCHAR(50) DEFAULT 'pending',
  
  -- Financial
  subtotal DECIMAL(10,2) NOT NULL DEFAULT 0,
  tax_amount DECIMAL(10,2) DEFAULT 0,
  shipping_amount DECIMAL(10,2) DEFAULT 0,
  discount_amount DECIMAL(10,2) DEFAULT 0,
  total_amount DECIMAL(10,2) NOT NULL DEFAULT 0,
  
  -- Payment
  payment_status VARCHAR(50) DEFAULT 'pending',
  payment_method VARCHAR(50),
  stripe_payment_intent_id VARCHAR(255),
  paid_at TIMESTAMPTZ,
  
  -- Delivery
  delivery_method VARCHAR(50), -- ship, pickup, mixed
  delivery_address JSONB,
  tracking_numbers JSONB DEFAULT '[]',
  
  -- Timestamps
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  confirmed_at TIMESTAMPTZ,
  shipped_at TIMESTAMPTZ,
  delivered_at TIMESTAMPTZ
);

-- Link party member outfits to orders
CREATE TABLE IF NOT EXISTS public.wedding_order_items (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  order_id UUID NOT NULL REFERENCES public.wedding_orders(id) ON DELETE CASCADE,
  party_outfit_id UUID NOT NULL REFERENCES public.wedding_party_outfits(id),
  member_id UUID NOT NULL REFERENCES public.wedding_party_members(id),
  
  -- Status for this specific item
  item_status VARCHAR(50) DEFAULT 'pending',
  
  -- Timestamps
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Wedding timeline and tasks
CREATE TABLE IF NOT EXISTS public.wedding_tasks (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  wedding_id UUID NOT NULL REFERENCES public.weddings(id) ON DELETE CASCADE,
  
  -- Task details
  task_type VARCHAR(100) NOT NULL, -- measurement_reminder, payment_due, fitting_scheduled, etc.
  title VARCHAR(255) NOT NULL,
  description TEXT,
  
  -- Assignment
  assigned_to_member UUID REFERENCES public.wedding_party_members(id),
  assigned_to_role VARCHAR(50), -- all, groom, groomsmen, specific role
  
  -- Timing
  due_date DATE,
  reminder_date DATE,
  
  -- Status
  status VARCHAR(50) DEFAULT 'pending', -- pending, in_progress, completed, overdue, cancelled
  completed_at TIMESTAMPTZ,
  completed_by UUID REFERENCES auth.users(id),
  
  -- Automation
  is_automated BOOLEAN DEFAULT false,
  automation_trigger VARCHAR(100), -- days_before_wedding, after_measurement, etc.
  
  -- Metadata
  priority VARCHAR(20) DEFAULT 'normal', -- low, normal, high, urgent
  notes TEXT,
  
  -- Timestamps
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Wedding communications log
CREATE TABLE IF NOT EXISTS public.wedding_communications (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  wedding_id UUID NOT NULL REFERENCES public.weddings(id) ON DELETE CASCADE,
  
  -- Communication details
  type VARCHAR(50) NOT NULL, -- email, sms, phone, in_person, system
  direction VARCHAR(20) NOT NULL, -- inbound, outbound
  
  -- Participants
  from_user UUID REFERENCES auth.users(id),
  to_member UUID REFERENCES public.wedding_party_members(id),
  to_role VARCHAR(50), -- all, groom, groomsmen, etc.
  
  -- Content
  subject VARCHAR(255),
  message TEXT NOT NULL,
  template_used VARCHAR(100),
  
  -- Status
  status VARCHAR(50) DEFAULT 'sent', -- draft, sent, delivered, read, failed
  delivered_at TIMESTAMPTZ,
  read_at TIMESTAMPTZ,
  
  -- Metadata
  metadata JSONB DEFAULT '{}',
  
  -- Timestamps
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Fitting appointments
CREATE TABLE IF NOT EXISTS public.wedding_fittings (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  wedding_id UUID NOT NULL REFERENCES public.weddings(id) ON DELETE CASCADE,
  member_id UUID REFERENCES public.wedding_party_members(id),
  
  -- Appointment details
  appointment_date DATE NOT NULL,
  appointment_time TIME NOT NULL,
  duration_minutes INTEGER DEFAULT 30,
  
  -- Location
  location_type VARCHAR(50), -- store, home, virtual
  location_details JSONB,
  
  -- Status
  status VARCHAR(50) DEFAULT 'scheduled', -- scheduled, confirmed, completed, cancelled, no_show
  
  -- Results
  notes TEXT,
  alterations_needed JSONB DEFAULT '[]',
  new_measurements JSONB,
  
  -- Staff
  assigned_staff UUID REFERENCES public.admin_users(id),
  
  -- Timestamps
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  confirmed_at TIMESTAMPTZ,
  completed_at TIMESTAMPTZ,
  cancelled_at TIMESTAMPTZ
);

-- =====================================================
-- INDEXES
-- =====================================================

-- Weddings indexes
CREATE INDEX idx_weddings_wedding_code ON public.weddings(wedding_code);
CREATE INDEX idx_weddings_wedding_date ON public.weddings(wedding_date);
CREATE INDEX idx_weddings_status ON public.weddings(status);
CREATE INDEX idx_weddings_coordinator ON public.weddings(coordinator_id);
CREATE INDEX idx_weddings_created_at ON public.weddings(created_at);

-- Party members indexes
CREATE INDEX idx_party_members_wedding ON public.wedding_party_members(wedding_id);
CREATE INDEX idx_party_members_user ON public.wedding_party_members(user_id);
CREATE INDEX idx_party_members_email ON public.wedding_party_members(email);
CREATE INDEX idx_party_members_role ON public.wedding_party_members(role);
CREATE INDEX idx_party_members_status ON public.wedding_party_members(invitation_status);

-- Outfits indexes
CREATE INDEX idx_party_outfits_wedding ON public.wedding_party_outfits(wedding_id);
CREATE INDEX idx_party_outfits_member ON public.wedding_party_outfits(member_id);
CREATE INDEX idx_party_outfits_status ON public.wedding_party_outfits(status);

-- Orders indexes
CREATE INDEX idx_wedding_orders_wedding ON public.wedding_orders(wedding_id);
CREATE INDEX idx_wedding_orders_number ON public.wedding_orders(order_number);
CREATE INDEX idx_wedding_orders_status ON public.wedding_orders(status);

-- Tasks indexes
CREATE INDEX idx_wedding_tasks_wedding ON public.wedding_tasks(wedding_id);
CREATE INDEX idx_wedding_tasks_due_date ON public.wedding_tasks(due_date);
CREATE INDEX idx_wedding_tasks_status ON public.wedding_tasks(status);

-- Communications indexes
CREATE INDEX idx_wedding_comms_wedding ON public.wedding_communications(wedding_id);
CREATE INDEX idx_wedding_comms_created ON public.wedding_communications(created_at);

-- =====================================================
-- ROW LEVEL SECURITY
-- =====================================================

-- Enable RLS on all tables
ALTER TABLE public.weddings ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.wedding_party_members ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.wedding_outfits ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.wedding_party_outfits ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.wedding_orders ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.wedding_order_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.wedding_tasks ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.wedding_communications ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.wedding_fittings ENABLE ROW LEVEL SECURITY;

-- Weddings policies
CREATE POLICY "Couples can view own wedding" ON public.weddings
  FOR SELECT USING (auth.uid() = created_by);

CREATE POLICY "Couples can update own wedding" ON public.weddings
  FOR UPDATE USING (auth.uid() = created_by);

CREATE POLICY "Staff can view all weddings" ON public.weddings
  FOR ALL USING (
    EXISTS (
      SELECT 1 FROM public.admin_users
      WHERE admin_users.user_id = auth.uid()
      AND admin_users.is_active = true
    )
  );

-- Party members policies
CREATE POLICY "Members can view own info" ON public.wedding_party_members
  FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Couples can manage party members" ON public.wedding_party_members
  FOR ALL USING (
    EXISTS (
      SELECT 1 FROM public.weddings
      WHERE weddings.id = wedding_id
      AND weddings.created_by = auth.uid()
    )
  );

CREATE POLICY "Staff can manage all party members" ON public.wedding_party_members
  FOR ALL USING (
    EXISTS (
      SELECT 1 FROM public.admin_users
      WHERE admin_users.user_id = auth.uid()
      AND admin_users.is_active = true
    )
  );

-- =====================================================
-- FUNCTIONS
-- =====================================================

-- Generate unique wedding code
CREATE OR REPLACE FUNCTION generate_wedding_code()
RETURNS VARCHAR(10) AS $$
DECLARE
  chars TEXT := 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
  result VARCHAR(10) := '';
  i INTEGER;
BEGIN
  FOR i IN 1..10 LOOP
    result := result || substr(chars, floor(random() * length(chars) + 1)::int, 1);
  END LOOP;
  RETURN result;
END;
$$ LANGUAGE plpgsql;

-- Auto-generate wedding code on insert
CREATE OR REPLACE FUNCTION set_wedding_code()
RETURNS TRIGGER AS $$
BEGIN
  IF NEW.wedding_code IS NULL THEN
    LOOP
      NEW.wedding_code := generate_wedding_code();
      EXIT WHEN NOT EXISTS (SELECT 1 FROM public.weddings WHERE wedding_code = NEW.wedding_code);
    END LOOP;
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_set_wedding_code
  BEFORE INSERT ON public.weddings
  FOR EACH ROW
  EXECUTE FUNCTION set_wedding_code();

-- Calculate wedding party statistics
CREATE OR REPLACE FUNCTION get_wedding_stats(wedding_uuid UUID)
RETURNS JSON AS $$
DECLARE
  stats JSON;
BEGIN
  SELECT json_build_object(
    'total_members', COUNT(*),
    'accepted_invites', COUNT(*) FILTER (WHERE invitation_status = 'accepted'),
    'measurements_complete', COUNT(*) FILTER (WHERE measurement_status = 'confirmed'),
    'outfits_confirmed', COUNT(*) FILTER (WHERE outfit_status = 'confirmed'),
    'total_amount', SUM(amount_owed),
    'paid_amount', SUM(amount_paid)
  ) INTO stats
  FROM public.wedding_party_members
  WHERE wedding_id = wedding_uuid;
  
  RETURN stats;
END;
$$ LANGUAGE plpgsql;

-- Auto-create tasks based on wedding date
CREATE OR REPLACE FUNCTION create_wedding_tasks()
RETURNS TRIGGER AS $$
BEGIN
  -- Create standard tasks based on wedding date
  -- 6 months before: Initial consultation
  INSERT INTO public.wedding_tasks (wedding_id, task_type, title, due_date, priority)
  VALUES (NEW.id, 'consultation', 'Schedule initial consultation', NEW.wedding_date - INTERVAL '6 months', 'high');
  
  -- 4 months before: Send invitations
  INSERT INTO public.wedding_tasks (wedding_id, task_type, title, due_date, priority)
  VALUES (NEW.id, 'invitations', 'Send party member invitations', NEW.wedding_date - INTERVAL '4 months', 'high');
  
  -- 3 months before: Finalize selections
  INSERT INTO public.wedding_tasks (wedding_id, task_type, title, due_date, priority)
  VALUES (NEW.id, 'selection', 'Finalize outfit selections', NEW.wedding_date - INTERVAL '3 months', 'high');
  
  -- 2 months before: Complete measurements
  INSERT INTO public.wedding_tasks (wedding_id, task_type, title, due_date, priority)
  VALUES (NEW.id, 'measurements', 'All measurements due', NEW.wedding_date - INTERVAL '2 months', 'urgent');
  
  -- 6 weeks before: Place order
  INSERT INTO public.wedding_tasks (wedding_id, task_type, title, due_date, priority)
  VALUES (NEW.id, 'order', 'Place final order', NEW.wedding_date - INTERVAL '6 weeks', 'urgent');
  
  -- 2 weeks before: Final fitting
  INSERT INTO public.wedding_tasks (wedding_id, task_type, title, due_date, priority)
  VALUES (NEW.id, 'fitting', 'Final fitting appointment', NEW.wedding_date - INTERVAL '2 weeks', 'high');
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_create_wedding_tasks
  AFTER INSERT ON public.weddings
  FOR EACH ROW
  EXECUTE FUNCTION create_wedding_tasks();

-- Update timestamps
CREATE OR REPLACE FUNCTION update_wedding_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_weddings_updated_at
  BEFORE UPDATE ON public.weddings
  FOR EACH ROW
  EXECUTE FUNCTION update_wedding_updated_at();

CREATE TRIGGER update_party_members_updated_at
  BEFORE UPDATE ON public.wedding_party_members
  FOR EACH ROW
  EXECUTE FUNCTION update_wedding_updated_at();

-- =====================================================
-- VIEWS
-- =====================================================

-- Wedding dashboard view
CREATE OR REPLACE VIEW wedding_dashboard AS
SELECT 
  w.*,
  get_wedding_stats(w.id) as stats,
  COUNT(DISTINCT wpm.id) as party_size,
  COUNT(DISTINCT wt.id) FILTER (WHERE wt.status = 'pending') as pending_tasks,
  w.wedding_date - CURRENT_DATE as days_until_wedding
FROM public.weddings w
LEFT JOIN public.wedding_party_members wpm ON w.id = wpm.wedding_id
LEFT JOIN public.wedding_tasks wt ON w.id = wt.wedding_id
GROUP BY w.id;

-- Party member dashboard view
CREATE OR REPLACE VIEW party_member_dashboard AS
SELECT 
  wpm.*,
  w.wedding_date,
  w.venue_name,
  w.wedding_code,
  wpo.status as outfit_status,
  wpo.total_price as outfit_total,
  COUNT(wt.id) FILTER (WHERE wt.status = 'pending') as pending_tasks
FROM public.wedding_party_members wpm
JOIN public.weddings w ON wpm.wedding_id = w.id
LEFT JOIN public.wedding_party_outfits wpo ON wpm.id = wpo.member_id
LEFT JOIN public.wedding_tasks wt ON wpm.id = wt.assigned_to_member
GROUP BY wpm.id, w.wedding_date, w.venue_name, w.wedding_code, wpo.status, wpo.total_price;

-- =====================================================
-- SAMPLE DATA (OPTIONAL - Remove for production)
-- =====================================================

-- Insert sample wedding (commented out for production)
/*
INSERT INTO public.weddings (
  wedding_code,
  partner1_name,
  partner1_email,
  partner2_name,
  partner2_email,
  wedding_date,
  venue_name,
  venue_city,
  venue_state,
  wedding_theme,
  formality_level,
  season,
  estimated_budget
) VALUES (
  'SMITH2025',
  'John Smith',
  'john@example.com',
  'Jane Doe',
  'jane@example.com',
  '2025-10-15',
  'Grand Ballroom Hotel',
  'New York',
  'NY',
  'classic',
  'black-tie',
  'fall',
  5000.00
);
*/

-- =====================================================
-- PERMISSIONS & GRANTS
-- =====================================================

-- Grant necessary permissions
GRANT SELECT, INSERT, UPDATE ON ALL TABLES IN SCHEMA public TO authenticated;
GRANT USAGE ON ALL SEQUENCES IN SCHEMA public TO authenticated;
GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA public TO authenticated;

-- =====================================================
-- END OF SCHEMA
-- =====================================================