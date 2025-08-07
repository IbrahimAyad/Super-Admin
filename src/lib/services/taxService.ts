/**
 * TAX SERVICE
 * Comprehensive tax calculation and compliance management
 * 
 * Features:
 * - Real-time tax calculation
 * - Multi-jurisdiction support
 * - Tax exemption handling
 * - Integration with TaxJar, Avalara APIs
 * - Sales tax compliance
 * - Tax reporting and filing
 */

import { supabase } from '../supabase-client';

// Types
export interface TaxCalculationRequest {
  from_address: Address;
  to_address: Address;
  line_items: Array<{
    id: string;
    quantity: number;
    unit_price: number;
    discount: number;
    product_tax_code?: string;
  }>;
  shipping: number;
  customer_exemption?: {
    type: 'resale' | 'non_profit' | 'government' | 'other';
    certificate_id: string;
    exempt_regions?: string[];
  };
  order_date?: string;
}

export interface Address {
  country: string;
  state?: string;
  zip?: string;
  city?: string;
  street?: string;
}

export interface TaxCalculationResponse {
  tax_amount: number;
  taxable_amount: number;
  has_nexus: boolean;
  tax_source: 'origin' | 'destination';
  jurisdictions: {
    country?: TaxJurisdiction;
    state?: TaxJurisdiction;
    county?: TaxJurisdiction;
    city?: TaxJurisdiction;
    special?: TaxJurisdiction[];
  };
  line_items: Array<{
    id: string;
    taxable_amount: number;
    tax_amount: number;
    combined_tax_rate: number;
    tax_breakdown: TaxJurisdiction[];
  }>;
  freight_taxable: boolean;
  rate_cache_key: string;
}

export interface TaxJurisdiction {
  country: string;
  state?: string;
  county?: string;
  city?: string;
  name: string;
  tax_rate: number;
  tax_amount: number;
  tax_type: 'sales' | 'use' | 'vat' | 'gst';
}

export interface TaxExemptionCertificate {
  id: string;
  customer_id: string;
  type: 'resale' | 'non_profit' | 'government' | 'manufacturing' | 'agriculture' | 'other';
  certificate_number: string;
  issuing_jurisdiction: string;
  valid_from: string;
  valid_until?: string;
  exempt_states: string[];
  exempt_categories?: string[];
  status: 'active' | 'expired' | 'revoked' | 'pending';
  uploaded_document_url?: string;
}

export interface TaxNexus {
  id: string;
  country: string;
  state: string;
  has_physical_nexus: boolean;
  has_economic_nexus: boolean;
  economic_threshold_sales?: number;
  economic_threshold_transactions?: number;
  effective_date: string;
  nexus_type: 'physical' | 'economic' | 'click_through' | 'marketplace';
}

export interface TaxReport {
  id: string;
  period_start: string;
  period_end: string;
  jurisdiction: string;
  total_sales: number;
  taxable_sales: number;
  exempt_sales: number;
  tax_collected: number;
  tax_due: number;
  status: 'draft' | 'filed' | 'amended';
  filed_date?: string;
  transactions_count: number;
}

class TaxService {
  private taxJarApiKey: string | null = null;
  private avalaraConfig: { accountId: string; licenseKey: string } | null = null;

  constructor() {
    // Initialize API keys from environment or settings
    this.initializeApiKeys();
  }

