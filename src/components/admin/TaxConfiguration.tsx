import React, { useState } from 'react';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { Badge } from '@/components/ui/badge';
import { Input } from '@/components/ui/input';
import { Label } from '@/components/ui/label';
import { Switch } from '@/components/ui/switch';
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from '@/components/ui/select';
import { Dialog, DialogContent, DialogDescription, DialogFooter, DialogHeader, DialogTitle } from '@/components/ui/dialog';
import { Table, TableBody, TableCell, TableHead, TableHeader, TableRow } from '@/components/ui/table';
import { Plus, Edit, Trash2, Receipt, MapPin } from 'lucide-react';
import { toast } from 'sonner';

export function TaxConfiguration() {
  const [showTaxDialog, setShowTaxDialog] = useState(false);
  const [selectedTaxRate, setSelectedTaxRate] = useState<any>(null);
  const [taxInclusivePricing, setTaxInclusivePricing] = useState(false);
  
  // Form state
  const [jurisdiction, setJurisdiction] = useState('');
  const [taxRate, setTaxRate] = useState('');
  const [taxType, setTaxType] = useState('');

  // Mock data - replace with real data
  const taxRates = [
    {
      id: 'tx_001',
      jurisdiction: 'California, US',
      type: 'Sales Tax',
      rate: 8.75,
      appliesTo: 'All products',
      status: 'active',
      effectiveDate: '2024-01-01'
    },
    {
      id: 'tx_002',
      jurisdiction: 'New York, US',
      type: 'Sales Tax',
      rate: 8.25,
      appliesTo: 'Physical goods',
      status: 'active',
      effectiveDate: '2024-01-01'
    },
    {
      id: 'tx_003',
      jurisdiction: 'Ontario, CA',
      type: 'HST',
      rate: 13.0,
      appliesTo: 'All products',
      status: 'active',
      effectiveDate: '2024-01-01'
    }
  ];

  const handleAddTaxRate = () => {
    setSelectedTaxRate(null);
    setJurisdiction('');
    setTaxRate('');
    setTaxType('');
    setShowTaxDialog(true);
  };

  const handleEditTaxRate = (rate: any) => {
    setSelectedTaxRate(rate);
    setJurisdiction(rate.jurisdiction);
    setTaxRate(rate.rate.toString());
    setTaxType(rate.type);
    setShowTaxDialog(true);
  };

  const saveTaxRate = async () => {
    try {
      // Mock API call - replace with actual tax rate saving
      await new Promise(resolve => setTimeout(resolve, 1000));
      
      toast.success(selectedTaxRate ? 'Tax rate updated' : 'Tax rate added');
      setShowTaxDialog(false);
    } catch (error) {
      toast.error('Failed to save tax rate');
    }
  };

  return (
    <div className="space-y-6">
      {/* Header */}
      <div className="flex items-center justify-between">
        <div>
          <h3 className="text-2xl font-bold">Tax Configuration</h3>
          <p className="text-muted-foreground">Manage tax rates and settings</p>
        </div>
        <Button onClick={handleAddTaxRate}>
          <Plus className="h-4 w-4 mr-2" />
          Add Tax Rate
        </Button>
      </div>

      {/* Global Tax Settings */}
      <Card>
        <CardHeader>
          <CardTitle>Global Tax Settings</CardTitle>
          <CardDescription>Configure how taxes are calculated and displayed</CardDescription>
        </CardHeader>
        <CardContent className="space-y-6">
          <div className="flex items-center justify-between">
            <div className="space-y-0.5">
              <Label className="text-base">Tax-Inclusive Pricing</Label>
              <div className="text-sm text-muted-foreground">
                Display prices with tax included rather than adding tax at checkout
              </div>
            </div>
            <Switch
              checked={taxInclusivePricing}
              onCheckedChange={setTaxInclusivePricing}
            />
          </div>

          <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
            <div>
              <Label htmlFor="default-tax-behavior">Default Tax Behavior</Label>
              <Select defaultValue="origin-based">
                <SelectTrigger>
                  <SelectValue />
                </SelectTrigger>
                <SelectContent>
                  <SelectItem value="origin-based">Origin-based (Business location)</SelectItem>
                  <SelectItem value="destination-based">Destination-based (Customer location)</SelectItem>
                </SelectContent>
              </Select>
            </div>

            <div>
              <Label htmlFor="tax-calculation">Tax Calculation</Label>
              <Select defaultValue="automatic">
                <SelectTrigger>
                  <SelectValue />
                </SelectTrigger>
                <SelectContent>
                  <SelectItem value="automatic">Automatic (recommended)</SelectItem>
                  <SelectItem value="manual">Manual rates only</SelectItem>
                  <SelectItem value="third-party">Third-party service</SelectItem>
                </SelectContent>
              </Select>
            </div>
          </div>

          <div className="flex items-center justify-between p-4 border rounded-lg">
            <div className="flex items-center gap-2">
              <Receipt className="h-5 w-5 text-muted-foreground" />
              <div>
                <div className="font-medium">Tax Service Integration</div>
                <div className="text-sm text-muted-foreground">
                  Connect to TaxJar, Avalara, or other tax calculation services
                </div>
              </div>
            </div>
            <Button variant="outline">Configure</Button>
          </div>
        </CardContent>
      </Card>

      {/* Tax Rates Table */}
      <Card>
        <CardHeader>
          <CardTitle>Tax Rates by Jurisdiction</CardTitle>
          <CardDescription>Manage tax rates for different locations</CardDescription>
        </CardHeader>
        <CardContent>
          <Table>
            <TableHeader>
              <TableRow>
                <TableHead>Jurisdiction</TableHead>
                <TableHead>Tax Type</TableHead>
                <TableHead>Rate</TableHead>
                <TableHead>Applies To</TableHead>
                <TableHead>Effective Date</TableHead>
                <TableHead>Status</TableHead>
                <TableHead>Actions</TableHead>
              </TableRow>
            </TableHeader>
            <TableBody>
              {taxRates.map((rate) => (
                <TableRow key={rate.id}>
                  <TableCell>
                    <div className="flex items-center gap-2">
                      <MapPin className="h-4 w-4 text-muted-foreground" />
                      {rate.jurisdiction}
                    </div>
                  </TableCell>
                  <TableCell>{rate.type}</TableCell>
                  <TableCell className="font-medium">{rate.rate}%</TableCell>
                  <TableCell>{rate.appliesTo}</TableCell>
                  <TableCell>{rate.effectiveDate}</TableCell>
                  <TableCell>
                    <Badge variant={rate.status === 'active' ? 'default' : 'secondary'}>
                      {rate.status}
                    </Badge>
                  </TableCell>
                  <TableCell>
                    <div className="flex items-center gap-2">
                      <Button
                        size="sm"
                        variant="outline"
                        onClick={() => handleEditTaxRate(rate)}
                      >
                        <Edit className="h-4 w-4" />
                      </Button>
                      <Button
                        size="sm"
                        variant="outline"
                        onClick={() => toast.info('Tax rate deleted')}
                      >
                        <Trash2 className="h-4 w-4" />
                      </Button>
                    </div>
                  </TableCell>
                </TableRow>
              ))}
            </TableBody>
          </Table>
        </CardContent>
      </Card>

      {/* Add/Edit Tax Rate Dialog */}
      <Dialog open={showTaxDialog} onOpenChange={setShowTaxDialog}>
        <DialogContent>
          <DialogHeader>
            <DialogTitle>
              {selectedTaxRate ? 'Edit Tax Rate' : 'Add Tax Rate'}
            </DialogTitle>
            <DialogDescription>
              Configure tax rate for a specific jurisdiction
            </DialogDescription>
          </DialogHeader>

          <div className="space-y-4">
            <div>
              <Label htmlFor="jurisdiction">Jurisdiction</Label>
              <Input
                id="jurisdiction"
                value={jurisdiction}
                onChange={(e) => setJurisdiction(e.target.value)}
                placeholder="e.g., California, US"
              />
            </div>

            <div className="grid grid-cols-2 gap-4">
              <div>
                <Label htmlFor="tax-type">Tax Type</Label>
                <Select value={taxType} onValueChange={setTaxType}>
                  <SelectTrigger>
                    <SelectValue placeholder="Select type" />
                  </SelectTrigger>
                  <SelectContent>
                    <SelectItem value="sales-tax">Sales Tax</SelectItem>
                    <SelectItem value="vat">VAT</SelectItem>
                    <SelectItem value="gst">GST</SelectItem>
                    <SelectItem value="hst">HST</SelectItem>
                    <SelectItem value="excise">Excise Tax</SelectItem>
                  </SelectContent>
                </Select>
              </div>

              <div>
                <Label htmlFor="tax-rate">Tax Rate (%)</Label>
                <Input
                  id="tax-rate"
                  type="number"
                  step="0.01"
                  min="0"
                  max="100"
                  value={taxRate}
                  onChange={(e) => setTaxRate(e.target.value)}
                  placeholder="0.00"
                />
              </div>
            </div>

            <div>
              <Label htmlFor="effective-date">Effective Date</Label>
              <Input
                id="effective-date"
                type="date"
                defaultValue={new Date().toISOString().split('T')[0]}
              />
            </div>

            <div>
              <Label htmlFor="applies-to">Applies To</Label>
              <Select defaultValue="all-products">
                <SelectTrigger>
                  <SelectValue />
                </SelectTrigger>
                <SelectContent>
                  <SelectItem value="all-products">All Products</SelectItem>
                  <SelectItem value="physical-goods">Physical Goods Only</SelectItem>
                  <SelectItem value="digital-goods">Digital Goods Only</SelectItem>
                  <SelectItem value="services">Services Only</SelectItem>
                </SelectContent>
              </Select>
            </div>
          </div>

          <DialogFooter>
            <Button variant="outline" onClick={() => setShowTaxDialog(false)}>
              Cancel
            </Button>
            <Button onClick={saveTaxRate}>
              {selectedTaxRate ? 'Update' : 'Add'} Tax Rate
            </Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>
    </div>
  );
}