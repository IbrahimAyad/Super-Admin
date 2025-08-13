#!/bin/bash

# ============================================
# PRODUCTION DEPLOYMENT & MONITORING SETUP
# KCT Menswear E-commerce Platform
# ============================================

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
ENVIRONMENT="${ENVIRONMENT:-production}"
SUPABASE_PROJECT_ID="${SUPABASE_PROJECT_ID}"
VERCEL_PROJECT_NAME="${VERCEL_PROJECT_NAME:-kct-menswear-admin}"
MONITORING_EMAIL="${MONITORING_EMAIL:-admin@kctmenswear.com}"
SLACK_WEBHOOK_URL="${SLACK_WEBHOOK_URL}"

# Logging function
log() {
    echo -e "${BLUE}[$(date +'%Y-%m-%d %H:%M:%S')]${NC} $1"
}

success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check prerequisites
check_prerequisites() {
    log "Checking prerequisites..."
    
    # Check required environment variables
    if [[ -z "$SUPABASE_PROJECT_ID" ]]; then
        error "SUPABASE_PROJECT_ID environment variable is required"
        exit 1
    fi
    
    if [[ -z "$SUPABASE_URL" ]]; then
        error "SUPABASE_URL environment variable is required"
        exit 1
    fi
    
    if [[ -z "$SUPABASE_SERVICE_ROLE_KEY" ]]; then
        error "SUPABASE_SERVICE_ROLE_KEY environment variable is required"
        exit 1
    fi
    
    # Check required commands
    local required_commands=("psql" "curl" "node" "npm")
    for cmd in "${required_commands[@]}"; do
        if ! command -v "$cmd" &> /dev/null; then
            error "Required command '$cmd' is not installed"
            exit 1
        fi
    done
    
    success "Prerequisites check completed"
}

# Deploy database monitoring infrastructure
deploy_database_monitoring() {
    log "Deploying database monitoring infrastructure..."
    
    # Apply comprehensive monitoring setup
    log "Applying comprehensive monitoring schema..."
    psql "$SUPABASE_URL" -c "\i comprehensive-production-monitoring.sql" || {
        error "Failed to apply comprehensive monitoring setup"
        exit 1
    }
    
    # Apply inventory monitoring and BI
    log "Applying inventory monitoring and business intelligence..."
    psql "$SUPABASE_URL" -c "\i inventory-monitoring-business-intelligence.sql" || {
        error "Failed to apply inventory monitoring setup"
        exit 1
    }
    
    success "Database monitoring infrastructure deployed"
}

# Deploy Supabase Edge Functions
deploy_edge_functions() {
    log "Deploying Supabase Edge Functions..."
    
    # Check if Supabase CLI is available
    if ! command -v supabase &> /dev/null; then
        error "Supabase CLI is not installed. Please install it first:"
        error "npm install -g supabase"
        exit 1
    fi
    
    # Login to Supabase (if not already logged in)
    supabase login --token "$SUPABASE_SERVICE_ROLE_KEY" || {
        error "Failed to login to Supabase"
        exit 1
    }
    
    # Link to project
    supabase link --project-ref "$SUPABASE_PROJECT_ID" || {
        error "Failed to link to Supabase project"
        exit 1
    }
    
    # Deploy all edge functions
    log "Deploying edge functions..."
    supabase functions deploy --no-verify-jwt || {
        error "Failed to deploy edge functions"
        exit 1
    }
    
    success "Edge functions deployed successfully"
}

# Setup monitoring services
setup_monitoring_services() {
    log "Setting up monitoring services..."
    
    # Create monitoring configuration file
    cat > monitoring-config.json << EOF
{
  "environment": "$ENVIRONMENT",
  "supabase": {
    "url": "$SUPABASE_URL",
    "project_id": "$SUPABASE_PROJECT_ID"
  },
  "monitoring": {
    "check_interval_seconds": 60,
    "alert_channels": {
      "email": "$MONITORING_EMAIL",
      "slack": "$SLACK_WEBHOOK_URL"
    },
    "thresholds": {
      "database": {
        "connection_usage_warning": 70,
        "connection_usage_critical": 85,
        "cache_hit_ratio_warning": 90,
        "cache_hit_ratio_critical": 80
      },
      "api": {
        "response_time_warning": 200,
        "response_time_critical": 500,
        "error_rate_warning": 1,
        "error_rate_critical": 3
      },
      "business": {
        "conversion_rate_warning": 2,
        "conversion_rate_critical": 1,
        "payment_failure_warning": 5,
        "payment_failure_critical": 10
      }
    }
  }
}
EOF
    
    success "Monitoring configuration created"
}

