--[[
    ╔══════════════════════════════════════════════════════╗
    ║   HUB LOADER — entry point (execute this one)         ║
    ╚══════════════════════════════════════════════════════╝

    User cukup jalanin 1 baris:
    loadstring(game:HttpGet("https://raw.githubusercontent.com/Kunsyy/hub-library/main/loader.lua"))()

    CARA NAMBAH GAME:
    1. Bikin file baru di  scripts/NamaGame.lua  (lihat scripts/SlimeRNG.lua sebagai contoh)
    2. Tambahin entry di tabel GAMES di bawah:
         NamaGame = { ids = { PLACEID }, script = "NamaGame" }
       (ids bisa lebih dari satu kalau game-nya punya banyak place)
--]]

local REPO = "https://raw.githubusercontent.com/Kunsyy/hub-library/main/"

-- fetch dengan cache-busting (executor kayak Potasium suka nge-cache HttpGet)
local function fetch(file)
    local bust = "?v=" .. tostring(os.time()) .. tostring(math.random(1,99999))
    return game:HttpGet(REPO .. file .. bust)
end

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
--  2) SUPPORTED GAMES REGISTRY
--     key = nama bebas | ids = {PlaceId...} | script = nama file di /scripts
-- ============================================================
local GAMES = {
    GrowAGarden2 = { ids = { 97598239454123 }, script = "GrowAGarden2" },
    -- PetSim    = { ids = { 123, 456 }, script = "PetSim" },
}

-- ============================================================
--  3) DETECT GAME
-- ============================================================
local pid, gid = game.PlaceId, game.GameId
local matched, matchedName
for name, info in pairs(GAMES) do
    for _, id in ipairs(info.ids) do
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
