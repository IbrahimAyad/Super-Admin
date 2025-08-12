import React, { useRef, useMemo, memo } from 'react';
import { useVirtualizer } from '@tanstack/react-virtual';
import { Card } from '@/components/ui/card';
import { Badge } from '@/components/ui/badge';
import { Button } from '@/components/ui/button';
import { Checkbox } from '@/components/ui/checkbox';
import { Avatar, AvatarFallback } from '@/components/ui/avatar';
import { 
  DollarSign, 
  Mail, 
  Phone, 
  MapPin,
  ShoppingCart,
  Calendar,
  MoreVertical
} from 'lucide-react';
import { DropdownMenu, DropdownMenuContent, DropdownMenuItem, DropdownMenuTrigger } from '@/components/ui/dropdown-menu';

interface Customer {
  id: string;
  name: string;
  email: string;
  phone?: string;
  address?: string;
  city?: string;
  state?: string;
  total_spent: number;
  order_count: number;
  tags?: string[];
  created_at: string;
}

interface VirtualCustomerListProps {
  customers: Customer[];
  selectedCustomers: string[];
  onCustomerSelect: (customerId: string) => void;
  onCustomerAction: (action: string, customerId: string) => void;
  searchTerm?: string;
}

export const VirtualCustomerList = memo<VirtualCustomerListProps>(({
  customers,
  selectedCustomers,
  onCustomerSelect,
  onCustomerAction,
  searchTerm = ''
}) => {
  const parentRef = useRef<HTMLDivElement>(null);

  // Filter customers based on search term
  const filteredCustomers = useMemo(() => {
    if (!searchTerm) return customers;
    
    const term = searchTerm.toLowerCase();
    return customers.filter(customer => 
      customer.name?.toLowerCase().includes(term) ||
      customer.email?.toLowerCase().includes(term) ||
      customer.phone?.includes(term) ||
      customer.city?.toLowerCase().includes(term)
    );
  }, [customers, searchTerm]);

  // Initialize virtualizer
  const virtualizer = useVirtualizer({
    count: filteredCustomers.length,
    getScrollElement: () => parentRef.current,
    estimateSize: () => 120, // Estimated height of each customer card
    overscan: 5, // Number of items to render outside of the visible area
  });

  // Format currency
  const formatCurrency = (amount: number) => {
    return new Intl.NumberFormat('en-US', {
      style: 'currency',
      currency: 'USD'
    }).format(amount);
  };

  // Get customer initials for avatar
  const getInitials = (name: string) => {
    return name
      .split(' ')
      .map(n => n[0])
      .join('')
      .toUpperCase()
      .slice(0, 2);
  };

  // Format date
  const formatDate = (dateString: string) => {
    return new Date(dateString).toLocaleDateString('en-US', {
      month: 'short',
      day: 'numeric',
      year: 'numeric'
    });
  };

  // Customer row component
  const CustomerRow = ({ customer, isSelected }: { customer: Customer; isSelected: boolean }) => (
    <Card className="p-4 hover:shadow-md transition-shadow">
      <div className="flex items-start gap-4">
        {/* Selection checkbox */}
        <Checkbox
          checked={isSelected}
          onCheckedChange={() => onCustomerSelect(customer.id)}
          className="mt-1"
        />

        {/* Avatar */}
        <Avatar className="h-10 w-10">
          <AvatarFallback className="bg-primary/10 text-primary font-semibold">
            {getInitials(customer.name)}
          </AvatarFallback>
        </Avatar>

        {/* Customer details */}
        <div className="flex-1 min-w-0">
          <div className="flex items-start justify-between">
            <div className="space-y-1">
              <h3 className="font-semibold text-sm truncate">{customer.name}</h3>
              
              <div className="flex flex-wrap gap-2 text-xs text-muted-foreground">
                {customer.email && (
                  <div className="flex items-center gap-1">
                    <Mail className="h-3 w-3" />
                    <span className="truncate max-w-[200px]">{customer.email}</span>
                  </div>
                )}
                {customer.phone && (
                  <div className="flex items-center gap-1">
                    <Phone className="h-3 w-3" />
                    <span>{customer.phone}</span>
                  </div>
                )}
                {customer.city && (
                  <div className="flex items-center gap-1">
                    <MapPin className="h-3 w-3" />
                    <span>{customer.city}, {customer.state}</span>
                  </div>
                )}
              </div>
            </div>

            {/* Actions dropdown */}
            <DropdownMenu>
              <DropdownMenuTrigger asChild>
                <Button variant="ghost" size="sm" className="h-8 w-8 p-0">
                  <MoreVertical className="h-4 w-4" />
                </Button>
              </DropdownMenuTrigger>
              <DropdownMenuContent align="end">
                <DropdownMenuItem onClick={() => onCustomerAction('view', customer.id)}>
                  View Details
                </DropdownMenuItem>
                <DropdownMenuItem onClick={() => onCustomerAction('edit', customer.id)}>
                  Edit Customer
                </DropdownMenuItem>
                <DropdownMenuItem onClick={() => onCustomerAction('orders', customer.id)}>
                  View Orders
                </DropdownMenuItem>
                <DropdownMenuItem onClick={() => onCustomerAction('email', customer.id)}>
                  Send Email
                </DropdownMenuItem>
              </DropdownMenuContent>
            </DropdownMenu>
          </div>

          {/* Stats and tags */}
          <div className="flex flex-wrap items-center gap-3 mt-2">
            <div className="flex items-center gap-1 text-xs">
              <DollarSign className="h-3 w-3 text-green-600" />
              <span className="font-medium">{formatCurrency(customer.total_spent)}</span>
            </div>
            <div className="flex items-center gap-1 text-xs">
              <ShoppingCart className="h-3 w-3 text-blue-600" />
              <span>{customer.order_count} orders</span>
            </div>
            <div className="flex items-center gap-1 text-xs text-muted-foreground">
              <Calendar className="h-3 w-3" />
              <span>{formatDate(customer.created_at)}</span>
            </div>
            
            {/* Tags */}
            {customer.tags && customer.tags.length > 0 && (
              <div className="flex gap-1 ml-auto">
                {customer.tags.slice(0, 3).map((tag, index) => (
                  <Badge key={index} variant="secondary" className="text-xs">
                    {tag}
                  </Badge>
                ))}
                {customer.tags.length > 3 && (
                  <Badge variant="outline" className="text-xs">
                    +{customer.tags.length - 3}
                  </Badge>
                )}
              </div>
            )}
          </div>
        </div>
      </div>
    </Card>
  );

  return (
    <div className="space-y-4">
      {/* Results count */}
      <div className="text-sm text-muted-foreground">
        Showing {filteredCustomers.length} of {customers.length} customers
      </div>

      {/* Virtual scroll container */}
      <div
        ref={parentRef}
        className="h-[600px] overflow-auto space-y-2 pr-2"
        style={{
          contain: 'strict',
        }}
      >
        <div
          style={{
            height: `${virtualizer.getTotalSize()}px`,
            width: '100%',
            position: 'relative',
          }}
        >
          {virtualizer.getVirtualItems().map((virtualItem) => {
            const customer = filteredCustomers[virtualItem.index];
            const isSelected = selectedCustomers.includes(customer.id);

            return (
              <div
                key={virtualItem.key}
                style={{
                  position: 'absolute',
                  top: 0,
                  left: 0,
                  width: '100%',
                  height: `${virtualItem.size}px`,
                  transform: `translateY(${virtualItem.start}px)`,
                }}
              >
                <CustomerRow 
                  customer={customer} 
                  isSelected={isSelected}
                />
              </div>
            );
          })}
        </div>
      </div>
    </div>
  );
}, (prevProps, nextProps) => {
  // Custom comparison for React.memo optimization
  return (
    prevProps.customers === nextProps.customers &&
    prevProps.selectedCustomers === nextProps.selectedCustomers &&
    prevProps.searchTerm === nextProps.searchTerm &&
    prevProps.onCustomerSelect === nextProps.onCustomerSelect &&
    prevProps.onCustomerAction === nextProps.onCustomerAction
  );
});

VirtualCustomerList.displayName = 'VirtualCustomerList';