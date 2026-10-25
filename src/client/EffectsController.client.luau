--!strict
local ReplicatedStorage=game:GetService("ReplicatedStorage")
local Debris=game:GetService("Debris")
local SoundService=game:GetService("SoundService")
local remotes=ReplicatedStorage:WaitForChild("Remotes")
local function chime(pitch)
	local sound=Instance.new("Sound")
	sound.SoundId="rbxasset://sounds/electronicpingshort.wav"
	sound.Volume=0.35
	sound.PlaybackSpeed=pitch
	sound.Parent=SoundService
	sound:Play()
	Debris:AddItem(sound,3)
end
remotes.CheckpointNotification.OnClientEvent:Connect(function() chime(1.15) end)
remotes.VictoryEvent.OnClientEvent:Connect(function()
	chime(0.8)
end)
-- Local proximity warnings: a single scheduler, no per-part sound loops.
local CollectionService=game:GetService("CollectionService")
local Players=game:GetService("Players")
local RunService=game:GetService("RunService")
local tower=workspace:WaitForChild("GeneratedTower")
local lastStates={}
local elapsed=0
local lastSound=0
RunService.Heartbeat:Connect(function(dt)
	elapsed+=dt
	if elapsed<0.15 then return end
	elapsed=0
	local character=Players.LocalPlayer.Character
	local root=character and character:FindFirstChild("HumanoidRootPart")
	if not root then return end
	for _,model in CollectionService:GetTagged("TowerMechanism") do
		if not model:IsDescendantOf(tower) then continue end
		local state=model:GetAttribute("VisualState")
		if state~=lastStates[model] then
			lastStates[model]=state
			if state=="warning" and (root.Position-model:GetAttribute("Base").Position).Magnitude<25 then
				if model:GetAttribute("SoundEnabled") and os.clock()-lastSound>0.4 then chime(0.6); lastSound=os.clock() end
				local sparks=model:FindFirstChild("WarningSparks",true)
				if sparks then sparks:Emit(6) end
			end
		end
	end
end)
