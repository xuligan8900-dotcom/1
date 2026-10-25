--!strict
-- Cosmetic only: no item changes movement, collisions, health or checkpoints.
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
}
local byId={}
for _,item in items do byId[item.Id]=table.freeze(item) end
return table.freeze({Items=items,ById=byId,Defaults={Trail="trail_none",Victory="fx_default",Title="title_rookie"}})