  /**
   * Calculate tax for an order
   */
  async calculateTax(request: TaxCalculationRequest): Promise<TaxCalculationResponse> {
    try {
      // Validate addresses
      this.validateAddresses(request.from_address, request.to_address);

      // Check for exemptions first
      if (request.customer_exemption) {
        const exemption = await this.validateExemption(
          request.customer_exemption.certificate_id,
          request.to_address
        );
        if (exemption.is_valid) {
          return this.createExemptResponse(request);
        }
      }

      // Check nexus requirements
      const hasNexus = await this.checkNexusRequirement(
        request.from_address,
        request.to_address
      );

      if (!hasNexus) {
        return this.createZeroTaxResponse(request);
      }

      // Try cache first
      const cacheKey = this.generateCacheKey(request);
      const cachedResult = await this.getCachedTaxCalculation(cacheKey);
      
      if (cachedResult && this.isCacheValid(cachedResult)) {
        return cachedResult.result;
      }

      // Calculate tax using primary service
      let taxResult: TaxCalculationResponse;

      try {
        taxResult = await this.calculateTaxWithTaxJar(request);
      } catch (primaryError) {
        console.warn('TaxJar calculation failed, trying Avalara:', primaryError);
        try {
          taxResult = await this.calculateTaxWithAvalara(request);
        } catch (secondaryError) {
          console.error('Both tax services failed:', { primaryError, secondaryError });
          // Fallback to internal calculation
          taxResult = await this.calculateTaxInternal(request);
        }
      }

      // Cache the result
      await this.cacheTaxCalculation(cacheKey, taxResult);

      // Log tax calculation
      await this.logTaxCalculation(request, taxResult);

      return taxResult;

    } catch (error) {
      console.error('Error calculating tax:', error);
      throw new Error(`Tax calculation failed: ${error.message}`);
    }
  }

  /**
   * Calculate tax using TaxJar
   */
  private async calculateTaxWithTaxJar(request: TaxCalculationRequest): Promise<TaxCalculationResponse> {
    if (!this.taxJarApiKey) {
      throw new Error('TaxJar API key not configured');
    }

    const taxJarRequest = {
      from_country: request.from_address.country,
      from_zip: request.from_address.zip,
      from_state: request.from_address.state,
      from_city: request.from_address.city,
      from_street: request.from_address.street,
      to_country: request.to_address.country,
      to_zip: request.to_address.zip,
      to_state: request.to_address.state,
      to_city: request.to_address.city,
      to_street: request.to_address.street,
      amount: request.line_items.reduce((sum, item) => 
        sum + (item.quantity * item.unit_price - item.discount), 0
      ),
      shipping: request.shipping,
      line_items: request.line_items.map(item => ({
        id: item.id,
        quantity: item.quantity,
        unit_price: item.unit_price,
        discount: item.discount,
        product_tax_code: item.product_tax_code
      }))
    };

    const response = await fetch('https://api.taxjar.com/v2/taxes', {
      method: 'POST',
      headers: {
        'Authorization': `Token token="${this.taxJarApiKey}"`,
        'Content-Type': 'application/json'
      },
      body: JSON.stringify(taxJarRequest)
    });

    if (!response.ok) {
      throw new Error(`TaxJar API error: ${response.status}`);
    }

    const data = await response.json();
    
    return this.transformTaxJarResponse(data.tax, request);
  }

  /**
   * Calculate tax using Avalara
   */
  private async calculateTaxWithAvalara(request: TaxCalculationRequest): Promise<TaxCalculationResponse> {
    if (!this.avalaraConfig) {
      throw new Error('Avalara configuration not found');
    }

    // Call Avalara Edge Function for security
    const { data, error } = await supabase.functions.invoke('calculate-tax', {
      body: {
        provider: 'avalara',
        request: request
      }
    });

    if (error) throw error;
    return data;
  }

  /**
   * Internal tax calculation fallback
   */
  private async calculateTaxInternal(request: TaxCalculationRequest): Promise<TaxCalculationResponse> {
    // Get tax rates from database
    const { data: taxRates, error } = await supabase
      .from('tax_rates')
      .select('*')
      .eq('country', request.to_address.country)
      .eq('state', request.to_address.state || '')
      .eq('is_active', true)
      .order('priority', { ascending: false });

    if (error) throw error;

    if (!taxRates || taxRates.length === 0) {
      return this.createZeroTaxResponse(request);
    }

    const totalAmount = request.line_items.reduce((sum, item) => 
      sum + (item.quantity * item.unit_price - item.discount), 0
    ) + request.shipping;

    const combinedRate = taxRates.reduce((sum, rate) => sum + rate.rate, 0);
    const taxAmount = totalAmount * (combinedRate / 100);

    return {
      tax_amount: Math.round(taxAmount * 100) / 100,
      taxable_amount: totalAmount,
      has_nexus: true,
      tax_source: 'destination',
      jurisdictions: {
        state: {
          country: request.to_address.country,
          state: request.to_address.state,
          name: `${request.to_address.state} State Tax`,
          tax_rate: combinedRate,
          tax_amount: taxAmount,
          tax_type: 'sales'
        }
      },
      line_items: request.line_items.map(item => {
        const itemAmount = item.quantity * item.unit_price - item.discount;
        const itemTax = itemAmount * (combinedRate / 100);
        
        return {
          id: item.id,
          taxable_amount: itemAmount,
          tax_amount: Math.round(itemTax * 100) / 100,
          combined_tax_rate: combinedRate,
          tax_breakdown: [{
            country: request.to_address.country,
            state: request.to_address.state,
            name: `${request.to_address.state} State Tax`,
            tax_rate: combinedRate,
            tax_amount: itemTax,
            tax_type: 'sales'
          }]
        };
      }),
      freight_taxable: true,
      rate_cache_key: this.generateCacheKey(request)
    };
  }

