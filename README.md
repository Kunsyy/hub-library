# Kunsy Hub Library

Roblox multi-game cheat loader built on [Obsidian V2](https://github.com/deividcomsono/Obsidian).

---

## How to Use

Execute `loader.lua` in your executor:

```lua
loadstring(game:HttpGet("https://raw.githubusercontent.com/Kunsyy/hub-library/main/loader.lua"))()
```

The loader will:
1. Ask for a key (or load saved key)
2. Validate it
3. Detect the current game via PlaceId
4. Download and run the matching game script

---

## Supported Games

| Game | Status |
|------|--------|
| Cook and Sell | ✅ Live |
| Grow a Garden | 🔜 Soon |
| Blox Fruits | 🔜 Soon |

---

## Adding a New Game

**1. Create the game script**

Copy `games/cook_and_sell.lua` as a base. The structure every game script must follow:

```lua
-- Load Obsidian + addons
local Library      = loadstring(fetchCached("Library.lua"))()
local ThemeManager = loadstring(fetchCached("addons/ThemeManager.lua"))()
local SaveManager  = loadstring(fetchCached("addons/SaveManager.lua"))()

-- Create window
local Window = Library:CreateWindow({
    Title            = "Game Name",
    Icon             = "rbxassetid://139962551928576",
    Size             = UDim2.fromOffset(700, 520),
    Center           = true,
    AutoShow         = true,
    ShowCustomCursor = false,  -- MUST be false or real cursor disappears on PC
})
-- Restore cursor (Obsidian hides it on init)
game:GetService("UserInputService").MouseIconEnabled = true

-- Add tabs
local Tabs = {
    Main     = Window:AddTab("", "bot"),
    Settings = Window:AddTab("", "settings"),
}
```

**2. Register in `games/index.lua`**

```lua
return {
    [106131416903029] = "games/cook_and_sell.lua",  -- Cook and Sell
    [YOUR_PLACE_ID]   = "games/your_game.lua",      -- your new game
}
```

**3. Push to GitHub** — loader picks it up automatically.

---

## Obsidian V2 — Critical Rules

> These are bugs/quirks discovered in production. Break these rules and your features will silently do nothing.

### ❌ Toggles — DO NOT chain `:OnChanged()`

`AddToggle()` returns the **Groupbox** (not the Toggle). Chaining `:OnChanged()` is a silent no-op.

```lua
-- WRONG: callback never fires
group:AddToggle("AutoFarm", {}):OnChanged(function(val) ... end)

-- CORRECT: use Callback inside options table
group:AddToggle("AutoFarm", { Text = "Auto Farm", Default = false,
    Callback = function(val)
        -- val = true/false
    end })
```

### ❌ Dropdowns — DO NOT chain `:OnChanged()`

Same issue. `AddDropdown()` also returns the Groupbox.

```lua
-- WRONG
group:AddDropdown("Mode", { Values = {...} }):OnChanged(fn)

-- CORRECT: access via Library.Options after creation
group:AddDropdown("Mode", { Values = {...}, Default = 1 })
Library.Options.Mode:OnChanged(function(val) ... end)
```

### ❌ Toggle state is NOT in `Library.Options`

`Library.Options` only stores Dropdowns, Inputs, Keybinds — not Toggles.

```lua
-- WRONG: always nil
local enabled = Library.Options.AutoFarm.Value

-- CORRECT: use a local flag set by Callback
local autoFarmEnabled = false
group:AddToggle("AutoFarm", { Callback = function(val)
    autoFarmEnabled = val
end })
```

---

## Heartbeat Loop Helper

All game scripts use `trackInterval` to run periodic tasks:

```lua
local Connections = {}

local function clearTag(tag)
    if Connections[tag] then
        Connections[tag]:Disconnect()
        Connections[tag] = nil
    end
end

local function trackInterval(tag, enabled, delay, callback)
    clearTag(tag)
    if not enabled then return end
    local last = 0
    Connections[tag] = RunService.Heartbeat:Connect(function()
        local now = os.clock()
        if now - last >= delay then
            last = now
            pcall(callback)
        end
    end)
end

-- Wire to a toggle:
group:AddToggle("AutoFarm", { Default = false,
    Callback = function(val)
        trackInterval("FarmLoop", val, 0.5, doAutoFarm)
    end })
```

---

## Built-in Features (all game scripts)

| Feature | Description |
|---------|-------------|
| **Floating K button** | Draggable toggle to show/hide UI, works on PC and mobile |
| **Auto-collapse groupboxes** | Every groupbox has a collapse chevron |
| **Thin outlines** | 0.5px stroke instead of default |
| **Obsidian caching** | Library files cached locally, no re-download on every execute |
| **Guard re-execute** | Unloads previous instance automatically on re-execute |

---

## Credits

- UI Framework: [Obsidian](https://github.com/deividcomsono/Obsidian) by deividcomsono
- Icons: [Lucide](https://lucide.dev) via lucide-roblox-direct
