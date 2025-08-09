# API Documentation

Complete API reference for KCT Menswear Super Admin Dashboard.

## Base URL

```
Development: http://localhost:8080/api
Production: https://admin.kctmenswear.com/api
```

## Authentication

All API requests require authentication via Supabase Auth.

### Headers

```http
Authorization: Bearer YOUR_JWT_TOKEN
Content-Type: application/json
```

### Getting a Token

```javascript
const { data: { session } } = await supabase.auth.getSession();
const token = session?.access_token;
```

## Endpoints

### Products

#### Get All Products

```http
GET /api/products
```

Query Parameters:
- `category` (string): Filter by category
- `status` (string): active | inactive | archived
- `limit` (number): Results per page (default: 50)
- `offset` (number): Pagination offset

Response:
```json
{
  "data": [
    {
      "id": "uuid",
      "name": "Product Name",
      "description": "Description",
      "category": "suits",
      "base_price": 299.99,
      "status": "active",
      "stripe_product_id": "prod_xxx",
      "product_variants": [...]
    }
  ],
  "total": 100,
  "limit": 50,
  "offset": 0
}
```

#### Get Single Product

```http
GET /api/products/{id}
```

Response:
```json
{
  "id": "uuid",
  "name": "Product Name",
  "description": "Description",
  "category": "suits",
  "base_price": 299.99,
  "images": ["url1", "url2"],
  "product_variants": [
    {
      "id": "uuid",
      "sku": "SKU123",
      "price": 299.99,
      "attributes": {
        "size": "42R",
        "color": "Navy"
      },
      "inventory_quantity": 10
    }
  ]
}
```

#### Create Product

```http
POST /api/products
```

Request Body:
```json
{
  "name": "New Product",
  "description": "Product description",
  "category": "suits",
  "base_price": 299.99,
  "images": ["url1", "url2"],
  "variants": [
    {
      "sku": "SKU123",
      "price": 299.99,
      "attributes": {
        "size": "42R",
        "color": "Navy"
      },
      "inventory_quantity": 10
    }
  ]
}
```

#### Update Product

```http
PUT /api/products/{id}
```

Request Body: Same as create

#### Delete Product

```http
DELETE /api/products/{id}
```

### Orders

#### Get All Orders

```http
GET /api/orders
```

Query Parameters:
- `status`: pending | processing | shipped | delivered | cancelled
- `customer_id`: Filter by customer
- `date_from`: ISO date string
- `date_to`: ISO date string
- `limit`: Results per page
- `offset`: Pagination offset

#### Get Order Details

```http
GET /api/orders/{id}
```

Response:
```json
{
  "id": "uuid",
  "order_number": "ORD-2025-001",
  "customer_id": "uuid",
  "status": "processing",
  "total_amount": 599.99,
  "subtotal": 499.99,
  "tax": 50.00,
  "shipping": 50.00,
  "items": [
    {
      "product_id": "uuid",
      "variant_id": "uuid",
      "quantity": 1,
      "price": 299.99,
      "product_name": "Navy Suit",
      "variant_details": {
        "size": "42R"
      }
    }
  ],
  "shipping_address": {...},
  "billing_address": {...},
  "created_at": "2025-08-09T00:00:00Z"
}
```

#### Create Order

```http
POST /api/orders
```

Request Body:
```json
{
  "customer_id": "uuid",
  "items": [
    {
      "product_id": "uuid",
      "variant_id": "uuid",
      "quantity": 1,
      "price": 299.99
    }
  ],
  "shipping_address": {
    "line1": "123 Main St",
    "city": "New York",
    "state": "NY",
    "postal_code": "10001",
    "country": "US"
  },
  "billing_address": {...}
}
```

#### Update Order Status

```http
PUT /api/orders/{id}/status
```

Request Body:
```json
{
  "status": "shipped",
  "tracking_number": "1234567890",
  "notes": "Shipped via FedEx"
}
```

### Customers

#### Get All Customers

```http
GET /api/customers
```

Query Parameters:
- `search`: Search by name or email
- `segment`: regular | premium | vip
- `status`: active | inactive

#### Get Customer Profile

```http
GET /api/customers/{id}
```

