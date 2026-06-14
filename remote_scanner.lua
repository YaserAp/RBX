--[[
    Roblox Remote Event Scanner & Dumper (Delta Executor Compatible)
    
    Fitur:
    1. Otomatis memindai semua RemoteEvent dan RemoteFunction di ReplicatedStorage.
    2. Menampilkan daftar Remote di layar (GUI Scrolling Frame) agar mudah dilihat.
    3. Menyediakan tombol "Copy" di setiap remote untuk menyalin jalurnya ke clipboard (menggunakan setclipboard).
    4. Menyimpan daftar lengkap ke dalam file "grow_garden_remotes.txt" di folder workspace executor Anda.
--]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

-- Fungsi Pemindaian
local function scanRemotes()
    local remotes = {}
    
    -- Pindai ReplicatedStorage
    for _, obj in ipairs(ReplicatedStorage:GetDescendants()) do
        if obj:IsA("RemoteEvent") or obj:IsA("RemoteFunction") then
            table.insert(remotes, {
                Name = obj.Name,
                FullName = obj:GetFullName(),
                ClassName = obj.ClassName
            })
        end
    end
    
    return remotes
end

local foundRemotes = scanRemotes()

-- 1. Simpan ke File Workspace Executor (Menggunakan writefile)
local fileContent = "=== GROW A GARDEN 2 REMOTE DUMP ===\n\n"
for _, r in ipairs(foundRemotes) do
    fileContent = fileContent .. string.format("[%s] %s\n", r.ClassName, r.FullName)
end

local success, err = pcall(function()
    if writefile then
        writefile("grow_garden_remotes.txt", fileContent)
        return true
    end
    return false
end)

-- 2. Membuat GUI untuk Menampilkan di Layar
local function showScannerGUI()
    -- Hapus GUI lama jika ada
    local oldGui = LocalPlayer:WaitForChild("PlayerGui"):FindFirstChild("RemoteScannerGUI")
    if oldGui then oldGui:Destroy() end
    
    local ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = "RemoteScannerGUI"
    ScreenGui.ResetOnSpawn = false
    ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")
    
    local MainFrame = Instance.new("Frame")
    MainFrame.Size = UDim2.new(0, 450, 0, 350)
    MainFrame.Position = UDim2.new(0.3, 0, 0.25, 0)
    MainFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
    MainFrame.BorderSizePixel = 2
    MainFrame.BorderColor3 = Color3.fromRGB(0, 255, 127)
    MainFrame.Active = true
    MainFrame.Draggable = true
    MainFrame.Parent = ScreenGui
    
    local Title = Instance.new("TextLabel")
    Title.Size = UDim2.new(1, 0, 0.12, 0)
    Title.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
    Title.Text = "Grow a Garden 2 - Remote Scanner (" .. tostring(#foundRemotes) .. " found)"
    Title.TextColor3 = Color3.fromRGB(255, 255, 255)
    Title.TextSize = 14
    Title.Font = Enum.Font.SourceSansBold
    Title.Parent = MainFrame
    
    -- Tombol Close
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
    Scroll.Size = UDim2.new(0.95, 0, 0.82, 0)
    Scroll.Position = UDim2.new(0.025, 0, 0.15, 0)
    Scroll.BackgroundTransparency = 1
    Scroll.CanvasSize = UDim2.new(0, 0, 0, #foundRemotes * 35)
    Scroll.ScrollBarThickness = 6
    Scroll.Parent = MainFrame
    
    local UIListLayout = Instance.new("UIListLayout")
    UIListLayout.Padding = UDim.new(0, 5)
    UIListLayout.Parent = Scroll
    
    -- Isi Scroll Frame dengan Remote yang ditemukan
    for i, r in ipairs(foundRemotes) do
        local ItemFrame = Instance.new("Frame")
        ItemFrame.Size = UDim2.new(0.98, 0, 0, 30)
        ItemFrame.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
        ItemFrame.BorderSizePixel = 0
        ItemFrame.Parent = Scroll
        
        local ClassLabel = Instance.new("TextLabel")
        ClassLabel.Size = UDim2.new(0.15, 0, 1, 0)
        ClassLabel.BackgroundTransparency = 1
        ClassLabel.Text = r.ClassName == "RemoteEvent" and "[RE]" or "[RF]"
        ClassLabel.TextColor3 = r.ClassName == "RemoteEvent" and Color3.fromRGB(92, 240, 247) or Color3.fromRGB(247, 92, 240)
        ClassLabel.TextSize = 11
        ClassLabel.Font = Enum.Font.SourceSansBold
        ClassLabel.Parent = ItemFrame
        
        local NameLabel = Instance.new("TextLabel")
        NameLabel.Size = UDim2.new(0.65, 0, 1, 0)
        NameLabel.Position = UDim2.new(0.15, 0, 0, 0)
        NameLabel.BackgroundTransparency = 1
        NameLabel.Text = r.Name
        NameLabel.TextColor3 = Color3.fromRGB(230, 230, 230)
        NameLabel.TextSize = 12
        NameLabel.TextXAlignment = Enum.TextXAlignment.Left
        NameLabel.Font = Enum.Font.SourceSans
        NameLabel.Parent = ItemFrame
        
        local CopyBtn = Instance.new("TextButton")
        CopyBtn.Size = UDim2.new(0.18, 0, 0.8, 0)
        CopyBtn.Position = UDim2.new(0.8, 0, 0.1, 0)
        CopyBtn.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
        CopyBtn.Text = "Copy Path"
        CopyBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
        CopyBtn.TextSize = 10
        CopyBtn.Font = Enum.Font.SourceSans
        CopyBtn.Parent = ItemFrame
        
        CopyBtn.MouseButton1Click:Connect(function()
            if setclipboard then
                setclipboard(r.FullName)
                CopyBtn.Text = "Copied!"
                CopyBtn.BackgroundColor3 = Color3.fromRGB(0, 150, 100)
                task.wait(1)
                CopyBtn.Text = "Copy Path"
                CopyBtn.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
            else
                CopyBtn.Text = "No Clipboard API"
            end
        end)
    end
    
    -- Notifikasi Sukses
    local notifyMsg = "Berhasil memindai " .. tostring(#foundRemotes) .. " Remote."
    if success then
        notifyMsg = notifyMsg .. " Hasil disimpan di grow_garden_remotes.txt"
    end
    
    print("[RemoteScanner] " .. notifyMsg)
end

-- Jalankan GUI
showScannerGUI()
