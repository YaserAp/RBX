--[[
    Grow a Garden 2 - Modern & Responsive GUI Hub v2.6 (Fluent UI Monolithic Version)
    
    Skrip Auto-Farm dengan Fluent UI (dawid-scripts).
    Dilengkapi sistem debug log terperinci di F9 untuk melacak kendala executor.
--]]

print("[SpeedHubX] SCRIPT EXECUTION STARTED!")

-- ----------------------------------------------------
-- SYSTEM LOG INTERCEPTOR (DIAGNOSTIC SERVICE)
-- ----------------------------------------------------
shared.SpeedHubX = {
    LogMessages = {},
    OnLogAdded = nil
}
local SpeedHubX = shared.SpeedHubX
local logMessages = SpeedHubX.LogMessages

local LogService = nil
pcall(function() LogService = game:GetService("LogService") end)
if LogService then
    LogService.MessageOut:Connect(function(message, messageType)
        local prefix = "[INFO]"
        if messageType == Enum.MessageType.MessageWarning then
            prefix = "[WARN]"
        elseif messageType == Enum.MessageType.MessageError then
            prefix = "[ERROR]"
        end
        local formatted = prefix .. " " .. tostring(message)
        table.insert(logMessages, formatted)
        if #logMessages > 80 then table.remove(logMessages, 1) end
        if SpeedHubX.OnLogAdded then pcall(SpeedHubX.OnLogAdded, formatted) end
    end)
    
    pcall(function()
        local history = LogService:GetLogHistory()
        for _, log in ipairs(history) do
            local prefix = "[INFO]"
            if log.messageType == Enum.MessageType.MessageWarning then
                prefix = "[WARN]"
            elseif log.messageType == Enum.MessageType.MessageError then
                prefix = "[ERROR]"
            end
            table.insert(logMessages, prefix .. " " .. tostring(log.message))
        end
    end)
end

print("[SpeedHubX] LogService interceptor initialized.")


-- ----------------------------------------------------
-- CONFIG MODULE
-- ----------------------------------------------------
--[[
    Speed Hub X - Config Module
    Menyimpan seluruh state konfigurasi fitur auto-farm dan player mods.
--]]

local SpeedHubX = shared.SpeedHubX or {}
shared.SpeedHubX = SpeedHubX

SpeedHubX.Config = {
    AutoPlant = false,
    AutoHarvest = false,
    AutoWater = false,
    AutoSell = false,
    AutoBuySeeds = false,
    AutoSpray = false,
    SelectedSeeds = {
        ["Carrot"] = false,
        ["Strawberry"] = false,
        ["Blueberry"] = false,
        ["Tomato"] = true,
        ["Apple"] = false,
        ["Tulip"] = false,
        ["Corn"] = false,
        ["Cactus"] = false,
        ["Pineapple"] = false,
        ["Bamboo"] = false,
        ["Mushroom"] = false,
        ["Green Bean"] = false,
        ["Banana"] = false,
        ["Grape"] = false,
        ["Coconut"] = false,
        ["Mango"] = false,
        ["Acorn"] = false,
        ["Cherry"] = false,
        ["Dragon Fruit"] = false,
        ["Sunflower"] = false,
        ["Pomegranate"] = false,
        ["Poison Apple"] = false,
        ["Venus Fly Trap"] = false,
        ["Moon Bloom"] = false,
        ["Dragon's Breath"] = false
    },
    WalkSpeed = 16,
    JumpPower = 50,
    InfiniteJump = false,
    AntiAFK = true,
    SelectedMutations = {"Choc", "Overgrown", "Gold", "Rainbow"}
}

print("[SpeedHubX] Config module successfully loaded.")


-- ----------------------------------------------------
-- UTILITIES MODULE
-- ----------------------------------------------------
--[[
    Speed Hub X - Utilities Module
    Berisi fungsi-fungsi pembantu interaksi game dan dekorasi UI.
--]]

local SpeedHubX = shared.SpeedHubX or {}
shared.SpeedHubX = SpeedHubX

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

