import React, { useEffect, useState } from 'react';
import { createClient } from '@supabase/supabase-js';

// Initialize Supabase client
const supabaseUrl = import.meta.env.VITE_SUPABASE_URL || '';
const supabaseAnonKey = import.meta.env.VITE_SUPABASE_ANON_KEY || '';
const supabase = createClient(supabaseUrl, supabaseAnonKey);

interface EnhancedProduct {
  id: string;
  name: string;
  sku: string;
  handle: string;
  style_code?: string;
  season?: string;
  collection?: string;
  category: string;
  subcategory?: string;
  price_tier: string;
  base_price: number;
  compare_at_price?: number;
  color_family?: string;
  color_name?: string;
  materials?: any;
  fit_type?: string;
  images?: any;
  description?: string;
  status: string;
  stripe_product_id?: string;
  stripe_active?: boolean;
  created_at: string;
  updated_at: string;
}

export default function EnhancedProducts() {
  const [products, setProducts] = useState<EnhancedProduct[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    fetchEnhancedProducts();
  }, []);

  async function fetchEnhancedProducts() {
    try {
      setLoading(true);
      const { data, error } = await supabase
        .from('products_enhanced')
        .select('*')
        .order('created_at', { ascending: false });

      if (error) {
        console.error('Supabase error:', error);
        setError(error.message);
      } else {
        setProducts(data || []);
      }
    } catch (err) {
      console.error('Error fetching enhanced products:', err);
      setError('Failed to load products');
    } finally {
      setLoading(false);
    }
  }

  if (loading) {
    return (
      <div className="flex items-center justify-center min-h-screen bg-gray-50">
        <div className="text-center">
          <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-black mx-auto"></div>
          <div className="text-xl mt-4">Loading enhanced products...</div>
        </div>
      </div>
    );
  }

  if (error) {
    return (
      <div className="flex items-center justify-center min-h-screen bg-gray-50">
        <div className="text-center bg-red-50 p-6 rounded-lg">
          <div className="text-red-600 text-xl mb-2">Error Loading Products</div>
          <div className="text-gray-600">{error}</div>
          <button 
            onClick={fetchEnhancedProducts}
            className="mt-4 px-4 py-2 bg-black text-white rounded hover:bg-gray-800"
          >
            Try Again
          </button>
        </div>
      </div>
    );
  }

  return (
    <div className="min-h-screen bg-gray-50 p-6">
      <div className="max-w-7xl mx-auto">
        <h1 className="text-3xl font-bold mb-6">Enhanced Products System</h1>
        
        {/* Stats Cards */}
        <div className="grid grid-cols-1 md:grid-cols-4 gap-4 mb-6">
          <div className="bg-white p-4 rounded-lg shadow">
            <div className="text-2xl font-bold">{products.length}</div>
            <div className="text-gray-600">Total Products</div>
          </div>
          <div className="bg-white p-4 rounded-lg shadow">
            <div className="text-2xl font-bold">
              {products.filter(p => p.status === 'active').length}
            </div>
            <div className="text-gray-600">Active</div>
          </div>
          <div className="bg-white p-4 rounded-lg shadow">
            <div className="text-2xl font-bold">
              {products.reduce((acc, p) => acc + (p.images?.total_images || 0), 0)}
            </div>
            <div className="text-gray-600">Total Images</div>
          </div>
          <div className="bg-white p-4 rounded-lg shadow">
            <div className="text-2xl font-bold">20</div>
            <div className="text-gray-600">Price Tiers</div>
          </div>
        </div>

        {/* Products Table */}
        <div className="bg-white rounded-lg shadow overflow-hidden">
          <div className="px-6 py-4 border-b">
            <h2 className="text-xl font-semibold">Product List</h2>
          </div>
          <div className="overflow-x-auto">
            <table className="w-full">
              <thead className="bg-gray-50">
                <tr>
                  <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                    Image
                  </th>
                  <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                    Product
                  </th>
                  <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                    SKU
                  </th>
                  <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                    Category
                  </th>
                  <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                    Price
                  </th>
                  <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                    Images
                  </th>
                  <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                    Status
                  </th>
                </tr>
              </thead>
              <tbody className="bg-white divide-y divide-gray-200">
                {products.map((product) => (
                  <tr key={product.id}>
                    <td className="px-6 py-4 whitespace-nowrap">
                      {product.images?.hero?.url ? (
                        <img 
                          src={product.images.hero.url} 
                          alt={product.name}
                          className="w-16 h-20 object-cover rounded"
                          onError={(e) => {
                            const target = e.target as HTMLImageElement;
                            target.src = 'data:image/svg+xml;base64,PHN2ZyB3aWR0aD0iNjQiIGhlaWdodD0iODAiIHhtbG5zPSJodHRwOi8vd3d3LnczLm9yZy8yMDAwL3N2ZyI+PHJlY3Qgd2lkdGg9IjY0IiBoZWlnaHQ9IjgwIiBmaWxsPSIjZTVlN2ViIi8+PHRleHQgeD0iNTAlIiB5PSI1MCUiIGZvbnQtZmFtaWx5PSJzYW5zLXNlcmlmIiBmb250LXNpemU9IjEyIiBmaWxsPSIjOWNhM2FmIiB0ZXh0LWFuY2hvcj0ibWlkZGxlIiBkeT0iLjNlbSI+Tm8gSW1hZ2U8L3RleHQ+PC9zdmc+';
                          }}
                        />
                      ) : (
                        <div className="w-16 h-20 bg-gray-200 rounded flex items-center justify-center">
                          <span className="text-gray-500 text-xs">No Image</span>
                        </div>
                      )}
                    </td>
                    <td className="px-6 py-4">
                      <div className="text-sm font-medium text-gray-900">{product.name}</div>
                      <div className="text-sm text-gray-500">{product.handle}</div>
                    </td>
                    <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-900">
                      {product.sku}
                    </td>
                    <td className="px-6 py-4 whitespace-nowrap">
                      <div className="text-sm text-gray-900">{product.category}</div>
                      {product.subcategory && (
                        <div className="text-sm text-gray-500">{product.subcategory}</div>
                      )}
                    </td>
                    <td className="px-6 py-4 whitespace-nowrap">
                      <div className="text-sm">
                        <span className="px-2 py-1 bg-black text-white text-xs rounded">
                          {product.price_tier}
                        </span>
                      </div>
                      <div className="text-sm text-gray-900 mt-1">
                        ${(product.base_price / 100).toFixed(2)}
                      </div>
                    </td>
                    <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-900">
                      {product.images?.total_images || 0} images
                    </td>
                    <td className="px-6 py-4 whitespace-nowrap">
                      <span className={`px-2 py-1 inline-flex text-xs leading-5 font-semibold rounded-full ${
                        product.status === 'active' 
                          ? 'bg-green-100 text-green-800'
                          : 'bg-gray-100 text-gray-800'
                      }`}>
                        {product.status}
                      </span>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        </div>

        {/* Image Gallery Section */}
        <div className="mt-6 bg-white rounded-lg shadow p-6">
          <h2 className="text-xl font-semibold mb-4">Product Images</h2>
          {products.map((product) => (
            <div key={product.id} className="mb-6 pb-6 border-b last:border-b-0">
              <h3 className="font-medium mb-3">{product.name}</h3>
              <div className="grid grid-cols-2 md:grid-cols-4 lg:grid-cols-6 gap-2">
                {product.images?.hero && (
                  <div className="text-center">
                    <img 
                      src={product.images.hero.url} 
                      alt="Hero"
                      className="w-full h-32 object-cover rounded border"
                      onError={(e) => {
                        const target = e.target as HTMLImageElement;
                        target.style.display = 'none';
                      }}
                    />
                    <p className="text-xs mt-1">Hero</p>
                  </div>
                )}
                {product.images?.flat && (
                  <div className="text-center">
                    <img 
                      src={product.images.flat.url} 
                      alt="Flat"
                      className="w-full h-32 object-cover rounded border"
                      onError={(e) => {
                        const target = e.target as HTMLImageElement;
                        target.style.display = 'none';
                      }}
                    />
                    <p className="text-xs mt-1">Flat</p>
                  </div>
                )}
                {product.images?.lifestyle?.map((img: any, i: number) => (
                  <div key={i} className="text-center">
                    <img 
                      src={img.url} 
                      alt={img.alt}
                      className="w-full h-32 object-cover rounded border"
                      onError={(e) => {
                        const target = e.target as HTMLImageElement;
                        target.style.display = 'none';
                      }}
                    />
                    <p className="text-xs mt-1">Lifestyle {i + 1}</p>
                  </div>
                ))}
                {product.images?.details?.map((img: any, i: number) => (
                  <div key={i} className="text-center">
                    <img 
                      src={img.url} 
                      alt={img.alt}
                      className="w-full h-32 object-cover rounded border"
                      onError={(e) => {
                        const target = e.target as HTMLImageElement;
                        target.style.display = 'none';
                      }}
                    />
                    <p className="text-xs mt-1">Detail {i + 1}</p>
                  </div>
                ))}
              </div>
            </div>
          ))}
        </div>
      </div>
    </div>
  );
}