-- =============================================
-- Cook and Sell — Auto Farm
-- Part of Kunsy Hub Library V2
-- =============================================

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService        = game:GetService("RunService")
local Players           = game:GetService("Players")

local CACHE_DIR = "HubLibraryV2/cache/"
local OBSIDIAN  = "https://raw.githubusercontent.com/deividcomsono/Obsidian/main/"

local IS_MOBILE = (game:GetService("UserInputService").TouchEnabled
    and not game:GetService("UserInputService").KeyboardEnabled)

-- ── Cache helpers ─────────────────────────────────────────────────────────────

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
    local path   = CACHE_DIR .. filename
    local cached = safeRead(path)
    if cached then return cached end
    local data = game:HttpGet(OBSIDIAN .. filename)
    safeWrite(path, data)
    return data
end

-- ── Load Obsidian ─────────────────────────────────────────────────────────────

local Library      = loadstring(fetchCached("Library.lua"))()
local ThemeManager = loadstring(fetchCached("addons/ThemeManager.lua"))()
local SaveManager  = loadstring(fetchCached("addons/SaveManager.lua"))()

-- ── ThemeManager split (Colors left / Themes right) ──────────────────────────

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
        L:Notify("Deleted theme")
        L.Options.ThemeManager_CustomThemeList:SetValues(self:ReloadCustomThemes())
        L.Options.ThemeManager_CustomThemeList:SetValue(nil)
    end)
    presetsBox:AddButton("Refresh list", function()
        L.Options.ThemeManager_CustomThemeList:SetValues(self:ReloadCustomThemes())
        L.Options.ThemeManager_CustomThemeList:SetValue(nil)
    end)
    presetsBox:AddButton("Reset default", function()
        pcall(delfile, self.Folder .. "/themes/default.txt")
        L:Notify("Reset default theme")
    end)

    self:LoadDefault()
    self.AppliedToTab = true
    local function upd() self:ThemeUpdate() end
    L.Options.BackgroundColor:OnChanged(upd) ; L.Options.MainColor:OnChanged(upd)
    L.Options.AccentColor:OnChanged(upd)     ; L.Options.OutlineColor:OnChanged(upd)
    L.Options.FontColor:OnChanged(upd)
    L.Options.FontFace:OnChanged(function(v) L:SetFont(Enum.Font[v]) ; L:UpdateColorsUsingRegistry() end)
end

-- ── Thin outlines ─────────────────────────────────────────────────────────────

local _origAddOutline = Library.AddOutline
Library.AddOutline = function(self, Frame)
    local OutlineStroke, ShadowStroke = _origAddOutline(self, Frame)
    if OutlineStroke then OutlineStroke.Thickness = 0.5 end
    if ShadowStroke  then ShadowStroke.Thickness  = 0.5 end
    return OutlineStroke, ShadowStroke
end

-- ── Guard: unload previous instance ──────────────────────────────────────────

if getgenv().KunsyCookLoaded then
    pcall(function() getgenv().KunsyCookInstance:Unload() end)
end
getgenv().KunsyCookLoaded   = true

-- ── Window ────────────────────────────────────────────────────────────────────

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
getgenv().KunsyCookInstance = Library
Window:SetSidebarWidth(48)
game:GetService("UserInputService").MouseIconEnabled = true

-- ── Toggle button (all devices) ───────────────────────────────────────────────

