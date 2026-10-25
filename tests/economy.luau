--!strict
local Test={}
function Test.run(check,rules,catalog,processor)
	local wallet=rules.sanitize(nil,catalog)
	check(wallet.Coins==0 and wallet.Equipped.Trail=="trail_none","New wallet defaults")
	check(wallet.Owned.trail_none and not wallet.Owned.title_supporter,"Free/premium ownership")
	local status
	wallet,status=rules.apply(wallet,{Kind="buy",Id="trail_cyan"},catalog)
	check(status=="not_enough_coins" and wallet.Coins==0,"Overspend accepted")
	wallet,status=rules.apply(wallet,{Kind="equip",Id="trail_prism"},catalog)
	check(status=="not_owned" and wallet.Equipped.Trail=="trail_none","Unowned item equipped")
	for stage=1,50 do
		wallet,status=rules.apply(wallet,{Kind="stage",Stage=stage},catalog)
		check(status=="ok" and wallet.Coins==stage*20,"Stage reward wrong")
		local repeated,result=rules.apply(wallet,{Kind="stage",Stage=stage},catalog)
		check(result=="duplicate" and repeated.Coins==wallet.Coins,"Stage reward farmed twice")
	end
	wallet,status=rules.apply(wallet,{Kind="buy",Id="trail_cyan",Price=-100000},catalog)
	check(status=="ok" and wallet.Coins==850,"Server price replaced by client price")
	check(wallet.Owned.trail_cyan and wallet.Equipped.Trail=="trail_cyan","Purchase not equipped")
	wallet,status=rules.apply(wallet,{Kind="buy",Id="trail_cyan"},catalog)
	check(wallet.Coins==850,"Duplicate purchase charged again")
	wallet,status=rules.apply(wallet,{Kind="equip",Id="trail_none"},catalog)
	check(wallet.Coins==850 and wallet.Equipped.Trail=="trail_none","Unequip changed balance")
	wallet,status=rules.apply(wallet,{Kind="buy",Id="title_master"},catalog)
	check(status=="requires_win","Winner title purchased early")
	wallet,status=rules.apply(wallet,{Kind="buy",Id="title_supporter"},catalog)
	check(status=="requires_support","Supporter title acquired without receipt")
	local beforeWin=wallet.Coins
	wallet,status=rules.apply(wallet,{Kind="win"},catalog)
	check(wallet.Coins==beforeWin+250 and wallet.Owned.title_master,"First win reward absent")
	wallet,status=rules.apply(wallet,{Kind="win"},catalog)
	check(status=="duplicate" and wallet.Coins==beforeWin+250,"Win bonus farmed")
	wallet,status=rules.apply(wallet,{Kind="buy",Id="unknown_item"},catalog)
	check(status=="invalid","Unknown cosmetic accepted")
	for stage=1,50 do
		for _,node in {4,8} do
			local id=stage.."_"..node
			local before=wallet.Coins
			wallet,status=rules.apply(wallet,{Kind="collect",Id=id,Day=20000},catalog)
			check(status=="ok" and wallet.Coins==before+5,"Valid map coin refused")
			wallet,status=rules.apply(wallet,{Kind="collect",Id=id,Day=20000},catalog)
			check(status=="duplicate" and wallet.Coins==before+5,"Collected coin repeated same day")
		end
	end
	for _,id in {"0_4","51_8","1_3","01_4","1_04","999_4","receipt","1_4_extra"} do
		wallet,status=rules.apply(wallet,{Kind="collect",Id=id,Day=20000},catalog)
		check(status=="invalid","Invalid coin ID minted currency")
	end
	local beforeDay=wallet.Coins
	wallet,status=rules.apply(wallet,{Kind="collect",Id="1_4",Day=20001},catalog)
	check(status=="ok" and wallet.Coins==beforeDay+5,"Daily coin reset failed")
	wallet,status=rules.apply(wallet,{Kind="collect",Id="1_4",Day=20000},catalog)
	check(status=="invalid" and wallet.Coins==beforeDay+5,"Stale server reset the claim day backwards")
	-- Simulate a committed grant with its network response lost, followed by a
	-- replay on a second server. The receipt marker survives intervening spending.
	local receipt={Kind="receipt",Id="receipt-a",Amount=1000}
	local coinsBeforeReceipt=wallet.Coins
	local discarded=rules.apply(wallet,receipt,catalog) -- callback trial, not committed
	wallet,status=rules.apply(wallet,receipt,catalog)
	check(status=="ok" and wallet.Coins==coinsBeforeReceipt+1000,"Receipt credit wrong")
	check(discarded.Coins==wallet.Coins,"Callback has external side effects")
	check(wallet.Supporter and wallet.Owned.title_supporter and wallet.Receipts["receipt-a"],"Receipt bonus/marker absent")
	wallet,status=rules.apply(wallet,{Kind="buy",Id="fx_prism"},catalog)
	local afterSpending=wallet.Coins
	wallet,status=rules.apply(wallet,receipt,catalog)
	check(status=="duplicate" and wallet.Coins==afterSpending,"Receipt replay recreated spent coins")
	wallet,status=rules.apply(wallet,{Kind="receipt",Id="receipt-b",Amount=250},catalog)
	check(status=="ok" and wallet.Coins==afterSpending+250,"Second distinct receipt lost")
	for _,amount in {-10,0,1.5,100001,math.huge,0/0} do
		local before=wallet.Coins
		wallet,status=rules.apply(wallet,{Kind="receipt",Id="bad",Amount=amount},catalog)
		check(status=="invalid" and wallet.Coins==before and not wallet.Receipts.bad,"Bad paid credit accepted")
	end
	local restored=rules.sanitize(wallet,catalog)
	check(restored.Coins==wallet.Coins and restored.Receipts["receipt-a"] and restored.Receipts["receipt-b"],"Reload lost paid receipt history")
	check(restored.Owned.fx_prism and restored.Equipped.Victory=="fx_prism","Reload lost cosmetic")
	local other=rules.sanitize(nil,catalog)
	check(other.Coins==0 and not other.Receipts["receipt-a"],"One player's wallet contaminated another")
	local capped=rules.sanitize({Coins=rules.MaxCoins},catalog)
	capped,status=rules.apply(capped,{Kind="receipt",Id="pending",Amount=250},catalog)
	check(status=="balance_limit" and not capped.Receipts.pending,"Paid credit acknowledged without capacity")
	check(rules.sanitize({Coins=0/0},catalog).Coins==0,"NaN balance accepted")
	check(rules.sanitize({Equipped={Trail="fx_gold"}},catalog).Equipped.Trail=="trail_none","Cross-category equip accepted")
	for _,item in catalog.Items do
		check(item.Price>=0 and item.Price%1==0,"Invalid cosmetic price")
		check(item.Category=="Trail" or item.Category=="Victory" or item.Category=="Title","Gameplay upgrade in cosmetic catalog")
	end
	-- Exercise the exact receipt processor used by the server, including a lost
	-- successful response. These are mock storage callbacks, not live Robux tests.
	local persisted=rules.sanitize(nil,catalog)
	local loseResponse=true
	local writes=0
	local online=true
	local loaded=true
	local context={Products={[101]={Coins=250}},Durable=true,
		GetPlayer=function(id) return if online and id==7 then "player7" else nil end,
		IsLoaded=function() return loaded end,
		Grant=function(_,command)
			writes+=1
			local new,result=rules.apply(persisted,command,catalog)
			persisted=new
			if loseResponse then loseResponse=false; return false,"save_failed" end
			return true,result
		end}
	local receipt={PurchaseId="platform-receipt",ProductId=101,PlayerId=7}
	local decision=processor.process(receipt,context)
	check(decision=="NotProcessedYet" and persisted.Coins==250,"Unconfirmed write acknowledged prematurely")
	decision=processor.process(receipt,context)
	check(decision=="PurchaseGranted" and persisted.Coins==250,"Receipt retry lost or duplicated coins")
	decision=processor.process(receipt,context)
	check(decision=="PurchaseGranted" and persisted.Coins==250,"Third receipt callback granted again")
	online=false
	decision=processor.process(receipt,context)
	check(decision=="NotProcessedYet","Offline purchase acknowledged")
	online=true; loaded=false
	decision=processor.process(receipt,context)
	check(decision=="NotProcessedYet","Unloaded wallet acknowledged")
	loaded=true; context.Durable=false
	decision=processor.process(receipt,context)
	check(decision=="NotProcessedYet","Session-only wallet accepted real payment")
	context.Durable=true
	decision=processor.process({PurchaseId="unknown",ProductId=999,PlayerId=7},context)
	check(decision=="NotProcessedYet" and writes==3,"Unknown product credited")
	decision=processor.process({ProductId=101,PlayerId=7},context)
	check(decision=="NotProcessedYet","Missing receipt ID accepted")
	context.Grant=function() error("DataStore unavailable") end
	decision=processor.process(receipt,context)
	check(decision=="NotProcessedYet","Storage exception acknowledged purchase")
	print("Economy PASS: 100 coin claims/day, stage rewards, purchase/equip, durable receipt replay model, independent wallets")
end
return Test
