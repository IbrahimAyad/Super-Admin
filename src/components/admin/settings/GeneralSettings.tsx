import { useState, useEffect } from 'react';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { Label } from '@/components/ui/label';
import { Textarea } from '@/components/ui/textarea';
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from '@/components/ui/select';
import { Switch } from '@/components/ui/switch';
import { Separator } from '@/components/ui/separator';
import { Badge } from '@/components/ui/badge';
import { useToast } from '@/hooks/use-toast';
import { 
  Store, 
  Upload, 
  MapPin, 
  Phone, 
  Mail, 
  Globe, 
  Clock,
  Image as ImageIcon,
  X,
  Check,
  AlertCircle
} from 'lucide-react';

interface GeneralSettingsData {
  // Store Information
  storeName: string;
  storeDescription: string;
  storeTagline: string;
  logoUrl: string;
  faviconUrl: string;
  
  // Contact Information
  contactEmail: string;
  supportEmail: string;
  phoneNumber: string;
  
  // Address
  address: {
    street: string;
    city: string;
    state: string;
    postalCode: string;
    country: string;
  };
  
  // Business Information
  businessType: 'retail' | 'wholesale' | 'both';
  timezone: string;
  currency: string;
  weightUnit: 'kg' | 'lb';
  dimensionUnit: 'cm' | 'in';
  
  // Social Media
  socialMedia: {
    facebook: string;
    instagram: string;
    twitter: string;
    linkedin: string;
    youtube: string;
  };
  
  // Store Features
  features: {
    guestCheckout: boolean;
    accountCreation: boolean;
    productReviews: boolean;
    wishlist: boolean;
    compareProducts: boolean;
    multiCurrency: boolean;
    multiLanguage: boolean;
  };
  
  // Legal
  legal: {
    privacyPolicyUrl: string;
    termsOfServiceUrl: string;
    returnPolicyUrl: string;
    shippingPolicyUrl: string;
  };
}

const defaultSettings: GeneralSettingsData = {
  storeName: 'KCT Menswear',
  storeDescription: 'Premium men\'s fashion and custom tailoring services',
  storeTagline: 'Elevating Men\'s Style Since 1985',
  logoUrl: '',
  faviconUrl: '',
  contactEmail: 'info@kctmenswear.com',
  supportEmail: 'support@kctmenswear.com',
  phoneNumber: '+1 (555) 123-4567',
  address: {
    street: '123 Fashion Avenue',
    city: 'New York',
    state: 'NY',
    postalCode: '10001',
    country: 'United States'
  },
  businessType: 'retail',
  timezone: 'America/New_York',
  currency: 'USD',
  weightUnit: 'lb',
  dimensionUnit: 'in',
  socialMedia: {
    facebook: '',
    instagram: '',
    twitter: '',
    linkedin: '',
    youtube: ''
  },
  features: {
    guestCheckout: true,
    accountCreation: true,
    productReviews: true,
    wishlist: true,
    compareProducts: false,
    multiCurrency: false,
    multiLanguage: false
  },
  legal: {
    privacyPolicyUrl: '',
    termsOfServiceUrl: '',
    returnPolicyUrl: '',
    shippingPolicyUrl: ''
  }
};

const timezones = [
  'America/New_York',
  'America/Chicago',
  'America/Denver',
  'America/Los_Angeles',
  'Europe/London',
  'Europe/Paris',
  'Asia/Tokyo',
  'Asia/Shanghai',
  'Australia/Sydney'
];

const currencies = [
  'USD', 'EUR', 'GBP', 'CAD', 'AUD', 'JPY', 'CHF', 'SEK', 'NOK', 'DKK'
];

const countries = [
  'United States', 'Canada', 'United Kingdom', 'Australia', 'Germany', 
  'France', 'Japan', 'Netherlands', 'Sweden', 'Norway'
];

interface GeneralSettingsProps {
  onSettingsChange: () => void;
}

