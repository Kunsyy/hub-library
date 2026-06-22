local request = (syn and syn.request) or (http and http.request) or http_request

local TweenService = game:GetService("TweenService")
local HttpService = game:GetService("HttpService")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local CoreGui = game:GetService("CoreGui")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local TeleportService = game:GetService("TeleportService")
local VirtualUser = game:GetService("VirtualUser")
local Workspace = game:GetService("Workspace")

local client = Players.LocalPlayer

print("Loading Library...")

local Library = loadstring(game:HttpGet("https://versusairlines.top/scripts/NewLibrary.lua"))()

local Setup = Library:Setup({
    Location = CoreGui,
    OpenCloseLocation = "Top Center"
})

client.Idled:Connect(function()
    VirtualUser:Button2Down(Vector2.new(0, 0), Workspace.CurrentCamera.CFrame)
    wait(1)
    VirtualUser:Button2Up(Vector2.new(0, 0), Workspace.CurrentCamera.CFrame)
end)

-----------------------------------------------------------------

local function interval(tag, flag, delayTime, callback)
    Library:CleanupConnectionsByTag(tag)
    delayTime = math.max(tonumber(delayTime) or 0.1, 0.05)
    if not Library.Flags[flag] then
        return
    end

    local last = 0
    local running = false
    local slowWarnAt = 0
    local conn = RunService.Heartbeat:Connect(function()
        if not Library.Flags[flag] then
            Library:CleanupConnectionsByTag(tag)
            return
        end

        local current = os.clock()
        if running or current - last < delayTime then
            return
        end

        last = current
        running = true

        local spawnFn = task and task.spawn or spawn
        spawnFn(function()
            local startedAt = os.clock()
            local ok, err = pcall(callback)
            local elapsed = os.clock() - startedAt

            if not ok then
                warn("[interval:" .. tostring(tag) .. "]", err)
            elseif elapsed > 10 and os.clock() - slowWarnAt > 5 then
                slowWarnAt = os.clock()
                warn(string.format("[Versus] slow interval %s took %.3fs", tostring(tag), elapsed))
            end

            local waitFn = task and task.wait or wait
            waitFn()
            running = false
        end)
    end)

    Library:TrackConnection(conn, tag)
end

local function notify(title, desc, style)
    Library:createDisplayMessage(title, desc, {
        { text = "OK" },
    }, style or "info")
end

-----------------------------------------------------------------

local SharedModules = ReplicatedStorage:WaitForChild("SharedModules")
local SharedData = ReplicatedStorage:WaitForChild("SharedData")

local function safeRequire(inst)
    if not inst then
        return nil
    end
    local ok, result = pcall(require, inst)
    if ok then
        return result
    end
    return nil
end

local ok, NetMod = pcall(function() return SharedModules.Networking end)
local Net = safeRequire(ok and NetMod or nil)
local ok, SeedMod = pcall(function() return SharedModules.SeedData end)
local SeedData = safeRequire(ok and SeedMod or nil)
local ok, GearMod = pcall(function() return SharedModules.GearShopData end)
local GearShopData = safeRequire(ok and GearMod or nil)
local ok, SprinklerMod = pcall(function() return SharedModules.SprinklerData end)
local SprinklerData = safeRequire(ok and SprinklerMod or nil)
local ok, WateringMod = pcall(function() return SharedModules.WateringcanData end)
local WateringcanData = safeRequire(ok and WateringMod or nil)
local ok, CrateMod = pcall(function() return SharedModules.CrateData end)
local CrateData = safeRequire(ok and CrateMod or nil)
local ok, SeedPackMod = pcall(function() return SharedModules.SeedPackData end)
local SeedPackData = safeRequire(ok and SeedPackMod or nil)
local ok, EggMod = pcall(function() return SharedModules.EggData end)
local EggData = safeRequire(ok and EggMod or nil)
local ok, PetMod = pcall(function() return SharedData.PetData end)
local PetData = safeRequire(ok and PetMod or nil)
local ok, PetSizesMod = pcall(function() return SharedData.PetSizes end)
local PetSizes = safeRequire(ok and PetSizesMod or nil)

local GardenSync = nil
do
    local ok, controllers = pcall(function()
        return client:WaitForChild("PlayerScripts", 10):WaitForChild("Controllers", 10)
    end)
    if ok and controllers then
        local okGS, gsMod = pcall(function() return controllers.GardenSyncController end)
        GardenSync = safeRequire(okGS and gsMod or nil)
    end
end

local State = {
    StatusLabel = nil,
    SavedPosition = nil,
    IsStealingActive = false,
    WeatherActive = false,
}

local SKILL_NAMES = { "BaseSpeed", "BaseJump", "ShovelPower", "MaxBackpack" }

-----------------------------------------------------------------

