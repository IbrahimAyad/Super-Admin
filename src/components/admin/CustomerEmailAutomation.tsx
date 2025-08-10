/**
 * CUSTOMER EMAIL AUTOMATION
 * Automated email templates and campaigns for customer communication
 */

import React, { useState, useEffect } from 'react';
import { Button } from '@/components/ui/button';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Badge } from '@/components/ui/badge';
import { Tabs, TabsContent, TabsList, TabsTrigger } from '@/components/ui/tabs';
import { Input } from '@/components/ui/input';
import { Textarea } from '@/components/ui/textarea';
import { Label } from '@/components/ui/label';
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from '@/components/ui/select';
import { Switch } from '@/components/ui/switch';
import { Separator } from '@/components/ui/separator';
import { Alert, AlertDescription } from '@/components/ui/alert';
import { toast } from 'sonner';
import { supabase } from '@/lib/supabase-client';
import { 
  Mail, 
  Send, 
  Clock,
  CheckCircle,
  AlertTriangle,
  FileText,
  Eye,
  Edit,
  Trash2,
  Copy,
  Users,
  Calendar,
  Package,
  ShoppingCart,
  Heart,
  Star,
  RefreshCw,
  Zap,
  Settings,
  ChevronRight
} from 'lucide-react';

interface EmailTemplate {
  id: string;
  name: string;
  type: 'order_confirmation' | 'shipping' | 'delivery' | 'review_request' | 'welcome' | 'abandoned_cart' | 'promotional';
  subject: string;
  content: string;
  variables: string[];
  enabled: boolean;
  created_at: string;
  updated_at: string;
  send_count: number;
  open_rate: number;
  click_rate: number;
}

interface EmailCampaign {
  id: string;
  name: string;
  template_id: string;
  trigger: 'immediate' | 'scheduled' | 'event_based';
  event_type?: string;
  schedule_time?: string;
  delay_hours?: number;
  audience_filter?: any;
  status: 'draft' | 'active' | 'paused' | 'completed';
  sent_count: number;
  pending_count: number;
  created_at: string;
}

interface EmailQueue {
  id: string;
  to: string;
  template_id: string;
  campaign_id?: string;
  data: any;
  status: 'pending' | 'sent' | 'failed';
  scheduled_for?: string;
  sent_at?: string;
  error_message?: string;
}

const DEFAULT_TEMPLATES = {
  order_confirmation: {
    subject: 'Order Confirmation - #{order_number}',
    content: `
Dear {customer_name},

Thank you for your order! We're excited to confirm that we've received your order #{order_number}.

Order Details:
{order_items}

Subtotal: ${'{subtotal}'}
Shipping: ${'{shipping}'}
Tax: ${'{tax}'}
Total: ${'{total}'}

Shipping Address:
{shipping_address}

You'll receive another email when your order ships.

Best regards,
The KC Tuxedos Team
    `.trim()
  },
  shipping_confirmation: {
    subject: 'Your Order Has Shipped! - #{order_number}',
    content: `
Hi {customer_name},

Great news! Your order #{order_number} has shipped.

Tracking Information:
Carrier: {carrier}
Tracking Number: {tracking_number}
Track Your Package: {tracking_url}

Estimated Delivery: {estimated_delivery}

Items Shipped:
{order_items}

Questions? Reply to this email or contact us at support@kctuxedos.com

Thank you for your business!
KC Tuxedos Team
    `.trim()
  },
  delivery_confirmation: {
    subject: 'Your Order Has Been Delivered! - #{order_number}',
    content: `
Hi {customer_name},

Your order #{order_number} has been delivered!

We hope you love your purchase. If you have any questions or concerns, please don't hesitate to reach out.

Would you mind taking a moment to review your purchase? Your feedback helps us improve and helps other customers make informed decisions.

[Leave a Review]

Thank you for choosing KC Tuxedos!
    `.trim()
  },
  review_request: {
    subject: 'How was your experience with your recent purchase?',
    content: `
Hi {customer_name},

We hope you're enjoying your recent purchase from KC Tuxedos!

Your opinion matters to us and helps other customers. Would you mind taking a moment to share your experience?

[Write a Review for {product_name}]

As a thank you, you'll receive 10% off your next order after submitting your review.

Thank you for being a valued customer!
KC Tuxedos Team
    `.trim()
  },
  welcome: {
    subject: 'Welcome to KC Tuxedos - Enjoy 15% Off Your First Order!',
    content: `
Welcome {customer_name}!

Thank you for joining the KC Tuxedos family. We're thrilled to have you!

As a welcome gift, enjoy 15% off your first order with code: WELCOME15

Browse our collections:
• Men's Suits & Tuxedos
• Dress Shirts
• Ties & Accessories
• Wedding Collections

[Shop Now]

Follow us on social media for style tips and exclusive offers!

Best regards,
KC Tuxedos Team
    `.trim()
  },
  abandoned_cart: {
    subject: 'You left something behind...',
    content: `
Hi {customer_name},

We noticed you left some great items in your cart:

{cart_items}

Complete your purchase now and enjoy free shipping on orders over $200!

[Complete Your Order]

Your cart will be saved for 48 hours. If you have any questions, we're here to help!

KC Tuxedos Team

P.S. Use code SAVE10 for 10% off your order!
    `.trim()
  }
};

