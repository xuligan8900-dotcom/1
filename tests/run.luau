-- Execute with Luau CLI from any working directory: luau tests/run.luau
local Stages=require("../src/shared/StageDefinitions")
local Route=require("../src/shared/Route")
local Rules=require("../src/shared/ProgressRules")
local Schema=require("../src/shared/DataSchema")
local Traps=require("../src/shared/TrapDefinitions")
local MotionMath=require("../src/shared/MotionMath")
local checks=0
local function check(condition,message)
	assert(condition,message)
	checks+=1
end
check(Route.validate(Stages),"Route invariants")
local names={}
local used={}
local maxJump=0
for i,stage in Stages do
	check(not names[stage.Name],"Duplicate stage name")
	names[stage.Name]=true
	check(#stage.Traps==3,"Three real mechanisms per floor")
	for _,kind in stage.Traps do
		check(Traps[kind]~=nil,"Missing mechanism definition")
		used[kind]=true
	end
	for n=1,12 do
		local x,y,z=Route.point(i,n,stage.Layout)
		local px,py,pz=Route.point(i,n-1,stage.Layout)
		local distance=math.sqrt((x-px)^2+(z-pz)^2)
		maxJump=math.max(maxJump,distance)
		-- At 16 studs/s and JP50: analytical flight time to a +1.667 landing.
		local rise=y-py
		local flight=(50+math.sqrt(50^2-2*196.2*rise))/196.2
		check(distance<16*flight,"Center-to-center leap exceeds ballistic range")
		check(Route.width(i,n,stage.Layout)>=2.8,"Platform too narrow")
	end
end
for name in Traps do check(used[name],"Unused mechanism "..name) end
-- Exercise the actual oscillator: warning windows, activation, determinism,
-- disappearing surfaces, plus the complete translation envelope of every carrier.
for name,definition in Traps do
	for _,sample in {0.1,definition.Safe+definition.Warning/2,definition.Safe+definition.Warning+definition.Active/2} do
		local amount,z,angle,state,danger=MotionMath.sample(definition.Motion,sample,definition.Safe,definition.Warning,definition.Active,definition.Travel)
		local second=MotionMath.sample(definition.Motion,sample,definition.Safe,definition.Warning,definition.Active,definition.Travel)
		check(amount==second and amount==amount and z==z and angle==angle,"Nondeterministic or NaN motion")
		check(state==(if sample<definition.Safe then "safe" elseif sample<definition.Safe+definition.Warning then "warning" else "active"),"Bad trap window")
		if definition.Motion=="gate" or definition.Motion=="fade" or definition.Motion=="press" then
			check(danger==(state=="active"),"Unsafe activation timing")
		end
	end
end
for i,stage in Stages do
	for station,kind in stage.Traps do
		local definition=Traps[kind]
		local mode=definition.Motion
		if mode~="slide" and mode~="lift" and mode~="orbit" then continue end
		local node=station*4-2
		local x,y,z=Route.point(i,node,stage.Layout)
		local nx,_,nz=Route.point(i,node+1,stage.Layout)
		local length=math.sqrt((nx-x)^2+(nz-z)^2)
		local tx,tz=(nx-x)/length,(nz-z)/length
		for sample=0,31 do
			local amount,orbitZ=MotionMath.sample(mode,sample*math.pi/16,definition.Safe,definition.Warning,definition.Active,definition.Travel)
			local ox,oy,oz=0,0,0
			if mode=="lift" then oy=amount
			else ox=-tz*amount-tx*orbitZ; oz=tx*amount-tz*orbitZ end
			for _,neighbor in {node-1,node+1} do
				local ax,ay,az=Route.point(i,neighbor,stage.Layout)
				local rise=if neighbor<node then y+oy-ay else ay-y-oy
				local horizontal=math.sqrt((x+ox-ax)^2+(z+oz-az)^2)
				local discriminant=50^2-2*196.2*rise
				check(discriminant>0,"Carrier unreachable vertically")
				local reach=16*(50+math.sqrt(discriminant))/196.2
				check(horizontal<reach,"Carrier envelope exceeds jump range")
			end
		end
	end
end
local p={RunStage=0,MaxStage=0,Won=false,Completed=false,Gate=0,LastReplay=-10}
for n=1,50 do
	check(not Rules.canCheckpoint(p,n+1,2,10),"Skipped checkpoint accepted")
	check(not Rules.canCheckpoint(p,n,1,10),"Missing route gate accepted")
	check(not Rules.canCheckpoint(p,n,2,2.9),"Impossible instant completion accepted")
	check(Rules.canCheckpoint(p,n,2,10),"Ordered checkpoint refused")
	Rules.advance(p,n,n*10)
	check(p.MaxStage==n and p.RunStage==n,"Progress failed")
	check(not Rules.canCheckpoint(p,math.max(1,n-1),2,10),"Backtracking lowered progress")
end
check(p.Won and p.Completed,"Victory absent")
check(Rules.replay(p,2000,1000),"Replay refused")
check(p.RunStage==0 and p.MaxStage==50 and p.Completed and not p.Won,"Replay erased record")
check(not Rules.replay(p,2001,1001),"Replay remotely spammed")
Rules.advance(p,1,1010)
check(p.MaxStage==50 and p.RunStage==1,"Replay reduced maximum")
local merged=Schema.merge({MaxStage=30,BestTime=500},{MaxStage=12,BestTime=700})
check(merged.MaxStage==30 and merged.BestTime==500,"Concurrent stale write reduced record")
merged=Schema.merge(merged,{MaxStage=50,Completed=true,BestTime=400})
check(merged.MaxStage==50 and merged.Completed and merged.BestTime==400,"Winning merge failed")
check(Schema.sanitize(nil).MaxStage==0,"New player default")
check(Schema.sanitize({MaxStage=0/0,BestTime=-10}).MaxStage==0,"NaN not sanitized")
check(Schema.sanitize({MaxStage=90}).MaxStage==50,"Overflow stage")
check(Schema.sanitize({MaxStage=-3}).MaxStage==0,"Negative stage")
check(Schema.sanitize({BestTime=math.huge}).BestTime==nil,"Invalid timer")
print(string.format("PASS: %d assertions, 50 stages / 600 route segments / 150 mechanisms / %d types",checks,16))
print(string.format("Maximum static center-to-center segment: %.3f studs; route rise %.3f studs",maxJump,20/12))
print("NOT TESTED: Roblox physics, network ownership, Studio UI, live DataStore. See docs/TESTING.md.")