local function withAll(list)
    local out = { "All" }
    for _, v in ipairs(list) do
        out[#out + 1] = v
    end
    return out
end

local function dedupe(list)
    local seen = {}
    local out = {}
    for _, v in ipairs(list) do
        if v and not seen[v] then
            seen[v] = true
            out[#out + 1] = v
        end
    end
    return out
end

local function seedNames()
    local out = {}
    if SeedData then
        for _, s in ipairs(SeedData) do
            if s.SeedName then
                out[#out + 1] = s.SeedName
            end
        end
    end
    return dedupe(out)
end

local function gearNames()
    local out = {}
    if GearShopData and GearShopData.Data then
        for _, g in ipairs(GearShopData.Data) do
            if g.ItemName then
                out[#out + 1] = g.ItemName
            end
        end
    end
    return dedupe(out)
end

local function sprinklerNames()
    local out = {}
    if SprinklerData then
        for _, s in ipairs(SprinklerData) do
            if s.SprinklerName then
                out[#out + 1] = s.SprinklerName
            end
        end
    end
    return out
end

local function wateringcanNames()
    local out = {}
    if WateringcanData then
        for _, w in ipairs(WateringcanData) do
            if w.Name then
                out[#out + 1] = w.Name
            end
        end
    end
    return out
end

local function crateNames()
    local out = {}
    if CrateData and type(CrateData.GetAllCrates) == "function" then
        local ok, all = pcall(CrateData.GetAllCrates)
        if ok and type(all) == "table" then
            for _, c in ipairs(all) do
                if type(c) == "table" and c.Name then
                    out[#out + 1] = c.Name
                end
            end
        end
    end
    return out
end

local function seedPackNames()
    local out = {}
    if SeedPackData and SeedPackData.Data then
        for _, p in ipairs(SeedPackData.Data) do
            if p.PackName then
                out[#out + 1] = p.PackName
            end
        end
    end
    return out
end

local function eggNames()
    local out = {}
    if EggData and EggData.Data then
        for _, e in ipairs(EggData.Data) do
            if e.EggName then
                out[#out + 1] = e.EggName
            end
        end
    end
    return out
end

local function mutationNames()
    local out = {}
    local ok, mod = pcall(function() return SharedModules.MutationData end)
    if not ok then mod = nil end
    if mod then
        for _, c in ipairs(mod:GetChildren()) do
            out[#out + 1] = c.Name
        end
    end
    return out
end

local function petSpecies()
    local out = {}
    if PetData then
        for name, data in pairs(PetData) do
            if type(data) == "table" and data.Rarity then
                out[#out + 1] = name
            end
        end
    end
    return out
end

local function petRarities()
    local set = {}
    if PetData then
        for _, data in pairs(PetData) do
            if type(data) == "table" and data.Rarity then
                set[data.Rarity] = true
            end
        end
    end
    local out = {}
    for r in pairs(set) do
        out[#out + 1] = r
    end
    return out
end

local function petSizeNames()
    local out = {}
    if PetSizes and type(PetSizes.Scales) == "table" then
        for size in pairs(PetSizes.Scales) do
            out[#out + 1] = size
        end
    end
    out[#out + 1] = "Normal"
    return out
end

-----------------------------------------------------------------

local function dropdownValue(flag)
    local v = Library.Flags[flag]
    if type(v) == "table" then
        return v[1]
    end
    return v
end

local function matchesSelection(flag, value)
    local v = Library.Flags[flag]
    if type(v) ~= "table" then
        return v == nil or v == "All" or v == value
    end
    if #v == 0 then
        return true
    end
    for _, x in ipairs(v) do
        if x == "All" or x == value then
            return true
        end
    end
    return false
end

local function firePacket(packet, ...)
    if not packet then
        return false
    end
    local args = { ... }
    local ok, result = pcall(function()
        return packet:Fire(table.unpack(args))
    end)
    if not ok then
        return false, result
    end
    return true, result
end

local function getRoot()
    local char = client.Character
    if not char then
        return nil
    end
    return char:FindFirstChild("HumanoidRootPart")
end

local function getHumanoid()
    local char = client.Character
    if not char then
        return nil
    end
    return char:FindFirstChildOfClass("Humanoid")
end

local function getTools()
    local out = {}
    local char = client.Character
    if char then
        for _, t in ipairs(char:GetChildren()) do
            if t:IsA("Tool") then
                out[#out + 1] = t
            end
        end
    end
    local backpack = client:FindFirstChildOfClass("Backpack")
    if backpack then
        for _, t in ipairs(backpack:GetChildren()) do
            if t:IsA("Tool") then
                out[#out + 1] = t
            end
        end
    end
    return out
end

local function getFruitTools()
    local out = {}
    for _, t in ipairs(getTools()) do
        if t:GetAttribute("HarvestedFruit") == true and t:GetAttribute("Id") then
            out[#out + 1] = t
        end
    end
    return out
end

local function getPetTools()
    local out = {}
    for _, t in ipairs(getTools()) do
        local pid = t:GetAttribute("PetId")
        if type(pid) == "string" and pid ~= "" then
            out[#out + 1] = t
        end
    end
    return out
end

local function getPlot()
    local plotId = client:GetAttribute("PlotId")
    if not plotId then
        return nil
    end
    local ok, plot = pcall(function()
        return Workspace.Gardens["Plot" .. tostring(plotId)]
    end)
    if ok then
        return plot
    end
    return nil
end

-----------------------------------------------------------------

local function fruitPassesFilter(tool, cropFlag, mutFlag, onlyMutatedFlag, minWeightFlag, maxWeightFlag, protectFav)
    if protectFav and tool:GetAttribute("IsFavorite") == true then
        return false
    end

    local fruitName = tool:GetAttribute("FruitName")
    if cropFlag and not matchesSelection(cropFlag, fruitName) then
        return false
    end

    local mutation = tool:GetAttribute("Mutation")
    local hasMutation = mutation ~= nil and mutation ~= ""

    if onlyMutatedFlag and Library.Flags[onlyMutatedFlag] and not hasMutation then
        return false
    end

    if mutFlag then
        local v = Library.Flags[mutFlag]
        local allMut = type(v) ~= "table" or #v == 0
        if not allMut then
            local ok = false
            for _, x in ipairs(v) do
                if x == "All" or (hasMutation and x == mutation) then
                    ok = true
                    break
                end
            end
            if not ok then
                return false
            end
        end
    end

    local weight = tonumber(tool:GetAttribute("SizeMultiplier")) or 0
    if minWeightFlag then
        local minW = tonumber(Library.Flags[minWeightFlag]) or 0
        if minW > 0 and weight < minW then
            return false
        end
    end
    if maxWeightFlag then
        local maxW = tonumber(Library.Flags[maxWeightFlag]) or 0
        if maxW > 0 and weight > maxW then
            return false
        end
    end

    return true
end

-----------------------------------------------------------------

local pendingPlants = {}
local function autoPlant()
    if not Net then
        return
    end
    local plot = getPlot()
    local humanoid = getHumanoid()
    if not plot or not humanoid then
        return
    end

    local seedTool
    for _, t in ipairs(getTools()) do
        local sname = t:GetAttribute("SeedTool")
        if sname and matchesSelection("PlantSeeds", sname) then
            seedTool = t
            break
        end
    end
    if not seedTool then
        return
    end

    local seedName = seedTool:GetAttribute("SeedTool")
    pcall(function()
        humanoid:EquipTool(seedTool)
    end)

    local spacing = math.clamp(tonumber(Library.Flags["PlantSpacing"]) or 4, 2, 10)
    local planted = 0
    for _, area in ipairs(CollectionService:GetTagged("PlantArea")) do
        if area:IsA("BasePart") and area:IsDescendantOf(plot) then
            local size = area.Size
            local cframe = area.CFrame
            local startX = -size.X / 2 + spacing / 2
            local startZ = -size.Z / 2 + spacing / 2
            for x = startX, size.X / 2, spacing do
                for z = startZ, size.Z / 2, spacing do
                    local pos = (cframe * CFrame.new(x, size.Y / 2, z)).Position
                    local posKey = math.floor(pos.X) .. "_" .. math.floor(pos.Z)
                    if not pendingPlants[posKey] or os.clock() - pendingPlants[posKey] > 5 then
                        pendingPlants[posKey] = os.clock()
                        firePacket(Net.Plant.PlantSeed, pos, seedName, seedTool)
                        planted = planted + 1
                    end
                end
            end
        end
    end
end

local pendingHarvests = {}
local function autoHarvest()
    if not Net or not GardenSync then
        return
    end
    if Library.Flags["PauseHarvestWeather"] and State.WeatherActive then
        return
    end
    local ok, garden = pcall(function()
        return GardenSync:GetGarden(client.UserId)
    end)
    if not ok or type(garden) ~= "table" then
        return
    end

    local onlyMutated = Library.Flags["HarvestOnlyMutated"] == true
    local onlyNonMutated = Library.Flags["HarvestOnlyNonMutated"] == true
    local blacklist = Library.Flags["HarvestBlacklist"] == true
    local minSize = tonumber(Library.Flags["HarvestMinSize"]) or 0
    local maxSize = tonumber(Library.Flags["HarvestMaxSize"]) or 0
    local count = 0
    for plantId, plant in pairs(garden) do
        if type(plant) == "table" and plant.Fruits then
            for fruitId, fruit in pairs(plant.Fruits) do
                local pass = true
                local cacheKey = tostring(plantId) .. "_" .. tostring(fruitId)
                if pendingHarvests[cacheKey] and os.clock() - pendingHarvests[cacheKey] < 5 then
                    pass = false
                end
                if pass then
                    local mutation = fruit.Mutation
                    local hasMutation = mutation ~= nil and mutation ~= ""
                    local weight = tonumber(fruit.Weight or fruit.SizeMultiplier) or 0
                    local cropName = fruit.FruitName or fruit.Name
                    if blacklist then
                        pass = not matchesSelection("HarvestCrops", cropName)
                    else
                        pass = matchesSelection("HarvestCrops", cropName)
                    end
                    if onlyMutated and not hasMutation then
                        pass = false
                    end
                    if onlyNonMutated and hasMutation then
                        pass = false
                    end
                    if minSize > 0 and weight < minSize then
                        pass = false
                    end
                    if maxSize > 0 and weight > maxSize then
                        pass = false
                    end
                end
                if pass then
                    local cacheKey = tostring(plantId) .. "_" .. tostring(fruitId)
                    pendingHarvests[cacheKey] = os.clock()
                    firePacket(Net.Garden.CollectFruit, plantId, fruitId)
                    count = count + 1
                    if count % 2 == 0 then task.wait() end
                end
            end
        end
    end
end

local function autoCollectDrops()
    local root = getRoot()
    if not root then
        return
    end
    local ok, folder = pcall(function() return Workspace.DroppedItems end)
    if not ok then folder = nil end
    if not folder then
        return
    end
    local origin = root.CFrame
    local moved = false
    for _, drop in ipairs(folder:GetChildren()) do
        local ok, visual = pcall(function() return drop.Visual end)
        if not ok then visual = nil end
        local part = visual and (visual:IsA("BasePart") and visual or (pcall(function() return visual:FindFirstChildWhichIsA("BasePart") end) and visual:FindFirstChildWhichIsA("BasePart") or nil))
        if part then
            root.CFrame = CFrame.new(part.Position)
            moved = true
            task.wait(0.12)
        end
    end
    if moved then
        root.CFrame = origin
    end
end

local pendingSells = {}
local function autoSell()
    if not Net then
        return
    end
    local mode = dropdownValue("SellMode") or "Filtered"
    if mode == "All" then
        if not pendingSells["ALL"] or os.clock() - pendingSells["ALL"] > 5 then
            pendingSells["ALL"] = os.clock()
            firePacket(Net.NPCS.SellAll)
        end
        return
    end

    local protect = Library.Flags["SellProtectFavorite"] == true
    local sold = 0
    for _, tool in ipairs(getFruitTools()) do
        local tId = tool:GetAttribute("Id")
        if tId and (not pendingSells[tId] or os.clock() - pendingSells[tId] > 5) then
            if fruitPassesFilter(tool, "SellCrops", "SellMutations", "SellOnlyMutated", "SellMinWeight", "SellMaxWeight", protect) then
                pendingSells[tId] = os.clock()
                firePacket(Net.NPCS.SellFruit, tId)
                sold = sold + 1
            end
        end
    end
end

local pendingFavs = {}
local function autoFavorite()
    if not Net then
        return
    end
    local count = 0
    for _, tool in ipairs(getFruitTools()) do
        local tId = tool:GetAttribute("Id")
        if tId and (not pendingFavs[tId] or os.clock() - pendingFavs[tId] > 5) then
            if tool:GetAttribute("IsFavorite") ~= true then
                if fruitPassesFilter(tool, "FavoriteCrops", "FavoriteMutations", "FavoriteOnlyMutated", "FavoriteMinWeight", "FavoriteMaxWeight", false) then
                    pendingFavs[tId] = os.clock()
                    firePacket(Net.Backpack.SetFruitFavorite, tId, true)
                    count = count + 1
                end
            end
        end
    end
end

local function autoShovel()
    if not Net or not GardenSync then
        return
    end
    local shovel
    for _, t in ipairs(getTools()) do
        if t:GetAttribute("Shovel") then
            shovel = t
            break
        end
    end
    if not shovel then
        return
    end
    local humanoid = getHumanoid()
    if humanoid then
        pcall(function()
            humanoid:EquipTool(shovel)
        end)
    end

    local shovelType = shovel:GetAttribute("Shovel")
    local onlyMutated = Library.Flags["ShovelOnlyMutated"] == true
    local ok, garden = pcall(function()
        return GardenSync:GetGarden(client.UserId)
    end)
    if not ok or type(garden) ~= "table" then
        return
    end

    local count = 0
    for plantId, plant in pairs(garden) do
        if type(plant) == "table" then
            local pass = matchesSelection("ShovelCrops", plant.PlantName or plant.Name or plant.SeedName)
            if onlyMutated and (plant.Mutation == nil or plant.Mutation == "") then
                pass = false
            end
            if pass then
                firePacket(Net.Shovel.UseShovel, plantId, "", shovelType, shovel)
                count = count + 1
                task.wait(0.7)
                if count >= 20 then
                    return
                end
            end
        end
    end
end

local function autoPlaceSprinklers()
    if not Net then
        return
    end
    local plot = getPlot()
    if not plot then
        return
    end
    local selected = dropdownValue("SprinklerType")
    for _, t in ipairs(getTools()) do
        local sname = t:GetAttribute("Sprinkler")
        if sname and (not selected or selected == "All" or selected == sname) then
            local humanoid = getHumanoid()
            if humanoid then
                pcall(function()
                    humanoid:EquipTool(t)
                end)
            end
            local root = getRoot()
            if root then
                firePacket(Net.Place.PlaceSprinkler, root.Position, sname, t, 0)
            end
            return
        end
    end
end

local function autoWater()
    if not Net or not GardenSync then
        return
    end
    local can
    for _, t in ipairs(getTools()) do
        if t:GetAttribute("WateringCan") then
            can = t
            break
        end
    end
    if not can then
        return
    end
    local humanoid = getHumanoid()
    if humanoid then
        pcall(function()
            humanoid:EquipTool(can)
        end)
    end
    local canName = can:GetAttribute("WateringCan")
    local ok, garden = pcall(function()
        return GardenSync:GetGarden(client.UserId)
    end)
    if not ok or type(garden) ~= "table" then
        return
    end
    local count = 0
    for _, plant in pairs(garden) do
        if type(plant) == "table" and plant.Positions then
            local pos = Vector3.new(plant.Positions.PosX, plant.Positions.PosY, plant.Positions.PosZ)
            firePacket(Net.WateringCan.UseWateringCan, pos, canName, can)
            count = count + 1
            if count % 6 == 0 then
                task.wait()
            end
            if count >= 40 then
                return
            end
        end
    end
end

local function autoBuySeeds()
    if not Net then
        return
    end
    for _, name in ipairs(seedNames()) do
        if matchesSelection("BuySeeds", name) then
            firePacket(Net.SeedShop.PurchaseSeed, name)
        end
    end
end

local function autoBuyGear()
    if not Net then
        return
    end
    for _, name in ipairs(gearNames()) do
        if matchesSelection("BuyGear", name) then
            firePacket(Net.GearShop.PurchaseGear, name)
        end
    end
end

local function autoSpendSkill()
    if not Net then
        return
    end
    local skill = dropdownValue("SkillName") or "BaseSpeed"
    firePacket(Net.SkillPoints.SpendSkillPoint, skill)
end

local function autoOpenCrates()
    if not Net then
        return
    end
    for _, t in ipairs(getTools()) do
        local crate = t:GetAttribute("Crate")
        if crate and matchesSelection("CrateType", crate) then
            firePacket(Net.Crate.OpenCrate, crate)
            task.wait(0.2)
        end
    end
end

local function autoOpenSeedPacks()
    if not Net then
        return
    end
    for _, t in ipairs(getTools()) do
        local pack = t:GetAttribute("SeedPack")
        if pack and matchesSelection("SeedPackType", pack) then
            firePacket(Net.SeedPack.OpenSeedPack, pack)
            task.wait(0.2)
        end
    end
end

local function autoOpenEggs()
    if not Net then
        return
    end
    for _, t in ipairs(getTools()) do
        local egg = t:GetAttribute("Egg")
        if egg and matchesSelection("EggType", egg) then
            firePacket(Net.Egg.OpenEgg, egg)
            task.wait(0.2)
        end
    end
end

local function autoEquipPets()
    if not Net then
        return
    end
    for _, t in ipairs(getPetTools()) do
        local petType = t:GetAttribute("PetType") or t:GetAttribute("PetName")
        if not petType or matchesSelection("EquipPets", petType) then
            firePacket(Net.Pets.RequestEquipByName, petType or t:GetAttribute("PetId"))
            task.wait(0.15)
        end
    end
end

local function autoSellPets()
    if not Net then
        return
    end
    for _, t in ipairs(getPetTools()) do
        local rarity = t:GetAttribute("Rarity")
        local size = t:GetAttribute("Size") or t:GetAttribute("PetSize")
        local keepRarity = matchesSelection("KeepRarities", rarity)
        local keepSize = matchesSelection("KeepSizes", size)
        if not keepRarity and not keepSize then
            firePacket(Net.NPCS.SellPet, t:GetAttribute("PetId"))
            task.wait(0.15)
        end
    end
end

local function autoCollectSheckles()
    if not Net then
        return
    end
    firePacket(Net.ShecklePop.SheckleCollect)
end

local function autoDailyDeal()
    if not Net then
        return
    end
    firePacket(Net.NPCS.UseDailyDealAll)
end

local function autoClaimMail()
    if not Net then
        return
    end
    local ok, list = firePacket(Net.Mailbox.List)
    if ok and type(list) == "table" then
        for _, mail in pairs(list) do
            local id = type(mail) == "table" and (mail.Id or mail.MailId)
            if id then
                firePacket(Net.Mailbox.Claim, id)
                task.wait(0.1)
            end
        end
    end
end

local function serverHop()
    pcall(function()
        TeleportService:Teleport(game.PlaceId, client)
    end)
end

local function autoUnfavorite()
    if not Net then return end
    local count = 0
    for _, tool in ipairs(getFruitTools()) do
        if tool:GetAttribute("IsFavorite") == true then
            if fruitPassesFilter(tool, "UnfavoriteCrops", "UnfavoriteMutations", nil, nil, nil, false) then
                firePacket(Net.Backpack.SetFruitFavorite, tool:GetAttribute("Id"), false)
                count = count + 1
                if count % 8 == 0 then task.wait() end
            end
        end
    end
end

local function unfavoriteAll()
    if not Net then return end
    local count = 0
    for _, tool in ipairs(getFruitTools()) do
        if tool:GetAttribute("IsFavorite") == true then
            firePacket(Net.Backpack.SetFruitFavorite, tool:GetAttribute("Id"), false)
            count = count + 1
            if count % 8 == 0 then task.wait() end
        end
    end
end

local function autoBargain()
    if not Net then return end
    firePacket(Net.NPCS.AskBidAll)
end

local function skipCutscene()
    local gui = client.PlayerGui
    if gui then
        for _, name in ipairs({ "LoadingGui", "CinematicBars", "GearCinematicBars" }) do
            local ok, g = pcall(function() return gui[name] end)
            if ok and g then g.Enabled = false end
        end
    end
    if Net then
        pcall(function() firePacket(Net.Tutorial.Ready) end)
        pcall(function() firePacket(Net.Tutorial.Complete) end)
    end
end

local function withReturn(fn)
    return function()
        fn()
        if Library.Flags["ReturnAfterAction"] and State.SavedPosition then
            local root = getRoot()
            if root then root.CFrame = State.SavedPosition end
        end
    end
end

local function autoSteal()
    if not Net or not GardenSync then return end
    if State.IsStealingActive then return end

    local onlyMutated = Library.Flags["StealOnlyMutated"] == true
    local minValue = tonumber(Library.Flags["StealMinValue"]) or 0
    local mode = dropdownValue("StealMode") or "Highest"

    local best = nil
    local bestValue = -1

    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= client then
            local ok, garden = pcall(function()
                return GardenSync:GetGarden(plr.UserId)
            end)
            if ok and type(garden) == "table" then
                for plantId, plant in pairs(garden) do
                    if type(plant) == "table" and plant.Fruits then
                        for fruitId, fruit in pairs(plant.Fruits) do
                            local hasMutation = fruit.Mutation ~= nil and fruit.Mutation ~= ""
                            local default = tonumber(fruit.Value or fruit.SellValue or 0) or 0
                            local pass = true
                            if onlyMutated and not hasMutation then pass = false end
                            if value < minValue then pass = false end
                            if pass then
                                if mode == "Highest" and value > bestValue then
                                    bestValue = value
                                    best = { userId = plr.UserId, plantId = plantId, fruitId = fruitId }
                                elseif mode ~= "Highest" and not best then
                                    best = { userId = plr.UserId, plantId = plantId, fruitId = fruitId }
                                end
                            end
                        end
                    end
                end
            end
        end
    end

    if not best then return end

    State.IsStealingActive = true
    firePacket(Net.Steal.BeginSteal, best.userId, best.plantId, best.fruitId)
    local dur = math.max(tonumber(Library.Flags["StealDuration"]) or 3, 1)
    task.delay(dur, function()
        if Library.Flags["AutoSteal"] then
            firePacket(Net.Steal.CompleteSteal)
        else
            firePacket(Net.Steal.CancelSteal)
        end
        State.IsStealingActive = false
    end)
end

local function autoUseBuff()
    if not Net then return end
    local selected = dropdownValue("BuffGear")
    if not selected or selected == "All" then
        for _, name in ipairs(gearNames()) do
            firePacket(Net.GearShop.EquipGear, name)
            task.wait(0.1)
        end
    else
        firePacket(Net.GearShop.EquipGear, selected)
    end
end

local function setupInstantPrompts()
    Library:CleanupConnectionsByTag("InstantPrompts")
    local function apply(inst)
        if inst:IsA("ProximityPrompt") then
            pcall(function()
                inst.MaxActivationDistance = 999
                inst.HoldDuration = 0
            end)
        end
    end
    pcall(function()
        for _, desc in ipairs(CollectionService:GetTagged("ProximityPrompt") or {}) do
            apply(desc)
        end
    end)
    local conn = CollectionService:GetInstanceAddedSignal("ProximityPrompt"):Connect(function(inst)
        if not Library.Flags["InstantPrompts"] then return end
        apply(inst)
    end)
    Library:TrackConnection(conn, "InstantPrompts")
end

local function autoTameWildPet()
    if not Net then return end
    local ok, spawns = pcall(function()
        return Workspace.Map.WildPetSpawns
    end)
    if not ok or not spawns then return end
    for _, model in ipairs(spawns:GetChildren()) do
        local petName = model:GetAttribute("PetName")
        if petName then
            local info = PetData and PetData[petName]
            local rarity = info and info.Rarity
            if matchesSelection("TameRarities", rarity) then
                firePacket(Net.Pets.WildPetTame, model)
                task.wait(1)
            end
        end
    end
end

local function autoCollectEventSeeds()
    local root = getRoot()
    if not root then return end
    local ok, folder = pcall(function() return Workspace.DroppedItems end)
    if not ok then folder = nil end
    if not folder then return end
    local origin = root.CFrame
    local moved = false
    for _, drop in ipairs(folder:GetChildren()) do
        local itemType = tostring(drop:GetAttribute("ItemType") or drop:GetAttribute("Type") or "")
        local isEventSeed = string.find(itemType:lower(), "seed") ~= nil or drop:GetAttribute("EventSeed") ~= nil
        local passFilter = Library.Flags["EventSeedFilterAll"] or isEventSeed
        if passFilter then
            local ok, visual = pcall(function() return drop.Visual end)
        if not ok then visual = nil end
            local part = visual and (visual:IsA("BasePart") and visual or (pcall(function() return visual:FindFirstChildWhichIsA("BasePart") end) and visual:FindFirstChildWhichIsA("BasePart") or nil))
            if not part then
                part = drop:IsA("BasePart") and drop or drop:FindFirstChildWhichIsA("BasePart")
            end
            if part then
                root.CFrame = CFrame.new(part.Position + Vector3.new(0, 3, 0))
                moved = true
                task.wait(0.12)
            end
        end
    end
    if moved then
        root.CFrame = origin
    end
end

local function serverHopUntilNight()
    local nightVal = ReplicatedStorage:FindFirstChild("Night")
    if nightVal and nightVal.Value then
        Library.Flags["HopUntilNight"] = false
        Library:CleanupConnectionsByTag("HopUntilNight")
        notify("Server Hop", "Malam ditemukan! Berhenti hop.", "info")
        return
    end
    serverHop()
end

local ESPObjects = {}

local function clearESP(tag)
    local bucket = ESPObjects[tag]
    if not bucket then return end
    for _, obj in ipairs(bucket) do
        pcall(function() obj:Destroy() end)
    end
    ESPObjects[tag] = {}
end

local function addHighlight(parent, fillColor, outlineColor, tag)
    local h = Instance.new("Highlight")
    h.FillColor = fillColor
    h.OutlineColor = outlineColor
    h.FillTransparency = 0.5
    h.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    h.Parent = parent
    ESPObjects[tag] = ESPObjects[tag] or {}
    table.insert(ESPObjects[tag], h)
end

local function addBillboard(parent, text, tag)
    local bb = Instance.new("BillboardGui")
    bb.Size = UDim2.new(0, 140, 0, 40)
    bb.StudsOffset = Vector3.new(0, 4, 0)
    bb.AlwaysOnTop = true
    bb.ResetOnSpawn = false
    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1, 0, 1, 0)
    lbl.BackgroundTransparency = 1
    lbl.TextColor3 = Color3.fromRGB(255, 255, 255)
    lbl.TextStrokeTransparency = 0
    lbl.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
    lbl.Text = text
    lbl.TextScaled = true
    lbl.Font = Enum.Font.GothamBold
    lbl.Parent = bb
    bb.Parent = parent
    ESPObjects[tag] = ESPObjects[tag] or {}
    table.insert(ESPObjects[tag], bb)
end

local function getWildPetSpawns()
    local ok, folder = pcall(function()
        return Workspace.Map.WildPetSpawns
    end)
    if ok then
        return folder
    end
    return nil
end

local function getGardens()
    local ok, folder = pcall(function()
        return Workspace.Gardens
    end)
    if ok then
        return folder
    end
    return nil
end

local function getBirds()
    local ok, folder = pcall(function()
        return Workspace.Birds
    end)
    if ok then
        return folder
    end
    return nil
end

local function wildPetRarity(petName)
    local info = PetData and PetData[petName]
    if info then
        return info.Rarity
    end
    return nil
end

local function updateWildPetESP()
    clearESP("WildPetESP")
    if not Library.Flags["ESPWildPets"] then return end
    local spawns = getWildPetSpawns()
    if not spawns then return end
    for _, model in ipairs(spawns:GetChildren()) do
        local petName = model:GetAttribute("PetName")
        if petName then
            local rarity = wildPetRarity(petName) or "?"
            if matchesSelection("ESPPetRarities", rarity) then
                addHighlight(model, Color3.fromRGB(0, 255, 100), Color3.fromRGB(255, 255, 255), "WildPetESP")
                addBillboard(model, string.format("[%s] %s", rarity, petName), "WildPetESP")
            end
        end
    end
end

local function updateFruitESP()
    clearESP("FruitESP")
    if not Library.Flags["ESPFruit"] then return end
    local gardens = getGardens()
    if not gardens then return end
    for _, plot in ipairs(gardens:GetChildren()) do
        local ok, plants = pcall(function() return plot.Plants end)
        if not ok then plants = nil end
        if plants then
            for _, plant in ipairs(plants:GetChildren()) do
                local ok, fruits = pcall(function() return plant.Fruits end)
                if not ok then fruits = nil end
                if fruits then
                    for _, fruit in ipairs(fruits:GetChildren()) do
                        local mutation = fruit:GetAttribute("Mutation")
                        local hasMut = mutation ~= nil and mutation ~= ""
                        local fillColor = hasMut and Color3.fromRGB(255, 80, 200) or Color3.fromRGB(255, 165, 0)
                        addHighlight(fruit, fillColor, Color3.fromRGB(255, 255, 0), "FruitESP")
                    end
                end
            end
        end
    end
end

local function updateShovelESP()
    clearESP("ShovelESP")
    if not Library.Flags["ESPShovelTarget"] then return end
    local gardens = getGardens()
    if not gardens then return end
    for _, plot in ipairs(gardens:GetChildren()) do
        local ok, plants = pcall(function() return plot.Plants end)
        if not ok then plants = nil end
        if plants then
            for _, plant in ipairs(plants:GetChildren()) do
                local seedName = plant:GetAttribute("SeedName")
                if seedName and matchesSelection("ShovelCrops", seedName) then
                    addHighlight(plant, Color3.fromRGB(255, 50, 50), Color3.fromRGB(255, 165, 0), "ShovelESP")
                end
            end
        end
    end
end

local function serverHopUntilWildPet()
    if not Library.Flags["HopUntilWildPet"] then return end
    local spawns = getWildPetSpawns()
    if spawns then
        for _, model in ipairs(spawns:GetChildren()) do
            local petName = model:GetAttribute("PetName")
            if petName then
                local rarity = wildPetRarity(petName)
                if matchesSelection("HopPetTarget", petName) and matchesSelection("HopPetRarity", rarity) then
                    Library.Flags["HopUntilWildPet"] = false
                    Library:CleanupConnectionsByTag("HopUntilWildPet")
                    notify("Wild Pet", "Pet ditemukan: " .. petName, "info")
                    return
                end
            end
        end
    end
    serverHop()
end

local function sendPetWebhook(petName, rarity, size)
    if not request then return end
    local url = Library.Flags["WebhookURL"]
    if not url or url == "" then return end
    local body = HttpService:JSONEncode({
        content = string.format("Pet terbeli! | Nama: %s | Rarity: %s | Size: %s",
            tostring(petName), tostring(rarity or "?"), tostring(size or "?")),
    })
    pcall(function()
        request({
            Url = url,
            Method = "POST",
            Headers = { ["Content-Type"] = "application/json" },
            Body = body,
        })
    end)
end

local function autoSendMailbox()
    if not Net then return end
    local targetName = Library.Flags["MailboxTarget"]
    if not targetName or targetName == "" then
        notify("Mailbox", "Isi Target Player Name dahulu.", "warn")
        return
    end
    local ok, userId = firePacket(Net.Mailbox.LookupPlayer, targetName)
    if not ok or not userId then
        notify("Mailbox", "Player tidak ditemukan.", "warn")
        return
    end
    for _, tool in ipairs(getFruitTools()) do
        if fruitPassesFilter(tool, "MailboxCrops", nil, nil, nil, nil, false) then
            local id = tool:GetAttribute("Id")
            if id then
                firePacket(Net.Mailbox.Send, userId, tostring(id), "fruit")
                task.wait(0.3)
            end
        end
    end
end

local function autoDefense()
    if not Net then return end
    local plot = getPlot()
    local root = getRoot()
    if not plot or not root then return end
    local ok, spawnPoint = pcall(function() return plot.SpawnPoint end)
    local center = plot.PrimaryPart or (ok and spawnPoint or nil)
    if not center then return end
    local plotCenter = center.Position

    local nearestPlayer = nil
    local nearestDist = 30
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= client then
            local char = plr.Character
            local ok, hrp = pcall(function() return char.HumanoidRootPart end)
                if not ok then hrp = nil end
            if hrp then
                local dist = (hrp.Position - plotCenter).Magnitude
                if dist < nearestDist then
                    nearestDist = dist
                    nearestPlayer = plr
                end
            end
        end
    end

    if not nearestPlayer then return end

    local priority = dropdownValue("DefensePriority") or "Shovel"
    if priority == "FreezeRay" then
        local char = nearestPlayer.Character
        local ok, hrp = pcall(function() return char.HumanoidRootPart end)
                if not ok then hrp = nil end
        if hrp then
            for _, t in ipairs(getTools()) do
                if string.lower(t.Name):find("freeze") then
                    pcall(function() getHumanoid():EquipTool(t) end)
                    break
                end
            end
            firePacket(Net.FreezeRay.Fire, hrp.Position, hrp)
        end
    else
        for _, t in ipairs(getTools()) do
            if t:GetAttribute("Shovel") or string.lower(t.Name):find("shovel") then
                pcall(function() getHumanoid():EquipTool(t) end)
                break
            end
        end
        firePacket(Net.Shovel.HitPlayer, nearestPlayer.UserId)
    end
end

local function autoCollectRobin()
    local birds = getBirds()
    if not birds then return end
    local root = getRoot()
    if not root then return end
    local moved = false
    for _, bird in ipairs(birds:GetChildren()) do
        local isRobin = string.find(string.lower(bird.Name), "robin") ~= nil
        if Library.Flags["CollectAllBirds"] or isRobin then
            local part = (bird:IsA("BasePart") and bird) or (bird:IsA("Model") and bird.PrimaryPart)
            if part then
                root.CFrame = CFrame.new(part.Position + Vector3.new(0, 3, 0))
                moved = true
                task.wait(0.2)
            end
        end
    end
    if moved and State.SavedPosition then
        root.CFrame = State.SavedPosition
    end
end

-----------------------------------------------------------------

--[[
    Game script: Grow A Garden 2
    Ported to Kunsy Hub Premium Violet Layout
--]]

local Library = _G.HubLibrary
if not Library then return warn("[GrowAGarden2] Library not loaded.") end

local Setup = Library:Setup({
    Location = game:GetService("CoreGui"),
    Logo     = "rbxassetid://0",
    Title    = "Kunsy Hub Premium",
    Discord  = "discord.gg/chiyo",
    Version  = "v1.0",
    Game     = "Grow A Garden 2"
})

local GardenTab = Setup:CreateTab({ name = "Garden", columns = 1 })
local Garden = GardenTab:CreateSection("General")
local ShopTab = Setup:CreateTab({ name = "Shop", columns = 1 })
local Shop = ShopTab:CreateSection("General")
local CratesTab = Setup:CreateTab({ name = "Crates", columns = 1 })
local Crates = CratesTab:CreateSection("General")
local PetsTab = Setup:CreateTab({ name = "Pets", columns = 1 })
local Pets = PetsTab:CreateSection("General")
local PlayerTabTab = Setup:CreateTab({ name = "Player", columns = 1 })
local PlayerTab = PlayerTabTab:CreateSection("General")
local VisualsTab = Setup:CreateTab({ name = "Visuals", columns = 1 })
local Visuals = VisualsTab:CreateSection("General")

Garden = GardenTab:CreateSection("Grow a Garden 2")

State.StatusLabel = Garden:CreateLabel({
    name = "Plot: waiting...",
    TransparentBackground = true,
})

-- Planting
Garden = GardenTab:CreateSection("Planting")

Garden:CreateToggle({
    name = "Auto Plant",
    default = false,
    flag = "AutoPlant",
    callback = function()
        interval("AutoPlant", "AutoPlant", 0.1, withReturn(autoPlant))
    end,
})

Garden:CreateMultiDropdown({
    name = "Seeds to Plant",
    flag = "PlantSeeds",
    default = { "All" },
    options = withAll(seedNames()),
})

Garden:CreateSlider({
    name = "Plant Grid Spacing",
    flag = "PlantSpacing",
    default = 4,
    minValue = 2,
    maxValue = 10,
})

Garden:CreateButton({
    name = "Teleport to My Garden",
    callback = function()
        local plot = getPlot()
        local root = getRoot()
        if plot and root and plot.PrimaryPart then
            root.CFrame = plot.PrimaryPart.CFrame + Vector3.new(0, 5, 0)
        else
            notify("Garden", "Plot belum kebaca. Tunggu sebentar.", "warning")
        end
    end,
})

Garden:CreateButton({
    name = "Expand Garden Now",
    callback = function()
        if Net then
            firePacket(Net.Actions.ExpandGarden)
        end
    end,
})

Garden:CreateToggle({
    name = "Auto Expand Garden",
    default = false,
    flag = "AutoExpand",
    callback = function()
        interval("AutoExpand", "AutoExpand", 5, function()
            if Net then
                firePacket(Net.Actions.ExpandGarden)
            end
        end)
    end,
})

-- Growing
Garden = GardenTab:CreateSection("Growing")

Garden:CreateToggle({
    name = "Auto Place Sprinklers",
    default = false,
    flag = "AutoSprinkler",
    callback = function()
        interval("AutoSprinkler", "AutoSprinkler", 3, withReturn(autoPlaceSprinklers))
    end,
})

Garden:CreateMultiDropdown({
    name = "Sprinkler",
    flag = "SprinklerType",
    default = { "All" },
    multi = false,
    options = withAll(sprinklerNames()),
})

Garden:CreateToggle({
    name = "Auto Water Plants",
    default = false,
    flag = "AutoWater",
    callback = function()
        interval("AutoWater", "AutoWater", 3, withReturn(autoWater))
    end,
})

-- Harvesting
Garden = GardenTab:CreateSection("Harvesting")

Garden:CreateToggle({
    name = "Auto Harvest",
    default = false,
    flag = "AutoHarvest",
    callback = function()
        interval("AutoHarvest", "AutoHarvest", 0.1, autoHarvest)
    end,
})

Garden:CreateToggle({
    name = "Auto Collect Drops",
    default = false,
    flag = "AutoCollectDrops",
    Description = "Teleport singkat ke item di workspace.DroppedItems lalu balik.",
    callback = function()
        interval("AutoCollectDrops", "AutoCollectDrops", 1, autoCollectDrops)
    end,
})

Garden:CreateDropdown({
    name = "Harvest Crops",
    flag = "HarvestCrops",
    default = { "All" },
    options = withAll(seedNames()),
})

Garden:CreateToggle({
    name = "Harvest Only Mutated",
    default = false,
    flag = "HarvestOnlyMutated",
})

Garden:CreateTextbox({
    name = "Harvest Min Size",
    flag = "HarvestMinSize",
    default = "0",
})

Garden:CreateTextbox({
    name = "Harvest Max Size",
    flag = "HarvestMaxSize",
    default = "0",
})

Garden:CreateToggle({
    name = "Harvest Blacklist Mode",
    default = false,
    flag = "HarvestBlacklist",
    Description = "Harvest semua kecuali crop yang dipilih di Harvest Crops.",
})

Garden:CreateToggle({
    name = "Harvest Only Non-Mutated",
    default = false,
    flag = "HarvestOnlyNonMutated",
})

-- Shovel
Garden = GardenTab:CreateSection("Shovel")

Garden:CreateToggle({
    name = "Auto Shovel",
    default = false,
    flag = "AutoShovel",
    callback = function()
        interval("AutoShovel", "AutoShovel", 1, autoShovel)
    end,
})

Garden:CreateMultiDropdown({
    name = "Shovel Crops",
    flag = "ShovelCrops",
    default = { "All" },
    options = withAll(seedNames()),
})

Garden:CreateToggle({
    name = "Shovel Only Mutated",
    default = false,
    flag = "ShovelOnlyMutated",
})

-- Selling
Garden = GardenTab:CreateSection("Selling")

Garden:CreateToggle({
    name = "Auto Sell",
    default = false,
    flag = "AutoSell",
    callback = function()
        interval("AutoSell", "AutoSell", tonumber(Library.Flags["SellInterval"]) or 5, autoSell)
    end,
})

Garden:CreateMultiDropdown({
    name = "Sell Mode",
    flag = "SellMode",
    default = { "Filtered" },
    multi = false,
    options = { "Filtered", "All" },
})

Garden:CreateTextbox({
    name = "Sell Interval (s)",
    flag = "SellInterval",
    default = "5",
})

Garden:CreateDropdown({
    name = "Sell Crops",
    flag = "SellCrops",
    default = { "All" },
    options = withAll(seedNames()),
})

Garden:CreateMultiDropdown({
    name = "Sell Mutations",
    flag = "SellMutations",
    default = { "All" },
    options = withAll(mutationNames()),
})

Garden:CreateToggle({
    name = "Sell Only Mutated",
    default = false,
    flag = "SellOnlyMutated",
})

Garden:CreateToggle({
    name = "Protect Favorited",
    default = true,
    flag = "SellProtectFavorite",
})

Garden:CreateTextbox({
    name = "Sell Min Weight",
    flag = "SellMinWeight",
    default = "0",
})

Garden:CreateButton({
    name = "Sell Now",
    callback = function()
        task.spawn(autoSell)
    end,
})

Garden:CreateButton({
    name = "Sell Entire Inventory Now",
    callback = function()
        if Net then
            firePacket(Net.NPCS.SellAll)
        end
    end,
})

-- Favoriting
Garden = GardenTab:CreateSection("Favoriting")

Garden:CreateToggle({
    name = "Auto Favorite",
    default = false,
    flag = "AutoFavorite",
    callback = function()
        interval("AutoFavorite", "AutoFavorite", 3, autoFavorite)
    end,
})

Garden:CreateMultiDropdown({
    name = "Favorite Crops",
    flag = "FavoriteCrops",
    default = { "All" },
    options = withAll(seedNames()),
})

Garden:CreateMultiDropdown({
    name = "Favorite Mutations",
    flag = "FavoriteMutations",
    default = { "All" },
    options = withAll(mutationNames()),
})

-- Unfavoriting
Garden = GardenTab:CreateSection("Unfavoriting")

Garden:CreateToggle({
    name = "Auto Unfavorite",
    default = false,
    flag = "AutoUnfavorite",
    callback = function()
        interval("AutoUnfavorite", "AutoUnfavorite", 3, autoUnfavorite)
    end,
})

Garden:CreateMultiDropdown({
    name = "Unfavorite Crops",
    flag = "UnfavoriteCrops",
    default = { "All" },
    options = withAll(seedNames()),
})

Garden:CreateMultiDropdown({
    name = "Unfavorite Mutations",
    flag = "UnfavoriteMutations",
    default = { "All" },
    options = withAll(mutationNames()),
})

Garden:CreateButton({
    name = "Unfavorite All Now",
    callback = function()
        task.spawn(unfavoriteAll)
    end,
})

-- Event Seeds
Garden = GardenTab:CreateSection("Event Seeds")

Garden:CreateToggle({
    name = "Auto Collect Event Seeds",
    default = false,
    flag = "AutoEventSeeds",
    callback = function()
        interval("AutoEventSeeds", "AutoEventSeeds", 1, autoCollectEventSeeds)
    end,
})

Garden:CreateToggle({
    name = "Collect All Drops",
    default = false,
    flag = "EventSeedFilterAll",
    Description = "Jika aktif, ambil semua item di DroppedItems bukan hanya seed.",
})

Garden:CreateButton({
    name = "Collect Event Seeds Now",
    callback = function()
        task.spawn(autoCollectEventSeeds)
    end,
})

-- Stealing
Garden = GardenTab:CreateSection("Stealing")

Garden:CreateToggle({
    name = "Auto Steal",
    default = false,
    flag = "AutoSteal",
    callback = function()
        interval("AutoSteal", "AutoSteal", 5, autoSteal)
    end,
})

Garden:CreateMultiDropdown({
    name = "Steal Mode",
    flag = "StealMode",
    default = { "Highest" },
    multi = false,
    options = { "Highest", "First" },
})

Garden:CreateToggle({
    name = "Steal Only Mutated",
    default = false,
    flag = "StealOnlyMutated",
})

Garden:CreateTextbox({
    name = "Steal Min Value",
    flag = "StealMinValue",
    default = "0",
})

Garden:CreateTextbox({
    name = "Steal Duration (s)",
    flag = "StealDuration",
    default = "3",
})

Garden:CreateButton({
    name = "Cancel Steal",
    callback = function()
        if Net then
            firePacket(Net.Steal.CancelSteal)
            State.IsStealingActive = false
        end
    end,
})

Garden = GardenTab:CreateSection("Defense")

Garden:CreateToggle({
    name = "Auto Defense",
    default = false,
    flag = "AutoDefense",
    Description = "Auto serang player yang mendekati kebun kamu saat steal aktif.",
    callback = function()
        interval("AutoDefense", "AutoDefense", 1, autoDefense)
    end,
})

Garden:CreateDropdown({
    name = "Defense Priority",
    flag = "DefensePriority",
    default = { "Shovel" },
    multi = false,
    options = { "Shovel", "FreezeRay" },
})

Garden = GardenTab:CreateSection("Robin")

Garden:CreateToggle({
    name = "Auto Collect Robin",
    default = false,
    flag = "AutoCollectRobin",
    Description = "Auto teleport ke burung Robin yang muncul di workspace.",
    callback = function()
        interval("AutoCollectRobin", "AutoCollectRobin", 2, autoCollectRobin)
    end,
})

Garden:CreateToggle({
    name = "Collect All Birds",
    default = false,
    flag = "CollectAllBirds",
    Description = "Kumpulkan semua jenis burung, bukan hanya Robin.",
    callback = function() end,
})

-- Shop
Shop = ShopTab:CreateSection("Seeds")

Shop:CreateToggle({
    name = "Auto Buy Seeds",
    default = false,
    flag = "AutoBuySeeds",
    callback = function()
        interval("AutoBuySeeds", "AutoBuySeeds", 2, autoBuySeeds)
    end,
})

Shop:CreateDropdown({
    name = "Seeds to Buy",
    flag = "BuySeeds",
    default = { "All" },
    options = withAll(seedNames()),
})

Shop = ShopTab:CreateSection("Gear")

Shop:CreateToggle({
    name = "Auto Buy Gear",
    default = false,
    flag = "AutoBuyGear",
    callback = function()
        interval("AutoBuyGear", "AutoBuyGear", 2, autoBuyGear)
    end,
})

local gearDropdown = Shop:CreateMultiDropdown({
    name = "Gears to Buy",
    flag = "BuyGear",
    default = { "All" },
    options = { "All" },
})
task.spawn(function()
    local names = gearNames()
    if #names > 0 then gearDropdown:updateList(withAll(names)) end
end)

Shop = ShopTab:CreateSection("Buff Gears")

Shop:CreateToggle({
    name = "Auto Use Buff Gears",
    default = false,
    flag = "AutoUseBuff",
    callback = function()
        interval("AutoUseBuff", "AutoUseBuff", 10, autoUseBuff)
    end,
})

Shop:CreateMultiDropdown({
    name = "Buff Gear",
    flag = "BuffGear",
    default = { "All" },
    multi = false,
    options = withAll(gearNames()),
})

Shop = ShopTab:CreateSection("Skills")

Shop:CreateToggle({
    name = "Auto Spend Skill Points",
    default = false,
    flag = "AutoSkill",
    callback = function()
        interval("AutoSkill", "AutoSkill", 3, autoSpendSkill)
    end,
})

Shop:CreateDropdown({
    name = "Skill",
    flag = "SkillName",
    default = { "BaseSpeed" },
    multi = false,
    options = SKILL_NAMES,
})

-- Crates
Crates = CratesTab:CreateSection("Crates")

Crates:CreateToggle({
    name = "Auto Open Crates",
    default = false,
    flag = "AutoOpenCrates",
    callback = function()
        interval("AutoOpenCrates", "AutoOpenCrates", 1.5, autoOpenCrates)
    end,
})

local crateDropdown = Crates:CreateDropdown({
    name = "Crate",
    flag = "CrateType",
    default = { "All" },
    options = { "All" },
})
task.spawn(function()
    local names = crateNames()
    if #names > 0 then crateDropdown:updateList(withAll(names)) end
end)

Crates = CratesTab:CreateSection("Seed Packs")

Crates:CreateToggle({
    name = "Auto Open Seed Packs",
    default = false,
    flag = "AutoOpenSeedPacks",
    callback = function()
        interval("AutoOpenSeedPacks", "AutoOpenSeedPacks", 1.5, autoOpenSeedPacks)
    end,
})

Crates:CreateMultiDropdown({
    name = "Seed Pack",
    flag = "SeedPackType",
    default = { "All" },
    options = withAll(seedPackNames()),
})

-- Pets
Pets = PetsTab:CreateSection("Pets")

Pets:CreateToggle({
    name = "Auto Equip Pets",
    default = false,
    flag = "AutoEquipPets",
    callback = function()
        interval("AutoEquipPets", "AutoEquipPets", 3, autoEquipPets)
    end,
})

Pets:CreateMultiDropdown({
    name = "Pets to Equip",
    flag = "EquipPets",
    default = { "All" },
    options = withAll(petSpecies()),
})

Pets:CreateButton({
    name = "Buy Pet Slot",
    callback = function()
        if Net then
            firePacket(Net.Pets.RequestPurchasePetSlot)
        end
    end,
})

Pets = PetsTab:CreateSection("Eggs")

Pets:CreateToggle({
    name = "Auto Open Eggs",
    default = false,
    flag = "AutoOpenEggs",
    callback = function()
        interval("AutoOpenEggs", "AutoOpenEggs", 1.5, autoOpenEggs)
    end,
})

Pets:CreateMultiDropdown({
    name = "Egg",
    flag = "EggType",
    default = { "All" },
    options = withAll(eggNames()),
})

Pets = PetsTab:CreateSection("Wild Pets")

Pets:CreateToggle({
    name = "Auto Tame Wild Pet",
    default = false,
    flag = "AutoTameWildPet",
    callback = function()
        interval("AutoTameWildPet", "AutoTameWildPet", 2, autoTameWildPet)
    end,
})

Pets:CreateMultiDropdown({
    name = "Tame Rarities",
    flag = "TameRarities",
    default = { "All" },
    options = withAll(petRarities()),
})

Pets:CreateToggle({
    name = "Server Hop Until Found",
    default = false,
    flag = "ServerHop",
    Description = "Hop ke server lain (TeleportService) untuk cari wild pet.",
    callback = function(enabled)
        if enabled then
            serverHop()
        end
    end,
})

Pets = PetsTab:CreateSection("Hop Until Wild Pet")

Pets:CreateToggle({
    name = "Hop Until Wild Pet Found",
    default = false,
    flag = "HopUntilWildPet",
    Description = "Server hop terus sampai wild pet target ditemukan.",
    callback = function()
        interval("HopUntilWildPet", "HopUntilWildPet", 10, serverHopUntilWildPet)
    end,
})

Pets:CreateMultiDropdown({
    name = "Target Pet Species",
    flag = "HopPetTarget",
    default = { "All" },
    options = withAll(petSpecies()),
})

Pets:CreateMultiDropdown({
    name = "Target Pet Rarity",
    flag = "HopPetRarity",
    default = { "All" },
    options = withAll(petRarities()),
})

Pets = PetsTab:CreateSection("Pet Webhook")

Pets:CreateToggle({
    name = "Pet Purchase Webhook",
    default = false,
    flag = "PetWebhook",
    Description = "Kirim notif Discord saat pet berhasil di-tame.",
    callback = function() end,
})

Pets:CreateTextbox({
    name = "Webhook URL",
    flag = "WebhookURL",
    default = "",
    callback = function() end,
})

Pets = PetsTab:CreateSection("Selling Pets")

Pets:CreateToggle({
    name = "Auto Sell Pets",
    default = false,
    flag = "AutoSellPets",
    callback = function()
        interval("AutoSellPets", "AutoSellPets", 3, autoSellPets)
    end,
})

Pets:CreateMultiDropdown({
    name = "Keep Rarities",
    flag = "KeepRarities",
    default = { "All" },
    options = withAll(petRarities()),
})

Pets:CreateMultiDropdown({
    name = "Keep Sizes",
    flag = "KeepSizes",
    default = { "All" },
    options = withAll(petSizeNames()),
})

-- Player
PlayerTab = PlayerTabTab:CreateSection("Quality of Life")

PlayerTab:CreateToggle({
    name = "Auto Collect Sheckles",
    default = false,
    flag = "AutoSheckles",
    callback = function()
        interval("AutoSheckles", "AutoSheckles", 1, autoCollectSheckles)
    end,
})

PlayerTab:CreateToggle({
    name = "Auto Daily Deal",
    default = false,
    flag = "AutoDailyDeal",
    callback = function()
        interval("AutoDailyDeal", "AutoDailyDeal", 30, autoDailyDeal)
    end,
})

PlayerTab:CreateToggle({
    name = "Auto Claim Mail",
    default = false,
    flag = "AutoMail",
    callback = function()
        interval("AutoMail", "AutoMail", 30, autoClaimMail)
    end,
})

PlayerTab:CreateTextbox({
    name = "Redeem Code",
    flag = "RedeemCode",
    default = "",
})

PlayerTab:CreateButton({
    name = "Submit Code",
    callback = function()
        local code = Library.Flags["RedeemCode"]
        if Net and code and code ~= "" then
            firePacket(Net.Settings.SubmitCode, code)
            notify("Codes", "Submitted: " .. tostring(code), "info")
        end
    end,
})

PlayerTab = PlayerTabTab:CreateSection("Utility")

PlayerTab:CreateToggle({
    name = "Auto Bargain",
    default = false,
    flag = "AutoBargain",
    callback = function()
        interval("AutoBargain", "AutoBargain", 5, autoBargain)
    end,
})

PlayerTab:CreateToggle({
    name = "Auto Accept Gifts",
    default = false,
    flag = "AutoAcceptGifts",
    callback = function(enabled)
        Library:CleanupConnectionsByTag("AutoAcceptGifts")
        if enabled and Net then
            local conn = Net.Gifting.Prompted.OnClientEvent:Connect(function(inst, _)
                if not Library.Flags["AutoAcceptGifts"] then return end
                firePacket(Net.Gifting.Response, inst, true)
            end)
            Library:TrackConnection(conn, "AutoAcceptGifts")
        end
    end,
})

PlayerTab:CreateButton({
    name = "Skip Cutscene",
    callback = function()
        task.spawn(skipCutscene)
    end,
})

PlayerTab = PlayerTabTab:CreateSection("Save Position")

PlayerTab:CreateButton({
    name = "Save Current Position",
    callback = function()
        local root = getRoot()
        if root then
            State.SavedPosition = root.CFrame
            notify("Position", "Posisi tersimpan!", "info")
        end
    end,
})

PlayerTab:CreateButton({
    name = "Teleport to Saved Position",
    callback = function()
        local root = getRoot()
        if root and State.SavedPosition then
            root.CFrame = State.SavedPosition
        else
            notify("Position", "Belum ada posisi tersimpan.", "warning")
        end
    end,
})

PlayerTab:CreateToggle({
    name = "Return to Saved Pos After Auto Actions",
    default = false,
    flag = "ReturnAfterAction",
    Description = "Auto Plant / Water / Sprinkler teleport balik ke posisi tersimpan setelah jalan.",
})

PlayerTab = PlayerTabTab:CreateSection("Night & Events")

PlayerTab:CreateToggle({
    name = "Stay at Garden at Night",
    default = false,
    flag = "StayAtGardenNight",
    Description = "Teleport ke kebun saat event Night mulai.",
})

PlayerTab:CreateToggle({
    name = "Pause Harvest During Weather",
    default = false,
    flag = "PauseHarvestWeather",
    Description = "Hentikan Auto Harvest saat Bloodmoon/Blizzard/Rain aktif.",
})

PlayerTab:CreateToggle({
    name = "Return to Base on Event End",
    default = false,
    flag = "ReturnOnEventEnd",
    Description = "Teleport ke kebun saat event cuaca berakhir.",
})

PlayerTab:CreateToggle({
    name = "Server Hop Until Night",
    default = false,
    flag = "HopUntilNight",
    callback = function()
        interval("HopUntilNight", "HopUntilNight", 8, serverHopUntilNight)
    end,
})

PlayerTab = PlayerTabTab:CreateSection("Prompts")

PlayerTab:CreateToggle({
    name = "Instant Proximity Prompts",
    default = false,
    flag = "InstantPrompts",
    Description = "Set MaxActivationDistance = 999 & HoldDuration = 0 pada semua ProximityPrompt.",
    callback = function(enabled)
        if enabled then
            task.spawn(setupInstantPrompts)
        else
            Library:CleanupConnectionsByTag("InstantPrompts")
        end
    end,
})

PlayerTab = PlayerTabTab:CreateSection("Protection")

PlayerTab:CreateToggle({
    name = "Anti Fling",
    default = false,
    flag = "AntiFling",
    callback = function()
        interval("AntiFling", "AntiFling", 0.05, function()
            local root = getRoot()
            if not root then return end
            if root.AssemblyLinearVelocity.Magnitude > 100 then
                root.AssemblyLinearVelocity = Vector3.zero
            end
        end)
    end,
})

PlayerTab:CreateToggle({
    name = "Anti Void",
    default = false,
    flag = "AntiVoid",
    callback = function()
        interval("AntiVoid", "AntiVoid", 0.1, function()
            local root = getRoot()
            if not root then return end
            if root.Position.Y > -100 then
                State.SavedPosition = root.CFrame
            elseif State.SavedPosition then
                root.CFrame = State.SavedPosition
            end
        end)
    end,
})

PlayerTab:CreateButton({
    name = "Server Hop",
    callback = serverHop,
})

PlayerTab = PlayerTabTab:CreateSection("Mailbox Send")

PlayerTab:CreateTextbox({
    name = "Target Player Name",
    flag = "MailboxTarget",
    default = "",
    callback = function() end,
})

PlayerTab:CreateMultiDropdown({
    name = "Send Crops",
    flag = "MailboxCrops",
    default = { "All" },
    options = withAll(seedNames()),
})

PlayerTab:CreateButton({
    name = "Send Mailbox Now",
    callback = function()
        task.spawn(autoSendMailbox)
    end,
})

-- Visuals / ESP

Visuals = VisualsTab:CreateSection("Wild Pet ESP")

Visuals:CreateToggle({
    name = "Wild Pet ESP",
    default = false,
    flag = "ESPWildPets",
    Description = "Highlight semua wild pet di workspace dengan filter rarity.",
    callback = function(enabled)
        if enabled then
            interval("ESPWildPets", "ESPWildPets", 2, updateWildPetESP)
        else
            Library:CleanupConnectionsByTag("ESPWildPets")
            clearESP("WildPetESP")
        end
    end,
})

Visuals:CreateMultiDropdown({
    name = "ESP Pet Rarities",
    flag = "ESPPetRarities",
    default = { "All" },
    options = withAll(petRarities()),
})

Visuals = VisualsTab:CreateSection("Fruit ESP")

Visuals:CreateToggle({
    name = "Fruit ESP",
    default = false,
    flag = "ESPFruit",
    Description = "Highlight semua buah di Gardens. Mutated = pink, normal = orange.",
    callback = function(enabled)
        if enabled then
            interval("ESPFruit", "ESPFruit", 2, updateFruitESP)
        else
            Library:CleanupConnectionsByTag("ESPFruit")
            clearESP("FruitESP")
        end
    end,
})

Visuals = VisualsTab:CreateSection("Shovel Target ESP")

Visuals:CreateToggle({
    name = "Shovel Target ESP",
    default = false,
    flag = "ESPShovelTarget",
    Description = "Highlight tanaman yang sesuai filter Auto Shovel (pakai ShovelCrops).",
    callback = function(enabled)
        if enabled then
            interval("ESPShovelTarget", "ESPShovelTarget", 2, updateShovelESP)
        else
            Library:CleanupConnectionsByTag("ESPShovelTarget")
            clearESP("ShovelESP")
        end
    end,
})

-----------------------------------------------------------------

if Net then
    local stealCancelConn = Net.Steal.StealCancelled.OnClientEvent:Connect(function()
        State.IsStealingActive = false
    end)
    Library:TrackConnection(stealCancelConn, "StealTracker")

    for _, evt in ipairs({ Net.WeatherEffects.BloodmoonStart, Net.WeatherEffects.BlizzardStart, Net.WeatherEffects.RainStart }) do
        local conn = evt.OnClientEvent:Connect(function()
            State.WeatherActive = true
        end)
        Library:TrackConnection(conn, "WeatherTracker")
    end

    for _, evt in ipairs({ Net.WeatherEffects.BloodmoonEnd, Net.WeatherEffects.BlizzardEnd, Net.WeatherEffects.RainEnd }) do
        local conn = evt.OnClientEvent:Connect(function()
            State.WeatherActive = false
        end)
        Library:TrackConnection(conn, "WeatherTracker")
    end

    local nightConn = Net.WeatherEffects.NightStart.OnClientEvent:Connect(function()
        if not Library.Flags["StayAtGardenNight"] then return end
        local plot = getPlot()
        local root = getRoot()
        if plot and root and plot.PrimaryPart then
            root.CFrame = plot.PrimaryPart.CFrame + Vector3.new(0, 5, 0)
        end
    end)
    Library:TrackConnection(nightConn, "NightTracker")

    local function onEventEnd()
        if not Library.Flags["ReturnOnEventEnd"] then return end
        local plot = getPlot()
        local root = getRoot()
        if plot and root and plot.PrimaryPart then
            root.CFrame = plot.PrimaryPart.CFrame + Vector3.new(0, 5, 0)
        end
    end

    for _, evt in ipairs({ Net.WeatherEffects.BloodmoonEnd, Net.WeatherEffects.BlizzardEnd, Net.WeatherEffects.RainbowEnd, Net.WeatherEffects.NightEnd }) do
        local conn = evt.OnClientEvent:Connect(onEventEnd)
        Library:TrackConnection(conn, "EventEndTracker")
    end
end

if Net then
    if Net.Steal and Net.Steal.StealStarted then
        local defenseConn = Net.Steal.StealStarted.OnClientEvent:Connect(function()
            if Library.Flags["AutoDefense"] then
                task.spawn(autoDefense)
            end
        end)
        Library:TrackConnection(defenseConn, "DefenseTracker")
    end

    if Net.Bird and Net.Bird.SeedDropped then
        local robinConn = Net.Bird.SeedDropped.OnClientEvent:Connect(function(birdType)
            if not Library.Flags["AutoCollectRobin"] then return end
            local isRobin = string.lower(tostring(birdType)):find("robin") ~= nil
            if Library.Flags["CollectAllBirds"] or isRobin then
                task.wait(0.5)
                task.spawn(autoCollectRobin)
            end
        end)
        Library:TrackConnection(robinConn, "RobinTracker")
    end

    if Net.Pets and Net.Pets.WildPetCollected then
        local webhookConn = Net.Pets.WildPetCollected.OnClientEvent:Connect(function(petInstance, petName)
            if not Library.Flags["PetWebhook"] then return end
            local rarity = petInstance and petInstance:GetAttribute("Rarity")
            local size = petInstance and petInstance:GetAttribute("Size")
            task.spawn(function()
                sendPetWebhook(tostring(petName), rarity, size)
            end)
        end)
        Library:TrackConnection(webhookConn, "PetWebhookTracker")
    end
end

-----------------------------------------------------------------

local function updateStatus()
    if not State.StatusLabel then
        return
    end
    local plot = getPlot()
    local fruits = #getFruitTools()
    if plot then
        pcall(function()
            State.StatusLabel:Set(string.format("Plot: %s | Fruits in bag: %d", plot.Name, fruits))
        end)
    else
        pcall(function()
            State.StatusLabel:Set("Plot: waiting...")
        end)
    end
end

Library:CleanupConnectionsByTag("StatusWatcher")
local lastStatus = 0
local statusConn = RunService.Heartbeat:Connect(function()
    if os.clock() - lastStatus >= 2 then
        lastStatus = os.clock()
        updateStatus()
    end
end)
Library:TrackConnection(statusConn, "StatusWatcher")

print("Grow a Garden 2 loaded.")
