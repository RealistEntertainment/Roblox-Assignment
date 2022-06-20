local ServerStorage = game:GetService("ServerStorage")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Knit = require(ReplicatedStorage.Packages.Knit)

for _, Child: ModuleScript in pairs(ServerStorage.Source:GetDescendants()) do
	local IsModule: boolean = Child:IsA("ModuleScript")
	local IsService: boolean = Child:IsDescendantOf(ServerStorage.Source.Services) and Child.Name:match("Service$")

	if IsModule and IsService then
		require(Child)
	end
end

Knit.Start()
	:andThen(function()
		print("Knit Started")
	end)
	:catch(warn)
