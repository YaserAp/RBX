--[[
    Grow a Garden 2 - SharedModules Tree Dumper
    
    Skrip ini mendata seluruh struktur folder dan file di dalam ReplicatedStorage.SharedModules
    dan menyimpannya di file "shared_modules_tree.txt" di folder workspace Delta Anda.
--]]

local function printTree(instance, depth)
    depth = depth or 0
    local prefix = string.rep("  ", depth)
    local content = prefix .. instance.Name .. " (" .. instance.ClassName .. ")\n"
    for _, child in ipairs(instance:GetChildren()) do
        content = content .. printTree(child, depth + 1)
    end
    return content
end

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local sharedModules = ReplicatedStorage:FindFirstChild("SharedModules")

if sharedModules then
    local tree = printTree(sharedModules)
    if writefile then
        writefile("shared_modules_tree.txt", tree)
        print("[TreeDumper] Struktur berhasil disimpan ke shared_modules_tree.txt!")
    else
        print("[TreeDumper] Struktur gagal disimpan karena writefile tidak didukung.")
        print(tree) -- Tampilkan di konsol F9 jika tidak bisa tulis file
    end
else
    print("[TreeDumper] SharedModules tidak ditemukan di ReplicatedStorage.")
end
