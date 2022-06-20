--[[ Documentation
	This is the weaponClass. The base of all weapons

	new
		constructor

	DealDamage(target, damage)
		Checks if the target exists
		Checks if health > 0
		Calls Display Damage
		Applies damage to target
		Add Money based on Damage


	DisplayDamage(target, damage)
		Checks if target exits
		Creates a Display Number
		Projects Number with a random BezierCurve(with a loop simulating time by task.wait())
		Adds DisplayNumber to debris

	GetTarget
		Creates a BoundBox around the Character with the range of the weapon.
		Loops through all the possible targets. Checks if the player is looking at the npc by getting the angle to the target.
		Returns the closest npc that is in your view radius

	ApplyRagDoll(target, timeDurationInSeconds, force)
		Checks if target exists
		Creates BallSocketsConstraints replicated the targets Motor6D welds.
		Creates AngularForce for the targets head(because it was spinning around like crazy. This slows that down)
		Disables the Motor6D so parts can freely move
		Applies force to target with a debris( I remove this shortly after to act as a burst of force)
		yields till timeDurationInSeconds
		enables Motor6Ds
		Removes all constraints

--]]

local Players = game:GetService("Players")
local Debris = game:GetService("Debris")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local WeaponClass = {}
WeaponClass.__index = WeaponClass

local Knit = require(ReplicatedStorage.Packages.Knit)

function WeaponClass.new()
	local self = setmetatable({}, WeaponClass)

	self.PlayerDataService = Knit.GetService("PlayerDataService")

	return self
end

function WeaponClass:DealDamage(target: Model | BasePart, damage: number)
	if target and target.Parent then
		local humanoid: Humanoid = target.Parent:FindFirstChild("Humanoid") or target:FindFirstChild("Humanoid")
		if humanoid and tonumber(damage) and humanoid.Health > 0 then
			--// Rounding number so we don't get some huge number
			damage = math.round(damage)

			self:DisplayDamage(target, damage)
			humanoid:TakeDamage(damage)
			--// add cash to player
			self.PlayerDataService:AddMoney(Players:GetPlayerFromCharacter(self.Character), damage)
		end
	end
end

--// local functions. if this grows. I'll make a util or a math lib
local function lerp(a, b, c)
	return a + (b - a) * c
end

local function quadBezier(t, p0, p1, p2)
	local l1 = lerp(p0, p1, t)
	local l2 = lerp(p1, p2, t)
	local quad = lerp(l1, l2, t)
	return quad
end

--// projects out a number with a curve
function WeaponClass:DisplayDamage(target: Model | BasePart, damage: number)
	if target then --// make sure they exist
		task.spawn(function()
			local billboardUI: BillboardGui = Instance.new("BillboardGui")
			billboardUI.AlwaysOnTop = true
			billboardUI.Size = UDim2.new(2, 0, 2, 0)

			local damageText: TextLabel = Instance.new("TextLabel")
			damageText.Size = UDim2.new(1, 0, 1, 0)
			damageText.Text = tostring(damage)
			damageText.TextScaled = true
			damageText.BackgroundTransparency = 1
			damageText.TextColor3 = Color3.fromRGB(255, 0, 0)
			damageText.Parent = billboardUI

			billboardUI.Parent = target:FindFirstChild("Head") or target

			local RandomPos: Random = math.random(-2, 2) * 2
			local p0: Vector3 = Vector3.new(0, 3, 0)
			local p1: Vector3 = Vector3.new(RandomPos, 6, 0)
			local p2: Vector3 = p1 + p1
			for i = 0, 1, 0.05 do
				task.wait()

				if damageText then --// incase the target is removed
					local curve = quadBezier(i, p0, p1, Vector3.new(p2.X, p0.Y, 0))
					billboardUI.ExtentsOffset = curve
				end
			end
			--// remove item. letting them see it a little longer
			Debris:AddItem(billboardUI, 0.3)
		end)
	end
end

