--[[
    ╔══════════════════════════════════════════════════════╗
    ║   Chiyo UI Library — Premium Violet ChiyoTheme (Sidebar Layout)      ║
    ╚══════════════════════════════════════════════════════╝

    ┌─ CARA GANTI LOGO / DISCORD / VERSI ─────────────────────┐
    │  Cukup ubah nilai di Library:Setup({...}) dari script:   │
    │                                                          │
    │  local Setup = Library:Setup({                           │
    │      Location = CoreGui,                                  │
    │      OpenCloseLocation = "Top Center",                   │
    │      Logo    = "rbxassetid://0",   -- << GANTI LOGO      │
    │      Title   = "Chiyo Hub",                             │
    │      Discord = "discord.gg/chiyo", -- << GANTI DISCORD   │
    │      Version = "v1.0",             -- << GANTI VERSI     │
    │      Game    = "Slime RNG",        -- << GANTI NAMA GAME │
    │  })                                                      │
    └──────────────────────────────────────────────────────────┘

    Pakai elemen:
        local Tab = Setup:CreateTab({ name="Main", icon="rbxassetid://0" })  -- opsional
        local Sec = Setup:CreateSection("Rolling")   -- otomatis masuk tab Main
        Sec:CreateToggle({ name="Auto Roll", flag="autoRoll", default=false, callback=function(v) end })
        Sec:CreateSlider({ name="Equip Delay", flag="delay", min=0, max=300, default=30, callback=function(v) end })
        Sec:CreateDropdown({ name="Best Mode", flag="mode", options={"Damage","Speed"}, default="Damage" })
        Sec:CreateTextbox({ name="Save At", flag="saveAt", placeholder="Default" })
        Sec:CreateButton({ name="Rejoin", callback=function() end })
--]]

local TweenService     = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService       = game:GetService("RunService")
local CoreGui          = game:GetService("CoreGui")
local HttpService      = game:GetService("HttpService")

-- ============================================================
--  PLACEHOLDER (ganti dari Setup juga bisa)
-- ============================================================
local LOGO_PLACEHOLDER = "https://raw.githubusercontent.com/Kunsyy/hub-library/main/icons/logo.png"  -- logo default kunsy
local CONFIG_FOLDER    = "CY_Config"        -- folder simpan config di workspace

local function getLogoImage(url)
    if not url or url == "" then url = LOGO_PLACEHOLDER end
    if string.match(url, "^http") then
        local req = (syn and syn.request) or (http and http.request) or http_request or request
        if req and writefile and getcustomasset then
            local hash = string.gsub(url, "[^%w]", "")
            local path = CONFIG_FOLDER .. "/logo_" .. string.sub(hash, -10) .. ".png"
            if isfile and not isfile(path) then
                if isfolder and not isfolder(CONFIG_FOLDER) then pcall(makefolder, CONFIG_FOLDER) end
                local ok, res = pcall(function() return req({Url = url, Method = "GET"}) end)
                if ok and type(res) == "table" and res.StatusCode == 200 then 
                    pcall(writefile, path, res.Body) 
                end
            end
            if isfile and isfile(path) then 
                local ok, asset = pcall(getcustomasset, path)
                if ok and asset then return asset end
            end
        end
    end
    return url
end

-- ============================================================
--  THEME (UNGU)
-- ============================================================
local ChiyoTheme = {
    Window       = Color3.fromRGB(20, 16, 26),
    Sidebar      = Color3.fromRGB(15, 12, 20),
    Bar          = Color3.fromRGB(15, 12, 20),
    Card         = Color3.fromRGB(28, 24, 38),
    Element      = Color3.fromRGB(36, 30, 48),
    ElementHover = Color3.fromRGB(48, 38, 64),
    Accent       = Color3.fromRGB(160, 100, 255),
    AccentDark   = Color3.fromRGB(120, 70, 220),
    AccentGlow   = Color3.fromRGB(190, 140, 255),
    Text         = Color3.fromRGB(245, 240, 255),
    SubText      = Color3.fromRGB(160, 150, 180),
    Stroke       = Color3.fromRGB(60, 50, 80),
    Off          = Color3.fromRGB(50, 40, 70),
}

local FAST   = TweenInfo.new(0.16, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local SMOOTH = TweenInfo.new(0.28, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)

-- ============================================================
--  HELPER
-- ============================================================
local function tween(obj, info, props)
    local t = TweenService:Create(obj, info, props); t:Play(); return t
end
local function applyDropShadow(parent, intensity)
    local shadow = Instance.new("ImageLabel")
    shadow.Name = "Shadow"
    shadow.AnchorPoint = Vector2.new(0.5, 0.5)
    shadow.Position = UDim2.fromScale(0.5, 0.5)
    shadow.Size = UDim2.new(1, 47, 1, 47)
    shadow.BackgroundTransparency = 1
    shadow.Image = "rbxassetid://6015897843"
    shadow.ImageColor3 = Color3.new(0, 0, 0)
    shadow.ImageTransparency = intensity or 0.4
    shadow.SliceCenter = Rect.new(49, 49, 450, 450)
    shadow.ScaleType = Enum.ScaleType.Slice
    shadow.ZIndex = -1
    shadow.Parent = parent
    return shadow
end
local function applyCorner(p, r)
    local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0, r or 8); c.Parent = p; return c
end
local function applyStroke(p, col, th, tr)
    local s = Instance.new("UIStroke")
    s.Color = col or ChiyoTheme.Stroke; s.Thickness = th or 1; s.Transparency = tr or 0
    s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border; s.Parent = p; return s
end
local function applyGradient(p, c1, c2, rot)
    local g = Instance.new("UIGradient")
    g.Color = ColorSequence.new(c1, c2); g.Rotation = rot or 0; g.Parent = p; return g
end
local function applyPadding(p, all)
    local u = Instance.new("UIPadding")
    u.PaddingLeft = UDim.new(0, all); u.PaddingRight = UDim.new(0, all)
    u.PaddingTop = UDim.new(0, all); u.PaddingBottom = UDim.new(0, all)
    u.Parent = p; return u
end
-- bikin frame dengan sudut membulat HANYA di sisi tertentu (pakai cover)
local function applyPartialRadius(frame, side, color, radius)
    applyCorner(frame, radius or 14)
    local cover = Instance.new("Frame")
    cover.BackgroundColor3 = color
    cover.BorderSizePixel = 0
    cover.ZIndex = frame.ZIndex
    if side == "top" then        cover.Size = UDim2.new(1, 0, 1, -(radius or 14)); cover.Position = UDim2.new(0, 0, 0, (radius or 14))
    elseif side == "bottom" then cover.Size = UDim2.new(1, 0, 1, -(radius or 14)); cover.Position = UDim2.new(0, 0, 0, 0)
    elseif side == "left" then   cover.Size = UDim2.new(1, -(radius or 14), 1, 0); cover.Position = UDim2.new(0, (radius or 14), 0, 0)
    end
    cover.Parent = frame
end

-- ============================================================
--  ICONS  (Image assets di-upload via Studio -> rbxassetid render di semua executor)
--  Update ID di sini kalau re-upload. Lihat icons/uploaded-ids.json
--  Logo masih WIP (pakai rbxthumb sementara) -> ganti kalau logo final.
-- ============================================================
local function thumb(id) return "rbxthumb://type=Asset&id=" .. id .. "&w=150&h=150" end
local Icons = {
    Logo     = thumb(101654945061026),       -- WIP placeholder
    Home     = "rbxassetid://86527598755783",
    Settings = "rbxassetid://83572703805151",
    Gear     = "rbxassetid://139934031665318",
    Sword    = "rbxassetid://106463958161380",
    Sword2   = "rbxassetid://127030584943192",
    Diamond  = "rbxassetid://121534310776905",
    Shop     = "rbxassetid://114952767371797",
    Trophy   = "rbxassetid://137426453440412",
    Notif    = "rbxassetid://131445084342623",
    Scroll   = "rbxassetid://101647887010375",
    Location = "rbxassetid://87670232389844",
    Folder   = "rbxassetid://105904459950210",
    Gift     = "rbxassetid://78284430469050",
    Empty    = "rbxassetid://101320488602048",
}

-- ============================================================
--  LIBRARY
-- ============================================================
local Library = {}
Library.__index = Library
Library.Icons = Icons
Library.Flags = {}
Library._connections = {}

function Library:TrackConnection(conn, tag)
    tag = tag or "default"
    self._connections[tag] = self._connections[tag] or {}
    table.insert(self._connections[tag], conn)
end
function Library:CleanupConnectionsByTag(tag)
    local b = self._connections[tag]; if not b then return end
    for _, c in ipairs(b) do pcall(function() c:Disconnect() end) end
    self._connections[tag] = nil
end

-- filter elemen berdasarkan teks search (cocokin nama element & nama section)
function Library:_runSearch(q)
    q = string.lower(q or "")
    local names = self._cardNames or {}
    for _, it in ipairs(self._searchItems or {}) do
        local cardName = names[it.card] or ""
        it.row.Visible = (q == ""
            or string.find(it.name, q, 1, true) ~= nil
            or string.find(cardName, q, 1, true) ~= nil)
    end
    for card, rows in pairs(self._searchCards or {}) do
        local cardName = names[card] or ""
        local any = (q == "" or string.find(cardName, q, 1, true) ~= nil)
        if not any then
            for _, r in ipairs(rows) do if r.Visible then any = true break end end
        end
        card.Visible = any
    end
end

-- ============================================================
--  CONFIG SYSTEM (save / load / export / import / auto-save)
-- ============================================================
local function _hasFiles() return writefile and readfile and isfile end
local function _ensureFolder()
    if isfolder and makefolder and not isfolder(CONFIG_FOLDER) then
        pcall(makefolder, CONFIG_FOLDER)
    end
end
local function _path(name) return CONFIG_FOLDER .. "/" .. tostring(name) .. ".json" end

-- ambil config sebagai string JSON (dari file kalau ada nama, kalau nggak dari Flags sekarang)
function Library:GetConfigString(name)
    if name and isfile and isfile(_path(name)) then return readfile(_path(name)) end
    return HttpService:JSONEncode(self.Flags)
end

-- terapin string JSON ke Flags + update tampilan element
function Library:ApplyConfigString(json)
    local ok, data = pcall(function() return HttpService:JSONDecode(json) end)
    if not ok or type(data) ~= "table" then return false end
    for flag, value in pairs(data) do
        self.Flags[flag] = value
        local setter = (self._setters or {})[flag]
        if setter then pcall(setter, value) end
    end
    return true
end

function Library:SaveConfig(name)
    if not _hasFiles() then return false, "executor nggak support writefile" end
    _ensureFolder()
    return pcall(writefile, _path(name), HttpService:JSONEncode(self.Flags))
end

function Library:LoadConfig(name)
    if not _hasFiles() or not isfile(_path(name)) then return false end
    return self:ApplyConfigString(readfile(_path(name)))
end

function Library:DeleteConfig(name)
    if delfile and isfile and isfile(_path(name)) then pcall(delfile, _path(name)) end
end

function Library:ListConfigs()
    local out = {}
    if listfiles and isfolder and isfolder(CONFIG_FOLDER) then
        for _, f in ipairs(listfiles(CONFIG_FOLDER)) do
            local n = string.match(f, "([^/\\]+)%.json$")
            if n then table.insert(out, n) end
        end
    end
    return out
end

-- export: balikin JSON + copy ke clipboard (buat dibagi/disimpan)
function Library:ExportConfig(name)
    local s = self:GetConfigString(name)
    local cb = setclipboard or (syn and syn.write_clipboard) or toclipboard
    if cb then pcall(cb, s) end
    return s
end

-- import: dari string JSON -> terapin, opsional simpan jadi config bernama
function Library:ImportConfig(json, saveAsName)
    local ok = self:ApplyConfigString(json)
    if ok and saveAsName and _hasFiles() then
        _ensureFolder(); pcall(writefile, _path(saveAsName), json)
    end
    return ok
end

-- aktifin auto-save ke 1 config (sekalian auto-load kalau filenya udah ada)
function Library:SetAutoSave(name)
    self._autoSaveName = name
    self:LoadConfig(name)
end

