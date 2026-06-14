--[[
    Roblox Custom Packet Spy (Khusus Grow a Garden 2)
    
    Karena game ini menggunakan satu RemoteEvent utama untuk semua aksi:
    "ReplicatedStorage.SharedModules.Packet.RemoteEvent"
    
    Skrip ini akan merekam argumen paket yang dikirimkan saat Anda menanam, memanen,
    menjual, dll., lalu menampilkannya di layar dan menyimpannya di file "packet_logs.txt".
--]]

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Cari RemoteEvent utama
local PacketRemote = ReplicatedStorage:FindFirstChild("SharedModules") 
    and ReplicatedStorage.SharedModules:FindFirstChild("Packet")
    and ReplicatedStorage.SharedModules.Packet:FindFirstChild("RemoteEvent")

if not PacketRemote then
    -- Cari cadangan secara rekursif
    PacketRemote = ReplicatedStorage:FindFirstChild("RemoteEvent", true)
end

if not PacketRemote then
    error("[PacketSpy] RemoteEvent utama tidak ditemukan di ReplicatedStorage!")
end

print("[PacketSpy] Menghubungkan ke: " .. PacketRemote:GetFullName())

-- 1. Siapkan GUI Tampilan di Layar
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "PacketSpyGUI"
ScreenGui.ResetOnSpawn = false
ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")

local MainFrame = Instance.new("Frame")
MainFrame.Size = UDim2.new(0, 450, 0, 300)
MainFrame.Position = UDim2.new(0.3, 0, 0.3, 0)
MainFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
MainFrame.BorderSizePixel = 2
MainFrame.BorderColor3 = Color3.fromRGB(0, 150, 255)
MainFrame.Active = true
MainFrame.Draggable = true
MainFrame.Parent = ScreenGui

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, 0, 0.12, 0)
Title.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
Title.Text = "Packet Spy - Lakukan Aksi Manual (Tanam/Panen/Jual)"
Title.TextColor3 = Color3.fromRGB(255, 255, 255)
Title.TextSize = 14
Title.Font = Enum.Font.SourceSansBold
Title.Parent = MainFrame

local Scroll = Instance.new("ScrollingFrame")
Scroll.Size = UDim2.new(0.95, 0, 0.82, 0)
Scroll.Position = UDim2.new(0.025, 0, 0.15, 0)
Scroll.BackgroundTransparency = 1
Scroll.CanvasSize = UDim2.new(0, 0, 0, 1000)
Scroll.ScrollBarThickness = 6
Scroll.Parent = MainFrame

local UIListLayout = Instance.new("UIListLayout")
UIListLayout.Padding = UDim.new(0, 5)
UIListLayout.Parent = Scroll

local logCount = 0
local function addLog(text)
    logCount = logCount + 1
    local Label = Instance.new("TextBox")
    Label.Size = UDim2.new(0.98, 0, 0, 50)
    Label.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
    Label.ClearTextOnFocus = false
    Label.TextEditable = false
    Label.Text = text
    Label.TextColor3 = Color3.fromRGB(255, 255, 255)
    Label.TextSize = 12
    Label.Font = Enum.Font.SourceSans
    Label.TextWrapped = true
    Label.TextXAlignment = Enum.TextXAlignment.Left
    Label.Parent = Scroll
    
    Scroll.CanvasSize = UDim2.new(0, 0, 0, logCount * 55)
end

-- 2. Hooking Instance Level (Tidak memerlukan hookmetamethod, aman & stabil di Delta)
local rawFunc = getrawmetatable(game)
setreadonly(rawFunc, false)
local oldNamecall = rawFunc.__namecall

rawFunc.__namecall = newcclosure(function(self, ...)
    local method = getnamecallmethod()
    local args = {...}
    
    if self == PacketRemote and (method == "FireServer" or method == "fireServer") then
        local logText = string.format("[PACKET FIRED]\nArgs: ")
        local fileText = "[PACKET FIRED] "
        
        for i, v in ipairs(args) do
            local str = tostring(v)
            if typeof(v) == "Instance" then
                str = v:GetFullName() .. " (" .. v.ClassName .. ")"
            elseif typeof(v) == "table" then
                -- Coba ubah table ke string sederhana
                pcall(function()
                    local HttpService = game:GetService("HttpService")
                    str = HttpService:JSONEncode(v)
                end)
            end
            logText = logText .. string.format("\n  [%d]: %s (%s)", i, str, typeof(v))
            fileText = fileText .. string.format("[%d]: %s (%s) | ", i, str, typeof(v))
        end
        
        -- Cetak di layar GUI
        addLog(logText)
        
        -- Cetak di F9 Developer Console
        print(logText)
        
        -- Simpan ke file teks di workspace
        pcall(function()
            if writefile then
                local currentLogs = ""
                pcall(function() currentLogs = readfile("packet_logs.txt") end)
                writefile("packet_logs.txt", currentLogs .. fileText .. "\n")
            end
        end)
    end
    
    return oldNamecall(self, ...)
end)

setreadonly(rawFunc, true)

addLog("System: Scanner aktif. Lakukan aksi menanam, memanen, atau menjual secara manual.")
print("[PacketSpy] Scanner aktif. Menunggu pengiriman paket...")
