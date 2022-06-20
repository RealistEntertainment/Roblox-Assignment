--[[ Documentation
    The purpose of PlayerService is going to be for handling all of player changes.

	LoadCharacter(player)
		This is a client method
		This fires the loadCharacter method in the PlayerClass.
		Return if loading the character was possible.

	EquipWeapon(player, weaponName)
		removes the old weapon and add the new weapon.

]]

local Players = game:GetService("Players")
local ServerStorage = game:GetService("ServerStorage")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Knit = require(ReplicatedStorage.Packages.Knit)

local classes = ServerStorage.Source.Classes
local playerClass = require(classes.PlayerClass)

local assets = ServerStorage.Assets
local weaponAssets = assets.Weapons

local PlayerService = Knit.CreateService({
	Name = "PlayerService",
	Client = {},
})

--// called via client. Fires the load character method in the player class
function PlayerService.Client:LoadCharacter(player: Player): boolean
	if player then
		local thePlayer = self.Server.StoredPlayers[player.UserId]
		if thePlayer then
			thePlayer:LoadCharacter()
			return true
		end
	end
	return false
end

--// this function is called after successfully equipping a weapon in data
function PlayerService:EquipWeapon(player: Player, weaponName: string)
	local weaponTool = weaponAssets:FindFirstChild(weaponName)
	if weaponTool then
		--// clear Backpack, StarterGear, and Character of any tools
		player.Backpack:ClearAllChildren()
		player.StarterGear:ClearAllChildren()

		--// if the character exist find tools and destroy them
		if player.Character then
			for _, weapon: Tool in ipairs(player.Character:GetDescendants()) do
				if weapon:IsA("Tool") then
					weapon:Destroy()
				end
			end
		end

		--// add the new tool
		weaponTool:Clone().Parent = player.StarterGear
		weaponTool:Clone().Parent = player.Backpack
	end
end

function PlayerService:KnitInit()
	self.PlayerDataService = Knit.GetService("PlayerDataService")
	self.StoredPlayers = {}
end

function PlayerService:KnitStart()
	--// incase a player loads in before this service is started
	for _, player: Player in ipairs(Players:GetPlayers()) do
		local newPlayer = playerClass.new(player)
		self.StoredPlayers[player.UserId] = newPlayer
	end

	Players.PlayerAdded:Connect(function(player: Player)
		--// create a player class for the new plays
		if not self.StoredPlayers[player.UserId] then
			local newPlayer = playerClass.new(player)
			self.StoredPlayers[player.UserId] = newPlayer
		end
	end)

	Players.PlayerRemoving:Connect(function(player)
		if self.StoredPlayers[player.UserId] then
			self.StoredPlayers[player.UserId]:CleanUp()
			self.StoredPlayers[player.UserId] = nil
		end
	end)
end

return PlayerService
