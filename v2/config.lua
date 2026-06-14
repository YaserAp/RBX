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
    SelectedSeeds = {
        ["Carrot"] = false,
        ["Strawberry"] = false,
        ["Blueberry"] = false,
        ["Tomato"] = true,
        ["Apple"] = false,
        ["Tulip"] = false,
        ["Corn"] = false,
        ["Cactus"] = false,
        ["Pineapple"] = false,
        ["Bamboo"] = false,
        ["Mushroom"] = false,
        ["Green Bean"] = false,
        ["Banana"] = false,
        ["Grape"] = false,
        ["Coconut"] = false,
        ["Mango"] = false,
        ["Acorn"] = false,
        ["Cherry"] = false,
        ["Dragon Fruit"] = false,
        ["Sunflower"] = false,
        ["Pomegranate"] = false,
        ["Poison Apple"] = false,
        ["Venus Fly Trap"] = false,
        ["Moon Bloom"] = false,
        ["Dragon's Breath"] = false,
        ["Gold"] = false,
        ["Rainbow"] = false
    },
    WalkSpeed = 16,
    JumpPower = 50,
    InfiniteJump = false,
    AntiAFK = true,
    SelectedMutations = {"Choc", "Overgrown", "Gold", "Rainbow"}
}

print("[SpeedHubX] Config module successfully loaded.")
