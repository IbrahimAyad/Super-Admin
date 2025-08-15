import React, { useEffect, useState } from 'react';
import { supabase } from '@/lib/supabase';
import EnhancedProductUI from '@/components/products/EnhancedProductUI';

export default function EnhancedProductsPage() {
  const [products, setProducts] = useState([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    fetchEnhancedProducts();
  }, []);

  async function fetchEnhancedProducts() {
    try {
      const { data, error } = await supabase
        .from('products_enhanced')
        .select('*')
        .order('created_at', { ascending: false });

      if (error) throw error;
      
      setProducts(data || []);
    } catch (error) {
      console.error('Error fetching enhanced products:', error);
    } finally {
      setLoading(false);
    }
  }

  if (loading) {
    return (
      <div className="flex items-center justify-center min-h-screen">
        <div className="text-xl">Loading enhanced products...</div>
      </div>
    );
  }

  return (
    <div className="min-h-screen bg-gray-50">
      <div className="p-6">
        <h1 className="text-3xl font-bold mb-6">Enhanced Products</h1>
        
        {/* Product Stats */}
        <div className="grid grid-cols-4 gap-4 mb-6">
          <div className="bg-white p-4 rounded-lg shadow">
            <div className="text-2xl font-bold">{products.length}</div>
            <div className="text-gray-600">Total Enhanced Products</div>
          </div>
          <div className="bg-white p-4 rounded-lg shadow">
            <div className="text-2xl font-bold">
              {products.filter(p => p.status === 'active').length}
            </div>
            <div className="text-gray-600">Active Products</div>
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

        {/* Product List */}
        <div className="bg-white rounded-lg shadow p-6">
          <h2 className="text-xl font-semibold mb-4">Product List</h2>
          <div className="overflow-x-auto">
            <table className="w-full">
              <thead className="bg-gray-50">
                <tr>
                  <th className="px-4 py-2 text-left">Image</th>
                  <th className="px-4 py-2 text-left">Name</th>
                  <th className="px-4 py-2 text-left">SKU</th>
                  <th className="px-4 py-2 text-left">Category</th>
                  <th className="px-4 py-2 text-left">Price Tier</th>
                  <th className="px-4 py-2 text-left">Images</th>
                  <th className="px-4 py-2 text-left">Status</th>
                  <th className="px-4 py-2 text-left">Actions</th>
                </tr>
              </thead>
              <tbody>
                {products.map((product) => (
                  <tr key={product.id} className="border-b">
                    <td className="px-4 py-2">
                      {product.images?.hero?.url ? (
                        <img 
                          src={product.images.hero.url} 
                          alt={product.name}
                          className="w-16 h-20 object-cover rounded"
                          onError={(e) => {
                            e.target.src = '/api/placeholder/64/80';
                          }}
                        />
                      ) : (
                        <div className="w-16 h-20 bg-gray-200 rounded flex items-center justify-center">
                          <span className="text-gray-500 text-xs">No Image</span>
                        </div>
                      )}
                    </td>
                    <td className="px-4 py-2">
                      <div className="font-medium">{product.name}</div>
                      <div className="text-sm text-gray-500">{product.handle}</div>
                    </td>
                    <td className="px-4 py-2 text-sm">{product.sku}</td>
                    <td className="px-4 py-2">
                      <div>{product.category}</div>
                      {product.subcategory && (
                        <div className="text-sm text-gray-500">{product.subcategory}</div>
                      )}
                    </td>
                    <td className="px-4 py-2">
                      <span className="px-2 py-1 bg-black text-white text-xs rounded">
                        {product.price_tier}
                      </span>
                      <div className="text-sm text-gray-600 mt-1">
                        ${(product.base_price / 100).toFixed(2)}
                      </div>
                    </td>
                    <td className="px-4 py-2">
                      <div className="text-sm">
                        <div>Total: {product.images?.total_images || 0}</div>
                        {product.images?.hero && <div className="text-gray-500">✓ Hero</div>}
                        {product.images?.flat && <div className="text-gray-500">✓ Flat</div>}
                        {product.images?.lifestyle?.length > 0 && (
                          <div className="text-gray-500">✓ {product.images.lifestyle.length} Lifestyle</div>
                        )}
                        {product.images?.details?.length > 0 && (
                          <div className="text-gray-500">✓ {product.images.details.length} Details</div>
                        )}
                      </div>
                    </td>
                    <td className="px-4 py-2">
                      <span className={`px-2 py-1 rounded text-xs ${
                        product.status === 'active' 
                          ? 'bg-green-100 text-green-800'
                          : 'bg-gray-100 text-gray-800'
                      }`}>
                        {product.status}
                      </span>
                    </td>
                    <td className="px-4 py-2">
                      <button
                        onClick={() => console.log('View', product)}
                        className="text-blue-600 hover:text-blue-800 text-sm"
                      >
                        View Details
                      </button>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        </div>

        {/* Image Gallery Preview */}
        <div className="mt-6 bg-white rounded-lg shadow p-6">
          <h2 className="text-xl font-semibold mb-4">Image Gallery Preview</h2>
          {products.map((product) => (
            <div key={product.id} className="mb-6 border-b pb-6">
              <h3 className="font-medium mb-3">{product.name}</h3>
              <div className="grid grid-cols-6 gap-2">
                {product.images?.hero && (
                  <div>
                    <img 
                      src={product.images.hero.url} 
                      alt="Hero"
                      className="w-full h-32 object-cover rounded"
                      onError={(e) => e.target.src = '/api/placeholder/150/128'}
                    />
                    <p className="text-xs text-center mt-1">Hero</p>
                  </div>
                )}
                {product.images?.flat && (
                  <div>
                    <img 
                      src={product.images.flat.url} 
                      alt="Flat"
                      className="w-full h-32 object-cover rounded"
                      onError={(e) => e.target.src = '/api/placeholder/150/128'}
                    />
                    <p className="text-xs text-center mt-1">Flat</p>
                  </div>
                )}
                {product.images?.lifestyle?.map((img, i) => (
                  <div key={i}>
                    <img 
                      src={img.url} 
                      alt={img.alt}
                      className="w-full h-32 object-cover rounded"
                      onError={(e) => e.target.src = '/api/placeholder/150/128'}
                    />
                    <p className="text-xs text-center mt-1">Lifestyle {i + 1}</p>
                  </div>
                ))}
                {product.images?.details?.map((img, i) => (
                  <div key={i}>
                    <img 
                      src={img.url} 
                      alt={img.alt}
                      className="w-full h-32 object-cover rounded"
                      onError={(e) => e.target.src = '/api/placeholder/150/128'}
                    />
                    <p className="text-xs text-center mt-1">Detail {i + 1}</p>
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