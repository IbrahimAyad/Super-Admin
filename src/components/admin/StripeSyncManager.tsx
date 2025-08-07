import React, { useState, useEffect } from 'react';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { Badge } from '@/components/ui/badge';
import { Alert, AlertDescription, AlertTitle } from '@/components/ui/alert';
import { Progress } from '@/components/ui/progress';
import { Tabs, TabsContent, TabsList, TabsTrigger } from '@/components/ui/tabs';
import { 
  Loader2, 
  CheckCircle2, 
  XCircle, 
  AlertCircle, 
  RefreshCw, 
  Play,
  Pause,
  RotateCcw,
  Shield,
  Database,
  CreditCard
} from 'lucide-react';
import { stripeSyncService } from '@/lib/services/stripeSync';
import { useToast } from '@/hooks/use-toast';

export function StripeSyncManager() {
  const [syncStatus, setSyncStatus] = useState<any>(null);
  const [isSyncing, setIsSyncing] = useState(false);
  const [isDryRun, setIsDryRun] = useState(true);
  const [selectedCategories, setSelectedCategories] = useState<string[]>([]);
  const [syncProgress, setSyncProgress] = useState(0);
  const [validationResult, setValidationResult] = useState<any>(null);
  const [categoryProgress, setCategoryProgress] = useState<Record<string, { synced: number; total: number; }>>({});
  const [isProgressiveSync, setIsProgressiveSync] = useState(false);
  const [syncPhases, setSyncPhases] = useState<any[]>([]);
  const { toast } = useToast();

  // Product categories
  const categories = [
    'Luxury Velvet Blazers',
    'Men\'s Suits',
    'Sparkle & Sequin Blazers',
    'Vest & Tie Sets',
    'Prom & Formal Blazers',
    'Men\'s Dress Shirts',
    'Suspender & Bowtie Sets',
    'Casual Summer Blazers',
    'Sparkle Vest Sets'
  ];

  useEffect(() => {
    loadSyncStatus();
    validateConfig();
  }, []);

  const loadSyncStatus = async () => {
    try {
      const [status, progress] = await Promise.all([
        stripeSyncService.getSyncStatus(),
        stripeSyncService.getSyncProgress()
      ]);
      
      setSyncStatus(status);
      setCategoryProgress(progress.categoryProgress);
      
      if (status.syncedProducts > 0 && status.totalProducts > 0) {
        setSyncProgress((status.syncedProducts / status.totalProducts) * 100);
      }
    } catch (error) {
      console.error('Failed to load sync status:', error);
    }
  };

  const validateConfig = async () => {
    try {
      const result = await stripeSyncService.validateStripeConfig();
      setValidationResult(result);
    } catch (error) {
      console.error('Failed to validate config:', error);
    }
  };

  const handleSync = async () => {
    setIsSyncing(true);
    setSyncPhases([]);
    
    try {
      let result;
      
      if (isProgressiveSync) {
        result = await stripeSyncService.executeProgressiveSync({
          dryRun: isDryRun,
          batchSize: 5,
          skipExisting: true
        });
        
        setSyncPhases(result.phases);
        
        toast({
          title: isDryRun ? "Progressive Dry Run Complete" : "Progressive Sync Complete",
          description: `Completed ${result.phases.length} phases. Overall success: ${result.overallSuccess ? 'Yes' : 'No'}`,
          variant: result.overallSuccess ? "default" : "destructive"
        });
      } else {
        const syncResult = await stripeSyncService.syncProducts({
          dryRun: isDryRun,
          batchSize: 5,
          categories: selectedCategories.length > 0 ? selectedCategories : undefined,
          skipExisting: true
        });

        if (syncResult.success) {
          toast({
            title: isDryRun ? "Dry Run Complete" : "Sync Complete",
            description: `Processed ${syncResult.productsProcessed} products with ${syncResult.errors.length} errors`,
            variant: syncResult.errors.length > 0 ? "destructive" : "default"
          });
        } else {
          toast({
            title: "Sync Failed",
            description: `Encountered ${syncResult.errors.length} errors during sync`,
            variant: "destructive"
          });
        }
      }

      // Reload status
      await loadSyncStatus();
    } catch (error) {
      toast({
        title: "Sync Error",
        description: error.message,
        variant: "destructive"
      });
    } finally {
      setIsSyncing(false);
    }
  };

  const handleRollback = async (productIds: string[]) => {
    if (!confirm('Are you sure you want to rollback these products? This will remove their Stripe IDs.')) {
      return;
    }

    try {
      const result = await stripeSyncService.rollbackSync(productIds);
      
      toast({
        title: result.success ? "Rollback Complete" : "Rollback Partial",
        description: `Rolled back ${result.rolledBack} products`,
        variant: result.success ? "default" : "destructive"
      });

      await loadSyncStatus();
    } catch (error) {
      toast({
        title: "Rollback Error",
        description: error.message,
        variant: "destructive"
      });
    }
  };

  return (
    <Card>
      <CardHeader>
        <div className="flex items-center justify-between">
          <div>
            <CardTitle className="flex items-center gap-2">
              <CreditCard className="h-5 w-5" />
              Stripe Product Sync
            </CardTitle>
            <CardDescription>
              Safely sync your products to Stripe for payment processing
            </CardDescription>
          </div>
          <Button 
            variant="outline" 
            size="sm"
            onClick={loadSyncStatus}
            disabled={isSyncing}
          >
            <RefreshCw className="h-4 w-4 mr-2" />
            Refresh
          </Button>
        </div>
      </CardHeader>
      <CardContent>
        {/* Validation Status */}
        {validationResult && !validationResult.isValid && (
          <Alert variant="destructive" className="mb-4">
            <AlertCircle className="h-4 w-4" />
            <AlertTitle>Configuration Issues</AlertTitle>
            <AlertDescription>
              <ul className="list-disc list-inside mt-2">
                {validationResult.errors.map((error: string, i: number) => (
                  <li key={i}>{error}</li>
                ))}
              </ul>
            </AlertDescription>
          </Alert>
        )}

        <Tabs defaultValue="status" className="space-y-4">
          <TabsList className="grid w-full grid-cols-3">
            <TabsTrigger value="status">Status</TabsTrigger>
            <TabsTrigger value="sync">Sync Products</TabsTrigger>
            <TabsTrigger value="safety">Safety Controls</TabsTrigger>
          </TabsList>

          <TabsContent value="status" className="space-y-4">
            {syncStatus && (
              <>
                {/* Progress Overview */}
                <div className="space-y-2">
                  <div className="flex justify-between text-sm">
                    <span>Overall Progress</span>
                    <span>{syncStatus.syncedProducts} / {syncStatus.totalProducts} products</span>
                  </div>
                  <Progress value={syncProgress} className="h-2" />
                </div>

                {/* Status Cards */}
                <div className="grid grid-cols-2 md:grid-cols-4 gap-4">
                  <div className="space-y-1">
                    <p className="text-sm text-muted-foreground">Products Synced</p>
                    <p className="text-2xl font-bold">{syncStatus.syncedProducts}</p>
                  </div>
                  <div className="space-y-1">
                    <p className="text-sm text-muted-foreground">Pending</p>
                    <p className="text-2xl font-bold">{syncStatus.pendingProducts}</p>
                  </div>
                  <div className="space-y-1">
                    <p className="text-sm text-muted-foreground">Variants Synced</p>
                    <p className="text-2xl font-bold">{syncStatus.syncedVariants}</p>
                  </div>
                  <div className="space-y-1">
                    <p className="text-sm text-muted-foreground">Last Sync</p>
                    <p className="text-sm font-medium">
                      {syncStatus.lastSyncAt ? new Date(syncStatus.lastSyncAt).toLocaleString() : 'Never'}
                    </p>
                  </div>
                </div>

                {/* Status Indicators */}
                <div className="flex gap-2">
                  {validationResult?.isValid && (
                    <Badge variant="default" className="gap-1">
                      <CheckCircle2 className="h-3 w-3" />
                      Stripe Connected
                    </Badge>
                  )}
                  {syncStatus.syncedProducts > 0 && (
                    <Badge variant="secondary" className="gap-1">
                      <Database className="h-3 w-3" />
                      Database Ready
                    </Badge>
                  )}
                  {syncStatus.failedProducts > 0 && (
                    <Badge variant="destructive" className="gap-1">
                      <XCircle className="h-3 w-3" />
                      {syncStatus.failedProducts} Failed
                    </Badge>
                  )}
                </div>
              </>
            )}
          </TabsContent>

          <TabsContent value="sync" className="space-y-4">
            {/* Sync Mode */}
            <div className="flex items-center gap-4 p-4 border rounded-lg">
              <Shield className="h-5 w-5 text-muted-foreground" />
              <div className="flex-1">
                <p className="font-medium">Dry Run Mode</p>
                <p className="text-sm text-muted-foreground">
                  Test the sync without making changes
                </p>
              </div>
              <label className="relative inline-flex items-center cursor-pointer">
                <input 
                  type="checkbox" 
                  checked={isDryRun}
                  onChange={(e) => setIsDryRun(e.target.checked)}
                  className="sr-only peer"
                />
                <div className="w-11 h-6 bg-gray-200 peer-focus:outline-none rounded-full peer dark:bg-gray-700 peer-checked:after:translate-x-full rtl:peer-checked:after:-translate-x-full peer-checked:after:border-white after:content-[''] after:absolute after:top-[2px] after:start-[2px] after:bg-white after:border-gray-300 after:border after:rounded-full after:h-5 after:w-5 after:transition-all dark:border-gray-600 peer-checked:bg-blue-600"></div>
              </label>
            </div>

            {/* Progressive Sync Mode */}
            <div className="flex items-center gap-4 p-4 border rounded-lg">
              <Play className="h-5 w-5 text-muted-foreground" />
              <div className="flex-1">
                <p className="font-medium">Progressive Sync</p>
                <p className="text-sm text-muted-foreground">
                  Sync categories progressively from smallest to largest (recommended for first sync)
                </p>
              </div>
              <label className="relative inline-flex items-center cursor-pointer">
                <input 
                  type="checkbox" 
                  checked={isProgressiveSync}
                  onChange={(e) => setIsProgressiveSync(e.target.checked)}
                  className="sr-only peer"
                />
                <div className="w-11 h-6 bg-gray-200 peer-focus:outline-none rounded-full peer dark:bg-gray-700 peer-checked:after:translate-x-full rtl:peer-checked:after:-translate-x-full peer-checked:after:border-white after:content-[''] after:absolute after:top-[2px] after:start-[2px] after:bg-white after:border-gray-300 after:border after:rounded-full after:h-5 after:w-5 after:transition-all dark:border-gray-600 peer-checked:bg-blue-600"></div>
              </label>
            </div>

            {/* Category Selection - Hidden for Progressive Sync */}
            {!isProgressiveSync && (
              <div className="space-y-2">
                <p className="text-sm font-medium">Select Categories to Sync</p>
                <div className="grid grid-cols-2 gap-2">
                  {categories.map(category => {
                    const progress = categoryProgress[category];
                    return (
                      <label key={category} className="flex items-center gap-2 p-2 border rounded hover:bg-accent cursor-pointer">
                        <input
                          type="checkbox"
                          checked={selectedCategories.includes(category)}
                          onChange={(e) => {
                            if (e.target.checked) {
                              setSelectedCategories([...selectedCategories, category]);
                            } else {
                              setSelectedCategories(selectedCategories.filter(c => c !== category));
                            }
                          }}
                          className="rounded border-gray-300"
                        />
                        <div className="flex-1">
                          <span className="text-sm">{category}</span>
                          {progress && (
                            <div className="text-xs text-muted-foreground">
                              {progress.synced}/{progress.total} synced
                            </div>
                          )}
                        </div>
                      </label>
                    );
                  })}
                </div>
              </div>
            )}

            {/* Progressive Sync Phases Display */}
            {isProgressiveSync && syncPhases.length > 0 && (
              <div className="space-y-3">
                <p className="text-sm font-medium">Sync Phases Progress</p>
                <div className="space-y-2">
                  {syncPhases.map((phase, index) => (
                    <div key={index} className="flex items-center justify-between p-3 border rounded-lg">
                      <div className="space-y-1">
                        <div className="flex items-center gap-2">
                          <span className="font-medium">Phase {phase.phase}: {phase.category}</span>
                          {phase.result.success ? (
                            <CheckCircle2 className="h-4 w-4 text-green-500" />
                          ) : (
                            <XCircle className="h-4 w-4 text-red-500" />
                          )}
                        </div>
                        <div className="text-sm text-muted-foreground">
                          {phase.productCount} products • {phase.result.productsProcessed} processed • {phase.result.errors.length} errors
                        </div>
                      </div>
                      <Badge variant={phase.result.success ? "default" : "destructive"}>
                        {phase.result.success ? "Complete" : "Failed"}
                      </Badge>
                    </div>
                  ))}
                </div>
              </div>
            )}

            {/* Sync Button */}
            <div className="flex gap-2">
              <Button 
                onClick={handleSync}
                disabled={isSyncing || (validationResult && !validationResult.isValid)}
                className="flex-1"
              >
                {isSyncing ? (
                  <>
                    <Loader2 className="h-4 w-4 mr-2 animate-spin" />
                    Syncing...
                  </>
                ) : (
                  <>
                    <Play className="h-4 w-4 mr-2" />
                    {isProgressiveSync 
                      ? (isDryRun ? 'Start Progressive Dry Run' : 'Start Progressive Sync')
                      : (isDryRun ? 'Start Dry Run' : 'Start Sync')
                    }
                  </>
                )}
              </Button>
              {isSyncing && (
                <Button variant="outline" size="icon">
                  <Pause className="h-4 w-4" />
                </Button>
              )}
            </div>

            {/* Sync Info */}
            <Alert>
              <AlertCircle className="h-4 w-4" />
              <AlertTitle>How Sync Works</AlertTitle>
              <AlertDescription>
                <ul className="list-disc list-inside mt-2 space-y-1">
                  <li>Products are synced in batches of 5 to avoid rate limits</li>
                  <li>Each product's variants are created as Stripe prices</li>
                  <li>Existing Stripe products are skipped by default</li>
                  <li>All changes are logged for audit purposes</li>
                </ul>
              </AlertDescription>
            </Alert>
          </TabsContent>

          <TabsContent value="safety" className="space-y-4">
            <Alert>
              <Shield className="h-4 w-4" />
              <AlertTitle>Safety Features</AlertTitle>
              <AlertDescription>
                This sync process includes multiple safety mechanisms to protect your data
              </AlertDescription>
            </Alert>

            <div className="space-y-3">
              <div className="flex items-start gap-3 p-3 border rounded-lg">
                <CheckCircle2 className="h-5 w-5 text-green-500 mt-0.5" />
                <div>
                  <p className="font-medium">Non-Destructive</p>
                  <p className="text-sm text-muted-foreground">
                    Original product data is never modified, only Stripe IDs are added
                  </p>
                </div>
              </div>

              <div className="flex items-start gap-3 p-3 border rounded-lg">
                <CheckCircle2 className="h-5 w-5 text-green-500 mt-0.5" />
                <div>
                  <p className="font-medium">Rollback Support</p>
                  <p className="text-sm text-muted-foreground">
                    Any sync can be rolled back to remove Stripe IDs
                  </p>
                </div>
              </div>

              <div className="flex items-start gap-3 p-3 border rounded-lg">
                <CheckCircle2 className="h-5 w-5 text-green-500 mt-0.5" />
                <div>
                  <p className="font-medium">Audit Logging</p>
                  <p className="text-sm text-muted-foreground">
                    All sync operations are logged in the stripe_sync_log table
                  </p>
                </div>
              </div>

              <div className="flex items-start gap-3 p-3 border rounded-lg">
                <CheckCircle2 className="h-5 w-5 text-green-500 mt-0.5" />
                <div>
                  <p className="font-medium">Rate Limiting</p>
                  <p className="text-sm text-muted-foreground">
                    Automatic delays between batches to respect Stripe's rate limits
                  </p>
                </div>
              </div>
            </div>

            {/* Emergency Rollback */}
            <div className="p-4 border border-destructive/50 rounded-lg space-y-3">
              <div className="flex items-center gap-2 text-destructive">
                <RotateCcw className="h-5 w-5" />
                <p className="font-medium">Emergency Rollback</p>
              </div>
              <p className="text-sm text-muted-foreground">
                Remove all Stripe IDs and reset sync status. Use only if needed.
              </p>
              <Button 
                variant="destructive" 
                size="sm"
                onClick={() => {
                  if (confirm('This will remove ALL Stripe IDs from your products. Continue?')) {
                    // Implement full rollback
                  }
                }}
              >
                <RotateCcw className="h-4 w-4 mr-2" />
                Rollback All Products
              </Button>
            </div>
          </TabsContent>
        </Tabs>
      </CardContent>
    </Card>
  );
}