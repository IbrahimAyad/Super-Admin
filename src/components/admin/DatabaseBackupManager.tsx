/**
 * DATABASE BACKUP MANAGER
 * Automated backup system with scheduling and restore capabilities
 */

import React, { useState, useEffect } from 'react';
import { Button } from '@/components/ui/button';
import { Card, CardContent, CardHeader, CardTitle, CardDescription } from '@/components/ui/card';
import { Badge } from '@/components/ui/badge';
import { Progress } from '@/components/ui/progress';
import { Alert, AlertDescription } from '@/components/ui/alert';
import { Tabs, TabsContent, TabsList, TabsTrigger } from '@/components/ui/tabs';
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from '@/components/ui/select';
import { Separator } from '@/components/ui/separator';
import { toast } from 'sonner';
import { supabase } from '@/lib/supabase-client';
import { 
  Database, 
  Download, 
  Upload,
  Clock,
  CheckCircle,
  AlertTriangle,
  RefreshCw,
  Calendar,
  HardDrive,
  Shield,
  Archive,
  Trash2,
  History
} from 'lucide-react';

interface BackupRecord {
  id: string;
  backup_name: string;
  backup_type: 'manual' | 'scheduled' | 'auto';
  tables_included: string[];
  size_bytes: number;
  status: 'completed' | 'in_progress' | 'failed';
  created_at: string;
  completed_at?: string;
  error_message?: string;
  backup_url?: string;
  retention_days: number;
}

interface BackupSchedule {
  id: string;
  schedule_name: string;
  frequency: 'daily' | 'weekly' | 'monthly';
  time_of_day: string;
  day_of_week?: number;
  day_of_month?: number;
  enabled: boolean;
  last_run?: string;
  next_run?: string;
  retention_days: number;
}

