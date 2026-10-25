--!strict
local Players=game:GetService("Players")
local RunService=game:GetService("RunService")
local DataStoreService=game:GetService("DataStoreService")
local MarketplaceService=game:GetService("MarketplaceService")
local Shared=game:GetService("ReplicatedStorage").Shared
local Config=require(Shared.GameConfig)
local Catalog=require(Shared.CosmeticCatalog)
local Rules=require(Shared.EconomyRules)
local Receipts=require(Shared.ReceiptProcessor)
local Commerce=require(script.Parent.CommerceConfig)
local Cosmetics=require(script.Parent.CosmeticService)
local persistent=not RunService:IsStudio() or Config.StudioPersistence
local store=if persistent then DataStoreService:GetDataStore(Commerce.DataStoreName) else nil
local Economy={Profiles={},Products={},Remotes=nil}
local byProduct={}
for _,product in Commerce.Products do
	assert(product.ProductId>=0 and product.ProductId%1==0 and product.Coins>0 and product.Coins%1==0 and product.Coins<=Rules.MaxPack)
	if product.ProductId>0 then
		assert(not byProduct[product.ProductId],"Developer Product IDs must be unique")
		byProduct[product.ProductId]=product
	end
end
local function retry(operation)
	local message
	for attempt=1,3 do
		local ok,result=pcall(operation)
		if ok then return true,result end
		message=result
		if attempt<3 then task.wait(attempt) end
	end
	return false,message
end
function Economy.public(player)
	local p=Economy.Profiles[player]
	if not p then return {Ready=false} end
	local w=p.Wallet
	-- Never replicate receipt history to clients.
	return {Ready=true,Revision=w.Revision,Coins=w.Coins,Owned=w.Owned,Equipped=w.Equipped,Day=w.Day,Collected=w.Collected,
		Supporter=w.Supporter,WinRewarded=w.WinRewarded,Products=Economy.Products,Persistent=persistent}
end
function Economy.publish(player)
	local p=Economy.Profiles[player]
	if not p or not player.Parent then return end
	player:SetAttribute("Coins",p.Wallet.Coins)
	player:SetAttribute("CosmeticTrail",p.Wallet.Equipped.Trail)
	player:SetAttribute("CosmeticVictory",p.Wallet.Equipped.Victory)
	player:SetAttribute("CosmeticTitle",p.Wallet.Equipped.Title)
	Economy.Remotes.ShopStateChanged:FireClient(player,Economy.public(player))
	local signature=p.Wallet.Equipped.Trail..p.Wallet.Equipped.Title
	if signature~=p.Appearance then Cosmetics.apply(player,p.Wallet); p.Appearance=signature end
end
function Economy.load(player)
	local saved=nil
	if store then
		local ok,value=retry(function() return store:GetAsync("u_"..player.UserId) end)
		if not ok then
			warn("[Economy] Load failed: "..tostring(value))
			if player.Parent then player:Kick("Could not load coins and inventory. Please rejoin; no data was overwritten.") end
			return false
		end
		saved=value
	end
	if not player.Parent then return false end
	Economy.Profiles[player]={Wallet=Rules.sanitize(saved,Catalog),Busy=false,LastRequest=-10}
	Economy.publish(player)
	return true
end
function Economy.change(player,command)
	local p=Economy.Profiles[player]
	if not p then return false,"not_loaded" end
	local deadline=os.clock()+12
	while p.Busy do
		if os.clock()>deadline or not player.Parent then return false,"busy" end
		task.wait(0.05)
	end
	if Economy.Profiles[player]~=p then return false,"not_loaded" end
	p.Busy=true
	local status="invalid"
	local ok,state
	if store then
		ok,state=retry(function()
			return store:UpdateAsync("u_"..player.UserId,function(old)
				local nextState,result=Rules.apply(old,command,Catalog)
				status=result
				return nextState
			end)
		end)
	else
		ok,state=pcall(function()
			local nextState,result=Rules.apply(p.Wallet,command,Catalog)
			status=result
			return nextState
		end)
	end
	p.Busy=false
	if not ok then warn("[Economy] Transaction pending: "..tostring(state)); return false,"save_failed" end
	p.Wallet=state
	Economy.publish(player)
	return true,status
