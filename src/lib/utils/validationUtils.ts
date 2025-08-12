/**
 * VALIDATION UTILITIES
 * Comprehensive validation functions for order processing workflow
 * Production-ready validation with detailed error reporting
 */

// ============================================
// TYPES AND INTERFACES
// ============================================

export interface ValidationResult {
  isValid: boolean;
  errors: ValidationError[];
  warnings: ValidationWarning[];
}

export interface ValidationError {
  field: string;
  message: string;
  code: string;
  severity: 'error' | 'warning';
}

export interface ValidationWarning {
  field: string;
  message: string;
  code: string;
}

export interface OrderValidationContext {
  orderId?: string;
  customerId?: string;
  items: OrderItemValidation[];
  shippingAddress: AddressValidation;
  billingAddress?: AddressValidation;
  paymentMethod?: string;
  totalAmount: number;
}

export interface OrderItemValidation {
  productId: string;
  variantId?: string;
  quantity: number;
  price: number;
  availableStock?: number;
}

export interface AddressValidation {
  name: string;
  line1: string;
  line2?: string;
  city: string;
  state: string;
  postalCode: string;
  country: string;
  phone?: string;
  email?: string;
}

// ============================================
// VALIDATION CONSTANTS
// ============================================

const US_STATES = [
  'AL', 'AK', 'AZ', 'AR', 'CA', 'CO', 'CT', 'DE', 'FL', 'GA',
  'HI', 'ID', 'IL', 'IN', 'IA', 'KS', 'KY', 'LA', 'ME', 'MD',
  'MA', 'MI', 'MN', 'MS', 'MO', 'MT', 'NE', 'NV', 'NH', 'NJ',
  'NM', 'NY', 'NC', 'ND', 'OH', 'OK', 'OR', 'PA', 'RI', 'SC',
  'SD', 'TN', 'TX', 'UT', 'VT', 'VA', 'WA', 'WV', 'WI', 'WY'
];

const VALIDATION_PATTERNS = {
  email: /^[^\s@]+@[^\s@]+\.[^\s@]+$/,
  phone: /^[\+]?[1-9][\d]{0,15}$/,
  zipCode: /^\d{5}(-\d{4})?$/,
  canadianPostal: /^[A-Za-z]\d[A-Za-z][ -]?\d[A-Za-z]\d$/,
  ukPostal: /^[A-Z]{1,2}\d[A-Z\d]? ?\d[A-Z]{2}$/i
};

// ============================================
// ORDER VALIDATION
// ============================================

/**
 * Validate complete order data
 */
export function validateOrder(order: OrderValidationContext): ValidationResult {
  const errors: ValidationError[] = [];
  const warnings: ValidationWarning[] = [];

  // Validate required fields
  if (!order.items || order.items.length === 0) {
    errors.push({
      field: 'items',
      message: 'Order must contain at least one item',
      code: 'ORDER_EMPTY',
      severity: 'error'
    });
  }

  if (!order.totalAmount || order.totalAmount <= 0) {
    errors.push({
      field: 'totalAmount',
      message: 'Order total must be greater than zero',
      code: 'INVALID_TOTAL',
      severity: 'error'
    });
  }

  // Validate shipping address
  const shippingValidation = validateAddress(order.shippingAddress, 'shipping');
  errors.push(...shippingValidation.errors);
  warnings.push(...shippingValidation.warnings);

  // Validate billing address if provided
  if (order.billingAddress) {
    const billingValidation = validateAddress(order.billingAddress, 'billing');
    errors.push(...billingValidation.errors);
    warnings.push(...billingValidation.warnings);
  }

  // Validate order items
  const itemsValidation = validateOrderItems(order.items);
  errors.push(...itemsValidation.errors);
  warnings.push(...itemsValidation.warnings);

  // Business rule validations
  const businessValidation = validateBusinessRules(order);
  errors.push(...businessValidation.errors);
  warnings.push(...businessValidation.warnings);

  return {
    isValid: errors.length === 0,
    errors,
    warnings
  };
}

/**
 * Validate order items
 */
