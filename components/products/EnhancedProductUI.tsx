import React, { useState, useCallback, useMemo } from 'react';
import { 
  Search, Plus, Upload, Download, Grid3x3, List, LayoutGrid,
  Filter, ChevronDown, MoreVertical, Image, Package, 
  DollarSign, Eye, Edit2, Copy, Archive, Trash2, 
  CheckSquare, Square, ArrowUpDown, Sparkles, Tag,
  Calendar, Palette, Ruler, AlertCircle, Check
} from 'lucide-react';

// Types for Enhanced Product System
interface EnhancedProduct {
  id: string;
  name: string;
  sku: string;
  handle: string;
  styleCode?: string;
  season?: string;
  collection?: string;
  category: string;
  subcategory?: string;
  priceTier: string;
  basePrice: number;
  compareAtPrice?: number;
  images: {
    hero?: ImageData;
    flat?: ImageData;
    lifestyle?: ImageData[];
    details?: ImageData[];
    variants?: Record<string, ImageData[]>;
    totalImages: number;
  };
  colorFamily?: string;
  colorName?: string;
  materials?: {
    primary: string;
    composition: Record<string, number>;
  };
  fitType?: string;
  sizeRange?: {
    min: string;
    max: string;
    available: string[];
  };
  status: 'draft' | 'active' | 'archived';
  viewCount: number;
  addToCartCount: number;
  purchaseCount: number;
  returnRate?: number;
  createdAt: string;
  updatedAt: string;
}

interface ImageData {
  url: string;
  alt?: string;
  width?: number;
  height?: number;
  position?: number;
}

// Price Tier Configuration
const PRICE_TIERS = {
  TIER_1: { range: '$50-74', color: 'bg-emerald-500' },
  TIER_2: { range: '$75-99', color: 'bg-emerald-600' },
  TIER_3: { range: '$100-124', color: 'bg-blue-500' },
  TIER_4: { range: '$125-149', color: 'bg-blue-600' },
  TIER_5: { range: '$150-199', color: 'bg-purple-500' },
  TIER_6: { range: '$200-249', color: 'bg-purple-600' },
  TIER_7: { range: '$250-299', color: 'bg-pink-500' },
  TIER_8: { range: '$300-399', color: 'bg-pink-600' },
  TIER_9: { range: '$400-499', color: 'bg-orange-500' },
  TIER_10: { range: '$500-599', color: 'bg-orange-600' },
  TIER_11: { range: '$600-699', color: 'bg-red-500' },
  TIER_12: { range: '$700-799', color: 'bg-red-600' },
  TIER_13: { range: '$800-899', color: 'bg-yellow-500' },
  TIER_14: { range: '$900-999', color: 'bg-yellow-600' },
  TIER_15: { range: '$1000-1249', color: 'bg-indigo-500' },
  TIER_16: { range: '$1250-1499', color: 'bg-indigo-600' },
  TIER_17: { range: '$1500-1999', color: 'bg-gray-700' },
  TIER_18: { range: '$2000-2999', color: 'bg-gray-800' },
  TIER_19: { range: '$3000-4999', color: 'bg-gray-900' },
  TIER_20: { range: '$5000+', color: 'bg-black' },
};

