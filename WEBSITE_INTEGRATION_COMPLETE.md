# Complete Website Integration Guide
## All Systems Ready: Chat Commerce, Checkout & 20-Tier Pricing

---

## 🚀 WEBSITE INTEGRATION OVERVIEW

Your website can now integrate THREE powerful systems:

1. **AI Chat Commerce** - Conversational shopping with in-chat checkout
2. **Standard Checkout** - Traditional e-commerce flow with Stripe
3. **20-Tier Pricing** - Dynamic pricing display and tier-based promotions

---

## 💬 1. AI CHAT WIDGET INTEGRATION

### Quick Setup (Copy & Paste)

Add this to your website's HTML before `</body>`:

```html
<!-- KCT AI Chat Commerce Widget -->
<script src="https://cdn.jsdelivr.net/npm/@supabase/supabase-js@2"></script>

<!-- Configuration -->
<script>
  window.KCTChat = {
    // API Configuration
    supabaseUrl: 'https://gvcswimqaxvylgxbklbz.supabase.co',
    supabaseAnonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imd2Y3N3aW1xYXh2eWxneGJrbGJ6Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3MjI1Mzg3ODIsImV4cCI6MjAzODExNDc4Mn0.3prUhVvlpmVOtaOcTHNqLinkewmLMb3WqJms-xZdsxo',
    stripePublishableKey: 'pk_live_51RAMT2CHc12x7sCzz0cBxUwBPONdyvxMnhDRMwC1bgoaFlDgmEmfvcJZT7yk7jOuEo4LpWkFpb5Gv88DJ9fSB49j00QtRac8uW',
    
    // Chat Configuration
    chatTitle: 'KCT Style Assistant',
    welcomeMessage: 'Welcome! I can help you find the perfect blazer. What occasion are you shopping for?',
    position: 'bottom-right',
    
    // Features
    enablePriceTiers: true,
    showTierBadges: true,
    enableCheckout: true
  };
</script>

<!-- Chat Widget Container -->
<div id="kct-chat-widget"></div>

<!-- Load Chat Widget -->
<script src="path/to/kct-chat-widget.js"></script>
```

### Chat Widget Features
- **Natural Language Search**: "Show me navy blazers under $400"
- **Tier-Based Recommendations**: "What's in your Premium collection?"
- **Smart Filtering**: Automatically filters by price tier
- **In-Chat Checkout**: Complete purchase without leaving chat
- **Order Tracking**: "Where's my order CHT001234?"

---

## 🛒 2. STANDARD CHECKOUT INTEGRATION

### For Product Pages

```javascript
// Fetch product with tier information
async function loadProduct(productId) {
  const { data: product } = await fetch(
    `https://gvcswimqaxvylgxbklbz.supabase.co/rest/v1/products_enhanced?id=eq.${productId}`,
    {
      headers: {
        'apikey': 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imd2Y3N3aW1xYXh2eWxneGJrbGJ6Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3MjI1Mzg3ODIsImV4cCI6MjAzODExNDc4Mn0.3prUhVvlpmVOtaOcTHNqLinkewmLMb3WqJms-xZdsxo'
      }
    }
  ).then(res => res.json());
  
  return product[0];
}

