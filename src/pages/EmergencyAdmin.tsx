import { SidebarProvider } from '@/components/ui/sidebar';
import { AdminSidebar } from '@/components/admin/AdminSidebar';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { useNavigate } from 'react-router-dom';
import { FinancialManagement } from '@/components/admin/FinancialManagement';
import { ProductManagement } from '@/components/admin/ProductManagement';

// Emergency admin access - NO AUTH REQUIRED
const EmergencyAdmin = () => {
  const navigate = useNavigate();
  const path = window.location.pathname;

  const renderContent = () => {
    if (path.includes('financial')) {
      return <FinancialManagement />;
    }
    if (path.includes('products')) {
      return <ProductManagement />;
    }

    // Default dashboard
    return (
      <>
        <div className="mb-6">
          <h1 className="text-3xl font-bold">Emergency Admin Access</h1>
          <p className="text-red-600 font-semibold">⚠️ Authentication bypassed - Use with caution</p>
        </div>

        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6 mb-8">
          <Card className="border-green-500">
            <CardHeader>
              <CardTitle>System Status</CardTitle>
            </CardHeader>
            <CardContent>
              <div className="text-2xl font-bold text-green-600">ACCESSIBLE</div>
              <p className="text-sm text-gray-500 mt-1">No auth required</p>
            </CardContent>
          </Card>

          <Card>
            <CardHeader>
              <CardTitle>Products</CardTitle>
            </CardHeader>
            <CardContent>
              <div className="text-2xl font-bold">182</div>
              <Button 
                size="sm" 
                className="mt-2"
                onClick={() => window.location.href = '/emergency/products'}
              >
                Manage
              </Button>
            </CardContent>
          </Card>

          <Card>
            <CardHeader>
              <CardTitle>Financial</CardTitle>
            </CardHeader>
            <CardContent>
              <div className="text-2xl font-bold">Ready</div>
              <Button 
                size="sm" 
                className="mt-2"
                onClick={() => window.location.href = '/emergency/financial'}
              >
                Access
              </Button>
            </CardContent>
          </Card>

          <Card>
            <CardHeader>
              <CardTitle>Orders</CardTitle>
            </CardHeader>
            <CardContent>
              <div className="text-2xl font-bold">Active</div>
              <Button 
                size="sm" 
                className="mt-2"
                onClick={() => window.location.href = '/emergency/orders'}
              >
                View
              </Button>
            </CardContent>
          </Card>
        </div>

        <Card>
          <CardHeader>
            <CardTitle>Quick Navigation</CardTitle>
          </CardHeader>
          <CardContent>
            <div className="grid grid-cols-2 md:grid-cols-3 gap-4">
              <Button variant="outline" onClick={() => window.location.href = '/emergency/products'}>
                Products
              </Button>
              <Button variant="outline" onClick={() => window.location.href = '/emergency/financial'}>
                Financial
              </Button>
              <Button variant="outline" onClick={() => window.location.href = '/emergency/orders'}>
                Orders
              </Button>
              <Button variant="outline" onClick={() => window.location.href = '/emergency/customers'}>
                Customers
              </Button>
              <Button variant="outline" onClick={() => window.location.href = '/emergency/settings'}>
                Settings
              </Button>
              <Button variant="outline" onClick={() => window.location.href = '/emergency/stripe-sync'}>
                Stripe Sync
              </Button>
            </div>
          </CardContent>
        </Card>
      </>
    );
  };

  return (
    <SidebarProvider>
      <div className="flex h-screen overflow-hidden">
        <AdminSidebar />
        <div className="flex-1 overflow-y-auto p-6">
          {renderContent()}
        </div>
      </div>
    </SidebarProvider>
  );
};

export default EmergencyAdmin;