export default function EnhancedProductUI() {
  const [viewMode, setViewMode] = useState<'grid' | 'list' | 'board'>('grid');
  const [selectedProducts, setSelectedProducts] = useState<Set<string>>(new Set());
  const [searchQuery, setSearchQuery] = useState('');
  const [filterOpen, setFilterOpen] = useState(false);
  const [bulkActionOpen, setBulkActionOpen] = useState(false);

  // Mock data - replace with actual data fetching
  const products: EnhancedProduct[] = useMemo(() => [
    {
      id: '1',
      name: 'Premium Velvet Blazer - Midnight Navy',
      sku: 'VB-001-NVY',
      handle: 'premium-velvet-blazer-navy',
      styleCode: 'FW24-VB-001',
      season: 'FW24',
      collection: 'Luxury Essentials',
      category: 'Outerwear',
      subcategory: 'Blazers',
      priceTier: 'TIER_8',
      basePrice: 34900,
      compareAtPrice: 44900,
      images: {
        hero: { url: '/api/placeholder/400/500', alt: 'Velvet Blazer Hero' },
        flat: { url: '/api/placeholder/400/500', alt: 'Velvet Blazer Flat' },
        lifestyle: [
          { url: '/api/placeholder/400/500', alt: 'Lifestyle 1' },
          { url: '/api/placeholder/400/500', alt: 'Lifestyle 2' }
        ],
        details: [
          { url: '/api/placeholder/400/500', alt: 'Detail 1' },
          { url: '/api/placeholder/400/500', alt: 'Detail 2' }
        ],
        totalImages: 6
      },
      colorFamily: 'Blue',
      colorName: 'Midnight Navy',
      materials: {
        primary: 'Velvet',
        composition: { 'Cotton Velvet': 85, 'Silk': 15 }
      },
      fitType: 'Modern Fit',
      sizeRange: {
        min: 'XS',
        max: '3XL',
        available: ['XS', 'S', 'M', 'L', 'XL', '2XL', '3XL']
      },
      status: 'active',
      viewCount: 1245,
      addToCartCount: 89,
      purchaseCount: 34,
      returnRate: 2.5,
      createdAt: '2024-01-15T10:00:00Z',
      updatedAt: '2024-08-14T15:30:00Z'
    },
    // Add more mock products as needed
  ], []);

  const toggleProductSelection = useCallback((productId: string) => {
    setSelectedProducts(prev => {
      const newSet = new Set(prev);
      if (newSet.has(productId)) {
        newSet.delete(productId);
      } else {
        newSet.add(productId);
      }
      return newSet;
    });
  }, []);

  const selectAllProducts = useCallback(() => {
    if (selectedProducts.size === products.length) {
      setSelectedProducts(new Set());
    } else {
      setSelectedProducts(new Set(products.map(p => p.id)));
    }
  }, [selectedProducts, products]);

  return (
    <div className="min-h-screen bg-gray-50">
      {/* Header Section */}
      <div className="bg-white border-b border-gray-200 sticky top-0 z-40">
        <div className="px-6 py-4">
          <div className="flex items-center justify-between">
            <div className="flex items-center space-x-4">
              <h1 className="text-2xl font-bold text-gray-900">Products</h1>
              <span className="px-3 py-1 bg-gray-100 text-gray-600 rounded-full text-sm">
                274 total
              </span>
            </div>
            
            <div className="flex items-center space-x-3">
              {/* Quick Actions */}
              <button className="flex items-center px-4 py-2 bg-black text-white rounded-lg hover:bg-gray-800 transition">
                <Plus className="w-4 h-4 mr-2" />
                Add Product
              </button>
              <button className="flex items-center px-4 py-2 border border-gray-300 rounded-lg hover:bg-gray-50">
                <Upload className="w-4 h-4 mr-2" />
                Import
              </button>
              <button className="flex items-center px-4 py-2 border border-gray-300 rounded-lg hover:bg-gray-50">
                <Download className="w-4 h-4 mr-2" />
                Export
              </button>
            </div>
          </div>

          {/* Search and Filter Bar */}
          <div className="flex items-center space-x-4 mt-4">
            {/* Search */}
            <div className="flex-1 relative">
              <Search className="absolute left-3 top-1/2 transform -translate-y-1/2 text-gray-400 w-5 h-5" />
              <input
                type="text"
                placeholder="Search products by name, SKU, or style code..."
                value={searchQuery}
                onChange={(e) => setSearchQuery(e.target.value)}
                className="w-full pl-10 pr-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-black focus:border-transparent"
              />
            </div>

            {/* Filters */}
            <button 
              onClick={() => setFilterOpen(!filterOpen)}
              className="flex items-center px-4 py-2 border border-gray-300 rounded-lg hover:bg-gray-50"
            >
              <Filter className="w-4 h-4 mr-2" />
              Filters
              {filterOpen && <span className="ml-2 px-2 py-0.5 bg-black text-white text-xs rounded-full">3</span>}
            </button>

            {/* View Mode Toggle */}
            <div className="flex items-center border border-gray-300 rounded-lg">
              <button
                onClick={() => setViewMode('grid')}
                className={`p-2 ${viewMode === 'grid' ? 'bg-black text-white' : 'text-gray-600 hover:bg-gray-50'}`}
              >
                <Grid3x3 className="w-4 h-4" />
              </button>
              <button
                onClick={() => setViewMode('list')}
                className={`p-2 ${viewMode === 'list' ? 'bg-black text-white' : 'text-gray-600 hover:bg-gray-50'}`}
              >
                <List className="w-4 h-4" />
              </button>
              <button
                onClick={() => setViewMode('board')}
                className={`p-2 ${viewMode === 'board' ? 'bg-black text-white' : 'text-gray-600 hover:bg-gray-50'}`}
              >
                <LayoutGrid className="w-4 h-4" />
              </button>
            </div>
          </div>

          {/* Active Filters */}
          {filterOpen && (
            <div className="flex items-center space-x-2 mt-3">
              <span className="text-sm text-gray-600">Active filters:</span>
              <span className="px-3 py-1 bg-gray-100 text-gray-700 rounded-full text-sm flex items-center">
                Category: Blazers
                <button className="ml-2 text-gray-500 hover:text-gray-700">×</button>
              </span>
              <span className="px-3 py-1 bg-gray-100 text-gray-700 rounded-full text-sm flex items-center">
                Season: FW24
                <button className="ml-2 text-gray-500 hover:text-gray-700">×</button>
              </span>
              <span className="px-3 py-1 bg-gray-100 text-gray-700 rounded-full text-sm flex items-center">
                Status: Active
                <button className="ml-2 text-gray-500 hover:text-gray-700">×</button>
              </span>
              <button className="text-sm text-blue-600 hover:text-blue-700">Clear all</button>
            </div>
          )}
        </div>

        {/* Bulk Actions Bar */}
        {selectedProducts.size > 0 && (
          <div className="px-6 py-3 bg-blue-50 border-t border-blue-200">
            <div className="flex items-center justify-between">
              <div className="flex items-center space-x-4">
                <button
                  onClick={selectAllProducts}
                  className="flex items-center text-blue-600 hover:text-blue-700"
                >
                  {selectedProducts.size === products.length ? 
                    <CheckSquare className="w-4 h-4 mr-2" /> : 
                    <Square className="w-4 h-4 mr-2" />
                  }
                  {selectedProducts.size === products.length ? 'Deselect all' : 'Select all'}
                </button>
                <span className="text-sm text-blue-600">
                  {selectedProducts.size} product{selectedProducts.size !== 1 ? 's' : ''} selected
                </span>
              </div>

              <div className="flex items-center space-x-2">
                <button className="px-3 py-1 text-sm bg-white border border-blue-300 rounded-lg hover:bg-blue-50">
                  Update Prices
                </button>
                <button className="px-3 py-1 text-sm bg-white border border-blue-300 rounded-lg hover:bg-blue-50">
                  Change Category
                </button>
                <button className="px-3 py-1 text-sm bg-white border border-blue-300 rounded-lg hover:bg-blue-50">
                  Archive
                </button>
                <button 
                  onClick={() => setBulkActionOpen(!bulkActionOpen)}
                  className="px-3 py-1 text-sm bg-white border border-blue-300 rounded-lg hover:bg-blue-50 flex items-center"
                >
                  More Actions
                  <ChevronDown className="w-3 h-3 ml-1" />
                </button>
              </div>
            </div>
          </div>
        )}
      </div>

      {/* Product Grid View */}
      {viewMode === 'grid' && (
        <div className="p-6">
          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4 gap-6">
            {products.map((product) => (
              <ProductCard 
                key={product.id} 
                product={product}
                isSelected={selectedProducts.has(product.id)}
                onToggleSelect={toggleProductSelection}
              />
            ))}
          </div>
        </div>
      )}

      {/* Product List View */}
      {viewMode === 'list' && (
        <div className="p-6">
          <div className="bg-white rounded-lg shadow-sm border border-gray-200">
            <table className="w-full">
              <thead className="bg-gray-50 border-b border-gray-200">
                <tr>
                  <th className="p-4 text-left">
                    <input
                      type="checkbox"
                      checked={selectedProducts.size === products.length}
                      onChange={selectAllProducts}
                      className="rounded border-gray-300"
                    />
                  </th>
                  <th className="p-4 text-left text-sm font-medium text-gray-700">Product</th>
                  <th className="p-4 text-left text-sm font-medium text-gray-700">SKU</th>
                  <th className="p-4 text-left text-sm font-medium text-gray-700">Category</th>
                  <th className="p-4 text-left text-sm font-medium text-gray-700">Price Tier</th>
                  <th className="p-4 text-left text-sm font-medium text-gray-700">Status</th>
                  <th className="p-4 text-left text-sm font-medium text-gray-700">Performance</th>
                  <th className="p-4 text-left text-sm font-medium text-gray-700">Actions</th>
                </tr>
              </thead>
              <tbody>
                {products.map((product) => (
                  <ProductListRow
                    key={product.id}
                    product={product}
                    isSelected={selectedProducts.has(product.id)}
                    onToggleSelect={toggleProductSelection}
                  />
                ))}
              </tbody>
            </table>
          </div>
        </div>
      )}

      {/* Product Board View */}
      {viewMode === 'board' && (
        <div className="p-6">
          <div className="flex space-x-6 overflow-x-auto">
            <ProductBoard title="Draft" products={products.filter(p => p.status === 'draft')} />
            <ProductBoard title="Active" products={products.filter(p => p.status === 'active')} />
            <ProductBoard title="Archived" products={products.filter(p => p.status === 'archived')} />
          </div>
        </div>
      )}
    </div>
  );
}

