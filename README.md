# Hub Library — Roblox UI Library (Purple Theme)

Load with one line:
```lua
local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/Kunsyy/hub-library/master/NewLibrary.lua"))()
```

---

## Quick Start

```lua
local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/Kunsyy/hub-library/master/NewLibrary.lua"))()

local Setup = Library:Setup({
    Location = game:GetService("CoreGui"),
    Logo     = "rbxassetid://0",
    Title    = "My Hub",
    Discord  = "discord.gg/yourserver",
    Version  = "v1.0",
    Game     = "Slime RNG",
})

local Main = Setup:CreateTab({ name = "Main" })
local Section = Main:CreateSection("Auto Farm")
Section:CreateToggle({ name = "Auto Roll", flag = "autoRoll", default = false, callback = function(v) end })
```

---

## Setup Options

| Option | Type | Description |
|--------|------|-------------|
| `Location` | Instance | Where to parent the UI. Use `game:GetService("CoreGui")` |
| `Logo` | string | `rbxassetid://...` for sidebar logo |
| `Title` | string | Hub name (shown in key screen if KeyValidator is set) |
| `Discord` | string | Discord invite link (e.g. `discord.gg/abc`) |
| `Version` | string | Shown in bottom bar |
| `Game` | string | Game name shown in bottom bar |
| `OpenCloseLocation` | string | Position of the toggle button. Options below |
| `MenuKey` | string | Default keybind to open/close (default: `"RightShift"`) |
| `KeyValidator` | function | `function(key) return bool end` — enables key system |

### OpenCloseLocation options
`"Top Center"` · `"Top Right"` · `"Top Left"` · `"Center Left"` · `"Bottom Left"` · `"Bottom Right"`

---

## Tabs

```lua
local Tab = Setup:CreateTab({ name = "Main" })
-- Tab with icon (rbxassetid)
local Tab2 = Setup:CreateTab({ name = "Settings", icon = "rbxassetid://0" })
```

---

## Sections

```lua
local Sec = Tab:CreateSection("Section Name")
```

Sections alternate between left and right columns automatically.

---

## Elements

### Toggle
```lua
Sec:CreateToggle({
    name     = "Auto Roll",
    flag     = "autoRoll",      -- Library.Flags["autoRoll"]
    default  = false,
    callback = function(value) end,
})
```

### Slider
```lua
Sec:CreateSlider({
    name     = "Delay",
    flag     = "delay",
    min      = 0,
    max      = 300,
    default  = 30,
    callback = function(value) end,
})
```

### Dropdown
```lua
Sec:CreateDropdown({
    name     = "Mode",
    flag     = "mode",
    options  = { "Damage", "Speed", "Luck" },
    default  = "Damage",
    callback = function(value) end,
})
```

### MultiDropdown
```lua
Sec:CreateMultiDropdown({
    name     = "Boosts",
    flag     = "boosts",
    options  = { "Luck", "Speed", "Damage", "Coins" },
    default  = { "Luck" },
    callback = function(values) end,  -- values = table
})
```

### Button
```lua
Sec:CreateButton({
    name     = "Rejoin",
    callback = function() end,
})
```

### Textbox
```lua
Sec:CreateTextbox({
    name        = "Save At",
    flag        = "saveAt",
    placeholder = "Type here...",
    callback    = function(text) end,
})
```

### Keybind
```lua
Sec:CreateKeybind({
    name     = "Toggle Fly",
    flag     = "flyKey",
    default  = "F",
    callback = function() end,  -- fires when key is pressed
})
```

### Menu Keybind
```lua
Sec:CreateMenuKeybind({
    name    = "Menu Keybind",
    default = "RightShift",
})
```

### Config Section (full panel, 1 call)
```lua
Tab:CreateConfigSection({ title = "Configuration" })
```

---

## Key System

```lua
local Setup = Library:Setup({
    KeyValidator = function(key)
        -- return true if key is valid
        local res = game:HttpGet("https://yourapi.com/check?key=" .. key)
        return res == "true"
    end,
    Discord = "discord.gg/yourserver",  -- shown as "Get key" link in key screen
    -- ...other options
})
```

The key screen blocks Setup until a valid key is entered.

---

## Config API

```lua
Library:SaveConfig("configName")          -- save current flags
Library:LoadConfig("configName")          -- load flags from file
Library:DeleteConfig("configName")        -- delete config file
Library:ListConfigs()                     -- returns table of config names
Library:ExportConfig("configName")        -- copies JSON to clipboard
Library:ImportConfig(jsonString)          -- applies JSON string
Library:SetAutoloadConfig("configName")   -- set config to auto-load on next run
Library:ClearAutoload()                   -- remove autoload
Library:ApplyAutoload()                   -- call at end of script to load saved autoload
```

---

## Interval Helper (from Template Script)

```lua
local function interval(tag, flag, delayTime, callback)
    Library:CleanupConnectionsByTag(tag)
    delayTime = math.max(tonumber(delayTime) or 0.1, 0.05)
    if not Library.Flags[flag] then return end
    local last, running = 0, false
    local conn = game:GetService("RunService").Heartbeat:Connect(function()
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
```

---

## Available Icons

Icons are in the `/icons` folder. Upload to Roblox as Decals to get `rbxassetid://` IDs.

| File | Usage |
|------|-------|
| `home.png` | Main/home tab |
| `settings.png` | Settings tab |
| `gear.png` | Config/tools tab |
| `sword.png` / `sword2.png` | Combat/farm tab |
| `diamond.png` | Premium/misc tab |
| `shop.png` | Shop tab |
| `trophy.png` | Leaderboard tab |
| `notif.png` | Notifications tab |
| `scroll.png` | Scripts tab |
| `location.png` | Teleport tab |
| `folder.png` | Files/config tab |
| `gift.png` | Events/reward tab |
| `logo.png` | Hub logo |

---

## Flags

All element values are accessible via `Library.Flags`:
```lua
print(Library.Flags["autoRoll"])   -- true/false
print(Library.Flags["delay"])      -- number
print(Library.Flags["mode"])       -- string
print(Library.Flags["boosts"])     -- table
print(Library.Flags["flyKey"])     -- string (key name)
print(Library.Flags["menuKeybind"]) -- string
```
