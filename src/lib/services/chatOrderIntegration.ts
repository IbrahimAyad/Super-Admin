import { supabase } from '@/lib/supabase';

/**
 * Chat Order Integration Service
 * Syncs chat_orders with the main orders table for unified order management
 */

interface ChatOrder {
  id: string;
  order_number: string;
  checkout_session_id: string;
  customer_email: string;
  items: any[];
  total_amount: number;
  status: string;
  payment_status: string;
  shipping_address: any;
  created_at: string;
}

interface MainOrder {
  order_number: string;
  customer_email: string;
  status: string;
  order_type: string;
  subtotal: number;
  total_amount: number;
  payment_status: string;
  payment_method: string;
  shipping_address_line_1?: string;
  shipping_city?: string;
  shipping_state?: string;
  shipping_postal_code?: string;
  shipping_country?: string;
  source?: string;
  metadata?: any;
}

export class ChatOrderIntegrationService {
  /**
   * Syncs a chat order to the main orders table
   */
  async syncChatOrderToMain(chatOrderId: string): Promise<void> {
    try {
      // Fetch the chat order
      const { data: chatOrder, error: fetchError } = await supabase
        .from('chat_orders')
        .select('*')
        .eq('id', chatOrderId)
        .single();

      if (fetchError) throw fetchError;
      if (!chatOrder) throw new Error('Chat order not found');

      // Check if order already exists in main table
      const { data: existingOrder } = await supabase
        .from('orders')
        .select('id')
        .eq('order_number', chatOrder.order_number)
        .single();

      if (existingOrder) {
        console.log('Order already synced:', chatOrder.order_number);
        return;
      }

      // Transform chat order to main order format
      const mainOrder = this.transformChatOrderToMain(chatOrder);

      // Insert into main orders table
      const { error: insertError } = await supabase
        .from('orders')
        .insert(mainOrder);

      if (insertError) throw insertError;

      // Create order items
      if (chatOrder.items && Array.isArray(chatOrder.items)) {
        const orderItems = chatOrder.items.map((item: any) => ({
          order_id: chatOrder.order_number,
          product_sku: item.product?.sku || item.sku,
          product_name: item.product?.name || item.description,
          size: item.size,
          quantity: item.quantity || 1,
          unit_price: item.product?.base_price || item.amount_total,
          line_total: (item.product?.base_price || item.amount_total) * (item.quantity || 1),
          item_status: 'confirmed'
        }));

        const { error: itemsError } = await supabase
          .from('order_items')
          .insert(orderItems);

        if (itemsError) {
          console.error('Error creating order items:', itemsError);
        }
      }

      console.log('Successfully synced chat order to main system:', chatOrder.order_number);
    } catch (error) {
      console.error('Error syncing chat order:', error);
      throw error;
    }
  }

  /**
   * Transforms a chat order to main order format
   */
  private transformChatOrderToMain(chatOrder: ChatOrder): MainOrder {
    const shippingAddress = chatOrder.shipping_address || {};
    
    return {
      order_number: chatOrder.order_number,
      customer_email: chatOrder.customer_email,
      status: this.mapChatStatusToMainStatus(chatOrder.status),
      order_type: 'standard', // Chat orders are standard by default
      subtotal: chatOrder.total_amount, // Will be in cents
      total_amount: chatOrder.total_amount,
      payment_status: chatOrder.payment_status as any,
      payment_method: 'stripe', // All chat orders use Stripe
      shipping_address_line_1: shippingAddress.line1,
      shipping_city: shippingAddress.city,
      shipping_state: shippingAddress.state,
      shipping_postal_code: shippingAddress.postal_code,
      shipping_country: shippingAddress.country || 'US',
      source: 'chat_commerce',
      metadata: {
        checkout_session_id: chatOrder.checkout_session_id,
        chat_order_id: chatOrder.id,
        synced_at: new Date().toISOString()
      }
    };
  }

  /**
   * Maps chat order status to main order status
   */
  private mapChatStatusToMainStatus(chatStatus: string): string {
    const statusMap: Record<string, string> = {
      'pending': 'pending',
      'processing': 'processing',
      'shipped': 'shipped',
      'delivered': 'delivered',
      'cancelled': 'cancelled',
      'refunded': 'refunded'
    };

    return statusMap[chatStatus] || 'pending';
  }

  /**
   * Syncs all unsynced chat orders
   */
  async syncAllPendingOrders(): Promise<void> {
    try {
      // Get all chat orders that haven't been synced
      const { data: chatOrders, error } = await supabase
        .from('chat_orders')
        .select('*')
        .eq('payment_status', 'paid')
        .is('metadata->synced_to_main', null);

      if (error) throw error;

      if (!chatOrders || chatOrders.length === 0) {
        console.log('No pending orders to sync');
        return;
      }

      console.log(`Found ${chatOrders.length} orders to sync`);

      // Sync each order
      for (const chatOrder of chatOrders) {
        try {
          await this.syncChatOrderToMain(chatOrder.id);
          
          // Mark as synced
          await supabase
            .from('chat_orders')
            .update({
              metadata: {
                ...chatOrder.metadata,
                synced_to_main: true,
                synced_at: new Date().toISOString()
              }
            })
            .eq('id', chatOrder.id);
        } catch (error) {
          console.error(`Failed to sync order ${chatOrder.order_number}:`, error);
        }
      }
    } catch (error) {
      console.error('Error syncing pending orders:', error);
      throw error;
    }
  }

  /**
   * Sets up real-time sync for new chat orders
   */
  setupRealtimeSync(): void {
    const channel = supabase
      .channel('chat_orders_sync')
      .on(
        'postgres_changes',
        {
          event: 'INSERT',
          schema: 'public',
          table: 'chat_orders',
          filter: 'payment_status=eq.paid'
        },
        async (payload) => {
          console.log('New chat order detected:', payload.new);
          try {
            await this.syncChatOrderToMain(payload.new.id);
          } catch (error) {
            console.error('Real-time sync failed:', error);
          }
        }
      )
      .subscribe();

    console.log('Real-time chat order sync enabled');
  }

  /**
   * Updates order status in both tables
   */
  async updateOrderStatus(orderNumber: string, newStatus: string): Promise<void> {
    try {
      // Update main orders table
      const { error: mainError } = await supabase
        .from('orders')
        .update({ status: newStatus })
        .eq('order_number', orderNumber);

      if (mainError) throw mainError;

      // Update chat_orders table
      const { error: chatError } = await supabase
        .from('chat_orders')
        .update({ status: newStatus })
        .eq('order_number', orderNumber);

      if (chatError) {
        console.error('Error updating chat order status:', chatError);
      }

      console.log(`Order ${orderNumber} status updated to ${newStatus}`);
    } catch (error) {
      console.error('Error updating order status:', error);
      throw error;
    }
  }

  /**
   * Gets unified order view (combines data from both tables)
   */
  async getUnifiedOrder(orderNumber: string): Promise<any> {
    try {
      // Get main order
      const { data: mainOrder } = await supabase
        .from('orders')
        .select('*')
        .eq('order_number', orderNumber)
        .single();

      // Get chat order if exists
      const { data: chatOrder } = await supabase
        .from('chat_orders')
        .select('*')
        .eq('order_number', orderNumber)
        .single();

      return {
        ...mainOrder,
        chat_details: chatOrder,
        source: chatOrder ? 'chat_commerce' : 'standard',
        has_chat_history: !!chatOrder
      };
    } catch (error) {
      console.error('Error getting unified order:', error);
      throw error;
    }
  }
}

// Export singleton instance
export const chatOrderIntegration = new ChatOrderIntegrationService();