-- dipanggil tiap ada perubahan; nyimpen otomatis (debounce 0.5s)
function Library:_autoSave()
    if not self._autoSaveName then return end
    self._saveDirty = true
    if self._saving then return end
    self._saving = true
    task.spawn(function()
        task.wait(0.5)
        self._saving = false
        if self._saveDirty then
            self._saveDirty = false
            pcall(function() self:SaveConfig(self._autoSaveName) end)
        end
    end)
end

-- ===== AUTOLOAD (config yang dimuat otomatis pas join) =====
local AUTOLOAD_FILE = CONFIG_FOLDER .. "/_autoload.txt"
function Library:GetAutoloadConfig()
    if isfile and isfile(AUTOLOAD_FILE) then return readfile(AUTOLOAD_FILE) end
    return nil
end
function Library:SetAutoloadConfig(name)
    self._autoSaveName = name
    if _hasFiles() then _ensureFolder(); pcall(writefile, AUTOLOAD_FILE, tostring(name)) end
end
function Library:ClearAutoload()
    self._autoSaveName = nil
    if delfile and isfile and isfile(AUTOLOAD_FILE) then pcall(delfile, AUTOLOAD_FILE) end
end
-- panggil di akhir (setelah UI dibuat) biar config autoload kebaca + autosave aktif
function Library:ApplyAutoload()
    local n = self:GetAutoloadConfig()
    if n and n ~= "" then self:LoadConfig(n); self._autoSaveName = n end
    return n
end

-- ============================================================
--  KEY VALIDATOR (statik) — ambil daftar key dari URL
--  Support format: {"keys":[...]} | ["k1","k2"] | newline/comma list
--  (buat fase awal tanpa server; nggak ada HWID/tier)
-- ============================================================
function Library:MakeKeyValidator(url)
    return function(key)
        local ok, body = pcall(function() return game:HttpGet(url) end)
        if not ok or not body or body == "" then return false end
        key = tostring(key):gsub("%s", "")
        if key == "" then return false end
        -- coba JSON dulu
        local okj, decoded = pcall(function() return HttpService:JSONDecode(body) end)
        if okj and type(decoded) == "table" then
            local list = decoded.keys or decoded
            if type(list) == "table" then
                for _, k in ipairs(list) do
                    if tostring(k):gsub("%s","") == key then return true end
                end
                return false
            end
        end
        -- fallback: list dipisah newline/koma
        for line in tostring(body):gmatch("[^\r\n,]+") do
            if line:gsub("%s","") == key then return true end
        end
        return false
    end
end

-- ============================================================
--  HWID helper
-- ============================================================
local function getHWID()
    local ok, id = pcall(function()
        if gethwid then return gethwid() end
        if syn and syn.crypt and gethwid then return gethwid() end
        return game:GetService("RbxAnalyticsService"):GetClientId()
    end)
    return (ok and id and tostring(id)) or "unknown-hwid"
end
Library.GetHWID = function() return getHWID() end

-- cari fungsi request executor (buat POST)
local function getRequestFn()
    return (syn and syn.request) or (http and http.request) or http_request or request
end

-- ============================================================
--  SERVER VALIDATOR (Cloudflare Worker) — key + HWID + tier
--  baseUrl contoh: "https://kunsy-hub-keys.xxx.workers.dev"
--  Set self._premium dari response. Return true/false ke key UI.
-- ============================================================
function Library:MakeServerValidator(baseUrl)
    baseUrl = tostring(baseUrl):gsub("/+$", "")
    local lib = self
    return function(key)
        local req = getRequestFn()
        if not req then
            warn("[Hub] Executor nggak support HTTP request (POST).")
            return false
        end
        local hwid = getHWID()
        local ok, res = pcall(function()
            return req({
                Url = baseUrl .. "/validate",
                Method = "POST",
                Headers = { ["Content-Type"] = "application/json" },
                Body = HttpService:JSONEncode({ key = key, hwid = hwid, place = tostring(game.PlaceId) }),
            })
        end)
        if not ok or not res or not res.Body then return false end
        local okd, data = pcall(function() return HttpService:JSONDecode(res.Body) end)
        if not okd or type(data) ~= "table" then return false end

        -- simpen info buat dipake UI (lock fitur premium, dll)
        lib._premium  = data.premium == true
        lib._tier     = data.tier
        lib._keyExpiry = data.expiry
        lib._keyMsg   = data.message
        return data.valid == true
    end
end

-- shortcut buat cek premium dari script game
function Library:IsPremium() return self._premium == true end

function Library:createDisplayMessage(title, desc, buttons, style)
    local accents = { info = ChiyoTheme.Accent, warning = Color3.fromRGB(235,180,60), danger = Color3.fromRGB(235,70,90) }
    local accent = accents[style] or accents.info

    local loc = self._location or CoreGui
    -- hapus popup lama biar nggak numpuk/spam pas diklik berkali-kali
    for _, g in ipairs(loc:GetChildren()) do
        if g.Name == "CY_Message" then pcall(function() g:Destroy() end) end
    end
    local screen = Instance.new("ScreenGui")
    screen.Name = "CY_Message"; screen.ResetOnSpawn = false; screen.DisplayOrder = 999
    screen.IgnoreGuiInset = true; screen.Parent = loc

    local dim = Instance.new("Frame")
    dim.Size = UDim2.fromScale(1,1); dim.BackgroundColor3 = Color3.new(0,0,0)
    dim.BackgroundTransparency = 1; dim.Parent = screen
    tween(dim, FAST, { BackgroundTransparency = 0.45 })

    local frame = Instance.new("Frame")
    frame.Size = UDim2.fromOffset(340, 0); frame.Position = UDim2.fromScale(0.5,0.5)
    frame.AnchorPoint = Vector2.new(0.5,0.5); frame.BackgroundColor3 = ChiyoTheme.Window
    frame.Parent = screen
    applyCorner(frame, 12); applyStroke(frame, accent, 1.4, 0.2); applyPadding(frame, 16)
    applyDropShadow(frame, 0.5)
    local lay = Instance.new("UIListLayout", frame); lay.Padding = UDim.new(0,10)

    local t = Instance.new("TextLabel")
    t.Size = UDim2.new(1,0,0,22); t.BackgroundTransparency = 1; t.Font = Enum.Font.GothamBold
    t.TextSize = 18; t.TextColor3 = ChiyoTheme.Text; t.TextXAlignment = Enum.TextXAlignment.Left
    t.Text = title or "Message"; t.LayoutOrder = 1; t.Parent = frame

    local d = Instance.new("TextLabel")
    d.Size = UDim2.new(1,0,0,0); d.AutomaticSize = Enum.AutomaticSize.Y; d.BackgroundTransparency = 1
    d.Font = Enum.Font.Gotham; d.TextSize = 14; d.TextWrapped = true; d.TextColor3 = ChiyoTheme.SubText
    d.TextXAlignment = Enum.TextXAlignment.Left; d.Text = desc or ""; d.LayoutOrder = 2; d.Parent = frame

    local row = Instance.new("Frame")
    row.Size = UDim2.new(1,0,0,34); row.BackgroundTransparency = 1; row.LayoutOrder = 3; row.Parent = frame
    local rl = Instance.new("UIListLayout", row)
    rl.FillDirection = Enum.FillDirection.Horizontal; rl.HorizontalAlignment = Enum.HorizontalAlignment.Right
    rl.Padding = UDim.new(0,8)

    local function close()
        tween(dim, FAST, { BackgroundTransparency = 1 })
        tween(frame, FAST, { Size = UDim2.fromOffset(340,0) }).Completed:Wait()
        screen:Destroy()
    end
    for _, b in ipairs(buttons or {{text="OK"}}) do
        local btn = Instance.new("TextButton")
        btn.Size = UDim2.fromOffset(86,34); btn.BackgroundColor3 = accent; btn.AutoButtonColor = false
        btn.Font = Enum.Font.GothamMedium; btn.TextSize = 14; btn.TextColor3 = Color3.new(1,1,1)
        btn.Text = b.text or "OK"; btn.Parent = row
        applyCorner(btn,8); applyGradient(btn, accent, ChiyoTheme.AccentDark, 90)
        btn.MouseButton1Click:Connect(function()
            if b.callback then pcall(b.callback) end; close()
        end)
    end
    tween(frame, SMOOTH, { Size = UDim2.fromOffset(340,150) })
end

-- ===== TOAST NOTIFICATION (pojok kanan-bawah, auto-hilang) =====
function Library:Notify(opts)
    opts = opts or {}
    local title = opts.title or "Notification"
    local desc  = opts.text or opts.desc or ""
    local dur   = opts.duration or 3
    local accents = { info = ChiyoTheme.Accent, warning = Color3.fromRGB(235,180,60), danger = Color3.fromRGB(235,70,90), success = Color3.fromRGB(80,220,120) }
    local accent = accents[opts.style] or accents.info

    local loc = self._location or CoreGui
    -- container toast (bikin sekali, tumpuk dari bawah)
    local holder = loc:FindFirstChild("CY_Toasts")
    if not holder then
        holder = Instance.new("ScreenGui")
        holder.Name = "CY_Toasts"; holder.ResetOnSpawn = false; holder.DisplayOrder = 1001
        holder.IgnoreGuiInset = true; holder.Parent = loc
        local frame = Instance.new("Frame")
        frame.Name = "stack"; frame.Size = UDim2.new(0,300,1,-20); frame.Position = UDim2.new(1,-312,0,10)
        frame.BackgroundTransparency = 1; frame.Parent = holder
        local lay = Instance.new("UIListLayout", frame)
        lay.VerticalAlignment = Enum.VerticalAlignment.Bottom; lay.HorizontalAlignment = Enum.HorizontalAlignment.Right
        lay.Padding = UDim.new(0,8); lay.SortOrder = Enum.SortOrder.LayoutOrder
    end
    local stack = holder:FindFirstChild("stack")

    local card = Instance.new("Frame")
    card.Size = UDim2.new(0,300,0,0); card.AutomaticSize = Enum.AutomaticSize.Y
    card.BackgroundColor3 = ChiyoTheme.Card; card.Parent = stack
    card.LayoutOrder = tick() * 1000 % 2147483647
    applyCorner(card,10); applyPadding(card,12)
    applyDropShadow(card, 0.4)
    local accentBar = Instance.new("Frame")
    accentBar.Size = UDim2.new(0,3,1,-8); accentBar.Position = UDim2.new(0,-8,0,4)
    accentBar.BackgroundColor3 = accent; accentBar.BorderSizePixel = 0; accentBar.Parent = card; applyCorner(accentBar,2)
    local lay = Instance.new("UIListLayout", card); lay.Padding = UDim.new(0,3)

    local t = Instance.new("TextLabel")
    t.Size = UDim2.new(1,0,0,18); t.BackgroundTransparency = 1; t.Font = Enum.Font.GothamBold
    t.TextSize = 14; t.TextColor3 = ChiyoTheme.Text; t.TextXAlignment = Enum.TextXAlignment.Left
    t.Text = title; t.Parent = card
    local d = Instance.new("TextLabel")
    d.Size = UDim2.new(1,0,0,0); d.AutomaticSize = Enum.AutomaticSize.Y; d.BackgroundTransparency = 1
    d.Font = Enum.Font.Gotham; d.TextSize = 12; d.TextWrapped = true; d.TextColor3 = ChiyoTheme.SubText
    d.TextXAlignment = Enum.TextXAlignment.Left; d.Text = desc; d.Parent = card

    -- slide in
    card.Position = UDim2.fromOffset(320,0)
    tween(card, SMOOTH, { Position = UDim2.fromOffset(0,0) })
    -- progress bar
    local prog = Instance.new("Frame")
    prog.Size = UDim2.new(1,0,0,2); prog.Position = UDim2.new(0,0,1,-2)
    prog.BackgroundColor3 = accent; prog.BorderSizePixel = 0; prog.Parent = card
    tween(prog, TweenInfo.new(dur, Enum.EasingStyle.Linear), { Size = UDim2.new(0,0,0,2) })

    task.delay(dur, function()
        tween(card, FAST, { Position = UDim2.fromOffset(320,0) }).Completed:Wait()
        card:Destroy()
    end)
end

-- ============================================================
--  ELEMEN (Section)
-- ============================================================
local Section = {}
Section.__index = Section

