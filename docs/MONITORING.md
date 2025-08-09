# Monitoring & Logging Guide

Comprehensive monitoring, logging, and observability setup for KCT Menswear Super Admin.

## Overview

The monitoring system provides:
- Centralized logging
- Error tracking
- Performance monitoring
- User analytics
- System health checks
- Real-time alerting

## Architecture

```
┌─────────────────┐
│   Application   │
├─────────────────┤
│ Monitoring SDK  │
├─────────────────┤
│   Log Buffer    │
├─────────────────┤
│   API Gateway   │
├─────────────────┤
│ Logging Backend │
└─────────────────┘
         ↓
┌─────────────────┐
│  Time Series DB │ → Grafana
│  Log Storage    │ → Kibana
│  Error Tracking │ → Sentry
│  Analytics      │ → Google Analytics
└─────────────────┘
```

## Client-Side Monitoring

### Usage

```typescript
import { logger, track, timer } from '@/lib/services/monitoring';

// Logging
logger.info('User logged in', { userId: user.id });
logger.error('Payment failed', error, { orderId });

// Tracking
track.event('checkout_completed', { value: 299.99 });
track.pageView('/products', 'Products Page');
track.userAction('click', 'button', 'add-to-cart');

// Performance
const endTimer = timer.start('api_call');
await fetchData();
endTimer();

// Async timing
const data = await timer.measureAsync('fetch_products', async () => {
  return await supabase.from('products').select();
});
```

### Log Levels

| Level | Use Case | Example |
|-------|----------|---------|
| DEBUG | Development info | `logger.debug('Cache hit', { key })` |
| INFO | General information | `logger.info('Order placed', { orderId })` |
| WARN | Potential issues | `logger.warn('Slow query', { duration })` |
| ERROR | Recoverable errors | `logger.error('API failed', error)` |
| FATAL | Critical failures | `logger.fatal('Database down', error)` |

## Server-Side Logging

### Edge Functions

```typescript
// In Edge Functions
import { createClient } from '@supabase/supabase-js';

const log = async (level: string, message: string, context?: any) => {
  await supabase.from('logs').insert({
    level,
    message,
    context,
    function_name: Deno.env.get('FUNCTION_NAME'),
    timestamp: new Date().toISOString()
  });
};

// Usage
await log('info', 'Processing order', { orderId });
```

### Database Logging

```sql
-- Create logs table
CREATE TABLE IF NOT EXISTS logs (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  level VARCHAR(10) NOT NULL,
  message TEXT NOT NULL,
  context JSONB,
  user_id UUID REFERENCES auth.users(id),
  session_id VARCHAR(50),
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Create index for faster queries
CREATE INDEX idx_logs_created_at ON logs(created_at DESC);
CREATE INDEX idx_logs_level ON logs(level);
CREATE INDEX idx_logs_user_id ON logs(user_id);
```

## Metrics & Performance

### Key Metrics

#### Application Metrics

```typescript
// Page load time
track.metric('page_load', loadTime, 'ms');

// API response time
track.metric('api_response', responseTime, 'ms', { endpoint: '/api/products' });

// Database query time
track.metric('db_query', queryTime, 'ms', { table: 'orders' });

// Cache hit rate
track.metric('cache_hit_rate', hitRate, 'percentage');
```

#### Business Metrics

```typescript
// Revenue
track.metric('revenue', amount, 'usd', { source: 'stripe' });

// Conversion rate
track.metric('conversion_rate', rate, 'percentage', { funnel: 'checkout' });

// Cart abandonment
track.metric('cart_abandonment', count, 'count', { reason: 'payment_failed' });
```

### Performance Budget

| Metric | Target | Warning | Critical |
|--------|--------|---------|----------|
| Page Load | <2s | 2-4s | >4s |
| API Response | <200ms | 200-500ms | >500ms |
| Database Query | <50ms | 50-200ms | >200ms |
| JavaScript Bundle | <500KB | 500-1MB | >1MB |
| First Contentful Paint | <1s | 1-2s | >2s |

## Error Tracking

### Setup Sentry

