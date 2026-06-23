-- Cook and Sell — Auto Farm
-- Part of Kunsy Hub Library V2

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService        = game:GetService("RunService")
local Players           = game:GetService("Players")
local VirtualUser       = game:GetService("VirtualUser")

-- Anti AFK
Players.LocalPlayer.Idled:Connect(function()
    VirtualUser:Button2Down(Vector2.new(0, 0), workspace.CurrentCamera.CFrame)
    task.wait(1)
    VirtualUser:Button2Up(Vector2.new(0, 0), workspace.CurrentCamera.CFrame)
end)

local CACHE_DIR = "HubLibraryV2/cache/"
local OBSIDIAN  = "https://raw.githubusercontent.com/deividcomsono/Obsidian/main/"

local IS_MOBILE = (game:GetService("UserInputService").TouchEnabled
    and not game:GetService("UserInputService").KeyboardEnabled)

-- Cache helpers

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

-- Load Obsidian

local Library      = loadstring(fetchCached("Library.lua"))()
local ThemeManager = loadstring(fetchCached("addons/ThemeManager.lua"))()
local SaveManager  = loadstring(fetchCached("addons/SaveManager.lua"))()

-- ThemeManager split (Colors left / Themes right)

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

-- Thin outlines

local _origAddOutline = Library.AddOutline
Library.AddOutline = function(self, Frame)
    local OutlineStroke, ShadowStroke = _origAddOutline(self, Frame)
    if OutlineStroke then OutlineStroke.Thickness = 0.5 end
    if ShadowStroke  then ShadowStroke.Thickness  = 0.5 end
    return OutlineStroke, ShadowStroke
end

-- Guard: unload previous instance

if getgenv().KunsyCookLoaded then
    pcall(function() getgenv().KunsyCookInstance:Unload() end)
end
getgenv().KunsyCookLoaded   = true

-- Window

local Window = Library:CreateWindow({
    Title            = "Cook and Sell",
    Icon             = "rbxassetid://139962551928576",
    IconSize         = UDim2.fromOffset(38, 38),
    Size             = UDim2.fromOffset(700, 520),
    Center           = true,
    AutoShow         = true,
    ShowCustomCursor   = false,
    NotifySide         = "Right",
    ShowMobileButtons  = false,
})
getgenv().KunsyCookInstance = Library
Window:SetFooter("ayank auliaa yg manis cantik dan kesayangan nya aku, wkwkwk")
Window:SetSidebarWidth(48)
game:GetService("UserInputService").MouseIconEnabled = true

-- Toggle button (all devices)

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

-- Tabs

local Tabs = {
    Farm     = Window:AddTab("", "bot"),
    Shop     = Window:AddTab("", "shopping-cart"),
    Cook     = Window:AddTab("", "cooking-pot"),
    Misc     = Window:AddTab("", "wrench"),
    Settings = Window:AddTab("", "settings"),
}
Tabs.Farm:Show()

-- Auto-collapse all groupboxes

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

-- GAME LOGIC

-- Remote helper

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

-- Connection manager (replaces Library:TrackConnection)

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

-- Shared module loaders

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

-- Auto Cashier

local processingCustomers = {}
local customerCooldown    = {}  -- prevents re-processing same instance after checkout

