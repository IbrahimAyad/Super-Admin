import React from 'react';
import AIChatBot from '@/components/chat/AIChatBot';
import { Card } from '@/components/ui/card';
import { Badge } from '@/components/ui/badge';
import { Shield, Lock, CreditCard, Zap } from 'lucide-react';

export default function TestChatCheckout() {
  return (
    <div className="min-h-screen bg-gray-50">
      {/* Header */}
      <div className="bg-white border-b">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-4">
          <div className="flex items-center justify-between">
            <div>
              <h1 className="text-2xl font-bold">KCT Menswear - Chat Commerce Test</h1>
              <p className="text-sm text-muted-foreground mt-1">
                Test the AI chatbot with secure Stripe checkout integration
              </p>
            </div>
            <div className="flex items-center gap-2">
              <Badge variant="success">
                <Shield className="h-3 w-3 mr-1" />
                Secure
              </Badge>
              <Badge variant="secondary">
                <Zap className="h-3 w-3 mr-1" />
                Live
              </Badge>
            </div>
          </div>
        </div>
      </div>

      {/* Main Content */}
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
        <div className="grid grid-cols-1 lg:grid-cols-3 gap-8">
          {/* Instructions */}
          <div className="lg:col-span-2 space-y-6">
            <Card className="p-6">
              <h2 className="text-lg font-semibold mb-4">🧪 Test Instructions</h2>
              <ol className="space-y-3">
                <li className="flex gap-3">
                  <span className="font-semibold text-blue-600">1.</span>
                  <div>
                    <p className="font-medium">Start a Conversation</p>
                    <p className="text-sm text-muted-foreground">
                      Click the chat button in the bottom right corner to open the AI assistant
                    </p>
                  </div>
                </li>
                <li className="flex gap-3">
                  <span className="font-semibold text-blue-600">2.</span>
                  <div>
                    <p className="font-medium">Browse Products</p>
                    <p className="text-sm text-muted-foreground">
                      Try: "Show me blazers", "Prom collection", or "Velvet blazers"
                    </p>
                  </div>
                </li>
                <li className="flex gap-3">
                  <span className="font-semibold text-blue-600">3.</span>
                  <div>
                    <p className="font-medium">Add to Cart</p>
                    <p className="text-sm text-muted-foreground">
                      Click "Add to Cart" on any product you like
                    </p>
                  </div>
                </li>
                <li className="flex gap-3">
                  <span className="font-semibold text-blue-600">4.</span>
                  <div>
                    <p className="font-medium">Checkout</p>
                    <p className="text-sm text-muted-foreground">
                      Say "checkout" or click the checkout button to get a secure Stripe payment link
                    </p>
                  </div>
                </li>
              </ol>
            </Card>

            <Card className="p-6">
              <h2 className="text-lg font-semibold mb-4">✅ What's Working</h2>
              <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
                <div className="flex items-start gap-3">
                  <div className="text-green-500">✓</div>
                  <div>
                    <p className="font-medium">Product Search</p>
                    <p className="text-sm text-muted-foreground">AI-powered product discovery</p>
                  </div>
                </div>
                <div className="flex items-start gap-3">
                  <div className="text-green-500">✓</div>
                  <div>
                    <p className="font-medium">Cart Management</p>
                    <p className="text-sm text-muted-foreground">Add/remove items in chat</p>
                  </div>
                </div>
                <div className="flex items-start gap-3">
                  <div className="text-green-500">✓</div>
                  <div>
                    <p className="font-medium">Secure Checkout</p>
                    <p className="text-sm text-muted-foreground">Stripe-hosted payment page</p>
                  </div>
                </div>
                <div className="flex items-start gap-3">
                  <div className="text-green-500">✓</div>
                  <div>
                    <p className="font-medium">Order Tracking</p>
                    <p className="text-sm text-muted-foreground">Success/cancel handling</p>
                  </div>
                </div>
              </div>
            </Card>

            <Card className="p-6 bg-yellow-50 border-yellow-200">
              <h2 className="text-lg font-semibold mb-4">⚠️ Test Mode</h2>
              <p className="text-sm mb-3">Use these test card numbers for checkout:</p>
              <div className="space-y-2 font-mono text-sm">
                <div>
                  <span className="font-semibold">Success:</span> 4242 4242 4242 4242
                </div>
                <div>
                  <span className="font-semibold">Decline:</span> 4000 0000 0000 0002
                </div>
                <div>
                  <span className="font-semibold">3D Secure:</span> 4000 0027 6000 3184
                </div>
              </div>
              <p className="text-xs text-muted-foreground mt-3">
                Use any future date for expiry and any 3 digits for CVC
              </p>
            </Card>
          </div>

          {/* Status Panel */}
          <div className="space-y-6">
            <Card className="p-6">
              <h2 className="text-lg font-semibold mb-4">🔐 Security Features</h2>
              <div className="space-y-3">
                <div className="flex items-center gap-3">
                  <Lock className="h-4 w-4 text-green-600" />
                  <span className="text-sm">PCI-compliant checkout</span>
                </div>
                <div className="flex items-center gap-3">
                  <Shield className="h-4 w-4 text-green-600" />
                  <span className="text-sm">SSL encrypted</span>
                </div>
                <div className="flex items-center gap-3">
                  <CreditCard className="h-4 w-4 text-green-600" />
                  <span className="text-sm">No card data stored</span>
                </div>
              </div>
            </Card>

            <Card className="p-6">
              <h2 className="text-lg font-semibold mb-4">📊 Test Metrics</h2>
              <div className="space-y-3">
                <div className="flex justify-between">
                  <span className="text-sm text-muted-foreground">Sessions Today</span>
                  <span className="font-semibold">0</span>
                </div>
                <div className="flex justify-between">
                  <span className="text-sm text-muted-foreground">Carts Created</span>
                  <span className="font-semibold">0</span>
                </div>
                <div className="flex justify-between">
                  <span className="text-sm text-muted-foreground">Checkouts Initiated</span>
                  <span className="font-semibold">0</span>
                </div>
                <div className="flex justify-between">
                  <span className="text-sm text-muted-foreground">Orders Completed</span>
                  <span className="font-semibold">0</span>
                </div>
              </div>
            </Card>

            <Card className="p-6 bg-green-50 border-green-200">
              <h2 className="text-lg font-semibold mb-2">✨ Next Features</h2>
              <ul className="space-y-2 text-sm">
                <li>• Apple Pay / Google Pay</li>
                <li>• Embedded payment forms</li>
                <li>• Size recommendations</li>
                <li>• Wedding coordination</li>
                <li>• Virtual fitting</li>
              </ul>
            </Card>
          </div>
        </div>
      </div>

      {/* AI Chat Bot */}
      <AIChatBot />
    </div>
  );
}