// Display product with tier badge
function displayProduct(product) {
  const tierInfo = getTierInfo(product.price_tier);
  
  return `
    <div class="product-card">
      <img src="${product.images?.hero?.url}" alt="${product.name}">
      <h2>${product.name}</h2>
      
      <!-- Price Tier Badge -->
      <div class="tier-badge" style="background: ${tierInfo.color}">
        ${tierInfo.name} Collection
      </div>
      
      <p class="price">$${(product.base_price / 100).toFixed(2)}</p>
      
      <button onclick="addToCart('${product.id}')">Add to Cart</button>
      <button onclick="buyNow('${product.id}')">Buy Now</button>
    </div>
  `;
}
```

### Checkout Button

```javascript
// Create Stripe checkout session
async function createCheckout(items) {
  const response = await fetch(
    'https://gvcswimqaxvylgxbklbz.supabase.co/functions/v1/create-checkout-secure',
    {
      method: 'POST',
      headers: {
        'Authorization': 'Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imd2Y3N3aW1xYXh2eWxneGJrbGJ6Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3MjI1Mzg3ODIsImV4cCI6MjAzODExNDc4Mn0.3prUhVvlpmVOtaOcTHNqLinkewmLMb3WqJms-xZdsxo',
        'Content-Type': 'application/json'
      },
      body: JSON.stringify({
        items: items,
        success_url: window.location.origin + '/checkout/success',
        cancel_url: window.location.origin + '/checkout/cancel',
        metadata: {
          source: 'website'
        }
      })
    }
  );
  
  const data = await response.json();
  
  // Redirect to Stripe Checkout
  window.location.href = data.checkoutUrl;
}
```

---

## 🏷️ 3. 20-TIER PRICING DISPLAY

### Tier Information Helper

```javascript
// Price tier configuration
const PRICE_TIERS = {
  'tier_1_essential': { name: 'Essential', color: '#9CA3AF', range: '$0-99', message: 'Affordable style' },
  'tier_2_starter': { name: 'Starter', color: '#6B7280', range: '$100-149', message: 'Quality basics' },
  'tier_3_everyday': { name: 'Everyday', color: '#4B5563', range: '$150-199', message: 'Daily essentials' },
  'tier_4_smart': { name: 'Smart', color: '#374151', range: '$200-249', message: 'Smart choices' },
  'tier_5_classic': { name: 'Classic', color: '#1F2937', range: '$250-299', message: 'Timeless style' },
  'tier_6_refined': { name: 'Refined', color: '#991B1B', range: '$300-349', message: 'Refined taste' },
  'tier_7_premium': { name: 'Premium', color: '#7C2D12', range: '$350-399', message: 'Premium quality' },
  'tier_8_distinguished': { name: 'Distinguished', color: '#78350F', range: '$400-449', message: 'Distinguished design' },
  'tier_9_prestige': { name: 'Prestige', color: '#713F12', range: '$450-499', message: 'Prestigious pieces' },
  'tier_10_exclusive': { name: 'Exclusive', color: '#581C87', range: '$500-599', message: 'Exclusively yours' },
  'tier_11_signature': { name: 'Signature', color: '#6B21A8', range: '$600-699', message: 'Signature style' },
  'tier_12_elite': { name: 'Elite', color: '#7C3AED', range: '$700-799', message: 'Elite status' },
  'tier_13_luxe': { name: 'Luxe', color: '#8B5CF6', range: '$800-899', message: 'Luxury redefined' },
  'tier_14_opulent': { name: 'Opulent', color: '#A78BFA', range: '$900-999', message: 'Opulent designs' },
  'tier_15_imperial': { name: 'Imperial', color: '#C4B5FD', range: '$1000-1199', message: 'Imperial quality' },
  'tier_16_majestic': { name: 'Majestic', color: '#DDD6FE', range: '$1200-1399', message: 'Majestic pieces' },
  'tier_17_sovereign': { name: 'Sovereign', color: '#EDE9FE', range: '$1400-1599', message: 'Sovereign style' },
  'tier_18_regal': { name: 'Regal', color: '#F3F4F6', range: '$1600-1799', message: 'Regal bearing' },
  'tier_19_pinnacle': { name: 'Pinnacle', color: '#F9FAFB', range: '$1800-1999', message: 'Fashion pinnacle' },
  'tier_20_bespoke': { name: 'Bespoke', color: '#FFFFFF', range: '$2000+', message: 'Beyond luxury' }
};

function getTierInfo(tierId) {
  return PRICE_TIERS[tierId] || PRICE_TIERS['tier_3_everyday'];
}
```

### Collection Pages by Tier

```javascript
// Fetch products by tier
async function loadTierCollection(tierId) {
  const { data: products } = await fetch(
    `https://gvcswimqaxvylgxbklbz.supabase.co/rest/v1/products_enhanced?price_tier=eq.${tierId}&status=eq.active`,
    {
      headers: {
        'apikey': 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imd2Y3N3aW1xYXh2eWxneGJrbGJ6Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3MjI1Mzg3ODIsImV4cCI6MjAzODExNDc4Mn0.3prUhVvlpmVOtaOcTHNqLinkewmLMb3WqJms-xZdsxo'
      }
    }
  ).then(res => res.json());
  
  return products;
}

// Display tier collection page
function displayTierCollection(tierId) {
  const tierInfo = getTierInfo(tierId);
  
  return `
    <div class="tier-collection-header" style="background: linear-gradient(135deg, ${tierInfo.color}20, ${tierInfo.color}10)">
      <h1>${tierInfo.name} Collection</h1>
      <p class="tier-range">${tierInfo.range}</p>
      <p class="tier-message">${tierInfo.message}</p>
    </div>
  `;
}
```

---

## 📊 4. ANALYTICS INTEGRATION

### Track Tier Performance

```javascript
// Track tier views
function trackTierView(tierId) {
  gtag('event', 'view_tier', {
    event_category: 'engagement',
    tier_id: tierId,
    tier_name: getTierInfo(tierId).name
  });
}

