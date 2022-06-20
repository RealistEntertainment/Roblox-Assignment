--[[ Documentation
	This creates the base of all NPC

    new(mapData)
		Constructor
		mapData is passed through the RoundService.

	Start
		This starts the Main loop.

	HandleNpc(boolean)
		This method cleans up Npc that have died or became nil.
		When a npc is removed it randomly will pick a new npc and spawn it in with according round difficulty.
		Starts the AI brain if the true is passed.

	Feedback(string)
		This connects to the RoundService feedback signal.
		it passes the string back to the clients

	Intermission(number)
		This fires feedback. While yield the amount of time passed to it

	ClearNpc()
		This removes all npcs

	CleanUp
		Self explanatory cleans up.
			

]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local RoundClass = {}
RoundClass.__index = RoundClass

local Knit = require(ReplicatedStorage.Packages.Knit)

local classes = script.Parent.Parent.Classes
local aiClass = require(classes.AIClass)

local modules = script.Parent.Parent.Modules
local npcsModule = require(modules.Npcs)

function RoundClass.new(mapData)
	local self = setmetatable({}, RoundClass)

	--// service
	self.RoundService = Knit.GetService("RoundService")

	self.Map = mapData.MapReference:Clone()
	self.Objective = self.Map:FindFirstChild("Objective")
	self.AISpawn = self.Map:FindFirstChild("AISpawn")
	self.PlayerSpawn = self.Map:FindFirstChild("PlayerSpawn")

	--// round information
	self.RoundTime = mapData.RoundTime
	self.CurrentRoundTime = self.RoundTime
	self.CurrentDifficulty = mapData.StartingDifficulty
	self.NpcCap = mapData.NpcCap
	self.Active = false

	--// holds npcs for easy clean up
	self.Npc = {}

	-- load map in.
	self.Map.Parent = workspace.MapHolder

	-- this will be use to determined if we have everything needed to run the round
	self.isCreated = false

	if self.Map and self.Objective and self.AISpawn and self.PlayerSpawn then
		self.isCreated = true
	end

	return self
end

function RoundClass:HandleNPC(autoStart: boolean)
	--// make sure we are not holding on to dead npc
	for idx, npcs in ipairs(self.Npc) do
		if not npcs.Npc then
			self.Npc[idx]:CleanUp()
			table.remove(self.Npc, idx)
		end
	end

	local npcNeededCount = self.NpcCap - #self.Npc
	if npcNeededCount > 0 then --// we have room to spawn npc
		for _ = 1, npcNeededCount do
			local npcName, npcType = npcsModule.RandomNpc()
			if npcName and npcType then
				local npc = aiClass.new(npcName, npcType, self.CurrentDifficulty, self.Map)
				table.insert(self.Npc, npc)

				if autoStart then --// if autoStart then AI will start from this function
					npc:Start()
				end
			end
		end
	end
end

function RoundClass:Feedback(msg: string)
	self.RoundService.Client.Feedback:FireAll(tostring(msg))
end

function RoundClass:Start()
	--[[
		Spawn Npc in
        Start intermission.
		Initiate Npc
        Keep spawning npc until round is over. or objective is destroyed
    ]]
	--// start the round
	self.CurrentRound = 1
	self.Active = true

	--// connect objective to know if it destroyed
	self.Objective.AttributeChanged:Connect(function(attributeName: string)
		if attributeName == "Health" and self.Objective ~= nil then
			local health: number = self.Objective:GetAttribute(attributeName)
			local maxHealth: number = self.Objective:GetAttribute("MaxHealth")
			local healthUI: BillboardGui = self.Objective:FindFirstChild("HealthUI")

			--// a bounce effect. to visualize damage taken
			if health > 0 then --Damaged
				self.Objective.PrimaryPart.Size = Vector3.new(4.8, 4.8, 4.8)
				task.wait(0.1)
				self.Objective.PrimaryPart.Size = Vector3.new(5, 5, 5)

				--// update health UI
				if healthUI then
					local healthBar: Frame = healthUI.HealthFrame.HealthBar
					local healthText: TextLabel = healthUI.HealthFrame.HealthText

					healthBar.Size = UDim2.new(math.clamp(0, health / maxHealth, 1), 0, 1, 0)
					healthText.Text = tostring(health) .. "/" .. tostring(maxHealth)
				end
			else -- it died
				self:CleanUp()
			end
		end
	end)

	--// intermission
	self:Intermission(30)

	--// start the round
	while true do
		task.wait(1)
		if self.Active then
			self.CurrentRoundTime -= 1
			self:Feedback("Round " .. self.CurrentRound .. " seconds left: " .. self.CurrentRoundTime)
			if self.CurrentRoundTime <= 0 then
				self.CurrentRoundTime = self.RoundTime
				self.CurrentRound += 1

				--// increases difficulty making Npcs stronger
				self.CurrentDifficulty += 0.1

				self:Feedback("Finished Round!")

				--// clean out all npc round is over
				self:ClearNpc()

				--// intermission
				self:Intermission(30)

				--// spawn new npc
				self:HandleNPC(true)
			end

			--// check if we need to spawn a new npc in
			self:HandleNPC(true)
		else
			break
		end
	end
end

function RoundClass:Intermission(time: number)
	for i = 1, time do
		task.wait(1)
		self:Feedback("Round starting in " .. time - i)
	end
end

function RoundClass:ClearNpc()
	if self.Npc then
		for _, npc in ipairs(self.Npc) do
			npc:CleanUp()
		end
		self.Npc = {}
	end
end

function RoundClass:CleanUp()
	self.Active = false
	self.Map:Destroy()

	self:ClearNpc()
end
return RoundClass
