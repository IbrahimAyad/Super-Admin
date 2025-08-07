/**
 * SESSION MANAGER COMPONENT
 * Complete session management interface with device tracking and security
 * Created: 2025-08-07
 */

import React, { useState, useEffect } from 'react';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { Badge } from '@/components/ui/badge';
import { Alert, AlertDescription } from '@/components/ui/alert';
import { Progress } from '@/components/ui/progress';
import {
  Table,
  TableBody,
  TableCell,
  TableHead,
  TableHeader,
  TableRow,
} from '@/components/ui/table';
import {
  AlertDialog,
  AlertDialogAction,
  AlertDialogCancel,
  AlertDialogContent,
  AlertDialogDescription,
  AlertDialogFooter,
  AlertDialogHeader,
  AlertDialogTitle,
  AlertDialogTrigger,
} from '@/components/ui/alert-dialog';
import {
  Dialog,
  DialogContent,
  DialogDescription,
  DialogHeader,
  DialogTitle,
  DialogTrigger,
} from '@/components/ui/dialog';
import {
  Tooltip,
  TooltipContent,
  TooltipProvider,
  TooltipTrigger,
} from '@/components/ui/tooltip';
import {
  Monitor,
  Smartphone,
  Tablet,
  RefreshCw,
  LogOut,
  Clock,
  Shield,
  MapPin,
  AlertTriangle,
  CheckCircle,
  XCircle,
  Eye,
  Calendar,
  Activity,
  Zap,
} from 'lucide-react';
import { useSessionManager, useSessionExpiryWarning } from '@/hooks/useSessionManager';
import { AdminSession } from '@/lib/services/sessionManager';
import { toast } from 'sonner';
import { formatDistanceToNow, format } from 'date-fns';

interface SessionManagerProps {
  className?: string;
}

interface DeviceIconProps {
  deviceInfo: Record<string, any>;
  className?: string;
}

function DeviceIcon({ deviceInfo, className = "h-4 w-4" }: DeviceIconProps) {
  const userAgent = deviceInfo?.userAgent?.toLowerCase() || '';
  
  if (userAgent.includes('mobile') || userAgent.includes('android') || userAgent.includes('iphone')) {
    return <Smartphone className={className} />;
  } else if (userAgent.includes('tablet') || userAgent.includes('ipad')) {
    return <Tablet className={className} />;
  } else {
    return <Monitor className={className} />;
  }
}

function getDeviceName(deviceInfo: Record<string, any>): string {
  const userAgent = deviceInfo?.userAgent || '';
  const platform = deviceInfo?.platform || '';
  
  if (userAgent.toLowerCase().includes('chrome')) {
    return `Chrome on ${platform}`;
  } else if (userAgent.toLowerCase().includes('firefox')) {
    return `Firefox on ${platform}`;
  } else if (userAgent.toLowerCase().includes('safari') && !userAgent.toLowerCase().includes('chrome')) {
    return `Safari on ${platform}`;
  } else if (userAgent.toLowerCase().includes('edge')) {
    return `Edge on ${platform}`;
  } else {
    return platform || 'Unknown Device';
  }
}

function getRiskLevelColor(riskLevel: 'low' | 'medium' | 'high'): string {
  switch (riskLevel) {
    case 'high': return 'text-red-600';
    case 'medium': return 'text-yellow-600';
    case 'low': return 'text-green-600';
    default: return 'text-gray-600';
  }
}

function SessionExpiryWarning() {
  const { showWarning, timeRemaining, extendSession, dismissWarning } = useSessionExpiryWarning(5);

  if (!showWarning) return null;

  return (
    <Alert className="border-yellow-200 bg-yellow-50">
      <Clock className="h-4 w-4 text-yellow-600" />
      <AlertDescription className="flex items-center justify-between">
        <div>
          <strong>Session Expiring Soon</strong>
          <p className="text-sm">
            Your session will expire in {timeRemaining} minute{timeRemaining !== 1 ? 's' : ''}.
          </p>
        </div>
        <div className="flex gap-2">
          <Button
            size="sm"
            variant="outline"
            onClick={() => extendSession()}
          >
            Extend Session
          </Button>
          <Button
            size="sm"
            variant="ghost"
            onClick={dismissWarning}
          >
            Dismiss
          </Button>
        </div>
      </AlertDescription>
    </Alert>
  );
}

