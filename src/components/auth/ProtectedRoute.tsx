import { Navigate } from 'react-router-dom';

interface ProtectedRouteProps {
  children: React.ReactNode;
  allowInProduction?: boolean;
}

/**
 * Component to protect test/debug routes from being accessible in production
 */
export function ProtectedRoute({ children, allowInProduction = false }: ProtectedRouteProps) {
  const isProduction = import.meta.env.PROD;
  const isDevelopmentMode = import.meta.env.VITE_ENABLE_DEV_ROUTES === 'true';
  
  // In production, only allow if explicitly permitted or if dev mode is enabled
  if (isProduction && !allowInProduction && !isDevelopmentMode) {
    console.warn('Test route accessed in production - redirecting to home');
    return <Navigate to="/" replace />;
  }
  
  return <>{children}</>;
}