export function CustomerEmailAutomation() {
  const [templates, setTemplates] = useState<EmailTemplate[]>([]);
  const [campaigns, setCampaigns] = useState<EmailCampaign[]>([]);
  const [queuedEmails, setQueuedEmails] = useState<EmailQueue[]>([]);
  const [selectedTemplate, setSelectedTemplate] = useState<EmailTemplate | null>(null);
  const [isEditing, setIsEditing] = useState(false);
  const [isSending, setIsSending] = useState(false);
  
  // Template editor
  const [editingTemplate, setEditingTemplate] = useState({
    name: '',
    type: 'order_confirmation' as const,
    subject: '',
    content: '',
    enabled: true
  });

  // Campaign creator
  const [newCampaign, setNewCampaign] = useState({
    name: '',
    template_id: '',
    trigger: 'immediate' as const,
    event_type: '',
    delay_hours: 0
  });

  // Test email
  const [testEmail, setTestEmail] = useState('');

  // Statistics
  const [stats, setStats] = useState({
    totalSent: 0,
    avgOpenRate: 0,
    avgClickRate: 0,
    pendingEmails: 0
  });

  useEffect(() => {
    loadTemplates();
    loadCampaigns();
    loadQueuedEmails();
    calculateStats();
  }, []);

  const loadTemplates = async () => {
    try {
      const { data, error } = await supabase
        .from('email_templates')
        .select('*')
        .order('name');

      if (!error && data) {
        setTemplates(data);
      } else if (data?.length === 0) {
        // Initialize with default templates
        initializeDefaultTemplates();
      }
    } catch (error) {
      console.error('Failed to load templates:', error);
    }
  };

  const loadCampaigns = async () => {
    try {
      const { data, error } = await supabase
        .from('email_campaigns')
        .select('*')
        .order('created_at', { ascending: false });

      if (!error && data) {
        setCampaigns(data);
      }
    } catch (error) {
      console.error('Failed to load campaigns:', error);
    }
  };

  const loadQueuedEmails = async () => {
    try {
      const { data, error } = await supabase
        .from('email_queue')
        .select('*')
        .eq('status', 'pending')
        .order('scheduled_for')
        .limit(50);

      if (!error && data) {
        setQueuedEmails(data);
      }
    } catch (error) {
      console.error('Failed to load email queue:', error);
    }
  };

  const calculateStats = async () => {
    try {
      const { data: sentEmails } = await supabase
        .from('email_queue')
        .select('*')
        .eq('status', 'sent');

      const { count: pendingCount } = await supabase
        .from('email_queue')
        .select('*', { count: 'exact', head: true })
        .eq('status', 'pending');

      const { data: templateStats } = await supabase
        .from('email_templates')
        .select('open_rate, click_rate');

      if (templateStats) {
        const avgOpenRate = templateStats.reduce((sum, t) => sum + (t.open_rate || 0), 0) / templateStats.length;
        const avgClickRate = templateStats.reduce((sum, t) => sum + (t.click_rate || 0), 0) / templateStats.length;

        setStats({
          totalSent: sentEmails?.length || 0,
          avgOpenRate: avgOpenRate || 0,
          avgClickRate: avgClickRate || 0,
          pendingEmails: pendingCount || 0
        });
      }
    } catch (error) {
      console.error('Failed to calculate stats:', error);
    }
  };

  const initializeDefaultTemplates = async () => {
    try {
      const templates = Object.entries(DEFAULT_TEMPLATES).map(([type, template]) => ({
        name: type.replace(/_/g, ' ').replace(/\b\w/g, l => l.toUpperCase()),
        type,
        subject: template.subject,
        content: template.content,
        variables: extractVariables(template.content),
        enabled: true,
        created_at: new Date().toISOString(),
        updated_at: new Date().toISOString(),
        send_count: 0,
        open_rate: 0,
        click_rate: 0
      }));

      const { error } = await supabase
        .from('email_templates')
        .insert(templates);

      if (!error) {
        toast.success('Default templates initialized');
        loadTemplates();
      }
    } catch (error) {
      console.error('Failed to initialize templates:', error);
    }
  };

  const extractVariables = (content: string): string[] => {
    const regex = /\{([^}]+)\}/g;
    const variables = new Set<string>();
    let match;
    
    while ((match = regex.exec(content)) !== null) {
      variables.add(match[1]);
    }
    
    return Array.from(variables);
  };

  const saveTemplate = async () => {
    try {
      const variables = extractVariables(editingTemplate.content);
      
      if (selectedTemplate) {
        // Update existing
        const { error } = await supabase
          .from('email_templates')
          .update({
            ...editingTemplate,
            variables,
            updated_at: new Date().toISOString()
          })
          .eq('id', selectedTemplate.id);

        if (!error) {
          toast.success('Template updated');
        }
      } else {
        // Create new
        const { error } = await supabase
          .from('email_templates')
          .insert({
            ...editingTemplate,
            variables,
            created_at: new Date().toISOString(),
            updated_at: new Date().toISOString(),
            send_count: 0,
            open_rate: 0,
            click_rate: 0
          });

        if (!error) {
          toast.success('Template created');
        }
      }

      loadTemplates();
      setIsEditing(false);
      setSelectedTemplate(null);
    } catch (error) {
      console.error('Failed to save template:', error);
      toast.error('Failed to save template');
    }
  };

  const deleteTemplate = async (templateId: string) => {
    const confirmed = window.confirm('Are you sure you want to delete this template?');
    if (!confirmed) return;

    try {
      const { error } = await supabase
        .from('email_templates')
        .delete()
        .eq('id', templateId);

      if (!error) {
        toast.success('Template deleted');
        loadTemplates();
      }
    } catch (error) {
      console.error('Failed to delete template:', error);
      toast.error('Failed to delete template');
    }
  };

  const sendTestEmail = async () => {
    if (!selectedTemplate || !testEmail) {
      toast.error('Select a template and enter email address');
      return;
    }

    setIsSending(true);

    try {
      // Queue test email
      const { error } = await supabase
        .from('email_queue')
        .insert({
          to: testEmail,
          template_id: selectedTemplate.id,
          data: {
            customer_name: 'Test Customer',
            order_number: 'TEST123',
            order_items: 'Test Product x1',
            total: '$99.99'
          },
          status: 'pending',
          scheduled_for: new Date().toISOString()
        });

      if (!error) {
        toast.success('Test email queued for sending');
      }
    } catch (error) {
      console.error('Failed to send test email:', error);
      toast.error('Failed to send test email');
    } finally {
      setIsSending(false);
    }
  };

  const createCampaign = async () => {
    try {
      const { error } = await supabase
        .from('email_campaigns')
        .insert({
          ...newCampaign,
          status: 'active',
          sent_count: 0,
          pending_count: 0,
          created_at: new Date().toISOString()
        });

      if (!error) {
        toast.success('Campaign created');
        loadCampaigns();
        setNewCampaign({
          name: '',
          template_id: '',
          trigger: 'immediate',
          event_type: '',
          delay_hours: 0
        });
      }
    } catch (error) {
      console.error('Failed to create campaign:', error);
      toast.error('Failed to create campaign');
    }
  };

  const toggleCampaign = async (campaignId: string, status: string) => {
    const newStatus = status === 'active' ? 'paused' : 'active';
    
    try {
      const { error } = await supabase
        .from('email_campaigns')
        .update({ status: newStatus })
        .eq('id', campaignId);

      if (!error) {
        toast.success(`Campaign ${newStatus}`);
        loadCampaigns();
      }
    } catch (error) {
      console.error('Failed to toggle campaign:', error);
    }
  };

  const processEmailQueue = async () => {
    setIsSending(true);

    try {
      // Get pending emails
      const { data: pendingEmails } = await supabase
        .from('email_queue')
        .select('*')
        .eq('status', 'pending')
        .lte('scheduled_for', new Date().toISOString())
        .limit(10);

      if (pendingEmails && pendingEmails.length > 0) {
        // Process each email
        for (const email of pendingEmails) {
          // In production, this would actually send emails via SendGrid/Mailgun
          await supabase
            .from('email_queue')
            .update({
              status: 'sent',
              sent_at: new Date().toISOString()
            })
            .eq('id', email.id);
        }

        toast.success(`Processed ${pendingEmails.length} emails`);
        loadQueuedEmails();
      } else {
        toast.info('No emails to process');
      }
    } catch (error) {
      console.error('Failed to process email queue:', error);
      toast.error('Failed to process email queue');
    } finally {
      setIsSending(false);
    }
  };

  const getTemplateIcon = (type: string) => {
    switch (type) {
      case 'order_confirmation': return <ShoppingCart className="h-4 w-4" />;
      case 'shipping': return <Package className="h-4 w-4" />;
      case 'delivery': return <CheckCircle className="h-4 w-4" />;
      case 'review_request': return <Star className="h-4 w-4" />;
      case 'welcome': return <Heart className="h-4 w-4" />;
      case 'abandoned_cart': return <AlertTriangle className="h-4 w-4" />;
      default: return <Mail className="h-4 w-4" />;
    }
  };

  return (
    <div className="space-y-6">
      {/* Header */}
      <div className="flex items-center justify-between">
        <div>
          <h2 className="text-2xl font-bold">Customer Email Automation</h2>
          <p className="text-muted-foreground">Manage email templates and automated campaigns</p>
        </div>
        
        <Button 
          onClick={processEmailQueue}
          disabled={isSending}
        >
          {isSending ? (
            <>
              <RefreshCw className="h-4 w-4 mr-2 animate-spin" />
              Processing...
            </>
          ) : (
            <>
              <Send className="h-4 w-4 mr-2" />
              Process Queue
            </>
          )}
        </Button>
      </div>

      {/* Statistics */}
      <div className="grid grid-cols-4 gap-4">
        <Card>
          <CardContent className="p-4">
            <div className="flex items-center justify-between">
              <div>
                <p className="text-sm text-muted-foreground">Total Sent</p>
                <p className="text-2xl font-bold">{stats.totalSent}</p>
              </div>
              <Send className="h-8 w-8 text-blue-500" />
            </div>
          </CardContent>
        </Card>

        <Card>
          <CardContent className="p-4">
            <div className="flex items-center justify-between">
              <div>
                <p className="text-sm text-muted-foreground">Avg Open Rate</p>
                <p className="text-2xl font-bold">{stats.avgOpenRate.toFixed(1)}%</p>
              </div>
              <Eye className="h-8 w-8 text-green-500" />
            </div>
          </CardContent>
        </Card>

        <Card>
          <CardContent className="p-4">
            <div className="flex items-center justify-between">
              <div>
                <p className="text-sm text-muted-foreground">Avg Click Rate</p>
                <p className="text-2xl font-bold">{stats.avgClickRate.toFixed(1)}%</p>
              </div>
              <Zap className="h-8 w-8 text-yellow-500" />
            </div>
          </CardContent>
        </Card>

        <Card>
          <CardContent className="p-4">
            <div className="flex items-center justify-between">
              <div>
                <p className="text-sm text-muted-foreground">Pending Emails</p>
                <p className="text-2xl font-bold">{stats.pendingEmails}</p>
              </div>
              <Clock className="h-8 w-8 text-orange-500" />
            </div>
          </CardContent>
        </Card>
      </div>

      <Tabs defaultValue="templates" className="w-full">
        <TabsList className="grid w-full grid-cols-4">
          <TabsTrigger value="templates">Templates</TabsTrigger>
          <TabsTrigger value="campaigns">Campaigns</TabsTrigger>
          <TabsTrigger value="queue">Email Queue</TabsTrigger>
          <TabsTrigger value="editor">Template Editor</TabsTrigger>
        </TabsList>

        {/* Templates Tab */}
        <TabsContent value="templates" className="space-y-4">
          <div className="grid grid-cols-2 gap-4">
            {templates.map((template) => (
              <Card key={template.id}>
                <CardContent className="p-4">
                  <div className="flex items-start justify-between">
                    <div className="flex-1">
                      <div className="flex items-center gap-2 mb-2">
                        {getTemplateIcon(template.type)}
                        <h3 className="font-semibold">{template.name}</h3>
                        <Badge variant={template.enabled ? 'default' : 'outline'}>
                          {template.enabled ? 'Active' : 'Disabled'}
                        </Badge>
                      </div>
                      <p className="text-sm text-muted-foreground mb-2">
                        Subject: {template.subject}
                      </p>
                      <div className="flex items-center gap-4 text-xs text-muted-foreground">
                        <span>Sent: {template.send_count}</span>
                        <span>Open: {template.open_rate}%</span>
                        <span>Click: {template.click_rate}%</span>
                      </div>
                    </div>
                    
                    <div className="flex items-center gap-2">
                      <Button
                        variant="outline"
                        size="sm"
                        onClick={() => {
                          setSelectedTemplate(template);
                          setEditingTemplate({
                            name: template.name,
                            type: template.type as any,
                            subject: template.subject,
                            content: template.content,
                            enabled: template.enabled
                          });
                          setIsEditing(true);
                        }}
                      >
                        <Edit className="h-4 w-4" />
                      </Button>
                      <Button
                        variant="outline"
                        size="sm"
                        onClick={() => deleteTemplate(template.id)}
                      >
                        <Trash2 className="h-4 w-4" />
                      </Button>
                    </div>
                  </div>
                </CardContent>
              </Card>
            ))}
          </div>
        </TabsContent>

        {/* Campaigns Tab */}
        <TabsContent value="campaigns" className="space-y-4">
          <Card>
            <CardHeader>
              <CardTitle>Create Campaign</CardTitle>
            </CardHeader>
            <CardContent>
              <div className="grid grid-cols-5 gap-4">
                <Input
                  placeholder="Campaign name"
                  value={newCampaign.name}
                  onChange={(e) => setNewCampaign(prev => ({ ...prev, name: e.target.value }))}
                />
                <Select
                  value={newCampaign.template_id}
                  onValueChange={(value) => setNewCampaign(prev => ({ ...prev, template_id: value }))}
                >
                  <SelectTrigger>
                    <SelectValue placeholder="Select template" />
                  </SelectTrigger>
                  <SelectContent>
                    {templates.map(template => (
                      <SelectItem key={template.id} value={template.id}>
                        {template.name}
                      </SelectItem>
                    ))}
                  </SelectContent>
                </Select>
                <Select
                  value={newCampaign.trigger}
                  onValueChange={(value: any) => setNewCampaign(prev => ({ ...prev, trigger: value }))}
                >
                  <SelectTrigger>
                    <SelectValue />
                  </SelectTrigger>
                  <SelectContent>
                    <SelectItem value="immediate">Immediate</SelectItem>
                    <SelectItem value="scheduled">Scheduled</SelectItem>
                    <SelectItem value="event_based">Event Based</SelectItem>
                  </SelectContent>
                </Select>
                {newCampaign.trigger === 'event_based' && (
                  <Input
                    placeholder="Event type"
                    value={newCampaign.event_type}
                    onChange={(e) => setNewCampaign(prev => ({ ...prev, event_type: e.target.value }))}
                  />
                )}
                <Button onClick={createCampaign} disabled={!newCampaign.name || !newCampaign.template_id}>
                  Create
                </Button>
              </div>
            </CardContent>
          </Card>

          <div className="space-y-2">
            {campaigns.map((campaign) => (
              <Card key={campaign.id}>
                <CardContent className="p-4">
                  <div className="flex items-center justify-between">
                    <div>
                      <h3 className="font-medium">{campaign.name}</h3>
                      <p className="text-sm text-muted-foreground">
                        Trigger: {campaign.trigger} • 
                        Sent: {campaign.sent_count} • 
                        Pending: {campaign.pending_count}
                      </p>
                    </div>
                    <Button
                      variant={campaign.status === 'active' ? 'default' : 'outline'}
                      size="sm"
                      onClick={() => toggleCampaign(campaign.id, campaign.status)}
                    >
                      {campaign.status === 'active' ? 'Pause' : 'Activate'}
                    </Button>
                  </div>
                </CardContent>
              </Card>
            ))}
          </div>
        </TabsContent>

        {/* Email Queue Tab */}
        <TabsContent value="queue" className="space-y-4">
          {queuedEmails.length === 0 ? (
            <Card>
              <CardContent className="text-center py-12">
                <Mail className="h-12 w-12 mx-auto mb-4 text-muted-foreground" />
                <h3 className="text-lg font-semibold mb-2">No Pending Emails</h3>
                <p className="text-muted-foreground">
                  All emails have been processed
                </p>
              </CardContent>
            </Card>
          ) : (
            <div className="space-y-2">
              {queuedEmails.map((email) => (
                <Card key={email.id}>
                  <CardContent className="p-4">
                    <div className="flex items-center justify-between">
                      <div>
                        <p className="font-medium">{email.to}</p>
                        <p className="text-sm text-muted-foreground">
                          Template: {templates.find(t => t.id === email.template_id)?.name} • 
                          Scheduled: {new Date(email.scheduled_for || '').toLocaleString()}
                        </p>
                      </div>
                      <Badge variant="secondary">Pending</Badge>
                    </div>
                  </CardContent>
                </Card>
              ))}
            </div>
          )}
        </TabsContent>

        {/* Template Editor Tab */}
        <TabsContent value="editor" className="space-y-4">
          <Card>
            <CardHeader>
              <CardTitle>{isEditing ? 'Edit Template' : 'Create Template'}</CardTitle>
            </CardHeader>
            <CardContent className="space-y-4">
              <div className="grid grid-cols-2 gap-4">
                <div>
                  <Label htmlFor="template-name">Template Name</Label>
                  <Input
                    id="template-name"
                    value={editingTemplate.name}
                    onChange={(e) => setEditingTemplate(prev => ({ ...prev, name: e.target.value }))}
                  />
                </div>
                <div>
                  <Label htmlFor="template-type">Type</Label>
                  <Select
                    value={editingTemplate.type}
                    onValueChange={(value: any) => setEditingTemplate(prev => ({ ...prev, type: value }))}
                  >
                    <SelectTrigger>
                      <SelectValue />
                    </SelectTrigger>
                    <SelectContent>
                      <SelectItem value="order_confirmation">Order Confirmation</SelectItem>
                      <SelectItem value="shipping">Shipping</SelectItem>
                      <SelectItem value="delivery">Delivery</SelectItem>
                      <SelectItem value="review_request">Review Request</SelectItem>
                      <SelectItem value="welcome">Welcome</SelectItem>
                      <SelectItem value="abandoned_cart">Abandoned Cart</SelectItem>
                      <SelectItem value="promotional">Promotional</SelectItem>
                    </SelectContent>
                  </Select>
                </div>
              </div>

              <div>
                <Label htmlFor="template-subject">Subject Line</Label>
                <Input
                  id="template-subject"
                  value={editingTemplate.subject}
                  onChange={(e) => setEditingTemplate(prev => ({ ...prev, subject: e.target.value }))}
                  placeholder="Email subject with {variables}"
                />
              </div>

              <div>
                <Label htmlFor="template-content">Email Content</Label>
                <Textarea
                  id="template-content"
                  value={editingTemplate.content}
                  onChange={(e) => setEditingTemplate(prev => ({ ...prev, content: e.target.value }))}
                  rows={12}
                  placeholder="Email content with {variables}"
                  className="font-mono"
                />
              </div>

              <div className="flex items-center justify-between">
                <div className="text-sm text-muted-foreground">
                  Variables: {extractVariables(editingTemplate.content).join(', ')}
                </div>
                
                <div className="flex items-center gap-2">
                  <Button variant="outline" onClick={() => {
                    setIsEditing(false);
                    setSelectedTemplate(null);
                  }}>
                    Cancel
                  </Button>
                  <Button onClick={saveTemplate}>
                    Save Template
                  </Button>
                </div>
              </div>
            </CardContent>
          </Card>

          {selectedTemplate && (
            <Card>
              <CardHeader>
                <CardTitle>Send Test Email</CardTitle>
              </CardHeader>
              <CardContent className="flex items-center gap-4">
                <Input
                  placeholder="test@example.com"
                  value={testEmail}
                  onChange={(e) => setTestEmail(e.target.value)}
                />
                <Button onClick={sendTestEmail} disabled={isSending}>
                  <Send className="h-4 w-4 mr-2" />
                  Send Test
                </Button>
              </CardContent>
            </Card>
          )}
        </TabsContent>
      </Tabs>
    </div>
  );
}