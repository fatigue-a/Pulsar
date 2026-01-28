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
    local source = game:HttpGet(ids[game.PlaceId])
    if type(source) ~= "string" then
        error("[Pulsar] HttpGet returned non-string type: " .. type(source))
    end
    local fn, err = loadstring(source)
    if not fn then
        error("[Pulsar] Failed to compile game script: " .. tostring(err))
    end
    fn()
else
    warn("Pulsar: Game not supported join ", game.PlaceId)
end