export function SessionManager({ className }: SessionManagerProps) {
  const {
    currentSession,
    allSessions,
    isLoading,
    isExpiring,
    minutesUntilExpiry,
    refreshSession,
    extendSession,
    logout,
    logoutFromAllDevices,
    isSuspiciousActivity,
    suspiciousReasons,
    riskLevel,
  } = useSessionManager();

  const [selectedSession, setSelectedSession] = useState<AdminSession | null>(null);

  // Calculate session progress (time until expiry)
  const getSessionProgress = (session: AdminSession): number => {
    const now = new Date().getTime();
    const expires = new Date(session.expires_at).getTime();
    const created = new Date(session.created_at).getTime();
    const total = expires - created;
    const remaining = expires - now;
    return Math.max(0, Math.min(100, (remaining / total) * 100));
  };

  const getSessionTimeRemaining = (session: AdminSession): string => {
    const now = new Date();
    const expires = new Date(session.expires_at);
    if (expires <= now) return 'Expired';
    return formatDistanceToNow(expires, { addSuffix: true });
  };

  const handleExtendSession = async () => {
    const success = await extendSession(30);
    if (success) {
      await refreshSession();
    }
  };

  if (isLoading) {
    return (
      <Card className={className}>
        <CardHeader>
          <CardTitle className="flex items-center gap-2">
            <Activity className="h-5 w-5" />
            Session Management
          </CardTitle>
        </CardHeader>
        <CardContent>
          <div className="flex items-center justify-center p-8">
            <RefreshCw className="h-6 w-6 animate-spin" />
          </div>
        </CardContent>
      </Card>
    );
  }

  return (
    <div className={`space-y-6 ${className}`}>
      <SessionExpiryWarning />

      {/* Current Session Overview */}
      <Card>
        <CardHeader>
          <CardTitle className="flex items-center gap-2">
            <Activity className="h-5 w-5" />
            Current Session
          </CardTitle>
          <CardDescription>
            Your current login session and security status
          </CardDescription>
        </CardHeader>
        <CardContent className="space-y-4">
          {currentSession ? (
            <>
              <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                <div className="space-y-2">
                  <div className="flex items-center gap-2">
                    <DeviceIcon deviceInfo={currentSession.device_info} />
                    <span className="font-medium">
                      {getDeviceName(currentSession.device_info)}
                    </span>
                    <Badge variant="outline">Current</Badge>
                  </div>
                  <p className="text-sm text-muted-foreground">
                    Started {formatDistanceToNow(new Date(currentSession.created_at))} ago
                  </p>
                  <p className="text-sm text-muted-foreground">
                    Last activity {formatDistanceToNow(new Date(currentSession.last_activity_at))} ago
                  </p>
                </div>

                <div className="space-y-2">
                  <div className="flex items-center gap-2">
                    <Clock className="h-4 w-4" />
                    <span className="text-sm">
                      Expires {getSessionTimeRemaining(currentSession)}
                    </span>
                  </div>
                  <Progress 
                    value={getSessionProgress(currentSession)} 
                    className="w-full"
                  />
                  {currentSession.remember_me && (
                    <Badge variant="secondary">Remember Me</Badge>
                  )}
                </div>
              </div>

              {/* Security Alerts */}
              {isSuspiciousActivity && (
                <Alert variant="destructive">
                  <AlertTriangle className="h-4 w-4" />
                  <AlertDescription>
                    <div>
                      <strong>Suspicious Activity Detected</strong>
                      <p className="text-sm mt-1">Risk Level: <span className={getRiskLevelColor(riskLevel)}>{riskLevel.toUpperCase()}</span></p>
                      <ul className="text-sm mt-2 list-disc list-inside">
                        {suspiciousReasons.map((reason, index) => (
                          <li key={index}>{reason}</li>
                        ))}
                      </ul>
                    </div>
                  </AlertDescription>
                </Alert>
              )}

              <div className="flex flex-wrap gap-2">
                <Button
                  variant="outline"
                  size="sm"
                  onClick={handleExtendSession}
                >
                  <Zap className="h-4 w-4 mr-2" />
                  Extend Session
                </Button>
                
                <Button
                  variant="outline"
                  size="sm"
                  onClick={refreshSession}
                >
                  <RefreshCw className="h-4 w-4 mr-2" />
                  Refresh
                </Button>

                <AlertDialog>
                  <AlertDialogTrigger asChild>
                    <Button variant="destructive" size="sm">
                      <LogOut className="h-4 w-4 mr-2" />
                      Logout
                    </Button>
                  </AlertDialogTrigger>
                  <AlertDialogContent>
                    <AlertDialogHeader>
                      <AlertDialogTitle>Confirm Logout</AlertDialogTitle>
                      <AlertDialogDescription>
                        Are you sure you want to logout from your current session?
                      </AlertDialogDescription>
                    </AlertDialogHeader>
                    <AlertDialogFooter>
                      <AlertDialogCancel>Cancel</AlertDialogCancel>
                      <AlertDialogAction onClick={logout}>
                        Logout
                      </AlertDialogAction>
                    </AlertDialogFooter>
                  </AlertDialogContent>
                </AlertDialog>
              </div>
            </>
          ) : (
            <Alert>
              <AlertTriangle className="h-4 w-4" />
              <AlertDescription>
                No active session found. Please log in again.
              </AlertDescription>
            </Alert>
          )}
        </CardContent>
      </Card>

      {/* All Sessions */}
      <Card>
        <CardHeader>
          <div className="flex items-center justify-between">
            <div>
              <CardTitle className="flex items-center gap-2">
                <Shield className="h-5 w-5" />
                Active Sessions
              </CardTitle>
              <CardDescription>
                All devices where you're currently logged in
              </CardDescription>
            </div>
            {allSessions.length > 1 && (
              <AlertDialog>
                <AlertDialogTrigger asChild>
                  <Button variant="destructive" size="sm">
                    <LogOut className="h-4 w-4 mr-2" />
                    Logout All
                  </Button>
                </AlertDialogTrigger>
                <AlertDialogContent>
                  <AlertDialogHeader>
                    <AlertDialogTitle>Logout from All Devices</AlertDialogTitle>
                    <AlertDialogDescription>
                      This will end all active sessions across all devices. You'll need to log in again on each device.
                    </AlertDialogDescription>
                  </AlertDialogHeader>
                  <AlertDialogFooter>
                    <AlertDialogCancel>Cancel</AlertDialogCancel>
                    <AlertDialogAction onClick={logoutFromAllDevices}>
                      Logout All Sessions
                    </AlertDialogAction>
                  </AlertDialogFooter>
                </AlertDialogContent>
              </AlertDialog>
            )}
          </div>
        </CardHeader>
        <CardContent>
          {allSessions.length > 0 ? (
            <div className="space-y-4">
              <div className="rounded-md border">
                <Table>
                  <TableHeader>
                    <TableRow>
                      <TableHead>Device</TableHead>
                      <TableHead>Location</TableHead>
                      <TableHead>Status</TableHead>
                      <TableHead>Last Activity</TableHead>
                      <TableHead>Actions</TableHead>
                    </TableRow>
                  </TableHeader>
                  <TableBody>
                    {allSessions.map((session) => {
                      const isCurrentSession = session.id === currentSession?.id;
                      const progress = getSessionProgress(session);
                      const timeRemaining = getSessionTimeRemaining(session);
                      
                      return (
                        <TableRow key={session.id}>
                          <TableCell>
                            <div className="flex items-center gap-2">
                              <DeviceIcon deviceInfo={session.device_info} />
                              <div className="flex flex-col">
                                <span className="font-medium">
                                  {getDeviceName(session.device_info)}
                                </span>
                                <span className="text-xs text-muted-foreground">
                                  {session.device_info?.screenResolution && (
                                    <span>{session.device_info.screenResolution} • </span>
                                  )}
                                  {session.device_info?.timezone}
                                </span>
                              </div>
                              {isCurrentSession && (
                                <Badge variant="default" className="text-xs">
                                  Current
                                </Badge>
                              )}
                              {session.remember_me && (
                                <Badge variant="secondary" className="text-xs">
                                  Remember Me
                                </Badge>
                              )}
                            </div>
                          </TableCell>
                          <TableCell>
                            <div className="flex items-center gap-1">
                              <MapPin className="h-3 w-3 text-muted-foreground" />
                              <span className="text-sm">
                                {session.ip_address || 'Unknown'}
                              </span>
                            </div>
                          </TableCell>
                          <TableCell>
                            <div className="space-y-1">
                              <div className="flex items-center gap-2">
                                {session.is_active ? (
                                  <CheckCircle className="h-4 w-4 text-green-600" />
                                ) : (
                                  <XCircle className="h-4 w-4 text-red-600" />
                                )}
                                <span className="text-sm">
                                  {session.is_active ? 'Active' : 'Inactive'}
                                </span>
                              </div>
                              <div className="flex items-center gap-2">
                                <Progress 
                                  value={progress} 
                                  className="w-16 h-2"
                                />
                                <span className="text-xs text-muted-foreground">
                                  {timeRemaining}
                                </span>
                              </div>
                            </div>
                          </TableCell>
                          <TableCell>
                            <TooltipProvider>
                              <Tooltip>
                                <TooltipTrigger>
                                  <span className="text-sm">
                                    {formatDistanceToNow(new Date(session.last_activity_at))} ago
                                  </span>
                                </TooltipTrigger>
                                <TooltipContent>
                                  {format(new Date(session.last_activity_at), 'PPpp')}
                                </TooltipContent>
                              </Tooltip>
                            </TooltipProvider>
                          </TableCell>
                          <TableCell>
                            <div className="flex gap-1">
                              <Dialog>
                                <DialogTrigger asChild>
                                  <Button
                                    variant="ghost"
                                    size="icon"
                                    className="h-8 w-8"
                                    onClick={() => setSelectedSession(session)}
                                  >
                                    <Eye className="h-4 w-4" />
                                  </Button>
                                </DialogTrigger>
                                <DialogContent>
                                  <DialogHeader>
                                    <DialogTitle>Session Details</DialogTitle>
                                    <DialogDescription>
                                      Detailed information about this session
                                    </DialogDescription>
                                  </DialogHeader>
                                  {selectedSession && (
                                    <div className="space-y-4">
                                      <div className="grid grid-cols-2 gap-4">
                                        <div>
                                          <h4 className="font-medium">Device Info</h4>
                                          <p className="text-sm text-muted-foreground">
                                            {getDeviceName(selectedSession.device_info)}
                                          </p>
                                          <p className="text-xs text-muted-foreground">
                                            {selectedSession.device_info?.platform}
                                          </p>
                                        </div>
                                        <div>
                                          <h4 className="font-medium">Location</h4>
                                          <p className="text-sm text-muted-foreground">
                                            IP: {selectedSession.ip_address || 'Unknown'}
                                          </p>
                                          <p className="text-xs text-muted-foreground">
                                            Timezone: {selectedSession.device_info?.timezone}
                                          </p>
                                        </div>
                                        <div>
                                          <h4 className="font-medium">Created</h4>
                                          <p className="text-sm text-muted-foreground">
                                            {format(new Date(selectedSession.created_at), 'PPpp')}
                                          </p>
                                        </div>
                                        <div>
                                          <h4 className="font-medium">Expires</h4>
                                          <p className="text-sm text-muted-foreground">
                                            {format(new Date(selectedSession.expires_at), 'PPpp')}
                                          </p>
                                        </div>
                                      </div>
                                      <div>
                                        <h4 className="font-medium">Browser Info</h4>
                                        <p className="text-xs text-muted-foreground break-all">
                                          {selectedSession.user_agent}
                                        </p>
                                      </div>
                                    </div>
                                  )}
                                </DialogContent>
                              </Dialog>
                              
                              {!isCurrentSession && (
                                <AlertDialog>
                                  <AlertDialogTrigger asChild>
                                    <Button
                                      variant="ghost"
                                      size="icon"
                                      className="h-8 w-8 text-red-600 hover:text-red-700"
                                    >
                                      <LogOut className="h-4 w-4" />
                                    </Button>
                                  </AlertDialogTrigger>
                                  <AlertDialogContent>
                                    <AlertDialogHeader>
                                      <AlertDialogTitle>End Session</AlertDialogTitle>
                                      <AlertDialogDescription>
                                        Are you sure you want to end this session? The user will be logged out from this device.
                                      </AlertDialogDescription>
                                    </AlertDialogHeader>
                                    <AlertDialogFooter>
                                      <AlertDialogCancel>Cancel</AlertDialogCancel>
                                      <AlertDialogAction
                                        onClick={() => {
                                          // This would require a new function to end specific session
                                          toast.info('Session termination feature coming soon');
                                        }}
                                      >
                                        End Session
                                      </AlertDialogAction>
                                    </AlertDialogFooter>
                                  </AlertDialogContent>
                                </AlertDialog>
                              )}
                            </div>
                          </TableCell>
                        </TableRow>
                      );
                    })}
                  </TableBody>
                </Table>
              </div>
            </div>
          ) : (
            <Alert>
              <AlertTriangle className="h-4 w-4" />
              <AlertDescription>
                No active sessions found.
              </AlertDescription>
            </Alert>
          )}
        </CardContent>
      </Card>
    </div>
  );
}