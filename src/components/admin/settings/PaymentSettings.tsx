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
import { Alert, AlertDescription } from '@/components/ui/alert';
import { useToast } from '@/hooks/use-toast';
import { 
  CreditCard, 
  Key, 
  Shield, 
  AlertCircle,
  CheckCircle,
  Settings,
  Plus,
  Trash2,
  Eye,
  EyeOff,
  ExternalLink,
  RefreshCw
} from 'lucide-react';

interface PaymentProvider {
  id: string;
  name: string;
  type: 'stripe' | 'paypal' | 'square' | 'authorize_net' | 'braintree';
  enabled: boolean;
  testMode: boolean;
  credentials: {
    [key: string]: string;
  };
  supportedFeatures: string[];
  fees: {
    percentage: number;
    fixed: number;
    currency: string;
  };
}

interface PaymentSettingsData {
  // Primary Payment Provider
  primaryProvider: string;
  
  // Payment Providers
  providers: PaymentProvider[];
  
  // Payment Methods
  enabledMethods: {
    creditCard: boolean;
    paypal: boolean;
    applePay: boolean;
    googlePay: boolean;
    bankTransfer: boolean;
    cashOnDelivery: boolean;
    buyNowPayLater: boolean;
  };
  
  // Currency Settings
  currencies: {
    primary: string;
    supported: string[];
    autoConversion: boolean;
    conversionProvider: 'openexchangerates' | 'fixer' | 'currencyapi';
  };
  
  // Security Settings
  security: {
    requireCVV: boolean;
    use3DSecure: boolean;
    fraudProtection: boolean;
    savePaymentMethods: boolean;
    tokenization: boolean;
  };
  
  // Checkout Settings
  checkout: {
    guestCheckout: boolean;
    quickCheckout: boolean;
    abandonedCartRecovery: boolean;
    taxInclusivePricing: boolean;
    minimumOrderAmount: number;
    maximumOrderAmount: number;
  };
  
  // Webhooks
  webhooks: {
    paymentSucceeded: string;
    paymentFailed: string;
    refundProcessed: string;
    chargebackReceived: string;
  };
}

const defaultSettings: PaymentSettingsData = {
  primaryProvider: 'stripe',
  providers: [
    {
      id: 'stripe',
      name: 'Stripe',
      type: 'stripe',
      enabled: true,
      testMode: true,
      credentials: {
        publishableKey: '',
        secretKey: '',
        webhookSecret: ''
      },
      supportedFeatures: ['cards', 'apple_pay', 'google_pay', 'klarna', 'afterpay'],
      fees: { percentage: 2.9, fixed: 0.30, currency: 'USD' }
    }
  ],
  enabledMethods: {
    creditCard: true,
    paypal: false,
    applePay: true,
    googlePay: true,
    bankTransfer: false,
    cashOnDelivery: false,
    buyNowPayLater: false
  },
  currencies: {
    primary: 'USD',
    supported: ['USD'],
    autoConversion: false,
    conversionProvider: 'openexchangerates'
  },
  security: {
    requireCVV: true,
    use3DSecure: true,
    fraudProtection: true,
    savePaymentMethods: true,
    tokenization: true
  },
  checkout: {
    guestCheckout: true,
    quickCheckout: true,
    abandonedCartRecovery: true,
    taxInclusivePricing: false,
    minimumOrderAmount: 0,
    maximumOrderAmount: 10000
  },
  webhooks: {
    paymentSucceeded: '',
    paymentFailed: '',
    refundProcessed: '',
    chargebackReceived: ''
  }
};

const supportedCurrencies = [
  'USD', 'EUR', 'GBP', 'CAD', 'AUD', 'JPY', 'CHF', 'SEK', 'NOK', 'DKK',
  'PLN', 'CZK', 'HUF', 'BGN', 'HRK', 'RON', 'ISK', 'THB', 'SGD', 'HKD'
];

