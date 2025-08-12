/**
 * SHIPPING INTEGRATION SERVICE
 * Comprehensive shipping and carrier integration for KCT Menswear
 * Supports multiple carriers with extensible API integration
 */

import { supabase } from '@/lib/supabase-client';

// ============================================
// TYPES AND INTERFACES
// ============================================

export interface ShippingAddress {
  name: string;
  company?: string;
  line1: string;
  line2?: string;
  city: string;
  state: string;
  postal_code: string;
  country: string;
  phone?: string;
  email?: string;
}

export interface PackageDimensions {
  length: number; // inches
  width: number;  // inches
  height: number; // inches
  weight: number; // pounds
}

export interface ShippingRate {
  carrier: string;
  service: string;
  rate: number;
  estimated_days: number;
  currency: string;
}

export interface ShippingLabel {
  id: string;
  tracking_number: string;
  label_url: string;
  carrier: string;
  service_type: string;
  cost: number;
  tracking_url: string;
  estimated_delivery_date: string;
}

export interface TrackingUpdate {
  status: string;
  description: string;
  location?: string;
  timestamp: string;
}

export interface TrackingInfo {
  tracking_number: string;
  carrier: string;
  status: string;
  estimated_delivery: string;
  updates: TrackingUpdate[];
}

export type Carrier = 'usps' | 'ups' | 'fedex' | 'dhl';
export type ServiceType = 'standard' | 'express' | 'overnight' | 'priority';

// ============================================
// CARRIER CONFIGURATIONS
// ============================================

export const CARRIER_CONFIGS = {
  usps: {
    name: 'USPS',
    services: {
      standard: 'Ground Advantage',
      express: 'Priority Mail Express',
      priority: 'Priority Mail',
      overnight: 'Priority Mail Express'
    },
    tracking_url: 'https://tools.usps.com/go/TrackConfirmAction?tLabels=',
    max_weight: 70, // pounds
    max_dimensions: { length: 108, width: 108, height: 108 }
  },
  ups: {
    name: 'UPS',
    services: {
      standard: 'UPS Ground',
      express: 'UPS 2nd Day Air',
      overnight: 'UPS Next Day Air',
      priority: 'UPS 3 Day Select'
    },
    tracking_url: 'https://www.ups.com/track?loc=en_US&tracknum=',
    max_weight: 150,
    max_dimensions: { length: 108, width: 165, height: 108 }
  },
  fedex: {
    name: 'FedEx',
    services: {
      standard: 'FedEx Ground',
      express: 'FedEx 2Day',
      overnight: 'FedEx Standard Overnight',
      priority: 'FedEx Express Saver'
    },
    tracking_url: 'https://www.fedex.com/fedextrack/?trknbr=',
    max_weight: 150,
    max_dimensions: { length: 119, width: 165, height: 119 }
  },
  dhl: {
    name: 'DHL',
    services: {
      standard: 'DHL Ground',
      express: 'DHL Express',
      overnight: 'DHL Express 9:00',
      priority: 'DHL Express 12:00'
    },
    tracking_url: 'https://www.dhl.com/us-en/home/tracking/tracking-express.html?submit=1&tracking-id=',
    max_weight: 150,
    max_dimensions: { length: 120, width: 120, height: 120 }
  }
};

// ============================================
// SHIPPING RATE CALCULATION
// ============================================

/**
 * Calculate shipping rates for all available carriers and services
 */
export async function calculateShippingRates(
  fromAddress: ShippingAddress,
  toAddress: ShippingAddress,
  packages: PackageDimensions[],
  options: {
    includeInsurance?: boolean;
    signatureRequired?: boolean;
    saturdayDelivery?: boolean;
  } = {}
): Promise<ShippingRate[]> {
  try {
    const rates: ShippingRate[] = [];

    // Calculate rates for each carrier
    for (const carrier of Object.keys(CARRIER_CONFIGS) as Carrier[]) {
      const carrierRates = await calculateCarrierRates(
        carrier,
        fromAddress,
        toAddress,
        packages,
        options
      );
      rates.push(...carrierRates);
    }

    // Sort by price
    return rates.sort((a, b) => a.rate - b.rate);
  } catch (error) {
    console.error('Error calculating shipping rates:', error);
    throw error;
  }
}

