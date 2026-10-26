--!strict
local Players=game:GetService("Players")
Players.CharacterAutoLoads=false
workspace:SetAttribute("TowerVersion","7.4")
workspace:SetAttribute("TowerBootStatus","starting")
workspace:SetAttribute("TowerBootError",nil)
workspace:SetAttribute("TowerDiagnosticsPassed",nil)
local function start()
	local ReplicatedStorage=game:GetService("ReplicatedStorage")
	workspace:SetAttribute("TowerBootStatus","modules")
	local Generator=require(script.Parent.TowerGenerator)
	local Traps=require(script.Parent.TrapController)
	local Data=require(script.Parent.PlayerDataService)
	local Economy=require(script.Parent.EconomyService)
	local Coins=require(script.Parent.CoinService)
	local Clubs=require(script.Parent.ClubService)
	local Checkpoints=require(script.Parent.CheckpointService)
	local Respawn=require(script.Parent.RespawnService)
	local Rules=require(ReplicatedStorage.Shared.ProgressRules)
	local remotes=Instance.new("Folder")
	remotes.Name="Remotes"
	for _,name in {"CheckpointNotification","VictoryEvent","PlayAgain","ShopRequest","ShopStateChanged","ShopNotice","CosmeticVictory","ClubAttack","ClubSwing","ClubHit"} do
		local event=Instance.new("RemoteEvent")
		event.Name=name
		event.Parent=remotes
	end
	local shopState=Instance.new("RemoteFunction")
	shopState.Name="ShopGetState"
	shopState.Parent=remotes
	remotes.Parent=ReplicatedStorage
	workspace:SetAttribute("TowerBootStatus","generating")
	local tower=Generator.generate()
	workspace:SetAttribute("TowerBootStatus","services")
	Economy.start(remotes)
	Clubs.start(tower,remotes,Economy,Data)
	Coins.start(tower,Economy,Data)
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
		if not Economy.load(player) then joining[player]=nil; return end
		task.spawn(Economy.refreshPasses,player,false)
		task.spawn(function()
			Economy.stage(player,p.MaxStage)
			if p.Completed then Economy.change(player,{Kind="win"}) end
		end)
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
		Economy.remove(player)
		Clubs.remove(player)
		joining[player]=nil
	end)
	for _,player in Players:GetPlayers() do task.spawn(join,player) end
	remotes.PlayAgain.OnServerEvent:Connect(function(player)
		local p=Data.Profiles[player]
		if not p or p.Spawning or not Rules.replay(p,workspace:GetServerTimeNow(),os.clock()) then return end
		Checkpoints.publish(player,p)
		player.RespawnLocation=tower.Foundation.LobbySpawn
		Clubs.protect(player,4)
		local character=player.Character
		local humanoid=character and character:FindFirstChildOfClass("Humanoid")
		if character and humanoid and humanoid.Health>0 then
			local root=character:FindFirstChild("HumanoidRootPart")
			if root then root.AssemblyLinearVelocity=Vector3.zero; root.AssemblyAngularVelocity=Vector3.zero end
			character:PivotTo(Respawn.destination(tower,0))
		else Respawn.spawn(player,p,tower) end
	end)
	print("[Tower] Server initialized. Characters spawn only after deterministic generation and data loading.")

	workspace:SetAttribute("TowerBootStatus","ready")
	-- Diagnostics still execute and report failure, but a diagnostic assertion must
	-- not strand all players with CharacterAutoLoads=false before join is bound.
	if game:GetService("RunService"):IsStudio() then
		task.defer(function()
			local ok,result=xpcall(function()
				return require(game:GetService("ServerStorage").TowerTests.Smoke).run(tower)
			end,debug.traceback)
			workspace:SetAttribute("TowerDiagnosticsPassed",ok and result==true)
			if not ok then
				warn("[StudioSmoke] FAILED (game started; see diagnostic traceback): "..tostring(result))
			end
		end)
	end
end
local ok,err=xpcall(start,debug.traceback)
if not ok then
	local phase=workspace:GetAttribute("TowerBootStatus")
	workspace:SetAttribute("TowerBootError",tostring(err))
	workspace:SetAttribute("TowerBootStatus","failed")
	warn("[Tower] STARTUP FAILED at "..tostring(phase)..": "..tostring(err))
end
