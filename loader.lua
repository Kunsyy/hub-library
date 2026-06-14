--[[
    ╔══════════════════════════════════════════════════════╗
    ║   HUB LOADER — entry point (OBFUSCATE THIS ONCE)      ║
    ╚══════════════════════════════════════════════════════╝

    User cukup jalanin 1 baris:
    loadstring(game:HttpGet("https://raw.githubusercontent.com/Kunsyy/hub-library/main/loader.lua"))()

    ⚠️ FILE INI DIBEKUKAN — obfuscate SEKALI, jangan disentuh lagi.
       Daftar game ada di  games.json  (edit di situ, GRATIS, no re-obf).
       Fitur game ada di    scripts/*.lua  (edit di situ, GRATIS, no re-obf).

    CARA NAMBAH GAME (tanpa re-obf):
    1. Bikin file  scripts/NamaGame.lua
    2. Tambahin entry di  games.json:
         "NamaGame": { "ids": [PLACEID], "script": "NamaGame" }
--]]

-- ⚙️ SUMBER FILE: lewat Worker (browser -> 404, cuma executor bisa, update ~30 detik)
local REPO = "https://api.kunsydev.xyz/raw/"
--   Fallback GitHub langsung (file kebaca di browser):
-- local REPO = "https://raw.githubusercontent.com/Kunsyy/hub-library/main/"

-- fetch dengan cache-busting (executor kayak Potasium suka nge-cache HttpGet)
local function fetch(file)
    local bust = "?v=" .. tostring(os.time()) .. tostring(math.random(1,99999))
    return game:HttpGet(REPO .. file .. bust)
end

local HttpService = game:GetService("HttpService")

-- ============================================================
--  1) LOAD UI LIBRARY
-- ============================================================
local Library
do
    local ok, res = pcall(function()
        return loadstring(fetch("NewLibrary.lua"))()
    end)
    Library = res or _G.HubLibrary
    if not Library then
        warn("[Hub] Failed to load UI library. Check your internet / executor HTTP support.")
        return
    end
end

-- ============================================================
--  2) LOAD GAMES REGISTRY (dari games.json — edit bebas, no re-obf)
-- ============================================================
local GAMES
do
    local ok, data = pcall(function()
        return HttpService:JSONDecode(fetch("games.json"))
    end)
    GAMES = (ok and data and data.games) or {}
end

-- ============================================================
--  3) DETECT GAME
-- ============================================================
local pid, gid = game.PlaceId, game.GameId
local matched, matchedName
for name, info in pairs(GAMES) do
    for _, id in ipairs(info.ids or {}) do
        if id == pid or id == gid then
            matched, matchedName = info, name
            break
        end
    end
    if matched then break end
end

-- ============================================================
--  4) NOT SUPPORTED -> console notif, UI nggak muncul
-- ============================================================
if not matched then
    warn("=================================================")
    warn("  [Hub] This game is NOT supported yet.")
    warn("  [Hub] PlaceId : " .. tostring(pid))
    warn("  [Hub] GameId  : " .. tostring(gid))
    warn("  [Hub] Join Discord for updates & requests.")
    warn("=================================================")
    return
end

-- ============================================================
--  5) LOAD GAME-SPECIFIC SCRIPT (pakai _G.HubLibrary)
-- ============================================================
_G.HubLibrary = Library
local ok, err = pcall(function()
    loadstring(fetch("scripts/" .. matched.script .. ".lua"))()
end)
if not ok then
    warn("[Hub] Error loading game script '" .. matchedName .. "': " .. tostring(err))
end
