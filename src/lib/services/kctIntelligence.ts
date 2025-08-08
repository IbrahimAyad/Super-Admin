/**
 * KCT INTELLIGENCE SERVICE
 * Integrates with KCT Knowledge API for smart product management
 * Provides AI-powered enhancements without complexity
 */

interface KCTApiResponse<T = any> {
  success: boolean;
  data: T;
  error?: string;
}

interface EnhancedDescription {
  description: string;
  seo_description: string;
  key_features: string[];
  styling_tips?: string;
}

interface SEOContent {
  meta_title: string;
  meta_description: string;
  suggested_slug: string;
  keywords: string[];
}

interface ColorValidation {
  isValid: boolean;
  score: number;
  warnings: string[];
  suggestions: string[];
  complementary_colors?: string[];
}

interface ProductValidation {
  isValid: boolean;
  quality_score: number;
  errors: string[];
  warnings: string[];
  suggestions: string[];
}

interface SmartDefaults {
  materials?: string[];
  care_instructions?: string;
  fit_type?: string;
  occasion?: string[];
  features?: string[];
  sizing_info?: string;
}

class KCTIntelligenceService {
  private baseUrl = process.env.NEXT_PUBLIC_KCT_API_URL || 'https://kct-knowledge-api-2-production.up.railway.app';
  private apiKey = process.env.NEXT_PUBLIC_KCT_API_KEY || 'kct-menswear-api-2024-secret';
  private cache = new Map<string, { data: any; timestamp: number }>();
  private cacheTimeout = 5 * 60 * 1000; // 5 minutes

  /**
   * Make API request with error handling and caching
   */
  private async makeRequest<T>(endpoint: string, data: any, useCache = false): Promise<KCTApiResponse<T>> {
    const cacheKey = `${endpoint}-${JSON.stringify(data)}`;
    
    // Check cache if enabled
    if (useCache && this.cache.has(cacheKey)) {
      const cached = this.cache.get(cacheKey)!;
      if (Date.now() - cached.timestamp < this.cacheTimeout) {
        return { success: true, data: cached.data };
      }
    }

    try {
      const response = await fetch(`${this.baseUrl}/api${endpoint}`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'X-API-Key': this.apiKey
        },
        body: JSON.stringify(data)
      });

      if (!response.ok) {
        throw new Error(`API request failed: ${response.statusText}`);
      }

      const result = await response.json();
      
      // Cache successful responses
      if (useCache) {
        this.cache.set(cacheKey, { data: result, timestamp: Date.now() });
      }

