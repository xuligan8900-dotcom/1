--!strict
local RunService=game:GetService("RunService")
local Route=require(game:GetService("ReplicatedStorage").Shared.Route)
local Definitions=require(game:GetService("ReplicatedStorage").Shared.StageDefinitions)
local U=require(script.Parent.BuildUtil)
local Service={}
function Service.start(tower,economy,progress)
	local folder=U.folder(tower,"CollectibleCoins")
	local coins={}
	for _,stage in Definitions do
		for _,node in {4,8} do
			local x,y,z=Route.point(stage.Id,node,stage.Layout)
			local id=stage.Id.."_"..node
			local coin=U.part(folder,"Coin_"..id,Vector3.new(0.22,1.4,1.4),
				CFrame.new(x,y+2,z)*CFrame.Angles(0,math.pi/2,0),Color3.fromRGB(255,210,60),Enum.Material.Neon,false)
			coin.Shape=Enum.PartType.Cylinder
			coin:SetAttribute("CoinId",id)
			coin:SetAttribute("Base",coin.CFrame)
			coin:SetAttribute("Stage",stage.Id)
			table.insert(coins,coin)
		end
	end
	local elapsed=0
	local connection
	connection=RunService.Heartbeat:Connect(function(dt)
		if not tower.Parent then connection:Disconnect(); return end
		elapsed+=dt
		if elapsed<0.2 then return end
		elapsed=0
		local day=math.floor(os.time()/86400)
		if tower:GetAttribute("CoinDay")~=day then tower:SetAttribute("CoinDay",day) end
		for player,p in economy.Profiles do
			local run=progress.Profiles[player]
			local character=player.Character
			local root=character and character:FindFirstChild("HumanoidRootPart")
			local humanoid=character and character:FindFirstChildOfClass("Humanoid")
			if not run or not root or not humanoid or humanoid.Health<=0 or p.Busy or p.Collecting then continue end
			for _,coin in coins do
				local id=coin:GetAttribute("CoinId")
				if coin:GetAttribute("Stage")>run.RunStage+1 then continue end
				if p.Wallet.Day==day and p.Wallet.Collected[id] then continue end
				if (root.Position-coin.Position).Magnitude<=3 then
					p.Collecting=true
					task.spawn(function()
						economy.change(player,{Kind="collect",Id=id,Day=day})
						p.Collecting=false
					end)
					break
				end
			end
		end
	end)
	return connection
end
return Service
