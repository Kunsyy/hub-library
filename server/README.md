# Kunsy Hub — Key Server (Cloudflare Worker)

Backend buat validasi key + HWID binding + 5 tier. Gratis (Cloudflare free tier).

## Tier (ubah di `worker.js` bagian `TIERS`)

| Tier | Premium | Durasi | Device (HWID) |
|------|---------|--------|---------------|
| free | ❌ | 1 hari | 1 |
| ads | ✅ | 1 hari | 1 |
| monthly | ✅ | 30 hari | 1 |
| yearly | ✅ | 365 hari | 2 |
| permanent | ✅ | selamanya | 3 |

---

## Deploy (sekali setup)

Butuh akun Cloudflare gratis (cloudflare.com).

```bash
cd server

# 1) login (buka browser)
npx wrangler login

# 2) bikin KV namespace
npx wrangler kv namespace create KEYS
#   -> copy "id" yang muncul, paste ke wrangler.toml (ganti PASTE_KV_ID_HERE)

# 3) set admin secret (buat bikin/hapus key)
npx wrangler secret put ADMIN_SECRET
#   -> ketik password rahasia kamu

# 4) deploy
npx wrangler deploy
#   -> dapet URL: https://kunsy-hub-keys.<akun>.workers.dev
```

URL Worker itu dipakai di game script (lihat di bawah).

---

## Bikin / kelola key (lewat admin endpoint)

Ganti `SECRET` dan `URL` sesuai punyamu.

```bash
# bikin 1 key permanen
curl -X POST https://URL/admin/create \
  -H "X-Admin-Secret: SECRET" \
  -H "Content-Type: application/json" \
  -d '{"tier":"permanent"}'

# bikin 10 key bulanan sekaligus
curl -X POST https://URL/admin/create \
  -H "X-Admin-Secret: SECRET" -H "Content-Type: application/json" \
  -d '{"tier":"monthly","count":10}'

# bikin key custom (nama key kamu sendiri)
curl -X POST https://URL/admin/create \
  -H "X-Admin-Secret: SECRET" -H "Content-Type: application/json" \
  -d '{"tier":"yearly","key":"VIP-KUNSY-001"}'

# reset HWID sebuah key (user ganti PC)
curl -X POST https://URL/admin/reset \
  -H "X-Admin-Secret: SECRET" -H "Content-Type: application/json" \
  -d '{"key":"KEYNYA"}'

# hapus key
curl -X POST https://URL/admin/revoke \
  -H "X-Admin-Secret: SECRET" -H "Content-Type: application/json" \
  -d '{"key":"KEYNYA"}'

# liat detail key (tier, expiry, HWID yg kebound)
curl "https://URL/admin/info?key=KEYNYA" -H "X-Admin-Secret: SECRET"
```

---

## Pakai di game script

Di `scripts/GrowAGarden2.lua`, ganti `KeyValidator`:

```lua
local Setup = Library:Setup({
    Location = CoreGui,
    Title    = "Kunsy Hub",
    Discord  = "discord.gg/yourserver",
    -- pakai SERVER validator (key + HWID + tier)
    KeyValidator = Library:MakeServerValidator(
        "https://kunsy-hub-keys.<akun>.workers.dev"
    ),
})

-- fitur premium: tambahin premium = true
Section:CreateToggle({ name = "Auto Farm Pro", flag = "farmPro", premium = true, callback = function(v) end })
-- kalau user bukan premium -> element keunci + badge "PREMIUM"

-- cek premium dari script:
if Library:IsPremium() then
    -- ...
end
```

---

## Browser gating ("400 di browser")

Worker punya endpoint `/raw/<file>` yang proxy ke GitHub tapi **nolak browser** (balik 400) dan cuma serve ke executor. Kalau mau loader lewat Worker (sumber kesembunyi dari browser):

```lua
-- di loader, ganti REPO jadi:
local REPO = "https://kunsy-hub-keys.<akun>.workers.dev/raw/"
```

> Catatan: gating User-Agent itu proteksi ringan (bisa di-spoof). Keamanan utama tetap di validasi key server-side.

---

## Catatan keamanan

- Key divalidasi **di server**, bukan di script → walau script kebongkar, tanpa key valid = nggak bisa pakai.
- HWID binding otomatis: key kepakai di N device pertama, sisanya ditolak "Device limit reached".
- `ADMIN_SECRET` jangan pernah masuk ke script client / repo.
