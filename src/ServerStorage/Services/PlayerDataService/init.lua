--[[ Documentation

	Client.GetData
		returns GetData

	GetData
		Returns the profile.Data
		if profile.Data doesn't exist it will yield until it does or until the player leaves

	AddMoney(player, amount)
		Increments the cash value of the player

	RemoveMoney(player, amount) : boolean
		Checks if you can remove the amount with out exceeding zero
		returns if amount can be removed

	Client.HandleWeapon() : (boolean, string)
		Checks if weapon is owned then equips it. If it's already equip it does nothing
		If the weapon is not owned it checks if a purchase is possible if it is then it equips it
		returns success : boolean, message : string
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local MarketplaceService = game:GetService("MarketplaceService")
local ServerStorage = game:GetService("ServerStorage")

local Knit = require(ReplicatedStorage.Packages.Knit)
local ProfileService = require(ServerStorage.Source.Services.ProfileService)

local SharedModule = ReplicatedStorage.Source.Modules
local weaponDataModule = require(SharedModule.WeaponData)

local config = require(script.config)

local PlayerDataService = Knit.CreateService({
	Name = "PlayerDataService",
	Client = {
		CashUpdate = Knit.CreateSignal(),
		PlayerDataIsReady = Knit.CreateSignal(),
	},
})

local DataStoreSettings = config.DataStoreSettings

local ProfileStore = ProfileService.GetProfileStore("PlayerDataV1", DataStoreSettings.ProfileStoreTemplate)
if RunService:IsStudio() == true then
	ProfileStore = ProfileStore.Mock
end

function PlayerDataService.Client:GetData(player: Player): table | nil
	local data = self.Server:GetData(player)
	print(data)
	return data
end

function PlayerDataService:GetData(player: Player): table | nil
	if self.CachedProfiles[player] then
		return self.CachedProfiles[player].Data
	else
		repeat
			task.wait()
		until not player or self.CachedProfiles[player]
		if self.CachedProfiles[player] then
			return self.CachedProfiles[player].Data
		end
	end
	return nil
end

function PlayerDataService.Client:HandleWeapon(player: Player, weaponName: string): (boolean, string | nil)
	local weaponData = weaponDataModule.Weapons[weaponName]
	local profile = self.Server.CachedProfiles[player]
	if profile and weaponData then
		--// check if weapon is already owned if so then equip it.
		if profile.Data.Weapons[weaponName] and profile.Data.CurrentWeapon ~= weaponName then
			profile.Data.CurrentWeapon = weaponName
			self.Server.PlayerService:EquipWeapon(player, profile.Data.CurrentWeapon)
			return true, "Equipped " .. weaponName
		else -- not owned
			local price = weaponData.Price
			local removedMoney: boolean = self.Server:RemoveMoney(player, price)
			if removedMoney then
				profile.Data.CurrentWeapon = weaponName
				profile.Data.Weapons[weaponName] = {}

				self.Server.PlayerService:EquipWeapon(player, profile.Data.CurrentWeapon)
				return true, "Successful purchase"
			else
				return false, "Not enough money"
			end
		end
	end
	return false, nil
end

function PlayerDataService:RemoveMoney(player: Player, amount: number): boolean
	local Profile = self.CachedProfiles[player]
	local isSuccessful: boolean = false
	if Profile and tonumber(amount) then
		if (Profile.Data.Cash - amount) >= 0 then
			isSuccessful = true
			Profile.Data.Cash -= amount

			--// tell client controller to update cash
			self.Client.CashUpdate:Fire(player, Profile.Data.Cash)
		end
	end
	return isSuccessful
end

function PlayerDataService:AddMoney(player: Player, amount: number)
	local Profile = self.CachedProfiles[player]
	if Profile and tonumber(amount) then
		Profile.Data.Cash += amount

		--// tell client controller to update cash
		self.Client.CashUpdate:Fire(player, Profile.Data.Cash)
	end
end

function PlayerDataService:Wipe(player: Player)
	ProfileStore:WipeProfileAsync("Player_" .. player.UserId)
end

function PlayerDataService:PlayerLoaded(player: Player, profile: table)
	if profile then
		--// tell client controller to update cash
		self.Client.CashUpdate:Fire(player, profile.Data.Cash)

		--// equip weapon
		self.PlayerService:EquipWeapon(player, profile.Data.CurrentWeapon)
	end
end

function PlayerDataService:PlayerAdded(player: Player)
	local Profile = ProfileStore:LoadProfileAsync("Player_" .. player.UserId, "ForceLoad")
	if Profile ~= nil then
		Profile:AddUserId(player.UserId) -- GDPR compliance
		Profile:Reconcile() -- Fill in missing variables from ProfileTemplate
		Profile:ListenToRelease(function()
			self.CachedProfiles[player] = nil
			player:Kick("Your profile has been loaded in another server. Please rejoin.")
		end)

		if player:IsDescendantOf(Players) then -- loaded data
			self.CachedProfiles[player] = Profile
			PlayerDataService:PlayerLoaded(player, Profile)
		else
			Profile:Release()
		end
	else
		player:Kick("Unable to load data. Please rejoin.")
	end
end

function PlayerDataService:KnitInit()
	self.CachedProfiles = {}
end

function PlayerDataService:KnitStart()
	--// Services
	self.PlayerService = Knit.GetService("PlayerService")

	--// Check if players already in
	for _, player in ipairs(Players:GetPlayers()) do
		task.spawn(function()
			self:PlayerAdded(player)
		end)
	end

	Players.PlayerAdded:Connect(function(player: Player)
		self:PlayerAdded(player)
	end)

	Players.PlayerRemoving:Connect(function(player)
		local Profile = self.CachedProfiles[player]
		if Profile then
			Profile:Release()
		end
	end)

	self.util = require(script.util)
	MarketplaceService.ProcessReceipt = self.util.ProcessReceipt
end

return PlayerDataService
