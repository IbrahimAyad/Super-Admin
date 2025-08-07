import { useState } from 'react';
import { Button } from '@/components/ui/button';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Badge } from '@/components/ui/badge';
import { 
  fetchProductsWithImages, 
  getProductImageUrl, 
  debugImageUrls, 
  diagnoseAdminImageIssues,
  enableImageDebugging 
} from '@/lib/services';
import { Bug, Image, RefreshCw } from 'lucide-react';

/**
 * Temporary debugging component for admin image issues
 * Remove this after images are working properly
 */
export function ImageDebugger() {
  const [debugResults, setDebugResults] = useState<any>(null);
  const [loading, setLoading] = useState(false);

  const runDiagnostic = async () => {
    setLoading(true);
    console.clear();
    
    try {
      // Enable debugging in browser console
      enableImageDebugging();
      
      // Run comprehensive diagnostic
      await diagnoseAdminImageIssues();
      
      // Fetch sample products for display
      const result = await fetchProductsWithImages({ limit: 5 });
      setDebugResults(result);
      
      console.log('🎯 Diagnostic complete! Check browser console for details.');
      
    } catch (error) {
      console.error('Debug error:', error);
      setDebugResults({ success: false, error: error.message });
    } finally {
      setLoading(false);
    }
  };

  const testImageUrls = async () => {
    setLoading(true);
    try {
      await debugImageUrls(10);
      console.log('📸 Image URL debugging complete - check console');
    } catch (error) {
      console.error('Image URL debug error:', error);
    } finally {
      setLoading(false);
    }
  };

  return (
    <Card className="mb-6 border-orange-200 bg-orange-50">
      <CardHeader>
        <CardTitle className="flex items-center gap-2 text-orange-800">
          <Bug className="h-5 w-5" />
          Image Debug Panel
          <Badge variant="outline" className="text-xs">
            TEMPORARY - Remove after fixing images
          </Badge>
        </CardTitle>
      </CardHeader>
      <CardContent className="space-y-4">
        <div className="flex gap-2">
          <Button 
            onClick={runDiagnostic} 
            disabled={loading}
            size="sm"
            variant="outline"
          >
            <RefreshCw className={`h-4 w-4 mr-2 ${loading ? 'animate-spin' : ''}`} />
            Run Full Diagnostic
          </Button>
          <Button 
            onClick={testImageUrls} 
            disabled={loading}
            size="sm"
            variant="outline"
          >
            <Image className="h-4 w-4 mr-2" />
            Test Image URLs
          </Button>
        </div>

        {debugResults && (
          <div className="space-y-3">
            <div className="text-sm">
              <strong>Status:</strong>{' '}
              <Badge variant={debugResults.success ? 'default' : 'destructive'}>
                {debugResults.success ? 'SUCCESS' : 'ERROR'}
              </Badge>
            </div>
            
            {debugResults.success && debugResults.data && (
              <div className="space-y-2">
                <div className="text-sm">
                  <strong>Found:</strong> {debugResults.data.length} products
                </div>
                
                {/* Show first few products with image status */}
                <div className="grid grid-cols-1 md:grid-cols-2 gap-2 text-xs">
                  {debugResults.data.slice(0, 4).map((product: any) => (
                    <div key={product.id} className="p-2 bg-white rounded border">
                      <div className="font-medium truncate">{product.name}</div>
                      <div className="text-gray-600">
                        Images: {product.images?.length || 0}
                      </div>
                      {product.images?.length > 0 && (
                        <div className="mt-1">
                          <img
                            src={getProductImageUrl(product)}
                            alt={product.name}
                            className="w-12 h-12 object-cover rounded border"
                            onError={(e) => {
                              const target = e.target as HTMLImageElement;
                              target.style.border = '2px solid red';
                              target.alt = 'Failed to load';
                            }}
                          />
                        </div>
                      )}
                    </div>
                  ))}
                </div>
              </div>
            )}

            {debugResults.error && (
              <div className="text-sm text-red-600">
                <strong>Error:</strong> {debugResults.error}
              </div>
            )}
          </div>
        )}

        <div className="text-xs text-gray-600 bg-white p-2 rounded">
          <strong>Instructions:</strong>
          <ol className="list-decimal list-inside mt-1 space-y-1">
            <li>Click "Run Full Diagnostic" to test the image system</li>
            <li>Open browser Developer Console (F12) to see detailed logs</li>
            <li>Check Network tab to see if images are loading or returning 404s</li>
            <li>Use console functions like <code>diagnoseAdminImageIssues()</code> for deeper analysis</li>
          </ol>
        </div>
      </CardContent>
    </Card>
  );
}