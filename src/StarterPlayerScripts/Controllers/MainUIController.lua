--[[ Documentation
	LoadShop
		This generates all the weapons from weaponDataModule with a viewport class.
		Displays in the correct DisplayOrder
		AutoFits weapon into the frame
		Applies the correct data to the, ("Equipped", "Owned")
		Connects to a signal so when the viewport is clicked it fires the HandleWeapon method from PlayerDataService
		Makes the shop visible 
	
	UnloadShop
		Cleans up all the viewports
		Makes the shop Invisible
	
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Knit = require(ReplicatedStorage.Packages.Knit)
local Janitor = require(ReplicatedStorage.Packages.Janitor)

local assets: Folder = ReplicatedStorage.Assets

local classes: Folder = script.Parent.Parent.Classes
local viewportClass = require(classes.ViewportClass)

local SharedModules: Folder = ReplicatedStorage.Source.Modules
local weaponDataModule = require(SharedModules.WeaponData)

local MainUIController = Knit.CreateController({
	Name = "MainUIController",
})

function MainUIController:LoadShop()
	--// loop through all weapons
	for weaponName, weapon in pairs(weaponDataModule.Weapons) do
		local viewportFrame: ViewportFrame = assets.UI.ShopViewportTemplate:Clone()
		viewportFrame.Name = weapon.DisplayOrder
		viewportFrame.CurrentCamera = self.ViewportCamera

		--// set weapon name here
		viewportFrame.NameText.Text = tostring(weaponName)

		--// handle action text. if owned and currentWeapon then display equipped. if owned then display owned. if not owned then display price
		if self.PlayerData.CurrentWeapon == weaponName then
			viewportFrame.PriceText.Text = "Equipped"
		elseif self.PlayerData.Weapons[weaponName] then
			viewportFrame.PriceText.Text = "Owned"
		else
			viewportFrame.PriceText.Text = "$" .. weapon.Price
		end

		--// parent the viewport after finishing setting up all the labels
		viewportFrame.Parent = self.ShopFrame.ShopFrame

		--// grabbing the weapon from assets and putting it in the viewport
		local weaponObject = assets.Weapons:FindFirstChild(weaponName):Clone()
		if weaponObject then
			weaponObject.Parent = viewportFrame
		end

		--// fit object to camera frame
		local ObjectExtents: Vector3 = weaponObject:GetExtentsSize()
		weaponObject:PivotTo(
			self.ViewportCamera.CFrame * CFrame.Angles(math.rad(90), 0, 0)
				+ (self.ViewportCamera.CFrame.LookVector * math.max(ObjectExtents.X * 2, ObjectExtents.Y * 4))
		)

		local viewportObject = viewportClass.new(viewportFrame, weaponObject)
		--// handle purchase here
		viewportObject.SelectSignal:Connect(function()
			local isSuccessful, result, msg = self.PlayerDataService:HandleWeapon(weaponName):await()

			if isSuccessful then
				if result then
					--// find last weapon viewport and change the text to owned
					if self.PlayerData.CurrentWeapon ~= "" then
						local lastCurrentWeaponId = weaponDataModule.GetWeaponDisplayOrderId(
							self.PlayerData.CurrentWeapon
						) or 0
						local lastCurrentWeaponViewport = self.ShopFrame.ShopFrame:FindFirstChild(lastCurrentWeaponId)
						if lastCurrentWeaponViewport then
							lastCurrentWeaponViewport.PriceText.Text = "Owned"
						end
					end

					--// update the players data
					self.PlayerData.CurrentWeapon = weaponName
					self.PlayerData.Weapons[weaponName] = {}

					--// update the text
					viewportFrame.PriceText.Text = "Equipped"
				end

				--// this will be use for user feedback
				if msg then
					print(msg)
				end
			else
				warn("Failed to call HandleWeapon method.")
			end
		end)

		--// rename shop button text for new action
		self.ShopFrame.ShopButton.Text = "CLOSE"
		self.ShopFrame.ShopButton.BackgroundColor3 = Color3.fromRGB(227, 14, 14)

		--// added to a table to clean up later. Not using janitor so I can call the cleanup method
		table.insert(self.ActiveViewports, viewportObject)
	end

	self.ShopFrame.ShopFrame.Visible = true
end

function MainUIController:UnloadShop()
	--// clean up will remove everything and disconnect everything.
	for _, viewportObject in ipairs(self.ActiveViewports) do
		viewportObject:CleanUp()
	end

	--// rename shop button text for new action
	self.ShopFrame.ShopButton.Text = "SHOP"
	self.ShopFrame.ShopButton.BackgroundColor3 = Color3.fromRGB(14, 199, 227)

	self.ActiveViewports = {}
	self.ShopFrame.ShopFrame.Visible = false
end

function MainUIController:KnitInit()
	print("Fired controller")
	self.Player = Players.LocalPlayer
	self.MainUI = assets.UI:FindFirstChild("Main") or assets.UI:WaitForChild("Main")

	--// viewport
	self.ViewportCamera = Instance.new("Camera")
	self.ActiveViewports = {}

	--// main frames
	self.MainMenu = self.MainUI.MainMenu
	self.ShopFrame = self.MainUI.Shop
	self.FeedbackFrame = self.MainUI.Feedback
	self.CurrencyFrame = self.MainUI.Currency

	--// Services
	self.PlayerService = Knit.GetService("PlayerService")
	self.RoundService = Knit.GetService("RoundService")
	self.PlayerDataService = Knit.GetService("PlayerDataService")

	--// Set mainUI to the player on join
	self.MainUI.Parent = self.Player.PlayerGui
end

function MainUIController:KnitStart()
	self.PlayerData = {}
	--// grab data. wait for response. it'll yield until data is ready
	self.PlayerDataService
		:GetData()
		:andThen(function(data)
			self.PlayerData = data
		end)
		:await()

	--// connect feedback
	self.RoundService.Feedback:Connect(function(msg: string)
		self.FeedbackFrame.FeedbackText.Text = tostring(msg)
	end)

	--// connect cash update
	self.PlayerDataService.CashUpdate:Connect(function(cash: number)
		self.CurrencyFrame.CashText.Text = "Cash: " .. tostring(cash)
	end)

	--// connect mainUI buttons
	self.MainMenu.PlayButton.Activated:Connect(function()
		local isCharacterLoaded = self.PlayerService:LoadCharacter():await() --// yields until character is loaded
		if isCharacterLoaded then
			self.MainMenu.Parent = nil
		end
	end)

	--// connect Shop button
	self.ShopFrame.ShopButton.Activated:Connect(function()
		if not self.ShopFrame.ShopFrame.Visible then
			self:LoadShop()
		else
			self:UnloadShop()
		end
	end)

	--// character removed reapply mainMenu
	self.Player:GetPropertyChangedSignal("Character"):Connect(function()
		if self.Player.Character == nil then
			self.MainMenu.Parent = self.MainUI
		end
	end)
end

return MainUIController