export function GeneralSettings({ onSettingsChange }: GeneralSettingsProps) {
  const [settings, setSettings] = useState<GeneralSettingsData>(defaultSettings);
  const [isLoading, setIsLoading] = useState(false);
  const [errors, setErrors] = useState<Record<string, string>>({});
  const { toast } = useToast();

  useEffect(() => {
    loadSettings();
  }, []);

  const loadSettings = async () => {
    setIsLoading(true);
    try {
      // Simulate loading settings from API
      await new Promise(resolve => setTimeout(resolve, 500));
      // In real implementation, load from API
    } catch (error) {
      toast({
        title: "Error loading settings",
        description: "Unable to load general settings. Using defaults.",
        variant: "destructive"
      });
    } finally {
      setIsLoading(false);
    }
  };

  const handleInputChange = (field: string, value: string | boolean) => {
    setSettings(prev => {
      const keys = field.split('.');
      const newSettings = { ...prev };
      let current: any = newSettings;
      
      for (let i = 0; i < keys.length - 1; i++) {
        current[keys[i]] = { ...current[keys[i]] };
        current = current[keys[i]];
      }
      
      current[keys[keys.length - 1]] = value;
      return newSettings;
    });
    onSettingsChange();
  };

  const handleImageUpload = async (type: 'logo' | 'favicon', file: File) => {
    try {
      // Simulate image upload
      const formData = new FormData();
      formData.append('file', file);
      
      // In real implementation, upload to storage service
      await new Promise(resolve => setTimeout(resolve, 1000));
      
      const imageUrl = URL.createObjectURL(file); // Temporary preview
      handleInputChange(type === 'logo' ? 'logoUrl' : 'faviconUrl', imageUrl);
      
      toast({
        title: "Image uploaded",
        description: `${type === 'logo' ? 'Logo' : 'Favicon'} uploaded successfully.`,
      });
    } catch (error) {
      toast({
        title: "Upload failed",
        description: "Unable to upload image. Please try again.",
        variant: "destructive"
      });
    }
  };

  const validateSettings = () => {
    const newErrors: Record<string, string> = {};
    
    if (!settings.storeName.trim()) {
      newErrors.storeName = 'Store name is required';
    }
    
    if (!settings.contactEmail.trim()) {
      newErrors.contactEmail = 'Contact email is required';
    } else if (!/\S+@\S+\.\S+/.test(settings.contactEmail)) {
      newErrors.contactEmail = 'Invalid email format';
    }
    
    if (!settings.address.street.trim()) {
      newErrors['address.street'] = 'Street address is required';
    }
    
    if (!settings.address.city.trim()) {
      newErrors['address.city'] = 'City is required';
    }
    
    setErrors(newErrors);
    return Object.keys(newErrors).length === 0;
  };

  if (isLoading) {
    return (
      <div className="space-y-6">
        {[...Array(4)].map((_, i) => (
          <Card key={i}>
            <CardHeader>
              <div className="h-5 bg-muted animate-pulse rounded" />
            </CardHeader>
            <CardContent className="space-y-4">
              <div className="h-4 bg-muted animate-pulse rounded w-3/4" />
              <div className="h-10 bg-muted animate-pulse rounded" />
            </CardContent>
          </Card>
        ))}
      </div>
    );
  }

  return (
    <div className="space-y-6">
      {/* Store Information */}
      <Card>
        <CardHeader>
          <div className="flex items-center gap-2">
            <Store className="h-5 w-5" />
            <CardTitle>Store Information</CardTitle>
            <Badge variant="outline" className="ml-auto">
              Critical
            </Badge>
          </div>
          <CardDescription>
            Basic information about your store that appears on your website
          </CardDescription>
        </CardHeader>
        <CardContent className="space-y-4">
          <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
            <div className="space-y-2">
              <Label htmlFor="storeName">
                Store Name <span className="text-destructive">*</span>
              </Label>
              <Input
                id="storeName"
                value={settings.storeName}
                onChange={(e) => handleInputChange('storeName', e.target.value)}
                className={errors.storeName ? 'border-destructive' : ''}
              />
              {errors.storeName && (
                <p className="text-sm text-destructive flex items-center gap-1">
                  <AlertCircle className="h-3 w-3" />
                  {errors.storeName}
                </p>
              )}
            </div>
            
            <div className="space-y-2">
              <Label htmlFor="storeTagline">Store Tagline</Label>
              <Input
                id="storeTagline"
                value={settings.storeTagline}
                onChange={(e) => handleInputChange('storeTagline', e.target.value)}
                placeholder="A brief tagline for your store"
              />
            </div>
          </div>
          
          <div className="space-y-2">
            <Label htmlFor="storeDescription">Store Description</Label>
            <Textarea
              id="storeDescription"
              value={settings.storeDescription}
              onChange={(e) => handleInputChange('storeDescription', e.target.value)}
              placeholder="Describe your store and what makes it unique"
              rows={3}
            />
          </div>
          
          {/* Logo and Favicon Upload */}
          <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
            <div className="space-y-2">
              <Label>Store Logo</Label>
              <div className="flex items-center gap-4">
                {settings.logoUrl ? (
                  <div className="relative">
                    <img 
                      src={settings.logoUrl} 
                      alt="Store logo"
                      className="h-16 w-16 object-contain border rounded"
                    />
                    <Button
                      size="sm"
                      variant="ghost"
                      className="absolute -top-2 -right-2 h-6 w-6 p-0"
                      onClick={() => handleInputChange('logoUrl', '')}
                    >
                      <X className="h-3 w-3" />
                    </Button>
                  </div>
                ) : (
                  <div className="h-16 w-16 border-2 border-dashed border-muted-foreground/25 rounded flex items-center justify-center">
                    <ImageIcon className="h-6 w-6 text-muted-foreground" />
                  </div>
                )}
                <div>
                  <Button
                    variant="outline"
                    size="sm"
                    onClick={() => document.getElementById('logo-upload')?.click()}
                  >
                    <Upload className="h-4 w-4 mr-2" />
                    Upload Logo
                  </Button>
                  <input
                    id="logo-upload"
                    type="file"
                    accept="image/*"
                    className="hidden"
                    onChange={(e) => {
                      const file = e.target.files?.[0];
                      if (file) handleImageUpload('logo', file);
                    }}
                  />
                  <p className="text-xs text-muted-foreground mt-1">
                    PNG, JPG up to 2MB
                  </p>
                </div>
              </div>
            </div>
            
            <div className="space-y-2">
              <Label>Favicon</Label>
              <div className="flex items-center gap-4">
                {settings.faviconUrl ? (
                  <div className="relative">
                    <img 
                      src={settings.faviconUrl} 
                      alt="Favicon"
                      className="h-8 w-8 object-contain border rounded"
                    />
                    <Button
                      size="sm"
                      variant="ghost"
                      className="absolute -top-1 -right-1 h-4 w-4 p-0"
                      onClick={() => handleInputChange('faviconUrl', '')}
                    >
                      <X className="h-2 w-2" />
                    </Button>
                  </div>
                ) : (
                  <div className="h-8 w-8 border-2 border-dashed border-muted-foreground/25 rounded flex items-center justify-center">
                    <ImageIcon className="h-3 w-3 text-muted-foreground" />
                  </div>
                )}
                <div>
                  <Button
                    variant="outline"
                    size="sm"
                    onClick={() => document.getElementById('favicon-upload')?.click()}
                  >
                    <Upload className="h-4 w-4 mr-2" />
                    Upload Favicon
                  </Button>
                  <input
                    id="favicon-upload"
                    type="file"
                    accept="image/x-icon,image/png"
                    className="hidden"
                    onChange={(e) => {
                      const file = e.target.files?.[0];
                      if (file) handleImageUpload('favicon', file);
                    }}
                  />
                  <p className="text-xs text-muted-foreground mt-1">
                    ICO, PNG 32x32px
                  </p>
                </div>
              </div>
            </div>
          </div>
        </CardContent>
      </Card>

      {/* Contact Information */}
      <Card>
        <CardHeader>
          <div className="flex items-center gap-2">
            <Mail className="h-5 w-5" />
            <CardTitle>Contact Information</CardTitle>
          </div>
          <CardDescription>
            Contact details that customers can use to reach you
          </CardDescription>
        </CardHeader>
        <CardContent className="space-y-4">
          <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
            <div className="space-y-2">
              <Label htmlFor="contactEmail">
                Contact Email <span className="text-destructive">*</span>
              </Label>
              <Input
                id="contactEmail"
                type="email"
                value={settings.contactEmail}
                onChange={(e) => handleInputChange('contactEmail', e.target.value)}
                className={errors.contactEmail ? 'border-destructive' : ''}
              />
              {errors.contactEmail && (
                <p className="text-sm text-destructive flex items-center gap-1">
                  <AlertCircle className="h-3 w-3" />
                  {errors.contactEmail}
                </p>
              )}
            </div>
            
            <div className="space-y-2">
              <Label htmlFor="supportEmail">Support Email</Label>
              <Input
                id="supportEmail"
                type="email"
                value={settings.supportEmail}
                onChange={(e) => handleInputChange('supportEmail', e.target.value)}
              />
            </div>
          </div>
          
          <div className="space-y-2">
            <Label htmlFor="phoneNumber">Phone Number</Label>
            <Input
              id="phoneNumber"
              value={settings.phoneNumber}
              onChange={(e) => handleInputChange('phoneNumber', e.target.value)}
              placeholder="+1 (555) 123-4567"
            />
          </div>
        </CardContent>
      </Card>

      {/* Business Address */}
      <Card>
        <CardHeader>
          <div className="flex items-center gap-2">
            <MapPin className="h-5 w-5" />
            <CardTitle>Business Address</CardTitle>
          </div>
          <CardDescription>
            Your business location for shipping and legal purposes
          </CardDescription>
        </CardHeader>
        <CardContent className="space-y-4">
          <div className="space-y-2">
            <Label htmlFor="street">
              Street Address <span className="text-destructive">*</span>
            </Label>
            <Input
              id="street"
              value={settings.address.street}
              onChange={(e) => handleInputChange('address.street', e.target.value)}
              className={errors['address.street'] ? 'border-destructive' : ''}
            />
            {errors['address.street'] && (
              <p className="text-sm text-destructive flex items-center gap-1">
                <AlertCircle className="h-3 w-3" />
                {errors['address.street']}
              </p>
            )}
          </div>
          
          <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
            <div className="space-y-2">
              <Label htmlFor="city">
                City <span className="text-destructive">*</span>
              </Label>
              <Input
                id="city"
                value={settings.address.city}
                onChange={(e) => handleInputChange('address.city', e.target.value)}
                className={errors['address.city'] ? 'border-destructive' : ''}
              />
              {errors['address.city'] && (
                <p className="text-sm text-destructive flex items-center gap-1">
                  <AlertCircle className="h-3 w-3" />
                  {errors['address.city']}
                </p>
              )}
            </div>
            
            <div className="space-y-2">
              <Label htmlFor="state">State/Province</Label>
              <Input
                id="state"
                value={settings.address.state}
                onChange={(e) => handleInputChange('address.state', e.target.value)}
              />
            </div>
            
            <div className="space-y-2">
              <Label htmlFor="postalCode">Postal Code</Label>
              <Input
                id="postalCode"
                value={settings.address.postalCode}
                onChange={(e) => handleInputChange('address.postalCode', e.target.value)}
              />
            </div>
          </div>
          
          <div className="space-y-2">
            <Label htmlFor="country">Country</Label>
            <Select 
              value={settings.address.country} 
              onValueChange={(value) => handleInputChange('address.country', value)}
            >
              <SelectTrigger>
                <SelectValue />
              </SelectTrigger>
              <SelectContent>
                {countries.map((country) => (
                  <SelectItem key={country} value={country}>
                    {country}
                  </SelectItem>
                ))}
              </SelectContent>
            </Select>
          </div>
        </CardContent>
      </Card>

      {/* Business Settings */}
      <Card>
        <CardHeader>
          <div className="flex items-center gap-2">
            <Globe className="h-5 w-5" />
            <CardTitle>Regional Settings</CardTitle>
          </div>
          <CardDescription>
            Configure regional settings for your business
          </CardDescription>
        </CardHeader>
        <CardContent className="space-y-4">
          <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
            <div className="space-y-2">
              <Label htmlFor="timezone">Timezone</Label>
              <Select 
                value={settings.timezone} 
                onValueChange={(value) => handleInputChange('timezone', value)}
              >
                <SelectTrigger>
                  <SelectValue />
                </SelectTrigger>
                <SelectContent>
                  {timezones.map((tz) => (
                    <SelectItem key={tz} value={tz}>
                      {tz}
                    </SelectItem>
                  ))}
                </SelectContent>
              </Select>
            </div>
            
            <div className="space-y-2">
              <Label htmlFor="currency">Default Currency</Label>
              <Select 
                value={settings.currency} 
                onValueChange={(value) => handleInputChange('currency', value)}
              >
                <SelectTrigger>
                  <SelectValue />
                </SelectTrigger>
                <SelectContent>
                  {currencies.map((currency) => (
                    <SelectItem key={currency} value={currency}>
                      {currency}
                    </SelectItem>
                  ))}
                </SelectContent>
              </Select>
            </div>
          </div>
          
          <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
            <div className="space-y-2">
              <Label htmlFor="weightUnit">Weight Unit</Label>
              <Select 
                value={settings.weightUnit} 
                onValueChange={(value) => handleInputChange('weightUnit', value)}
              >
                <SelectTrigger>
                  <SelectValue />
                </SelectTrigger>
                <SelectContent>
                  <SelectItem value="kg">Kilograms (kg)</SelectItem>
                  <SelectItem value="lb">Pounds (lb)</SelectItem>
                </SelectContent>
              </Select>
            </div>
            
            <div className="space-y-2">
              <Label htmlFor="dimensionUnit">Dimension Unit</Label>
              <Select 
                value={settings.dimensionUnit} 
                onValueChange={(value) => handleInputChange('dimensionUnit', value)}
              >
                <SelectTrigger>
                  <SelectValue />
                </SelectTrigger>
                <SelectContent>
                  <SelectItem value="cm">Centimeters (cm)</SelectItem>
                  <SelectItem value="in">Inches (in)</SelectItem>
                </SelectContent>
              </Select>
            </div>
          </div>
        </CardContent>
      </Card>

      {/* Store Features */}
      <Card>
        <CardHeader>
          <div className="flex items-center gap-2">
            <Check className="h-5 w-5" />
            <CardTitle>Store Features</CardTitle>
          </div>
          <CardDescription>
            Enable or disable various features for your customers
          </CardDescription>
        </CardHeader>
        <CardContent className="space-y-4">
          <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
            {Object.entries(settings.features).map(([key, value]) => (
              <div key={key} className="flex items-center justify-between">
                <div className="space-y-1">
                  <Label className="capitalize">{key.replace(/([A-Z])/g, ' $1')}</Label>
                  <p className="text-sm text-muted-foreground">
                    {getFeatureDescription(key)}
                  </p>
                </div>
                <Switch
                  checked={value}
                  onCheckedChange={(checked) => handleInputChange(`features.${key}`, checked)}
                />
              </div>
            ))}
          </div>
        </CardContent>
      </Card>
    </div>
  );
}

function getFeatureDescription(feature: string): string {
  const descriptions: Record<string, string> = {
    guestCheckout: 'Allow customers to checkout without creating an account',
    accountCreation: 'Enable customer account registration',
    productReviews: 'Allow customers to leave product reviews',
    wishlist: 'Enable customer wishlists',
    compareProducts: 'Allow product comparison feature',
    multiCurrency: 'Support multiple currencies',
    multiLanguage: 'Support multiple languages'
  };
  
  return descriptions[feature] || '';
}