/**
 * Calculate rates for a specific carrier
 */
async function calculateCarrierRates(
  carrier: Carrier,
  fromAddress: ShippingAddress,
  toAddress: ShippingAddress,
  packages: PackageDimensions[],
  options: any
): Promise<ShippingRate[]> {
  const config = CARRIER_CONFIGS[carrier];
  const rates: ShippingRate[] = [];

  // Calculate total weight and dimensions
  const totalWeight = packages.reduce((sum, pkg) => sum + pkg.weight, 0);
  const maxLength = Math.max(...packages.map(pkg => pkg.length));
  const maxWidth = Math.max(...packages.map(pkg => pkg.width));
  const maxHeight = Math.max(...packages.map(pkg => pkg.height));

  // Check if package is within carrier limits
  if (totalWeight > config.max_weight) {
    return rates; // Skip this carrier
  }

  // Calculate distance zone (simplified)
  const zone = calculateShippingZone(fromAddress, toAddress);

  // Calculate rates for each service
  for (const [serviceKey, serviceName] of Object.entries(config.services)) {
    const baseRate = getBaseRate(carrier, serviceKey as ServiceType, totalWeight, zone);
    let rate = baseRate;

    // Add surcharges
    if (options.includeInsurance) {
      rate += calculateInsuranceCost(packages.reduce((sum, pkg) => sum + (pkg.weight * 50), 0)); // Assuming $50/lb value
    }

    if (options.signatureRequired) {
      rate += 5.50; // Signature confirmation fee
    }

    if (options.saturdayDelivery && ['express', 'overnight'].includes(serviceKey)) {
      rate += 15.00; // Saturday delivery fee
    }

    // Add dimensional weight surcharge if applicable
    const dimWeight = calculateDimensionalWeight(maxLength, maxWidth, maxHeight);
    if (dimWeight > totalWeight) {
      rate += (dimWeight - totalWeight) * 0.50; // $0.50 per lb dimensional weight charge
    }

    rates.push({
      carrier: config.name,
      service: serviceName,
      rate: Math.round(rate * 100) / 100, // Round to 2 decimal places
      estimated_days: getEstimatedDeliveryDays(serviceKey as ServiceType, zone),
      currency: 'USD'
    });
  }

  return rates;
}

/**
 * Calculate shipping zone based on addresses (simplified)
 */
function calculateShippingZone(fromAddress: ShippingAddress, toAddress: ShippingAddress): number {
  // This is a simplified zone calculation
  // In production, you'd use actual distance calculation or carrier APIs
  
  if (fromAddress.state === toAddress.state) {
    return 1; // Same state
  }
  
  const fromRegion = getRegion(fromAddress.state);
  const toRegion = getRegion(toAddress.state);
  
  if (fromRegion === toRegion) {
    return 2; // Same region
  }
  
  // Calculate approximate distance (very simplified)
  const stateDistances: Record<string, number> = {
    'CA': 1, 'NV': 2, 'OR': 2, 'WA': 3, 'AZ': 3, 'UT': 4, 'ID': 4, 'MT': 5,
    'WY': 5, 'CO': 5, 'NM': 4, 'TX': 6, 'OK': 6, 'KS': 6, 'NE': 7, 'SD': 7,
    'ND': 8, 'MN': 8, 'IA': 7, 'MO': 6, 'AR': 6, 'LA': 7, 'MS': 7, 'AL': 8,
    'TN': 7, 'KY': 7, 'IN': 7, 'IL': 7, 'WI': 8, 'MI': 8, 'OH': 8, 'WV': 8,
    'VA': 8, 'NC': 8, 'SC': 8, 'GA': 8, 'FL': 8, 'NY': 8, 'PA': 8, 'NJ': 8,
    'CT': 8, 'RI': 8, 'MA': 8, 'VT': 8, 'NH': 8, 'ME': 8
  };
  
  const fromDistance = stateDistances[fromAddress.state] || 5;
  const toDistance = stateDistances[toAddress.state] || 5;
  
  return Math.min(8, Math.abs(fromDistance - toDistance) + 2);
}

