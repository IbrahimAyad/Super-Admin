# Fixed SQL Migrations - Ready to Run

## ⚠️ IMPORTANT: Use the FIXED versions

The original migration files have PostgreSQL syntax errors with inline INDEX declarations.
Use these fixed versions instead:

## 📁 Fixed Migration Files:

1. **053_order_processing_tables_FIXED.sql** ✅ CREATED
2. **054_email_system_FIXED.sql** - See below
3. **055_inventory_automation_FIXED.sql** - See below  
4. **056_daily_reports_FIXED.sql** - See below

## 🔧 Quick Fix Instructions:

### For 054_email_system.sql:
Replace lines 19-21:
```sql
-- OLD (WRONG):
  INDEX idx_email_logs_status (status),
  INDEX idx_email_logs_created (created_at DESC),
  INDEX idx_email_logs_template (template)

-- NEW (CORRECT - add after CREATE TABLE):
);

CREATE INDEX IF NOT EXISTS idx_email_logs_status ON email_logs(status);
CREATE INDEX IF NOT EXISTS idx_email_logs_created ON email_logs(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_email_logs_template ON email_logs(template);
```

Replace lines 51-55:
```sql
-- OLD (WRONG):
  INDEX idx_email_queue_status (status),
  INDEX idx_email_queue_scheduled (scheduled_for),
  INDEX idx_email_queue_attempts (attempts)

-- NEW (CORRECT - add after CREATE TABLE):
);

CREATE INDEX IF NOT EXISTS idx_email_queue_status ON email_queue(status);
CREATE INDEX IF NOT EXISTS idx_email_queue_scheduled ON email_queue(scheduled_for);
CREATE INDEX IF NOT EXISTS idx_email_queue_attempts ON email_queue(attempts);
```

### For 055_inventory_automation.sql:
Replace lines 17-21:
```sql
-- OLD (WRONG):
  INDEX idx_inventory_movements_variant (variant_id),
  INDEX idx_inventory_movements_type (movement_type),
  INDEX idx_inventory_movements_created (created_at DESC),
  INDEX idx_inventory_movements_reference (reference_type, reference_id)

-- NEW (CORRECT - add after CREATE TABLE):
);

CREATE INDEX IF NOT EXISTS idx_inventory_movements_variant ON inventory_movements(variant_id);
CREATE INDEX IF NOT EXISTS idx_inventory_movements_type ON inventory_movements(movement_type);
CREATE INDEX IF NOT EXISTS idx_inventory_movements_created ON inventory_movements(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_inventory_movements_reference ON inventory_movements(reference_type, reference_id);
```

Replace lines 37-40:
```sql
-- OLD (WRONG):
  INDEX idx_low_stock_alerts_variant (variant_id),
  INDEX idx_low_stock_alerts_resolved (resolved),
  INDEX idx_low_stock_alerts_created (created_at DESC)

-- NEW (CORRECT - add after CREATE TABLE):
);

CREATE INDEX IF NOT EXISTS idx_low_stock_alerts_variant ON low_stock_alerts(variant_id);
CREATE INDEX IF NOT EXISTS idx_low_stock_alerts_resolved ON low_stock_alerts(resolved);
CREATE INDEX IF NOT EXISTS idx_low_stock_alerts_created ON low_stock_alerts(created_at DESC);
```

### For 056_daily_reports.sql:
Replace lines 14-16:
```sql
-- OLD (WRONG):
  INDEX idx_daily_reports_date (report_date DESC),
  INDEX idx_daily_reports_created (created_at DESC)

-- NEW (CORRECT - add after CREATE TABLE):
);

CREATE INDEX IF NOT EXISTS idx_daily_reports_date ON daily_reports(report_date DESC);
CREATE INDEX IF NOT EXISTS idx_daily_reports_created ON daily_reports(created_at DESC);
```

## ✅ Corrected Order of Execution:

1. Run **053_order_processing_tables_FIXED.sql** (already created)
2. Fix and run **054_email_system.sql** (with changes above)
3. Fix and run **055_inventory_automation.sql** (with changes above)
4. Fix and run **056_daily_reports.sql** (with changes above)

## 🎯 Quick Copy-Paste Fix:

If you want to quickly fix in SQL Editor, just remove the INDEX lines from inside CREATE TABLE and add them as separate CREATE INDEX statements after each table.

The pattern is:
```sql
-- Remove this from inside CREATE TABLE:
INDEX index_name (column_name)

-- Add this after CREATE TABLE:
CREATE INDEX IF NOT EXISTS index_name ON table_name(column_name);
```