--!strict
local RunService=game:GetService("RunService")
local Shared=game:GetService("ReplicatedStorage").Shared
local Rules=require(Shared.ProgressRules)
local Recovery=require(script.Parent.RecoveryService)
local Service={}
function Service.publish(player,p)
	Recovery.update(player,p)
	player:SetAttribute("RunStage",p.RunStage)
	player:SetAttribute("MaxStage",p.MaxStage)
	player:SetAttribute("Deaths",p.Deaths)
	player:SetAttribute("StartedAt",p.StartedAt)
	player:SetAttribute("FinishTime",p.FinishTime)
	player:SetAttribute("Won",p.Won)
	player:SetAttribute("Completed",p.Completed)
	player:SetAttribute("BestTime",p.BestTime)
	player:SetAttribute("FullRun",p.FullRun)
	player:SetAttribute("SavePending",p.Revision>p.SavedRevision)
end
local function inside(part,position,halfSize)
	local p=part.CFrame:PointToObjectSpace(position)
	return math.abs(p.X)<=halfSize.X and math.abs(p.Y)<=halfSize.Y and math.abs(p.Z)<=halfSize.Z
end
function Service.start(tower,data,remotes)
	local checkpoints={}
	local gates={}
	for n=1,50 do
		checkpoints[n]=tower.Checkpoints:FindFirstChild("Checkpoint_"..n)
		gates[n]={tower.RouteGates:FindFirstChild("Gate_"..n.."_4"),tower.RouteGates:FindFirstChild("Gate_"..n.."_8")}
	end
	local elapsed=0
	local connection
	connection=RunService.Heartbeat:Connect(function(dt)
		if not tower.Parent then connection:Disconnect(); return end
		elapsed+=dt
		if elapsed<0.1 then return end
		elapsed=0
		for player,p in data.Profiles do
			if not player.Parent or p.Won or p.Spawning then continue end
			local character=player.Character
			local root=character and character:FindFirstChild("HumanoidRootPart")
			local humanoid=character and character:FindFirstChildOfClass("Humanoid")
			if not root or not humanoid or humanoid.Health<=0 then continue end
			local stage=p.RunStage+1
			local gate=gates[stage][p.Gate+1]
			if gate and inside(gate,root.Position,Vector3.new(4.5,3.5,3.5)) then p.Gate+=1 end
			local checkpoint=checkpoints[stage]
			local relative=checkpoint.CFrame:PointToObjectSpace(root.Position)
			local touching=Rules.onPad(relative.X,relative.Y,relative.Z,checkpoint.Size.X,checkpoint.Size.Z)
			if touching and Rules.canCheckpoint(p,stage) then
				Rules.advance(p,stage,os.clock())
				player.RespawnLocation=checkpoint
				if p.Won then
					p.FinishTime=workspace:GetServerTimeNow()-p.StartedAt
					if p.FullRun then p.BestTime=math.min(p.BestTime or math.huge,p.FinishTime) end
				end
				data.mark(p)
				Service.publish(player,p)
				remotes.CheckpointNotification:FireClient(player,stage)
				if p.Won then
					remotes.VictoryEvent:FireClient(player,p.FinishTime,p.FullRun)
					task.spawn(data.save,player)
				else data.requestSave(player) end
			end
		end
	end)
	return connection
end
return Service
