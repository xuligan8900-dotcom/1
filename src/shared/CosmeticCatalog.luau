--!strict
-- Shared shop catalog. Cosmetic items and server-authoritative PvP clubs are separate categories.
local items={
	{Id="trail_none",Category="Trail",Name="Без следа",Price=0,Color={150,160,175}},
	{Id="trail_cyan",Category="Trail",Name="Ионный след",Price=150,Color={65,220,255}},
	{Id="trail_amber",Category="Trail",Name="След кузницы",Price=350,Color={255,175,45}},
	{Id="trail_prism",Category="Trail",Name="Призма",Price=750,Color={210,100,255},SecondColor={70,240,230}},
	{Id="fx_default",Category="Victory",Name="Конфетти",Price=0,Color={70,220,255}},
	{Id="fx_gold",Category="Victory",Name="Золотой салют",Price=400,Color={255,205,60}},
	{Id="fx_prism",Category="Victory",Name="Неоновая вспышка",Price=800,Color={205,95,255},SecondColor={60,240,230}},
	{Id="title_rookie",Category="Title",Name="Новичок",Price=0,Color={170,190,215}},
	{Id="title_runner",Category="Title",Name="Паркурщик",Price=200,Color={70,230,180}},
	{Id="title_engineer",Category="Title",Name="Инженер башни",Price=600,Color={255,180,70}},
	{Id="title_master",Category="Title",Name="Покоритель башни",Price=0,RequiredWin=true,Color={150,245,255}},
	{Id="title_supporter",Category="Title",Name="Поддержка проекта",Price=0,RequiredSupport=true,Color={255,150,220}},
	{Id="club_wood",Category="Club",Name="Деревянная дубинка",Price=0,Color={160,110,65},Style="wood",Power=32,Lift=12,Range=6.5,Cooldown=1.2,Windup=0.16},
	{Id="club_steel",Category="Club",Name="Стальная дубинка",Price=250,Color={155,175,195},Style="steel",Power=40,Lift=13,Range=6.8,Cooldown=1.35,Windup=0.18},
	{Id="club_baton",Category="Club",Name="Неоновая дубинка",Price=600,Color={60,235,210},Style="neon",Power=32,Lift=12,Range=6.4,Cooldown=0.9,Windup=0.12},
	{Id="club_hammer",Category="Club",Name="Механический молот",Price=1000,Color={255,170,55},Style="hammer",Power=52,Lift=15,Range=6.3,Cooldown=1.8,Windup=0.28},
	{Id="club_plasma",Category="Club",Name="Плазменная дубинка",Price=0,RequiredPass="club_plasma",Color={210,85,255},Style="plasma",Power=43,Lift=13,Range=6.8,Cooldown=1.3,Windup=0.18},
	{Id="club_cosmic",Category="Club",Name="Космическая дубинка",Price=0,RequiredPass="club_cosmic",Color={80,170,255},Style="cosmic",Power=37,Lift=15,Range=7.2,Cooldown=1.25,Windup=0.18},
}
local byId={}
for _,item in items do byId[item.Id]=table.freeze(item) end
return table.freeze({Items=items,ById=byId,Defaults={Trail="trail_none",Victory="fx_default",Title="title_rookie",Club="club_wood"}})