// Track tier conversions
function trackTierPurchase(product) {
  gtag('event', 'purchase', {
    event_category: 'ecommerce',
    value: product.base_price / 100,
    currency: 'USD',
    tier_id: product.price_tier,
    tier_name: getTierInfo(product.price_tier).name
  });
}
```

---

## 🎯 5. MARKETING CAMPAIGNS BY TIER

### Tier-Based Promotions

```javascript
// Display tier-specific promotions
function getTierPromotion(tierId) {
  const promotions = {
    'tier_1_essential': 'Free shipping on orders over $75',
    'tier_2_starter': '10% off your first Starter Collection purchase',
    'tier_3_everyday': 'Buy 2 get 15% off Everyday Essentials',
    'tier_4_smart': 'Smart buyers save 20% this week',
    'tier_5_classic': 'Classic Collection: Timeless style, special price',
    'tier_6_refined': 'Refined taste deserves 15% off',
    'tier_7_premium': 'Premium members get exclusive access',
    'tier_8_distinguished': 'Distinguished customers enjoy free alterations',
    'tier_9_prestige': 'Prestige Collection with complimentary styling',
    'tier_10_exclusive': 'Exclusive access to limited editions'
  };
  
  return promotions[tierId] || null;
}

// Show promotion banner
function showTierPromotion(product) {
  const promo = getTierPromotion(product.price_tier);
  if (promo) {
    return `
      <div class="tier-promotion-banner">
        <span class="badge">${getTierInfo(product.price_tier).name} Offer</span>
        <p>${promo}</p>
      </div>
    `;
  }
  return '';
}
```

---

## 🔧 6. COMPLETE IMPLEMENTATION EXAMPLE

### Full Product Card with Everything

```html
<!DOCTYPE html>
<html>
<head>
  <style>
    .product-grid {
      display: grid;
      grid-template-columns: repeat(auto-fill, minmax(300px, 1fr));
      gap: 24px;
      padding: 24px;
    }
    
    .product-card {
      border: 1px solid #e5e5e5;
      border-radius: 12px;
      overflow: hidden;
      transition: transform 0.2s;
    }
    
    .product-card:hover {
      transform: translateY(-4px);
      box-shadow: 0 10px 40px rgba(0,0,0,0.1);
    }
    
    .tier-badge {
      display: inline-block;
      padding: 4px 12px;
      border-radius: 20px;
      font-size: 12px;
      font-weight: 600;
      margin: 8px;
    }
    
    .price {
      font-size: 24px;
      font-weight: bold;
      margin: 12px;
    }
    
    .chat-bubble {
      position: fixed;
      bottom: 24px;
      right: 24px;
      width: 56px;
      height: 56px;
      background: #000;
      border-radius: 50%;
      display: flex;
      align-items: center;
      justify-content: center;
      cursor: pointer;
      box-shadow: 0 4px 12px rgba(0,0,0,0.15);
    }
  </style>
</head>
<body>

<!-- Product Grid -->
<div id="product-grid" class="product-grid"></div>

<!-- Chat Widget -->
<div id="kct-chat-widget"></div>

<script>
// Initialize Supabase
const SUPABASE_URL = 'https://gvcswimqaxvylgxbklbz.supabase.co';
const SUPABASE_KEY = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imd2Y3N3aW1xYXh2eWxneGJrbGJ6Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3MjI1Mzg3ODIsImV4cCI6MjAzODExNDc4Mn0.3prUhVvlpmVOtaOcTHNqLinkewmLMb3WqJms-xZdsxo';

// Load and display products
async function loadProducts() {
  const response = await fetch(
    `${SUPABASE_URL}/rest/v1/products_enhanced?status=eq.active&limit=12`,
    {
      headers: {
        'apikey': SUPABASE_KEY
      }
    }
  );
  
  const products = await response.json();
  const grid = document.getElementById('product-grid');
  
  products.forEach(product => {
    const tierInfo = getTierInfo(product.price_tier);
    
    grid.innerHTML += `
      <div class="product-card">
        ${product.images?.hero?.url ? 
          `<img src="${product.images.hero.url}" alt="${product.name}" style="width: 100%; height: 300px; object-fit: cover;">` :
          '<div style="width: 100%; height: 300px; background: #f5f5f5;"></div>'
        }
        
        <div style="padding: 16px;">
          <div class="tier-badge" style="background: ${tierInfo.color}20; color: ${tierInfo.color};">
            ${tierInfo.name} Collection
          </div>
          
          <h3>${product.name}</h3>
          <p style="color: #666; font-size: 14px;">${product.sku}</p>
          
          <div class="price">
            $${(product.base_price / 100).toFixed(2)}
            ${product.compare_at_price ? 
              `<span style="text-decoration: line-through; color: #999; font-size: 16px; margin-left: 8px;">
                $${(product.compare_at_price / 100).toFixed(2)}
              </span>` : ''
            }
          </div>
          
          <div style="display: flex; gap: 8px; margin-top: 16px;">
            <button onclick="addToCart('${product.id}')" style="flex: 1; padding: 10px; border: 1px solid #000; background: white; cursor: pointer;">
              Add to Cart
            </button>
            <button onclick="buyNow('${product.id}')" style="flex: 1; padding: 10px; background: #000; color: white; border: none; cursor: pointer;">
              Buy Now
            </button>
          </div>
        </div>
      </div>
    `;
  });
}

