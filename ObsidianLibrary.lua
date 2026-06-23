-- =============================================
-- Hub Library V2
-- Author  : Kunsyy
-- Version : 2.0.0
-- =============================================

local VERSION    = "2.0.0"
local CACHE_DIR  = "HubLibraryV2/cache/"
local OBSIDIAN   = "https://raw.githubusercontent.com/deividcomsono/Obsidian/main/"

-- Detect mobile (no custom cursor, larger touch targets)
local IS_MOBILE  = (game:GetService("UserInputService").TouchEnabled
    and not game:GetService("UserInputService").KeyboardEnabled)

-- ── Cache helpers ────────────────────────────────────────────────────────────
local function safeRead(path)
    local ok, data = pcall(readfile, path)
    return (ok and data and #data > 256) and data or nil
end

local function safeWrite(path, data)
    pcall(function()
        if not isfolder(CACHE_DIR) then makefolder(CACHE_DIR) end
        writefile(path, data)
    end)
end

local function fetchCached(filename)
    local path = CACHE_DIR .. filename
    local cached = safeRead(path)
    if cached then return cached end
    local data = game:HttpGet(OBSIDIAN .. filename)
    safeWrite(path, data)
    return data
end
-- ─────────────────────────────────────────────────────────────────────────────

local Library      = loadstring(fetchCached("Library.lua"))()
local ThemeManager = loadstring(fetchCached("addons/ThemeManager.lua"))()
local SaveManager  = loadstring(fetchCached("addons/SaveManager.lua"))()

-- Split Themes tab: Colors (left groupbox) + Presets (right groupbox)
function ThemeManager:ApplyToTabSplit(tab)
    assert(self.Library, "Must set ThemeManager.Library first!")
    local L = self.Library
    local colorsBox  = tab:AddLeftGroupbox("Colors",  "paintbrush")
    local presetsBox = tab:AddRightGroupbox("Themes",  "palette")

    colorsBox:AddLabel("Background color"):AddColorPicker("BackgroundColor", { Default = L.Scheme.BackgroundColor })
    colorsBox:AddLabel("Main color")      :AddColorPicker("MainColor",       { Default = L.Scheme.MainColor })
    colorsBox:AddLabel("Accent color")    :AddColorPicker("AccentColor",     { Default = L.Scheme.AccentColor })
    colorsBox:AddLabel("Outline color")   :AddColorPicker("OutlineColor",    { Default = L.Scheme.OutlineColor })
    colorsBox:AddLabel("Font color")      :AddColorPicker("FontColor",       { Default = L.Scheme.FontColor })
    colorsBox:AddDropdown("FontFace", {
        Text = "Font Face", Default = "Code",
        Values = { "BuilderSans","Code","Fantasy","Gotham","Jura","Roboto","RobotoMono","SourceSans" },
    })

    local ThemesArray = {}
    for Name in pairs(self.BuiltInThemes) do table.insert(ThemesArray, Name) end
    table.sort(ThemesArray, function(a, b) return self.BuiltInThemes[a][1] < self.BuiltInThemes[b][1] end)

    presetsBox:AddDropdown("ThemeManager_ThemeList", { Text = "Theme list", Values = ThemesArray, Default = 1 })
    presetsBox:AddButton("Set as default", function()
        self:SaveDefault(L.Options.ThemeManager_ThemeList.Value)
        L:Notify(string.format("Set default theme to %q", L.Options.ThemeManager_ThemeList.Value))
    end)
    L.Options.ThemeManager_ThemeList:OnChanged(function() self:ApplyTheme(L.Options.ThemeManager_ThemeList.Value) end)

    presetsBox:AddDivider()
    presetsBox:AddInput("ThemeManager_CustomThemeName", { Text = "Custom theme name" })
    presetsBox:AddButton("Create theme", function()
        local name = L.Options.ThemeManager_CustomThemeName.Value
        if name:gsub(" ", "") == "" then L:Notify("Invalid theme name", 2) return end
        self:SaveCustomTheme(name)
        L:Notify(string.format("Created theme %q", name))
        L.Options.ThemeManager_CustomThemeList:SetValues(self:ReloadCustomThemes())
        L.Options.ThemeManager_CustomThemeList:SetValue(nil)
    end)
    presetsBox:AddDivider()
    presetsBox:AddDropdown("ThemeManager_CustomThemeList", { Text = "Custom themes", Values = self:ReloadCustomThemes(), AllowNull = true, Default = 1 })
    presetsBox:AddButton("Load theme",      function() self:ApplyTheme(L.Options.ThemeManager_CustomThemeList.Value) end)
    presetsBox:AddButton("Overwrite theme", function() self:SaveCustomTheme(L.Options.ThemeManager_CustomThemeList.Value) end)
    presetsBox:AddButton("Delete theme", function()
        local ok, err = self:Delete(L.Options.ThemeManager_CustomThemeList.Value)
        if not ok then L:Notify("Failed: " .. err) return end
        L:Notify("Deleted theme") ; L.Options.ThemeManager_CustomThemeList:SetValues(self:ReloadCustomThemes()) ; L.Options.ThemeManager_CustomThemeList:SetValue(nil)
    end)
    presetsBox:AddButton("Refresh list", function()
        L.Options.ThemeManager_CustomThemeList:SetValues(self:ReloadCustomThemes()) ; L.Options.ThemeManager_CustomThemeList:SetValue(nil)
    end)
    presetsBox:AddButton("Reset default", function()
        pcall(delfile, self.Folder .. "/themes/default.txt")
        L:Notify("Reset default theme")
    end)

    self:LoadDefault() ; self.AppliedToTab = true
    local function upd() self:ThemeUpdate() end
    L.Options.BackgroundColor:OnChanged(upd) ; L.Options.MainColor:OnChanged(upd)
    L.Options.AccentColor:OnChanged(upd)     ; L.Options.OutlineColor:OnChanged(upd)
    L.Options.FontColor:OnChanged(upd)
    L.Options.FontFace:OnChanged(function(v) L:SetFont(Enum.Font[v]) ; L:UpdateColorsUsingRegistry() end)
end

-- Thin all outline strokes (0.5px instead of default 1/1.5)
local _origAddOutline = Library.AddOutline
Library.AddOutline = function(self, Frame)
    local OutlineStroke, ShadowStroke = _origAddOutline(self, Frame)
    if OutlineStroke then OutlineStroke.Thickness = 0.5 end
    if ShadowStroke  then ShadowStroke.Thickness  = 0.5 end
    return OutlineStroke, ShadowStroke
end

if getgenv().HubLibrary_Loaded then
    pcall(function() getgenv().HubLibrary_Instance:Unload() end)
end
getgenv().HubLibrary_Loaded   = true
getgenv().HubLibrary_Version  = VERSION

local RunService = game:GetService("RunService")

local Window = Library:CreateWindow({
    Title            = "Hub Library V2",
    Icon             = "rbxassetid://139962551928576",
    IconSize         = UDim2.fromOffset(38, 38),
    Size             = UDim2.fromOffset(700, 520),
    Center           = true,
    AutoShow         = true,
    ShowCustomCursor = not IS_MOBILE,
    NotifySide       = "Right",
})
getgenv().HubLibrary_Instance = Library
Window:SetSidebarWidth(48)

local Tabs = {
    Info     = Window:AddTab("", "info"),
    Main     = Window:AddTab("", "cpu"),
    Misc     = Window:AddTab("", "wrench"),
    Profile  = Window:AddTab("", "user"),
    Settings = Window:AddTab("", "settings"),
}
Tabs.Main:Show()

-- Tracks all GroupWithTabs entries for deferred resize
local AllGroupEntries = {}

-- =============================================
-- HELPER: Auto collapse chevron on any groupbox
-- =============================================
local function AddCollapseToGroupbox(Group)
    local S = Library.Scheme
    local collapsed = false

    -- Hide any pre-existing TextButton Obsidian may have placed in the header
    for _, child in Group.Holder:GetChildren() do
        if child:IsA("TextButton") then child.Visible = false end
    end

    local CollapseBtn = Instance.new("TextButton")
    CollapseBtn.AnchorPoint            = Vector2.new(1, 0.5)
    CollapseBtn.BackgroundTransparency = 1
    CollapseBtn.Position               = UDim2.new(1, -8, 0, 17)
    CollapseBtn.Size                   = UDim2.fromOffset(22, 22)
    CollapseBtn.Text                   = ""
    CollapseBtn.ZIndex                 = 10
    CollapseBtn.Parent                 = Group.Holder

    local chevron = Library:GetCustomIcon("chevron-up")
    local ChevronIndicator

    if chevron and chevron.Url then
        local img = Instance.new("ImageLabel")
        img.AnchorPoint            = Vector2.new(0.5, 0.5)
        img.BackgroundTransparency = 1
        img.Image                  = chevron.Url
        img.ImageColor3            = S.FontColor
        img.Position               = UDim2.fromScale(0.5, 0.5)
        img.Size                   = UDim2.fromOffset(14, 14)
        if chevron.ImageRectSize and chevron.ImageRectSize ~= Vector2.zero then
            img.ImageRectOffset = chevron.ImageRectOffset
            img.ImageRectSize   = chevron.ImageRectSize
        end
        img.Parent       = CollapseBtn
        ChevronIndicator = img
    else
        -- Text fallback when icon pack isn't available
        local txt = Instance.new("TextLabel")
        txt.AnchorPoint            = Vector2.new(0.5, 0.5)
        txt.BackgroundTransparency = 1
        txt.Position               = UDim2.fromScale(0.5, 0.5)
        txt.Size                   = UDim2.fromScale(1, 1)
        txt.Text                   = "∧"
        txt.TextColor3             = S.FontColor
        txt.TextSize               = 13
        txt.Font                   = Enum.Font.GothamBold
        txt.ZIndex                 = 11
        txt.Parent                 = CollapseBtn
        ChevronIndicator           = txt
    end

    CollapseBtn.MouseButton1Click:Connect(function()
        collapsed = not collapsed
        Group.Container.Visible = not collapsed
        if collapsed then
            Group.Holder.Size = UDim2.new(1, 0, 0, 35)
            if ChevronIndicator:IsA("ImageLabel") then
                ChevronIndicator.Rotation = 180
            else
                ChevronIndicator.Text = "∨"
            end
        else
            Group:Resize()
            if ChevronIndicator:IsA("ImageLabel") then
                ChevronIndicator.Rotation = 0
            else
                ChevronIndicator.Text = "∧"
            end
        end
    end)
end

-- Wrap a tab so every AddLeftGroupbox/AddRightGroupbox call auto-gets a chevron
local function WrapTabCollapse(tab)
    local origLeft  = tab.AddLeftGroupbox
    local origRight = tab.AddRightGroupbox
    tab.AddLeftGroupbox = function(self, ...)
        local group = origLeft(self, ...)
        AddCollapseToGroupbox(group)
        return group
    end
    tab.AddRightGroupbox = function(self, ...)
        local group = origRight(self, ...)
        AddCollapseToGroupbox(group)
        return group
    end
end

for _, tab in pairs(Tabs) do
    WrapTabCollapse(tab)
end

-- =============================================
-- HELPER: Groupbox with icon-only sub-tabs
-- =============================================
local function GroupWithTabs(parentTab, side, title, titleIcon, iconList)
    local S = Library.Scheme
    local Group = side == "left"
        and parentTab:AddLeftGroupbox(title, titleIcon)
        or  parentTab:AddRightGroupbox(title, titleIcon)
    -- collapse button already added by WrapTabCollapse above

    local TabBar = Instance.new("Frame")
    TabBar.BackgroundColor3 = S.DarkColor
    TabBar.BorderSizePixel  = 0
    TabBar.LayoutOrder      = 0
    TabBar.Size             = UDim2.new(1, 0, 0, 34)
    TabBar.Parent           = Group.Container

    local BarLayout = Instance.new("UIListLayout")
    BarLayout.FillDirection  = Enum.FillDirection.Horizontal
    BarLayout.HorizontalFlex = Enum.UIFlexAlignment.Fill
    BarLayout.Parent         = TabBar

    local tabs = {}

    for i, iconName in ipairs(iconList) do
        local isFirst = i == 1

        local Btn = Instance.new("TextButton")
        Btn.BackgroundColor3 = isFirst and S.MainColor or S.DarkColor
        Btn.BorderSizePixel  = 0
        Btn.LayoutOrder      = i
        Btn.Size             = UDim2.fromOffset(0, 34)
        Btn.Text             = ""
        Btn.Parent           = TabBar

        local iconData = Library:GetCustomIcon(iconName)
        local iconImg
        if iconData then
            iconImg = Instance.new("ImageLabel")
            iconImg.AnchorPoint            = Vector2.new(0.5, 0.5)
            iconImg.BackgroundTransparency = 1
            iconImg.Image                  = iconData.Url
            iconImg.ImageColor3            = S.WhiteColor
            iconImg.ImageTransparency      = isFirst and 0 or 0.55
            iconImg.Position               = UDim2.fromScale(0.5, 0.5)
            iconImg.Size                   = UDim2.fromOffset(16, 16)
            if iconData.ImageRectSize and iconData.ImageRectSize ~= Vector2.zero then
                iconImg.ImageRectOffset = iconData.ImageRectOffset
                iconImg.ImageRectSize   = iconData.ImageRectSize
            end
            iconImg.Parent = Btn
        end

        local Content = Instance.new("Frame")
        Content.BackgroundTransparency = 1
        Content.LayoutOrder            = i + 10
        Content.Size                   = UDim2.new(1, 0, 0, 0)
        Content.Visible                = isFirst
        Content.Name                   = "SubTabContent" .. i
        Content.Parent                 = Group.Container

        local CLayout = Instance.new("UIListLayout")
        CLayout.Padding = UDim.new(0, 8)
        CLayout.Parent  = Content

        local capturedContent = Content
        local capturedCLayout = CLayout

        local Proxy = {
            Container       = Content,
            Elements        = Group.Elements,
            DependencyBoxes = {},
            Tab             = Group.Tab,
        }
        -- Direct field prevents __namecall from firing
        Proxy.Resize = function()
            capturedContent.Size = UDim2.new(1, 0, 0,
                capturedCLayout.AbsoluteContentSize.Y / Library.DPIScale)
            Group:Resize()
        end
        setmetatable(Proxy, getmetatable(Group))

        table.insert(tabs, {
            Btn     = Btn,
            Img     = iconImg,
            Content = Content,
            Proxy   = Proxy,
            CLayout = capturedCLayout,
            Group   = Group,
        })
    end

    -- Click handlers
    for i, t in ipairs(tabs) do
        t.Btn.MouseButton1Click:Connect(function()
            for j, o in ipairs(tabs) do
                local active = j == i
                o.Content.Visible      = active
                o.Btn.BackgroundColor3 = active and S.MainColor or S.DarkColor
                if o.Img then
                    o.Img.ImageColor3       = S.WhiteColor
                    o.Img.ImageTransparency = active and 0 or 0.55
                end
            end
            -- Resize newly visible tab
            local h = t.CLayout.AbsoluteContentSize.Y / Library.DPIScale
            t.Content.Size = UDim2.new(1, 0, 0, h)
            Group:Resize()
        end)
    end

    -- Register for deferred resize
    for _, t in ipairs(tabs) do
        table.insert(AllGroupEntries, t)
    end

    local proxies = {}
    for _, t in ipairs(tabs) do table.insert(proxies, t.Proxy) end
    return proxies
end

-- =============================================
-- HELPER: Side-by-side Min/Max textboxes
-- =============================================
local function AddMinMaxRow(proxy, labelText, defaultMin, defaultMax)
    local S = Library.Scheme

    local Row = Instance.new("Frame")
    Row.BackgroundTransparency = 1
    Row.Size   = UDim2.new(1, 0, 0, 44)
    Row.Parent = proxy.Container

    local Lbl = Instance.new("TextLabel")
    Lbl.BackgroundTransparency = 1
    Lbl.Size             = UDim2.new(1, 0, 0, 18)
    Lbl.Text             = labelText
    Lbl.TextSize         = 14
    Lbl.TextColor3       = S.FontColor
    Lbl.TextTransparency = 0.4
    Lbl.TextXAlignment   = Enum.TextXAlignment.Left
    Lbl.Font             = Enum.Font.GothamMedium
    Lbl.Parent           = Row

    local InputRow = Instance.new("Frame")
    InputRow.BackgroundTransparency = 1
    InputRow.Position               = UDim2.fromOffset(0, 22)
    InputRow.Size                   = UDim2.new(1, 0, 0, 22)
    InputRow.Parent                 = Row

    local RowLayout = Instance.new("UIListLayout")
    RowLayout.FillDirection = Enum.FillDirection.Horizontal
    RowLayout.Padding       = UDim.new(0, 6)
    RowLayout.Parent        = InputRow

    for _, default in ipairs({ defaultMin, defaultMax }) do
        local Box = Instance.new("Frame")
        Box.BackgroundColor3 = S.MainColor
        Box.Size             = UDim2.new(0.5, -3, 1, 0)
        Box.Parent           = InputRow
        Instance.new("UICorner", Box).CornerRadius = UDim.new(0, 4)
        Library:AddOutline(Box)

        local TBox = Instance.new("TextBox")
        TBox.AnchorPoint            = Vector2.new(0.5, 0.5)
        TBox.BackgroundTransparency = 1
        TBox.Position               = UDim2.fromScale(0.5, 0.5)
        TBox.Size                   = UDim2.new(1, -8, 1, 0)
        TBox.Text                   = tostring(default)
        TBox.TextSize               = 13
        TBox.TextColor3             = S.FontColor
        TBox.Font                   = Enum.Font.GothamMedium
        TBox.ClearTextOnFocus       = false
        TBox.Parent                 = Box
    end
end

-- =============================================
-- MAIN TAB
-- =============================================

local BaseTabs = GroupWithTabs(Tabs.Main, "left", "Base", "layout-grid", {"layout-grid", "eye", "zap"})
local BaseMain = BaseTabs[1]
BaseMain:AddDropdown("BrainrotSelect", {
    Text = "Select Brainrot to Sell", Default = 1,
    Values = { "---", "Item 1", "Item 2" }, Multi = false,
})
BaseMain:AddDropdown("RaritySelect", {
    Text = "Select Rarities to Sell", Default = 1,
    Values = { "---", "Common", "Rare", "Legendary" }, Multi = false,
})
AddMinMaxRow(BaseMain, "Generation To Sell (Min - Max)", 0, 10)
BaseMain:AddToggle("AutoSell", { Text = "Auto Sell Brainrot", Default = true })
BaseMain:AddToggle("GateESP",  { Text = "Gate ESP",           Default = true })

local BrainrotTabs = GroupWithTabs(Tabs.Main, "left", "Brainrot", "shopping-cart", {"shopping-cart"})
BrainrotTabs[1]:AddDropdown("BrainrotBuy", {
    Text = "Select Brainrot to Buy", Default = 1,
    Values = { "---", "Item A", "Item B" }, Multi = false,
})

local GearTabs = GroupWithTabs(Tabs.Main, "right", "Gear", "crosshair", {"shield", "shopping-cart"})
local GearMain = GearTabs[1]
GearMain:AddToggle("AimbotToggle", {
    Text = "Aimbot (Laser/Web)", Default = true,
}):AddKeyPicker("AimbotKey", {
    Default = "F7", SyncToggleState = true,
    Mode = "Toggle", Text = "Aimbot (Laser/Web)", NoUI = false,
})
GearMain:AddDropdown("ExcludePlayers", {
    Text = "Exclude Players (Laser)", Default = 1,
    Values = { "---", "Player1", "Player2" }, Multi = false,
})
GearMain:AddToggle("AutoLaserCape",      { Text = "Auto Use Laser Cape",    Default = true })
GearMain:AddToggle("AutoWebSlinger",     { Text = "Auto Use Web Slinger",   Default = true })
GearMain:AddToggle("AutoDestroyTurrets", { Text = "Auto Destroy Turrets",   Default = true })

local StealTabs = GroupWithTabs(Tabs.Main, "right", "Steal Utilities/Anti Hit", "bug", {"bug", "zap"})
local StealMain = StealTabs[1]
StealMain:AddToggle("AutoStealBest",    { Text = "Auto-Steal Best",    Default = true })
StealMain:AddToggle("AutoStealNearest", { Text = "Auto-Steal Nearest", Default = true })
StealMain:AddSlider("AutoFlingDist", {
    Text = "Auto Fling Distance", Default = 8, Min = 0, Max = 50, Rounding = 0,
})

-- =============================================
-- SETTINGS TAB
-- =============================================
local MenuGroup = Tabs.Settings:AddLeftGroupbox("Menu", "menu")

MenuGroup:AddButton("Open Keybind Menu", function()
    if Library.KeybindFrame then
        Library.KeybindFrame.Visible = not Library.KeybindFrame.Visible
    end
end)

MenuGroup:AddToggle("AutoExecute",    { Text = "Auto Execute",    Default = false })
MenuGroup:AddToggle("AutoReconnect",  { Text = "Auto Reconnect",  Default = false })
MenuGroup:AddToggle("RejoinPingFreeze", {
    Text = "Rejoin If Ping Freezes for 20 mins", Default = false,
})

MenuGroup:AddToggle("CustomCursor", {
    Text = "Custom Cursor", Default = not IS_MOBILE,
}):OnChanged(function(val)
    Library.ShowCustomCursor = val
end)

MenuGroup:AddToggle("ShowWatermark",  { Text = "Show Watermark",  Default = true })

MenuGroup:AddToggle("NotifyOnError", {
    Text = "Notify On Error", Default = true,
}):OnChanged(function(val)
    Library.NotifyOnError = val
end)

MenuGroup:AddDropdown("NotifySide", {
    Text = "Notification Side", Default = 1,
    Values = { "Right", "Left" }, Multi = false,
}):OnChanged(function(val)
    Library.NotifySide = val
end)

MenuGroup:AddDropdown("DPIScale", {
    Text = "DPI Scale", Default = 2,
    Values = { "75%", "100%", "125%", "150%" }, Multi = false,
}):OnChanged(function(val)
    local map = { ["75%"] = 75, ["100%"] = 100, ["125%"] = 125, ["150%"] = 150 }
    Library:SetDPIScale(map[val] or 100)
end)

MenuGroup:AddLabel("Menu bind"):AddKeyPicker("MenuKeybind", {
    Default = "RightShift", NoUI = true, Text = "Menu keybind",
})
Library.ToggleKeybind = Library.Options.MenuKeybind

MenuGroup:AddButton("Unload", function() Library:Unload() end)

ThemeManager:SetLibrary(Library)
SaveManager:SetLibrary(Library)
SaveManager:IgnoreThemeSettings()
SaveManager:SetFolder("HubLibraryV2")
ThemeManager:SetFolder("HubLibraryV2")
ThemeManager:ApplyToTabSplit(Tabs.Settings)   -- Colors left, Themes presets right
SaveManager:BuildConfigSection(Tabs.Settings)
SaveManager:LoadAutoloadConfig()

-- =============================================
-- DEFERRED RESIZE — 2 frames for layout to settle
-- =============================================
task.spawn(function()
    RunService.Heartbeat:Wait()
    RunService.Heartbeat:Wait()

    -- Pass 1: size each SubTabContent frame
    for _, entry in ipairs(AllGroupEntries) do
        local h = entry.CLayout.AbsoluteContentSize.Y / Library.DPIScale
        entry.Content.Size = UDim2.new(1, 0, 0, h)
    end

    RunService.Heartbeat:Wait()

    -- Pass 2: size each outer Groupbox now that SubTabContent sizes are set
    local resizedGroups = {}
    for _, entry in ipairs(AllGroupEntries) do
        if not resizedGroups[entry.Group] then
            resizedGroups[entry.Group] = true
            entry.Group:Resize()
        end
    end
end)
