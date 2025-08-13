# 📂 Project File Organization Guide

## 🗂️ Directory Structure

```
Super-Admin/
├── 📁 src/                    # React application source code
│   ├── components/            # UI components
│   ├── contexts/             # React contexts
│   ├── hooks/                # Custom hooks
│   ├── lib/                  # Services and utilities
│   └── pages/                # Page components
│
├── 📁 sql/                    # All SQL files (ORGANIZED)
│   ├── migrations/           # Database schema & tables
│   ├── fixes/               # Bug fixes & corrections
│   ├── imports/             # Product & data imports
│   ├── analytics/           # Analytics queries
│   ├── reports/             # Report generation
│   ├── testing/             # Test scripts
│   └── utilities/           # Helper & diagnostic scripts
│
├── 📁 docs/                   # Documentation
│   ├── setup/               # Setup & configuration guides
│   ├── deployment/          # Deployment instructions
│   ├── systems/             # System architecture docs
│   └── utilities/           # Utility documentation
│
├── 📁 scripts/                # Shell scripts & utilities
│   ├── deployment scripts
│   └── setup scripts
│
├── 📁 supabase/              # Supabase configuration
│   ├── functions/           # Edge Functions
│   └── migrations/          # Official migrations
│
└── 📁 public/                # Static assets

```

## 🚀 Quick Access to Important Files

### 🛍️ Product Management
- **Import 233 Products:** `sql/imports/import-products-with-sizes-fixed.sql`
- **Product CSV Files:** `sql/imports/products_*.csv`

### 💳 Checkout & Payment
- **Website Checkout Guide:** `WEBSITE_CHECKOUT_COMPLETE_GUIDE.md`
- **Secure Checkout Docs:** `SECURE_CHECKOUT_IMPLEMENTATION.md`
- **Stripe Webhook:** `supabase/functions/stripe-webhook-secure/`

### 📊 System Status
- **System Ready Status:** `docs/SYSTEM_100_PERCENT_READY.md`
- **Complete Summary:** `docs/SYSTEM_COMPLETE_SUMMARY.md`
- **System Diagnostic:** `sql/utilities/COMPLETE_SYSTEM_DIAGNOSTIC.sql`

### 🔧 Configuration
- **Environment Variables:** `.env`
- **README:** `README.md`
- **Package.json:** `package.json`

### 📈 Reports & Analytics
- **Daily Reports:** `sql/reports/CREATE_DAILY_REPORTS.sql`
- **Financial Dashboard:** `sql/reports/FINANCIAL_DASHBOARD_QUERIES.sql`
- **Analytics Integration:** `docs/systems/analytics-*.md`

## 🎯 Common Tasks

### To Import New Products:
1. Go to: `sql/imports/import-products-with-sizes-fixed.sql`
2. Run in Supabase SQL Editor

### To Check System Health:
1. Go to: `sql/utilities/COMPLETE_SYSTEM_DIAGNOSTIC.sql`
2. Run diagnostic queries

### To Deploy Updates:
1. Check: `docs/deployment/` folder
2. Follow deployment guides

### To Fix Issues:
1. Check: `sql/fixes/` folder
2. Find relevant fix script

## 📝 Notes
- All SQL files are now organized by purpose
- Documentation is categorized by topic
- Scripts are in the scripts folder
- Source code remains in src/
