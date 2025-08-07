import React, { useState } from 'react';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { Badge } from '@/components/ui/badge';
import { Input } from '@/components/ui/input';
import { Label } from '@/components/ui/label';
import { Textarea } from '@/components/ui/textarea';
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from '@/components/ui/select';
import { Dialog, DialogContent, DialogDescription, DialogFooter, DialogHeader, DialogTitle } from '@/components/ui/dialog';
import { Table, TableBody, TableCell, TableHead, TableHeader, TableRow } from '@/components/ui/table';
import { RefreshCw, Check, X, DollarSign, AlertCircle } from 'lucide-react';
import { toast } from 'sonner';

export function RefundProcessor() {
  const [selectedRefund, setSelectedRefund] = useState<any>(null);
  const [showRefundDialog, setShowRefundDialog] = useState(false);
  const [refundAmount, setRefundAmount] = useState('');
  const [refundReason, setRefundReason] = useState('');

  // Mock data - replace with real data
  const pendingRefunds = [
    {
      id: 'rf_001',
      orderId: 'ord_12345',
      customer: 'John Smith',
      amount: 299.99,
      originalAmount: 299.99,
      reason: 'Item not as described',
      status: 'pending',
      requestDate: '2025-08-06',
      paymentMethod: 'Stripe'
    },
    {
      id: 'rf_002',
      orderId: 'ord_12346',
      customer: 'Sarah Johnson',
      amount: 149.50,
      originalAmount: 299.00,
      reason: 'Partial return - size issue',
      status: 'pending',
      requestDate: '2025-08-05',
      paymentMethod: 'PayPal'
    }
  ];

  const handleApproveRefund = (refund: any) => {
    setSelectedRefund(refund);
    setRefundAmount(refund.amount.toString());
    setShowRefundDialog(true);
  };

  const processRefund = async () => {
    try {
      // Mock API call - replace with actual refund processing
      await new Promise(resolve => setTimeout(resolve, 2000));
      
      toast.success(`Refund of $${refundAmount} processed successfully`);
      setShowRefundDialog(false);
      setSelectedRefund(null);
    } catch (error) {
      toast.error('Failed to process refund');
    }
  };

  return (
    <div className="space-y-6">
      {/* Header */}
      <div className="flex items-center justify-between">
        <div>
          <h3 className="text-2xl font-bold">Refund Processing</h3>
          <p className="text-muted-foreground">Manage refund requests and processing</p>
        </div>
        <Button variant="outline">
          <RefreshCw className="h-4 w-4 mr-2" />
          Refresh
        </Button>
      </div>

      {/* Summary Cards */}
      <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
        <Card>
          <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
            <CardTitle className="text-sm font-medium">Pending Refunds</CardTitle>
            <AlertCircle className="h-4 w-4 text-yellow-600" />
          </CardHeader>
          <CardContent>
            <div className="text-2xl font-bold">{pendingRefunds.length}</div>
            <p className="text-xs text-muted-foreground">Awaiting approval</p>
          </CardContent>
        </Card>

        <Card>
          <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
            <CardTitle className="text-sm font-medium">Total Amount</CardTitle>
            <DollarSign className="h-4 w-4 text-muted-foreground" />
          </CardHeader>
          <CardContent>
            <div className="text-2xl font-bold">
              ${pendingRefunds.reduce((sum, r) => sum + r.amount, 0).toLocaleString()}
            </div>
            <p className="text-xs text-muted-foreground">Pending refund value</p>
          </CardContent>
        </Card>

        <Card>
          <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
            <CardTitle className="text-sm font-medium">Today's Refunds</CardTitle>
            <RefreshCw className="h-4 w-4 text-muted-foreground" />
          </CardHeader>
          <CardContent>
            <div className="text-2xl font-bold">5</div>
            <p className="text-xs text-muted-foreground">Processed today</p>
          </CardContent>
        </Card>
      </div>

      {/* Pending Refunds Table */}
      <Card>
        <CardHeader>
          <CardTitle>Pending Refund Requests</CardTitle>
          <CardDescription>Review and process customer refund requests</CardDescription>
        </CardHeader>
        <CardContent>
          <Table>
            <TableHeader>
              <TableRow>
                <TableHead>Order ID</TableHead>
                <TableHead>Customer</TableHead>
                <TableHead>Amount</TableHead>
                <TableHead>Reason</TableHead>
                <TableHead>Date</TableHead>
                <TableHead>Payment Method</TableHead>
                <TableHead>Actions</TableHead>
              </TableRow>
            </TableHeader>
            <TableBody>
              {pendingRefunds.map((refund) => (
                <TableRow key={refund.id}>
                  <TableCell className="font-medium">{refund.orderId}</TableCell>
                  <TableCell>{refund.customer}</TableCell>
                  <TableCell>
                    <div>
                      <div className="font-medium">${refund.amount}</div>
                      {refund.amount < refund.originalAmount && (
                        <div className="text-sm text-muted-foreground">
                          of ${refund.originalAmount}
                        </div>
                      )}
                    </div>
                  </TableCell>
                  <TableCell>
                    <div className="max-w-32 truncate" title={refund.reason}>
                      {refund.reason}
                    </div>
                  </TableCell>
                  <TableCell>{refund.requestDate}</TableCell>
                  <TableCell>
                    <Badge variant="outline">{refund.paymentMethod}</Badge>
                  </TableCell>
                  <TableCell>
                    <div className="flex items-center gap-2">
                      <Button
                        size="sm"
                        variant="outline"
                        onClick={() => handleApproveRefund(refund)}
                      >
                        <Check className="h-4 w-4" />
                      </Button>
                      <Button
                        size="sm"
                        variant="outline"
                        onClick={() => toast.info('Refund rejected')}
                      >
                        <X className="h-4 w-4" />
                      </Button>
                    </div>
                  </TableCell>
                </TableRow>
              ))}
            </TableBody>
          </Table>
        </CardContent>
      </Card>

      {/* Refund Processing Dialog */}
      <Dialog open={showRefundDialog} onOpenChange={setShowRefundDialog}>
        <DialogContent className="max-w-md">
          <DialogHeader>
            <DialogTitle>Process Refund</DialogTitle>
            <DialogDescription>
              Process refund for order {selectedRefund?.orderId}
            </DialogDescription>
          </DialogHeader>

          <div className="space-y-4">
            <div>
              <Label htmlFor="refund-amount">Refund Amount</Label>
              <Input
                id="refund-amount"
                type="number"
                step="0.01"
                value={refundAmount}
                onChange={(e) => setRefundAmount(e.target.value)}
                placeholder="0.00"
              />
              <p className="text-xs text-muted-foreground mt-1">
                Max refundable: ${selectedRefund?.originalAmount}
              </p>
            </div>

            <div>
              <Label htmlFor="refund-reason">Refund Reason</Label>
              <Select value={refundReason} onValueChange={setRefundReason}>
                <SelectTrigger>
                  <SelectValue placeholder="Select reason" />
                </SelectTrigger>
                <SelectContent>
                  <SelectItem value="customer-request">Customer Request</SelectItem>
                  <SelectItem value="item-defective">Item Defective</SelectItem>
                  <SelectItem value="wrong-item">Wrong Item Sent</SelectItem>
                  <SelectItem value="damaged-shipping">Damaged in Shipping</SelectItem>
                  <SelectItem value="size-issue">Size Issue</SelectItem>
                  <SelectItem value="other">Other</SelectItem>
                </SelectContent>
              </Select>
            </div>

            <div>
              <Label htmlFor="refund-notes">Additional Notes (Optional)</Label>
              <Textarea
                id="refund-notes"
                placeholder="Add any additional notes about this refund..."
                className="min-h-[80px]"
              />
            </div>
          </div>

          <DialogFooter>
            <Button variant="outline" onClick={() => setShowRefundDialog(false)}>
              Cancel
            </Button>
            <Button onClick={processRefund}>Process Refund</Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>
    </div>
  );
}