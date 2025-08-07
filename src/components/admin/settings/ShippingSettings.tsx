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
import { Table, TableBody, TableCell, TableHead, TableHeader, TableRow } from '@/components/ui/table';
import { Dialog, DialogContent, DialogDescription, DialogFooter, DialogHeader, DialogTitle, DialogTrigger } from '@/components/ui/dialog';
import { useToast } from '@/hooks/use-toast';
import { 
  Truck, 
  Plus, 
  Edit2, 
  Trash2, 
  Globe, 
  Package, 
  Clock, 
  DollarSign,
  MapPin,
  AlertCircle,
  Settings,
  Calculator,
  Zap
} from 'lucide-react';

interface ShippingZone {
  id: string;
  name: string;
  regions: string[];
  methods: ShippingMethod[];
  enabled: boolean;
}

interface ShippingMethod {
  id: string;
  name: string;
  description: string;
  type: 'flat_rate' | 'weight_based' | 'free' | 'calculated' | 'pickup';
  rate: number;
  minOrderAmount?: number;
  maxWeight?: number;
  estimatedDays: {
    min: number;
    max: number;
  };
  enabled: boolean;
  conditions?: {
    minOrder?: number;
    maxWeight?: number;
    weightRanges?: WeightRange[];
  };
}

interface WeightRange {
  minWeight: number;
  maxWeight: number;
  rate: number;
}

interface ShippingProvider {
  id: string;
  name: string;
  type: 'ups' | 'fedex' | 'dhl' | 'usps' | 'custom';
  enabled: boolean;
  credentials: Record<string, string>;
  services: string[];
}

interface ShippingSettingsData {
  // General Settings
  general: {
    defaultWeightUnit: 'kg' | 'lb';
    defaultDimensionUnit: 'cm' | 'in';
    packageOrigin: {
      country: string;
      state: string;
      city: string;
      postalCode: string;
    };
    handlingTime: number;
    cutoffTime: string;
  };
  
  // Shipping Zones
  zones: ShippingZone[];
  
  // Shipping Providers
  providers: ShippingProvider[];
  
  // Packaging
  packaging: {
    defaultPackage: {
      length: number;
      width: number;
      height: number;
      weight: number;
    };
    customPackages: Array<{
      id: string;
      name: string;
      dimensions: { length: number; width: number; height: number };
      maxWeight: number;
    }>;
  };
  
  // Free Shipping
  freeShipping: {
    enabled: boolean;
    threshold: number;
    zones: string[];
    methods: string[];
  };
  
  // Restrictions
  restrictions: {
    countries: {
      allowed: string[];
      blocked: string[];
    };
    weightLimits: {
      min: number;
      max: number;
    };
    dimensionLimits: {
      maxLength: number;
      maxWidth: number;
      maxHeight: number;
    };
  };
  
  // Rate Calculation
  calculation: {
    showRates: boolean;
    sortBy: 'price' | 'speed' | 'name';
    hideZeroRates: boolean;
    roundingRules: {
      enabled: boolean;
      rule: 'up' | 'down' | 'nearest';
      precision: number;
    };
  };
}

const defaultSettings: ShippingSettingsData = {
  general: {
    defaultWeightUnit: 'lb',
    defaultDimensionUnit: 'in',
    packageOrigin: {
      country: 'United States',
      state: 'NY',
      city: 'New York',
      postalCode: '10001'
    },
    handlingTime: 1,
    cutoffTime: '15:00'
  },
  zones: [
    {
      id: 'domestic',
      name: 'Domestic',
      regions: ['United States'],
      enabled: true,
      methods: [
        {
          id: 'standard',
          name: 'Standard Shipping',
          description: 'Standard ground shipping',
          type: 'flat_rate',
          rate: 9.99,
          estimatedDays: { min: 3, max: 7 },
          enabled: true
        },
        {
          id: 'express',
          name: 'Express Shipping',
          description: 'Next day delivery',
          type: 'flat_rate',
          rate: 24.99,
          estimatedDays: { min: 1, max: 2 },
          enabled: true
        }
      ]
    },
    {
      id: 'international',
      name: 'International',
      regions: ['Canada', 'United Kingdom', 'Australia'],
      enabled: true,
      methods: [
        {
          id: 'intl_standard',
          name: 'International Standard',
          description: 'International ground shipping',
          type: 'flat_rate',
          rate: 29.99,
          estimatedDays: { min: 7, max: 14 },
          enabled: true
        }
      ]
    }
  ],
  providers: [],
  packaging: {
    defaultPackage: {
      length: 12,
      width: 12,
      height: 6,
      weight: 1
    },
    customPackages: []
  },
  freeShipping: {
    enabled: true,
    threshold: 100,
    zones: ['domestic'],
    methods: ['standard']
  },
  restrictions: {
    countries: {
      allowed: [],
      blocked: []
    },
    weightLimits: {
      min: 0,
      max: 150
    },
    dimensionLimits: {
      maxLength: 48,
      maxWidth: 48,
      maxHeight: 48
    }
  },
  calculation: {
    showRates: true,
    sortBy: 'price',
    hideZeroRates: false,
    roundingRules: {
      enabled: false,
      rule: 'up',
      precision: 2
    }
  }
};

