--!strict
-- Pure atomic transitions. UpdateAsync may replay these without side effects.
local Rules={CoinValue=5,StageValue=20,FirstWinValue=250,MaxPack=100000,MaxCoins=9000000000000}
local function integer(value,maximum)
	if type(value)~="number" or value~=value or value==math.huge then return 0 end
	return math.clamp(math.floor(value),0,maximum)
end
function Rules.validCoin(id)
	if type(id)~="string" then return false end
	local stage,node=string.match(id,"^(%d+)_(%d+)$")
	stage,node=tonumber(stage),tonumber(node)
	return stage~=nil and stage>=1 and stage<=50 and (node==4 or node==8) and id==stage.."_"..node
end
function Rules.sanitize(old,catalog)
	old=if type(old)=="table" then old else {}
	local state={Version=1,Revision=integer(old.Revision,Rules.MaxCoins),Coins=integer(old.Coins,Rules.MaxCoins),StageRewardMax=integer(old.StageRewardMax,50),
		Day=integer(old.Day,1000000),Collected={},Receipts={},Owned={},Equipped={},
		WinRewarded=old.WinRewarded==true,Supporter=old.Supporter==true}
	if type(old.Collected)=="table" then
		for id,value in old.Collected do if value==true and Rules.validCoin(id) then state.Collected[id]=true end end
	end
	if type(old.Receipts)=="table" then
		for id,value in old.Receipts do
			if type(id)=="string" and #id>0 and #id<=128 and value==true then state.Receipts[id]=true end
		end
	end
	for _,item in catalog.Items do
		local owned=type(old.Owned)=="table" and old.Owned[item.Id]==true
		if owned or catalog.Defaults[item.Category]==item.Id then state.Owned[item.Id]=true end
	end
	if state.WinRewarded then state.Owned.title_master=true end
	if state.Supporter then state.Owned.title_supporter=true end
	for category,default in catalog.Defaults do
		local id=type(old.Equipped)=="table" and old.Equipped[category] or default
		local item=catalog.ById[id]
		state.Equipped[category]=if item and item.Category==category and state.Owned[id] then id else default
	end
	return state
end
function Rules.apply(old,command,catalog)
	local state=Rules.sanitize(old,catalog)
	if command.Kind=="collect" then
		if not Rules.validCoin(command.Id) or type(command.Day)~="number" or command.Day%1~=0 or command.Day<state.Day then return state,"invalid" end
		if command.Day>state.Day then state.Day=command.Day; state.Collected={} end
		if state.Collected[command.Id] then return state,"duplicate" end
		if state.Coins>Rules.MaxCoins-Rules.CoinValue then return state,"balance_limit" end
		state.Collected[command.Id]=true
		state.Coins+=Rules.CoinValue
	elseif command.Kind=="stage" then
		local reached=integer(command.Stage,50)
		local count=math.max(0,reached-state.StageRewardMax)
		if count==0 then return state,"duplicate" end
		if state.Coins>Rules.MaxCoins-count*Rules.StageValue then return state,"balance_limit" end
		state.Coins+=count*Rules.StageValue
		state.StageRewardMax=reached
	elseif command.Kind=="win" then
		if state.WinRewarded then return state,"duplicate" end
		if state.Coins>Rules.MaxCoins-Rules.FirstWinValue then return state,"balance_limit" end
		state.Coins+=Rules.FirstWinValue
		state.WinRewarded=true
		state.Owned.title_master=true
	elseif command.Kind=="receipt" then
		if type(command.Id)~="string" or #command.Id==0 or #command.Id>128 then return state,"invalid" end
		if state.Receipts[command.Id] then return state,"duplicate" end
		if type(command.Amount)~="number" or command.Amount%1~=0 or command.Amount<=0 or command.Amount>Rules.MaxPack then return state,"invalid" end
		if state.Coins>Rules.MaxCoins-command.Amount then return state,"balance_limit" end
		-- Receipt marker and grant are written to the SAME user key atomically.
		state.Coins+=command.Amount
		state.Receipts[command.Id]=true
		state.Supporter=true
		state.Owned.title_supporter=true
	elseif command.Kind=="buy" or command.Kind=="equip" then
		local item=catalog.ById[command.Id]
		if not item then return state,"invalid" end
		if item.RequiredWin and not state.WinRewarded then return state,"requires_win" end
		if item.RequiredSupport and not state.Supporter then return state,"requires_support" end
		if not state.Owned[item.Id] then
			if command.Kind=="equip" then return state,"not_owned" end
			if state.Coins<item.Price then return state,"not_enough_coins" end
			state.Coins-=item.Price
			state.Owned[item.Id]=true
		end
		state.Equipped[item.Category]=item.Id
	else return state,"invalid" end
	state.Revision+=1
	return state,"ok"
end
return table.freeze(Rules)
