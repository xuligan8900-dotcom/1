-- Execute with Luau CLI from any working directory: luau tests/run.luau
local Stages=require("../src/shared/StageDefinitions")
local Route=require("../src/shared/Route")
local Rules=require("../src/shared/ProgressRules")
local Schema=require("../src/shared/DataSchema")
local Traps=require("../src/shared/TrapDefinitions")
local MotionMath=require("../src/shared/MotionMath")
local Recovery=require("../src/shared/RecoveryRules")
local Difficulty=require("../src/shared/Difficulty")
local Geometry=require("../src/shared/TrapGeometry")
local Numeric=require("../src/shared/Numeric")
local Traversal=require("../src/shared/Traversal")
local TraversalTests=require("./traversal")
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
	for station,kind in stage.Traps do
		local balanced=Difficulty.trap(Traps[kind],stage,station)
		check(balanced.Safe/balanced.Speed>=3.6-0.00001,"Insufficient safe window")
		check(balanced.Warning/balanced.Speed>=1.2-0.00001,"Insufficient warning")
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
		check(Route.width(i,n,stage.Layout)>=2.2,"Platform too narrow")
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
		local definition=Difficulty.trap(Traps[kind],stage,station)
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
-- Regression for checkpoint 14 -> stage 15: green means genuinely harmless,
-- the complete crossing window fits two standard jumps plus generous reaction time.
local jumpSeconds=(50+math.sqrt(50^2-2*196.2*(20/12)))/196.2
for _,stage in Stages do
	for station,kind in stage.Traps do
		local trap=Difficulty.trap(Traps[kind],stage,station)
		local safeSeconds=trap.Safe/trap.Speed
		check(safeSeconds>2*jumpSeconds+1.5,"Not enough time to enter and leave trap")
		for _,fraction in {0.1,0.5,0.9} do
			local _,_,_,state,harmful=MotionMath.sample(trap.Motion,trap.Safe*fraction,trap.Safe,trap.Warning,trap.Active,trap.Travel)
			check(state=="safe" and not harmful,"Green trap still inflicts damage")
		end
		local node=station*4-2
		if kind=="rotor" or kind=="doubleRotor" or kind=="blade" then
			local x,_,z=Route.point(stage.Id,node,stage.Layout)
			local px,_,pz=Route.point(stage.Id,node-1,stage.Layout)
			local distance=math.sqrt((x-px)^2+(z-pz)^2)
			check(Geometry.SweepLength/2+1.3<distance,"Sweep hits avatar waiting on previous platform")
		end
		if stage.Id==15 then check(safeSeconds>=5.5-0.00001,"Stage 15 safety window missing") end
		if kind=="press" then
			check(Geometry.PressRestHeight-Geometry.PressHalfHeight>Geometry.AvatarHeight+1,"Press blocks a standing avatar in its safe phase")
		elseif kind=="door" then
			check(Geometry.DoorRestCenter-Geometry.DoorHalfHeight+trap.Travel>Geometry.AvatarHeight+1,"Open door has insufficient headroom")
		end
	end
end
-- Check actual oriented platform edge projections, not just center spacing.
local minStaticGap=math.huge
local function halfExtent(stage,node,ex,ez)
	local x,_,z=Route.point(stage.Id,node,stage.Layout)
	local fx,fz
	if node==12 then
		local length=math.sqrt(x*x+z*z); fx,fz=-z/length,x/length
	else
		local nx,_,nz=Route.point(stage.Id,node+1,stage.Layout)
		local length=math.sqrt((nx-x)^2+(nz-z)^2); fx,fz=(nx-x)/length,(nz-z)/length
	end
	return math.abs(ex*(-fz)+ez*fx)*Route.width(stage.Id,node,stage.Layout)/2
		+math.abs(ex*fx+ez*fz)*Route.depth(stage.Id,node)/2
end
for _,stage in Stages do
	for n=1,12 do
		-- Carrier docking and circular gears intentionally have independent envelopes.
		if n%4==2 or (n-1)%4==2 then continue end
		local x,_,z=Route.point(stage.Id,n,stage.Layout)
		local px,_,pz=Route.point(stage.Id,n-1,stage.Layout)
		local distance=math.sqrt((x-px)^2+(z-pz)^2)
		local ex,ez=(x-px)/distance,(z-pz)/distance
		local gap=distance-halfExtent(stage,n,ex,ez)-halfExtent(stage,n-1,ex,ez)
		minStaticGap=math.min(minStaticGap,gap)
		check(gap>=1.7,string.format("Static platforms too close: stage %d, node %d, gap %.3f",stage.Id,n,gap))
	end
