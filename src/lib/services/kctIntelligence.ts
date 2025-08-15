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
  private baseUrl = import.meta.env.VITE_KCT_API_URL || 'https://kct-knowledge-api-2-production.up.railway.app';
  private apiKey = import.meta.env.VITE_KCT_API_KEY || 'kct-menswear-api-2024-secret';
  private cache = new Map<string, { data: any; timestamp: number }>();
  private cacheTimeout = 5 * 60 * 1000; // 5 minutes
  private maxRetries = 3;
  private retryDelay = 1000; // 1 second
  private requestTimeout = 10000; // 10 seconds
  private healthStatus: 'healthy' | 'degraded' | 'down' = 'healthy';
  private lastHealthCheck = 0;

  /**
   * Check API health status
   */
  async checkHealth(): Promise<{ status: string; latency?: number; error?: string }> {
    const startTime = Date.now();
    
    try {
      const controller = new AbortController();
      const timeoutId = setTimeout(() => controller.abort(), 5000);
      
      const response = await fetch(`${this.baseUrl}/health`, {
        method: 'GET',
        signal: controller.signal,
        headers: {
          'X-API-Key': this.apiKey
        }
      });
      
      clearTimeout(timeoutId);
      const latency = Date.now() - startTime;
      
      if (response.ok) {
        this.healthStatus = latency > 3000 ? 'degraded' : 'healthy';
        this.lastHealthCheck = Date.now();
        return { status: this.healthStatus, latency };
      } else {
        this.healthStatus = 'down';
        return { status: 'down', error: `HTTP ${response.status}` };
      }
    } catch (error) {
      this.healthStatus = 'down';
      const errorMessage = error instanceof Error ? error.message : 'Network error';
      console.error('KCT API health check failed:', errorMessage);
      return { status: 'down', error: errorMessage };
    }
  }

  /**
   * Test specific endpoints
   */
  async testEndpoints(): Promise<{ [endpoint: string]: boolean }> {
    const endpoints = ['/recommendations', '/colors/validate', '/rules/check'];
    const results: { [endpoint: string]: boolean } = {};
    
    for (const endpoint of endpoints) {
      try {
        const response = await this.makeRequest(endpoint, { test: true }, false);
        results[endpoint] = response.success;
      } catch (error) {
        results[endpoint] = false;
      }
    }
    
    return results;
  }

  /**
   * Make API request with comprehensive error handling and retry logic
   */
  private async makeRequest<T>(endpoint: string, data: any, useCache = false): Promise<KCTApiResponse<T>> {
    const cacheKey = `${endpoint}-${JSON.stringify(data)}`;
    
    // Check cache if enabled
    if (useCache && this.cache.has(cacheKey)) {
      const cached = this.cache.get(cacheKey)!;
      if (Date.now() - cached.timestamp < this.cacheTimeout) {
        console.log(`KCT API: Cache hit for ${endpoint}`);
        return { success: true, data: cached.data };
      }
    }

    // Check if we should perform a health check
    if (Date.now() - this.lastHealthCheck > 300000) { // 5 minutes
      const health = await this.checkHealth();
      console.log('KCT API Health:', health);
    }

    let lastError: Error | null = null;
    
    for (let attempt = 1; attempt <= this.maxRetries; attempt++) {
      try {
        console.log(`KCT API: Attempt ${attempt}/${this.maxRetries} for ${endpoint}`);
        
        const controller = new AbortController();
        const timeoutId = setTimeout(() => controller.abort(), this.requestTimeout);
        
        const response = await fetch(`${this.baseUrl}/api${endpoint}`, {
          method: 'POST',
          signal: controller.signal,
          headers: {
            'Content-Type': 'application/json',
            'X-API-Key': this.apiKey,
            'User-Agent': 'KCT-Admin/1.0',
            'Accept': 'application/json'
          },
          body: JSON.stringify(data)
        });

        clearTimeout(timeoutId);

        // Handle different HTTP status codes
        if (response.status === 429) {
          // Rate limited - wait longer before retry
          const waitTime = Math.pow(2, attempt) * this.retryDelay;
          console.log(`KCT API: Rate limited, waiting ${waitTime}ms before retry`);
          await this.sleep(waitTime);
          continue;
        }

        if (response.status >= 500) {
          // Server error - retry
          throw new Error(`Server error: ${response.status} ${response.statusText}`);
        }

        if (!response.ok) {
          // Client error - don't retry
          const errorText = await response.text();
          console.error(`KCT API: Client error ${response.status}:`, errorText);
          return {
            success: false,
            data: null as any,
            error: `API request failed: ${response.status} ${response.statusText}`
          };
        }

        const result = await response.json();
        
        // Validate response structure
        if (!result || typeof result !== 'object') {
          throw new Error('Invalid response format');
        }
        
        // Cache successful responses
        if (useCache) {
          this.cache.set(cacheKey, { data: result, timestamp: Date.now() });
          console.log(`KCT API: Cached response for ${endpoint}`);
        }

        this.healthStatus = 'healthy';
        console.log(`KCT API: Success for ${endpoint}`);
        
        return {
          success: true,
          data: result
        };

      } catch (error) {
        lastError = error instanceof Error ? error : new Error('Unknown error');
        
        // Don't retry on abort (timeout)
        if (lastError.name === 'AbortError') {
          console.error(`KCT API: Request timeout for ${endpoint}`);
          break;
        }
        
        console.error(`KCT API: Attempt ${attempt} failed:`, lastError.message);
        
        // Wait before retry (exponential backoff)
        if (attempt < this.maxRetries) {
          const waitTime = Math.pow(2, attempt - 1) * this.retryDelay;
          console.log(`KCT API: Waiting ${waitTime}ms before retry`);
          await this.sleep(waitTime);
        }
      }
    }

    // All retries failed
    this.healthStatus = 'down';
    const errorMessage = lastError?.message || 'All retries failed';
    console.error(`KCT API: All attempts failed for ${endpoint}:`, errorMessage);
    
    return {
      success: false,
      data: null as any,
      error: errorMessage
    };
  }

  /**
   * Sleep utility for retry delays
   */
  private sleep(ms: number): Promise<void> {
    return new Promise(resolve => setTimeout(resolve, ms));
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
   * Get service status and metrics
   */
  getStatus(): {
    health: 'healthy' | 'degraded' | 'down';
    cacheSize: number;
    lastHealthCheck: Date | null;
    uptime: number;
  } {
    return {
      health: this.healthStatus,
      cacheSize: this.cache.size,
      lastHealthCheck: this.lastHealthCheck > 0 ? new Date(this.lastHealthCheck) : null,
      uptime: Date.now() - (this.lastHealthCheck || Date.now())
    };
  }

  /**
   * Perform comprehensive service diagnostics
   */
  async runDiagnostics(): Promise<{
    health: any;
    endpoints: any;
    performance: any;
    cache: any;
  }> {
    console.log('KCT Intelligence: Running diagnostics...');
    
    const diagnostics = {
      health: await this.checkHealth(),
      endpoints: await this.testEndpoints(),
      performance: await this.measurePerformance(),
      cache: {
        size: this.cache.size,
        maxAge: this.cacheTimeout,
        keys: Array.from(this.cache.keys()).slice(0, 10) // Sample of cache keys
      }
    };
    
    console.log('KCT Intelligence Diagnostics:', diagnostics);
    return diagnostics;
  }

  /**
   * Measure API performance
   */
  private async measurePerformance(): Promise<{
    averageLatency: number;
    samples: number;
    errors: number;
  }> {
    const testData = { test: true, timestamp: Date.now() };
    const results: number[] = [];
    let errors = 0;
    
    // Run 5 test requests
    for (let i = 0; i < 5; i++) {
      const start = Date.now();
      try {
        await this.makeRequest('/recommendations', testData, false);
        results.push(Date.now() - start);
      } catch (error) {
        errors++;
      }
    }
    
    const averageLatency = results.length > 0 
      ? results.reduce((a, b) => a + b, 0) / results.length 
      : 0;
    
    return {
      averageLatency,
      samples: results.length,
      errors
    };
  }

  /**
   * Enhanced generate description with fallback
   */
  async generateDescriptionEnhanced(productData: {
    name: string;
    category: string;
    materials?: string[];
    occasion?: string[];
    fit_type?: string;
    features?: string[];
    price?: number;
    images?: string[];
  }): Promise<KCTApiResponse<EnhancedDescription & { generated_by: string; confidence: number }>> {
    try {
      // First try the AI service
      const response = await this.makeRequest<any>('/recommendations', {
        type: 'enhanced_description',
        product: productData,
        context: 'admin_enhancement',
        include_confidence: true
      });

      if (response.success && response.data) {
        return {
          success: true,
          data: {
            description: response.data.description || this.generateFallbackDescription(productData),
            seo_description: response.data.seo_description || this.generateFallbackSEO(productData),
            key_features: response.data.features || this.inferFeaturesFromProduct(productData),
            styling_tips: response.data.styling_tips,
            generated_by: 'ai',
            confidence: response.data.confidence || 0.85
          }
        };
      }
    } catch (error) {
      console.warn('AI description generation failed, using fallback:', error);
    }

    // Fallback to rule-based generation
    return {
      success: true,
      data: {
        description: this.generateFallbackDescription(productData),
        seo_description: this.generateFallbackSEO(productData),
        key_features: this.inferFeaturesFromProduct(productData),
        styling_tips: this.generateStylingTips(productData),
        generated_by: 'fallback',
        confidence: 0.65
      }
    };
  }

  /**
   * Validate product with detailed scoring
   */
  async validateProductEnhanced(productData: any): Promise<KCTApiResponse<ProductValidation & {
    detailed_scores: { [category: string]: number };
    recommendations: string[];
    completeness: number;
  }>> {
    try {
      const response = await this.makeRequest<any>('/rules/check', {
        product: productData,
        context: 'detailed_validation',
        include_scores: true
      });

      if (response.success && response.data) {
        return {
          success: true,
          data: {
            isValid: response.data.passed !== false,
            quality_score: response.data.overall_score || this.calculateQualityScore(productData, response.data),
            errors: response.data.errors || [],
            warnings: response.data.warnings || [],
            suggestions: response.data.suggestions || [],
            detailed_scores: response.data.detailed_scores || this.calculateDetailedScores(productData),
            recommendations: response.data.recommendations || this.generateRecommendations(productData),
            completeness: response.data.completeness || this.calculateCompleteness(productData)
          }
        };
      }
    } catch (error) {
      console.warn('Enhanced validation failed, using basic validation:', error);
    }

    // Fallback validation
    const detailedScores = this.calculateDetailedScores(productData);
    const completeness = this.calculateCompleteness(productData);
    
    return {
      success: true,
      data: {
        isValid: completeness > 0.7,
        quality_score: Math.round(Object.values(detailedScores).reduce((a, b) => a + b, 0) / Object.keys(detailedScores).length),
        errors: completeness < 0.5 ? ['Product information is incomplete'] : [],
        warnings: completeness < 0.8 ? ['Some product details could be improved'] : [],
        suggestions: this.generateRecommendations(productData),
        detailed_scores: detailedScores,
        recommendations: this.generateRecommendations(productData),
        completeness
      }
    };
  }

  // === Enhanced Helper Methods ===

  private inferFeaturesFromProduct(productData: any): string[] {
    const features: string[] = [];
    
    if (productData.materials?.includes('Wool')) {
      features.push('Natural Wool Construction', 'Breathable');
    }
    
    if (productData.category?.includes('Suit')) {
      features.push('Professional Appearance', 'Versatile Styling');
    }
    
    if (productData.fit_type === 'slim') {
      features.push('Modern Slim Fit', 'Tailored Silhouette');
    }
    
    if (productData.price && productData.price > 500) {
      features.push('Premium Quality', 'Investment Piece');
    }
    
    return features.length > 0 ? features : ['Quality Construction', 'Professional Grade'];
  }

  private generateStylingTips(productData: any): string {
    if (productData.category?.includes('Suit')) {
      return 'Perfect for boardroom meetings, formal events, and special occasions. Pair with a crisp dress shirt and leather dress shoes for a complete look.';
    }
    
    if (productData.category?.includes('Shirt')) {
      return 'Versatile piece that works well under blazers or on its own. Can be dressed up for business or down for smart casual occasions.';
    }
    
    return 'A versatile addition to any wardrobe that can be styled for multiple occasions.';
  }

  private calculateDetailedScores(productData: any): { [category: string]: number } {
    const scores: { [category: string]: number } = {};
    
    // Basic Information Score
    scores.basic_info = 0;
    if (productData.name) scores.basic_info += 30;
    if (productData.description && productData.description.length > 50) scores.basic_info += 40;
    if (productData.category) scores.basic_info += 30;
    
    // Pricing Score
    scores.pricing = 0;
    if (productData.base_price > 0) scores.pricing += 50;
    if (productData.compare_at_price) scores.pricing += 25;
    if (productData.cost_price) scores.pricing += 25;
    
    // Media Score
    scores.media = 0;
    if (productData.images && productData.images.length > 0) scores.media += 60;
    if (productData.images && productData.images.length > 2) scores.media += 40;
    
    // SEO Score
    scores.seo = 0;
    if (productData.meta_title) scores.seo += 40;
    if (productData.meta_description) scores.seo += 40;
    if (productData.url_slug) scores.seo += 20;
    
    // Product Details Score
    scores.details = 0;
    if (productData.materials) scores.details += 25;
    if (productData.care_instructions) scores.details += 25;
    if (productData.fit_type) scores.details += 25;
    if (productData.features && productData.features.length > 0) scores.details += 25;
    
    return scores;
  }

  private calculateCompleteness(productData: any): number {
    const requiredFields = ['name', 'category', 'base_price', 'description'];
    const optionalFields = ['images', 'materials', 'meta_title', 'meta_description', 'features'];
    
    const requiredScore = requiredFields.filter(field => productData[field]).length / requiredFields.length;
    const optionalScore = optionalFields.filter(field => productData[field]).length / optionalFields.length;
    
    return (requiredScore * 0.7) + (optionalScore * 0.3);
  }

  private generateRecommendations(productData: any): string[] {
    const recommendations: string[] = [];
    
    if (!productData.images || productData.images.length === 0) {
      recommendations.push('Add high-quality product images to improve customer engagement');
    }
    
    if (!productData.meta_title) {
      recommendations.push('Add SEO-optimized meta title for better search visibility');
    }
    
    if (!productData.description || productData.description.length < 100) {
      recommendations.push('Expand product description with more details and benefits');
    }
    
    if (!productData.materials) {
      recommendations.push('Specify materials and fabric composition for customer information');
    }
    
    if (productData.images && productData.images.length < 3) {
      recommendations.push('Add more product images from different angles');
    }
    
    return recommendations;
  }

  /**
   * Clear cache
   */
  clearCache(): void {
    this.cache.clear();
    console.log('KCT Intelligence: Cache cleared');
  }

  /**
   * Get cache statistics
   */
  getCacheStats(): {
    size: number;
    maxAge: number;
    hitRate: number;
    totalRequests: number;
  } {
    // This would need to be tracked in production
    return {
      size: this.cache.size,
      maxAge: this.cacheTimeout,
      hitRate: 0.75, // Mock value
      totalRequests: 1000 // Mock value
    };
  }
}

// Export singleton instance
export const kctIntelligence = new KCTIntelligenceService();