local function createContainerRow(parent, h)
    local row = Instance.new("Frame")
    row.Size = UDim2.new(1,0,0,h or 36); row.BackgroundColor3 = ChiyoTheme.Element; row.Parent = parent
    applyCorner(row,7); applyStroke(row, ChiyoTheme.Stroke, 1, 0.5); return row
end

-- daftarin elemen ke registry search
function Section:_track(row, name)
    local lib = self._lib
    local card = self._container.Parent
    lib._searchItems = lib._searchItems or {}
    lib._searchCards = lib._searchCards or {}
    lib._searchCards[card] = lib._searchCards[card] or {}
    table.insert(lib._searchItems, { row = row, name = string.lower(tostring(name)), card = card })
    table.insert(lib._searchCards[card], row)
end

-- daftarin "setter" per flag, dipakai LoadConfig buat update tampilan
function Section:_setter(flag, fn)
    local lib = self._lib
    lib._setters = lib._setters or {}
    lib._setters[flag] = fn
end

-- kunci element premium kalau user bukan premium.
-- return true kalau dikunci (caller skip pasang interaksi).
function Section:_premiumLock(row, opts)
    if not (opts and opts.premium) then return false end
    if self._lib._premium == true then return false end
    -- visual: redupin + badge gembok, blok klik
    row.BackgroundColor3 = ChiyoTheme.Sidebar
    for _, c in ipairs(row:GetDescendants()) do
        if c:IsA("TextLabel") then c.TextColor3 = ChiyoTheme.Off
        elseif c:IsA("TextButton") then c.Active = false; c.AutoButtonColor = false end
    end
    local lockBtn = Instance.new("TextButton")
    lockBtn.Size = UDim2.fromScale(1,1); lockBtn.BackgroundTransparency = 1
    lockBtn.Text = ""; lockBtn.ZIndex = 50; lockBtn.Parent = row
    local badge = Instance.new("TextLabel")
    badge.Size = UDim2.fromOffset(74,16); badge.Position = UDim2.new(1,-80,0.5,-8)
    badge.BackgroundColor3 = ChiyoTheme.AccentDark; badge.Font = Enum.Font.GothamBold
    badge.TextSize = 10; badge.TextColor3 = Color3.new(1,1,1); badge.Text = "PREMIUM"
    badge.ZIndex = 51; badge.Parent = row; applyCorner(badge,5)
    lockBtn.MouseButton1Click:Connect(function()
        self._lib:Notify({ title = "Premium Only", text = (opts.name or "This feature").." needs Premium.", style = "warning" })
    end)
    return true
end

function Section:CreateToggle(opts)
    local lib = self._lib; lib.Flags[opts.flag] = opts.default or false
    local row = createContainerRow(self._container)
    self:_track(row, opts.name or opts.flag)
    local hit = Instance.new("TextButton"); hit.Size = UDim2.fromScale(1,1)
    hit.BackgroundTransparency = 1; hit.Text = ""; hit.Parent = row

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1,-70,1,0); label.Position = UDim2.fromOffset(12,0); label.BackgroundTransparency = 1
    label.Font = Enum.Font.GothamMedium; label.TextSize = 14; label.TextColor3 = ChiyoTheme.Text
    label.TextXAlignment = Enum.TextXAlignment.Left; label.Text = opts.name or opts.flag; label.Parent = row

    local track = Instance.new("Frame")
    track.Size = UDim2.fromOffset(40,20); track.Position = UDim2.new(1,-52,0.5,-10)
    track.BackgroundColor3 = lib.Flags[opts.flag] and ChiyoTheme.Accent or ChiyoTheme.Off; track.Parent = row
    applyCorner(track,10)
    local knob = Instance.new("Frame")
    knob.Size = UDim2.fromOffset(16,16); knob.BackgroundColor3 = Color3.new(1,1,1)
    knob.Position = lib.Flags[opts.flag] and UDim2.new(1,-18,0.5,-8) or UDim2.new(0,2,0.5,-8); knob.Parent = track
    applyCorner(knob,8)

    local function render()
        local on = lib.Flags[opts.flag]
        tween(track, FAST, { BackgroundColor3 = on and ChiyoTheme.Accent or ChiyoTheme.Off })
        tween(knob, FAST, { Position = on and UDim2.new(1,-18,0.5,-8) or UDim2.new(0,2,0.5,-8) })
    end
    hit.MouseEnter:Connect(function() tween(row,FAST,{BackgroundColor3=ChiyoTheme.ElementHover}) end)
    hit.MouseLeave:Connect(function() tween(row,FAST,{BackgroundColor3=ChiyoTheme.Element}) end)
    hit.MouseButton1Click:Connect(function()
        lib.Flags[opts.flag] = not lib.Flags[opts.flag]; render()
        if opts.callback then pcall(opts.callback, lib.Flags[opts.flag]) end
        lib:_autoSave()
    end)
    local setter = function(v) lib.Flags[opts.flag]=v; render() end
    self:_setter(opts.flag, setter)
    self:_premiumLock(row, opts)
    return { Set = setter }
end

function Section:CreateButton(opts)
    local row = createContainerRow(self._container)
    self:_track(row, opts.name or "button")
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.fromScale(1,1); btn.BackgroundTransparency = 1; btn.Font = Enum.Font.GothamMedium
    btn.TextSize = 14; btn.TextColor3 = ChiyoTheme.Text; btn.Text = opts.name or "Button"; btn.Parent = row
    local bar = Instance.new("Frame")
    bar.Size = UDim2.new(0,3,0.6,0); bar.Position = UDim2.new(0,0,0.2,0)
    bar.BackgroundColor3 = ChiyoTheme.Accent; bar.BorderSizePixel = 0; bar.Parent = row; applyCorner(bar,2)
    btn.MouseEnter:Connect(function() tween(row,FAST,{BackgroundColor3=ChiyoTheme.ElementHover}) end)
    btn.MouseLeave:Connect(function() tween(row,FAST,{BackgroundColor3=ChiyoTheme.Element}) end)
    btn.MouseButton1Click:Connect(function()
        tween(row,FAST,{BackgroundColor3=ChiyoTheme.Accent}).Completed:Connect(function()
            tween(row,FAST,{BackgroundColor3=ChiyoTheme.Element})
        end)
        if opts.callback then pcall(opts.callback) end
    end)
    self:_premiumLock(row, opts)
    return row
end

function Section:CreateSlider(opts)
    local lib = self._lib
    local min,max = opts.min or 0, opts.max or 100
    local value = math.clamp(opts.default or min, min, max)
    lib.Flags[opts.flag] = value
    local row = createContainerRow(self._container, 48)
    self:_track(row, opts.name or opts.flag)

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1,-60,0,20); label.Position = UDim2.fromOffset(12,5); label.BackgroundTransparency = 1
    label.Font = Enum.Font.GothamMedium; label.TextSize = 14; label.TextColor3 = ChiyoTheme.Text
    label.TextXAlignment = Enum.TextXAlignment.Left; label.Text = opts.name or opts.flag; label.Parent = row

    local valLbl = Instance.new("TextLabel")
    valLbl.Size = UDim2.new(0,52,0,20); valLbl.Position = UDim2.new(1,-60,0,5); valLbl.BackgroundTransparency = 1
    valLbl.Font = Enum.Font.GothamBold; valLbl.TextSize = 13; valLbl.TextColor3 = ChiyoTheme.AccentGlow
    valLbl.TextXAlignment = Enum.TextXAlignment.Right; valLbl.Text = tostring(value); valLbl.Parent = row

    local bar = Instance.new("Frame")
    bar.Size = UDim2.new(1,-24,0,6); bar.Position = UDim2.new(0,12,1,-14)
    bar.BackgroundColor3 = ChiyoTheme.Off; bar.Parent = row; applyCorner(bar,3)
    local fill = Instance.new("Frame")
    fill.Size = UDim2.fromScale((value-min)/(max-min),1); fill.BackgroundColor3 = ChiyoTheme.Accent; fill.Parent = bar
    applyCorner(fill,3); applyGradient(fill, ChiyoTheme.AccentGlow, ChiyoTheme.Accent, 0)
    local knob = Instance.new("Frame")
    knob.Size = UDim2.fromOffset(12,12); knob.AnchorPoint = Vector2.new(0.5,0.5)
    knob.Position = UDim2.new((value-min)/(max-min),0,0.5,0); knob.BackgroundColor3 = Color3.new(1,1,1)
    knob.Parent = bar; applyCorner(knob,6)

    local dragging = false
    local function setFromX(x)
        local rel = math.clamp((x - bar.AbsolutePosition.X)/bar.AbsoluteSize.X, 0, 1)
        value = math.floor((min+(max-min)*rel)+0.5); lib.Flags[opts.flag] = value
        valLbl.Text = tostring(value); fill.Size = UDim2.fromScale(rel,1); knob.Position = UDim2.new(rel,0,0.5,0)
        if opts.callback then pcall(opts.callback, value) end
        lib:_autoSave()
    end
    local hit = Instance.new("TextButton")
    hit.Size = UDim2.new(1,0,0,20); hit.Position = UDim2.new(0,0,1,-20)
    hit.BackgroundTransparency = 1; hit.Text = ""; hit.Parent = row
    hit.MouseButton1Down:Connect(function() dragging = true end)
    UserInputService.InputEnded:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end
    end)
    UserInputService.InputChanged:Connect(function(i)
        if dragging and i.UserInputType == Enum.UserInputType.MouseMovement then setFromX(i.Position.X) end
    end)
    hit.MouseButton1Click:Connect(function() setFromX(UserInputService:GetMouseLocation().X) end)
    local function setValue(v)
        v = math.clamp(tonumber(v) or min, min, max)
        value = v; lib.Flags[opts.flag] = v
        local rel = (max > min) and (v-min)/(max-min) or 0
        valLbl.Text = tostring(v); fill.Size = UDim2.fromScale(rel,1); knob.Position = UDim2.new(rel,0,0.5,0)
        if opts.callback then pcall(opts.callback, v) end
    end
    self:_setter(opts.flag, setValue)
    self:_premiumLock(row, opts)
    return { Set = setValue }
end

