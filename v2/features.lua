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
    -- Helper function to check if fruit/plant is ready to harvest based on prompts or attributes
    local function isHarvestable(object, parentPlant)
        if not object then return false end
        
        -- Check for enabled ProximityPrompt
        for _, desc in ipairs(object:GetDescendants()) do
            if desc:IsA("ProximityPrompt") and desc.Enabled then
                return true
            end
        end
        
        -- Check for ClickDetector
        for _, desc in ipairs(object:GetDescendants()) do
            if desc:IsA("ClickDetector") then
                return true
            end
        end
        
        -- Check attributes of object
        if object:GetAttribute("ReadyToHarvest") == true or object:GetAttribute("Progress") == 100 then
            return true
        end
        
        -- Fallback to parent plant attributes
        if parentPlant and (parentPlant:GetAttribute("ReadyToHarvest") == true or parentPlant:GetAttribute("Progress") == 100) then
            return true
        end
        
        return false
    end

    -- Helper function to harvest an object (fruit or plant model)
    local function harvestObject(object)
        -- Prioritize physical interaction (ProximityPrompt/ClickDetector) first,
        -- since it is 100% reliable and mimics real user input.
        local fired = utils.triggerInteraction(object)
        
        -- If physical interaction is not available/failed, fallback to network event bypass
        if not fired then
            if SpeedHubX.Networking and SpeedHubX.Networking.Garden and SpeedHubX.Networking.Garden.CollectFruit then
                utils.fireNetworkEvent(SpeedHubX.Networking.Garden.CollectFruit, object)
            end
        end
    end

    while true do
        if config.AutoHarvest then
            local plot = utils.getPlayerPlot()
            if plot then
                local physicalFolder = plot:FindFirstChild("Important") and plot.Important:FindFirstChild("Plants_Physical")
                if not physicalFolder then
                    physicalFolder = plot:FindFirstChild("Plants_Physical", true) or plot:FindFirstChild("Plants", true)
                end
                local targetFolder = physicalFolder or plot
                
                for _, plant in ipairs(targetFolder:GetChildren()) do
                    if plant:IsA("Model") or plant:IsA("BasePart") then
                        local fruitsFolder = plant:FindFirstChild("Fruits")
                        if fruitsFolder then
                            -- Case 1: Plant has a Fruits folder (e.g. Tomato, Blueberry, etc.)
                            for _, fruit in ipairs(fruitsFolder:GetChildren()) do
                                if isHarvestable(fruit, plant) then
                                    harvestObject(fruit)
                                    task.wait(0.05)
                                end
                            end
                        else
                            -- Case 2: Plant itself is harvested (no Fruits folder)
                            if isHarvestable(plant) then
                                harvestObject(plant)
                                task.wait(0.05)
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
