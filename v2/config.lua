--[[
    Speed Hub X - Config Module
    Menyimpan seluruh state konfigurasi fitur auto-farm dan player mods.
--]]

local SpeedHubX = shared.SpeedHubX or {}
shared.SpeedHubX = SpeedHubX

SpeedHubX.Config = {
    AutoPlant = false,
    AutoHarvest = false,
    AutoWater = false,
    AutoSell = false,
    AutoBuySeeds = false,
    AutoSpray = false,
    SelectedSeed = "Tomato",
    WalkSpeed = 16,
    JumpPower = 50,
    InfiniteJump = false,
    AntiAFK = true,
    SelectedMutations = {"Choc", "Overgrown", "Gold", "Rainbow"}
}

print("[SpeedHubX] Config module successfully loaded.")
