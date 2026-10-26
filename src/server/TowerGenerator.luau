--!strict
local Lighting = game:GetService("Lighting")
local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Config = require(Shared.GameConfig)
local Definitions = require(Shared.StageDefinitions)
local Route = require(Shared.Route)
local U = require(script.Parent.BuildUtil)
local Builder = require(script.Parent.StageBuilder)
local Recovery=require(script.Parent.RecoveryService)
local Generator = {}
function Generator.generate()
	Recovery.configure()
	Lighting.ClockTime=13.5
	Lighting.Brightness=3.2
	Lighting.Ambient=Color3.fromRGB(166,176,194)
	Lighting.OutdoorAmbient=Color3.fromRGB(194,204,219)
	Lighting.GlobalShadows=false
	local existing=workspace:FindFirstChild("GeneratedTower")
	if existing then
		assert(existing:GetAttribute("Ready"),"Previous incomplete tower exists; stop Play before rebuilding")
		return existing
	end
	Route.validate(Definitions)
	local tower=Instance.new("Model")
	tower.Name="GeneratedTower"
	tower:SetAttribute("Ready",false)
	-- Parent only when the complete map is ready; auto character loading is disabled by bootstrap.
	for _,name in {"Foundation","StructuralSupports","Stages","Checkpoints","KillZones","FinishArea","RouteGates","RecoveryFloors"} do U.folder(tower,name) end
	U.part(tower.Foundation,"Foundation",Vector3.new(108,4,108),CFrame.new(0,0,0),Color3.fromRGB(35,40,50),Enum.Material.Concrete)
	U.part(tower.Foundation,"Lobby",Vector3.new(16,6,18),CFrame.new(42,5,0))
	U.part(tower.Foundation,"LobbyStep1",Vector3.new(10,2,4),CFrame.new(42,3,-15))
	U.part(tower.Foundation,"LobbyStep2",Vector3.new(10,4,4),CFrame.new(42,4,-11))
	local spawn=Instance.new("SpawnLocation")
	spawn.Name="LobbySpawn"
	spawn.Size=Vector3.new(8,1,8)
	spawn.CFrame=CFrame.new(42,8,0)
	spawn.Anchored=true
	spawn.Neutral=true
	spawn.Duration=0
	spawn.Transparency=1
	spawn.CanCollide=false
	spawn.Enabled=true -- Each player explicitly selects this or a completed checkpoint as RespawnLocation.
	spawn.Parent=tower.Foundation
	U.label(spawn,"MEGA MECHANICAL TOWER\n50 STAGES · SAFETY FLOORS EVERY 5",Config.ZoneColors[1])
	for _,x in {-47,47} do for _,z in {-47,47} do
		U.part(tower.StructuralSupports,"MainColumn",Vector3.new(3,1010,3),CFrame.new(x,503,z))
		U.part(tower.StructuralSupports,"ColumnLight",Vector3.new(0.25,1008,0.25),CFrame.new(x-1.6,503,z-1.6),Config.ZoneColors[5],Enum.Material.Neon,false)
	end end
	for level=0,10 do
		local y=level*100+4
		for _,z in {-47,47} do U.part(tower.StructuralSupports,"CrossBeam",Vector3.new(97,1.5,2),CFrame.new(0,y,z)) end
		for _,x in {-47,47} do U.part(tower.StructuralSupports,"CrossBeam",Vector3.new(2,1.5,97),CFrame.new(x,y,0)) end
	end
	local kill=U.part(tower.KillZones,"BottomKillZone",Vector3.new(4000,5,4000),CFrame.new(0,-65,0),nil,nil,false)
	kill.Transparency=1
	kill.CanTouch=true
	kill.Touched:Connect(function(hit)
		local character=hit:FindFirstAncestorOfClass("Model")
		local humanoid=character and character:FindFirstChildOfClass("Humanoid")
		if humanoid then humanoid.Health=0 end
	end)
	for _,definition in Definitions do Builder.build(tower,definition) end
	local secrets=U.folder(tower,"SecretRooms")
	for index,cf in ipairs({CFrame.new(52,208,-18),CFrame.new(-54,508,16),CFrame.new(18,808,54)}) do
		local room=U.part(secrets,"SecretRoom_"..index,Vector3.new(12,1,12),cf,Config.ZoneColors[(index%5)+1],Enum.Material.Neon,true)
		room:SetAttribute("SecretRoom",true)
		U.label(room,"SECRET ROOM\n+25 COINS",Config.ZoneColors[5])
	end
	Recovery.build(tower)
	local finish=tower.Checkpoints:FindFirstChild("Checkpoint_50")
	local finishCF=finish.CFrame*CFrame.new(0,-0.12,-11)
	U.part(tower.FinishArea,"CrownDeck",Vector3.new(26,1,22),finishCF*CFrame.new(0,-0.5,0),Color3.fromRGB(26,30,42))
	for _,x in {-12.5,12.5} do U.part(tower.FinishArea,"ViewingRail",Vector3.new(0.4,3,20),finishCF*CFrame.new(x,1.5,0),Config.ZoneColors[5]) end
	local portal=U.part(tower.FinishArea,"VictoryPortal",Vector3.new(12,0.5,1),finishCF*CFrame.new(0,10,-6),Config.ZoneColors[5],Enum.Material.Neon,false)
	for _,x in {-6,6} do U.part(tower.FinishArea,"PortalPillar",Vector3.new(0.5,10,1),finishCF*CFrame.new(x,5,-6),Config.ZoneColors[5],Enum.Material.Neon,false) end
	U.label(portal,"YOU WIN!\nMASTER MECHANIC",Config.ZoneColors[5])
	local attachment=Instance.new("Attachment")
	attachment.Position=Vector3.new(0,-4,0)
	attachment.Parent=portal
	local confetti=Instance.new("ParticleEmitter")
	confetti.Name="Confetti"
	confetti.Enabled=false
	confetti.Rate=0
	confetti.Texture="rbxasset://textures/particles/sparkles_main.dds"
	confetti.Color=ColorSequence.new(Config.ZoneColors[3],Config.ZoneColors[5])
	confetti.Lifetime=NumberRange.new(2,4)
	confetti.Speed=NumberRange.new(12,24)
	confetti.SpreadAngle=Vector2.new(180,180)
	confetti.Acceleration=Vector3.new(0,-18,0)
	confetti.Parent=attachment
	for _,item in {"Atmosphere","BloomEffect","ColorCorrectionEffect"} do
		if not Lighting:FindFirstChild("Tower"..item) then
			local effect=Instance.new(item)
			effect.Name="Tower"..item
			if item=="Atmosphere" then effect.Density=0.07; effect.Offset=0.15
			elseif item=="BloomEffect" then effect.Intensity=0.35; effect.Size=24; effect.Threshold=1.4
			else effect.Contrast=0.02; effect.Saturation=0.06 end
			effect.Parent=Lighting
		end
	end
	assert(#tower.Stages:GetChildren()==Config.StageCount)
	assert(#tower.Checkpoints:GetChildren()==Config.StageCount)
	assert(#tower.RouteGates:GetChildren()==Config.StageCount*2)
	local lastY=-math.huge
	for i=1,Config.StageCount do
		local cp=tower.Checkpoints:FindFirstChild("Checkpoint_"..i)
		assert(cp and cp.Position.Y>lastY,"Invalid checkpoint height")
		lastY=cp.Position.Y
	end
	tower:SetAttribute("Ready",true)
	tower.Parent=workspace
	local parts=0
	for _,object in tower:GetDescendants() do if object:IsA("BasePart") then parts+=1 end end
	print(string.format("[Tower] READY: 50 stages, 50 checkpoints, 100 route gates, %d parts; top %.1f studs",parts,lastY))
	return tower
end
return Generator
