import React, { useState } from 'react';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card';
import { Tabs, TabsContent, TabsList, TabsTrigger } from '@/components/ui/tabs';
import { Badge } from '@/components/ui/badge';
import { Separator } from '@/components/ui/separator';
import { 
  Settings2, 
  Store, 
  CreditCard, 
  Truck, 
  Calculator, 
  Mail, 
  Search, 
  Shield, 
  Code,
  Sync,
  Save,
  RotateCcw
} from 'lucide-react';
import { Button } from '@/components/ui/button';
import { useToast } from '@/hooks/use-toast';

// Import individual setting components
import { GeneralSettings } from './settings/GeneralSettings';
import { PaymentSettings } from './settings/PaymentSettings';
import { ShippingSettings } from './settings/ShippingSettings';
import { TaxSettings } from './settings/TaxSettings';
import { EmailSettings } from './settings/EmailSettings';
import { SEOSettings } from './settings/SEOSettings';
import { SecuritySettings } from './settings/SecuritySettings';
import { APISettings } from './settings/APISettings';

interface SettingsTabConfig {
  id: string;
  label: string;
  icon: React.ComponentType<{ className?: string }>;
  description: string;
  badge?: string;
  critical?: boolean;
}

const settingsTabs: SettingsTabConfig[] = [
  {
    id: 'general',
    label: 'General',
    icon: Store,
    description: 'Store information, branding, and contact details',
    critical: true
  },
  {
    id: 'payment',
    label: 'Payment',
    icon: CreditCard,
    description: 'Payment processors, methods, and currencies',
    critical: true
  },
  {
    id: 'shipping',
    label: 'Shipping',
    icon: Truck,
    description: 'Shipping zones, rates, and delivery methods'
  },
  {
    id: 'tax',
    label: 'Tax',
    icon: Calculator,
    description: 'Tax rates, regions, and calculation settings'
  },
  {
    id: 'email',
    label: 'Email',
    icon: Mail,
    description: 'SMTP configuration, templates, and notifications'
  },
  {
    id: 'seo',
    label: 'SEO',
    icon: Search,
    description: 'Meta tags, analytics, and search optimization'
  },
  {
    id: 'security',
    label: 'Security',
    icon: Shield,
    description: 'Authentication, access control, and security policies',
    badge: 'Important'
  },
  {
    id: 'api',
    label: 'API',
    icon: Code,
    description: 'API keys, webhooks, and integration settings'
  }
];