end
-- Door closure is continuous across state boundaries, with no instant engulfing.
local door=Traps.door
for _,boundary in {door.Safe,door.Safe+door.Warning,door.Safe+door.Warning+door.Active} do
	local before=MotionMath.sample("door",boundary-0.0001,door.Safe,door.Warning,door.Active,door.Travel)
	local after=MotionMath.sample("door",boundary+0.0001,door.Safe,door.Warning,door.Active,door.Travel)
	check(math.abs(after-before)<0.01,"Door teleports closed onto player")
end
print(string.format("Minimum oriented static edge gap: %.3f studs",minStaticGap))
local p={RunStage=0,MaxStage=0,Won=false,Completed=false,Gate=0,LastReplay=-10}
for n=1,50 do
	check(not Rules.canCheckpoint(p,n+1,2,10),"Skipped checkpoint accepted")
	check(Rules.canCheckpoint(p,n),"A legitimate pad must work even when a jump bypassed hidden gates")
	check(not Rules.canCheckpoint(p,0),"Invalid checkpoint accepted")
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
-- Regression: death is independent of persistence and uses the current run checkpoint.
local survivor={RunStage=0,MaxStage=0,Won=false,Completed=false,Gate=0,LastReplay=-10}
for stage=1,17 do Rules.advance(survivor,stage,stage*10) end
check(survivor.RunStage==17,"Death destination must retain checkpoint 17")
check(Recovery.section(survivor.RunStage)==3,"Stage 17 must unlock floor 15")
for stage=0,50 do
	local section=Recovery.section(stage)
	for floor=1,9 do
		check(Recovery.canStandOn(section,floor)==(stage>=floor*5),"Incorrect per-player floor collision")
		if Recovery.canStandOn(section,floor) then
			local _,checkpointY=Route.point(stage,12,Stages[math.max(stage,1)].Layout)
			check(Recovery.floorHeight(floor)<checkpointY-6,"Enabling floor traps a checkpoint occupant")
		end
	end
end
check(Recovery.section(0)==0 and Recovery.section(50)==9,"Recovery bounds")
check(Recovery.floorHeight(1)==98 and Recovery.floorHeight(9)==898,"Recovery heights")
check(Rules.onPad(0,3,0,5,4),"Standing on a pad must activate")
check(Rules.onPad(3.1,3,0,5,4),"Edge contact lost")
check(not Rules.onPad(5,3,0,5,4),"Distant checkpoint granted")
check(not Rules.onPad(0,10,0,5,4),"Flying overhead granted checkpoint")
check(not Rules.onPad(0,-2,0,5,4),"Player below pad granted checkpoint")
local starter=Difficulty.trap(Traps.rotor,Stages[1],2)
local final=Difficulty.trap(Traps.rotor,Stages[49],2)
check(final.Speed>starter.Speed*1.5,"Final mechanisms must be harder")
check(Route.width(49,3,"arc")<Route.width(1,3,"arc"),"Late platforms not narrower")
check(Route.depth(49,3)<3 and Route.depth(1,3)<4,"Overlapping easy walkways returned")
check(Rules.replay(survivor,2000,2000)==false,"Replay before victory accepted")
local merged=Schema.merge({MaxStage=30,BestTime=500},{MaxStage=12,BestTime=700})
check(merged.MaxStage==30 and merged.BestTime==500,"Concurrent stale write reduced record")
merged=Schema.merge(merged,{MaxStage=50,Completed=true,BestTime=400})
check(merged.MaxStage==50 and merged.Completed and merged.BestTime==400,"Winning merge failed")
check(Schema.sanitize(nil).MaxStage==0,"New player default")
check(Schema.sanitize({MaxStage=0/0,BestTime=-10}).MaxStage==0,"NaN not sanitized")
check(Schema.sanitize({MaxStage=90}).MaxStage==50,"Overflow stage")
check(Schema.sanitize({MaxStage=-3}).MaxStage==0,"Negative stage")
check(Schema.sanitize({BestTime=math.huge}).BestTime==nil,"Invalid timer")
-- Reproduce the engine float32 round-trip that used to abort Studio startup.
local bytes=buffer.create(4)
for _,size in {Geometry.BladeLength,Geometry.SweepLength} do
	buffer.writef32(bytes,0,size)
	local engineSize=buffer.readf32(bytes,0)
	check(engineSize~=size,"Regression fixture must reproduce float32 rounding")
	check(Numeric.near(engineSize,size),"Float32 part sizes falsely fail startup diagnostic")
	check(not Numeric.near(engineSize,size+0.1),"Tolerance hides an actual wrong blade size")
end
check(not Numeric.near(0/0,6.2),"NaN passes numeric diagnostic")
TraversalTests.run(check,Stages,Route,Traversal)
print(string.format("PASS: %d assertions, 50 stages / 600 route segments / 150 mechanisms / %d types",checks,16))
print(string.format("Maximum static center-to-center segment: %.3f studs; route rise %.3f studs",maxJump,20/12))
print("NOT TESTED: Roblox physics, network ownership, Studio UI, live DataStore. See docs/TESTING.md.")
