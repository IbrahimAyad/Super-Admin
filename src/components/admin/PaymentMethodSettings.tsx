import React, { useState } from 'react';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { Badge } from '@/components/ui/badge';
import { Input } from '@/components/ui/input';
import { Label } from '@/components/ui/label';
import { Switch } from '@/components/ui/switch';
import { Tabs, TabsContent, TabsList, TabsTrigger } from '@/components/ui/tabs';
import { CreditCard, Smartphone, Banknote, Settings, Shield, TrendingUp } from 'lucide-react';
import { toast } from 'sonner';

export function PaymentMethodSettings() {
  const [stripeEnabled, setStripeEnabled] = useState(true);
  const [paypalEnabled, setPaypalEnabled] = useState(true);
  const [applePayEnabled, setApplePayEnabled] = useState(false);
  const [googlePayEnabled, setGooglePayEnabled] = useState(false);

  // Mock data - replace with real data
  const paymentStats = {
    stripe: { volume: 89450.23, transactions: 342, fees: 2589.47 },
    paypal: { volume: 23460.89, transactions: 89, fees: 689.23 },
    applePay: { volume: 15670.45, transactions: 67, fees: 453.21 },
    googlePay: { volume: 8930.12, transactions: 34, fees: 258.47 }
  };

  const savePaymentSettings = async () => {
    try {
      // Mock API call - replace with actual settings save
      await new Promise(resolve => setTimeout(resolve, 1000));
      toast.success('Payment settings saved successfully');
    } catch (error) {
      toast.error('Failed to save payment settings');
    }
  };

  return (
    <div className="space-y-6">
      {/* Header */}
      <div className="flex items-center justify-between">
        <div>
          <h3 className="text-2xl font-bold">Payment Method Settings</h3>
          <p className="text-muted-foreground">Configure payment methods and processing</p>
        </div>
        <Button onClick={savePaymentSettings}>
          Save Settings
        </Button>
      </div>

      <Tabs defaultValue="methods" className="space-y-6">
        <TabsList>
          <TabsTrigger value="methods">Payment Methods</TabsTrigger>
          <TabsTrigger value="fees">Fees & Analytics</TabsTrigger>
          <TabsTrigger value="security">Security Settings</TabsTrigger>
        </TabsList>

        <TabsContent value="methods" className="space-y-6">
          {/* Payment Methods Grid */}
          <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
            {/* Stripe */}
            <Card>
              <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
                <div className="flex items-center gap-2">
                  <CreditCard className="h-5 w-5" />
                  <CardTitle className="text-base">Stripe</CardTitle>
                </div>
                <Switch
                  checked={stripeEnabled}
                  onCheckedChange={setStripeEnabled}
                />
              </CardHeader>
              <CardContent className="space-y-4">
                <div className="grid grid-cols-2 gap-4 text-sm">
                  <div>
                    <span className="text-muted-foreground">Volume (30d)</span>
                    <div className="font-medium">${paymentStats.stripe.volume.toLocaleString()}</div>
                  </div>
                  <div>
                    <span className="text-muted-foreground">Transactions</span>
                    <div className="font-medium">{paymentStats.stripe.transactions}</div>
                  </div>
                </div>
                <div className="space-y-2">
                  <Label htmlFor="stripe-key">Publishable Key</Label>
                  <Input
                    id="stripe-key"
                    type="password"
                    defaultValue="pk_test_..."
                    disabled={!stripeEnabled}
                  />
                </div>
                <div className="space-y-2">
                  <Label htmlFor="stripe-secret">Secret Key</Label>
                  <Input
                    id="stripe-secret"
                    type="password"
                    defaultValue="sk_test_..."
                    disabled={!stripeEnabled}
                  />
                </div>
                <Badge variant="outline" className="text-green-600">
                  Active • 2.9% + $0.30
                </Badge>
              </CardContent>
            </Card>

            {/* PayPal */}
            <Card>
              <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
                <div className="flex items-center gap-2">
                  <Banknote className="h-5 w-5" />
                  <CardTitle className="text-base">PayPal</CardTitle>
                </div>
                <Switch
                  checked={paypalEnabled}
                  onCheckedChange={setPaypalEnabled}
                />
              </CardHeader>
              <CardContent className="space-y-4">
                <div className="grid grid-cols-2 gap-4 text-sm">
                  <div>
                    <span className="text-muted-foreground">Volume (30d)</span>
                    <div className="font-medium">${paymentStats.paypal.volume.toLocaleString()}</div>
                  </div>
                  <div>
                    <span className="text-muted-foreground">Transactions</span>
                    <div className="font-medium">{paymentStats.paypal.transactions}</div>
                  </div>
                </div>
                <div className="space-y-2">
                  <Label htmlFor="paypal-client">Client ID</Label>
                  <Input
                    id="paypal-client"
                    type="password"
                    defaultValue="AY..."
                    disabled={!paypalEnabled}
                  />
                </div>
                <div className="space-y-2">
                  <Label htmlFor="paypal-secret">Client Secret</Label>
                  <Input
                    id="paypal-secret"
                    type="password"
                    defaultValue="EH..."
                    disabled={!paypalEnabled}
                  />
                </div>
                <Badge variant="outline" className="text-blue-600">
                  Active • 2.9% + $0.49
                </Badge>
              </CardContent>
            </Card>

            {/* Apple Pay */}
            <Card>
              <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
                <div className="flex items-center gap-2">
                  <Smartphone className="h-5 w-5" />
                  <CardTitle className="text-base">Apple Pay</CardTitle>
                </div>
                <Switch
                  checked={applePayEnabled}
                  onCheckedChange={setApplePayEnabled}
                />
              </CardHeader>
              <CardContent className="space-y-4">
                <div className="grid grid-cols-2 gap-4 text-sm">
                  <div>
                    <span className="text-muted-foreground">Volume (30d)</span>
                    <div className="font-medium">${paymentStats.applePay.volume.toLocaleString()}</div>
                  </div>
                  <div>
                    <span className="text-muted-foreground">Transactions</span>
                    <div className="font-medium">{paymentStats.applePay.transactions}</div>
                  </div>
                </div>
                <div className="text-sm text-muted-foreground">
                  Requires domain verification and SSL certificate
                </div>
                <Button variant="outline" size="sm" disabled={!applePayEnabled}>
                  Configure Domain
                </Button>
                <Badge variant={applePayEnabled ? "outline" : "secondary"}>
                  {applePayEnabled ? "Active" : "Inactive"} • Via Stripe
                </Badge>
              </CardContent>
            </Card>

            {/* Google Pay */}
            <Card>
              <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
                <div className="flex items-center gap-2">
                  <Smartphone className="h-5 w-5" />
                  <CardTitle className="text-base">Google Pay</CardTitle>
                </div>
                <Switch
                  checked={googlePayEnabled}
                  onCheckedChange={setGooglePayEnabled}
                />
              </CardHeader>
              <CardContent className="space-y-4">
                <div className="grid grid-cols-2 gap-4 text-sm">
                  <div>
                    <span className="text-muted-foreground">Volume (30d)</span>
                    <div className="font-medium">${paymentStats.googlePay.volume.toLocaleString()}</div>
                  </div>
                  <div>
                    <span className="text-muted-foreground">Transactions</span>
                    <div className="font-medium">{paymentStats.googlePay.transactions}</div>
                  </div>
                </div>
                <div className="space-y-2">
                  <Label htmlFor="google-merchant">Merchant ID</Label>
                  <Input
                    id="google-merchant"
                    placeholder="merchant.your-domain.com"
                    disabled={!googlePayEnabled}
                  />
                </div>
                <Badge variant={googlePayEnabled ? "outline" : "secondary"}>
                  {googlePayEnabled ? "Active" : "Inactive"} • Via Stripe
                </Badge>
              </CardContent>
            </Card>
          </div>
        </TabsContent>

        <TabsContent value="fees" className="space-y-6">
          {/* Fee Analytics */}
          <div className="grid grid-cols-1 md:grid-cols-4 gap-4">
            <Card>
              <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
                <CardTitle className="text-sm font-medium">Total Fees (30d)</CardTitle>
                <TrendingUp className="h-4 w-4 text-muted-foreground" />
              </CardHeader>
              <CardContent>
                <div className="text-2xl font-bold">
                  ${Object.values(paymentStats).reduce((sum, stat) => sum + stat.fees, 0).toLocaleString()}
                </div>
                <p className="text-xs text-muted-foreground">Average 2.9% of volume</p>
              </CardContent>
            </Card>

            <Card>
              <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
                <CardTitle className="text-sm font-medium">Stripe Fees</CardTitle>
                <CreditCard className="h-4 w-4 text-muted-foreground" />
              </CardHeader>
              <CardContent>
                <div className="text-2xl font-bold">${paymentStats.stripe.fees.toLocaleString()}</div>
                <p className="text-xs text-muted-foreground">2.9% + $0.30 per transaction</p>
              </CardContent>
            </Card>

            <Card>
              <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
                <CardTitle className="text-sm font-medium">PayPal Fees</CardTitle>
                <Banknote className="h-4 w-4 text-muted-foreground" />
              </CardHeader>
              <CardContent>
                <div className="text-2xl font-bold">${paymentStats.paypal.fees.toLocaleString()}</div>
                <p className="text-xs text-muted-foreground">2.9% + $0.49 per transaction</p>
              </CardContent>
            </Card>

            <Card>
              <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
                <CardTitle className="text-sm font-medium">Mobile Wallets</CardTitle>
                <Smartphone className="h-4 w-4 text-muted-foreground" />
              </CardHeader>
              <CardContent>
                <div className="text-2xl font-bold">
                  ${(paymentStats.applePay.fees + paymentStats.googlePay.fees).toLocaleString()}
                </div>
                <p className="text-xs text-muted-foreground">Same as card rates</p>
              </CardContent>
            </Card>
          </div>

          {/* Fee Breakdown Table */}
          <Card>
            <CardHeader>
              <CardTitle>Fee Breakdown by Method</CardTitle>
              <CardDescription>Detailed analysis of payment processing costs</CardDescription>
            </CardHeader>
            <CardContent>
              <div className="space-y-4">
                {Object.entries(paymentStats).map(([method, stats]) => (
                  <div key={method} className="flex items-center justify-between p-4 border rounded-lg">
                    <div className="flex items-center gap-3">
                      <div className="capitalize font-medium">{method}</div>
                      <Badge variant="outline">{stats.transactions} transactions</Badge>
                    </div>
                    <div className="text-right">
                      <div className="font-medium">${stats.fees.toLocaleString()}</div>
                      <div className="text-sm text-muted-foreground">
                        {((stats.fees / stats.volume) * 100).toFixed(2)}% effective rate
                      </div>
                    </div>
                  </div>
                ))}
              </div>
            </CardContent>
          </Card>
        </TabsContent>

        <TabsContent value="security" className="space-y-6">
          {/* Security Settings */}
          <Card>
            <CardHeader>
              <CardTitle className="flex items-center gap-2">
                <Shield className="h-5 w-5" />
                Payment Security
              </CardTitle>
              <CardDescription>Configure security settings for payment processing</CardDescription>
            </CardHeader>
            <CardContent className="space-y-6">
              <div className="flex items-center justify-between">
                <div className="space-y-0.5">
                  <Label className="text-base">Require CVV Verification</Label>
                  <div className="text-sm text-muted-foreground">
                    Always require CVV code for card payments
                  </div>
                </div>
                <Switch defaultChecked />
              </div>

              <div className="flex items-center justify-between">
                <div className="space-y-0.5">
                  <Label className="text-base">Address Verification (AVS)</Label>
                  <div className="text-sm text-muted-foreground">
                    Verify billing address matches card information
                  </div>
                </div>
                <Switch defaultChecked />
              </div>

              <div className="flex items-center justify-between">
                <div className="space-y-0.5">
                  <Label className="text-base">3D Secure Authentication</Label>
                  <div className="text-sm text-muted-foreground">
                    Require additional authentication for high-risk transactions
                  </div>
                </div>
                <Switch />
              </div>

              <div className="flex items-center justify-between">
                <div className="space-y-0.5">
                  <Label className="text-base">Fraud Detection</Label>
                  <div className="text-sm text-muted-foreground">
                    Automatically flag suspicious transactions
                  </div>
                </div>
                <Switch defaultChecked />
              </div>

              <div className="space-y-2">
                <Label htmlFor="risk-threshold">Risk Score Threshold</Label>
                <Input
                  id="risk-threshold"
                  type="number"
                  min="1"
                  max="100"
                  defaultValue="75"
                  placeholder="75"
                />
                <p className="text-xs text-muted-foreground">
                  Transactions above this risk score will be flagged for review
                </p>
              </div>
            </CardContent>
          </Card>
        </TabsContent>
      </Tabs>
    </div>
  );
}