local Utils = {}
SpeedHubX.Utils = Utils

-- Fungsi Mencari Plot Kebun Pemain
function Utils.getPlayerPlot()
    local farmFolder = workspace:FindFirstChild("Farm") or workspace:FindFirstChild("Farms")
    if farmFolder then
        for _, plot in ipairs(farmFolder:GetChildren()) do
            local important = plot:FindFirstChild("Important")
            local data = important and important:FindFirstChild("Data")
            local owner = data and data:FindFirstChild("Owner")
            if owner and (owner.Value == LocalPlayer.Name or owner.Value == LocalPlayer) then
                return plot
            end
        end
    end
    return nil
end

-- Fungsi Pemanggil Event Biner Game secara aman
function Utils.fireNetworkEvent(eventTable, ...)
    if not eventTable then return false end
    local successCall = false
    local args = {...}
    local argCount = select("#", ...)
    local unpackFunc = unpack or table.unpack
    
    pcall(function()
        if type(eventTable) == "table" then
            if eventTable.Fire then
                eventTable:Fire(unpackFunc(args, 1, argCount))
                successCall = true
            elseif eventTable.FireServer then
                eventTable:FireServer(unpackFunc(args, 1, argCount))
                successCall = true
            elseif eventTable.fire then
                eventTable:fire(unpackFunc(args, 1, argCount))
                successCall = true
            else
                local mt = getmetatable(eventTable)
                if mt and mt.__call then
                    eventTable(unpackFunc(args, 1, argCount))
                    successCall = true
                end
            end
        end
    end)
    
    return successCall
end

-- Fungsi Fallback Interaksi Click/Prompt Fisik
function Utils.triggerInteraction(object)
    if not object then return false end
    local prompt = object:FindFirstChildOfClass("ProximityPrompt")
    if prompt and fireproximityprompt then
        pcall(function() fireproximityprompt(prompt) end)
        return true
    end
    local clickDetector = object:FindFirstChildOfClass("ClickDetector")
    if clickDetector and fireclickdetector then
        pcall(function() fireclickdetector(clickDetector) end)
        return true
    end
    return false
end

-- Fungsi Pembuat UICorner
function Utils.addCorner(parent, radius)
    local success, corner = pcall(function()
        local c = Instance.new("UICorner")
        c.CornerRadius = UDim.new(0, radius)
        c.Parent = parent
        return c
    end)
    return success and corner or nil
end

-- Fungsi Pembuat UIStroke
function Utils.addStroke(parent, color, thickness)
    local success, str = pcall(function()
        local s = Instance.new("UIStroke")
        s.Color = color
        s.Thickness = thickness
        s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
        s.Parent = parent
        return s
    end)
    return success and str or nil
end

print("[SpeedHubX] Utilities module successfully loaded.")


-- ----------------------------------------------------
-- FEATURES MODULE
-- ----------------------------------------------------
--[[
    Speed Hub X - Features Module
    Menjalankan seluruh loop pertanian, penyemprotan, transaksi, dan modifikasi pemain.
--]]

local SpeedHubX = shared.SpeedHubX or {}
shared.SpeedHubX = SpeedHubX

local config = SpeedHubX.Config
local utils = SpeedHubX.Utils

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

-- ----------------------------------------------------
-- DYNAMIC NETWORKING CONTROLLER (BACKGROUND ASYNC)
-- ----------------------------------------------------
task.spawn(function()
    print("[SpeedHubX] Loading internal networking module...")
    local SharedModules = ReplicatedStorage:WaitForChild("SharedModules", 10)
    if SharedModules then
        local netModule = SharedModules:WaitForChild("Networking", 10)
        if netModule then
            local successNet, errNet = pcall(function()
                SpeedHubX.Networking = require(netModule)
            end)
            if successNet and SpeedHubX.Networking then
                print("[SpeedHubX] Internal Networking Module successfully loaded!")
            else
                warn("[SpeedHubX] Failed to require networking: " .. tostring(errNet))
            end
        else
            warn("[SpeedHubX] Networking module not found in SharedModules.")
        end
    else
        warn("[SpeedHubX] SharedModules folder not found.")
    end
end)

