# Kunsy Hub Library — Agent Notes

## Stack
- **Loader**: `loader.lua` — fetches game scripts from GitHub CDN, validates key (DEV MODE: always passes)
- **UI Library**: [Obsidian V2](https://github.com/deividcomsono/Obsidian) — cached locally in `HubLibraryV2/cache/`
- **Game scripts**: `games/<name>.lua` — one file per game, registered in `games/index.lua` by PlaceId

---

## CRITICAL: Obsidian V2 API Quirks

### AddToggle / AddDropdown return `self` (Groupbox), NOT the element

Chaining `:OnChanged()` after `AddToggle()` or `AddDropdown()` silently does nothing — it calls OnChanged on the Groupbox, which is a no-op.

**Toggle — always use `Callback` in the options table:**
```lua
-- WRONG: OnChanged never fires
group:AddToggle("MyToggle", { Text = "Label" }):OnChanged(function(val) ... end)

-- CORRECT
group:AddToggle("MyToggle", { Text = "Label", Default = false,
    Callback = function(val)
        -- val = boolean, fires when user clicks the toggle
    end })
```

**Dropdown — access via `Library.Options` after creation:**
```lua
-- WRONG: OnChanged never fires
group:AddDropdown("MyDrop", { Values = {...} }):OnChanged(function(val) ... end)

-- CORRECT
group:AddDropdown("MyDrop", { Values = {...}, Default = 1 })
Library.Options.MyDrop:OnChanged(function(val) ... end)
```

**Label chaining is fine** — `AddLabel` returns the element:
```lua
group:AddLabel("text"):AddColorPicker("id", opts)  -- OK
```

### Library.Options does NOT store Toggles

`Library.Options["SomeToggleId"]` → nil. Only Dropdowns, Inputs, and Keybinds are stored there.

Never read toggle state from `Library.Options`. Always pass the boolean from `Callback`:
```lua
-- WRONG: always nil
local enabled = Library.Options.AutoCashier.Value

-- CORRECT: use a local flag set by the Callback
local autoCashierEnabled = false
group:AddToggle("AutoCashier", { Callback = function(val)
    autoCashierEnabled = val
end })
```

### Heartbeat loop pattern (`trackInterval`)

All game scripts use this helper — pass `enabled` directly from Callback:
```lua
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

-- Usage in toggle:
group:AddToggle("AutoFarm", { Default = false,
    Callback = function(val) trackInterval("FarmLoop", val, 0.5, doFarm) end })
```

### Custom Cursor — hides system cursor on PC

Set `ShowCustomCursor = false` in Window options and force-restore after init:
```lua
local Window = Library:CreateWindow({
    ShowCustomCursor = false,
    ...
})
game:GetService("UserInputService").MouseIconEnabled = true

-- Also restore on every menu toggle:
task.defer(function() game:GetService("UserInputService").MouseIconEnabled = true end)
```

### KunsyToggle stacking on re-execute

Before creating the floating K button, destroy all existing ones:
```lua
pcall(function()
    for _, v in ipairs(game:GetService("CoreGui"):GetChildren()) do
        if v.Name == "KunsyToggle" then v:Destroy() end
    end
end)
```

---

## Adding a New Game

1. Find PlaceId from Roblox URL
2. Create `games/<game_name>.lua` — copy structure from `games/cook_and_sell.lua`
3. Add to `games/index.lua`: `[PlaceId] = "games/<game_name>.lua"`
4. Push to GitHub — loader picks it up automatically via CDN

## DEV MODE

`loader.lua` line 265: `if true then return true, "free" end` — bypasses key validation. Remove when backend is ready.
