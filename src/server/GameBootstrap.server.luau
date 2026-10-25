--!strict
local Players=game:GetService("Players")
Players.CharacterAutoLoads=false
local ReplicatedStorage=game:GetService("ReplicatedStorage")
local Generator=require(script.Parent.TowerGenerator)
local Traps=require(script.Parent.TrapController)
local Data=require(script.Parent.PlayerDataService)
local Checkpoints=require(script.Parent.CheckpointService)
local Respawn=require(script.Parent.RespawnService)
local Rules=require(ReplicatedStorage.Shared.ProgressRules)
local remotes=Instance.new("Folder")
remotes.Name="Remotes"
for _,name in {"CheckpointNotification","VictoryEvent","PlayAgain"} do
	local event=Instance.new("RemoteEvent")
	event.Name=name
	event.Parent=remotes
end
remotes.Parent=ReplicatedStorage
local tower=Generator.generate()
if game:GetService("RunService"):IsStudio() then
	require(game:GetService("ServerStorage").TowerTests.Smoke).run(tower)
end
Traps.start(tower)
Checkpoints.start(tower,Data,remotes)
Data.start()
local connections={}
local joining={}
local function join(player)
	if joining[player] then return end
	joining[player]=true
	local p=Data.load(player)
	if not p then joining[player]=nil; return end
	Checkpoints.publish(player,p)
	connections[player]=Respawn.bind(player,p,tower,Checkpoints.publish)
	player:SetAttribute("DataLoaded",true)
	Respawn.spawn(player,p,tower)
end
Players.PlayerAdded:Connect(join)
Players.PlayerRemoving:Connect(function(player)
	local profile=Data.Profiles[player]
	if profile and profile.CollisionConnection then profile.CollisionConnection:Disconnect() end
	if connections[player] then connections[player]:Disconnect(); connections[player]=nil end
	Data.save(player,os.clock()+15)
	Data.Profiles[player]=nil
	joining[player]=nil
end)
for _,player in Players:GetPlayers() do task.spawn(join,player) end
remotes.PlayAgain.OnServerEvent:Connect(function(player)
	local p=Data.Profiles[player]
	if not p or p.Spawning or not Rules.replay(p,workspace:GetServerTimeNow(),os.clock()) then return end
	Checkpoints.publish(player,p)
	player.RespawnLocation=tower.Foundation.LobbySpawn
	local character=player.Character
	local humanoid=character and character:FindFirstChildOfClass("Humanoid")
	if character and humanoid and humanoid.Health>0 then
		local root=character:FindFirstChild("HumanoidRootPart")
		if root then root.AssemblyLinearVelocity=Vector3.zero; root.AssemblyAngularVelocity=Vector3.zero end
		character:PivotTo(Respawn.destination(tower,0))
	else Respawn.spawn(player,p,tower) end
end)
print("[Tower] Server initialized. Characters spawn only after deterministic generation and data loading.")
