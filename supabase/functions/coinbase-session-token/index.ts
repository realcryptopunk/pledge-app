import { serve } from "https://deno.land/std@0.208.0/http/server.ts";

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

// MARK: - Helper: Base64URL encode

function b64url(data: Uint8Array): string {
  const b64 = btoa(String.fromCharCode(...data));
  return b64.replace(/\+/g, "-").replace(/\//g, "_").replace(/=+$/, "");
}

function strToB64url(str: string): string {
  return b64url(new TextEncoder().encode(str));
}

// MARK: - Helper: Build Ed25519 PKCS#8 DER from 32-byte seed

function ed25519SeedToPkcs8(seed: Uint8Array): Uint8Array {
  // PKCS#8 structure for Ed25519:
  // SEQUENCE { version=0, AlgorithmIdentifier(Ed25519 OID), OCTET_STRING(OCTET_STRING(seed)) }
  const prefix = new Uint8Array([
    0x30, 0x2e,             // SEQUENCE (46 bytes)
    0x02, 0x01, 0x00,       // INTEGER version = 0
    0x30, 0x05,             // SEQUENCE (AlgorithmIdentifier)
    0x06, 0x03, 0x2b, 0x65, 0x70, // OID 1.3.101.112 (Ed25519)
    0x04, 0x22,             // OCTET STRING (34 bytes)
    0x04, 0x20,             // OCTET STRING (32 bytes = seed)
  ]);
  const result = new Uint8Array(prefix.length + 32);
  result.set(prefix, 0);
  result.set(seed.slice(0, 32), prefix.length);
  return result;
}

// MARK: - Helper: Build SEC1 EC → PKCS#8 DER (for P-256 legacy keys)

function sec1DerToPkcs8Der(sec1Der: Uint8Array): Uint8Array {
  const algId = new Uint8Array([
    0x30, 0x13,
    0x06, 0x07, 0x2a, 0x86, 0x48, 0xce, 0x3d, 0x02, 0x01,
    0x06, 0x08, 0x2a, 0x86, 0x48, 0xce, 0x3d, 0x03, 0x01, 0x07,
  ]);
  const version = new Uint8Array([0x02, 0x01, 0x00]);
  const octetLen = sec1Der.length;
  const octet = octetLen < 128
    ? new Uint8Array([0x04, octetLen, ...sec1Der])
    : new Uint8Array([0x04, 0x81, octetLen, ...sec1Der]);
  const inner = new Uint8Array(version.length + algId.length + octet.length);
  inner.set(version, 0);
  inner.set(algId, version.length);
  inner.set(octet, version.length + algId.length);
  const innerLen = inner.length;
  if (innerLen < 128) {
    const result = new Uint8Array(2 + innerLen);
    result[0] = 0x30;
    result[1] = innerLen;
    result.set(inner, 2);
    return result;
  } else {
    const result = new Uint8Array(3 + innerLen);
    result[0] = 0x30;
    result[1] = 0x81;
    result[2] = innerLen;
    result.set(inner, 3);
    return result;
  }
}

// MARK: - Key import: detect format and return { key, algorithm }

interface ImportedKey {
  key: CryptoKey;
  alg: "ES256" | "EdDSA";
}

async function importCdpKey(keySecret: string): Promise<ImportedKey> {
  const cleaned = keySecret.replace(/\\n/g, "\n").trim();

  // PEM format → ECDSA / ES256
  if (cleaned.includes("-----BEGIN")) {
    const b64 = cleaned
      .replace(/-----BEGIN[^-]+-----/g, "")
      .replace(/-----END[^-]+-----/g, "")
      .replace(/\s/g, "");
    const der = Uint8Array.from(atob(b64), (c) => c.charCodeAt(0));

    let pkcs8: Uint8Array;
    if (cleaned.includes("EC PRIVATE KEY")) {
      pkcs8 = sec1DerToPkcs8Der(der);
    } else {
      pkcs8 = der; // Already PKCS#8
    }

    const key = await crypto.subtle.importKey(
      "pkcs8", pkcs8,
      { name: "ECDSA", namedCurve: "P-256" },
      false, ["sign"],
    );
    return { key, alg: "ES256" };
  }

  // Raw base64 → Ed25519 / EdDSA (newer CDP key format)
  const raw = Uint8Array.from(atob(cleaned), (c) => c.charCodeAt(0));

  if (raw.length === 64 || raw.length === 32) {
    // 64 bytes = seed (32) + public key (32), or 32 bytes = just seed
    const seed = raw.slice(0, 32);
    const pkcs8 = ed25519SeedToPkcs8(seed);
    const key = await crypto.subtle.importKey(
      "pkcs8", pkcs8,
      "Ed25519",
      false, ["sign"],
    );
    return { key, alg: "EdDSA" };
  }

  // Raw DER (starts with 0x30 SEQUENCE tag) → try ECDSA
  if (raw[0] === 0x30) {
    try {
      const key = await crypto.subtle.importKey(
        "pkcs8", raw,
        { name: "ECDSA", namedCurve: "P-256" },
        false, ["sign"],
      );
      return { key, alg: "ES256" };
    } catch {
      const pkcs8 = sec1DerToPkcs8Der(raw);
      const key = await crypto.subtle.importKey(
        "pkcs8", pkcs8,
        { name: "ECDSA", namedCurve: "P-256" },
        false, ["sign"],
      );
      return { key, alg: "ES256" };
    }
  }

  throw new Error("Unrecognized CDP_API_KEY_SECRET format");
}

// MARK: - Sign JWT with imported key

async function signJwt(
  importedKey: ImportedKey,
  kid: string,
  requestUri: string,
): Promise<string> {
  const now = Math.floor(Date.now() / 1000);
  const nonce = randomHex(16);

  // Newer Ed25519 keys use "cdp" issuer and "cdp_service" audience
  // Legacy EC keys use "coinbase-cloud" issuer and "retail_rest_api_proxy" audience
  const isLegacy = importedKey.alg === "ES256";

  const header = {
    alg: importedKey.alg,
    kid: kid,
    typ: "JWT",
    nonce: nonce,
  };

  const payload: Record<string, unknown> = {
    sub: kid,
    iss: isLegacy ? "coinbase-cloud" : "cdp",
    aud: isLegacy ? ["retail_rest_api_proxy"] : ["cdp_service"],
    nbf: now,
    exp: now + 120,
  };

  // Newer keys use "uri" (singular), legacy uses "uris" (array)
  if (isLegacy) {
    payload.uris = [];
  } else {
    payload.uri = requestUri;
  }

  const headerB64 = strToB64url(JSON.stringify(header));
  const payloadB64 = strToB64url(JSON.stringify(payload));
  const signingInput = new TextEncoder().encode(`${headerB64}.${payloadB64}`);

  let signature: ArrayBuffer;
  if (importedKey.alg === "ES256") {
    signature = await crypto.subtle.sign(
      { name: "ECDSA", hash: "SHA-256" },
      importedKey.key,
      signingInput,
    );
  } else {
    signature = await crypto.subtle.sign(
      "Ed25519",
      importedKey.key,
      signingInput,
    );
  }

  const sigB64 = b64url(new Uint8Array(signature));
  return `${headerB64}.${payloadB64}.${sigB64}`;
}

// MARK: - Main Handler

serve(async (req: Request) => {
  if (req.method === "OPTIONS") {
    return new Response(null, { status: 204, headers: corsHeaders });
  }

  if (req.method !== "POST") {
    return new Response(
      JSON.stringify({ error: "Method not allowed" }),
      { status: 405, headers: { ...corsHeaders, "Content-Type": "application/json" } }
    );
  }

  try {
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

    const cdpKeyName = Deno.env.get("CDP_API_KEY_NAME");
    const cdpKeySecret = Deno.env.get("CDP_API_KEY_SECRET");

    if (!cdpKeyName || !cdpKeySecret) {
      return new Response(
        JSON.stringify({ error: "Server configuration error: CDP credentials not set" }),
        { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    const importedKey = await importCdpKey(cdpKeySecret);
    const jwt = await signJwt(
      importedKey,
      cdpKeyName,
      "POST api.developer.coinbase.com/onramp/v1/token",
    );

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
            { address: wallet_address, blockchains: ["base"] },
          ],
        }),
      }
    );

    if (!coinbaseResponse.ok) {
      const errorText = await coinbaseResponse.text();
      console.error(`Coinbase API error: ${coinbaseResponse.status} — ${errorText}`);
      return new Response(
        JSON.stringify({
          error: "Failed to generate session token from Coinbase",
          details: errorText,
          status: coinbaseResponse.status,
        }),
        { status: 502, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    const coinbaseData = await coinbaseResponse.json();
    const token = coinbaseData.token;

    if (!token) {
      return new Response(
        JSON.stringify({
          error: "Coinbase response did not contain a session token",
          details: JSON.stringify(coinbaseData),
        }),
        { status: 502, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    return new Response(
      JSON.stringify({ token }),
      { status: 200, headers: { ...corsHeaders, "Content-Type": "application/json" } }
    );
  } catch (err) {
    console.error("Unexpected error:", err);
    return new Response(
      JSON.stringify({
        error: "Internal server error",
        message: err instanceof Error ? err.message : String(err),
      }),
      { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } }
    );
  }
});
