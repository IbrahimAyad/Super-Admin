# 🚨 URGENT: Add New Admin URL to R2 CORS

The latest admin deployment has a NEW URL that needs to be added to R2 CORS:

## Error:
```
Origin https://super-admin-jsbd07csf-ibrahimayads-projects.vercel.app is not allowed
```

## Add this to your R2 CORS allowed origins:

```json
[
  {
    "AllowedOrigins": [
      "https://super-admin-ruby.vercel.app",
      "https://backend-ai-enhanced-kct-admin.vercel.app",
      "https://kct-menswear-ai-enhanced.vercel.app",
      "https://kctmenswear.com",
      "https://www.kctmenswear.com",
      "https://super-admin-gil539m55-ibrahimayads-projects.vercel.app",
      "https://super-admin-ey00lcmtt-ibrahimayads-projects.vercel.app",
      "https://super-admin-jsbd07csf-ibrahimayads-projects.vercel.app",
      "https://super-admin-*-ibrahimayads-projects.vercel.app",
      "http://localhost:3000",
      "http://localhost:3001",
      "http://localhost:5173",
      "http://localhost:8080"
    ],
    "AllowedMethods": [
      "GET",
      "HEAD",
      "PUT",
      "POST",
      "DELETE"
    ],
    "AllowedHeaders": [
      "*"
    ],
    "ExposeHeaders": [
      "ETag",
      "Content-Type",
      "Content-Length"
    ],
    "MaxAgeSeconds": 3600
  }
]
```

## Steps:
1. Go to Cloudflare R2
2. Select your bucket: `kct-base-products`
3. Go to Settings → CORS
4. Replace with the JSON above
5. **SAVE**

This will fix the images in the admin panel!