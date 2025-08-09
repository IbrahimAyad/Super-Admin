/**
 * Environment variable validation and configuration
 * Ensures all required environment variables are present and valid
 */

interface EnvConfig {
  // Supabase
  SUPABASE_URL: string;
  SUPABASE_ANON_KEY: string;
  
  // Stripe
  STRIPE_PUBLISHABLE_KEY: string;
  
  // Application
  APP_URL: string;
  
  // Feature Flags
  ENABLE_ANALYTICS: boolean;
  ENABLE_AI_RECOMMENDATIONS: boolean;
  ENABLE_DEV_ROUTES: boolean;
  
  // Security (optional in development)
  TWO_FA_ENCRYPTION_KEY?: string;
  JWT_SECRET?: string;
  WEBHOOK_SECRET?: string;
  
  // Environment
  IS_PRODUCTION: boolean;
  IS_DEVELOPMENT: boolean;
}

class EnvironmentError extends Error {
  constructor(message: string) {
    super(message);
    this.name = 'EnvironmentError';
  }
}

/**
 * Validates that a required environment variable exists
 */
function validateRequired(key: string, value: string | undefined): string {
  if (!value || value.trim() === '') {
    throw new EnvironmentError(`Missing required environment variable: ${key}`);
  }
  return value.trim();
}

/**
 * Validates and parses a boolean environment variable
 */
function validateBoolean(key: string, value: string | undefined, defaultValue: boolean): boolean {
  if (value === undefined || value === '') {
    return defaultValue;
  }
  
  const trimmed = value.trim().toLowerCase();
  if (trimmed === 'true' || trimmed === '1' || trimmed === 'yes') {
    return true;
  }
  if (trimmed === 'false' || trimmed === '0' || trimmed === 'no') {
    return false;
  }
  
  console.warn(`Invalid boolean value for ${key}: "${value}". Using default: ${defaultValue}`);
  return defaultValue;
}

/**
 * Validates URL format
 */
function validateUrl(key: string, value: string): string {
  try {
    new URL(value);
    return value;
  } catch {
    throw new EnvironmentError(`Invalid URL format for ${key}: ${value}`);
  }
}

/**
 * Validates Supabase configuration
 */
function validateSupabase(url: string, anonKey: string): void {
  // Check URL format
  if (!url.includes('supabase.co') && !url.includes('supabase.in') && !url.includes('localhost')) {
    console.warn('Supabase URL does not appear to be a valid Supabase instance');
  }
  
  // Check anon key format (basic check)
  if (anonKey.length < 30) {
    throw new EnvironmentError('Supabase anon key appears to be invalid (too short)');
  }
  
  // Ensure service role key is NOT in environment
  if (import.meta.env.VITE_SUPABASE_SERVICE_ROLE_KEY) {
    throw new EnvironmentError(
      'SECURITY WARNING: Service role key detected in environment variables! ' +
      'Remove it immediately and only use it in Edge Function secrets.'
    );
  }
}

/**
 * Validates Stripe configuration
 */
function validateStripe(publishableKey: string): void {
  const isProduction = import.meta.env.PROD;
  
  // Check for correct key type
  if (isProduction && publishableKey.startsWith('pk_test_')) {
    console.warn('WARNING: Using Stripe test key in production environment!');
  }
  
  if (!isProduction && publishableKey.startsWith('pk_live_')) {
    console.warn('WARNING: Using Stripe live key in development environment!');
  }
  
  // Ensure secret key is NOT in environment
  if (import.meta.env.VITE_STRIPE_SECRET_KEY) {
    throw new EnvironmentError(
      'SECURITY WARNING: Stripe secret key detected in environment variables! ' +
      'Remove it immediately and only use it in Edge Function secrets.'
    );
  }
}

/**
 * Loads and validates all environment variables
 */
