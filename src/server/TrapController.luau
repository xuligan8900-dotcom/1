--!strict
local Players=game:GetService("Players")
local RunService=game:GetService("RunService")
local CollectionService=game:GetService("CollectionService")
local Motion=require(game:GetService("ReplicatedStorage").Shared.TrapMotion)
local Controller={}
function Controller.start(tower)
	local mechanisms=CollectionService:GetTagged("TowerMechanism")
	local records={}
	for _,model in mechanisms do
		if model:IsDescendantOf(tower) then
			local hazards={}
			for _,p in model:GetDescendants() do
				if p:IsA("BasePart") and p:GetAttribute("Hazard") then table.insert(hazards,p) end
			end
			table.insert(records,{model=model,hazards=hazards})
		end
	end
	local elapsed=0
	local hitAt=setmetatable({},{__mode="k"})
	local connection
	connection=RunService.PreSimulation:Connect(function(dt)
		if not tower.Parent then connection:Disconnect(); return end
		elapsed+=dt
		if elapsed<1/30 then return end
		elapsed=0
		local now=workspace:GetServerTimeNow()
		local characters={}
		local heights={}
		local positions={}
		for _,player in Players:GetPlayers() do
			local character=player.Character
			local root=character and character:FindFirstChild("HumanoidRootPart")
			if root then table.insert(characters,character); table.insert(heights,root.Position.Y); table.insert(positions,root.Position) end
		end
		local params=OverlapParams.new()
		params.FilterType=Enum.RaycastFilterType.Include
		params.FilterDescendantsInstances=characters
		for _,record in records do
			local model=record.model
			local near=false
			for _,height in heights do
				if math.abs(height-model:GetAttribute("Base").Position.Y)<130 then near=true; break end
			end
			if not near then continue end
			local danger=Motion.apply(model,now)
			for _,p in record.hazards do
				-- Inactive laser beams must also disappear on clients; motion is evaluated there too.
				if model:GetAttribute("Motion")=="gate" then
					p.Transparency=if danger then 0.05 elseif model:GetAttribute("VisualState")=="warning" then 0.65 else 0.95
				end
			end
			local damageNear=false
			for _,position in positions do
				if (position-model:GetAttribute("Base").Position).Magnitude<24 then damageNear=true; break end
			end
			if not danger or not damageNear then continue end
			for _,hazard in record.hazards do
				for _,hit in workspace:GetPartBoundsInBox(hazard.CFrame,hazard.Size,params) do
					local character=hit:FindFirstAncestorOfClass("Model")
					if character and hit.Parent~=character then continue end -- Cosmetic accessories do not enlarge the damage hitbox.
					local humanoid=character and character:FindFirstChildOfClass("Humanoid")
					local root=character and character:FindFirstChild("HumanoidRootPart")
					if not humanoid or humanoid.Health<=0 or now-(hitAt[humanoid] or 0)<0.6 then continue end
					hitAt[humanoid]=now
					local damage=model:GetAttribute("Damage")
					if damage>0 then humanoid:TakeDamage(damage) end
					if root and model:GetAttribute("Push")>0 then
						root:ApplyImpulse((model:GetAttribute("Base").RightVector*model:GetAttribute("Push")+Vector3.new(0,9,0))*root.AssemblyMass)
					end
				end
			end
		end
	end)
	print("[Tower] Central trap controller: "..#records.." mechanisms; 30 Hz, vertical activity culling")
	return connection
end
return Controller
