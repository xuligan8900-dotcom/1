--!strict
local Players=game:GetService("Players")
local player=Players.LocalPlayer
local floors=workspace:WaitForChild("GeneratedTower"):WaitForChild("RecoveryFloors")
local function update()
	local unlocked=player:GetAttribute("RecoveryStage") or 0
	for _,model in floors:GetChildren() do
		local active=unlocked>=(model:GetAttribute("UnlockStage") or math.huge)
		for _,object in model:GetDescendants() do
			if object:IsA("BasePart") then
				-- Locked floors are pass-through for this character and shown as ghosts.
				object.LocalTransparencyModifier=if active then 0 else 0.94
			elseif object:IsA("BillboardGui") then object.Enabled=active end
		end
	end
end
player:GetAttributeChangedSignal("RecoveryStage"):Connect(update)
floors.DescendantAdded:Connect(update)
update()
