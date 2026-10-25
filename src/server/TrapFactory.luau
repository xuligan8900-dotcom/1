--!strict
local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Definitions = require(Shared.TrapDefinitions)
local U = require(script.Parent.BuildUtil)
local Difficulty=require(Shared.Difficulty)
local Route=require(Shared.Route)
local Geometry=require(Shared.TrapGeometry)
local Factory = {}
local metal = Color3.fromRGB(75,83,104)
local danger = Color3.fromRGB(255,75,70)
function Factory.create(parent, kind, surface, stage, station)
	local definition=Difficulty.trap(assert(Definitions[kind],"Unknown trap "..kind),stage,station)
	assert(definition.Size>0 and definition.Speed>0 and definition.Safe>0 and definition.Warning>0 and definition.Active>0)
	local model = Instance.new("Model")
	model.Name = kind .. "_" .. station
	model:SetAttribute("Kind",kind)
	model:SetAttribute("Stage",stage.Id)
	for key,value in definition do model:SetAttribute(key,value) end
	model:SetAttribute("Speed", definition.Speed)
	-- Some rooms share a clock; others have clearly staggered warnings.
	model:SetAttribute("Phase", if stage.Id == 30 or stage.Id == 47 then stage.Phase else stage.Phase + station * 1.35)
	local direction=Vector3.new(definition.DirectionX,definition.DirectionY,definition.DirectionZ)
	model:SetAttribute("Direction",if direction.Magnitude>0 then direction.Unit else Vector3.xAxis)
	local base = surface
	if kind == "press" then base *= CFrame.new(0,Geometry.PressRestHeight,0)
	elseif kind == "pendulum" then base *= CFrame.new(0,12,0)
	elseif kind == "pusher" then base *= CFrame.new(-6,2,0)
	elseif kind == "ring" then base *= CFrame.new(0,3.5,0)
	elseif kind == "door" then base *= CFrame.new(0,Geometry.DoorRestCenter,0)
	elseif kind == "laser" then base *= CFrame.new(0,2,0)
	elseif kind == "rotor" or kind == "doubleRotor" or kind == "blade" then base *= CFrame.new(0,Geometry.SweepHeight,0)
	end
	model:SetAttribute("Base",base)
	model.WorldPivot = base
	local function piece(name,size,localCF,hazard,carry,solid)
		local p = U.part(model,name,size,base*localCF,if hazard then danger else metal,
			if hazard then Enum.Material.Neon else Enum.Material.DiamondPlate,solid)
		p:SetAttribute("Hazard",hazard == true)
		p:SetAttribute("Carry",carry == true and definition.Carry)
		p:SetAttribute("Signal",hazard == true or kind == "fade" or kind == "timer")
		return p
	end
	if kind == "move" or kind == "lift" or kind == "orbit" or kind == "fade" or kind == "timer" or kind == "conveyor" then
		local deckWidth,deckDepth=Route.carrierSize(stage.Id)
		piece("Deck",Vector3.new(deckWidth,1,deckDepth),CFrame.new(0,-0.5,0),false,true,true)
		for x=-1,1,2 do
			piece("EdgeLight",Vector3.new(0.15,0.08,deckDepth-0.2),CFrame.new(x*(deckWidth/2-0.15),0.04,0),false,false,false).Color = Color3.fromRGB(70,220,255)
		end
		if kind == "lift" then
			piece("MovingColumn",Vector3.new(2.8,6,2.8),CFrame.new(0,-4,0),false,false,false)
		end
		if kind == "conveyor" then
			for z=-1,1 do
				local stripe = piece("BeltMark",Vector3.new(deckWidth-0.4,0.04,0.16),CFrame.new(0,0.05,z),false,false,false)
				stripe.Color = Color3.fromRGB(255,195,60)
			end
			U.label(model.Deck, "⇧ BELT ⇧",Color3.fromRGB(255,195,60))
		end
	elseif kind == "gear" then
		local deck = piece("GearDeck",Vector3.new(0.9,Geometry.GearDiameter,Geometry.GearDiameter),CFrame.new(0,-0.45,0)*CFrame.Angles(0,0,math.pi/2),false,true,true)
		deck.Shape = Enum.PartType.Cylinder
		for n=0,11 do
			local a=n*math.pi/6
			piece("Tooth",Vector3.new(0.7,0.65,0.9),CFrame.new(math.cos(a)*Geometry.GearToothRadius,-0.3,math.sin(a)*Geometry.GearToothRadius)*CFrame.Angles(0,-a,0),true,false,false)
		end
		piece("Sector",Vector3.new(1.5,0.08,4),CFrame.new(0,0.06,0),false,false,false).Color=Color3.fromRGB(60,230,170)
	elseif kind == "rotor" or kind == "doubleRotor" or kind == "blade" then
		piece("Axle",Vector3.new(0.6,2,0.6),CFrame.new(0,-1,0),false,false,false)
		if kind=="blade" then
			-- Three short paddles; no lethal upper bar or reach into the waiting pad.
			for index=0,2 do
				local angle=index*math.pi*2/3
				local offset=CFrame.new(math.cos(angle)*Geometry.BladeCenter,0,math.sin(angle)*Geometry.BladeCenter)*CFrame.Angles(0,-angle,0)
				piece(if index==0 then "Sweep" elseif index==1 then "CrossSweep" else "ThirdSweep",
					Vector3.new(Geometry.BladeLength,Geometry.SweepThickness,0.75),offset,true,false,false)
			end
		else
			piece("Sweep",Vector3.new(Geometry.SweepLength,Geometry.SweepThickness,0.45),CFrame.new(),true,false,false)
			if kind=="doubleRotor" then
				piece("CrossSweep",Vector3.new(0.45,Geometry.SweepThickness,Geometry.SweepLength),CFrame.new(),true,false,false)
			end
		end
	elseif kind == "pendulum" then
		piece("Shaft",Vector3.new(0.35,9,0.35),CFrame.new(0,-4.5,0),false,false,false)
		piece("Hammer",Vector3.new(if stage.Id>=34 then 4.2 else 3.5,2.2,2.5),CFrame.new(0,-9.5,0),true,false,false)
	elseif kind == "press" then
		piece("Piston",Vector3.new(1,5,1),CFrame.new(0,3,0),false,false,false)
		piece("Crusher",Vector3.new(7,1.5,4),CFrame.new(),true,false,true)
	elseif kind == "pusher" then
		piece("Ram",Vector3.new(1.2,3,3),CFrame.new(),true,false,true)
	elseif kind == "laser" then
		piece("Beam",Vector3.new(10,0.35,0.35),CFrame.new(),true,false,false)
	elseif kind == "ring" then
		for n=0,9 do
			local a=n*math.pi/6
			piece("Rim",Vector3.new(1.9,0.5,0.5),CFrame.new(math.cos(a)*3.7,math.sin(a)*3.7,0)*CFrame.Angles(0,0,a+math.pi/2),true,false,false)
		end
		piece("Spoke",Vector3.new(3.5,0.4,0.4),CFrame.new(1.75,0,0),true,false,false)
	elseif kind == "door" then
		piece("Shutter",Vector3.new(9,6,0.7),CFrame.new(),false,false,true)
	end
	local signal=piece("WarningStrip",Vector3.new(2,0.12,0.2),CFrame.new(0,0.15,2.8),false,false,false)
	signal.Material=Enum.Material.Neon
	signal:SetAttribute("Signal",true)
	if stage.Id%5==0 then
		local attachment=Instance.new("Attachment")
		attachment.Parent=signal
		local sparks=Instance.new("ParticleEmitter")
		sparks.Name="WarningSparks"
		sparks.Enabled=false
		sparks.Rate=0
		sparks.Texture="rbxasset://textures/particles/sparkles_main.dds"
		sparks.Color=ColorSequence.new(Color3.fromRGB(255,190,60))
		sparks.Lifetime=NumberRange.new(0.15,0.4)
		sparks.Speed=NumberRange.new(2,5)
		sparks.Parent=attachment
	end
	if definition.Size~=1 then model:ScaleTo(definition.Size) end
	model.Parent = parent
	model:AddTag("TowerMechanism")
	return model
end
return Factory
