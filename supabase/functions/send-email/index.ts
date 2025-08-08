import { serve } from "https://deno.land/std@0.190.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.45.0";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};

interface EmailRequest {
  to: string | string[];
  subject: string;
  html: string;
  text?: string;
  from?: string;
  cc?: string[];
  bcc?: string[];
  replyTo?: string;
  attachments?: Array<{
    filename: string;
    content: string;
    contentType?: string;
  }>;
}

serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response(null, { headers: corsHeaders });
  }

  try {
    const RESEND_API_KEY = Deno.env.get("RESEND_API_KEY");
    
    if (!RESEND_API_KEY) {
      console.error("RESEND_API_KEY is not configured");
      throw new Error("Email service not configured");
    }

    const emailRequest: EmailRequest = await req.json();

    // Validate required fields
    if (!emailRequest.to || !emailRequest.subject || !emailRequest.html) {
      throw new Error("Missing required fields: to, subject, html");
    }

    // Prepare Resend API request
    const resendPayload = {
      from: emailRequest.from || "KCT Menswear <noreply@kctmenswear.com>",
      to: emailRequest.to,
      subject: emailRequest.subject,
      html: emailRequest.html,
      text: emailRequest.text,
      cc: emailRequest.cc,
      bcc: emailRequest.bcc,
      reply_to: emailRequest.replyTo,
      attachments: emailRequest.attachments
    };

    // Send email via Resend API
    const response = await fetch("https://api.resend.com/emails", {
      method: "POST",
      headers: {
        "Authorization": `Bearer ${RESEND_API_KEY}`,
        "Content-Type": "application/json",
      },
      body: JSON.stringify(resendPayload),
    });

    const data = await response.json();

    if (!response.ok) {
      console.error("Resend API error:", data);
      throw new Error(data.message || "Failed to send email");
    }

    // Log email in database
    const supabase = createClient(
      Deno.env.get("SUPABASE_URL") ?? "",
      Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? ""
    );

    await supabase.from("email_logs").insert({
      to: Array.isArray(emailRequest.to) ? emailRequest.to.join(", ") : emailRequest.to,
      subject: emailRequest.subject,
      status: "sent",
      resend_id: data.id,
      created_at: new Date().toISOString(),
    });

    return new Response(JSON.stringify({ 
      success: true, 
      id: data.id,
      message: "Email sent successfully" 
    }), {
      headers: { ...corsHeaders, "Content-Type": "application/json" },
      status: 200,
    });

  } catch (error) {
    console.error("Email error:", error);
    
    return new Response(JSON.stringify({ 
      success: false,
      error: error.message 
    }), {
      headers: { ...corsHeaders, "Content-Type": "application/json" },
      status: 500,
    });
  }
});