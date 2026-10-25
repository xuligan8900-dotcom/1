--!strict
local Players=game:GetService("Players")
local RunService=game:GetService("RunService")
local Shared=game:GetService("ReplicatedStorage").Shared
local Catalog=require(Shared.CosmeticCatalog)
local Rules=require(Shared.CombatRules)
local Service={States={},Staggers={},Economy=nil,Data=nil,Tower=nil,Remotes=nil,Templates={}}
local function state(player)
	local s=Service.States[player]
	if not s then s={NextSwing=0,LastRequest=-10,ShieldUntil=0,ImmuneUntil=0}; Service.States[player]=s end
	return s
end
function Service.protect(player,seconds)
	state(player).ShieldUntil=os.clock()+seconds
	player:SetAttribute("ClubShieldUntil",workspace:GetServerTimeNow()+seconds)
end
local function body(player)
	local character=player.Character
	local root=character and character:FindFirstChild("HumanoidRootPart")
	local humanoid=character and character:FindFirstChildOfClass("Humanoid")
	return character,root,humanoid
end
function Service.safe(player,root)
	local s=state(player)
	if os.clock()<s.ShieldUntil then return true end
	local p=Service.Data and Service.Data.Profiles[player]
	if not p or p.Won then return true end
	local lobby=Service.Tower.Foundation.LobbySpawn.CFrame:PointToObjectSpace(root.Position)
	if Rules.inBox(lobby.X,lobby.Y,lobby.Z,10,12,-2,9) then return true end
	local nearest=math.floor((root.Position.Y-8)/20)
	for n=math.max(1,nearest-1),math.min(50,nearest+1) do
		local cp=Service.Tower.Checkpoints:FindFirstChild("Checkpoint_"..n)
		local q=cp.CFrame:PointToObjectSpace(root.Position)
		if Rules.inBox(q.X,q.Y,q.Z,cp.Size.X/2+1.1,cp.Size.Z/2+1.1,-1,7) then return true end
	end
	for _,floor in Service.Tower.RecoveryFloors:GetChildren() do
		if p.RunStage>=floor:GetAttribute("UnlockStage") then
			local q=root.Position-floor.CatchDeck.Position
			if Rules.inBox(q.X,q.Y,q.Z,54,54,0.6,7.6) then return true end
		end
	end
	return false
end
local function part(tool,name,size,offset,color,material,handle)
	local p=Instance.new("Part")
	p.Name=name; p.Size=size; p.CFrame=offset
	p.Color=color; p.Material=material
	p.CanCollide=false; p.CanTouch=false; p.CanQuery=false; p.Massless=true
	p.Parent=tool
	if handle then
		local weld=Instance.new("WeldConstraint")
		weld.Part0=handle; weld.Part1=p; weld.Parent=p
	end
	return p
end
local function makeTool(item)
	local tool=Instance.new("Tool")
	tool.Name=item.Name
	tool.ToolTip="Клик / F / кнопка Удар — оттолкнуть игрока"
	tool.RequiresHandle=true; tool.CanBeDropped=false
	tool.Grip=CFrame.new(0,-0.65,0)*CFrame.Angles(math.rad(-15),0,0)
	tool:SetAttribute("TowerClub",true); tool:SetAttribute("ClubId",item.Id)
	local color=Color3.fromRGB(item.Color[1],item.Color[2],item.Color[3])
	local handle=part(tool,"Handle",Vector3.new(0.35,2.8,0.35),CFrame.identity,Color3.fromRGB(80,68,58),Enum.Material.Wood)
	local material=if item.Style=="wood" then Enum.Material.Wood elseif item.Style=="steel" or item.Style=="hammer" then Enum.Material.Metal else Enum.Material.Neon
	local head=part(tool,"Head",if item.Style=="hammer" then Vector3.new(1.8,0.9,0.9) else Vector3.new(0.75,1.5,0.75),CFrame.new(0,1.3,0),color,material,handle)
	if item.Style=="plasma" then head.Shape=Enum.PartType.Ball end
	if item.Style=="cosmic" then
		head.Shape=Enum.PartType.Ball
		for _,x in {-0.65,0.65} do
			local orb=part(tool,"OrbitOrb",Vector3.new(0.4,0.4,0.4),CFrame.new(x,1.4,0),color,Enum.Material.Neon,handle)
			orb.Shape=Enum.PartType.Ball
		end
	end
	for _,y in {0.7,1.85} do part(tool,"Band",Vector3.new(0.82,0.12,0.82),CFrame.new(0,y,0),color,material,handle) end
	return tool
end
function Service.sync(player,forceEquip)
	if not Service.Economy then return end
	local p=Service.Economy.Profiles[player]
	local character,_,humanoid=body(player)
	local backpack=player:FindFirstChildOfClass("Backpack")
	if not p or not backpack then return end
	local id=p.Wallet.Equipped.Club
	local item=Catalog.ById[id]
	if not item or item.Category~="Club" or not p.Wallet.Owned[id] then return end
	local existing=nil
	for _,container in {backpack,character} do
		if not container then continue end
		for _,tool in container:GetChildren() do
			if tool:IsA("Tool") and tool:GetAttribute("TowerClub") then
				if tool:GetAttribute("ClubId")==id and not existing then existing=tool else tool:Destroy() end
			end
		end
	end
	if not existing then existing=Service.Templates[id]:Clone(); existing.Parent=backpack; forceEquip=true end
	if forceEquip and humanoid and humanoid.Health>0 then humanoid:EquipTool(existing) end
