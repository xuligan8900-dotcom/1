--!strict
local PhysicsService=game:GetService("PhysicsService")
local Shared=game:GetService("ReplicatedStorage").Shared
local Rules=require(Shared.RecoveryRules)
local Route=require(Shared.Route)
local Config=require(Shared.GameConfig)
local Definitions=require(Shared.StageDefinitions)
local U=require(script.Parent.BuildUtil)
local Recovery={}
function Recovery.configure()
	for section=0,Rules.FloorCount do
		local name=Rules.playerGroup(section)
		if not PhysicsService:IsCollisionGroupRegistered(name) then PhysicsService:RegisterCollisionGroup(name) end
	end
	for floor=1,Rules.FloorCount do
		local name=Rules.floorGroup(floor)
		if not PhysicsService:IsCollisionGroupRegistered(name) then PhysicsService:RegisterCollisionGroup(name) end
		PhysicsService:CollisionGroupSetCollidable(name,"Default",false)
		for section=0,Rules.FloorCount do
			PhysicsService:CollisionGroupSetCollidable(name,Rules.playerGroup(section),Rules.canStandOn(section,floor))
		end
	end
end
function Recovery.update(player,profile)
	local section=Rules.section(profile.RunStage)
	player:SetAttribute("RecoveryStage",section*Rules.Interval)
	local character=player.Character
	if not character or character:GetAttribute("TowerSection")==section then return end
	character:SetAttribute("TowerSection",section)
	for _,part in character:GetDescendants() do
		if part:IsA("BasePart") then part.CollisionGroup=Rules.playerGroup(section) end
	end
end
function Recovery.bindCharacter(player,profile,character)
	if profile.CollisionConnection then profile.CollisionConnection:Disconnect() end
	Recovery.update(player,profile)
	profile.CollisionConnection=character.DescendantAdded:Connect(function(part)
		if part:IsA("BasePart") then part.CollisionGroup=Rules.playerGroup(Rules.section(profile.RunStage)) end
	end)
end
function Recovery.build(tower)
	for floor=1,Rules.FloorCount do
		local completed=floor*Rules.Interval
		local height=Rules.floorHeight(floor)
		local model=Instance.new("Model")
		model.Name="Recovery_"..completed
		model:SetAttribute("UnlockStage",completed)
		model:SetAttribute("FloorHeight",height)
		model.Parent=tower.RecoveryFloors
		local accent=Config.ZoneColors[math.ceil(completed/10)]
		local deck=U.part(model,"CatchDeck",Vector3.new(108,1.2,108),CFrame.new(0,height-0.6,0),Color3.fromRGB(104,116,132),Enum.Material.DiamondPlate)
		for _,edge in {-53,53} do
			U.part(model,"SafetyRail",Vector3.new(1,3,108),CFrame.new(edge,height+1.5,0),accent)
			U.part(model,"SafetyRail",Vector3.new(106,3,1),CFrame.new(0,height+1.5,edge),accent)
		end
		-- Rejoin node 8 of the completed stage: only 3.33 studs above the floor.
		-- Two broad steps approach it radially, without teleporting a fallen player.
		local x,y,z=Route.point(completed,8,Definitions[completed].Layout)
		local outward=Vector3.new(x,0,z).Unit
		local endpoint=Vector3.new(x,y,z)
		for step=1,2 do
			local top=height+(y-height)*step/3
			local position=endpoint+outward*((3-step)*4)
			U.part(model,"ReturnStep_"..step,Vector3.new(5,1,5),CFrame.new(position.X,top-0.5,position.Z),accent)
		end
		local sign=U.part(model,"ReturnMarker",Vector3.new(1,0.15,1),CFrame.new(x,height+0.15,z)+outward*10,accent,Enum.Material.Neon,false)
		U.label(sign,string.format("SAFETY FLOOR · %d–%d\n⇧ STAIRS → CHECKPOINT %d",completed+1,math.min(completed+5,50),completed),accent)
		U.label(deck,string.format("RECOVERY %d\nFALLS STOP HERE AFTER CHECKPOINT %d",completed,completed),accent)
		for _,part in model:GetDescendants() do
			if part:IsA("BasePart") then part.CollisionGroup=Rules.floorGroup(floor) end
		end
	end
end
return Recovery
