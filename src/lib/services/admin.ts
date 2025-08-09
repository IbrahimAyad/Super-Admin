/**
 * ADMIN SERVICE
 * Handles all admin operations using the service role client
 * This bypasses RLS issues and provides full database access for admin operations
 * Last updated: 2025-08-09
 */

import { getAdminSupabaseClient, getSupabaseClient } from '../supabase-client';

/**
 * Admin Database Operations
 * These functions use the admin client (service role key) to bypass RLS
 */

/**
 * Get all products - admin view
 */
export async function getAdminProducts(filters?: {
  search?: string;
  category?: string;
  status?: string;
  limit?: number;
  offset?: number;
}) {
  try {
    const adminClient = getAdminSupabaseClient();
    
    let query = adminClient
      .from('products')
      .select('*');

    // Apply filters
    if (filters?.search) {
      query = query.or(`name.ilike.%${filters.search}%,description.ilike.%${filters.search}%`);
    }
    
    if (filters?.category) {
      query = query.eq('category', filters.category);
    }
    
    if (filters?.status) {
      query = query.eq('status', filters.status);
    }

    // Pagination
    if (filters?.limit) {
      query = query.limit(filters.limit);
    }
    
    if (filters?.offset) {
      query = query.range(filters.offset, (filters.offset || 0) + (filters.limit || 50) - 1);
    }

    query = query.order('created_at', { ascending: false });

    const { data, error, count } = await query;

    if (error) throw error;

    return {
      success: true,
      data,
      count,
      error: null
    };
  } catch (error) {
    console.error('getAdminProducts error:', error);
    return {
      success: false,
      data: null,
      count: 0,
      error: error instanceof Error ? error.message : 'Unknown error'
    };
  }
}

/**
 * Create product - admin operation
 */
export async function createProduct(productData: any) {
  try {
    const adminClient = getAdminSupabaseClient();
    
    const { data, error } = await adminClient
      .from('products')
      .insert(productData)
      .select()
      .single();

    if (error) throw error;

    return {
      success: true,
      data,
      error: null
    };
  } catch (error) {
    console.error('createProduct error:', error);
    return {
      success: false,
      data: null,
      error: error instanceof Error ? error.message : 'Unknown error'
    };
  }
}

/**
 * Update product - admin operation
 */
export async function updateProduct(productId: string, updates: any) {
  try {
    const adminClient = getAdminSupabaseClient();
    
    const { data, error } = await adminClient
      .from('products')
      .update(updates)
      .eq('id', productId)
      .select()
      .single();

    if (error) throw error;

    return {
      success: true,
      data,
      error: null
    };
  } catch (error) {
    console.error('updateProduct error:', error);
    return {
      success: false,
      data: null,
      error: error instanceof Error ? error.message : 'Unknown error'
    };
  }
}

/**
 * Delete product - admin operation
 */
export async function deleteProduct(productId: string) {
  try {
    const adminClient = getAdminSupabaseClient();
    
    const { error } = await adminClient
      .from('products')
      .delete()
      .eq('id', productId);

    if (error) throw error;

    return {
      success: true,
      error: null
    };
  } catch (error) {
    console.error('deleteProduct error:', error);
    return {
      success: false,
      error: error instanceof Error ? error.message : 'Unknown error'
    };
  }
}

/**
 * Get all customers - admin view
 */
export async function getAdminCustomers(filters?: {
  search?: string;
  limit?: number;
  offset?: number;
}) {
  try {
    const adminClient = getAdminSupabaseClient();
    
    let query = adminClient
      .from('customers')
      .select('*');

    if (filters?.search) {
      query = query.or(`email.ilike.%${filters.search}%,first_name.ilike.%${filters.search}%,last_name.ilike.%${filters.search}%`);
    }

    if (filters?.limit) {
      query = query.limit(filters.limit);
    }
    
    if (filters?.offset) {
      query = query.range(filters.offset, (filters.offset || 0) + (filters.limit || 50) - 1);
    }

    query = query.order('created_at', { ascending: false });

    const { data, error, count } = await query;

    if (error) throw error;

    return {
      success: true,
      data,
      count,
      error: null
    };
  } catch (error) {
    console.error('getAdminCustomers error:', error);
    return {
      success: false,
      data: null,
      count: 0,
      error: error instanceof Error ? error.message : 'Unknown error'
    };
  }
}

/**
 * Get all orders - admin view
 */