export function loadEnvironment(): EnvConfig {
  const isProduction = import.meta.env.PROD;
  const isDevelopment = import.meta.env.DEV;
  
  // Required variables
  const supabaseUrl = validateRequired('VITE_SUPABASE_URL', import.meta.env.VITE_SUPABASE_URL);
  const supabaseAnonKey = validateRequired('VITE_SUPABASE_ANON_KEY', import.meta.env.VITE_SUPABASE_ANON_KEY);
  const stripePublishableKey = validateRequired('VITE_STRIPE_PUBLISHABLE_KEY', import.meta.env.VITE_STRIPE_PUBLISHABLE_KEY);
  
  // Validate URLs
  const appUrl = validateUrl(
    'VITE_APP_URL',
    import.meta.env.VITE_APP_URL || (isProduction ? window.location.origin : 'http://localhost:8080')
  );
  
  // Validate configurations
  validateSupabase(supabaseUrl, supabaseAnonKey);
  validateStripe(stripePublishableKey);
  
  // Feature flags
  const enableAnalytics = validateBoolean('VITE_ENABLE_ANALYTICS', import.meta.env.VITE_ENABLE_ANALYTICS, false);
  const enableAI = validateBoolean('VITE_ENABLE_AI_RECOMMENDATIONS', import.meta.env.VITE_ENABLE_AI_RECOMMENDATIONS, false);
  const enableDevRoutes = validateBoolean('VITE_ENABLE_DEV_ROUTES', import.meta.env.VITE_ENABLE_DEV_ROUTES, false);
  
  // Warn if dev routes are enabled in production
  if (isProduction && enableDevRoutes) {
    console.error('WARNING: Development routes are enabled in production!');
  }
  
  // Optional security keys (required in production)
  const twoFAKey = import.meta.env.TWO_FA_ENCRYPTION_KEY;
  const jwtSecret = import.meta.env.JWT_SECRET;
  const webhookSecret = import.meta.env.WEBHOOK_SECRET;
  
  if (isProduction) {
    if (!twoFAKey) {
      console.warn('Missing TWO_FA_ENCRYPTION_KEY in production');
    }
    if (!jwtSecret) {
      console.warn('Missing JWT_SECRET in production');
    }
    if (!webhookSecret) {
      console.warn('Missing WEBHOOK_SECRET in production');
    }
  }
  
  return {
    SUPABASE_URL: supabaseUrl,
    SUPABASE_ANON_KEY: supabaseAnonKey,
    STRIPE_PUBLISHABLE_KEY: stripePublishableKey,
    APP_URL: appUrl,
    ENABLE_ANALYTICS: enableAnalytics,
    ENABLE_AI_RECOMMENDATIONS: enableAI,
    ENABLE_DEV_ROUTES: enableDevRoutes,
    TWO_FA_ENCRYPTION_KEY: twoFAKey,
    JWT_SECRET: jwtSecret,
    WEBHOOK_SECRET: webhookSecret,
    IS_PRODUCTION: isProduction,
    IS_DEVELOPMENT: isDevelopment
  };
}

/**
 * Singleton instance of validated environment configuration
 */
let envConfig: EnvConfig | null = null;

/**
 * Gets the validated environment configuration
 * Loads and validates on first call, returns cached version afterwards
 */
export function getEnv(): EnvConfig {
  if (!envConfig) {
    try {
      envConfig = loadEnvironment();
      
      // Log environment info (without sensitive data)
      console.log('Environment loaded:', {
        environment: envConfig.IS_PRODUCTION ? 'production' : 'development',
        supabaseUrl: envConfig.SUPABASE_URL.substring(0, 30) + '...',
        stripeMode: envConfig.STRIPE_PUBLISHABLE_KEY.startsWith('pk_live_') ? 'live' : 'test',
        features: {
          analytics: envConfig.ENABLE_ANALYTICS,
          ai: envConfig.ENABLE_AI_RECOMMENDATIONS,
          devRoutes: envConfig.ENABLE_DEV_ROUTES
        }
      });
    } catch (error) {
      console.error('Failed to load environment:', error);
      
      // In development, show error in UI
      if (import.meta.env.DEV) {
        throw error;
      }
      
      // In production, fail silently but log
      console.error('Application may not function correctly due to environment errors');
      
      // Return minimal config to prevent crashes
      envConfig = {
        SUPABASE_URL: '',
        SUPABASE_ANON_KEY: '',
        STRIPE_PUBLISHABLE_KEY: '',
        APP_URL: window.location.origin,
        ENABLE_ANALYTICS: false,
        ENABLE_AI_RECOMMENDATIONS: false,
        ENABLE_DEV_ROUTES: false,
        IS_PRODUCTION: true,
        IS_DEVELOPMENT: false
      };
    }
  }
  
  return envConfig;
}

/**
 * Resets the environment cache (useful for testing)
 */
export function resetEnvCache(): void {
  envConfig = null;
}

// Auto-validate on module load
if (import.meta.env.DEV) {
  try {
    getEnv();
  } catch (error) {
    console.error('Environment validation failed:', error);
  }
}