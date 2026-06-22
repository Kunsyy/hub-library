--[[
    Game script: Universal (Fallback)
    Loaded automatically when a game is not found in games.json.
--]]

local Library = _G.HubLibrary
if not Library then return warn("[Universal] Library not loaded.") end

local CoreGui = game:GetService("CoreGui")
local Players = game:GetService("Players")
local LP = Players.LocalPlayer

-- ============================================================
--  BUILD UI
-- ============================================================
local Setup = Library:Setup({
    Location = CoreGui,
    Logo     = "rbxassetid://0",
    Title    = "Kunsy Hub Premium",
    Discord  = "discord.gg/chiyo",
    Version  = "v1.0 (Universal)",
    Game     = "Universal Fallback"
})

-- Beri notifikasi kalau game ini gak di-support secara spesifik
task.delay(1, function()
    -- Menggunakan API Roblox StarterGui atau Library Notification kalau ada
    pcall(function()
        game.StarterGui:SetCore("SendNotification", {
            Title = "Game Not Supported",
            Text = "Loading Universal basic features instead.",
            Duration = 5,
        })
    end)
end)

-- ===== TAB: LOCAL PLAYER =====
local MainTab = Setup:CreateTab({ name = "Local Player", columns = 1 })
local Movement = MainTab:CreateSection("Movement")

Movement:CreateSlider({
    name = "WalkSpeed",
    flag = "WalkSpeed",
    min = 16,
    max = 200,
    default = 16,
    callback = function(val)
        if LP.Character and LP.Character:FindFirstChild("Humanoid") then
            LP.Character.Humanoid.WalkSpeed = val
        end
    end
})

Movement:CreateSlider({
    name = "JumpPower",
    flag = "JumpPower",
    min = 50,
    max = 300,
    default = 50,
    callback = function(val)
        if LP.Character and LP.Character:FindFirstChild("Humanoid") then
            LP.Character.Humanoid.JumpPower = val
        end
    end
})

-- ===== TAB: VISUAL =====
local VisualTab = Setup:CreateTab({ name = "Visuals", columns = 1 })
local ESP = VisualTab:CreateSection("ESP")

ESP:CreateToggle({
    name = "Player ESP",
    flag = "playerEsp",
    default = false,
    callback = function(on)
        -- Placeholder for ESP Logic
        if on then
            print("ESP Enabled")
        else
            print("ESP Disabled")
        end
    end
})

-- ===== TAB: MISC =====
local MiscTab = Setup:CreateTab({ name = "Misc", columns = 2 })
local Settings = MiscTab:CreateSection("Settings")

Settings:CreateButton({
    name = "Rejoin Server",
    callback = function()
        local TS = game:GetService("TeleportService")
        TS:Teleport(game.PlaceId, LP)
    end
})

MiscTab:CreateConfigSection({ title = "Configuration" })

Library:ApplyAutoload()

print("[Kunsy Hub] Universal loaded! Press RightShift to toggle.")
