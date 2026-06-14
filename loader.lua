--[[
    Speed Hub X - Grow a Garden 2 Loader
    
    Salin skrip ini ke Delta Executor Anda untuk menjalankan menu modular.
    
    - Untuk uji coba lokal (Tanpa unggah ke GitHub):
      Atur USE_LOCAL = true. Delta akan langsung membaca folder 'src/' di HP/PC Anda.
    - Untuk publikasi (Dipanggil lewat GitHub):
      Atur USE_LOCAL = false, lalu sesuaikan nama GitHub 'owner', 'repo', dan 'branch' Anda.
--]]

local USE_LOCAL = false -- Ganti ke false jika ingin memanggil langsung dari repo GitHub Anda

local owner = "YaserAp"
local repo = "RBX"
local branch = "main"

-- ----------------------------------------------------
-- INTERCEPT SYSTEM LOGS (UNTUK PENANGANAN ERROR & TAB LOGS)
-- ----------------------------------------------------
shared.SpeedHubX = {
    LogMessages = {},
    OnLogAdded = nil
}
local SpeedHubX = shared.SpeedHubX
local logMessages = SpeedHubX.LogMessages

local LogService = nil
pcall(function() LogService = game:GetService("LogService") end)
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
        if SpeedHubX.OnLogAdded then pcall(SpeedHubX.OnLogAdded, formatted) end
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

print("[SpeedHubX] Loader started. Mode: " .. (USE_LOCAL and "LOCAL WORKSPACE" or "GITHUB CLOUD"))

-- ----------------------------------------------------
-- DYNAMIC MODULE LOAD FUNCTION
-- ----------------------------------------------------
local function loadModule(path)
    local sourceCode = ""
    if USE_LOCAL then
        -- Mode Lokal: Baca file dari penyimpanan internal executor
        if not readfile then
            error("Executor Anda tidak mendukung fungsi 'readfile' untuk testing lokal.")
        end
        local successRead, content = pcall(function()
            return readfile(path)
        end)
        if not successRead or not content then
            error("Gagal membaca file lokal: " .. path .. "\nPastikan struktur folder 'src/' sudah berada di dalam folder workspace Delta Executor.")
        end
        sourceCode = content
    else
        -- Mode GitHub: Unduh file secara dinamis dari server raw GitHub (bypassing cache)
        local url = string.format("https://raw.githubusercontent.com/%s/%s/%s/%s?t=%s", owner, repo, branch, path, tostring(tick()))
        local successGet, content = pcall(function()
            return game:HttpGet(url)
        end)
        if not successGet or not content or content == "404: Not Found" then
            error("Gagal mendownload modul dari GitHub: " .. path .. "\nPeriksa nama GitHub username, repository, atau status koneksi Anda.")
        end
        sourceCode = content
    end
    
    -- Compile & jalankan kode modul
    local runFunc, compileError = loadstring(sourceCode)
    if not runFunc then
        error("Syntax error saat mem-parsing modul " .. path .. ":\n" .. tostring(compileError))
    end
    
    local successRun, runError = pcall(runFunc)
    if not successRun then
        error("Runtime error saat mengeksekusi modul " .. path .. ":\n" .. tostring(runError))
    end
end

-- ----------------------------------------------------
-- LOAD ORDER WITH TRY-CATCH PCALL
-- ----------------------------------------------------
local initSuccess, initError = pcall(function()
    loadModule("src/config.lua")
    loadModule("src/utils.lua")
    loadModule("src/features.lua")
    loadModule("src/ui.lua")
    loadModule("src/main.lua")
end)

-- ----------------------------------------------------
-- FALLBACK EMERGENCY PANEL (JIKA PENGUNDUHAN/EKSEKUSI GAGAL)
-- ----------------------------------------------------
if not initSuccess then
    warn("[SpeedHubX] Critical loader error: " .. tostring(initError))
    
    pcall(function()
        local Players = game:GetService("Players")
        local LocalPlayer = Players.LocalPlayer
        
        -- Cari PlayerGui secara aman
        local PlayerGui = nil
        pcall(function() PlayerGui = LocalPlayer:FindFirstChildOfClass("PlayerGui") end)
        if not PlayerGui then pcall(function() PlayerGui = LocalPlayer:WaitForChild("PlayerGui", 5) end) end
        if not PlayerGui then pcall(function() PlayerGui = LocalPlayer.PlayerGui end) end
        
        if not PlayerGui then return end
        
        -- Bersihkan GUI fallback lama
        local oldFallback = PlayerGui:FindFirstChild("SpeedHubX_Loader_Fallback")
        if oldFallback then oldFallback:Destroy() end
        
        local fallbackScreen = Instance.new("ScreenGui")
        fallbackScreen.Name = "SpeedHubX_Loader_Fallback"
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
        Title.Text = " Speed Hub X - Critical Loader Error!"
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
        
        local function destroyFB() fallbackScreen:Destroy() end
        CloseBtn.Activated:Connect(destroyFB)
        CloseBtn.MouseButton1Click:Connect(destroyFB)
        
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
        TextLabel.Text = "LOADER ENCOUNTERED A FAILURE:\n" .. tostring(initError)
        TextLabel.Parent = Frame
    end)
end
