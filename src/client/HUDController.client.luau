--!strict
local Players=game:GetService("Players")
local TweenService=game:GetService("TweenService")
local RunService=game:GetService("RunService")
local ReplicatedStorage=game:GetService("ReplicatedStorage")
local Config=require(ReplicatedStorage:WaitForChild("Shared").GameConfig)
local player=Players.LocalPlayer
local remotes=ReplicatedStorage:WaitForChild("Remotes")
local tower=workspace:WaitForChild("GeneratedTower")
local checkpointFolder=tower:WaitForChild("Checkpoints")
local gui=Instance.new("ScreenGui")
gui.Name="MechanicalTowerHUD"
gui.ResetOnSpawn=false
gui.ZIndexBehavior=Enum.ZIndexBehavior.Sibling
gui.Parent=player:WaitForChild("PlayerGui")
local function round(object,radius)
	local corner=Instance.new("UICorner")
	corner.CornerRadius=UDim.new(0,radius)
	corner.Parent=object
end
local function label(parent,name,text,position,size,fontSize,color)
	local object=Instance.new("TextLabel")
	object.Name=name
	object.BackgroundTransparency=1
	object.Position=position
	object.Size=size
	object.Font=Enum.Font.GothamBold
	object.TextSize=fontSize
	object.TextColor3=color or Color3.fromRGB(235,242,255)
	object.TextXAlignment=Enum.TextXAlignment.Left
	object.Text=text
	object.Parent=parent
	return object
end
local panel=Instance.new("Frame")
panel.Name="ProgressPanel"
panel.Position=UDim2.fromOffset(14,12)
panel.Size=UDim2.fromOffset(360,182)
panel.BackgroundColor3=Color3.fromRGB(16,22,34)
panel.BackgroundTransparency=0.08
panel.Parent=gui
round(panel,14)
local scale=Instance.new("UIScale")
scale.Parent=panel
local border=Instance.new("UIStroke")
border.Color=Config.ZoneColors[1]
border.Transparency=0.35
border.Parent=panel
label(panel,"Title","MEGA / MECHANICAL TOWER",UDim2.fromOffset(18,12),UDim2.fromOffset(326,20),13,Config.ZoneColors[1])
local zone=label(panel,"Zone","LOADING…",UDim2.fromOffset(18,36),UDim2.fromOffset(326,18),12,Color3.fromRGB(150,169,191))
local stageText=label(panel,"Stage","Stage: 0 / 50",UDim2.fromOffset(18,61),UDim2.fromOffset(326,30),25)
local track=Instance.new("Frame")
track.Size=UDim2.fromOffset(324,8)
track.Position=UDim2.fromOffset(18,104)
track.BackgroundColor3=Color3.fromRGB(43,53,70)
track.ClipsDescendants=true
track.Parent=panel
round(track,4)
local fill=Instance.new("Frame")
fill.Name="Progress"
fill.Size=UDim2.fromScale(0,1)
fill.BackgroundColor3=Config.ZoneColors[1]
fill.BorderSizePixel=0
fill.Parent=track
round(fill,4)
local stats=label(panel,"Stats","Deaths: 0     Time: 00:00",UDim2.fromOffset(18,123),UDim2.fromOffset(326,22),14)
local status=label(panel,"SaveStatus","",UDim2.fromOffset(18,150),UDim2.fromOffset(326,18),11,Color3.fromRGB(150,169,191))
local toast=label(gui,"CheckpointToast","",UDim2.fromScale(0.5,0.24),UDim2.fromScale(0.86,0.09),25)
toast.AnchorPoint=Vector2.new(0.5,0.5)
toast.TextXAlignment=Enum.TextXAlignment.Center
toast.TextScaled=true
toast.TextStrokeTransparency=0.25
toast.Visible=false
local toastConstraint=Instance.new("UITextSizeConstraint")
toastConstraint.MaxTextSize=28
toastConstraint.MinTextSize=12
toastConstraint.Parent=toast
local victory=Instance.new("Frame")
victory.Name="VictoryGui"
victory.AnchorPoint=Vector2.new(0.5,0.5)
victory.Position=UDim2.fromScale(0.5,0.55)
victory.Size=UDim2.fromScale(0.86,0.7)
victory.BackgroundColor3=Color3.fromRGB(15,22,37)
victory.Visible=false
victory.Parent=gui
round(victory,20)
local aspect=Instance.new("UIAspectRatioConstraint")
aspect.AspectRatio=1.5
aspect.DominantAxis=Enum.DominantAxis.Width
aspect.Parent=victory
local sizeLimit=Instance.new("UISizeConstraint")
sizeLimit.MaxSize=Vector2.new(540,360)
sizeLimit.Parent=victory
local winTitle=label(victory,"WinTitle","YOU WIN!",UDim2.fromScale(0.07,0.1),UDim2.fromScale(0.86,0.18),40,Config.ZoneColors[5])
winTitle.TextScaled=true
winTitle.TextXAlignment=Enum.TextXAlignment.Center
local winInfo=label(victory,"WinInfo","",UDim2.fromScale(0.08,0.34),UDim2.fromScale(0.84,0.25),19)
winInfo.TextScaled=true
winInfo.TextWrapped=true
winInfo.TextXAlignment=Enum.TextXAlignment.Center
local replay=Instance.new("TextButton")
replay.Name="PlayAgain"
replay.Size=UDim2.fromScale(0.7,0.18)
replay.Position=UDim2.fromScale(0.15,0.69)
replay.BackgroundColor3=Config.ZoneColors[5]
replay.TextColor3=Color3.fromRGB(12,25,35)
replay.Font=Enum.Font.GothamBold
replay.Text="Play Again"
replay.TextScaled=true
replay.Parent=victory
round(replay,10)
replay.Activated:Connect(function() remotes.PlayAgain:FireServer() end)
local function formatTime(seconds)
	seconds=math.max(0,math.floor(seconds))
	return string.format("%02d:%02d",math.floor(seconds/60),seconds%60)
