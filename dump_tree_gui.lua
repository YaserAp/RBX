--[[
    Grow a Garden 2 - SharedModules Tree Dumper GUI
    
    Skrip ini mendata seluruh struktur folder dan file di dalam ReplicatedStorage.SharedModules
    dan menampilkannya di sebuah kotak teks di layar Anda yang bisa disalin langsung.
--]]

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Fungsi membuat tree teks
local function printTree(instance, depth)
    depth = depth or 0
    local prefix = string.rep("  ", depth)
    local content = prefix .. instance.Name .. " (" .. instance.ClassName .. ")\n"
    for _, child in ipairs(instance:GetChildren()) do
        content = content .. printTree(child, depth + 1)
    end
    return content
end

local sharedModules = ReplicatedStorage:FindFirstChild("SharedModules")
local treeText = ""

if sharedModules then
    treeText = printTree(sharedModules)
else
    treeText = "SharedModules tidak ditemukan di ReplicatedStorage!"
end

-- 1. Membuat GUI di Layar
local oldGui = LocalPlayer:WaitForChild("PlayerGui"):FindFirstChild("TreeDumperGUI")
if oldGui then oldGui:Destroy() end

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "TreeDumperGUI"
ScreenGui.ResetOnSpawn = false
ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")

local MainFrame = Instance.new("Frame")
MainFrame.Size = UDim2.new(0, 480, 0, 380)
MainFrame.Position = UDim2.new(0.25, 0, 0.2, 0)
MainFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
MainFrame.BorderSizePixel = 2
MainFrame.BorderColor3 = Color3.fromRGB(255, 165, 0) -- Orange Border
MainFrame.Active = true
MainFrame.Draggable = true
MainFrame.Parent = ScreenGui

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, 0, 0.12, 0)
Title.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
Title.Text = "SharedModules Folder Structure"
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

local TextBox = Instance.new("TextBox")
TextBox.Size = UDim2.new(0.94, 0, 0.7, 0)
TextBox.Position = UDim2.new(0.03, 0, 0.15, 0)
TextBox.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
TextBox.TextColor3 = Color3.fromRGB(0, 255, 127)
TextBox.Text = treeText
TextBox.TextSize = 11
TextBox.Font = Enum.Font.Code
TextBox.TextXAlignment = Enum.TextXAlignment.Left
TextBox.TextYAlignment = Enum.TextYAlignment.Top
TextBox.ClearTextOnFocus = false
TextBox.MultiLine = true
TextBox.TextEditable = false
TextBox.Parent = MainFrame

local CopyBtn = Instance.new("TextButton")
CopyBtn.Size = UDim2.new(0.94, 0, 0.1, 0)
CopyBtn.Position = UDim2.new(0.03, 0, 0.87, 0)
CopyBtn.BackgroundColor3 = Color3.fromRGB(255, 165, 0)
CopyBtn.Text = "Copy Structure to Clipboard"
CopyBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
CopyBtn.TextSize = 14
CopyBtn.Font = Enum.Font.SourceSansBold
CopyBtn.Parent = MainFrame

CopyBtn.MouseButton1Click:Connect(function()
    if setclipboard then
        setclipboard(treeText)
        CopyBtn.Text = "Copied!"
        CopyBtn.BackgroundColor3 = Color3.fromRGB(0, 150, 100)
        task.wait(1.5)
        CopyBtn.Text = "Copy Structure to Clipboard"
        CopyBtn.BackgroundColor3 = Color3.fromRGB(255, 165, 0)
    else
        CopyBtn.Text = "setclipboard not supported by executor"
    end
end)
