# Deployment Guide

This guide covers deploying the KCT Menswear Super Admin dashboard to various platforms.

## Table of Contents
- [Prerequisites](#prerequisites)
- [Environment Variables](#environment-variables)
- [Vercel Deployment](#vercel-deployment)
- [Netlify Deployment](#netlify-deployment)
- [Railway Deployment](#railway-deployment)
- [Self-Hosted Deployment](#self-hosted-deployment)
- [Post-Deployment](#post-deployment)
- [Monitoring](#monitoring)

## Prerequisites

Before deploying, ensure you have:

1. **Completed local setup** and verified everything works
2. **Supabase project** configured with:
   - Database migrations applied
   - Edge Functions deployed
   - RLS policies enabled
   - Service role key secured
3. **Stripe account** with:
   - Products synced
   - Webhooks configured
   - API keys ready
4. **Domain name** (optional but recommended)
5. **SSL certificate** (usually auto-configured by hosting provider)

## Environment Variables

### Required Variables

```env
# Supabase (Public)
VITE_SUPABASE_URL=https://[PROJECT_REF].supabase.co
VITE_SUPABASE_ANON_KEY=eyJ...

# Stripe (Public)
VITE_STRIPE_PUBLISHABLE_KEY=pk_live_...

# Application
VITE_APP_URL=https://admin.kctmenswear.com
VITE_ENABLE_ANALYTICS=true
VITE_ENABLE_AI_RECOMMENDATIONS=true

# Security
VITE_2FA_ENCRYPTION_KEY=[GENERATE_SECURE_KEY]
```

### Generating Secure Keys

```bash
# Generate 2FA encryption key
openssl rand -base64 32

# Generate secure passwords
openssl rand -base64 24
```

## Vercel Deployment

### Step 1: Install Vercel CLI

```bash
npm i -g vercel
```

### Step 2: Configure Project

Create `vercel.json` in project root:

```json
{
  "buildCommand": "npm run build",
  "outputDirectory": "dist",
  "framework": "vite",
  "rewrites": [
    { "source": "/(.*)", "destination": "/" }
  ],
  "headers": [
    {
      "source": "/api/(.*)",
      "headers": [
        { "key": "Cache-Control", "value": "no-cache, no-store, must-revalidate" }
      ]
    }
  ]
}
```

### Step 3: Deploy

```bash
# Login to Vercel
vercel login

# Deploy to preview
vercel

# Deploy to production
vercel --prod
```

### Step 4: Configure Environment Variables

1. Go to [Vercel Dashboard](https://vercel.com/dashboard)
2. Select your project
3. Go to Settings → Environment Variables
4. Add all required variables
5. Redeploy to apply changes

### Step 5: Configure Domain

1. Go to Settings → Domains
2. Add your custom domain
3. Configure DNS records as instructed

## Netlify Deployment

### Step 1: Configure Build Settings

Create `netlify.toml` in project root:

```toml
[build]
  command = "npm run build"
  publish = "dist"

[[redirects]]
  from = "/*"
  to = "/index.html"
  status = 200

[[headers]]
  for = "/api/*"
  [headers.values]
    Cache-Control = "no-cache, no-store, must-revalidate"

[build.environment]
  NODE_VERSION = "20"
```

### Step 2: Deploy via CLI

```bash
# Install Netlify CLI
npm i -g netlify-cli

# Login
netlify login

# Deploy
netlify deploy

# Deploy to production
netlify deploy --prod
```

### Step 3: Configure Environment Variables

1. Go to [Netlify Dashboard](https://app.netlify.com)
2. Select your site
3. Go to Site settings → Environment variables
4. Add all required variables

### Step 4: Configure Custom Domain

1. Go to Domain settings
2. Add custom domain
3. Configure DNS (Netlify provides free SSL)

## Railway Deployment

### Step 1: Install Railway CLI

```bash
npm i -g @railway/cli
```

### Step 2: Initialize Project

```bash
# Login
railway login

# Initialize
railway init

# Link to project
railway link
```

### Step 3: Configure Build

Create `railway.json`:

```json
{
  "build": {
    "builder": "NIXPACKS",
    "buildCommand": "npm run build"
  },
  "deploy": {
    "startCommand": "npm run preview",
    "restartPolicyType": "ON_FAILURE",
    "restartPolicyMaxRetries": 10
  }
}
```

### Step 4: Deploy

```bash
# Add environment variables
railway variables set VITE_SUPABASE_URL=your_url
railway variables set VITE_SUPABASE_ANON_KEY=your_key
# ... add all variables

# Deploy
railway up
```

## Self-Hosted Deployment

### Option 1: Docker Deployment

Create `Dockerfile`:

```dockerfile
# Build stage
FROM node:20-alpine as builder
WORKDIR /app
COPY package*.json ./
RUN npm ci
COPY . .
RUN npm run build

# Production stage
FROM nginx:alpine
COPY --from=builder /app/dist /usr/share/nginx/html
COPY nginx.conf /etc/nginx/nginx.conf
EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]
```

Create `nginx.conf`:

```nginx
events {
    worker_connections 1024;
}

http {
    include /etc/nginx/mime.types;
    default_type application/octet-stream;

    server {
        listen 80;
        server_name _;
        root /usr/share/nginx/html;
        index index.html;

        # Security headers
        add_header X-Frame-Options "SAMEORIGIN" always;
        add_header X-Content-Type-Options "nosniff" always;
        add_header X-XSS-Protection "1; mode=block" always;

        # SPA routing
        location / {
            try_files $uri $uri/ /index.html;
        }

        # API proxy (if needed)
        location /api {
            proxy_pass https://your-api-endpoint.com;
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
        }

        # Cache static assets
        location ~* \.(js|css|png|jpg|jpeg|gif|ico|svg)$ {
            expires 1y;
            add_header Cache-Control "public, immutable";
        }
    }
}
```

Build and run:

```bash
# Build Docker image
docker build -t kct-admin .

# Run container
docker run -d -p 80:80 --name kct-admin \
  -e VITE_SUPABASE_URL=your_url \
  -e VITE_SUPABASE_ANON_KEY=your_key \
  kct-admin
```

### Option 2: PM2 Deployment

```bash
# Install PM2
npm install -g pm2

# Build application
npm run build

# Install serve
npm install -g serve

# Create ecosystem file
cat > ecosystem.config.js << EOF
module.exports = {
  apps: [{
    name: 'kct-admin',
    script: 'serve',
    args: '-s dist -l 3000',
    env: {
      NODE_ENV: 'production',
      VITE_SUPABASE_URL: 'your_url',
      VITE_SUPABASE_ANON_KEY: 'your_key'
    }
  }]
}
EOF

# Start with PM2
pm2 start ecosystem.config.js

# Save PM2 config
pm2 save

# Setup startup script
pm2 startup
```

## Post-Deployment

### 1. Verify Deployment

- [ ] Application loads without errors
- [ ] Can log in with admin credentials
- [ ] Database connection works
- [ ] Stripe integration functional
- [ ] Email sending works
- [ ] File uploads work (if applicable)

### 2. Configure Stripe Webhooks

Update webhook endpoint to production URL:

```
https://your-domain.com/api/stripe-webhook
```

### 3. Update Supabase Settings

1. Add production domain to allowed URLs
2. Update email templates with production URLs
3. Configure custom SMTP if needed

### 4. Enable Monitoring

#### Sentry Setup

```bash
npm install @sentry/react
```

Add to `main.tsx`:

```typescript
import * as Sentry from "@sentry/react";

Sentry.init({
  dsn: "your-sentry-dsn",
  environment: "production",
  integrations: [
    new Sentry.BrowserTracing(),
  ],
  tracesSampleRate: 0.1,
});
```

#### Google Analytics

Add to `index.html`:

```html
<!-- Google Analytics -->
<script async src="https://www.googletagmanager.com/gtag/js?id=GA_MEASUREMENT_ID"></script>
<script>
  window.dataLayer = window.dataLayer || [];
  function gtag(){dataLayer.push(arguments);}
  gtag('js', new Date());
  gtag('config', 'GA_MEASUREMENT_ID');
</script>
```

### 5. Setup Backups

#### Database Backups

Configure in Supabase Dashboard:
- Daily automated backups
- Point-in-time recovery
- Download monthly snapshots

#### Code Backups

```bash
# Setup automated git backups
git remote add backup https://backup-repo-url.git
git push backup main
```

## Monitoring

### Health Checks

Create health check endpoint:

```typescript
// src/api/health.ts
export async function GET() {
  const checks = {
    database: await checkDatabase(),
    stripe: await checkStripe(),
    storage: await checkStorage(),
  };
  
  return new Response(JSON.stringify({
    status: 'healthy',
    checks,
    timestamp: new Date().toISOString()
  }));
}
```

### Uptime Monitoring

Configure with services like:
- [UptimeRobot](https://uptimerobot.com)
- [Pingdom](https://www.pingdom.com)
- [StatusCake](https://www.statuscake.com)

### Performance Monitoring

Use tools like:
- Lighthouse CI
- Web Vitals monitoring
- New Relic or DataDog

## Rollback Procedure

If deployment fails:

### Vercel
```bash
vercel rollback
```

### Netlify
```bash
netlify rollback
```

### Docker
```bash
docker stop kct-admin
docker run -d -p 80:80 --name kct-admin kct-admin:previous-version
```

### Database
```sql
-- Restore from backup
-- In Supabase Dashboard: Settings → Backups → Restore
```

## Security Checklist

- [ ] All secrets in environment variables
- [ ] HTTPS enabled
- [ ] CORS properly configured
- [ ] Rate limiting enabled
- [ ] Security headers configured
- [ ] RLS policies active
- [ ] 2FA enabled for admins
- [ ] Regular dependency updates
- [ ] Security monitoring active

## Troubleshooting

### Build Failures

```bash
# Clear cache and rebuild
rm -rf node_modules dist
npm install
npm run build
```

### Environment Variables Not Loading

1. Check variable names (must start with `VITE_`)
2. Rebuild after adding variables
3. Clear browser cache

### Database Connection Issues

1. Check Supabase service status
2. Verify anon key is correct
3. Check RLS policies
4. Verify network connectivity

## Support

For deployment issues:
- Check [GitHub Issues](https://github.com/IbrahimAyad/Super-Admin/issues)
- Contact: support@kctmenswear.com
- Review logs in hosting platform dashboard

---

Last Updated: August 2025