function getRegion(state: string): string {
  const regions: Record<string, string> = {
    'CA': 'west', 'NV': 'west', 'OR': 'west', 'WA': 'west', 'AZ': 'west', 'UT': 'west',
    'TX': 'south', 'OK': 'south', 'AR': 'south', 'LA': 'south', 'MS': 'south', 'AL': 'south',
    'TN': 'south', 'KY': 'south', 'WV': 'south', 'VA': 'south', 'NC': 'south', 'SC': 'south',
    'GA': 'south', 'FL': 'south', 'NY': 'northeast', 'PA': 'northeast', 'NJ': 'northeast',
    'CT': 'northeast', 'RI': 'northeast', 'MA': 'northeast', 'VT': 'northeast', 'NH': 'northeast',
    'ME': 'northeast', 'IL': 'midwest', 'IN': 'midwest', 'MI': 'midwest', 'OH': 'midwest',
    'WI': 'midwest', 'MN': 'midwest', 'IA': 'midwest', 'MO': 'midwest', 'ND': 'midwest',
    'SD': 'midwest', 'NE': 'midwest', 'KS': 'midwest'
  };
  
  return regions[state] || 'other';
}

/**
 * Get base shipping rate
 */
function getBaseRate(carrier: Carrier, service: ServiceType, weight: number, zone: number): number {
  // Base rates by carrier and service (simplified)
  const rates: Record<Carrier, Record<ServiceType, number[]>> = {
    usps: {
      standard: [5.20, 6.50, 8.00, 9.50, 11.00, 12.50, 14.00, 15.50],
      express: [26.35, 28.00, 30.00, 32.00, 34.00, 36.00, 38.00, 40.00],
      priority: [9.35, 11.00, 13.00, 15.00, 17.00, 19.00, 21.00, 23.00],
      overnight: [26.35, 28.00, 30.00, 32.00, 34.00, 36.00, 38.00, 40.00]
    },
    ups: {
      standard: [8.50, 10.00, 12.00, 14.00, 16.00, 18.00, 20.00, 22.00],
      express: [32.00, 35.00, 38.00, 41.00, 44.00, 47.00, 50.00, 53.00],
      priority: [25.00, 28.00, 31.00, 34.00, 37.00, 40.00, 43.00, 46.00],
      overnight: [75.00, 80.00, 85.00, 90.00, 95.00, 100.00, 105.00, 110.00]
    },
    fedex: {
      standard: [9.00, 11.00, 13.00, 15.00, 17.00, 19.00, 21.00, 23.00],
      express: [35.00, 38.00, 41.00, 44.00, 47.00, 50.00, 53.00, 56.00],
      priority: [28.00, 31.00, 34.00, 37.00, 40.00, 43.00, 46.00, 49.00],
      overnight: [80.00, 85.00, 90.00, 95.00, 100.00, 105.00, 110.00, 115.00]
    },
    dhl: {
      standard: [10.00, 12.00, 14.00, 16.00, 18.00, 20.00, 22.00, 24.00],
      express: [40.00, 43.00, 46.00, 49.00, 52.00, 55.00, 58.00, 61.00],
      priority: [32.00, 35.00, 38.00, 41.00, 44.00, 47.00, 50.00, 53.00],
      overnight: [90.00, 95.00, 100.00, 105.00, 110.00, 115.00, 120.00, 125.00]
    }
  };

  const baseRate = rates[carrier][service][Math.min(zone - 1, 7)] || rates[carrier][service][7];
  
  // Add weight surcharge for packages over 1 lb
  const weightSurcharge = Math.max(0, weight - 1) * 0.85;
  
  return baseRate + weightSurcharge;
}

/**
 * Calculate dimensional weight
 */
