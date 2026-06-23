# Kunsy Hub Library — Developer Docs

Multi-game Roblox loader built on [Obsidian V2](https://github.com/deividcomsono/Obsidian).  
Each game gets its own script. The loader handles key validation, game detection, and delivery.

---

## Loading

```lua
loadstring(game:HttpGet("https://raw.githubusercontent.com/Kunsyy/hub-library/main/loader.lua"))()
```

---

## Creating a Window

Every game script starts by creating a window.

```lua
local Window = Library:CreateWindow({
    Title            = "Cook and Sell",
    Icon             = "rbxassetid://139962551928576",
    IconSize         = UDim2.fromOffset(38, 38),
    Size             = UDim2.fromOffset(700, 520),
    Center           = true,
    AutoShow         = true,
    ShowCustomCursor = false,
    NotifySide       = "Right",
})
Window:SetSidebarWidth(48)

-- Always add this after CreateWindow — Obsidian hides the real cursor on init
game:GetService("UserInputService").MouseIconEnabled = true
```

> **Note:** Always set `ShowCustomCursor = false`. If true, Obsidian hides the real cursor and the player's mouse disappears on PC.

---

## Tabs

Tabs appear as icons in the left sidebar. Use empty string `""` for no label (icon-only).

```lua
local Tabs = {
    Farm     = Window:AddTab("", "bot"),
    Shop     = Window:AddTab("", "shopping-cart"),
    Cook     = Window:AddTab("", "cooking-pot"),
    Misc     = Window:AddTab("", "wrench"),
    Settings = Window:AddTab("", "settings"),
}
Tabs.Farm:Show()  -- open this tab by default
```

Icons come from [Lucide](https://lucide.dev) — use the icon name as a string.

---

## Groupboxes

Groupboxes are the panels inside a tab. Each tab has a left column and a right column.

```lua
local LeftGroup  = Tabs.Farm:AddLeftGroupbox("Cashier", "users")
local RightGroup = Tabs.Farm:AddRightGroupbox("Kitchen", "cooking-pot")
```

Every groupbox automatically gets a **collapse chevron** — click the `∧` button in the header to collapse/expand.

---

## Toggle

Adds an on/off switch. Use `Callback` — **never** chain `:OnChanged()` (see Gotchas).

```lua
LeftGroup:AddToggle("AutoCashier", {
    Text    = "Auto Cashier",
    Default = false,
    Callback = function(val)
        -- val is true when ON, false when OFF
        trackInterval("CashierLoop", val, 0.5, doAutoCashier)
    end
})
```

| Option | Type | Description |
|--------|------|-------------|
| `Text` | string | Label shown next to the toggle |
| `Default` | boolean | Starting state |
| `Callback` | function(val) | Fires when the user clicks the toggle |

---

## Dropdown

Adds a selectable list. Access value changes via `Library.Options` — **never** chain `:OnChanged()` (see Gotchas).

```lua
LeftGroup:AddDropdown("BuyShopItem", {
    Text    = "Select Item",
    Values  = { "Burger", "Pizza", "Sushi" },
    Default = 1,
})
Library.Options.BuyShopItem:OnChanged(function(val)
    print("Selected:", val)
end)
```

| Option | Type | Description |
|--------|------|-------------|
| `Text` | string | Label above the dropdown |
| `Values` | table | List of options |
| `Default` | number | Index of the default option |
| `Multi` | boolean | Allow multiple selections |
| `AllowNull` | boolean | Allow no selection |

---

## Button

Adds a clickable button. The callback fires on click.

```lua
LeftGroup:AddButton("Order 1", function()
    local id = itemMeta[Library.Options.BuyShopItem.Value]
    fireRemote("BuyRecipeItem", id, 1)
end)
```

---

## Label

Adds static text. Use it for section headings, dividers, or notes.

```lua
LeftGroup:AddLabel("Farm controls below")
```

Labels can be chained with color pickers (unlike Toggle/Dropdown):

```lua
LeftGroup:AddLabel("Accent color"):AddColorPicker("AccentColor", {
    Default = Color3.fromRGB(168, 85, 247)
})
```

---

## Keybind

Adds a key picker. Use `NoUI = true` to hide it from the UI and only use it as a menu toggle.

```lua
LeftGroup:AddLabel("Menu bind"):AddKeyPicker("MenuKeybind", {
    Default = "RightShift",
    NoUI    = true,
    Text    = "Menu keybind",
})
Library.ToggleKeybind = Library.Options.MenuKeybind
```

---

## trackInterval — Heartbeat Loop

The standard pattern for all auto-farm features. Runs a callback on a fixed interval using `RunService.Heartbeat`. Cleans up the old connection automatically when called again.

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
```

**Usage with a toggle:**

```lua
local function doAutoFarm()
    -- your farming logic here
end

group:AddToggle("AutoFarm", { Default = false,
    Callback = function(val)
        trackInterval("FarmLoop", val, 0.5, doAutoFarm)
    end })
```

| Parameter | Description |
|-----------|-------------|
| `tag` | Unique string key for this loop |
| `enabled` | Pass `val` directly from the toggle Callback |
| `delay` | Seconds between each call |
| `callback` | Function to run each tick |

> **Tip:** Use descriptive tags like `"CashierLoop"`, `"CookLoop"` — they're also used to stop loops individually with `clearTag(tag)`.

---

## Floating Toggle Button

A draggable K logo button that shows/hides the UI. Works on both PC and mobile.

```lua
do
    pcall(function()
        for _, v in ipairs(game:GetService("CoreGui"):GetChildren()) do
            if v.Name == "KunsyToggle" then v:Destroy() end
        end
    end)

    local toggleGui = Instance.new("ScreenGui")
    toggleGui.Name           = "KunsyToggle"
    toggleGui.ResetOnSpawn   = false
    toggleGui.DisplayOrder   = 999
    toggleGui.IgnoreGuiInset = true
    pcall(function() toggleGui.Parent = game:GetService("CoreGui") end)

    local btn = Instance.new("ImageButton")
    btn.AnchorPoint            = Vector2.new(0.5, 0.5)
    btn.BackgroundTransparency = 1
    btn.BorderSizePixel        = 0
    btn.Position               = UDim2.fromOffset(50, 200)
    btn.Size                   = UDim2.fromOffset(56, 56)
    btn.Image                  = "rbxassetid://139962551928576"
    btn.ZIndex                 = 10
    btn.Parent                 = toggleGui

    -- ... drag + click logic (see cook_and_sell.lua for full implementation)
end
```

> **Note:** The cleanup loop at the top is required — without it, re-executing the script stacks multiple K buttons on screen.

---

## Remote Helper

Fires a RemoteEvent or invokes a RemoteFunction from `ReplicatedStorage.Riese.Remotes`.

```lua
local RemoteCache = {}

local function getRemote(name)
    if RemoteCache[name] then return RemoteCache[name] end
    local r = ReplicatedStorage:FindFirstChild("Riese")
        and ReplicatedStorage.Riese:FindFirstChild("Remotes")
        and ReplicatedStorage.Riese.Remotes:FindFirstChild(name)
    if r then RemoteCache[name] = r end
    return r
end

local function fireRemote(name, ...)
    local remote = getRemote(name)
    if not remote or not remote.Parent then return end
    pcall(function()
        if remote:IsA("RemoteFunction") then
            remote:InvokeServer(...)
        else
            remote:FireServer(...)
        end
    end)
end
```

---

## Settings Tab (built-in)

Every game script ships a pre-built Settings tab with:

| Groupbox | Contents |
|----------|----------|
| **Menu** | Keybind menu, Auto Execute, Auto Reconnect, Custom Cursor, DPI Scale, Unload |
| **Colors** | Background / Main / Accent / Outline / Font color pickers + Font Face |
| **Themes** | Built-in + custom theme manager |
| **Configuration** | SaveManager auto-save/load |

Wire it up at the bottom of every game script:

```lua
ThemeManager:SetLibrary(Library)
SaveManager:SetLibrary(Library)
SaveManager:IgnoreThemeSettings()
SaveManager:SetFolder("HubLibraryV2/GameName")
ThemeManager:SetFolder("HubLibraryV2")
ThemeManager:ApplyToTabSplit(Tabs.Settings)
SaveManager:BuildConfigSection(Tabs.Settings)
SaveManager:LoadAutoloadConfig()
```

---

## Adding a New Game

1. Get the PlaceId from the Roblox URL (`?placeId=XXXXX`)
2. Create `games/your_game.lua` — use `games/cook_and_sell.lua` as a base
3. Register it in `games/index.lua`:

```lua
return {
    [106131416903029] = "games/cook_and_sell.lua",
    [YOUR_PLACE_ID]   = "games/your_game.lua",
}
```

4. Push to GitHub — the loader fetches it automatically via CDN.

---

## Gotchas

### AddToggle and AddDropdown return the Groupbox, not the element

Chaining `:OnChanged()` after them calls it on the Groupbox — **it silently does nothing**.

```lua
-- WRONG
group:AddToggle("X", {}):OnChanged(fn)      -- fn never fires
group:AddDropdown("Y", {}):OnChanged(fn)    -- fn never fires

-- CORRECT for toggles
group:AddToggle("X", { Callback = function(val) ... end })

-- CORRECT for dropdowns
group:AddDropdown("Y", { Values = {...} })
Library.Options.Y:OnChanged(function(val) ... end)
```

### Library.Options does not store Toggles

Only Dropdowns, Inputs, and Keybinds end up in `Library.Options`. Reading `Library.Options.SomeToggle` returns nil.

```lua
-- WRONG
local on = Library.Options.AutoFarm.Value  -- nil, crashes

-- CORRECT: use a local flag
local autoFarmOn = false
group:AddToggle("AutoFarm", { Callback = function(val) autoFarmOn = val end })
```

---

## Credits

- UI: [Obsidian](https://github.com/deividcomsono/Obsidian) by deividcomsono
- Icons: [Lucide](https://lucide.dev)
