# Kunsy Hub — Discord Bot (Cloudflare Worker)

Bot key gratis via slash command. Jalan di Cloudflare Worker (gratis), share KV yang sama dengan key server.

## Commands
- `/getkey` — user dapet key free (1 hari, 1 device), cooldown 24 jam/user
- `/resethwid <key>` — user reset device lock key sendiri (cooldown 12 jam)
- `/keyinfo <key>` — cek tier/device/expiry sebuah key

---

## Setup (sekali)

### 1. Bikin Discord Application
1. Buka **discord.com/developers/applications** → **New Application** → kasih nama (mis. Kunsy Hub)
2. **General Information** → copy **Application ID** & **Public Key**
3. **Bot** (menu kiri) → **Reset Token** → copy **Bot Token** (rahasia!)

### 2. Deploy bot Worker
```bash
cd server/bot
npx wrangler deploy
# set public key (dari General Information)
npx wrangler secret put DISCORD_PUBLIC_KEY
```
Dapet URL: `https://kunsy-hub-bot.<akun>.workers.dev`

### 3. Pasang Interactions Endpoint
Di Discord Dev Portal → **General Information** → **Interactions Endpoint URL** →
isi URL Worker di atas → **Save**.
(Discord bakal ngirim ping verifikasi; kalau signature bener, langsung tersimpan.)

### 4. Daftarin slash commands (sekali)
```bash
cd server/bot
# Windows PowerShell:
$env:APP_ID="<application id>"; $env:BOT_TOKEN="<bot token>"; node register-commands.js
# atau bash:
APP_ID=<application id> BOT_TOKEN=<bot token> node register-commands.js
```

### 5. Invite bot ke server (biar command muncul)
Dev Portal → **OAuth2** → **URL Generator** → centang scope **`applications.commands`** →
buka URL yang muncul → pilih server kamu → Authorize.

---

## Selesai
User di Discord ketik `/getkey` → langsung dapet key. Key & cooldown disimpen di KV
yang sama dengan key server, jadi langsung kepakai di hub.

> Tier ads/paid menyusul (ads = setelah Lootlabs, paid = setelah payment webhook).
