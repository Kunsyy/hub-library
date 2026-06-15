# AGENTS.md — Kunsy Hub

Onboarding for any AI assistant or developer working on this project. Read this first.

## What this is
Kunsy Hub — a premium Roblox script hub. Three things in one repo:
1. A purple-theme Roblox UI library (Lua).
2. A loader + per-game feature scripts.
3. A Cloudflare-backed backend (key/HWID server + browser-gated file serving) and a marketing website.

## Architecture (3 layers)
- `loader.lua` — single entry point users execute. Loads the UI library, reads `games.json`, detects the game by PlaceId/GameId, then loads the matching `scripts/<Game>.lua`. **Freeze this file** (it is the "obfuscate once" target); add games/features without touching it.
- `NewLibrary.lua` — the UI engine (sidebar, 2-column layout, search, config system, key screen, notifications). Returns the lib table and also sets `_G.HubLibrary` (some executors drop the loadstring return value).
- `scripts/*.lua` — per-game feature modules. They grab `_G.HubLibrary`.

## Infra (Cloudflare, account: buatprojex@gmail.com)
- **Website** → `kunsydev.xyz` (served from `site/`, auto-deploys on push to `main`).
- **Key server Worker** `kunsy-hub-keys` (source: `server/worker.js`) on:
  - `api.kunsydev.xyz` (custom domain)
  - `kunsydev.xyz/raw/*` (path route — so the public loadstring has no `api.` subdomain)
  - `kunsy-hub-keys.buatprojex.workers.dev` (fallback)
- Worker endpoints: `POST /validate`, `POST /admin/{create,reset,revoke}`, `GET /admin/info`, `GET /raw/<file>`.
- `/raw/<file>` is **browser-gated**: real browsers get 404, executors get the file. It proxies the file fresh (~30s) from the GitHub **API** (not the raw CDN, which caches ~5min).

## Public load URL
```lua
loadstring(game:HttpGet("https://kunsydev.xyz/raw/loader.lua"))()
```

## File / directory map
| Path | What |
|------|------|
| `loader.lua` | Entry point. `REPO` base URL + game detection. Frozen. |
| `NewLibrary.lua` | UI library engine. `Icons` table uses `rbxthumb://` (works with any asset id). |
| `scripts/<Game>.lua` | Per-game features (e.g. `GrowAGarden2.lua`). |
| `games.json` | Game registry. `games.<Name>.ids` + `.script` are read by the loader. `display`, `features`, `premiumFeatures`, plus top-level `comingSoon` are read by the **website only** (loader ignores extra fields). |
| `keys.json` | Legacy static key list (server-side validation is the real gate now). |
| `server/worker.js` | Key/HWID server + `/raw` gating. Tier config in `TIERS`. |
| `server/wrangler.toml` | Worker config: routes, KV namespace binding. |
| `server/bot/bot.js` | Discord bot Worker (free-key generation). Not deployed yet. |
| `site/index.html` | Marketing website (single file). |
| `icons/` | Source PNG icons + `uploaded-ids.json` (filename → Roblox asset id). |
| `tools/upload-icons.mjs` | Bulk icon uploader via Roblox Open Cloud Assets API. |

## How to deploy
- **Website / loader / scripts / games.json**: just `git push origin main`. Cloudflare redeploys the site; the Worker serves Lua files fresh via `/raw`.
- **Worker code or routes** (`server/worker.js`, `server/wrangler.toml`): `cd server && npx wrangler deploy`. Requires Cloudflare auth (`npx wrangler login`).

## Secrets (names only — never commit values)
Set on the `kunsy-hub-keys` Worker via `npx wrangler secret put <NAME>`:
- `ADMIN_SECRET` — header `X-Admin-Secret` for `/admin/*` routes.
- `GH_TOKEN` — GitHub token so `/raw` can use the GitHub API (fresh fetch + higher rate limit).
- `CLIENT_SECRET` — optional; if set, `/raw` also requires header `X-Hub-Client`.
KV namespace `KEYS` id lives in `wrangler.toml`.

## Key tiers (in `server/worker.js` → `TIERS`)
free 1d/1dev (no premium) · ads 1d/1dev · monthly 30d/3dev · yearly 365d/10dev · permanent ∞/25dev.
The website pricing (`site/index.html`) and these tiers must be kept in sync by hand.

## Common tasks
- **Add a game**: create `scripts/<Name>.lua`, add `"<Name>": { "ids": [PLACEID, GAMEID], "script": "<Name>", "display": "...", "features": [...], "premiumFeatures": [...] }` to `games.json`, push. No loader change, no re-obfuscation.
- **Edit the UI library**: edit `NewLibrary.lua`, push. See `README.md` for the element API.
- **Change pricing/tiers**: edit `TIERS` in `server/worker.js` (then `wrangler deploy`) AND the matching cards in `site/index.html`.
- **Create/manage keys**: `curl` the `/admin/*` endpoints with header `X-Admin-Secret` (see `server/README.md`).

## Conventions
- Branch is `main`.
- UI-facing strings are English.
- Keep `api.kunsydev.xyz` alive as a fallback when changing routing.
- Don't hardcode Roblox cookies/tokens anywhere; icon uploads use a scoped Open Cloud API key.
