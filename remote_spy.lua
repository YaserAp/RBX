--[[
    Roblox Simple Remote Spy (Untuk Delta Executor)
    
    Cara Pakai:
    1. Jalankan skrip ini di Delta Executor Anda.
    2. Buka F9 (Developer Console) di Roblox untuk melihat log.
    3. Lakukan aksi secara manual di dalam game (Menanam, Memanen, Menjual, Membeli Benih).
    4. Nama remote event beserta argumennya akan tercetak di F9 Console.
--]]

local oldNamecall
oldNamecall = hookmetamethod(game, "__namecall", function(self, ...)
    local method = getnamecallmethod()
    
    -- Memantau pemanggilan FireServer (RemoteEvent) dan InvokeServer (RemoteFunction)
    if method == "FireServer" or method == "InvokeServer" then
        local path = self:GetFullName()
        
        -- Memfilter log agar tidak terlalu spam dengan remote sistem umum Roblox
        if not path:find("RobloxReplicatedStorage") and not path:find("CharacterSoundEvent") then
            print("\n[REMOTE SPY] ----------------------------------")
            print("Path    : " .. path)
            print("Method  : " .. method)
            
            local args = {...}
            if #args > 0 then
                print("Arguments:")
                for i, v in ipairs(args) do
                    local valStr = tostring(v)
                    if typeof(v) == "Instance" then
                        valStr = v:GetFullName() .. " (" .. v.ClassName .. ")"
                    end
                    print("  [" .. tostring(i) .. "] : " .. valStr .. " (" .. typeof(v) .. ")")
                end
            else
                print("Arguments: (None)")
            end
            print("------------------------------------------------")
        end
    end
    
    return oldNamecall(self, ...)
end)

print("[RemoteSpy] Scanner telah aktif! Silakan lakukan aksi menanam/memanen/menjual manual lalu cek F9 console.")
OrionLib:MakeNotification({
    Name = "Remote Spy",
    Content = "Scanner Aktif! Cek konsol F9 setelah melakukan aksi manual.",
    Time = 5
})