function Section:CreateDropdown(opts)
    local lib = self._lib
    lib.Flags[opts.flag] = opts.default or (opts.options and opts.options[1])
    local row = createContainerRow(self._container); local open = false
    self:_track(row, opts.name or opts.flag)

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1,-30,0,36); label.Position = UDim2.fromOffset(12,0); label.BackgroundTransparency = 1
    label.Font = Enum.Font.GothamMedium; label.TextSize = 13; label.TextColor3 = ChiyoTheme.Text
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Text = (opts.name or opts.flag)..": "..tostring(lib.Flags[opts.flag]); label.Parent = row

    local arrow = Instance.new("TextLabel")
    arrow.Size = UDim2.fromOffset(20,36); arrow.Position = UDim2.new(1,-26,0,0); arrow.BackgroundTransparency = 1
    arrow.Font = Enum.Font.GothamBold; arrow.TextSize = 12; arrow.TextColor3 = ChiyoTheme.Accent; arrow.Text = "v"; arrow.Parent = row

    local list = Instance.new("Frame")
    list.Size = UDim2.new(1,0,0,0); list.Position = UDim2.fromOffset(0,38); list.BackgroundTransparency = 1
    list.ClipsDescendants = true; list.Parent = row
    local ll = Instance.new("UIListLayout", list); ll.Padding = UDim.new(0,4)
    for _, opt in ipairs(opts.options or {}) do
        local item = Instance.new("TextButton")
        item.Size = UDim2.new(1,0,0,26); item.BackgroundColor3 = ChiyoTheme.Window
        item.Font = Enum.Font.Gotham; item.TextSize = 13; item.TextColor3 = ChiyoTheme.SubText
        item.Text = tostring(opt); item.Parent = list; applyCorner(item,6)
        item.MouseButton1Click:Connect(function()
            lib.Flags[opts.flag] = opt
            label.Text = (opts.name or opts.flag)..": "..tostring(opt)
            if opts.callback then pcall(opts.callback, opt) end
            lib:_autoSave()
        end)
    end
    self:_setter(opts.flag, function(v)
        lib.Flags[opts.flag] = v
        label.Text = (opts.name or opts.flag)..": "..tostring(v)
        if opts.callback then pcall(opts.callback, v) end
    end)
    local hit = Instance.new("TextButton")
    hit.Size = UDim2.new(1,0,0,36); hit.BackgroundTransparency = 1; hit.Text = ""; hit.Parent = row
    hit.MouseButton1Click:Connect(function()
        open = not open
        local h = open and (#(opts.options or {})*30+4) or 0
        tween(row, FAST, { Size = UDim2.new(1,0,0,36+h) })
        tween(list, FAST, { Size = UDim2.new(1,0,0,h) })
        arrow.Text = open and "^" or "v"
    end)
    self:_premiumLock(row, opts)
    return row
end

function Section:CreateTextbox(opts)
    local lib = self._lib; lib.Flags[opts.flag] = ""
    local row = createContainerRow(self._container)
    self:_track(row, opts.name or opts.flag)
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(0.45,0,1,0); label.Position = UDim2.fromOffset(12,0); label.BackgroundTransparency = 1
    label.Font = Enum.Font.GothamMedium; label.TextSize = 13; label.TextColor3 = ChiyoTheme.Text
    label.TextXAlignment = Enum.TextXAlignment.Left; label.Text = opts.name or opts.flag; label.Parent = row
    local box = Instance.new("TextBox")
    box.Size = UDim2.new(0.5,-16,0,24); box.Position = UDim2.new(0.5,0,0.5,-12)
    box.BackgroundColor3 = ChiyoTheme.Window; box.Font = Enum.Font.Gotham; box.TextSize = 13
    box.TextColor3 = ChiyoTheme.Text; box.PlaceholderText = opts.placeholder or "..."; box.PlaceholderColor3 = ChiyoTheme.SubText
    box.Text = ""; box.ClearTextOnFocus = false; box.Parent = row; applyCorner(box,6); applyStroke(box, ChiyoTheme.Stroke, 1)
    box.FocusLost:Connect(function()
        lib.Flags[opts.flag] = box.Text
        if opts.callback then pcall(opts.callback, box.Text) end
        lib:_autoSave()
    end)
    self:_setter(opts.flag, function(v) box.Text = tostring(v); lib.Flags[opts.flag] = box.Text end)
    return row
end

function Section:CreateKeybind(opts)
    local lib = self._lib
    local cur = opts.default
    if typeof(cur) == "EnumItem" then cur = cur.Name end
    cur = cur or "None"
    lib.Flags[opts.flag] = cur

    local row = createContainerRow(self._container)
    self:_track(row, opts.name or opts.flag)

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1,-110,1,0); label.Position = UDim2.fromOffset(12,0); label.BackgroundTransparency = 1
    label.Font = Enum.Font.GothamMedium; label.TextSize = 14; label.TextColor3 = ChiyoTheme.Text
    label.TextXAlignment = Enum.TextXAlignment.Left; label.Text = opts.name or opts.flag; label.Parent = row

    local btn = Instance.new("TextButton")
    btn.Size = UDim2.fromOffset(90,24); btn.Position = UDim2.new(1,-100,0.5,-12)
    btn.BackgroundColor3 = ChiyoTheme.Window; btn.Font = Enum.Font.GothamMedium; btn.TextSize = 12
    btn.TextColor3 = ChiyoTheme.AccentGlow; btn.Text = "[ "..cur.." ]"; btn.Parent = row
    applyCorner(btn,6); applyStroke(btn, ChiyoTheme.Stroke, 1)

    local listening = false
    local function setKey(k) cur = tostring(k); lib.Flags[opts.flag] = cur; btn.Text = "[ "..cur.." ]" end
    self:_setter(opts.flag, setKey)

    btn.MouseButton1Click:Connect(function() listening = true; btn.Text = "[ ... ]" end)
    local conn = UserInputService.InputBegan:Connect(function(i, gpe)
        if listening then
            if i.UserInputType == Enum.UserInputType.Keyboard then
                setKey(i.KeyCode.Name); listening = false; lib:_autoSave()
            end
            return
        end
        if gpe then return end
        if i.UserInputType == Enum.UserInputType.Keyboard and i.KeyCode.Name == cur then
            if opts.callback then pcall(opts.callback) end
        end
    end)
    lib:TrackConnection(conn, "cy_keybind")
    return { Set = setKey }
end

-- keybind khusus buat buka/tutup menu (kayak "Menu Keybind" di Versus)
function Section:CreateMenuKeybind(opts)
    opts = opts or {}
    local lib = self._lib
    local cur = lib.Flags.menuKeybind or opts.default or "RightShift"
    lib.Flags.menuKeybind = cur

    local row = createContainerRow(self._container)
    self:_track(row, opts.name or "Menu Keybind")

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1,-110,1,0); label.Position = UDim2.fromOffset(12,0); label.BackgroundTransparency = 1
    label.Font = Enum.Font.GothamMedium; label.TextSize = 14; label.TextColor3 = ChiyoTheme.Text
    label.TextXAlignment = Enum.TextXAlignment.Left; label.Text = opts.name or "Menu Keybind"; label.Parent = row

    local btn = Instance.new("TextButton")
    btn.Size = UDim2.fromOffset(90,24); btn.Position = UDim2.new(1,-100,0.5,-12)
    btn.BackgroundColor3 = ChiyoTheme.Window; btn.Font = Enum.Font.GothamMedium; btn.TextSize = 12
    btn.TextColor3 = ChiyoTheme.AccentGlow; btn.Text = "[ "..cur.." ]"; btn.Parent = row
    applyCorner(btn,6); applyStroke(btn, ChiyoTheme.Stroke, 1)

    local listening = false
    local function setKey(k) cur = tostring(k); lib.Flags.menuKeybind = cur; btn.Text = "[ "..cur.." ]" end
    self:_setter("menuKeybind", setKey)

    btn.MouseButton1Click:Connect(function() listening = true; lib._rebindingMenu = true; btn.Text = "[ ... ]" end)
    local conn = UserInputService.InputBegan:Connect(function(i, gpe)
        if listening and i.UserInputType == Enum.UserInputType.Keyboard then
            setKey(i.KeyCode.Name); listening = false; lib._rebindingMenu = false; lib:_autoSave()
        end
    end)
    lib:TrackConnection(conn, "cy_keybind")
    return { Set = setKey }
end