  /**
   * Validate tax exemption certificate
   */
  async validateExemption(certificateId: string, address: Address): Promise<{
    is_valid: boolean;
    certificate?: TaxExemptionCertificate;
    reason?: string;
  }> {
    try {
      const { data: certificate, error } = await supabase
        .from('tax_exemption_certificates')
        .select('*')
        .eq('id', certificateId)
        .eq('status', 'active')
        .single();

      if (error || !certificate) {
        return { is_valid: false, reason: 'Certificate not found or inactive' };
      }

      // Check expiration
      if (certificate.valid_until && new Date(certificate.valid_until) < new Date()) {
        return { is_valid: false, reason: 'Certificate expired' };
      }

      // Check jurisdiction
      if (!certificate.exempt_states.includes(address.state || '')) {
        return { is_valid: false, reason: 'Certificate not valid in destination state' };
      }

      return { is_valid: true, certificate };

    } catch (error) {
      console.error('Error validating exemption:', error);
      return { is_valid: false, reason: 'Validation error' };
    }
  }

  /**
   * Check nexus requirement
   */
  private async checkNexusRequirement(fromAddress: Address, toAddress: Address): Promise<boolean> {
    try {
      const { data: nexus, error } = await supabase
        .from('tax_nexus')
        .select('*')
        .eq('country', toAddress.country)
        .eq('state', toAddress.state || '')
        .or('has_physical_nexus.eq.true,has_economic_nexus.eq.true');

      if (error) throw error;
      return nexus && nexus.length > 0;

    } catch (error) {
      console.error('Error checking nexus:', error);
      return false; // Err on the side of not collecting tax if unsure
    }
  }

  /**
   * Manage tax exemption certificates
   */
  async createExemptionCertificate(certificate: Omit<TaxExemptionCertificate, 'id' | 'status'>): Promise<TaxExemptionCertificate> {
    try {
      const { data, error } = await supabase
        .from('tax_exemption_certificates')
        .insert([{ ...certificate, status: 'pending' }])
        .select()
        .single();

      if (error) throw error;

      // Trigger verification process
      await this.verifyExemptionCertificate(data.id);

      return data;
    } catch (error) {
      console.error('Error creating exemption certificate:', error);
      throw new Error('Failed to create exemption certificate');
    }
  }

  /**
   * Verify exemption certificate
   */
  private async verifyExemptionCertificate(certificateId: string): Promise<void> {
    try {
      // Call verification Edge Function
      await supabase.functions.invoke('verify-tax-exemption', {
        body: { certificate_id: certificateId }
      });
    } catch (error) {
      console.error('Error verifying exemption certificate:', error);
    }
  }

  /**
   * Generate tax reports
   */
  async generateTaxReport(params: {
    jurisdiction: string;
    period_start: string;
    period_end: string;
  }): Promise<TaxReport> {
    try {
      const { data, error } = await supabase.rpc('generate_tax_report', {
        jurisdiction: params.jurisdiction,
        period_start: params.period_start,
        period_end: params.period_end
      });

      if (error) throw error;

      // Store the report
      const { data: report, error: reportError } = await supabase
        .from('tax_reports')
        .insert([{
          jurisdiction: params.jurisdiction,
          period_start: params.period_start,
          period_end: params.period_end,
          ...data,
          status: 'draft'
        }])
        .select()
        .single();

      if (reportError) throw reportError;
      return report;

    } catch (error) {
      console.error('Error generating tax report:', error);
      throw new Error('Failed to generate tax report');
    }
  }

