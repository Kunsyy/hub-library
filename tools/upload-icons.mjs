/**
 * Bulk-upload semua PNG di icons/ ke Roblox via Open Cloud Assets API.
 * AMAN: pakai API key (scoped, revocable), BUKAN cookie akun.
 *
 * Cara pakai (PowerShell):
 *   $env:ROBLOX_API_KEY="xxx"; $env:CREATOR_USER_ID="123456"; node tools/upload-icons.mjs
 * Cara pakai (bash):
 *   ROBLOX_API_KEY=xxx CREATOR_USER_ID=123456 node tools/upload-icons.mjs
 *
 * Hasil: icons/uploaded-ids.json  (mapping nama file -> assetId)
 */

import { readFileSync, readdirSync, writeFileSync } from "node:fs";
import { fileURLToPath } from "node:url";
import { dirname, join } from "node:path";

const API_KEY = process.env.ROBLOX_API_KEY;
const USER_ID = process.env.CREATOR_USER_ID;
if (!API_KEY || !USER_ID) {
  console.error("Set ROBLOX_API_KEY dan CREATOR_USER_ID dulu.");
  process.exit(1);
}

const ICON_DIR = join(dirname(fileURLToPath(import.meta.url)), "..", "icons");
const API = "https://apis.roblox.com/assets/v1/assets";
const OP = "https://apis.roblox.com/assets/v1/operations/";

const sleep = (ms) => new Promise((r) => setTimeout(r, ms));

async function uploadOne(file) {
  const buf = readFileSync(join(ICON_DIR, file));
  const displayName = file.replace(/\.png$/i, "");
  const request = {
    assetType: "Decal",
    displayName: "kunsy_" + displayName,
    description: "Kunsy Hub UI icon",
    creationContext: { creator: { userId: Number(USER_ID) } },
  };
  const fd = new FormData();
  fd.append("request", JSON.stringify(request));
  fd.append("fileContent", new Blob([buf], { type: "image/png" }), file);

  const res = await fetch(API, { method: "POST", headers: { "x-api-key": API_KEY }, body: fd });
  const txt = await res.text();
  if (!res.ok) throw new Error(`upload ${file} failed (${res.status}): ${txt}`);
  const data = JSON.parse(txt);
  const opId = (data.operationId) || (data.path && data.path.split("/").pop());
  if (!opId) throw new Error(`no operation id for ${file}: ${txt}`);

  // poll operation sampai dapet assetId
  for (let i = 0; i < 20; i++) {
    await sleep(1500);
    const r = await fetch(OP + opId, { headers: { "x-api-key": API_KEY } });
    const d = await r.json().catch(() => ({}));
    if (d.done && d.response && d.response.assetId) return d.response.assetId;
  }
  throw new Error(`timeout polling ${file}`);
}

const files = readdirSync(ICON_DIR).filter((f) => /\.png$/i.test(f));
console.log(`Found ${files.length} PNG(s). Uploading...\n`);

const result = {};
for (const f of files) {
  try {
    const id = await uploadOne(f);
    result[f] = id;
    console.log(`✅ ${f.padEnd(18)} -> rbxassetid://${id}`);
  } catch (e) {
    console.error(`❌ ${f}: ${e.message}`);
  }
  await sleep(800); // jaga rate limit
}

writeFileSync(join(ICON_DIR, "uploaded-ids.json"), JSON.stringify(result, null, 2));
console.log(`\nSaved -> icons/uploaded-ids.json (${Object.keys(result).length} ok)`);
console.log("Catatan: asset baru kadang perlu moderasi beberapa menit sebelum muncul in-game.");
