// netlify/functions/db.js
//
// Secure Supabase proxy. Credentials never reach the browser.
// Optimised for high-frequency concurrent use (6-7 operators).

const SUPABASE_URL = process.env.SUPABASE_URL;
const SUPABASE_KEY = process.env.SUPABASE_KEY;

// Reuse HTTPS agent across invocations within the same Lambda instance.
// Eliminates TCP/TLS handshake on every request — biggest latency win.
const https = require("https");
const agent = new https.Agent({ keepAlive: true, maxSockets: 20 });

const BASE_HEADERS = {
  "Content-Type":  "application/json",
  "apikey":        SUPABASE_KEY,
  "Authorization": "Bearer " + SUPABASE_KEY,
};

const ALLOWED_TABLES = ["members", "tokens", "logs", "app_users", "counter_allocations", "allocation_log", "event_settings"];

async function query(method, path, body, extra = {}) {
  const url = `${SUPABASE_URL}/rest/v1/${path}`;
  const res = await fetch(url, {
    method,
    headers: { ...BASE_HEADERS, ...extra },
    body: body != null ? JSON.stringify(body) : undefined,
    agent,
  });
  const text = await res.text();
  const data = text ? JSON.parse(text) : null;
  if (!res.ok) {
    const msg = (data && data.message) ? data.message : text;
    const err = new Error(msg);
    err.status = res.status;
    throw err;
  }
  return data;
}

const CORS = {
  "Access-Control-Allow-Origin":  "*",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
  "Access-Control-Allow-Headers": "Content-Type",
};

exports.handler = async (event) => {
  if (event.httpMethod === "OPTIONS") return { statusCode: 204, headers: CORS };
  if (event.httpMethod !== "POST") {
    return { statusCode: 405, headers: CORS, body: JSON.stringify({ error: "Method not allowed" }) };
  }

  let payload;
  try { payload = JSON.parse(event.body); }
  catch { return { statusCode: 400, headers: CORS, body: JSON.stringify({ error: "Invalid JSON" }) }; }

  const { op, table, qs, body, patch, match } = payload;

  if (!ALLOWED_TABLES.includes(table)) {
    return { statusCode: 403, headers: CORS, body: JSON.stringify({ error: "Table not allowed" }) };
  }

  try {
    let result;

    if (op === "select") {
      result = await query("GET", `${table}?${qs || ""}`);
    }
    else if (op === "insert") {
      result = await query("POST", table, body, { Prefer: "return=representation" });
      if (Array.isArray(result)) result = result.length ? result[0] : null;
    }
    else if (op === "upsert") {
      result = await query("POST", table, body, {
        Prefer: "return=representation,resolution=merge-duplicates"
      });
      if (Array.isArray(result)) result = result.length ? result[0] : null;
    }
    else if (op === "update") {
      const q = Object.entries(match).map(([k,v])=>`${k}=eq.${encodeURIComponent(v)}`).join("&");
      result = await query("PATCH", `${table}?${q}`, patch, { Prefer: "return=representation" });
      if (Array.isArray(result)) result = result.length ? result[0] : null;
    }
    else if (op === "del") {
      const q = Object.entries(match).map(([k,v])=>`${k}=eq.${encodeURIComponent(v)}`).join("&");
      await query("DELETE", `${table}?${q}`);
      result = null;
    }
    else {
      return { statusCode: 400, headers: CORS, body: JSON.stringify({ error: "Unknown op" }) };
    }

    return {
      statusCode: 200,
      headers: { ...CORS, "Cache-Control": "no-store" },
      body: JSON.stringify({ data: result }),
    };

  } catch (err) {
    return {
      statusCode: err.status || 500,
      headers: CORS,
      body: JSON.stringify({ error: err.message || String(err) }),
    };
  }
};