```typescript
// Install
npm install @sentry/react

// Initialize
import * as Sentry from "@sentry/react";

Sentry.init({
  dsn: "YOUR_SENTRY_DSN",
  environment: process.env.NODE_ENV,
  integrations: [
    new Sentry.BrowserTracing(),
    new Sentry.Replay()
  ],
  tracesSampleRate: 0.1,
  replaysSessionSampleRate: 0.1,
  replaysOnErrorSampleRate: 1.0,
});
```

### Error Boundaries Integration

```typescript
// Integrate with error boundaries
export class ErrorBoundary extends Component {
  componentDidCatch(error: Error, errorInfo: ErrorInfo) {
    logger.error('Component error', error, errorInfo);
    
    if (import.meta.env.PROD) {
      Sentry.captureException(error, {
        contexts: { react: errorInfo }
      });
    }
  }
}
```

## Analytics

### Google Analytics 4

```html
<!-- Add to index.html -->
<script async src="https://www.googletagmanager.com/gtag/js?id=G-XXXXXXXXXX"></script>
<script>
  window.dataLayer = window.dataLayer || [];
  function gtag(){dataLayer.push(arguments);}
  gtag('js', new Date());
  gtag('config', 'G-XXXXXXXXXX');
</script>
```

### Custom Events

```typescript
// E-commerce events
track.event('purchase', {
  transaction_id: '12345',
  value: 299.99,
  currency: 'USD',
  items: [...]
});

track.event('add_to_cart', {
  currency: 'USD',
  value: 99.99,
  items: [{ item_id: 'SKU123', item_name: 'Suit' }]
});

// User events
track.event('sign_up', { method: 'email' });
track.event('login', { method: 'google' });
```

## Health Checks

### API Health Endpoint

```typescript
// /api/health
export async function GET() {
  const checks = {
    database: await checkDatabase(),
    redis: await checkRedis(),
    stripe: await checkStripe(),
    storage: await checkStorage()
  };
  
  const healthy = Object.values(checks).every(c => c.status === 'healthy');
  
  return new Response(JSON.stringify({
    status: healthy ? 'healthy' : 'degraded',
    checks,
    timestamp: new Date().toISOString()
  }), {
    status: healthy ? 200 : 503
  });
}
```

### Uptime Monitoring

Configure with services like:
- UptimeRobot
- Pingdom
- DataDog
- New Relic

## Alerting

### Alert Rules

```yaml
# Prometheus alert rules
groups:
  - name: application
    rules:
      - alert: HighErrorRate
        expr: rate(errors_total[5m]) > 0.05
        for: 5m
        annotations:
          summary: "High error rate detected"
          
      - alert: SlowAPIResponse
        expr: http_request_duration_seconds{quantile="0.95"} > 1
        for: 10m
        annotations:
          summary: "API response time is slow"
          
      - alert: LowDiskSpace
        expr: disk_free_bytes / disk_total_bytes < 0.1
        for: 5m
        annotations:
          summary: "Low disk space"
```

### Notification Channels

```typescript
// Slack notifications
const sendSlackAlert = async (message: string, severity: 'info' | 'warning' | 'critical') => {
  const color = {
    info: '#36a64f',
    warning: '#ff9900',
    critical: '#ff0000'
  }[severity];
  
  await fetch(SLACK_WEBHOOK_URL, {
    method: 'POST',
    body: JSON.stringify({
      attachments: [{
        color,
        title: 'KCT Admin Alert',
        text: message,
        timestamp: Math.floor(Date.now() / 1000)
      }]
    })
  });
};
```

## Dashboard Setup

### Grafana Configuration

```json
{
  "dashboard": {
    "title": "KCT Admin Monitoring",
    "panels": [
      {
        "title": "Request Rate",
        "targets": [{
          "expr": "rate(http_requests_total[5m])"
        }]
      },
      {
        "title": "Error Rate",
        "targets": [{
          "expr": "rate(http_requests_total{status=~'5..'}[5m])"
        }]
      },
      {
        "title": "Response Time",
        "targets": [{
          "expr": "histogram_quantile(0.95, http_request_duration_seconds)"
        }]
      },
      {
        "title": "Active Users",
        "targets": [{
          "expr": "active_users_total"
        }]
      }
    ]
  }
}
```

