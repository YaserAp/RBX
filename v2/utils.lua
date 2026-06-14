--[[
    Speed Hub X - Utilities Module
    Berisi fungsi-fungsi pembantu interaksi game dan dekorasi UI.
--]]

local SpeedHubX = shared.SpeedHubX or {}
shared.SpeedHubX = SpeedHubX

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

local Utils = {}
SpeedHubX.Utils = Utils

-- Fungsi Mencari Plot Kebun Pemain
function Utils.getPlayerPlot()
    local farmFolder = workspace:FindFirstChild("Farm") or workspace:FindFirstChild("Farms")
    if farmFolder then
        for _, plot in ipairs(farmFolder:GetChildren()) do
            -- 1. Cek nama plot
            if plot.Name == LocalPlayer.Name then
                return plot
            end
            
            -- 2. Cek Owner secara rekursif
            local ownerObj = plot:FindFirstChild("Owner", true)
            if ownerObj then
                if ownerObj.Value == LocalPlayer.Name or ownerObj.Value == LocalPlayer then
                    return plot
                end
            end
            
            -- 3. Cek struktur asli
            local important = plot:FindFirstChild("Important")
            local data = important and important:FindFirstChild("Data")
            local owner = data and data:FindFirstChild("Owner")
            if owner and (owner.Value == LocalPlayer.Name or owner.Value == LocalPlayer) then
                return plot
            end
            
            -- 4. Cek atribut
            if plot:GetAttribute("Owner") == LocalPlayer.Name or plot:GetAttribute("Owner") == LocalPlayer or plot:GetAttribute("OwnerId") == LocalPlayer.UserId then
                return plot
            end
        end
    end
    return nil
end

-- Fungsi Pemanggil Event Biner Game secara aman
function Utils.fireNetworkEvent(eventTable, ...)
    if not eventTable then return false end
    local successCall = false
    local args = {...}
    local argCount = select("#", ...)
    local unpackFunc = unpack or table.unpack
    
    pcall(function()
        if type(eventTable) == "table" then
            if eventTable.Fire then
                eventTable:Fire(unpackFunc(args, 1, argCount))
                successCall = true
            elseif eventTable.FireServer then
                eventTable:FireServer(unpackFunc(args, 1, argCount))
                successCall = true
            elseif eventTable.fire then
                eventTable:fire(unpackFunc(args, 1, argCount))
                successCall = true
            else
                local mt = getmetatable(eventTable)
                if mt and mt.__call then
                    eventTable(unpackFunc(args, 1, argCount))
                    successCall = true
                end
            end
        end
    end)
    
    return successCall
end

-- Fungsi Fallback Interaksi Click/Prompt Fisik (Mendukung pencarian rekursif)
function Utils.triggerInteraction(object)
    if not object then return false end
    
    -- Cari ProximityPrompt secara rekursif
    local prompt = object:IsA("ProximityPrompt") and object
    if not prompt then
        prompt = object:FindFirstChildOfClass("ProximityPrompt")
    end
    if not prompt then
        for _, desc in ipairs(object:GetDescendants()) do
            if desc:IsA("ProximityPrompt") then
                prompt = desc
                break
            end
        end
    end
    
    if prompt and fireproximityprompt then
        if prompt.Enabled then
            pcall(function() fireproximityprompt(prompt) end)
            return true
        end
    end
    
    -- Cari ClickDetector secara rekursif
    local clickDetector = object:IsA("ClickDetector") and object
    if not clickDetector then
        clickDetector = object:FindFirstChildOfClass("ClickDetector")
    end
    if not clickDetector then
        for _, desc in ipairs(object:GetDescendants()) do
            if desc:IsA("ClickDetector") then
                clickDetector = desc
                break
            end
        end
    end
    
    if clickDetector and fireclickdetector then
        pcall(function() fireclickdetector(clickDetector) end)
        return true
    end
    
    return false
end

-- Fungsi Pembuat UICorner
function Utils.addCorner(parent, radius)
    local success, corner = pcall(function()
        local c = Instance.new("UICorner")
        c.CornerRadius = UDim.new(0, radius)
        c.Parent = parent
        return c
    end)
    return success and corner or nil
end

-- Fungsi Pembuat UIStroke
function Utils.addStroke(parent, color, thickness)
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

print("[SpeedHubX] Utilities module successfully loaded.")
