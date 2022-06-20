local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Knit = require(ReplicatedStorage.Packages.Knit)

local classes = script.Parent.Parent.Classes
local roundClass = require(classes.RoundClass)

local modules = script.Parent.Parent.Modules
local mapModule = require(modules.Maps)

local RoundService = Knit.CreateService({
	Name = "RoundService",
	Client = {
		Feedback = Knit.CreateSignal(),
	},
})

function RoundService:KnitInit()
	self.CurrentRound = nil
end

function RoundService:KnitStart()
	--// Start the round service loop
	task.spawn(function()
		while true do
			self.CurrentRound = roundClass.new(mapModule.RandomMap())
			self.CurrentRound:Start()
		end
	end)
end

return RoundService
