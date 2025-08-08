/**
 * PRODUCT DIAGNOSTIC TOOL
 * Helps debug product creation issues
 */

import React, { useState } from 'react';
import { Button } from '@/components/ui/button';
import { Card } from '@/components/ui/card';
import { supabase } from '@/lib/supabase-client';
import { toast } from 'sonner';

export function ProductDiagnostic() {
  const [results, setResults] = useState<any[]>([]);
  const [loading, setLoading] = useState(false);

  const runDiagnostics = async () => {
    setLoading(true);
    const diagnostics = [];

    try {
      // 1. Check authentication
      const { data: { user }, error: authError } = await supabase.auth.getUser();
      diagnostics.push({
        test: 'Authentication',
        success: !!user,
        details: user ? `Logged in as ${user.email}` : authError?.message || 'Not authenticated',
      });

      // 2. Check if products table is accessible
      const { data: readTest, error: readError } = await supabase
        .from('products')
        .select('id')
        .limit(1);
      
      diagnostics.push({
        test: 'Read Products Table',
        success: !readError,
        details: readError ? readError.message : 'Can read products table',
      });

      // 3. Test minimal product insert
      const timestamp = Date.now();
      const testProduct = {
        name: 'Test Product ' + timestamp,
        sku: 'TEST-' + timestamp,
        base_price: 99.99,
        status: 'active',
        category: 'Test',
        description: '',  // Empty description
        created_at: new Date().toISOString(),
        updated_at: new Date().toISOString(),
      };

      const { data: insertData, error: insertError } = await supabase
        .from('products')
        .insert(testProduct)
        .select()
        .single();

      diagnostics.push({
        test: 'Insert Test Product',
        success: !insertError,
        details: insertError ? insertError.message : `Created product with ID: ${insertData?.id}`,
        data: insertError ? null : insertData,
      });

      // 4. If insert succeeded, clean up
      if (insertData?.id) {
        const { error: deleteError } = await supabase
          .from('products')
          .delete()
          .eq('id', insertData.id);

        diagnostics.push({
          test: 'Delete Test Product',
          success: !deleteError,
          details: deleteError ? deleteError.message : 'Test product deleted',
        });
      }

      // 5. Check table columns
      const { data: columns, error: columnsError } = await supabase
        .rpc('get_table_columns', { table_name: 'products' })
        .single();

      if (!columnsError && columns) {
        diagnostics.push({
          test: 'Table Structure',
          success: true,
          details: 'Products table columns retrieved',
          data: columns,
        });
      }

    } catch (error) {
      diagnostics.push({
        test: 'Unexpected Error',
        success: false,
        details: error instanceof Error ? error.message : 'Unknown error',
      });
    }

    setResults(diagnostics);
    setLoading(false);
  };

  return (
    <Card className="p-6 max-w-4xl mx-auto mt-6">
      <h2 className="text-xl font-bold mb-4">Product System Diagnostic</h2>
      
      <Button 
        onClick={runDiagnostics} 
        disabled={loading}
        className="mb-4"
      >
        {loading ? 'Running Diagnostics...' : 'Run Diagnostics'}
      </Button>

      {results.length > 0 && (
        <div className="space-y-3">
          {results.map((result, idx) => (
            <div
              key={idx}
              className={`p-3 rounded border ${
                result.success 
                  ? 'bg-green-50 border-green-300' 
                  : 'bg-red-50 border-red-300'
              }`}
            >
              <div className="flex items-center justify-between">
                <span className="font-semibold">{result.test}</span>
                <span className={result.success ? 'text-green-600' : 'text-red-600'}>
                  {result.success ? '✓ PASS' : '✗ FAIL'}
                </span>
              </div>
              <p className="text-sm mt-1 text-gray-600">{result.details}</p>
              {result.data && (
                <pre className="text-xs mt-2 p-2 bg-white rounded overflow-x-auto">
                  {JSON.stringify(result.data, null, 2)}
                </pre>
              )}
            </div>
          ))}
        </div>
      )}
    </Card>
  );
}