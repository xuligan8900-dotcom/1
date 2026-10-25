--!strict
local Players=game:GetService("Players")
local ReplicatedStorage=game:GetService("ReplicatedStorage")
local Catalog=require(ReplicatedStorage:WaitForChild("Shared").CosmeticCatalog)
local remotes=ReplicatedStorage:WaitForChild("Remotes")
local player=Players.LocalPlayer
local gui=Instance.new("ScreenGui")
gui.Name="CosmeticShop"
gui.ResetOnSpawn=false
gui.DisplayOrder=10
gui.Parent=player:WaitForChild("PlayerGui")
local function rounded(object)
	local corner=Instance.new("UICorner")
	corner.CornerRadius=UDim.new(0,10)
	corner.Parent=object
end
local function text(parent,value,position,size,fontSize)
	local label=Instance.new("TextLabel")
	label.BackgroundTransparency=1
	label.Text=value
	label.Position=position
	label.Size=size
	label.Font=Enum.Font.GothamBold
	label.TextColor3=Color3.fromRGB(235,242,255)
	label.TextSize=fontSize
	label.TextXAlignment=Enum.TextXAlignment.Left
	label.TextWrapped=true
	label.Parent=parent
	return label
end
local function button(parent,value,position,size)
	local b=Instance.new("TextButton")
	b.Text=value
	b.Position=position
	b.Size=size
	b.Font=Enum.Font.GothamBold
	b.TextSize=14
	b.TextColor3=Color3.fromRGB(15,24,36)
	b.BackgroundColor3=Color3.fromRGB(95,225,245)
	b.Parent=parent
	rounded(b)
	return b
end
local open=button(gui,"◉ 0\nМАГАЗИН",UDim2.new(1,-12,0,12),UDim2.fromOffset(130,60))
open.AnchorPoint=Vector2.new(1,0)
local openScale=Instance.new("UIScale")
openScale.Parent=open
local function resize()
	local camera=workspace.CurrentCamera
	if camera then openScale.Scale=math.clamp(camera.ViewportSize.X/600,0.75,1) end
end
local viewportConnection
local function bindCamera()
	if viewportConnection then viewportConnection:Disconnect() end
	if workspace.CurrentCamera then viewportConnection=workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(resize) end
	resize()
end
workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(bindCamera)
bindCamera()
local panel=Instance.new("Frame")
panel.AnchorPoint=Vector2.new(0.5,0.5)
panel.Position=UDim2.fromScale(0.5,0.52)
panel.Size=UDim2.fromScale(0.92,0.82)
panel.BackgroundColor3=Color3.fromRGB(17,24,38)
panel.Visible=false
panel.Parent=gui
rounded(panel)
local limit=Instance.new("UISizeConstraint")
limit.MaxSize=Vector2.new(720,600)
limit.Parent=panel
text(panel,"МАГАЗИН • КОСМЕТИКА",UDim2.fromOffset(14,8),UDim2.new(1,-60,0,26),18)
local close=button(panel,"×",UDim2.new(1,-43,0,8),UDim2.fromOffset(32,28))
close.Activated:Connect(function() panel.Visible=false end)
local balance=text(panel,"Загрузка монет…",UDim2.fromOffset(14,37),UDim2.new(1,-28,0,24),14)
local hint=text(panel,"Монеты: на маршруте, за этапы и первую победу",UDim2.fromOffset(14,62),UDim2.new(1,-28,0,20),11)
hint.TextColor3=Color3.fromRGB(155,175,195)
local tabs=Instance.new("Frame")
tabs.BackgroundTransparency=1
tabs.Position=UDim2.fromOffset(12,89)
tabs.Size=UDim2.new(1,-24,0,32)
tabs.Parent=panel
local scroll=Instance.new("ScrollingFrame")
scroll.BackgroundTransparency=1
scroll.BorderSizePixel=0
scroll.Position=UDim2.fromOffset(12,132)
scroll.Size=UDim2.new(1,-24,1,-144)
scroll.ScrollBarThickness=5
scroll.AutomaticCanvasSize=Enum.AutomaticSize.Y
scroll.CanvasSize=UDim2.new()
scroll.Parent=panel
local layout=Instance.new("UIListLayout")
layout.Padding=UDim.new(0,8)
layout.SortOrder=Enum.SortOrder.LayoutOrder
layout.Parent=scroll
local notice=text(gui,"",UDim2.fromScale(0.5,0.83),UDim2.fromScale(0.88,0.1),17)
notice.AnchorPoint=Vector2.new(0.5,0)
notice.TextXAlignment=Enum.TextXAlignment.Center
notice.TextStrokeTransparency=0.25
notice.Visible=false
local state=nil
local category="Trail"
local tabButtons={}
local function card(name,description,color,actionText,enabled,callback)
	local row=Instance.new("Frame")
	row.Name="Card"
	row.Size=UDim2.new(1,-8,0,84)
	row.BackgroundColor3=Color3.fromRGB(31,42,59)
	row.Parent=scroll
	row.LayoutOrder=#scroll:GetChildren()
	rounded(row)
	local nameLabel=text(row,name,UDim2.fromOffset(12,8),UDim2.new(1,-147,0,28),16)
	nameLabel.TextColor3=color
	text(row,description,UDim2.fromOffset(12,38),UDim2.new(1,-147,0,36),11)
	local b=button(row,actionText,UDim2.new(1,-130,0.5,-20),UDim2.fromOffset(118,40))
	b.TextWrapped=true
	b.Active=enabled
	b.AutoButtonColor=enabled
	if not enabled then b.BackgroundColor3=Color3.fromRGB(99,114,134) end
	if enabled then b.Activated:Connect(callback) end
