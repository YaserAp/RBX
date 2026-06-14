--[[
    Speed Hub X - UI Library Module
    Mengimplementasikan library ModernUI Cyberpunk bertema Dark-Neon.
    Dioptimalkan secara penuh untuk Delta Executor (Mobile).
--]]

local SpeedHubX = shared.SpeedHubX or {}
shared.SpeedHubX = SpeedHubX

local utils = SpeedHubX.Utils
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local UserInputService = game:GetService("UserInputService")

-- Cari PlayerGui secara aman
local PlayerGui = nil
pcall(function() PlayerGui = LocalPlayer:FindFirstChildOfClass("PlayerGui") end)
if not PlayerGui then pcall(function() PlayerGui = LocalPlayer:WaitForChild("PlayerGui", 5) end) end
if not PlayerGui then pcall(function() PlayerGui = LocalPlayer.PlayerGui end) end

local ModernUI = {}
ModernUI.__index = ModernUI
SpeedHubX.UI = ModernUI

function ModernUI:CreateWindow(titleText)
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
    utils.addCorner(MainFrame, 8)
    utils.addStroke(MainFrame, Color3.fromRGB(0, 180, 255), 1.5) -- Cyan outline
    
    -- 3. Header / Title Bar
    local Header = Instance.new("Frame")
    Header.Size = UDim2.new(1, 0, 0, 32)
    Header.BackgroundColor3 = Color3.fromRGB(24, 26, 32)
    Header.BorderSizePixel = 0
    Header.Parent = MainFrame
    utils.addCorner(Header, 8)
    
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
    utils.addCorner(CloseBtn, 5)
    
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
    utils.addCorner(Fab, 19)
    utils.addStroke(Fab, Color3.fromRGB(0, 180, 255), 1.5)
    
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
        utils.addCorner(TabBtn, 5)
        utils.addStroke(TabBtn, Color3.fromRGB(35, 38, 47), 1)
        
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
            utils.addCorner(Card, 5)
            utils.addStroke(Card, Color3.fromRGB(30, 33, 41), 1)
            
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
            utils.addCorner(Switch, 9)
            
            local Circle = Instance.new("Frame")
            Circle.Size = UDim2.new(0, 12, 0, 12)
            Circle.Position = toggle.Value and UDim2.new(0.55, 0, 0.15, 0) or UDim2.new(0.1, 0, 0.15, 0)
            Circle.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
            Circle.BorderSizePixel = 0
            Circle.Parent = Switch
            utils.addCorner(Circle, 6)
            
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
            utils.addCorner(Card, 5)
            utils.addStroke(Card, Color3.fromRGB(30, 33, 41), 1)
            
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
            utils.addCorner(SlideBar, 2)
            
            local Fill = Instance.new("Frame")
            local pct = math.clamp((slider.Value - min) / (max - min), 0, 1)
            Fill.Size = UDim2.new(pct, 0, 1, 0)
            Fill.BackgroundColor3 = Color3.fromRGB(0, 180, 255)
            Fill.BorderSizePixel = 0
            Fill.Parent = SlideBar
            utils.addCorner(Fill, 2)
            
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
            utils.addCorner(Card, 5)
            utils.addStroke(Card, Color3.fromRGB(30, 33, 41), 1)
            
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
            utils.addCorner(OpenBtn, 4)
            utils.addStroke(OpenBtn, Color3.fromRGB(45, 48, 58), 1)
            
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
                utils.addCorner(OptBtn, 3)
                
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
            utils.addCorner(Card, 5)
            utils.addStroke(Card, Color3.fromRGB(30, 33, 41), 1)
            
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
            Content.Parent = Card
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
            utils.addCorner(LogFrame, 5)
            utils.addStroke(LogFrame, Color3.fromRGB(25, 25, 30), 1)
            
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
                local logMessages = SpeedHubX.LogMessages or {}
                local limit = math.max(1, #logMessages - 40)
                for i = limit, #logMessages do
                    txt = txt .. logMessages[i] .. "\n"
                end
                LogLabel.Text = txt
                
                local height = LogLabel.TextBounds.Y
                LogFrame.CanvasSize = UDim2.new(0, 0, 0, height + 20)
                LogFrame.CanvasPosition = Vector2.new(0, math.max(0, height - LogFrame.AbsoluteSize.Y + 20))
            end
            
            SpeedHubX.OnLogAdded = function(msg)
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
    
    return window
end

print("[SpeedHubX] UI Library successfully loaded.")
