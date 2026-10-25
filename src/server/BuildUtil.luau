--!strict
local Util = {}
function Util.part(parent, name, size, cf, color, material, collide)
	local part = Instance.new("Part")
	part.Name = name
	part.Size = size
	part.CFrame = cf
	part.Color = color or Color3.fromRGB(58,65,80)
	part.Material = material or Enum.Material.Metal
	part.Anchored = true
	part.CanCollide = collide ~= false
	part.CanTouch = false
	part.CanQuery = part.CanCollide
	part:SetAttribute("TowerSolid",part.CanCollide)
	part.TopSurface = Enum.SurfaceType.Smooth
	part.BottomSurface = Enum.SurfaceType.Smooth
	part.Parent = parent
	return part
end
function Util.label(part, text, color)
	local gui = Instance.new("BillboardGui")
	gui.Name = "Sign"
	gui.Size = UDim2.fromOffset(240,60)
	gui.StudsOffset = Vector3.new(0,4,0)
	gui.MaxDistance = 95
	gui.AlwaysOnTop = false
	gui.Parent = part
	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1,1)
	label.BackgroundTransparency = 1
	label.Text = text
	label.TextColor3 = color or Color3.new(1,1,1)
	label.TextStrokeTransparency = 0.3
	label.Font = Enum.Font.GothamBold
	label.TextScaled = true
	label.Parent = gui
end
function Util.folder(parent,name)
	local folder = Instance.new("Folder")
	folder.Name = name
	folder.Parent = parent
	return folder
end
return Util
