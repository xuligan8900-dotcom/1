--!strict
local Math=require(script.Parent.MotionMath)
local Motion = {}
function Motion.evaluate(model, now)
	local base=model:GetAttribute("Base")
	local t=now*model:GetAttribute("Speed")+model:GetAttribute("Phase")
	local direction=model:GetAttribute("Direction")
	local mode=model:GetAttribute("Motion")
	local amount,orbitZ,angle,state,danger=Math.sample(mode,t,
		model:GetAttribute("Safe"),model:GetAttribute("Warning"),model:GetAttribute("Active"),model:GetAttribute("Travel"))
	local cf=base
	if mode=="slide" or mode=="lift" or mode=="pulse" or mode=="press" then cf=base*CFrame.new(direction*amount)
	elseif mode=="orbit" then cf=base*CFrame.new(amount,0,orbitZ)
	elseif mode=="spin" or mode=="ring" or mode=="swing" then cf=base*CFrame.fromAxisAngle(direction,angle)
	elseif mode=="door" then cf=base*CFrame.new(0,amount,0)
	end
	return cf,state,danger
end
function Motion.apply(model, now)
	local cf,state,danger = Motion.evaluate(model,now)
	model:PivotTo(cf)
	if model:GetAttribute("VisualState") ~= state then
		model:SetAttribute("VisualState",state)
		for _,p in model:GetDescendants() do
			if p:IsA("BasePart") then
				if p:GetAttribute("Signal") then
					p.Color = if state == "warning" then Color3.fromRGB(255,190,40)
						elseif danger then Color3.fromRGB(255,65,70) else Color3.fromRGB(60,230,170)
				end
				if model:GetAttribute("Motion") == "fade" then
					p.CanCollide = state ~= "active" and p:GetAttribute("TowerSolid")==true
					p.CanQuery = p.CanCollide
					p.Transparency = if state == "active" then 0.92 elseif state == "warning" then 0.45 else 0.05
				end
			end
		end
	end
	return danger
end
return Motion
