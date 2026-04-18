// Supabase Edge Function: runs-ingest
// Deploy: supabase functions deploy runs-ingest

import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const SUPABASE_URL = Deno.env.get("SUPABASE_URL")!;
const SUPABASE_SERVICE_ROLE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
const INGEST_API_KEY = Deno.env.get("INGEST_API_KEY")!;
const INGEST_SIGNING_SECRET = Deno.env.get("INGEST_SIGNING_SECRET")!;

const supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY);

async function hmacSHA256Hex(secret: string, payload: string) {
  const key = await crypto.subtle.importKey(
    "raw",
    new TextEncoder().encode(secret),
    { name: "HMAC", hash: "SHA-256" },
    false,
    ["sign"],
  );
  const sig = await crypto.subtle.sign("HMAC", key, new TextEncoder().encode(payload));
  return [...new Uint8Array(sig)].map((b) => b.toString(16).padStart(2, "0")).join("");
}

Deno.serve(async (req) => {
  if (req.method !== "POST") {
    return new Response(JSON.stringify({ ok: false, error: "method_not_allowed" }), { status: 405 });
  }

  const apiKey = req.headers.get("x-api-key") || "";
  if (apiKey !== INGEST_API_KEY) {
    return new Response(JSON.stringify({ ok: false, error: "unauthorized" }), { status: 401 });
  }

  const raw = await req.text();
  const gotSig = (req.headers.get("x-signature") || "").toLowerCase();
  const expected = await hmacSHA256Hex(INGEST_SIGNING_SECRET, raw);
  if (gotSig !== expected) {
    return new Response(JSON.stringify({ ok: false, error: "bad_signature" }), { status: 401 });
  }

  let body: any;
  try {
    body = JSON.parse(raw);
  } catch {
    return new Response(JSON.stringify({ ok: false, error: "invalid_json" }), { status: 400 });
  }

  const required = ["external_run_id", "started_at", "ended_at", "distance_m", "moving_time_s"];
  for (const field of required) {
    if (body[field] === undefined || body[field] === null || body[field] === "") {
      return new Response(JSON.stringify({ ok: false, error: `missing_${field}` }), { status: 400 });
    }
  }

  const row = {
    external_run_id: body.external_run_id,
    source: "apple_health",
    started_at: body.started_at,
    ended_at: body.ended_at,
    distance_m: body.distance_m,
    moving_time_s: body.moving_time_s,
    elevation_gain_m: body.elevation_gain_m ?? null,
    avg_hr: body.avg_hr ?? null,
    max_hr: body.max_hr ?? null,
    cadence_avg: body.cadence_avg ?? null,
    splits_json: body.splits ?? null,
    raw_payload: body,
  };

  const { data, error } = await supabase
    .from("run_sessions")
    .upsert(row, { onConflict: "external_run_id" })
    .select("id")
    .single();

  if (error) {
    return new Response(JSON.stringify({ ok: false, error: "db_error", detail: error.message }), { status: 500 });
  }

  return new Response(JSON.stringify({ ok: true, id: data.id }), {
    status: 200,
    headers: { "content-type": "application/json" },
  });
});
