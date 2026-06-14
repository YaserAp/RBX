--[[
    Speed Hub X - Shop Data Locator
    Mencari lokasi penyimpanan data stok benih toko di game.
--]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

local logText = "=== SPEED HUB X - SHOP STOCK LOCATOR LOG ===\n\n"

local function log(txt)
    logText = logText .. tostring(txt) .. "\n"
    print("[ShopLocator] " .. tostring(txt))
end

-- Cari di PlayerGui
log("--- SEARCHING IN PLAYERGUI ---")
local playerGui = LocalPlayer:FindFirstChild("PlayerGui")
if playerGui then
    for _, descendant in ipairs(playerGui:GetDescendants()) do
        if descendant:IsA("TextLabel") or descendant:IsA("TextButton") then
            local text = descendant.Text
            if text:find("Carrot") or text:find("Strawberry") or text:find("Blueberry") or text:find("Stock") then
                log(string.format("Found Text: '%s' in GUI Object: %s (Path: %s)", text, descendant.ClassName, descendant:GetFullName()))
            end
        end
    end
else
    log("PlayerGui tidak ditemukan!")
end

-- Cari di ReplicatedStorage
log("\n--- SEARCHING IN REPLICATEDSTORAGE ---")
for _, descendant in ipairs(ReplicatedStorage:GetDescendants()) do
    if descendant:IsA("StringValue") or descendant:IsA("ObjectValue") or descendant:IsA("IntValue") then
        local name = descendant.Name
        local val = tostring(descendant.Value)
        if name:find("Carrot") or name:find("Seed") or val:find("Carrot") or val:find("Seed") then
            log(string.format("Found Value Object: Name='%s' | Val='%s' (Path: %s)", name, val, descendant:GetFullName()))
        end
    end
end

-- Cari di Workspace
log("\n--- SEARCHING IN WORKSPACE ---")
for _, descendant in ipairs(workspace:GetDescendants()) do
    if descendant.Name:find("SeedShop") or descendant.Name:find("Shop") or descendant.Name:find("Merchant") then
        log(string.format("Shop Object: Name='%s' | Class=%s (Path: %s)", descendant.Name, descendant.ClassName, descendant:GetFullName()))
        -- Cek jika ada objek di dalamnya
        for _, child in ipairs(descendant:GetChildren()) do
            log(string.format("  -> Child: '%s' | Class: %s", child.Name, child.ClassName))
        end
    end
end

-- Simpan ke file
if writefile then
    pcall(function()
        writefile("hasil_scan_toko.txt", logText)
    end)
    log("\nLOG DISIMPAN KE 'hasil_scan_toko.txt'")
else
    log("\nwritefile tidak didukung.")
end

-- GUI Sederhana
local oldGui = LocalPlayer:WaitForChild("PlayerGui"):FindFirstChild("ShopLocatorGUI")
if oldGui then oldGui:Destroy() end

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "ShopLocatorGUI"
ScreenGui.ResetOnSpawn = false
ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")

local MainFrame = Instance.new("Frame")
MainFrame.Size = UDim2.new(0, 480, 0, 350)
MainFrame.Position = UDim2.new(0.2, 0, 0.25, 0)
MainFrame.BackgroundColor3 = Color3.fromRGB(20, 30, 25)
MainFrame.BorderSizePixel = 2
MainFrame.BorderColor3 = Color3.fromRGB(0, 255, 127)
MainFrame.Active = true
MainFrame.Draggable = true
MainFrame.Parent = ScreenGui

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, 0, 0.12, 0)
Title.BackgroundColor3 = Color3.fromRGB(30, 45, 35)
Title.Text = "Shop Stock Data Locator"
Title.TextColor3 = Color3.fromRGB(255, 255, 255)
Title.TextSize = 14
Title.Font = Enum.Font.SourceSansBold
Title.Parent = MainFrame

local CloseBtn = Instance.new("TextButton")
CloseBtn.Size = UDim2.new(0.1, 0, 1, 0)
CloseBtn.Position = UDim2.new(0.9, 0, 0, 0)
CloseBtn.BackgroundTransparency = 1
CloseBtn.Text = "X"
CloseBtn.TextColor3 = Color3.fromRGB(255, 100, 100)
CloseBtn.TextSize = 16
CloseBtn.Font = Enum.Font.SourceSansBold
CloseBtn.Parent = Title
CloseBtn.MouseButton1Click:Connect(function()
    ScreenGui:Destroy()
end)

local Scroll = Instance.new("ScrollingFrame")
Scroll.Size = UDim2.new(0.94, 0, 0.8, 0)
Scroll.Position = UDim2.new(0.03, 0, 0.15, 0)
Scroll.BackgroundColor3 = Color3.fromRGB(10, 15, 12)
Scroll.BorderSizePixel = 0
Scroll.ScrollBarThickness = 6
Scroll.Parent = MainFrame

local TextBox = Instance.new("TextBox")
TextBox.Size = UDim2.new(1, -10, 1, 0)
TextBox.Position = UDim2.new(0, 5, 0, 0)
TextBox.BackgroundTransparency = 1
TextBox.TextColor3 = Color3.fromRGB(150, 255, 200)
TextBox.Text = logText
TextBox.TextSize = 11
TextBox.Font = Enum.Font.Code
TextBox.TextXAlignment = Enum.TextXAlignment.Left
TextBox.TextYAlignment = Enum.TextYAlignment.Top
TextBox.ClearTextOnFocus = false
TextBox.MultiLine = true
TextBox.TextEditable = false
TextBox.Parent = Scroll

local _, lineCount = string.gsub(logText, "\n", "")
Scroll.CanvasSize = UDim2.new(0, 0, 0, math.max(300, lineCount * 16))
