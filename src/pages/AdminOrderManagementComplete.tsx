import { useState } from 'react';
import { Tabs, TabsContent, TabsList, TabsTrigger } from '@/components/ui/tabs';
import { 
  ShoppingCart, 
  Package, 
  Truck, 
  Factory,
  Zap,
  Bell,
  Mail,
  Database
} from 'lucide-react';
import AdminOrderManagement from './AdminOrderManagement';
import { ManualOrderCreation } from '@/components/admin/ManualOrderCreation';
import { OrderProcessingAutomation } from '@/components/admin/OrderProcessingAutomation';
import { SmartInventoryAlerts } from '@/components/admin/SmartInventoryAlerts';
import { CustomerEmailAutomation } from '@/components/admin/CustomerEmailAutomation';
import { DatabaseBackupManager } from '@/components/admin/DatabaseBackupManager';

export default function AdminOrderManagementComplete() {
  const [activeTab, setActiveTab] = useState('orders');

  return (
    <div className="min-h-screen bg-background">
      <div className="container mx-auto py-6">
        <div className="mb-6">
          <h1 className="text-3xl font-bold">Order & Operations Management</h1>
          <p className="text-muted-foreground">
            Comprehensive order processing, inventory management, and automation tools
          </p>
        </div>

        <Tabs value={activeTab} onValueChange={setActiveTab} className="w-full">
          <TabsList className="grid w-full grid-cols-6 mb-6">
            <TabsTrigger value="orders" className="flex items-center gap-2">
              <ShoppingCart className="h-4 w-4" />
              Orders
            </TabsTrigger>
            <TabsTrigger value="manual-order" className="flex items-center gap-2">
              <Factory className="h-4 w-4" />
              Manual/Dropship
            </TabsTrigger>
            <TabsTrigger value="automation" className="flex items-center gap-2">
              <Zap className="h-4 w-4" />
              Automation
            </TabsTrigger>
            <TabsTrigger value="inventory" className="flex items-center gap-2">
              <Bell className="h-4 w-4" />
              Inventory Alerts
            </TabsTrigger>
            <TabsTrigger value="emails" className="flex items-center gap-2">
              <Mail className="h-4 w-4" />
              Email System
            </TabsTrigger>
            <TabsTrigger value="backups" className="flex items-center gap-2">
              <Database className="h-4 w-4" />
              Backups
            </TabsTrigger>
          </TabsList>

          <TabsContent value="orders" className="mt-0">
            <AdminOrderManagement />
          </TabsContent>

          <TabsContent value="manual-order" className="mt-0">
            <ManualOrderCreation />
          </TabsContent>

          <TabsContent value="automation" className="mt-0">
            <OrderProcessingAutomation />
          </TabsContent>

          <TabsContent value="inventory" className="mt-0">
            <SmartInventoryAlerts />
          </TabsContent>

          <TabsContent value="emails" className="mt-0">
            <CustomerEmailAutomation />
          </TabsContent>

          <TabsContent value="backups" className="mt-0">
            <DatabaseBackupManager />
          </TabsContent>
        </Tabs>
      </div>
    </div>
  );
}