function Section:CreateMultiDropdown(opts)
    local lib = self._lib
    local options = opts.options or {}
    local selected = {}
    for _, v in ipairs(opts.default or {}) do selected[v] = true end
    local function listSel()
        local t = {}
        for _, o in ipairs(options) do if selected[o] then t[#t+1] = o end end
        return t
    end
    lib.Flags[opts.flag] = listSel()

    local row = createContainerRow(self._container)
    self:_track(row, opts.name or opts.flag); local open = false

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1,-30,0,36); label.Position = UDim2.fromOffset(12,0); label.BackgroundTransparency = 1
    label.Font = Enum.Font.GothamMedium; label.TextSize = 13; label.TextColor3 = ChiyoTheme.Text
    label.TextXAlignment = Enum.TextXAlignment.Left; label.Parent = row

    local arrow = Instance.new("TextLabel")
    arrow.Size = UDim2.fromOffset(20,36); arrow.Position = UDim2.new(1,-26,0,0); arrow.BackgroundTransparency = 1
    arrow.Font = Enum.Font.GothamBold; arrow.TextSize = 12; arrow.TextColor3 = ChiyoTheme.Accent; arrow.Text = "v"; arrow.Parent = row

    local function refreshLabel()
        local sel = listSel()
        label.Text = (opts.name or opts.flag)..": "..((#sel == 0) and "---" or table.concat(sel, ", "))
    end

    local list = Instance.new("Frame")
    list.Size = UDim2.new(1,0,0,0); list.Position = UDim2.fromOffset(0,38); list.BackgroundTransparency = 1
    list.ClipsDescendants = true; list.Parent = row
    local ll = Instance.new("UIListLayout", list); ll.Padding = UDim.new(0,4)

    local items = {}
    local SELECTED_BG = Color3.fromRGB(85, 55, 140)  -- ungu muted buat opsi kepilih
    local function styleItem(item, on)
        tween(item, FAST, { BackgroundColor3 = on and SELECTED_BG or ChiyoTheme.Window })
        item.TextColor3 = on and Color3.new(1,1,1) or ChiyoTheme.SubText
    end
    for _, opt in ipairs(options) do
        local item = Instance.new("TextButton")
        item.Size = UDim2.new(1,0,0,26); item.AutoButtonColor = false
        item.Font = Enum.Font.Gotham; item.TextSize = 13; item.Text = tostring(opt)
        item.Parent = list; applyCorner(item,6)
        item.BackgroundColor3 = selected[opt] and SELECTED_BG or ChiyoTheme.Window
        item.TextColor3 = selected[opt] and Color3.new(1,1,1) or ChiyoTheme.SubText
        items[opt] = item
        item.MouseButton1Click:Connect(function()
            selected[opt] = not selected[opt]
            styleItem(item, selected[opt])
            lib.Flags[opts.flag] = listSel(); refreshLabel()
            if opts.callback then pcall(opts.callback, lib.Flags[opts.flag]) end
            lib:_autoSave()
        end)
    end
    refreshLabel()

    self:_setter(opts.flag, function(v)
        for k in pairs(selected) do selected[k] = nil end
        for _, o in ipairs(v or {}) do selected[o] = true end
        for opt, item in pairs(items) do styleItem(item, selected[opt]) end
        lib.Flags[opts.flag] = listSel(); refreshLabel()
    end)

    local hit = Instance.new("TextButton")
    hit.Size = UDim2.new(1,0,0,36); hit.BackgroundTransparency = 1; hit.Text = ""; hit.Parent = row
    hit.MouseButton1Click:Connect(function()
        open = not open
        local h = open and (#options*30+4) or 0
        tween(row, FAST, { Size = UDim2.new(1,0,0,36+h) })
        tween(list, FAST, { Size = UDim2.new(1,0,0,h) })
        arrow.Text = open and "^" or "v"
    end)
    self:_premiumLock(row, opts)
    return row
end

-- ===== LABEL (teks statis 1 baris) =====
function Section:CreateLabel(opts)
    opts = opts or {}
    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1,0,0,20); lbl.BackgroundTransparency = 1
    lbl.Font = Enum.Font.GothamMedium; lbl.TextSize = 13; lbl.TextColor3 = ChiyoTheme.Text
    lbl.TextXAlignment = Enum.TextXAlignment.Left; lbl.TextWrapped = true
    lbl.Text = opts.text or opts.name or ""; lbl.Parent = self._container
    self:_track(lbl, opts.text or opts.name or "label")
    return { Set = function(t) lbl.Text = tostring(t) end, Instance = lbl }
end

-- ===== PARAGRAPH (judul + teks panjang) =====
function Section:CreateParagraph(opts)
    opts = opts or {}
    local row = Instance.new("Frame")
    row.Size = UDim2.new(1,0,0,0); row.AutomaticSize = Enum.AutomaticSize.Y
    row.BackgroundColor3 = ChiyoTheme.Element; row.Parent = self._container
    applyCorner(row,7); applyStroke(row, ChiyoTheme.Stroke, 1, 0.5); applyPadding(row, 10)
    local lay = Instance.new("UIListLayout", row); lay.Padding = UDim.new(0,4)
    self:_track(row, opts.title or "paragraph")

    if opts.title then
        local t = Instance.new("TextLabel")
        t.Size = UDim2.new(1,0,0,18); t.BackgroundTransparency = 1; t.Font = Enum.Font.GothamBold
        t.TextSize = 14; t.TextColor3 = ChiyoTheme.AccentGlow; t.TextXAlignment = Enum.TextXAlignment.Left
        t.Text = opts.title; t.Parent = row
    end
    local body = Instance.new("TextLabel")
    body.Size = UDim2.new(1,0,0,0); body.AutomaticSize = Enum.AutomaticSize.Y; body.BackgroundTransparency = 1
    body.Font = Enum.Font.Gotham; body.TextSize = 13; body.TextColor3 = ChiyoTheme.SubText
    body.TextXAlignment = Enum.TextXAlignment.Left; body.TextWrapped = true
    body.Text = opts.text or ""; body.Parent = row
    return { Set = function(t) body.Text = tostring(t) end, Instance = row }
end

-- ===== SEPARATOR (garis pemisah, opsional ada teks) =====
function Section:CreateSeparator(opts)
    opts = opts or {}
    local row = Instance.new("Frame")
    row.Size = UDim2.new(1,0,0, opts.text and 18 or 8); row.BackgroundTransparency = 1; row.Parent = self._container
    self:_track(row, opts.text or "separator")
    if opts.text then
        local lbl = Instance.new("TextLabel")
        lbl.Size = UDim2.fromScale(1,1); lbl.BackgroundTransparency = 1; lbl.Font = Enum.Font.GothamMedium
        lbl.TextSize = 11; lbl.TextColor3 = ChiyoTheme.SubText; lbl.Text = opts.text; lbl.Parent = row
    else
        local line = Instance.new("Frame")
        line.Size = UDim2.new(1,-8,0,1); line.Position = UDim2.new(0,4,0.5,0)
        line.BackgroundColor3 = ChiyoTheme.Stroke; line.BorderSizePixel = 0; line.Parent = row
    end
    return row
end

-- ===== COLOR PICKER (RGB sliders) =====
function Section:CreateColorPicker(opts)
    local lib = self._lib
    local default = opts.default or Color3.fromRGB(160,100,255)
    lib.Flags[opts.flag] = default
    local row = createContainerRow(self._container); local open = false
    self:_track(row, opts.name or opts.flag)

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1,-50,0,36); label.Position = UDim2.fromOffset(12,0); label.BackgroundTransparency = 1
    label.Font = Enum.Font.GothamMedium; label.TextSize = 14; label.TextColor3 = ChiyoTheme.Text
    label.TextXAlignment = Enum.TextXAlignment.Left; label.Text = opts.name or opts.flag; label.Parent = row

    local preview = Instance.new("Frame")
    preview.Size = UDim2.fromOffset(28,18); preview.Position = UDim2.new(1,-40,0,9)
    preview.BackgroundColor3 = default; preview.Parent = row; applyCorner(preview,5); applyStroke(preview, ChiyoTheme.Stroke, 1)

    local panel = Instance.new("Frame")
    panel.Size = UDim2.new(1,0,0,0); panel.Position = UDim2.fromOffset(0,40); panel.BackgroundTransparency = 1
    panel.ClipsDescendants = true; panel.Parent = row
    local pl = Instance.new("UIListLayout", panel); pl.Padding = UDim.new(0,6)

    local rgb = { math.floor(default.R*255+0.5), math.floor(default.G*255+0.5), math.floor(default.B*255+0.5) }
    local names = { "R", "G", "B" }
    local function apply()
        local c = Color3.fromRGB(rgb[1],rgb[2],rgb[3])
        preview.BackgroundColor3 = c; lib.Flags[opts.flag] = c
        if opts.callback then pcall(opts.callback, c) end
        lib:_autoSave()
    end
    local fills = {}
    for idx = 1, 3 do
        local s = Instance.new("Frame")
        s.Size = UDim2.new(1,0,0,22); s.BackgroundTransparency = 1; s.Parent = panel
        local nm = Instance.new("TextLabel")
        nm.Size = UDim2.fromOffset(14,22); nm.BackgroundTransparency = 1; nm.Font = Enum.Font.GothamBold
        nm.TextSize = 12; nm.TextColor3 = ChiyoTheme.SubText; nm.Text = names[idx]; nm.Parent = s
        local bar = Instance.new("Frame")
        bar.Size = UDim2.new(1,-50,0,6); bar.Position = UDim2.new(0,18,0.5,-3)
        bar.BackgroundColor3 = ChiyoTheme.Off; bar.Parent = s; applyCorner(bar,3)
        local fill = Instance.new("Frame")
        fill.Size = UDim2.fromScale(rgb[idx]/255,1); fill.BackgroundColor3 = ChiyoTheme.Accent; fill.Parent = bar; applyCorner(fill,3)
        fills[idx] = fill
        local val = Instance.new("TextLabel")
        val.Size = UDim2.fromOffset(28,22); val.Position = UDim2.new(1,-28,0,0); val.BackgroundTransparency = 1
        val.Font = Enum.Font.Gotham; val.TextSize = 12; val.TextColor3 = ChiyoTheme.Text
        val.Text = tostring(rgb[idx]); val.Parent = s
        local dragging = false
        local function setX(x)
            local rel = math.clamp((x - bar.AbsolutePosition.X)/bar.AbsoluteSize.X, 0, 1)
            rgb[idx] = math.floor(rel*255+0.5); fill.Size = UDim2.fromScale(rel,1); val.Text = tostring(rgb[idx]); apply()
        end
        local hit = Instance.new("TextButton")
        hit.Size = UDim2.new(1,-50,1,0); hit.Position = UDim2.fromOffset(18,0); hit.BackgroundTransparency = 1; hit.Text = ""; hit.Parent = s
        hit.MouseButton1Down:Connect(function() dragging = true end)
        UserInputService.InputEnded:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end end)
        UserInputService.InputChanged:Connect(function(i) if dragging and i.UserInputType == Enum.UserInputType.MouseMovement then setX(i.Position.X) end end)
        hit.MouseButton1Click:Connect(function() setX(UserInputService:GetMouseLocation().X) end)
    end

    self:_setter(opts.flag, function(v)
        if typeof(v) == "table" then v = Color3.fromRGB(v[1] or v.R or 0, v[2] or v.G or 0, v[3] or v.B or 0) end
        if typeof(v) ~= "Color3" then return end
        rgb = { math.floor(v.R*255+0.5), math.floor(v.G*255+0.5), math.floor(v.B*255+0.5) }
        for i=1,3 do fills[i].Size = UDim2.fromScale(rgb[i]/255,1) end
        preview.BackgroundColor3 = v; lib.Flags[opts.flag] = v
    end)

    local hit = Instance.new("TextButton")
    hit.Size = UDim2.new(1,0,0,36); hit.BackgroundTransparency = 1; hit.Text = ""; hit.Parent = row
    hit.MouseButton1Click:Connect(function()
        open = not open
        local h = open and (3*28+4) or 0
        tween(row, FAST, { Size = UDim2.new(1,0,0,36+h) })
        tween(panel, FAST, { Size = UDim2.new(1,0,0,h) })
    end)
    return { Set = function(c) (self._lib._setters[opts.flag])(c) end }
end

-- ============================================================
--  TAB (halaman dengan 2 kolom)
-- ============================================================
local Tab = {}
Tab.__index = Tab

function Tab:CreateSection(name)
    local section = setmetatable({}, Section)
    section._lib = self._lib

    local column
    if self._isTwoColumn then
        self._count = (self._count or 0) + 1
        column = (self._count % 2 == 1) and self._colLeft or self._colRight
    else
        column = self._colMain
    end

    local card = Instance.new("Frame")
    card.Size = UDim2.new(1,0,0,0); card.AutomaticSize = Enum.AutomaticSize.Y
    card.BackgroundColor3 = ChiyoTheme.Card; card.BackgroundTransparency = 0.1; card.Parent = column
    applyCorner(card,10); applyStroke(card, ChiyoTheme.Stroke, 1, 0.5); applyPadding(card, 10)
    applyDropShadow(card, 0.6)

    -- daftarin section ke registry search (biar bisa dicari pakai nama section)
    local lib = self._lib
    lib._searchCards = lib._searchCards or {}
    lib._searchCards[card] = lib._searchCards[card] or {}
    lib._cardNames = lib._cardNames or {}
    lib._cardNames[card] = string.lower(name or "section")
    local lay = Instance.new("UIListLayout", card); lay.Padding = UDim.new(0,7); lay.SortOrder = Enum.SortOrder.LayoutOrder

    -- header (klik buat collapse)
    local head = Instance.new("TextButton")
    head.Size = UDim2.new(1,0,0,24); head.BackgroundTransparency = 1; head.Text = ""
    head.LayoutOrder = -1; head.Parent = card
    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1,-24,1,0); title.BackgroundTransparency = 1; title.Font = Enum.Font.GothamBold
    title.TextSize = 15; title.TextColor3 = ChiyoTheme.AccentGlow; title.TextXAlignment = Enum.TextXAlignment.Left
    title.Text = name or "Section"; title.Parent = head
    local chev = Instance.new("TextLabel")
    chev.Size = UDim2.fromOffset(20,24); chev.Position = UDim2.new(1,-20,0,0); chev.BackgroundTransparency = 1
    chev.Font = Enum.Font.GothamBold; chev.TextSize = 12; chev.TextColor3 = ChiyoTheme.Accent; chev.Text = "v"; chev.Parent = head

    -- body (elemen-elemen)
    local body = Instance.new("Frame")
    body.Size = UDim2.new(1,0,0,0); body.AutomaticSize = Enum.AutomaticSize.Y
    body.BackgroundTransparency = 1; body.Parent = card
    local bl = Instance.new("UIListLayout", body); bl.Padding = UDim.new(0,7); bl.SortOrder = Enum.SortOrder.LayoutOrder

    local open = true
    head.MouseButton1Click:Connect(function()
        open = not open; body.Visible = open; chev.Text = open and "v" or "<"
    end)

    section._container = body
    return section
end

