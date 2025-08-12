import React, { useState, useEffect } from 'react';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { Label } from '@/components/ui/label';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Separator } from '@/components/ui/separator';
import { Badge } from '@/components/ui/badge';
import { Alert, AlertDescription } from '@/components/ui/alert';
import { useAuth } from '@/contexts/AuthContext';
import { useCart } from '@/contexts/CartContext';
import { supabase } from '@/lib/supabase-client';
import { toast } from 'sonner';
import { 
  ShoppingCart, 
  User, 
  MapPin, 
  CreditCard, 
  Shield, 
  AlertCircle, 
  CheckCircle,
  Clock 
} from 'lucide-react';

interface UserProfile {
  id: string;
  email: string;
  full_name?: string;
  phone?: string;
  saved_addresses: Array<{
    id: string;
    type: 'shipping' | 'billing';
    first_name: string;
    last_name: string;
    address_line_1: string;
    address_line_2?: string;
    city: string;
    state: string;
    postal_code: string;
    country: string;
    is_default?: boolean;
  }>;
  saved_payment_methods: Array<{
    id: string;
    type: string;
    last4: string;
    exp_month: number;
    exp_year: number;
    is_default?: boolean;
  }>;
}

interface CheckoutFormProps {
  onCheckoutComplete?: (sessionId: string) => void;
  onCheckoutError?: (error: string) => void;
}

