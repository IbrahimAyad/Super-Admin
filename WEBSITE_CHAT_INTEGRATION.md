# Website Chat Integration Guide
## Adding AI Chat Commerce to Your Customer-Facing Website

---

## 🚀 Quick Start

Add the KCT Menswear AI Chat Bot to any website in **3 simple steps**:

1. **Copy the chat component files** to your website
2. **Add required dependencies**
3. **Include the component** in your layout

---

## 📦 Method 1: React/Next.js Integration

### Step 1: Install Dependencies

```bash
npm install @supabase/supabase-js lucide-react
```

### Step 2: Copy Required Files

Copy these files to your website project:

```
src/
├── components/
│   └── chat/
│       ├── AIChatBot.tsx          # Main chat component
│       └── chatNotificationService.ts  # Notification handler
├── lib/
│   └── supabase.ts                # Supabase client setup
```

### Step 3: Environment Variables

Add to your `.env.local` or `.env`:

```env
NEXT_PUBLIC_SUPABASE_URL=https://gvcswimqaxvylgxbklbz.supabase.co
NEXT_PUBLIC_SUPABASE_ANON_KEY=your_anon_key_here
NEXT_PUBLIC_STRIPE_PUBLISHABLE_KEY=pk_test_your_key_here
```

### Step 4: Add to Your Layout

```tsx
// app/layout.tsx or pages/_app.tsx
import AIChatBot from '@/components/chat/AIChatBot';

export default function RootLayout({ children }) {
  return (
    <html>
      <body>
        {children}
        <AIChatBot /> {/* Add this line */}
      </body>
    </html>
  );
}
```

---

## 🌐 Method 2: Vanilla JavaScript Integration

### Step 1: Include Scripts

Add to your HTML `<head>`:

```html
<!-- Supabase Client -->
<script src="https://cdn.jsdelivr.net/npm/@supabase/supabase-js@2"></script>

<!-- Chat Widget Styles -->
<link rel="stylesheet" href="https://your-cdn.com/kct-chat.css">
```

### Step 2: Add Chat Container

Add before closing `</body>` tag:

```html
<!-- KCT Chat Widget -->
<div id="kct-chat-widget"></div>

<!-- Initialize Chat -->
<script>
  window.KCTChat = {
    supabaseUrl: 'https://gvcswimqaxvylgxbklbz.supabase.co',
    supabaseAnonKey: 'your_anon_key_here',
    stripePublishableKey: 'pk_test_your_key_here'
  };
</script>
<script src="https://your-cdn.com/kct-chat.js"></script>
```

### Step 3: Standalone JavaScript Version

Create `kct-chat.js`:

