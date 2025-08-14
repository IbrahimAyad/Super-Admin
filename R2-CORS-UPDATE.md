# 🚨 URGENT: Update R2 CORS Settings

The images are blocked because R2 doesn't allow the new Vercel deployment URL.

## Current Error:
```
Origin https://super-admin-gil539m55-ibrahimayads-projects.vercel.app is not allowed
```

## Fix Instructions:

### 1. Go to Cloudflare R2 Dashboard
1. Login to Cloudflare
2. Go to R2 → Your bucket (pub-8ea0502158a94b8ca8a7abb9e18a57e8)
3. Click on "Settings" tab
4. Find "CORS Policy"

### 2. Update CORS Settings
Add these URLs to allowed origins:

```json
{
  "AllowedOrigins": [
    "http://localhost:5173",
    "http://localhost:3000",
    "https://kctmenswear.com",
    "https://www.kctmenswear.com",
    "https://super-admin-ruby.vercel.app",
    "https://super-admin-*.vercel.app",
    "https://*-ibrahimayads-projects.vercel.app",
    "https://super-admin-gil539m55-ibrahimayads-projects.vercel.app",
    "https://super-admin-ey00lcmtt-ibrahimayads-projects.vercel.app"
  ],
  "AllowedMethods": ["GET", "HEAD", "POST", "PUT", "DELETE"],
  "AllowedHeaders": ["*"],
  "ExposeHeaders": ["ETag"],
  "MaxAgeSeconds": 3600
}
```

### 3. Alternative: Make Bucket Public
If CORS continues to be an issue:
1. Go to R2 bucket settings
2. Under "Public Access"
3. Enable "Allow public access"
4. Add a custom domain if needed

## Quick Test:
After updating CORS, test an image URL directly:
```
https://pub-8ea0502158a94b8ca8a7abb9e18a57e8.r2.dev/products/test.jpg
```

## Why This Happened:
- Each Vercel deployment gets a unique URL
- R2 CORS was configured for old URLs only
- New deployment URL wasn't whitelisted

## Permanent Solution:
Use a custom domain for your admin panel (e.g., admin.kctmenswear.com) to avoid CORS issues with changing Vercel URLs.