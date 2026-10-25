--!strict
local Players=game:GetService("Players")
local Config=require(game:GetService("ReplicatedStorage").Shared.GameConfig)
local Respawn={}
function Respawn.destination(tower,stage)
	if stage==0 then return CFrame.new(32,12,0) end
	return tower.Checkpoints:FindFirstChild("Checkpoint_"..stage):GetAttribute("Spawn")
end
function Respawn.spawn(player,profile,tower)
	if profile.Spawning or not player.Parent then return end
	profile.Spawning=true
	local ok,err=pcall(function() player:LoadCharacterAsync() end)
	profile.Spawning=false
	if not ok and player.Parent then
		warn("[Respawn] "..tostring(err))
		task.delay(3,function() if player.Parent then Respawn.spawn(player,profile,tower) end end)
	end
end
function Respawn.bind(player,profile,tower,publish)
	local connection=player.CharacterAdded:Connect(function(character)
		local humanoid=character:WaitForChild("Humanoid",15)
		local root=character:WaitForChild("HumanoidRootPart",15)
		if not humanoid or not root or not player.Parent then return end
		humanoid.WalkSpeed=Config.WalkSpeed
		humanoid.UseJumpPower=true
		humanoid.JumpPower=Config.JumpPower
		profile.Gate=0
		profile.StageEntered=os.clock()
		character:PivotTo(Respawn.destination(tower,profile.RunStage))
		humanoid.Died:Once(function()
			profile.Deaths+=1
			publish(player,profile)
			task.delay(3,function()
				if player.Parent and player.Character==character then Respawn.spawn(player,profile,tower) end
			end)
		end)
	end)
	return connection
end
return Respawn
