import { Toaster } from "@/components/ui/toaster";
import { Toaster as Sonner } from "@/components/ui/sonner";
import { TooltipProvider } from "@/components/ui/tooltip";
import { QueryClient, QueryClientProvider } from "@tanstack/react-query";
import { BrowserRouter, Routes, Route } from "react-router-dom";
import { AuthProvider } from "@/contexts/AuthContext";
import { CartProvider } from "@/contexts/CartContext";
import AdminDashboard from "./pages/AdminDashboard";
import NotFound from "./pages/NotFound";
import { AdminAuthTest } from "./pages/AdminAuthTest";
import VerifyEmail from "./pages/VerifyEmail";
import ForgotPassword from "./pages/ForgotPassword";
import ResetPassword from "./pages/ResetPassword";
import Login from "./pages/Login";
import TestLogin from "./pages/TestLogin";
import ProductTest from "./pages/ProductTest";
import StorageTest from "./pages/StorageTest";
import SupabaseConnectionTest from "./pages/SupabaseConnectionTest";
import TestProductImages from "./pages/TestProductImages";
import SmartSizingManager from "./components/admin/SmartSizingManager";
import { OrderProcessingDashboard } from "./components/admin/OrderProcessingDashboard";
import { AdminRoute } from "./components/auth/AdminRoute";
import { autoDebugIfNeeded } from "@/utils/deploymentDebug";
import AdminDashboardDirect from "./pages/AdminDashboardDirect";
import EmergencyAdmin from "./pages/EmergencyAdmin";

const queryClient = new QueryClient();

// Auto-run deployment diagnostics if needed
autoDebugIfNeeded();

const App = () => (
  <QueryClientProvider client={queryClient}>
    <TooltipProvider>
      <AuthProvider>
        <CartProvider>
          <Toaster />
          <Sonner />
          <BrowserRouter>
            <Routes>
              <Route path="/" element={<AdminRoute><AdminDashboard /></AdminRoute>} />
              <Route path="/login" element={<Login />} />
              <Route path="/test" element={<TestLogin />} />
              <Route path="/admin" element={<AdminDashboard />} />
              <Route path="/admin/analytics" element={<AdminRoute><AdminDashboard /></AdminRoute>} />
              <Route path="/admin/products" element={<AdminRoute><AdminDashboard /></AdminRoute>} />
              <Route path="/admin/collections" element={<AdminRoute><AdminDashboard /></AdminRoute>} />
              <Route path="/admin/orders" element={<AdminRoute><AdminDashboard /></AdminRoute>} />
              <Route path="/admin/stripe-orders" element={<AdminRoute><AdminDashboard /></AdminRoute>} />
              <Route path="/admin/financial" element={<AdminRoute><AdminDashboard /></AdminRoute>} />
              <Route path="/admin/customers" element={<AdminRoute><AdminDashboard /></AdminRoute>} />
              <Route path="/admin/inventory" element={<AdminRoute><AdminDashboard /></AdminRoute>} />
              <Route path="/admin/weddings" element={<AdminRoute><AdminDashboard /></AdminRoute>} />
              <Route path="/admin/events" element={<AdminRoute><AdminDashboard /></AdminRoute>} />
              <Route path="/admin/custom-orders" element={<AdminRoute><AdminDashboard /></AdminRoute>} />
              <Route path="/admin/reviews" element={<AdminRoute><AdminDashboard /></AdminRoute>} />
              <Route path="/admin/search" element={<AdminRoute><AdminDashboard /></AdminRoute>} />
              <Route path="/admin/search-analytics" element={<AdminRoute><AdminDashboard /></AdminRoute>} />
              <Route path="/admin/reports" element={<AdminRoute><AdminDashboard /></AdminRoute>} />
              <Route path="/admin/integrations" element={<AdminRoute><AdminDashboard /></AdminRoute>} />
              <Route path="/admin/settings" element={<AdminRoute><AdminDashboard /></AdminRoute>} />
              <Route path="/admin/email-analytics" element={<AdminRoute><AdminDashboard /></AdminRoute>} />
              <Route path="/admin/revenue-forecast" element={<AdminRoute><AdminDashboard /></AdminRoute>} />
              <Route path="/admin/ai-recommendations" element={<AdminRoute><AdminDashboard /></AdminRoute>} />
              <Route path="/admin/predictive-analytics" element={<AdminRoute><AdminDashboard /></AdminRoute>} />
              <Route path="/admin/customer-lifetime-value" element={<AdminRoute><AdminDashboard /></AdminRoute>} />
              <Route path="/admin/ab-testing" element={<AdminRoute><AdminDashboard /></AdminRoute>} />
              <Route path="/admin/inventory-forecasting" element={<AdminRoute><AdminDashboard /></AdminRoute>} />
              <Route path="/admin/automation" element={<AdminRoute><AdminDashboard /></AdminRoute>} />
              <Route path="/admin/stripe-sync" element={<AdminRoute><AdminDashboard /></AdminRoute>} />
              <Route path="/admin/test-auth" element={<AdminRoute><AdminAuthTest /></AdminRoute>} />
              <Route path="/product-test" element={<ProductTest />} />
              <Route path="/storage-test" element={<StorageTest />} />
              <Route path="/supabase-test" element={<SupabaseConnectionTest />} />
              <Route path="/test-images" element={<TestProductImages />} />
              <Route path="/admin/sizing" element={<AdminRoute><SmartSizingManager /></AdminRoute>} />
              <Route path="/admin/order-processing" element={<AdminRoute><OrderProcessingDashboard /></AdminRoute>} />
              <Route path="/verify-email" element={<VerifyEmail />} />
              <Route path="/forgot-password" element={<ForgotPassword />} />
              <Route path="/reset-password" element={<ResetPassword />} />
              <Route path="/admin-direct" element={<AdminDashboardDirect />} />
              <Route path="/emergency" element={<EmergencyAdmin />} />
              <Route path="/emergency/*" element={<EmergencyAdmin />} />
              <Route path="*" element={<NotFound />} />
            </Routes>
          </BrowserRouter>
        </CartProvider>
      </AuthProvider>
    </TooltipProvider>
  </QueryClientProvider>
);

export default App;