-- section config siap-pakai (1 panggilan = panel config lengkap)
function Tab:CreateConfigSection(opts)
    opts = opts or {}
    local lib = self._lib
    local sec = self:CreateSection(opts.title or "Configuration")
    local body = sec._container
    local selectedName = nil

    local function mkButton(text, cb)
        local row = createContainerRow(body)
        local b = Instance.new("TextButton")
        b.Size = UDim2.fromScale(1,1); b.BackgroundTransparency = 1; b.Font = Enum.Font.GothamMedium
        b.TextSize = 14; b.TextColor3 = ChiyoTheme.Text; b.Text = text; b.Parent = row
        b.MouseEnter:Connect(function() tween(row,FAST,{BackgroundColor3=ChiyoTheme.ElementHover}) end)
        b.MouseLeave:Connect(function() tween(row,FAST,{BackgroundColor3=ChiyoTheme.Element}) end)
        b.MouseButton1Click:Connect(function()
            tween(row,FAST,{BackgroundColor3=ChiyoTheme.Accent}).Completed:Connect(function()
                tween(row,FAST,{BackgroundColor3=ChiyoTheme.Element}) end)
            if cb then pcall(cb) end
        end)
        return b
    end
    local function mkTextbox(placeholder)
        local row = createContainerRow(body)
        local tb = Instance.new("TextBox")
        tb.Size = UDim2.new(1,-16,1,-8); tb.Position = UDim2.fromOffset(8,4)
        tb.BackgroundColor3 = ChiyoTheme.Window; tb.Font = Enum.Font.Gotham; tb.TextSize = 13
        tb.TextColor3 = ChiyoTheme.Text; tb.PlaceholderText = placeholder; tb.PlaceholderColor3 = ChiyoTheme.SubText
        tb.Text = ""; tb.ClearTextOnFocus = false; tb.TextXAlignment = Enum.TextXAlignment.Left; tb.Parent = row
        applyCorner(tb,6); applyStroke(tb, ChiyoTheme.Stroke, 1)
        local p = Instance.new("UIPadding", tb); p.PaddingLeft = UDim.new(0,8); p.PaddingRight = UDim.new(0,8)
        return tb
    end
    local function mkLabel(text)
        local l = Instance.new("TextLabel")
        l.Size = UDim2.new(1,0,0,18); l.BackgroundTransparency = 1; l.Font = Enum.Font.Gotham
        l.TextSize = 12; l.TextColor3 = ChiyoTheme.SubText; l.TextXAlignment = Enum.TextXAlignment.Left
        l.Text = text; l.Parent = body
        return l
    end

    local nameBox = mkTextbox("new config name...")

    -- list config (refreshable)
    local listRow = createContainerRow(body)
    local listLabel = Instance.new("TextLabel")
    listLabel.Size = UDim2.new(1,-30,0,36); listLabel.Position = UDim2.fromOffset(12,0); listLabel.BackgroundTransparency = 1
    listLabel.Font = Enum.Font.GothamMedium; listLabel.TextSize = 13; listLabel.TextColor3 = ChiyoTheme.Text
    listLabel.TextXAlignment = Enum.TextXAlignment.Left; listLabel.Text = "Select config: -"; listLabel.Parent = listRow
    local listArrow = Instance.new("TextLabel")
    listArrow.Size = UDim2.fromOffset(20,36); listArrow.Position = UDim2.new(1,-26,0,0); listArrow.BackgroundTransparency = 1
    listArrow.Font = Enum.Font.GothamBold; listArrow.TextSize = 12; listArrow.TextColor3 = ChiyoTheme.Accent; listArrow.Text = "v"; listArrow.Parent = listRow
    local listBox = Instance.new("Frame")
    listBox.Size = UDim2.new(1,0,0,0); listBox.Position = UDim2.fromOffset(0,38); listBox.BackgroundTransparency = 1
    listBox.ClipsDescendants = true; listBox.Parent = listRow
    local listLL = Instance.new("UIListLayout", listBox); listLL.Padding = UDim.new(0,4)
    local listOpen = false
    local function resizeList()
        local n = #listBox:GetChildren() - 1
        local h = listOpen and (n*30+4) or 0
        tween(listRow, FAST, { Size = UDim2.new(1,0,0,36+h) })
        tween(listBox, FAST, { Size = UDim2.new(1,0,0,h) })
    end
    local function refreshList()
        for _, c in ipairs(listBox:GetChildren()) do if c:IsA("TextButton") then c:Destroy() end end
        local cfgs = lib:ListConfigs()
        for _, nm in ipairs(cfgs) do
            local it = Instance.new("TextButton")
            it.Size = UDim2.new(1,0,0,26); it.BackgroundColor3 = ChiyoTheme.Window
            it.Font = Enum.Font.Gotham; it.TextSize = 13; it.TextColor3 = ChiyoTheme.SubText
            it.Text = nm; it.Parent = listBox; applyCorner(it,6)
            it.MouseButton1Click:Connect(function()
                selectedName = nm; listLabel.Text = "Select config: " .. nm
            end)
        end
        if #cfgs == 0 then listLabel.Text = "Select config: (empty)" end
        if listOpen then resizeList() end
    end
    local listHit = Instance.new("TextButton")
    listHit.Size = UDim2.new(1,0,0,36); listHit.BackgroundTransparency = 1; listHit.Text = ""; listHit.Parent = listRow
    listHit.MouseButton1Click:Connect(function()
        listOpen = not listOpen; listArrow.Text = listOpen and "^" or "v"; resizeList()
    end)

    local statusLbl = mkLabel("")
    local function updateStatus()
        local auto = lib._autoSaveName
        statusLbl.Text = "Auto-save: " .. (auto and ("ON -> "..auto) or "OFF")
            .. "  |  Autoload: " .. (lib:GetAutoloadConfig() or "-")
    end

    mkButton("Create / Save config", function()
        local nm = (nameBox.Text ~= "" and nameBox.Text) or selectedName
        if not nm or nm == "" then
            lib:createDisplayMessage("Config", "Enter a config name first.", {{text="OK"}}, "warning"); return
        end
        lib:SaveConfig(nm); refreshList(); updateStatus()
        lib:createDisplayMessage("Config", "Saved: "..nm, {{text="OK"}}, "info")
    end)
    mkButton("Load selected config", function()
        if not selectedName then
            lib:createDisplayMessage("Config", "Select a config from the list first.", {{text="OK"}}, "warning"); return
        end
        lib:LoadConfig(selectedName)
    end)
    mkButton("Delete selected config", function()
        if not selectedName then return end
        lib:DeleteConfig(selectedName); selectedName = nil; refreshList(); updateStatus()
    end)
    mkButton("Refresh list", function() refreshList() end)

    -- toggle auto-save
    local autoRow = createContainerRow(body)
    local autoLbl = Instance.new("TextLabel")
    autoLbl.Size = UDim2.new(1,-70,1,0); autoLbl.Position = UDim2.fromOffset(12,0); autoLbl.BackgroundTransparency = 1
    autoLbl.Font = Enum.Font.GothamMedium; autoLbl.TextSize = 14; autoLbl.TextColor3 = ChiyoTheme.Text
    autoLbl.TextXAlignment = Enum.TextXAlignment.Left; autoLbl.Text = "Auto-save config"; autoLbl.Parent = autoRow
    local track = Instance.new("Frame")
    track.Size = UDim2.fromOffset(40,20); track.Position = UDim2.new(1,-52,0.5,-10)
    track.BackgroundColor3 = ChiyoTheme.Off; track.Parent = autoRow; applyCorner(track,10)
    local knob = Instance.new("Frame")
    knob.Size = UDim2.fromOffset(16,16); knob.Position = UDim2.new(0,2,0.5,-8); knob.BackgroundColor3 = Color3.new(1,1,1); knob.Parent = track; applyCorner(knob,8)
    local autoHit = Instance.new("TextButton"); autoHit.Size = UDim2.fromScale(1,1); autoHit.BackgroundTransparency = 1; autoHit.Text = ""; autoHit.Parent = autoRow
    local function renderAuto()
        local on = lib._autoSaveName ~= nil
        tween(track, FAST, { BackgroundColor3 = on and ChiyoTheme.Accent or ChiyoTheme.Off })
        tween(knob, FAST, { Position = on and UDim2.new(1,-18,0.5,-8) or UDim2.new(0,2,0.5,-8) })
    end
    autoHit.MouseButton1Click:Connect(function()
        if lib._autoSaveName then
            lib._autoSaveName = nil
        else
            local nm = (nameBox.Text ~= "" and nameBox.Text) or selectedName or "auto"
            lib._autoSaveName = nm; lib:SaveConfig(nm); refreshList()
        end
        renderAuto(); updateStatus()
    end)

    mkButton("Set as autoload (selected)", function()
        local nm = selectedName or (nameBox.Text ~= "" and nameBox.Text)
        if not nm then lib:createDisplayMessage("Autoload","Select or enter a config first.",{{text="OK"}},"warning"); return end
        lib:SetAutoloadConfig(nm); renderAuto(); updateStatus()
    end)
    mkButton("Reset autoload", function() lib:ClearAutoload(); renderAuto(); updateStatus() end)

    mkButton("Export (copy to clipboard)", function()
        lib:ExportConfig(selectedName)
        lib:createDisplayMessage("Export", "Config copied to clipboard.", {{text="OK"}}, "info")
    end)

    local importBox = mkTextbox("paste config JSON here...")
    mkButton("Import config", function()
        if importBox.Text == "" then return end
        local ok = lib:ImportConfig(importBox.Text, (nameBox.Text ~= "" and nameBox.Text) or nil)
        if ok then
            refreshList(); updateStatus()
            lib:createDisplayMessage("Import", "Config imported successfully!", {{text="OK"}}, "info")
        else
            lib:createDisplayMessage("Import", "Failed: invalid JSON format.", {{text="OK"}}, "danger")
        end
    end)

    refreshList(); renderAuto(); updateStatus()
    return sec
end

-- ============================================================
--  SETUP
-- ============================================================
local Setup = {}
Setup.__index = Setup

function Setup:CreateTab(opts)
    opts = opts or {}
    local index = #self._tabs + 1

    -- tombol icon di sidebar
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.fromOffset(40,40); btn.Position = UDim2.new(0.5,-20,0,52 + (index-1)*48)
    btn.BackgroundColor3 = ChiyoTheme.Element; btn.AutoButtonColor = false; btn.Text = ""
    btn.Parent = self._sidebar; applyCorner(btn,10)

    if opts.icon then
        local img = Instance.new("ImageLabel")
        img.Size = UDim2.fromOffset(22,22); img.Position = UDim2.fromScale(0.5,0.5); img.AnchorPoint = Vector2.new(0.5,0.5)
        img.BackgroundTransparency = 1; img.Image = opts.icon; img.ImageColor3 = ChiyoTheme.SubText; img.Parent = btn
        btn:SetAttribute("img", true)
    else
        local letter = Instance.new("TextLabel")
        letter.Size = UDim2.fromScale(1,1); letter.BackgroundTransparency = 1; letter.Font = Enum.Font.GothamBold
        letter.TextSize = 16; letter.TextColor3 = ChiyoTheme.SubText
        letter.Text = string.sub(opts.name or "T", 1, 1):upper(); letter.Parent = btn
    end

    -- halaman (page) dengan 2 kolom
    local page = Instance.new("ScrollingFrame")
    page.Size = UDim2.new(1,-16,1,0); page.Position = UDim2.fromOffset(8,0); page.BackgroundTransparency = 1
    page.BorderSizePixel = 0; page.ScrollBarThickness = 3; page.ScrollBarImageColor3 = ChiyoTheme.SubText
    page.AutomaticCanvasSize = Enum.AutomaticSize.Y; page.CanvasSize = UDim2.new()
    page.Visible = (index == 1); page.Parent = self._pageHolder

    local holder = Instance.new("Frame")
    holder.Size = UDim2.new(1,0,0,0); holder.AutomaticSize = Enum.AutomaticSize.Y
    holder.BackgroundTransparency = 1; holder.Parent = page
    applyPadding(holder, 2)

    local isTwoColumn = (opts.columns == 2)
    local tab = setmetatable({}, Tab)
    tab._lib = self._lib; tab._page = page
    tab._isTwoColumn = isTwoColumn
    
    if isTwoColumn then
        local colLeft = Instance.new("Frame")
        colLeft.Size = UDim2.new(0.5,-5,0,0); colLeft.Position = UDim2.fromScale(0,0); colLeft.AutomaticSize = Enum.AutomaticSize.Y
        colLeft.BackgroundTransparency = 1; colLeft.Parent = holder
        local llL = Instance.new("UIListLayout", colLeft); llL.Padding = UDim.new(0,10)

        local colRight = Instance.new("Frame")
        colRight.Size = UDim2.new(0.5,-5,0,0); colRight.Position = UDim2.new(0.5,5,0,0); colRight.AutomaticSize = Enum.AutomaticSize.Y
        colRight.BackgroundTransparency = 1; colRight.Parent = holder
        local llR = Instance.new("UIListLayout", colRight); llR.Padding = UDim.new(0,10)
        
        tab._colLeft = colLeft; tab._colRight = colRight
    else
        local colMain = Instance.new("Frame")
        colMain.Size = UDim2.new(1, 0, 0, 0); colMain.Position = UDim2.fromScale(0,0); colMain.AutomaticSize = Enum.AutomaticSize.Y
        colMain.BackgroundTransparency = 1; colMain.Parent = holder
        local llM = Instance.new("UIListLayout", colMain); llM.Padding = UDim.new(0,10)
        
        tab._colMain = colMain
    end
    tab._btn = btn

    local function highlight(active)
        local letter = btn:FindFirstChildOfClass("TextLabel")
        local img = btn:FindFirstChildOfClass("ImageLabel")
        tween(btn, FAST, { BackgroundColor3 = active and ChiyoTheme.Accent or ChiyoTheme.Element })
        if letter then letter.TextColor3 = active and Color3.new(1,1,1) or ChiyoTheme.SubText end
        if img then img.ImageColor3 = active and Color3.new(1,1,1) or ChiyoTheme.SubText end
    end
    tab._highlight = highlight

    btn.MouseButton1Click:Connect(function()
        if page.Visible then return end
        for _, t in ipairs(self._tabs) do t._page.Visible = false; t._highlight(false) end
        page.Visible = true; highlight(true)
        -- Smooth Slide Transition
        page.Position = UDim2.fromOffset(8, 20)
        tween(page, SMOOTH, { Position = UDim2.fromOffset(8, 0) })
    end)

    table.insert(self._tabs, tab)
    highlight(index == 1)
    return tab
end

-- backward compatible: Setup:CreateSection langsung pakai tab default
function Setup:CreateSection(name)
    if not self._defaultTab then
        self._defaultTab = self:CreateTab({ name = "Main", icon = self._homeIcon })
    end
    return self._defaultTab:CreateSection(name)
end