  /**
   * Get tax reports
   */
  async getTaxReports(filters: {
    jurisdiction?: string;
    year?: number;
    status?: string;
  } = {}): Promise<TaxReport[]> {
    try {
      let query = supabase
        .from('tax_reports')
        .select('*')
        .order('period_start', { ascending: false });

      if (filters.jurisdiction) {
        query = query.eq('jurisdiction', filters.jurisdiction);
      }
      if (filters.year) {
        query = query.gte('period_start', `${filters.year}-01-01`)
               .lt('period_start', `${filters.year + 1}-01-01`);
      }
      if (filters.status) {
        query = query.eq('status', filters.status);
      }

      const { data, error } = await query;
      if (error) throw error;
      return data;

    } catch (error) {
      console.error('Error getting tax reports:', error);
      throw new Error('Failed to retrieve tax reports');
    }
  }

  /**
   * Update nexus settings
   */
  async updateNexusSettings(nexusData: Omit<TaxNexus, 'id'>): Promise<TaxNexus> {
    try {
      const { data, error } = await supabase
        .from('tax_nexus')
        .upsert([nexusData], {
          onConflict: 'country,state'
        })
        .select()
        .single();

      if (error) throw error;
      return data;

    } catch (error) {
      console.error('Error updating nexus settings:', error);
      throw new Error('Failed to update nexus settings');
    }
  }

  /**
   * Get nexus requirements
   */
  async getNexusRequirements(): Promise<TaxNexus[]> {
    try {
      const { data, error } = await supabase
        .from('tax_nexus')
        .select('*')
        .order('country', { ascending: true })
        .order('state', { ascending: true });

      if (error) throw error;
      return data;

    } catch (error) {
      console.error('Error getting nexus requirements:', error);
      throw new Error('Failed to retrieve nexus requirements');
    }
  }

  /**
   * Initialize API keys
   */
  private async initializeApiKeys(): Promise<void> {
    try {
      const { data: settings, error } = await supabase
        .from('system_settings')
        .select('key, value')
        .in('key', ['taxjar_api_key', 'avalara_account_id', 'avalara_license_key']);

      if (!error && settings) {
        const settingsMap = settings.reduce((acc, setting) => {
          acc[setting.key] = setting.value;
          return acc;
        }, {} as Record<string, string>);

        this.taxJarApiKey = settingsMap.taxjar_api_key || null;
        
        if (settingsMap.avalara_account_id && settingsMap.avalara_license_key) {
          this.avalaraConfig = {
            accountId: settingsMap.avalara_account_id,
            licenseKey: settingsMap.avalara_license_key
          };
        }
      }
    } catch (error) {
      console.error('Error initializing tax service API keys:', error);
    }
  }

  // Helper methods

  private validateAddresses(fromAddress: Address, toAddress: Address): void {
    if (!fromAddress.country || !toAddress.country) {
      throw new Error('Country is required for tax calculation');
    }
    
    if (toAddress.country === 'US' && !toAddress.state) {
      throw new Error('State is required for US tax calculation');
    }
  }

  private generateCacheKey(request: TaxCalculationRequest): string {
    const keyData = {
      to_country: request.to_address.country,
      to_state: request.to_address.state,
      to_zip: request.to_address.zip,
      amount: request.line_items.reduce((sum, item) => 
        sum + (item.quantity * item.unit_price - item.discount), 0
      ),
      shipping: request.shipping
    };
    
    return btoa(JSON.stringify(keyData));
  }

  private async getCachedTaxCalculation(cacheKey: string): Promise<any> {
    try {
      const { data, error } = await supabase
        .from('tax_calculation_cache')
        .select('*')
        .eq('cache_key', cacheKey)
        .single();

      return error ? null : data;
    } catch (error) {
      return null;
    }
  }

  private isCacheValid(cachedResult: any): boolean {
    const cacheAge = Date.now() - new Date(cachedResult.created_at).getTime();
    const maxAge = 24 * 60 * 60 * 1000; // 24 hours
    return cacheAge < maxAge;
  }