// Product Card Component for Grid View
function ProductCard({ 
  product, 
  isSelected, 
  onToggleSelect 
}: { 
  product: EnhancedProduct; 
  isSelected: boolean;
  onToggleSelect: (id: string) => void;
}) {
  const [showQuickActions, setShowQuickActions] = useState(false);
  
  const tierConfig = PRICE_TIERS[product.priceTier as keyof typeof PRICE_TIERS];
  const hasDiscount = product.compareAtPrice && product.compareAtPrice > product.basePrice;
  const discountPercentage = hasDiscount 
    ? Math.round((1 - product.basePrice / product.compareAtPrice!) * 100)
    : 0;

  return (
    <div 
      className={`bg-white rounded-lg shadow-sm border ${isSelected ? 'border-blue-500 ring-2 ring-blue-200' : 'border-gray-200'} hover:shadow-lg transition-all duration-200 overflow-hidden group`}
      onMouseEnter={() => setShowQuickActions(true)}
      onMouseLeave={() => setShowQuickActions(false)}
    >
      {/* Selection Checkbox */}
      <div className="absolute top-3 left-3 z-10">
        <input
          type="checkbox"
          checked={isSelected}
          onChange={() => onToggleSelect(product.id)}
          className="w-4 h-4 rounded border-gray-300 bg-white/80 backdrop-blur"
        />
      </div>

      {/* Quick Actions */}
      {showQuickActions && (
        <div className="absolute top-3 right-3 z-10 flex space-x-1">
          <button className="p-1.5 bg-white/90 backdrop-blur rounded-lg hover:bg-white shadow-sm">
            <Eye className="w-4 h-4 text-gray-600" />
          </button>
          <button className="p-1.5 bg-white/90 backdrop-blur rounded-lg hover:bg-white shadow-sm">
            <Edit2 className="w-4 h-4 text-gray-600" />
          </button>
          <button className="p-1.5 bg-white/90 backdrop-blur rounded-lg hover:bg-white shadow-sm">
            <Copy className="w-4 h-4 text-gray-600" />
          </button>
        </div>
      )}

      {/* Product Image Gallery Indicator */}
      <div className="relative aspect-[3/4] bg-gray-100">
        {product.images.hero ? (
          <img
            src={product.images.hero.url}
            alt={product.images.hero.alt}
            className="w-full h-full object-cover"
          />
        ) : (
          <div className="w-full h-full flex items-center justify-center">
            <Image className="w-12 h-12 text-gray-400" />
          </div>
        )}
        
        {/* Image Count Badge */}
        <div className="absolute bottom-2 right-2 px-2 py-1 bg-black/70 text-white text-xs rounded-lg flex items-center">
          <Image className="w-3 h-3 mr-1" />
          {product.images.totalImages}
        </div>

        {/* Discount Badge */}
        {hasDiscount && (
          <div className="absolute top-12 left-3 px-2 py-1 bg-red-500 text-white text-xs font-semibold rounded">
            -{discountPercentage}%
          </div>
        )}

        {/* Season Badge */}
        {product.season && (
          <div className="absolute bottom-2 left-2 px-2 py-1 bg-white/90 backdrop-blur text-gray-700 text-xs rounded">
            {product.season}
          </div>
        )}
      </div>

      {/* Product Info */}
      <div className="p-4">
        {/* Title and Style Code */}
        <div className="mb-2">
          <h3 className="font-semibold text-gray-900 line-clamp-1">{product.name}</h3>
          <p className="text-xs text-gray-500 mt-0.5">
            {product.styleCode} • {product.sku}
          </p>
        </div>

        {/* Category and Collection */}
        <div className="flex items-center space-x-2 mb-3">
          <span className="text-xs px-2 py-1 bg-gray-100 text-gray-600 rounded">
            {product.category}
          </span>
          {product.collection && (
            <span className="text-xs px-2 py-1 bg-purple-100 text-purple-700 rounded">
              {product.collection}
            </span>
          )}
        </div>

        {/* Price Tier and Amount */}
        <div className="flex items-center justify-between mb-3">
          <div>
            <div className="flex items-center space-x-2">
              <span className={`px-2 py-1 text-xs font-medium text-white rounded ${tierConfig.color}`}>
                {product.priceTier}
              </span>
              <span className="text-xs text-gray-500">{tierConfig.range}</span>
            </div>
            <div className="mt-1">
              <span className="text-lg font-bold text-gray-900">
                ${(product.basePrice / 100).toFixed(2)}
              </span>
              {hasDiscount && (
                <span className="ml-2 text-sm text-gray-500 line-through">
                  ${(product.compareAtPrice! / 100).toFixed(2)}
                </span>
              )}
            </div>
          </div>
        </div>

        {/* Material and Fit */}
        {product.materials && (
          <div className="flex items-center space-x-3 text-xs text-gray-600 mb-3">
            <span className="flex items-center">
              <Sparkles className="w-3 h-3 mr-1" />
              {product.materials.primary}
            </span>
            {product.fitType && (
              <span className="flex items-center">
                <Ruler className="w-3 h-3 mr-1" />
                {product.fitType}
              </span>
            )}
          </div>
        )}

        {/* Size Range */}
        {product.sizeRange && (
          <div className="text-xs text-gray-600 mb-3">
            Sizes: {product.sizeRange.min} - {product.sizeRange.max}
          </div>
        )}

        {/* Performance Metrics */}
        <div className="grid grid-cols-3 gap-2 text-xs">
          <div className="text-center">
            <div className="font-semibold text-gray-900">{product.viewCount}</div>
            <div className="text-gray-500">Views</div>
          </div>
          <div className="text-center">
            <div className="font-semibold text-gray-900">{product.addToCartCount}</div>
            <div className="text-gray-500">Cart</div>
          </div>
          <div className="text-center">
            <div className="font-semibold text-gray-900">{product.purchaseCount}</div>
            <div className="text-gray-500">Sold</div>
          </div>
        </div>

        {/* Status */}
        <div className="mt-3 pt-3 border-t border-gray-100 flex items-center justify-between">
          <span className={`inline-flex items-center px-2 py-1 rounded-full text-xs font-medium ${
            product.status === 'active' 
              ? 'bg-green-100 text-green-800' 
              : product.status === 'draft'
              ? 'bg-gray-100 text-gray-800'
              : 'bg-red-100 text-red-800'
          }`}>
            <span className={`w-1.5 h-1.5 rounded-full mr-1.5 ${
              product.status === 'active' 
                ? 'bg-green-500' 
                : product.status === 'draft'
                ? 'bg-gray-500'
                : 'bg-red-500'
            }`} />
            {product.status.charAt(0).toUpperCase() + product.status.slice(1)}
          </span>

          {/* Return Rate Warning */}
          {product.returnRate && product.returnRate > 5 && (
            <div className="flex items-center text-amber-600">
              <AlertCircle className="w-3 h-3 mr-1" />
              <span className="text-xs">{product.returnRate}% returns</span>
            </div>
          )}
        </div>
      </div>
    </div>
  );
}