export function Settings() {
  const [activeTab, setActiveTab] = useState('general');
  const [hasUnsavedChanges, setHasUnsavedChanges] = useState(false);
  const [isSaving, setIsSaving] = useState(false);
  const [isSyncing, setIsSyncing] = useState(false);
  const { toast } = useToast();

  const handleSaveAll = async () => {
    setIsSaving(true);
    try {
      // Simulate save operation
      await new Promise(resolve => setTimeout(resolve, 1500));
      
      toast({
        title: "Settings saved",
        description: "All settings have been saved successfully.",
      });
      
      setHasUnsavedChanges(false);
    } catch (error) {
      toast({
        title: "Error saving settings",
        description: "Please try again or contact support if the problem persists.",
        variant: "destructive"
      });
    } finally {
      setIsSaving(false);
    }
  };

  const handleSyncToWebsite = async () => {
    setIsSyncing(true);
    try {
      // Simulate sync operation
      await new Promise(resolve => setTimeout(resolve, 2000));
      
      toast({
        title: "Settings synchronized",
        description: "Critical settings have been synced to your website.",
      });
    } catch (error) {
      toast({
        title: "Sync failed",
        description: "Unable to sync settings to website. Please try again.",
        variant: "destructive"
      });
    } finally {
      setIsSyncing(false);
    }
  };

  const handleDiscardChanges = () => {
    setHasUnsavedChanges(false);
    toast({
      title: "Changes discarded",
      description: "All unsaved changes have been reverted.",
    });
  };

  const renderTabContent = (tabId: string) => {
    const onSettingsChange = () => setHasUnsavedChanges(true);

    switch (tabId) {
      case 'general':
        return <GeneralSettings onSettingsChange={onSettingsChange} />;
      case 'payment':
        return <PaymentSettings onSettingsChange={onSettingsChange} />;
      case 'shipping':
        return <ShippingSettings onSettingsChange={onSettingsChange} />;
      case 'tax':
        return <TaxSettings onSettingsChange={onSettingsChange} />;
      case 'email':
        return <EmailSettings onSettingsChange={onSettingsChange} />;
      case 'seo':
        return <SEOSettings onSettingsChange={onSettingsChange} />;
      case 'security':
        return <SecuritySettings onSettingsChange={onSettingsChange} />;
      case 'api':
        return <APISettings onSettingsChange={onSettingsChange} />;
      default:
        return null;
    }
  };

  const criticalTabs = settingsTabs.filter(tab => tab.critical).map(tab => tab.id);
  const shouldShowSyncButton = criticalTabs.includes(activeTab);

  return (
    <div className="space-y-6">
      {/* Header */}
      <div className="flex items-center justify-between">
        <div className="flex items-center gap-3">
          <div className="flex h-10 w-10 items-center justify-center rounded-lg bg-primary/10">
            <Settings2 className="h-5 w-5 text-primary" />
          </div>
          <div>
            <h1 className="text-2xl font-bold tracking-tight">Settings & Configuration</h1>
            <p className="text-muted-foreground">
              Manage your store settings and system configuration
            </p>
          </div>
        </div>

        {/* Action Buttons */}
        <div className="flex items-center gap-2">
          {hasUnsavedChanges && (
            <Button 
              variant="outline" 
              size="sm"
              onClick={handleDiscardChanges}
              className="text-muted-foreground"
            >
              <RotateCcw className="h-4 w-4 mr-2" />
              Discard Changes
            </Button>
          )}
          
          {shouldShowSyncButton && (
            <Button 
              variant="outline" 
              size="sm"
              onClick={handleSyncToWebsite}
              disabled={isSyncing}
              className="border-primary/20 text-primary hover:bg-primary/5"
            >
              {isSyncing ? (
                <div className="h-4 w-4 mr-2 animate-spin rounded-full border-2 border-primary border-t-transparent" />
              ) : (
                <Sync className="h-4 w-4 mr-2" />
              )}
              Sync to Website
            </Button>
          )}
          
          <Button 
            size="sm"
            onClick={handleSaveAll}
            disabled={isSaving || !hasUnsavedChanges}
            className="min-w-[120px]"
          >
            {isSaving ? (
              <div className="h-4 w-4 mr-2 animate-spin rounded-full border-2 border-white border-t-transparent" />
            ) : (
              <Save className="h-4 w-4 mr-2" />
            )}
            {isSaving ? 'Saving...' : 'Save All'}
          </Button>
        </div>
      </div>

      {/* Unsaved Changes Alert */}
      {hasUnsavedChanges && (
        <Card className="border-amber-200 bg-amber-50 dark:border-amber-800 dark:bg-amber-950/50">
          <CardContent className="flex items-center gap-3 p-4">
            <div className="h-2 w-2 rounded-full bg-amber-500 animate-pulse" />
            <span className="text-sm text-amber-800 dark:text-amber-200">
              You have unsaved changes. Don't forget to save your settings.
            </span>
          </CardContent>
        </Card>
      )}

      {/* Settings Tabs */}
      <Card>
        <CardHeader className="pb-3">
          <CardTitle className="text-lg">Configuration Sections</CardTitle>
          <CardDescription>
            Choose a section to configure your store settings
          </CardDescription>
        </CardHeader>
        <Separator />
        
        <Tabs 
          value={activeTab} 
          onValueChange={setActiveTab}
          className="w-full"
        >
          <div className="border-b">
            <TabsList className="h-auto p-1 bg-transparent w-full justify-start overflow-x-auto">
              {settingsTabs.map((tab) => {
                const Icon = tab.icon;
                return (
                  <TabsTrigger
                    key={tab.id}
                    value={tab.id}
                    className="flex items-center gap-2 px-4 py-3 rounded-md data-[state=active]:bg-muted whitespace-nowrap"
                  >
                    <Icon className="h-4 w-4" />
                    <span>{tab.label}</span>
                    {tab.badge && (
                      <Badge 
                        variant="secondary" 
                        className="ml-1 h-5 px-1.5 text-xs"
                      >
                        {tab.badge}
                      </Badge>
                    )}
                    {tab.critical && (
                      <div className="h-2 w-2 rounded-full bg-primary ml-1" />
                    )}
                  </TabsTrigger>
                );
              })}
            </TabsList>
          </div>

          {/* Tab Content */}
          {settingsTabs.map((tab) => (
            <TabsContent key={tab.id} value={tab.id} className="mt-0">
              <CardContent className="p-6">
                <div className="mb-6">
                  <div className="flex items-center gap-3 mb-2">
                    <tab.icon className="h-5 w-5 text-muted-foreground" />
                    <h3 className="text-lg font-semibold">{tab.label} Settings</h3>
                    {tab.critical && (
                      <Badge variant="outline" className="text-xs">
                        Critical
                      </Badge>
                    )}
                  </div>
                  <p className="text-sm text-muted-foreground">
                    {tab.description}
                  </p>
                </div>
                
                <Separator className="mb-6" />
                
                {renderTabContent(tab.id)}
              </CardContent>
            </TabsContent>
          ))}
        </Tabs>
      </Card>
    </div>
  );
}