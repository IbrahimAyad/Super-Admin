import React, { useState, useEffect } from 'react';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card";
import { Tabs, TabsContent, TabsList, TabsTrigger } from "@/components/ui/tabs";
import { Button } from "@/components/ui/button";
import { Badge } from "@/components/ui/badge";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "@/components/ui/select";
import { Separator } from "@/components/ui/separator";
import { toast } from "sonner";
import { supabase } from '@/lib/supabase-client';
import {
  User, Mail, Phone, Calendar, MapPin, CreditCard, 
  ShoppingBag, Ruler, Palette, Sparkles, Package,
  Edit, Save, X, Send, AlertCircle, DollarSign,
  Clock, TrendingUp, Hash
} from 'lucide-react';

interface CustomerProfileViewProps {
  customerId: string;
  customerEmail: string;
  onClose?: () => void;
}

interface SizeProfile {
  chest?: number;
  waist?: number;
  inseam?: number;
  neck?: number;
  sleeve?: number;
  shoe_size?: number;
  preferred_fit?: string;
  notes?: string;
}

interface StylePreferences {
  preferred_colors?: string[];
  preferred_styles?: string[];
  occasions?: string[];
  brands?: string[];
  avoid_materials?: string[];
  price_range?: string;
  notes?: string;
}

interface CustomerProfile {
  id: string;
  email: string;
  full_name?: string;
  phone?: string;
  date_of_birth?: string;
  size_profile?: SizeProfile;
  style_preferences?: StylePreferences;
  saved_addresses?: any[];
  wishlist_items?: any[];
  created_at?: string;
  updated_at?: string;
}

interface OrderSummary {
  total_orders: number;
  total_spent: number;
  last_order_date?: string;
  average_order_value?: number;
}

