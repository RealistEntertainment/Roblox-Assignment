--[[ Documentation
	This creates the base of all NPC

    new(npcName, npcType, Difficulty, Map)
		Variables
			npcName, npcType:  are use to located the npc data and model.
			Difficulty :  will spawn the NPC in with more with according to the difficulty value.

	Start
		This starts the "brains of the NPC"


	CleanUp
		Self explanatory cleans up NPC.
			

]]

local ServerStorage = game:GetService("ServerStorage")

local NpcModels = ServerStorage.Assets.Npc

local Modules = script.Parent.Parent.Modules
local NpcModule = require(Modules.Npcs)

local AIClass = {}
AIClass.__index = AIClass

function AIClass.new(npcName: string, npcType: "Normal" | "Boss", Difficulty: number, Map: Folder)
	local self = setmetatable({}, AIClass)

	--// default difficulty to 1 if not set
	self.Difficulty = Difficulty or 1

	--// clone the Npc model
	self.Npc = NpcModels[npcType][npcName]:Clone()
	self.Humanoid = self.Npc.Humanoid

	--// set health based on difficulty
	self.Humanoid.MaxHealth = self.Humanoid.MaxHealth * Difficulty
	self.Humanoid.Health = self.Humanoid.Health * Difficulty

	self.NpcData = NpcModule[npcType][npcName]
	self.Objective = Map.Objective

	--// folder of spawns
	self.AISpawn = Map.AISpawn
	local RandomSpawn: BasePart = self.AISpawn:GetChildren()[math.random(1, #self.AISpawn:GetChildren())]

	--// Move npc to the spawn
	local npcSize: Vector3 = self.Npc:GetExtentsSize()
	self.Npc:PivotTo(RandomSpawn.CFrame + Vector3.new(0, npcSize.Y, 0))
	self.Npc.Parent = workspace.Npc

	--// if Npc dies clean itself up
	self.Humanoid.Died:Connect(function()
		self:CleanUp()
	end)
	return self
end

function AIClass:Start()
	if self.Objective then
		self.Active = true
		task.spawn(function()
			while true do
				task.wait(0.2)

				--// breaking loop to clean up.
				if not self.Active or not self.Npc or not self.Npc.PrimaryPart or self.Npc.Parent == nil then
					break
				end

				local npcCFrame: CFrame = self.Npc:GetPrimaryPartCFrame()
				local objectiveCFrame: CFrame = self.Objective:GetPivot()

				local rayInfo: RaycastParams = RaycastParams.new()
				rayInfo.FilterType = Enum.RaycastFilterType.Blacklist
				rayInfo.FilterDescendantsInstances = { self.Npc.Parent }

				local rayCast = workspace:Raycast(
					npcCFrame.Position,
					(objectiveCFrame.Position - npcCFrame.Position),
					rayInfo
				)

				--// checking if the objective is in range. If so damage it with applied difficulty
				local attacked = false
				if rayCast then
					if rayCast.Instance.Parent == self.Objective and rayCast.Distance <= self.NpcData.AttackRange then
						local health = self.Objective:GetAttribute("Health")
						print(health)
						if health > 0 then
							self.Objective:SetAttribute("Health", health - (self.NpcData.Damage * self.Difficulty))
							task.wait(self.NpcData.AttackRate)

							attacked = true
						end
					end
				end

				--// if we are not in attack range then keep moving to the objective
				if not attacked then
					self.Humanoid:MoveTo(objectiveCFrame.Position)
				end
			end

			--// destroy npc when the loops stops
			if self.Npc then
				self.Npc:Destroy()
				self.Npc = nil
			end

			self = nil
		end)
	end
end

function AIClass:CleanUp()
	self.Active = false
	self = nil
end
return AIClass