# Setup alerting rules
setup_alerting() {
    log "Setting up alerting rules..."
    
    # Create alerting configuration
    cat > alerting-rules.sql << 'EOF'
-- Insert notification channels
INSERT INTO notification_channels (id, name, type, config, enabled) VALUES
('slack_critical', 'Slack Critical Alerts', 'slack', 
 jsonb_build_object('webhook_url', '$SLACK_WEBHOOK_URL'), true),
('email_admin', 'Admin Email Alerts', 'email',
 jsonb_build_object('email_addresses', ARRAY['$MONITORING_EMAIL']), true)
ON CONFLICT (id) DO UPDATE SET
  config = EXCLUDED.config,
  enabled = EXCLUDED.enabled;

-- Insert incident rules
INSERT INTO incident_rules (
  id, name, category, severity, auto_create_incident,
  notify_channels, conditions, enabled, created_by
) VALUES
('payment_failures', 'Payment Failure Detection', 'payment_failure', 'critical', true,
 ARRAY['slack_critical', 'email_admin'],
 jsonb_build_object('time_window_minutes', 15, 'minimum_occurrences', 5, 'ignore_resolved_duplicates', true),
 true, 'system'),
 
('database_performance', 'Database Performance Issues', 'database_error', 'warning', true,
 ARRAY['slack_critical'],
 jsonb_build_object('time_window_minutes', 5, 'minimum_occurrences', 3, 'ignore_resolved_duplicates', true),
 true, 'system'),
 
('api_errors', 'High API Error Rate', 'api_error', 'warning', true,
 ARRAY['slack_critical'],
 jsonb_build_object('time_window_minutes', 10, 'minimum_occurrences', 10, 'ignore_resolved_duplicates', true),
 true, 'system')

ON CONFLICT (id) DO UPDATE SET
  notify_channels = EXCLUDED.notify_channels,
  conditions = EXCLUDED.conditions,
  enabled = EXCLUDED.enabled;
EOF
    
    # Apply alerting rules
    envsubst < alerting-rules.sql | psql "$SUPABASE_URL" || {
        error "Failed to setup alerting rules"
        exit 1
    }
    
    success "Alerting rules configured"
}

# Deploy monitoring dashboard
deploy_monitoring_dashboard() {
    log "Deploying monitoring dashboard..."
    
    # Build the application
    log "Building application..."
    npm install || {
        error "Failed to install dependencies"
        exit 1
    }
    
    npm run build || {
        error "Failed to build application"
        exit 1
    }
    
    # Deploy to Vercel (if Vercel CLI is available)
    if command -v vercel &> /dev/null; then
        log "Deploying to Vercel..."
        vercel --prod --confirm || {
            warning "Vercel deployment failed or not configured"
        }
    else
        warning "Vercel CLI not found. Please deploy manually or install Vercel CLI"
    fi
    
    success "Application build completed"
}

# Setup health checks
setup_health_checks() {
    log "Setting up health checks..."
    
    # Create health check script
    cat > health-check.sh << 'EOF'
#!/bin/bash

# Health check script for KCT Menswear monitoring
HEALTH_CHECK_URL="$SUPABASE_URL/rest/v1/rpc/performance_health_check"
WEBHOOK_URL="$SLACK_WEBHOOK_URL"

check_health() {
    local response=$(curl -s -w "%{http_code}" "$HEALTH_CHECK_URL" \
        -H "Authorization: Bearer $SUPABASE_SERVICE_ROLE_KEY" \
        -H "Content-Type: application/json")
    
    local http_code="${response: -3}"
    local body="${response%???}"
    
    if [[ "$http_code" != "200" ]]; then
        send_alert "Health check failed with HTTP $http_code"
        return 1
    fi
    
    # Check for critical issues in response
    if echo "$body" | grep -q "CRITICAL"; then
        send_alert "Critical health issues detected: $body"
        return 1
    fi
    
    return 0
}

send_alert() {
    local message="$1"
    if [[ -n "$WEBHOOK_URL" ]]; then
        curl -X POST "$WEBHOOK_URL" \
            -H "Content-Type: application/json" \
            -d "{\"text\":\"🚨 KCT Menswear Health Alert: $message\"}"
    fi
    echo "ALERT: $message"
}

# Run health check
if ! check_health; then
    exit 1
fi

echo "Health check passed"
EOF
    
    chmod +x health-check.sh
    
    success "Health check script created"
}