function calculateDimensionalWeight(length: number, width: number, height: number): number {
  // Standard dimensional weight divisor is 139 for most carriers
  return (length * width * height) / 139;
}

/**
 * Calculate insurance cost
 */
function calculateInsuranceCost(value: number): number {
  if (value <= 50) return 0;
  if (value <= 100) return 2.25;
  if (value <= 200) return 3.40;
  if (value <= 300) return 4.60;
  
  // $1.30 per additional $100 or fraction thereof
  return 4.60 + Math.ceil((value - 300) / 100) * 1.30;
}

/**
 * Get estimated delivery days
 */
function getEstimatedDeliveryDays(service: ServiceType, zone: number): number {
  const estimatedDays: Record<ServiceType, number[]> = {
    overnight: [1, 1, 1, 1, 1, 1, 1, 1],
    express: [2, 2, 2, 2, 3, 3, 3, 3],
    priority: [2, 3, 3, 4, 4, 5, 5, 6],
    standard: [3, 4, 5, 6, 7, 8, 9, 10]
  };

  return estimatedDays[service][Math.min(zone - 1, 7)] || estimatedDays[service][7];
}

// ============================================
// SHIPPING LABEL GENERATION
// ============================================

/**
 * Generate shipping label with carrier API integration
 */
export async function generateShippingLabel(params: {
  orderId: string;
  carrier: Carrier;
  service: string;
  fromAddress: ShippingAddress;
  toAddress: ShippingAddress;
  packages: PackageDimensions[];
  options?: {
    insurance?: number;
    signature_required?: boolean;
    saturday_delivery?: boolean;
    reference?: string;
  };
}): Promise<ShippingLabel> {
  const { orderId, carrier, service, fromAddress, toAddress, packages, options = {} } = params;

  try {
    // In production, this would integrate with actual carrier APIs
    // For now, we'll simulate the label generation
    const mockLabel = await generateMockLabel({
      orderId,
      carrier,
      service,
      fromAddress,
      toAddress,
      packages,
      options
    });

    // Store label in database
    const { data: label, error } = await supabase
      .from('shipping_labels')
      .insert({
        order_id: orderId,
        tracking_number: mockLabel.tracking_number,
        label_url: mockLabel.label_url,
        carrier: carrier,
        service_type: service,
        weight_lbs: packages.reduce((sum, pkg) => sum + pkg.weight, 0),
        length_inches: Math.max(...packages.map(pkg => pkg.length)),
        width_inches: Math.max(...packages.map(pkg => pkg.width)),
        height_inches: Math.max(...packages.map(pkg => pkg.height)),
        shipping_cost: mockLabel.cost,
        insurance_cost: options.insurance ? calculateInsuranceCost(options.insurance) : 0,
        from_address: fromAddress,
        to_address: toAddress,
        status: 'generated'
      })
      .select()
      .single();

    if (error) throw error;

    return {
      id: label.id,
      tracking_number: mockLabel.tracking_number,
      label_url: mockLabel.label_url,
      carrier: CARRIER_CONFIGS[carrier].name,
      service_type: service,
      cost: mockLabel.cost,
      tracking_url: mockLabel.tracking_url,
      estimated_delivery_date: mockLabel.estimated_delivery_date
    };
  } catch (error) {
    console.error('Error generating shipping label:', error);
    throw error;
  }
}

/**
 * Mock label generation (replace with actual carrier API calls)
 */
