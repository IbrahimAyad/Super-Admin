import { useState } from "react";
import { useNavigate, Link } from "react-router-dom";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card";
import { Alert, AlertDescription } from "@/components/ui/alert";
import { Checkbox } from "@/components/ui/checkbox";
import { useToast } from "@/components/ui/use-toast";
import { useAuth } from "@/contexts/AuthContext";
import { LogIn, AlertTriangle, Shield, Mail, Eye, EyeOff } from "lucide-react";

export default function Login() {
  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
  const [showPassword, setShowPassword] = useState(false);
  const [rememberMe, setRememberMe] = useState(false);
  const [loading, setLoading] = useState(false);
  const navigate = useNavigate();
  const { toast } = useToast();
  const { 
    signIn, 
    emailVerificationRequired, 
    accountLocked, 
    twoFactorRequired,
    sendEmailVerification 
  } = useAuth();

  const handleLogin = async (e: React.FormEvent) => {
    e.preventDefault();
    setLoading(true);

    try {
      const result = await signIn(email, password, rememberMe);

      if (!result.success) {
        // Handle different error cases
        if (result.requiresVerification || emailVerificationRequired) {
          // Email verification required - don't show generic error
          return;
        } else if (result.accountLocked || accountLocked) {
          // Account locked - don't show generic error
          return;
        } else if (result.twoFactorRequired || result.requiresTwoFactor) {
          // 2FA required - redirect to 2FA page
          navigate("/two-factor-auth");
          return;
        } else {
          throw new Error(result.error || "Invalid credentials");
        }
      }

      // Successful login
      toast({
        title: "Login successful",
        description: "Welcome back!",
      });

      navigate("/admin");
    } catch (error: any) {
      toast({
        title: "Login failed",
        description: error.message || "Invalid credentials",
        variant: "destructive",
      });
    } finally {
      setLoading(false);
    }
  };

  const handleSendVerificationEmail = async () => {
    setLoading(true);
    try {
      await sendEmailVerification();
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="flex items-center justify-center min-h-screen bg-gray-50 p-4">
      <Card className="w-full max-w-md">
        <CardHeader className="space-y-1">
          <CardTitle className="text-2xl font-bold text-center">
            KCT Admin Login
          </CardTitle>
          <CardDescription className="text-center">
            Enter your credentials to access the admin dashboard
          </CardDescription>
        </CardHeader>
        <CardContent>
          {/* Email verification required alert */}
          {emailVerificationRequired && (
            <Alert variant="destructive" className="mb-4">
              <Mail className="h-4 w-4" />
              <AlertDescription>
                Please verify your email address before logging in.
                <Button 
                  variant="link" 
                  className="p-0 h-auto ml-1 text-sm"
                  onClick={handleSendVerificationEmail}
                  disabled={loading}
                >
                  Resend verification email
                </Button>
              </AlertDescription>
            </Alert>
          )}

          {/* Account locked alert */}
          {accountLocked && (
            <Alert variant="destructive" className="mb-4">
              <Shield className="h-4 w-4" />
              <AlertDescription>
                Your account has been temporarily locked due to multiple failed login attempts.
                Please try again later or contact support.
              </AlertDescription>
            </Alert>
          )}

          {/* 2FA required alert */}
          {twoFactorRequired && (
            <Alert className="mb-4">
              <Shield className="h-4 w-4" />
              <AlertDescription>
                Two-factor authentication is required. You will be redirected to enter your verification code.
              </AlertDescription>
            </Alert>
          )}

          <form onSubmit={handleLogin} className="space-y-4">
            <div className="space-y-2">
              <Label htmlFor="email">Email</Label>
              <Input
                id="email"
                type="email"
                placeholder="admin@kctmenswear.com"
                value={email}
                onChange={(e) => setEmail(e.target.value)}
                required
                disabled={loading}
              />
            </div>
            
            <div className="space-y-2">
              <div className="flex items-center justify-between">
                <Label htmlFor="password">Password</Label>
                <Link 
                  to="/forgot-password" 
                  className="text-sm text-primary hover:underline"
                >
                  Forgot password?
                </Link>
              </div>
              <div className="relative">
                <Input
                  id="password"
                  type={showPassword ? "text" : "password"}
                  value={password}
                  onChange={(e) => setPassword(e.target.value)}
                  required
                  disabled={loading}
                  className="pr-10"
                />
                <button
                  type="button"
                  onClick={() => setShowPassword(!showPassword)}
                  className="absolute right-3 top-1/2 -translate-y-1/2 text-gray-500 hover:text-gray-700"
                  disabled={loading}
                >
                  {showPassword ? <EyeOff className="h-4 w-4" /> : <Eye className="h-4 w-4" />}
                </button>
              </div>
            </div>

            <div className="flex items-center space-x-2">
              <Checkbox 
                id="remember-me"
                checked={rememberMe}
                onCheckedChange={(checked) => setRememberMe(checked as boolean)}
                disabled={loading}
              />
              <Label 
                htmlFor="remember-me" 
                className="text-sm font-normal cursor-pointer"
              >
                Remember me for 30 days
              </Label>
            </div>
            
            <Button
              type="submit"
              className="w-full"
              disabled={loading || !email || !password}
            >
              {loading ? (
                "Signing in..."
              ) : (
                <>
                  <LogIn className="mr-2 h-4 w-4" />
                  Sign In
                </>
              )}
            </Button>
          </form>

          <div className="mt-6 text-center">
            <p className="text-sm text-muted-foreground">
              Need help? Contact{" "}
              <a 
                href="mailto:support@kctmenswear.com"
                className="text-primary hover:underline"
              >
                support@kctmenswear.com
              </a>
            </p>
          </div>
        </CardContent>
      </Card>
    </div>
  );
}