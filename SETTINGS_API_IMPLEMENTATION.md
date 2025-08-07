# Settings API & Synchronization Implementation

## Overview
A comprehensive settings management system with API layer, real-time synchronization, and security controls for the KCT Admin system.

## 🏗️ Architecture Components

### 1. Database Layer
**File:** `supabase/migrations/040_create_settings_system.sql`
- **Settings table** with comprehensive metadata
- **Audit logging** for all changes
- **Cache table** for performance optimization
- **RLS policies** for security
- **Database functions** for atomic operations

### 2. Core Services

#### Settings Service
**File:** `src/lib/services/settings.ts`
- `getSettings(category?)` - Fetch settings with caching
- `updateSetting(key, value, options)` - Update with validation
- `getPublicSettings()` - Website-safe settings
- `validateSettings()` - Schema validation
- Built-in **encryption** for sensitive data
- **Memory caching** with TTL

#### Security Service  
**File:** `src/lib/services/settingsSecurity.ts`
- **Role-based access control**
- **Encryption/decryption** of sensitive settings
- **Audit logging** with risk levels
- **Permission checking** by setting type
- **Export functionality** with security filtering

#### Sync Service
**File:** `src/lib/services/settingsSync.ts`
- **Real-time broadcasting** via Supabase Realtime
- **Reliable delivery** with retry mechanisms
- **Multi-channel support** (public, admin, website)
- **Maintenance mode** notifications

### 3. Edge Functions

#### Public Settings API
**File:** `supabase/functions/get-public-settings/index.ts`
- **Rate limiting** (100 req/min)
- **Caching** with ETags and version control
- **Security validation**
- **CORS support**
- **Error handling** with fallbacks

### 4. React Integration

#### React Query Hooks
**File:** `src/hooks/useSettings.ts`
- `useSettings(category?)` - Query all settings
- `useSetting(key)` - Query single setting
- `useUpdateSetting()` - Mutation with optimistic updates
- `useBulkUpdateSettings()` - Batch operations
- **Real-time subscriptions**
- **Cache management**

#### Settings Context
**File:** `src/contexts/SettingsContext.tsx`
- **Global state management**
- **Loading and error states**
- **Real-time updates**
- **Quick access** to common settings
- **HOC wrapper** for components

### 5. Admin Interface

#### Settings Management Component
**File:** `src/components/admin/SettingsManagement.tsx`
- **Full CRUD operations**
- **Security recommendations**
- **Audit log viewer**
- **Export/import functionality**
- **Real-time sync controls**
- **Category filtering** and search

## 🔒 Security Features

### Access Control
- **Super Admin** settings require highest privileges
- **Sensitive categories** require admin access
- **Critical settings** require confirmation
- **Audit logging** for all actions

### Data Protection
- **AES-GCM encryption** for sensitive values
- **Secure key derivation** (PBKDF2)
- **Value validation** against injection attacks
- **Export filtering** by security level

### Monitoring
- **Risk-based audit logging**
- **Security recommendations**
- **Critical event notifications**
- **Permission tracking**

## ⚡ Performance Features

### Caching Strategy
- **Multi-level caching**:
  - Memory cache (5min TTL)
  - Database cache table
  - React Query cache
- **Cache invalidation** on updates
- **Stale-while-revalidate** patterns

### Real-time Sync
- **Supabase Realtime** channels
- **Broadcast queuing** with retries
- **Audience targeting** (public, admin, website)
- **Maintenance mode** notifications

## 🌐 Website Integration

### For the Website Codebase
```javascript
// Fetch public settings
const response = await fetch('/functions/v1/get-public-settings');
const { settings } = await response.json();

// Subscribe to changes
const channel = supabase.channel('public_settings_sync');
channel.on('broadcast', { event: 'settings_updated' }, ({ payload }) => {
  updateSettings(payload.settings);
});
```

### Settings Available to Website
- `site_name` - Display name
- `currency` - Default currency
- `free_shipping_threshold` - Shipping rules
- `maintenance_mode` - Site availability
- `max_cart_items` - Cart limits

## 📊 Usage Examples

### Admin Operations
```typescript
import { settingsService, useSettings, useUpdateSetting } from '../lib/services';

// Get all settings
const { data: settings } = useSettings();

// Update a setting
const updateMutation = useUpdateSetting();
await updateMutation.mutateAsync({
  key: 'site_name',
  value: 'New Site Name',
  options: { is_public: true }
});

// Sync to website
await settingsSyncService.broadcastSettingsUpdate(['site_name'], 'website');
```

### Security Operations
```typescript
import { settingsSecurityService } from '../lib/services';

// Check permissions
const permission = await settingsSecurityService.checkPermission(
  'stripe_secret_key', 
  'write'
);

// Encrypt sensitive data
const encrypted = await settingsSecurityService.encryptValue(secretKey);

// Get security recommendations
const recommendations = settingsSecurityService.getSecurityRecommendations(
  'api_key', 
  setting
);
```

## 🚀 Deployment Steps

1. **Run Migration**
   ```bash
   supabase db push
   ```

2. **Deploy Edge Function**
   ```bash
   supabase functions deploy get-public-settings
   ```

3. **Update Environment Variables**
   ```bash
   VITE_ENCRYPTION_KEY=your-secure-encryption-key
   ```

4. **Initialize Settings**
   - Default settings are created by migration
   - Access admin panel to configure additional settings

## 📈 Monitoring & Maintenance

### Health Checks
- Settings count and distribution
- Cache hit rates
- Sync queue status
- Security recommendations count
- Recent audit events

### Maintenance Tasks
- **Cache cleanup** (automated)
- **Audit log rotation** (manual)
- **Security reviews** (monthly)
- **Performance monitoring** (ongoing)

## 🔧 Configuration

### Rate Limiting
- **Public API**: 100 requests/minute
- **Admin operations**: 500 requests/minute
- **Critical operations**: Additional confirmation required

### Cache Settings
- **Memory TTL**: 5 minutes
- **Database cache**: 5 minutes
- **Browser cache**: 5 minutes (with ETags)

### Security Levels
- **PUBLIC**: Website accessible
- **ADMIN**: Admin panel only
- **SUPER_ADMIN**: Highest privileges
- **SYSTEM**: Internal operations

## 📝 API Documentation

### Edge Function Endpoints

#### GET /get-public-settings
Returns public settings for website consumption.

**Query Parameters:**
- `nocache=true` - Force cache refresh
- `version=<hash>` - Check for changes

**Response:**
```json
{
  "settings": {
    "site_name": "KCT Menswear",
    "currency": "USD",
    "maintenance_mode": false
  },
  "cached": true,
  "cache_expires_at": "2025-08-07T12:00:00Z",
  "version": "abc123"
}
```

**Headers:**
- `X-RateLimit-Limit` - Rate limit
- `X-RateLimit-Remaining` - Remaining requests
- `ETag` - Version for caching

## 🎯 Next Steps

1. **Add more Edge Functions** for specific setting categories
2. **Implement bulk import** functionality
3. **Add setting templates** for common configurations
4. **Create mobile app integration**
5. **Add analytics** for setting usage patterns

---

**Created:** 2025-08-07
**Status:** ✅ Complete
**Security Level:** Production Ready