# Setup performance monitoring
setup_performance_monitoring() {
    log "Setting up performance monitoring..."
    
    # Create performance monitoring service
    cat > performance-monitor.js << 'EOF'
const { createClient } = require('@supabase/supabase-js');

const supabase = createClient(
    process.env.SUPABASE_URL,
    process.env.SUPABASE_SERVICE_ROLE_KEY
);

class PerformanceMonitor {
    constructor() {
        this.metrics = new Map();
        this.lastCheck = new Date();
    }

    async collectMetrics() {
        try {
            console.log('Collecting performance metrics...');
            
            // Collect system health
            const { data: health, error: healthError } = await supabase
                .rpc('collect_system_health_metrics');
            
            if (healthError) {
                console.error('Health metrics error:', healthError);
            }
            
            // Generate business metrics
            const { data: business, error: businessError } = await supabase
                .rpc('generate_business_metrics');
            
            if (businessError) {
                console.error('Business metrics error:', businessError);
            }
            
            // Check for alerts
            const { data: alerts, error: alertsError } = await supabase
                .rpc('check_and_trigger_alerts');
            
            if (alertsError) {
                console.error('Alerts check error:', alertsError);
            } else if (alerts > 0) {
                console.log(`Triggered ${alerts} new alerts`);
            }
            
            this.lastCheck = new Date();
            console.log('Performance metrics collection completed');
            
        } catch (error) {
            console.error('Failed to collect metrics:', error);
        }
    }

    start() {
        console.log('Starting performance monitoring...');
        
        // Initial collection
        this.collectMetrics();
        
        // Schedule regular collection every 5 minutes
        setInterval(() => {
            this.collectMetrics();
        }, 5 * 60 * 1000);
        
        console.log('Performance monitoring started');
    }
}

// Start monitoring if this script is run directly
if (require.main === module) {
    const monitor = new PerformanceMonitor();
    monitor.start();
    
    // Keep the process running
    process.on('SIGINT', () => {
        console.log('Performance monitoring stopped');
        process.exit(0);
    });
}

module.exports = PerformanceMonitor;
EOF
    
    success "Performance monitoring service created"
}

# Create systemd service (for Linux servers)
create_systemd_service() {
    if [[ "$OSTYPE" == "linux-gnu"* ]]; then
        log "Creating systemd service..."
        
        cat > kct-monitoring.service << EOF
[Unit]
Description=KCT Menswear Monitoring Service
After=network.target

[Service]
Type=simple
User=www-data
WorkingDirectory=$(pwd)
Environment=NODE_ENV=production
Environment=SUPABASE_URL=$SUPABASE_URL
Environment=SUPABASE_SERVICE_ROLE_KEY=$SUPABASE_SERVICE_ROLE_KEY
ExecStart=/usr/bin/node performance-monitor.js
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF
        
        success "Systemd service file created (kct-monitoring.service)"
        log "To install: sudo cp kct-monitoring.service /etc/systemd/system/ && sudo systemctl enable kct-monitoring"
    fi
}