-- ----------------------------------------------------
-- GAMEPLAY LOOPS
-- ----------------------------------------------------

-- 1. Auto Plant Loop
task.spawn(function()
    while true do
        if config.AutoPlant then
            local plot = utils.getPlayerPlot()
            if plot then
                for _, tile in ipairs(plot:GetDescendants()) do
                    if tile.Name == "Dirt" or tile.Name == "PlotTile" or tile.Name == "Tile" then
                        local isEmpty = tile:GetAttribute("Empty") == true or tile:GetAttribute("Occupied") == false or #tile:GetChildren() == 0
                        if isEmpty then
                            local seedTool = nil
                            for seedName, isSelected in pairs(config.SelectedSeeds) do
                                if isSelected then
                                    seedTool = LocalPlayer.Backpack:FindFirstChild(seedName)
                                        or LocalPlayer.Backpack:FindFirstChild(seedName .. " Seed")
                                        or LocalPlayer.Backpack:FindFirstChild(seedName .. "Seed")
                                    if not seedTool and LocalPlayer.Character then
                                        seedTool = LocalPlayer.Character:FindFirstChild(seedName)
                                            or LocalPlayer.Character:FindFirstChild(seedName .. " Seed")
                                            or LocalPlayer.Character:FindFirstChild(seedName .. "Seed")
                                    end
                                    if seedTool then
                                        break
                                    end
                                end
                            end
                            
                            if seedTool then
                                pcall(function() LocalPlayer.Character.Humanoid:EquipTool(seedTool) end)
                                task.wait(0.05)
                                
                                local fired = false
                                if SpeedHubX.Networking and SpeedHubX.Networking.Plant and SpeedHubX.Networking.Plant.PlantSeed then
                                    fired = utils.fireNetworkEvent(SpeedHubX.Networking.Plant.PlantSeed, tile, seedTool.Name)
                                end
                                
                                if not fired then
                                    utils.triggerInteraction(tile)
                                end
                                task.wait(0.05)
                            end
                        end
                    end
                end
            end
        end
        task.wait(1.0)
    end
end)

-- 2. Auto Harvest Loop
task.spawn(function()
    while true do
        if config.AutoHarvest then
            local plot = utils.getPlayerPlot()
            if plot then
                local physicalFolder = plot:FindFirstChild("Important") and plot.Important:FindFirstChild("Plants_Physical")
                local targetFolder = physicalFolder or plot
                
                for _, plant in ipairs(targetFolder:GetDescendants()) do
                    local isReady = plant:GetAttribute("ReadyToHarvest") == true or plant:GetAttribute("Progress") == 100 or plant:FindFirstChild("Fruits")
                    
                    if isReady then
                        local fruitsFolder = plant:FindFirstChild("Fruits")
                        if fruitsFolder then
                            for _, fruit in ipairs(fruitsFolder:GetChildren()) do
                                local fired = false
                                if SpeedHubX.Networking and SpeedHubX.Networking.Garden and SpeedHubX.Networking.Garden.CollectFruit then
                                    fired = utils.fireNetworkEvent(SpeedHubX.Networking.Garden.CollectFruit, fruit)
                                end
                                if not fired then
                                    utils.triggerInteraction(fruit)
                                end
                            end
                        else
                            local fired = false
                            if SpeedHubX.Networking and SpeedHubX.Networking.Garden and SpeedHubX.Networking.Garden.CollectFruit then
                                fired = utils.fireNetworkEvent(SpeedHubX.Networking.Garden.CollectFruit, plant)
                            end
                            if not fired then
                                utils.triggerInteraction(plant)
                            end
                        end
                    end
                end
            end
        end
        task.wait(0.8)
    end
end)

