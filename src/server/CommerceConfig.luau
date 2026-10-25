--!strict
-- Create Developer Products in this experience, then replace ONLY ProductId.
-- Zero intentionally disables a product; it is never used as a purchase target.
-- Robux prices come from Roblox; do not hardcode them in the UI.
return table.freeze({
	DataStoreName="MechanicalTower_Economy_v1",
	Products={
		{Key="coins_small",Name="250 монет",Coins=250,ProductId=0},
		{Key="coins_medium",Name="1000 монет",Coins=1000,ProductId=0},
		{Key="coins_large",Name="3000 монет",Coins=3000,ProductId=0},
	},
})
