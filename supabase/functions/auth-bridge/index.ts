// supabase/functions/auth-bridge/index.ts
// Auth bridge: Verifies Privy token, upserts user_profiles, mints Supabase JWT
//
// Environment variables (set via `supabase secrets set`):
//   JWT_SECRET — project JWT secret (custom name; SUPABASE_ prefix reserved)
//   PRIVY_APP_ID — Privy application ID
//   PRIVY_APP_SECRET — Privy app secret for API calls (optional, used for verification fallback)
//   SUPABASE_SERVICE_ROLE_KEY — auto-provisioned, for upserting user_profiles (bypasses RLS)
//   SUPABASE_URL — auto-provisioned, project URL

import { serve } from "https://deno.land/std@0.177.0/http/server.ts";
import * as jose from "https://deno.land/x/jose@v5.2.0/index.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.39.0";

// CORS headers for development
const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

// Privy JWKS endpoint for token verification
const PRIVY_JWKS_URL = "https://auth.privy.io/api/v1/apps/";

interface AuthBridgeRequest {
  privy_token: string;
  wallet_address?: string;
  phone?: string;
}

interface AuthBridgeResponse {
  access_token: string;
  user_id: string;
  expires_at: number;
}

// Cache the JWKS key set
let cachedJWKS: jose.JWTVerifyGetKey | null = null;

async function getPrivyJWKS(appId: string): Promise<jose.JWTVerifyGetKey> {
  if (!cachedJWKS) {
    const jwksUrl = new URL(
      `https://auth.privy.io/api/v1/apps/${appId}/jwks.json`
    );
    cachedJWKS = jose.createRemoteJWKSet(jwksUrl);
  }
  return cachedJWKS;
}

async function verifyPrivyToken(
  token: string,
  appId: string
): Promise<{ sub: string; [key: string]: unknown }> {
  const jwks = await getPrivyJWKS(appId);

  const { payload } = await jose.jwtVerify(token, jwks, {
    issuer: "privy.io",
    audience: appId,
  });

  if (!payload.sub) {
    throw new Error("Privy token missing sub claim");
  }

  return payload as { sub: string; [key: string]: unknown };
}

async function mintSupabaseJWT(
  userId: string,
  jwtSecret: string
): Promise<{ token: string; expiresAt: number }> {
  const now = Math.floor(Date.now() / 1000);
  const exp = now + 3600; // 1 hour

  const secret = new TextEncoder().encode(jwtSecret);

  const token = await new jose.SignJWT({
    sub: userId,
    role: "authenticated",
    aud: "authenticated",
    iss: "supabase",
    iat: now,
    exp: exp,
  })
    .setProtectedHeader({ alg: "HS256", typ: "JWT" })
    .sign(secret);

  return { token, expiresAt: exp };
}

serve(async (req: Request) => {
  // Handle CORS preflight
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  if (req.method !== "POST") {
    return new Response(JSON.stringify({ error: "Method not allowed" }), {
      status: 405,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  }

  try {
    // Read environment variables
    const supabaseUrl = Deno.env.get("SUPABASE_URL");
    const serviceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");
    const jwtSecret = Deno.env.get("JWT_SECRET");
    const privyAppId = Deno.env.get("PRIVY_APP_ID");

    if (!supabaseUrl || !serviceRoleKey || !jwtSecret || !privyAppId) {
      console.error("Missing environment variables:", {
        hasSupabaseUrl: !!supabaseUrl,
        hasServiceRoleKey: !!serviceRoleKey,
        hasJwtSecret: !!jwtSecret, // JWT_SECRET env var
        hasPrivyAppId: !!privyAppId,
      });
      return new Response(
        JSON.stringify({ error: "Server configuration error" }),
        {
          status: 500,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        }
      );
    }

    // Parse request body
    const body: AuthBridgeRequest = await req.json();

    if (!body.privy_token) {
      return new Response(
        JSON.stringify({ error: "privy_token is required" }),
        {
          status: 400,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        }
      );
    }

    // Step 1: Verify the Privy token
    let privyUserId: string;
    try {
      const payload = await verifyPrivyToken(body.privy_token, privyAppId);
      privyUserId = payload.sub;
    } catch (err) {
      console.error("Privy token verification failed:", err);
      return new Response(
        JSON.stringify({
          error: "Invalid or expired Privy token",
          detail: err instanceof Error ? err.message : "Unknown error",
        }),
        {
          status: 401,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        }
      );
    }

    // Step 2: Upsert user_profiles using service_role client (bypasses RLS)
    const supabase = createClient(supabaseUrl, serviceRoleKey, {
      auth: {
        autoRefreshToken: false,
        persistSession: false,
      },
    });

    const { data: profile, error: upsertError } = await supabase
      .from("user_profiles")
      .upsert(
        {
          privy_user_id: privyUserId,
          phone: body.phone || null,
          wallet_address: body.wallet_address || null,
        },
        {
          onConflict: "privy_user_id",
        }
      )
      .select("id")
      .single();

    if (upsertError) {
      console.error("User profile upsert failed:", upsertError);

      // Check for unexpected conflict
      if (upsertError.code === "23505") {
        return new Response(
          JSON.stringify({
            error: "User profile conflict",
            detail: upsertError.message,
          }),
          {
            status: 409,
            headers: { ...corsHeaders, "Content-Type": "application/json" },
          }
        );
      }

      return new Response(
        JSON.stringify({
          error: "Failed to create user profile",
          detail: upsertError.message,
        }),
        {
          status: 500,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        }
      );
    }

    const userProfileId = profile.id;

    // Step 3: Mint a custom Supabase JWT with user_profiles.id as sub
    let supabaseToken: string;
    let expiresAt: number;
    try {
      const jwt = await mintSupabaseJWT(userProfileId, jwtSecret);
      supabaseToken = jwt.token;
      expiresAt = jwt.expiresAt;
    } catch (err) {
      console.error("JWT minting failed:", err);
      return new Response(
        JSON.stringify({
          error: "Failed to mint Supabase JWT",
          detail: err instanceof Error ? err.message : "Unknown error",
        }),
        {
          status: 500,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        }
      );
    }

    // Step 4: Return the access token, user ID, and expiry
    const response: AuthBridgeResponse = {
      access_token: supabaseToken,
      user_id: userProfileId,
      expires_at: expiresAt,
    };

    return new Response(JSON.stringify(response), {
      status: 200,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  } catch (err) {
    console.error("Unexpected error in auth-bridge:", err);
    return new Response(
      JSON.stringify({
        error: "Internal server error",
        detail: err instanceof Error ? err.message : "Unknown error",
      }),
      {
        status: 500,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      }
    );
  }
});