export function validateOrderItems(items: OrderItemValidation[]): ValidationResult {
  const errors: ValidationError[] = [];
  const warnings: ValidationWarning[] = [];

  items.forEach((item, index) => {
    const fieldPrefix = `items[${index}]`;

    // Required fields
    if (!item.productId) {
      errors.push({
        field: `${fieldPrefix}.productId`,
        message: 'Product ID is required',
        code: 'PRODUCT_ID_REQUIRED',
        severity: 'error'
      });
    }

    if (!item.quantity || item.quantity <= 0) {
      errors.push({
        field: `${fieldPrefix}.quantity`,
        message: 'Quantity must be greater than zero',
        code: 'INVALID_QUANTITY',
        severity: 'error'
      });
    }

    if (!item.price || item.price < 0) {
      errors.push({
        field: `${fieldPrefix}.price`,
        message: 'Price must be greater than or equal to zero',
        code: 'INVALID_PRICE',
        severity: 'error'
      });
    }

    // Stock validation
    if (item.availableStock !== undefined && item.quantity > item.availableStock) {
      errors.push({
        field: `${fieldPrefix}.quantity`,
        message: `Requested quantity (${item.quantity}) exceeds available stock (${item.availableStock})`,
        code: 'INSUFFICIENT_STOCK',
        severity: 'error'
      });
    }

    // Quantity warnings
    if (item.quantity > 10) {
      warnings.push({
        field: `${fieldPrefix}.quantity`,
        message: 'Large quantity order - consider bulk pricing',
        code: 'LARGE_QUANTITY'
      });
    }

    // Price validation
    if (item.price === 0) {
      warnings.push({
        field: `${fieldPrefix}.price`,
        message: 'Item has zero price - verify this is intentional',
        code: 'ZERO_PRICE'
      });
    }
  });

  return { isValid: errors.length === 0, errors, warnings };
}

/**
 * Validate shipping address
 */
export function validateAddress(address: AddressValidation, type: string = 'address'): ValidationResult {
  const errors: ValidationError[] = [];
  const warnings: ValidationWarning[] = [];

  // Required fields
  if (!address.name?.trim()) {
    errors.push({
      field: `${type}.name`,
      message: 'Name is required',
      code: 'NAME_REQUIRED',
      severity: 'error'
    });
  }

  if (!address.line1?.trim()) {
    errors.push({
      field: `${type}.line1`,
      message: 'Address line 1 is required',
      code: 'ADDRESS_LINE1_REQUIRED',
      severity: 'error'
    });
  }

  if (!address.city?.trim()) {
    errors.push({
      field: `${type}.city`,
      message: 'City is required',
      code: 'CITY_REQUIRED',
      severity: 'error'
    });
  }

  if (!address.state?.trim()) {
    errors.push({
      field: `${type}.state`,
      message: 'State is required',
      code: 'STATE_REQUIRED',
      severity: 'error'
    });
  }

  if (!address.postalCode?.trim()) {
    errors.push({
      field: `${type}.postalCode`,
      message: 'Postal code is required',
      code: 'POSTAL_CODE_REQUIRED',
      severity: 'error'
    });
  }

  if (!address.country?.trim()) {
    errors.push({
      field: `${type}.country`,
      message: 'Country is required',
      code: 'COUNTRY_REQUIRED',
      severity: 'error'
    });
  }

  // Format validations
  if (address.country === 'US') {
    if (address.state && !US_STATES.includes(address.state.toUpperCase())) {
      errors.push({
        field: `${type}.state`,
        message: 'Invalid US state code',
        code: 'INVALID_STATE',
        severity: 'error'
      });
    }

    if (address.postalCode && !VALIDATION_PATTERNS.zipCode.test(address.postalCode)) {
      errors.push({
        field: `${type}.postalCode`,
        message: 'Invalid US ZIP code format',
        code: 'INVALID_ZIP_CODE',
        severity: 'error'
      });
    }
  } else if (address.country === 'CA') {
    if (address.postalCode && !VALIDATION_PATTERNS.canadianPostal.test(address.postalCode)) {
      errors.push({
        field: `${type}.postalCode`,
        message: 'Invalid Canadian postal code format',
        code: 'INVALID_POSTAL_CODE',
        severity: 'error'
      });
    }
  }

  // Email validation
  if (address.email && !VALIDATION_PATTERNS.email.test(address.email)) {
    errors.push({
      field: `${type}.email`,
      message: 'Invalid email format',
      code: 'INVALID_EMAIL',
      severity: 'error'
    });
  }

  // Phone validation
  if (address.phone && !VALIDATION_PATTERNS.phone.test(address.phone.replace(/\D/g, ''))) {
    warnings.push({
      field: `${type}.phone`,
      message: 'Phone number format may be invalid',
      code: 'INVALID_PHONE_FORMAT'
    });
  }

  // Length validations
  if (address.name && address.name.length > 100) {
    errors.push({
      field: `${type}.name`,
      message: 'Name must be 100 characters or less',
      code: 'NAME_TOO_LONG',
      severity: 'error'
    });
  }

  if (address.line1 && address.line1.length > 100) {
    errors.push({
      field: `${type}.line1`,
      message: 'Address line 1 must be 100 characters or less',
      code: 'ADDRESS_TOO_LONG',
      severity: 'error'
    });
  }

  return { isValid: errors.length === 0, errors, warnings };
}

/**
 * Validate business rules
 */
