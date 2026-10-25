--!strict
-- Engine-independent deterministic oscillator used by the actual server/client controller.
local Math={}
function Math.sample(mode,t,safe,warning,active,travel)
	local cycle=t%(safe+warning+active)
	local state=if cycle<safe then "safe" elseif cycle<safe+warning then "warning" else "active"
	local pulse=if state=="active" then math.sin((cycle-safe-warning)/active*math.pi) else 0
	local amount,orbitZ,angle=0,0,0
	if mode=="slide" or mode=="lift" then amount=math.sin(t)*travel
	elseif mode=="orbit" then amount=math.sin(t)*travel; orbitZ=math.cos(t)*travel
	elseif mode=="pulse" or mode=="press" then amount=pulse*travel
	elseif mode=="spin" or mode=="ring" then angle=t
	elseif mode=="swing" then angle=math.sin(t)*0.68
	elseif mode=="door" then amount=if state=="active" then 0 else travel end
	local continuous=mode=="spin" or mode=="swing" or mode=="ring"
	return amount,orbitZ,angle,state,continuous or state=="active"
end
return table.freeze(Math)
