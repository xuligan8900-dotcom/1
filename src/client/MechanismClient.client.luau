--!strict
-- Anchored mechanisms use the same server clock on both peers. Only the owning
-- client carries its character; the server never applies a second displacement.
local Players=game:GetService("Players")
local RunService=game:GetService("RunService")
local CollectionService=game:GetService("CollectionService")
local Motion=require(game:GetService("ReplicatedStorage"):WaitForChild("Shared").TrapMotion)
local player=Players.LocalPlayer
local tower=workspace:WaitForChild("GeneratedTower")
local records={}
local byModel={}
local function add(model)
	if byModel[model] or not model:IsDescendantOf(tower) then return end
	local record={model=model,previous=nil,delta=CFrame.identity}
	table.insert(records,record)
	byModel[model]=record
end
CollectionService:GetInstanceAddedSignal("TowerMechanism"):Connect(add)
CollectionService:GetInstanceRemovedSignal("TowerMechanism"):Connect(function(model)
	local record=byModel[model]
	if not record then return end
	byModel[model]=nil
	local index=table.find(records,record)
	if index then table.remove(records,index) end
end)
for _,model in CollectionService:GetTagged("TowerMechanism") do add(model) end
local rayParams=RaycastParams.new()
rayParams.FilterType=Enum.RaycastFilterType.Exclude
RunService.PreSimulation:Connect(function(dt)
	local character=player.Character
	local root=character and character:FindFirstChild("HumanoidRootPart")
	local humanoid=character and character:FindFirstChildOfClass("Humanoid")
	if not root or not humanoid then return end
	local now=workspace:GetServerTimeNow()
	for _,record in records do
		local model=record.model
		if math.abs(root.Position.Y-model:GetAttribute("Base").Position.Y)>140 then
			record.previous=nil
			continue
		end
		local _,_,danger=Motion.evaluate(model,now)
		Motion.apply(model,now)
		local current=model:GetPivot()
		record.delta=if record.previous then current*record.previous:Inverse() else CFrame.identity
		record.previous=current
		if model:GetAttribute("Motion")=="gate" then
			for _,p in model:GetChildren() do
				if p:IsA("BasePart") and p:GetAttribute("Hazard") then
					p.Transparency=if danger then 0.05 elseif model:GetAttribute("VisualState")=="warning" then 0.65 else 0.95
				end
			end
		end
	end
	if workspace:GetServerTimeNow()<(root:GetAttribute("ClubKnockbackUntil") or 0) then return end
	if humanoid.Health<=0 or humanoid:GetState()==Enum.HumanoidStateType.Jumping then return end
	rayParams.FilterDescendantsInstances={character}
	rayParams.CollisionGroup=root.CollisionGroup
	local distance=humanoid.HipHeight+root.Size.Y/2+0.65
	local hit=workspace:Raycast(root.Position,Vector3.new(0,-distance,0),rayParams)
	if not hit or hit.Normal.Y<0.5 or not hit.Instance:GetAttribute("Carry") then return end
	-- A ground ray alone must not catch falling characters early or cancel a jump.
	if root.AssemblyLinearVelocity.Y>8 or root.AssemblyLinearVelocity.Y < -12 then return end
	local model=hit.Instance:FindFirstAncestorOfClass("Model")
	local record=model and byModel[model]
	if not record then return end
	local displacement=record.delta
	if model:GetAttribute("Motion")=="belt" then
		displacement=CFrame.new(model:GetAttribute("Base"):VectorToWorldSpace(model:GetAttribute("Direction"))*model:GetAttribute("BeltSpeed")*math.min(dt,0.05))*displacement
	end
	root.CFrame=displacement*root.CFrame
end)
