# Hub Library V2 — Roblox UI Library (Obsidian)

Built on top of [Obsidian](https://github.com/deividcomsono/Obsidian) by deividcomsono.

Load with one line:

```lua
loadstring(game:HttpGet("https://raw.githubusercontent.com/Kunsyy/hub-library/master/ObsidianLibrary.lua"))()
```

---

## Quick Start

```lua
-- Load the hub (handles Obsidian + ThemeManager + SaveManager internally)
loadstring(game:HttpGet("https://raw.githubusercontent.com/Kunsyy/hub-library/master/ObsidianLibrary.lua"))()
```

The script auto-creates the window, sidebar tabs, and Settings tab. To add your own tabs/groupboxes, edit `ObsidianLibrary.lua`.

---

## Adding Tabs & Groupboxes

```lua
local Window = Library:CreateWindow({
    Title  = "Hub Library V2",
    Icon   = "rbxassetid://139962551928576",
    Size   = UDim2.fromOffset(700, 520),
    Center = true,
})

-- Icon-only sidebar tabs (no text)
local Tabs = {
    Main     = Window:AddTab("", "cpu"),
    Settings = Window:AddTab("", "settings"),
}

-- Groupboxes
local Group = Tabs.Main:AddLeftGroupbox("Base", "layout-grid")
Group:AddToggle("AutoFarm", { Text = "Auto Farm", Default = false })
Group:AddSlider("Speed", { Text = "Speed", Min = 0, Max = 100, Default = 16 })
Group:AddDropdown("Mode", { Text = "Mode", Values = { "Safe", "Fast" }, Default = 1 })
Group:AddButton("Teleport", function() end)
```

---

## Groupbox with Sub-Tabs

```lua
-- Returns an array of proxy objects, one per sub-tab
local Proxies = GroupWithTabs(Tabs.Main, "left", "Base", "layout-grid", {
    "layout-grid",  -- tab 1 icon
    "eye",          -- tab 2 icon
    "zap",          -- tab 3 icon
})

local Tab1 = Proxies[1]
Tab1:AddToggle("AutoSell", { Text = "Auto Sell", Default = true })

local Tab2 = Proxies[2]
Tab2:AddToggle("ESP", { Text = "ESP", Default = false })
```

---

## Min / Max Row

```lua
-- Side-by-side Min / Max textboxes inside any groupbox or sub-tab proxy
AddMinMaxRow(Group, "Generation To Sell (Min - Max)", 0, 10)
```

---

## Settings Tab (built-in)

The Settings tab is pre-built with:

| Section | Contents |
|---------|----------|
| **Menu** (left) | Open Keybind Menu, Auto Execute, Auto Reconnect, Custom Cursor, DPI Scale, Menu Bind, Unload |
| **Colors** (left) | Background / Main / Accent / Outline / Font color pickers, Font Face dropdown |
| **Themes** (right) | Built-in theme list, Set as default, Custom themes (create / load / overwrite / delete) |
| **Configuration** (right) | SaveManager config section (auto-save / load) |

---

## Features

- **Icon-only sidebar** — compact 48 px width, no labels
- **Auto-collapse chevron** — every groupbox collapses with a click; applies to all groupboxes automatically including those added by ThemeManager / SaveManager
- **Sub-tab system** — icon-only tab bar inside any groupbox, with depth layer effect
- **Android-safe caching** — Obsidian source files cached locally with `readfile`/`writefile`; graceful fallback to `HttpGet`
- **Thin outlines** — 0.5 px stroke instead of the default 1 / 1.5 px
- **Custom logo** — Roblox asset at top of sidebar

---

## Credits

- UI Framework: [Obsidian](https://github.com/deividcomsono/Obsidian) by deividcomsono
- Icons: [Lucide](https://lucide.dev) via [lucide-roblox-direct](https://github.com/deividcomsono/lucide-roblox-direct)