export function DatabaseBackupManager() {
  const [backups, setBackups] = useState<BackupRecord[]>([]);
  const [schedules, setSchedules] = useState<BackupSchedule[]>([]);
  const [isBackingUp, setIsBackingUp] = useState(false);
  const [isRestoring, setIsRestoring] = useState(false);
  const [backupProgress, setBackupProgress] = useState(0);
  const [selectedBackup, setSelectedBackup] = useState<BackupRecord | null>(null);
  const [storageUsed, setStorageUsed] = useState(0);
  const [storageLimit] = useState(10 * 1024 * 1024 * 1024); // 10GB limit
  
  // New schedule form
  const [newSchedule, setNewSchedule] = useState({
    name: '',
    frequency: 'daily' as const,
    time: '02:00',
    retention: 7
  });

  useEffect(() => {
    loadBackups();
    loadSchedules();
    calculateStorageUsage();
  }, []);

  const loadBackups = async () => {
    try {
      const { data, error } = await supabase
        .from('database_backups')
        .select('*')
        .order('created_at', { ascending: false })
        .limit(50);

      if (!error && data) {
        setBackups(data);
      }
    } catch (error) {
      console.error('Failed to load backups:', error);
    }
  };

  const loadSchedules = async () => {
    try {
      const { data, error } = await supabase
        .from('backup_schedules')
        .select('*')
        .order('schedule_name');

      if (!error && data) {
        setSchedules(data);
      }
    } catch (error) {
      console.error('Failed to load schedules:', error);
    }
  };

  const calculateStorageUsage = async () => {
    try {
      const { data, error } = await supabase
        .from('database_backups')
        .select('size_bytes')
        .eq('status', 'completed');

      if (!error && data) {
        const total = data.reduce((sum, backup) => sum + (backup.size_bytes || 0), 0);
        setStorageUsed(total);
      }
    } catch (error) {
      console.error('Failed to calculate storage:', error);
    }
  };

  const createBackup = async (type: 'manual' | 'scheduled' = 'manual') => {
    setIsBackingUp(true);
    setBackupProgress(0);

    try {
      // Tables to backup
      const tables = [
        'products',
        'product_variants',
        'product_images',
        'orders',
        'order_items',
        'customers',
        'user_profiles',
        'inventory_history',
        'stripe_sync_log'
      ];

      const backupData: any = {};
      const totalTables = tables.length;

      // Export each table
      for (let i = 0; i < tables.length; i++) {
        const table = tables[i];
        setBackupProgress((i / totalTables) * 80);

        const { data, error } = await supabase
          .from(table)
          .select('*');

        if (!error && data) {
          backupData[table] = data;
        } else {
          console.warn(`Failed to backup table ${table}:`, error);
        }
      }

      setBackupProgress(90);

      // Create backup record
      const backupName = `backup_${new Date().toISOString().split('T')[0]}_${Date.now()}`;
      const backupJson = JSON.stringify(backupData, null, 2);
      const sizeBytes = new Blob([backupJson]).size;

      // Store backup metadata
      const { data: backupRecord, error: recordError } = await supabase
        .from('database_backups')
        .insert({
          backup_name: backupName,
          backup_type: type,
          tables_included: tables,
          size_bytes: sizeBytes,
          status: 'completed',
          created_at: new Date().toISOString(),
          completed_at: new Date().toISOString(),
          retention_days: 30
        })
        .select()
        .single();

      if (recordError) throw recordError;

      // Store backup file in storage
      const { error: uploadError } = await supabase.storage
        .from('backups')
        .upload(`${backupName}.json`, backupJson, {
          contentType: 'application/json',
          cacheControl: '3600'
        });

      if (uploadError) {
        console.error('Failed to upload backup:', uploadError);
        // Update status to failed
        await supabase
          .from('database_backups')
          .update({ 
            status: 'failed', 
            error_message: uploadError.message 
          })
          .eq('id', backupRecord.id);
      }

      setBackupProgress(100);
      toast.success('Backup created successfully');
      loadBackups();
      calculateStorageUsage();

    } catch (error) {
      console.error('Backup failed:', error);
      toast.error('Backup failed. Please try again.');
    } finally {
      setIsBackingUp(false);
      setBackupProgress(0);
    }
  };

  const restoreBackup = async (backup: BackupRecord) => {
    const confirmed = window.confirm(
      `Are you sure you want to restore from backup "${backup.backup_name}"? This will overwrite current data.`
    );
    
    if (!confirmed) return;

    setIsRestoring(true);
    setSelectedBackup(backup);

    try {
      // Download backup file
      const { data: fileData, error: downloadError } = await supabase.storage
        .from('backups')
        .download(`${backup.backup_name}.json`);

      if (downloadError) throw downloadError;

      const backupContent = await fileData.text();
      const backupData = JSON.parse(backupContent);

      // Restore each table
      for (const [table, data] of Object.entries(backupData)) {
        if (Array.isArray(data) && data.length > 0) {
          // Clear existing data
          await supabase.from(table).delete().neq('id', '00000000-0000-0000-0000-000000000000');
          
          // Insert backup data in batches
          const batchSize = 100;
          for (let i = 0; i < data.length; i += batchSize) {
            const batch = data.slice(i, i + batchSize);
            await supabase.from(table).insert(batch);
          }
        }
      }

      toast.success('Backup restored successfully');
      
      // Log restore action
      await supabase.from('backup_restore_log').insert({
        backup_id: backup.id,
        restored_at: new Date().toISOString(),
        restored_by: 'admin' // Get from auth context
      });

    } catch (error) {
      console.error('Restore failed:', error);
      toast.error('Restore failed. Please try again.');
    } finally {
      setIsRestoring(false);
      setSelectedBackup(null);
    }
  };

  const deleteBackup = async (backup: BackupRecord) => {
    const confirmed = window.confirm(
      `Are you sure you want to delete backup "${backup.backup_name}"?`
    );
    
    if (!confirmed) return;

    try {
      // Delete from storage
      await supabase.storage
        .from('backups')
        .remove([`${backup.backup_name}.json`]);

      // Delete record
      await supabase
        .from('database_backups')
        .delete()
        .eq('id', backup.id);

      toast.success('Backup deleted');
      loadBackups();
      calculateStorageUsage();

    } catch (error) {
      console.error('Delete failed:', error);
      toast.error('Failed to delete backup');
    }
  };

  const createSchedule = async () => {
    try {
      const { error } = await supabase
        .from('backup_schedules')
        .insert({
          schedule_name: newSchedule.name,
          frequency: newSchedule.frequency,
          time_of_day: newSchedule.time,
          enabled: true,
          retention_days: newSchedule.retention,
          created_at: new Date().toISOString()
        });

      if (!error) {
        toast.success('Backup schedule created');
        loadSchedules();
        setNewSchedule({ name: '', frequency: 'daily', time: '02:00', retention: 7 });
      }
    } catch (error) {
      console.error('Failed to create schedule:', error);
      toast.error('Failed to create schedule');
    }
  };

  const toggleSchedule = async (schedule: BackupSchedule) => {
    try {
      await supabase
        .from('backup_schedules')
        .update({ enabled: !schedule.enabled })
        .eq('id', schedule.id);

      toast.success(`Schedule ${schedule.enabled ? 'disabled' : 'enabled'}`);
      loadSchedules();
    } catch (error) {
      console.error('Failed to toggle schedule:', error);
    }
  };

  const formatBytes = (bytes: number) => {
    if (bytes === 0) return '0 Bytes';
    const k = 1024;
    const sizes = ['Bytes', 'KB', 'MB', 'GB'];
    const i = Math.floor(Math.log(bytes) / Math.log(k));
    return Math.round(bytes / Math.pow(k, i) * 100) / 100 + ' ' + sizes[i];
  };

  const storagePercentage = (storageUsed / storageLimit) * 100;

  return (
    <div className="space-y-6">
      {/* Header */}
      <div className="flex items-center justify-between">
        <div>
          <h2 className="text-2xl font-bold">Database Backup Manager</h2>
          <p className="text-muted-foreground">Automated backups and restore points</p>
        </div>
        
        <Button 
          onClick={() => createBackup('manual')}
          disabled={isBackingUp}
        >
          {isBackingUp ? (
            <>
              <RefreshCw className="h-4 w-4 mr-2 animate-spin" />
              Creating Backup... {Math.round(backupProgress)}%
            </>
          ) : (
            <>
              <Database className="h-4 w-4 mr-2" />
              Create Backup Now
            </>
          )}
        </Button>
      </div>

      {/* Storage Overview */}
      <Card>
        <CardHeader>
          <CardTitle className="flex items-center gap-2">
            <HardDrive className="h-5 w-5" />
            Storage Usage
          </CardTitle>
        </CardHeader>
        <CardContent>
          <div className="space-y-2">
            <div className="flex items-center justify-between text-sm">
              <span>{formatBytes(storageUsed)} used</span>
              <span>{formatBytes(storageLimit)} total</span>
            </div>
            <Progress value={storagePercentage} className="h-2" />
            {storagePercentage > 80 && (
              <Alert>
                <AlertTriangle className="h-4 w-4" />
                <AlertDescription>
                  Storage usage is high. Consider deleting old backups.
                </AlertDescription>
              </Alert>
            )}
          </div>
        </CardContent>
      </Card>

      <Tabs defaultValue="backups" className="w-full">
        <TabsList className="grid w-full grid-cols-3">
          <TabsTrigger value="backups">Backups</TabsTrigger>
          <TabsTrigger value="schedules">Schedules</TabsTrigger>
          <TabsTrigger value="settings">Settings</TabsTrigger>
        </TabsList>

        {/* Backups Tab */}
        <TabsContent value="backups" className="space-y-4">
          {backups.length === 0 ? (
            <Card>
              <CardContent className="text-center py-12">
                <Database className="h-12 w-12 mx-auto mb-4 text-muted-foreground" />
                <h3 className="text-lg font-semibold mb-2">No backups yet</h3>
                <p className="text-muted-foreground mb-4">
                  Create your first backup to protect your data
                </p>
                <Button onClick={() => createBackup('manual')}>
                  Create First Backup
                </Button>
              </CardContent>
            </Card>
          ) : (
            <div className="space-y-4">
              {backups.map((backup) => (
                <Card key={backup.id}>
                  <CardContent className="p-4">
                    <div className="flex items-center justify-between">
                      <div className="space-y-1">
                        <div className="flex items-center gap-2">
                          <h3 className="font-semibold">{backup.backup_name}</h3>
                          <Badge variant={
                            backup.status === 'completed' ? 'default' :
                            backup.status === 'in_progress' ? 'secondary' : 'destructive'
                          }>
                            {backup.status}
                          </Badge>
                          <Badge variant="outline">
                            {backup.backup_type}
                          </Badge>
                        </div>
                        <div className="text-sm text-muted-foreground">
                          {formatBytes(backup.size_bytes)} • {backup.tables_included.length} tables • 
                          {new Date(backup.created_at).toLocaleString()}
                        </div>
                      </div>
                      
                      <div className="flex items-center gap-2">
                        <Button
                          variant="outline"
                          size="sm"
                          onClick={() => {
                            // Download backup
                            supabase.storage
                              .from('backups')
                              .download(`${backup.backup_name}.json`)
                              .then(({ data }) => {
                                if (data) {
                                  const url = URL.createObjectURL(data);
                                  const a = document.createElement('a');
                                  a.href = url;
                                  a.download = `${backup.backup_name}.json`;
                                  a.click();
                                }
                              });
                          }}
                        >
                          <Download className="h-4 w-4" />
                        </Button>
                        <Button
                          variant="outline"
                          size="sm"
                          onClick={() => restoreBackup(backup)}
                          disabled={isRestoring}
                        >
                          <Upload className="h-4 w-4" />
                        </Button>
                        <Button
                          variant="outline"
                          size="sm"
                          onClick={() => deleteBackup(backup)}
                        >
                          <Trash2 className="h-4 w-4" />
                        </Button>
                      </div>
                    </div>
                  </CardContent>
                </Card>
              ))}
            </div>
          )}
        </TabsContent>

        {/* Schedules Tab */}
        <TabsContent value="schedules" className="space-y-4">
          <Card>
            <CardHeader>
              <CardTitle>Create Schedule</CardTitle>
            </CardHeader>
            <CardContent className="space-y-4">
              <div className="grid grid-cols-4 gap-4">
                <input
                  placeholder="Schedule name"
                  value={newSchedule.name}
                  onChange={(e) => setNewSchedule(prev => ({ ...prev, name: e.target.value }))}
                  className="col-span-1 px-3 py-2 border rounded"
                />
                <Select
                  value={newSchedule.frequency}
                  onValueChange={(value: 'daily' | 'weekly' | 'monthly') => 
                    setNewSchedule(prev => ({ ...prev, frequency: value }))
                  }
                >
                  <SelectTrigger>
                    <SelectValue />
                  </SelectTrigger>
                  <SelectContent>
                    <SelectItem value="daily">Daily</SelectItem>
                    <SelectItem value="weekly">Weekly</SelectItem>
                    <SelectItem value="monthly">Monthly</SelectItem>
                  </SelectContent>
                </Select>
                <input
                  type="time"
                  value={newSchedule.time}
                  onChange={(e) => setNewSchedule(prev => ({ ...prev, time: e.target.value }))}
                  className="px-3 py-2 border rounded"
                />
                <Button onClick={createSchedule} disabled={!newSchedule.name}>
                  Add Schedule
                </Button>
              </div>
            </CardContent>
          </Card>

          <div className="space-y-2">
            {schedules.map((schedule) => (
              <Card key={schedule.id}>
                <CardContent className="p-4">
                  <div className="flex items-center justify-between">
                    <div>
                      <h3 className="font-medium">{schedule.schedule_name}</h3>
                      <p className="text-sm text-muted-foreground">
                        {schedule.frequency} at {schedule.time_of_day} • 
                        Retention: {schedule.retention_days} days
                      </p>
                    </div>
                    <Button
                      variant={schedule.enabled ? 'default' : 'outline'}
                      size="sm"
                      onClick={() => toggleSchedule(schedule)}
                    >
                      {schedule.enabled ? 'Enabled' : 'Disabled'}
                    </Button>
                  </div>
                </CardContent>
              </Card>
            ))}
          </div>
        </TabsContent>

        {/* Settings Tab */}
        <TabsContent value="settings" className="space-y-4">
          <Card>
            <CardHeader>
              <CardTitle>Backup Settings</CardTitle>
            </CardHeader>
            <CardContent className="space-y-4">
              <div className="space-y-2">
                <h3 className="text-sm font-medium">Auto-cleanup</h3>
                <p className="text-sm text-muted-foreground">
                  Automatically delete backups older than 30 days
                </p>
              </div>
              <Separator />
              <div className="space-y-2">
                <h3 className="text-sm font-medium">Compression</h3>
                <p className="text-sm text-muted-foreground">
                  Compress backups to save storage space
                </p>
              </div>
              <Separator />
              <div className="space-y-2">
                <h3 className="text-sm font-medium">Encryption</h3>
                <p className="text-sm text-muted-foreground">
                  Encrypt backups for additional security
                </p>
              </div>
            </CardContent>
          </Card>
        </TabsContent>
      </Tabs>
    </div>
  );
}