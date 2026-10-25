--!strict
local ReplicatedStorage=game:GetService("ReplicatedStorage")
local Debris=game:GetService("Debris")
local Players=game:GetService("Players")
local Catalog=require(ReplicatedStorage:WaitForChild("Shared").CosmeticCatalog)
local remotes=ReplicatedStorage:WaitForChild("Remotes")
local function color(rgb) return Color3.fromRGB(rgb[1],rgb[2],rgb[3]) end
remotes.CosmeticVictory.OnClientEvent:Connect(function(userId,cf,effectId)
	local item=Catalog.ById[effectId]
	if not item or item.Category~="Victory" then return end
	local camera=workspace.CurrentCamera
	if userId~=Players.LocalPlayer.UserId and camera and (camera.CFrame.Position-cf.Position).Magnitude>150 then return end
	local anchor=Instance.new("Part")
	anchor.Name="LocalVictoryEffect"
	anchor.Size=Vector3.new(0.1,0.1,0.1)
	anchor.CFrame=cf*CFrame.new(0,5,0)
	anchor.Anchored=true
	anchor.Transparency=1
	anchor.CanCollide=false; anchor.CanQuery=false; anchor.CanTouch=false
	anchor.Parent=workspace
	local attachment=Instance.new("Attachment")
	attachment.Parent=anchor
	local emitter=Instance.new("ParticleEmitter")
	emitter.Texture="rbxasset://textures/particles/sparkles_main.dds"
	emitter.Enabled=false
	emitter.Rate=0
	emitter.Color=ColorSequence.new(color(item.Color),color(item.SecondColor or {255,225,100}))
	emitter.Lifetime=NumberRange.new(1.5,3)
	emitter.Speed=NumberRange.new(12,24)
	emitter.SpreadAngle=Vector2.new(180,180)
	emitter.Acceleration=Vector3.new(0,-15,0)
	emitter.LightEmission=0.8
	emitter.Size=NumberSequence.new(if effectId=="fx_prism" then 0.5 else 0.3,0)
	emitter.Parent=attachment
	Debris:AddItem(anchor,7)
	for burst=1,4 do emitter:Emit(if effectId=="fx_default" then 65 else 90); task.wait(0.4) end
end)
