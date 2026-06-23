-- =============================================
-- Kunsy Loader
-- Entry point — THIS FILE GETS OBFUSCATED
-- =============================================

local VERSION  = "1.0.0"
local BASE_URL = "https://raw.githubusercontent.com/Kunsyy/hub-library/main/"
local KEY_API  = "https://kunsydev.xyz/api/validate"
local KEY_FILE = "Kunsy/key.txt"

local HttpService = game:GetService("HttpService")
local RunService  = game:GetService("RunService")

-- ── Utilities ─────────────────────────────────────────────────────────────────

local function fetch(url)
    local ok, res = pcall(game.HttpGet, game, url)
    return ok and res or nil
end

local function getHWID()
    local ok, id = pcall(function()
        return game:GetService("RbxAnalyticsService"):GetClientId()
    end)
    return ok and tostring(id) or "unknown"
end

-- ── Key persistence ────────────────────────────────────────────────────────────

local function readKey()
    local ok, val = pcall(readfile, KEY_FILE)
    local key = ok and val and val:gsub("%s+", "") or ""
    return #key > 0 and key or nil
end

local function saveKey(key)
    pcall(function()
        if not isfolder("Kunsy") then makefolder("Kunsy") end
        writefile(KEY_FILE, key)
    end)
end

local function clearKey()
    pcall(writefile, KEY_FILE, "")
end

-- ── Popup UI ──────────────────────────────────────────────────────────────────
-- Matches kunsydev.xyz purple theme (#a855f7)

local PURPLE     = Color3.fromRGB(168, 85, 247)
local PURPLE_DIM = Color3.fromRGB(100, 40, 160)
local BG         = Color3.fromRGB(12, 12, 18)
local SURFACE    = Color3.fromRGB(22, 22, 32)
local RED        = Color3.fromRGB(220, 50, 60)
local WHITE      = Color3.fromRGB(255, 255, 255)
local GRAY       = Color3.fromRGB(160, 160, 160)
local DARK_GRAY  = Color3.fromRGB(70, 70, 80)

local function makeCorner(parent, radius)
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, radius or 8)
    c.Parent = parent
    return c
end

local function makeStroke(parent, color, thickness)
    local s = Instance.new("UIStroke")
    s.Color = color or PURPLE_DIM
    s.Thickness = thickness or 1
    s.Parent = parent
    return s
end

local function makeLabel(parent, props)
    local l = Instance.new("TextLabel")
    l.BackgroundTransparency = 1
    l.Font        = props.bold and Enum.Font.GothamBold or Enum.Font.Gotham
    l.Text        = props.text or ""
    l.TextColor3  = props.color or WHITE
    l.TextSize    = props.size or 14
    l.TextWrapped = props.wrap ~= false
    l.TextXAlignment = props.align or Enum.TextXAlignment.Left
    l.Position    = props.pos or UDim2.new()
    l.Size        = props.sz or UDim2.fromScale(1, 0)
    l.ZIndex      = props.z or 12
    l.Parent      = parent
    return l
end

local function createScreen(name)
    local sg = Instance.new("ScreenGui")
    sg.Name = name
    sg.ResetOnSpawn = false
    sg.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    pcall(function() sg.Parent = game:GetService("CoreGui") end)

    local overlay = Instance.new("Frame")
    overlay.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    overlay.BackgroundTransparency = 0.55
    overlay.Size  = UDim2.fromScale(1, 1)
    overlay.ZIndex = 10
    overlay.Parent = sg

    return sg, overlay
end

local function makeCard(parent, w, h)
    local card = Instance.new("Frame")
    card.AnchorPoint = Vector2.new(0.5, 0.5)
    card.BackgroundColor3 = BG
    card.BorderSizePixel = 0
    card.Position = UDim2.fromScale(0.5, 0.5)
    card.Size = UDim2.fromOffset(w, h)
    card.ZIndex = 11
    card.Parent = parent
    makeCorner(card, 12)
    makeStroke(card, PURPLE_DIM, 1)

    -- top accent stripe
    local stripe = Instance.new("Frame")
    stripe.BackgroundColor3 = PURPLE
    stripe.BorderSizePixel  = 0
    stripe.Size = UDim2.new(1, 0, 0, 3)
    stripe.ZIndex = 12
    stripe.Parent = card
    makeCorner(stripe, 2)

    return card
