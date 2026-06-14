--[[
    Game script: Slime RNG
    Dipanggil otomatis sama loader.lua kalau PlaceId cocok.
    Library udah ke-load, ambil dari _G.HubLibrary.
--]]

local Library = _G.HubLibrary
if not Library then return warn("[SlimeRNG] Library not loaded.") end

local CoreGui     = game:GetService("CoreGui")
local RunService  = game:GetService("RunService")

-- ============================================================
--  HELPER: interval (jalanin callback tiap X detik kalau flag ON)
-- ============================================================
local function interval(tag, flag, delayTime, callback)
    Library:CleanupConnectionsByTag(tag)
    delayTime = math.max(tonumber(delayTime) or 0.1, 0.05)
    if not Library.Flags[flag] then return end
    local last, running = 0, false
    local conn = RunService.Heartbeat:Connect(function()
        if not Library.Flags[flag] then Library:CleanupConnectionsByTag(tag); return end
        local now = os.clock()
        if running or now - last < delayTime then return end
        last = now; running = true
        task.spawn(function()
            pcall(callback)
            task.wait(); running = false
        end)
    end)
    Library:TrackConnection(conn, tag)
end

-- ============================================================
--  BUILD UI
-- ============================================================
local Setup = Library:Setup({
    Location = CoreGui,
    Title    = "Kunsy Hub",
    Discord  = "discord.gg/yourserver",
    Version  = "v1.0",
    Game     = "Slime RNG",
    -- KeyValidator = function(key) return key == "test123" end,  -- aktifin kalau mau key system
})

-- ===== TAB: MAIN =====
local Main = Setup:CreateTab({ name = "Main" })

local Rolling = Main:CreateSection("Rolling")
Rolling:CreateToggle({
    name = "Auto Roll", flag = "autoRoll", default = false,
    callback = function(on)
        interval("autoRoll", "autoRoll", Library.Flags.rollDelay or 1, function()
            -- TODO: logika roll di sini
            -- contoh: ReplicatedStorage.Remotes.Roll:FireServer()
        end)
    end,
})
Rolling:CreateSlider({ name = "Roll Delay (s)", flag = "rollDelay", min = 0, max = 10, default = 1 })

local Equip = Main:CreateSection("Equip")
Equip:CreateToggle({ name = "Auto Equip Best", flag = "autoEquip", default = false, callback = function(v) end })

-- ===== TAB: MISC =====
local Misc = Setup:CreateTab({ name = "Misc" })

local Server = Misc:CreateSection("Server")
Server:CreateButton({
    name = "Rejoin",
    callback = function()
        local TS = game:GetService("TeleportService")
        local LP = game:GetService("Players").LocalPlayer
        TS:Teleport(game.PlaceId, LP)
    end,
})

local Keys = Misc:CreateSection("Keybinds")
Keys:CreateMenuKeybind({ name = "Menu Keybind", default = "RightShift" })

-- ===== CONFIG PANEL =====
Misc:CreateConfigSection({ title = "Configuration" })

-- load autoload config (kalau ada) + aktifin auto-save
Library:ApplyAutoload()

print("[Kunsy Hub] Slime RNG loaded! Press RightShift to toggle.")
