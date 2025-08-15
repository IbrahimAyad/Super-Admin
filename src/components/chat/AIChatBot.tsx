import React, { useState, useEffect, useRef } from 'react';
import { supabase } from '@/lib/supabase';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { Card } from '@/components/ui/card';
import { ScrollArea } from '@/components/ui/scroll-area';
import { Badge } from '@/components/ui/badge';
import { 
  Send, 
  Bot, 
  User, 
  ShoppingCart, 
  X, 
  Minimize2, 
  Maximize2,
  Sparkles,
  Package,
  Info
} from 'lucide-react';
import { toast } from '@/components/ui/use-toast';
import { cn } from '@/lib/utils';

interface Product {
  id: string;
  name: string;
  sku: string;
  handle: string;
  category: string;
  subcategory?: string;
  price_tier: string;
  base_price: number;
  images?: any;
  description?: string;
  status: string;
  meta_description?: string;
  tags?: string[];
}

interface CartItem {
  product: Product;
  quantity: number;
  size?: string;
}

interface Message {
  id: string;
  type: 'user' | 'bot' | 'product' | 'cart';
  content: string;
  products?: Product[];
  timestamp: Date;
  actions?: MessageAction[];
}

interface MessageAction {
  label: string;
  action: string;
  payload?: any;
}

const QUICK_REPLIES = {
  initial: [
    { label: '👔 Browse Blazers', action: 'browse_blazers' },
    { label: '✨ Prom Collection', action: 'show_prom' },
    { label: '💎 Velvet Collection', action: 'show_velvet' },
    { label: '🎩 Wedding Guest', action: 'wedding_assist' },
    { label: '📏 Size Guide', action: 'size_guide' }
  ],
  product: [
    { label: 'Add to Cart', action: 'add_to_cart' },
    { label: 'View Details', action: 'view_details' },
    { label: 'Check Sizes', action: 'check_sizes' },
    { label: 'Similar Items', action: 'similar_items' }
  ]
};

