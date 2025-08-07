/**
 * GET PUBLIC SETTINGS EDGE FUNCTION
 * Provides secure, rate-limited access to public settings for the website
 * Last updated: 2025-08-07
 */

import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.38.0";
import { RateLimiter, generateRateLimitIdentifier, createRateLimitHeaders, RATE_LIMIT_CONFIGS } from "../_shared/rate-limiting.ts";
import { corsHeaders } from "../_shared/cors.ts";

interface SettingsResponse {
  settings: Record<string, any>;
  cached: boolean;
  cache_expires_at?: string;
  version?: string;
}

interface ErrorResponse {
  error: string;
  code?: string;
  details?: any;
}

// Initialize rate limiter
const rateLimiter = new RateLimiter(
  Deno.env.get('SUPABASE_URL'),
  Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')
);

// Cache settings in memory with TTL
const settingsCache = new Map<string, {
  data: Record<string, any>;
  expires_at: number;
  version: string;
}>();

const CACHE_TTL = 5 * 60 * 1000; // 5 minutes in milliseconds
const CACHE_KEY = 'public_settings';

/**
 * Get settings from cache or database
 */
async function getPublicSettings(supabase: any, useCache: boolean = true): Promise<{
  settings: Record<string, any>;
  cached: boolean;
  cache_expires_at?: string;
  version: string;
}> {
  const now = Date.now();
  
  // Check memory cache first
  if (useCache) {
    const cached = settingsCache.get(CACHE_KEY);
    if (cached && cached.expires_at > now) {
      return {
        settings: cached.data,
        cached: true,
        cache_expires_at: new Date(cached.expires_at).toISOString(),
        version: cached.version
      };
    }
  }

  try {
    // Use the database function for cached settings
    const { data, error } = await supabase.rpc('get_public_settings_cached');
    
    if (error) {
      console.error('Database error fetching public settings:', error);
      throw new Error(`Database error: ${error.message}`);
    }

    const settings = data || {};
    const version = generateSettingsVersion(settings);
    const expires_at = now + CACHE_TTL;

    // Update memory cache
    settingsCache.set(CACHE_KEY, {
      data: settings,
      expires_at,
      version
    });

    return {
      settings,
      cached: false,
      cache_expires_at: new Date(expires_at).toISOString(),
      version
    };
  } catch (error) {
    console.error('Error fetching public settings:', error);
    
    // Try to return stale cache as fallback
    const staleCache = settingsCache.get(CACHE_KEY);
    if (staleCache) {
      console.log('Returning stale cache due to database error');
      return {
        settings: staleCache.data,
        cached: true,
        cache_expires_at: new Date(staleCache.expires_at).toISOString(),
        version: staleCache.version
      };
    }
    
    throw error;
  }
}

/**
 * Generate a version hash for settings to enable client-side caching
 */
function generateSettingsVersion(settings: Record<string, any>): string {
  const settingsString = JSON.stringify(settings, Object.keys(settings).sort());
  
  // Simple hash function (you might want to use a better one in production)
  let hash = 0;
  for (let i = 0; i < settingsString.length; i++) {
    const char = settingsString.charCodeAt(i);
    hash = ((hash << 5) - hash) + char;
    hash = hash & hash; // Convert to 32-bit integer
  }
  
  return Math.abs(hash).toString(36);
}

/**
 * Validate request parameters
 */
function validateRequest(url: URL): { valid: boolean; errors: string[] } {
  const errors: string[] = [];
  
  // Check for suspicious patterns
  const suspiciousParams = ['script', 'eval', 'function', 'constructor'];
  for (const [key, value] of url.searchParams.entries()) {
    if (suspiciousParams.some(pattern => 
      key.toLowerCase().includes(pattern) || 
      value.toLowerCase().includes(pattern)
    )) {
      errors.push(`Suspicious parameter detected: ${key}`);
    }
  }
  
  return {
    valid: errors.length === 0,
    errors
  };
}

/**
 * Main request handler
 */