-- 3. Auto Sell Loop
task.spawn(function()
    while true do
        if config.AutoSell then
            local fired = false
            if SpeedHubX.Networking and SpeedHubX.Networking.NPCS and SpeedHubX.Networking.NPCS.SellAll then
                fired = utils.fireNetworkEvent(SpeedHubX.Networking.NPCS.SellAll)
            end
            
            -- Jika bypass jaringan gagal, gunakan interaksi fisik di SellArea/Merchant/Sell
            if not fired then
                local sellPart = workspace:FindFirstChild("SellArea", true) 
                    or workspace:FindFirstChild("Merchant", true) 
                    or workspace:FindFirstChild("Sell", true)
                if sellPart then
                    utils.triggerInteraction(sellPart)
                end
            end
        end
        task.wait(1.5)
    end
end)

-- 4. Auto Buy Seeds Loop
task.spawn(function()
    while true do
        if config.AutoBuySeeds then
            for seedName, isSelected in pairs(config.SelectedSeeds) do
                if isSelected then
                    if SpeedHubX.Networking and SpeedHubX.Networking.SeedShop and SpeedHubX.Networking.SeedShop.PurchaseSeed then
                        utils.fireNetworkEvent(SpeedHubX.Networking.SeedShop.PurchaseSeed, seedName, 1)
                    end
                    task.wait(0.1) -- Jeda singkat antar pembelian benih
                end
            end
        end
        task.wait(1.5)
    end
end)

-- 5. Auto Spray Mutation Loop
task.spawn(function()
    while true do
        if config.AutoSpray then
            local plot = utils.getPlayerPlot()
            if plot then
                local physicalFolder = plot:FindFirstChild("Important") and plot.Important:FindFirstChild("Plants_Physical")
                if physicalFolder then
                    for _, plant in ipairs(physicalFolder:GetChildren()) do
                        local fruits = plant:FindFirstChild("Fruits")
                        if fruits then
                            for _, fruit in ipairs(fruits:GetChildren()) do
                                local hasMutation = false
                                for _, mut in ipairs(config.SelectedMutations) do
                                    if fruit:GetAttribute(mut) == true then
                                        hasMutation = true
                                        break
                                    end
                                end
                                
                                if hasMutation then
                                    local spray = LocalPlayer.Backpack:FindFirstChild("Cleaning Spray") or LocalPlayer.Character:FindFirstChild("Cleaning Spray")
                                    if spray then
                                        pcall(function() LocalPlayer.Character.Humanoid:EquipTool(spray) end)
                                        task.wait(0.1)
                                        if SpeedHubX.Networking and SpeedHubX.Networking.SprayService and SpeedHubX.Networking.SprayService.TrySpray then
                                            utils.fireNetworkEvent(SpeedHubX.Networking.SprayService.TrySpray, fruit)
                                        else
                                            local sprayEvent = ReplicatedStorage:FindFirstChild("SprayService_RE", true)
                                            if sprayEvent then
                                                sprayEvent:FireServer("TrySpray", fruit)
                                            end
                                        end
                                        task.wait(0.1)
                                    end
                                end
                            end
                        end
                    end
                end
            end
        end
        task.wait(1.5)
    end
end)

-- 6. Auto Water Loop
task.spawn(function()
    while true do
        if config.AutoWater then
            local plot = utils.getPlayerPlot()
            if plot then
                for _, tile in ipairs(plot:GetDescendants()) do
                    if tile.Name == "Dirt" or tile.Name == "PlotTile" or tile.Name == "Tile" then
                        local waterValue = tile:GetAttribute("Water") or 100
                        if waterValue < 80 then
                            local waterCan = LocalPlayer.Backpack:FindFirstChild("Watering Can") or LocalPlayer.Character:FindFirstChild("Watering Can")
                            if not waterCan then
                                for _, item in ipairs(LocalPlayer.Backpack:GetChildren()) do
                                    if item.Name:lower():find("water") or item.Name:lower():find("can") then
                                        waterCan = item
                                        break
                                    end
                                end
                            end
                            
                            if waterCan then
                                pcall(function() LocalPlayer.Character.Humanoid:EquipTool(waterCan) end)
                                task.wait(0.1)
                                local fired = false
                                if SpeedHubX.Networking and SpeedHubX.Networking.WateringCan and SpeedHubX.Networking.WateringCan.UseWateringCan then
                                    fired = utils.fireNetworkEvent(SpeedHubX.Networking.WateringCan.UseWateringCan, tile)
                                end
                                if not fired then
                                    utils.triggerInteraction(tile)
                                end
                                task.wait(0.1)
                            end
                        end
                    end
                end
            end
        end
        task.wait(1.5)
    end
end)

