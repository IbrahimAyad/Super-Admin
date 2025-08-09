# KCT Menswear Super Admin Dashboard

A comprehensive admin dashboard for managing KCT Menswear's e-commerce operations, built with React, TypeScript, Supabase, and Stripe.

## 🌟 Features

### Core Features
- **Product Management**: Complete CRUD operations for products with variants, sizing, and inventory tracking
- **Order Processing**: Real-time order management with status tracking and fulfillment workflows
- **Customer Management**: Customer profiles with size profiles, style preferences, and purchase history
- **Stripe Integration**: Secure payment processing and product sync with Stripe
- **Analytics Dashboard**: Real-time sales metrics, customer insights, and performance tracking
- **Inventory Management**: Stock tracking, low-stock alerts, and automated reordering
- **Email Automation**: Transactional emails, marketing campaigns, and abandoned cart recovery

### Advanced Features
- **AI Recommendations**: Personalized product recommendations based on customer preferences
- **Size Profiling**: Customer measurement tracking for perfect fit recommendations
- **Bundle Builder**: Create and manage product bundles with dynamic pricing
- **Wedding Management**: (Coming Soon) Complete wedding party coordination system
- **Multi-channel Sync**: Inventory sync across multiple sales channels
- **Advanced Reporting**: Custom reports with export functionality

## 📋 Prerequisites

Before you begin, ensure you have the following installed:
- **Node.js** (v20.0.0 or higher)
- **npm** (v10.0.0 or higher) or **yarn**
- **Git**
- **Supabase CLI** (for local development)

You'll also need accounts for:
- **Supabase** (Backend & Database)
- **Stripe** (Payment Processing)
- **Resend** or **SendGrid** (Email Service)

## 🚀 Quick Start

### 1. Clone the Repository

```bash
git clone https://github.com/IbrahimAyad/Super-Admin.git
cd Super-Admin
```

### 2. Install Dependencies

```bash
npm install
```

### 3. Environment Setup

Copy the example environment file and configure your variables:

```bash
cp .env.example .env
```

Edit `.env` with your actual values:

```env
# Supabase Configuration
VITE_SUPABASE_URL=your_supabase_project_url
VITE_SUPABASE_ANON_KEY=your_supabase_anon_key

# Stripe Configuration (Public key only)
VITE_STRIPE_PUBLISHABLE_KEY=your_stripe_publishable_key

# Application Settings
VITE_APP_URL=http://localhost:8080
VITE_ENABLE_ANALYTICS=true
VITE_ENABLE_AI_RECOMMENDATIONS=true

# 2FA Security (Generate a secure key for production)
VITE_2FA_ENCRYPTION_KEY=your_secure_encryption_key_here
```

### 4. Database Setup

Run the migrations in order:

```bash
# Connect to your Supabase project
supabase link --project-ref your-project-ref

# Run migrations
supabase db push
```

Or run them manually in your Supabase SQL editor in this order:
1. `001_create_admin_users.sql`
2. `057_create_user_profiles_table.sql`
3. `059_update_user_profiles_safe.sql`
4. Run other migrations as needed

### 5. Configure Supabase Edge Functions

Set up the required secrets for Edge Functions:

```bash
# Set the service role key (NEVER commit this to git)
supabase secrets set SUPABASE_SERVICE_ROLE_KEY=your_service_role_key

# Set Stripe secret key
supabase secrets set STRIPE_SECRET_KEY=your_stripe_secret_key

# Deploy Edge Functions
supabase functions deploy
```

### 6. Create Initial Admin User

Run this SQL in your Supabase dashboard:

```sql
-- Create your admin user
INSERT INTO auth.users (email, encrypted_password, email_confirmed_at)
VALUES (
  'admin@kctmenswear.com',
  crypt('your_secure_password', gen_salt('bf')),
  NOW()
);

-- Add to admin_users table
INSERT INTO admin_users (user_id, email, role, permissions)
SELECT id, email, 'super_admin', '["all"]'
FROM auth.users
WHERE email = 'admin@kctmenswear.com';
```

### 7. Start Development Server

```bash
npm run dev
```

Visit `http://localhost:8080` and log in with your admin credentials.

## 📁 Project Structure

```
Super-Admin/
├── src/
│   ├── components/
│   │   ├── admin/          # Admin dashboard components
│   │   ├── auth/           # Authentication components
│   │   ├── ui/             # Reusable UI components
│   │   └── wedding/        # Wedding management (future)
│   ├── contexts/           # React contexts
│   ├── hooks/              # Custom React hooks
│   ├── lib/                # Utilities and services
│   │   └── services/       # API services
│   ├── pages/              # Page components
│   └── utils/              # Helper functions
├── supabase/
│   ├── functions/          # Edge Functions
│   └── migrations/         # Database migrations
├── docs/                   # Documentation
└── public/                 # Static assets
```

