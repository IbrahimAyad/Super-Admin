import React, { useState, useEffect } from 'react';
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
  AlertTriangle,
  Loader2
} from 'lucide-react';
import { RefundProcessor } from './RefundProcessor';
import { TaxConfiguration } from './TaxConfiguration';
import { PaymentMethodSettings } from './PaymentMethodSettings';
import { FinancialReports } from './FinancialReports';
import { getFinancialSummary, getRecentTransactions } from '@/lib/services/financialService';
import { useToast } from '@/hooks/use-toast';

export function FinancialManagement() {
  const [activeTab, setActiveTab] = useState('overview');
  const [loading, setLoading] = useState(true);
  const [financialSummary, setFinancialSummary] = useState({
    totalRevenue: 0,
    pendingRefunds: 0,
    processingFees: 0,
    taxCollected: 0,
    pendingPayouts: 0,
    refundCount: 0,
    orderCount: 0,
    averageOrderValue: 0
  });
  const [recentTransactions, setRecentTransactions] = useState<any[]>([]);
  const { toast } = useToast();

  const loadFinancialData = async () => {
    try {
      setLoading(true);
      const [summary, transactions] = await Promise.all([
        getFinancialSummary(30),
        getRecentTransactions(10)
      ]);
      
      setFinancialSummary(summary);
      setRecentTransactions(transactions);
    } catch (error) {
      console.error('Error loading financial data:', error);
      toast({
        title: 'Error',
        description: 'Failed to load financial data',
        variant: 'destructive'
      });
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    loadFinancialData();
  }, []);

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
            <div className="text-2xl font-bold">
              {loading ? (
                <Loader2 className="h-6 w-6 animate-spin" />
              ) : (
                `$${financialSummary.totalRevenue.toLocaleString('en-US', { minimumFractionDigits: 2, maximumFractionDigits: 2 })}`
              )}
            </div>
            <p className="text-xs text-muted-foreground">{financialSummary.orderCount} orders</p>
          </CardContent>
        </Card>

        <Card>
          <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
            <CardTitle className="text-sm font-medium">Pending Refunds</CardTitle>
            <RefreshCw className="h-4 w-4 text-muted-foreground" />
          </CardHeader>
          <CardContent>
            <div className="text-2xl font-bold">
              {loading ? (
                <Loader2 className="h-6 w-6 animate-spin" />
              ) : (
                `$${financialSummary.pendingRefunds.toLocaleString('en-US', { minimumFractionDigits: 2, maximumFractionDigits: 2 })}`
              )}
            </div>
            <p className="text-xs text-muted-foreground">{financialSummary.refundCount} requests pending</p>
          </CardContent>
        </Card>

        <Card>
          <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
            <CardTitle className="text-sm font-medium">Processing Fees</CardTitle>
            <CreditCard className="h-4 w-4 text-muted-foreground" />
          </CardHeader>
          <CardContent>
            <div className="text-2xl font-bold">
              {loading ? (
                <Loader2 className="h-6 w-6 animate-spin" />
              ) : (
                `$${financialSummary.processingFees.toLocaleString('en-US', { minimumFractionDigits: 2, maximumFractionDigits: 2 })}`
              )}
            </div>
            <p className="text-xs text-muted-foreground">2.9% + $0.30 per transaction</p>
          </CardContent>
        </Card>

        <Card>
          <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
            <CardTitle className="text-sm font-medium">Tax Collected</CardTitle>
            <Receipt className="h-4 w-4 text-muted-foreground" />
          </CardHeader>
          <CardContent>
            <div className="text-2xl font-bold">
              {loading ? (
                <Loader2 className="h-6 w-6 animate-spin" />
              ) : (
                `$${financialSummary.taxCollected.toLocaleString('en-US', { minimumFractionDigits: 2, maximumFractionDigits: 2 })}`
              )}
            </div>
            <p className="text-xs text-muted-foreground">8.5% estimated</p>
          </CardContent>
        </Card>

        <Card>
          <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
            <CardTitle className="text-sm font-medium">Pending Payouts</CardTitle>
            <TrendingUp className="h-4 w-4 text-muted-foreground" />
          </CardHeader>
          <CardContent>
            <div className="text-2xl font-bold">
              {loading ? (
                <Loader2 className="h-6 w-6 animate-spin" />
              ) : (
                `$${financialSummary.pendingPayouts.toLocaleString('en-US', { minimumFractionDigits: 2, maximumFractionDigits: 2 })}`
              )}
            </div>
            <p className="text-xs text-muted-foreground">After fees & refunds</p>
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
              <span className="text-sm">{financialSummary.refundCount} refund requests awaiting approval</span>
              <Button size="sm" variant="outline" onClick={() => setActiveTab('refunds')}>Review</Button>
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
              <CardHeader className="relative">
                <CardTitle>Recent Transactions</CardTitle>
                <CardDescription>Latest payment activity</CardDescription>
                <Button 
                  size="sm" 
                  variant="ghost" 
                  onClick={loadFinancialData}
                  className="absolute right-6 top-4"
                >
                  <RefreshCw className="h-4 w-4" />
                </Button>
              </CardHeader>
              <CardContent>
                <div className="space-y-4">
                  {loading ? (
                    <div className="flex justify-center py-4">
                      <Loader2 className="h-6 w-6 animate-spin" />
                    </div>
                  ) : recentTransactions.length === 0 ? (
                    <p className="text-sm text-muted-foreground text-center py-4">No transactions yet</p>
                  ) : (
                    recentTransactions.map((transaction) => (
                      <div key={transaction.id} className="flex items-center justify-between">
                        <div>
                          <p className="font-medium">{transaction.customer_name || 'Guest'}</p>
                          <p className="text-sm text-muted-foreground">
                            {transaction.order_number} • {transaction.payment_method}
                          </p>
                        </div>
                        <div className="text-right">
                          <p className="font-medium">${transaction.amount.toFixed(2)}</p>
                          <Badge 
                            variant={
                              transaction.status === 'paid' ? 'default' :
                              transaction.status === 'refunded' ? 'destructive' :
                              transaction.status === 'partially_refunded' ? 'outline' :
                              'secondary'
                            }
                          >
                            {transaction.status.replace('_', ' ')}
                          </Badge>
                        </div>
                      </div>
                    ))
                  )}
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