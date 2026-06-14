--[[
    Grow a Garden 2 - Modern & Responsive GUI Hub v2.2 (Trace Debug Version)
    
    Skrip Auto-Farm dengan Modern UI Offline Cyberpunk/Dark-Neon.
    Dilengkapi sistem debug log terperinci di F9 untuk melacak kendala executor.
--]]

print("[SpeedHubX] SCRIPT EXECUTION STARTED!")

-- ----------------------------------------------------
-- SYSTEM LOG INTERCEPTOR (DIAGNOSTIC SERVICE)
-- ----------------------------------------------------
local LogService = nil
pcall(function() LogService = game:GetService("LogService") end)
local logMessages = {}
local onLogAdded = nil

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
        if onLogAdded then pcall(onLogAdded, formatted) end
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

-- Wrap entire setup process in a pcall to catch early initialization bugs
local initSuccess, initError = pcall(function()
    print("[SpeedHubX] Getting core services...")
    local Players = game:GetService("Players")
    local LocalPlayer = Players.LocalPlayer
    
    -- Tunggu LocalPlayer secara non-blocking jika belum siap
    local retriesLP = 0
    while not LocalPlayer and retriesLP < 50 do
        task.wait(0.1)
        LocalPlayer = Players.LocalPlayer
        retriesLP = retriesLP + 1
    end
    
    if not LocalPlayer then
        error("LocalPlayer is nil after retries.")
    end
    print("[SpeedHubX] LocalPlayer obtained: " .. tostring(LocalPlayer.Name))
    
    -- Jalankan Loaded check di background agar tidak memblokir thread utama
    task.spawn(function()
        if not game:IsLoaded() then
            pcall(function() game.Loaded:Wait() end)
        end
    end)
    
    -- Cara aman mendapatkan PlayerGui dengan beberapa alternatif (hybrid method)
    print("[SpeedHubX] Retrieving PlayerGui...")
    local PlayerGui = nil
    local retriesPG = 0
    
    while not PlayerGui and retriesPG < 50 do
        pcall(function() PlayerGui = LocalPlayer:FindFirstChildOfClass("PlayerGui") end)
        if not PlayerGui then
            pcall(function() PlayerGui = LocalPlayer:WaitForChild("PlayerGui", 0.1) end)
        end
        if not PlayerGui then
            pcall(function() PlayerGui = LocalPlayer.PlayerGui end)
        end
        if not PlayerGui then
            task.wait(0.1)
            retriesPG = retriesPG + 1
        end
    end
    
    if not PlayerGui then
        error("PlayerGui is completely inaccessible.")
    end
    print("[SpeedHubX] PlayerGui obtained: " .. tostring(PlayerGui:GetFullName()))
    
    -- Hapus GUI lama jika ada
    print("[SpeedHubX] Cleaning old GUIs...")
    local oldGUI = PlayerGui:FindFirstChild("SpeedHubX_ModernGUI")
    if oldGUI then pcall(function() oldGUI:Destroy() end) end
    
    local oldFallback = PlayerGui:FindFirstChild("SpeedHubX_Fallback")
    if oldFallback then pcall(function() oldFallback:Destroy() end) end
    
    local ReplicatedStorage = game:GetService("ReplicatedStorage")
    local TweenService = game:GetService("TweenService")
    local UserInputService = game:GetService("UserInputService")
    
    -- ----------------------------------------------------
    -- STATE KONFIGURASI
    -- ----------------------------------------------------
    local config = {
        AutoPlant = false,
        AutoHarvest = false,
        AutoWater = false,
        AutoSell = false,
        AutoBuySeeds = false,
        AutoSpray = false,
        SelectedSeed = "Tomato",
        WalkSpeed = 16,
        JumpPower = 50,
        InfiniteJump = false,
        AntiAFK = true,
        SelectedMutations = {"Choc", "Overgrown", "Gold", "Rainbow"}
    }
    
    -- ----------------------------------------------------
    -- DYNAMIC NETWORKING CONTROLLER (BACKGROUND ASYNC)
    -- ----------------------------------------------------
    local Networking = nil
    task.spawn(function()
        print("[SpeedHubX] Loading internal networking in background...")
        local SharedModules = ReplicatedStorage:WaitForChild("SharedModules", 10)
        if SharedModules then
            local netModule = SharedModules:WaitForChild("Networking", 10)
            if netModule then
                local successNet, errNet = pcall(function()
                    Networking = require(netModule)
                end)
                if successNet and Networking then
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
    
    -- Fungsi Pemanggil Event Biner Game
    local function fireNetworkEvent(eventTable, ...)
        if not eventTable then return false end
        local successCall = false
        
        pcall(function()
            if type(eventTable) == "table" then
                if eventTable.Fire then
                    eventTable:Fire(...)
                    successCall = true
                elseif eventTable.FireServer then
                    eventTable:FireServer(...)
                    successCall = true
                elseif eventTable.fire then
                    eventTable:fire(...)
                    successCall = true
                else
                    local mt = getmetatable(eventTable)
                    if mt and mt.__call then
                        eventTable(...)
                        successCall = true
                    end
                end
            end
        end)
        
        return successCall
    end
    
    -- Fungsi Cari Plot Kebun Pemain
    local function getPlayerPlot()
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
    
    -- Fungsi Fallback Interaksi Click/Prompt
    local function triggerInteraction(object)
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
    
    -- ----------------------------------------------------
    -- GAMEPLAY LOOPS (BACKGROUND PROCESSES)
    -- ----------------------------------------------------
    
    -- 1. Auto Plant Loop
    task.spawn(function()
        while true do
            if config.AutoPlant then
                local plot = getPlayerPlot()
                if plot then
                    for _, tile in ipairs(plot:GetDescendants()) do
                        if tile.Name == "Dirt" or tile.Name == "PlotTile" or tile.Name == "Tile" then
                            local isEmpty = tile:GetAttribute("Empty") == true or tile:GetAttribute("Occupied") == false or #tile:GetChildren() == 0
                            if isEmpty then
                                local seedTool = nil
                                for _, seedName in ipairs(config.SelectedSeeds) do
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
                                
                                if seedTool then
                                    pcall(function() LocalPlayer.Character.Humanoid:EquipTool(seedTool) end)
                                    task.wait(0.05)
                                    
                                    local fired = false
                                    if Networking and Networking.Plant and Networking.Plant.PlantSeed then
                                        fired = fireNetworkEvent(Networking.Plant.PlantSeed, tile, seedTool.Name)
                                    end
                                    
                                    if not fired then
                                        triggerInteraction(tile)
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
                local plot = getPlayerPlot()
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
                                    if Networking and Networking.Garden and Networking.Garden.CollectFruit then
                                        fired = fireNetworkEvent(Networking.Garden.CollectFruit, fruit)
                                    end
                                    if not fired then
                                        triggerInteraction(fruit)
                                    end
                                end
                            else
                                local fired = false
                                if Networking and Networking.Garden and Networking.Garden.CollectFruit then
                                    fired = fireNetworkEvent(Networking.Garden.CollectFruit, plant)
                                end
                                if not fired then
                                    triggerInteraction(plant)
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
                if Networking and Networking.NPCS and Networking.NPCS.SellAll then
                    fired = fireNetworkEvent(Networking.NPCS.SellAll)
                end
                
                -- Jika bypass jaringan gagal, gunakan interaksi fisik di SellArea/Merchant/Sell
                if not fired then
                    local sellPart = workspace:FindFirstChild("SellArea", true) 
                        or workspace:FindFirstChild("Merchant", true) 
                        or workspace:FindFirstChild("Sell", true)
                    if sellPart then
                        triggerInteraction(sellPart)
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
                for _, seedName in ipairs(config.SelectedSeeds) do
                    if Networking and Networking.SeedShop and Networking.SeedShop.PurchaseSeed then
                        fireNetworkEvent(Networking.SeedShop.PurchaseSeed, seedName, 1)
                    end
                    task.wait(0.1) -- Jeda singkat antar pembelian benih
                end
            end
            task.wait(1.5)
        end
    end)
    
    -- 5. Auto Spray Mutation Loop
    task.spawn(function()
        while true do
            if config.AutoSpray then
                local plot = getPlayerPlot()
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
                                            if Networking and Networking.SprayService and Networking.SprayService.TrySpray then
                                                fireNetworkEvent(Networking.SprayService.TrySpray, fruit)
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
                local plot = getPlayerPlot()
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
                                    if Networking and Networking.WateringCan and Networking.WateringCan.UseWateringCan then
                                        fired = fireNetworkEvent(Networking.WateringCan.UseWateringCan, tile)
                                    end
                                    if not fired then
                                        triggerInteraction(tile)
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
    
    print("[SpeedHubX] Gameplay loops initialized.")
    
    -- ----------------------------------------------------
    -- DEKORASI FAIL-SAFE (UICorner & UIStroke)
    -- ----------------------------------------------------
    local function addCorner(parent, radius)
        local success, corner = pcall(function()
            local c = Instance.new("UICorner")
            c.CornerRadius = UDim.new(0, radius)
            c.Parent = parent
            return c
        end)
        return success and corner or nil
    end
    
    local function addStroke(parent, color, thickness)
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
    
    -- ----------------------------------------------------
    -- LIBRARY PANEL UTAMA (ModernUI)
    -- ----------------------------------------------------
    local ModernUI = {}
    ModernUI.__index = ModernUI
    
    function ModernUI:CreateWindow(titleText)
        print("[SpeedHubX] Creating Window elements...")
        local window = {
            Tabs = {},
            ActiveTab = nil,
            Visible = true
        }
        
        -- 1. ScreenGui Utama
        local ScreenGui = Instance.new("ScreenGui")
        ScreenGui.Name = "SpeedHubX_ModernGUI"
        ScreenGui.ResetOnSpawn = false
        ScreenGui.Parent = PlayerGui
        window.ScreenGui = ScreenGui
        
        -- 2. Frame Utama (Responsive 420x260)
        local MainFrame = Instance.new("Frame")
        MainFrame.Size = UDim2.new(0, 420, 0, 260)
        MainFrame.Position = UDim2.new(0.5, -210, 0.5, -130)
        MainFrame.BackgroundColor3 = Color3.fromRGB(13, 14, 18) -- Charcoal-black
        MainFrame.BorderSizePixel = 0
        MainFrame.Active = true
        MainFrame.Parent = ScreenGui
        window.MainFrame = MainFrame
        addCorner(MainFrame, 8)
        addStroke(MainFrame, Color3.fromRGB(0, 180, 255), 1.5) -- Cyan outline
        
        -- 3. Header / Title Bar
        local Header = Instance.new("Frame")
        Header.Size = UDim2.new(1, 0, 0, 32)
        Header.BackgroundColor3 = Color3.fromRGB(24, 26, 32)
        Header.BorderSizePixel = 0
        Header.Parent = MainFrame
        addCorner(Header, 8)
        
        -- Label Judul
        local TitleLabel = Instance.new("TextLabel")
        TitleLabel.Size = UDim2.new(0.8, 0, 1, 0)
        TitleLabel.Position = UDim2.new(0.04, 0, 0, 0)
        TitleLabel.BackgroundTransparency = 1
        TitleLabel.Text = titleText or "Speed Hub X"
        TitleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
        TitleLabel.TextSize = 12
        TitleLabel.Font = Enum.Font.GothamBold
        TitleLabel.TextXAlignment = Enum.TextXAlignment.Left
        TitleLabel.Parent = Header
        
        -- Tombol Tutup (Close Button "X")
        local CloseBtn = Instance.new("TextButton")
        CloseBtn.Size = UDim2.new(0, 22, 0, 22)
        CloseBtn.Position = UDim2.new(0.93, 0, 0.15, 0)
        CloseBtn.BackgroundColor3 = Color3.fromRGB(255, 60, 100) -- Red
        CloseBtn.Text = "X"
        CloseBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
        CloseBtn.TextSize = 10
        CloseBtn.Font = Enum.Font.GothamBold
        CloseBtn.Parent = Header
        addCorner(CloseBtn, 5)
        
        -- 4. Sidebar (Navigasi Kiri)
        local Sidebar = Instance.new("ScrollingFrame")
        Sidebar.Size = UDim2.new(0, 95, 1, -32)
        Sidebar.Position = UDim2.new(0, 0, 0, 32)
        Sidebar.BackgroundColor3 = Color3.fromRGB(18, 19, 24)
        Sidebar.BorderSizePixel = 0
        Sidebar.ScrollBarThickness = 0
        Sidebar.CanvasSize = UDim2.new(0, 0, 0, 0)
        Sidebar.Parent = MainFrame
        
        local SidebarLayout = Instance.new("UIListLayout")
        SidebarLayout.Padding = UDim.new(0, 3)
        SidebarLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
        SidebarLayout.SortOrder = Enum.SortOrder.LayoutOrder
        SidebarLayout.Parent = Sidebar
        
        local SidebarPadding = Instance.new("UIPadding")
        SidebarPadding.PaddingTop = UDim.new(0, 4)
        SidebarPadding.Parent = Sidebar
        
        -- 5. Content Container (Area Kanan)
        local Container = Instance.new("Frame")
        Container.Size = UDim2.new(1, -100, 1, -38)
        Container.Position = UDim2.new(0, 100, 0, 38)
        Container.BackgroundTransparency = 1
        Container.Parent = MainFrame
        
        -- 6. Tombol Melayang (Floating Action Button) - Draggable Kustom (Aman Sentuh)
        local Fab = Instance.new("TextButton")
        Fab.Size = UDim2.new(0, 38, 0, 38)
        Fab.Position = UDim2.new(0.02, 0, 0.15, 0)
        Fab.BackgroundColor3 = Color3.fromRGB(20, 20, 28)
        Fab.Text = "SH"
        Fab.TextColor3 = Color3.fromRGB(0, 180, 255)
        Fab.TextSize = 12
        Fab.Font = Enum.Font.GothamBold
        Fab.Active = true
        Fab.Parent = ScreenGui
        addCorner(Fab, 19)
        addStroke(Fab, Color3.fromRGB(0, 180, 255), 1.5)
        
        -- Aksi Klik Buka/Tutup (Menggunakan Event Ganda demi Kompatibilitas Maksimal)
        local function toggleMenu()
            window.Visible = not window.Visible
            MainFrame.Visible = window.Visible
        end
        
        local function closeMenu()
            window.Visible = false
            MainFrame.Visible = false
        end
        
        CloseBtn.Activated:Connect(closeMenu)
        CloseBtn.MouseButton1Click:Connect(closeMenu)
        
        Fab.Activated:Connect(toggleMenu)
        Fab.MouseButton1Click:Connect(toggleMenu)
        
        -- Sistem Drag Kustom agar Klik Tidak Terkunci di Delta Android
        local dragging = false
        local dragInput, dragStart, startPos
        
        local function update(input)
            local delta = input.Position - dragStart
            Fab.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
        
        Fab.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                dragging = true
                dragStart = input.Position
                startPos = Fab.Position
                
                input.Changed:Connect(function()
                    if input.UserInputState == Enum.UserInputState.End then
                        dragging = false
                    end
                end)
            end
        end)
        
        Fab.InputChanged:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
                dragInput = input
            end
        end)
        
        UserInputService.InputChanged:Connect(function(input)
            if input == dragInput and dragging then
                update(input)
            end
        end)
    
        -- Sistem Drag Kustom untuk Header Panel Utama
        local mainDragging = false
        local mainDragStart, mainStartPos
        
        Header.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                mainDragging = true
                mainDragStart = input.Position
                mainStartPos = MainFrame.Position
                
                input.Changed:Connect(function()
                    if input.UserInputState == Enum.UserInputState.End then
                        mainDragging = false
                    end
                end)
            end
        end)
        
        UserInputService.InputChanged:Connect(function(input)
            if mainDragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
                local delta = input.Position - mainDragStart
                MainFrame.Position = UDim2.new(mainStartPos.X.Scale, mainStartPos.X.Offset + delta.X, mainStartPos.Y.Scale, mainStartPos.Y.Offset + delta.Y)
            end
        end)
        
        -- Fungsi Membuat Tab Baru
        function window:CreateTab(tabName)
            local tab = {
                Active = false
            }
            
            -- Tombol Tab di Sidebar
            local TabBtn = Instance.new("TextButton")
            TabBtn.Size = UDim2.new(0.9, 0, 0, 26)
            TabBtn.BackgroundColor3 = Color3.fromRGB(24, 26, 32)
            TabBtn.Text = tabName or "Tab"
            TabBtn.TextColor3 = Color3.fromRGB(160, 160, 170)
            TabBtn.TextSize = 10
            TabBtn.Font = Enum.Font.GothamBold
            TabBtn.Parent = Sidebar
            addCorner(TabBtn, 5)
            addStroke(TabBtn, Color3.fromRGB(35, 38, 47), 1)
            
            -- ScrollArea Konten Tab
            local ScrollContent = Instance.new("ScrollingFrame")
            ScrollContent.Size = UDim2.new(1, 0, 1, 0)
            ScrollContent.BackgroundTransparency = 1
            ScrollContent.BorderSizePixel = 0
            ScrollContent.ScrollBarThickness = 3
            ScrollContent.Visible = false
            ScrollContent.Parent = Container
            
            local ContentLayout = Instance.new("UIListLayout")
            ContentLayout.Padding = UDim.new(0, 5)
            ContentLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
            ContentLayout.SortOrder = Enum.SortOrder.LayoutOrder
            ContentLayout.Parent = ScrollContent
            
            local ContentPadding = Instance.new("UIPadding")
            ContentPadding.PaddingTop = UDim.new(0, 2)
            ContentPadding.PaddingBottom = UDim.new(0, 5)
            ContentPadding.Parent = ScrollContent
            
            ContentLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
                ScrollContent.CanvasSize = UDim2.new(0, 0, 0, ContentLayout.AbsoluteContentSize.Y + 10)
            end)
            
            local function selectTab()
                window.ActiveTab = tab
                for _, t in ipairs(window.Tabs) do
                    t.ScrollContent.Visible = false
                    t.TabBtn.BackgroundColor3 = Color3.fromRGB(24, 26, 32)
                    t.TabBtn.TextColor3 = Color3.fromRGB(160, 160, 170)
                end
                ScrollContent.Visible = true
                TabBtn.BackgroundColor3 = Color3.fromRGB(0, 120, 220)
                TabBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
            end
            
            TabBtn.Activated:Connect(selectTab)
            TabBtn.MouseButton1Click:Connect(selectTab)
            
            tab.TabBtn = TabBtn
            tab.ScrollContent = ScrollContent
            
            -- 1. ADD TOGGLE (TOMBOL ON/OFF)
            function tab:AddToggle(toggleName, defaultVal, callback)
                local toggle = { Value = defaultVal or false }
                
                local Card = Instance.new("Frame")
                Card.Size = UDim2.new(0.95, 0, 0, 30)
                Card.BackgroundColor3 = Color3.fromRGB(20, 21, 27)
                Card.BorderSizePixel = 0
                Card.Parent = ScrollContent
                addCorner(Card, 5)
                addStroke(Card, Color3.fromRGB(30, 33, 41), 1)
                
                local Label = Instance.new("TextLabel")
                Label.Size = UDim2.new(0.7, 0, 1, 0)
                Label.Position = UDim2.new(0.04, 0, 0, 0)
                Label.BackgroundTransparency = 1
                Label.Text = toggleName or "Toggle"
                Label.TextColor3 = Color3.fromRGB(210, 210, 220)
                Label.TextSize = 10
                Label.Font = Enum.Font.Gotham
                Label.TextXAlignment = Enum.TextXAlignment.Left
                Label.Parent = Card
                
                -- Frame Tombol Geser (Switch)
                local Switch = Instance.new("TextButton")
                Switch.Size = UDim2.new(0, 36, 0, 18)
                Switch.Position = UDim2.new(0.85, 0, 0.2, 0)
                Switch.BackgroundColor3 = toggle.Value and Color3.fromRGB(0, 180, 100) or Color3.fromRGB(60, 60, 70)
                Switch.Text = ""
                Switch.Parent = Card
                addCorner(Switch, 9)
                
                local Circle = Instance.new("Frame")
                Circle.Size = UDim2.new(0, 12, 0, 12)
                Circle.Position = toggle.Value and UDim2.new(0.55, 0, 0.15, 0) or UDim2.new(0.1, 0, 0.15, 0)
                Circle.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
                Circle.BorderSizePixel = 0
                Circle.Parent = Switch
                addCorner(Circle, 6)
                
                local function updateToggle(fire)
                    local targetPos = toggle.Value and UDim2.new(0.55, 0, 0.15, 0) or UDim2.new(0.1, 0, 0.15, 0)
                    local targetCol = toggle.Value and Color3.fromRGB(0, 180, 100) or Color3.fromRGB(60, 60, 70)
                    
                    Circle:TweenPosition(targetPos, "Out", "Quad", 0.15, true)
                    Switch.BackgroundColor3 = targetCol
                    
                    if fire and callback then
                        pcall(callback, toggle.Value)
                    end
                end
                
                Switch.Activated:Connect(function()
                    toggle.Value = not toggle.Value
                    updateToggle(true)
                end)
                Switch.MouseButton1Click:Connect(function()
                    toggle.Value = not toggle.Value
                    updateToggle(true)
                end)
                
                updateToggle(false)
                return toggle
            end
            
            -- 2. ADD SLIDER (PENGGESER NILAI)
            function tab:AddSlider(sliderName, min, max, defaultVal, callback)
                local slider = { Value = defaultVal or min }
                
                local Card = Instance.new("Frame")
                Card.Size = UDim2.new(0.95, 0, 0, 38)
                Card.BackgroundColor3 = Color3.fromRGB(20, 21, 27)
                Card.BorderSizePixel = 0
                Card.Parent = ScrollContent
                addCorner(Card, 5)
                addStroke(Card, Color3.fromRGB(30, 33, 41), 1)
                
                local Label = Instance.new("TextLabel")
                Label.Size = UDim2.new(0.5, 0, 0, 18)
                Label.Position = UDim2.new(0.04, 0, 0, 2)
                Label.BackgroundTransparency = 1
                Label.Text = sliderName or "Slider"
                Label.TextColor3 = Color3.fromRGB(210, 210, 220)
                Label.TextSize = 10
                Label.Font = Enum.Font.Gotham
                Label.TextXAlignment = Enum.TextXAlignment.Left
                Label.Parent = Card
                
                local ValLabel = Instance.new("TextLabel")
                ValLabel.Size = UDim2.new(0.4, 0, 0, 18)
                ValLabel.Position = UDim2.new(0.56, 0, 0, 2)
                ValLabel.BackgroundTransparency = 1
                ValLabel.Text = tostring(slider.Value)
                ValLabel.TextColor3 = Color3.fromRGB(0, 180, 255)
                ValLabel.TextSize = 10
                ValLabel.Font = Enum.Font.GothamBold
                ValLabel.TextXAlignment = Enum.TextXAlignment.Right
                ValLabel.Parent = Card
                
                -- Bar Slider
                local SlideBar = Instance.new("Frame")
                SlideBar.Size = UDim2.new(0.92, 0, 0, 4)
                SlideBar.Position = UDim2.new(0.04, 0, 0, 24)
                SlideBar.BackgroundColor3 = Color3.fromRGB(45, 48, 58)
                SlideBar.BorderSizePixel = 0
                SlideBar.Parent = Card
                addCorner(SlideBar, 2)
                
                local Fill = Instance.new("Frame")
                local pct = math.clamp((slider.Value - min) / (max - min), 0, 1)
                Fill.Size = UDim2.new(pct, 0, 1, 0)
                Fill.BackgroundColor3 = Color3.fromRGB(0, 180, 255)
                Fill.BorderSizePixel = 0
                Fill.Parent = SlideBar
                addCorner(Fill, 2)
                
                local Trigger = Instance.new("TextButton")
                Trigger.Size = UDim2.new(1, 0, 3, 0)
                Trigger.Position = UDim2.new(0, 0, -1, 0)
                Trigger.BackgroundTransparency = 1
                Trigger.Text = ""
                Trigger.Parent = SlideBar
                
                local isDragging = false
                
                local function updateSlider(input)
                    local absPos = SlideBar.AbsolutePosition
                    local absSize = SlideBar.AbsoluteSize
                    local inputX = input.Position.X
                    local newPct = math.clamp((inputX - absPos.X) / absSize.X, 0, 1)
                    
                    local val = math.round(min + newPct * (max - min))
                    slider.Value = val
                    ValLabel.Text = tostring(val)
                    Fill.Size = UDim2.new(newPct, 0, 1, 0)
                    
                    if callback then
                        pcall(callback, val)
                    end
                end
                
                Trigger.InputBegan:Connect(function(input)
                    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                        isDragging = true
                        updateSlider(input)
                    end
                end)
                
                UserInputService.InputChanged:Connect(function(input)
                    if isDragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
                        updateSlider(input)
                    end
                end)
                
                UserInputService.InputEnded:Connect(function(input)
                    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                        isDragging = false
                    end
                end)
                
                pcall(callback, slider.Value)
                return slider
            end
            
            -- 3. ADD DROPDOWN (PILIHAN MENU)
            function tab:AddDropdown(ddName, optionsList, defaultVal, callback)
                local dd = {
                    Value = defaultVal or optionsList[1] or "",
                    Open = false
                }
                
                local Card = Instance.new("Frame")
                Card.Size = UDim2.new(0.95, 0, 0, 30)
                Card.BackgroundColor3 = Color3.fromRGB(20, 21, 27)
                Card.BorderSizePixel = 0
                Card.ClipsDescendants = true
                Card.Parent = ScrollContent
                addCorner(Card, 5)
                addStroke(Card, Color3.fromRGB(30, 33, 41), 1)
                
                local Label = Instance.new("TextLabel")
                Label.Size = UDim2.new(0.5, 0, 0, 30)
                Label.Position = UDim2.new(0.04, 0, 0, 0)
                Label.BackgroundTransparency = 1
                Label.Text = ddName or "Dropdown"
                Label.TextColor3 = Color3.fromRGB(210, 210, 220)
                Label.TextSize = 10
                Label.Font = Enum.Font.Gotham
                Label.TextXAlignment = Enum.TextXAlignment.Left
                Label.Parent = Card
                
                local OpenBtn = Instance.new("TextButton")
                OpenBtn.Size = UDim2.new(0, 90, 0, 20)
                OpenBtn.Position = UDim2.new(0.72, 0, 0.15, 0)
                OpenBtn.BackgroundColor3 = Color3.fromRGB(28, 30, 38)
                OpenBtn.Text = dd.Value .. " ▼"
                OpenBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
                OpenBtn.TextSize = 9
                OpenBtn.Font = Enum.Font.Gotham
                OpenBtn.Parent = Card
                addCorner(OpenBtn, 4)
                addStroke(OpenBtn, Color3.fromRGB(45, 48, 58), 1)
                
                local ListContainer = Instance.new("Frame")
                ListContainer.Size = UDim2.new(0.92, 0, 0, 0)
                ListContainer.Position = UDim2.new(0.04, 0, 0, 32)
                ListContainer.BackgroundTransparency = 1
                ListContainer.Visible = false
                ListContainer.Parent = Card
                
                local ListLayout = Instance.new("UIListLayout")
                ListLayout.Padding = UDim.new(0, 2)
                ListLayout.SortOrder = Enum.SortOrder.LayoutOrder
                ListLayout.Parent = ListContainer
                
                local function toggleDD()
                    dd.Open = not dd.Open
                    if dd.Open then
                        ListContainer.Visible = true
                        local targetHeight = #optionsList * 22 + 6
                        Card.Size = UDim2.new(0.95, 0, 0, 34 + targetHeight)
                        ListContainer.Size = UDim2.new(0.92, 0, 0, targetHeight)
                    else
                        Card.Size = UDim2.new(0.95, 0, 0, 30)
                        ListContainer.Size = UDim2.new(0.92, 0, 0, 0)
                        task.delay(0.1, function()
                            if not dd.Open then ListContainer.Visible = false end
                        end)
                    end
                end
                
                OpenBtn.Activated:Connect(toggleDD)
                OpenBtn.MouseButton1Click:Connect(toggleDD)
                
                for _, opt in ipairs(optionsList) do
                    local OptBtn = Instance.new("TextButton")
                    OptBtn.Size = UDim2.new(1, 0, 0, 20)
                    OptBtn.BackgroundColor3 = Color3.fromRGB(24, 26, 32)
                    OptBtn.Text = opt
                    OptBtn.TextColor3 = Color3.fromRGB(180, 180, 190)
                    OptBtn.TextSize = 9
                    OptBtn.Font = Enum.Font.Gotham
                    OptBtn.Parent = ListContainer
                    addCorner(OptBtn, 3)
                    
                    OptBtn.Activated:Connect(function()
                        dd.Value = opt
                        OpenBtn.Text = opt .. " ▼"
                        toggleDD()
                        if callback then
                            pcall(callback, opt)
                        end
                    end)
                    OptBtn.MouseButton1Click:Connect(function()
                        dd.Value = opt
                        OpenBtn.Text = opt .. " ▼"
                        toggleDD()
                        if callback then
                            pcall(callback, opt)
                        end
                    end)
                end
                
                pcall(callback, dd.Value)
                return dd
            end
            
            -- 4. ADD PARAGRAPH (INFO/TEKS)
            function tab:AddParagraph(pTitle, pText)
                local Card = Instance.new("Frame")
                Card.Size = UDim2.new(0.95, 0, 0, 42)
                Card.BackgroundColor3 = Color3.fromRGB(18, 19, 24)
                Card.BorderSizePixel = 0
                Card.Parent = ScrollContent
                addCorner(Card, 5)
                addStroke(Card, Color3.fromRGB(30, 33, 41), 1)
                
                local Title = Instance.new("TextLabel")
                Title.Size = UDim2.new(0.92, 0, 0, 16)
                Title.Position = UDim2.new(0.04, 0, 0, 2)
                Title.BackgroundTransparency = 1
                Title.Text = pTitle or ""
                Title.TextColor3 = Color3.fromRGB(255, 255, 255)
                Title.TextSize = 10
                Title.Font = Enum.Font.GothamBold
                Title.TextXAlignment = Enum.TextXAlignment.Left
                Title.Parent = Card
                
                local Content = Instance.new("TextLabel")
                Content.Size = UDim2.new(0.92, 0, 0, 20)
                Content.Position = UDim2.new(0.04, 0, 0, 18)
                Content.BackgroundTransparency = 1
                Content.Text = pText or ""
                Content.TextColor3 = Color3.fromRGB(150, 150, 160)
                Content.TextSize = 9
                Content.Font = Enum.Font.Gotham
                Content.TextXAlignment = Enum.TextXAlignment.Left
                Content.TextYAlignment = Enum.TextYAlignment.Top
                Content.TextWrapped = true
                local para = {}
                function para:SetTitle(t)
                    Title.Text = t
                end
                function para:SetText(t)
                    Content.Text = t
                end
                return para
            end
    
            -- 5. ADD LOGVIEWER (KHUSUS TAB LOGS)
            function tab:AddLogViewer()
                local LogFrame = Instance.new("ScrollingFrame")
                LogFrame.Size = UDim2.new(0.96, 0, 0.94, 0)
                LogFrame.BackgroundColor3 = Color3.fromRGB(10, 10, 14)
                LogFrame.BorderSizePixel = 0
                LogFrame.ScrollBarThickness = 4
                LogFrame.CanvasSize = UDim2.new(0, 0, 0, 1000)
                LogFrame.Parent = ScrollContent
                addCorner(LogFrame, 5)
                addStroke(LogFrame, Color3.fromRGB(25, 25, 30), 1)
                
                local LogLabel = Instance.new("TextLabel")
                LogLabel.Size = UDim2.new(0.96, 0, 0.98, 0)
                LogLabel.Position = UDim2.new(0.02, 0, 0.01, 0)
                LogLabel.BackgroundTransparency = 1
                LogLabel.TextColor3 = Color3.fromRGB(130, 240, 255)
                LogLabel.TextSize = 8
                LogLabel.Font = Enum.Font.Code
                LogLabel.TextXAlignment = Enum.TextXAlignment.Left
                LogLabel.TextYAlignment = Enum.TextYAlignment.Top
                LogLabel.TextWrapped = true
                LogLabel.Parent = LogFrame
                
                local function refreshLogs()
                    local txt = ""
                    local limit = math.max(1, #logMessages - 40)
                    for i = limit, #logMessages do
                        txt = txt .. logMessages[i] .. "\n"
                    end
                    LogLabel.Text = txt
                    
                    -- Auto scroll ke bawah
                    local height = LogLabel.TextBounds.Y
                    LogFrame.CanvasSize = UDim2.new(0, 0, 0, height + 20)
                    LogFrame.CanvasPosition = Vector2.new(0, math.max(0, height - LogFrame.AbsoluteSize.Y + 20))
                end
                
                onLogAdded = function(msg)
                    pcall(refreshLogs)
                end
                
                pcall(refreshLogs)
            end
            
            table.insert(window.Tabs, tab)
            if #window.Tabs == 1 then
                selectTab()
            end
            
            return tab
        end
        
        print("[SpeedHubX] Window instance created successfully.")
        return window
    end
    
    print("[SpeedHubX] Initializing tabs and components...")
    local Window = ModernUI:CreateWindow("Speed Hub X | Grow a Garden 2")
    
    -- Tab 1: Farming
    local FarmTab = Window:CreateTab("Auto Farm")
    FarmTab:AddToggle("Auto Plant (Tanam)", false, function(v)
        config.AutoPlant = v
    end)
    FarmTab:AddToggle("Auto Harvest (Panen)", false, function(v)
        config.AutoHarvest = v
    end)
    FarmTab:AddToggle("Auto Water (Siram)", false, function(v)
        config.AutoWater = v
    end)
    FarmTab:AddToggle("Auto sell all (semua buah d inventory)", false, function(v)
        config.AutoSell = v
    end)
    
    -- Tab 2: Toko Benih
    local ShopTab = Window:CreateTab("Toko Benih")
    
    ShopTab:AddToggle("Auto Beli Benih (Global)", false, function(v)
        config.AutoBuySeeds = v
    end)
    
    ShopTab:AddParagraph("Pilih Benih yang Ingin Dibeli & Ditanam", "Silakan nyalakan/matikan saklar benih di bawah ini.")
    
    local seedsList = {
        {"Carrot", "Carrot (Wortel) - Common"},
        {"Strawberry", "Strawberry (Stroberi) - Common"},
        {"Blueberry", "Blueberry (Bluberi) - Common"},
        {"Tomato", "Tomato (Tomat) - Uncommon"},
        {"Apple", "Apple (Apel) - Uncommon"},
        {"Tulip", "Tulip - Uncommon"},
        {"Corn", "Corn (Jagung) - Rare"},
        {"Cactus", "Cactus (Kaktus) - Rare"},
        {"Pineapple", "Pineapple (Nanas) - Rare"},
        {"Bamboo", "Bamboo (Bambu) - Rare"},
        {"Mushroom", "Mushroom (Jamur) - Epic"},
        {"Green Bean", "Green Bean (Buncis) - Epic"},
        {"Banana", "Banana (Pisang) - Epic"},
        {"Grape", "Grape (Anggur) - Epic"},
        {"Coconut", "Coconut (Kelapa) - Epic"},
        {"Mango", "Mango (Mangga) - Epic"},
        {"Acorn", "Acorn (Kenari) - Legendary"},
        {"Cherry", "Cherry (Ceri) - Legendary"},
        {"Dragon Fruit", "Dragon Fruit (Buah Naga) - Legendary"},
        {"Sunflower", "Sunflower (Bunga Matahari) - Legendary"},
        {"Pomegranate", "Pomegranate (Delima) - Mythic"},
        {"Poison Apple", "Poison Apple (Apel Beracun) - Mythic"},
        {"Venus Fly Trap", "Venus Fly Trap - Mythic"},
        {"Moon Bloom", "Moon Bloom - Super"},
        {"Dragon's Breath", "Dragon's Breath - Super"},
        {"Gold", "Gold (Emas) - Mutation"},
        {"Rainbow", "Rainbow (Pelangi) - Mutation"}
    }
    
    for _, seedInfo in ipairs(seedsList) do
        local seedKey = seedInfo[1]
        local seedLabel = seedInfo[2]
        ShopTab:AddToggle(seedLabel, config.SelectedSeeds[seedKey] or false, function(v)
            config.SelectedSeeds[seedKey] = v
        end)
    end
    
    -- Tab 3: Mutations (Spray)
    local MutationTab = Window:CreateTab("Auto Spray")
    MutationTab:AddToggle("Auto Spray (Mutasi)", false, function(v)
        config.AutoSpray = v
    end)
    MutationTab:AddDropdown("Pilih Mutasi", {"Choc", "Overgrown", "Gold", "Rainbow", "Celestial", "Frozen", "Plasma"}, "Choc", function(v)
        if not table.find(config.SelectedMutations, v) then
            table.insert(config.SelectedMutations, v)
        end
    end)
    
    -- Tab 4: Player Mods
    local PlayerTab = Window:CreateTab("Player Mods")
    PlayerTab:AddSlider("WalkSpeed", 16, 150, 16, function(v)
        config.WalkSpeed = v
        pcall(function()
            if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
                LocalPlayer.Character.Humanoid.WalkSpeed = v
            end
        end)
    end)
    PlayerTab:AddSlider("JumpPower", 50, 300, 50, function(v)
        config.JumpPower = v
        pcall(function()
            if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
                LocalPlayer.Character.Humanoid.JumpPower = v
            end
        end)
    end)
    PlayerTab:AddToggle("Infinite Jump", false, function(v)
        config.InfiniteJump = v
    end)
    
    -- Tab 5: Logs (Diagnostic Live Console)
    local LogTab = Window:CreateTab("System Logs")
    LogTab:AddLogViewer()
    
    -- Tab 6: Credits
    local CreditsTab = Window:CreateTab("Credits")
    CreditsTab:AddParagraph("Dibuat Oleh", "Antigravity AI (Pair Programming dengan Anda)")
    CreditsTab:AddParagraph("UI Version", "v2.2 Debug Cyberpunk Offline UI")
    CreditsTab:AddParagraph("Executor Kompatibilitas", "Delta Executor (100% Offline UI Mode)")

    -- ----------------------------------------------------
    -- ADDITIONAL SERVICES (ANTI-AFK & EVENT BINDINGS)
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
    if config.AntiAFK then
        local VirtualUser = nil
        pcall(function() VirtualUser = game:GetService("VirtualUser") end)
        if VirtualUser then
            LocalPlayer.Idled:Connect(function()
                pcall(function()
                    VirtualUser:CaptureController()
                    VirtualUser:ClickButton2(Vector2.new(0, 0))
                    print("[SpeedHubX] Mencegah diskoneksi AFK!")
                end)
            end)
        end
    end
    
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
    
    print("[SpeedHubX] Modern Cyberpunk UI v2.2 successfully rendered!")
end)

