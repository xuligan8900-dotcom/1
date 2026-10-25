--!strict
local Schema={}
function Schema.sanitize(value)
	if type(value)~="table" then return {MaxStage=0,Completed=false,BestTime=nil} end
	local stage=tonumber(value.MaxStage) or 0
	if stage~=stage then stage=0 end
	local best=tonumber(value.BestTime)
	if best and (best~=best or best<=0 or best==math.huge) then best=nil end
	stage=math.clamp(math.floor(stage),0,50)
	return {MaxStage=stage,Completed=value.Completed==true or stage==50,BestTime=best}
end
function Schema.merge(old,snapshot)
	local merged=Schema.sanitize(old)
	local incoming=Schema.sanitize(snapshot)
	merged.MaxStage=math.max(merged.MaxStage,incoming.MaxStage)
	merged.Completed=merged.Completed or incoming.Completed
	if incoming.BestTime then merged.BestTime=math.min(merged.BestTime or math.huge,incoming.BestTime) end
	merged.Version=1
	return merged
end
return table.freeze(Schema)