end
local function render()
	for _,child in scroll:GetChildren() do if child:IsA("Frame") then child:Destroy() end end
	for id,b in tabButtons do b.BackgroundColor3=if id==category then Color3.fromRGB(95,225,245) else Color3.fromRGB(135,155,175) end
	if not state or not state.Ready then balance.Text="Загрузка монет…"; return end
	open.Text="◉ "..state.Coins.."\nМАГАЗИН"
	balance.Text="◉ "..state.Coins..(if state.Persistent then " монет" else " монет · Studio: только эта сессия")
	if category=="Donate" then
		hint.Text="Поддержка добровольная. Монеты покупают только косметику."
		for _,product in state.Products do
			card(product.Name,"Набор монет + титул поддержки. Стоимость подтвердит Roblox.",Color3.fromRGB(255,210,80),
				if product.Enabled then "Купить за Robux" else "Скоро",product.Enabled,function() remotes.ShopRequest:FireServer("donate",product.Key) end)
		end
	else
		hint.Text="Без бонусов к скорости, прыжку и прохождению"
		for _,item in Catalog.Items do
			if item.Category~=category then continue end
			local owned=state.Owned[item.Id]
			local equipped=state.Equipped[category]==item.Id
			local locked=(item.RequiredWin and not state.WinRewarded) or (item.RequiredSupport and not state.Supporter)
			local description=if item.RequiredWin then "За первую победу на 50-м этапе"
				elseif item.RequiredSupport then "В подарок за любой набор поддержки"
				elseif owned then "Есть в вашей коллекции" else "Постоянный косметический предмет"
			local action=if equipped then "Выбрано" elseif locked then "Закрыто" elseif owned then "Надеть" else "◉ "..item.Price
			card(item.Name,description,Color3.fromRGB(item.Color[1],item.Color[2],item.Color[3]),action,not equipped and not locked,function()
				remotes.ShopRequest:FireServer(if owned then "equip" else "buy",item.Id)
			end)
		end
	end
end
for i,entry in {{"Trail","Следы"},{"Victory","Победа"},{"Title","Титулы"},{"Donate","Донат"}} do
	local b=button(tabs,entry[2],UDim2.new((i-1)/4,3,0,0),UDim2.new(0.25,-6,1,0))
	tabButtons[entry[1]]=b
	b.Activated:Connect(function() category=entry[1]; render() end)
end
local function accept(value)
	if not value.Ready then return end
	if state and value.Revision<state.Revision then return end
	state=value
	render()
end
local function refresh()
	task.spawn(function()
		local ok,value=pcall(function() return remotes.ShopGetState:InvokeServer() end)
		if ok then accept(value) end
	end)
end
open.Activated:Connect(function() panel.Visible=not panel.Visible; if panel.Visible then refresh() end end)
remotes.ShopStateChanged.OnClientEvent:Connect(accept)
player:GetAttributeChangedSignal("Coins"):Connect(function() open.Text="◉ "..(player:GetAttribute("Coins") or 0).."\nМАГАЗИН" end)
player:GetAttributeChangedSignal("DataLoaded"):Connect(refresh)
local noticeVersion=0
remotes.ShopNotice.OnClientEvent:Connect(function(message)
	noticeVersion+=1
	local version=noticeVersion
	notice.Text=message
	notice.Visible=true
	task.delay(3,function() if version==noticeVersion then notice.Visible=false end end)
end)
refresh()
render()
