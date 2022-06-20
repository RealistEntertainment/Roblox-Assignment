local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Signal = require(ReplicatedStorage.Packages.Signal)
local janitor = require(ReplicatedStorage.Packages.Janitor)

local PlacementViewport = {}
PlacementViewport.__index = PlacementViewport

function PlacementViewport.new(Viewport: ViewportFrame, ViewportObject: Model)
	local self = setmetatable({}, PlacementViewport)
	self.Viewport = Viewport
	self.Object = ViewportObject

	self.IsRendering = false

	self.janitor = janitor.new()
	-- add viewport to janitor
	self.janitor:Add(self.Viewport)
	-- Add InputBegan event to janitor
	self.janitor:Add(self.Viewport.InputBegan:Connect(function(inputObject)
		if
			inputObject.UserInputType == Enum.UserInputType.MouseMovement
			or inputObject.UserInputType == Enum.UserInputType.Touch
		then
			self:Hover()
		end
	end))
	-- Add InputEnded event to janitor
	self.janitor:Add(self.Viewport.InputEnded:Connect(function(inputObject)
		if inputObject.UserInputType == Enum.UserInputType.MouseMovement then
			self:UnHover()
		elseif
			inputObject.UserInputType == Enum.UserInputType.MouseButton1
			or inputObject.UserInputType == Enum.UserInputType.Touch
		then
			self:Select()
		end
	end))

	self.RenderJanitor = janitor.new()

	self.SelectSignal = Signal.new()

	return self
end

--// when the mouse enters the viewport. We being the rendering state
function PlacementViewport:Hover()
	if not self.IsRendering then
		self.IsRendering = true
		self.RenderJanitor:Add(RunService.RenderStepped:Connect(function()
			self.Object:PivotTo(self.Object.WorldPivot * CFrame.Angles(0, math.rad(1), 0))
		end))
	end
end

--// when the mouse exits the viewport we clean up the rendering functions. and exit rendering state
function PlacementViewport:UnHover()
	if self.IsRendering then
		self.IsRendering = false
		self.RenderJanitor:Cleanup()
	end
end

--// selected fires a signal when the viewport is clicked
function PlacementViewport:Select()
	self.SelectSignal:Fire(self.Object.Name)
end

function PlacementViewport:CleanUp()
	self.janitor:Destroy()
	self.RenderJanitor:Destroy()
	self.SelectSignal:DisconnectAll()
end

return PlacementViewport