export function validateBusinessRules(order: OrderValidationContext): ValidationResult {
  const errors: ValidationError[] = [];
  const warnings: ValidationWarning[] = [];

  // Calculate expected total
  const itemsTotal = order.items.reduce((sum, item) => sum + (item.price * item.quantity), 0);
  const tolerance = 0.01; // Allow 1 cent difference for rounding

  if (Math.abs(order.totalAmount - itemsTotal) > tolerance) {
    errors.push({
      field: 'totalAmount',
      message: `Order total (${order.totalAmount}) does not match items total (${itemsTotal})`,
      code: 'TOTAL_MISMATCH',
      severity: 'error'
    });
  }

  // High-value order warning
  if (order.totalAmount > 100000) { // $1000
    warnings.push({
      field: 'totalAmount',
      message: 'High-value order requires additional verification',
      code: 'HIGH_VALUE_ORDER'
    });
  }

  // International shipping warnings
  if (order.shippingAddress.country !== 'US') {
    warnings.push({
      field: 'shipping.country',
      message: 'International order - verify shipping restrictions and duties',
      code: 'INTERNATIONAL_SHIPPING'
    });
  }

  // PO Box detection
  const poBoxRegex = /\b(p\.?o\.?\s*(box|b)\s*\d+|post\s*office\s*box\s*\d+)\b/i;
  if (poBoxRegex.test(order.shippingAddress.line1)) {
    warnings.push({
      field: 'shipping.line1',
      message: 'PO Box address detected - some carriers may not deliver',
      code: 'PO_BOX_ADDRESS'
    });
  }

  return { isValid: errors.length === 0, errors, warnings };
}

// ============================================
// FULFILLMENT VALIDATION
// ============================================

/**
 * Validate fulfillment data
 */
export function validateFulfillment(fulfillment: {
  orderId: string;
  warehouseLocation?: string;
  assignedPicker?: string;
  assignedPacker?: string;
  items: Array<{ variantId: string; quantity: number; availableStock: number }>;
}): ValidationResult {
  const errors: ValidationError[] = [];
  const warnings: ValidationWarning[] = [];

  // Required fields
  if (!fulfillment.orderId) {
    errors.push({
      field: 'orderId',
      message: 'Order ID is required',
      code: 'ORDER_ID_REQUIRED',
      severity: 'error'
    });
  }

  // Validate items can be fulfilled
  fulfillment.items.forEach((item, index) => {
    if (item.quantity > item.availableStock) {
      errors.push({
        field: `items[${index}].quantity`,
        message: `Cannot fulfill ${item.quantity} units - only ${item.availableStock} available`,
        code: 'INSUFFICIENT_STOCK_FULFILLMENT',
        severity: 'error'
      });
    }

    if (item.availableStock < 5 && item.quantity === item.availableStock) {
      warnings.push({
        field: `items[${index}].stock`,
        message: 'Fulfillment will deplete stock - consider reordering',
        code: 'STOCK_DEPLETION'
      });
    }
  });

  // Validate staff assignments
  if (fulfillment.assignedPicker && fulfillment.assignedPicker.length < 2) {
    errors.push({
      field: 'assignedPicker',
      message: 'Invalid picker assignment',
      code: 'INVALID_PICKER',
      severity: 'error'
    });
  }

  return { isValid: errors.length === 0, errors, warnings };
}

// ============================================
// SHIPPING VALIDATION
// ============================================

/**
 * Validate shipping data
 */
export function validateShipping(shipping: {
  carrier: string;
  service: string;
  weight: number;
  dimensions: { length: number; width: number; height: number };
  fromAddress: AddressValidation;
  toAddress: AddressValidation;
}): ValidationResult {
  const errors: ValidationError[] = [];
  const warnings: ValidationWarning[] = [];

  // Required fields
  if (!shipping.carrier) {
    errors.push({
      field: 'carrier',
      message: 'Carrier is required',
      code: 'CARRIER_REQUIRED',
      severity: 'error'
    });
  }

  if (!shipping.service) {
    errors.push({
      field: 'service',
      message: 'Service type is required',
      code: 'SERVICE_REQUIRED',
      severity: 'error'
    });
  }

  // Weight validation
  if (!shipping.weight || shipping.weight <= 0) {
    errors.push({
      field: 'weight',
      message: 'Weight must be greater than zero',
      code: 'INVALID_WEIGHT',
      severity: 'error'
    });
  }

  if (shipping.weight > 150) {
    warnings.push({
      field: 'weight',
      message: 'Heavy package - may require special handling',
      code: 'HEAVY_PACKAGE'
    });
  }

  // Dimensions validation
  const { length, width, height } = shipping.dimensions;
  if (!length || !width || !height || length <= 0 || width <= 0 || height <= 0) {
    errors.push({
      field: 'dimensions',
      message: 'All dimensions must be greater than zero',
      code: 'INVALID_DIMENSIONS',
      severity: 'error'
    });
  }

  // Check maximum dimensions
  if (length > 108 || width > 108 || height > 108) {
    warnings.push({
      field: 'dimensions',
      message: 'Package may exceed carrier size limits',
      code: 'OVERSIZED_PACKAGE'
    });
  }

  // Address validation
  const fromValidation = validateAddress(shipping.fromAddress, 'fromAddress');
  const toValidation = validateAddress(shipping.toAddress, 'toAddress');
  
  errors.push(...fromValidation.errors, ...toValidation.errors);
  warnings.push(...fromValidation.warnings, ...toValidation.warnings);

  return { isValid: errors.length === 0, errors, warnings };
}

