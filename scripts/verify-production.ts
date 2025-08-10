#!/usr/bin/env npx tsx

/**
 * Production Setup Verification Script
 * Run this to verify all services are connected and configured correctly
 */

import * as dotenv from 'dotenv';
import { createClient } from '@supabase/supabase-js';

// Load environment variables
dotenv.config();

// Colors for console output
const colors = {
  reset: '\x1b[0m',
  green: '\x1b[32m',
  red: '\x1b[31m',
  yellow: '\x1b[33m',
  blue: '\x1b[34m',
  cyan: '\x1b[36m'
};

const log = {
  success: (msg: string) => console.log(`${colors.green}✅ ${msg}${colors.reset}`),
  error: (msg: string) => console.log(`${colors.red}❌ ${msg}${colors.reset}`),
  warning: (msg: string) => console.log(`${colors.yellow}⚠️  ${msg}${colors.reset}`),
  info: (msg: string) => console.log(`${colors.cyan}ℹ️  ${msg}${colors.reset}`),
  header: (msg: string) => console.log(`\n${colors.blue}${msg}${colors.reset}\n${'='.repeat(50)}`)
};

async function verifyProduction() {
  log.header('🔍 PRODUCTION VERIFICATION');
  
  // Check environment variables
  log.header('Environment Variables');
  
  const requiredEnvVars = [
    'VITE_SUPABASE_URL',
    'VITE_SUPABASE_ANON_KEY',
    'VITE_STRIPE_PUBLISHABLE_KEY'
  ];
  
  let envVarsOk = true;
  for (const envVar of requiredEnvVars) {
    if (process.env[envVar]) {
      log.success(`${envVar} is set`);
      
      // Show partial values for verification
      if (envVar === 'VITE_STRIPE_PUBLISHABLE_KEY') {
        const key = process.env[envVar]!;
        const mode = key.startsWith('pk_live') ? 'LIVE MODE' : 'TEST MODE';
        log.info(`  Stripe Mode: ${mode}`);
      }
    } else {
      log.error(`${envVar} is NOT set`);
      envVarsOk = false;
    }
  }
  
  if (!envVarsOk) {
    log.error('Missing environment variables. Please check your .env file.');
    process.exit(1);
  }
  
  // Test Supabase connection
  log.header('Supabase Connection');
  
  const supabase = createClient(
    process.env.VITE_SUPABASE_URL!,
    process.env.VITE_SUPABASE_ANON_KEY!
  );
  
  try {
    // Test basic connectivity
    const { data: healthCheck, error: healthError } = await supabase
      .from('products')
      .select('count', { count: 'exact', head: true });
    
    if (healthError) {
      log.error(`Cannot connect to Supabase: ${healthError.message}`);
    } else {
      log.success('Connected to Supabase');
    }
    
    // Check important tables
    const tables = [
      { name: 'products', required: true },
      { name: 'customers', required: true },
      { name: 'orders', required: true },
      { name: 'admin_users', required: true },
      { name: 'user_profiles', required: false },
      { name: 'categories', required: false },
      { name: 'stripe_sync_log', required: false }
    ];
    
    log.header('Database Tables');
    
    let missingRequired = false;
    for (const table of tables) {
      const { count, error } = await supabase
        .from(table.name)
        .select('*', { count: 'exact', head: true });
      
      if (error) {
        if (table.required) {
          log.error(`${table.name}: ${error.message}`);
          missingRequired = true;
        } else {
          log.warning(`${table.name}: ${error.message}`);
        }
      } else {
        log.success(`${table.name}: ${count || 0} records`);
      }
    }
    
    if (missingRequired) {
      log.warning('Some required tables are missing. Run database migrations.');
    }
    
    // Check for admin users
    const { data: admins, error: adminError } = await supabase
      .from('admin_users')
      .select('email, is_active')
      .eq('is_active', true);
    
    if (!adminError && admins) {
      log.header('Admin Users');
      if (admins.length === 0) {
        log.warning('No active admin users found');
      } else {
        log.success(`${admins.length} active admin(s) found`);
        admins.forEach(admin => {
          log.info(`  - ${admin.email}`);
        });
      }
    }
    
  } catch (error) {
    log.error(`Supabase connection failed: ${error}`);
  }
  
  // Check Stripe configuration
  log.header('Stripe Configuration');
  
  const stripeKey = process.env.VITE_STRIPE_PUBLISHABLE_KEY;
  if (stripeKey) {
    if (stripeKey.startsWith('pk_live')) {
      log.warning('Using LIVE Stripe key - Real payments will be processed!');
    } else if (stripeKey.startsWith('pk_test')) {
      log.success('Using TEST Stripe key - Safe for testing');
    } else {
      log.error('Invalid Stripe key format');
    }
  }
  
  // Summary
  log.header('📊 SUMMARY');
  
  log.info('Next Steps:');
  console.log('1. Run database migrations if tables are missing');
  console.log('2. Deploy Edge Functions for Stripe webhooks');
  console.log('3. Create an admin user if none exists');
  console.log('4. Configure Stripe webhook endpoints');
  console.log('5. Test the application at your deployed URL');
  
  log.header('🚀 Production URL');
  log.info('Your app should be live at:');
  console.log('https://super-admin-git-main-ibrahimayads-projects.vercel.app/');
}

// Run verification
verifyProduction().catch(console.error);