/**
 * PREFIXED STORAGE UTILITY
 * Provides prefixed localStorage/sessionStorage to prevent conflicts across deployments
 * Last updated: 2025-08-07
 */

// Get deployment URL for storage key prefixing
const getDeploymentUrl = (): string => {
  if (typeof window !== 'undefined') {
    return window.location.origin;
  }
  return import.meta.env.VITE_SUPABASE_URL || 'localhost';
};

// Create storage key prefix based on deployment URL
const createStorageKeyPrefix = (): string => {
  const deploymentUrl = getDeploymentUrl();
  const cleanUrl = deploymentUrl.replace(/[^a-zA-Z0-9]/g, '').toLowerCase();
  return `kct-${cleanUrl}`;
};

const STORAGE_PREFIX = createStorageKeyPrefix();

/**
 * Prefixed localStorage wrapper
 */
export const storage = {
  /**
   * Get an item from localStorage with deployment prefix
   */
  getItem: (key: string): string | null => {
    if (typeof window === 'undefined') return null;
    const prefixedKey = `${STORAGE_PREFIX}-${key}`;
    return localStorage.getItem(prefixedKey);
  },

  /**
   * Set an item in localStorage with deployment prefix
   */
  setItem: (key: string, value: string): void => {
    if (typeof window === 'undefined') return;
    const prefixedKey = `${STORAGE_PREFIX}-${key}`;
    localStorage.setItem(prefixedKey, value);
  },

  /**
   * Remove an item from localStorage with deployment prefix
   */
  removeItem: (key: string): void => {
    if (typeof window === 'undefined') return;
    const prefixedKey = `${STORAGE_PREFIX}-${key}`;
    localStorage.removeItem(prefixedKey);
  },

  /**
   * Clear all items with our prefix (leaves other apps' data intact)
   */
  clear: (): void => {
    if (typeof window === 'undefined') return;
    const keys = Object.keys(localStorage);
    const prefixedKeys = keys.filter(key => key.startsWith(`${STORAGE_PREFIX}-`));
    prefixedKeys.forEach(key => localStorage.removeItem(key));
  },

  /**
   * Check if an item exists
   */
  hasItem: (key: string): boolean => {
    return storage.getItem(key) !== null;
  },

  /**
   * Get an item and parse as JSON, with optional default value
   */
  getJSON: <T>(key: string, defaultValue?: T): T | null => {
    const item = storage.getItem(key);
    if (item === null) {
      return defaultValue ?? null;
    }
    try {
      return JSON.parse(item) as T;
    } catch {
      console.warn(`Failed to parse JSON for storage key: ${key}`);
      return defaultValue ?? null;
    }
  },

  /**
   * Set an item by stringifying as JSON
   */
  setJSON: <T>(key: string, value: T): void => {
    storage.setItem(key, JSON.stringify(value));
  }
};

/**
 * Prefixed sessionStorage wrapper
 */
export const sessionStorage = {
  /**
   * Get an item from sessionStorage with deployment prefix
   */
  getItem: (key: string): string | null => {
    if (typeof window === 'undefined') return null;
    const prefixedKey = `${STORAGE_PREFIX}-${key}`;
    return window.sessionStorage.getItem(prefixedKey);
  },

  /**
   * Set an item in sessionStorage with deployment prefix
   */
  setItem: (key: string, value: string): void => {
    if (typeof window === 'undefined') return;
    const prefixedKey = `${STORAGE_PREFIX}-${key}`;
    window.sessionStorage.setItem(prefixedKey, value);
  },

  /**
   * Remove an item from sessionStorage with deployment prefix
   */
  removeItem: (key: string): void => {
    if (typeof window === 'undefined') return;
    const prefixedKey = `${STORAGE_PREFIX}-${key}`;
    window.sessionStorage.removeItem(prefixedKey);
  },

  /**
   * Clear all items with our prefix
   */
  clear: (): void => {
    if (typeof window === 'undefined') return;
    const keys = Object.keys(window.sessionStorage);
    const prefixedKeys = keys.filter(key => key.startsWith(`${STORAGE_PREFIX}-`));
    prefixedKeys.forEach(key => window.sessionStorage.removeItem(key));
  },

  /**
   * Check if an item exists
   */
  hasItem: (key: string): boolean => {
    return sessionStorage.getItem(key) !== null;
  },

  /**
   * Get an item and parse as JSON, with optional default value
   */
  getJSON: <T>(key: string, defaultValue?: T): T | null => {
    const item = sessionStorage.getItem(key);
    if (item === null) {
      return defaultValue ?? null;
    }
    try {
      return JSON.parse(item) as T;
    } catch {
      console.warn(`Failed to parse JSON for sessionStorage key: ${key}`);
      return defaultValue ?? null;
    }
  },

  /**
   * Set an item by stringifying as JSON
   */
  setJSON: <T>(key: string, value: T): void => {
    sessionStorage.setItem(key, JSON.stringify(value));
  }
};

/**
 * Get the current storage prefix (useful for debugging)
 */
export const getStoragePrefix = (): string => STORAGE_PREFIX;

/**
 * Migration utility to move data from unprefixed keys to prefixed keys
 */
export const migrateStorageKeys = (keys: string[]): void => {
  if (typeof window === 'undefined') return;
  
  keys.forEach(key => {
    // Check if unprefixed key exists and prefixed doesn't
    const unprefixedValue = localStorage.getItem(key);
    const prefixedExists = storage.hasItem(key);
    
    if (unprefixedValue && !prefixedExists) {
      console.log(`Migrating storage key: ${key} -> ${STORAGE_PREFIX}-${key}`);
      storage.setItem(key, unprefixedValue);
      localStorage.removeItem(key); // Remove the old unprefixed key
    }
  });
};

export default storage;