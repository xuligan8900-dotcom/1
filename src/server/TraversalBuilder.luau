--!strict
local Shared=game:GetService("ReplicatedStorage").Shared
local Traversal=require(Shared.Traversal)
local Route=require(Shared.Route)
local U=require(script.Parent.BuildUtil)
local Builder={}
local labels={rails="BALANCE BEAMS",needles="NEEDLE WALK",zigzag="ZIGZAG CATWALK",pipes="PIPE CROSSING",wrap="AROUND THE COLUMNS",posts="COLUMN HOPS"}
local function vector(p) return Vector3.new(p.x,p.y,p.z) end
function Builder.post(parent,name,cf,diameter,accent)
	local height=4
	local part=U.part(parent,name,Vector3.new(height,diameter,diameter),
		CFrame.new(cf.Position-Vector3.new(0,height/2,0))*CFrame.Angles(0,0,math.pi/2),accent,Enum.Material.Concrete)
	part.Shape=Enum.PartType.Cylinder
	part:SetAttribute("TraversalPost",true)
	return part
end
function Builder.build(parent,definition,accent)
	local style=definition.Traversal or "jumps"
	if style=="jumps" then return end
	local model=Instance.new("Model")
	model.Name="Traversal_"..style
	model:SetAttribute("Style",style)
	model.Parent=parent
	for index,path in Traversal.paths(definition,Route) do
		for segment=1,#path.Points-1 do
			local a,b=vector(path.Points[segment]),vector(path.Points[segment+1])
			local direction=(b-a).Unit
			local up=(Vector3.yAxis-direction*direction.Y).Unit
			local center=(a+b)/2
			local part
			if path.Shape=="pipe" then
				part=U.part(model,"Pipe_"..index.."_"..segment,
					Vector3.new((b-a).Magnitude+0.5,path.Width,path.Width),
					CFrame.fromMatrix(center-Vector3.yAxis*path.Width/2,direction,up,direction:Cross(up)),
					Color3.fromRGB(155,169,185))
				part.Shape=Enum.PartType.Cylinder
			else
				part=U.part(model,"Beam_"..index.."_"..segment,
					Vector3.new(path.Width,0.45,(b-a).Magnitude+0.5),
					CFrame.lookAt(center-Vector3.yAxis*0.225,b-Vector3.yAxis*0.225),Color3.fromRGB(155,169,185),Enum.Material.DiamondPlate)
			end
			part:SetAttribute("WalkWidth",path.Width)
			part:SetAttribute("TraversalSurface",true)
			-- A slim center light makes the route legible without widening collision.
			U.part(model,"CenterStripe",Vector3.new(0.08,0.04,(b-a).Magnitude),
				CFrame.lookAt(center+up*0.035,b+up*0.035),accent,Enum.Material.Neon,false)
		end
		for point=2,#path.Points-1 do
			local p=path.Points[point]
			U.part(model,"CornerJoint",Vector3.new(path.Width,0.45,path.Width),CFrame.new(p.x,p.y-0.225,p.z),accent)
		end
		if path.Column then
			local p=path.Column
			U.part(model,"RouteColumn",Vector3.new(1.2,7,1.2),CFrame.new(p.x,p.y+3.5,p.z),Color3.fromRGB(95,108,129))
		end
	end
	local x,y,z=Route.point(definition.Id,4,definition.Layout)
	local sign=U.part(model,"TraversalSign",Vector3.new(0.1,0.1,0.1),CFrame.new(x,y+2,z),accent,nil,false)
	sign.Transparency=1
	U.label(sign,labels[style].."\n⇧ FOLLOW THE CENTER LIGHT",accent)
end
return Builder