end

local function makeButton(parent, text, color, pos, sz)
    local btn = Instance.new("TextButton")
    btn.BackgroundColor3 = color or PURPLE
    btn.BorderSizePixel  = 0
    btn.Position = pos
    btn.Size     = sz or UDim2.fromOffset(120, 36)
    btn.Text     = text
    btn.TextColor3 = WHITE
    btn.TextSize = 14
    btn.Font = Enum.Font.GothamBold
    btn.ZIndex = 12
    btn.Parent = parent
    makeCorner(btn, 7)
    return btn
end

-- ── Info popup (game not supported / error / success) ─────────────────────────

local function showPopup(title, message, isError, onClose)
    local sg, overlay = createScreen("KunsyPopup")
    local card = makeCard(sg, 360, 190)

    makeLabel(card, {
        text = title, bold = true, size = 16, z = 12,
        pos = UDim2.fromOffset(20, 18),
        sz  = UDim2.new(1, -40, 0, 22),
        color = isError and RED or WHITE,
    })
    makeLabel(card, {
        text = message, size = 13, color = GRAY, wrap = true, z = 12,
        pos = UDim2.fromOffset(20, 48),
        sz  = UDim2.new(1, -40, 0, 72),
    })

    local closeBtn = makeButton(card, "OK",
        isError and RED or PURPLE,
        UDim2.new(0.5, -60, 0, 138),
        UDim2.fromOffset(120, 34)
    )

    local function dismiss()
        sg:Destroy()
        if onClose then onClose() end
    end
    closeBtn.MouseButton1Click:Connect(dismiss)
    if not isError then
        task.delay(8, function() pcall(dismiss) end)
    end
end

-- ── Key input prompt ──────────────────────────────────────────────────────────

local function showKeyPrompt(onSubmit)
    local sg, overlay = createScreen("KunsyKeyPrompt")
    local card = makeCard(sg, 380, 240)

    makeLabel(card, {
        text = "Kunsy — Enter Key", bold = true, size = 16, z = 12,
        pos = UDim2.fromOffset(20, 18),
        sz  = UDim2.new(1, -40, 0, 22),
    })
    makeLabel(card, {
        text = "Get a free key daily from kunsydev.xyz or our Discord bot.",
        size = 12, color = GRAY, wrap = true, z = 12,
        pos = UDim2.fromOffset(20, 46),
        sz  = UDim2.new(1, -40, 0, 28),
    })

    -- Input field
    local inputBg = Instance.new("Frame")
    inputBg.BackgroundColor3 = SURFACE
    inputBg.BorderSizePixel  = 0
    inputBg.Position = UDim2.fromOffset(20, 84)
    inputBg.Size     = UDim2.new(1, -40, 0, 40)
    inputBg.ZIndex   = 12
    inputBg.Parent   = card
    makeCorner(inputBg, 7)
    makeStroke(inputBg, DARK_GRAY, 1)

    local box = Instance.new("TextBox")
    box.BackgroundTransparency = 1
    box.Position = UDim2.fromOffset(12, 0)
    box.Size     = UDim2.new(1, -24, 1, 0)
    box.Text     = ""
    box.PlaceholderText  = "KUNSY-XXXX-XXXX-XXXX"
    box.PlaceholderColor3 = DARK_GRAY
    box.TextColor3 = WHITE
    box.TextSize   = 13
    box.Font = Enum.Font.Code
    box.ClearTextOnFocus = false
    box.ZIndex = 13
    box.Parent = inputBg

    -- Status label
    local status = makeLabel(card, {
        text = "", size = 12, color = RED, z = 12,
        pos = UDim2.fromOffset(20, 130),
        sz  = UDim2.new(1, -40, 0, 18),
        align = Enum.TextXAlignment.Center,
    })

    local activateBtn = makeButton(card, "Activate",
        PURPLE,
        UDim2.fromOffset(20, 156),
        UDim2.new(1, -40, 0, 38)
    )

    makeLabel(card, {
        text = "kunsydev.xyz", size = 11, color = PURPLE_DIM, z = 12,
        pos  = UDim2.fromOffset(0, 206),
        sz   = UDim2.fromScale(1, 0),
        align = Enum.TextXAlignment.Center,
    })

    activateBtn.MouseButton1Click:Connect(function()
        local key = box.Text:gsub("%s+", ""):upper()
        if #key < 5 then
            status.Text = "Please enter a valid key."
            return
        end
        status.TextColor3 = GRAY
        status.Text = "Validating..."
        activateBtn.Active = false
        task.spawn(function()
            sg:Destroy()
            onSubmit(key)
        end)
    end)