-- ============================================================
local function resolveAnchor(name)
    local m = {
        ["Top Center"]   = { Vector2.new(0.5,0), UDim2.new(0.5,0,0,12) },
        ["Top Right"]    = { Vector2.new(1,0),   UDim2.new(1,-12,0,12) },
        ["Top Left"]     = { Vector2.new(0,0),   UDim2.new(0,12,0,12) },
        ["Center Left"]  = { Vector2.new(0,0.5), UDim2.new(0,12,0.5,0) },
        ["Bottom Left"]  = { Vector2.new(0,1),   UDim2.new(0,12,1,-12) },
        ["Bottom Right"] = { Vector2.new(1,1),   UDim2.new(1,-12,1,-12) },
    }
    return m[name] or m["Top Center"]
end

local function inBounds(gui, pos)
    local ap, as = gui.AbsolutePosition, gui.AbsoluteSize
    return pos.X >= ap.X and pos.X <= ap.X + as.X and pos.Y >= ap.Y and pos.Y <= ap.Y + as.Y
end

-- drag pakai deteksi posisi global + Spring/Lerp smooth movement
local function makeDraggable(handle, target, ignore)
    local dragging, dragInput, dragStart, startPos
    UserInputService.InputBegan:Connect(function(i, gpe)
        if gpe then return end
        if (i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch)
           and inBounds(handle, i.Position) and not (ignore and inBounds(ignore, i.Position)) then
            dragging = true; dragStart = i.Position; startPos = target.Position
        end
    end)
    UserInputService.InputChanged:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch then
            dragInput = i
        end
    end)
    UserInputService.InputEnded:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end)
    
    local targetPos = target.Position
    RunService.RenderStepped:Connect(function(dt)
        if dragging and dragInput then
            local delta = dragInput.Position - dragStart
            targetPos = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
        target.Position = target.Position:Lerp(targetPos, math.clamp(dt * 15, 0, 1))
    end)
end

-- ============================================================
--  LIBRARY:SETUP
-- ============================================================
function Library:Setup(config)
    config = config or {}
    self._location = config.Location or CoreGui

    -- bikin folder config di workspace executor (kalau didukung)
    _ensureFolder()

    -- hapus UI lama biar nggak dobel kalau script di-execute ulang
    for _, gui in ipairs(self._location:GetChildren()) do
        if gui.Name == "CY_Library" or gui.Name == "CY_Message" or gui.Name == "CY_KeyCheck" then
            pcall(function() gui:Destroy() end)
        end
    end

    -- ===== KEY SYSTEM (optional) =====
    if config.KeyValidator then
        local validated = false
        local keyGui = Instance.new("ScreenGui")
        keyGui.Name = "CY_KeyCheck"; keyGui.ResetOnSpawn = false
        keyGui.DisplayOrder = 1000; keyGui.IgnoreGuiInset = true; keyGui.Parent = self._location

        local overlay = Instance.new("Frame")
        overlay.Size = UDim2.fromScale(1,1); overlay.BackgroundColor3 = Color3.new(0,0,0)
        overlay.BackgroundTransparency = 0.4; overlay.Parent = keyGui

        local card = Instance.new("Frame")
        card.Size = UDim2.fromOffset(340, 0); card.AutomaticSize = Enum.AutomaticSize.Y
        card.AnchorPoint = Vector2.new(0.5,0.5)
        card.Position = UDim2.new(0.5,0,1.3,0)
        card.BackgroundColor3 = ChiyoTheme.Window; card.Parent = keyGui
        applyCorner(card,14); applyStroke(card, ChiyoTheme.Accent, 1.6, 0.05)
        local cardLayout = Instance.new("UIListLayout",card)
        cardLayout.Padding = UDim.new(0,10); cardLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
        cardLayout.SortOrder = Enum.SortOrder.LayoutOrder
        applyPadding(card, 20)

        -- top accent bar
        local topBar = Instance.new("Frame")
        topBar.Size = UDim2.new(1,0,0,3); topBar.BackgroundColor3 = ChiyoTheme.Accent
        topBar.BorderSizePixel = 0; topBar.LayoutOrder = 0; topBar.Parent = card
        applyGradient(topBar, ChiyoTheme.AccentGlow, ChiyoTheme.AccentDark, 0)

        -- logo
        local kLogo = Instance.new("ImageLabel")
        kLogo.Size = UDim2.fromOffset(56,56); kLogo.BackgroundColor3 = ChiyoTheme.Element
        kLogo.Image = getLogoImage(config.Logo)
        kLogo.ScaleType = Enum.ScaleType.Fit; kLogo.LayoutOrder = 1; kLogo.Parent = card
        local lC = Instance.new("UICorner", kLogo); lC.CornerRadius = UDim.new(1, 0); applyStroke(kLogo, ChiyoTheme.Accent, 1.4, 0.1)

        -- title
        local kTitle = Instance.new("TextLabel")
        kTitle.Size = UDim2.new(1,0,0,24); kTitle.BackgroundTransparency = 1
        kTitle.Font = Enum.Font.GothamBold; kTitle.TextSize = 18; kTitle.TextColor3 = ChiyoTheme.Text
        kTitle.Text = config.Title or "Hub"; kTitle.TextXAlignment = Enum.TextXAlignment.Center
        kTitle.LayoutOrder = 2; kTitle.Parent = card

        -- subtitle
        local kSub = Instance.new("TextLabel")
        kSub.Size = UDim2.new(1,0,0,16); kSub.BackgroundTransparency = 1
        kSub.Font = Enum.Font.Gotham; kSub.TextSize = 12; kSub.TextColor3 = ChiyoTheme.SubText
        kSub.Text = "Enter your access key to continue"; kSub.TextXAlignment = Enum.TextXAlignment.Center
        kSub.LayoutOrder = 3; kSub.Parent = card

        -- textbox row
        local kBoxFrame = Instance.new("Frame")
        kBoxFrame.Size = UDim2.new(1,0,0,36); kBoxFrame.BackgroundColor3 = ChiyoTheme.Element
        kBoxFrame.LayoutOrder = 4; kBoxFrame.Parent = card
        applyCorner(kBoxFrame, 8); applyStroke(kBoxFrame, ChiyoTheme.Stroke, 1)
        local kBox = Instance.new("TextBox")
        kBox.Size = UDim2.new(1,-16,1,-8); kBox.Position = UDim2.fromOffset(8,4)
        kBox.BackgroundTransparency = 1; kBox.Font = Enum.Font.GothamMedium; kBox.TextSize = 13
        kBox.TextColor3 = ChiyoTheme.Text; kBox.PlaceholderText = "Enter your key here..."
        kBox.PlaceholderColor3 = ChiyoTheme.SubText; kBox.Text = ""
        kBox.ClearTextOnFocus = false; kBox.TextXAlignment = Enum.TextXAlignment.Left; kBox.Parent = kBoxFrame
        local kBoxPad = Instance.new("UIPadding",kBox); kBoxPad.PaddingLeft = UDim.new(0,4)

        -- validate button
        local kBtn = Instance.new("TextButton")
        kBtn.Size = UDim2.new(1,0,0,36); kBtn.BackgroundColor3 = ChiyoTheme.Accent; kBtn.AutoButtonColor = false
        kBtn.Font = Enum.Font.GothamBold; kBtn.TextSize = 14; kBtn.TextColor3 = Color3.new(1,1,1)
        kBtn.Text = "Validate Key"; kBtn.LayoutOrder = 5; kBtn.Parent = card
        applyCorner(kBtn,8); applyGradient(kBtn, ChiyoTheme.AccentGlow, ChiyoTheme.AccentDark, 90)
        kBtn.MouseEnter:Connect(function() tween(kBtn,FAST,{BackgroundColor3=ChiyoTheme.AccentGlow}) end)
        kBtn.MouseLeave:Connect(function() tween(kBtn,FAST,{BackgroundColor3=ChiyoTheme.Accent}) end)

        -- status
        local kStatus = Instance.new("TextLabel")
        kStatus.Size = UDim2.new(1,0,0,14); kStatus.BackgroundTransparency = 1
        kStatus.Font = Enum.Font.Gotham; kStatus.TextSize = 11; kStatus.TextColor3 = ChiyoTheme.SubText
        kStatus.Text = ""; kStatus.TextXAlignment = Enum.TextXAlignment.Center
        kStatus.LayoutOrder = 6; kStatus.Parent = card

        -- discord footer
        if config.Discord then
            local kFoot = Instance.new("TextLabel")
            kFoot.Size = UDim2.new(1,0,0,14); kFoot.BackgroundTransparency = 1
            kFoot.Font = Enum.Font.Gotham; kFoot.TextSize = 10; kFoot.TextColor3 = ChiyoTheme.Accent
            kFoot.Text = "Get key → " .. config.Discord; kFoot.TextXAlignment = Enum.TextXAlignment.Center
            kFoot.LayoutOrder = 7; kFoot.Parent = card
        end

        -- slide in
        tween(card, SMOOTH, { Position = UDim2.new(0.5,0,0.5,0) })

        -- validate logic
        local checking = false
        kBtn.MouseButton1Click:Connect(function()
            if checking then return end
            local k = kBox.Text
            if k == "" then
                kStatus.TextColor3 = Color3.fromRGB(235,70,90); kStatus.Text = "Key cannot be empty."
                return
            end
            checking = true
            kStatus.TextColor3 = ChiyoTheme.SubText; kStatus.Text = "Checking..."
            kBtn.Text = "Checking..."; kBtn.BackgroundColor3 = ChiyoTheme.AccentDark

            task.spawn(function()
                local ok, result = pcall(config.KeyValidator, k)
                if ok and result == true then
                    local welcome = self._keyMsg or "Valid! Loading hub..."
                    if self._tier then welcome = welcome .. " ("..tostring(self._tier)..")" end
                    kStatus.TextColor3 = Color3.fromRGB(80,220,120); kStatus.Text = welcome
                    task.wait(0.7)
                    tween(card, FAST, { Position = UDim2.new(0.5,0,1.3,0) })
                    task.wait(0.25); keyGui:Destroy(); validated = true
                else
                    -- pakai pesan asli dari server kalau ada (Device limit / Expired / dll)
                    kStatus.TextColor3 = Color3.fromRGB(235,70,90)
                    kStatus.Text = self._keyMsg or "Invalid key. Try again."
                    kBtn.Text = "Validate Key"; kBtn.BackgroundColor3 = ChiyoTheme.Accent; checking = false
                end
            end)
        end)

        repeat task.wait(0.1) until validated
    end
    -- ===== END KEY SYSTEM =====

    local screen = Instance.new("ScreenGui")
    screen.Name = "CY_Library"; screen.ResetOnSpawn = false; screen.IgnoreGuiInset = true
    screen.ZIndexBehavior = Enum.ZIndexBehavior.Sibling; screen.Parent = self._location

    -- WINDOW
    local W, H = 580, 430
    local window = Instance.new("Frame")
    window.Size = UDim2.fromOffset(W, H); window.Position = UDim2.new(0.5,-W/2,0.5,-H/2)
    window.BackgroundColor3 = ChiyoTheme.Window; window.BackgroundTransparency = 0.15; window.ClipsDescendants = false; window.Parent = screen
    applyCorner(window, 14); applyStroke(window, ChiyoTheme.Accent, 1.4, 0.25)
    applyDropShadow(window, 0.3)

    -- ===== SIDEBAR =====
    local sidebar = Instance.new("Frame")
    sidebar.Size = UDim2.new(0,52,1,0); sidebar.BackgroundColor3 = ChiyoTheme.Sidebar; sidebar.Parent = window
    applyPartialRadius(sidebar, "left", ChiyoTheme.Sidebar, 14)

    -- LOGO (template, tinggal ganti config.Logo)
    local logo = Instance.new("ImageLabel")
    logo.Size = UDim2.fromOffset(36,36); logo.Position = UDim2.new(0.5,-18,0,8); logo.BackgroundColor3 = ChiyoTheme.Element
    logo.Image = getLogoImage(config.Logo); logo.Parent = sidebar
    local mC = Instance.new("UICorner", logo); mC.CornerRadius = UDim.new(1, 0); applyStroke(logo, ChiyoTheme.Accent, 1.4, 0.1)

    -- ===== MAIN CONTAINER =====
    local main = Instance.new("Frame")
    main.Size = UDim2.new(1,-52,1,0); main.Position = UDim2.fromOffset(52,0)
    main.BackgroundTransparency = 1; main.Parent = window

    -- TITLEBAR
    local titlebar = Instance.new("Frame")
    titlebar.Size = UDim2.new(1,0,0,40); titlebar.BackgroundColor3 = ChiyoTheme.Card; titlebar.Parent = main
    applyPartialRadius(titlebar, "top", ChiyoTheme.Card, 14)
    applyGradient(titlebar, ChiyoTheme.AccentDark, ChiyoTheme.Card, 25)

    -- SEARCH BAR (ganti judul)
    local search = Instance.new("TextBox")
    search.Size = UDim2.new(1,-52,0,26); search.Position = UDim2.new(0,12,0.5,-13)
    search.BackgroundColor3 = ChiyoTheme.Window; search.Font = Enum.Font.Gotham; search.TextSize = 13
    search.TextColor3 = ChiyoTheme.Text; search.PlaceholderText = "Search..."; search.PlaceholderColor3 = ChiyoTheme.SubText
    search.Text = ""; search.ClearTextOnFocus = false; search.TextXAlignment = Enum.TextXAlignment.Left
    search.ZIndex = 2; search.Parent = titlebar
    applyCorner(search, 7); applyStroke(search, ChiyoTheme.Stroke, 1)
    local sPad = Instance.new("UIPadding", search); sPad.PaddingLeft = UDim.new(0,10); sPad.PaddingRight = UDim.new(0,10)
    search:GetPropertyChangedSignal("Text"):Connect(function()
        self:_runSearch(search.Text)
    end)

    local closeBtn = Instance.new("TextButton")
    closeBtn.Size = UDim2.fromOffset(26,26); closeBtn.Position = UDim2.new(1,-34,0.5,-13)
    closeBtn.BackgroundColor3 = Color3.fromRGB(60,40,80); closeBtn.Font = Enum.Font.GothamBold
    closeBtn.TextSize = 16; closeBtn.TextColor3 = ChiyoTheme.Text; closeBtn.Text = "x"; closeBtn.ZIndex = 2; closeBtn.Parent = titlebar
    applyCorner(closeBtn, 8)

    -- BOTTOM BAR (discord | versi | game)
    local bottombar = Instance.new("TextButton")
    bottombar.Size = UDim2.new(1,0,0,26); bottombar.Position = UDim2.new(0,0,1,-26)
    bottombar.BackgroundColor3 = ChiyoTheme.Bar; bottombar.AutoButtonColor = false; bottombar.Text = ""; bottombar.Parent = main
    applyPartialRadius(bottombar, "bottom", ChiyoTheme.Bar, 14)

    local info = Instance.new("TextLabel")
    info.Size = UDim2.fromScale(1,1); info.BackgroundTransparency = 1; info.Font = Enum.Font.GothamMedium
    info.TextSize = 12; info.TextColor3 = ChiyoTheme.SubText; info.ZIndex = 2
    info.Text = string.format("%s  |  %s  |  Game: %s",
        config.Discord or "discord.gg/yourserver", config.Version or "v1.0", config.Game or "Unknown")
    info.Parent = bottombar

    -- klik bottom bar = copy link discord (kalau executor support setclipboard)
    bottombar.MouseButton1Click:Connect(function()
        local cb = setclipboard or (syn and syn.write_clipboard) or toclipboard
        if cb and config.Discord then
            pcall(cb, "https://" .. config.Discord)
            info.Text = "Discord link copied!"
            task.delay(1.5, function()
                info.Text = string.format("%s  |  %s  |  Game: %s",
                    config.Discord or "discord.gg/yourserver", config.Version or "v1.0", config.Game or "Unknown")
            end)
        end
    end)

    -- PAGE HOLDER (tempat semua tab)
    local pageHolder = Instance.new("Frame")
    pageHolder.Size = UDim2.new(1,0,1,-72); pageHolder.Position = UDim2.fromOffset(0,44)
    pageHolder.BackgroundTransparency = 1; pageHolder.Parent = main

    -- ===== RESIZE GRIP (pojok kanan-bawah) — titik bunder estetik =====
    local grip = Instance.new("TextButton")
    grip.Size = UDim2.fromOffset(20,20); grip.Position = UDim2.new(1,-22,1,-22)
    grip.BackgroundTransparency = 1; grip.Text = ""; grip.ZIndex = 10; grip.Parent = window
    local function gripDot(x,y)
        local d = Instance.new("Frame")
        d.Size = UDim2.fromOffset(4,4); d.Position = UDim2.fromOffset(x,y)
        d.BackgroundColor3 = ChiyoTheme.Accent; d.BackgroundTransparency = 0.2; d.BorderSizePixel = 0
        d.ZIndex = 10; d.Parent = grip; applyCorner(d, 2)
    end
    gripDot(13,5); gripDot(5,13); gripDot(13,13)
    local resizing, rStart, rStartSize
    grip.MouseButton1Down:Connect(function()
        resizing = true; rStart = UserInputService:GetMouseLocation(); rStartSize = window.AbsoluteSize
    end)
    UserInputService.InputEnded:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 then resizing = false end
    end)
    UserInputService.InputChanged:Connect(function(i)
        if resizing and i.UserInputType == Enum.UserInputType.MouseMovement then
            local d = UserInputService:GetMouseLocation() - rStart
            W = math.clamp(rStartSize.X + d.X, 380, 900)
            H = math.clamp(rStartSize.Y + d.Y, 240, 720)
            window.Size = UDim2.fromOffset(W, H)
        end
    end)

    -- ===== TOGGLE BUTTON (open/close) =====
    local toggleBtn = Instance.new("ImageButton")
    toggleBtn.Size = UDim2.fromOffset(46,46)
    if config.OpenCloseLocation then
        -- pakai posisi layar (Top Left, Top Right, dll)
        local anchor = resolveAnchor(config.OpenCloseLocation)
        toggleBtn.AnchorPoint = anchor[1]; toggleBtn.Position = anchor[2]
    else
        -- default: nempel di pojok kiri-atas window
        toggleBtn.AnchorPoint = Vector2.new(0,1)
        toggleBtn.Position = UDim2.new(0.5, -W/2, 0.5, -H/2 - 8)
    end
    toggleBtn.BackgroundColor3 = ChiyoTheme.Accent; toggleBtn.Image = getLogoImage(config.Logo); toggleBtn.Parent = screen
    local tC = Instance.new("UICorner", toggleBtn); tC.CornerRadius = UDim.new(1, 0); applyGradient(toggleBtn, ChiyoTheme.AccentGlow, ChiyoTheme.AccentDark, 90); applyStroke(toggleBtn, ChiyoTheme.AccentGlow, 1.2, 0.2)

    local isOpen = true
    local function setOpen(state)
        isOpen = state; window.Visible = true
        if state then
            window.Size = UDim2.fromOffset(W,0); tween(window, SMOOTH, { Size = UDim2.fromOffset(W,H) })
        else
            local t = tween(window, FAST, { Size = UDim2.fromOffset(W,0) })
            t.Completed:Connect(function() if not isOpen then window.Visible = false end end)
        end
    end
    -- tombol toggle bisa di-drag; klik (tanpa geser) buat buka/tutup
    do
        local tDrag, tMoved, tStartInput, tStartPos
        toggleBtn.InputBegan:Connect(function(i)
            if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
                tDrag = true; tMoved = false; tStartInput = i.Position; tStartPos = toggleBtn.Position
            end
        end)
        UserInputService.InputChanged:Connect(function(i)
            if tDrag and (i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch) then
                local d = i.Position - tStartInput
                if math.abs(d.X) > 4 or math.abs(d.Y) > 4 then tMoved = true end
                toggleBtn.Position = UDim2.new(tStartPos.X.Scale, tStartPos.X.Offset + d.X, tStartPos.Y.Scale, tStartPos.Y.Offset + d.Y)
            end
        end)
        UserInputService.InputEnded:Connect(function(i)
            if tDrag and (i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch) then
                tDrag = false
                if not tMoved then setOpen(not isOpen) end
            end
        end)
    end
    closeBtn.MouseButton1Click:Connect(function() setOpen(false) end)
    closeBtn.MouseEnter:Connect(function() tween(closeBtn,FAST,{BackgroundColor3=Color3.fromRGB(200,60,80)}) end)
    closeBtn.MouseLeave:Connect(function() tween(closeBtn,FAST,{BackgroundColor3=Color3.fromRGB(60,40,80)}) end)
    -- keybind buka/tutup menu (bisa diganti lewat CreateMenuKeybind)
    self.Flags.menuKeybind = config.MenuKey or "RightShift"
    UserInputService.InputBegan:Connect(function(i, gpe)
        if gpe or self._rebindingMenu then return end
        if i.UserInputType == Enum.UserInputType.Keyboard and i.KeyCode.Name == self.Flags.menuKeybind then
            setOpen(not isOpen)
        end
    end)
    makeDraggable(titlebar, window, search)

    window.Size = UDim2.fromOffset(W,0); tween(window, SMOOTH, { Size = UDim2.fromOffset(W,H) })

    local setup = setmetatable({}, Setup)
    setup._lib = self; setup._screen = screen; setup._window = window
    setup._sidebar = sidebar; setup._pageHolder = pageHolder
    setup._tabs = {}; setup._homeIcon = config.Logo
    return setup
