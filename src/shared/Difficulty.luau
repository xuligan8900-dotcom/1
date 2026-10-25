--!strict
local Difficulty={}
function Difficulty.trap(definition,stage,station)
	local result=table.clone(definition)
	local overrides=stage.TrapOverrides and stage.TrapOverrides[station]
	if overrides then
		for key,value in overrides do
			assert(definition[key]~=nil and type(value)==type(definition[key]),"Invalid trap override "..key)
			result[key]=value
		end
	end
	local progress=(stage.Id-1)/49
	result.Speed*=stage.Speed*(1+(station-2)*0.07)*(1+0.25*progress)
	-- Faster late-game cycles, but retain readable warnings and a crossing window.
	result.Safe=math.max(1.8*result.Speed,result.Safe*(1-0.2*progress))
	result.Warning=math.max(0.75*result.Speed,result.Warning)
	result.Active*=1+0.35*progress
	return result
end
return table.freeze(Difficulty)
