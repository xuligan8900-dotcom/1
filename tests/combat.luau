--!strict
local Test={}
function Test.run(check,rules,economy,catalog,passes)
	local wallet=economy.sanitize({Coins=777,Owned={trail_cyan=true},Equipped={Trail="trail_cyan"}},catalog)
	check(wallet.Owned.club_wood and wallet.Equipped.Club=="club_wood","Starter club missing on migration")
	check(wallet.Coins==777 and wallet.Owned.trail_cyan and wallet.Equipped.Trail=="trail_cyan","Club migration lost cosmetics/balance")
	local count=0
	for _,item in catalog.Items do
		if item.Category~="Club" then continue end
		count+=1
		check(item.Power>=25 and item.Power<=55,"Unbounded knockback")
		check(item.Lift>=10 and item.Lift<=16,"Excessive vertical launch")
		check(item.Range>=6 and item.Range<=7.5,"Long-distance club")
		check(item.Cooldown>=0.85 and item.Cooldown<=2,"Club fire rate unreasonable")
		check(item.Windup>=0.1 and item.Windup+0.4<item.Cooldown,"Windup or recovery missing")
	end
	check(count==6,"Expected six club variants")
	check(catalog.ById.club_hammer.Power>catalog.ById.club_plasma.Power,"Paid club strictly dominates earned hammer")
	local status
	wallet,status=economy.apply(wallet,{Kind="buy",Id="club_steel",Price=0},catalog)
	check(status=="ok" and wallet.Coins==527 and wallet.Equipped.Club=="club_steel","Club purchase not server priced")
	wallet,status=economy.apply(wallet,{Kind="buy",Id="club_steel"},catalog)
	check(wallet.Coins==527,"Repeated club purchase charged twice")
	wallet,status=economy.apply(wallet,{Kind="buy",Id="club_plasma"},catalog)
	check(status=="requires_pass" and not wallet.Owned.club_plasma,"Paid club acquired for zero coins")
	wallet,status=economy.apply(wallet,{Kind="equip",Id="club_cosmic"},catalog)
	check(status=="requires_pass" and wallet.Equipped.Club=="club_steel","Unowned premium club equipped")
	wallet,status=economy.apply(wallet,{Kind="pass",Id="club_plasma",PassKey="club_plasma",Verified=false},catalog)
	check(status=="invalid" and not wallet.Owned.club_plasma,"Unverified pass granted item")
	wallet,status=economy.apply(wallet,{Kind="pass",Id="club_plasma",PassKey="club_cosmic",Verified=true},catalog)
	check(status=="invalid","Mismatched pass granted wrong item")
	wallet,status=economy.apply(wallet,{Kind="pass",Id="club_plasma",PassKey="club_plasma",Verified=true},catalog)
	check(status=="ok" and wallet.Owned.club_plasma and wallet.Supporter,"Verified pass grant missing")
	check(wallet.Coins==527,"Pass altered currency balance")
	wallet,status=economy.apply(wallet,{Kind="pass",Id="club_plasma",PassKey="club_plasma",Verified=true},catalog)
	check(status=="duplicate" and wallet.Coins==527,"Repeated pass callback changed balance")
	wallet,status=economy.apply(wallet,{Kind="equip",Id="club_plasma"},catalog)
	check(status=="ok" and wallet.Equipped.Club=="club_plasma","Purchased pass item cannot equip")
	local reloaded=economy.sanitize(wallet,catalog)
	check(reloaded.Owned.club_plasma and reloaded.Equipped.Club=="club_plasma","Reload lost club")
	check(rules.canSwing(10,9,true,true,false,false),"Valid swing refused")
	check(not rules.canSwing(10,11,true,true,false,false),"Cooldown bypassed")
	check(not rules.canSwing(10,9,false,true,false,false),"Unequipped club activated")
	check(not rules.canSwing(10,9,true,false,false,false),"Dead player attacks")
	check(not rules.canSwing(10,9,true,true,true,false),"Safe-zone attacker attacks outside")
	check(not rules.canSwing(10,9,true,true,false,true),"Staggered attacker swings")
	check(rules.canHit(5,1,0.8,6.5,true,false,false,true,false),"Valid hit refused")
	check(not rules.canHit(50,1,1,6.5,true,false,false,true,false),"Distant player hit")
	check(not rules.canHit(5,10,1,6.5,true,false,false,true,false),"Other floor hit")
	check(not rules.canHit(5,1,-1,6.5,true,false,false,true,false),"Player behind attacker hit")
	check(not rules.canHit(5,1,1,6.5,false,false,false,true,false),"Attack passes through wall")
	check(not rules.canHit(5,1,1,6.5,true,true,false,true,false),"Attack from checkpoint permitted")
	check(not rules.canHit(5,1,1,6.5,true,false,true,true,false),"Protected victim hit")
	check(not rules.canHit(5,1,1,6.5,true,false,false,false,false),"Dead victim hit")
	check(not rules.canHit(5,1,1,6.5,true,false,false,true,true),"Hit immunity bypassed")
	for stage=1,50 do
		check(rules.inBox(0,3,0,3.5,2.4,-1,7),"Checkpoint standing point not safe")
		check(not rules.inBox(0,10,0,3.5,2.4,-1,7),"Safe checkpoint extends vertically without limit")
	end
	check(rules.inBox(0,3.6,0,54,54,0.6,7.6),"Recovery floor not safe")
	check(not rules.inBox(0,15,0,54,54,0.6,7.6),"Floor protects next parkour stage")
	check(rules.SpawnShield>=4 and rules.HitImmunity>rules.Stagger,"Spawn or repeated-hit protection missing")
	local grants=0
	local pass={PassId=123,ItemId="club_cosmic",Key="club_cosmic"}
	local function grant(command)
		grants+=1
		local updated,result=economy.apply(wallet,command,catalog)
		wallet=updated
		return true,result
	end
	local verified=passes.process(pass,function() return false end,grant)
	check(not verified and grants==0,"Purchase event granted without platform ownership")
	verified=passes.process(pass,function() error("Marketplace unavailable") end,grant)
	check(not verified and grants==0,"Ownership lookup failure granted pass")
	verified=passes.process(pass,function() return true end,function() return false,"save_failed" end)
	check(not verified and not wallet.Owned.club_cosmic,"Pass grant acknowledged before durable write")
	verified=passes.process(pass,function() return true end,grant)
	check(verified and wallet.Owned.club_cosmic,"Verified platform pass missing")
	local balance=wallet.Coins
	verified=passes.process(pass,function() return true end,grant)
	check(verified and wallet.Coins==balance,"Repeated pass verification charged again")
	print("Combat PASS: six clubs, free migration, paid ownership, cooldown, cone, range, walls and safe-zone rules")
end
return Test