export function SecureCheckoutForm({ 
  onCheckoutComplete, 
  onCheckoutError 
}: CheckoutFormProps) {
  const { user } = useAuth();
  const { items, getCartTotal, clearCart } = useCart();
  
  // State management
  const [loading, setLoading] = useState(false);
  const [userProfile, setUserProfile] = useState<UserProfile | null>(null);
  const [cartExpiration, setCartExpiration] = useState<Date | null>(null);
  const [validationErrors, setValidationErrors] = useState<Record<string, string>>({});
  const [paymentMethods, setPaymentMethods] = useState<string[]>(['card']);
  const [selectedAddress, setSelectedAddress] = useState<string>('');
  const [useProfileAddress, setUseProfileAddress] = useState(false);

  // Form state
  const [formData, setFormData] = useState({
    email: user?.email || '',
    phone: '',
    firstName: '',
    lastName: '',
    addressLine1: '',
    addressLine2: '',
    city: '',
    state: '',
    postalCode: '',
    country: 'US'
  });

  // Load user profile on mount
  useEffect(() => {
    if (user?.id) {
      loadUserProfile();
    }
    initializeCartExpiration();
    validatePaymentMethods();
  }, [user?.id]);

  // Auto-save form data
  useEffect(() => {
    if (user?.id) {
      const debounced = setTimeout(() => {
        saveFormDataToProfile();
      }, 1000);
      return () => clearTimeout(debounced);
    }
  }, [formData, user?.id]);

  const loadUserProfile = async () => {
    if (!user?.id) return;

    try {
      const { data, error } = await supabase
        .from('user_profiles')
        .select('*')
        .eq('id', user.id)
        .single();

      if (error && error.code !== 'PGRST116') {
        throw error;
      }

      if (data) {
        setUserProfile(data);
        
        // Pre-populate form with profile data
        if (data.full_name) {
          const [firstName, ...lastNameParts] = data.full_name.split(' ');
          setFormData(prev => ({
            ...prev,
            firstName: firstName || '',
            lastName: lastNameParts.join(' ') || '',
            email: data.email || prev.email,
            phone: data.phone || prev.phone
          }));
        }

        // Use default address if available
        const defaultAddress = data.saved_addresses?.find((addr: any) => addr.is_default);
        if (defaultAddress && !useProfileAddress) {
          setFormData(prev => ({
            ...prev,
            firstName: defaultAddress.first_name,
            lastName: defaultAddress.last_name,
            addressLine1: defaultAddress.address_line_1,
            addressLine2: defaultAddress.address_line_2 || '',
            city: defaultAddress.city,
            state: defaultAddress.state,
            postalCode: defaultAddress.postal_code,
            country: defaultAddress.country
          }));
          setUseProfileAddress(true);
        }
      }
    } catch (error) {
      console.error('Error loading user profile:', error);
    }
  };

  const saveFormDataToProfile = async () => {
    if (!user?.id || !formData.firstName) return;

    try {
      const addressData = {
        id: crypto.randomUUID(),
        type: 'shipping' as const,
        first_name: formData.firstName,
        last_name: formData.lastName,
        address_line_1: formData.addressLine1,
        address_line_2: formData.addressLine2,
        city: formData.city,
        state: formData.state,
        postal_code: formData.postalCode,
        country: formData.country,
        is_default: false
      };

      // Update profile with current form data
      const updates: any = {
        full_name: `${formData.firstName} ${formData.lastName}`.trim(),
        phone: formData.phone
      };

      // Add address to saved addresses if valid
      if (formData.addressLine1 && formData.city && formData.state) {
        const existingAddresses = userProfile?.saved_addresses || [];
        const addressExists = existingAddresses.some((addr: any) => 
          addr.address_line_1 === formData.addressLine1 &&
          addr.city === formData.city &&
          addr.postal_code === formData.postalCode
        );

        if (!addressExists) {
          updates.saved_addresses = [...existingAddresses, addressData];
        }
      }

      await supabase
        .from('user_profiles')
        .upsert({
          id: user.id,
          email: user.email!,
          ...updates
        });

    } catch (error) {
      console.error('Error saving form data:', error);
    }
  };

  const initializeCartExpiration = () => {
    // Set cart expiration to 30 minutes from now
    const expiration = new Date();
    expiration.setMinutes(expiration.getMinutes() + 30);
    setCartExpiration(expiration);
  };

  const validatePaymentMethods = () => {
    // Check if Apple Pay is available
    if ((window as any).ApplePaySession?.canMakePayments()) {
      setPaymentMethods(prev => [...prev, 'apple_pay']);
    }
    
    // Check if Google Pay is available (simplified check)
    if (typeof (window as any).google !== 'undefined') {
      setPaymentMethods(prev => [...prev, 'google_pay']);
    }
  };

  const validateForm = (): boolean => {
    const errors: Record<string, string> = {};

    // Email validation
    if (!formData.email) {
      errors.email = 'Email is required';
    } else if (!/\S+@\S+\.\S+/.test(formData.email)) {
      errors.email = 'Invalid email format';
    }

    // Name validation
    if (!formData.firstName.trim()) {
      errors.firstName = 'First name is required';
    }
    if (!formData.lastName.trim()) {
      errors.lastName = 'Last name is required';
    }

    // Address validation
    if (!formData.addressLine1.trim()) {
      errors.addressLine1 = 'Address is required';
    }
    if (!formData.city.trim()) {
      errors.city = 'City is required';
    }
    if (!formData.state.trim()) {
      errors.state = 'State is required';
    }
    if (!formData.postalCode.trim()) {
      errors.postalCode = 'Postal code is required';
    }

    // Phone validation (optional but if provided, validate format)
    if (formData.phone && !/^\+?[\d\s\-()]+$/.test(formData.phone)) {
      errors.phone = 'Invalid phone format';
    }

    setValidationErrors(errors);
    return Object.keys(errors).length === 0;
  };

  const validateCartItems = async (): Promise<boolean> => {
    if (items.length === 0) {
      toast.error('Your cart is empty');
      return false;
    }

    try {
      // Check inventory and price changes for each item
      for (const item of items) {
        if (item.variant_id) {
          // Check inventory
          const { data: availableQty, error: invError } = await supabase
            .rpc('get_available_inventory', { variant_uuid: item.variant_id });

          if (invError) {
            throw new Error('Failed to check inventory');
          }

          if (availableQty < item.quantity) {
            toast.error(`Insufficient inventory for ${item.product?.name || 'item'}`);
            return false;
          }

          // Check price hasn't changed significantly (> 5%)
          const currentPrice = item.variant?.price || item.product?.base_price || 0;
          const originalPrice = item.price || currentPrice;
          const priceChange = Math.abs(currentPrice - originalPrice) / originalPrice;

          if (priceChange > 0.05) {
            toast.error(`Price has changed for ${item.product?.name || 'item'}. Please refresh your cart.`);
            return false;
          }
        }
      }

      // Check cart expiration
      if (cartExpiration && new Date() > cartExpiration) {
        toast.error('Your cart has expired. Please refresh and try again.');
        return false;
      }

      return true;
    } catch (error) {
      console.error('Cart validation error:', error);
      toast.error('Failed to validate cart items');
      return false;
    }
  };

  const handleCheckout = async () => {
    if (!validateForm()) {
      toast.error('Please fix form errors before proceeding');
      return;
    }

    if (!(await validateCartItems())) {
      return;
    }

    setLoading(true);

    try {
      // Prepare checkout data
      const checkoutItems = items.map(item => ({
        product_id: item.product_id,
        variant_id: item.variant_id,
        stripe_price_id: item.variant?.stripe_price_id || undefined,
        quantity: item.quantity,
        customization: item.customizations || {}
      }));

      // Create checkout session using secure Edge Function
      const { data, error } = await supabase.functions.invoke('create-checkout-secure', {
        body: {
          items: checkoutItems,
          customer_email: formData.email,
          success_url: `${window.location.origin}/order-success?session_id={CHECKOUT_SESSION_ID}`,
          cancel_url: `${window.location.origin}/cart`,
          customer_details: {
            name: `${formData.firstName} ${formData.lastName}`.trim(),
            phone: formData.phone,
            address: {
              line1: formData.addressLine1,
              line2: formData.addressLine2,
              city: formData.city,
              state: formData.state,
              postal_code: formData.postalCode,
              country: formData.country
            }
          }
        },
        headers: user ? {
          'Authorization': `Bearer ${(await supabase.auth.getSession()).data.session?.access_token}`
        } : undefined
      });

      if (error) {
        throw new Error(error.message || 'Failed to create checkout session');
      }

      if (!data?.url) {
        throw new Error('No checkout URL received');
      }

      // Clear cart on successful checkout creation
      await clearCart();

      // Redirect to Stripe Checkout
      window.location.href = data.url;

      if (onCheckoutComplete) {
        onCheckoutComplete(data.session_id || data.checkout_session_id);
      }

    } catch (error: any) {
      console.error('Checkout error:', error);
      const errorMessage = error.message || 'Failed to create checkout session';
      
      toast.error(errorMessage);
      
      if (onCheckoutError) {
        onCheckoutError(errorMessage);
      }
    } finally {
      setLoading(false);
    }
  };

  const handleInputChange = (field: string, value: string) => {
    setFormData(prev => ({ ...prev, [field]: value }));
    
    // Clear validation error for this field
    if (validationErrors[field]) {
      setValidationErrors(prev => {
        const { [field]: _, ...rest } = prev;
        return rest;
      });
    }
  };

  const cartTotal = getCartTotal();
  const itemCount = items.reduce((sum, item) => sum + item.quantity, 0);

  if (items.length === 0) {
    return (
      <Card className="w-full max-w-2xl mx-auto">
        <CardContent className="flex flex-col items-center py-8">
          <ShoppingCart className="h-12 w-12 text-muted-foreground mb-4" />
          <h3 className="text-lg font-semibold mb-2">Your cart is empty</h3>
          <p className="text-muted-foreground text-center">
            Add some items to your cart before proceeding to checkout.
          </p>
        </CardContent>
      </Card>
    );
  }

  return (
    <div className="w-full max-w-4xl mx-auto space-y-6">
      {/* Security indicators */}
      <div className="flex items-center gap-2 text-sm text-muted-foreground">
        <Shield className="h-4 w-4 text-green-600" />
        <span>Secure checkout powered by Stripe</span>
        {cartExpiration && (
          <>
            <Separator orientation="vertical" className="h-4" />
            <Clock className="h-4 w-4" />
            <span>Cart expires: {cartExpiration.toLocaleTimeString()}</span>
          </>
        )}
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
        {/* Order Summary */}
        <div className="lg:col-span-1">
          <Card>
            <CardHeader>
              <CardTitle className="flex items-center gap-2">
                <ShoppingCart className="h-5 w-5" />
                Order Summary
              </CardTitle>
            </CardHeader>
            <CardContent className="space-y-4">
              {items.map((item) => (
                <div key={`${item.product_id}-${item.variant_id}`} className="flex justify-between">
                  <div className="flex-1">
                    <h4 className="font-medium text-sm">{item.product?.name}</h4>
                    {item.variant?.title && (
                      <p className="text-xs text-muted-foreground">{item.variant.title}</p>
                    )}
                    <p className="text-xs text-muted-foreground">Qty: {item.quantity}</p>
                  </div>
                  <div className="text-sm font-medium">
                    ${((item.variant?.price || item.product?.base_price || 0) * item.quantity).toFixed(2)}
                  </div>
                </div>
              ))}
              
              <Separator />
              
              <div className="flex justify-between items-center font-semibold">
                <span>Total ({itemCount} items)</span>
                <span>${cartTotal.toFixed(2)}</span>
              </div>

              {user && userProfile && (
                <Alert>
                  <CheckCircle className="h-4 w-4" />
                  <AlertDescription>
                    Signed in as {userProfile.full_name || user.email}
                  </AlertDescription>
                </Alert>
              )}
            </CardContent>
          </Card>
        </div>

        {/* Checkout Form */}
        <div className="lg:col-span-2">
          <Card>
            <CardHeader>
              <CardTitle className="flex items-center gap-2">
                <CreditCard className="h-5 w-5" />
                Checkout Details
              </CardTitle>
            </CardHeader>
            <CardContent className="space-y-6">
              {/* Contact Information */}
              <div className="space-y-4">
                <div className="flex items-center gap-2">
                  <User className="h-4 w-4" />
                  <h3 className="font-semibold">Contact Information</h3>
                </div>
                
                <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
                  <div>
                    <Label htmlFor="firstName">First Name *</Label>
                    <Input
                      id="firstName"
                      value={formData.firstName}
                      onChange={(e) => handleInputChange('firstName', e.target.value)}
                      className={validationErrors.firstName ? 'border-red-500' : ''}
                    />
                    {validationErrors.firstName && (
                      <p className="text-xs text-red-600 mt-1">{validationErrors.firstName}</p>
                    )}
                  </div>
                  
                  <div>
                    <Label htmlFor="lastName">Last Name *</Label>
                    <Input
                      id="lastName"
                      value={formData.lastName}
                      onChange={(e) => handleInputChange('lastName', e.target.value)}
                      className={validationErrors.lastName ? 'border-red-500' : ''}
                    />
                    {validationErrors.lastName && (
                      <p className="text-xs text-red-600 mt-1">{validationErrors.lastName}</p>
                    )}
                  </div>
                </div>

                <div>
                  <Label htmlFor="email">Email *</Label>
                  <Input
                    id="email"
                    type="email"
                    value={formData.email}
                    onChange={(e) => handleInputChange('email', e.target.value)}
                    className={validationErrors.email ? 'border-red-500' : ''}
                  />
                  {validationErrors.email && (
                    <p className="text-xs text-red-600 mt-1">{validationErrors.email}</p>
                  )}
                </div>

                <div>
                  <Label htmlFor="phone">Phone</Label>
                  <Input
                    id="phone"
                    type="tel"
                    value={formData.phone}
                    onChange={(e) => handleInputChange('phone', e.target.value)}
                    className={validationErrors.phone ? 'border-red-500' : ''}
                  />
                  {validationErrors.phone && (
                    <p className="text-xs text-red-600 mt-1">{validationErrors.phone}</p>
                  )}
                </div>
              </div>

              {/* Shipping Address */}
              <div className="space-y-4">
                <div className="flex items-center gap-2">
                  <MapPin className="h-4 w-4" />
                  <h3 className="font-semibold">Shipping Address</h3>
                  {userProfile?.saved_addresses && userProfile.saved_addresses.length > 0 && (
                    <Badge variant="outline">
                      {userProfile.saved_addresses.length} saved
                    </Badge>
                  )}
                </div>

                <div>
                  <Label htmlFor="addressLine1">Address *</Label>
                  <Input
                    id="addressLine1"
                    value={formData.addressLine1}
                    onChange={(e) => handleInputChange('addressLine1', e.target.value)}
                    className={validationErrors.addressLine1 ? 'border-red-500' : ''}
                  />
                  {validationErrors.addressLine1 && (
                    <p className="text-xs text-red-600 mt-1">{validationErrors.addressLine1}</p>
                  )}
                </div>

                <div>
                  <Label htmlFor="addressLine2">Apartment, suite, etc.</Label>
                  <Input
                    id="addressLine2"
                    value={formData.addressLine2}
                    onChange={(e) => handleInputChange('addressLine2', e.target.value)}
                  />
                </div>

                <div className="grid grid-cols-2 sm:grid-cols-3 gap-4">
                  <div>
                    <Label htmlFor="city">City *</Label>
                    <Input
                      id="city"
                      value={formData.city}
                      onChange={(e) => handleInputChange('city', e.target.value)}
                      className={validationErrors.city ? 'border-red-500' : ''}
                    />
                    {validationErrors.city && (
                      <p className="text-xs text-red-600 mt-1">{validationErrors.city}</p>
                    )}
                  </div>
                  
                  <div>
                    <Label htmlFor="state">State *</Label>
                    <Input
                      id="state"
                      value={formData.state}
                      onChange={(e) => handleInputChange('state', e.target.value)}
                      className={validationErrors.state ? 'border-red-500' : ''}
                    />
                    {validationErrors.state && (
                      <p className="text-xs text-red-600 mt-1">{validationErrors.state}</p>
                    )}
                  </div>
                  
                  <div>
                    <Label htmlFor="postalCode">ZIP Code *</Label>
                    <Input
                      id="postalCode"
                      value={formData.postalCode}
                      onChange={(e) => handleInputChange('postalCode', e.target.value)}
                      className={validationErrors.postalCode ? 'border-red-500' : ''}
                    />
                    {validationErrors.postalCode && (
                      <p className="text-xs text-red-600 mt-1">{validationErrors.postalCode}</p>
                    )}
                  </div>
                </div>
              </div>

              {/* Payment Methods */}
              <div className="space-y-4">
                <div className="flex items-center gap-2">
                  <CreditCard className="h-4 w-4" />
                  <h3 className="font-semibold">Payment Methods</h3>
                </div>
                
                <div className="flex flex-wrap gap-2">
                  {paymentMethods.map((method) => (
                    <Badge key={method} variant="outline">
                      {method === 'card' && 'Credit Card'}
                      {method === 'apple_pay' && 'Apple Pay'}
                      {method === 'google_pay' && 'Google Pay'}
                    </Badge>
                  ))}
                </div>

                <Alert>
                  <Shield className="h-4 w-4" />
                  <AlertDescription>
                    Payment details will be securely processed by Stripe. We never store your card information.
                  </AlertDescription>
                </Alert>
              </div>

              {/* Checkout Button */}
              <Button
                onClick={handleCheckout}
                disabled={loading || items.length === 0}
                className="w-full"
                size="lg"
              >
                {loading ? (
                  "Creating secure checkout..."
                ) : (
                  `Proceed to Payment - $${cartTotal.toFixed(2)}`
                )}
              </Button>

              <p className="text-xs text-muted-foreground text-center">
                By proceeding, you agree to our Terms of Service and Privacy Policy.
                Your payment will be processed securely by Stripe.
              </p>
            </CardContent>
          </Card>
        </div>
      </div>
    </div>
  );
}