### Key Dashboards

1. **System Overview**
   - Request rate
   - Error rate
   - Response times
   - CPU/Memory usage

2. **Business Metrics**
   - Revenue
   - Orders
   - Conversion rates
   - User activity

3. **Performance**
   - Page load times
   - API latencies
   - Database performance
   - Cache hit rates

4. **Errors**
   - Error frequency
   - Error types
   - Affected users
   - Error trends

## Log Aggregation

### ELK Stack Setup

```yaml
# docker-compose.yml
version: '3'
services:
  elasticsearch:
    image: elasticsearch:8.0.0
    environment:
      - discovery.type=single-node
      
  logstash:
    image: logstash:8.0.0
    volumes:
      - ./logstash.conf:/usr/share/logstash/pipeline/logstash.conf
      
  kibana:
    image: kibana:8.0.0
    ports:
      - "5601:5601"
```

### Logstash Configuration

```ruby
# logstash.conf
input {
  http {
    port => 8080
    codec => json
  }
}

filter {
  date {
    match => [ "timestamp", "ISO8601" ]
  }
  
  grok {
    match => { "message" => "%{LOGLEVEL:level} %{GREEDYDATA:msg}" }
  }
}

output {
  elasticsearch {
    hosts => ["elasticsearch:9200"]
    index => "kct-logs-%{+YYYY.MM.dd}"
  }
}
```

## Security & Compliance

### PII Handling

```typescript
// Sanitize sensitive data
const sanitizeLog = (data: any): any => {
  const sensitive = ['password', 'token', 'api_key', 'credit_card'];
  
  const sanitized = { ...data };
  for (const key of Object.keys(sanitized)) {
    if (sensitive.some(s => key.toLowerCase().includes(s))) {
      sanitized[key] = '[REDACTED]';
    }
  }
  
  return sanitized;
};
```

### GDPR Compliance

- Log retention: 90 days
- User consent for analytics
- Right to deletion
- Data anonymization

## Troubleshooting

### Common Issues

#### Logs not appearing

```bash
# Check buffer size
localStorage.getItem('monitoring_buffer')

# Force flush
monitoring.flush()

# Check network
curl -X POST https://your-api/logs -d '{"test": true}'
```

#### High memory usage

```javascript
// Reduce buffer size
monitoring.setMaxBufferSize(50);

// Increase flush frequency
monitoring.setFlushInterval(2000);
```

#### Missing metrics

```javascript
// Enable debug mode
localStorage.setItem('monitoring_debug', 'true');

// Check Performance API support
console.log('Performance API:', 'performance' in window);
```

## Best Practices

1. **Structured Logging**
   ```typescript
   // Good
   logger.info('Order processed', {
     orderId: '123',
     userId: '456',
     amount: 299.99
   });
   
   // Bad
   logger.info(`Order 123 processed for user 456 amount $299.99`);
   ```

2. **Correlation IDs**
   ```typescript
   const correlationId = generateId();
   logger.info('Request started', { correlationId });
   // ... operations ...
   logger.info('Request completed', { correlationId });
   ```

3. **Error Context**
   ```typescript
   try {
     await processOrder(order);
   } catch (error) {
     logger.error('Order processing failed', error, {
       orderId: order.id,
       step: 'payment',
       attemptNumber: 3
     });
   }
   ```

4. **Performance Budgets**
   ```typescript
   const budget = 1000; // ms
   const duration = await timer.measureAsync('operation', async () => {
     return await expensiveOperation();
   });
   
   if (duration > budget) {
     logger.warn('Performance budget exceeded', {
       operation: 'expensive_operation',
       duration,
       budget
     });
   }
   ```

## Related Documentation

- [Error Boundaries](./components/error/ErrorBoundary.tsx)
- [Environment Configuration](./lib/config/env.ts)
- [Database Backup](./DATABASE_BACKUP.md)
- [Deployment Guide](./DEPLOYMENT.md)

---

**Last Updated**: August 2025  
**Version**: 1.0.0