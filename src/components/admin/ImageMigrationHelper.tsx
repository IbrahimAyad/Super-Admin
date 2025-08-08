/**
 * IMAGE MIGRATION HELPER
 * Helps fix broken image references from R2 migration
 */

import React, { useState, useEffect } from 'react';
import { Button } from '@/components/ui/button';
import { Card } from '@/components/ui/card';
import { supabase } from '@/lib/supabase-client';
import { toast } from 'sonner';
import { AlertCircle, Image, Upload, Check } from 'lucide-react';

export function ImageMigrationHelper() {
  const [brokenProducts, setBrokenProducts] = useState<any[]>([]);
  const [loading, setLoading] = useState(false);
  const [fixing, setFixing] = useState(false);

  const checkBrokenImages = async () => {
    setLoading(true);
    try {
      // Find products with non-Supabase image references
      const { data, error } = await supabase
        .from('products')
        .select('id, name, sku, primary_image, image_gallery')
        .or('primary_image.not.like.%supabase%,primary_image.not.is.null');

      if (error) throw error;

      const broken = data?.filter(product => {
        // Check if primary_image is a broken reference
        const hasOldImage = product.primary_image && 
          !product.primary_image.includes('supabase') && 
          !product.primary_image.startsWith('http');
        
        return hasOldImage;
      }) || [];

      setBrokenProducts(broken);
      
      if (broken.length === 0) {
        toast.success('No broken image references found!');
      } else {
        toast.warning(`Found ${broken.length} products with broken images`);
      }
    } catch (error) {
      console.error('Error checking images:', error);
      toast.error('Failed to check images');
    } finally {
      setLoading(false);
    }
  };

  const clearBrokenReferences = async () => {
    if (!confirm('This will clear all broken image references. Continue?')) return;
    
    setFixing(true);
    try {
      // Clear broken primary_image references
      const { error: primaryError } = await supabase
        .from('products')
        .update({ 
          primary_image: null,
          image_gallery: []
        })
        .not('primary_image', 'like', '%supabase%')
        .not('primary_image', 'is', null);

      if (primaryError) throw primaryError;

      // Also clear from product_images table
      const { error: imagesError } = await supabase
        .from('product_images')
        .delete()
        .not('image_url', 'like', '%supabase%');

      if (imagesError) throw imagesError;

      toast.success('Cleared all broken image references');
      await checkBrokenImages(); // Refresh the list
    } catch (error) {
      console.error('Error clearing references:', error);
      toast.error('Failed to clear references');
    } finally {
      setFixing(false);
    }
  };

  return (
    <Card className="p-6">
      <div className="space-y-4">
        <div className="flex items-start space-x-3">
          <AlertCircle className="h-5 w-5 text-amber-500 mt-0.5" />
          <div className="flex-1">
            <h3 className="font-semibold">Image Migration Status</h3>
            <p className="text-sm text-gray-600 mt-1">
              Some products still have references to old R2 storage images that no longer exist.
              This tool helps identify and clean up these broken references.
            </p>
          </div>
        </div>

        <div className="flex gap-2">
          <Button 
            onClick={checkBrokenImages} 
            disabled={loading}
            variant="outline"
          >
            {loading ? 'Checking...' : 'Check for Broken Images'}
          </Button>
          
          {brokenProducts.length > 0 && (
            <Button 
              onClick={clearBrokenReferences}
              disabled={fixing}
              variant="destructive"
            >
              {fixing ? 'Clearing...' : `Clear ${brokenProducts.length} Broken References`}
            </Button>
          )}
        </div>

        {brokenProducts.length > 0 && (
          <div className="border rounded-lg p-3 bg-amber-50">
            <p className="text-sm font-medium text-amber-900 mb-2">
              Products with broken images:
            </p>
            <div className="space-y-1 max-h-40 overflow-y-auto">
              {brokenProducts.map(product => (
                <div key={product.id} className="text-sm text-amber-800">
                  • {product.name} ({product.sku})
                </div>
              ))}
            </div>
            <p className="text-xs text-amber-700 mt-2">
              These products are showing 404 errors. Clear the references and re-upload images.
            </p>
          </div>
        )}

        <div className="bg-blue-50 border border-blue-200 rounded-lg p-3">
          <p className="text-sm text-blue-800">
            <strong>How to fix:</strong>
          </p>
          <ol className="text-sm text-blue-700 mt-1 space-y-1">
            <li>1. Click "Check for Broken Images" to identify affected products</li>
            <li>2. Click "Clear Broken References" to remove 404 errors</li>
            <li>3. Edit each product and re-upload images using Supabase storage</li>
          </ol>
        </div>
      </div>
    </Card>
  );
}