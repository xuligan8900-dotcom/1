--!strict
local Players=game:GetService("Players")
local RunService=game:GetService("RunService")
local ReplicatedStorage=game:GetService("ReplicatedStorage")
local tower=workspace:WaitForChild("GeneratedTower")
local folder=tower:WaitForChild("CollectibleCoins")
local player=Players.LocalPlayer
local remotes=ReplicatedStorage:WaitForChild("Remotes")
local state=nil
local function update()
	local day=tower:GetAttribute("CoinDay")
	for _,coin in folder:GetChildren() do
		local collected=state and state.Day==day and state.Collected[coin:GetAttribute("CoinId")]
		coin.LocalTransparencyModifier=if collected then 1 else 0
	end
end
remotes.ShopStateChanged.OnClientEvent:Connect(function(value) if value.Ready and (not state or value.Revision>=state.Revision) then state=value; update() end end)
folder.ChildAdded:Connect(update)
tower:GetAttributeChangedSignal("CoinDay"):Connect(update)
task.spawn(function()
	if not player:GetAttribute("DataLoaded") then player:GetAttributeChangedSignal("DataLoaded"):Wait() end
	local ok,value=pcall(function() return remotes.ShopGetState:InvokeServer() end)
	if ok and value.Ready and (not state or value.Revision>=state.Revision) then state=value; update() end
end)
RunService.RenderStepped:Connect(function()
	local root=player.Character and player.Character:FindFirstChild("HumanoidRootPart")
	if not root then return end
	local now=workspace:GetServerTimeNow()
	for _,coin in folder:GetChildren() do
		local base=coin:GetAttribute("Base")
		if base and coin.LocalTransparencyModifier<1 and math.abs(base.Position.Y-root.Position.Y)<55 then
			coin.CFrame=base*CFrame.Angles(0,now*1.6,0)+Vector3.new(0,math.sin(now*2)*0.2,0)
		end
	end
end)