async function generateMockLabel(params: any): Promise<{
  tracking_number: string;
  label_url: string;
  cost: number;
  tracking_url: string;
  estimated_delivery_date: string;
}> {
  const { carrier, service, packages, options } = params;
  const config = CARRIER_CONFIGS[carrier];

  // Generate mock tracking number
  const tracking_number = generateTrackingNumber(carrier);
  
  // Calculate cost
  const totalWeight = packages.reduce((sum: number, pkg: PackageDimensions) => sum + pkg.weight, 0);
  const zone = 3; // Mock zone
  const serviceType = Object.keys(config.services).find(key => 
    config.services[key as keyof typeof config.services] === service
  ) as ServiceType || 'standard';
  
  let cost = getBaseRate(carrier, serviceType, totalWeight, zone);
  
  if (options.insurance) {
    cost += calculateInsuranceCost(options.insurance);
  }
  
  if (options.signature_required) {
    cost += 5.50;
  }
  
  if (options.saturday_delivery) {
    cost += 15.00;
  }

  // Calculate estimated delivery
  const deliveryDays = getEstimatedDeliveryDays(serviceType, zone);
  const estimatedDelivery = new Date();
  estimatedDelivery.setDate(estimatedDelivery.getDate() + deliveryDays);

  return {
    tracking_number,
    label_url: `https://api.example.com/labels/${tracking_number}.pdf`,
    cost: Math.round(cost * 100) / 100,
    tracking_url: config.tracking_url + tracking_number,
    estimated_delivery_date: estimatedDelivery.toISOString().split('T')[0]
  };
}

/**
 * Generate tracking number based on carrier
 */
function generateTrackingNumber(carrier: Carrier): string {
  const prefixes: Record<Carrier, string> = {
    usps: '9400',
    ups: '1Z',
    fedex: '7712',
    dhl: '5678'
  };

  const prefix = prefixes[carrier];
  const randomDigits = Math.random().toString().slice(2, 12);
  
  switch (carrier) {
    case 'usps':
      return `${prefix}1110${randomDigits}`;
    case 'ups':
      return `${prefix}${randomDigits}`;
    case 'fedex':
      return `${prefix}${randomDigits}`;
    case 'dhl':
      return `${prefix}${randomDigits}`;
    default:
      return `${prefix}${randomDigits}`;
  }
}

// ============================================
// TRACKING MANAGEMENT
// ============================================

/**
 * Track shipment using carrier API
 */
export async function trackShipment(
  trackingNumber: string,
  carrier: Carrier
): Promise<TrackingInfo> {
  try {
    // In production, this would call actual carrier tracking APIs
    const mockTracking = generateMockTracking(trackingNumber, carrier);
    
    // Update database with latest tracking info
    await updateTrackingInDatabase(trackingNumber, mockTracking);
    
    return mockTracking;
  } catch (error) {
    console.error('Error tracking shipment:', error);
    throw error;
  }
}

/**
 * Generate mock tracking data (replace with actual API calls)
 */
function generateMockTracking(trackingNumber: string, carrier: Carrier): TrackingInfo {
  const config = CARRIER_CONFIGS[carrier];
  
  const statuses = ['Label Created', 'Picked Up', 'In Transit', 'Out for Delivery', 'Delivered'];
  const currentStatusIndex = Math.floor(Math.random() * statuses.length);
  
  const updates: TrackingUpdate[] = [];
  
  for (let i = 0; i <= currentStatusIndex; i++) {
    const timestamp = new Date();
    timestamp.setDate(timestamp.getDate() - (currentStatusIndex - i));
    
    updates.push({
      status: statuses[i],
      description: getTrackingDescription(statuses[i]),
      location: i > 0 ? getRandomLocation() : undefined,
      timestamp: timestamp.toISOString()
    });
  }

  const estimatedDelivery = new Date();
  estimatedDelivery.setDate(estimatedDelivery.getDate() + (4 - currentStatusIndex));

  return {
    tracking_number: trackingNumber,
    carrier: config.name,
    status: statuses[currentStatusIndex],
    estimated_delivery: estimatedDelivery.toISOString().split('T')[0],
    updates: updates.reverse() // Most recent first
  };
}

function getTrackingDescription(status: string): string {
  const descriptions: Record<string, string> = {
    'Label Created': 'Shipping label has been created',
    'Picked Up': 'Package has been picked up by carrier',
    'In Transit': 'Package is on its way to destination',
    'Out for Delivery': 'Package is out for delivery',
    'Delivered': 'Package has been delivered'
  };
  
  return descriptions[status] || status;
}