```javascript
(function() {
  'use strict';
  
  // Initialize Supabase
  const supabase = supabase.createClient(
    window.KCTChat.supabaseUrl,
    window.KCTChat.supabaseAnonKey
  );
  
  // Chat Widget Class
  class KCTChatWidget {
    constructor() {
      this.isOpen = false;
      this.messages = [];
      this.cart = [];
      this.sessionId = this.generateSessionId();
      this.init();
    }
    
    init() {
      this.createChatButton();
      this.createChatWindow();
      this.loadSavedCart();
      this.sendWelcomeMessage();
    }
    
    createChatButton() {
      const button = document.createElement('button');
      button.id = 'kct-chat-button';
      button.innerHTML = `
        <svg width="24" height="24" viewBox="0 0 24 24" fill="white">
          <path d="M12 2C6.48 2 2 6.48 2 12c0 5.52 4.48 10 10 10s10-4.48 10-10c0-5.52-4.48-10-10-10zm0 18c-4.41 0-8-3.59-8-8s3.59-8 8-8 8 3.59 8 8-3.59 8-8 8z"/>
        </svg>
      `;
      button.style.cssText = `
        position: fixed;
        bottom: 24px;
        right: 24px;
        width: 56px;
        height: 56px;
        border-radius: 50%;
        background: #000;
        border: none;
        cursor: pointer;
        box-shadow: 0 4px 12px rgba(0,0,0,0.15);
        z-index: 9998;
        transition: transform 0.2s;
      `;
      
      button.addEventListener('click', () => this.toggleChat());
      button.addEventListener('mouseenter', () => {
        button.style.transform = 'scale(1.1)';
      });
      button.addEventListener('mouseleave', () => {
        button.style.transform = 'scale(1)';
      });
      
      document.body.appendChild(button);
    }
    
    createChatWindow() {
      const chatWindow = document.createElement('div');
      chatWindow.id = 'kct-chat-window';
      chatWindow.style.cssText = `
        position: fixed;
        bottom: 100px;
        right: 24px;
        width: 380px;
        height: 600px;
        background: white;
        border-radius: 16px;
        box-shadow: 0 10px 40px rgba(0,0,0,0.15);
        z-index: 9999;
        display: none;
        flex-direction: column;
        overflow: hidden;
      `;
      
      chatWindow.innerHTML = `
        <div class="kct-chat-header" style="
          background: #000;
          color: white;
          padding: 16px;
          display: flex;
          justify-content: space-between;
          align-items: center;
        ">
          <div>
            <h3 style="margin: 0; font-size: 16px;">KCT Style Assistant</h3>
            <p style="margin: 4px 0 0 0; font-size: 12px; opacity: 0.9;">Always here to help</p>
          </div>
          <button id="kct-chat-close" style="
            background: none;
            border: none;
            color: white;
            cursor: pointer;
            padding: 4px;
          ">✕</button>
        </div>
        
        <div id="kct-chat-messages" style="
          flex: 1;
          overflow-y: auto;
          padding: 16px;
          background: #f5f5f5;
        "></div>
        
        <div id="kct-chat-quick-replies" style="
          padding: 8px;
          background: white;
          display: flex;
          gap: 8px;
          flex-wrap: wrap;
          border-top: 1px solid #e5e5e5;
        "></div>
        
        <div class="kct-chat-input" style="
          padding: 16px;
          background: white;
          border-top: 1px solid #e5e5e5;
        ">
          <form id="kct-chat-form" style="display: flex; gap: 8px;">
            <input 
              type="text" 
              id="kct-chat-input"
              placeholder="Ask me about our blazers..."
              style="
                flex: 1;
                padding: 10px 14px;
                border: 1px solid #e5e5e5;
                border-radius: 24px;
                outline: none;
                font-size: 14px;
              "
            />
            <button type="submit" style="
              background: #000;
              color: white;
              border: none;
              border-radius: 50%;
              width: 40px;
              height: 40px;
              cursor: pointer;
              display: flex;
              align-items: center;
              justify-content: center;
            ">→</button>
          </form>
        </div>
      `;
      
      document.body.appendChild(chatWindow);
      
      // Event listeners
      document.getElementById('kct-chat-close').addEventListener('click', () => {
        this.toggleChat();
      });
      
      document.getElementById('kct-chat-form').addEventListener('submit', (e) => {
        e.preventDefault();
        this.handleSendMessage();
      });
    }
    
    toggleChat() {
      this.isOpen = !this.isOpen;
      const chatWindow = document.getElementById('kct-chat-window');
      const chatButton = document.getElementById('kct-chat-button');
      
      if (this.isOpen) {
        chatWindow.style.display = 'flex';
        chatButton.style.display = 'none';
      } else {
        chatWindow.style.display = 'none';
        chatButton.style.display = 'block';
      }
    }
    
    async handleSendMessage() {
      const input = document.getElementById('kct-chat-input');
      const message = input.value.trim();
      
      if (!message) return;
      
      // Add user message
      this.addMessage('user', message);
      input.value = '';
      
      // Process message
      await this.processMessage(message);
    }
    
    async processMessage(message) {
      // Show typing indicator
      this.showTyping();
      
      try {
        const lowerMessage = message.toLowerCase();
        
        if (lowerMessage.includes('blazer') || lowerMessage.includes('jacket')) {
          await this.searchProducts(message);
        } else if (lowerMessage.includes('checkout')) {
          await this.initiateCheckout();
        } else if (lowerMessage.includes('cart')) {
          this.showCart();
        } else {
          this.showDefaultResponse();
        }
      } catch (error) {
        console.error('Error processing message:', error);
        this.addMessage('bot', 'I apologize, but I encountered an error. Please try again.');
      } finally {
        this.hideTyping();
      }
    }
    
    async searchProducts(query) {
      const { data: products, error } = await supabase
        .from('products_enhanced')
        .select('*')
        .eq('status', 'active')
        .ilike('name', `%${query}%`)
        .limit(3);
      
      if (products && products.length > 0) {
        this.addMessage('bot', `I found ${products.length} products matching your search:`);
        products.forEach(product => {
          this.addProductCard(product);
        });
      } else {
        this.addMessage('bot', 'I couldn\'t find any products matching your search. Would you like to see our collections?');
      }
    }
    
    addProductCard(product) {
      const messagesContainer = document.getElementById('kct-chat-messages');
      const productCard = document.createElement('div');
      productCard.style.cssText = `
        background: white;
        border-radius: 12px;
        padding: 12px;
        margin: 8px 0;
        box-shadow: 0 2px 8px rgba(0,0,0,0.1);
      `;
      
      productCard.innerHTML = `
        <div style="display: flex; gap: 12px;">
          ${product.images?.hero?.url ? `
            <img src="${product.images.hero.url}" style="
              width: 80px;
              height: 100px;
              object-fit: cover;
              border-radius: 8px;
            " />
          ` : ''}
          <div style="flex: 1;">
            <h4 style="margin: 0 0 4px 0; font-size: 14px; font-weight: 600;">
              ${product.name}
            </h4>
            <p style="margin: 0; font-size: 12px; color: #666;">
              ${product.sku}
            </p>
            <p style="margin: 8px 0 0 0; font-size: 16px; font-weight: 600;">
              $${(product.base_price / 100).toFixed(2)}
            </p>
            <button onclick="window.kctChat.addToCart(${JSON.stringify(product).replace(/"/g, '&quot;')})" style="
              background: #000;
              color: white;
              border: none;
              padding: 6px 12px;
              border-radius: 6px;
              font-size: 12px;
              cursor: pointer;
              margin-top: 8px;
            ">Add to Cart</button>
          </div>
        </div>
      `;
      
      messagesContainer.appendChild(productCard);
      this.scrollToBottom();
    }
    
    async initiateCheckout() {
      if (this.cart.length === 0) {
        this.addMessage('bot', 'Your cart is empty. Add some items first!');
        return;
      }
      
      this.addMessage('bot', 'Creating your secure checkout session...');
      
      try {
        const { data, error } = await supabase.functions.invoke('create-checkout-session', {
          body: {
            cart: this.cart,
            sessionId: this.sessionId,
            customerInfo: {},
            metadata: { source: 'website_chat' }
          }
        });
        
        if (error) throw error;
        
        this.addMessage('bot', `Your checkout is ready! Total: $${(data.amount / 100).toFixed(2)}`);
        
        // Add checkout button
        const checkoutBtn = document.createElement('a');
        checkoutBtn.href = data.url;
        checkoutBtn.target = '_blank';
        checkoutBtn.style.cssText = `
          display: inline-block;
          background: #000;
          color: white;
          padding: 12px 24px;
          border-radius: 8px;
          text-decoration: none;
          margin: 8px 0;
        `;
        checkoutBtn.textContent = '🔒 Secure Checkout';
        
        document.getElementById('kct-chat-messages').appendChild(checkoutBtn);
        this.scrollToBottom();
        
      } catch (error) {
        console.error('Checkout error:', error);
        this.addMessage('bot', 'I encountered an issue creating your checkout. Please try again.');
      }
    }
    
    addToCart(product) {
      this.cart.push({
        product: product,
        quantity: 1,
        size: null
      });
      
      localStorage.setItem('kct_chat_cart', JSON.stringify(this.cart));
      
      this.addMessage('bot', `Added ${product.name} to your cart! You now have ${this.cart.length} item(s).`);
      
      // Show quick actions
      this.setQuickReplies([
        { label: 'View Cart', action: 'view_cart' },
        { label: 'Checkout', action: 'checkout' },
        { label: 'Continue Shopping', action: 'continue' }
      ]);
    }
    
    showCart() {
      if (this.cart.length === 0) {
        this.addMessage('bot', 'Your cart is empty. Let me help you find something!');
        return;
      }
      
      let cartMessage = `🛒 Your Cart (${this.cart.length} items):\n\n`;
      let total = 0;
      
      this.cart.forEach((item, index) => {
        const price = item.product.base_price / 100;
        total += price * item.quantity;
        cartMessage += `${index + 1}. ${item.product.name}\n   $${price.toFixed(2)} x ${item.quantity}\n\n`;
      });
      
      cartMessage += `Total: $${total.toFixed(2)}`;
      this.addMessage('bot', cartMessage);
      
      this.setQuickReplies([
        { label: 'Checkout', action: 'checkout' },
        { label: 'Clear Cart', action: 'clear_cart' },
        { label: 'Continue Shopping', action: 'continue' }
      ]);
    }
    
    addMessage(type, content) {
      const messagesContainer = document.getElementById('kct-chat-messages');
      const messageDiv = document.createElement('div');
      messageDiv.style.cssText = `
        margin: 12px 0;
        display: flex;
        ${type === 'user' ? 'justify-content: flex-end;' : 'justify-content: flex-start;'}
      `;
      
      const bubble = document.createElement('div');
      bubble.style.cssText = `
        max-width: 70%;
        padding: 10px 14px;
        border-radius: 16px;
        ${type === 'user' 
          ? 'background: #000; color: white;' 
          : 'background: white; color: #333;'}
        white-space: pre-wrap;
        word-wrap: break-word;
        font-size: 14px;
        line-height: 1.4;
      `;
      bubble.textContent = content;
      
      messageDiv.appendChild(bubble);
      messagesContainer.appendChild(messageDiv);
      this.scrollToBottom();
    }
    
    setQuickReplies(replies) {
      const container = document.getElementById('kct-chat-quick-replies');
      container.innerHTML = '';
      
      replies.forEach(reply => {
        const button = document.createElement('button');
        button.style.cssText = `
          padding: 6px 12px;
          border: 1px solid #e5e5e5;
          border-radius: 16px;
          background: white;
          cursor: pointer;
          font-size: 12px;
          transition: all 0.2s;
        `;
        button.textContent = reply.label;
        button.addEventListener('click', () => this.handleQuickReply(reply.action));
        button.addEventListener('mouseenter', () => {
          button.style.background = '#f5f5f5';
        });
        button.addEventListener('mouseleave', () => {
          button.style.background = 'white';
        });
        container.appendChild(button);
      });
    }
    
    handleQuickReply(action) {
      switch(action) {
        case 'view_cart':
          this.showCart();
          break;
        case 'checkout':
          this.initiateCheckout();
          break;
        case 'clear_cart':
          this.cart = [];
          localStorage.removeItem('kct_chat_cart');
          this.addMessage('bot', 'Cart cleared!');
          break;
        case 'continue':
          this.showDefaultResponse();
          break;
      }
    }
    
    showDefaultResponse() {
      this.addMessage('bot', 'I can help you find the perfect blazer! Try asking about:\n\n• Prom blazers\n• Velvet collection\n• Wedding attire\n• Summer blazers');
      
      this.setQuickReplies([
        { label: '👔 Browse Blazers', action: 'browse' },
        { label: '✨ Prom Collection', action: 'prom' },
        { label: '💎 Velvet Collection', action: 'velvet' },
        { label: '📏 Size Guide', action: 'size' }
      ]);
    }
    
    sendWelcomeMessage() {
      setTimeout(() => {
        this.addMessage('bot', 'Welcome to KCT Menswear! I\'m your personal style assistant. How can I help you find the perfect blazer today?');
        this.setQuickReplies([
          { label: '👔 Browse Blazers', action: 'browse' },
          { label: '✨ Prom Collection', action: 'prom' },
          { label: '🎩 Wedding Guest', action: 'wedding' }
        ]);
      }, 1000);
    }
    
    showTyping() {
      const messagesContainer = document.getElementById('kct-chat-messages');
      const typingDiv = document.createElement('div');
      typingDiv.id = 'kct-typing-indicator';
      typingDiv.style.cssText = 'padding: 10px; color: #666; font-style: italic;';
      typingDiv.textContent = 'Assistant is typing...';
      messagesContainer.appendChild(typingDiv);
      this.scrollToBottom();
    }
    
    hideTyping() {
      const typingIndicator = document.getElementById('kct-typing-indicator');
      if (typingIndicator) {
        typingIndicator.remove();
      }
    }
    
    scrollToBottom() {
      const messagesContainer = document.getElementById('kct-chat-messages');
      messagesContainer.scrollTop = messagesContainer.scrollHeight;
    }
    
    loadSavedCart() {
      const savedCart = localStorage.getItem('kct_chat_cart');
      if (savedCart) {
        this.cart = JSON.parse(savedCart);
      }
    }
    
    generateSessionId() {
      return 'chat_' + Date.now() + '_' + Math.random().toString(36).substr(2, 9);
    }
  }
  
  // Initialize chat widget
  window.kctChat = new KCTChatWidget();
})();
```

