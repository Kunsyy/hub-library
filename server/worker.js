/**
 * ╔══════════════════════════════════════════════════════════╗
 * ║  KUNSY HUB — Key + HWID Server (Cloudflare Worker)         ║
 * ╚══════════════════════════════════════════════════════════╝
 *
 * Endpoints:
 *   POST /validate           { key, hwid, place }  -> validasi key + bind HWID
 *   POST /admin/create       (X-Admin-Secret)      -> bikin key baru
 *   POST /admin/reset        (X-Admin-Secret)      -> reset HWID sebuah key
 *   POST /admin/revoke       (X-Admin-Secret)      -> hapus key
 *   GET  /admin/info?key=    (X-Admin-Secret)      -> liat detail key
 *   GET  /raw/<file>                               -> proxy file dari GitHub
 *                                                     (browser -> 400, executor -> file)
 *
 * Storage: KV namespace "KEYS"
 * Secret : ADMIN_SECRET (wrangler secret)
 */

// ============================================================
//  TIER CONFIG  (gampang diubah)
//  days: null = permanen | devices = max HWID per key
// ============================================================
const TIERS = {
  free:      { premium: false, days: 1,    devices: 1 },
  ads:       { premium: true,  days: 1,    devices: 1 },
  monthly:   { premium: true,  days: 30,   devices: 3 },
  yearly:    { premium: true,  days: 365,  devices: 10 },
  permanent: { premium: true,  days: null, devices: 25 },
};

// sumber file asli (buat /raw proxy)
const GITHUB_BASE = "https://raw.githubusercontent.com/Kunsyy/hub-library/main/";

// ============================================================
//  HELPERS
// ============================================================
const json = (obj, status = 200) =>
  new Response(JSON.stringify(obj), {
    status,
    headers: { "Content-Type": "application/json" },
  });

function randomKey(len = 24) {
  const chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789";
  let out = "";
  const bytes = crypto.getRandomValues(new Uint8Array(len));
  for (let i = 0; i < len; i++) out += chars[bytes[i] % chars.length];
  return out;
}

function isBrowser(request) {
  // Browser asli ngirim sinyal-sinyal ini; executor (game:HttpGet/request) nggak.
  const h = request.headers;
  const accept = h.get("Accept") || "";
  // Sec-Fetch-* HANYA dikirim browser beneran (Chrome/Firefox/Edge/dst)
  if (h.get("Sec-Fetch-Mode") || h.get("Sec-Fetch-Site") || h.get("Sec-Fetch-Dest")) return true;
  if (h.get("Upgrade-Insecure-Requests")) return true; // navigasi browser
  if (accept.includes("text/html")) return true;
  if (h.get("Referer") || h.get("Origin")) return true; // datang dari halaman web
  return false;
}

// gerbang akses /raw: tolak browser; kalau CLIENT_SECRET di-set, wajib header cocok
function rawAllowed(request, env) {
  if (isBrowser(request)) return false;
  if (env.CLIENT_SECRET) {
    return request.headers.get("X-Hub-Client") === env.CLIENT_SECRET;
  }
  return true;
}

// ============================================================
//  MAIN
// ============================================================
export default {
  async fetch(request, env) {
    const url = new URL(request.url);
    const path = url.pathname;

    try {
      // ---------- VALIDATE ----------
      if (path === "/validate" && request.method === "POST") {
        return await handleValidate(request, env);
      }

      // ---------- ADMIN ----------
      if (path.startsWith("/admin/")) {
        const secret = request.headers.get("X-Admin-Secret");
        if (!secret || secret !== env.ADMIN_SECRET) {
          return json({ error: "unauthorized" }, 401);
        }
        if (path === "/admin/create" && request.method === "POST")
          return await handleCreate(request, env);
        if (path === "/admin/reset" && request.method === "POST")
          return await handleReset(request, env);
        if (path === "/admin/revoke" && request.method === "POST")
          return await handleRevoke(request, env);
        if (path === "/admin/info" && request.method === "GET")
          return await handleInfo(url, env);
        return json({ error: "unknown admin route" }, 404);
      }

      // ---------- RAW PROXY (browser-gated, fresh via GitHub API) ----------
      if (path.startsWith("/raw/")) {
        if (!rawAllowed(request, env)) {
          return new Response("404 Not Found", { status: 404 });
        }
        const file = path.slice(5); // buang "/raw/" (tanpa query)
        // Ambil dari GitHub API (fresh, bukan raw CDN yg cache ~5menit).
        // Edge-cache 30 detik biar update cepet TAPI aman dari rate limit.
        const apiUrl = `https://api.github.com/repos/Kunsyy/hub-library/contents/${file}?ref=main`;
        const ghHeaders = {
          "Accept": "application/vnd.github.raw",
          "User-Agent": "kunsy-hub-worker",
        };
        if (env.GH_TOKEN) ghHeaders["Authorization"] = "Bearer " + env.GH_TOKEN;
        let res = await fetch(apiUrl, { headers: ghHeaders, cf: { cacheTtl: 30, cacheEverything: true } });
        if (!res.ok) {
          // fallback ke raw CDN kalau API gagal
          res = await fetch(GITHUB_BASE + file, { cf: { cacheTtl: 30 } });
          if (!res.ok) return new Response("Not found", { status: 404 });
        }
        const body = await res.text();
        return new Response(body, {
          headers: { "Content-Type": "text/plain", "Cache-Control": "public, max-age=30" },
        });
      }

      return json({ ok: true, service: "kunsy-hub-keys" });
    } catch (e) {
      return json({ error: "server", detail: String(e) }, 500);
    }
  },
};

