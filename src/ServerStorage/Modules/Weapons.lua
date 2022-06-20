--[[ Documentation
	This a module script is for storing weapon data and functions. Each weapon inherits weaponClass. Along with it's own functions and data.

	Swing
		This method grabs the target and applies damage and ragdoll.
]]
--

local classes = script.Parent.Parent.Classes
local weaponClass = require(classes.WeaponClass)

local Weapons = {}

Weapons["Small Bat"] = function(character: Model)
	local weapon = weaponClass.new()
	weapon.Character = character

	weapon.Damage = 5
	weapon.Range = 8
	weapon.Delay = 0.3

	function weapon:Swing()
		print("Swing", character)
		if character then
			local target = weapon:GetTarget()
			if target then
				local ragdollTime = 0.6 --// time before the effect stops
				local ragdollForce = 1.25 --// 1000 * ragdollForce. This only lasts .2 seconds
				self:ApplyRagDoll(target, ragdollTime, ragdollForce)
				self:DealDamage(target, weapon.Damage)
			end
		end
		task.wait(weapon.Delay)
	end
	return weapon
end

Weapons["Baseball Bat"] = function(character: Model)
	local weapon = weaponClass.new()
	weapon.Character = character

	weapon.Damage = 10
	weapon.Range = 10
	weapon.Delay = 0.3

	function weapon:Swing()
		print("Swing", character)
		if character then
			local target = weapon:GetTarget()
			if target then
				local ragdollTime = 1 --// time before the effect stops
				local ragdollForce = 2 --// 1000 * ragdollForce. This only lasts .2 seconds
				self:ApplyRagDoll(target, ragdollTime, ragdollForce)
				self:DealDamage(target, weapon.Damage)
			end
		end
		task.wait(weapon.Delay)
	end
	return weapon
end

Weapons["King Bat"] = function(character: Model)
	local weapon = weaponClass.new()
	weapon.Character = character

	weapon.Damage = 15
	weapon.Range = 12
	weapon.Delay = 0.3

	function weapon:Swing()
		print("Swing", character)
		if character then
			local target = weapon:GetTarget()
			if target then
				local ragdollTime = 1 --// time before the effect stops
				local ragdollForce = 2.5 --// 1000 * ragdollForce. This only lasts .2 seconds
				self:ApplyRagDoll(target, ragdollTime, ragdollForce)
				self:DealDamage(target, weapon.Damage)
			end
		end
		task.wait(weapon.Delay)
	end
	return weapon
end

return Weapons
