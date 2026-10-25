--!strict
-- Runs automatically only in Studio after generation. No production mutations.
local Test={}
function Test.run(tower)
	local Shared=game:GetService("ReplicatedStorage").Shared
	local Definitions=require(Shared.StageDefinitions)
	local Route=require(Shared.Route)
	local Motion=require(Shared.TrapMotion)
	local Recovery=require(Shared.RecoveryRules)
	local Geometry=require(Shared.TrapGeometry)
	local Numeric=require(Shared.Numeric)
	local PhysicsService=game:GetService("PhysicsService")
	assert(Route.validate(Definitions))
	assert(#tower.RecoveryFloors:GetChildren()==9,"Missing catch floors")
	for floor=1,9 do
		local model=tower.RecoveryFloors:FindFirstChild("Recovery_"..floor*5)
		assert(model and model.CatchDeck.Size.X==108 and model.CatchDeck.Size.Z==108)
		assert(math.abs(model.CatchDeck.Position.Y+model.CatchDeck.Size.Y/2-Recovery.floorHeight(floor))<0.01)
		for section=0,9 do
			assert(PhysicsService:CollisionGroupsAreCollidable(Recovery.floorGroup(floor),Recovery.playerGroup(section))==Recovery.canStandOn(section,floor),"Incorrect recovery collision matrix")
		end
	end
	assert(game:GetService("Lighting").ClockTime==13.5,"Daylight settings missing")
	assert(tower:GetAttribute("Ready"))
	assert(#tower.Stages:GetChildren()==50)
	assert(#tower.Checkpoints:GetChildren()==50)
	assert(#tower.RouteGates:GetChildren()==100)
	local count=0
	for _,model in game:GetService("CollectionService"):GetTagged("TowerMechanism") do
		if not model:IsDescendantOf(tower) then continue end
		count+=1
		local base=model:GetAttribute("Base")
		assert(typeof(base)=="CFrame")
		local safe=model:GetAttribute("Safe")
		local warning=model:GetAttribute("Warning")
		local active=model:GetAttribute("Active")
		local speed=model:GetAttribute("Speed")
		local phase=model:GetAttribute("Phase")
		assert(speed>0 and warning/speed>=1.2-0.00001,"Warning window too short")
		assert(safe/speed>=3.6-0.00001,"Safe window too short")
		for _,sample in {0.1,safe+warning*0.5,safe+warning+active*0.5} do
			local time=(sample-phase)/speed
			local first,state,danger=Motion.evaluate(model,time)
			assert(danger==(state=="active"),"Green or warning trap can damage player")
			local second=Motion.evaluate(model,time)
			assert(first==second,"Nondeterministic mechanism")
			assert(first.Position.X==first.Position.X,"NaN mechanism transform")
			if sample<safe then assert(state=="safe")
			elseif sample<safe+warning then assert(state=="warning")
			else assert(state=="active") end
		end
		if model:GetAttribute("Kind")=="blade" or model:GetAttribute("Kind")=="doubleRotor" then
			assert(math.abs(model.CrossSweep.Position.Y-model.Sweep.Position.Y)<0.001,"Unfair double-height blade")
			assert(Numeric.near(model.Sweep.Size.X,if model:GetAttribute("Kind")=="blade" then Geometry.BladeLength else Geometry.SweepLength),"Unsafe blade reach")
		end
		if model:GetAttribute("Stage")==15 then assert(safe/speed>=5.5-0.00001,"Stage 15 crossing window missing") end
		for _,part in model:GetDescendants() do
			if part:IsA("BasePart") then assert(part.Anchored,"Uncontrolled physics assembly") end
		end
	end
	assert(count==150,"Missing mechanism instances")
	for n=1,50 do
		local checkpoint=tower.Checkpoints:FindFirstChild("Checkpoint_"..n)
		assert(checkpoint:GetAttribute("Stage")==n)
		assert(checkpoint:IsA("SpawnLocation") and checkpoint.Enabled and checkpoint.CanTouch,"Broken respawn checkpoint")
		local spawn=checkpoint:GetAttribute("Spawn")
		assert(spawn.Position.Y>checkpoint.Position.Y+2)
		local stage=tower.Stages:FindFirstChild(string.format("Stage_%02d_%s",n,Definitions[n].Name))
		assert(stage and stage:GetAttribute("StageId")==n)
	end
	print("[StudioSmoke] PASS: generated hierarchy, daylight, 9 recovery floors, collision matrix, 50 respawn checkpoints, 150 mechanisms, timing and deterministic poses. Physics and persistence still need playtesting.")
	return true
end
return Test