function getRandomLocation(): string {
  const locations = [
    'Los Angeles, CA', 'Phoenix, AZ', 'Denver, CO', 'Dallas, TX', 'Chicago, IL',
    'Atlanta, GA', 'New York, NY', 'Philadelphia, PA', 'Miami, FL', 'Seattle, WA'
  ];
  
  return locations[Math.floor(Math.random() * locations.length)];
}

/**
 * Update tracking information in database
 */
async function updateTrackingInDatabase(trackingNumber: string, trackingInfo: TrackingInfo) {
  try {
    // Update shipping label status
    await supabase
      .from('shipping_labels')
      .update({
        status: trackingInfo.status.toLowerCase().replace(/\s+/g, '_'),
        updated_at: new Date().toISOString()
      })
      .eq('tracking_number', trackingNumber);

    // Update order status if delivered
    if (trackingInfo.status === 'Delivered') {
      const { data: label } = await supabase
        .from('shipping_labels')
        .select('order_id')
        .eq('tracking_number', trackingNumber)
        .single();

      if (label) {
        await supabase
          .from('orders')
          .update({
            status: 'delivered',
            delivered_at: new Date().toISOString(),
            updated_at: new Date().toISOString()
          })
          .eq('id', label.order_id);
      }
    }
  } catch (error) {
    console.error('Error updating tracking in database:', error);
  }
}

// ============================================
// UTILITY FUNCTIONS
// ============================================

/**
 * Validate shipping address
 */
export function validateShippingAddress(address: Partial<ShippingAddress>): string[] {
  const errors: string[] = [];

  if (!address.name?.trim()) errors.push('Name is required');
  if (!address.line1?.trim()) errors.push('Address line 1 is required');
  if (!address.city?.trim()) errors.push('City is required');
  if (!address.state?.trim()) errors.push('State is required');
  if (!address.postal_code?.trim()) errors.push('Postal code is required');
  if (!address.country?.trim()) errors.push('Country is required');

  // Validate postal code format (basic)
  if (address.country === 'US' && address.postal_code) {
    const zipRegex = /^\d{5}(-\d{4})?$/;
    if (!zipRegex.test(address.postal_code)) {
      errors.push('Invalid US postal code format');
    }
  }

  return errors;
}

/**
 * Validate package dimensions
 */
export function validatePackageDimensions(packages: PackageDimensions[], carrier: Carrier): string[] {
  const errors: string[] = [];
  const config = CARRIER_CONFIGS[carrier];

  packages.forEach((pkg, index) => {
    if (pkg.weight <= 0) errors.push(`Package ${index + 1}: Weight must be greater than 0`);
    if (pkg.weight > config.max_weight) errors.push(`Package ${index + 1}: Weight exceeds ${carrier.toUpperCase()} limit of ${config.max_weight} lbs`);
    
    if (pkg.length <= 0 || pkg.width <= 0 || pkg.height <= 0) {
      errors.push(`Package ${index + 1}: All dimensions must be greater than 0`);
    }
    
    if (pkg.length > config.max_dimensions.length || 
        pkg.width > config.max_dimensions.width || 
        pkg.height > config.max_dimensions.height) {
      errors.push(`Package ${index + 1}: Dimensions exceed ${carrier.toUpperCase()} limits`);
    }
  });

  return errors;
}

/**
 * Get company shipping address
 */
export function getCompanyShippingAddress(): ShippingAddress {
  return {
    name: 'KCT Menswear',
    company: 'KCT Menswear LLC',
    line1: '123 Business Street',
    line2: 'Suite 100',
    city: 'Los Angeles',
    state: 'CA',
    postal_code: '90210',
    country: 'US',
    phone: '555-123-4567',
    email: 'shipping@kctmenswear.com'
  };
}

/**
 * Format tracking URL for display
 */
export function getTrackingUrl(carrier: string, trackingNumber: string): string {
  const carrierKey = carrier.toLowerCase() as Carrier;
  const config = CARRIER_CONFIGS[carrierKey];
  
  if (config) {
    return config.tracking_url + trackingNumber;
  }
  
  return `https://google.com/search?q=${encodeURIComponent(`${carrier} tracking ${trackingNumber}`)}`;
}