--[[
    Roblox Auto Buy Script Template (Educational & Development Purpose)
    
    Deskripsi:
    Script ini menunjukkan cara kerja otomatisasi pembelian (Auto Buy) di Roblox.
    Dalam pengembangan game Roblox, interaksi antara client (pemain) dan server (sistem toko)
    biasanya menggunakan RemoteEvent atau RemoteFunction yang berada di ReplicatedStorage.
--]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

-- Konfigurasi Auto Buy
local config = {
    Enabled = false,          -- Status aktif/nonaktif
    ItemName = "TomatoSeed",  -- Ganti dengan nama item/benih di game
    Delay = 1.0               -- Jeda waktu antar pembelian (detik)
}

-- Cari Remote untuk pembelian. Nama Remote berbeda-beda tergantung game.
-- Contoh umum: "BuyItem", "Purchase", "BuySeed", "ShopRemote"
local PurchaseRemote = nil
local remoteNames = {"BuyItem", "Purchase", "BuySeed", "ShopRemote", "PurchaseItem"}

for _, name in ipairs(remoteNames) do
    local found = ReplicatedStorage:FindFirstChild(name, true) -- pencarian rekursif
    if found and (found:IsA("RemoteEvent") or found:IsA("RemoteFunction")) then
        PurchaseRemote = found
        print("[AutoBuy] Menemukan Remote: " .. found:GetFullName())
        break
    end
end

-- Fungsi utama Auto Buy
local function startAutoBuy()
    task.spawn(function()
        while config.Enabled do
            if PurchaseRemote then
                if PurchaseRemote:IsA("RemoteEvent") then
                    -- Mengirim sinyal ke server untuk membeli item
                    PurchaseRemote:FireServer(config.ItemName)
                    print("[AutoBuy] Mengirim pembelian: " .. config.ItemName)
                elseif PurchaseRemote:IsA("RemoteFunction") then
                    -- Memanggil fungsi server dan menunggu hasil respon
                    local success, err = pcall(function()
                        return PurchaseRemote:InvokeServer(config.ItemName)
                    end)
                    if success then
                        print("[AutoBuy] Berhasil membeli: " .. config.ItemName)
                    else
                        print("[AutoBuy] Error saat membeli: " .. tostring(err))
                    end
                end
            else
                warn("[AutoBuy] Remote pembelian tidak ditemukan. Pastikan nama Remote sesuai.")
                break
            end
            task.wait(config.Delay)
        end
    end)
end

-- GUI Sederhana untuk Mengontrol Script (Bisa dimasukkan ke CoreGui atau PlayerGui)
local function createGUI()
    local ScreenGui = Instance.new("ScreenGui")
    local Frame = Instance.new("Frame")
    local Title = Instance.new("TextLabel")
    local ToggleBtn = Instance.new("TextButton")
    
    -- Konfigurasi Gui
    ScreenGui.Name = "AutoBuyGUI"
    ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")
    ScreenGui.ResetOnSpawn = false
    
    Frame.Size = UDim2.new(0, 200, 0, 120)
    Frame.Position = UDim2.new(0.05, 0, 0.4, 0)
    Frame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    Frame.BorderSizePixel = 2
    Frame.BorderColor3 = Color3.fromRGB(0, 255, 127)
    Frame.Active = true
    Frame.Draggable = true
    Frame.Parent = ScreenGui
    
    Title.Size = UDim2.new(1, 0, 0.3, 0)
    Title.BackgroundTransparency = 1
    Title.Text = "Auto Buy Garden 2"
    Title.TextColor3 = Color3.fromRGB(255, 255, 255)
    Title.TextSize = 16
    Title.Font = Enum.Font.SourceSansBold
    Title.Parent = Frame
    
    ToggleBtn.Size = UDim2.new(0.8, 0, 0.4, 0)
    ToggleBtn.Position = UDim2.new(0.1, 0, 0.45, 0)
    ToggleBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
    ToggleBtn.Text = "Status: OFF"
    ToggleBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    ToggleBtn.TextSize = 18
    ToggleBtn.Font = Enum.Font.SourceSans
    ToggleBtn.Parent = Frame
    
    -- Logika Toggle Button
    ToggleBtn.MouseButton1Click:Connect(function()
        config.Enabled = not config.Enabled
        if config.Enabled then
            ToggleBtn.BackgroundColor3 = Color3.fromRGB(50, 200, 50)
            ToggleBtn.Text = "Status: ON"
            startAutoBuy()
        else
            ToggleBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
            ToggleBtn.Text = "Status: OFF"
        end
    end)
end

-- Jalankan GUI
createGUI()