// ============================================
// REFUND VALIDATION
// ============================================

/**
 * Validate refund data
 */
export function validateRefund(refund: {
  orderId: string;
  refundType: string;
  refundAmount: number;
  originalAmount: number;
  reason: string;
  reasonCategory: string;
}): ValidationResult {
  const errors: ValidationError[] = [];
  const warnings: ValidationWarning[] = [];

  // Required fields
  if (!refund.orderId) {
    errors.push({
      field: 'orderId',
      message: 'Order ID is required',
      code: 'ORDER_ID_REQUIRED',
      severity: 'error'
    });
  }

  if (!refund.reason?.trim()) {
    errors.push({
      field: 'reason',
      message: 'Refund reason is required',
      code: 'REASON_REQUIRED',
      severity: 'error'
    });
  }

  // Amount validation
  if (!refund.refundAmount || refund.refundAmount <= 0) {
    errors.push({
      field: 'refundAmount',
      message: 'Refund amount must be greater than zero',
      code: 'INVALID_REFUND_AMOUNT',
      severity: 'error'
    });
  }

  if (refund.refundAmount > refund.originalAmount) {
    errors.push({
      field: 'refundAmount',
      message: 'Refund amount cannot exceed original order amount',
      code: 'REFUND_EXCEEDS_ORIGINAL',
      severity: 'error'
    });
  }

  // Partial refund validation
  if (refund.refundType === 'partial_refund' && refund.refundAmount === refund.originalAmount) {
    warnings.push({
      field: 'refundType',
      message: 'Refund amount equals original - consider full refund type',
      code: 'PARTIAL_EQUALS_FULL'
    });
  }

  // High-value refund warning
  if (refund.refundAmount > 50000) { // $500
    warnings.push({
      field: 'refundAmount',
      message: 'High-value refund requires manager approval',
      code: 'HIGH_VALUE_REFUND'
    });
  }

  return { isValid: errors.length === 0, errors, warnings };
}

// ============================================
// UTILITY FUNCTIONS
// ============================================

/**
 * Format validation errors for display
 */
export function formatValidationErrors(errors: ValidationError[]): string[] {
  return errors.map(error => `${error.field}: ${error.message}`);
}

/**
 * Check if validation result has critical errors
 */
export function hasCriticalErrors(result: ValidationResult): boolean {
  return result.errors.some(error => error.severity === 'error');
}

/**
 * Get errors by field
 */
export function getErrorsByField(errors: ValidationError[], field: string): ValidationError[] {
  return errors.filter(error => error.field === field || error.field.startsWith(`${field}.`));
}

/**
 * Sanitize input data
 */
export function sanitizeString(input: string): string {
  if (typeof input !== 'string') return '';
  
  return input
    .trim()
    .replace(/[<>]/g, '') // Remove potential HTML tags
    .replace(/[^\w\s\-.,@#()]/g, '') // Allow only safe characters
    .substring(0, 1000); // Limit length
}

/**
 * Validate email format
 */
export function isValidEmail(email: string): boolean {
  return VALIDATION_PATTERNS.email.test(email);
}

/**
 * Validate phone number
 */
export function isValidPhone(phone: string): boolean {
  const cleaned = phone.replace(/\D/g, '');
  return cleaned.length >= 10 && cleaned.length <= 15;
}

/**
 * Validate ZIP code
 */
export function isValidZipCode(zipCode: string): boolean {
  return VALIDATION_PATTERNS.zipCode.test(zipCode);
}

/**
 * Create validation summary
 */
export function createValidationSummary(result: ValidationResult): string {
  const errorCount = result.errors.length;
  const warningCount = result.warnings.length;
  
  if (errorCount === 0 && warningCount === 0) {
    return 'Validation passed successfully';
  }
  
  const parts = [];
  if (errorCount > 0) {
    parts.push(`${errorCount} error${errorCount === 1 ? '' : 's'}`);
  }
  if (warningCount > 0) {
    parts.push(`${warningCount} warning${warningCount === 1 ? '' : 's'}`);
  }
  
  return `Validation completed with ${parts.join(' and ')}`;
}