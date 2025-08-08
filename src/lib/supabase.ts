import { createClient } from '@supabase/supabase-js'

// Hard-code temporarily to verify this is the issue
const supabaseUrl = 'https://gvcswimqaxvylgxbklbz.supabase.co'
const supabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imd2Y3N3aW1xYXh2eWxneGJrbGJ6Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTM3NjA1MzAsImV4cCI6MjA2OTMzNjUzMH0.UZdiGcJXUV5VYetjWXV26inmbj2yXdiT03Z6t_5Lg24'

// Fallback to env vars if available
const url = process.env.NEXT_PUBLIC_SUPABASE_URL || supabaseUrl
const key = process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY || supabaseAnonKey

if (!url || !key) {
  console.error('Supabase config missing, using hardcoded values')
}

export const supabase = createClient(url, key)