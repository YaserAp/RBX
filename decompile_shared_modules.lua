--[[
    Grow a Garden 2 - SharedModules Decompiler
    
    Skrip ini mencari semua ModuleScript di dalam ReplicatedStorage.SharedModules,
    men-decompile kodenya (mengubah bytecode kembali ke teks yang bisa dibaca),
    dan menyimpannya di file "shared_modules_decompiled.lua".
--]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local decompile = decompile or getscriptsource or function(s) return "-- Decompiler tidak didukung di executor ini" end

local function dumpSharedModules()
    local sharedModules = ReplicatedStorage:FindFirstChild("SharedModules")
    if not sharedModules then
        return "SharedModules tidak ditemukan di ReplicatedStorage."
    end
    
    local content = "=== GROW A GARDEN 2 SHARED MODULES DUMP ===\n\n"
    
    for _, module in ipairs(sharedModules:GetDescendants()) do
        if module:IsA("ModuleScript") then
            content = content .. string.format("\n\n=========================================\n")
            content = content .. string.format("MODULE: %s\n", module:GetFullName())
            content = content .. string.format("=========================================\n")
            
            local success, decompiledText = pcall(function()
                return decompile(module)
            end)
            
            if success then
                content = content .. decompiledText
            else
                content = content .. "-- Gagal men-decompile module ini: " .. tostring(decompiledText)
            end
        end
    end
    
    if writefile then
        writefile("shared_modules_decompiled.lua", content)
        return "Sukses men-decompile dan menyimpan ke shared_modules_decompiled.lua!"
    else
        return "writefile tidak didukung, tidak bisa menyimpan berkas."
    end
end

local result = dumpSharedModules()
print(result)