## 🔧 Configuration

### Stripe Integration

1. **Get your API keys** from [Stripe Dashboard](https://dashboard.stripe.com/apikeys)
2. **Configure webhooks** in Stripe:
   - Endpoint: `https://your-domain.com/api/stripe-webhook`
   - Events to listen for:
     - `checkout.session.completed`
     - `payment_intent.succeeded`
     - `customer.subscription.created`
     - `customer.subscription.updated`

3. **Product Sync**:
   - Navigate to Admin Dashboard > Stripe Sync
   - Run initial sync to import products
   - Enable auto-sync for real-time updates

### Email Configuration

Configure your email service in Supabase Edge Functions:

```bash
supabase secrets set RESEND_API_KEY=your_resend_api_key
# OR
supabase secrets set SENDGRID_API_KEY=your_sendgrid_api_key
```

### Security Settings

1. **Enable Row Level Security (RLS)** on all tables
2. **Configure CORS** in `supabase/functions/_shared/cors.ts`
3. **Set up 2FA** for admin accounts
4. **Regular security audits** using the built-in security dashboard

## 🚢 Deployment

### Deploy to Vercel

[![Deploy with Vercel](https://vercel.com/button)](https://vercel.com/new/clone?repository-url=https://github.com/IbrahimAyad/Super-Admin)

1. Click the button above
2. Configure environment variables
3. Deploy

### Deploy to Netlify

[![Deploy to Netlify](https://www.netlify.com/img/deploy/button.svg)](https://app.netlify.com/start/deploy?repository=https://github.com/IbrahimAyad/Super-Admin)

1. Click the button above
2. Configure build settings:
   - Build command: `npm run build`
   - Publish directory: `dist`
3. Add environment variables
4. Deploy

### Manual Deployment

```bash
# Build for production
npm run build

# Preview production build
npm run preview

# Deploy dist folder to your hosting provider
```

## 📊 Database Schema

### Core Tables

- **users** - Authentication (managed by Supabase Auth)
- **user_profiles** - User preferences and settings
- **admin_users** - Admin access control
- **customers** - Customer records (including guests)
- **products** - Product catalog
- **product_variants** - Size/color variants
- **inventory** - Stock levels
- **orders** - Order records
- **order_items** - Line items in orders
- **stripe_sync_log** - Stripe synchronization logs

See `/docs/DATABASE_SCHEMA.md` for complete schema documentation.

## 🔐 Security

### Best Practices

1. **Never commit sensitive keys** to version control
2. **Use Row Level Security (RLS)** on all Supabase tables
3. **Implement rate limiting** on API endpoints
4. **Regular security audits** and dependency updates
5. **Enable 2FA** for all admin accounts
6. **Use secure session management**
7. **Implement proper CORS policies**

### Environment Variables

- **Frontend variables** must start with `VITE_` to be accessible
- **Backend secrets** should only be in Supabase Edge Function secrets
- **Never expose** service role keys or secret keys in frontend code

## 🧪 Testing

```bash
# Run unit tests
npm run test

# Run tests with UI
npm run test:ui

# Run tests with coverage
npm run test:coverage

# Test Edge Functions
npm run test:edge-functions
```

## 📚 API Documentation

### REST Endpoints

See `/docs/API.md` for complete API documentation.

### Key Endpoints

- `GET /api/products` - Fetch products
- `POST /api/orders` - Create order
- `GET /api/customers/{id}` - Get customer details
- `POST /api/stripe/sync` - Sync with Stripe
- `POST /api/ai/recommendations` - Get AI recommendations

## 🐛 Troubleshooting

### Common Issues

**Issue**: "Missing SUPABASE_SERVICE_ROLE_KEY"
- **Solution**: This key should only be set in Supabase Edge Function secrets, not in `.env`

**Issue**: "Stripe sync timeout"
- **Solution**: Reduce batch size or sync fewer products at once

**Issue**: "RLS policy violation"
- **Solution**: Check your user role and RLS policies in Supabase

See `/docs/TROUBLESHOOTING.md` for more solutions.

## 🤝 Contributing

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

## 📄 License

This project is proprietary and confidential. All rights reserved by KCT Menswear.

## 🆘 Support

For support, email support@kctmenswear.com or open an issue in the GitHub repository.

## 🙏 Acknowledgments

- Built with [Vite](https://vitejs.dev/)
- UI components from [shadcn/ui](https://ui.shadcn.com/)
- Backend powered by [Supabase](https://supabase.com/)
- Payments by [Stripe](https://stripe.com/)

---

**Version**: 1.0.0  
**Last Updated**: August 2025  
**Maintained By**: KCT Menswear Development Team