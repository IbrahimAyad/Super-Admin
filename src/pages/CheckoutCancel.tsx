import React, { useEffect } from 'react';
import { useNavigate } from 'react-router-dom';
import { Card } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { Alert, AlertDescription } from '@/components/ui/alert';
import { XCircle, ShoppingCart, MessageCircle, Home, Info } from 'lucide-react';

export default function CheckoutCancel() {
  const navigate = useNavigate();

  useEffect(() => {
    // Restore cart from localStorage if available
    const savedCart = localStorage.getItem('checkout_cart');
    if (savedCart) {
      console.log('Cart restored from cancelled checkout');
    }
  }, []);

  const returnToChat = () => {
    // Trigger event to open chat with cart restored
    window.dispatchEvent(new CustomEvent('open-chat', {
      detail: {
        message: 'checkout_cancelled',
        type: 'restore_cart'
      }
    }));
    navigate('/');
  };

  return (
    <div className="min-h-screen bg-gray-50 py-12 px-4">
      <div className="max-w-2xl mx-auto">
        {/* Cancel Card */}
        <Card className="p-8 mb-6">
          <div className="text-center mb-8">
            <div className="inline-flex items-center justify-center w-20 h-20 bg-yellow-100 rounded-full mb-4">
              <XCircle className="h-10 w-10 text-yellow-600" />
            </div>
            <h1 className="text-3xl font-bold mb-2">Checkout Cancelled</h1>
            <p className="text-xl text-muted-foreground">
              Your order was not completed
            </p>
          </div>

          {/* Info Alert */}
          <Alert className="mb-6">
            <Info className="h-4 w-4" />
            <AlertDescription>
              Don't worry! Your cart items have been saved and you can complete your purchase anytime.
            </AlertDescription>
          </Alert>

          {/* Why customers cancel */}
          <div className="bg-gray-50 rounded-lg p-6 mb-6">
            <h3 className="font-semibold mb-3">Need Assistance?</h3>
            <p className="text-sm text-muted-foreground mb-4">
              Common reasons customers pause checkout:
            </p>
            <div className="space-y-3">
              <div className="flex items-start gap-3">
                <div className="mt-1">💳</div>
                <div>
                  <p className="font-medium">Payment Questions</p>
                  <p className="text-sm text-muted-foreground">
                    We accept all major credit cards, Apple Pay, and Google Pay
                  </p>
                </div>
              </div>
              <div className="flex items-start gap-3">
                <div className="mt-1">📏</div>
                <div>
                  <p className="font-medium">Sizing Concerns</p>
                  <p className="text-sm text-muted-foreground">
                    Our AI assistant can help you find the perfect fit
                  </p>
                </div>
              </div>
              <div className="flex items-start gap-3">
                <div className="mt-1">🚚</div>
                <div>
                  <p className="font-medium">Shipping Information</p>
                  <p className="text-sm text-muted-foreground">
                    Free shipping on orders over $200, express options available
                  </p>
                </div>
              </div>
              <div className="flex items-start gap-3">
                <div className="mt-1">🔄</div>
                <div>
                  <p className="font-medium">Return Policy</p>
                  <p className="text-sm text-muted-foreground">
                    30-day hassle-free returns on all items
                  </p>
                </div>
              </div>
            </div>
          </div>

          {/* Special Offer */}
          <div className="bg-green-50 border border-green-200 rounded-lg p-4 mb-6">
            <div className="flex items-center gap-3">
              <div className="text-2xl">🎁</div>
              <div>
                <p className="font-semibold text-green-900">Complete your order today</p>
                <p className="text-sm text-green-700">
                  Get 10% off with code COMPLETE10 - valid for 24 hours
                </p>
              </div>
            </div>
          </div>

          {/* Action Buttons */}
          <div className="flex flex-col sm:flex-row gap-3">
            <Button 
              onClick={returnToChat}
              className="flex-1"
              size="lg"
            >
              <MessageCircle className="mr-2 h-4 w-4" />
              Return to Chat & Complete Order
            </Button>
            <Button 
              onClick={() => navigate('/')}
              variant="outline"
              className="flex-1"
              size="lg"
            >
              <Home className="mr-2 h-4 w-4" />
              Continue Shopping
            </Button>
          </div>
        </Card>

        {/* Help Card */}
        <Card className="p-6">
          <h3 className="font-semibold mb-3">Need Help Completing Your Order?</h3>
          <p className="text-sm text-muted-foreground mb-4">
            Our style assistants are available to help with sizing, styling advice, or any questions.
          </p>
          <div className="flex flex-col sm:flex-row gap-4">
            <Button
              variant="outline"
              size="sm"
              onClick={() => window.location.href = 'mailto:support@kctmenswear.com'}
            >
              Email Support
            </Button>
            <Button
              variant="outline"
              size="sm"
              onClick={returnToChat}
            >
              Chat with AI Assistant
            </Button>
            <Button
              variant="outline"
              size="sm"
              onClick={() => window.location.href = 'tel:1-800-528-7848'}
            >
              Call 1-800-KCT-SUIT
            </Button>
          </div>
        </Card>
      </div>
    </div>
  );
}