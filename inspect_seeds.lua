--[[
    Speed Hub X - Seed & Shop Inspector
    Jalankan skrip ini di Delta Executor Anda untuk mengetahui nama persis benih 
    dan data toko yang digunakan oleh game.
--]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

local logText = "=== SPEED HUB X - SEED & SHOP INSPECTION ===\n\n"

local function log(txt)
    logText = logText .. tostring(txt) .. "\n"
    print("[SeedInspector] " .. tostring(txt))
end

-- 1. Inspect Backpack & Inventory Tools
log("--- CURRENT INVENTORY / BACKPACK TOOLS ---")
local backpack = LocalPlayer:FindFirstChild("Backpack")
if backpack then
    local tools = backpack:GetChildren()
    if #tools == 0 then
        log("Backpack kosong. Silakan beli beberapa benih terlebih dahulu agar kita bisa melihat nama itemnya.")
    else
        for _, tool in ipairs(tools) do
            log(string.format("Tool Name: '%s' | Class: %s", tool.Name, tool.ClassName))
        end
    end
else
    log("Backpack tidak ditemukan!")
end

local char = LocalPlayer.Character
if char then
    log("\n--- CHARACTER TOOLS (Equipped) ---")
    for _, child in ipairs(char:GetChildren()) do
        if child:IsA("Tool") then
            log(string.format("Equipped Tool: '%s'", child.Name))
        end
    end
end

-- 2. Inspect SharedModules.SeedData
log("\n--- REPLICATEDSTORAGE SEEDDATA MODULE ---")
local SharedModules = ReplicatedStorage:FindFirstChild("SharedModules")
if SharedModules then
    local SeedDataModule = SharedModules:FindFirstChild("SeedData")
    if SeedDataModule then
        local success, seedData = pcall(function()
            return require(SeedDataModule)
        end)
        if success and type(seedData) == "table" then
            log("Berhasil require SeedData. Daftar kunci (keys):")
            for k, v in pairs(seedData) do
                log(string.format("  Key: '%s' (Type: %s)", tostring(k), type(v)))
                if type(v) == "table" then
                    -- Tampilkan sub-keys jika ada
                    local count = 0
                    for subK, subV in pairs(v) do
                        count = count + 1
                        if count <= 5 then
                            log(string.format("    -> SubKey: '%s' (ValType: %s)", tostring(subK), type(subV)))
                        end
                    end
                    if count > 5 then
                        log(string.format("    -> ... dan %d subkeys lainnya", count - 5))
                    end
                end
            end
        else
            log("Gagal require SeedData atau return bukan table: " .. tostring(seedData))
        end
    else
        log("SeedData Module tidak ditemukan di SharedModules!")
    end
else
    log("SharedModules tidak ditemukan di ReplicatedStorage!")
end

-- 3. Inspect SeedShop & Stock (Jika ada di Workspace)
log("\n--- SEED SHOP IN WORKSPACE ---")
local shopFolder = workspace:FindFirstChild("SeedShop", true) 
    or workspace:FindFirstChild("Shop", true) 
    or workspace:FindFirstChild("Merchant", true)
if shopFolder then
    log(string.format("Menemukan objek Toko: '%s' (Path: %s)", shopFolder.Name, shopFolder:GetFullName()))
    log("Anak objek dari toko:")
    for _, child in ipairs(shopFolder:GetChildren()) do
        log(string.format("  Child: '%s' | Class: %s", child.Name, child.ClassName))
        -- Cek attributes
        local attrs = child:GetAttributes()
        for attrName, attrVal in pairs(attrs) do
            log(string.format("    Attribute: '%s' = %s", attrName, tostring(attrVal)))
        end
    end
else
    log("Objek Toko (SeedShop/Shop/Merchant) tidak ditemukan di Workspace.")
end

-- 4. Simpan ke berkas
if writefile then
    local success, err = pcall(function()
        writefile("hasil_inspect_seeds.txt", logText)
    end)
    if success then
        log("\nHASIL BERHASIL DISIMPAN KE: 'hasil_inspect_seeds.txt'")
    else
        log("\nGagal menyimpan file: " .. tostring(err))
    end
else
    log("\nwritefile tidak didukung oleh executor Anda.")
end

-- 5. Buat GUI Sederhana untuk menampilkan hasil
local oldGui = LocalPlayer:WaitForChild("PlayerGui"):FindFirstChild("SeedInspectorGUI")
if oldGui then oldGui:Destroy() end

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "SeedInspectorGUI"
ScreenGui.ResetOnSpawn = false
ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")

local MainFrame = Instance.new("Frame")
MainFrame.Size = UDim2.new(0, 450, 0, 350)
MainFrame.Position = UDim2.new(0.3, 0, 0.25, 0)
MainFrame.BackgroundColor3 = Color3.fromRGB(30, 20, 40)
MainFrame.BorderSizePixel = 2
MainFrame.BorderColor3 = Color3.fromRGB(180, 50, 250)
MainFrame.Active = true
MainFrame.Draggable = true
MainFrame.Parent = ScreenGui

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, 0, 0.12, 0)
Title.BackgroundColor3 = Color3.fromRGB(45, 30, 60)
Title.Text = "Speed Hub X - Seed & Shop Inspector"
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
Scroll.BackgroundColor3 = Color3.fromRGB(15, 10, 20)
Scroll.BorderSizePixel = 0
Scroll.ScrollBarThickness = 6
Scroll.Parent = MainFrame

local TextBox = Instance.new("TextBox")
TextBox.Size = UDim2.new(1, -10, 1, 0)
TextBox.Position = UDim2.new(0, 5, 0, 0)
TextBox.BackgroundTransparency = 1
TextBox.TextColor3 = Color3.fromRGB(220, 150, 255)
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
