// supabase/functions/gemini-proxy/index.ts
// Proxies photo verification requests to Google Gemini API.
// Keeps the Gemini API key server-side (never exposed in iOS source).
//
// Environment variables (set via `supabase secrets set`):
//   GEMINI_API_KEY — Google Gemini API key for vision model access
//
// NOTE: The API key was previously hardcoded in iOS source. After deploying
// this proxy, rotate the key in Google Cloud Console:
// https://aistudio.google.com/apikey

import { serve } from "https://deno.land/std@0.177.0/http/server.ts";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

const GEMINI_ENDPOINT =
  "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent";

interface GeminiProxyRequest {
  image_base64: string;
  habit_type: string;
}

/**
 * Builds the verification prompt based on the habit type.
 * Ported from iOS PhotoVerificationService.buildPrompt(for:).
 */
function buildPrompt(habitType: string): string {
  let habitClues: string;

  switch (habitType) {
    case "coldShower":
      habitClues = `The user claims they just took a COLD SHOWER. Look for:
- Person near/in a shower or bathroom
- Wet hair, water droplets on skin
- Fogged mirror, towel, shower stall visible
- Post-shower appearance (damp skin, wet clothing/towel)`;
      break;

    case "meditate":
      habitClues = `The user claims they are MEDITATING. Look for:
- Person sitting in calm/cross-legged position
- Meditation cushion, yoga mat, quiet space
- Eyes closed, relaxed posture
- Meditation app on screen, candles, incense`;
      break;

    case "journal":
      habitClues = `The user claims they are JOURNALING. Look for:
- Open notebook, journal, or diary
- Pen/pencil in hand or nearby
- Handwriting visible on page
- Writing desk setup`;
      break;

    case "read":
      habitClues = `The user claims they are READING. Look for:
- Book, e-reader (Kindle), or tablet with text
- Person holding/looking at reading material
- Reading posture (sitting, lying down with book)
- Visible text on pages`;
      break;

    default:
      habitClues =
        "The user claims they completed a habit. Look for any evidence of the activity.";
      break;
  }

  return `You are a habit verification AI for the Pledge app. Analyze this photo to verify if the user is actually doing their habit.

${habitClues}

RULES:
- Be reasonably lenient — this isn't a court of law. If it looks plausible, verify it.
- The photo is taken in-the-moment (like BeReal), so it may be slightly blurry or poorly framed.
- Look for contextual clues, not perfection.
- If the photo is completely unrelated (e.g., a screenshot, random object, black screen), reject it.

Respond in EXACTLY this JSON format, nothing else:
{"verified": true/false, "confidence": 0.0-1.0, "reason": "one short sentence"}`;
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
    const geminiApiKey = Deno.env.get("GEMINI_API_KEY");

    if (!geminiApiKey) {
      console.error("Missing GEMINI_API_KEY environment variable");
      return new Response(
        JSON.stringify({ error: "Server configuration error" }),
        {
          status: 500,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        }
      );
    }

    // Parse request body
    const body: GeminiProxyRequest = await req.json();

    if (!body.image_base64 || !body.habit_type) {
      return new Response(
        JSON.stringify({
          error: "image_base64 and habit_type are required",
        }),
        {
          status: 400,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        }
      );
    }

    // Build the prompt server-side based on habit type
    const prompt = buildPrompt(body.habit_type);

    // Build Gemini API request (same format as the iOS client previously used)
    const geminiRequest = {
      contents: [
        {
          parts: [
            { text: prompt },
            {
              inlineData: {
                mimeType: "image/jpeg",
                data: body.image_base64,
              },
            },
          ],
        },
      ],
      generationConfig: {
        temperature: 0.1,
        maxOutputTokens: 256,
      },
    };

    // Forward to Gemini API
    const geminiUrl = `${GEMINI_ENDPOINT}?key=${geminiApiKey}`;
    const geminiResponse = await fetch(geminiUrl, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify(geminiRequest),
    });

    if (!geminiResponse.ok) {
      const errorText = await geminiResponse.text();
      console.error(
        `Gemini API error (${geminiResponse.status}): ${errorText}`
      );
      return new Response(
        JSON.stringify({
          error: "Gemini API request failed",
          status: geminiResponse.status,
        }),
        {
          status: 502,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        }
      );
    }

    // Return the Gemini response as-is (iOS client parses the same format)
    const geminiData = await geminiResponse.json();

    return new Response(JSON.stringify(geminiData), {
      status: 200,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  } catch (err) {
    console.error("Unexpected error in gemini-proxy:", err);
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