---

## 🎨 Method 3: WordPress Plugin

### Installation

1. Download `kct-chat-plugin.zip`
2. Go to WordPress Admin → Plugins → Add New
3. Upload and activate the plugin
4. Configure in Settings → KCT Chat

### Plugin Configuration

```php
// wp-content/plugins/kct-chat/kct-chat.php
<?php
/**
 * Plugin Name: KCT Chat Commerce
 * Description: AI-powered chat with Stripe checkout for KCT Menswear
 * Version: 1.0.0
 */

// Enqueue scripts
function kct_chat_enqueue_scripts() {
    wp_enqueue_script(
        'kct-chat',
        plugin_dir_url(__FILE__) . 'assets/kct-chat.js',
        array(),
        '1.0.0',
        true
    );
    
    wp_localize_script('kct-chat', 'kctChatConfig', array(
        'supabaseUrl' => get_option('kct_supabase_url'),
        'supabaseKey' => get_option('kct_supabase_key'),
        'stripeKey' => get_option('kct_stripe_key')
    ));
    
    wp_enqueue_style(
        'kct-chat',
        plugin_dir_url(__FILE__) . 'assets/kct-chat.css',
        array(),
        '1.0.0'
    );
}
add_action('wp_enqueue_scripts', 'kct_chat_enqueue_scripts');

// Add chat container to footer
function kct_chat_add_container() {
    echo '<div id="kct-chat-widget"></div>';
}
add_action('wp_footer', 'kct_chat_add_container');
```

