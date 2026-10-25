--!strict
local Test={}
local function distanceToSegment(p,a,b)
	local dx,dz=b.x-a.x,b.z-a.z
	local t=math.clamp(((p.x-a.x)*dx+(p.z-a.z)*dz)/(dx*dx+dz*dz),0,1)
	return math.sqrt((p.x-a.x-t*dx)^2+(p.z-a.z-t*dz)^2)
end
function Test.run(check,stages,route,traversal)
	local styles={}
	local varied=0
	for _,stage in stages do
		local paths=traversal.paths(stage,route)
		local expected=if stage.Traversal=="jumps" or stage.Traversal=="posts" then 0 else 6
		check(#paths==expected,"Missing walking segments")
		if stage.Traversal~="jumps" then varied+=1; styles[stage.Traversal]=true end
		for _,path in paths do
			check(path.Width>=0.95 and path.Width<=1.5,"Unfair balance width")
			for node=path.From,path.To do check(node%4~=2,"Walking bridge bypasses a mechanism") end
			local ax,ay,az=route.point(stage.Id,path.From,stage.Layout)
			local bx,by,bz=route.point(stage.Id,path.To,stage.Layout)
			local first,last=path.Points[1],path.Points[#path.Points]
			check(first.x==ax and first.y==ay and first.z==az,"Broken walking entrance")
			check(last.x==bx and last.y==by and last.z==bz,"Broken walking exit")
			for n=1,#path.Points-1 do
				local a,b=path.Points[n],path.Points[n+1]
				local horizontal=math.sqrt((a.x-b.x)^2+(a.z-b.z)^2)
				local slope=math.deg(math.atan((b.y-a.y)/horizontal))
				check(horizontal>0 and slope>=0 and slope<25,"Beam too steep to run up")
				check(math.abs(a.x)<49 and math.abs(a.z)<49,"Walking route leaves tower clearance")
				if path.Column then
					check(distanceToSegment(path.Column,a,b)>2.05,"Column blocks the R15 centerline")
				end
			end
		end
		for node=1,11,2 do
			local width,depth,shape=traversal.node(stage,node,route.width(stage.Id,node,stage.Layout),route.depth(stage.Id,node))
			check(width>0 and depth>0,"Invalid junction")
			if stage.Traversal=="posts" then check(shape=="post" and width>=2.5,"Missing column-hop surface")
			elseif stage.Traversal~="jumps" and node%4==1 then
				check(width>=3,"A trap lost its waiting pad")
			elseif stage.Traversal~="jumps" and stage.Traversal~="wrap" then
				check(shape=="joint" and width<=1.5,"Full platform remains on a thin beam")
			end
		end
	end
	local count=0
	for _ in styles do count+=1 end
	check(count==6 and varied==21,"Expected six traversal styles over 21 distinct stages")
	check(stages[15].Traversal=="jumps","Stage 15 blade fix changed unexpectedly")
	print("Traversal PASS: 21 varied stages, six surface types, connected slopes, R15 column clearance")
end
return Test
