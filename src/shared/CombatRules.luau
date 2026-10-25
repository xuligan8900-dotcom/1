--!strict
local Rules={SpawnShield=4,CheckpointShield=2,HitImmunity=0.9,Stagger=0.25,MaxVertical=4.5}
function Rules.canSwing(now,nextSwing,equipped,alive,safe,staggered)
	return now>=nextSwing and equipped and alive and not safe and not staggered
end
function Rules.canHit(distance,vertical,dot,range,visible,attackerSafe,targetSafe,alive,immune)
	return distance>0.05 and distance<=range and math.abs(vertical)<=Rules.MaxVertical
		and dot>=0.35 and visible and not attackerSafe and not targetSafe and alive and not immune
end
function Rules.inBox(x,y,z,halfX,halfZ,minY,maxY)
	return math.abs(x)<=halfX and math.abs(z)<=halfZ and y>=minY and y<=maxY
end
return table.freeze(Rules)
