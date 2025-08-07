import { useState } from 'react';
import { Button } from '@/components/ui/button';
import { createCheckout, type CartItem } from '@/lib/services';
import { useToast } from '@/hooks/use-toast';

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
  const { toast } = useToast();

  const handleCheckout = async () => {
    if (items.length === 0) {
      toast({
        title: "Cart Empty",
        description: "Please add items to your cart before checkout.",
        variant: "destructive",
      });
      return;
    }

    try {
      setLoading(true);
      
      const result = await createCheckout(items, {
        customer_email: customerEmail,
        success_url: `${window.location.origin}/order-success?session_id={CHECKOUT_SESSION_ID}`,
        cancel_url: `${window.location.origin}/cart`,
      });

      if (!result.success) {
        throw new Error(result.error || 'Failed to create checkout');
      }

      // Open Stripe checkout in a new tab
      if (result.data.url) {
        window.open(result.data.url, '_blank');
      }
    } catch (error: any) {
      console.error('Checkout error:', error);
      toast({
        title: "Checkout Error",
        description: error.message || "Failed to create checkout session. Please try again.",
        variant: "destructive",
      });
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