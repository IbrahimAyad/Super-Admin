import React, { useEffect, useState } from 'react';
import { useSearchParams, useNavigate } from 'react-router-dom';
import { supabase } from '@/lib/supabase';
import { Card } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { CheckCircle, Package, Home, MessageCircle } from 'lucide-react';
import { toast } from '@/components/ui/use-toast';
import { chatOrderIntegration } from '@/lib/services/chatOrderIntegration';

interface OrderDetails {
  orderNumber: string;
  email: string;
  items: any[];
  total: number;
  estimatedDelivery: string;
}

export default function CheckoutSuccess() {
  const [searchParams] = useSearchParams();
  const navigate = useNavigate();
  const [loading, setLoading] = useState(true);
  const [orderDetails, setOrderDetails] = useState<OrderDetails | null>(null);
  const sessionId = searchParams.get('session_id');

  useEffect(() => {
    if (sessionId) {
      verifyAndCreateOrder();
    } else {
      setLoading(false);
    }
  }, [sessionId]);

  const verifyAndCreateOrder = async () => {
    try {
      // Verify the checkout session with Stripe
      const { data, error } = await supabase.functions.invoke('verify-checkout-session', {
        body: { sessionId }
      });

      if (error) throw error;

      if (data.status === 'complete') {
        // Create order in database
        const { data: order, error: orderError } = await supabase
          .from('chat_orders')
          .insert({
            checkout_session_id: sessionId,
            customer_email: data.customer_email,
            items: data.line_items,
            subtotal: data.amount_subtotal,
            total_amount: data.amount_total,
            payment_status: 'paid',
            stripe_payment_intent_id: data.payment_intent,
            shipping_address: data.shipping_details?.address || data.customer_details?.address,
            billing_address: data.customer_details?.address,
            metadata: {
              source: 'chat_checkout',
              session_id: sessionId
            }
          })
          .select()
          .single();

        if (orderError) {
          console.error('Error creating order:', orderError);
        } else {
          setOrderDetails({
            orderNumber: order.order_number,
            email: order.customer_email,
            items: order.items,
            total: order.total_amount / 100,
            estimatedDelivery: '5-7 business days'
          });

          // Clear cart from localStorage
          localStorage.removeItem('checkout_cart');
          localStorage.removeItem('checkout_session');
          
          // Send confirmation notification
          toast({
            title: 'Order Confirmed!',
            description: `Your order ${order.order_number} has been successfully placed.`
          });

          // Sync with main order system
          try {
            await chatOrderIntegration.syncChatOrderToMain(order.id);
            console.log('Order synced with main system');
          } catch (syncError) {
            console.error('Failed to sync with main system:', syncError);
            // Don't show error to user - this is a background process
          }
        }
      }
    } catch (error) {
      console.error('Error verifying order:', error);
      toast({
        title: 'Verification Error',
        description: 'We received your payment but had an issue creating your order. Please contact support.',
        variant: 'destructive'
      });
    } finally {
      setLoading(false);
    }
  };

  const returnToChat = () => {
    // Trigger event to open chat with order confirmation
    window.dispatchEvent(new CustomEvent('open-chat', {
      detail: {
        message: `Order ${orderDetails?.orderNumber} confirmed!`,
        type: 'order_confirmation'
      }
    }));
    navigate('/');
  };

  if (loading) {
    return (
      <div className="min-h-screen flex items-center justify-center">
        <div className="text-center">
          <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-black mx-auto"></div>
          <p className="mt-4">Confirming your order...</p>
        </div>
      </div>
    );
  }

  if (!orderDetails && !loading) {
    return (
      <div className="min-h-screen flex items-center justify-center p-4">
        <Card className="max-w-md w-full p-8 text-center">
          <div className="text-red-500 mb-4">
            <CheckCircle className="h-16 w-16 mx-auto" />
          </div>
          <h1 className="text-2xl font-bold mb-4">Session Not Found</h1>
          <p className="text-muted-foreground mb-6">
            We couldn't find your checkout session. If you completed a purchase, 
            please check your email for confirmation.
          </p>
          <Button onClick={() => navigate('/')} className="w-full">
            Return Home
          </Button>
        </Card>
      </div>
    );
  }

  return (
    <div className="min-h-screen bg-gray-50 py-12 px-4">
      <div className="max-w-3xl mx-auto">
        {/* Success Card */}
        <Card className="p-8 mb-6">
          <div className="text-center mb-8">
            <div className="inline-flex items-center justify-center w-20 h-20 bg-green-100 rounded-full mb-4">
              <CheckCircle className="h-10 w-10 text-green-600" />
            </div>
            <h1 className="text-3xl font-bold mb-2">Order Confirmed!</h1>
            <p className="text-xl text-muted-foreground">
              Thank you for your purchase
            </p>
          </div>

          {/* Order Details */}
          <div className="border-t border-b py-6 mb-6">
            <div className="grid grid-cols-2 gap-4 mb-4">
              <div>
                <p className="text-sm text-muted-foreground">Order Number</p>
                <p className="font-semibold">{orderDetails?.orderNumber}</p>
              </div>
              <div>
                <p className="text-sm text-muted-foreground">Email</p>
                <p className="font-semibold">{orderDetails?.email}</p>
              </div>
            </div>
            <div className="grid grid-cols-2 gap-4">
              <div>
                <p className="text-sm text-muted-foreground">Total</p>
                <p className="font-semibold">${orderDetails?.total.toFixed(2)}</p>
              </div>
              <div>
                <p className="text-sm text-muted-foreground">Estimated Delivery</p>
                <p className="font-semibold">{orderDetails?.estimatedDelivery}</p>
              </div>
            </div>
          </div>

          {/* Order Items */}
          <div className="mb-6">
            <h3 className="font-semibold mb-3">Order Items</h3>
            {orderDetails?.items.map((item: any, index: number) => (
              <div key={index} className="flex justify-between py-2">
                <span>{item.description}</span>
                <span>${(item.amount_total / 100).toFixed(2)}</span>
              </div>
            ))}
          </div>

          {/* Next Steps */}
          <div className="bg-gray-50 rounded-lg p-6 mb-6">
            <h3 className="font-semibold mb-3">What's Next?</h3>
            <div className="space-y-3">
              <div className="flex items-start gap-3">
                <div className="mt-1">📧</div>
                <div>
                  <p className="font-medium">Confirmation Email</p>
                  <p className="text-sm text-muted-foreground">
                    We've sent order details to {orderDetails?.email}
                  </p>
                </div>
              </div>
              <div className="flex items-start gap-3">
                <div className="mt-1">📦</div>
                <div>
                  <p className="font-medium">Order Processing</p>
                  <p className="text-sm text-muted-foreground">
                    Your order is being prepared for shipment
                  </p>
                </div>
              </div>
              <div className="flex items-start gap-3">
                <div className="mt-1">🚚</div>
                <div>
                  <p className="font-medium">Tracking Information</p>
                  <p className="text-sm text-muted-foreground">
                    You'll receive tracking details once shipped
                  </p>
                </div>
              </div>
            </div>
          </div>

          {/* Action Buttons */}
          <div className="flex gap-3">
            <Button 
              onClick={() => navigate('/')}
              variant="outline"
              className="flex-1"
            >
              <Home className="mr-2 h-4 w-4" />
              Continue Shopping
            </Button>
            <Button 
              onClick={returnToChat}
              className="flex-1"
            >
              <MessageCircle className="mr-2 h-4 w-4" />
              Return to Chat
            </Button>
          </div>
        </Card>

        {/* Additional Info */}
        <Card className="p-6">
          <h3 className="font-semibold mb-3">Need Help?</h3>
          <p className="text-sm text-muted-foreground mb-4">
            Our customer service team is here to assist you with any questions about your order.
          </p>
          <div className="flex gap-4 text-sm">
            <a href="mailto:support@kctmenswear.com" className="text-blue-600 hover:underline">
              support@kctmenswear.com
            </a>
            <span className="text-muted-foreground">•</span>
            <span>1-800-KCT-SUIT</span>
          </div>
        </Card>
      </div>
    </div>
  );
}