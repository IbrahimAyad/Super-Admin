import { useState } from 'react';
import { Button } from '@/components/ui/button';
import { createCheckout, type CartItem } from '@/lib/services';
import { useAuth } from '@/contexts/AuthContext';
import { toast } from 'sonner';

interface CheckoutButtonProps {
  items: CartItem[];
  customerEmail?: string;
  className?: string;
  children?: React.ReactNode;
}

export function CheckoutButton({ 
  items, 
  customerEmail, 
  className,
  children = "Checkout"
}: CheckoutButtonProps) {
  const [loading, setLoading] = useState(false);
  const { user } = useAuth();

  const handleCheckout = async () => {
    if (items.length === 0) {
      toast.error("Please add items to your cart before checkout.");
      return;
    }

    try {
      setLoading(true);
      
      // Use the secure checkout service which calls create-checkout-secure Edge Function
      const result = await createCheckout(items, {
        customer_email: customerEmail || user?.email,
        success_url: `${window.location.origin}/order-success?session_id={CHECKOUT_SESSION_ID}`,
        cancel_url: `${window.location.origin}/cart`,
      });

      if (!result.success) {
        throw new Error(result.error || 'Failed to create checkout');
      }

      // Redirect to Stripe checkout (same window for better UX)
      if (result.data.url) {
        window.location.href = result.data.url;
      }
    } catch (error: any) {
      console.error('Checkout error:', error);
      toast.error(error.message || "Failed to create checkout session. Please try again.");
    } finally {
      setLoading(false);
    }
  };

  return (
    <Button
      onClick={handleCheckout}
      disabled={loading || items.length === 0}
      className={className}
    >
      {loading ? "Creating checkout..." : children}
    </Button>
  );
}