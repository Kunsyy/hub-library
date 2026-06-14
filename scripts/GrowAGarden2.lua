--[[
    Game script: Grow A Garden 2
    Status: WIP — masih test auto-detect + struktur dasar.
    Dipanggil otomatis sama loader.lua kalau PlaceId/GameId == 97598239454123.
--]]

local Library = _G.HubLibrary
if not Library then return warn("[GrowAGarden2] Library not loaded.") end

local CoreGui    = game:GetService("CoreGui")
local RunService = game:GetService("RunService")

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
    Version  = "v1.0 (WIP)",
    Game     = "Grow A Garden 2",
    -- ===== KEY SYSTEM (server + HWID + tier) =====
    -- Validasi key + HWID lewat api.kunsydev.xyz. Kelola key via admin endpoint
    -- (lihat server/README.md). Tier: free/ads/monthly/yearly/permanent.
    KeyValidator = Library:MakeServerValidator("https://api.kunsydev.xyz"),
})

-- ===== TAB: FARM =====
local Farm = Setup:CreateTab({ name = "Farm" })

local Auto = Farm:CreateSection("Auto Farm")
Auto:CreateToggle({
    name = "Auto Collect", flag = "autoCollect", default = false,
    callback = function(on)
        interval("autoCollect", "autoCollect", Library.Flags.collectDelay or 1, function()
            -- TODO: logika collect di sini
        end)
    end,
})
Auto:CreateSlider({ name = "Collect Delay (s)", flag = "collectDelay", min = 0, max = 10, default = 1 })

local Plant = Farm:CreateSection("Planting")
Plant:CreateToggle({ name = "Auto Plant", flag = "autoPlant", default = false, callback = function(v) end })
Plant:CreateToggle({ name = "Auto Sell", flag = "autoSell", default = false,
    callback = function(on)
        if on then Library:Notify({ title = "Auto Sell", text = "Enabled!", style = "success" }) end
    end })

-- ===== TAB: VISUAL (demo elemen baru) =====
local Visual = Setup:CreateTab({ name = "Visual" })
local Theme = Visual:CreateSection("Theme")
Theme:CreateLabel({ text = "Customize your hub appearance:" })
Theme:CreateSeparator({})
Theme:CreateColorPicker({ name = "ESP Color", flag = "espColor", default = Color3.fromRGB(150,90,255),
    callback = function(c) end })
Theme:CreateSeparator({ text = "INFO" })
Theme:CreateParagraph({ title = "About", text = "Kunsy Hub for Grow A Garden 2. Join Discord for updates and key access." })

-- ===== TAB: SHOP =====
local Shop = Setup:CreateTab({ name = "Shop" })
local Buy = Shop:CreateSection("Auto Buy")
Buy:CreateMultiDropdown({
    name = "Buy Seeds", flag = "buySeeds",
    options = { "Carrot", "Tomato", "Corn", "Pumpkin" }, default = {},
    callback = function(v) end,
})

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

Library:ApplyAutoload()

print("[Kunsy Hub] Grow A Garden 2 loaded (WIP)! Press RightShift to toggle.")
