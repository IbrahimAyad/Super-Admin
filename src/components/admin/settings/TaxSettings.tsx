import { useState, useEffect } from 'react';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { Label } from '@/components/ui/label';
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from '@/components/ui/select';
import { Switch } from '@/components/ui/switch';
import { Badge } from '@/components/ui/badge';
import { Table, TableBody, TableCell, TableHead, TableHeader, TableRow } from '@/components/ui/table';
import { Dialog, DialogContent, DialogDescription, DialogFooter, DialogHeader, DialogTitle, DialogTrigger } from '@/components/ui/dialog';
import { useToast } from '@/hooks/use-toast';
import { 
  Calculator, 
  Plus, 
  Edit2, 
  Trash2, 
  Settings, 
  MapPin,
  AlertCircle,
  DollarSign,
  Percent
} from 'lucide-react';

interface TaxRate {
  id: string;
  name: string;
  rate: number;
  type: 'percentage' | 'fixed';
  regions: string[];
  categories: string[];
  priority: number;
  enabled: boolean;
  compound?: boolean;
}

interface TaxSettingsData {
  general: {
    taxInclusivePricing: boolean;
    displayTaxBreakdown: boolean;
    roundTaxes: boolean;
    roundingMethod: 'up' | 'down' | 'nearest';
    defaultTaxBehavior: 'exclusive' | 'inclusive';
    exemptionHandling: 'manual' | 'automatic';
  };
  
  rates: TaxRate[];
  
  exemptions: {
    customerTypes: Array<{
      id: string;
      name: string;
      type: 'business' | 'nonprofit' | 'government' | 'reseller';
      taxExempt: boolean;
    }>;
    productCategories: Array<{
      id: string;
      name: string;
      taxExempt: boolean;
    }>;
  };
  
  compliance: {
    salesTaxEnabled: boolean;
    vatEnabled: boolean;
    gstEnabled: boolean;
    taxIdRequired: boolean;
    nexusStates: string[];
    vatNumber?: string;
    businessNumber?: string;
  };
  
  reporting: {
    automaticReports: boolean;
    reportFrequency: 'monthly' | 'quarterly' | 'annually';
    emailReports: boolean;
    reportRecipients: string[];
  };
}

const defaultSettings: TaxSettingsData = {
  general: {
    taxInclusivePricing: false,
    displayTaxBreakdown: true,
    roundTaxes: true,
    roundingMethod: 'nearest',
    defaultTaxBehavior: 'exclusive',
    exemptionHandling: 'manual'
  },
  rates: [
    {
      id: 'ny_sales_tax',
      name: 'New York Sales Tax',
      rate: 8.25,
      type: 'percentage',
      regions: ['New York'],
      categories: ['all'],
      priority: 1,
      enabled: true
    }
  ],
  exemptions: {
    customerTypes: [
      { id: 'business', name: 'Business Customers', type: 'business', taxExempt: false },
      { id: 'nonprofit', name: 'Non-Profit Organizations', type: 'nonprofit', taxExempt: true }
    ],
    productCategories: [
      { id: 'clothing', name: 'Clothing', taxExempt: false },
      { id: 'accessories', name: 'Accessories', taxExempt: false }
    ]
  },
  compliance: {
    salesTaxEnabled: true,
    vatEnabled: false,
    gstEnabled: false,
    taxIdRequired: false,
    nexusStates: ['New York'],
    vatNumber: '',
    businessNumber: ''
  },
  reporting: {
    automaticReports: true,
    reportFrequency: 'monthly',
    emailReports: true,
    reportRecipients: ['admin@kctmenswear.com']
  }
};

const usStates = [
  'Alabama', 'Alaska', 'Arizona', 'Arkansas', 'California', 'Colorado', 'Connecticut',
  'Delaware', 'Florida', 'Georgia', 'Hawaii', 'Idaho', 'Illinois', 'Indiana', 'Iowa',
  'Kansas', 'Kentucky', 'Louisiana', 'Maine', 'Maryland', 'Massachusetts', 'Michigan',
  'Minnesota', 'Mississippi', 'Missouri', 'Montana', 'Nebraska', 'Nevada', 'New Hampshire',
  'New Jersey', 'New Mexico', 'New York', 'North Carolina', 'North Dakota', 'Ohio',
  'Oklahoma', 'Oregon', 'Pennsylvania', 'Rhode Island', 'South Carolina', 'South Dakota',
  'Tennessee', 'Texas', 'Utah', 'Vermont', 'Virginia', 'Washington', 'West Virginia',
  'Wisconsin', 'Wyoming'
];

