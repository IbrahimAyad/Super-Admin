import React, { useState, useEffect, useMemo, useCallback } from 'react';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { Badge } from '@/components/ui/badge';
import { Input } from '@/components/ui/input';
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from '@/components/ui/select';
import { Dialog, DialogContent, DialogHeader, DialogTitle } from '@/components/ui/dialog';
import { Tabs, TabsContent, TabsList, TabsTrigger } from '@/components/ui/tabs';
import { Avatar, AvatarFallback } from '@/components/ui/avatar';
import { Checkbox } from '@/components/ui/checkbox';
import { 
  Users, 
  Search, 
  Filter, 
  UserCheck, 
  Crown, 
  Mail,
  Phone,
  Calendar,
  ShoppingCart,
  DollarSign,
  Eye,
  Plus,
  Download,
  Upload,
  ChevronLeft,
  ChevronRight,
  ChevronsLeft,
  ChevronsRight,
  TrendingUp,
  AlertCircle,
  RefreshCw,
  SlidersHorizontal,
  Grid3x3,
  List,
  MoreVertical,
  Edit,
  Trash2,
  Send,
  FileText,
  Tag,
  Clock,
  MapPin,
  Star
} from 'lucide-react';
import { useToast } from '@/hooks/use-toast';
import { supabase } from '@/lib/supabase-client';
import { CustomerImport } from './CustomerImport';
import { CustomerProfileView } from './CustomerProfileView';
import {
  DropdownMenu,
  DropdownMenuContent,
  DropdownMenuItem,
  DropdownMenuSeparator,
  DropdownMenuTrigger,
} from '@/components/ui/dropdown-menu';
import { cn } from '@/lib/utils';

interface Customer {
  id: string;
  email: string;
  name?: string;
  first_name?: string;
  last_name?: string;
  phone?: string;
  accepts_email_marketing?: boolean;
  accepts_sms_marketing?: boolean;
  total_spent: number;
  total_orders: number;
  customer_tier?: string;
  engagement_score?: number;
  average_order_value: number;
  repeat_customer?: boolean;
  vip_status?: boolean;
  primary_occasion?: string;
  first_purchase_date?: string;
  last_purchase_date?: string;
  days_since_last_purchase?: number;
  notes?: string;
  tags?: string;
  shipping_address?: any;
  created_at: string;
  updated_at: string;
}

type ViewMode = 'grid' | 'list';
type SortField = 'name' | 'email' | 'total_spent' | 'total_orders' | 'created_at' | 'last_purchase_date';
type SortOrder = 'asc' | 'desc';