// Product List Row Component
function ProductListRow({ 
  product, 
  isSelected, 
  onToggleSelect 
}: { 
  product: EnhancedProduct; 
  isSelected: boolean;
  onToggleSelect: (id: string) => void;
}) {
  const tierConfig = PRICE_TIERS[product.priceTier as keyof typeof PRICE_TIERS];
  
  return (
    <tr className="border-b border-gray-200 hover:bg-gray-50">
      <td className="p-4">
        <input
          type="checkbox"
          checked={isSelected}
          onChange={() => onToggleSelect(product.id)}
          className="rounded border-gray-300"
        />
      </td>
      <td className="p-4">
        <div className="flex items-center space-x-3">
          <div className="w-12 h-16 bg-gray-100 rounded overflow-hidden">
            {product.images.hero ? (
              <img
                src={product.images.hero.url}
                alt={product.images.hero.alt}
                className="w-full h-full object-cover"
              />
            ) : (
              <div className="w-full h-full flex items-center justify-center">
                <Image className="w-6 h-6 text-gray-400" />
              </div>
            )}
          </div>
          <div>
            <div className="font-medium text-gray-900">{product.name}</div>
            <div className="text-sm text-gray-500">{product.styleCode}</div>
          </div>
        </div>
      </td>
      <td className="p-4 text-sm text-gray-900">{product.sku}</td>
      <td className="p-4">
        <span className="text-sm text-gray-900">{product.category}</span>
        {product.subcategory && (
          <span className="text-xs text-gray-500 block">{product.subcategory}</span>
        )}
      </td>
      <td className="p-4">
        <span className={`px-2 py-1 text-xs font-medium text-white rounded ${tierConfig.color}`}>
          {product.priceTier}
        </span>
        <span className="text-xs text-gray-500 block mt-1">${(product.basePrice / 100).toFixed(2)}</span>
      </td>
      <td className="p-4">
        <span className={`inline-flex items-center px-2 py-1 rounded-full text-xs font-medium ${
          product.status === 'active' 
            ? 'bg-green-100 text-green-800' 
            : product.status === 'draft'
            ? 'bg-gray-100 text-gray-800'
            : 'bg-red-100 text-red-800'
        }`}>
          {product.status}
        </span>
      </td>
      <td className="p-4">
        <div className="text-xs">
          <div>{product.viewCount} views</div>
          <div>{product.purchaseCount} sold</div>
        </div>
      </td>
      <td className="p-4">
        <button className="text-gray-400 hover:text-gray-600">
          <MoreVertical className="w-4 h-4" />
        </button>
      </td>
    </tr>
  );
}