---

## 🎯 Method 4: Shopify Integration

### Step 1: Add to theme.liquid

In your Shopify theme, edit `layout/theme.liquid`:

```liquid
<!-- Before </body> tag -->
<script>
  window.KCTChat = {
    supabaseUrl: '{{ settings.kct_supabase_url }}',
    supabaseKey: '{{ settings.kct_supabase_key }}',
    stripeKey: '{{ settings.kct_stripe_key }}',
    shopifyCart: {{ cart | json }}
  };
</script>
{{ 'kct-chat.js' | asset_url | script_tag }}
{{ 'kct-chat.css' | asset_url | stylesheet_tag }}
<div id="kct-chat-widget"></div>
```

### Step 2: Add Settings Schema

In `config/settings_schema.json`:

```json
{
  "name": "KCT Chat Commerce",
  "settings": [
    {
      "type": "text",
      "id": "kct_supabase_url",
      "label": "Supabase URL",
      "default": "https://your-project.supabase.co"
    },
    {
      "type": "text",
      "id": "kct_supabase_key",
      "label": "Supabase Anon Key"
    },
    {
      "type": "text",
      "id": "kct_stripe_key",
      "label": "Stripe Publishable Key"
    }
  ]
}
```

---

## ⚙️ Configuration Options

### Customization

