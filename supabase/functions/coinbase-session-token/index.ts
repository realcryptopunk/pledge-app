import { serve } from "https://deno.land/std@0.208.0/http/server.ts";
import { SignJWT, importPKCS8 } from "https://deno.land/x/jose@v5.2.0/index.ts";

// MARK: - CORS Headers

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
  "Access-Control-Allow-Headers": "Authorization, Content-Type, apikey, x-client-info",
};

// MARK: - Helper: Generate random hex nonce

function randomHex(bytes: number): string {
  const arr = new Uint8Array(bytes);
  crypto.getRandomValues(arr);
  return Array.from(arr)
    .map((b) => b.toString(16).padStart(2, "0"))
    .join("");
}

// MARK: - Main Handler

serve(async (req: Request) => {
  // Handle CORS preflight
  if (req.method === "OPTIONS") {
    return new Response(null, { status: 204, headers: corsHeaders });
  }

  // Only accept POST
  if (req.method !== "POST") {
    return new Response(
      JSON.stringify({ error: "Method not allowed" }),
      { status: 405, headers: { ...corsHeaders, "Content-Type": "application/json" } }
    );
  }

  try {
    // MARK: - Parse request body
    const body = await req.json();
    const { wallet_address, amount } = body;

    if (!wallet_address || typeof wallet_address !== "string") {
      return new Response(
        JSON.stringify({ error: "Missing or invalid wallet_address" }),
        { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    if (amount !== undefined && (typeof amount !== "number" || amount <= 0)) {
      return new Response(
        JSON.stringify({ error: "Invalid amount — must be a positive number" }),
        { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    // MARK: - Load CDP credentials from environment
    const cdpKeyName = Deno.env.get("CDP_API_KEY_NAME");
    const cdpKeySecret = Deno.env.get("CDP_API_KEY_SECRET");

    if (!cdpKeyName || !cdpKeySecret) {
      console.error("Missing CDP_API_KEY_NAME or CDP_API_KEY_SECRET environment variables");
      return new Response(
        JSON.stringify({ error: "Server configuration error: CDP credentials not set" }),
        { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    // MARK: - Build and sign JWT for Coinbase API
    const now = Math.floor(Date.now() / 1000);
    const nonce = randomHex(16);

    // Import the EC private key (PEM format, PKCS8)
    const privateKey = await importPKCS8(cdpKeySecret, "ES256");

    const jwt = await new SignJWT({
      sub: cdpKeyName,
      iss: "coinbase-cloud",
      aud: ["retail_rest_api_proxy"],
      nbf: now,
      exp: now + 300, // 5 minutes
      uris: [],
    })
      .setProtectedHeader({
        alg: "ES256",
        kid: cdpKeyName,
        typ: "JWT",
        nonce: nonce,
      })
      .sign(privateKey);

    // MARK: - Request session token from Coinbase
    const coinbaseResponse = await fetch(
      "https://api.developer.coinbase.com/onramp/v1/token",
      {
        method: "POST",
        headers: {
          Authorization: `Bearer ${jwt}`,
          "Content-Type": "application/json",
        },
        body: JSON.stringify({
          destination_wallets: [
            {
              address: wallet_address,
              blockchains: ["base"],
            },
          ],
        }),
      }
    );

    if (!coinbaseResponse.ok) {
      const errorText = await coinbaseResponse.text();
      console.error(
        `Coinbase API error: ${coinbaseResponse.status} — ${errorText}`
      );
      return new Response(
        JSON.stringify({
          error: "Failed to generate session token from Coinbase",
          details: errorText,
          status: coinbaseResponse.status,
        }),
        {
          status: 502,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        }
      );
    }

    const coinbaseData = await coinbaseResponse.json();
    const token = coinbaseData.token;

    if (!token) {
      console.error("Coinbase response missing token field:", coinbaseData);
      return new Response(
        JSON.stringify({
          error: "Coinbase response did not contain a session token",
          details: JSON.stringify(coinbaseData),
        }),
        {
          status: 502,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        }
      );
    }

    // MARK: - Return token to client
    return new Response(
      JSON.stringify({ token }),
      {
        status: 200,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      }
    );
  } catch (err) {
    console.error("Unexpected error:", err);
    return new Response(
      JSON.stringify({
        error: "Internal server error",
        message: err instanceof Error ? err.message : String(err),
      }),
      {
        status: 500,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      }
    );
  }
});
