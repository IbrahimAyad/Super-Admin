import { useState, useEffect } from 'react';
import { Button } from '@/components/ui/button';
import { Alert, AlertDescription } from '@/components/ui/alert';
import { Badge } from '@/components/ui/badge';
import { ArrowRight, Database, Sparkles, AlertTriangle } from 'lucide-react';

interface ProductSystemToggleProps {
  onSystemChange: (system: 'old' | 'new') => void;
}

export function ProductSystemToggle({ onSystemChange }: ProductSystemToggleProps) {
  const [currentSystem, setCurrentSystem] = useState<'old' | 'new'>('old');
  const [showWarning, setShowWarning] = useState(false);
  
  useEffect(() => {
    // Check localStorage for preference
    const saved = localStorage.getItem('product_system');
    if (saved === 'new') {
      setCurrentSystem('new');
      onSystemChange('new');
    }
  }, [onSystemChange]);
  
  const switchSystem = (system: 'old' | 'new') => {
    if (system === 'new' && currentSystem === 'old') {
      setShowWarning(true);
      return;
    }
    
    setCurrentSystem(system);
    localStorage.setItem('product_system', system);
    onSystemChange(system);
    setShowWarning(false);
  };
  
  const confirmSwitch = () => {
    setCurrentSystem('new');
    localStorage.setItem('product_system', 'new');
    onSystemChange('new');
    setShowWarning(false);
  };
  
  return (
    <>
      <Alert className="mb-4 border-2">
        <div className="flex items-center justify-between">
          <div className="flex items-center gap-3">
            <Database className="h-5 w-5" />
            <div>
              <div className="flex items-center gap-2">
                <p className="font-semibold">Product System</p>
                {currentSystem === 'new' && (
                  <Badge className="bg-green-100 text-green-800">
                    <Sparkles className="h-3 w-3 mr-1" />
                    Enhanced Active
                  </Badge>
                )}
              </div>
              <p className="text-sm text-muted-foreground mt-1">
                {currentSystem === 'old' 
                  ? 'Using legacy products table (limited features)' 
                  : 'Using enhanced products with 20-tier pricing & Stripe integration'}
              </p>
            </div>
          </div>
          
          <div className="flex gap-2">
            <Button 
              variant={currentSystem === 'old' ? 'default' : 'outline'}
              size="sm"
              onClick={() => switchSystem('old')}
              disabled={currentSystem === 'old'}
            >
              Old System
            </Button>
            <Button 
              variant={currentSystem === 'new' ? 'default' : 'outline'}
              size="sm"
              onClick={() => switchSystem('new')}
              disabled={currentSystem === 'new'}
              className="min-w-[120px]"
            >
              <Sparkles className="h-4 w-4 mr-1" />
              New Enhanced
            </Button>
          </div>
        </div>
        
        {currentSystem === 'old' && (
          <div className="mt-3 pt-3 border-t">
            <div className="flex items-start gap-2">
              <AlertTriangle className="h-4 w-4 text-amber-500 mt-0.5" />
              <div className="text-sm">
                <p className="font-medium text-amber-700">Migration Recommended</p>
                <p className="text-muted-foreground">
                  The old system has inaccurate data. Switch to Enhanced Products for:
                </p>
                <ul className="mt-1 space-y-1 text-muted-foreground">
                  <li>• 20-tier pricing system</li>
                  <li>• Stripe product sync</li>
                  <li>• Better image management</li>
                  <li>• SEO optimization</li>
                </ul>
              </div>
            </div>
          </div>
        )}
      </Alert>
      
      {/* Warning Dialog */}
      {showWarning && (
        <div className="fixed inset-0 bg-black/50 flex items-center justify-center z-50">
          <div className="bg-white rounded-lg p-6 max-w-md">
            <h3 className="text-lg font-semibold mb-2">Switch to Enhanced Products?</h3>
            <p className="text-sm text-muted-foreground mb-4">
              The enhanced system uses the <code>products_enhanced</code> table with:
            </p>
            <ul className="text-sm space-y-1 mb-4">
              <li>✅ 20-tier pricing</li>
              <li>✅ Stripe integration</li>
              <li>✅ Better data structure</li>
              <li>✅ Clean slate (no bad data)</li>
            </ul>
            <Alert className="mb-4">
              <AlertTriangle className="h-4 w-4" />
              <AlertDescription>
                You'll need to re-add products in the new system. The old inaccurate data won't be migrated.
              </AlertDescription>
            </Alert>
            <div className="flex gap-2">
              <Button variant="outline" onClick={() => setShowWarning(false)}>
                Cancel
              </Button>
              <Button onClick={confirmSwitch}>
                <ArrowRight className="h-4 w-4 mr-1" />
                Switch to Enhanced
              </Button>
            </div>
          </div>
        </div>
      )}
    </>
  );
}