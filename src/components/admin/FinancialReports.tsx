import React, { useState } from 'react';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { Badge } from '@/components/ui/badge';
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from '@/components/ui/select';
import { Calendar, Download, TrendingUp, TrendingDown, DollarSign, Receipt, CreditCard, BarChart3 } from 'lucide-react';

export function FinancialReports() {
  const [dateRange, setDateRange] = useState('30d');

  // Mock data - replace with real data
  const reportData = {
    revenue: {
      current: 125680.50,
      previous: 98450.23,
      change: 27.6
    },
    transactions: {
      current: 1245,
      previous: 987,
      change: 26.1
    },
    avgOrderValue: {
      current: 299.50,
      previous: 275.80,
      change: 8.6
    },
    refundRate: {
      current: 2.1,
      previous: 2.8,
      change: -25.0
    }
  };

  const exportReport = (format: string) => {
    // Mock export - replace with actual export functionality
    console.log(`Exporting financial report as ${format}`);
  };

  return (
    <Card>
      <CardHeader>
        <div className="flex items-center justify-between">
          <div>
            <CardTitle className="flex items-center gap-2">
              <BarChart3 className="h-5 w-5" />
              Financial Reports
            </CardTitle>
            <CardDescription>Revenue and transaction analytics</CardDescription>
          </div>
          <div className="flex items-center gap-2">
            <Select value={dateRange} onValueChange={setDateRange}>
              <SelectTrigger className="w-32">
                <SelectValue />
              </SelectTrigger>
              <SelectContent>
                <SelectItem value="7d">Last 7 days</SelectItem>
                <SelectItem value="30d">Last 30 days</SelectItem>
                <SelectItem value="90d">Last 90 days</SelectItem>
                <SelectItem value="1y">Last year</SelectItem>
              </SelectContent>
            </Select>
            <Button variant="outline" size="sm" onClick={() => exportReport('csv')}>
              <Download className="h-4 w-4 mr-2" />
              Export
            </Button>
          </div>
        </div>
      </CardHeader>
      <CardContent>
        <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
          {/* Revenue */}
          <div className="space-y-2">
            <div className="flex items-center justify-between">
              <span className="text-sm font-medium">Total Revenue</span>
              <Badge variant={reportData.revenue.change > 0 ? "default" : "destructive"}>
                {reportData.revenue.change > 0 ? (
                  <TrendingUp className="h-3 w-3 mr-1" />
                ) : (
                  <TrendingDown className="h-3 w-3 mr-1" />
                )}
                {Math.abs(reportData.revenue.change)}%
              </Badge>
            </div>
            <div className="text-2xl font-bold">${reportData.revenue.current.toLocaleString()}</div>
            <div className="text-xs text-muted-foreground">
              Previous period: ${reportData.revenue.previous.toLocaleString()}
            </div>
          </div>

          {/* Transactions */}
          <div className="space-y-2">
            <div className="flex items-center justify-between">
              <span className="text-sm font-medium">Transactions</span>
              <Badge variant={reportData.transactions.change > 0 ? "default" : "destructive"}>
                {reportData.transactions.change > 0 ? (
                  <TrendingUp className="h-3 w-3 mr-1" />
                ) : (
                  <TrendingDown className="h-3 w-3 mr-1" />
                )}
                {Math.abs(reportData.transactions.change)}%
              </Badge>
            </div>
            <div className="text-2xl font-bold">{reportData.transactions.current.toLocaleString()}</div>
            <div className="text-xs text-muted-foreground">
              Previous period: {reportData.transactions.previous.toLocaleString()}
            </div>
          </div>

          {/* Average Order Value */}
          <div className="space-y-2">
            <div className="flex items-center justify-between">
              <span className="text-sm font-medium">Avg Order Value</span>
              <Badge variant={reportData.avgOrderValue.change > 0 ? "default" : "destructive"}>
                {reportData.avgOrderValue.change > 0 ? (
                  <TrendingUp className="h-3 w-3 mr-1" />
                ) : (
                  <TrendingDown className="h-3 w-3 mr-1" />
                )}
                {Math.abs(reportData.avgOrderValue.change)}%
              </Badge>
            </div>
            <div className="text-2xl font-bold">${reportData.avgOrderValue.current}</div>
            <div className="text-xs text-muted-foreground">
              Previous period: ${reportData.avgOrderValue.previous}
            </div>
          </div>

          {/* Refund Rate */}
          <div className="space-y-2">
            <div className="flex items-center justify-between">
              <span className="text-sm font-medium">Refund Rate</span>
              <Badge variant={reportData.refundRate.change < 0 ? "default" : "destructive"}>
                {reportData.refundRate.change < 0 ? (
                  <TrendingDown className="h-3 w-3 mr-1" />
                ) : (
                  <TrendingUp className="h-3 w-3 mr-1" />
                )}
                {Math.abs(reportData.refundRate.change)}%
              </Badge>
            </div>
            <div className="text-2xl font-bold">{reportData.refundRate.current}%</div>
            <div className="text-xs text-muted-foreground">
              Previous period: {reportData.refundRate.previous}%
            </div>
          </div>
        </div>

        {/* Quick Report Actions */}
        <div className="mt-6 pt-4 border-t space-y-2">
          <div className="text-sm font-medium">Quick Reports</div>
          <div className="grid grid-cols-2 gap-2">
            <Button variant="outline" size="sm" onClick={() => exportReport('revenue')}>
              <Receipt className="h-4 w-4 mr-2" />
              Revenue Report
            </Button>
            <Button variant="outline" size="sm" onClick={() => exportReport('transactions')}>
              <CreditCard className="h-4 w-4 mr-2" />
              Transaction Log
            </Button>
            <Button variant="outline" size="sm" onClick={() => exportReport('taxes')}>
              <Receipt className="h-4 w-4 mr-2" />
              Tax Report
            </Button>
            <Button variant="outline" size="sm" onClick={() => exportReport('fees')}>
              <DollarSign className="h-4 w-4 mr-2" />
              Fee Analysis
            </Button>
          </div>
        </div>
      </CardContent>
    </Card>
  );
}