do
    local UIS = game:GetService("UserInputService")
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
    btn.ImageColor3            = Color3.fromRGB(255, 255, 255)
    btn.ZIndex                 = 10
    btn.Parent                 = toggleGui

    local dragging, dragStart, posStart = false, nil, nil

    local function beginDrag(pos)
        dragging  = false
        dragStart = pos
        posStart  = btn.Position
    end

    local function moveDrag(pos)
        if not dragStart then return end
        local delta = pos - dragStart
        if delta.Magnitude > 8 then dragging = true end
        if dragging then
            local vp = workspace.CurrentCamera.ViewportSize
            btn.Position = UDim2.fromOffset(
                math.clamp(posStart.X.Offset + delta.X, 28, vp.X - 28),
                math.clamp(posStart.Y.Offset + delta.Y, 28, vp.Y - 28)
            )
        end
    end

    local function endDrag(wasClick)
        if wasClick and not dragging then
            local shown = Library.ScreenGui.Enabled
            Library.ScreenGui.Enabled = not shown
            Library.Toggled           = shown
            btn.ImageTransparency     = shown and 0.5 or 0
            task.defer(function() game:GetService("UserInputService").MouseIconEnabled = true end)
        end
        dragging  = false
        dragStart = nil
    end

    btn.InputBegan:Connect(function(input)
        local t = input.UserInputType
        if t == Enum.UserInputType.Touch then
            beginDrag(input.Position)
        elseif t == Enum.UserInputType.MouseButton1 then
            beginDrag(Vector2.new(input.Position.X, input.Position.Y))
        end
    end)

    btn.InputChanged:Connect(function(input)
        local t = input.UserInputType
        if t == Enum.UserInputType.Touch or t == Enum.UserInputType.MouseMovement then
            moveDrag(Vector2.new(input.Position.X, input.Position.Y))
        end
    end)

    btn.InputEnded:Connect(function(input)
        local t = input.UserInputType
        if t == Enum.UserInputType.Touch or t == Enum.UserInputType.MouseButton1 then
            endDrag(true)
        end
    end)
end

-- ── Tabs ──────────────────────────────────────────────────────────────────────

local Tabs = {
    Farm     = Window:AddTab("", "bot"),
    Shop     = Window:AddTab("", "shopping-cart"),
    Cook     = Window:AddTab("", "cooking-pot"),
    Misc     = Window:AddTab("", "wrench"),
    Settings = Window:AddTab("", "settings"),
}
Tabs.Farm:Show()

-- ── Auto-collapse all groupboxes ──────────────────────────────────────────────

local function AddCollapseToGroupbox(Group)
    local S = Library.Scheme
    local collapsed = false
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

for _, tab in pairs(Tabs) do WrapTabCollapse(tab) end

-- ═════════════════════════════════════════════════════════════════════════════
-- GAME LOGIC
-- ═════════════════════════════════════════════════════════════════════════════

-- ── Remote helper ─────────────────────────────────────────────────────────────

local RemoteCache = {}

local function getRemote(name)
    if RemoteCache[name] then return RemoteCache[name] end
    local riese = ReplicatedStorage:FindFirstChild("Riese")
    if not riese then return nil end
    local remotes = riese:FindFirstChild("Remotes")
    if not remotes then return nil end
    local remote = remotes:FindFirstChild(name)
    if remote then RemoteCache[name] = remote end
    return remote
end

local function fireRemote(name, ...)
    local remote = getRemote(name)
    if not remote or not remote.Parent then return end
    local args = { ... }
    pcall(function()
        if remote:IsA("RemoteFunction") then
            remote:InvokeServer(table.unpack(args))
        else
            remote:FireServer(table.unpack(args))
        end
    end)
end

-- ── Connection manager (replaces Library:TrackConnection) ────────────────────

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
            local ok, err = pcall(callback)
            if not ok then warn("[CookAndSell]", err) end
        end
    end)
end

-- ── Shared module loaders ─────────────────────────────────────────────────────

local function getFoodShop()
    local ok, m = pcall(require, ReplicatedStorage.Riese.Shared.FoodShop)
    return ok and m or nil
end

local function getReplicaManager()
    local ok, m = pcall(require, ReplicatedStorage.Riese.Client.ReplicaControllerManager)
    return ok and m or nil
end

local function getMyPlot()
    local FS = getFoodShop()
    return FS and FS.GetPlayerPlot(Players.LocalPlayer) or nil
end

