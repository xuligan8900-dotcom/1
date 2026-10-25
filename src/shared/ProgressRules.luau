--!strict
-- No client input participates in this transition. Pure functions are tested outside Studio.
local Rules={}
function Rules.canCheckpoint(profile, stage, gate, elapsed)
	return not profile.Won and stage==profile.RunStage+1 and stage<=50 and gate==2 and elapsed>=3
end
function Rules.advance(profile, stage, now)
	profile.RunStage=stage
	profile.MaxStage=math.max(profile.MaxStage,stage)
	profile.Gate=0
	profile.StageEntered=now
	if stage==50 then
		profile.Won=true
		profile.Completed=true
	end
end
function Rules.replay(profile, serverTime, monotonicTime)
	if not profile.Won or monotonicTime-profile.LastReplay<3 then return false end
	profile.LastReplay=monotonicTime
	profile.RunStage=0
	profile.Won=false
	profile.Gate=0
	profile.StartedAt=serverTime
	profile.FullRun=true
	profile.FinishTime=nil
	profile.StageEntered=monotonicTime
	return true
end
return table.freeze(Rules)