      return {
        success: true,
        data: result
      };
    } catch (error) {
      console.error('KCT API Error:', error);
      return {
        success: false,
        data: null as any,
        error: error instanceof Error ? error.message : 'Unknown error'
      };
    }
  }

  /**
   * Generate enhanced product description with AI
   */
  async generateDescription(productData: {
    name: string;
    category: string;
    materials?: string[];
    occasion?: string[];
    fit_type?: string;
    features?: string[];
  }): Promise<KCTApiResponse<EnhancedDescription>> {
    // Use existing recommendation endpoint for description generation
    const response = await this.makeRequest<any>('/recommendations', {
      type: 'description',
      product: productData,
      context: 'admin_enhancement'
    });

    if (!response.success) {
      return response;
    }

    // Transform response to our format
    return {
      success: true,
      data: {
        description: response.data.description || this.generateFallbackDescription(productData),
        seo_description: response.data.seo_description || this.generateFallbackSEO(productData),
        key_features: response.data.features || [],
        styling_tips: response.data.styling_tips
      }
    };
  }

  /**
   * Generate SEO content for product
   */
  async generateSEO(productData: {
    name: string;
    category: string;
    description?: string;
    features?: string[];
  }): Promise<KCTApiResponse<SEOContent>> {
    const response = await this.makeRequest<any>('/recommendations', {
      type: 'seo',
      product: productData,
      context: 'seo_optimization'
    });

    if (!response.success) {
      return {
        success: true,
        data: this.generateFallbackSEOContent(productData)
      };
    }

    return {
      success: true,
      data: {
        meta_title: response.data.meta_title || `${productData.name} | KCT Menswear`,
        meta_description: response.data.meta_description || productData.description?.substring(0, 160),
        suggested_slug: response.data.slug || this.generateSlug(productData.name),
        keywords: response.data.keywords || []
      }
    };
  }

  /**
   * Validate color combinations
   */
  async validateColors(colors: string[], context?: {
    product_type?: string;
    occasion?: string;
  }): Promise<KCTApiResponse<ColorValidation>> {
    const response = await this.makeRequest<any>('/colors/validate', {
      colors,
      context
    });

    if (!response.success) {
      return {
        success: true,
        data: {
          isValid: true,
          score: 75,
          warnings: [],
          suggestions: []
        }
      };
    }

    return {
      success: true,
      data: {
        isValid: response.data.isValid !== false,
        score: response.data.score || 75,
        warnings: response.data.warnings || [],
        suggestions: response.data.suggestions || [],
        complementary_colors: response.data.complementary
      }
    };
  }

  /**
   * Validate complete product data
   */
  async validateProduct(productData: any): Promise<KCTApiResponse<ProductValidation>> {
    const response = await this.makeRequest<any>('/rules/check', {
      product: productData,
      context: 'product_validation'
    });

    if (!response.success) {
      return {
        success: true,
        data: {
          isValid: true,
          quality_score: 80,
          errors: [],
          warnings: [],
          suggestions: []
        }
      };
    }

    return {
      success: true,
      data: {
        isValid: response.data.passed !== false,
        quality_score: this.calculateQualityScore(productData, response.data),
        errors: response.data.errors || [],
        warnings: response.data.warnings || [],
        suggestions: response.data.suggestions || []
      }
    };
  }

  /**
   * Get smart defaults based on partial product data
   */
  async getSmartDefaults(partialData: {
    name?: string;
    category?: string;
    product_type?: string;
  }): Promise<KCTApiResponse<SmartDefaults>> {
    const response = await this.makeRequest<any>('/recommendations', {
      type: 'defaults',
      partial_product: partialData,
      context: 'smart_defaults'
    }, true); // Use cache for defaults

    if (!response.success) {
      return {
        success: true,
        data: this.generateFallbackDefaults(partialData)
      };
    }

    return {
      success: true,
      data: {
        materials: response.data.materials,
        care_instructions: response.data.care_instructions,
        fit_type: response.data.fit_type,
        occasion: response.data.occasions,
        features: response.data.features,
        sizing_info: response.data.sizing_info
      }
    };
  }

  /**
   * Bulk optimization suggestions
   */
  async getBulkOptimizations(products: any[]): Promise<KCTApiResponse<any>> {
    return this.makeRequest('/recommendations', {
      type: 'bulk_optimization',
      products,
      context: 'admin_bulk'
    });
  }

  // === Fallback Generators (when API is unavailable) ===

  private generateFallbackDescription(product: any): string {
    const { name, category, materials, features } = product;
    let description = `Introducing our ${name}, a premium addition to our ${category} collection.`;
    
    if (materials?.length) {
      description += ` Crafted from ${materials.join(' and ')}.`;
    }
    
    if (features?.length) {
      description += ` Features include ${features.slice(0, 3).join(', ')}.`;
    }
    
    return description;
  }

  private generateFallbackSEO(product: any): string {
    return `${product.name} - Premium ${product.category} at KCT Menswear. ${product.features?.slice(0, 2).join('. ')}.`;
  }

  private generateFallbackSEOContent(product: any): SEOContent {
    return {
      meta_title: `${product.name} | KCT Menswear`,
      meta_description: product.description?.substring(0, 160) || this.generateFallbackSEO(product),
      suggested_slug: this.generateSlug(product.name),
      keywords: [product.category, 'menswear', 'kct'].filter(Boolean)
    };
  }

  private generateFallbackDefaults(partial: any): SmartDefaults {
    const defaults: SmartDefaults = {};
    
    if (partial.category?.toLowerCase().includes('suit')) {
      defaults.materials = ['Wool', 'Polyester'];
      defaults.care_instructions = 'Dry clean only. Store on hanger.';
      defaults.fit_type = 'Classic';
      defaults.occasion = ['Business', 'Formal'];
    } else if (partial.category?.toLowerCase().includes('shirt')) {
      defaults.materials = ['Cotton', 'Polyester'];
      defaults.care_instructions = 'Machine wash cold. Tumble dry low.';
      defaults.fit_type = 'Regular';
      defaults.occasion = ['Casual', 'Business Casual'];
    }
    
    return defaults;
  }

  private generateSlug(name: string): string {
    return name
      .toLowerCase()
      .replace(/[^a-z0-9]+/g, '-')
      .replace(/^-+|-+$/g, '');
  }

  private calculateQualityScore(product: any, validation: any): number {
    let score = 100;
    
    // Deduct points for missing fields
    if (!product.description) score -= 10;
    if (!product.images?.length) score -= 15;
    if (!product.meta_description) score -= 5;
    if (!product.materials?.length) score -= 5;
    
    // Deduct for validation issues
    score -= (validation.errors?.length || 0) * 10;
    score -= (validation.warnings?.length || 0) * 5;
    
    return Math.max(0, Math.min(100, score));
  }

  /**
   * Clear cache
   */
  clearCache(): void {
    this.cache.clear();
  }
}

// Export singleton instance
export const kctIntelligence = new KCTIntelligenceService();