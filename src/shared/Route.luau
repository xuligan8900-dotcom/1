--!strict
-- Pure route math is shared by generation and the standalone Luau tests.
local Route = {}
local profiles = {
	wide = {0,0,1,2,1,0,-1,-2,-1,0,1,0,0},
	weave = {0,1,3,1,0,-2,-3,-1,0,2,3,1,0},
	arc = {0,0,0,0,0,0,0,0,0,0,0,0,0},
	outer = {0,1,2,3,3,3,3,3,3,3,2,1,0},
	inner = {0,-1,-2,-3,-3,-3,-3,-3,-3,-3,-2,-1,0},
	beams = {0,0,1,1,0,0,-1,-1,0,0,1,1,0},
	zigzag = {0,2,0,-2,0,2,0,-2,0,2,0,-2,0},
	columns = {0,1,1,0,-1,-1,0,1,1,0,-1,-1,0},
	islands = {0,-1,-2,-1,0,1,2,1,0,-1,-2,-1,0},
	maze = {0,1,2,2,1,0,-1,-2,-2,-1,0,1,0},
	needles = {0,1,0,-1,0,1,0,-1,0,1,0,-1,0},
	crown = {0,-1,-2,-3,-3,-2,-1,0,1,2,2,1,0},
}
function Route.point(stage, node, layout)
	local profile = assert(profiles[layout], "Unknown layout")
	local angle = ((stage - 1) * math.pi / 2) + node / 12 * math.pi / 2
	local radius = 36 + profile[node + 1]
	return radius * math.cos(angle), 8 + (stage - 1) * 20 + node * 20 / 12, radius * math.sin(angle)
end
function Route.width(stage, node, layout)
	if node % 4 == 0 then return 6 end
	if layout == "needles" then return 2.2 end
	if layout == "beams" then return 2.6 end
	if layout == "islands" then return 3.1 end
	return math.max(2.8,4.8-stage*0.04)
end
function Route.depth(stage,node)
	if node%4==0 then return 5 end
	return math.max(2.8,3.8-stage*0.02)
end
function Route.carrierSize(stage)
	return math.max(3.8,4.8-stage*0.02),math.max(3.2,3.8-stage*0.012)
end
function Route.validate(definitions)
	assert(#definitions == 50, "Exactly 50 stages required")
	local signatures = {}
	for i, stage in definitions do
		assert(stage.Id == i)
		local signature = stage.Layout .. table.concat(stage.Traps, ",") .. tostring(stage.Speed)
		assert(not signatures[signature], "Duplicate stage configuration")
		signatures[signature] = true
		for n = 1, 12 do
			local x,y,z = Route.point(i,n,stage.Layout)
			local px,py,pz = Route.point(i,n-1,stage.Layout)
			local horizontal = math.sqrt((x-px)^2 + (z-pz)^2)
			assert(horizontal <= 6.6, "Route exceeds conservative jump envelope")
			assert(y > py and y-py < 2, "Invalid rise")
			assert(math.abs(x) < 40 and math.abs(z) < 40, "Structural collision")
		end
		if i < 50 then
			local x,y,z = Route.point(i,12,stage.Layout)
			local nx,ny,nz = Route.point(i+1,0,definitions[i+1].Layout)
			assert(math.abs(x-nx)+math.abs(y-ny)+math.abs(z-nz) < 0.001, "Disconnected stages")
		end
	end
	return true
end
return table.freeze(Route)
