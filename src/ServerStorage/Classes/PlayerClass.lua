local ReplicatedStorage = game:GetService("ReplicatedStorage")
--[[ Documentation
    new
        This is the class constructor
    

]]

local Knit = require(ReplicatedStorage.Packages.Knit)

local PlayerClass = {}
PlayerClass.__index = PlayerClass

function PlayerClass.new(player: Player)
	local self = setmetatable({}, PlayerClass)

	self.Player = player

	--// services
	self.RoundService = Knit.GetService("RoundService")

	self.Character = nil

	player.CharacterAdded:Connect(function(character: Model)
		local Humanoid = character:WaitForChild("Humanoid")
		Humanoid.Died:Connect(function()
			self.Player.Character = nil
		end)
		self.Character = character
	end)

	return self
end

function PlayerClass:LoadCharacter()
	print("fired load")
	repeat
		task.wait()
		print(self.RoundService.CurrentRound)
	until self.RoundService.CurrentRound ~= nil

	local playerSpawn = self.RoundService.CurrentRound.PlayerSpawn
	local RandomSpawn: BasePart = playerSpawn:GetChildren()[math.random(1, #playerSpawn:GetChildren())]

	self.Player:LoadCharacter()
	self.Player.Character:PivotTo(RandomSpawn:GetPivot() + Vector3.new(0, 5, 0))
end
return PlayerClass
