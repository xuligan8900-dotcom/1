--!strict
local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Config = require(Shared.GameConfig)
local Route = require(Shared.Route)
local U = require(script.Parent.BuildUtil)
local Traps = require(script.Parent.TrapFactory)
local Builder = {}
function Builder.build(tower, definition)
	local id = definition.Id
	local stage = Instance.new("Model")
	stage.Name = string.format("Stage_%02d_%s",id,definition.Name)
	stage:SetAttribute("StageId",id)
	stage.Parent = tower.Stages
	local accent = Config.ZoneColors[definition.Zone]
	local frames = {}
	for node=0,12 do
		local x,y,z = Route.point(id,node,definition.Layout)
		local nx,_,nz = Route.point(id,math.min(node+1,12),definition.Layout)
		local point = Vector3.new(x,y,z)
		local tangent = if node==12 then Vector3.new(-z,0,x).Unit else Vector3.new(nx-x,0,nz-z).Unit
		frames[node] = CFrame.lookAt(point,point+tangent)
	end
	for node=0,12 do
		if node==0 and id>1 then continue end -- Previous checkpoint is this stage's safe start.
		local cf = frames[node]
		local station = if node==2 then 1 elseif node==6 then 2 elseif node==10 then 3 else nil
		local kind = if station then definition.Traps[station] else nil
		local moving = kind=="move" or kind=="lift" or kind=="orbit" or kind=="gear" or kind=="fade" or kind=="timer" or kind=="conveyor"
		local width = Route.width(id,node,definition.Layout)
		if not moving then
			local p = U.part(stage,"Landing_"..node,Vector3.new(width,1,Route.depth(id,node)),cf*CFrame.new(0,-0.5,0))
			U.part(stage,"RouteLight",Vector3.new(0.15,0.08,Route.depth(id,node)-0.3),cf*CFrame.new(-width/2+0.15,0.05,0),accent,Enum.Material.Neon,false)
			if node%4==0 then
				-- Side rails leave both route ends open and never close the fall shafts.
				for side=-1,1,2 do
					U.part(stage,"RestRail",Vector3.new(0.25,2.5,2.3),cf*CFrame.new(side*(width/2+0.25),1.25,0),accent)
				end
			end
			if node==0 then U.label(p,string.format("%02d · %s\n⇧ FOLLOW THE LIGHTS",id,definition.Name),accent) end
		end
		if definition.Layout=="maze" and (node==3 or node==5 or node==7 or node==9) then
			local side=if node%4==1 then -1 else 1
			U.part(stage,"MazeFin",Vector3.new(0.5,4,4),cf*CFrame.new(side*(width/2-0.4),2,0),accent)
		end
		if station then Traps.create(stage,kind,cf,definition,station) end
		if node==4 or node==8 then
			local gate = U.part(tower.RouteGates,"Gate_"..id.."_"..node,Vector3.new(9,7,7),cf*CFrame.new(0,3,0),accent,nil,false)
			gate.Transparency=1
			gate.CanQuery=false
			gate:SetAttribute("Stage",id)
			gate:SetAttribute("Order",node/4)
		end
		if node==12 then
			local cp=Instance.new("SpawnLocation")
			cp.Name="Checkpoint_"..id
			cp.Size=Vector3.new(4.8,0.2,2.6)
			cp.CFrame=cf*CFrame.new(0,0.12,0)
			cp.Color=accent
			cp.Material=Enum.Material.Neon
			cp.Anchored=true
			cp.CanCollide=false
			cp.CanQuery=false
			cp.CanTouch=true
			cp.Neutral=true
			cp.Enabled=true
			cp.Duration=0
			cp.AllowTeamChangeOnTouch=false
			cp.Parent=tower.Checkpoints
			cp:SetAttribute("Stage",id)
			cp:SetAttribute("Spawn",cf*CFrame.new(0,4,0))
			U.label(cp,string.format("CHECKPOINT %02d / 50\n%s",id,definition.Name),accent)
		elseif node%4==1 then
			local sign = U.part(stage,"Direction",Vector3.new(0.15,0.15,0.15),cf*CFrame.new(0,2.5,0),accent,nil,false)
			sign.Transparency=1
			U.label(sign,"WAIT FOR GREEN\n⇧ JUMP",accent)
		end
	end
	-- A few industrial details per zone, all outside the jumping corridor.
	local x,y,z=Route.point(id,6,definition.Layout)
	U.part(stage,"ServicePipe",Vector3.new(0.6,13,0.6),CFrame.new(x*1.32,y+3,z*1.32),accent)
	return stage
end
return Builder