-- ── Auto Cashier ──────────────────────────────────────────────────────────────

local processingCustomers = {}

local function doAutoCashier()
    local RM = getReplicaManager()
    if not RM then return end
    local myPlot = getMyPlot()
    if not myPlot then return end
    if myPlot:GetAttribute("HasHiredCashier") then return end

    local checkout  = myPlot:FindFirstChild("Checkout")
    local customers = myPlot:FindFirstChild("Customers")
    if not checkout or not customers then return end

    local queue1 = checkout:FindFirstChild("Queue") and checkout.Queue:FindFirstChild("1")

    for k in pairs(processingCustomers) do
        if not k or not k.Parent then processingCustomers[k] = nil end
    end

    for _, c in ipairs(customers:GetChildren()) do
        if processingCustomers[c] then continue end
        local replica = RM.NPCReplicas and RM.NPCReplicas[c]
        if not (replica and replica.Data and replica.Data.QueuePosition == 1) then continue end

        local hrp = c:FindFirstChild("HumanoidRootPart")
        if queue1 and hrp and (hrp.Position - queue1.Position).Magnitude > 5 then continue end

        processingCustomers[c] = true
        task.spawn(function()
            local bagNames = {}
            -- Open checkout (same as tapping the customer)
            fireRemote("ManualCheckoutProgress", "Set", c, bagNames)
            task.wait(0.3)

            -- Scan each bag
            local bagsFolder = checkout:FindFirstChild("Bags")
            if bagsFolder then
                local waited = 0
                while #bagsFolder:GetChildren() == 0 and waited < 20 do
                    task.wait(0.2) ; waited += 1
                end
                for _, bag in ipairs(bagsFolder:GetChildren()) do
                    if bag:IsA("BasePart") then
                        table.insert(bagNames, bag.Name)
                        fireRemote("ManualCheckoutProgress", "Set", c, bagNames)
                        task.wait(0.15)
                    end
                end
            end

            -- Complete checkout
            fireRemote("ManualCheckoutProgress", "Clear", c)
            task.wait(1.5)
            processingCustomers[c] = nil
        end)
        break
    end
end

-- ── Auto Collect Cash ─────────────────────────────────────────────────────────

local function doAutoCollect()
    local myPlot = getMyPlot()
    if not myPlot then return end
    for _, obj in ipairs(myPlot:GetDescendants()) do
        if obj:IsA("ProximityPrompt") and obj.Name == "CashPrompt" then
            pcall(fireproximityprompt, obj)
        end
    end
end

-- ── Auto Upgrade ──────────────────────────────────────────────────────────────

local function doAutoUpgrade()
    fireRemote("BuyPotUpgrade")
    fireRemote("BuyCheckoutUpgrade")
    fireRemote("BuildShopFixture")
    fireRemote("ExpandShop")
end

-- ── Auto Manage (claim from pot + place to counters) ─────────────────────────

local function doAutoManage()
    local myPlot = getMyPlot()
    if not myPlot then return end

    -- Claim ready items from pots
    for _, obj in ipairs(myPlot:GetDescendants()) do
        if obj:IsA("ProximityPrompt") and obj.Name == "ClaimItem" then
            pcall(fireproximityprompt, obj)
        end
    end
    local potFolder = workspace:FindFirstChild("CookingPotClientModel")
    if potFolder then
        for _, obj in ipairs(potFolder:GetDescendants()) do
            if obj:IsA("ProximityPrompt") and obj.Name == "ClaimItem" then
                pcall(fireproximityprompt, obj)
            end
        end
    end

    -- Place held tools to counters
    local char = Players.LocalPlayer.Character
    local counters = myPlot:FindFirstChild("Counters")
    if char and counters then
        for _, t in ipairs(char:GetChildren()) do
            if t:IsA("Tool") then
                for _, counter in ipairs(counters:GetChildren()) do
                    for i = 1, 12 do
                        if counter:FindFirstChild(tostring(i)) then
                            fireRemote("PlaceDownItem", t, counter, i)
                        end
                    end
                end
            end
        end
    end
