--!strict
local Catalog=require(game:GetService("ReplicatedStorage").Shared.CosmeticCatalog)
local Cosmetic={}
local function color(rgb) return Color3.fromRGB(rgb[1],rgb[2],rgb[3]) end
local function marked(class,parent,name)
	local object=Instance.new(class)
	object.Name=name
	object:SetAttribute("TowerCosmetic",true)
	object.Parent=parent
	return object
end
function Cosmetic.apply(player,wallet)
	local character=player.Character
	local root=character and character:FindFirstChild("HumanoidRootPart")
	local head=character and character:FindFirstChild("Head")
	if not root or not head then return end
	for _,parent in {root,head} do
		for _,object in parent:GetChildren() do
			if object:GetAttribute("TowerCosmetic") then object:Destroy() end
		end
	end
	local trailId=wallet.Equipped.Trail
	if trailId~="trail_none" then
		local item=Catalog.ById[trailId]
		local a=marked("Attachment",root,"TowerTrailTop")
		a.Position=Vector3.new(0,0.4,0.65)
		local b=marked("Attachment",root,"TowerTrailBottom")
		b.Position=Vector3.new(0,-1,0.65)
		local trail=marked("Trail",root,"TowerTrail")
		trail.Attachment0=a; trail.Attachment1=b
		trail.Color=ColorSequence.new(color(item.Color),color(item.SecondColor or item.Color))
		trail.Transparency=NumberSequence.new(0.2,1)
		trail.Lifetime=0.45
		trail.MinLength=0.15
		trail.LightEmission=0.8
		trail.FaceCamera=true
	end
	local item=Catalog.ById[wallet.Equipped.Title]
	local gui=marked("BillboardGui",head,"TowerTitle")
	gui.Size=UDim2.fromOffset(180,25)
	gui.StudsOffset=Vector3.new(0,2.5,0)
	gui.MaxDistance=45
	local label=Instance.new("TextLabel")
	label.BackgroundTransparency=1
	label.Size=UDim2.fromScale(1,1)
	label.Text=item.Name
	label.TextColor3=color(item.Color)
	label.TextStrokeTransparency=0.35
	label.Font=Enum.Font.GothamBold
	label.TextSize=14
	label.Parent=gui
end
return Cosmetic