end
local function equipped(player)
	local p=Service.Economy.Profiles[player]
	local character,root,humanoid=body(player)
	if not p or not character or not root or not humanoid or humanoid.Health<=0 then return nil end
	for _,tool in character:GetChildren() do
		if tool:IsA("Tool") and tool:GetAttribute("TowerClub") then
			local id=tool:GetAttribute("ClubId")
			local item=Catalog.ById[id]
			if item and item.Category=="Club" and p.Wallet.Owned[id] and p.Wallet.Equipped.Club==id then return tool,item,root,humanoid end
		end
	end
	return nil
end
function Service.request(player)
	local s=state(player)
	local now=os.clock()
	if now-s.LastRequest<0.1 then return end
	s.LastRequest=now
	local tool,item,root,humanoid=equipped(player)
	if not tool then return end
	if not Rules.canSwing(now,s.NextSwing,true,humanoid.Health>0,Service.safe(player,root),humanoid.PlatformStand) then return end
	s.NextSwing=now+item.Cooldown
	s.Pending={At=now+item.Windup,Tool=tool,Character=player.Character}
	player:SetAttribute("ClubCooldownUntil",workspace:GetServerTimeNow()+item.Cooldown)
	Service.Remotes.ClubSwing:FireAllClients(player.UserId,item.Id)
end
local function resolve(player,pending)
	local tool,item,root,attackerHumanoid=equipped(player)
	if not tool or attackerHumanoid.PlatformStand or tool~=pending.Tool or player.Character~=pending.Character or Service.safe(player,root) then return end
	local forward=Vector3.new(root.CFrame.LookVector.X,0,root.CFrame.LookVector.Z)
	if forward.Magnitude<0.01 then return end
	forward=forward.Unit
	local best,bestRoot,bestHumanoid,bestDistance=nil,nil,nil,math.huge
	for _,target in Players:GetPlayers() do
		if target==player then continue end
		local character,targetRoot,humanoid=body(target)
		if not targetRoot or not humanoid or humanoid.Health<=0 or targetRoot.Anchored then continue end
		local delta=targetRoot.Position-root.Position
		local horizontal=Vector3.new(delta.X,0,delta.Z)
		if horizontal.Magnitude<0.05 then continue end
		local distance=delta.Magnitude
		if distance>item.Range or distance>=bestDistance then continue end
		local safe=Service.safe(target,targetRoot)
		local params=RaycastParams.new()
		params.FilterType=Enum.RaycastFilterType.Exclude
		params.FilterDescendantsInstances={player.Character,character}
		params.RespectCanCollide=true
		params.CollisionGroup=root.CollisionGroup
		local visible=workspace:Raycast(root.Position+Vector3.new(0,0.5,0),delta,params)==nil
		if Rules.canHit(distance,delta.Y,forward:Dot(horizontal.Unit),item.Range,visible,false,safe,true,os.clock()<state(target).ImmuneUntil) then
			best,bestRoot,bestHumanoid,bestDistance=target,targetRoot,humanoid,distance
		end
	end
	if not best then return end
	local direction=Vector3.new(bestRoot.Position.X-root.Position.X,0,bestRoot.Position.Z-root.Position.Z).Unit
	local old=bestRoot.AssemblyLinearVelocity
	local desired=direction*item.Power+Vector3.new(0,math.max(old.Y,item.Lift),0)
	local previous=bestHumanoid.PlatformStand
	pcall(function() bestRoot:SetNetworkOwner(nil) end)
	bestHumanoid.PlatformStand=true
	bestRoot:ApplyImpulse((desired-old)*bestRoot.AssemblyMass)
	bestRoot:SetAttribute("ClubKnockbackUntil",workspace:GetServerTimeNow()+Rules.Stagger+0.1)
	state(best).ImmuneUntil=os.clock()+Rules.HitImmunity
	table.insert(Service.Staggers,{Root=bestRoot,Humanoid=bestHumanoid,Until=os.clock()+Rules.Stagger,Previous=previous})
	Service.Remotes.ClubHit:FireAllClients(player.UserId,best.UserId,bestRoot.Position,item.Id)
end
function Service.remove(player) Service.States[player]=nil end
function Service.start(tower,remotes,economy,data)
	Service.Tower=tower; Service.Remotes=remotes; Service.Economy=economy; Service.Data=data
	economy.Clubs=Service
	local templates=Instance.new("Folder")
	templates.Name="TowerClubTemplates"; templates.Parent=game:GetService("ServerStorage")
	for _,item in Catalog.Items do
		if item.Category=="Club" then
			local tool=makeTool(item); tool.Parent=templates
			Service.Templates[item.Id]=tool
		end
	end
	remotes.ClubAttack.OnServerEvent:Connect(function(player) Service.request(player) end)
	local elapsed=0
	local connection
	connection=RunService.Heartbeat:Connect(function(dt)
		if not tower.Parent then connection:Disconnect(); return end
		local now=os.clock()
		for player,s in Service.States do
			if s.Pending and s.Pending.At<=now then
				local pending=s.Pending; s.Pending=nil
				if player.Parent then resolve(player,pending) end
			end
		end
		for i=#Service.Staggers,1,-1 do
			local entry=Service.Staggers[i]
			if now>=entry.Until then
				if entry.Humanoid.Parent and entry.Humanoid.Health>0 then
					entry.Humanoid.PlatformStand=entry.Previous
					if not entry.Previous then entry.Humanoid:ChangeState(Enum.HumanoidStateType.GettingUp) end
				end
				if entry.Root.Parent then pcall(function() entry.Root:SetNetworkOwnershipAuto() end) end
				table.remove(Service.Staggers,i)
			end
		end
		elapsed+=dt
		if elapsed>=0.2 then
			elapsed=0
			for _,player in Players:GetPlayers() do
				local _,root=body(player)
				if root then player:SetAttribute("ClubSafe",Service.safe(player,root)) end
			end
		end
	end)
end
return Service