export function CustomerProfileView({ customerId, customerEmail, onClose }: CustomerProfileViewProps) {
  const [profile, setProfile] = useState<CustomerProfile | null>(null);
  const [orderSummary, setOrderSummary] = useState<OrderSummary>({
    total_orders: 0,
    total_spent: 0
  });
  const [loading, setLoading] = useState(true);
  const [editingSize, setEditingSize] = useState(false);
  const [editingStyle, setEditingStyle] = useState(false);
  const [sizeData, setSizeData] = useState<SizeProfile>({});
  const [styleData, setStylePreferences] = useState<StylePreferences>({});

  useEffect(() => {
    fetchCustomerProfile();
    fetchOrderSummary();
  }, [customerId, customerEmail]);

  const fetchCustomerProfile = async () => {
    try {
      setLoading(true);
      
      // First try to get user_profile by email
      const { data: profileData, error } = await supabase
        .from('user_profiles')
        .select('*')
        .eq('email', customerEmail)
        .single();

      if (error && error.code !== 'PGRST116') {
        console.error('Error fetching profile:', error);
      }

      if (profileData) {
        setProfile(profileData);
        setSizeData(profileData.size_profile || {});
        setStylePreferences(profileData.style_preferences || {});
      } else {
        // Create a basic profile structure if none exists
        setProfile({
          id: customerId,
          email: customerEmail,
          size_profile: {},
          style_preferences: {}
        });
      }

      // Also try to get customer data from customers table
      const { data: customerData } = await supabase
        .from('customers')
        .select('*')
        .eq('email', customerEmail)
        .single();

      if (customerData && profile) {
        setProfile(prev => ({
          ...prev!,
          full_name: customerData.name || prev?.full_name,
          phone: customerData.phone || prev?.phone
        }));
      }
    } catch (error) {
      console.error('Error:', error);
      toast.error('Failed to load customer profile');
    } finally {
      setLoading(false);
    }
  };

  const fetchOrderSummary = async () => {
    try {
      // Fetch order history
      const { data: orders, error } = await supabase
        .from('orders')
        .select('total_amount, created_at')
        .or(`customer_email.eq.${customerEmail},guest_email.eq.${customerEmail}`)
        .order('created_at', { ascending: false });

      if (!error && orders) {
        const totalSpent = orders.reduce((sum, order) => sum + (order.total_amount || 0), 0);
        const avgOrderValue = orders.length > 0 ? totalSpent / orders.length : 0;
        
        setOrderSummary({
          total_orders: orders.length,
          total_spent: totalSpent,
          last_order_date: orders[0]?.created_at,
          average_order_value: avgOrderValue
        });
      }
    } catch (error) {
      console.error('Error fetching order summary:', error);
    }
  };

  const saveSizeProfile = async () => {
    try {
      const { error } = await supabase
        .from('user_profiles')
        .upsert({
          id: profile?.id,
          email: customerEmail,
          size_profile: sizeData,
          updated_at: new Date().toISOString()
        });

      if (error) throw error;

      toast.success('Size profile updated successfully');
      setEditingSize(false);
      fetchCustomerProfile();
    } catch (error) {
      console.error('Error saving size profile:', error);
      toast.error('Failed to save size profile');
    }
  };

  const saveStylePreferences = async () => {
    try {
      const { error } = await supabase
        .from('user_profiles')
        .upsert({
          id: profile?.id,
          email: customerEmail,
          style_preferences: styleData,
          updated_at: new Date().toISOString()
        });

      if (error) throw error;

      toast.success('Style preferences updated successfully');
      setEditingStyle(false);
      fetchCustomerProfile();
    } catch (error) {
      console.error('Error saving style preferences:', error);
      toast.error('Failed to save style preferences');
    }
  };

  const generateAIRecommendation = async () => {
    toast.success('AI recommendation request sent!');
    // TODO: Integrate with AI recommendation system
  };

  const createCustomBundle = () => {
    toast.info('Opening bundle creator...');
    // TODO: Navigate to bundle creation with pre-filled customer data
  };

  const sendSizeRequestEmail = async () => {
    toast.success('Size request email sent to customer');
    // TODO: Integrate with email service
  };

  if (loading) {
    return (
      <div className="flex items-center justify-center p-8">
        <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-primary"></div>
      </div>
    );
  }

  return (
    <div className="space-y-6">
      {/* Header */}
      <div className="flex items-center justify-between">
        <div className="flex items-center gap-4">
          <div className="h-12 w-12 rounded-full bg-primary/10 flex items-center justify-center">
            <User className="h-6 w-6 text-primary" />
          </div>
          <div>
            <h2 className="text-2xl font-bold">Customer Profile</h2>
            <p className="text-muted-foreground">{customerEmail}</p>
          </div>
        </div>
        {onClose && (
          <Button variant="ghost" size="icon" onClick={onClose}>
            <X className="h-4 w-4" />
          </Button>
        )}
      </div>

      {/* Customer Information Card */}
      <Card>
        <CardContent className="pt-6">
          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6">
            {/* Basic Info */}
            <div className="space-y-3">
              <h3 className="font-semibold text-sm text-muted-foreground uppercase tracking-wider">Contact Info</h3>
              <div className="space-y-2">
                <div className="flex items-center gap-2">
                  <User className="h-4 w-4 text-muted-foreground" />
                  <span className="text-sm">{profile?.full_name || 'Name not set'}</span>
                </div>
                <div className="flex items-center gap-2">
                  <Mail className="h-4 w-4 text-muted-foreground" />
                  <span className="text-sm">{customerEmail}</span>
                </div>
                <div className="flex items-center gap-2">
                  <Phone className="h-4 w-4 text-muted-foreground" />
                  <span className="text-sm">{profile?.phone || 'No phone'}</span>
                </div>
              </div>
            </div>

            {/* Order Summary */}
            <div className="space-y-3">
              <h3 className="font-semibold text-sm text-muted-foreground uppercase tracking-wider">Order History</h3>
              <div className="space-y-2">
                <div className="flex items-center gap-2">
                  <Hash className="h-4 w-4 text-muted-foreground" />
                  <span className="text-sm">{orderSummary.total_orders} orders</span>
                </div>
                <div className="flex items-center gap-2">
                  <DollarSign className="h-4 w-4 text-muted-foreground" />
                  <span className="text-sm">${orderSummary.total_spent.toFixed(2)} total</span>
                </div>
                <div className="flex items-center gap-2">
                  <TrendingUp className="h-4 w-4 text-muted-foreground" />
                  <span className="text-sm">${orderSummary.average_order_value?.toFixed(2) || '0.00'} avg</span>
                </div>
              </div>
            </div>

            {/* Customer Status */}
            <div className="space-y-3">
              <h3 className="font-semibold text-sm text-muted-foreground uppercase tracking-wider">Customer Status</h3>
              <div className="space-y-2">
                <div className="flex items-center gap-2">
                  <Calendar className="h-4 w-4 text-muted-foreground" />
                  <span className="text-sm">
                    Member since {profile?.created_at ? new Date(profile.created_at).toLocaleDateString() : 'N/A'}
                  </span>
                </div>
                <div className="flex items-center gap-2">
                  <Clock className="h-4 w-4 text-muted-foreground" />
                  <span className="text-sm">
                    Last order: {orderSummary.last_order_date 
                      ? new Date(orderSummary.last_order_date).toLocaleDateString() 
                      : 'No orders'}
                  </span>
                </div>
                <div className="flex items-center gap-2">
                  <Badge variant={orderSummary.total_orders > 5 ? "default" : "secondary"}>
                    {orderSummary.total_orders > 5 ? 'VIP Customer' : 
                     orderSummary.total_orders > 0 ? 'Active Customer' : 'New Customer'}
                  </Badge>
                </div>
              </div>
            </div>

            {/* Quick Stats */}
            <div className="space-y-3">
              <h3 className="font-semibold text-sm text-muted-foreground uppercase tracking-wider">Profile Status</h3>
              <div className="space-y-2">
                <div className="flex items-center gap-2">
                  <Ruler className="h-4 w-4 text-muted-foreground" />
                  <span className="text-sm">
                    Size Profile: {profile?.size_profile && Object.keys(profile.size_profile).length > 0 
                      ? <Badge variant="success" className="ml-1">Complete</Badge>
                      : <Badge variant="outline" className="ml-1">Incomplete</Badge>}
                  </span>
                </div>
                <div className="flex items-center gap-2">
                  <Palette className="h-4 w-4 text-muted-foreground" />
                  <span className="text-sm">
                    Style Prefs: {profile?.style_preferences && Object.keys(profile.style_preferences).length > 0 
                      ? <Badge variant="success" className="ml-1">Set</Badge>
                      : <Badge variant="outline" className="ml-1">Not Set</Badge>}
                  </span>
                </div>
                <div className="flex items-center gap-2">
                  <MapPin className="h-4 w-4 text-muted-foreground" />
                  <span className="text-sm">
                    {profile?.saved_addresses && profile.saved_addresses.length > 0 
                      ? `${profile.saved_addresses.length} saved` 
                      : 'No addresses'}
                  </span>
                </div>
              </div>
            </div>
          </div>
        </CardContent>
      </Card>

      {/* Quick Actions */}
      <Card>
        <CardHeader>
          <CardTitle className="text-lg">Quick Actions</CardTitle>
        </CardHeader>
        <CardContent className="flex gap-2 flex-wrap">
          <Button onClick={generateAIRecommendation} variant="default" size="sm">
            <Sparkles className="h-4 w-4 mr-2" />
            Generate AI Recommendation
          </Button>
          <Button onClick={createCustomBundle} variant="outline" size="sm">
            <Package className="h-4 w-4 mr-2" />
            Create Custom Bundle
          </Button>
          <Button onClick={sendSizeRequestEmail} variant="outline" size="sm">
            <Send className="h-4 w-4 mr-2" />
            Request Size Info
          </Button>
        </CardContent>
      </Card>

      {/* Profile Tabs */}
      <Tabs defaultValue="size" className="w-full">
        <TabsList className="grid w-full grid-cols-4">
          <TabsTrigger value="size">Size Profile</TabsTrigger>
          <TabsTrigger value="style">Style Preferences</TabsTrigger>
          <TabsTrigger value="addresses">Addresses</TabsTrigger>
          <TabsTrigger value="wishlist">Wishlist</TabsTrigger>
        </TabsList>

        {/* Size Profile Tab */}
        <TabsContent value="size">
          <Card>
            <CardHeader>
              <div className="flex items-center justify-between">
                <div>
                  <CardTitle>Size Profile</CardTitle>
                  <CardDescription>Customer's measurements and fit preferences</CardDescription>
                </div>
                {!editingSize ? (
                  <Button onClick={() => setEditingSize(true)} variant="outline" size="sm">
                    <Edit className="h-4 w-4 mr-2" />
                    Edit
                  </Button>
                ) : (
                  <div className="flex gap-2">
                    <Button onClick={saveSizeProfile} size="sm">
                      <Save className="h-4 w-4 mr-2" />
                      Save
                    </Button>
                    <Button onClick={() => {
                      setEditingSize(false);
                      setSizeData(profile?.size_profile || {});
                    }} variant="outline" size="sm">
                      Cancel
                    </Button>
                  </div>
                )}
              </div>
            </CardHeader>
            <CardContent className="space-y-4">
              <div className="grid grid-cols-2 md:grid-cols-3 gap-4">
                <div>
                  <Label>Chest (inches)</Label>
                  {editingSize ? (
                    <Input
                      type="number"
                      value={sizeData.chest || ''}
                      onChange={(e) => setSizeData({...sizeData, chest: Number(e.target.value)})}
                      placeholder="40"
                    />
                  ) : (
                    <p className="text-lg font-medium">{sizeData.chest || '-'}</p>
                  )}
                </div>
                <div>
                  <Label>Waist (inches)</Label>
                  {editingSize ? (
                    <Input
                      type="number"
                      value={sizeData.waist || ''}
                      onChange={(e) => setSizeData({...sizeData, waist: Number(e.target.value)})}
                      placeholder="32"
                    />
                  ) : (
                    <p className="text-lg font-medium">{sizeData.waist || '-'}</p>
                  )}
                </div>
                <div>
                  <Label>Inseam (inches)</Label>
                  {editingSize ? (
                    <Input
                      type="number"
                      value={sizeData.inseam || ''}
                      onChange={(e) => setSizeData({...sizeData, inseam: Number(e.target.value)})}
                      placeholder="32"
                    />
                  ) : (
                    <p className="text-lg font-medium">{sizeData.inseam || '-'}</p>
                  )}
                </div>
                <div>
                  <Label>Neck (inches)</Label>
                  {editingSize ? (
                    <Input
                      type="number"
                      step="0.5"
                      value={sizeData.neck || ''}
                      onChange={(e) => setSizeData({...sizeData, neck: Number(e.target.value)})}
                      placeholder="15.5"
                    />
                  ) : (
                    <p className="text-lg font-medium">{sizeData.neck || '-'}</p>
                  )}
                </div>
                <div>
                  <Label>Sleeve (inches)</Label>
                  {editingSize ? (
                    <Input
                      type="number"
                      value={sizeData.sleeve || ''}
                      onChange={(e) => setSizeData({...sizeData, sleeve: Number(e.target.value)})}
                      placeholder="34"
                    />
                  ) : (
                    <p className="text-lg font-medium">{sizeData.sleeve || '-'}</p>
                  )}
                </div>
                <div>
                  <Label>Shoe Size</Label>
                  {editingSize ? (
                    <Input
                      type="number"
                      step="0.5"
                      value={sizeData.shoe_size || ''}
                      onChange={(e) => setSizeData({...sizeData, shoe_size: Number(e.target.value)})}
                      placeholder="10"
                    />
                  ) : (
                    <p className="text-lg font-medium">{sizeData.shoe_size || '-'}</p>
                  )}
                </div>
              </div>
              
              <Separator />
              
              <div>
                <Label>Preferred Fit</Label>
                {editingSize ? (
                  <Select
                    value={sizeData.preferred_fit || ''}
                    onValueChange={(value) => setSizeData({...sizeData, preferred_fit: value})}
                  >
                    <SelectTrigger>
                      <SelectValue placeholder="Select fit preference" />
                    </SelectTrigger>
                    <SelectContent>
                      <SelectItem value="slim">Slim Fit</SelectItem>
                      <SelectItem value="regular">Regular Fit</SelectItem>
                      <SelectItem value="relaxed">Relaxed Fit</SelectItem>
                      <SelectItem value="athletic">Athletic Fit</SelectItem>
                    </SelectContent>
                  </Select>
                ) : (
                  <p className="text-lg font-medium capitalize">{sizeData.preferred_fit || '-'}</p>
                )}
              </div>

              <div>
                <Label>Notes</Label>
                {editingSize ? (
                  <Input
                    value={sizeData.notes || ''}
                    onChange={(e) => setSizeData({...sizeData, notes: e.target.value})}
                    placeholder="Additional sizing notes..."
                  />
                ) : (
                  <p className="text-muted-foreground">{sizeData.notes || 'No notes'}</p>
                )}
              </div>
            </CardContent>
          </Card>
        </TabsContent>

        {/* Style Preferences Tab */}
        <TabsContent value="style">
          <Card>
            <CardHeader>
              <div className="flex items-center justify-between">
                <div>
                  <CardTitle>Style Preferences</CardTitle>
                  <CardDescription>Customer's style and fashion preferences</CardDescription>
                </div>
                {!editingStyle ? (
                  <Button onClick={() => setEditingStyle(true)} variant="outline" size="sm">
                    <Edit className="h-4 w-4 mr-2" />
                    Edit
                  </Button>
                ) : (
                  <div className="flex gap-2">
                    <Button onClick={saveStylePreferences} size="sm">
                      <Save className="h-4 w-4 mr-2" />
                      Save
                    </Button>
                    <Button onClick={() => {
                      setEditingStyle(false);
                      setStylePreferences(profile?.style_preferences || {});
                    }} variant="outline" size="sm">
                      Cancel
                    </Button>
                  </div>
                )}
              </div>
            </CardHeader>
            <CardContent className="space-y-4">
              <div>
                <Label>Preferred Colors</Label>
                <div className="flex flex-wrap gap-2 mt-2">
                  {editingStyle ? (
                    <Input
                      placeholder="Navy, Grey, Black (comma separated)"
                      value={styleData.preferred_colors?.join(', ') || ''}
                      onChange={(e) => setStylePreferences({
                        ...styleData,
                        preferred_colors: e.target.value.split(',').map(s => s.trim()).filter(Boolean)
                      })}
                    />
                  ) : (
                    styleData.preferred_colors?.length ? (
                      styleData.preferred_colors.map((color, index) => (
                        <Badge key={index} variant="secondary">{color}</Badge>
                      ))
                    ) : (
                      <p className="text-muted-foreground">No preferences set</p>
                    )
                  )}
                </div>
              </div>

              <div>
                <Label>Preferred Styles</Label>
                <div className="flex flex-wrap gap-2 mt-2">
                  {editingStyle ? (
                    <Input
                      placeholder="Business Casual, Smart Casual (comma separated)"
                      value={styleData.preferred_styles?.join(', ') || ''}
                      onChange={(e) => setStylePreferences({
                        ...styleData,
                        preferred_styles: e.target.value.split(',').map(s => s.trim()).filter(Boolean)
                      })}
                    />
                  ) : (
                    styleData.preferred_styles?.length ? (
                      styleData.preferred_styles.map((style, index) => (
                        <Badge key={index} variant="secondary">{style}</Badge>
                      ))
                    ) : (
                      <p className="text-muted-foreground">No preferences set</p>
                    )
                  )}
                </div>
              </div>

              <div>
                <Label>Occasions</Label>
                <div className="flex flex-wrap gap-2 mt-2">
                  {editingStyle ? (
                    <Input
                      placeholder="Work, Events, Casual (comma separated)"
                      value={styleData.occasions?.join(', ') || ''}
                      onChange={(e) => setStylePreferences({
                        ...styleData,
                        occasions: e.target.value.split(',').map(s => s.trim()).filter(Boolean)
                      })}
                    />
                  ) : (
                    styleData.occasions?.length ? (
                      styleData.occasions.map((occasion, index) => (
                        <Badge key={index} variant="outline">{occasion}</Badge>
                      ))
                    ) : (
                      <p className="text-muted-foreground">No occasions set</p>
                    )
                  )}
                </div>
              </div>

              <div>
                <Label>Materials to Avoid</Label>
                <div className="flex flex-wrap gap-2 mt-2">
                  {editingStyle ? (
                    <Input
                      placeholder="Polyester, Wool (comma separated)"
                      value={styleData.avoid_materials?.join(', ') || ''}
                      onChange={(e) => setStylePreferences({
                        ...styleData,
                        avoid_materials: e.target.value.split(',').map(s => s.trim()).filter(Boolean)
                      })}
                    />
                  ) : (
                    styleData.avoid_materials?.length ? (
                      styleData.avoid_materials.map((material, index) => (
                        <Badge key={index} variant="destructive">{material}</Badge>
                      ))
                    ) : (
                      <p className="text-muted-foreground">No restrictions</p>
                    )
                  )}
                </div>
              </div>

              <div>
                <Label>Price Range</Label>
                {editingStyle ? (
                  <Select
                    value={styleData.price_range || ''}
                    onValueChange={(value) => setStylePreferences({...styleData, price_range: value})}
                  >
                    <SelectTrigger>
                      <SelectValue placeholder="Select price range" />
                    </SelectTrigger>
                    <SelectContent>
                      <SelectItem value="budget">Budget ($0-50)</SelectItem>
                      <SelectItem value="moderate">Moderate ($50-150)</SelectItem>
                      <SelectItem value="premium">Premium ($150-300)</SelectItem>
                      <SelectItem value="luxury">Luxury ($300+)</SelectItem>
                    </SelectContent>
                  </Select>
                ) : (
                  <p className="text-lg font-medium capitalize">{styleData.price_range || 'Not specified'}</p>
                )}
              </div>
            </CardContent>
          </Card>
        </TabsContent>

        {/* Addresses Tab */}
        <TabsContent value="addresses">
          <Card>
            <CardHeader>
              <CardTitle>Saved Addresses</CardTitle>
              <CardDescription>Customer's shipping and billing addresses</CardDescription>
            </CardHeader>
            <CardContent>
              {profile?.saved_addresses?.length ? (
                <div className="space-y-4">
                  {profile.saved_addresses.map((address: any, index: number) => (
                    <div key={index} className="border rounded-lg p-4">
                      <div className="flex items-center gap-2 mb-2">
                        <MapPin className="h-4 w-4" />
                        <span className="font-medium">{address.type || 'Shipping'}</span>
                      </div>
                      <p className="text-sm text-muted-foreground">
                        {address.street}<br />
                        {address.city}, {address.state} {address.zip}<br />
                        {address.country}
                      </p>
                    </div>
                  ))}
                </div>
              ) : (
                <div className="text-center py-8 text-muted-foreground">
                  <MapPin className="h-12 w-12 mx-auto mb-2 opacity-50" />
                  <p>No saved addresses</p>
                </div>
              )}
            </CardContent>
          </Card>
        </TabsContent>

        {/* Wishlist Tab */}
        <TabsContent value="wishlist">
          <Card>
            <CardHeader>
              <CardTitle>Wishlist Items</CardTitle>
              <CardDescription>Products saved by the customer</CardDescription>
            </CardHeader>
            <CardContent>
              {profile?.wishlist_items?.length ? (
                <div className="grid grid-cols-2 md:grid-cols-3 gap-4">
                  {profile.wishlist_items.map((item: any, index: number) => (
                    <div key={index} className="border rounded-lg p-4">
                      <ShoppingBag className="h-8 w-8 mb-2" />
                      <p className="font-medium text-sm">{item.name || `Item ${index + 1}`}</p>
                      <p className="text-xs text-muted-foreground">{item.price || '$0.00'}</p>
                    </div>
                  ))}
                </div>
              ) : (
                <div className="text-center py-8 text-muted-foreground">
                  <ShoppingBag className="h-12 w-12 mx-auto mb-2 opacity-50" />
                  <p>No items in wishlist</p>
                </div>
              )}
            </CardContent>
          </Card>
        </TabsContent>
      </Tabs>
    </div>
  );
}