-- ----------------------------------------------------
-- FALLBACK DIAGNOSTIC RENDERER (BILA INISIALISASI ERROR)
-- ----------------------------------------------------
if not initSuccess then
    warn("[SpeedHubX] Fatal Error saat inisialisasi: " .. tostring(initError))
    
    pcall(function()
        local Players = game:GetService("Players")
        local LocalPlayer = Players.LocalPlayer
        local PlayerGui = LocalPlayer:FindFirstChildOfClass("PlayerGui") or LocalPlayer:WaitForChild("PlayerGui", 5)
        
        local fallbackScreen = Instance.new("ScreenGui")
        fallbackScreen.Name = "SpeedHubX_Fallback"
        fallbackScreen.ResetOnSpawn = false
        fallbackScreen.Parent = PlayerGui
        
        local Frame = Instance.new("Frame")
        Frame.Size = UDim2.new(0, 320, 0, 180)
        Frame.Position = UDim2.new(0.5, -160, 0.5, -90)
        Frame.BackgroundColor3 = Color3.fromRGB(30, 15, 15)
        Frame.BorderSizePixel = 1
        Frame.BorderColor3 = Color3.fromRGB(255, 60, 60)
        Frame.Active = true
        Frame.Parent = fallbackScreen
        
        local corner = Instance.new("UICorner")
        corner.CornerRadius = UDim.new(0, 8)
        corner.Parent = Frame
        
        local Title = Instance.new("TextLabel")
        Title.Size = UDim2.new(1, 0, 0, 24)
        Title.BackgroundColor3 = Color3.fromRGB(50, 15, 15)
        Title.Text = " Speed Hub X - Critical Initialization Error!"
        Title.TextColor3 = Color3.fromRGB(255, 255, 255)
        Title.TextSize = 10
        Title.Font = Enum.Font.GothamBold
        Title.TextXAlignment = Enum.TextXAlignment.Left
        Title.Parent = Frame
        
        local titleCorner = Instance.new("UICorner")
        titleCorner.CornerRadius = UDim.new(0, 8)
        titleCorner.Parent = Title
        
        local CloseBtn = Instance.new("TextButton")
        CloseBtn.Size = UDim2.new(0, 18, 0, 18)
        CloseBtn.Position = UDim2.new(0.93, 0, 0.12, 0)
        CloseBtn.BackgroundColor3 = Color3.fromRGB(255, 60, 60)
        CloseBtn.Text = "X"
        CloseBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
        CloseBtn.TextSize = 8
        CloseBtn.Font = Enum.Font.GothamBold
        CloseBtn.Parent = Title
        
        local btnCorner = Instance.new("UICorner")
        btnCorner.CornerRadius = UDim.new(0, 4)
        btnCorner.Parent = CloseBtn
        
        CloseBtn.Activated:Connect(function() fallbackScreen:Destroy() end)
        CloseBtn.MouseButton1Click:Connect(function() fallbackScreen:Destroy() end)
        
        local TextLabel = Instance.new("TextBox")
        TextLabel.Size = UDim2.new(0.92, 0, 0.74, 0)
        TextLabel.Position = UDim2.new(0.04, 0, 0.2, 0)
        TextLabel.BackgroundTransparency = 1
        TextLabel.TextColor3 = Color3.fromRGB(255, 200, 200)
        TextLabel.TextSize = 9
        TextLabel.Font = Enum.Font.Code
        TextLabel.TextXAlignment = Enum.TextXAlignment.Left
        TextLabel.TextYAlignment = Enum.TextYAlignment.Top
        TextLabel.MultiLine = true
        TextLabel.ClearTextOnFocus = false
        TextLabel.TextEditable = false
        TextLabel.Text = "CRITICAL INITIALIZATION FAILURE DETAILS:\n" .. tostring(initError)
        TextLabel.Parent = Frame
    end)
end