// Product Board Component
function ProductBoard({ title, products }: { title: string; products: EnhancedProduct[] }) {
  return (
    <div className="bg-gray-100 rounded-lg p-4 min-w-[320px]">
      <div className="flex items-center justify-between mb-4">
        <h3 className="font-semibold text-gray-900">{title}</h3>
        <span className="px-2 py-1 bg-gray-200 text-gray-600 rounded text-sm">
          {products.length}
        </span>
      </div>
      <div className="space-y-3">
        {products.map((product) => (
          <div key={product.id} className="bg-white rounded-lg p-3 shadow-sm">
            <div className="flex items-start space-x-3">
              <div className="w-16 h-20 bg-gray-100 rounded overflow-hidden">
                {product.images.hero && (
                  <img
                    src={product.images.hero.url}
                    alt={product.images.hero.alt}
                    className="w-full h-full object-cover"
                  />
                )}
              </div>
              <div className="flex-1">
                <h4 className="font-medium text-gray-900 text-sm line-clamp-1">
                  {product.name}
                </h4>
                <p className="text-xs text-gray-500 mt-1">{product.sku}</p>
                <div className="flex items-center space-x-2 mt-2">
                  <span className="text-xs px-2 py-1 bg-gray-100 rounded">
                    {product.category}
                  </span>
                  <span className="text-xs font-medium">
                    ${(product.basePrice / 100).toFixed(2)}
                  </span>
                </div>
              </div>
            </div>
          </div>
        ))}
      </div>
    </div>
  );
}