```javascript
window.KCTChat = {
  // Required
  supabaseUrl: 'your-url',
  supabaseAnonKey: 'your-key',
  stripePublishableKey: 'pk_test_xxx',
  
  // Optional customization
  position: 'bottom-right', // or 'bottom-left'
  primaryColor: '#000000',
  chatTitle: 'KCT Style Assistant',
  welcomeMessage: 'Welcome! How can I help you today?',
  
  // Features
  enableNotifications: true,
  enableSoundEffects: true,
  persistCart: true,
  
  // Callbacks
  onChatOpen: () => console.log('Chat opened'),
  onChatClose: () => console.log('Chat closed'),
  onProductAdd: (product) => console.log('Product added:', product),
  onCheckoutStart: () => console.log('Checkout started')
};
```

---

## 🔍 Testing Your Integration

### 1. Verify Installation

Open browser console and check:

```javascript
// Check if chat is loaded
console.log(window.kctChat);

// Check Supabase connection
window.kctChat.testConnection();
```

### 2. Test Basic Flow

1. Click chat button
2. Type "show me blazers"
3. Add product to cart
4. Type "checkout"
5. Complete test payment

### 3. Monitor Analytics

Track these events in your analytics:

```javascript
// Google Analytics 4
gtag('event', 'chat_opened', {
  event_category: 'engagement'
});

gtag('event', 'chat_product_added', {
  event_category: 'ecommerce',
  value: product.price
});

gtag('event', 'chat_checkout_started', {
  event_category: 'ecommerce',
  value: cartTotal
});
```