Response includes full profile with orders, addresses, and preferences.

#### Update Customer

```http
PUT /api/customers/{id}
```

### User Profiles

#### Get User Profile

```http
GET /api/user-profiles/{userId}
```

Response:
```json
{
  "id": "uuid",
  "email": "user@example.com",
  "full_name": "John Doe",
  "size_profile": {
    "chest": 42,
    "waist": 34,
    "inseam": 32,
    "neck": 15.5,
    "sleeve": 34,
    "shoe_size": 10,
    "preferred_fit": "slim"
  },
  "style_preferences": {
    "preferred_colors": ["navy", "grey"],
    "preferred_styles": ["business casual"],
    "occasions": ["work", "events"],
    "avoid_materials": ["polyester"]
  },
  "saved_addresses": [...],
  "wishlist_items": [...]
}
```

#### Update Size Profile

```http
PUT /api/user-profiles/{userId}/size-profile
```

Request Body:
```json
{
  "chest": 42,
  "waist": 34,
  "inseam": 32,
  "neck": 15.5,
  "sleeve": 34,
  "shoe_size": 10,
  "preferred_fit": "slim"
}
```

#### Update Style Preferences

```http
PUT /api/user-profiles/{userId}/style-preferences
```

Request Body:
```json
{
  "preferred_colors": ["navy", "grey", "black"],
  "preferred_styles": ["business casual", "formal"],
  "occasions": ["work", "wedding", "dinner"],
  "avoid_materials": ["polyester"],
  "price_range": "moderate"
}
```

### Inventory

#### Get Inventory Levels

```http
GET /api/inventory
```

Query Parameters:
- `low_stock`: true (show only low stock items)
- `variant_id`: Filter by specific variant

#### Update Inventory

```http
PUT /api/inventory/{variant_id}
```

Request Body:
```json
{
  "available_quantity": 50,
  "reserved_quantity": 5,
  "reorder_point": 10,
  "reorder_quantity": 20
}
```

#### Reserve Inventory

```http
POST /api/inventory/reserve
```

Request Body:
```json
{
  "variant_id": "uuid",
  "quantity": 2,
  "order_id": "uuid",
  "expires_at": "2025-08-10T00:00:00Z"
}
```

### Stripe Integration

#### Sync Products

```http
POST /api/stripe/sync
```

Request Body:
```json
{
  "mode": "full", // full | incremental
  "dry_run": false,
  "categories": ["suits", "shirts"],
  "skip_existing": true
}
```

#### Get Sync Status

```http
GET /api/stripe/sync/status
```

Response:
```json
{
  "total_products": 100,
  "synced_products": 95,
  "pending_products": 5,
  "last_sync": "2025-08-09T00:00:00Z",
  "errors": []
}
```

#### Process Refund

```http
POST /api/stripe/refund
```

Request Body:
```json
{
  "order_id": "uuid",
  "amount": 299.99,
  "reason": "customer_request",
  "notes": "Customer changed mind"
}
```

### AI Recommendations

#### Get Recommendations

```http
POST /api/ai/recommendations
```

Request Body:
```json
{
  "customer_id": "uuid",
  "occasion": "wedding",
  "budget": 500,
  "preferences": {
    "colors": ["navy", "grey"],
    "styles": ["formal"]
  }
}
```

Response:
```json
{
  "recommendations": [
    {
      "product_id": "uuid",
      "score": 0.95,
      "reason": "Matches color preference and occasion",
      "suggested_variants": ["uuid1", "uuid2"]
    }
  ],
  "bundles": [
    {
      "name": "Wedding Guest Outfit",
      "items": [...],
      "total_price": 499.99,
      "discount": 50.00
    }
  ]
}
```

### Analytics

#### Get Dashboard Stats

```http
GET /api/analytics/dashboard
```

Query Parameters:
- `period`: today | week | month | year
- `compare`: true (include comparison to previous period)

Response:
```json
{
  "revenue": {
    "current": 50000,
    "previous": 45000,
    "change_percent": 11.1
  },
  "orders": {
    "current": 150,
    "previous": 135,
    "change_percent": 11.1
  },
  "customers": {
    "current": 1200,
    "previous": 1100,
    "change_percent": 9.1
  },
  "average_order_value": {
    "current": 333.33,
    "previous": 333.33,
    "change_percent": 0
  }
}
```

