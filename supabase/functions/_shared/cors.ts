// CORS configuration for different environments
const ALLOWED_ORIGINS = [
  'http://localhost:8080',
  'http://localhost:5173',
  'https://kctmenswear.com',
  'https://www.kctmenswear.com',
  'https://admin.kctmenswear.com',
  'https://super-admin-ruby.vercel.app'
];

// Function to check if origin matches Vercel preview URLs
function isVercelPreview(origin: string): boolean {
  // Allow ALL Vercel preview URLs for your project
  // Format: https://super-admin-[hash]-ibrahimayads-projects.vercel.app
  return origin.includes('-ibrahimayads-projects.vercel.app') || 
         origin.includes('super-admin') && origin.includes('.vercel.app');
}

export function getCorsHeaders(origin?: string | null): Record<string, string> {
  // For webhook endpoints, typically no CORS needed
  if (!origin) {
    return {
      'Content-Type': 'application/json',
    };
  }

  // Check if origin is allowed (including Vercel preview URLs)
  const isAllowed = ALLOWED_ORIGINS.includes(origin) || isVercelPreview(origin);
  
  if (isAllowed) {
    return {
      'Access-Control-Allow-Origin': origin,
      'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
      'Access-Control-Allow-Methods': 'GET, POST, PUT, DELETE, OPTIONS',
      'Access-Control-Max-Age': '86400',
    };
  }

  // No CORS headers for disallowed origins
  return {
    'Content-Type': 'application/json',
  };
}

// Updated to use secure CORS configuration
// Use getCorsHeaders() function instead for proper origin validation
export const corsHeaders = {
  'Access-Control-Allow-Origin': process.env.ALLOWED_ORIGIN || 'https://kctmenswear.com',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
  'Access-Control-Allow-Methods': 'GET, POST, PUT, DELETE, OPTIONS',
}