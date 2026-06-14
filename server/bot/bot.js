/**
 * ╔══════════════════════════════════════════════════════════╗
 * ║  KUNSY HUB — Discord Bot (Cloudflare Worker)              ║
 * ╚══════════════════════════════════════════════════════════╝
 *
 * Slash commands:
 *   /getkey            -> generate FREE key (1/hari per user), reply ephemeral
 *   /resethwid <key>   -> reset HWID key milik sendiri (cooldown)
 *   /keyinfo <key>     -> liat sisa device & expiry
 *
 * Env (set via wrangler secret):
 *   DISCORD_PUBLIC_KEY  (verifikasi signature)
 * Bindings:
 *   KEYS   -> KV namespace yang sama dgn key server
 *
 * Endpoint ini dipasang sbg "Interactions Endpoint URL" di Discord Dev Portal.
 */

// ====== tier yg boleh dikasih bot ======
const FREE_TIER = { tier: "free", premium: false, days: 1, devices: 1 };
const GETKEY_COOLDOWN_H = 24;   // jeda /getkey per user (jam)
const RESET_COOLDOWN_H  = 12;   // jeda /resethwid per user (jam)

// ====== helpers ======
function hexToBytes(hex) {
  const b = new Uint8Array(hex.length / 2);
  for (let i = 0; i < b.length; i++) b[i] = parseInt(hex.substr(i * 2, 2), 16);
  return b;
}
function randomKey(len = 24) {
  const chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789";
  let out = "";
  const bytes = crypto.getRandomValues(new Uint8Array(len));
  for (let i = 0; i < len; i++) out += chars[bytes[i] % chars.length];
  return out;
}
function reply(content, ephemeral = true) {
  return new Response(JSON.stringify({
    type: 4, // CHANNEL_MESSAGE_WITH_SOURCE
    data: { content, flags: ephemeral ? 64 : 0 },
  }), { headers: { "Content-Type": "application/json" } });
}
function hoursLeft(ts, windowH) {
  const left = windowH * 3600000 - (Date.now() - ts);
  return Math.max(0, Math.ceil(left / 3600000));
}

async function verifySignature(request, rawBody, publicKey) {
  const sig = request.headers.get("X-Signature-Ed25519");
  const ts = request.headers.get("X-Signature-Timestamp");
  if (!sig || !ts) return false;
  try {
    const key = await crypto.subtle.importKey(
      "raw", hexToBytes(publicKey), { name: "Ed25519" }, false, ["verify"]
    );
    const data = new TextEncoder().encode(ts + rawBody);
    return await crypto.subtle.verify("Ed25519", key, hexToBytes(sig), data);
  } catch {
    return false;
  }
}

// ====== command handlers ======
async function cmdGetKey(userId, env) {
  const rlKey = "rl:getkey:" + userId;
  const last = await env.KEYS.get(rlKey);
  if (last) {
    const h = hoursLeft(Number(last), GETKEY_COOLDOWN_H);
    return reply(`⏳ You already claimed a free key. Try again in **${h}h**.\nWant premium without waiting? Check our store.`);
  }
  const key = randomKey();
  const rec = {
    tier: FREE_TIER.tier,
    premium: FREE_TIER.premium,
    devices: FREE_TIER.devices,
    created: Date.now(),
    expiry: Date.now() + FREE_TIER.days * 86400000,
    hwids: [],
    owner: userId,
  };
  await env.KEYS.put(key, JSON.stringify(rec));
  await env.KEYS.put(rlKey, String(Date.now()), { expirationTtl: GETKEY_COOLDOWN_H * 3600 });
  return reply(
    `🔑 **Your free key** (valid 1 day, 1 device):\n\`\`\`\n${key}\n\`\`\`\n` +
    `Paste it in the hub's key screen. Premium features are locked on free — upgrade in the store to unlock everything.`
  );
}

async function cmdResetHwid(userId, keyArg, env) {
  const raw = await env.KEYS.get(keyArg);
  if (!raw) return reply("❌ Key not found.");
  const rec = JSON.parse(raw);
  if (rec.owner && rec.owner !== userId) return reply("❌ This key isn't linked to your account.");
  const rlKey = "rl:reset:" + userId;
  const last = await env.KEYS.get(rlKey);
  if (last) {
    const h = hoursLeft(Number(last), RESET_COOLDOWN_H);
    return reply(`⏳ You can reset again in **${h}h**.`);
  }
  rec.hwids = [];
  await env.KEYS.put(keyArg, JSON.stringify(rec));
  await env.KEYS.put(rlKey, String(Date.now()), { expirationTtl: RESET_COOLDOWN_H * 3600 });
  return reply("✅ HWID reset. You can now use the key on a new device.");
}

async function cmdKeyInfo(keyArg, env) {
  const raw = await env.KEYS.get(keyArg);
  if (!raw) return reply("❌ Key not found.");
  const r = JSON.parse(raw);
  const exp = r.expiry ? new Date(r.expiry).toISOString().slice(0, 10) : "never";
  return reply(
    `🔎 **Key info**\n` +
    `Tier: **${r.tier}**\nPremium: **${r.premium ? "yes" : "no"}**\n` +
    `Devices: **${(r.hwids || []).length}/${r.devices}**\nExpires: **${exp}**`
  );
}

// ====== main ======
export default {
  async fetch(request, env) {
    if (request.method !== "POST") return new Response("Kunsy Hub bot", { status: 200 });

    const rawBody = await request.text();
    const ok = await verifySignature(request, rawBody, env.DISCORD_PUBLIC_KEY);
    if (!ok) return new Response("invalid request signature", { status: 401 });

    const body = JSON.parse(rawBody);

    // PING
    if (body.type === 1) {
      return new Response(JSON.stringify({ type: 1 }), { headers: { "Content-Type": "application/json" } });
    }

    // SLASH COMMAND
    if (body.type === 2) {
      const name = body.data?.name;
      const userId = body.member?.user?.id || body.user?.id || "unknown";
      const opts = {};
      for (const o of body.data?.options || []) opts[o.name] = o.value;

      if (name === "getkey")    return await cmdGetKey(userId, env);
      if (name === "resethwid") return await cmdResetHwid(userId, String(opts.key || ""), env);
      if (name === "keyinfo")   return await cmdKeyInfo(String(opts.key || ""), env);
      return reply("Unknown command.");
    }

    return new Response("ok");
  },
};
