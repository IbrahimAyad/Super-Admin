import { lazy, Suspense } from 'react';
import { Toaster } from "@/components/ui/toaster";
import { Toaster as Sonner } from "@/components/ui/sonner";
import { TooltipProvider } from "@/components/ui/tooltip";
import { QueryClient, QueryClientProvider } from "@tanstack/react-query";
import { BrowserRouter, Routes, Route } from "react-router-dom";
import { AuthProvider } from "@/contexts/AuthContext";
import { CartProvider } from "@/contexts/CartContext";
import { AdminRoute } from "./components/auth/AdminRoute";
import { ProtectedRoute } from "./components/auth/ProtectedRoute";
import { ErrorBoundary } from "./components/error/ErrorBoundary";
import { AsyncErrorBoundary } from "./components/error/AsyncErrorBoundary";
import { autoDebugIfNeeded } from "@/utils/deploymentDebug";
import { getEnv } from "@/lib/config/env";
import { monitoring, logger } from "@/lib/services/monitoring";
import { Skeleton } from "@/components/ui/skeleton";

// Lazy load all route components
const AdminDashboard = lazy(() => import('./pages/AdminDashboard'));
const NotFound = lazy(() => import('./pages/NotFound'));
const AdminAuthTest = lazy(() => import('./pages/AdminAuthTest').then(m => ({ default: m.AdminAuthTest })));
const VerifyEmail = lazy(() => import('./pages/VerifyEmail'));
const ForgotPassword = lazy(() => import('./pages/ForgotPassword'));
const ResetPassword = lazy(() => import('./pages/ResetPassword'));
const Login = lazy(() => import('./pages/Login'));
const TestLogin = lazy(() => import('./pages/TestLogin'));
const ProductTest = lazy(() => import('./pages/ProductTest'));
const StorageTest = lazy(() => import('./pages/StorageTest'));
const SupabaseConnectionTest = lazy(() => import('./pages/SupabaseConnectionTest'));
const TestProductImages = lazy(() => import('./pages/TestProductImages'));
const SmartSizingManager = lazy(() => import('./components/admin/SmartSizingManager'));
const OrderProcessingDashboard = lazy(() => import('./components/admin/OrderProcessingDashboard').then(m => ({ default: m.OrderProcessingDashboard })));
const AdminDashboardDirect = lazy(() => import('./pages/AdminDashboardDirect'));
const EmergencyAdmin = lazy(() => import('./pages/EmergencyAdmin'));

// Loading component for lazy loaded routes
const RouteLoadingFallback = () => (
  <div className="flex items-center justify-center min-h-screen">
    <div className="space-y-4 text-center">
      <div className="flex justify-center">
        <Skeleton className="h-12 w-12 rounded-full" />
      </div>
      <div className="space-y-2">
        <Skeleton className="h-4 w-48 mx-auto" />
        <Skeleton className="h-3 w-32 mx-auto" />
      </div>
    </div>
  </div>
);

const queryClient = new QueryClient({
  defaultOptions: {
    queries: {
      staleTime: 1000 * 60 * 5, // 5 minutes
      cacheTime: 1000 * 60 * 10, // 10 minutes
      retry: 2,
      refetchOnWindowFocus: false,
    },
  },
});

// Initialize monitoring
monitoring.info('Application starting', {
  environment: import.meta.env.MODE,
  version: import.meta.env.VITE_APP_VERSION || 'unknown'
});

// Validate environment variables on app start
try {
  getEnv();
  logger.info('Environment validation successful');
} catch (error) {
  logger.fatal('Critical environment error', error as Error);
}

// Auto-run deployment diagnostics if needed
autoDebugIfNeeded();