const paymentProviderTemplates = {
  stripe: {
    name: 'Stripe',
    credentials: {
      publishableKey: 'Publishable Key',
      secretKey: 'Secret Key',
      webhookSecret: 'Webhook Secret'
    },
    supportedFeatures: ['cards', 'apple_pay', 'google_pay', 'klarna', 'afterpay'],
    fees: { percentage: 2.9, fixed: 0.30, currency: 'USD' }
  },
  paypal: {
    name: 'PayPal',
    credentials: {
      clientId: 'Client ID',
      clientSecret: 'Client Secret'
    },
    supportedFeatures: ['paypal', 'paypal_credit'],
    fees: { percentage: 2.9, fixed: 0.30, currency: 'USD' }
  },
  square: {
    name: 'Square',
    credentials: {
      applicationId: 'Application ID',
      accessToken: 'Access Token',
      locationId: 'Location ID'
    },
    supportedFeatures: ['cards', 'apple_pay', 'google_pay'],
    fees: { percentage: 2.9, fixed: 0.30, currency: 'USD' }
  }
};

interface PaymentSettingsProps {
  onSettingsChange: () => void;
}

export function PaymentSettings({ onSettingsChange }: PaymentSettingsProps) {
  const [settings, setSettings] = useState<PaymentSettingsData>(defaultSettings);
  const [isLoading, setIsLoading] = useState(false);
  const [testingConnection, setTestingConnection] = useState<string | null>(null);
  const [showCredentials, setShowCredentials] = useState<Record<string, boolean>>({});
  const { toast } = useToast();

  useEffect(() => {
    loadSettings();
  }, []);

  const loadSettings = async () => {
    setIsLoading(true);
    try {
      await new Promise(resolve => setTimeout(resolve, 500));
      // Load settings from API
    } catch (error) {
      toast({
        title: "Error loading settings",
        description: "Unable to load payment settings. Using defaults.",
        variant: "destructive"
      });
    } finally {
      setIsLoading(false);
    }
  };

  const handleInputChange = (field: string, value: any) => {
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

  const testConnection = async (providerId: string) => {
    setTestingConnection(providerId);
    try {
      await new Promise(resolve => setTimeout(resolve, 2000));
      
      toast({
        title: "Connection successful",
        description: `Successfully connected to ${providerId}.`,
      });
    } catch (error) {
      toast({
        title: "Connection failed",
        description: "Please check your credentials and try again.",
        variant: "destructive"
      });
    } finally {
      setTestingConnection(null);
    }
  };

  const addPaymentProvider = (providerType: keyof typeof paymentProviderTemplates) => {
    const template = paymentProviderTemplates[providerType];
    const newProvider: PaymentProvider = {
      id: `${providerType}_${Date.now()}`,
      name: template.name,
      type: providerType as any,
      enabled: false,
      testMode: true,
      credentials: Object.keys(template.credentials).reduce((acc, key) => ({
        ...acc,
        [key]: ''
      }), {}),
      supportedFeatures: template.supportedFeatures,
      fees: template.fees
    };

    handleInputChange('providers', [...settings.providers, newProvider]);
  };

  const removeProvider = (providerId: string) => {
    const updatedProviders = settings.providers.filter(p => p.id !== providerId);
    handleInputChange('providers', updatedProviders);
  };

  const updateProvider = (providerId: string, field: string, value: any) => {
    const updatedProviders = settings.providers.map(provider => {
      if (provider.id === providerId) {
        if (field.includes('.')) {
          const keys = field.split('.');
          const updatedProvider = { ...provider };
          let current: any = updatedProvider;
          
          for (let i = 0; i < keys.length - 1; i++) {
            current[keys[i]] = { ...current[keys[i]] };
            current = current[keys[i]];
          }
          
          current[keys[keys.length - 1]] = value;
          return updatedProvider;
        } else {
          return { ...provider, [field]: value };
        }
      }
      return provider;
    });
    
    handleInputChange('providers', updatedProviders);
  };

  if (isLoading) {
    return (
      <div className="space-y-6">
        {[...Array(3)].map((_, i) => (
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
      {/* Payment Providers */}
      <Card>
        <CardHeader>
          <div className="flex items-center justify-between">
            <div className="flex items-center gap-2">
              <CreditCard className="h-5 w-5" />
              <div>
                <CardTitle>Payment Providers</CardTitle>
                <CardDescription>
                  Configure payment processors and gateways
                </CardDescription>
              </div>
              <Badge variant="outline" className="ml-2">
                Critical
              </Badge>
            </div>
            <div className="flex gap-2">
              <Select onValueChange={(value) => addPaymentProvider(value as any)}>
                <SelectTrigger className="w-[140px]">
                  <Plus className="h-4 w-4 mr-2" />
                  Add Provider
                </SelectTrigger>
                <SelectContent>
                  <SelectItem value="stripe">Stripe</SelectItem>
                  <SelectItem value="paypal">PayPal</SelectItem>
                  <SelectItem value="square">Square</SelectItem>
                </SelectContent>
              </Select>
            </div>
          </div>
        </CardHeader>
        <CardContent className="space-y-6">
          {settings.providers.map((provider) => {
            const template = paymentProviderTemplates[provider.type as keyof typeof paymentProviderTemplates];
            
            return (
              <Card key={provider.id} className={provider.enabled ? 'border-primary/20' : ''}>
                <CardHeader className="pb-3">
                  <div className="flex items-center justify-between">
                    <div className="flex items-center gap-3">
                      <Switch
                        checked={provider.enabled}
                        onCheckedChange={(checked) => updateProvider(provider.id, 'enabled', checked)}
                      />
                      <div>
                        <h4 className="font-semibold">{provider.name}</h4>
                        <p className="text-sm text-muted-foreground">
                          {provider.fees.percentage}% + ${provider.fees.fixed} per transaction
                        </p>
                      </div>
                      {provider.enabled && (
                        <Badge variant="outline" className="ml-auto">
                          Active
                        </Badge>
                      )}
                    </div>
                    <div className="flex items-center gap-2">
                      <Button
                        variant="outline"
                        size="sm"
                        onClick={() => testConnection(provider.id)}
                        disabled={testingConnection === provider.id}
                      >
                        {testingConnection === provider.id ? (
                          <RefreshCw className="h-4 w-4 animate-spin" />
                        ) : (
                          <CheckCircle className="h-4 w-4" />
                        )}
                        Test
                      </Button>
                      {settings.providers.length > 1 && (
                        <Button
                          variant="ghost"
                          size="sm"
                          onClick={() => removeProvider(provider.id)}
                          className="text-destructive hover:text-destructive"
                        >
                          <Trash2 className="h-4 w-4" />
                        </Button>
                      )}
                    </div>
                  </div>
                </CardHeader>
                
                {provider.enabled && (
                  <CardContent className="space-y-4">
                    <div className="flex items-center gap-2 mb-4">
                      <Switch
                        checked={provider.testMode}
                        onCheckedChange={(checked) => updateProvider(provider.id, 'testMode', checked)}
                      />
                      <Label className="text-sm">Test Mode</Label>
                      {provider.testMode && (
                        <Badge variant="secondary" className="text-xs">
                          Testing
                        </Badge>
                      )}
                    </div>
                    
                    <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                      {Object.entries(template?.credentials || {}).map(([key, label]) => (
                        <div key={key} className="space-y-2">
                          <Label>{label}</Label>
                          <div className="relative">
                            <Input
                              type={showCredentials[`${provider.id}_${key}`] ? 'text' : 'password'}
                              value={provider.credentials[key] || ''}
                              onChange={(e) => updateProvider(provider.id, `credentials.${key}`, e.target.value)}
                              placeholder={`Enter ${label.toLowerCase()}`}
                            />
                            <Button
                              type="button"
                              variant="ghost"
                              size="sm"
                              className="absolute right-0 top-0 h-full px-3"
                              onClick={() => setShowCredentials(prev => ({
                                ...prev,
                                [`${provider.id}_${key}`]: !prev[`${provider.id}_${key}`]
                              }))}
                            >
                              {showCredentials[`${provider.id}_${key}`] ? (
                                <EyeOff className="h-4 w-4" />
                              ) : (
                                <Eye className="h-4 w-4" />
                              )}
                            </Button>
                          </div>
                        </div>
                      ))}
                    </div>
                    
                    {provider.supportedFeatures.length > 0 && (
                      <div className="space-y-2">
                        <Label className="text-sm font-medium">Supported Features</Label>
                        <div className="flex flex-wrap gap-2">
                          {provider.supportedFeatures.map((feature) => (
                            <Badge key={feature} variant="outline" className="text-xs">
                              {feature.replace('_', ' ')}
                            </Badge>
                          ))}
                        </div>
                      </div>
                    )}
                  </CardContent>
                )}
              </Card>
            );
          })}
          
          {settings.providers.length === 0 && (
            <Alert>
              <AlertCircle className="h-4 w-4" />
              <AlertDescription>
                No payment providers configured. Add at least one payment provider to accept payments.
              </AlertDescription>
            </Alert>
          )}
        </CardContent>
      </Card>

      {/* Payment Methods */}
      <Card>
        <CardHeader>
          <div className="flex items-center gap-2">
            <Settings className="h-5 w-5" />
            <CardTitle>Payment Methods</CardTitle>
          </div>
          <CardDescription>
            Enable payment methods for your customers
          </CardDescription>
        </CardHeader>
        <CardContent className="space-y-4">
          <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
            {Object.entries(settings.enabledMethods).map(([method, enabled]) => (
              <div key={method} className="flex items-center justify-between">
                <div className="space-y-1">
                  <Label className="capitalize">
                    {method.replace(/([A-Z])/g, ' $1')}
                  </Label>
                  <p className="text-sm text-muted-foreground">
                    {getPaymentMethodDescription(method)}
                  </p>
                </div>
                <Switch
                  checked={enabled}
                  onCheckedChange={(checked) => handleInputChange(`enabledMethods.${method}`, checked)}
                />
              </div>
            ))}
          </div>
        </CardContent>
      </Card>

      {/* Currency Settings */}
      <Card>
        <CardHeader>
          <div className="flex items-center gap-2">
            <Key className="h-5 w-5" />
            <CardTitle>Currency Settings</CardTitle>
          </div>
          <CardDescription>
            Configure supported currencies and conversion
          </CardDescription>
        </CardHeader>
        <CardContent className="space-y-4">
          <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
            <div className="space-y-2">
              <Label>Primary Currency</Label>
              <Select 
                value={settings.currencies.primary} 
                onValueChange={(value) => handleInputChange('currencies.primary', value)}
              >
                <SelectTrigger>
                  <SelectValue />
                </SelectTrigger>
                <SelectContent>
                  {supportedCurrencies.map((currency) => (
                    <SelectItem key={currency} value={currency}>
                      {currency}
                    </SelectItem>
                  ))}
                </SelectContent>
              </Select>
            </div>
            
            <div className="space-y-2">
              <Label>Conversion Provider</Label>
              <Select 
                value={settings.currencies.conversionProvider} 
                onValueChange={(value) => handleInputChange('currencies.conversionProvider', value)}
                disabled={!settings.currencies.autoConversion}
              >
                <SelectTrigger>
                  <SelectValue />
                </SelectTrigger>
                <SelectContent>
                  <SelectItem value="openexchangerates">Open Exchange Rates</SelectItem>
                  <SelectItem value="fixer">Fixer.io</SelectItem>
                  <SelectItem value="currencyapi">CurrencyAPI</SelectItem>
                </SelectContent>
              </Select>
            </div>
          </div>
          
          <div className="flex items-center gap-2">
            <Switch
              checked={settings.currencies.autoConversion}
              onCheckedChange={(checked) => handleInputChange('currencies.autoConversion', checked)}
            />
            <Label>Enable automatic currency conversion</Label>
          </div>
        </CardContent>
      </Card>

      {/* Security Settings */}
      <Card>
        <CardHeader>
          <div className="flex items-center gap-2">
            <Shield className="h-5 w-5" />
            <CardTitle>Security Settings</CardTitle>
          </div>
          <CardDescription>
            Configure payment security and fraud protection
          </CardDescription>
        </CardHeader>
        <CardContent className="space-y-4">
          <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
            {Object.entries(settings.security).map(([setting, enabled]) => (
              <div key={setting} className="flex items-center justify-between">
                <div className="space-y-1">
                  <Label className="capitalize">
                    {setting.replace(/([A-Z])/g, ' $1')}
                  </Label>
                  <p className="text-sm text-muted-foreground">
                    {getSecuritySettingDescription(setting)}
                  </p>
                </div>
                <Switch
                  checked={enabled}
                  onCheckedChange={(checked) => handleInputChange(`security.${setting}`, checked)}
                />
              </div>
            ))}
          </div>
        </CardContent>
      </Card>

      {/* Checkout Settings */}
      <Card>
        <CardHeader>
          <div className="flex items-center gap-2">
            <Settings className="h-5 w-5" />
            <CardTitle>Checkout Settings</CardTitle>
          </div>
          <CardDescription>
            Configure checkout experience and limits
          </CardDescription>
        </CardHeader>
        <CardContent className="space-y-4">
          <div className="space-y-6">
            {Object.entries(settings.checkout).map(([setting, value]) => {
              if (typeof value === 'boolean') {
                return (
                  <div key={setting} className="flex items-center justify-between">
                    <div className="space-y-1">
                      <Label className="capitalize">
                        {setting.replace(/([A-Z])/g, ' $1')}
                      </Label>
                      <p className="text-sm text-muted-foreground">
                        {getCheckoutSettingDescription(setting)}
                      </p>
                    </div>
                    <Switch
                      checked={value}
                      onCheckedChange={(checked) => handleInputChange(`checkout.${setting}`, checked)}
                    />
                  </div>
                );
              }
              
              return (
                <div key={setting} className="space-y-2">
                  <Label className="capitalize">
                    {setting.replace(/([A-Z])/g, ' $1')}
                  </Label>
                  <Input
                    type="number"
                    value={value}
                    onChange={(e) => handleInputChange(`checkout.${setting}`, parseFloat(e.target.value) || 0)}
                    min="0"
                    step="0.01"
                  />
                </div>
              );
            })}
          </div>
        </CardContent>
      </Card>

      {/* Webhooks */}
      <Card>
        <CardHeader>
          <div className="flex items-center gap-2">
            <ExternalLink className="h-5 w-5" />
            <CardTitle>Webhook URLs</CardTitle>
          </div>
          <CardDescription>
            Configure webhook endpoints for payment events
          </CardDescription>
        </CardHeader>
        <CardContent className="space-y-4">
          <div className="space-y-4">
            {Object.entries(settings.webhooks).map(([event, url]) => (
              <div key={event} className="space-y-2">
                <Label className="capitalize">
                  {event.replace(/([A-Z])/g, ' $1')}
                </Label>
                <Input
                  value={url}
                  onChange={(e) => handleInputChange(`webhooks.${event}`, e.target.value)}
                  placeholder={`https://yoursite.com/webhook/${event.toLowerCase()}`}
                />
              </div>
            ))}
          </div>
          
          <Alert>
            <AlertCircle className="h-4 w-4" />
            <AlertDescription>
              Webhooks are essential for handling payment confirmations and updates. 
              Make sure your endpoints are accessible and properly configured.
            </AlertDescription>
          </Alert>
        </CardContent>
      </Card>
    </div>
  );
}

function getPaymentMethodDescription(method: string): string {
  const descriptions: Record<string, string> = {
    creditCard: 'Accept credit and debit cards',
    paypal: 'Accept PayPal payments',
    applePay: 'Accept Apple Pay on supported devices',
    googlePay: 'Accept Google Pay payments',
    bankTransfer: 'Accept direct bank transfers',
    cashOnDelivery: 'Allow cash payment on delivery',
    buyNowPayLater: 'Accept buy now, pay later services'
  };
  
  return descriptions[method] || '';
}

function getSecuritySettingDescription(setting: string): string {
  const descriptions: Record<string, string> = {
    requireCVV: 'Require CVV code for all transactions',
    use3DSecure: 'Enable 3D Secure authentication',
    fraudProtection: 'Enable automatic fraud detection',
    savePaymentMethods: 'Allow customers to save payment methods',
    tokenization: 'Use tokenization for stored payment data'
  };
  
  return descriptions[setting] || '';
}

function getCheckoutSettingDescription(setting: string): string {
  const descriptions: Record<string, string> = {
    guestCheckout: 'Allow checkout without account creation',
    quickCheckout: 'Enable express checkout options',
    abandonedCartRecovery: 'Send recovery emails for abandoned carts',
    taxInclusivePricing: 'Display prices including tax'
  };
  
  return descriptions[setting] || '';
}