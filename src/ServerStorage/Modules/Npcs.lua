local Npcs = {
	Normal = {},
	Boss = {},
}

Npcs.Normal["Zombie"] = {
	WalkSpeed = 16,
	Damage = 5,
	AttackRate = 1,
	Health = 25,
	AttackRange = 5,
}

Npcs.Boss["MEGA Zombie"] = {
	WalkSpeed = 8,
	Damage = 15,
	AttackRate = 1.2,
	Health = 350,
	AttackRange = 20,
}

function Npcs.RandomNpc(): (string, "Normal")
	local liveNpc = { "Zombie" }
	local randomNpc = math.random(1, #liveNpc)

	if Npcs.Normal[liveNpc[randomNpc]] then
		return liveNpc[randomNpc], "Normal"
	else
		return nil
	end
end

function Npcs.RandomBossNpc(): (string, "Boss")
	local liveNpc = { "MEGA Zombie" }
	local randomNpc = math.random(1, #liveNpc)

	if Npcs.Boss[liveNpc[randomNpc]] then
		return liveNpc[randomNpc], "Boss"
	else
		return nil
	end
end

return Npcs