interface TaxSettingsProps {
  onSettingsChange: () => void;
}

export function TaxSettings({ onSettingsChange }: TaxSettingsProps) {
  const [settings, setSettings] = useState<TaxSettingsData>(defaultSettings);
  const [isLoading, setIsLoading] = useState(false);
  const [editingRate, setEditingRate] = useState<TaxRate | null>(null);
  const [isDialogOpen, setIsDialogOpen] = useState(false);
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
        description: "Unable to load tax settings. Using defaults.",
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

  const addTaxRate = () => {
    const newRate: TaxRate = {
      id: `rate_${Date.now()}`,
      name: '',
      rate: 0,
      type: 'percentage',
      regions: [],
      categories: ['all'],
      priority: settings.rates.length + 1,
      enabled: true
    };
    setEditingRate(newRate);
    setIsDialogOpen(true);
  };

  const saveTaxRate = () => {
    if (!editingRate) return;

    const existingRateIndex = settings.rates.findIndex(rate => rate.id === editingRate.id);
    
    if (existingRateIndex >= 0) {
      const updatedRates = [...settings.rates];
      updatedRates[existingRateIndex] = editingRate;
      handleInputChange('rates', updatedRates);
    } else {
      handleInputChange('rates', [...settings.rates, editingRate]);
    }
    
    setEditingRate(null);
    setIsDialogOpen(false);
    
    toast({
      title: "Tax rate saved",
      description: "The tax rate has been saved successfully.",
    });
  };

  const removeTaxRate = (rateId: string) => {
    const updatedRates = settings.rates.filter(rate => rate.id !== rateId);
    handleInputChange('rates', updatedRates);
    
    toast({
      title: "Tax rate removed",
      description: "The tax rate has been removed.",
    });
  };

  const toggleRateEnabled = (rateId: string, enabled: boolean) => {
    const updatedRates = settings.rates.map(rate =>
      rate.id === rateId ? { ...rate, enabled } : rate
    );
    handleInputChange('rates', updatedRates);
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
      {/* General Tax Settings */}
      <Card>
        <CardHeader>
          <div className="flex items-center gap-2">
            <Settings className="h-5 w-5" />
            <CardTitle>General Tax Settings</CardTitle>
          </div>
          <CardDescription>
            Configure how taxes are calculated and displayed
          </CardDescription>
        </CardHeader>
        <CardContent className="space-y-4">
          <div className="space-y-4">
            <div className="flex items-center justify-between">
              <div className="space-y-1">
                <Label>Tax-Inclusive Pricing</Label>
                <p className="text-sm text-muted-foreground">
                  Display prices with tax included
                </p>
              </div>
              <Switch
                checked={settings.general.taxInclusivePricing}
                onCheckedChange={(checked) => handleInputChange('general.taxInclusivePricing', checked)}
              />
            </div>
            
            <div className="flex items-center justify-between">
              <div className="space-y-1">
                <Label>Display Tax Breakdown</Label>
                <p className="text-sm text-muted-foreground">
                  Show detailed tax breakdown at checkout
                </p>
              </div>
              <Switch
                checked={settings.general.displayTaxBreakdown}
                onCheckedChange={(checked) => handleInputChange('general.displayTaxBreakdown', checked)}
              />
            </div>
            
            <div className="flex items-center justify-between">
              <div className="space-y-1">
                <Label>Round Tax Amounts</Label>
                <p className="text-sm text-muted-foreground">
                  Round calculated tax amounts
                </p>
              </div>
              <Switch
                checked={settings.general.roundTaxes}
                onCheckedChange={(checked) => handleInputChange('general.roundTaxes', checked)}
              />
            </div>
          </div>
          
          {settings.general.roundTaxes && (
            <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
              <div className="space-y-2">
                <Label>Rounding Method</Label>
                <Select 
                  value={settings.general.roundingMethod} 
                  onValueChange={(value) => handleInputChange('general.roundingMethod', value)}
                >
                  <SelectTrigger>
                    <SelectValue />
                  </SelectTrigger>
                  <SelectContent>
                    <SelectItem value="up">Round Up</SelectItem>
                    <SelectItem value="down">Round Down</SelectItem>
                    <SelectItem value="nearest">Round to Nearest</SelectItem>
                  </SelectContent>
                </Select>
              </div>
              
              <div className="space-y-2">
                <Label>Default Tax Behavior</Label>
                <Select 
                  value={settings.general.defaultTaxBehavior} 
                  onValueChange={(value) => handleInputChange('general.defaultTaxBehavior', value)}
                >
                  <SelectTrigger>
                    <SelectValue />
                  </SelectTrigger>
                  <SelectContent>
                    <SelectItem value="exclusive">Tax Exclusive</SelectItem>
                    <SelectItem value="inclusive">Tax Inclusive</SelectItem>
                  </SelectContent>
                </Select>
              </div>
            </div>
          )}
        </CardContent>
      </Card>

      {/* Tax Rates */}
      <Card>
        <CardHeader>
          <div className="flex items-center justify-between">
            <div className="flex items-center gap-2">
              <Calculator className="h-5 w-5" />
              <div>
                <CardTitle>Tax Rates</CardTitle>
                <CardDescription>
                  Configure tax rates by region and product category
                </CardDescription>
              </div>
            </div>
            <Button onClick={addTaxRate} size="sm">
              <Plus className="h-4 w-4 mr-2" />
              Add Rate
            </Button>
          </div>
        </CardHeader>
        <CardContent>
          {settings.rates.length > 0 ? (
            <Table>
              <TableHeader>
                <TableRow>
                  <TableHead className="w-12"></TableHead>
                  <TableHead>Name</TableHead>
                  <TableHead>Rate</TableHead>
                  <TableHead>Type</TableHead>
                  <TableHead>Regions</TableHead>
                  <TableHead>Priority</TableHead>
                  <TableHead className="w-20">Actions</TableHead>
                </TableRow>
              </TableHeader>
              <TableBody>
                {settings.rates.map((rate) => (
                  <TableRow key={rate.id}>
                    <TableCell>
                      <Switch
                        checked={rate.enabled}
                        onCheckedChange={(checked) => toggleRateEnabled(rate.id, checked)}
                      />
                    </TableCell>
                    <TableCell>
                      <div className="font-medium">{rate.name}</div>
                    </TableCell>
                    <TableCell>
                      <div className="flex items-center gap-1">
                        {rate.type === 'percentage' ? (
                          <>
                            {rate.rate}
                            <Percent className="h-3 w-3" />
                          </>
                        ) : (
                          <>
                            <DollarSign className="h-3 w-3" />
                            {rate.rate.toFixed(2)}
                          </>
                        )}
                      </div>
                    </TableCell>
                    <TableCell>
                      <Badge variant="outline">
                        {rate.type}
                      </Badge>
                    </TableCell>
                    <TableCell>
                      <div className="flex flex-wrap gap-1">
                        {rate.regions.slice(0, 2).map((region) => (
                          <Badge key={region} variant="secondary" className="text-xs">
                            {region}
                          </Badge>
                        ))}
                        {rate.regions.length > 2 && (
                          <Badge variant="secondary" className="text-xs">
                            +{rate.regions.length - 2} more
                          </Badge>
                        )}
                      </div>
                    </TableCell>
                    <TableCell>{rate.priority}</TableCell>
                    <TableCell>
                      <div className="flex items-center gap-1">
                        <Button 
                          variant="ghost" 
                          size="sm"
                          onClick={() => {
                            setEditingRate(rate);
                            setIsDialogOpen(true);
                          }}
                        >
                          <Edit2 className="h-3 w-3" />
                        </Button>
                        <Button
                          variant="ghost"
                          size="sm"
                          onClick={() => removeTaxRate(rate.id)}
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
              <Calculator className="h-8 w-8 mx-auto mb-2 opacity-50" />
              <p>No tax rates configured</p>
              <p className="text-sm">Add a tax rate to get started</p>
            </div>
          )}
        </CardContent>
      </Card>

      {/* Compliance Settings */}
      <Card>
        <CardHeader>
          <div className="flex items-center gap-2">
            <MapPin className="h-5 w-5" />
            <CardTitle>Tax Compliance</CardTitle>
          </div>
          <CardDescription>
            Configure tax compliance and business registration details
          </CardDescription>
        </CardHeader>
        <CardContent className="space-y-4">
          <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
            <div className="flex items-center justify-between">
              <div className="space-y-1">
                <Label>Sales Tax</Label>
                <p className="text-xs text-muted-foreground">
                  US sales tax collection
                </p>
              </div>
              <Switch
                checked={settings.compliance.salesTaxEnabled}
                onCheckedChange={(checked) => handleInputChange('compliance.salesTaxEnabled', checked)}
              />
            </div>
            
            <div className="flex items-center justify-between">
              <div className="space-y-1">
                <Label>VAT</Label>
                <p className="text-xs text-muted-foreground">
                  European VAT collection
                </p>
              </div>
              <Switch
                checked={settings.compliance.vatEnabled}
                onCheckedChange={(checked) => handleInputChange('compliance.vatEnabled', checked)}
              />
            </div>
            
            <div className="flex items-center justify-between">
              <div className="space-y-1">
                <Label>GST</Label>
                <p className="text-xs text-muted-foreground">
                  Goods and Services Tax
                </p>
              </div>
              <Switch
                checked={settings.compliance.gstEnabled}
                onCheckedChange={(checked) => handleInputChange('compliance.gstEnabled', checked)}
              />
            </div>
          </div>
          
          {settings.compliance.salesTaxEnabled && (
            <div className="space-y-4">
              <div className="space-y-2">
                <Label>Nexus States</Label>
                <p className="text-sm text-muted-foreground">
                  States where you have sales tax obligations
                </p>
                <div className="flex flex-wrap gap-2">
                  {settings.compliance.nexusStates.map((state) => (
                    <Badge key={state} variant="secondary" className="cursor-pointer">
                      {state}
                      <Trash2 
                        className="h-3 w-3 ml-1" 
                        onClick={() => {
                          const updatedStates = settings.compliance.nexusStates.filter(s => s !== state);
                          handleInputChange('compliance.nexusStates', updatedStates);
                        }}
                      />
                    </Badge>
                  ))}
                  <Select
                    onValueChange={(state) => {
                      if (!settings.compliance.nexusStates.includes(state)) {
                        handleInputChange('compliance.nexusStates', [...settings.compliance.nexusStates, state]);
                      }
                    }}
                  >
                    <SelectTrigger className="w-[140px]">
                      <Plus className="h-4 w-4 mr-2" />
                      Add State
                    </SelectTrigger>
                    <SelectContent>
                      {usStates
                        .filter(state => !settings.compliance.nexusStates.includes(state))
                        .map((state) => (
                          <SelectItem key={state} value={state}>
                            {state}
                          </SelectItem>
                        ))}
                    </SelectContent>
                  </Select>
                </div>
              </div>
            </div>
          )}
          
          {settings.compliance.vatEnabled && (
            <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
              <div className="space-y-2">
                <Label>VAT Number</Label>
                <Input
                  value={settings.compliance.vatNumber || ''}
                  onChange={(e) => handleInputChange('compliance.vatNumber', e.target.value)}
                  placeholder="GB123456789"
                />
              </div>
            </div>
          )}
          
          <div className="flex items-center gap-2">
            <Switch
              checked={settings.compliance.taxIdRequired}
              onCheckedChange={(checked) => handleInputChange('compliance.taxIdRequired', checked)}
            />
            <Label>Require tax ID for business customers</Label>
          </div>
        </CardContent>
      </Card>

      {/* Tax Reporting */}
      <Card>
        <CardHeader>
          <div className="flex items-center gap-2">
            <AlertCircle className="h-5 w-5" />
            <CardTitle>Tax Reporting</CardTitle>
          </div>
          <CardDescription>
            Configure automatic tax reporting and notifications
          </CardDescription>
        </CardHeader>
        <CardContent className="space-y-4">
          <div className="flex items-center gap-2">
            <Switch
              checked={settings.reporting.automaticReports}
              onCheckedChange={(checked) => handleInputChange('reporting.automaticReports', checked)}
            />
            <Label>Enable automatic tax reports</Label>
          </div>
          
          {settings.reporting.automaticReports && (
            <div className="space-y-4">
              <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                <div className="space-y-2">
                  <Label>Report Frequency</Label>
                  <Select 
                    value={settings.reporting.reportFrequency} 
                    onValueChange={(value) => handleInputChange('reporting.reportFrequency', value)}
                  >
                    <SelectTrigger>
                      <SelectValue />
                    </SelectTrigger>
                    <SelectContent>
                      <SelectItem value="monthly">Monthly</SelectItem>
                      <SelectItem value="quarterly">Quarterly</SelectItem>
                      <SelectItem value="annually">Annually</SelectItem>
                    </SelectContent>
                  </Select>
                </div>
              </div>
              
              <div className="flex items-center gap-2">
                <Switch
                  checked={settings.reporting.emailReports}
                  onCheckedChange={(checked) => handleInputChange('reporting.emailReports', checked)}
                />
                <Label>Email reports to recipients</Label>
              </div>
              
              {settings.reporting.emailReports && (
                <div className="space-y-2">
                  <Label>Report Recipients</Label>
                  {settings.reporting.reportRecipients.map((email, index) => (
                    <div key={index} className="flex items-center gap-2">
                      <Input
                        type="email"
                        value={email}
                        onChange={(e) => {
                          const updatedRecipients = [...settings.reporting.reportRecipients];
                          updatedRecipients[index] = e.target.value;
                          handleInputChange('reporting.reportRecipients', updatedRecipients);
                        }}
                      />
                      <Button
                        variant="ghost"
                        size="sm"
                        onClick={() => {
                          const updatedRecipients = settings.reporting.reportRecipients.filter((_, i) => i !== index);
                          handleInputChange('reporting.reportRecipients', updatedRecipients);
                        }}
                        className="text-destructive hover:text-destructive"
                      >
                        <Trash2 className="h-4 w-4" />
                      </Button>
                    </div>
                  ))}
                  <Button
                    variant="outline"
                    size="sm"
                    onClick={() => {
                      handleInputChange('reporting.reportRecipients', [...settings.reporting.reportRecipients, '']);
                    }}
                  >
                    <Plus className="h-4 w-4 mr-2" />
                    Add Recipient
                  </Button>
                </div>
              )}
            </div>
          )}
        </CardContent>
      </Card>

      {/* Tax Rate Dialog */}
      <Dialog open={isDialogOpen} onOpenChange={setIsDialogOpen}>
        <DialogContent className="max-w-2xl">
          <DialogHeader>
            <DialogTitle>
              {editingRate?.name ? 'Edit Tax Rate' : 'Add Tax Rate'}
            </DialogTitle>
            <DialogDescription>
              Configure the tax rate details and applicable regions
            </DialogDescription>
          </DialogHeader>
          
          {editingRate && (
            <div className="space-y-4">
              <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                <div className="space-y-2">
                  <Label>Rate Name</Label>
                  <Input
                    value={editingRate.name}
                    onChange={(e) => setEditingRate({ ...editingRate, name: e.target.value })}
                    placeholder="e.g. California Sales Tax"
                  />
                </div>
                
                <div className="space-y-2">
                  <Label>Rate Type</Label>
                  <Select 
                    value={editingRate.type} 
                    onValueChange={(value: 'percentage' | 'fixed') => 
                      setEditingRate({ ...editingRate, type: value })
                    }
                  >
                    <SelectTrigger>
                      <SelectValue />
                    </SelectTrigger>
                    <SelectContent>
                      <SelectItem value="percentage">Percentage</SelectItem>
                      <SelectItem value="fixed">Fixed Amount</SelectItem>
                    </SelectContent>
                  </Select>
                </div>
              </div>
              
              <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                <div className="space-y-2">
                  <Label>
                    {editingRate.type === 'percentage' ? 'Tax Rate (%)' : 'Tax Amount ($)'}
                  </Label>
                  <Input
                    type="number"
                    step="0.01"
                    min="0"
                    value={editingRate.rate}
                    onChange={(e) => setEditingRate({ 
                      ...editingRate, 
                      rate: parseFloat(e.target.value) || 0 
                    })}
                  />
                </div>
                
                <div className="space-y-2">
                  <Label>Priority</Label>
                  <Input
                    type="number"
                    min="1"
                    value={editingRate.priority}
                    onChange={(e) => setEditingRate({ 
                      ...editingRate, 
                      priority: parseInt(e.target.value) || 1 
                    })}
                  />
                </div>
              </div>
              
              <div className="space-y-2">
                <Label>Applicable Regions</Label>
                <div className="flex flex-wrap gap-2 mb-2">
                  {editingRate.regions.map((region) => (
                    <Badge key={region} variant="secondary" className="cursor-pointer">
                      {region}
                      <Trash2 
                        className="h-3 w-3 ml-1" 
                        onClick={() => {
                          const updatedRegions = editingRate.regions.filter(r => r !== region);
                          setEditingRate({ ...editingRate, regions: updatedRegions });
                        }}
                      />
                    </Badge>
                  ))}
                </div>
                <Select
                  onValueChange={(region) => {
                    if (!editingRate.regions.includes(region)) {
                      setEditingRate({ 
                        ...editingRate, 
                        regions: [...editingRate.regions, region] 
                      });
                    }
                  }}
                >
                  <SelectTrigger>
                    <SelectValue placeholder="Add regions" />
                  </SelectTrigger>
                  <SelectContent>
                    {usStates
                      .filter(state => !editingRate.regions.includes(state))
                      .map((state) => (
                        <SelectItem key={state} value={state}>
                          {state}
                        </SelectItem>
                      ))}
                  </SelectContent>
                </Select>
              </div>
            </div>
          )}
          
          <DialogFooter>
            <Button variant="outline" onClick={() => setIsDialogOpen(false)}>
              Cancel
            </Button>
            <Button onClick={saveTaxRate}>
              Save Tax Rate
            </Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>
    </div>
  );
}