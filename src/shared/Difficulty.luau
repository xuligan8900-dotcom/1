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
	-- Every harmful family now has a genuine green crossing window.
	-- Wider gaps demand time for two jumps, not just a short dash across a deck.
	local greenSeconds=4.8-1.2*progress
	-- Stage 15 follows checkpoint 14: teach the blade rhythm without a speed wall.
	if stage.Id==15 then greenSeconds=5.5; result.Speed*=0.85 end
	if result.Motion=="fade" then greenSeconds+=0.5 end
	result.Safe=math.max(greenSeconds*result.Speed,result.Safe*(1-0.1*progress))
	result.Warning=math.max(1.2*result.Speed,result.Warning)
	result.Active*=1+0.2*progress
	return result
end
return table.freeze(Difficulty)