#### Get Sales Report

```http
GET /api/analytics/sales
```

Query Parameters:
- `date_from`: ISO date
- `date_to`: ISO date
- `group_by`: day | week | month
- `category`: Filter by product category

### Email

#### Send Email

```http
POST /api/email/send
```

Request Body:
```json
{
  "to": "customer@example.com",
  "template": "order_confirmation",
  "data": {
    "order_id": "uuid",
    "customer_name": "John Doe"
  }
}
```

#### Get Email Templates

```http
GET /api/email/templates
```

### Webhooks

#### Stripe Webhook

```http
POST /api/webhooks/stripe
```

Headers:
```http
Stripe-Signature: webhook_signature
```

This endpoint handles Stripe events like:
- `checkout.session.completed`
- `payment_intent.succeeded`
- `customer.subscription.created`
- `invoice.payment_failed`

## Error Responses

All endpoints return consistent error responses:

```json
{
  "error": {
    "code": "RESOURCE_NOT_FOUND",
    "message": "The requested resource was not found",
    "details": {
      "resource": "product",
      "id": "uuid"
    }
  }
}
```

Common Error Codes:
- `UNAUTHORIZED`: Missing or invalid authentication
- `FORBIDDEN`: Insufficient permissions
- `RESOURCE_NOT_FOUND`: Resource doesn't exist
- `VALIDATION_ERROR`: Invalid request data
- `RATE_LIMITED`: Too many requests
- `SERVER_ERROR`: Internal server error

## Rate Limiting

- **Default**: 100 requests per minute per IP
- **Authenticated**: 1000 requests per minute per user
- **Stripe Sync**: 10 requests per minute

Rate limit headers:
```http
X-RateLimit-Limit: 100
X-RateLimit-Remaining: 95
X-RateLimit-Reset: 1628686800
```

## Pagination

All list endpoints support pagination:

```http
GET /api/products?limit=20&offset=40
```

Response includes pagination metadata:
```json
{
  "data": [...],
  "pagination": {
    "total": 100,
    "limit": 20,
    "offset": 40,
    "has_more": true
  }
}
```

## Filtering & Sorting

Most endpoints support filtering and sorting:

```http
GET /api/products?category=suits&status=active&sort=price:desc
```

Common sort options:
- `created_at:desc` (newest first)
- `price:asc` (lowest price first)
- `name:asc` (alphabetical)

## Versioning

API version is specified in the URL:

```
https://api.kctmenswear.com/v1/products
```

Current version: `v1`

## SDK Examples

### JavaScript/TypeScript

```typescript
import { createClient } from '@supabase/supabase-js';

const supabase = createClient(url, anonKey);

// Get products
const { data, error } = await supabase
  .from('products')
  .select('*, product_variants(*)')
  .eq('status', 'active');

// Create order
const { data, error } = await supabase
  .from('orders')
  .insert({
    customer_id: 'uuid',
    total_amount: 299.99,
    status: 'pending'
  });
```

### cURL

```bash
# Get products
curl -X GET \
  'https://api.kctmenswear.com/v1/products' \
  -H 'Authorization: Bearer YOUR_TOKEN' \
  -H 'Content-Type: application/json'

# Create order
curl -X POST \
  'https://api.kctmenswear.com/v1/orders' \
  -H 'Authorization: Bearer YOUR_TOKEN' \
  -H 'Content-Type: application/json' \
  -d '{
    "customer_id": "uuid",
    "items": [...]
  }'
```

## Testing

Use the provided Postman collection or test with tools like HTTPie:

```bash
# Install HTTPie
brew install httpie

# Test endpoint
http GET localhost:8080/api/products \
  Authorization:"Bearer YOUR_TOKEN"
```

## Support

For API support:
- Documentation: https://docs.kctmenswear.com/api
- Issues: https://github.com/IbrahimAyad/Super-Admin/issues
- Email: api-support@kctmenswear.com

---

Last Updated: August 2025
API Version: 1.0.0