// ============================================================
//  /validate
// ============================================================
async function handleValidate(request, env) {
  let body;
  try {
    body = await request.json();
  } catch {
    return json({ valid: false, message: "Bad request" }, 400);
  }
  const key = String(body.key || "").trim();
  const hwid = String(body.hwid || "").trim();
  if (!key) return json({ valid: false, message: "Key is empty" });
  if (!hwid) return json({ valid: false, message: "No HWID provided" });

  const raw = await env.KEYS.get(key);
  if (!raw) return json({ valid: false, message: "Invalid key" });

  const rec = JSON.parse(raw);

  // expiry
  if (rec.expiry && Date.now() > rec.expiry) {
    return json({ valid: false, message: "Key expired" });
  }

  // HWID binding
  rec.hwids = rec.hwids || [];
  if (!rec.hwids.includes(hwid)) {
    if (rec.hwids.length >= rec.devices) {
      return json({
        valid: false,
        message: `Device limit reached (${rec.hwids.length}/${rec.devices})`,
      });
    }
    rec.hwids.push(hwid);
    rec.lastUsed = Date.now();
    await env.KEYS.put(key, JSON.stringify(rec));
  }

  return json({
    valid: true,
    premium: !!rec.premium,
    tier: rec.tier,
    expiry: rec.expiry || 0,
    devices: `${rec.hwids.length}/${rec.devices}`,
    message: "Welcome!",
  });
}

// ============================================================
//  /admin/create   body: { tier, count?, key? }
// ============================================================
async function handleCreate(request, env) {
  const body = await request.json();
  const tier = String(body.tier || "").toLowerCase();
  const t = TIERS[tier];
  if (!t) return json({ error: "unknown tier", tiers: Object.keys(TIERS) }, 400);

  const count = Math.min(Math.max(parseInt(body.count) || 1, 1), 100);
  const made = [];
  for (let i = 0; i < count; i++) {
    const key = count === 1 && body.key ? String(body.key) : randomKey();
    const rec = {
      tier,
      premium: t.premium,
      devices: t.devices,
      created: Date.now(),
      expiry: t.days ? Date.now() + t.days * 86400000 : null,
      hwids: [],
    };
    await env.KEYS.put(key, JSON.stringify(rec));
    made.push(key);
  }
  return json({ ok: true, tier, count, keys: made });
}

// ============================================================
//  /admin/reset   body: { key }   -> kosongin HWID
// ============================================================
async function handleReset(request, env) {
  const body = await request.json();
  const key = String(body.key || "");
  const raw = await env.KEYS.get(key);
  if (!raw) return json({ error: "key not found" }, 404);
  const rec = JSON.parse(raw);
  rec.hwids = [];
  await env.KEYS.put(key, JSON.stringify(rec));
  return json({ ok: true, key, message: "HWID reset" });
}

// ============================================================
//  /admin/revoke   body: { key }   -> hapus key
// ============================================================
async function handleRevoke(request, env) {
  const body = await request.json();
  const key = String(body.key || "");
  await env.KEYS.delete(key);
  return json({ ok: true, key, message: "Key revoked" });
}

// ============================================================
//  /admin/info?key=
// ============================================================
async function handleInfo(url, env) {
  const key = url.searchParams.get("key") || "";
  const raw = await env.KEYS.get(key);
  if (!raw) return json({ error: "key not found" }, 404);
  return json({ ok: true, key, record: JSON.parse(raw) });
}
