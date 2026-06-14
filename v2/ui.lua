--[[
    Speed Hub X - Fluent UI Wrapper
    Menggunakan Fluent UI Library dari dawid-scripts untuk tampilan premium.
    Dioptimalkan secara penuh untuk Delta Executor.
--]]

local SpeedHubX = shared.SpeedHubX or {}
shared.SpeedHubX = SpeedHubX

print("[SpeedHubX] Loading Fluent UI library from GitHub...")

local Fluent = nil
local success, result = pcall(function()
    return loadstring(game:HttpGet("https://github.com/dawid-scripts/Fluent/releases/latest/download/main.lua"))()
end)

if success and type(result) == "table" then
    Fluent = result
    print("[SpeedHubX] Fluent UI loaded successfully!")
else
    warn("[SpeedHubX] Failed to load Fluent UI from release, trying fallback...")
    local success2, result2 = pcall(function()
        return loadstring(game:HttpGet("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/main.lua"))()
    end)
    if success2 and type(result2) == "table" then
        Fluent = result2
        print("[SpeedHubX] Fluent UI loaded from fallback.")
    else
        error("[SpeedHubX] Critical Error: Fluent UI could not be loaded! " .. tostring(result or result2))
    end
end

local UIWrapper = {}
SpeedHubX.UI = UIWrapper

function UIWrapper:CreateWindow(titleText)
    local Window = Fluent:CreateWindow({
        Title = titleText or "Speed Hub X",
        SubTitle = "by YaserAp & Antigravity AI",
        TabWidth = 160,
        Size = UDim2.fromOffset(580, 460),
        Acrylic = false, -- Nonaktifkan acrylic blur di mobile agar bebas lag/crash
        Theme = "Dark",
        MinimizeKey = Enum.KeyCode.LeftControl
    })

    local WindowWrapper = {
        Tabs = {}
    }

    function WindowWrapper:CreateTab(tabName)
        local icon = "settings"
        if tabName == "Auto Farm" then
            icon = "home"
        elseif tabName == "Toko Benih" then
            icon = "shopping-cart"
        elseif tabName == "Auto Spray" then
            icon = "droplet"
        elseif tabName == "Player Mods" then
            icon = "user"
        elseif tabName == "System Logs" then
            icon = "terminal"
        elseif tabName == "Credits" then
            icon = "info"
        end

        local Tab = Window:AddTab({ Title = tabName, Icon = icon })
        local TabWrapper = {}

        function TabWrapper:AddToggle(labelText, defaultValue, callback)
            local toggleId = "Toggle_" .. labelText:gsub("%s+", ""):gsub("%W+", "")
            local Toggle = Tab:AddToggle(toggleId, {
                Title = labelText,
                Default = defaultValue or false
            })
            Toggle:OnChanged(function()
                pcall(callback, Toggle.Value)
            end)
            return Toggle
        end

        function TabWrapper:AddParagraph(titleText, contentText)
            local Paragraph = Tab:AddParagraph({
                Title = titleText or "",
                Content = contentText or ""
            })

            local ParaWrapper = {}
            function ParaWrapper:SetTitle(t)
                Paragraph:SetTitle(t)
            end
            function ParaWrapper:SetText(t)
                Paragraph:SetDesc(t)
            end
            return ParaWrapper
        end

        function TabWrapper:AddDropdown(labelText, valuesList, defaultValue, callback, multi)
            local dropdownId = "Dropdown_" .. labelText:gsub("%s+", ""):gsub("%W+", "")
            local Dropdown = Tab:AddDropdown(dropdownId, {
                Title = labelText,
                Values = valuesList or {},
                Multi = not not multi,
                Default = defaultValue
            })
            Dropdown:OnChanged(function(val)
                pcall(callback, val)
            end)
            return Dropdown
        end

        function TabWrapper:AddSlider(labelText, minVal, maxVal, defaultValue, callback)
            local sliderId = "Slider_" .. labelText:gsub("%s+", ""):gsub("%W+", "")
            local Slider = Tab:AddSlider(sliderId, {
                Title = labelText,
                Min = minVal or 0,
                Max = maxVal or 100,
                Default = defaultValue or minVal,
                Rounding = 0,
                Callback = function(val)
                    pcall(callback, val)
                end
            })
            return Slider
        end

        function TabWrapper:AddLogViewer()
            local LogParagraph = Tab:AddParagraph({
                Title = "Console Logs",
                Content = "Waiting for logs..."
            })

            local function refreshLogs()
                local txt = ""
                local logMessages = SpeedHubX.LogMessages or {}
                local limit = math.max(1, #logMessages - 15)
                for i = limit, #logMessages do
                    txt = txt .. logMessages[i] .. "\n"
                end
                LogParagraph:SetDesc(txt)
            end

            SpeedHubX.OnLogAdded = function(msg)
                pcall(refreshLogs)
            end

            pcall(refreshLogs)
        end

        return TabWrapper
    end

    return WindowWrapper
end

SpeedHubX.Fluent = Fluent
print("[SpeedHubX] Fluent UI Wrapper successfully loaded.")
return UIWrapper