end

-- ── Auto Daily Reward ─────────────────────────────────────────────────────────

local function doAutoRewards()
    fireRemote("GetDailyLoginReward")
    fireRemote("OpenDailyLoginReward")
end

-- ── Auto Pay Loan ─────────────────────────────────────────────────────────────

local function doAutoLoan()
    fireRemote("PayLoan")
end

-- ── Buy Shop logic ────────────────────────────────────────────────────────────

local function buildItemList()
    local okPD, ProductData = pcall(require, ReplicatedStorage.Riese.Shared.ProductData)
    local RM = getReplicaManager()
    if not okPD or not ProductData or not RM then return {}, {} end

    local replica  = RM.PlayerDataReplica
    local unlocked = replica and replica.Data and replica.Data.UnlockedProducts or {}
    local sorted   = {}
    for id, data in pairs(ProductData) do
        if type(data) == "table" and data.ItemName and unlocked[id] == true then
            table.insert(sorted, { id = id, name = data.ItemName, cost = data.UnitCost or 0 })
        end
    end
    table.sort(sorted, function(a, b) return a.cost < b.cost end)

    local list, meta = {}, {}
    for _, entry in ipairs(sorted) do
        local label = entry.name .. "  [$" .. entry.cost .. "]"
        table.insert(list, label)
        meta[label] = entry.id
    end
    return list, meta
end

local function buildCookList()
    local okPD, ProductData = pcall(require, ReplicatedStorage.Riese.Shared.ProductData)
    local RM = getReplicaManager()
    if not okPD or not ProductData or not RM then return {}, {} end

    local replica  = RM.PlayerDataReplica
    local unlocked = replica and replica.Data and replica.Data.UnlockedProducts or {}
    local sorted   = {}
    for id, data in pairs(ProductData) do
        if type(data) == "table" and data.ItemName and unlocked[id] == true then
            table.insert(sorted, { id = id, name = data.ItemName })
        end
    end
    table.sort(sorted, function(a, b) return a.name < b.name end)

    local list, meta = {}, {}
    for _, entry in ipairs(sorted) do
        table.insert(list, entry.name)
        meta[entry.name] = entry.id
    end
    return list, meta
end

local itemList, itemMeta = buildItemList()
local cookList, cookMeta = buildCookList()

-- ── Auto Cook Recipe ─────────────────────────────────────────────────────────

local cookInProgress  = false
local autoCookEnabled = false

local function findCookPrompt(serverPot)
    for _, obj in ipairs(workspace:GetDescendants()) do
        if obj.Name == "CookingPotClientModel" and obj:IsA("Model") then
            local ref = obj:FindFirstChild("ServerPotRef")
            if ref and ref.Value == serverPot then
                local base = obj:FindFirstChild("Base")
                if base then
                    local pa = base:FindFirstChild("PromptAttachment")
                    if pa then return pa:FindFirstChild("CookingPotCookPrompt") end
                end
            end
        end
    end
end

