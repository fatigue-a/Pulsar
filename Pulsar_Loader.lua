local ids = {
    [121864768012064] = "https://raw.githubusercontent.com/fatigue-a/Pulsar/refs/heads/main/Fish-It/Fish-it.lua",
}

if ids[game.PlaceId] then
    loadstring(game:HttpGet(ids[game.PlaceId], true))()
else
    warn("Pulsar: Game not supported join ", game.PlaceId)
end