-- ----------------------------------------------------
-- ADDITIONAL SERVICES (ANTI-AFK & PLAYER MODS)
-- ----------------------------------------------------

-- Infinite Jump Listener
UserInputService.JumpRequest:Connect(function()
    if config.InfiniteJump and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
        pcall(function()
            LocalPlayer.Character.Humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
        end)
    end
end)

-- Anti AFK
task.spawn(function()
    task.wait(2)
    if config.AntiAFK then
        local VirtualUser = nil
        pcall(function() VirtualUser = game:GetService("VirtualUser") end)
        if VirtualUser then
            LocalPlayer.Idled:Connect(function()
                pcall(function()
                    VirtualUser:CaptureController()
                    VirtualUser:ClickButton2(Vector2.new(0, 0))
                    print("[SpeedHubX] Anti-AFK triggered.")
                end)
            end)
        end
    end
end)

-- Karakter respawn handler (WalkSpeed & JumpPower refresh)
LocalPlayer.CharacterAdded:Connect(function(char)
    local hum = char:WaitForChild("Humanoid", 10)
    if hum then
        task.wait(0.5)
        pcall(function()
            hum.WalkSpeed = config.WalkSpeed
            hum.JumpPower = config.JumpPower
        end)
    end
end)

print("[SpeedHubX] Features module successfully loaded.")


-- ----------------------------------------------------
-- FLUENT UI WRAPPER
-- ----------------------------------------------------
--[[
    Speed Hub X - Fluent UI Wrapper
    Menggunakan Fluent UI Library dari dawid-scripts untuk tampilan premium.
    Dioptimalkan secara penuh untuk Delta Executor.
--]]

local SpeedHubX = shared.SpeedHubX or {}
shared.SpeedHubX = SpeedHubX

print("[SpeedHubX] Loading Fluent UI library from GitHub...")

local Fluent = nil
local success, result = pcall(function()
    return loadstring(game:HttpGet("https://github.com/dawid-scripts/Fluent/releases/latest/download/main.lua"))()
end)

if success and type(result) == "table" then
    Fluent = result
    print("[SpeedHubX] Fluent UI loaded successfully!")
else
    warn("[SpeedHubX] Failed to load Fluent UI from release, trying fallback...")
    local success2, result2 = pcall(function()
        return loadstring(game:HttpGet("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/main.lua"))()
    end)
    if success2 and type(result2) == "table" then
        Fluent = result2
        print("[SpeedHubX] Fluent UI loaded from fallback.")
    else
        error("[SpeedHubX] Critical Error: Fluent UI could not be loaded! " .. tostring(result or result2))
    end
end

local UIWrapper = {}
SpeedHubX.UI = UIWrapper