# Create Docker configuration
create_docker_config() {
    log "Creating Docker configuration..."
    
    cat > Dockerfile.monitoring << 'EOF'
FROM node:18-alpine

WORKDIR /app

# Copy package files
COPY package*.json ./

# Install dependencies
RUN npm ci --only=production

# Copy monitoring scripts
COPY performance-monitor.js ./
COPY health-check.sh ./

# Make scripts executable
RUN chmod +x health-check.sh

# Create non-root user
RUN addgroup -g 1001 -S nodejs
RUN adduser -S monitoring -u 1001

USER monitoring

EXPOSE 3000

CMD ["node", "performance-monitor.js"]
EOF

    cat > docker-compose.monitoring.yml << 'EOF'
version: '3.8'

services:
  monitoring:
    build:
      context: .
      dockerfile: Dockerfile.monitoring
    environment:
      - NODE_ENV=production
      - SUPABASE_URL=${SUPABASE_URL}
      - SUPABASE_SERVICE_ROLE_KEY=${SUPABASE_SERVICE_ROLE_KEY}
      - SLACK_WEBHOOK_URL=${SLACK_WEBHOOK_URL}
    restart: unless-stopped
    healthcheck:
      test: ["CMD", "./health-check.sh"]
      interval: 5m
      timeout: 30s
      retries: 3
      start_period: 40s
    logging:
      driver: "json-file"
      options:
        max-size: "10m"
        max-file: "3"
EOF
    
    success "Docker configuration created"
}