end
local progressTween
local function update()
	local stage=player:GetAttribute("RunStage") or 0
	local maximum=player:GetAttribute("MaxStage") or 0
	local zoneId=math.clamp(math.ceil(math.max(1,stage+1)/10),1,5)
	local color=Config.ZoneColors[zoneId]
	stageText.Text=string.format("Stage: %d / 50%s",stage,if player:GetAttribute("Completed") then "  ★" else "")
	zone.Text=Config.ZoneNames[zoneId].."  /  BEST "..maximum.." OF 50"
	zone.TextColor3=color
	border.Color=color
	fill.BackgroundColor3=color
	if progressTween then progressTween:Cancel() end
	progressTween=TweenService:Create(fill,TweenInfo.new(0.4,Enum.EasingStyle.Quad),{Size=UDim2.fromScale(stage/50,1)})
	progressTween:Play()
	status.Text=if not player:GetAttribute("DataLoaded") then "Loading progress…"
		elseif not player:GetAttribute("Persistence") then string.format("Respawn: %d · Safety floor: %d · Studio session",stage,player:GetAttribute("RecoveryStage") or 0)
		elseif player:GetAttribute("SavePending") then "Saving progress…" else string.format("Saved · Respawn: %d · Safety floor: %d",stage,player:GetAttribute("RecoveryStage") or 0)
	victory.Visible=player:GetAttribute("Won")==true
	local finishTime=player:GetAttribute("FinishTime")
	winInfo.Text=if finishTime then "50 / 50 · MASTER MECHANIC\n"..(if player:GetAttribute("FullRun") then "Full run: " else "Session time: ")..formatTime(finishTime).."\nMaximum progress is preserved."
		else "50 / 50 · MASTER MECHANIC\nWelcome back to the crown!\nPlay again without losing your record."
	-- Local color changes are personal: one player's touch never recolors another player's progress.
	for _,cp in checkpointFolder:GetChildren() do
		cp.Color=if cp:GetAttribute("Stage")<=stage then Color3.fromRGB(65,255,155) else Config.ZoneColors[math.ceil(cp:GetAttribute("Stage")/10)]
	end
end
for _,attribute in {"DataLoaded","RunStage","MaxStage","Won","Completed","SavePending","Persistence","FinishTime","Deaths","RecoveryStage"} do
	player:GetAttributeChangedSignal(attribute):Connect(update)
end
local function resize()
	local camera=workspace.CurrentCamera
	if camera then scale.Scale=math.clamp(math.min(camera.ViewportSize.X/600,camera.ViewportSize.Y/600),0.62,1) end
end
workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(resize)
local timerAccumulator=0
RunService.RenderStepped:Connect(function(dt)
	timerAccumulator+=dt
	if timerAccumulator<0.1 then return end
	timerAccumulator=0
	resize()
	local started=player:GetAttribute("StartedAt") or workspace:GetServerTimeNow()
	local duration=player:GetAttribute("FinishTime") or (workspace:GetServerTimeNow()-started)
	stats.Text=string.format("Deaths: %d     Time: %s",player:GetAttribute("Deaths") or 0,formatTime(duration))
end)
local toastVersion=0
remotes.CheckpointNotification.OnClientEvent:Connect(function(stage)
	toastVersion+=1
	local version=toastVersion
	toast.Text="Checkpoint "..stage.."/50"
	toast.TextColor3=Config.ZoneColors[math.ceil(stage/10)]
	toast.Visible=true
	task.delay(2.5,function() if toastVersion==version then toast.Visible=false end end)
end)
checkpointFolder.ChildAdded:Connect(update)
update()
resize()
