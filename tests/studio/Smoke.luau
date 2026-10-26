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
	local Traversal=require(Shared.Traversal)
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
	assert(#tower.CollectibleCoins:GetChildren()==100,"Missing map coins")
	local CoinRules=require(Shared.EconomyRules)
	for _,coin in tower.CollectibleCoins:GetChildren() do
		assert(CoinRules.validCoin(coin:GetAttribute("CoinId")),"Bad coin ID")
		assert(coin.Anchored and not coin.CanCollide and not coin.CanTouch,"Coins affect physics")
	end
	local templates=game:GetService("ServerStorage").TowerClubTemplates
	assert(#templates:GetChildren()==6,"Missing club models")
	local clubIds={}
	for _,tool in templates:GetChildren() do
		assert(tool:IsA("Tool") and tool.RequiresHandle and not tool.CanBeDropped,"Bad club tool")
		assert(tool:GetAttribute("TowerClub") and tool.Handle:IsA("BasePart"),"Club missing handle")
		assert(not clubIds[tool:GetAttribute("ClubId")],"Duplicate club template")
		clubIds[tool:GetAttribute("ClubId")]=true
		for _,part in tool:GetChildren() do
			if part:IsA("BasePart") then assert(not part.Anchored and part.Massless and not part.CanCollide and not part.CanQuery,"Club alters character collision/mass") end
		end
	end
	local remotes=game:GetService("ReplicatedStorage").Remotes
	assert(remotes.ClubAttack:IsA("RemoteEvent") and remotes.ClubSwing:IsA("RemoteEvent") and remotes.ClubHit:IsA("RemoteEvent"),"Club protocol missing")
	assert(remotes.ShopGetState:IsA("RemoteFunction") and remotes.ShopRequest:IsA("RemoteEvent"),"Shop protocol missing")
	assert(#tower.Checkpoints:GetChildren()==50)
	assert(#tower.RouteGates:GetChildren()==100)
	local slide=tower.FinishArea:FindFirstChild("VictoryWaterslide")
	assert(slide and #slide:GetChildren()>=20,"Missing victory waterslide")
	local slideSections=0
	for _,part in slide:GetChildren() do
		if part:IsA("BasePart") and part:GetAttribute("Waterslide") then
			slideSections+=1
			assert(part.Anchored and part.CanCollide,"Waterslide section is not physical")
		end
	end
	assert(slideSections==12,"Incomplete waterslide")
	assert(slide:FindFirstChild("DuckPool") and slide.DuckPool:GetAttribute("WaterslideWater"),"Missing duck pool")
	for duck=1,3 do assert(slide:FindFirstChild("Duck_"..duck),"Missing pool duck") end
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
		assert(stage:GetAttribute("Traversal")==Definitions[n].Traversal,"Traversal variant missing")
		if Definitions[n].Traversal=="posts" then
			for node=1,11,2 do
				local post=stage:FindFirstChild("Post_"..node)
				assert(post and post.Shape==Enum.PartType.Cylinder,"Missing hop column")
				local _,top=Route.point(n,node,Definitions[n].Layout)
				assert(Numeric.near(post.Position.Y+post.Size.X/2,top),"Column top not aligned to route")
			end
		elseif Definitions[n].Traversal~="jumps" then
			local walking=stage:FindFirstChild("Traversal_"..Definitions[n].Traversal)
			assert(walking,"Missing walking route")
			local count=0
			for _,part in walking:GetChildren() do
				if part:IsA("BasePart") and part:GetAttribute("TraversalSurface") then
					count+=1
					assert(part.Anchored and part.CanCollide,"Nonphysical walking beam")
					assert(Numeric.near(part:GetAttribute("WalkWidth"),Traversal.width(Definitions[n])),"Wrong beam width")
				end
			end
			assert(count>=6,"Incomplete walking route")
		end
	end
	print("[StudioSmoke] PASS: generated hierarchy, daylight, 9 recovery floors, collision matrix, 50 respawn checkpoints, 150 mechanisms, timing and deterministic poses. Physics and persistence still need playtesting.")
	return true
end
return Test
