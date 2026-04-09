// netlify/functions/db.js
//
// Secure proxy between the frontend and Supabase.
// SUPABASE_URL and SUPABASE_KEY are read from Netlify environment
// variables — they are NEVER sent to the browser.

const SUPABASE_URL = process.env.SUPABASE_URL;
const SUPABASE_KEY = process.env.SUPABASE_KEY;

const headers = {
  "Content-Type": "application/json",
  "apikey": SUPABASE_KEY,
  "Authorization": "Bearer " + SUPABASE_KEY,
};

exports.handler = async (event) => {
  // Only allow POST
  if (event.httpMethod !== "POST") {
    return { statusCode: 405, body: JSON.stringify({ error: "Method not allowed" }) };
  }

  let payload;
  try {
    payload = JSON.parse(event.body);
  } catch {
    return { statusCode: 400, body: JSON.stringify({ error: "Invalid JSON" }) };
  }

  const { op, table, qs, body, patch, match } = payload;

  // Whitelist allowed tables — extra safety layer
  const ALLOWED_TABLES = ["members", "tokens", "logs", "app_users"];
  if (!ALLOWED_TABLES.includes(table)) {
    return { statusCode: 403, body: JSON.stringify({ error: "Table not allowed" }) };
  }

  const base = `${SUPABASE_URL}/rest/v1/${table}`;

  try {
    let res;

    if (op === "select") {
      res = await fetch(`${base}?${qs || ""}`, { headers });
    }

    else if (op === "insert") {
      res = await fetch(base, {
        method: "POST",
        headers: { ...headers, Prefer: "return=representation" },
        body: JSON.stringify(body),
      });
    }

    else if (op === "update") {
      const q = Object.entries(match)
        .map(([k, v]) => `${k}=eq.${encodeURIComponent(v)}`)
        .join("&");
      res = await fetch(`${base}?${q}`, {
        method: "PATCH",
        headers: { ...headers, Prefer: "return=representation" },
        body: JSON.stringify(patch),
      });
    }

    else if (op === "del") {
      const q = Object.entries(match)
        .map(([k, v]) => `${k}=eq.${encodeURIComponent(v)}`)
        .join("&");
      res = await fetch(`${base}?${q}`, { method: "DELETE", headers });
      return { statusCode: 200, body: JSON.stringify({ data: null }) };
    }

    else {
      return { statusCode: 400, body: JSON.stringify({ error: "Unknown operation" }) };
    }

    const data = await res.json();

    if (!res.ok) {
      return {
        statusCode: res.status,
        body: JSON.stringify({ error: data.message || JSON.stringify(data) }),
      };
    }

    // For insert/update: return first row or null
    let result = data;
    if (op === "insert" || op === "update") {
      result = Array.isArray(data) ? (data.length ? data[0] : null) : data;
    }

    return {
      statusCode: 200,
      body: JSON.stringify({ data: result }),
    };

  } catch (err) {
    return {
      statusCode: 500,
      body: JSON.stringify({ error: err.message }),
    };
  }
};