function UIWrapper:CreateWindow(titleText)
    local Window = Fluent:CreateWindow({
        Title = titleText or "Speed Hub X",
        SubTitle = "by YaserAp & Antigravity AI",
        TabWidth = 160,
        Size = UDim2.fromOffset(580, 460),
        Acrylic = false, -- Nonaktifkan acrylic blur di mobile agar bebas lag/crash
        Theme = "Dark",
        MinimizeKey = Enum.KeyCode.LeftControl
    })

    local WindowWrapper = {
        Tabs = {}
    }

    function WindowWrapper:CreateTab(tabName)
        local icon = "settings"
        if tabName == "Auto Farm" then
            icon = "home"
        elseif tabName == "Toko Benih" then
            icon = "shopping-cart"
        elseif tabName == "Auto Spray" then
            icon = "droplet"
        elseif tabName == "Player Mods" then
            icon = "user"
        elseif tabName == "System Logs" then
            icon = "terminal"
        elseif tabName == "Credits" then
            icon = "info"
        end

        local Tab = Window:AddTab({ Title = tabName, Icon = icon })
        local TabWrapper = {}

        function TabWrapper:AddToggle(labelText, defaultValue, callback)
            local toggleId = "Toggle_" .. labelText:gsub("%s+", ""):gsub("%W+", "")
            local Toggle = Tab:AddToggle(toggleId, {
                Title = labelText,
                Default = defaultValue or false
            })
            Toggle:OnChanged(function()
                pcall(callback, Toggle.Value)
            end)
            return Toggle
        end

        function TabWrapper:AddParagraph(titleText, contentText)
            local Paragraph = Tab:AddParagraph({
                Title = titleText or "",
                Content = contentText or ""
            })

            local ParaWrapper = {}
            function ParaWrapper:SetTitle(t)
                Paragraph:SetTitle(t)
            end
            function ParaWrapper:SetText(t)
                Paragraph:SetDesc(t)
            end
            return ParaWrapper
        end

        function TabWrapper:AddDropdown(labelText, valuesList, defaultValue, callback, multi)
            local dropdownId = "Dropdown_" .. labelText:gsub("%s+", ""):gsub("%W+", "")
            local Dropdown = Tab:AddDropdown(dropdownId, {
                Title = labelText,
                Values = valuesList or {},
                Multi = not not multi,
                Default = defaultValue
            })
            Dropdown:OnChanged(function(val)
                pcall(callback, val)
            end)
            return Dropdown
        end

        function TabWrapper:AddSlider(labelText, minVal, maxVal, defaultValue, callback)
            local sliderId = "Slider_" .. labelText:gsub("%s+", ""):gsub("%W+", "")
            local Slider = Tab:AddSlider(sliderId, {
                Title = labelText,
                Min = minVal or 0,
                Max = maxVal or 100,
                Default = defaultValue or minVal,
                Rounding = 0,
                Callback = function(val)
                    pcall(callback, val)
                end
            })
            return Slider
        end

        function TabWrapper:AddLogViewer()
            local LogParagraph = Tab:AddParagraph({
                Title = "Console Logs",
                Content = "Waiting for logs..."
            })

            local function refreshLogs()
                local txt = ""
                local logMessages = SpeedHubX.LogMessages or {}
                local limit = math.max(1, #logMessages - 15)
                for i = limit, #logMessages do
                    txt = txt .. logMessages[i] .. "\n"
                end
                LogParagraph:SetDesc(txt)
            end

            SpeedHubX.OnLogAdded = function(msg)
                pcall(refreshLogs)
            end

            pcall(refreshLogs)
        end

        return TabWrapper
    end

    return WindowWrapper
end

SpeedHubX.Fluent = Fluent
print("[SpeedHubX] Fluent UI Wrapper successfully loaded.")
return UIWrapper


-- ----------------------------------------------------
-- MAIN INITIALIZATION
-- ----------------------------------------------------
--[[
    Speed Hub X - Main Initialization Script
    Menggabungkan modul UI dan fitur, serta merender seluruh panel di layar.
--]]

local SpeedHubX = shared.SpeedHubX or {}
shared.SpeedHubX = SpeedHubX

local config = SpeedHubX.Config
local UI = SpeedHubX.UI

print("[SpeedHubX] Initializing GUI layout...")

local Window = UI:CreateWindow("Speed Hub X | Grow a Garden 2")

-- Tab 1: Farming
local FarmTab = Window:CreateTab("Auto Farm")
FarmTab:AddToggle("Auto Plant (Tanam)", config.AutoPlant, function(v)
    config.AutoPlant = v
end)
FarmTab:AddToggle("Auto Harvest (Panen)", config.AutoHarvest, function(v)
    config.AutoHarvest = v
end)
FarmTab:AddToggle("Auto Water (Siram)", config.AutoWater, function(v)
    config.AutoWater = v
end)
FarmTab:AddToggle("Auto sell all (semua buah d inventory)", config.AutoSell, function(v)
    config.AutoSell = v
end)

-- Tab 2: Toko Benih
local ShopTab = Window:CreateTab("Toko Benih")

ShopTab:AddToggle("Auto Beli Benih (Global)", config.AutoBuySeeds, function(v)
    config.AutoBuySeeds = v
end)

local seedNames = {
    "Carrot", "Strawberry", "Blueberry", "Tomato", "Apple", "Tulip", "Corn", "Cactus",
    "Pineapple", "Bamboo", "Mushroom", "Green Bean", "Banana", "Grape", "Coconut",
    "Mango", "Acorn", "Cherry", "Dragon Fruit", "Sunflower", "Pomegranate",
    "Poison Apple", "Venus Fly Trap", "Moon Bloom", "Dragon's Breath"
}

-- Build standard list of default selected seed strings based on config.SelectedSeeds
local defaultSelected = {}
for seedName, isSelected in pairs(config.SelectedSeeds) do
    if isSelected and table.find(seedNames, seedName) then
        table.insert(defaultSelected, seedName)
    end
end

ShopTab:AddDropdown("Pilih Benih yang Ingin Dibeli", seedNames, defaultSelected, function(val)
    -- Reset all config seeds to false
    for _, seedName in ipairs(seedNames) do
        config.SelectedSeeds[seedName] = false
    end
    -- Set selected ones to true. val is a dictionary: {[seedName] = true/false}
    for seedName, isSelected in pairs(val) do
        if type(seedName) == "string" and isSelected == true then
            config.SelectedSeeds[seedName] = true
        end
    end
end, true) -- Pass true for multi-select dropdown

-- Tab 3: Mutations (Spray)
local MutationTab = Window:CreateTab("Auto Spray")
MutationTab:AddToggle("Auto Spray (Mutasi)", config.AutoSpray, function(v)
    config.AutoSpray = v
end)
MutationTab:AddDropdown("Pilih Mutasi", {"Choc", "Overgrown", "Gold", "Rainbow", "Celestial", "Frozen", "Plasma"}, "Choc", function(v)
    local Players = game:GetService("Players")
    local LocalPlayer = Players.LocalPlayer
    if not table.find(config.SelectedMutations, v) then
        table.insert(config.SelectedMutations, v)
    end
end)

-- Tab 4: Player Mods
local PlayerTab = Window:CreateTab("Player Mods")
PlayerTab:AddSlider("WalkSpeed", 16, 150, config.WalkSpeed, function(v)
    config.WalkSpeed = v
    pcall(function()
        local Players = game:GetService("Players")
        local LocalPlayer = Players.LocalPlayer
        if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
            LocalPlayer.Character.Humanoid.WalkSpeed = v
        end
    end)
end)
PlayerTab:AddSlider("JumpPower", 50, 300, config.JumpPower, function(v)
    config.JumpPower = v
    pcall(function()
        local Players = game:GetService("Players")
        local LocalPlayer = Players.LocalPlayer
        if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
            LocalPlayer.Character.Humanoid.JumpPower = v
        end
    end)
end)
PlayerTab:AddToggle("Infinite Jump", config.InfiniteJump, function(v)
    config.InfiniteJump = v
end)

-- Tab 5: Logs (Diagnostic Live Console)
local LogTab = Window:CreateTab("System Logs")
LogTab:AddLogViewer()

-- Tab 6: Credits
local CreditsTab = Window:CreateTab("Credits")
CreditsTab:AddParagraph("Dibuat Oleh", "Antigravity AI (Pair Programming dengan Anda)")
CreditsTab:AddParagraph("UI Version", "v2.2 Modular Offline UI")
CreditsTab:AddParagraph("Executor Kompatibilitas", "Delta Executor (Local / GitHub Mode)")

print("[SpeedHubX] Modern Cyberpunk UI successfully initialized and rendered!")
