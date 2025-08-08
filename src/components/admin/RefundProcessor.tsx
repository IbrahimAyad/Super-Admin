import React, { useState, useEffect } from 'react';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { Badge } from '@/components/ui/badge';
import { Input } from '@/components/ui/input';
import { Label } from '@/components/ui/label';
import { Textarea } from '@/components/ui/textarea';
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from '@/components/ui/select';
import { Dialog, DialogContent, DialogDescription, DialogFooter, DialogHeader, DialogTitle } from '@/components/ui/dialog';
import { Table, TableBody, TableCell, TableHead, TableHeader, TableRow } from '@/components/ui/table';
import { RefreshCw, Check, X, DollarSign, AlertCircle, Loader2 } from 'lucide-react';
import { toast } from 'sonner';
import { 
  getPendingRefunds, 
  getRefundMetrics, 
  processRefund as processRefundAPI, 
  rejectRefund,
  type RefundRequest,
  type RefundMetrics 
} from '@/lib/services/refundService';

export function RefundProcessor() {
  const [selectedRefund, setSelectedRefund] = useState<RefundRequest | null>(null);
  const [showRefundDialog, setShowRefundDialog] = useState(false);
  const [refundAmount, setRefundAmount] = useState('');
  const [refundReason, setRefundReason] = useState('');
  const [refundNotes, setRefundNotes] = useState('');
  const [pendingRefunds, setPendingRefunds] = useState<RefundRequest[]>([]);
  const [metrics, setMetrics] = useState<RefundMetrics>({
    pending_count: 0,
    pending_amount: 0,
    today_count: 0,
    today_amount: 0,
    week_count: 0,
    week_amount: 0,
  });
  const [loading, setLoading] = useState(true);
  const [processing, setProcessing] = useState(false);

  // Load refunds and metrics on mount
  useEffect(() => {
    loadRefundData();
  }, []);

  const loadRefundData = async () => {
    setLoading(true);
    try {
      const [refunds, refundMetrics] = await Promise.all([
        getPendingRefunds(),
        getRefundMetrics(),
      ]);
      setPendingRefunds(refunds);
      setMetrics(refundMetrics);
    } catch (error) {
      console.error('Error loading refund data:', error);
      toast.error('Failed to load refund data');
    } finally {
      setLoading(false);
    }
  };

  const handleApproveRefund = (refund: RefundRequest) => {
    setSelectedRefund(refund);
    setRefundAmount(refund.amount.toString());
    setRefundReason(refund.reason);
    setRefundNotes('');
    setShowRefundDialog(true);
  };

  const handleRejectRefund = async (refund: RefundRequest) => {
    if (!confirm(`Are you sure you want to reject the refund for ${refund.customer_name}?`)) {
      return;
    }
    
    try {
      const result = await rejectRefund(refund.id, 'Rejected by admin');
      if (result.success) {
        toast.success('Refund rejected');
        loadRefundData();
      } else {
        toast.error(result.message);
      }
    } catch (error) {
      toast.error('Failed to reject refund');
    }
  };

  const processRefund = async () => {
    if (!selectedRefund) return;
    
    setProcessing(true);
    try {
      const amount = parseFloat(refundAmount);
      if (isNaN(amount) || amount <= 0) {
        toast.error('Invalid refund amount');
        return;
      }
      
      if (amount > selectedRefund.original_amount) {
        toast.error('Refund amount exceeds original amount');
        return;
      }
      
      const result = await processRefundAPI(
        selectedRefund.id,
        amount,
        refundReason,
        refundNotes
      );
      
      if (result.success) {
        toast.success(result.message);
        setShowRefundDialog(false);
        setSelectedRefund(null);
        loadRefundData();
      } else {
        toast.error(result.message);
      }
    } catch (error) {
      console.error('Error processing refund:', error);
      toast.error('Failed to process refund');
    } finally {
      setProcessing(false);
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
        <Button variant="outline" onClick={loadRefundData} disabled={loading}>
          <RefreshCw className={`h-4 w-4 mr-2 ${loading ? 'animate-spin' : ''}`} />
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
            <div className="text-2xl font-bold">{metrics.pending_count}</div>
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
              ${metrics.pending_amount.toLocaleString('en-US', { minimumFractionDigits: 2, maximumFractionDigits: 2 })}
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
            <div className="text-2xl font-bold">{metrics.today_count}</div>
            <p className="text-xs text-muted-foreground">
              ${metrics.today_amount.toFixed(2)} processed today
            </p>
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
              {loading ? (
                <TableRow>
                  <TableCell colSpan={7} className="text-center py-8">
                    <Loader2 className="h-6 w-6 animate-spin mx-auto mb-2" />
                    <p className="text-sm text-muted-foreground">Loading refunds...</p>
                  </TableCell>
                </TableRow>
              ) : pendingRefunds.length === 0 ? (
                <TableRow>
                  <TableCell colSpan={7} className="text-center py-8">
                    <p className="text-sm text-muted-foreground">No pending refunds</p>
                  </TableCell>
                </TableRow>
              ) : pendingRefunds.map((refund) => (
                <TableRow key={refund.id}>
                  <TableCell className="font-medium">{refund.order_id}</TableCell>
                  <TableCell>{refund.customer_name || refund.customer_email || 'N/A'}</TableCell>
                  <TableCell>
                    <div>
                      <div className="font-medium">${refund.amount.toFixed(2)}</div>
                      {refund.amount < refund.original_amount && (
                        <div className="text-sm text-muted-foreground">
                          of ${refund.original_amount.toFixed(2)}
                        </div>
                      )}
                    </div>
                  </TableCell>
                  <TableCell>
                    <div className="max-w-32 truncate" title={refund.reason}>
                      {refund.reason}
                    </div>
                  </TableCell>
                  <TableCell>{refund.request_date}</TableCell>
                  <TableCell>
                    <Badge variant="outline">{refund.payment_method}</Badge>
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
                        onClick={() => handleRejectRefund(refund)}
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
              Process refund for order {selectedRefund?.order_id}
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
                Max refundable: ${selectedRefund?.original_amount?.toFixed(2) || '0.00'}
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
                value={refundNotes}
                onChange={(e) => setRefundNotes(e.target.value)}
                placeholder="Add any additional notes about this refund..."
                className="min-h-[80px]"
              />
            </div>
          </div>

          <DialogFooter>
            <Button variant="outline" onClick={() => setShowRefundDialog(false)}>
              Cancel
            </Button>
            <Button onClick={processRefund} disabled={processing}>
              {processing ? (
                <><Loader2 className="h-4 w-4 mr-2 animate-spin" /> Processing...</>
              ) : (
                'Process Refund'
              )}
            </Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>
    </div>
  );
}