export default function AIChatBot() {
  const [isOpen, setIsOpen] = useState(false);
  const [isMinimized, setIsMinimized] = useState(false);
  const [messages, setMessages] = useState<Message[]>([]);
  const [inputValue, setInputValue] = useState('');
  const [isTyping, setIsTyping] = useState(false);
  const [cart, setCart] = useState<CartItem[]>([]);
  const [sessionId, setSessionId] = useState<string>('');
  const messagesEndRef = useRef<HTMLDivElement>(null);

  useEffect(() => {
    // Generate session ID
    setSessionId(`chat_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`);
    
    // Load chat history from localStorage
    const savedMessages = localStorage.getItem('chat_messages');
    if (savedMessages) {
      setMessages(JSON.parse(savedMessages));
    } else {
      // Send welcome message
      setMessages([{
        id: '1',
        type: 'bot',
        content: "Welcome to KCT Menswear! I'm your personal style assistant. How can I help you find the perfect blazer today?",
        timestamp: new Date(),
        actions: QUICK_REPLIES.initial
      }]);
    }
  }, []);

  useEffect(() => {
    scrollToBottom();
    // Save messages to localStorage
    if (messages.length > 0) {
      localStorage.setItem('chat_messages', JSON.stringify(messages));
    }
  }, [messages]);

  const scrollToBottom = () => {
    messagesEndRef.current?.scrollIntoView({ behavior: 'smooth' });
  };

  const handleSendMessage = async () => {
    if (!inputValue.trim()) return;

    const userMessage: Message = {
      id: `msg_${Date.now()}`,
      type: 'user',
      content: inputValue,
      timestamp: new Date()
    };

    setMessages(prev => [...prev, userMessage]);
    setInputValue('');
    setIsTyping(true);

    // Process the message
    await processUserMessage(inputValue);
  };

  const processUserMessage = async (message: string) => {
    try {
      const lowerMessage = message.toLowerCase();
      
      // Check for product search keywords
      if (lowerMessage.includes('blazer') || lowerMessage.includes('jacket') || lowerMessage.includes('suit')) {
        await searchProducts(message);
      } 
      // Check for category keywords
      else if (lowerMessage.includes('prom')) {
        await showCategory('Prom');
      } 
      else if (lowerMessage.includes('velvet')) {
        await showCategory('Velvet');
      }
      else if (lowerMessage.includes('wedding')) {
        await showWeddingAssistant();
      }
      else if (lowerMessage.includes('size') || lowerMessage.includes('fit')) {
        await showSizeGuide();
      }
      else if (lowerMessage.includes('cart') || lowerMessage.includes('checkout')) {
        await showCart();
      }
      else {
        // Default response with suggestions
        await showDefaultResponse();
      }
    } catch (error) {
      console.error('Error processing message:', error);
      addBotMessage("I'm sorry, I encountered an error. Please try again or contact our support team.");
    } finally {
      setIsTyping(false);
    }
  };

  const searchProducts = async (query: string) => {
    try {
      // Search products based on query
      const { data: products, error } = await supabase
        .from('products_enhanced')
        .select('*')
        .eq('status', 'active')
        .or(`name.ilike.%${query}%,description.ilike.%${query}%,tags.cs.{${query.toLowerCase()}}`)
        .limit(5);

      if (error) throw error;

      if (products && products.length > 0) {
        addBotMessage(
          `I found ${products.length} products matching your search:`,
          products
        );
      } else {
        addBotMessage("I couldn't find any products matching your search. Would you like to browse our collections?");
      }
    } catch (error) {
      console.error('Search error:', error);
      addBotMessage("Sorry, I couldn't search products right now. Please try browsing our categories.");
    }
  };

  const showCategory = async (subcategory: string) => {
    try {
      const { data: products, error } = await supabase
        .from('products_enhanced')
        .select('*')
        .eq('status', 'active')
        .eq('subcategory', subcategory)
        .limit(6);

      if (error) throw error;

      if (products && products.length > 0) {
        addBotMessage(
          `Here are our top ${subcategory} blazers:`,
          products
        );
      } else {
        addBotMessage(`We're currently updating our ${subcategory} collection. Check back soon!`);
      }
    } catch (error) {
      console.error('Category error:', error);
      addBotMessage("Sorry, I couldn't load this category. Please try again.");
    }
  };

  const showWeddingAssistant = async () => {
    addBotMessage(
      "I'd love to help you find the perfect wedding attire! To get started, could you tell me:\n\n" +
      "1. Are you the groom, groomsman, or a guest?\n" +
      "2. What's the wedding season/date?\n" +
      "3. Do you have a color preference?\n" +
      "4. What's your budget range?",
      undefined,
      [
        { label: 'Groom', action: 'wedding_role', payload: 'groom' },
        { label: 'Groomsman', action: 'wedding_role', payload: 'groomsman' },
        { label: 'Guest', action: 'wedding_role', payload: 'guest' }
      ]
    );
  };

  const showSizeGuide = () => {
    addBotMessage(
      "📏 **KCT Menswear Size Guide**\n\n" +
      "**Blazer Sizes:**\n" +
      "• XS: Chest 34-36\"\n" +
      "• S: Chest 36-38\"\n" +
      "• M: Chest 38-40\"\n" +
      "• L: Chest 40-42\"\n" +
      "• XL: Chest 42-44\"\n" +
      "• 2XL: Chest 44-46\"\n" +
      "• 3XL: Chest 46-48\"\n\n" +
      "**Fit Types:**\n" +
      "• Slim Fit: Tailored close to body\n" +
      "• Modern Fit: Slightly relaxed\n" +
      "• Classic Fit: Traditional comfort\n\n" +
      "Need personalized sizing help? I can assist you!",
      undefined,
      [
        { label: 'Find My Size', action: 'size_calculator' },
        { label: 'Book Fitting', action: 'book_fitting' }
      ]
    );
  };

  const showCart = () => {
    if (cart.length === 0) {
      addBotMessage("Your cart is empty. Let me help you find something special!");
      return;
    }

    const cartTotal = cart.reduce((sum, item) => sum + (item.product.base_price * item.quantity), 0);
    
    addBotMessage(
      `🛒 **Your Cart (${cart.length} items)**\n\n` +
      cart.map(item => 
        `• ${item.product.name}\n  Size: ${item.size || 'Not selected'} | Qty: ${item.quantity} | $${(item.product.base_price / 100).toFixed(2)}`
      ).join('\n\n') +
      `\n\n**Total: $${(cartTotal / 100).toFixed(2)}**`,
      undefined,
      [
        { label: 'Checkout', action: 'checkout' },
        { label: 'Continue Shopping', action: 'continue_shopping' }
      ]
    );
  };

  const showDefaultResponse = () => {
    addBotMessage(
      "I'm here to help you find the perfect blazer! You can:\n\n" +
      "• Browse our collections\n" +
      "• Search for specific styles\n" +
      "• Get sizing assistance\n" +
      "• Plan wedding attire\n\n" +
      "What would you like to explore?",
      undefined,
      QUICK_REPLIES.initial
    );
  };

  const addBotMessage = (content: string, products?: Product[], actions?: MessageAction[]) => {
    const botMessage: Message = {
      id: `msg_${Date.now()}`,
      type: products ? 'product' : 'bot',
      content,
      products,
      timestamp: new Date(),
      actions: actions || (products ? QUICK_REPLIES.product : undefined)
    };
    
    setMessages(prev => [...prev, botMessage]);
  };

  const handleQuickReply = async (action: string, payload?: any) => {
    switch (action) {
      case 'browse_blazers':
        await searchProducts('blazer');
        break;
      case 'show_prom':
        await showCategory('Prom');
        break;
      case 'show_velvet':
        await showCategory('Velvet');
        break;
      case 'wedding_assist':
        await showWeddingAssistant();
        break;
      case 'size_guide':
        showSizeGuide();
        break;
      case 'add_to_cart':
        if (payload) {
          addToCart(payload);
        }
        break;
      case 'checkout':
        await initiateCheckout();
        break;
      case 'open_stripe_checkout':
        if (payload?.url) {
          // Open Stripe checkout in new tab
          window.open(payload.url, '_blank');
          addBotMessage(
            "I've opened the secure checkout in a new tab. Once you complete your purchase, I'll be here to help with order tracking and any questions!"
          );
        }
        break;
      case 'retry_checkout':
        await initiateCheckout();
        break;
      case 'show_cart':
        showCart();
        break;
      case 'contact_support':
        addBotMessage(
          "I'll connect you with our support team:\n\n" +
          "📧 Email: support@kctmenswear.com\n" +
          "📱 Phone: 1-800-KCT-SUIT\n" +
          "💬 Or continue chatting here for immediate assistance!"
        );
        break;
      default:
        showDefaultResponse();
    }
  };

  const addToCart = (product: Product) => {
    setCart(prev => [...prev, { product, quantity: 1 }]);
    toast({
      title: 'Added to cart',
      description: `${product.name} has been added to your cart`
    });
    addBotMessage(
      `Great choice! I've added ${product.name} to your cart. Would you like to:\n\n` +
      "• Continue shopping\n" +
      "• View your cart\n" +
      "• Proceed to checkout",
      undefined,
      [
        { label: 'View Cart', action: 'show_cart' },
        { label: 'Checkout', action: 'checkout' },
        { label: 'Keep Shopping', action: 'continue_shopping' }
      ]
    );
  };

  const initiateCheckout = async () => {
    setIsTyping(true);
    addBotMessage("Creating your secure checkout session...");

    try {
      // Prepare customer info (could be collected earlier in chat)
      const customerInfo = {
        email: '', // Will be collected in Stripe Checkout
        name: '',
        phone: ''
      };

      // Create Stripe checkout session
      const { data, error } = await supabase.functions.invoke('create-checkout-session', {
        body: {
          cart: cart.map(item => ({
            product: {
              id: item.product.id,
              name: item.product.name,
              sku: item.product.sku,
              category: item.product.category,
              base_price: item.product.base_price,
              images: item.product.images
            },
            quantity: item.quantity,
            size: item.size
          })),
          customerInfo,
          sessionId,
          metadata: {
            source: 'ai_chatbot',
            timestamp: new Date().toISOString()
          }
        }
      });

      if (error) throw error;

      // Save cart to localStorage for recovery
      localStorage.setItem('checkout_cart', JSON.stringify(cart));
      localStorage.setItem('checkout_session', data.sessionId);

      addBotMessage(
        `✅ Your secure checkout is ready!\n\n` +
        `**Order Summary:**\n` +
        cart.map(item => `• ${item.product.name} (Size: ${item.size || 'TBD'}) - $${(item.product.base_price / 100).toFixed(2)}`).join('\n') +
        `\n\n**Total: $${(data.amount / 100).toFixed(2)}**\n\n` +
        `Click below to complete your purchase securely with Stripe:`,
        undefined,
        [
          { 
            label: '🔒 Secure Checkout', 
            action: 'open_stripe_checkout',
            payload: { url: data.url }
          },
          { label: 'Edit Cart', action: 'show_cart' }
        ]
      );

      // Track checkout initiation
      trackEvent('checkout_initiated', {
        cart_value: data.amount,
        items_count: cart.length,
        session_id: data.sessionId
      });

    } catch (error) {
      console.error('Checkout error:', error);
      addBotMessage(
        "I encountered an issue creating your checkout session. Please try again or contact our support team.",
        undefined,
        [
          { label: 'Try Again', action: 'retry_checkout' },
          { label: 'Contact Support', action: 'contact_support' }
        ]
      );
    } finally {
      setIsTyping(false);
    }
  };

  // Add function to track analytics events
  const trackEvent = (eventName: string, data?: any) => {
    // Send to analytics service
    if (window.gtag) {
      window.gtag('event', eventName, {
        event_category: 'Chat Commerce',
        event_label: sessionId,
        ...data
      });
    }
  };

  const renderProductCard = (product: Product) => (
    <Card key={product.id} className="p-3 mb-2">
      <div className="flex gap-3">
        {product.images?.hero?.url && (
          <img 
            src={product.images.hero.url} 
            alt={product.name}
            className="w-20 h-24 object-cover rounded"
            onError={(e) => {
              (e.target as HTMLImageElement).src = '/placeholder.svg';
            }}
          />
        )}
        <div className="flex-1">
          <h4 className="font-semibold text-sm">{product.name}</h4>
          <p className="text-xs text-muted-foreground">{product.sku}</p>
          <div className="flex items-center gap-2 mt-1">
            <Badge variant="secondary" className="text-xs">{product.price_tier}</Badge>
            <span className="text-sm font-bold">${(product.base_price / 100).toFixed(2)}</span>
          </div>
          <div className="flex gap-2 mt-2">
            <Button 
              size="sm" 
              variant="outline" 
              className="text-xs"
              onClick={() => handleQuickReply('add_to_cart', product)}
            >
              Add to Cart
            </Button>
            <Button 
              size="sm" 
              variant="ghost" 
              className="text-xs"
            >
              Details
            </Button>
          </div>
        </div>
      </div>
    </Card>
  );

  return (
    <>
      {/* Chat Button */}
      {!isOpen && (
        <Button
          onClick={() => setIsOpen(true)}
          className="fixed bottom-6 right-6 h-14 w-14 rounded-full shadow-lg z-50 bg-black hover:bg-gray-800"
        >
          <Bot className="h-6 w-6" />
        </Button>
      )}

      {/* Chat Window */}
      {isOpen && (
        <Card className={cn(
          "fixed bottom-6 right-6 z-50 shadow-2xl transition-all duration-300",
          isMinimized ? "w-80 h-16" : "w-96 h-[600px]",
          "max-w-[calc(100vw-3rem)]"
        )}>
          {/* Header */}
          <div className="flex items-center justify-between p-4 border-b bg-black text-white rounded-t-lg">
            <div className="flex items-center gap-2">
              <Bot className="h-5 w-5" />
              <div>
                <h3 className="font-semibold">KCT Style Assistant</h3>
                {!isMinimized && (
                  <p className="text-xs opacity-90">Always here to help</p>
                )}
              </div>
            </div>
            <div className="flex gap-1">
              <Button
                size="sm"
                variant="ghost"
                className="h-8 w-8 p-0 text-white hover:bg-white/20"
                onClick={() => setIsMinimized(!isMinimized)}
              >
                {isMinimized ? <Maximize2 className="h-4 w-4" /> : <Minimize2 className="h-4 w-4" />}
              </Button>
              <Button
                size="sm"
                variant="ghost"
                className="h-8 w-8 p-0 text-white hover:bg-white/20"
                onClick={() => setIsOpen(false)}
              >
                <X className="h-4 w-4" />
              </Button>
            </div>
          </div>

          {!isMinimized && (
            <>
              {/* Messages */}
              <ScrollArea className="flex-1 p-4 h-[calc(600px-8rem)]">
                {messages.map((message) => (
                  <div
                    key={message.id}
                    className={cn(
                      "mb-4 flex",
                      message.type === 'user' ? "justify-end" : "justify-start"
                    )}
                  >
                    <div className={cn(
                      "max-w-[80%]",
                      message.type === 'user' ? "order-2" : "order-1"
                    )}>
                      {message.type !== 'user' && (
                        <div className="flex items-center gap-2 mb-1">
                          <Bot className="h-4 w-4 text-muted-foreground" />
                          <span className="text-xs text-muted-foreground">Style Assistant</span>
                        </div>
                      )}
                      
                      <div className={cn(
                        "rounded-lg p-3",
                        message.type === 'user' 
                          ? "bg-black text-white" 
                          : "bg-muted"
                      )}>
                        <p className="text-sm whitespace-pre-wrap">{message.content}</p>
                      </div>

                      {/* Product Cards */}
                      {message.products && (
                        <div className="mt-2">
                          {message.products.map(product => renderProductCard(product))}
                        </div>
                      )}

                      {/* Quick Reply Actions */}
                      {message.actions && (
                        <div className="flex flex-wrap gap-2 mt-2">
                          {message.actions.map((action, idx) => (
                            <Button
                              key={idx}
                              size="sm"
                              variant="outline"
                              className="text-xs"
                              onClick={() => handleQuickReply(action.action, action.payload)}
                            >
                              {action.label}
                            </Button>
                          ))}
                        </div>
                      )}
                    </div>
                  </div>
                ))}
                
                {isTyping && (
                  <div className="flex items-center gap-2">
                    <Bot className="h-4 w-4 text-muted-foreground" />
                    <div className="flex gap-1">
                      <span className="w-2 h-2 bg-gray-400 rounded-full animate-bounce" />
                      <span className="w-2 h-2 bg-gray-400 rounded-full animate-bounce delay-100" />
                      <span className="w-2 h-2 bg-gray-400 rounded-full animate-bounce delay-200" />
                    </div>
                  </div>
                )}
                
                <div ref={messagesEndRef} />
              </ScrollArea>

              {/* Input */}
              <div className="p-4 border-t">
                <form
                  onSubmit={(e) => {
                    e.preventDefault();
                    handleSendMessage();
                  }}
                  className="flex gap-2"
                >
                  <Input
                    value={inputValue}
                    onChange={(e) => setInputValue(e.target.value)}
                    placeholder="Ask me anything about our blazers..."
                    className="flex-1"
                    disabled={isTyping}
                  />
                  <Button 
                    type="submit" 
                    size="sm"
                    disabled={isTyping || !inputValue.trim()}
                  >
                    <Send className="h-4 w-4" />
                  </Button>
                </form>
                
                {cart.length > 0 && (
                  <div className="flex items-center justify-between mt-2 text-xs text-muted-foreground">
                    <span className="flex items-center gap-1">
                      <ShoppingCart className="h-3 w-3" />
                      {cart.length} items in cart
                    </span>
                    <Button
                      size="sm"
                      variant="link"
                      className="text-xs h-auto p-0"
                      onClick={() => showCart()}
                    >
                      View Cart
                    </Button>
                  </div>
                )}
              </div>
            </>
          )}
        </Card>
      )}
    </>
  );
}