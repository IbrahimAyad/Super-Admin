# Deploy Daily Reports System

## 1. Deploy the Database Migration

Go to the Supabase SQL Editor and run the migration from:
`supabase/migrations/056_daily_reports.sql`

This creates the `daily_reports` table to store report history.

## 2. Deploy the Daily Report Edge Function

### Option A: Via Supabase Dashboard
1. Go to Edge Functions in your Supabase dashboard
2. Click "New Function"
3. Name it: `daily-report`
4. Copy the code from `supabase/functions/daily-report/index.ts`
5. Deploy

### Option B: Via CLI (if linked)
```bash
supabase functions deploy daily-report --no-verify-jwt
```

## 3. Set Up Scheduled Execution

To run the daily report automatically at 8 AM every day:

### Using Supabase Cron Jobs:
1. Go to Database → Extensions
2. Enable `pg_cron` if not already enabled
3. Go to SQL Editor and run:

```sql
-- Schedule daily report at 8 AM UTC
SELECT cron.schedule(
  'daily-report-generation',
  '0 8 * * *', -- 8 AM UTC daily
  $$
  SELECT net.http_post(
    url := 'https://gvcswimqaxvylgxbklbz.supabase.co/functions/v1/daily-report',
    headers := jsonb_build_object(
      'Authorization', 'Bearer ' || current_setting('app.settings.service_key'),
      'Content-Type', 'application/json'
    ),
    body := jsonb_build_object('trigger', 'scheduled')
  );
  $$
);
```

### Or use external schedulers like:
- Vercel Cron
- GitHub Actions
- Uptime monitoring services

## 4. Test the Daily Report

Run this curl command to test (replace YOUR_ANON_KEY):

```bash
curl -X POST https://gvcswimqaxvylgxbklbz.supabase.co/functions/v1/daily-report \
  -H "Authorization: Bearer YOUR_ANON_KEY" \
  -H "Content-Type: application/json" \
  -d '{}'
```

## 5. Configure Email Recipients

Update the email recipients in the Edge Function:
- Line 451: Change `to: ["admin@kctmenswear.com"]` to your email addresses

## 6. Verify RESEND_API_KEY

Make sure `RESEND_API_KEY` is set in your Supabase Vault secrets.

## Features of the Daily Report:

1. **Comprehensive Metrics:**
   - Today's orders and revenue
   - Comparison with yesterday (% change)
   - New vs returning customers
   - Order status breakdown
   - Top selling products

2. **Alerts Included:**
   - Low stock products
   - Pending refunds
   - Orders awaiting processing

3. **Visual Format:**
   - HTML email with styled cards
   - Color-coded metrics (green for positive, red for negative)
   - Hourly performance breakdown

4. **Data Storage:**
   - Reports are saved in the database
   - Can view historical reports
   - Track email delivery status

## Next Steps:

1. Deploy the migration and Edge Function
2. Test with a manual trigger
3. Set up automated scheduling
4. Configure email recipients
5. Monitor daily reports

The system is now complete and ready for production use!