export async function getAdminOrders(filters?: {
  status?: string;
  customer_email?: string;
  limit?: number;
  offset?: number;
}) {
  try {
    const adminClient = getAdminSupabaseClient();
    
    let query = adminClient
      .from('orders')
      .select(`
        *,
        customer:customers(
          email,
          first_name,
          last_name
        )
      `);

    if (filters?.status) {
      query = query.eq('status', filters.status);
    }
    
    if (filters?.customer_email) {
      query = query.eq('customer_email', filters.customer_email);
    }

    if (filters?.limit) {
      query = query.limit(filters.limit);
    }
    
    if (filters?.offset) {
      query = query.range(filters.offset, (filters.offset || 0) + (filters.limit || 50) - 1);
    }

    query = query.order('created_at', { ascending: false });

    const { data, error, count } = await query;

    if (error) throw error;

    return {
      success: true,
      data,
      count,
      error: null
    };
  } catch (error) {
    console.error('getAdminOrders error:', error);
    return {
      success: false,
      data: null,
      count: 0,
      error: error instanceof Error ? error.message : 'Unknown error'
    };
  }
}

/**
 * Update order status - admin operation
 */
export async function updateOrderStatus(orderId: string, status: string, notes?: string) {
  try {
    const adminClient = getAdminSupabaseClient();
    
    const updates: any = { 
      status,
      updated_at: new Date().toISOString()
    };
    
    if (notes) {
      updates.admin_notes = notes;
    }

    const { data, error } = await adminClient
      .from('orders')
      .update(updates)
      .eq('id', orderId)
      .select()
      .single();

    if (error) throw error;

    return {
      success: true,
      data,
      error: null
    };
  } catch (error) {
    console.error('updateOrderStatus error:', error);
    return {
      success: false,
      data: null,
      error: error instanceof Error ? error.message : 'Unknown error'
    };
  }
}

/**
 * Get Stripe sync summary - admin view
 */
export async function getStripeSyncSummary() {
  try {
    const adminClient = getAdminSupabaseClient();
    
    const { data, error } = await adminClient
      .from('stripe_sync_summary')
      .select('*')
      .order('sync_date', { ascending: false })
      .limit(10);

    if (error) throw error;

    return {
      success: true,
      data,
      error: null
    };
  } catch (error) {
    console.error('getStripeSyncSummary error:', error);
    return {
      success: false,
      data: null,
      error: error instanceof Error ? error.message : 'Unknown error'
    };
  }
}

/**
 * Get admin dashboard stats
 */
export async function getAdminDashboardStats() {
  try {
    const adminClient = getAdminSupabaseClient();
    
    // Get multiple stats in parallel
    const [productsResult, customersResult, ordersResult, recentOrdersResult] = await Promise.all([
      adminClient.from('products').select('id', { count: 'exact', head: true }),
      adminClient.from('customers').select('id', { count: 'exact', head: true }),
      adminClient.from('orders').select('id', { count: 'exact', head: true }),
      adminClient
        .from('orders')
        .select('*')
        .order('created_at', { ascending: false })
        .limit(5)
    ]);

    const stats = {
      totalProducts: productsResult.count || 0,
      totalCustomers: customersResult.count || 0,
      totalOrders: ordersResult.count || 0,
      recentOrders: recentOrdersResult.data || []
    };

    return {
      success: true,
      data: stats,
      error: null
    };
  } catch (error) {
    console.error('getAdminDashboardStats error:', error);
    return {
      success: false,
      data: null,
      error: error instanceof Error ? error.message : 'Unknown error'
    };
  }
}

/**
 * Test admin database access
 */
export async function testAdminAccess() {
  try {
    const adminClient = getAdminSupabaseClient();
    
    // Test basic table access
    const tests = {
      products: false,
      customers: false,
      orders: false,
      admin_users: false,
      stripe_sync_summary: false
    };
    
    // Test products table
    try {
      const { data, error } = await adminClient.from('products').select('id').limit(1);
      tests.products = !error;
    } catch (e) {
      tests.products = false;
    }
    
    // Test customers table
    try {
      const { data, error } = await adminClient.from('customers').select('id').limit(1);
      tests.customers = !error;
    } catch (e) {
      tests.customers = false;
    }
    
    // Test orders table
    try {
      const { data, error } = await adminClient.from('orders').select('id').limit(1);
      tests.orders = !error;
    } catch (e) {
      tests.orders = false;
    }
    
    // Test admin_users table
    try {
      const { data, error } = await adminClient.from('admin_users').select('id').limit(1);
      tests.admin_users = !error;
    } catch (e) {
      tests.admin_users = false;
    }
    
    // Test stripe_sync_summary table
    try {
      const { data, error } = await adminClient.from('stripe_sync_summary').select('id').limit(1);
      tests.stripe_sync_summary = !error;
    } catch (e) {
      tests.stripe_sync_summary = false;
    }

    return {
      success: true,
      data: {
        message: 'Admin access test completed',
        tableAccess: tests,
        allTablesAccessible: Object.values(tests).every(test => test === true)
      },
      error: null
    };
  } catch (error) {
    console.error('testAdminAccess error:', error);
    return {
      success: false,
      data: null,
      error: error instanceof Error ? error.message : 'Unknown error'
    };
  }
}