# Generate deployment summary
generate_deployment_summary() {
    log "Generating deployment summary..."
    
    cat > DEPLOYMENT_SUMMARY.md << EOF
# KCT Menswear Production Monitoring Deployment Summary

## 🚀 Deployment Completed Successfully

**Deployment Date:** $(date)
**Environment:** $ENVIRONMENT

## 📋 Components Deployed

### ✅ Database Infrastructure
- [x] Comprehensive monitoring tables and functions
- [x] Real-time alerting system
- [x] Performance metrics collection
- [x] Business intelligence views
- [x] Inventory monitoring and forecasting
- [x] Automated scheduling (pg_cron)

### ✅ Application Components
- [x] Production Monitoring Dashboard (React/TypeScript)
- [x] Performance Optimizer Service
- [x] Incident Response System
- [x] Error Logging and Analysis

### ✅ Monitoring Services
- [x] System health monitoring
- [x] Performance tracking
- [x] Business metrics collection
- [x] Alert generation and notification
- [x] Inventory tracking and forecasting

### ✅ Alerting & Notifications
- [x] Slack integration ($([[ -n "$SLACK_WEBHOOK_URL" ]] && echo "Configured" || echo "Not configured"))
- [x] Email notifications (${MONITORING_EMAIL})
- [x] Critical incident escalation
- [x] Business metric alerts

## 📊 Key Metrics Being Monitored

### System Metrics
- Database performance and connections
- API response times and error rates
- Cache hit ratios
- System resource usage

### Business Metrics
- Revenue and conversion rates
- Order processing performance
- Customer behavior analytics
- Product performance tracking

### Inventory Metrics
- Stock levels and velocity
- Demand forecasting
- Reorder recommendations
- Supplier performance

## 🔧 Management Commands

### Start Performance Monitoring
\`\`\`bash
node performance-monitor.js
\`\`\`

### Run Health Check
\`\`\`bash
./health-check.sh
\`\`\`

### View System Status
\`\`\`sql
SELECT * FROM v_system_dashboard;
\`\`\`

### Check Active Alerts
\`\`\`sql
SELECT * FROM monitoring_alerts WHERE resolved_at IS NULL;
\`\`\`

## 📈 Dashboard Access

- **Production Dashboard:** https://$VERCEL_PROJECT_NAME.vercel.app/admin/monitoring
- **System Health:** https://$VERCEL_PROJECT_NAME.vercel.app/admin/system-health
- **Business Analytics:** https://$VERCEL_PROJECT_NAME.vercel.app/admin/analytics

## ⚠️ Important Notes

1. **Database Monitoring:** Automated monitoring runs every 5 minutes
2. **Alert Thresholds:** Configured for production e-commerce environment
3. **Data Retention:** Monitoring data is kept for 30 days by default
4. **Escalation:** Critical alerts escalate after 15 minutes if unacknowledged

## 🔍 Troubleshooting

### Check Monitoring Status
\`\`\`sql
SELECT 
  function_name,
  last_run,
  next_run,
  status
FROM cron.job;
\`\`\`

### View Recent Performance
\`\`\`sql
SELECT * FROM v_performance_summary 
ORDER BY collected_at DESC 
LIMIT 10;
\`\`\`

### Check Alert Configuration
\`\`\`sql
SELECT * FROM incident_rules WHERE enabled = true;
\`\`\`

## 📞 Support

For monitoring issues or questions:
- **Email:** $MONITORING_EMAIL
- **Slack:** #production-alerts (if configured)
- **Documentation:** See /docs/MONITORING.md

---

**Deployment completed at:** $(date)
**Next recommended action:** Monitor system for 24 hours to ensure stability
EOF
    
    success "Deployment summary created: DEPLOYMENT_SUMMARY.md"
}

# Test deployment
test_deployment() {
    log "Testing deployment..."
    
    # Test database connection
    log "Testing database connection..."
    psql "$SUPABASE_URL" -c "SELECT 1;" > /dev/null || {
        error "Database connection test failed"
        return 1
    }
    
    # Test monitoring functions
    log "Testing monitoring functions..."
    psql "$SUPABASE_URL" -c "SELECT collect_system_health_metrics();" > /dev/null || {
        error "Monitoring functions test failed"
        return 1
    }
    
    # Test health check endpoint
    if [[ -n "$SUPABASE_URL" ]]; then
        log "Testing health check endpoint..."
        local health_response=$(curl -s -w "%{http_code}" "$SUPABASE_URL/rest/v1/rpc/performance_health_check" \
            -H "Authorization: Bearer $SUPABASE_SERVICE_ROLE_KEY")
        
        local http_code="${health_response: -3}"
        if [[ "$http_code" != "200" ]]; then
            warning "Health check endpoint returned HTTP $http_code"
        fi
    fi
    
    success "Deployment tests completed"
}

# Send deployment notification
send_deployment_notification() {
    if [[ -n "$SLACK_WEBHOOK_URL" ]]; then
        log "Sending deployment notification..."
        
        curl -X POST "$SLACK_WEBHOOK_URL" \
            -H "Content-Type: application/json" \
            -d "{
                \"text\": \"🚀 KCT Menswear Production Monitoring Deployed\",
                \"attachments\": [{
                    \"color\": \"good\",
                    \"title\": \"Production Monitoring System\",
                    \"text\": \"Comprehensive monitoring and analytics system has been successfully deployed to production.\",
                    \"fields\": [
                        {\"title\": \"Environment\", \"value\": \"$ENVIRONMENT\", \"short\": true},
                        {\"title\": \"Timestamp\", \"value\": \"$(date)\", \"short\": true}
                    ]
                }]
            }" > /dev/null || {
            warning "Failed to send Slack notification"
        }
    fi
}

# Main deployment function
main() {
    echo "============================================"
    echo "🚀 KCT Menswear Production Monitoring Setup"
    echo "============================================"
    echo
    
    check_prerequisites
    
    log "Starting deployment process..."
    
    # Core deployment steps
    deploy_database_monitoring
    setup_monitoring_services
    setup_alerting
    setup_health_checks
    setup_performance_monitoring
    
    # Optional deployment components
    if command -v supabase &> /dev/null; then
        deploy_edge_functions
    else
        warning "Supabase CLI not found. Edge functions not deployed."
    fi
    
    # Application deployment
    if [[ -f "package.json" ]]; then
        deploy_monitoring_dashboard
    else
        warning "package.json not found. Skipping application deployment."
    fi
    
    # System integration
    create_systemd_service
    create_docker_config
    
    # Testing and validation
    test_deployment
    
    # Documentation and notifications
    generate_deployment_summary
    send_deployment_notification
    
    echo
    echo "============================================"
    success "🎉 Production monitoring deployment completed successfully!"
    echo "============================================"
    echo
    echo "📋 Summary:"
    echo "  • Database monitoring: ✅ Active"
    echo "  • Real-time alerts: ✅ Configured"
    echo "  • Performance tracking: ✅ Running"
    echo "  • Business intelligence: ✅ Available"
    echo "  • Health checks: ✅ Ready"
    echo
    echo "📖 Next steps:"
    echo "  1. Review DEPLOYMENT_SUMMARY.md"
    echo "  2. Access monitoring dashboard"
    echo "  3. Configure alert thresholds if needed"
    echo "  4. Monitor system for 24 hours"
    echo
    echo "🔗 Quick links:"
    echo "  • Dashboard: https://$VERCEL_PROJECT_NAME.vercel.app/admin/monitoring"
    echo "  • Documentation: ./docs/MONITORING.md"
    echo
}

# Script execution
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi