/**
 * SETTINGS MANAGEMENT COMPONENT
 * Comprehensive admin interface for managing system settings
 * Last updated: 2025-08-07
 */

import React, { useState, useEffect } from 'react';
import { 
  useSettings, 
  useUpdateSetting, 
  useBulkUpdateSettings,
  useDeleteSetting,
  useSettingsAuditLog 
} from '../../hooks/useSettings';
import { settingsSecurityService, AuditEventType } from '../../lib/services/settingsSecurity';
import { settingsSyncService } from '../../lib/services/settingsSync';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '../ui/card';
import { Button } from '../ui/button';
import { Input } from '../ui/input';
import { Label } from '../ui/label';
import { Textarea } from '../ui/textarea';
import { Switch } from '../ui/switch';
import { Badge } from '../ui/badge';
import { Tabs, TabsContent, TabsList, TabsTrigger } from '../ui/tabs';
import { Alert, AlertDescription, AlertTitle } from '../ui/alert';
import { 
  Dialog, 
  DialogContent, 
  DialogDescription, 
  DialogFooter, 
  DialogHeader, 
  DialogTitle,
  DialogTrigger 
} from '../ui/dialog';
import { 
  AlertDialog,
  AlertDialogAction,
  AlertDialogCancel,
  AlertDialogContent,
  AlertDialogDescription,
  AlertDialogFooter,
  AlertDialogHeader,
  AlertDialogTitle,
  AlertDialogTrigger,
} from '../ui/alert-dialog';
import { useToast } from '../../hooks/use-toast';
import { 
  Save, 
  Trash2, 
  Shield, 
  Eye, 
  EyeOff, 
  Download, 
  Upload,
  RefreshCw,
  AlertTriangle,
  CheckCircle,
  Info,
  Settings as SettingsIcon,
  Lock,
  Unlock,
  History,
  Zap,
  Globe,
  Database
} from 'lucide-react';

interface SettingFormData {
  key: string;
  value: any;
  category: string;
  description: string;
  data_type: 'string' | 'number' | 'boolean' | 'json' | 'encrypted';
  is_public: boolean;
  is_sensitive: boolean;
}

const SETTING_CATEGORIES = [
  'general',
  'commerce',
  'security',
  'notifications',
  'analytics',
  'system',
  'payment',
  'smtp',
  'api',
];

export default function SettingsManagement() {
  const { toast } = useToast();
  const [selectedCategory, setSelectedCategory] = useState<string>('all');
  const [searchTerm, setSearchTerm] = useState('');
  const [showSensitive, setShowSensitive] = useState(false);
  const [editingKey, setEditingKey] = useState<string | null>(null);
  const [formData, setFormData] = useState<SettingFormData>({
    key: '',
    value: '',
    category: 'general',
    description: '',
    data_type: 'string',
    is_public: false,
    is_sensitive: false,
  });
  const [securityStatus, setSecurityStatus] = useState<any>(null);
  const [syncStatus, setSyncStatus] = useState<any>(null);

  // Queries
  const { 
    data: settings = [], 
    isLoading: settingsLoading, 
    error: settingsError,
    refetch: refetchSettings
  } = useSettings(selectedCategory === 'all' ? undefined : selectedCategory);
  
  const { data: auditLog = [] } = useSettingsAuditLog(undefined, 50);
  
  // Mutations
  const updateSettingMutation = useUpdateSetting();
  const bulkUpdateMutation = useBulkUpdateSettings();
  const deleteSettingMutation = useDeleteSetting();

  // Load security and sync status
  useEffect(() => {
    const loadStatus = async () => {
      try {
        const [secStatus, syncStatus] = await Promise.all([
          settingsSecurityService.getSecurityStatus(),
          Promise.resolve(settingsSyncService.getSyncStatus()),
        ]);
        setSecurityStatus(secStatus);
        setSyncStatus(syncStatus);
      } catch (error) {
        console.error('Failed to load status:', error);
      }
    };
    loadStatus();
  }, []);

  // Filter settings based on search and category
  const filteredSettings = settings.filter(setting => {
    const matchesSearch = setting.key.toLowerCase().includes(searchTerm.toLowerCase()) ||
                         setting.description?.toLowerCase().includes(searchTerm.toLowerCase()) ||
                         setting.category.toLowerCase().includes(searchTerm.toLowerCase());
    
    const matchesCategory = selectedCategory === 'all' || setting.category === selectedCategory;
    
    return matchesSearch && matchesCategory;
  });

  // Handle form submission
  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    
    try {
      // Validate form data
      const validation = settingsSecurityService.validateSettingValue(
        formData.key, 
        formData.value
      );
      
      if (!validation.valid) {
        validation.errors.forEach(error => {
          toast({
            title: 'Validation Error',
            description: error,
            variant: 'destructive',
          });
        });
        return;
      }

      // Show warnings if any
      validation.warnings.forEach(warning => {
        toast({
          title: 'Warning',
          description: warning,
          variant: 'destructive',
        });
      });

      // Process the value based on data type
      let processedValue = formData.value;
      switch (formData.data_type) {
        case 'number':
          processedValue = parseFloat(formData.value);
          break;
        case 'boolean':
          processedValue = formData.value === 'true' || formData.value === true;
          break;
        case 'json':
          processedValue = JSON.parse(formData.value);
          break;
      }

      await updateSettingMutation.mutateAsync({
        key: formData.key,
        value: processedValue,
        options: {
          category: formData.category,
          description: formData.description,
          data_type: formData.data_type,
          is_public: formData.is_public,
          is_sensitive: formData.is_sensitive,
        },
      });

      toast({
        title: 'Setting Updated',
        description: `Successfully updated ${formData.key}`,
      });

      // Reset form
      setEditingKey(null);
      setFormData({
        key: '',
        value: '',
        category: 'general',
        description: '',
        data_type: 'string',
        is_public: false,
        is_sensitive: false,
      });

    } catch (error) {
      console.error('Failed to update setting:', error);
      toast({
        title: 'Update Failed',
        description: error.message || 'Failed to update setting',
        variant: 'destructive',
      });
    }
  };

  // Handle delete
  const handleDelete = async (key: string) => {
    try {
      await deleteSettingMutation.mutateAsync(key);
      toast({
        title: 'Setting Deleted',
        description: `Successfully deleted ${key}`,
      });
    } catch (error) {
      console.error('Failed to delete setting:', error);
      toast({
        title: 'Delete Failed',
        description: error.message || 'Failed to delete setting',
        variant: 'destructive',
      });
    }
  };

  // Handle sync to website
  const handleSyncToWebsite = async (keys?: string[]) => {
    try {
      await settingsSyncService.broadcastSettingsUpdate(
        keys || filteredSettings.filter(s => s.is_public).map(s => s.key),
        'website'
      );
      toast({
        title: 'Settings Synced',
        description: 'Settings have been synchronized to the website',
      });
    } catch (error) {
      console.error('Sync failed:', error);
      toast({
        title: 'Sync Failed',
        description: 'Failed to sync settings to website',
        variant: 'destructive',
      });
    }
  };

  // Handle export
  const handleExport = async (includeEncrypted: boolean = false) => {
    try {
      const exportData = await settingsSecurityService.exportSettings(
        includeEncrypted,
        selectedCategory === 'all' ? undefined : [selectedCategory]
      );

      const blob = new Blob([JSON.stringify(exportData, null, 2)], {
        type: 'application/json',
      });
      const url = URL.createObjectURL(blob);
      const a = document.createElement('a');
      a.href = url;
      a.download = `settings-export-${new Date().toISOString().split('T')[0]}.json`;
      a.click();
      URL.revokeObjectURL(url);

      toast({
        title: 'Export Complete',
        description: `Exported ${exportData.settings.length} settings`,
      });
    } catch (error) {
      console.error('Export failed:', error);
      toast({
        title: 'Export Failed',
        description: 'Failed to export settings',
        variant: 'destructive',
      });
    }
  };

  if (settingsError) {
    return (
      <Alert variant="destructive">
        <AlertTriangle className="h-4 w-4" />
        <AlertTitle>Error Loading Settings</AlertTitle>
        <AlertDescription>
          {settingsError.message}
          <Button 
            variant="outline" 
            size="sm" 
            className="ml-2"
            onClick={() => refetchSettings()}
          >
            <RefreshCw className="h-4 w-4 mr-1" />
            Retry
          </Button>
        </AlertDescription>
      </Alert>
    );
  }

  return (
    <div className="container mx-auto p-6 space-y-6">
      {/* Header */}
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-3xl font-bold flex items-center gap-2">
            <SettingsIcon className="h-8 w-8" />
            Settings Management
          </h1>
          <p className="text-muted-foreground mt-1">
            Configure and manage system settings with security controls
          </p>
        </div>
        
        <div className="flex items-center gap-2">
          <Button 
            variant="outline" 
            onClick={() => handleSyncToWebsite()}
            disabled={!filteredSettings.some(s => s.is_public)}
          >
            <Globe className="h-4 w-4 mr-1" />
            Sync to Website
          </Button>
          <Button 
            variant="outline" 
            onClick={() => handleExport()}
          >
            <Download className="h-4 w-4 mr-1" />
            Export
          </Button>
          <Button 
            onClick={() => refetchSettings()}
            disabled={settingsLoading}
          >
            <RefreshCw className={`h-4 w-4 mr-1 ${settingsLoading ? 'animate-spin' : ''}`} />
            Refresh
          </Button>
        </div>
      </div>

      {/* Status Cards */}
      {securityStatus && (
        <div className="grid grid-cols-1 md:grid-cols-4 gap-4">
          <Card>
            <CardHeader className="pb-2">
              <CardTitle className="text-sm font-medium flex items-center gap-2">
                <Database className="h-4 w-4" />
                Total Settings
              </CardTitle>
            </CardHeader>
            <CardContent>
              <div className="text-2xl font-bold">{securityStatus.total_settings}</div>
            </CardContent>
          </Card>

          <Card>
            <CardHeader className="pb-2">
              <CardTitle className="text-sm font-medium flex items-center gap-2">
                <Shield className="h-4 w-4" />
                Sensitive
              </CardTitle>
            </CardHeader>
            <CardContent>
              <div className="text-2xl font-bold text-orange-600">
                {securityStatus.sensitive_settings}
              </div>
            </CardContent>
          </Card>

          <Card>
            <CardHeader className="pb-2">
              <CardTitle className="text-sm font-medium flex items-center gap-2">
                <Lock className="h-4 w-4" />
                Encrypted
              </CardTitle>
            </CardHeader>
            <CardContent>
              <div className="text-2xl font-bold text-green-600">
                {securityStatus.encrypted_settings}
              </div>
            </CardContent>
          </Card>

          <Card>
            <CardHeader className="pb-2">
              <CardTitle className="text-sm font-medium flex items-center gap-2">
                <Globe className="h-4 w-4" />
                Public
              </CardTitle>
            </CardHeader>
            <CardContent>
              <div className="text-2xl font-bold text-blue-600">
                {securityStatus.public_settings}
              </div>
            </CardContent>
          </Card>
        </div>
      )}

      {/* Main Content */}
      <Tabs defaultValue="settings" className="space-y-4">
        <TabsList>
          <TabsTrigger value="settings">Settings</TabsTrigger>
          <TabsTrigger value="audit">Audit Log</TabsTrigger>
          <TabsTrigger value="security">Security</TabsTrigger>
          <TabsTrigger value="sync">Real-time Sync</TabsTrigger>
        </TabsList>

        {/* Settings Tab */}
        <TabsContent value="settings" className="space-y-4">
          {/* Filters */}
          <Card>
            <CardHeader>
              <CardTitle>Filters</CardTitle>
            </CardHeader>
            <CardContent>
              <div className="flex flex-wrap items-center gap-4">
                <div className="flex-1 min-w-[200px]">
                  <Label htmlFor="search">Search</Label>
                  <Input
                    id="search"
                    placeholder="Search settings..."
                    value={searchTerm}
                    onChange={(e) => setSearchTerm(e.target.value)}
                  />
                </div>
                
                <div className="min-w-[150px]">
                  <Label htmlFor="category">Category</Label>
                  <select
                    id="category"
                    className="w-full p-2 border rounded-md"
                    value={selectedCategory}
                    onChange={(e) => setSelectedCategory(e.target.value)}
                  >
                    <option value="all">All Categories</option>
                    {SETTING_CATEGORIES.map(cat => (
                      <option key={cat} value={cat}>
                        {cat.charAt(0).toUpperCase() + cat.slice(1)}
                      </option>
                    ))}
                  </select>
                </div>

                <div className="flex items-center space-x-2">
                  <Switch
                    id="show-sensitive"
                    checked={showSensitive}
                    onCheckedChange={setShowSensitive}
                  />
                  <Label htmlFor="show-sensitive">Show sensitive values</Label>
                </div>
              </div>
            </CardContent>
          </Card>

          {/* Settings List */}
          <div className="grid gap-4">
            {filteredSettings.map((setting) => (
              <SettingCard
                key={setting.id}
                setting={setting}
                showSensitive={showSensitive}
                onEdit={setEditingKey}
                onDelete={handleDelete}
                onSync={handleSyncToWebsite}
              />
            ))}

            {filteredSettings.length === 0 && !settingsLoading && (
              <Card>
                <CardContent className="text-center py-8">
                  <p className="text-muted-foreground">No settings found matching your criteria.</p>
                </CardContent>
              </Card>
            )}
          </div>
        </TabsContent>

        {/* Audit Log Tab */}
        <TabsContent value="audit" className="space-y-4">
          <AuditLogSection auditLog={auditLog} />
        </TabsContent>

        {/* Security Tab */}
        <TabsContent value="security" className="space-y-4">
          <SecuritySection 
            securityStatus={securityStatus}
            settings={settings}
            onExport={handleExport}
          />
        </TabsContent>

        {/* Sync Tab */}
        <TabsContent value="sync" className="space-y-4">
          <SyncSection 
            syncStatus={syncStatus}
            onSync={handleSyncToWebsite}
          />
        </TabsContent>
      </Tabs>

      {/* Edit Setting Dialog */}
      <SettingFormDialog
        isOpen={editingKey !== null}
        onClose={() => setEditingKey(null)}
        formData={formData}
        setFormData={setFormData}
        onSubmit={handleSubmit}
        isLoading={updateSettingMutation.isPending}
      />
    </div>
  );
}

// Setting Card Component
function SettingCard({ 
  setting, 
  showSensitive, 
  onEdit, 
  onDelete, 
  onSync 
}: {
  setting: any;
  showSensitive: boolean;
  onEdit: (key: string) => void;
  onDelete: (key: string) => void;
  onSync: (keys: string[]) => void;
}) {
  const displayValue = setting.is_sensitive && !showSensitive 
    ? '••••••••' 
    : typeof setting.value === 'object' 
      ? JSON.stringify(setting.value, null, 2)
      : String(setting.value);

  const recommendations = settingsSecurityService.getSecurityRecommendations(
    setting.key, 
    setting
  );

  return (
    <Card>
      <CardHeader>
        <div className="flex items-start justify-between">
          <div>
            <CardTitle className="flex items-center gap-2 text-lg">
              {setting.key}
              {setting.is_sensitive && <Shield className="h-4 w-4 text-orange-500" />}
              {setting.data_type === 'encrypted' && <Lock className="h-4 w-4 text-green-500" />}
              {setting.is_public && <Globe className="h-4 w-4 text-blue-500" />}
            </CardTitle>
            <CardDescription>
              {setting.description || 'No description provided'}
            </CardDescription>
          </div>
          
          <div className="flex items-center gap-2">
            <Badge variant="outline">{setting.category}</Badge>
            <Badge variant="secondary">{setting.data_type}</Badge>
          </div>
        </div>
      </CardHeader>
      
      <CardContent>
        <div className="space-y-4">
          {/* Value Display */}
          <div>
            <Label>Value</Label>
            <div className="mt-1 p-3 bg-muted rounded-md font-mono text-sm">
              {displayValue}
            </div>
          </div>

          {/* Security Recommendations */}
          {recommendations.length > 0 && (
            <Alert>
              <Info className="h-4 w-4" />
              <AlertTitle>Security Recommendations</AlertTitle>
              <AlertDescription>
                <ul className="list-disc list-inside space-y-1 mt-2">
                  {recommendations.map((rec, index) => (
                    <li key={index} className="text-sm">{rec}</li>
                  ))}
                </ul>
              </AlertDescription>
            </Alert>
          )}

          {/* Actions */}
          <div className="flex items-center gap-2">
            <Button 
              size="sm" 
              variant="outline"
              onClick={() => onEdit(setting.key)}
            >
              Edit
            </Button>
            
            {setting.is_public && (
              <Button 
                size="sm" 
                variant="outline"
                onClick={() => onSync([setting.key])}
              >
                <Zap className="h-4 w-4 mr-1" />
                Sync
              </Button>
            )}
            
            <AlertDialog>
              <AlertDialogTrigger asChild>
                <Button size="sm" variant="destructive">
                  <Trash2 className="h-4 w-4 mr-1" />
                  Delete
                </Button>
              </AlertDialogTrigger>
              <AlertDialogContent>
                <AlertDialogHeader>
                  <AlertDialogTitle>Delete Setting</AlertDialogTitle>
                  <AlertDialogDescription>
                    Are you sure you want to delete "{setting.key}"? This action cannot be undone.
                  </AlertDialogDescription>
                </AlertDialogHeader>
                <AlertDialogFooter>
                  <AlertDialogCancel>Cancel</AlertDialogCancel>
                  <AlertDialogAction 
                    onClick={() => onDelete(setting.key)}
                    className="bg-destructive text-destructive-foreground"
                  >
                    Delete
                  </AlertDialogAction>
                </AlertDialogFooter>
              </AlertDialogContent>
            </AlertDialog>
          </div>
        </div>
      </CardContent>
    </Card>
  );
}

// Form Dialog Component
function SettingFormDialog({ 
  isOpen, 
  onClose, 
  formData, 
  setFormData, 
  onSubmit, 
  isLoading 
}: {
  isOpen: boolean;
  onClose: () => void;
  formData: SettingFormData;
  setFormData: (data: SettingFormData) => void;
  onSubmit: (e: React.FormEvent) => void;
  isLoading: boolean;
}) {
  return (
    <Dialog open={isOpen} onOpenChange={onClose}>
      <DialogContent className="max-w-2xl">
        <DialogHeader>
          <DialogTitle>Edit Setting</DialogTitle>
          <DialogDescription>
            Modify setting configuration with security controls.
          </DialogDescription>
        </DialogHeader>

        <form onSubmit={onSubmit} className="space-y-4">
          <div className="grid grid-cols-2 gap-4">
            <div>
              <Label htmlFor="key">Key</Label>
              <Input
                id="key"
                value={formData.key}
                onChange={(e) => setFormData({ ...formData, key: e.target.value })}
                required
              />
            </div>
            
            <div>
              <Label htmlFor="category">Category</Label>
              <select
                id="category"
                className="w-full p-2 border rounded-md"
                value={formData.category}
                onChange={(e) => setFormData({ ...formData, category: e.target.value })}
              >
                {SETTING_CATEGORIES.map(cat => (
                  <option key={cat} value={cat}>
                    {cat.charAt(0).toUpperCase() + cat.slice(1)}
                  </option>
                ))}
              </select>
            </div>
          </div>

          <div>
            <Label htmlFor="description">Description</Label>
            <Input
              id="description"
              value={formData.description}
              onChange={(e) => setFormData({ ...formData, description: e.target.value })}
              placeholder="Describe what this setting controls..."
            />
          </div>

          <div className="grid grid-cols-2 gap-4">
            <div>
              <Label htmlFor="data_type">Data Type</Label>
              <select
                id="data_type"
                className="w-full p-2 border rounded-md"
                value={formData.data_type}
                onChange={(e) => setFormData({ 
                  ...formData, 
                  data_type: e.target.value as any 
                })}
              >
                <option value="string">String</option>
                <option value="number">Number</option>
                <option value="boolean">Boolean</option>
                <option value="json">JSON</option>
                <option value="encrypted">Encrypted</option>
              </select>
            </div>

            <div className="space-y-2">
              <div className="flex items-center space-x-2">
                <Switch
                  id="is_public"
                  checked={formData.is_public}
                  onCheckedChange={(checked) => setFormData({ 
                    ...formData, 
                    is_public: checked 
                  })}
                />
                <Label htmlFor="is_public">Public</Label>
              </div>

              <div className="flex items-center space-x-2">
                <Switch
                  id="is_sensitive"
                  checked={formData.is_sensitive}
                  onCheckedChange={(checked) => setFormData({ 
                    ...formData, 
                    is_sensitive: checked 
                  })}
                />
                <Label htmlFor="is_sensitive">Sensitive</Label>
              </div>
            </div>
          </div>

          <div>
            <Label htmlFor="value">Value</Label>
            {formData.data_type === 'boolean' ? (
              <select
                className="w-full p-2 border rounded-md"
                value={String(formData.value)}
                onChange={(e) => setFormData({ ...formData, value: e.target.value })}
              >
                <option value="true">True</option>
                <option value="false">False</option>
              </select>
            ) : formData.data_type === 'json' ? (
              <Textarea
                id="value"
                value={typeof formData.value === 'object' 
                  ? JSON.stringify(formData.value, null, 2)
                  : formData.value
                }
                onChange={(e) => setFormData({ ...formData, value: e.target.value })}
                rows={6}
                placeholder="Enter valid JSON..."
              />
            ) : (
              <Input
                id="value"
                type={formData.data_type === 'number' ? 'number' : 'text'}
                value={formData.value}
                onChange={(e) => setFormData({ ...formData, value: e.target.value })}
                required
              />
            )}
          </div>

          <DialogFooter>
            <Button type="button" variant="outline" onClick={onClose}>
              Cancel
            </Button>
            <Button type="submit" disabled={isLoading}>
              {isLoading && <RefreshCw className="h-4 w-4 mr-1 animate-spin" />}
              Save Setting
            </Button>
          </DialogFooter>
        </form>
      </DialogContent>
    </Dialog>
  );
}

// Audit Log Section
function AuditLogSection({ auditLog }: { auditLog: any[] }) {
  return (
    <Card>
      <CardHeader>
        <CardTitle className="flex items-center gap-2">
          <History className="h-5 w-5" />
          Audit Log
        </CardTitle>
        <CardDescription>
          Recent settings changes and security events
        </CardDescription>
      </CardHeader>
      <CardContent>
        <div className="space-y-4">
          {auditLog.map((entry) => (
            <div 
              key={entry.id} 
              className="flex items-start justify-between p-3 border rounded-lg"
            >
              <div>
                <div className="font-medium">
                  {entry.setting_key && `${entry.setting_key}: `}
                  {entry.action}
                </div>
                <div className="text-sm text-muted-foreground">
                  {entry.user_email || 'System'} • {new Date(entry.changed_at).toLocaleString()}
                </div>
              </div>
              <Badge variant="outline">{entry.action}</Badge>
            </div>
          ))}

          {auditLog.length === 0 && (
            <p className="text-center text-muted-foreground py-8">
              No audit events found.
            </p>
          )}
        </div>
      </CardContent>
    </Card>
  );
}

// Security Section
function SecuritySection({ 
  securityStatus, 
  settings, 
  onExport 
}: {
  securityStatus: any;
  settings: any[];
  onExport: (includeEncrypted?: boolean) => void;
}) {
  return (
    <div className="space-y-4">
      <Card>
        <CardHeader>
          <CardTitle className="flex items-center gap-2">
            <Shield className="h-5 w-5" />
            Security Overview
          </CardTitle>
        </CardHeader>
        <CardContent>
          {securityStatus && (
            <div className="grid grid-cols-2 md:grid-cols-3 gap-4">
              <div className="text-center p-4 border rounded-lg">
                <div className="text-2xl font-bold text-orange-600">
                  {securityStatus.critical_settings}
                </div>
                <div className="text-sm text-muted-foreground">Critical Settings</div>
              </div>
              <div className="text-center p-4 border rounded-lg">
                <div className="text-2xl font-bold text-yellow-600">
                  {securityStatus.recommendations_count}
                </div>
                <div className="text-sm text-muted-foreground">Recommendations</div>
              </div>
              <div className="text-center p-4 border rounded-lg">
                <div className="text-2xl font-bold text-blue-600">
                  {securityStatus.recent_audit_events}
                </div>
                <div className="text-sm text-muted-foreground">Recent Events (24h)</div>
              </div>
            </div>
          )}
        </CardContent>
      </Card>

      <Card>
        <CardHeader>
          <CardTitle>Export Settings</CardTitle>
          <CardDescription>
            Download settings for backup or migration
          </CardDescription>
        </CardHeader>
        <CardContent className="space-y-4">
          <div className="flex gap-2">
            <Button 
              variant="outline" 
              onClick={() => onExport(false)}
            >
              Export (Exclude Sensitive)
            </Button>
            <Button 
              variant="outline" 
              onClick={() => onExport(true)}
            >
              Export (Include All)
            </Button>
          </div>
          <Alert>
            <Info className="h-4 w-4" />
            <AlertDescription>
              Exports including sensitive data should be handled with extreme care and encrypted during transfer.
            </AlertDescription>
          </Alert>
        </CardContent>
      </Card>
    </div>
  );
}

// Sync Section
function SyncSection({ 
  syncStatus, 
  onSync 
}: {
  syncStatus: any;
  onSync: (keys?: string[]) => void;
}) {
  return (
    <div className="space-y-4">
      <Card>
        <CardHeader>
          <CardTitle className="flex items-center gap-2">
            <Zap className="h-5 w-5" />
            Real-time Sync Status
          </CardTitle>
        </CardHeader>
        <CardContent>
          {syncStatus && (
            <div className="space-y-4">
              <div className="grid grid-cols-2 md:grid-cols-3 gap-4">
                <div className="text-center p-4 border rounded-lg">
                  <div className="text-2xl font-bold">
                    {syncStatus.activeChannels?.length || 0}
                  </div>
                  <div className="text-sm text-muted-foreground">Active Channels</div>
                </div>
                <div className="text-center p-4 border rounded-lg">
                  <div className="text-2xl font-bold">
                    {syncStatus.queueSize || 0}
                  </div>
                  <div className="text-sm text-muted-foreground">Queue Size</div>
                </div>
                <div className="text-center p-4 border rounded-lg">
                  <div className={`text-2xl font-bold ${
                    syncStatus.isProcessing ? 'text-yellow-600' : 'text-green-600'
                  }`}>
                    {syncStatus.isProcessing ? 'Processing' : 'Ready'}
                  </div>
                  <div className="text-sm text-muted-foreground">Status</div>
                </div>
              </div>

              <div>
                <h4 className="font-medium mb-2">Active Channels:</h4>
                <div className="flex flex-wrap gap-2">
                  {syncStatus.activeChannels?.map((channel: string) => (
                    <Badge key={channel} variant="outline">{channel}</Badge>
                  )) || <span className="text-muted-foreground">No active channels</span>}
                </div>
              </div>
            </div>
          )}
        </CardContent>
      </Card>

      <Card>
        <CardHeader>
          <CardTitle>Manual Sync</CardTitle>
          <CardDescription>
            Force synchronization to website clients
          </CardDescription>
        </CardHeader>
        <CardContent>
          <Button onClick={() => onSync()}>
            <Globe className="h-4 w-4 mr-1" />
            Sync All Public Settings
          </Button>
        </CardContent>
      </Card>
    </div>
  );
}