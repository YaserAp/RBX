--[[
    Grow a Garden 2 - Packet Module Inspector GUI
    
    Skrip ini memindai fungsi dan properti di dalam ReplicatedStorage.SharedModules.Packet
    dan menampilkan hasilnya di layar agar Anda bisa menyalinnya dengan mudah.
--]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

local resultText = ""

local function inspectModule(moduleName, moduleInstance)
    resultText = resultText .. "=========================================\n"
    resultText = resultText .. "MODULE: " .. moduleName .. "\n"
    resultText = resultText .. "=========================================\n"
    
    local success, moduleTable = pcall(function()
        return require(moduleInstance)
    end)
    
    if not success then
        resultText = resultText .. "Gagal require: " .. tostring(moduleTable) .. "\n\n"
        return
    end
    
    if type(moduleTable) == "table" then
        for k, v in pairs(moduleTable) do
            resultText = resultText .. string.format("  [%s] = %s (%s)\n", tostring(k), tostring(v), type(v))
            if type(v) == "table" then
                for subK, subV in pairs(v) do
                    resultText = resultText .. string.format("    -> [%s] = %s (%s)\n", tostring(subK), tostring(subV), type(subV))
                end
            end
        end
        
        -- Cek metatable
        local mt = getmetatable(moduleTable)
        if mt then
            resultText = resultText .. "  --- Metatable ---\n"
            for k, v in pairs(mt) do
                resultText = resultText .. string.format("    MT: [%s] = %s (%s)\n", tostring(k), tostring(v), type(v))
            end
        end
    else
        resultText = resultText .. "Kembalian bukan table: " .. type(moduleTable) .. " (" .. tostring(moduleTable) .. ")\n"
    end
    resultText = resultText .. "\n"
end

-- Jalankan Inspeksi
local SharedModules = ReplicatedStorage:FindFirstChild("SharedModules")
if SharedModules then
    local Packet = SharedModules:FindFirstChild("Packet")
    if Packet then
        inspectModule("Packet", Packet)
    end
    
    local Networking = SharedModules:FindFirstChild("Networking")
    if Networking then
        inspectModule("Networking", Networking)
    end
else
    resultText = "SharedModules tidak ditemukan di ReplicatedStorage!"
end

-- 1. Membuat GUI di Layar
local oldGui = LocalPlayer:WaitForChild("PlayerGui"):FindFirstChild("ModuleInspectorGUI")
if oldGui then oldGui:Destroy() end

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "ModuleInspectorGUI"
ScreenGui.ResetOnSpawn = false
ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")

local MainFrame = Instance.new("Frame")
MainFrame.Size = UDim2.new(0, 480, 0, 380)
MainFrame.Position = UDim2.new(0.25, 0, 0.2, 0)
MainFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
MainFrame.BorderSizePixel = 2
MainFrame.BorderColor3 = Color3.fromRGB(0, 150, 255) -- Blue Border
MainFrame.Active = true
MainFrame.Draggable = true
MainFrame.Parent = ScreenGui

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, 0, 0.12, 0)
Title.BackgroundColor3 = Color3.fromRGB(35, 35, 40)
Title.Text = "Packet & Networking Module API Inspector"
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

-- TextBox di dalam ScrollingFrame
local Scroll = Instance.new("ScrollingFrame")
Scroll.Size = UDim2.new(0.94, 0, 0.7, 0)
Scroll.Position = UDim2.new(0.03, 0, 0.15, 0)
Scroll.BackgroundColor3 = Color3.fromRGB(15, 15, 18)
Scroll.BorderSizePixel = 0
Scroll.CanvasSize = UDim2.new(0, 0, 0, 2000) -- Canvas tinggi untuk text panjang
Scroll.ScrollBarThickness = 6
Scroll.Parent = MainFrame

local TextBox = Instance.new("TextBox")
TextBox.Size = UDim2.new(1, 0, 1, 0)
TextBox.BackgroundTransparency = 1
TextBox.TextColor3 = Color3.fromRGB(92, 240, 247)
TextBox.Text = resultText
TextBox.TextSize = 11
TextBox.Font = Enum.Font.Code
TextBox.TextXAlignment = Enum.TextXAlignment.Left
TextBox.TextYAlignment = Enum.TextYAlignment.Top
TextBox.ClearTextOnFocus = false
TextBox.MultiLine = true
TextBox.TextEditable = false
TextBox.Parent = Scroll

-- Hitung tinggi Canvas dinamis berdasarkan jumlah baris
local _, lineCount = string.gsub(resultText, "\n", "")
Scroll.CanvasSize = UDim2.new(0, 0, 0, math.max(300, lineCount * 18))

local CopyBtn = Instance.new("TextButton")
CopyBtn.Size = UDim2.new(0.94, 0, 0.1, 0)
CopyBtn.Position = UDim2.new(0.03, 0, 0.87, 0)
CopyBtn.BackgroundColor3 = Color3.fromRGB(0, 150, 255)
CopyBtn.Text = "Copy API Structure to Clipboard"
CopyBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
CopyBtn.TextSize = 14
CopyBtn.Font = Enum.Font.SourceSansBold
CopyBtn.Parent = MainFrame

CopyBtn.MouseButton1Click:Connect(function()
    if setclipboard then
        setclipboard(resultText)
        CopyBtn.Text = "Copied!"
        CopyBtn.BackgroundColor3 = Color3.fromRGB(0, 150, 100)
        task.wait(1.5)
        CopyBtn.Text = "Copy API Structure to Clipboard"
        CopyBtn.BackgroundColor3 = Color3.fromRGB(0, 150, 255)
    else
        CopyBtn.Text = "setclipboard not supported by executor"
    end
end)
