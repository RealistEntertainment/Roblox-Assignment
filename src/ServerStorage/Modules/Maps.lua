local ServerStorage = game:GetService("ServerStorage")

local MapModels = ServerStorage.Assets.Maps

local Maps = {}

Maps["Test_Map"] = {
	MapReference = MapModels:WaitForChild("Test_Map"),
	NpcCap = 5, --// this cap says only this many npc at a time(one must die to spawn a new one). This can control difficultly on smaller maps
	RoundTime = 60, --// the amount of the per round.
	StartingDifficulty = 1, --// 1 = default. This will be used as a scale 1.1 == 10%
}

function Maps.RandomMap(): table
	local activeMaps = { "Test_Map" }
	local randomMap = math.random(1, #activeMaps)

	if Maps[activeMaps[randomMap]] then
		return Maps[activeMaps[randomMap]]
	else
		return nil
	end
end

return Maps