local function doStartCook()
    if cookInProgress then return end
    local selectedCook = Library.Options.CookRecipe.Value
    local id = cookMeta[selectedCook]
    if not id then return end

    local FS = getFoodShop()
    if not FS then return end
    local myPlot = FS.GetPlayerPlot(Players.LocalPlayer)
    if not myPlot then return end

    local pot = myPlot:FindFirstChild("CookingPotServerModel")
    if not pot then return end

    -- Claim if ready
    if pot:GetAttribute("ReadyToClaim") then
        local prompt = findCookPrompt(pot)
        if prompt then pcall(fireproximityprompt, prompt) end
        return
    end

    local ingCount    = pot:GetAttribute("IngredientCount") or 0
    local ingRequired = pot:GetAttribute("IngredientsRequired") or 6
    if pot:GetAttribute("Cooking") or ingCount >= ingRequired then return end

    -- Start the recipe
    local StartCooking = getRemote("StartCooking")
    if not StartCooking then return end
    local ok, success = pcall(function() return StartCooking:InvokeServer(id) end)
    if not ok or not success then return end

    cookInProgress = true
    task.spawn(function()
        local CookingAction = getRemote("CookingAction")
        if not CookingAction then cookInProgress = false return end

        local localUserId = Players.LocalPlayer.UserId
        task.wait(0.6)

        local iters = 0
        while autoCookEnabled and iters < 60 do
            local curPot = myPlot:FindFirstChild("CookingPotServerModel")
            if not curPot then break end

            local cur = curPot:GetAttribute("IngredientCount") or 0
            local req = curPot:GetAttribute("IngredientsRequired") or 6
            if cur >= req or curPot:GetAttribute("Cooking") then break end

            -- Find available ingredient
            local ingFolder = myPlot:FindFirstChild("SpawnedIngredients")
            if ingFolder then
                for _, ing in ipairs(ingFolder:GetChildren()) do
                    if ing:IsA("BasePart") and ing:GetAttribute("CookingOwnerUserId") == localUserId then
                        local state = ing:GetAttribute("CookingState")
                        if state == "OnTable" or state == "Held" then
                            local slot = ing:GetAttribute("CookingSlotIndex")
                            if slot then
                                pcall(function() CookingAction:InvokeServer("PickUp", slot) end)
                                task.wait(0.35)
                                pcall(function() CookingAction:InvokeServer("AddToPot", nil) end)
                                task.wait(0.5)
                                break
                            end
                        end
                    end
                end
            end

            task.wait(0.3)
            iters += 1
        end

        -- Wait for cooking + claim
        local elapsed = 0
        while autoCookEnabled and elapsed < 300 do
            local curPot = myPlot:FindFirstChild("CookingPotServerModel")
            if not curPot then break end
            if curPot:GetAttribute("ReadyToClaim") then
                task.wait(0.3)
                local prompt = findCookPrompt(curPot)
                if prompt then pcall(fireproximityprompt, prompt) end
                break
            end
            if not curPot:GetAttribute("Cooking") and (curPot:GetAttribute("IngredientCount") or 0) == 0 then
                break
            end
            task.wait(1) ; elapsed += 1
        end

        cookInProgress = false
    end)
end

-- ═════════════════════════════════════════════════════════════════════════════
-- UI — FARM TAB
-- ═════════════════════════════════════════════════════════════════════════════

local FarmGroup = Tabs.Farm:AddLeftGroupbox("Cashier", "users")
FarmGroup:AddToggle("AutoCashier", { Text = "Auto Cashier", Default = false,
    Callback = function(val) trackInterval("CashierLoop", val, 0.5, doAutoCashier) end })
FarmGroup:AddToggle("AutoCollectCash", { Text = "Auto Collect Cash", Default = false,
    Callback = function(val) trackInterval("CollectLoop", val, 1, doAutoCollect) end })

local ManageGroup = Tabs.Farm:AddRightGroupbox("Kitchen", "cooking-pot")
ManageGroup:AddToggle("AutoManage", { Text = "Auto Manage (Claim + Place)", Default = false,
    Callback = function(val) trackInterval("ManageLoop", val, 0.5, doAutoManage) end })
ManageGroup:AddToggle("AutoUpgrade", { Text = "Auto Upgrade", Default = false,
    Callback = function(val) trackInterval("UpgradeLoop", val, 1.5, doAutoUpgrade) end })

-- ═════════════════════════════════════════════════════════════════════════════
-- UI — SHOP TAB
-- ═════════════════════════════════════════════════════════════════════════════

