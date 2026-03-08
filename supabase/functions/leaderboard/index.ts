// supabase/functions/leaderboard/index.ts
// Leaderboard endpoint: Returns ranked users by streaks, consistency, or total staked.
//
// GET /functions/v1/leaderboard?type=streaks&limit=50
// GET /functions/v1/leaderboard?type=consistency&limit=50&period=30
// GET /functions/v1/leaderboard?type=staked&limit=50
//
// Environment variables (auto-provisioned by Supabase):
//   SUPABASE_URL — project URL
//   SUPABASE_SERVICE_ROLE_KEY — service role key (bypasses RLS)

import { serve } from "https://deno.land/std@0.177.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.39.0";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "GET, OPTIONS",
};

interface LeaderboardEntry {
  rank: number;
  user_id: string;
  username: string;
  display_name: string | null;
  avatar_url: string | null;
  value: number;
  label: string;
}

interface LeaderboardResponse {
  type: string;
  entries: LeaderboardEntry[];
}

serve(async (req: Request) => {
  // Handle CORS preflight
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  if (req.method !== "GET") {
    return new Response(JSON.stringify({ error: "Method not allowed" }), {
      status: 405,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  }

  try {
    const supabaseUrl = Deno.env.get("SUPABASE_URL");
    const serviceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");

    if (!supabaseUrl || !serviceRoleKey) {
      return new Response(
        JSON.stringify({ error: "Server configuration error" }),
        {
          status: 500,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        }
      );
    }

    // Parse query parameters
    const url = new URL(req.url);
    const type = url.searchParams.get("type") || "streaks";
    const limit = Math.min(parseInt(url.searchParams.get("limit") || "50"), 100);
    const period = Math.min(
      parseInt(url.searchParams.get("period") || "30"),
      365
    );

    if (!["streaks", "consistency", "staked"].includes(type)) {
      return new Response(
        JSON.stringify({
          error: "Invalid type. Must be: streaks, consistency, or staked",
        }),
        {
          status: 400,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        }
      );
    }

    // Create service role client (bypasses RLS for cross-user queries)
    const supabase = createClient(supabaseUrl, serviceRoleKey, {
      auth: {
        autoRefreshToken: false,
        persistSession: false,
      },
    });

    let entries: LeaderboardEntry[] = [];

    if (type === "streaks") {
      entries = await fetchStreaksLeaderboard(supabase, limit);
    } else if (type === "consistency") {
      entries = await fetchConsistencyLeaderboard(supabase, limit, period);
    } else if (type === "staked") {
      entries = await fetchStakedLeaderboard(supabase, limit);
    }

    const response: LeaderboardResponse = { type, entries };

    return new Response(JSON.stringify(response), {
      status: 200,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  } catch (err) {
    console.error("Leaderboard error:", err);
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

// MARK: - Streaks Leaderboard

async function fetchStreaksLeaderboard(
  supabase: ReturnType<typeof createClient>,
  limit: number
): Promise<LeaderboardEntry[]> {
  // Use RPC or raw query via the existing leaderboard view for simplicity,
  // or query habits + user_profiles directly
  const { data, error } = await supabase
    .from("habits")
    .select(
      `
      current_streak,
      user_id,
      user_profiles!inner (
        id,
        username,
        display_name,
        avatar_url
      )
    `
    )
    .eq("is_active", true)
    .not("user_profiles.username", "is", null)
    .order("current_streak", { ascending: false })
    .limit(limit * 3); // Fetch more since we need to group by user

  if (error) {
    console.error("Streaks query error:", error);
    throw new Error(error.message);
  }

  // Group by user, take max streak per user
  const userMap = new Map<
    string,
    {
      user_id: string;
      username: string;
      display_name: string | null;
      avatar_url: string | null;
      best_streak: number;
      active_habits: number;
    }
  >();

  for (const row of data || []) {
    const profile = (row as any).user_profiles;
    if (!profile?.username) continue;

    const userId = profile.id;
    const existing = userMap.get(userId);

    if (existing) {
      existing.best_streak = Math.max(
        existing.best_streak,
        row.current_streak
      );
      existing.active_habits += 1;
    } else {
      userMap.set(userId, {
        user_id: userId,
        username: profile.username,
        display_name: profile.display_name,
        avatar_url: profile.avatar_url,
        best_streak: row.current_streak,
        active_habits: 1,
      });
    }
  }

  // Sort by best streak descending
  const sorted = Array.from(userMap.values())
    .sort((a, b) => b.best_streak - a.best_streak)
    .slice(0, limit);

  return sorted.map((u, i) => ({
    rank: i + 1,
    user_id: u.user_id,
    username: u.username,
    display_name: u.display_name,
    avatar_url: u.avatar_url,
    value: u.best_streak,
    label:
      u.best_streak === 1
        ? "1 day streak"
        : `${u.best_streak} day streak`,
  }));
}

// MARK: - Consistency Leaderboard

async function fetchConsistencyLeaderboard(
  supabase: ReturnType<typeof createClient>,
  limit: number,
  period: number
): Promise<LeaderboardEntry[]> {
  // Calculate the start date
  const startDate = new Date();
  startDate.setDate(startDate.getDate() - period);
  const startDateStr = startDate.toISOString().split("T")[0];

  const { data, error } = await supabase
    .from("habit_logs")
    .select(
      `
      status,
      user_id,
      user_profiles!inner (
        id,
        username,
        display_name,
        avatar_url
      )
    `
    )
    .gte("log_date", startDateStr)
    .not("user_profiles.username", "is", null);

  if (error) {
    console.error("Consistency query error:", error);
    throw new Error(error.message);
  }

  // Group by user, calculate consistency rate
  const userMap = new Map<
    string,
    {
      user_id: string;
      username: string;
      display_name: string | null;
      avatar_url: string | null;
      total_logs: number;
      verified_count: number;
    }
  >();

  for (const row of data || []) {
    const profile = (row as any).user_profiles;
    if (!profile?.username) continue;

    const userId = profile.id;
    const existing = userMap.get(userId);

    if (existing) {
      existing.total_logs += 1;
      if (row.status === "verified") existing.verified_count += 1;
    } else {
      userMap.set(userId, {
        user_id: userId,
        username: profile.username,
        display_name: profile.display_name,
        avatar_url: profile.avatar_url,
        total_logs: 1,
        verified_count: row.status === "verified" ? 1 : 0,
      });
    }
  }

  // Calculate rate and sort
  const sorted = Array.from(userMap.values())
    .map((u) => ({
      ...u,
      rate: u.total_logs > 0 ? u.verified_count / u.total_logs : 0,
    }))
    .filter((u) => u.total_logs > 0)
    .sort((a, b) => b.rate - a.rate || b.verified_count - a.verified_count)
    .slice(0, limit);

  return sorted.map((u, i) => ({
    rank: i + 1,
    user_id: u.user_id,
    username: u.username,
    display_name: u.display_name,
    avatar_url: u.avatar_url,
    value: Math.round(u.rate * 100),
    label: `${Math.round(u.rate * 100)}% consistency`,
  }));
}

// MARK: - Staked (Invested) Leaderboard

async function fetchStakedLeaderboard(
  supabase: ReturnType<typeof createClient>,
  limit: number
): Promise<LeaderboardEntry[]> {
  const { data, error } = await supabase
    .from("habit_logs")
    .select(
      `
      invested_amount,
      status,
      user_id,
      user_profiles!inner (
        id,
        username,
        display_name,
        avatar_url,
        investment_pool_balance
      )
    `
    )
    .eq("status", "failed")
    .not("user_profiles.username", "is", null);

  if (error) {
    console.error("Staked query error:", error);
    throw new Error(error.message);
  }

  // Group by user, sum invested amounts
  const userMap = new Map<
    string,
    {
      user_id: string;
      username: string;
      display_name: string | null;
      avatar_url: string | null;
      total_invested: number;
    }
  >();

  for (const row of data || []) {
    const profile = (row as any).user_profiles;
    if (!profile?.username) continue;

    const userId = profile.id;
    const existing = userMap.get(userId);
    const amount = row.invested_amount || 0;

    if (existing) {
      existing.total_invested += amount;
    } else {
      userMap.set(userId, {
        user_id: userId,
        username: profile.username,
        display_name: profile.display_name,
        avatar_url: profile.avatar_url,
        total_invested: amount,
      });
    }
  }

  // Sort by total invested descending
  const sorted = Array.from(userMap.values())
    .sort((a, b) => b.total_invested - a.total_invested)
    .slice(0, limit);

  return sorted.map((u, i) => ({
    rank: i + 1,
    user_id: u.user_id,
    username: u.username,
    display_name: u.display_name,
    avatar_url: u.avatar_url,
    value: Math.round(u.total_invested * 100) / 100,
    label: `$${u.total_invested.toFixed(0)} invested`,
  }));
}