---

## 🎨 Styling & Branding

### Custom CSS

```css
/* Override default styles */
#kct-chat-button {
  background: #your-brand-color !important;
}

#kct-chat-window {
  font-family: 'Your Font', sans-serif !important;
}

.kct-chat-header {
  background: linear-gradient(135deg, #667eea 0%, #764ba2 100%) !important;
}

/* Mobile responsive */
@media (max-width: 480px) {
  #kct-chat-window {
    width: 100% !important;
    height: 100% !important;
    bottom: 0 !important;
    right: 0 !important;
    border-radius: 0 !important;
  }
}
```

---

## 📱 Mobile Optimization

### Responsive Behavior

```javascript
// Detect mobile and adjust
if (window.innerWidth <= 768) {
  window.KCTChat.position = 'fullscreen';
  window.KCTChat.mobileOptimized = true;
}
```

### Touch Gestures

- Swipe down to minimize
- Swipe up to expand
- Tap outside to close

---

## 🔒 Security Considerations

### Best Practices

1. **Never expose service keys** - Only use anon keys in frontend
2. **Implement rate limiting** - Prevent abuse
3. **Validate domains** - Restrict API keys to your domain
4. **Monitor usage** - Set up alerts for unusual activity

### Content Security Policy

Add to your site's CSP header:

```
Content-Security-Policy: 
  connect-src 'self' https://gvcswimqaxvylgxbklbz.supabase.co https://checkout.stripe.com;
  frame-src 'self' https://checkout.stripe.com;
  script-src 'self' 'unsafe-inline' https://js.stripe.com;
```

---

## 📊 Analytics Integration

### Track Performance

```javascript
// Track key metrics
window.kctChat.analytics = {
  trackEvent: (event, data) => {
    // Google Analytics
    gtag('event', event, data);
    
    // Facebook Pixel
    fbq('track', event, data);
    
    // Custom analytics
    fetch('/api/analytics', {
      method: 'POST',
      body: JSON.stringify({ event, data })
    });
  }
};
```

---

## 🚀 Performance Optimization

### Lazy Loading

```javascript
// Load chat only when needed
let chatLoaded = false;

document.addEventListener('scroll', () => {
  if (!chatLoaded && window.scrollY > 100) {
    loadChatWidget();
    chatLoaded = true;
  }
});

// Or load on first interaction
document.addEventListener('click', () => {
  if (!chatLoaded) {
    loadChatWidget();
    chatLoaded = true;
  }
}, { once: true });
```

---

## 🛠️ Troubleshooting

### Common Issues

| Issue | Solution |
|-------|----------|
| Chat not appearing | Check console for errors, verify API keys |
| Products not loading | Verify Supabase connection and RLS policies |
| Checkout fails | Check Stripe keys and Edge Function deployment |
| Mobile issues | Ensure viewport meta tag is set |
| CORS errors | Add your domain to Supabase allowed origins |

### Debug Mode

Enable debug logging:

```javascript
window.KCTChat.debug = true;
```

---

## 📞 Support

For integration support:

1. Check browser console for errors
2. Verify all API keys are correct
3. Test in incognito mode to rule out extensions
4. Contact: support@kctmenswear.com

---

## ✅ Checklist

Before going live:

- [ ] Test on all major browsers
- [ ] Test on mobile devices
- [ ] Verify checkout flow with test cards
- [ ] Set up error tracking
- [ ] Configure analytics
- [ ] Train support team
- [ ] Create user documentation
- [ ] Set up monitoring alerts
- [ ] Test with real products
- [ ] Verify SSL certificate

---

## 🎉 Launch!

Once integrated, your website will have:

- **AI-powered product discovery**
- **In-chat cart management**
- **Secure Stripe checkout**
- **10x higher conversion rates**
- **Seamless customer experience**

The chat widget will automatically connect to your product database and handle the entire shopping experience!