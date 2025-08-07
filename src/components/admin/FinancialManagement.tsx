import React, { useState } from 'react';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card';
import { Tabs, TabsContent, TabsList, TabsTrigger } from '@/components/ui/tabs';
import { Badge } from '@/components/ui/badge';
import { Button } from '@/components/ui/button';
import {
  DollarSign,
  CreditCard,
  Receipt,
  TrendingUp,
  RefreshCw,
  Settings,
  FileText,
  AlertTriangle
} from 'lucide-react';
import { RefundProcessor } from './RefundProcessor';
import { TaxConfiguration } from './TaxConfiguration';
import { PaymentMethodSettings } from './PaymentMethodSettings';
import { FinancialReports } from './FinancialReports';

export function FinancialManagement() {
  const [activeTab, setActiveTab] = useState('overview');

  // Mock data - replace with real data
  const financialSummary = {
    totalRevenue: 125680.50,
    pendingRefunds: 2340.00,
    processingFees: 3456.78,
    taxCollected: 8965.23,
    pendingPayouts: 4567.89
  };

  const recentTransactions = [
    { id: '1', amount: 299.99, status: 'completed', method: 'stripe', customer: 'John Smith' },
    { id: '2', amount: 149.50, status: 'refunded', method: 'stripe', customer: 'Sarah Johnson' },
    { id: '3', amount: 459.00, status: 'pending', method: 'paypal', customer: 'Mike Wilson' }
  ];

  return (
    <div className="space-y-6">
      {/* Header */}
      <div>
        <h2 className="text-3xl font-bold tracking-tight">Financial Management</h2>
        <p className="text-muted-foreground">
          Manage payments, refunds, taxes, and financial reporting
        </p>
      </div>

      {/* Financial Summary Cards */}
      <div className="grid grid-cols-1 md:grid-cols-5 gap-4">
        <Card>
          <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
            <CardTitle className="text-sm font-medium">Total Revenue</CardTitle>
            <DollarSign className="h-4 w-4 text-muted-foreground" />
          </CardHeader>
          <CardContent>
            <div className="text-2xl font-bold">${financialSummary.totalRevenue.toLocaleString()}</div>
            <p className="text-xs text-muted-foreground">+12% from last month</p>
          </CardContent>
        </Card>

        <Card>
          <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
            <CardTitle className="text-sm font-medium">Pending Refunds</CardTitle>
            <RefreshCw className="h-4 w-4 text-muted-foreground" />
          </CardHeader>
          <CardContent>
            <div className="text-2xl font-bold">${financialSummary.pendingRefunds.toLocaleString()}</div>
            <p className="text-xs text-muted-foreground">3 requests pending</p>
          </CardContent>
        </Card>

        <Card>
          <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
            <CardTitle className="text-sm font-medium">Processing Fees</CardTitle>
            <CreditCard className="h-4 w-4 text-muted-foreground" />
          </CardHeader>
          <CardContent>
            <div className="text-2xl font-bold">${financialSummary.processingFees.toLocaleString()}</div>
            <p className="text-xs text-muted-foreground">2.9% avg rate</p>
          </CardContent>
        </Card>

        <Card>
          <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
            <CardTitle className="text-sm font-medium">Tax Collected</CardTitle>
            <Receipt className="h-4 w-4 text-muted-foreground" />
          </CardHeader>
          <CardContent>
            <div className="text-2xl font-bold">${financialSummary.taxCollected.toLocaleString()}</div>
            <p className="text-xs text-muted-foreground">8.5% avg rate</p>
          </CardContent>
        </Card>

        <Card>
          <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
            <CardTitle className="text-sm font-medium">Pending Payouts</CardTitle>
            <TrendingUp className="h-4 w-4 text-muted-foreground" />
          </CardHeader>
          <CardContent>
            <div className="text-2xl font-bold">${financialSummary.pendingPayouts.toLocaleString()}</div>
            <p className="text-xs text-muted-foreground">Next payout in 2 days</p>
          </CardContent>
        </Card>
      </div>

      {/* Quick Actions */}
      <Card>
        <CardHeader>
          <CardTitle className="flex items-center gap-2">
            <AlertTriangle className="h-5 w-5" />
            Financial Alerts
          </CardTitle>
        </CardHeader>
        <CardContent>
          <div className="space-y-2">
            <div className="flex items-center justify-between p-2 bg-yellow-50 rounded-lg">
              <span className="text-sm">3 refund requests awaiting approval</span>
              <Button size="sm" variant="outline">Review</Button>
            </div>
            <div className="flex items-center justify-between p-2 bg-blue-50 rounded-lg">
              <span className="text-sm">Tax rates update needed for Q4</span>
              <Button size="sm" variant="outline">Configure</Button>
            </div>
            <div className="flex items-center justify-between p-2 bg-green-50 rounded-lg">
              <span className="text-sm">Reconciliation complete for yesterday</span>
              <Badge variant="secondary">Complete</Badge>
            </div>
          </div>
        </CardContent>
      </Card>

      {/* Main Content Tabs */}
      <Tabs value={activeTab} onValueChange={setActiveTab}>
        <TabsList className="grid w-full grid-cols-4">
          <TabsTrigger value="overview">Overview</TabsTrigger>
          <TabsTrigger value="refunds">Refunds</TabsTrigger>
          <TabsTrigger value="taxes">Tax Settings</TabsTrigger>
          <TabsTrigger value="payments">Payment Methods</TabsTrigger>
        </TabsList>

        <TabsContent value="overview" className="space-y-6">
          <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
            {/* Recent Transactions */}
            <Card>
              <CardHeader>
                <CardTitle>Recent Transactions</CardTitle>
                <CardDescription>Latest payment activity</CardDescription>
              </CardHeader>
              <CardContent>
                <div className="space-y-4">
                  {recentTransactions.map((transaction) => (
                    <div key={transaction.id} className="flex items-center justify-between">
                      <div>
                        <p className="font-medium">{transaction.customer}</p>
                        <p className="text-sm text-muted-foreground">{transaction.method}</p>
                      </div>
                      <div className="text-right">
                        <p className="font-medium">${transaction.amount}</p>
                        <Badge 
                          variant={
                            transaction.status === 'completed' ? 'default' :
                            transaction.status === 'refunded' ? 'destructive' : 'secondary'
                          }
                        >
                          {transaction.status}
                        </Badge>
                      </div>
                    </div>
                  ))}
                </div>
                <Button className="w-full mt-4" variant="outline">
                  View All Transactions
                </Button>
              </CardContent>
            </Card>

            {/* Financial Reports */}
            <FinancialReports />
          </div>
        </TabsContent>

        <TabsContent value="refunds">
          <RefundProcessor />
        </TabsContent>

        <TabsContent value="taxes">
          <TaxConfiguration />
        </TabsContent>

        <TabsContent value="payments">
          <PaymentMethodSettings />
        </TabsContent>
      </Tabs>
    </div>
  );
}