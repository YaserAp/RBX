--[[
    Grow a Garden 2 - Packet Module Inspector
    
    Skrip ini merequire modul ReplicatedStorage.SharedModules.Packet dan Networking
    untuk melihat fungsi/API apa saja yang diekspor, sehingga kita bisa memanggil
    fungsi menanam, memanen, dan menjual secara langsung menggunakan modul internal game.
--]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

local function inspectModule(moduleName, moduleInstance)
    print("\n=== INSPECTING MODULE: " .. moduleName .. " ===")
    local success, moduleTable = pcall(function()
        return require(moduleInstance)
    end)
    
    if not success then
        print("Gagal require module: " .. tostring(moduleTable))
        return
    end
    
    if type(moduleTable) == "table" then
        for k, v in pairs(moduleTable) do
            print(string.format("  Key: %s | Type: %s", tostring(k), type(v)))
            if type(v) == "table" then
                for subK, subV in pairs(v) do
                    print(string.format("    -> SubKey: %s | Type: %s", tostring(subK), type(subV)))
                end
            end
        end
        
        -- Cek metatable
        local mt = getmetatable(moduleTable)
        if mt then
            print("  --- Metatable ---")
            for k, v in pairs(mt) do
                print(string.format("    MT Key: %s | Type: %s", tostring(k), type(v)))
            end
        end
    else
        print("Module tidak mengembalikan table, tipe kembalian: " .. type(moduleTable))
        print("Nilai: " .. tostring(moduleTable))
    end
end

-- Cari modul-modul penting
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
    print("SharedModules tidak ditemukan!")
end