const availableCountries = [
  'United States', 'Canada', 'United Kingdom', 'Australia', 'Germany',
  'France', 'Italy', 'Spain', 'Netherlands', 'Belgium', 'Switzerland',
  'Sweden', 'Norway', 'Denmark', 'Finland', 'Japan', 'South Korea',
  'Singapore', 'Hong Kong', 'New Zealand', 'Brazil', 'Mexico'
];

const shippingProviders = [
  { id: 'ups', name: 'UPS', services: ['Ground', 'Next Day Air', '2nd Day Air'] },
  { id: 'fedex', name: 'FedEx', services: ['Ground', 'Express', 'Priority'] },
  { id: 'dhl', name: 'DHL', services: ['Express', 'Economy'] },
  { id: 'usps', name: 'USPS', services: ['Priority Mail', 'Express Mail', 'Ground Advantage'] }
];

interface ShippingSettingsProps {
  onSettingsChange: () => void;
}

export function ShippingSettings({ onSettingsChange }: ShippingSettingsProps) {
  const [settings, setSettings] = useState<ShippingSettingsData>(defaultSettings);
  const [isLoading, setIsLoading] = useState(false);
  const [editingZone, setEditingZone] = useState<ShippingZone | null>(null);
  const [editingMethod, setEditingMethod] = useState<ShippingMethod | null>(null);
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
        description: "Unable to load shipping settings. Using defaults.",
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

  const addShippingZone = () => {
    const newZone: ShippingZone = {
      id: `zone_${Date.now()}`,
      name: 'New Shipping Zone',
      regions: [],
      methods: [],
      enabled: true
    };
    
    handleInputChange('zones', [...settings.zones, newZone]);
    setEditingZone(newZone);
  };

  const updateZone = (zoneId: string, updates: Partial<ShippingZone>) => {
    const updatedZones = settings.zones.map(zone =>
      zone.id === zoneId ? { ...zone, ...updates } : zone
    );
    handleInputChange('zones', updatedZones);
  };

  const removeZone = (zoneId: string) => {
    const updatedZones = settings.zones.filter(zone => zone.id !== zoneId);
    handleInputChange('zones', updatedZones);
  };

  const addShippingMethod = (zoneId: string) => {
    const newMethod: ShippingMethod = {
      id: `method_${Date.now()}`,
      name: 'New Shipping Method',
      description: '',
      type: 'flat_rate',
      rate: 0,
      estimatedDays: { min: 1, max: 3 },
      enabled: true
    };

    const updatedZones = settings.zones.map(zone => {
      if (zone.id === zoneId) {
        return { ...zone, methods: [...zone.methods, newMethod] };
      }
      return zone;
    });

    handleInputChange('zones', updatedZones);
    setEditingMethod(newMethod);
  };

  const updateMethod = (zoneId: string, methodId: string, updates: Partial<ShippingMethod>) => {
    const updatedZones = settings.zones.map(zone => {
      if (zone.id === zoneId) {
        const updatedMethods = zone.methods.map(method =>
          method.id === methodId ? { ...method, ...updates } : method
        );
        return { ...zone, methods: updatedMethods };
      }
      return zone;
    });
    
    handleInputChange('zones', updatedZones);
  };

  const removeMethod = (zoneId: string, methodId: string) => {
    const updatedZones = settings.zones.map(zone => {
      if (zone.id === zoneId) {
        const updatedMethods = zone.methods.filter(method => method.id !== methodId);
        return { ...zone, methods: updatedMethods };
      }
      return zone;
    });
    
    handleInputChange('zones', updatedZones);
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
      {/* General Settings */}
      <Card>
        <CardHeader>
          <div className="flex items-center gap-2">
            <Settings className="h-5 w-5" />
            <CardTitle>General Settings</CardTitle>
          </div>
          <CardDescription>
            Basic shipping configuration and origin settings
          </CardDescription>
        </CardHeader>
        <CardContent className="space-y-4">
          <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
            <div className="space-y-2">
              <Label>Weight Unit</Label>
              <Select 
                value={settings.general.defaultWeightUnit} 
                onValueChange={(value) => handleInputChange('general.defaultWeightUnit', value)}
              >
                <SelectTrigger>
                  <SelectValue />
                </SelectTrigger>
                <SelectContent>
                  <SelectItem value="lb">Pounds (lb)</SelectItem>
                  <SelectItem value="kg">Kilograms (kg)</SelectItem>
                </SelectContent>
              </Select>
            </div>
            
            <div className="space-y-2">
              <Label>Dimension Unit</Label>
              <Select 
                value={settings.general.defaultDimensionUnit} 
                onValueChange={(value) => handleInputChange('general.defaultDimensionUnit', value)}
              >
                <SelectTrigger>
                  <SelectValue />
                </SelectTrigger>
                <SelectContent>
                  <SelectItem value="in">Inches (in)</SelectItem>
                  <SelectItem value="cm">Centimeters (cm)</SelectItem>
                </SelectContent>
              </Select>
            </div>
          </div>

          <Separator />

          <div className="space-y-4">
            <h4 className="font-medium">Package Origin Address</h4>
            <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
              <div className="space-y-2">
                <Label>Country</Label>
                <Select 
                  value={settings.general.packageOrigin.country} 
                  onValueChange={(value) => handleInputChange('general.packageOrigin.country', value)}
                >
                  <SelectTrigger>
                    <SelectValue />
                  </SelectTrigger>
                  <SelectContent>
                    {availableCountries.map((country) => (
                      <SelectItem key={country} value={country}>
                        {country}
                      </SelectItem>
                    ))}
                  </SelectContent>
                </Select>
              </div>
              
              <div className="space-y-2">
                <Label>State/Province</Label>
                <Input
                  value={settings.general.packageOrigin.state}
                  onChange={(e) => handleInputChange('general.packageOrigin.state', e.target.value)}
                />
              </div>
            </div>
            
            <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
              <div className="space-y-2">
                <Label>City</Label>
                <Input
                  value={settings.general.packageOrigin.city}
                  onChange={(e) => handleInputChange('general.packageOrigin.city', e.target.value)}
                />
              </div>
              
              <div className="space-y-2">
                <Label>Postal Code</Label>
                <Input
                  value={settings.general.packageOrigin.postalCode}
                  onChange={(e) => handleInputChange('general.packageOrigin.postalCode', e.target.value)}
                />
              </div>
            </div>
          </div>

          <Separator />

          <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
            <div className="space-y-2">
              <Label>Handling Time (days)</Label>
              <Input
                type="number"
                min="0"
                max="30"
                value={settings.general.handlingTime}
                onChange={(e) => handleInputChange('general.handlingTime', parseInt(e.target.value) || 0)}
              />
              <p className="text-xs text-muted-foreground">
                Time to prepare orders before shipping
              </p>
            </div>
            
            <div className="space-y-2">
              <Label>Cutoff Time</Label>
              <Input
                type="time"
                value={settings.general.cutoffTime}
                onChange={(e) => handleInputChange('general.cutoffTime', e.target.value)}
              />
              <p className="text-xs text-muted-foreground">
                Orders after this time ship the next day
              </p>
            </div>
          </div>
        </CardContent>
      </Card>

      {/* Shipping Zones */}
      <Card>
        <CardHeader>
          <div className="flex items-center justify-between">
            <div className="flex items-center gap-2">
              <Globe className="h-5 w-5" />
              <div>
                <CardTitle>Shipping Zones</CardTitle>
                <CardDescription>
                  Configure shipping zones and their methods
                </CardDescription>
              </div>
            </div>
            <Button onClick={addShippingZone} size="sm">
              <Plus className="h-4 w-4 mr-2" />
              Add Zone
            </Button>
          </div>
        </CardHeader>
        <CardContent>
          <div className="space-y-4">
            {settings.zones.map((zone) => (
              <Card key={zone.id} className={zone.enabled ? 'border-primary/20' : 'border-muted'}>
                <CardHeader className="pb-3">
                  <div className="flex items-center justify-between">
                    <div className="flex items-center gap-3">
                      <Switch
                        checked={zone.enabled}
                        onCheckedChange={(enabled) => updateZone(zone.id, { enabled })}
                      />
                      <div>
                        <h4 className="font-semibold">{zone.name}</h4>
                        <p className="text-sm text-muted-foreground">
                          {zone.regions.join(', ') || 'No regions configured'}
                        </p>
                      </div>
                    </div>
                    <div className="flex items-center gap-2">
                      <Dialog>
                        <DialogTrigger asChild>
                          <Button variant="ghost" size="sm">
                            <Edit2 className="h-4 w-4" />
                          </Button>
                        </DialogTrigger>
                        <DialogContent className="max-w-2xl">
                          <DialogHeader>
                            <DialogTitle>Edit Shipping Zone</DialogTitle>
                            <DialogDescription>
                              Configure the zone name and regions
                            </DialogDescription>
                          </DialogHeader>
                          
                          <div className="space-y-4">
                            <div className="space-y-2">
                              <Label>Zone Name</Label>
                              <Input
                                value={zone.name}
                                onChange={(e) => updateZone(zone.id, { name: e.target.value })}
                              />
                            </div>
                            
                            <div className="space-y-2">
                              <Label>Regions</Label>
                              <Select>
                                <SelectTrigger>
                                  <SelectValue placeholder="Add regions to this zone" />
                                </SelectTrigger>
                                <SelectContent>
                                  {availableCountries.map((country) => (
                                    <SelectItem key={country} value={country}>
                                      {country}
                                    </SelectItem>
                                  ))}
                                </SelectContent>
                              </Select>
                              <div className="flex flex-wrap gap-2 mt-2">
                                {zone.regions.map((region) => (
                                  <Badge
                                    key={region}
                                    variant="secondary"
                                    className="cursor-pointer"
                                    onClick={() => {
                                      const updatedRegions = zone.regions.filter(r => r !== region);
                                      updateZone(zone.id, { regions: updatedRegions });
                                    }}
                                  >
                                    {region}
                                    <Trash2 className="h-3 w-3 ml-1" />
                                  </Badge>
                                ))}
                              </div>
                            </div>
                          </div>
                        </DialogContent>
                      </Dialog>
                      
                      <Button
                        variant="ghost"
                        size="sm"
                        onClick={() => removeZone(zone.id)}
                        className="text-destructive hover:text-destructive"
                      >
                        <Trash2 className="h-4 w-4" />
                      </Button>
                    </div>
                  </div>
                </CardHeader>
                
                {zone.enabled && (
                  <CardContent>
                    <div className="space-y-4">
                      <div className="flex items-center justify-between">
                        <h5 className="font-medium">Shipping Methods</h5>
                        <Button 
                          variant="outline" 
                          size="sm"
                          onClick={() => addShippingMethod(zone.id)}
                        >
                          <Plus className="h-4 w-4 mr-2" />
                          Add Method
                        </Button>
                      </div>
                      
                      {zone.methods.length > 0 ? (
                        <Table>
                          <TableHeader>
                            <TableRow>
                              <TableHead className="w-12"></TableHead>
                              <TableHead>Method</TableHead>
                              <TableHead>Type</TableHead>
                              <TableHead>Rate</TableHead>
                              <TableHead>Delivery Time</TableHead>
                              <TableHead className="w-20">Actions</TableHead>
                            </TableRow>
                          </TableHeader>
                          <TableBody>
                            {zone.methods.map((method) => (
                              <TableRow key={method.id}>
                                <TableCell>
                                  <Switch
                                    checked={method.enabled}
                                    onCheckedChange={(enabled) => 
                                      updateMethod(zone.id, method.id, { enabled })
                                    }
                                  />
                                </TableCell>
                                <TableCell>
                                  <div>
                                    <div className="font-medium">{method.name}</div>
                                    <div className="text-sm text-muted-foreground">
                                      {method.description}
                                    </div>
                                  </div>
                                </TableCell>
                                <TableCell>
                                  <Badge variant="outline">
                                    {method.type.replace('_', ' ')}
                                  </Badge>
                                </TableCell>
                                <TableCell>
                                  ${method.rate.toFixed(2)}
                                </TableCell>
                                <TableCell>
                                  {method.estimatedDays.min}-{method.estimatedDays.max} days
                                </TableCell>
                                <TableCell>
                                  <div className="flex items-center gap-1">
                                    <Button variant="ghost" size="sm">
                                      <Edit2 className="h-3 w-3" />
                                    </Button>
                                    <Button
                                      variant="ghost"
                                      size="sm"
                                      onClick={() => removeMethod(zone.id, method.id)}
                                      className="text-destructive hover:text-destructive"
                                    >
                                      <Trash2 className="h-3 w-3" />
                                    </Button>
                                  </div>
                                </TableCell>
                              </TableRow>
                            ))}
                          </TableBody>
                        </Table>
                      ) : (
                        <div className="text-center py-8 text-muted-foreground">
                          <Package className="h-8 w-8 mx-auto mb-2 opacity-50" />
                          <p>No shipping methods configured</p>
                          <p className="text-sm">Add a shipping method to get started</p>
                        </div>
                      )}
                    </div>
                  </CardContent>
                )}
              </Card>
            ))}
            
            {settings.zones.length === 0 && (
              <div className="text-center py-8 text-muted-foreground">
                <Globe className="h-8 w-8 mx-auto mb-2 opacity-50" />
                <p>No shipping zones configured</p>
                <p className="text-sm">Add a shipping zone to get started</p>
              </div>
            )}
          </div>
        </CardContent>
      </Card>

      {/* Free Shipping */}
      <Card>
        <CardHeader>
          <div className="flex items-center gap-2">
            <Package className="h-5 w-5" />
            <CardTitle>Free Shipping</CardTitle>
          </div>
          <CardDescription>
            Configure free shipping offers and thresholds
          </CardDescription>
        </CardHeader>
        <CardContent className="space-y-4">
          <div className="flex items-center gap-2">
            <Switch
              checked={settings.freeShipping.enabled}
              onCheckedChange={(enabled) => handleInputChange('freeShipping.enabled', enabled)}
            />
            <Label>Enable free shipping</Label>
          </div>
          
          {settings.freeShipping.enabled && (
            <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
              <div className="space-y-2">
                <Label>Minimum Order Amount</Label>
                <div className="relative">
                  <DollarSign className="absolute left-3 top-1/2 transform -translate-y-1/2 h-4 w-4 text-muted-foreground" />
                  <Input
                    type="number"
                    min="0"
                    step="0.01"
                    className="pl-9"
                    value={settings.freeShipping.threshold}
                    onChange={(e) => handleInputChange('freeShipping.threshold', parseFloat(e.target.value) || 0)}
                  />
                </div>
                <p className="text-xs text-muted-foreground">
                  Orders above this amount qualify for free shipping
                </p>
              </div>
            </div>
          )}
        </CardContent>
      </Card>

      {/* Rate Calculation */}
      <Card>
        <CardHeader>
          <div className="flex items-center gap-2">
            <Calculator className="h-5 w-5" />
            <CardTitle>Rate Calculation</CardTitle>
          </div>
          <CardDescription>
            Configure how shipping rates are calculated and displayed
          </CardDescription>
        </CardHeader>
        <CardContent className="space-y-4">
          <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
            <div className="space-y-2">
              <Label>Sort Rates By</Label>
              <Select 
                value={settings.calculation.sortBy} 
                onValueChange={(value) => handleInputChange('calculation.sortBy', value)}
              >
                <SelectTrigger>
                  <SelectValue />
                </SelectTrigger>
                <SelectContent>
                  <SelectItem value="price">Price (Low to High)</SelectItem>
                  <SelectItem value="speed">Speed (Fast to Slow)</SelectItem>
                  <SelectItem value="name">Name (A to Z)</SelectItem>
                </SelectContent>
              </Select>
            </div>
          </div>
          
          <div className="space-y-4">
            <div className="flex items-center gap-2">
              <Switch
                checked={settings.calculation.showRates}
                onCheckedChange={(checked) => handleInputChange('calculation.showRates', checked)}
              />
              <Label>Show shipping rates during checkout</Label>
            </div>
            
            <div className="flex items-center gap-2">
              <Switch
                checked={settings.calculation.hideZeroRates}
                onCheckedChange={(checked) => handleInputChange('calculation.hideZeroRates', checked)}
              />
              <Label>Hide zero-cost shipping options</Label>
            </div>
            
            <div className="flex items-center gap-2">
              <Switch
                checked={settings.calculation.roundingRules.enabled}
                onCheckedChange={(checked) => handleInputChange('calculation.roundingRules.enabled', checked)}
              />
              <Label>Enable rate rounding</Label>
            </div>
          </div>
        </CardContent>
      </Card>
    </div>
  );
}