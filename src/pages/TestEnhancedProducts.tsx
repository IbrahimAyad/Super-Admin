import React, { useEffect, useState } from 'react';

export default function TestEnhancedProducts() {
  const [products, setProducts] = useState<any[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [debugInfo, setDebugInfo] = useState<any>({});

  useEffect(() => {
    testDatabaseConnection();
  }, []);

  async function testDatabaseConnection() {
    try {
      setLoading(true);
      
      // Direct fetch using public API
      const response = await fetch('https://gvcswimqaxvylgxbklbz.supabase.co/rest/v1/products_enhanced', {
        headers: {
          'apikey': 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imd2Y3N3aW1xYXh2eWxneGJrbGJ6Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTM3NjA1MzAsImV4cCI6MjA2OTMzNjUzMH0.UZdiGcJXUV5VYetjWXV26inmbj2yXdiT03Z6t_5Lg24',
          'Authorization': 'Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imd2Y3N3aW1xYXh2eWxneGJrbGJ6Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTM3NjA1MzAsImV4cCI6MjA2OTMzNjUzMH0.UZdiGcJXUV5VYetjWXV26inmbj2yXdiT03Z6t_5Lg24'
        }
      });

      const responseText = await response.text();
      console.log('Response status:', response.status);
      console.log('Response text:', responseText);

      setDebugInfo({
        status: response.status,
        statusText: response.statusText,
        headers: Object.fromEntries(response.headers.entries()),
        responseLength: responseText.length
      });

      if (response.ok) {
        try {
          const data = JSON.parse(responseText);
          setProducts(data);
          console.log('Products loaded:', data);
        } catch (parseError) {
          console.error('JSON parse error:', parseError);
          setError('Failed to parse response: ' + responseText.substring(0, 200));
        }
      } else {
        setError(`HTTP ${response.status}: ${responseText.substring(0, 200)}`);
      }
    } catch (err) {
      console.error('Fetch error:', err);
      setError('Network error: ' + (err as Error).message);
    } finally {
      setLoading(false);
    }
  }

  return (
    <div className="p-6 max-w-6xl mx-auto">
      <h1 className="text-2xl font-bold mb-4">Enhanced Products Test Page</h1>
      
      {/* Debug Info */}
      <div className="mb-6 p-4 bg-gray-100 rounded">
        <h2 className="font-semibold mb-2">Debug Information:</h2>
        <pre className="text-xs overflow-auto">
          {JSON.stringify(debugInfo, null, 2)}
        </pre>
      </div>

      {loading && (
        <div className="text-center py-8">
          <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-gray-900 mx-auto"></div>
          <p className="mt-2">Loading products...</p>
        </div>
      )}

      {error && (
        <div className="bg-red-50 border border-red-400 text-red-700 px-4 py-3 rounded mb-4">
          <strong>Error:</strong> {error}
        </div>
      )}

      {!loading && !error && products.length === 0 && (
        <div className="bg-yellow-50 border border-yellow-400 text-yellow-700 px-4 py-3 rounded">
          No products found. This might be due to RLS policies.
        </div>
      )}

      {products.length > 0 && (
        <div>
          <h2 className="text-xl font-semibold mb-3">
            Found {products.length} Enhanced Products:
          </h2>
          <div className="space-y-4">
            {products.map((product) => (
              <div key={product.id} className="border p-4 rounded bg-white shadow">
                <h3 className="font-semibold">{product.name}</h3>
                <div className="grid grid-cols-2 gap-2 mt-2 text-sm">
                  <div>SKU: {product.sku}</div>
                  <div>Status: {product.status}</div>
                  <div>Category: {product.category}</div>
                  <div>Price Tier: {product.price_tier}</div>
                  <div>Price: ${(product.base_price / 100).toFixed(2)}</div>
                  <div>Images: {product.images?.total_images || 0}</div>
                </div>
                {product.images?.hero?.url && (
                  <div className="mt-2">
                    <p className="text-xs text-gray-600 mb-1">Hero Image URL:</p>
                    <p className="text-xs break-all bg-gray-50 p-1 rounded">
                      {product.images.hero.url}
                    </p>
                  </div>
                )}
              </div>
            ))}
          </div>
        </div>
      )}
    </div>
  );
}