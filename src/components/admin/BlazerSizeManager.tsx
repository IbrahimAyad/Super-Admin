import React, { useState, useEffect } from 'react';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { Switch } from '@/components/ui/switch';
import { Label } from '@/components/ui/label';
import { Badge } from '@/components/ui/badge';
import { supabase } from '@/lib/supabase';
import { toast } from 'sonner';
import { Loader2, Save, RefreshCw } from 'lucide-react';

interface BlazerProduct {
  id: string;
  name: string;
  sku: string;
  base_price: number;
  size_options: {
    regular: boolean;
    short: boolean;
    long: boolean;
  };
  active_regular_sizes: number;
  active_short_sizes: number;
  active_long_sizes: number;
}

export function BlazerSizeManager() {
  const [blazers, setBlazers] = useState<BlazerProduct[]>([]);
  const [loading, setLoading] = useState(true);
  const [saving, setSaving] = useState<string | null>(null);
  const [selectedBlazer, setSelectedBlazer] = useState<BlazerProduct | null>(null);

  // Fetch blazer configuration
  const fetchBlazers = async () => {
    try {
      setLoading(true);
      const { data, error } = await supabase
        .from('blazer_size_configuration')
        .select('*')
        .order('name');

      if (error) throw error;
      setBlazers(data || []);
    } catch (error) {
      console.error('Error fetching blazers:', error);
      toast.error('Failed to load blazer configurations');
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchBlazers();
  }, []);

  // Toggle size options for a specific blazer
  const toggleSizeOption = async (
    blazerId: string, 
    sizeType: 'regular' | 'short' | 'long',
    enabled: boolean
  ) => {
    try {
      setSaving(blazerId);
      
      // Get current blazer
      const blazer = blazers.find(b => b.id === blazerId);
      if (!blazer) return;

      // Prepare the update
      const updates = {
        regular: sizeType === 'regular' ? enabled : blazer.size_options.regular,
        short: sizeType === 'short' ? enabled : blazer.size_options.short,
        long: sizeType === 'long' ? enabled : blazer.size_options.long,
      };

      // Call the database function
      const { data, error } = await supabase.rpc('toggle_product_size_options', {
        p_product_id: blazerId,
        p_enable_regular: updates.regular,
        p_enable_short: updates.short,
        p_enable_long: updates.long
      });

      if (error) throw error;

      // Update local state
      setBlazers(prev => prev.map(b => 
        b.id === blazerId 
          ? { ...b, size_options: updates }
          : b
      ));

      toast.success(`Updated size options for ${blazer.name}`);
    } catch (error) {
      console.error('Error updating size options:', error);
      toast.error('Failed to update size options');
    } finally {
      setSaving(null);
    }
  };

  // Bulk update all blazers
  const bulkUpdateSizes = async (regular: boolean, short: boolean, long: boolean) => {
    try {
      setLoading(true);
      
      // Update all blazers
      for (const blazer of blazers) {
        await supabase.rpc('toggle_product_size_options', {
          p_product_id: blazer.id,
          p_enable_regular: regular,
          p_enable_short: short,
          p_enable_long: long
        });
      }

      toast.success('Updated all blazer size configurations');
      await fetchBlazers();
    } catch (error) {
      console.error('Error in bulk update:', error);
      toast.error('Failed to update all blazers');
    } finally {
      setLoading(false);
    }
  };

  if (loading) {
    return (
      <div className="flex items-center justify-center p-8">
        <Loader2 className="h-8 w-8 animate-spin" />
      </div>
    );
  }

  return (
    <div className="space-y-6">
      <Card>
        <CardHeader>
          <CardTitle>Blazer Size Management</CardTitle>
          <p className="text-sm text-muted-foreground">
            Control which size variants are available for each blazer product
          </p>
        </CardHeader>
        <CardContent>
          {/* Quick Actions */}
          <div className="mb-6 p-4 bg-muted rounded-lg">
            <h3 className="font-medium mb-3">Quick Actions</h3>
            <div className="flex gap-3">
              <Button
                onClick={() => bulkUpdateSizes(true, false, false)}
                variant="outline"
                size="sm"
              >
                Regular Only (Default)
              </Button>
              <Button
                onClick={() => bulkUpdateSizes(true, true, false)}
                variant="outline"
                size="sm"
              >
                Regular + Short
              </Button>
              <Button
                onClick={() => bulkUpdateSizes(true, false, true)}
                variant="outline"
                size="sm"
              >
                Regular + Long
              </Button>
              <Button
                onClick={() => bulkUpdateSizes(true, true, true)}
                variant="outline"
                size="sm"
              >
                All Sizes
              </Button>
              <Button
                onClick={fetchBlazers}
                variant="outline"
                size="sm"
                className="ml-auto"
              >
                <RefreshCw className="h-4 w-4 mr-2" />
                Refresh
              </Button>
            </div>
          </div>

          {/* Blazer List */}
          <div className="space-y-3">
            {blazers.map((blazer) => (
              <div
                key={blazer.id}
                className="p-4 border rounded-lg hover:bg-muted/50 transition-colors"
              >
                <div className="flex items-start justify-between">
                  <div className="flex-1">
                    <h4 className="font-medium">{blazer.name}</h4>
                    <div className="flex gap-2 mt-1">
                      <span className="text-sm text-muted-foreground">
                        SKU: {blazer.sku}
                      </span>
                      <span className="text-sm text-muted-foreground">
                        Price: ${blazer.base_price}
                      </span>
                    </div>
                    <div className="flex gap-2 mt-2">
                      {blazer.active_regular_sizes > 0 && (
                        <Badge variant="secondary">
                          {blazer.active_regular_sizes} Regular
                        </Badge>
                      )}
                      {blazer.active_short_sizes > 0 && (
                        <Badge variant="secondary">
                          {blazer.active_short_sizes} Short
                        </Badge>
                      )}
                      {blazer.active_long_sizes > 0 && (
                        <Badge variant="secondary">
                          {blazer.active_long_sizes} Long
                        </Badge>
                      )}
                    </div>
                  </div>

                  <div className="flex gap-4">
                    {/* Regular Sizes Toggle */}
                    <div className="flex items-center space-x-2">
                      <Switch
                        id={`regular-${blazer.id}`}
                        checked={blazer.size_options.regular}
                        onCheckedChange={(checked) => 
                          toggleSizeOption(blazer.id, 'regular', checked)
                        }
                        disabled={saving === blazer.id}
                      />
                      <Label htmlFor={`regular-${blazer.id}`}>
                        Regular (36R-54R)
                      </Label>
                    </div>

                    {/* Short Sizes Toggle */}
                    <div className="flex items-center space-x-2">
                      <Switch
                        id={`short-${blazer.id}`}
                        checked={blazer.size_options.short}
                        onCheckedChange={(checked) => 
                          toggleSizeOption(blazer.id, 'short', checked)
                        }
                        disabled={saving === blazer.id}
                      />
                      <Label htmlFor={`short-${blazer.id}`}>
                        Short (34S-54S)
                      </Label>
                    </div>

                    {/* Long Sizes Toggle */}
                    <div className="flex items-center space-x-2">
                      <Switch
                        id={`long-${blazer.id}`}
                        checked={blazer.size_options.long}
                        onCheckedChange={(checked) => 
                          toggleSizeOption(blazer.id, 'long', checked)
                        }
                        disabled={saving === blazer.id}
                      />
                      <Label htmlFor={`long-${blazer.id}`}>
                        Long (36L-54L)
                      </Label>
                    </div>

                    {saving === blazer.id && (
                      <Loader2 className="h-4 w-4 animate-spin" />
                    )}
                  </div>
                </div>
              </div>
            ))}
          </div>

          {/* Summary */}
          <div className="mt-6 p-4 bg-muted rounded-lg">
            <div className="grid grid-cols-3 gap-4 text-sm">
              <div>
                <span className="text-muted-foreground">Total Blazers:</span>
                <span className="ml-2 font-medium">{blazers.length}</span>
              </div>
              <div>
                <span className="text-muted-foreground">With Regular:</span>
                <span className="ml-2 font-medium">
                  {blazers.filter(b => b.size_options.regular).length}
                </span>
              </div>
              <div>
                <span className="text-muted-foreground">With Short/Long:</span>
                <span className="ml-2 font-medium">
                  {blazers.filter(b => b.size_options.short || b.size_options.long).length}
                </span>
              </div>
            </div>
          </div>
        </CardContent>
      </Card>
    </div>
  );
}