local function doAutoCashier()
    local RM = getReplicaManager()
    if not RM then return end
    local myPlot = getMyPlot()
    if not myPlot then return end
    if myPlot:GetAttribute("HasHiredCashier") then return end

    local checkout  = myPlot:FindFirstChild("Checkout")
    local customers = myPlot:FindFirstChild("Customers")
    if not checkout or not customers then return end

    -- collect cash each tick (merged from Auto Collect)
    local cashReg = checkout:FindFirstChild("CashRegister")
    if cashReg then
        local pa = cashReg:FindFirstChild("PromptAttachment")
        local prompt = pa and pa:FindFirstChild("CashPrompt")
        if prompt then pcall(fireproximityprompt, prompt) end
    end

    local queue1 = checkout:FindFirstChild("Queue") and checkout.Queue:FindFirstChild("1")

    -- cleanup stale locks and cooldowns for customers that already left
    local now = os.clock()
    for k in pairs(processingCustomers) do
        if not k.Parent then processingCustomers[k] = nil end
    end
    for k, t in pairs(customerCooldown) do
        if not k.Parent or (now - t) > 8 then customerCooldown[k] = nil end
    end

    for _, c in ipairs(customers:GetChildren()) do
        if processingCustomers[c] then continue end
        if customerCooldown[c]    then continue end

        local replica = RM.NPCReplicas and RM.NPCReplicas[c]
        if not (replica and replica.Data and replica.Data.QueuePosition == 1) then continue end

        local hrp = c:FindFirstChild("HumanoidRootPart")
        if queue1 and hrp and (hrp.Position - queue1.Position).Magnitude > 5 then continue end

        local cart      = replica.Data.Cart
        local itemCount = type(cart) == "table" and #cart or 0

        processingCustomers[c] = true
        customerCooldown[c]    = os.clock()
        local capturedReplica  = replica
        task.spawn(function()
            fireRemote("ManualCheckoutProgress", "Set", c, {})
            task.wait(0.15)

            local bagList = {}
            for i = 1, itemCount do
                table.insert(bagList, 1, tostring(i))
                fireRemote("ManualCheckoutProgress", "Set", c, bagList)
                task.wait(0.12)
            end

            task.wait(0.2)
            fireRemote("ManualCheckoutProgress", "Clear", c)

            -- wait for customer to physically leave (QueuePosition change or depart), max 6s
            local elapsed = 0
            while elapsed < 6 do
                if not c.Parent then break end
                local d = capturedReplica.Data
                if not d or d.QueuePosition ~= 1 then break end
                task.wait(0.25)
                elapsed += 0.25
            end
            processingCustomers[c] = nil
            -- cooldown stays until customer leaves workspace or 8s passes (handled in cleanup above)
        end)
        break
    end
end

-- Auto Upgrade

local function doAutoUpgrade()
    fireRemote("BuyPotUpgrade")
    fireRemote("BuyCheckoutUpgrade")
    fireRemote("BuildShopFixture")
    fireRemote("ExpandShop")
end

-- Auto Manage (claim from kitchen counter + cooking pot)

local function doAutoManage()
    local myPlot = getMyPlot()
    if not myPlot then return end

    local kitchenCounter = myPlot:FindFirstChild("KitchenCounter")
    if kitchenCounter then
        for _, obj in ipairs(kitchenCounter:GetDescendants()) do
            if obj:IsA("ProximityPrompt") and obj.Name == "ClaimItem" then
                pcall(fireproximityprompt, obj)
            end
        end
    end
    for _, obj in ipairs(workspace:GetChildren()) do
        if obj.Name == "CookingPotClientModel" and obj:IsA("Model") then
            for _, child in ipairs(obj:GetDescendants()) do
                if child:IsA("ProximityPrompt") and child.Name == "ClaimItem" then
                    pcall(fireproximityprompt, child)
                end
            end
        end
    end
end

-- Auto Place (place tools from inventory onto display counter slots)

local function doAutoPlace()
    local char = Players.LocalPlayer.Character
    if not char then return end

    local myPlot = getMyPlot()
    if not myPlot then return end

    local counters = myPlot:FindFirstChild("Counters")
    if not counters then return end

    for _, tool in ipairs(char:GetChildren()) do
        if not tool:IsA("Tool") then continue end
        for _, counter in ipairs(counters:GetChildren()) do
            if not counter:IsA("Model") then continue end
            for i = 1, 12 do
                local slot = counter:FindFirstChild(tostring(i))
                if not slot then break end
                -- slot is empty when it has no nested Model (no displayed product)
                if not slot:FindFirstChildOfClass("Model") then
                    fireRemote("PlaceDownItem", tool, counter, i)
                end
            end
        end
    end
end

-- Auto Daily Reward

local function doAutoRewards()
    fireRemote("GetDailyLoginReward")
    fireRemote("OpenDailyLoginReward")
end

-- Auto Pay Loan

local function doAutoLoan()
    fireRemote("PayLoan")
end

-- Buy Shop logic

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

-- reverse map: productId -> display name (must be before refreshCookList)
local idToName = {}
for name, id in pairs(cookMeta) do idToName[id] = name end

