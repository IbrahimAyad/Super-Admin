/**
 * Utility to generate secure encryption keys for 2FA
 * Run this to generate a new key: npx tsx src/lib/security/generateKeys.ts
 */

import crypto from 'crypto';

// Generate a secure 256-bit key for AES encryption
export function generateEncryptionKey(): string {
  return crypto.randomBytes(32).toString('hex');
}

// Generate a secure JWT secret
export function generateJWTSecret(): string {
  return crypto.randomBytes(64).toString('hex');
}

// Generate a secure webhook secret
export function generateWebhookSecret(): string {
  return crypto.randomBytes(32).toString('hex');
}

// Generate all keys
export function generateAllKeys() {
  console.log('=== Secure Keys Generator ===\n');
  
  console.log('# Add these to your .env file:\n');
  
  const encryptionKey = generateEncryptionKey();
  console.log(`# 2FA Encryption Key (AES-256)`);
  console.log(`TWO_FA_ENCRYPTION_KEY=${encryptionKey}\n`);
  
  const jwtSecret = generateJWTSecret();
  console.log(`# JWT Secret for session tokens`);
  console.log(`JWT_SECRET=${jwtSecret}\n`);
  
  const webhookSecret = generateWebhookSecret();
  console.log(`# Webhook Secret for API security`);
  console.log(`WEBHOOK_SECRET=${webhookSecret}\n`);
  
  console.log('# Security reminder:');
  console.log('# - Never commit these keys to version control');
  console.log('# - Rotate keys regularly in production');
  console.log('# - Use different keys for each environment');
  console.log('# - Store production keys in secure vault (e.g., AWS Secrets Manager)');
}

// Run if executed directly
if (import.meta.url === `file://${process.argv[1]}`) {
  generateAllKeys();
}