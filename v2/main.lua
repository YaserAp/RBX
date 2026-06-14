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
ShopTab:AddDropdown("Pilih Benih", {"Carrot", "Strawberry", "Blueberry", "Tomato", "Apple", "Grape", "Pumpkin", "Banana", "Dragon Fruit", "Moon Bloom", "Gold", "Rainbow"}, config.SelectedSeed, function(v)
    config.SelectedSeed = v
end)
ShopTab:AddToggle("Auto Beli Benih", config.AutoBuySeeds, function(v)
    config.AutoBuySeeds = v
end)

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
