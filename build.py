import os

def build_monolithic():
    print("Starting build of grow_a_garden_2_complete.lua...")
    
    # 1. Header and Interceptor
    header = """--[[
    Grow a Garden 2 - Modern & Responsive GUI Hub v2.6 (Fluent UI Monolithic Version)
    
    Skrip Auto-Farm dengan Fluent UI (dawid-scripts).
    Dilengkapi sistem debug log terperinci di F9 untuk melacak kendala executor.
--]]

print("[SpeedHubX] SCRIPT EXECUTION STARTED!")

-- ----------------------------------------------------
-- SYSTEM LOG INTERCEPTOR (DIAGNOSTIC SERVICE)
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

print("[SpeedHubX] LogService interceptor initialized.")
"""

    # Read modules
    with open("v2/config.lua", "r", encoding="utf-8") as f:
        config_content = f.read()
        
    with open("v2/utils.lua", "r", encoding="utf-8") as f:
        utils_content = f.read()
        
    with open("v2/features.lua", "r", encoding="utf-8") as f:
        features_content = f.read()
        
    with open("v2/ui.lua", "r", encoding="utf-8") as f:
        ui_content = f.read()
        
    with open("v2/main.lua", "r", encoding="utf-8") as f:
        main_content = f.read()

    # Combine
    combined = []
    combined.append(header)
    
    combined.append("\n-- ----------------------------------------------------")
    combined.append("-- CONFIG MODULE")
    combined.append("-- ----------------------------------------------------")
    combined.append(config_content)
    
    combined.append("\n-- ----------------------------------------------------")
    combined.append("-- UTILITIES MODULE")
    combined.append("-- ----------------------------------------------------")
    combined.append(utils_content)
    
    combined.append("\n-- ----------------------------------------------------")
    combined.append("-- FEATURES MODULE")
    combined.append("-- ----------------------------------------------------")
    combined.append(features_content)
    
    combined.append("\n-- ----------------------------------------------------")
    combined.append("-- FLUENT UI WRAPPER")
    combined.append("-- ----------------------------------------------------")
    combined.append(ui_content)
    
    combined.append("\n-- ----------------------------------------------------")
    combined.append("-- MAIN INITIALIZATION")
    combined.append("-- ----------------------------------------------------")
    combined.append(main_content)
    
    with open("grow_a_garden_2_complete.lua", "w", encoding="utf-8") as f:
        f.write("\n".join(combined))
        
    print("grow_a_garden_2_complete.lua built successfully!")

if __name__ == "__main__":
    build_monolithic()
