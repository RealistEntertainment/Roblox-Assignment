--[[Documentation
	This a the shared WeaponData module script. 

	[ItemNameReference]
		Price is used by server and client.
		DisplayOrder is used the name the ViewportFrame of that item. so it keeps the order

	GetWeaponDisplayOrderId(weaponName)
		This function returns the weapon DisplayOrder. This is used by the client to reference to the correct item
]]

local WeaponData = {}

WeaponData.Weapons = {}

WeaponData.Weapons["Baseball Bat"] = {
	Price = 350,
	DisplayOrder = 0001,
}

WeaponData.Weapons["King Bat"] = {
	Price = 1500,
	DisplayOrder = 0002,
}

function WeaponData.GetWeaponDisplayOrderId(weaponName): string
	for name, weaponData in pairs(WeaponData.Weapons) do
		if name == weaponName then
			return tostring(weaponData.DisplayOrder)
		end
	end
end
return WeaponData
