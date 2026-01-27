--[[
Trying to load without doing Key System first will not work!
Trying to load without doing Key System first will not work!
Trying to load without doing Key System first will not work!
Trying to load without doing Key System first will not work!
]]

local ids = {
    [121864768012064] = "https://raw.githubusercontent.com/fatigue-a/Pulsar/refs/heads/main/Games/Fish-It/Fish-it.Lua",
}

if ids[game.PlaceId] then
    loadstring(game:HttpGet(ids[game.PlaceId], true))()
else
    warn("Pulsar: Game not supported join ", game.PlaceId)
end