// Tier helper function
function getTierInfo(tierId) {
  const tiers = {
    'tier_1_essential': { name: 'Essential', color: '#9CA3AF' },
    'tier_2_starter': { name: 'Starter', color: '#6B7280' },
    'tier_3_everyday': { name: 'Everyday', color: '#4B5563' },
    'tier_4_smart': { name: 'Smart', color: '#374151' },
    'tier_5_classic': { name: 'Classic', color: '#1F2937' },
    'tier_6_refined': { name: 'Refined', color: '#991B1B' },
    'tier_7_premium': { name: 'Premium', color: '#7C2D12' },
    'tier_8_distinguished': { name: 'Distinguished', color: '#78350F' },
    'tier_9_prestige': { name: 'Prestige', color: '#713F12' },
    'tier_10_exclusive': { name: 'Exclusive', color: '#581C87' }
  };
  return tiers[tierId] || { name: 'Standard', color: '#666' };
}

// Cart functions
function addToCart(productId) {
  console.log('Adding to cart:', productId);
  // Implement cart logic
}

// Checkout function
async function buyNow(productId) {
  const response = await fetch(
    `${SUPABASE_URL}/functions/v1/create-checkout-secure`,
    {
      method: 'POST',
      headers: {
        'Authorization': `Bearer ${SUPABASE_KEY}`,
        'Content-Type': 'application/json'
      },
      body: JSON.stringify({
        items: [{
          product_id: productId,
          quantity: 1
        }],
        success_url: window.location.origin + '/success',
        cancel_url: window.location.origin + '/cancel'
      })
    }
  );
  
  const data = await response.json();
  window.location.href = data.checkoutUrl;
}

// Initialize on load
loadProducts();
</script>

</body>
</html>
```

---

## 🚀 7. QUICK START CHECKLIST

### For Website Developer:

- [ ] Add Supabase and Stripe keys to environment variables
- [ ] Include chat widget script on all pages
- [ ] Set up product display with tier badges
- [ ] Implement checkout flow (standard and chat)
- [ ] Add success/cancel pages for Stripe
- [ ] Configure CORS for your domain in Supabase
- [ ] Test both checkout methods
- [ ] Set up analytics tracking
- [ ] Create tier-specific landing pages
- [ ] Implement tier-based promotions

---

## 📱 8. MOBILE CONSIDERATIONS

```css
/* Responsive chat widget */
@media (max-width: 768px) {
  #kct-chat-window {
    width: 100% !important;
    height: 100% !important;
    bottom: 0 !important;
    right: 0 !important;
    border-radius: 0 !important;
  }
  
  .tier-badge {
    font-size: 10px;
    padding: 2px 8px;
  }
}
```

---

## 🔒 9. SECURITY NOTES

1. **Never expose service keys** - Only use anon keys in frontend
2. **Validate prices server-side** - Don't trust frontend prices
3. **Use HTTPS only** - Ensure all API calls use HTTPS
4. **Configure CORS** - Restrict to your domain only
5. **Rate limiting** - Built into Edge Functions

---

## 📞 10. SUPPORT & MONITORING

### API Endpoints Status Check
```javascript
// Check if services are running
async function checkServices() {
  const checks = {
    supabase: await fetch(`${SUPABASE_URL}/rest/v1/`).then(r => r.ok),
    checkout: await fetch(`${SUPABASE_URL}/functions/v1/`).then(r => r.ok)
  };
  
  console.log('Service Status:', checks);
  return checks;
}
```

### Error Handling
```javascript
window.addEventListener('error', (e) => {
  if (e.message.includes('supabase')) {
    console.error('Supabase Error:', e);
    // Fallback to cached data or show message
  }
});
```

---

## ✅ EVERYTHING IS READY!

Your website can now:
1. **Show products** with 20-tier pricing badges
2. **Enable chat commerce** with AI assistant
3. **Process payments** through Stripe (both flows)
4. **Track orders** in unified admin panel
5. **Run tier-based** marketing campaigns

All systems are live and configured. Just add the code to your website!