local function refreshCookList()
    local newList, newMeta = buildCookList()
    if #newList == #cookList then return end
    cookList = newList
    cookMeta = newMeta
    for name, id in pairs(cookMeta) do idToName[id] = name end
    local drop = Library.Options.CookRecipe
    if drop then
        drop:SetValues(#cookList > 0 and cookList or { "No recipes unlocked" })
    end
end

-- Auto Cook Recipe

local cookInProgress  = false
local autoCookEnabled = false
local cookCycleIndex  = 1

local function getSelectedRecipes()
    local val = Library.Options.CookRecipe and Library.Options.CookRecipe.Value
    if type(val) ~= "table" then
        return type(val) == "string" and {val} or {}
    end
    local list = {}
    for k, v in pairs(val) do
        if type(k) == "string" and v == true then
            table.insert(list, k)
        elseif type(k) == "number" and type(v) == "string" then
            table.insert(list, v)
        end
    end
    table.sort(list)
    return list
end

local function doStartCook()
    if cookInProgress then return end

    local selectedList = getSelectedRecipes()
    if #selectedList == 0 then return end

    -- get uncooked stock
    local RM      = getReplicaManager()
    local rep     = RM and RM.PlayerDataReplica
    local uncooked = rep and rep.Data.UncookedProducts or {}

    -- cycle through selected recipes to find next one with stock
    local id, foundIdx
    for attempt = 1, #selectedList do
        local idx  = ((cookCycleIndex - 1 + attempt - 1) % #selectedList) + 1
        local name = selectedList[idx]
        local rid  = cookMeta[name]
        if rid and (uncooked[rid] or 0) > 0 then
            id       = rid
            foundIdx = idx
            break
        end
    end
    if not id then return end  -- no stock for any selected recipe

    local myPlot = getMyPlot()
    if not myPlot then return end

    local pot = myPlot:FindFirstChild("CookingPotServerModel")
    if not pot then return end

    local potRemote = pot:FindFirstChild("Remote")
    if not potRemote then return end

    if pot:GetAttribute("ReadyToClaim") then
        pcall(function() potRemote:FireServer("ClaimDessert") end)
        return
    end

    if pot:GetAttribute("Cooking") then return end

    local StartCooking = getRemote("StartCooking")
    if not StartCooking then return end
    local ok, success, ingredientData = pcall(function()
        return StartCooking:InvokeServer(id, false)
    end)
    if not ok or not success or type(ingredientData) ~= "table" then return end

    cookInProgress = true
    -- advance cycle to next recipe for the next cook session
    cookCycleIndex = (foundIdx % #selectedList) + 1

    task.spawn(function()
        task.wait(0.5)

        local curPot    = myPlot:FindFirstChild("CookingPotServerModel")
        local curRemote = curPot and curPot:FindFirstChild("Remote")
        if not curRemote then cookInProgress = false return end

        for _, ing in ipairs(ingredientData) do
            if not autoCookEnabled then break end
            pcall(function() curRemote:FireServer("AddIngredient", ing.ingredientName) end)
            task.wait(0.35)
        end

        local elapsed = 0
        while autoCookEnabled and elapsed < 300 do
            local p = myPlot:FindFirstChild("CookingPotServerModel")
            if not p then break end
            if p:GetAttribute("ReadyToClaim") then
                task.wait(0.3)
                local r = p:FindFirstChild("Remote")
                if r then pcall(function() r:FireServer("ClaimDessert") end) end
                break
            end
            if not p:GetAttribute("Cooking") and (p:GetAttribute("IngredientCount") or 0) == 0 then
                break
            end
            task.wait(1) elapsed += 1
        end

        cookInProgress = false
    end)
end

-- UI — FARM TAB

local FarmGroup = Tabs.Farm:AddLeftGroupbox("Cashier", "users")
FarmGroup:AddToggle("AutoCashier", { Text = "Auto Cashier (+ Collect Cash)", Default = false,
    Callback = function(val) trackInterval("CashierLoop", val, 0.2, doAutoCashier) end })

local ManageGroup = Tabs.Farm:AddRightGroupbox("Kitchen", "cooking-pot")
ManageGroup:AddToggle("AutoManage", { Text = "Auto Manage (Claim)", Default = false,
    Callback = function(val) trackInterval("ManageLoop", val, 0.5, doAutoManage) end })
ManageGroup:AddToggle("AutoPlace", { Text = "Auto Place", Default = false,
    Callback = function(val) trackInterval("PlaceLoop", val, 1, doAutoPlace) end })
ManageGroup:AddToggle("AutoUpgrade", { Text = "Auto Upgrade", Default = false,
    Callback = function(val) trackInterval("UpgradeLoop", val, 1.5, doAutoUpgrade) end })

-- UI — SHOP TAB

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

-- UI — COOK TAB

local CookGroup  = Tabs.Cook:AddLeftGroupbox("Recipe", "cooking-pot")
local StockGroup = Tabs.Cook:AddRightGroupbox("Pantry", "package")

CookGroup:AddDropdown("CookRecipe", {
    Text    = "Select Recipe",
    Values  = #cookList > 0 and cookList or { "No recipes unlocked" },
    Default = 1,
    Multi   = true,
})
CookGroup:AddToggle("AutoCookRecipe", { Text = "Auto Cook", Default = false,
    Callback = function(val)
        autoCookEnabled = val
        cookInProgress  = false
        cookCycleIndex  = 1
        trackInterval("AutoCookLoop", val, 2, doStartCook)
    end })

-- Pantry stock panel (right side, wrapping labels)
local stockLabelElem = StockGroup:AddLabel("Loading...", true)

local function updateStockLabel()
    if not stockLabelElem then return end
    local RM  = getReplicaManager()
    local rep = RM and RM.PlayerDataReplica
    if not rep then stockLabelElem:SetText("--") ; return end

    local uncooked  = rep.Data.UncookedProducts or {}
    local selList   = getSelectedRecipes()
    local selIdSet  = {}
    for _, name in ipairs(selList) do
        local rid = cookMeta[name]
        if rid then selIdSet[rid] = true end
    end

    -- only show recipes with stock > 0, selected ones first
    local entries = {}
    for rid, cnt in pairs(uncooked) do
        if cnt > 0 then
            table.insert(entries, { name = idToName[rid] or rid, cnt = cnt, isSel = selIdSet[rid] == true })
        end
    end
    table.sort(entries, function(a, b)
        if a.isSel ~= b.isSel then return a.isSel end
        return a.name < b.name
    end)

    if #entries == 0 then
        stockLabelElem:SetText("(kosong)")
        return
    end

    local lines = {}
    for _, e in ipairs(entries) do
        local prefix = e.isSel and "> " or "  "
        local warn   = e.cnt <= 3 and " [!]" or ""
        table.insert(lines, prefix .. e.name .. ": " .. e.cnt .. "x" .. warn)
    end
    stockLabelElem:SetText(table.concat(lines, "\n"))
end

-- update on recipe switch + reset cycle
Library.Options.CookRecipe:OnChanged(function()
    cookCycleIndex = 1
    updateStockLabel()
end)

-- realtime update loop (always on)
trackInterval("StockUpdateLoop", true, 0.5, updateStockLabel)

-- refresh recipe list when new recipes get unlocked
trackInterval("CookListRefresh", true, 5, refreshCookList)

-- UI — MISC TAB

local MiscGroup = Tabs.Misc:AddLeftGroupbox("Daily & Loan", "calendar")
MiscGroup:AddToggle("AutoReward", { Text = "Auto Daily Reward", Default = false,
    Callback = function(val) trackInterval("RewardLoop", val, 5, doAutoRewards) end })
MiscGroup:AddToggle("AutoLoan", { Text = "Auto Pay Loan", Default = false,
    Callback = function(val) trackInterval("LoanLoop", val, 5, doAutoLoan) end })

-- UI — SETTINGS TAB

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
SaveManager:SetIgnoreIndexes({ "AutoPlace" })
SaveManager:SetFolder("HubLibraryV2/CookAndSell")
ThemeManager:SetFolder("HubLibraryV2")
ThemeManager:ApplyToTabSplit(Tabs.Settings)
SaveManager:BuildConfigSection(Tabs.Settings)
SaveManager:LoadAutoloadConfig()
