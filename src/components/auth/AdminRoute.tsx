import { Navigate, useLocation } from 'react-router-dom';
import { useAdminAuth } from '@/hooks/useAdminAuth';
import { useAuth } from '@/contexts/AuthContext';
import { Loader2 } from 'lucide-react';

interface AdminRouteProps {
  children: React.ReactNode;
  requiredPermission?: string;
}

export function AdminRoute({ children, requiredPermission }: AdminRouteProps) {
  const { user, loading: authLoading } = useAuth();
  const { isAdmin, loading: adminLoading, hasPermission } = useAdminAuth();
  const location = useLocation();

  // Show loading while authentication is being determined
  if (authLoading || adminLoading) {
    return (
      <div className="flex items-center justify-center min-h-screen">
        <Loader2 className="h-8 w-8 animate-spin text-primary" />
      </div>
    );
  }

  // First check if user is authenticated at all
  if (!user) {
    // Redirect to login with return path
    return <Navigate to="/login" state={{ from: location }} replace />;
  }

  // For single-user admin system, if user is authenticated, allow access
  // The detailed admin checks are handled within individual components
  if (!isAdmin) {
    // In single-user mode, give it a moment for admin status to load
    // If still not admin after loading, show access denied
    return (
      <div className="flex items-center justify-center min-h-screen">
        <div className="text-center">
          <Loader2 className="h-8 w-8 animate-spin text-primary mx-auto mb-4" />
          <p className="text-muted-foreground">Verifying admin access...</p>
        </div>
      </div>
    );
  }

  if (requiredPermission && !hasPermission(requiredPermission)) {
    return (
      <div className="flex flex-col items-center justify-center min-h-screen">
        <h1 className="text-2xl font-bold text-red-600 mb-4">Access Denied</h1>
        <p className="text-gray-600">You don't have permission to access this page.</p>
        <p className="text-sm text-gray-500 mt-2">Required permission: {requiredPermission}</p>
      </div>
    );
  }

  return <>{children}</>;
}