end

-- ── Key validation ─────────────────────────────────────────────────────────────

local function validateKey(key)
    -- ── DEV MODE — remove when backend is ready ──────────────────
    -- return true, "free"
    -- ─────────────────────────────────────────────────────────────

    local body = HttpService:JSONEncode({
        key  = key,
        hwid = getHWID(),
    })

    local ok, raw = pcall(
        HttpService.PostAsync, HttpService,
        KEY_API, body,
        Enum.HttpContentType.ApplicationJson, false
    )

    if not ok then
        return false, nil, "Could not reach server. Check your connection."
    end

    local parsed, err = pcall(HttpService.JSONDecode, HttpService, raw)
    if not parsed then
        return false, nil, "Server returned an invalid response."
    end

    local data = err  -- JSONDecode returns the table as second value via pcall
    if data.valid then
        return true, data.tier or "free", nil
    else
        return false, nil, data.message or "Invalid or expired key."
    end
end

-- ── Game index ─────────────────────────────────────────────────────────────────

local function loadIndex()
    local raw = fetch(BASE_URL .. "games/index.lua")
    if not raw then return nil, "Failed to fetch game list." end
    local fn, err = loadstring(raw)
    if not fn then return nil, "Game list is corrupted: " .. tostring(err) end
    local ok, result = pcall(fn)
    return ok and result or nil, not ok and result or nil
end

-- ── Main ──────────────────────────────────────────────────────────────────────

local function boot(key)
    -- 1. Validate key
    local valid, tier, keyErr = validateKey(key)

    if not valid then
        clearKey()
        showPopup(
            "Invalid Key",
            (keyErr or "Your key is invalid or expired.") .. "\n\nGet a new key at kunsydev.xyz",
            true,
            function()
                -- re-show prompt so user can try again
                showKeyPrompt(function(newKey)
                    saveKey(newKey)
                    boot(newKey)
                end)
            end
        )
        return
    end

    -- 2. Load game index
    local index, indexErr = loadIndex()
    if not index then
        showPopup("Error", indexErr or "Could not load game list.", true)
        return
    end

    -- 3. Match current game
    local placeId   = game.PlaceId
    local scriptPath = index[placeId]

    if not scriptPath then
        showPopup(
            "Game Not Supported",
            "This game is not supported yet.\n\nPlace ID: " .. tostring(placeId) ..
            "\n\nCheck kunsydev.xyz for the full list of supported games.",
            false
        )
        return
    end

    -- 4. Load game script
    getgenv().KunsyTier    = tier
    getgenv().KunsyVersion = VERSION

    local gameScript = fetch(BASE_URL .. scriptPath)
    if not gameScript then
        showPopup("Error", "Failed to download script for this game.", true)
        return
    end

    local fn, compileErr = loadstring(gameScript)
    if not fn then
        showPopup("Error", "Script compile error:\n" .. tostring(compileErr), true)
        return
    end

    local ok, runErr = pcall(fn)
    if not ok then
        showPopup("Error", "Script crashed:\n" .. tostring(runErr), true)
    end
end

local function main()
    local key = readKey()

    if not key then
        showKeyPrompt(function(inputKey)
            saveKey(inputKey)
            boot(inputKey)
        end)
    else
        boot(key)
    end
end

main()