  private async cacheTaxCalculation(cacheKey: string, result: TaxCalculationResponse): Promise<void> {
    try {
      await supabase
        .from('tax_calculation_cache')
        .upsert([{
          cache_key: cacheKey,
          result: result,
          created_at: new Date().toISOString()
        }], { onConflict: 'cache_key' });
    } catch (error) {
      console.error('Error caching tax calculation:', error);
    }
  }

  private async logTaxCalculation(request: TaxCalculationRequest, result: TaxCalculationResponse): Promise<void> {
    try {
      await supabase
        .from('tax_calculation_logs')
        .insert([{
          request_data: request,
          response_data: result,
          calculated_at: new Date().toISOString()
        }]);
    } catch (error) {
      console.error('Error logging tax calculation:', error);
    }
  }

  private transformTaxJarResponse(taxjarData: any, request: TaxCalculationRequest): TaxCalculationResponse {
    return {
      tax_amount: taxjarData.amount_to_collect,
      taxable_amount: taxjarData.taxable_amount,
      has_nexus: taxjarData.has_nexus,
      tax_source: taxjarData.tax_source,
      jurisdictions: {
        state: taxjarData.breakdown?.state_taxable_amount ? {
          country: request.to_address.country,
          state: request.to_address.state,
          name: `${request.to_address.state} State Tax`,
          tax_rate: taxjarData.breakdown.state_tax_rate * 100,
          tax_amount: taxjarData.breakdown.state_tax_collectable,
          tax_type: 'sales'
        } : undefined,
        county: taxjarData.breakdown?.county_taxable_amount ? {
          country: request.to_address.country,
          state: request.to_address.state,
          county: taxjarData.breakdown.county,
          name: `${taxjarData.breakdown.county} County Tax`,
          tax_rate: taxjarData.breakdown.county_tax_rate * 100,
          tax_amount: taxjarData.breakdown.county_tax_collectable,
          tax_type: 'sales'
        } : undefined,
        city: taxjarData.breakdown?.city_taxable_amount ? {
          country: request.to_address.country,
          state: request.to_address.state,
          city: taxjarData.breakdown.city,
          name: `${taxjarData.breakdown.city} City Tax`,
          tax_rate: taxjarData.breakdown.city_tax_rate * 100,
          tax_amount: taxjarData.breakdown.city_tax_collectable,
          tax_type: 'sales'
        } : undefined
      },
      line_items: request.line_items.map(item => ({
        id: item.id,
        taxable_amount: item.quantity * item.unit_price - item.discount,
        tax_amount: (item.quantity * item.unit_price - item.discount) * taxjarData.rate,
        combined_tax_rate: taxjarData.rate * 100,
        tax_breakdown: []
      })),
      freight_taxable: taxjarData.freight_taxable,
      rate_cache_key: this.generateCacheKey(request)
    };
  }

  private createExemptResponse(request: TaxCalculationRequest): TaxCalculationResponse {
    return {
      tax_amount: 0,
      taxable_amount: 0,
      has_nexus: true,
      tax_source: 'destination',
      jurisdictions: {},
      line_items: request.line_items.map(item => ({
        id: item.id,
        taxable_amount: 0,
        tax_amount: 0,
        combined_tax_rate: 0,
        tax_breakdown: []
      })),
      freight_taxable: false,
      rate_cache_key: this.generateCacheKey(request)
    };
  }

  private createZeroTaxResponse(request: TaxCalculationRequest): TaxCalculationResponse {
    return {
      tax_amount: 0,
      taxable_amount: request.line_items.reduce((sum, item) => 
        sum + (item.quantity * item.unit_price - item.discount), 0
      ) + request.shipping,
      has_nexus: false,
      tax_source: 'destination',
      jurisdictions: {},
      line_items: request.line_items.map(item => ({
        id: item.id,
        taxable_amount: item.quantity * item.unit_price - item.discount,
        tax_amount: 0,
        combined_tax_rate: 0,
        tax_breakdown: []
      })),
      freight_taxable: false,
      rate_cache_key: this.generateCacheKey(request)
    };
  }
}

// Export singleton instance
export const taxService = new TaxService();
export default taxService;