export const CustomerManagementOptimized = React.memo(function CustomerManagementOptimized() {
  const { toast } = useToast();
  const [customers, setCustomers] = useState<Customer[]>([]);
  const [loading, setLoading] = useState(true);
  const [searchTerm, setSearchTerm] = useState('');
  const [selectedCustomers, setSelectedCustomers] = useState<Set<string>>(new Set());
  const [selectedCustomer, setSelectedCustomer] = useState<Customer | null>(null);
  const [showCreateDialog, setShowCreateDialog] = useState(false);
  const [viewMode, setViewMode] = useState<ViewMode>('list');
  const [currentPage, setCurrentPage] = useState(1);
  const [itemsPerPage, setItemsPerPage] = useState(25);
  const [sortField, setSortField] = useState<SortField>('created_at');
  const [sortOrder, setSortOrder] = useState<SortOrder>('desc');
  
  // Advanced filters
  const [filters, setFilters] = useState({
    tier: 'all',
    vipStatus: 'all',
    emailMarketing: 'all',
    dateRange: 'all',
    minSpent: '',
    maxSpent: '',
    minOrders: '',
    maxOrders: '',
    tags: '',
    occasion: 'all'
  });

  const [showFilters, setShowFilters] = useState(false);

  useEffect(() => {
    loadCustomers();
  }, []);

  const loadCustomers = async () => {
    try {
      setLoading(true);
      
      const { data, error } = await supabase
        .from('customers')
        .select('*')
        .order('created_at', { ascending: false });

      if (error) {
        console.error('Error loading customers:', error);
        toast({
          title: "Error",
          description: "Failed to load customers",
          variant: "destructive"
        });
        return;
      }

      setCustomers(data || []);
      
    } catch (error) {
      console.error('Error loading customers:', error);
      toast({
        title: "Error",
        description: "Failed to load customer data",
        variant: "destructive"
      });
    } finally {
      setLoading(false);
    }
  };

  // Advanced filtering logic
  const filteredAndSortedCustomers = useMemo(() => {
    let filtered = customers.filter(customer => {
      // Search filter
      const searchLower = searchTerm.toLowerCase();
      const matchesSearch = 
        customer.name?.toLowerCase().includes(searchLower) ||
        customer.first_name?.toLowerCase().includes(searchLower) ||
        customer.last_name?.toLowerCase().includes(searchLower) ||
        customer.email.toLowerCase().includes(searchLower) ||
        customer.phone?.includes(searchTerm) ||
        customer.tags?.toLowerCase().includes(searchLower);
      
      if (!matchesSearch) return false;

      // Tier filter
      if (filters.tier !== 'all' && customer.customer_tier !== filters.tier) return false;
      
      // VIP filter
      if (filters.vipStatus === 'yes' && !customer.vip_status) return false;
      if (filters.vipStatus === 'no' && customer.vip_status) return false;
      
      // Email marketing filter
      if (filters.emailMarketing === 'yes' && !customer.accepts_email_marketing) return false;
      if (filters.emailMarketing === 'no' && customer.accepts_email_marketing) return false;
      
      // Spent range filter
      if (filters.minSpent && customer.total_spent < parseFloat(filters.minSpent)) return false;
      if (filters.maxSpent && customer.total_spent > parseFloat(filters.maxSpent)) return false;
      
      // Orders range filter
      if (filters.minOrders && customer.total_orders < parseInt(filters.minOrders)) return false;
      if (filters.maxOrders && customer.total_orders > parseInt(filters.maxOrders)) return false;
      
      // Date range filter
      if (filters.dateRange !== 'all') {
        const lastPurchase = customer.last_purchase_date ? new Date(customer.last_purchase_date) : null;
        const now = new Date();
        const daysSince = lastPurchase ? Math.floor((now.getTime() - lastPurchase.getTime()) / (1000 * 60 * 60 * 24)) : Infinity;
        
        switch(filters.dateRange) {
          case 'week': if (daysSince > 7) return false; break;
          case 'month': if (daysSince > 30) return false; break;
          case 'quarter': if (daysSince > 90) return false; break;
          case 'year': if (daysSince > 365) return false; break;
        }
      }
      
      // Occasion filter
      if (filters.occasion !== 'all' && customer.primary_occasion !== filters.occasion) return false;
      
      return true;
    });

    // Sort
    filtered.sort((a, b) => {
      let aValue: any = a[sortField];
      let bValue: any = b[sortField];
      
      // Handle name sorting
      if (sortField === 'name') {
        aValue = a.name || `${a.first_name || ''} ${a.last_name || ''}`.trim();
        bValue = b.name || `${b.first_name || ''} ${b.last_name || ''}`.trim();
      }
      
      // Handle null/undefined values
      if (aValue == null) aValue = '';
      if (bValue == null) bValue = '';
      
      // Compare
      if (aValue < bValue) return sortOrder === 'asc' ? -1 : 1;
      if (aValue > bValue) return sortOrder === 'asc' ? 1 : -1;
      return 0;
    });

    return filtered;
  }, [customers, searchTerm, filters, sortField, sortOrder]);

  // Pagination
  const paginatedCustomers = useMemo(() => {
    const startIndex = (currentPage - 1) * itemsPerPage;
    const endIndex = startIndex + itemsPerPage;
    return filteredAndSortedCustomers.slice(startIndex, endIndex);
  }, [filteredAndSortedCustomers, currentPage, itemsPerPage]);

  const totalPages = Math.ceil(filteredAndSortedCustomers.length / itemsPerPage);

  // Customer segments for quick filtering
  const customerSegments = useMemo(() => {
    const segments = {
      all: filteredAndSortedCustomers.length,
      vip: filteredAndSortedCustomers.filter(c => c.vip_status).length,
      highValue: filteredAndSortedCustomers.filter(c => c.total_spent > 1000).length,
      frequent: filteredAndSortedCustomers.filter(c => c.total_orders > 5).length,
      recent: filteredAndSortedCustomers.filter(c => {
        if (!c.last_purchase_date) return false;
        const daysSince = Math.floor((Date.now() - new Date(c.last_purchase_date).getTime()) / (1000 * 60 * 60 * 24));
        return daysSince <= 30;
      }).length,
      atRisk: filteredAndSortedCustomers.filter(c => {
        if (!c.last_purchase_date) return false;
        const daysSince = Math.floor((Date.now() - new Date(c.last_purchase_date).getTime()) / (1000 * 60 * 60 * 24));
        return daysSince > 60 && daysSince <= 180;
      }).length,
      inactive: filteredAndSortedCustomers.filter(c => {
        if (!c.last_purchase_date) return true;
        const daysSince = Math.floor((Date.now() - new Date(c.last_purchase_date).getTime()) / (1000 * 60 * 60 * 24));
        return daysSince > 180;
      }).length,
    };
    return segments;
  }, [filteredAndSortedCustomers]);

  // Stats
  const customerStats = useMemo(() => ({
    total: customers.length,
    active: customers.filter(c => {
      if (!c.last_purchase_date) return false;
      const daysSince = Math.floor((Date.now() - new Date(c.last_purchase_date).getTime()) / (1000 * 60 * 60 * 24));
      return daysSince <= 90;
    }).length,
    newThisMonth: customers.filter(c => {
      const createdAt = new Date(c.created_at);
      const now = new Date();
      return createdAt.getMonth() === now.getMonth() && createdAt.getFullYear() === now.getFullYear();
    }).length,
    totalRevenue: customers.reduce((sum, c) => sum + (c.total_spent || 0), 0),
    avgOrderValue: customers.length > 0 
      ? customers.reduce((sum, c) => sum + (c.average_order_value || 0), 0) / customers.length 
      : 0
  }), [customers]);

  const handleSort = (field: SortField) => {
    if (sortField === field) {
      setSortOrder(sortOrder === 'asc' ? 'desc' : 'asc');
    } else {
      setSortField(field);
      setSortOrder('asc');
    }
  };

  const handleSelectAll = useCallback(() => {
    if (selectedCustomers.size === paginatedCustomers.length) {
      setSelectedCustomers(new Set());
    } else {
      setSelectedCustomers(new Set(paginatedCustomers.map(c => c.id)));
    }
  }, [selectedCustomers.size, paginatedCustomers]);

  const handleSelectCustomer = useCallback((customerId: string) => {
    const newSelection = new Set(selectedCustomers);
    if (newSelection.has(customerId)) {
      newSelection.delete(customerId);
    } else {
      newSelection.add(customerId);
    }
    setSelectedCustomers(newSelection);
  }, [selectedCustomers]);

  const handleBulkAction = async (action: string) => {
    if (selectedCustomers.size === 0) {
      toast({
        title: "No selection",
        description: "Please select customers first",
        variant: "destructive"
      });
      return;
    }

    switch(action) {
      case 'export':
        exportSelectedCustomers();
        break;
      case 'email':
        toast({
          title: "Email campaign",
          description: `Preparing email for ${selectedCustomers.size} customers...`
        });
        break;
      case 'tag':
        toast({
          title: "Add tags",
          description: `Adding tags to ${selectedCustomers.size} customers...`
        });
        break;
      case 'delete':
        if (confirm(`Delete ${selectedCustomers.size} customers?`)) {
          await deleteSelectedCustomers();
        }
        break;
    }
  };

  const exportSelectedCustomers = () => {
    const selected = customers.filter(c => selectedCustomers.has(c.id));
    const csv = [
      ['Email', 'Name', 'Phone', 'Total Spent', 'Total Orders', 'Tier', 'Created'].join(','),
      ...selected.map(c => [
        c.email,
        `${c.first_name || ''} ${c.last_name || ''}`.trim(),
        c.phone || '',
        c.total_spent,
        c.total_orders,
        c.customer_tier || '',
        new Date(c.created_at).toLocaleDateString()
      ].join(','))
    ].join('\n');
    
    const blob = new Blob([csv], { type: 'text/csv' });
    const url = URL.createObjectURL(blob);
    const a = document.createElement('a');
    a.href = url;
    a.download = `customers_export_${Date.now()}.csv`;
    a.click();
  };

  const deleteSelectedCustomers = async () => {
    try {
      const { error } = await supabase
        .from('customers')
        .delete()
        .in('id', Array.from(selectedCustomers));

      if (error) throw error;

      setCustomers(prev => prev.filter(c => !selectedCustomers.has(c.id)));
      setSelectedCustomers(new Set());
      
      toast({
        title: "Success",
        description: `Deleted ${selectedCustomers.size} customers`
      });
    } catch (error) {
      console.error('Error deleting customers:', error);
      toast({
        title: "Error",
        description: "Failed to delete customers",
        variant: "destructive"
      });
    }
  };

  const formatCurrency = (value: number) => {
    return new Intl.NumberFormat('en-US', {
      style: 'currency',
      currency: 'USD'
    }).format(value || 0);
  };

  const formatDate = (dateString?: string) => {
    if (!dateString) return 'Never';
    return new Date(dateString).toLocaleDateString('en-US', {
      year: 'numeric',
      month: 'short',
      day: 'numeric'
    });
  };

  const getInitials = (customer: Customer) => {
    const name = customer.name || `${customer.first_name || ''} ${customer.last_name || ''}`.trim();
    if (!name) return customer.email.substring(0, 2).toUpperCase();
    return name.split(' ').map(n => n[0]).join('').substring(0, 2).toUpperCase();
  };

  const getTierColor = (tier?: string) => {
    switch (tier?.toLowerCase()) {
      case 'platinum': return 'bg-purple-100 text-purple-800';
      case 'gold': return 'bg-yellow-100 text-yellow-800';
      case 'silver': return 'bg-gray-100 text-gray-800';
      case 'bronze': return 'bg-orange-100 text-orange-800';
      default: return 'bg-blue-100 text-blue-800';
    }
  };

  const getActivityStatus = (customer: Customer) => {
    if (!customer.last_purchase_date) return { label: 'New', color: 'bg-blue-100 text-blue-800' };
    
    const daysSince = customer.days_since_last_purchase || 
      Math.floor((Date.now() - new Date(customer.last_purchase_date).getTime()) / (1000 * 60 * 60 * 24));
    
    if (daysSince <= 30) return { label: 'Active', color: 'bg-green-100 text-green-800' };
    if (daysSince <= 90) return { label: 'Regular', color: 'bg-blue-100 text-blue-800' };
    if (daysSince <= 180) return { label: 'At Risk', color: 'bg-yellow-100 text-yellow-800' };
    return { label: 'Inactive', color: 'bg-red-100 text-red-800' };
  };

  if (loading) {
    return (
      <div className="space-y-6">
        <div className="h-8 bg-muted rounded w-64 animate-pulse" />
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-5 gap-4">
          {[1, 2, 3, 4, 5].map(i => (
            <div key={i} className="h-24 bg-muted rounded animate-pulse" />
          ))}
        </div>
        <div className="h-96 bg-muted rounded animate-pulse" />
      </div>
    );
  }

  return (
    <div className="space-y-6">
      {/* Header */}
      <div className="flex flex-col gap-4">
        <div className="flex justify-between items-center">
          <h2 className="text-2xl font-bold">Customer Management</h2>
          
          <div className="flex gap-2">
            <Button 
              onClick={() => setShowCreateDialog(true)}
              className="gap-2"
            >
              <Plus className="h-4 w-4" />
              Add Customer
            </Button>
            
            <CustomerImport onImportComplete={(result) => {
              toast({
                title: "Import completed",
                description: `Imported ${result.success} customers with ${result.errors} errors`,
              });
              loadCustomers();
            }} />
            
            <Button
              variant="outline"
              onClick={loadCustomers}
              className="gap-2"
            >
              <RefreshCw className="h-4 w-4" />
              Refresh
            </Button>
          </div>
        </div>

        {/* Search and Filters Bar */}
        <div className="flex flex-wrap gap-4 items-center">
          <div className="relative flex-1 max-w-md">
            <Search className="absolute left-3 top-1/2 transform -translate-y-1/2 h-4 w-4 text-muted-foreground" />
            <Input
              placeholder="Search by name, email, phone, or tags..."
              value={searchTerm}
              onChange={(e) => setSearchTerm(e.target.value)}
              className="pl-10"
            />
          </div>
          
          <Button
            variant="outline"
            onClick={() => setShowFilters(!showFilters)}
            className="gap-2"
          >
            <SlidersHorizontal className="h-4 w-4" />
            Filters
            {Object.values(filters).some(v => v !== 'all' && v !== '') && (
              <Badge className="ml-1">Active</Badge>
            )}
          </Button>
          
          <div className="flex gap-1 border rounded-lg p-1">
            <Button
              variant={viewMode === 'list' ? 'secondary' : 'ghost'}
              size="sm"
              onClick={() => setViewMode('list')}
            >
              <List className="h-4 w-4" />
            </Button>
            <Button
              variant={viewMode === 'grid' ? 'secondary' : 'ghost'}
              size="sm"
              onClick={() => setViewMode('grid')}
            >
              <Grid3x3 className="h-4 w-4" />
            </Button>
          </div>
          
          {selectedCustomers.size > 0 && (
            <DropdownMenu>
              <DropdownMenuTrigger asChild>
                <Button variant="outline" className="gap-2">
                  Bulk Actions ({selectedCustomers.size})
                </Button>
              </DropdownMenuTrigger>
              <DropdownMenuContent>
                <DropdownMenuItem onClick={() => handleBulkAction('export')}>
                  <Download className="h-4 w-4 mr-2" />
                  Export Selected
                </DropdownMenuItem>
                <DropdownMenuItem onClick={() => handleBulkAction('email')}>
                  <Mail className="h-4 w-4 mr-2" />
                  Send Email
                </DropdownMenuItem>
                <DropdownMenuItem onClick={() => handleBulkAction('tag')}>
                  <Tag className="h-4 w-4 mr-2" />
                  Add Tags
                </DropdownMenuItem>
                <DropdownMenuSeparator />
                <DropdownMenuItem 
                  onClick={() => handleBulkAction('delete')}
                  className="text-red-600"
                >
                  <Trash2 className="h-4 w-4 mr-2" />
                  Delete Selected
                </DropdownMenuItem>
              </DropdownMenuContent>
            </DropdownMenu>
          )}
        </div>

        {/* Advanced Filters */}
        {showFilters && (
          <Card>
            <CardContent className="p-4">
              <div className="grid grid-cols-2 md:grid-cols-4 lg:grid-cols-6 gap-4">
                <div>
                  <label className="text-sm font-medium mb-1 block">Tier</label>
                  <Select value={filters.tier} onValueChange={(v) => setFilters({...filters, tier: v})}>
                    <SelectTrigger>
                      <SelectValue />
                    </SelectTrigger>
                    <SelectContent>
                      <SelectItem value="all">All Tiers</SelectItem>
                      <SelectItem value="Platinum">Platinum</SelectItem>
                      <SelectItem value="Gold">Gold</SelectItem>
                      <SelectItem value="Silver">Silver</SelectItem>
                      <SelectItem value="Bronze">Bronze</SelectItem>
                    </SelectContent>
                  </Select>
                </div>
                
                <div>
                  <label className="text-sm font-medium mb-1 block">VIP Status</label>
                  <Select value={filters.vipStatus} onValueChange={(v) => setFilters({...filters, vipStatus: v})}>
                    <SelectTrigger>
                      <SelectValue />
                    </SelectTrigger>
                    <SelectContent>
                      <SelectItem value="all">All</SelectItem>
                      <SelectItem value="yes">VIP Only</SelectItem>
                      <SelectItem value="no">Non-VIP</SelectItem>
                    </SelectContent>
                  </Select>
                </div>
                
                <div>
                  <label className="text-sm font-medium mb-1 block">Last Purchase</label>
                  <Select value={filters.dateRange} onValueChange={(v) => setFilters({...filters, dateRange: v})}>
                    <SelectTrigger>
                      <SelectValue />
                    </SelectTrigger>
                    <SelectContent>
                      <SelectItem value="all">All Time</SelectItem>
                      <SelectItem value="week">Last 7 Days</SelectItem>
                      <SelectItem value="month">Last 30 Days</SelectItem>
                      <SelectItem value="quarter">Last 90 Days</SelectItem>
                      <SelectItem value="year">Last Year</SelectItem>
                    </SelectContent>
                  </Select>
                </div>
                
                <div>
                  <label className="text-sm font-medium mb-1 block">Min Spent</label>
                  <Input 
                    type="number" 
                    placeholder="0"
                    value={filters.minSpent}
                    onChange={(e) => setFilters({...filters, minSpent: e.target.value})}
                  />
                </div>
                
                <div>
                  <label className="text-sm font-medium mb-1 block">Max Spent</label>
                  <Input 
                    type="number" 
                    placeholder="∞"
                    value={filters.maxSpent}
                    onChange={(e) => setFilters({...filters, maxSpent: e.target.value})}
                  />
                </div>
                
                <div>
                  <label className="text-sm font-medium mb-1 block">Email Marketing</label>
                  <Select value={filters.emailMarketing} onValueChange={(v) => setFilters({...filters, emailMarketing: v})}>
                    <SelectTrigger>
                      <SelectValue />
                    </SelectTrigger>
                    <SelectContent>
                      <SelectItem value="all">All</SelectItem>
                      <SelectItem value="yes">Subscribed</SelectItem>
                      <SelectItem value="no">Not Subscribed</SelectItem>
                    </SelectContent>
                  </Select>
                </div>
              </div>
              
              <div className="flex justify-end mt-4 gap-2">
                <Button
                  variant="outline"
                  size="sm"
                  onClick={() => setFilters({
                    tier: 'all',
                    vipStatus: 'all',
                    emailMarketing: 'all',
                    dateRange: 'all',
                    minSpent: '',
                    maxSpent: '',
                    minOrders: '',
                    maxOrders: '',
                    tags: '',
                    occasion: 'all'
                  })}
                >
                  Clear Filters
                </Button>
              </div>
            </CardContent>
          </Card>
        )}
      </div>

      {/* Stats Cards */}
      <div className="grid grid-cols-2 md:grid-cols-3 lg:grid-cols-5 gap-4">
        <Card>
          <CardContent className="p-4">
            <div className="flex items-center gap-3">
              <Users className="h-8 w-8 text-blue-500" />
              <div>
                <p className="text-xs text-muted-foreground">Total</p>
                <p className="text-xl font-bold">{customerStats.total}</p>
              </div>
            </div>
          </CardContent>
        </Card>

        <Card>
          <CardContent className="p-4">
            <div className="flex items-center gap-3">
              <UserCheck className="h-8 w-8 text-green-500" />
              <div>
                <p className="text-xs text-muted-foreground">Active</p>
                <p className="text-xl font-bold">{customerStats.active}</p>
              </div>
            </div>
          </CardContent>
        </Card>

        <Card>
          <CardContent className="p-4">
            <div className="flex items-center gap-3">
              <TrendingUp className="h-8 w-8 text-purple-500" />
              <div>
                <p className="text-xs text-muted-foreground">New/Month</p>
                <p className="text-xl font-bold">{customerStats.newThisMonth}</p>
              </div>
            </div>
          </CardContent>
        </Card>

        <Card>
          <CardContent className="p-4">
            <div className="flex items-center gap-3">
              <DollarSign className="h-8 w-8 text-yellow-500" />
              <div>
                <p className="text-xs text-muted-foreground">Revenue</p>
                <p className="text-xl font-bold">{formatCurrency(customerStats.totalRevenue)}</p>
              </div>
            </div>
          </CardContent>
        </Card>

        <Card>
          <CardContent className="p-4">
            <div className="flex items-center gap-3">
              <ShoppingCart className="h-8 w-8 text-indigo-500" />
              <div>
                <p className="text-xs text-muted-foreground">Avg Order</p>
                <p className="text-xl font-bold">{formatCurrency(customerStats.avgOrderValue)}</p>
              </div>
            </div>
          </CardContent>
        </Card>
      </div>

      {/* Segment Pills */}
      <div className="flex flex-wrap gap-2">
        <Badge variant="outline" className="px-3 py-1">
          All ({customerSegments.all})
        </Badge>
        <Badge variant="outline" className="px-3 py-1 bg-purple-50">
          <Crown className="h-3 w-3 mr-1" />
          VIP ({customerSegments.vip})
        </Badge>
        <Badge variant="outline" className="px-3 py-1 bg-yellow-50">
          <DollarSign className="h-3 w-3 mr-1" />
          High Value ({customerSegments.highValue})
        </Badge>
        <Badge variant="outline" className="px-3 py-1 bg-blue-50">
          <ShoppingCart className="h-3 w-3 mr-1" />
          Frequent ({customerSegments.frequent})
        </Badge>
        <Badge variant="outline" className="px-3 py-1 bg-green-50">
          <Clock className="h-3 w-3 mr-1" />
          Recent ({customerSegments.recent})
        </Badge>
        <Badge variant="outline" className="px-3 py-1 bg-yellow-50">
          <AlertCircle className="h-3 w-3 mr-1" />
          At Risk ({customerSegments.atRisk})
        </Badge>
        <Badge variant="outline" className="px-3 py-1 bg-red-50">
          Inactive ({customerSegments.inactive})
        </Badge>
      </div>

      {/* Customer List/Grid */}
      <Card>
        <CardHeader className="pb-3">
          <div className="flex justify-between items-center">
            <CardTitle>
              Customers ({filteredAndSortedCustomers.length})
            </CardTitle>
            
            <div className="flex items-center gap-2 text-sm">
              <span className="text-muted-foreground">Show:</span>
              <Select value={itemsPerPage.toString()} onValueChange={(v) => setItemsPerPage(parseInt(v))}>
                <SelectTrigger className="w-20">
                  <SelectValue />
                </SelectTrigger>
                <SelectContent>
                  <SelectItem value="10">10</SelectItem>
                  <SelectItem value="25">25</SelectItem>
                  <SelectItem value="50">50</SelectItem>
                  <SelectItem value="100">100</SelectItem>
                </SelectContent>
              </Select>
            </div>
          </div>
        </CardHeader>
        
        <CardContent>
          {viewMode === 'list' ? (
            <div className="space-y-2">
              {/* List Header */}
              <div className="flex items-center gap-4 px-4 py-2 border-b text-sm font-medium text-muted-foreground">
                <Checkbox 
                  checked={selectedCustomers.size === paginatedCustomers.length && paginatedCustomers.length > 0}
                  onCheckedChange={handleSelectAll}
                />
                <div className="flex-1 grid grid-cols-12 gap-4">
                  <div 
                    className="col-span-3 flex items-center gap-1 cursor-pointer hover:text-foreground"
                    onClick={() => handleSort('name')}
                  >
                    Customer
                    {sortField === 'name' && (sortOrder === 'asc' ? '↑' : '↓')}
                  </div>
                  <div 
                    className="col-span-2 flex items-center gap-1 cursor-pointer hover:text-foreground"
                    onClick={() => handleSort('total_spent')}
                  >
                    Total Spent
                    {sortField === 'total_spent' && (sortOrder === 'asc' ? '↑' : '↓')}
                  </div>
                  <div 
                    className="col-span-2 flex items-center gap-1 cursor-pointer hover:text-foreground"
                    onClick={() => handleSort('total_orders')}
                  >
                    Orders
                    {sortField === 'total_orders' && (sortOrder === 'asc' ? '↑' : '↓')}
                  </div>
                  <div className="col-span-2">Status</div>
                  <div 
                    className="col-span-2 flex items-center gap-1 cursor-pointer hover:text-foreground"
                    onClick={() => handleSort('last_purchase_date')}
                  >
                    Last Purchase
                    {sortField === 'last_purchase_date' && (sortOrder === 'asc' ? '↑' : '↓')}
                  </div>
                  <div className="col-span-1 text-right">Actions</div>
                </div>
              </div>

              {/* List Items */}
              {paginatedCustomers.map(customer => {
                const activityStatus = getActivityStatus(customer);
                const fullName = customer.name || `${customer.first_name || ''} ${customer.last_name || ''}`.trim() || 'Unknown';
                
                return (
                  <div 
                    key={customer.id} 
                    className={cn(
                      "flex items-center gap-4 px-4 py-3 rounded-lg hover:bg-muted/50 transition-colors",
                      selectedCustomers.has(customer.id) && "bg-muted/30"
                    )}
                  >
                    <Checkbox 
                      checked={selectedCustomers.has(customer.id)}
                      onCheckedChange={() => handleSelectCustomer(customer.id)}
                    />
                    
                    <div className="flex-1 grid grid-cols-12 gap-4 items-center">
                      {/* Customer Info */}
                      <div className="col-span-3 flex items-center gap-3">
                        <Avatar className="h-10 w-10">
                          <AvatarFallback className="text-xs">
                            {getInitials(customer)}
                          </AvatarFallback>
                        </Avatar>
                        <div className="overflow-hidden">
                          <div className="flex items-center gap-2">
                            <p className="font-medium truncate">{fullName}</p>
                            {customer.vip_status && <Crown className="h-3 w-3 text-yellow-500" />}
                          </div>
                          <p className="text-sm text-muted-foreground truncate">{customer.email}</p>
                        </div>
                      </div>
                      
                      {/* Total Spent */}
                      <div className="col-span-2">
                        <p className="font-medium">{formatCurrency(customer.total_spent)}</p>
                        {customer.average_order_value > 0 && (
                          <p className="text-xs text-muted-foreground">
                            AOV: {formatCurrency(customer.average_order_value)}
                          </p>
                        )}
                      </div>
                      
                      {/* Orders */}
                      <div className="col-span-2">
                        <p className="font-medium">{customer.total_orders}</p>
                        {customer.repeat_customer && (
                          <Badge variant="outline" className="text-xs">Repeat</Badge>
                        )}
                      </div>
                      
                      {/* Status */}
                      <div className="col-span-2 flex flex-col gap-1">
                        <Badge className={cn("text-xs w-fit", getTierColor(customer.customer_tier))}>
                          {customer.customer_tier || 'Regular'}
                        </Badge>
                        <Badge className={cn("text-xs w-fit", activityStatus.color)}>
                          {activityStatus.label}
                        </Badge>
                      </div>
                      
                      {/* Last Purchase */}
                      <div className="col-span-2">
                        <p className="text-sm">{formatDate(customer.last_purchase_date)}</p>
                        {customer.days_since_last_purchase != null && (
                          <p className="text-xs text-muted-foreground">
                            {customer.days_since_last_purchase}d ago
                          </p>
                        )}
                      </div>
                      
                      {/* Actions */}
                      <div className="col-span-1 flex justify-end">
                        <DropdownMenu>
                          <DropdownMenuTrigger asChild>
                            <Button variant="ghost" size="sm">
                              <MoreVertical className="h-4 w-4" />
                            </Button>
                          </DropdownMenuTrigger>
                          <DropdownMenuContent align="end">
                            <DropdownMenuItem onClick={() => setSelectedCustomer(customer)}>
                              <Eye className="h-4 w-4 mr-2" />
                              View Details
                            </DropdownMenuItem>
                            <DropdownMenuItem>
                              <Edit className="h-4 w-4 mr-2" />
                              Edit
                            </DropdownMenuItem>
                            <DropdownMenuItem>
                              <Mail className="h-4 w-4 mr-2" />
                              Send Email
                            </DropdownMenuItem>
                            <DropdownMenuItem>
                              <FileText className="h-4 w-4 mr-2" />
                              View Orders
                            </DropdownMenuItem>
                            <DropdownMenuSeparator />
                            <DropdownMenuItem className="text-red-600">
                              <Trash2 className="h-4 w-4 mr-2" />
                              Delete
                            </DropdownMenuItem>
                          </DropdownMenuContent>
                        </DropdownMenu>
                      </div>
                    </div>
                  </div>
                );
              })}
            </div>
          ) : (
            // Grid View
            <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4 gap-4">
              {paginatedCustomers.map(customer => {
                const activityStatus = getActivityStatus(customer);
                const fullName = customer.name || `${customer.first_name || ''} ${customer.last_name || ''}`.trim() || 'Unknown';
                
                return (
                  <Card 
                    key={customer.id}
                    className={cn(
                      "relative hover:shadow-lg transition-shadow cursor-pointer",
                      selectedCustomers.has(customer.id) && "ring-2 ring-primary"
                    )}
                    onClick={() => setSelectedCustomer(customer)}
                  >
                    <div className="absolute top-2 right-2">
                      <Checkbox 
                        checked={selectedCustomers.has(customer.id)}
                        onCheckedChange={(e) => {
                          e.stopPropagation();
                          handleSelectCustomer(customer.id);
                        }}
                        onClick={(e) => e.stopPropagation()}
                      />
                    </div>
                    
                    <CardContent className="p-4">
                      <div className="flex flex-col items-center text-center space-y-3">
                        <Avatar className="h-16 w-16">
                          <AvatarFallback className="text-lg">
                            {getInitials(customer)}
                          </AvatarFallback>
                        </Avatar>
                        
                        <div>
                          <div className="flex items-center justify-center gap-2">
                            <p className="font-medium">{fullName}</p>
                            {customer.vip_status && <Crown className="h-4 w-4 text-yellow-500" />}
                          </div>
                          <p className="text-sm text-muted-foreground">{customer.email}</p>
                          {customer.phone && (
                            <p className="text-xs text-muted-foreground">{customer.phone}</p>
                          )}
                        </div>
                        
                        <div className="flex gap-2">
                          <Badge className={cn("text-xs", getTierColor(customer.customer_tier))}>
                            {customer.customer_tier || 'Regular'}
                          </Badge>
                          <Badge className={cn("text-xs", activityStatus.color)}>
                            {activityStatus.label}
                          </Badge>
                        </div>
                        
                        <div className="grid grid-cols-2 gap-4 w-full pt-2 border-t">
                          <div>
                            <p className="text-xs text-muted-foreground">Total Spent</p>
                            <p className="font-medium">{formatCurrency(customer.total_spent)}</p>
                          </div>
                          <div>
                            <p className="text-xs text-muted-foreground">Orders</p>
                            <p className="font-medium">{customer.total_orders}</p>
                          </div>
                        </div>
                        
                        <div className="flex gap-2 w-full">
                          {customer.accepts_email_marketing && (
                            <Badge variant="outline" className="text-xs flex-1">
                              <Mail className="h-3 w-3 mr-1" />
                              Email
                            </Badge>
                          )}
                          {customer.accepts_sms_marketing && (
                            <Badge variant="outline" className="text-xs flex-1">
                              <Phone className="h-3 w-3 mr-1" />
                              SMS
                            </Badge>
                          )}
                        </div>
                      </div>
                    </CardContent>
                  </Card>
                );
              })}
            </div>
          )}

          {filteredAndSortedCustomers.length === 0 && (
            <div className="text-center py-12 text-muted-foreground">
              <Users className="h-12 w-12 mx-auto mb-4 opacity-50" />
              <p className="text-lg">No customers found</p>
              <p className="text-sm">Try adjusting your search or filters</p>
            </div>
          )}
        </CardContent>

        {/* Pagination */}
        {totalPages > 1 && (
          <div className="border-t p-4">
            <div className="flex items-center justify-between">
              <p className="text-sm text-muted-foreground">
                Showing {((currentPage - 1) * itemsPerPage) + 1} to {Math.min(currentPage * itemsPerPage, filteredAndSortedCustomers.length)} of {filteredAndSortedCustomers.length} customers
              </p>
              
              <div className="flex items-center gap-2">
                <Button
                  variant="outline"
                  size="sm"
                  onClick={() => setCurrentPage(1)}
                  disabled={currentPage === 1}
                >
                  <ChevronsLeft className="h-4 w-4" />
                </Button>
                <Button
                  variant="outline"
                  size="sm"
                  onClick={() => setCurrentPage(prev => Math.max(1, prev - 1))}
                  disabled={currentPage === 1}
                >
                  <ChevronLeft className="h-4 w-4" />
                </Button>
                
                <div className="flex items-center gap-1">
                  {Array.from({ length: Math.min(5, totalPages) }, (_, i) => {
                    let pageNum;
                    if (totalPages <= 5) {
                      pageNum = i + 1;
                    } else if (currentPage <= 3) {
                      pageNum = i + 1;
                    } else if (currentPage >= totalPages - 2) {
                      pageNum = totalPages - 4 + i;
                    } else {
                      pageNum = currentPage - 2 + i;
                    }
                    
                    return (
                      <Button
                        key={i}
                        variant={pageNum === currentPage ? 'default' : 'outline'}
                        size="sm"
                        onClick={() => setCurrentPage(pageNum)}
                        className="w-8"
                      >
                        {pageNum}
                      </Button>
                    );
                  })}
                </div>
                
                <Button
                  variant="outline"
                  size="sm"
                  onClick={() => setCurrentPage(prev => Math.min(totalPages, prev + 1))}
                  disabled={currentPage === totalPages}
                >
                  <ChevronRight className="h-4 w-4" />
                </Button>
                <Button
                  variant="outline"
                  size="sm"
                  onClick={() => setCurrentPage(totalPages)}
                  disabled={currentPage === totalPages}
                >
                  <ChevronsRight className="h-4 w-4" />
                </Button>
              </div>
            </div>
          </div>
        )}
      </Card>

      {/* Customer Detail Dialog */}
      <Dialog open={!!selectedCustomer} onOpenChange={() => setSelectedCustomer(null)}>
        <DialogContent className="max-w-4xl max-h-[90vh] overflow-y-auto">
          {selectedCustomer && (
            <CustomerProfileView
              customerId={selectedCustomer.id}
              customerEmail={selectedCustomer.email}
              onClose={() => setSelectedCustomer(null)}
            />
          )}
        </DialogContent>
      </Dialog>

      {/* Create Customer Dialog */}
      <Dialog open={showCreateDialog} onOpenChange={setShowCreateDialog}>
        <DialogContent>
          <DialogHeader>
            <DialogTitle>Add New Customer</DialogTitle>
          </DialogHeader>
          
          <form onSubmit={(e) => {
            e.preventDefault();
            // Implementation for creating customer
            setShowCreateDialog(false);
          }} className="space-y-4">
            <div className="grid grid-cols-2 gap-4">
              <div>
                <label className="text-sm font-medium">First Name *</label>
                <Input name="first_name" required />
              </div>
              <div>
                <label className="text-sm font-medium">Last Name *</label>
                <Input name="last_name" required />
              </div>
            </div>
            
            <div>
              <label className="text-sm font-medium">Email *</label>
              <Input name="email" type="email" required />
            </div>
            
            <div>
              <label className="text-sm font-medium">Phone</label>
              <Input name="phone" type="tel" />
            </div>
            
            <div className="flex justify-end gap-2">
              <Button type="button" variant="outline" onClick={() => setShowCreateDialog(false)}>
                Cancel
              </Button>
              <Button type="submit">Create Customer</Button>
            </div>
          </form>
        </DialogContent>
      </Dialog>
    </div>
  );
});