end


Library = setmetatable({}, Library)

--[[ ════════════════════════════════════════════════════════════
     CONTOH PEMAKAIAN (ini yang nanti masuk ke script kamu)
     ════════════════════════════════════════════════════════════ ]]

local Setup = Library:Setup({
    Location = CoreGui,
    -- OpenCloseLocation nggak diisi -> tombol nempel di pojok kiri-atas window
    Logo    = "rbxassetid://0",     -- ganti pakai ID logo kamu
    Title   = "Versus Hub",
    Discord = "discord.gg/chiyo",
    Version = "v1.0",
    Game    = "Slime RNG",
})

-- ===== TAB 1: MAIN =====
local Main = Setup:CreateTab({ name = "Main", columns = 1 })

local Rolling = Main:CreateSection("Rolling")
Rolling:CreateToggle({ name = "Auto Roll", flag = "autoRoll", default = false, callback = function(v)
    print("Auto Roll:", v)
end })
Rolling:CreateToggle({ name = "Auto Equip Best", flag = "autoEquip" })
Rolling:CreateDropdown({ name = "Best Mode", flag = "bestMode", options = { "Damage", "Speed", "Luck" }, default = "Damage" })
Rolling:CreateSlider({ name = "Equip Delay", flag = "equipDelay", min = 0, max = 300, default = 30 })

local Collection = Main:CreateSection("Collection")
Collection:CreateToggle({ name = "Auto Collect Loot", flag = "collectLoot" })
Collection:CreateToggle({ name = "Auto Collect Fruits", flag = "collectFruits" })

local Special = Main:CreateSection("Special Roll")
Special:CreateTextbox({ name = "Save At", flag = "saveAt", placeholder = "Default" })
Special:CreateButton({ name = "Rejoin Server", callback = function()
    Library:createDisplayMessage("Rejoin", "Are you sure you want to rejoin?", {
        { text = "Yes", callback = function() print("rejoin...") end },
        { text = "Cancel" },
    }, "warning")
end })

-- ===== TAB 2: MISC (config, keybind, element baru) =====
local Misc = Setup:CreateTab({ name = "Misc", columns = 2 })

local KeybindSec = Misc:CreateSection("Keybinds")
KeybindSec:CreateMenuKeybind({ name = "Menu Keybind", default = "RightShift" })  -- buka/tutup UI
KeybindSec:CreateKeybind({ name = "Toggle Fly", flag = "flyKey", default = "F", callback = function()
    print("Fly key ditekan!")
end })

local ElemSec = Misc:CreateSection("Test Elements")
ElemSec:CreateMultiDropdown({ name = "Boost Types", flag = "boosts",
    options = { "Luck", "Speed", "Damage", "Coins" }, default = { "Luck" } })

-- panel config lengkap cuma 1 baris (save/load/delete/list/autoload/auto-save/export/import)
Misc:CreateConfigSection({ title = "Configuration" })

-- terapin autoload kalau user udah pernah set (dipanggil setelah semua UI dibuat)
Library:ApplyAutoload()

print("UI loaded! Press RightShift to toggle.")
