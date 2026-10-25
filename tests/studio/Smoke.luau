--!strict
-- Runs automatically only in Studio after generation. No production mutations.
local Test={}
function Test.run(tower)
	local Shared=game:GetService("ReplicatedStorage").Shared
	local Definitions=require(Shared.StageDefinitions)
	local Route=require(Shared.Route)
	local Motion=require(Shared.TrapMotion)
	assert(Route.validate(Definitions))
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
		assert(speed>0 and warning/speed>=0.7,"Warning window too short")
		assert(safe/speed>=2.5,"Safe window too short")
		for _,sample in {0.1,safe+warning*0.5,safe+warning+active*0.5} do
			local time=(sample-phase)/speed
			local first,state=Motion.evaluate(model,time)
			local second=Motion.evaluate(model,time)
			assert(first==second,"Nondeterministic mechanism")
			assert(first.Position.X==first.Position.X,"NaN mechanism transform")
			if sample<safe then assert(state=="safe")
			elseif sample<safe+warning then assert(state=="warning")
			else assert(state=="active") end
		end
		for _,part in model:GetDescendants() do
			if part:IsA("BasePart") then assert(part.Anchored,"Uncontrolled physics assembly") end
		end
	end
	assert(count==150,"Missing mechanism instances")
	for n=1,50 do
		local checkpoint=tower.Checkpoints:FindFirstChild("Checkpoint_"..n)
		assert(checkpoint:GetAttribute("Stage")==n)
		local spawn=checkpoint:GetAttribute("Spawn")
		assert(spawn.Position.Y>checkpoint.Position.Y+2)
		local stage=tower.Stages:FindFirstChild(string.format("Stage_%02d_%s",n,Definitions[n].Name))
		assert(stage and stage:GetAttribute("StageId")==n)
	end
	print("[StudioSmoke] PASS: generated hierarchy, 50 checkpoints, 150 mechanisms, timing and deterministic poses. Physics and persistence still need playtesting.")
	return true
end
return Test