function WeaponClass:GetTarget(): Model
	local target = nil
	if self.Character then
		local CharacterCFrame: CFrame = self.Character:GetPivot()

		--// create the BoundsBox
		local overlap = OverlapParams.new()
		overlap.FilterType = Enum.RaycastFilterType.Whitelist
		overlap.FilterDescendantsInstances = { workspace.Npc }
		local targets = workspace:GetPartBoundsInBox(
			CharacterCFrame,
			Vector3.new(self.Range, self.Range, self.Range),
			overlap
		)

		--// loop through all the possible targets
		local lastDistance = math.huge
		local targetedNpc = {}
		for _, Child: BasePart in pairs(targets) do
			local isInTable = table.find(targetedNpc, Child.Parent)
			if Child.Parent:FindFirstChild("Humanoid") and not isInTable then
				--// add npc to targetNpc so we know it was already calculated
				local npcModel: Model = Child.Parent
				table.insert(targetedNpc, npcModel)

				--// handle the math if npc is in range and angle of the lookvector
				local npcCFrame: CFrame = npcModel:GetPivot()
				local distance: number = (npcCFrame.Position - CharacterCFrame.Position).Magnitude
				local angle = (npcCFrame.Position - CharacterCFrame.Position).Unit:Dot(CharacterCFrame.LookVector)

				print(angle, distance)
				if angle >= 0.5 and distance < lastDistance then
					lastDistance = distance
					target = npcModel
				end
			end
		end
	end
	return target
end

function WeaponClass:ApplyRagDoll(target: Model, timeDurationInSeconds: number, force: number)
	task.spawn(function() --// in a thread so the weapon function doesn't yield
		if target then
			local humanoid: Humanoid = target:FindFirstChild("Humanoid")
			if humanoid then
				--// here we are creating a BallSocketConstraint to keep parts together. Replicating the Motor6D welds.
				for _, weld: Motor6D in ipairs(target:GetDescendants()) do
					if weld:IsA("Motor6D") then
						local attachment0, attachment1 = Instance.new("Attachment"), Instance.new("Attachment")
						attachment0.Name = "ragdollAttachment"
						attachment1.Name = "ragdollAttachment"
						attachment0.CFrame = weld.C0
						attachment1.CFrame = weld.C1
						attachment0.Parent = weld.Part0
						attachment1.Parent = weld.Part1

						local ballConstraint: BallSocketConstraint = Instance.new("BallSocketConstraint")
						ballConstraint.Attachment0 = attachment0
						ballConstraint.Attachment1 = attachment1
						ballConstraint.Parent = weld.Part0
						weld.Enabled = false
					end
				end

				for _, part: BasePart in ipairs(target:GetDescendants()) do
					if part:IsA("BasePart") then
						if part.Name == "Head" then --// apply AngularVelocity to keep the head from flopping around overly unrealistic
							local rotationForce: BodyAngularVelocity = Instance.new("BodyAngularVelocity")
							rotationForce.AngularVelocity = Vector3.new(0, 0, 0)
							rotationForce.MaxTorque = Vector3.new(50, 50, 50)
							rotationForce.Parent = part
						end

						--// create part for colliding later on
						local collider: BasePart = Instance.new("Part")
						collider.Name = "Collider"
						collider.Size = part.Size / Vector3.new(15, 15, 15)
						collider.CFrame = part.CFrame
						collider.Transparency = 1

						--// weld collider part to characters part
						local weld: Weld = Instance.new("Weld")
						weld.Part0 = part
						weld.Part1 = collider
						weld.C0 = CFrame.new()
						weld.C1 = weld.Part1.CFrame:ToObjectSpace(weld.Part0.CFrame)
						weld.Parent = collider
						collider.Parent = part
					end
				end

				--// set humanoid state so it can be manipulated
				humanoid.PlatformStand = true

				--// apply force here
				local NewForce = Instance.new("BodyForce")
				local DefaultForce = 1000

				--// increased y vector for a better result
				NewForce.Force = (self.Character:GetPivot() + Vector3.new(0, target:GetExtentsSize().Y, 0)).LookVector
					* DefaultForce
					* force
				NewForce.Parent = target.PrimaryPart
				game.Debris:AddItem(NewForce, 0.2)

				task.wait(timeDurationInSeconds)
				if humanoid then --// after yielding we should make sure it exists still
					--// remove rag doll
					for _, child: any in ipairs(target:GetDescendants()) do
						if child:isA("Motor6D") then
							child.Enabled = true
						elseif
							child:isA("BallSocketConstraint")
							or child.Name == "ragdollAttachment"
							or child.Name == "Collider"
						then
							child:Destroy()
						end
					end

					humanoid.PlatformStand = false
				end
			end
		end
	end)
end

return WeaponClass
