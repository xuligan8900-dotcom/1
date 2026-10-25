--!strict
-- A completed group of five unlocks its physical catch floor for that player.
-- Floors are below the checkpoint; enabling collision never intersects a climber.
local Rules={Interval=5,FloorCount=9}
function Rules.section(stage)
	return math.clamp(math.floor(stage/Rules.Interval),0,Rules.FloorCount)
end
function Rules.canStandOn(section,floorIndex)
	return floorIndex>=1 and floorIndex<=Rules.FloorCount and section>=floorIndex
end
function Rules.floorHeight(floorIndex)
	return 8+floorIndex*Rules.Interval*20-10
end
function Rules.playerGroup(section) return "TowerPlayer_"..section end
function Rules.floorGroup(floorIndex) return "TowerFloor_"..floorIndex end
return table.freeze(Rules)
