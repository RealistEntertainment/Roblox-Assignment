local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Knit = require(ReplicatedStorage.Packages.Knit)

for _, Child: ModuleScript in pairs(script.Parent:GetDescendants()) do
	local IsModule = Child:IsA("ModuleScript")

	local IsController = Child:IsDescendantOf(script.Parent.Controllers) and Child.Name:match("Controller$")
	if IsModule and IsController then
		require(Child)
	end
end

Knit.Start()
	:andThen(function()
		print("Knit Started")
	end)
	:catch(warn)