serve(async (req: Request) => {
  // Handle CORS preflight
  if (req.method === 'OPTIONS') {
    return new Response(null, { 
      status: 200, 
      headers: corsHeaders 
    });
  }

  // Only allow GET requests
  if (req.method !== 'GET') {
    return new Response(
      JSON.stringify({ 
        error: 'Method not allowed',
        code: 'METHOD_NOT_ALLOWED'
      } as ErrorResponse),
      { 
        status: 405, 
        headers: { 
          ...corsHeaders, 
          'Content-Type': 'application/json',
          'Allow': 'GET, OPTIONS'
        } 
      }
    );
  }

  try {
    const url = new URL(req.url);
    
    // Validate request
    const validation = validateRequest(url);
    if (!validation.valid) {
      return new Response(
        JSON.stringify({ 
          error: 'Invalid request parameters',
          code: 'INVALID_PARAMS',
          details: validation.errors
        } as ErrorResponse),
        { 
          status: 400, 
          headers: { 
            ...corsHeaders, 
            'Content-Type': 'application/json' 
          } 
        }
      );
    }

    // Rate limiting
    const identifier = generateRateLimitIdentifier(req, 'combined');
    const rateLimitResult = await rateLimiter.checkRateLimit(
      identifier,
      RATE_LIMIT_CONFIGS.api, // Use moderate API rate limiting
      'api'
    );

    const rateLimitHeaders = createRateLimitHeaders(rateLimitResult);

    if (!rateLimitResult.allowed) {
      return new Response(
        JSON.stringify({ 
          error: 'Rate limit exceeded',
          code: 'RATE_LIMIT_EXCEEDED',
          details: {
            limit: rateLimitResult.limit,
            remaining: rateLimitResult.remaining,
            resetTime: rateLimitResult.resetTime,
            retryAfter: rateLimitResult.retryAfter
          }
        } as ErrorResponse),
        { 
          status: 429, 
          headers: { 
            ...corsHeaders,
            ...rateLimitHeaders,
            'Content-Type': 'application/json'
          } 
        }
      );
    }

    // Initialize Supabase client
    const supabaseUrl = Deno.env.get('SUPABASE_URL');
    const supabaseAnonKey = Deno.env.get('SUPABASE_ANON_KEY');
    
    if (!supabaseUrl || !supabaseAnonKey) {
      throw new Error('Missing Supabase configuration');
    }

    const supabase = createClient(supabaseUrl, supabaseAnonKey, {
      auth: { persistSession: false }
    });

    // Parse query parameters
    const nocache = url.searchParams.get('nocache') === 'true';
    const version = url.searchParams.get('version');
    
    // Get settings
    const result = await getPublicSettings(supabase, !nocache);
    
    // Check if client version matches (for client-side caching)
    if (version && version === result.version) {
      return new Response(
        null,
        { 
          status: 304, // Not Modified
          headers: { 
            ...corsHeaders,
            ...rateLimitHeaders,
            'Cache-Control': 'public, max-age=300', // 5 minutes
            'ETag': `"${result.version}"`,
            'X-Settings-Version': result.version
          } 
        }
      );
    }

    // Prepare response
    const response: SettingsResponse = {
      settings: result.settings,
      cached: result.cached,
      cache_expires_at: result.cache_expires_at,
      version: result.version
    };

    // Set appropriate cache headers
    const cacheHeaders: Record<string, string> = {
      'Cache-Control': 'public, max-age=300', // 5 minutes browser cache
      'ETag': `"${result.version}"`,
      'X-Settings-Version': result.version,
      'X-Settings-Cached': result.cached.toString()
    };

    if (result.cache_expires_at) {
      cacheHeaders['Expires'] = result.cache_expires_at;
    }

    return new Response(
      JSON.stringify(response),
      { 
        status: 200, 
        headers: { 
          ...corsHeaders,
          ...rateLimitHeaders,
          ...cacheHeaders,
          'Content-Type': 'application/json'
        } 
      }
    );

  } catch (error) {
    console.error('Error in get-public-settings function:', error);
    
    // Don't expose internal errors to clients
    const isInternalError = error.message?.includes('Database error') || 
                           error.message?.includes('Supabase configuration');
    
    const errorResponse: ErrorResponse = {
      error: isInternalError ? 'Internal server error' : 'Failed to fetch settings',
      code: 'INTERNAL_ERROR'
    };

    // Add error details in development
    if (Deno.env.get('ENVIRONMENT') === 'development') {
      errorResponse.details = {
        message: error.message,
        stack: error.stack
      };
    }

    return new Response(
      JSON.stringify(errorResponse),
      { 
        status: 500, 
        headers: { 
          ...corsHeaders, 
          'Content-Type': 'application/json' 
        } 
      }
    );
  }
});

// Log function startup
console.log('🔧 Public Settings Edge Function started successfully');
console.log('📋 Available endpoints:');
console.log('  GET /get-public-settings - Fetch public settings');
console.log('  GET /get-public-settings?nocache=true - Force refresh cache');
console.log('  GET /get-public-settings?version=<hash> - Check if settings changed');
console.log('🔒 Rate limiting enabled: 100 requests/minute per IP');
console.log('💾 Memory caching enabled: 5 minute TTL');