const App = () => (
  <ErrorBoundary>
    <QueryClientProvider client={queryClient}>
      <TooltipProvider>
        <AuthProvider>
          <CartProvider>
            <AsyncErrorBoundary>
              <Toaster />
              <Sonner />
              <BrowserRouter>
                <Suspense fallback={<RouteLoadingFallback />}>
                  <Routes>
                    <Route path="/" element={<AdminDashboard />} />
                    <Route path="/login" element={<Login />} />
                    <Route path="/test" element={<ProtectedRoute><TestLogin /></ProtectedRoute>} />
                    <Route path="/admin" element={<AdminDashboard />} />
                    <Route path="/admin/analytics" element={<AdminDashboard />} />
                    <Route path="/admin/products" element={<AdminDashboard />} />
                    <Route path="/admin/collections" element={<AdminDashboard />} />
                    <Route path="/admin/orders" element={<AdminDashboard />} />
                    <Route path="/admin/stripe-orders" element={<AdminDashboard />} />
                    <Route path="/admin/financial" element={<AdminDashboard />} />
                    <Route path="/admin/customers" element={<AdminDashboard />} />
                    <Route path="/admin/inventory" element={<AdminDashboard />} />
                    <Route path="/admin/weddings" element={<AdminDashboard />} />
                    <Route path="/admin/events" element={<AdminDashboard />} />
                    <Route path="/admin/custom-orders" element={<AdminDashboard />} />
                    <Route path="/admin/reviews" element={<AdminDashboard />} />
                    <Route path="/admin/search" element={<AdminDashboard />} />
                    <Route path="/admin/search-analytics" element={<AdminDashboard />} />
                    <Route path="/admin/reports" element={<AdminDashboard />} />
                    <Route path="/admin/integrations" element={<AdminDashboard />} />
                    <Route path="/admin/settings" element={<AdminDashboard />} />
                    <Route path="/admin/email-analytics" element={<AdminDashboard />} />
                    <Route path="/admin/revenue-forecast" element={<AdminDashboard />} />
                    <Route path="/admin/ai-recommendations" element={<AdminDashboard />} />
                    <Route path="/admin/predictive-analytics" element={<AdminDashboard />} />
                    <Route path="/admin/customer-lifetime-value" element={<AdminDashboard />} />
                    <Route path="/admin/ab-testing" element={<AdminDashboard />} />
                    <Route path="/admin/inventory-forecasting" element={<AdminDashboard />} />
                    <Route path="/admin/automation" element={<AdminDashboard />} />
                    <Route path="/admin/stripe-sync" element={<AdminDashboard />} />
                    <Route path="/admin/test-auth" element={<ProtectedRoute><AdminRoute><AdminAuthTest /></AdminRoute></ProtectedRoute>} />
                    <Route path="/product-test" element={<ProtectedRoute><ProductTest /></ProtectedRoute>} />
                    <Route path="/storage-test" element={<ProtectedRoute><StorageTest /></ProtectedRoute>} />
                    <Route path="/supabase-test" element={<ProtectedRoute><SupabaseConnectionTest /></ProtectedRoute>} />
                    <Route path="/test-images" element={<ProtectedRoute><TestProductImages /></ProtectedRoute>} />
                    <Route path="/admin/sizing" element={<AdminRoute><SmartSizingManager /></AdminRoute>} />
                    <Route path="/admin/order-processing" element={<AdminRoute><OrderProcessingDashboard /></AdminRoute>} />
                    <Route path="/verify-email" element={<VerifyEmail />} />
                    <Route path="/forgot-password" element={<ForgotPassword />} />
                    <Route path="/reset-password" element={<ResetPassword />} />
                    <Route path="/admin-direct" element={<AdminDashboardDirect />} />
                    <Route path="/emergency-admin" element={<EmergencyAdmin />} />
                    <Route path="*" element={<NotFound />} />
                  </Routes>
                </Suspense>
              </BrowserRouter>
            </AsyncErrorBoundary>
          </CartProvider>
        </AuthProvider>
      </TooltipProvider>
    </QueryClientProvider>
  </ErrorBoundary>
);

export default App;