end
function Economy.stage(player,stage)
	return Economy.change(player,{Kind="stage",Stage=stage})
end
function Economy.victory(player,cf)
	Economy.change(player,{Kind="win"})
	local p=Economy.Profiles[player]
	if p and player.Parent then Economy.Remotes.CosmeticVictory:FireAllClients(player.UserId,cf,p.Wallet.Equipped.Victory) end
end
function Economy.character(player,character)
	local p=Economy.Profiles[player]
	if not p then return end
	if character:WaitForChild("Head",15) and character:WaitForChild("HumanoidRootPart",15) and player.Character==character then
		Cosmetics.apply(player,p.Wallet)
	end
end
function Economy.remove(player)
	-- All balance/inventory changes are already durable UpdateAsync transactions.
	Economy.Profiles[player]=nil
end
local notices={not_enough_coins="Недостаточно монет",requires_win="Сначала покорите 50-й этап",requires_support="Титул выдаётся за поддержку проекта",not_owned="Сначала купите предмет",save_failed="Не удалось сохранить. Попробуйте ещё раз",busy="Покупка обрабатывается"}
function Economy.start(remotes)
	Economy.Remotes=remotes
	local context={Products=byProduct,Durable=store~=nil,
		GetPlayer=function(id) return Players:GetPlayerByUserId(id) end,
		IsLoaded=function(player) return Economy.Profiles[player]~=nil end,
		Grant=Economy.change}
	MarketplaceService.ProcessReceipt=function(receipt)
		local decision,status=Receipts.process(receipt,context)
		if decision=="PurchaseGranted" and status=="ok" then
			local player=Players:GetPlayerByUserId(receipt.PlayerId)
			if player then remotes.ShopNotice:FireClient(player,"Покупка подтверждена · "..byProduct[receipt.ProductId].Coins.." монет") end
		end
		return Enum.ProductPurchaseDecision[decision]
	end
	remotes.ShopGetState.OnServerInvoke=function(player) return Economy.public(player) end
	remotes.ShopRequest.OnServerEvent:Connect(function(player,action,id)
		local p=Economy.Profiles[player]
		if not p or type(action)~="string" or type(id)~="string" or #id>64 or os.clock()-p.LastRequest<0.6 then return end
		p.LastRequest=os.clock()
		if action=="donate" then
			for _,product in Economy.Products do
				if product.Key==id and product.Enabled then
					local ok=pcall(function() MarketplaceService:PromptProductPurchase(player,product.ProductId) end)
					if not ok then remotes.ShopNotice:FireClient(player,"Покупка сейчас недоступна") end
					return
				end
			end
			remotes.ShopNotice:FireClient(player,"Покупка пока недоступна")
		elseif action=="buy" or action=="equip" then
			if not Catalog.ById[id] then return end
			local ok,result=Economy.change(player,{Kind=action,Id=id})
			remotes.ShopNotice:FireClient(player,if ok and result=="ok" then "Предмет выбран" else notices[result] or "Операция недоступна")
		end
	end)
	-- Zero IDs stay visible but disabled. No invented prices or fake successful sales.
	for _,product in Commerce.Products do
		table.insert(Economy.Products,{Key=product.Key,Name=product.Name,Coins=product.Coins,ProductId=product.ProductId,Enabled=false})
	end
	task.spawn(function()
		for _,product in Economy.Products do
			if product.ProductId>0 and not RunService:IsStudio() and game.GameId>0 then
				local ok,info=pcall(function() return MarketplaceService:GetProductInfoAsync(product.ProductId,Enum.InfoType.Product) end)
				if ok and type(info)=="table" and type(info.PriceInRobux)=="number" and info.IsForSale~=false then
					product.Price=info.PriceInRobux
					product.Enabled=true
				else warn("[Commerce] Product metadata unavailable: "..product.ProductId) end
			end
		end
		for player in Economy.Profiles do Economy.publish(player) end
	end)
end
return Economy
