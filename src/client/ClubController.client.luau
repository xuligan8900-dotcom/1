--!strict
local Players=game:GetService("Players")
local ReplicatedStorage=game:GetService("ReplicatedStorage")
local ContextActionService=game:GetService("ContextActionService")
local TweenService=game:GetService("TweenService")
local RunService=game:GetService("RunService")
local Debris=game:GetService("Debris")
local SoundService=game:GetService("SoundService")
local player=Players.LocalPlayer
local Catalog=require(ReplicatedStorage:WaitForChild("Shared").CosmeticCatalog)
local remotes=ReplicatedStorage:WaitForChild("Remotes")
local current=nil
local activated=nil
local characterConnections={}
local gui=Instance.new("ScreenGui")
gui.Name="ClubStatus"; gui.ResetOnSpawn=false; gui.Parent=player:WaitForChild("PlayerGui")
local status=Instance.new("TextLabel")
status.AnchorPoint=Vector2.new(0.5,0.5)
status.Position=UDim2.fromScale(0.5,0.78)
status.Size=UDim2.new(0.75,0,0,38)
status.BackgroundTransparency=1
status.TextColor3=Color3.fromRGB(235,245,255)
status.TextStrokeTransparency=0.3
status.Font=Enum.Font.GothamBold
status.TextSize=14
status.TextWrapped=true
status.Visible=false
status.Parent=gui
local function refresh()
	local nextTool=nil
	local character=player.Character
	if character then
		for _,child in character:GetChildren() do
			if child:IsA("Tool") and child:GetAttribute("TowerClub") then nextTool=child; break end
		end
	end
	if nextTool==current then return end
	if activated then activated:Disconnect(); activated=nil end
	ContextActionService:UnbindAction("TowerClubAttack")
	current=nextTool
	status.Visible=current~=nil
	if not current then return end
	activated=current.Activated:Connect(function()
		if current and current.Parent==player.Character then remotes.ClubAttack:FireServer() end
	end)
	ContextActionService:BindAction("TowerClubAttack",function(_,inputState)
		if inputState==Enum.UserInputState.Begin and current then current:Activate() end
		return Enum.ContextActionResult.Sink
	end,true,Enum.KeyCode.F,Enum.KeyCode.ButtonR2)
	ContextActionService:SetTitle("TowerClubAttack","Удар")
	ContextActionService:SetPosition("TowerClubAttack",UDim2.fromScale(0.77,0.55))
end
local function bind(character)
	for _,connection in characterConnections do connection:Disconnect() end
	characterConnections={character.ChildAdded:Connect(function(child)
		if child:IsA("Tool") then table.insert(characterConnections,child:GetAttributeChangedSignal("TowerClub"):Connect(refresh)) end
		refresh()
	end),character.ChildRemoved:Connect(refresh)}
	refresh()
end
player.CharacterAdded:Connect(bind)
if player.Character then bind(player.Character) end
local elapsed=0
RunService.RenderStepped:Connect(function(dt)
	elapsed+=dt
	if elapsed<0.1 then return end
	elapsed=0
	if not current then return end
	local now=workspace:GetServerTimeNow()
	local shield=player:GetAttribute("ClubShieldUntil") or 0
	local cooldown=player:GetAttribute("ClubCooldownUntil") or 0
	if now<shield then status.Text="ЗАЩИТА · "..string.format("%.1f",shield-now).."с"
	elseif player:GetAttribute("ClubSafe") then status.Text="БЕЗОПАСНАЯ ЗОНА · УДАРЫ ОТКЛЮЧЕНЫ"
	elseif cooldown>now then status.Text=string.format("ПЕРЕЗАРЯДКА · %.1fс",cooldown-now)
	else status.Text="КЛИК / F / УДАР · ОТТОЛКНУТЬ ИГРОКА" end
end)
remotes.ClubSwing.OnClientEvent:Connect(function(userId,id)
	local attacker=Players:GetPlayerByUserId(userId)
	local character=attacker and attacker.Character
	local item=Catalog.ById[id]
	if not character or not item or item.Category~="Club" then return end
	local tool=nil
	for _,child in character:GetChildren() do
		if child:IsA("Tool") and child:GetAttribute("ClubId")==id then tool=child; break end
	end
	if not tool then return end
	local rest=tool.Grip
	local animation=Instance.new("StringValue")
	animation.Name="toolanim"; animation.Value="Slash"; animation.Parent=tool
	Debris:AddItem(animation,1)
	TweenService:Create(tool,TweenInfo.new(item.Windup),{Grip=rest*CFrame.Angles(0,0,math.rad(-65))}):Play()
	task.delay(item.Windup,function()
		if not tool.Parent then return end
		TweenService:Create(tool,TweenInfo.new(0.12),{Grip=rest*CFrame.Angles(math.rad(75),0,math.rad(45))}):Play()
		task.delay(0.14,function() if tool.Parent then TweenService:Create(tool,TweenInfo.new(0.2),{Grip=rest}):Play() end end)
	end)
end)
remotes.ClubHit.OnClientEvent:Connect(function(_,_,position,id)
	local camera=workspace.CurrentCamera
	if camera and (camera.CFrame.Position-position).Magnitude>90 then return end
	local item=Catalog.ById[id]
	if not item then return end
	local anchor=Instance.new("Part")
	anchor.Size=Vector3.new(0.1,0.1,0.1); anchor.Position=position
	anchor.Transparency=1; anchor.Anchored=true
	anchor.CanCollide=false; anchor.CanTouch=false; anchor.CanQuery=false
	anchor.Parent=workspace
	local attachment=Instance.new("Attachment"); attachment.Parent=anchor
	local sparks=Instance.new("ParticleEmitter")
	sparks.Texture="rbxasset://textures/particles/sparkles_main.dds"
	sparks.Color=ColorSequence.new(Color3.fromRGB(item.Color[1],item.Color[2],item.Color[3]))
	sparks.Enabled=false; sparks.Rate=0
	sparks.Speed=NumberRange.new(4,9); sparks.Lifetime=NumberRange.new(0.15,0.35)
	sparks.SpreadAngle=Vector2.new(180,180); sparks.Parent=attachment
	sparks:Emit(15)
	Debris:AddItem(anchor,1)
	local sound=Instance.new("Sound")
	sound.SoundId="rbxasset://sounds/electronicpingshort.wav"
	sound.PlaybackSpeed=0.6; sound.Volume=0.2; sound.Parent=SoundService
	sound:Play(); Debris:AddItem(sound,2)
end)
