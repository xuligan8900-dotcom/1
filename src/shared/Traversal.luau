--!strict
-- Pure, deterministic walking paths. Mechanism nodes 2/6/10 stay isolated:
-- no bridge bypasses a moving/fading platform or its required landing jump.
local Traversal={}
local edges={{0,1},{3,4},{4,5},{7,8},{8,9},{11,12}}
function Traversal.width(stage)
	if stage.Traversal=="needles" then return 0.95 end
	if stage.Traversal=="pipes" then return 1.35 end
	return if stage.Id<=20 then 1.5 else 1.25
end
function Traversal.node(stage,node,baseWidth,baseDepth)
	local style=stage.Traversal or "jumps"
	if node%2==0 or style=="jumps" then return baseWidth,baseDepth,"deck" end
	if style=="posts" then
		local diameter=if stage.Id<30 then 2.8 else 2.5
		return diameter,diameter,"post"
	end
	-- Preserve flat waiting pads immediately before each trap.
	if node%4==1 then return math.max(3,baseWidth),baseDepth,"deck" end
	if style=="wrap" then return 3.2,2.5,"deck" end
	local width=Traversal.width(stage)
	return width,math.max(width,1.5),"joint"
end
local function interpolate(a,b,t,offset)
	local x=a.x+(b.x-a.x)*t
	local z=a.z+(b.z-a.z)*t
	local length=math.sqrt(x*x+z*z)
	return {x=x+x/length*offset,y=a.y+(b.y-a.y)*t,z=z+z/length*offset}
end
function Traversal.paths(stage,route)
	local style=stage.Traversal or "jumps"
	if style=="jumps" or style=="posts" then return {} end
	local result={}
	for index,edge in edges do
		local ax,ay,az=route.point(stage.Id,edge[1],stage.Layout)
		local bx,by,bz=route.point(stage.Id,edge[2],stage.Layout)
		local a,b={x=ax,y=ay,z=az},{x=bx,y=by,z=bz}
		local points={a}
		local column=nil
		if style=="zigzag" then
			table.insert(points,interpolate(a,b,0.5,if index%2==0 then -1.8 else 1.8))
		elseif style=="wrap" and edge[1]%4==3 then
			table.insert(points,interpolate(a,b,0.28,3.6))
			table.insert(points,interpolate(a,b,0.72,3.6))
			column=interpolate(a,b,0.5,0)
		end
		table.insert(points,b)
		table.insert(result,{From=edge[1],To=edge[2],Points=points,Width=Traversal.width(stage),
			Shape=if style=="pipes" then "pipe" else "beam",Column=column})
	end
	return result
end
return table.freeze(Traversal)