local BuyGroup = Tabs.Shop:AddLeftGroupbox("Buy Shop", "shopping-cart")
BuyGroup:AddDropdown("BuyShopItem", {
    Text   = "Select Item",
    Values = #itemList > 0 and itemList or { "No items unlocked" },
    Default = 1,
})
BuyGroup:AddButton("Order 1", function()
    local label = Library.Options.BuyShopItem.Value
    local id    = itemMeta[label]
    if not id then Library:Notify("No item selected", 2) return end
    task.spawn(function()
        fireRemote("OpenRecipeShop")
        task.wait(0.3)
        fireRemote("BuyRecipeItem", id, 1)
    end)
end)
BuyGroup:AddButton("Order 5", function()
    local label = Library.Options.BuyShopItem.Value
    local id    = itemMeta[label]
    if not id then Library:Notify("No item selected", 2) return end
    task.spawn(function()
        fireRemote("OpenRecipeShop")
        task.wait(0.3)
        fireRemote("BuyRecipeItem", id, 5)
    end)
end)

-- ═════════════════════════════════════════════════════════════════════════════
-- UI — COOK TAB
-- ═════════════════════════════════════════════════════════════════════════════

local CookGroup = Tabs.Cook:AddLeftGroupbox("Recipe", "cooking-pot")
CookGroup:AddDropdown("CookRecipe", {
    Text   = "Select Recipe",
    Values = #cookList > 0 and cookList or { "No recipes unlocked" },
    Default = 1,
})
CookGroup:AddToggle("AutoCookRecipe", { Text = "Auto Cook", Default = false,
    Callback = function(val)
        autoCookEnabled = val
        cookInProgress  = false
        trackInterval("AutoCookLoop", val, 2, doStartCook)
    end })

-- ═════════════════════════════════════════════════════════════════════════════
-- UI — MISC TAB
-- ═════════════════════════════════════════════════════════════════════════════

local MiscGroup = Tabs.Misc:AddLeftGroupbox("Daily & Loan", "calendar")
MiscGroup:AddToggle("AutoReward", { Text = "Auto Daily Reward", Default = false,
    Callback = function(val) trackInterval("RewardLoop", val, 5, doAutoRewards) end })
MiscGroup:AddToggle("AutoLoan", { Text = "Auto Pay Loan", Default = false,
    Callback = function(val) trackInterval("LoanLoop", val, 5, doAutoLoan) end })

-- ═════════════════════════════════════════════════════════════════════════════
-- UI — SETTINGS TAB
-- ═════════════════════════════════════════════════════════════════════════════

local MenuGroup = Tabs.Settings:AddLeftGroupbox("Menu", "menu")
MenuGroup:AddButton("Open Keybind Menu", function()
    if Library.KeybindFrame then
        Library.KeybindFrame.Visible = not Library.KeybindFrame.Visible
    end
end)
MenuGroup:AddToggle("AutoExecute",    { Text = "Auto Execute",    Default = false })
MenuGroup:AddToggle("AutoReconnect",  { Text = "Auto Reconnect",  Default = false })
MenuGroup:AddToggle("CustomCursor", { Text = "Custom Cursor", Default = false,
    Callback = function(val) Library.ShowCustomCursor = val end })
MenuGroup:AddToggle("ShowWatermark",  { Text = "Show Watermark",  Default = true })
MenuGroup:AddDropdown("NotifySide", {
    Text = "Notification Side", Default = 1,
    Values = { "Right", "Left" }, Multi = false,
})
Library.Options.NotifySide:OnChanged(function(val) Library.NotifySide = val end)
MenuGroup:AddDropdown("DPIScale", {
    Text = "DPI Scale", Default = 2,
    Values = { "75%", "100%", "125%", "150%" }, Multi = false,
})
Library.Options.DPIScale:OnChanged(function(val)
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
SaveManager:SetFolder("HubLibraryV2/CookAndSell")
ThemeManager:SetFolder("HubLibraryV2")
ThemeManager:ApplyToTabSplit(Tabs.Settings)
SaveManager:BuildConfigSection(Tabs.Settings)
SaveManager:LoadAutoloadConfig()
