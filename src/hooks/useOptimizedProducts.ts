import { useState, useEffect, useCallback } from 'react';
import { supabase } from '@/integrations/supabase/client';
import { useToast } from '@/hooks/use-toast';
import { Product } from '@/types/product';

interface UseOptimizedProductsOptions {
  pageSize?: number;
  initialPage?: number;
  searchTerm?: string;
  category?: string;
  status?: string;
}

export function useOptimizedProducts(options: UseOptimizedProductsOptions = {}) {
  const { 
    pageSize = 50, 
    initialPage = 1,
    searchTerm = '',
    category = null,
    status = null
  } = options;

  const [products, setProducts] = useState<Product[]>([]);
  const [loading, setLoading] = useState(false);
  const [totalCount, setTotalCount] = useState(0);
  const [currentPage, setCurrentPage] = useState(initialPage);
  const { toast } = useToast();

  // Use the optimized paginated function
  const fetchProducts = useCallback(async () => {
    setLoading(true);
    try {
      const { data, error } = await supabase.rpc('get_admin_products_paginated', {
        page_size: pageSize,
        page_number: currentPage,
        search_term: searchTerm || null,
        filter_category: category,
        filter_status: status
      });

      if (error) throw error;

      if (data && data.length > 0) {
        setProducts(data);
        setTotalCount(data[0].total_count || 0);
      } else {
        setProducts([]);
        setTotalCount(0);
      }
    } catch (error) {
      console.error('Error fetching products:', error);
      
      // Fallback to direct query if function doesn't exist
      try {
        let query = supabase
          .from('products')
          .select('*', { count: 'exact' });

        if (searchTerm) {
          query = query.ilike('name', `%${searchTerm}%`);
        }
        if (category) {
          query = query.eq('category', category);
        }
        if (status) {
          query = query.eq('status', status);
        }

        const { data, error, count } = await query
          .order('created_at', { ascending: false })
          .range((currentPage - 1) * pageSize, currentPage * pageSize - 1);

        if (error) throw error;

        setProducts(data || []);
        setTotalCount(count || 0);
      } catch (fallbackError) {
        toast({
          title: "Error loading products",
          description: "Please refresh the page and try again",
          variant: "destructive"
        });
      }
    } finally {
      setLoading(false);
    }
  }, [currentPage, pageSize, searchTerm, category, status]);

  // Fetch products when dependencies change
  useEffect(() => {
    fetchProducts();
  }, [fetchProducts]);

  // Reset to first page when filters change
  useEffect(() => {
    setCurrentPage(1);
  }, [searchTerm, category, status]);

  const totalPages = Math.ceil(totalCount / pageSize);

  return {
    products,
    loading,
    totalCount,
    currentPage,
    totalPages,
    setCurrentPage,
    refetch: fetchProducts
  };
}