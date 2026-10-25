--!strict
-- Independent of Shared, Remotes and GeneratedTower: visible even when one of
-- those fails to initialize. This script never grants progress or spawns players.
local Players=game:GetService("Players")
local player=Players.LocalPlayer
local gui=Instance.new("ScreenGui")
gui.Name="TowerStartupStatus"
gui.ResetOnSpawn=false
gui.DisplayOrder=100
gui.Parent=player:WaitForChild("PlayerGui")
local label=Instance.new("TextLabel")
label.AnchorPoint=Vector2.new(0.5,0.5)
label.Position=UDim2.fromScale(0.5,0.48)
label.Size=UDim2.fromScale(0.85,0.28)
label.BackgroundColor3=Color3.fromRGB(16,24,37)
label.BackgroundTransparency=0.06
label.TextColor3=Color3.fromRGB(175,235,255)
label.Font=Enum.Font.GothamBold
label.TextSize=20
label.TextScaled=true
label.TextWrapped=true
label.Parent=gui
local textLimit=Instance.new("UITextSizeConstraint")
textLimit.MinTextSize=12
textLimit.MaxTextSize=20
textLimit.Parent=label
local padding=Instance.new("UIPadding")
padding.PaddingTop=UDim.new(0,12)
padding.PaddingBottom=UDim.new(0,12)
padding.PaddingLeft=UDim.new(0,16)
padding.PaddingRight=UDim.new(0,16)
padding.Parent=label
local corner=Instance.new("UICorner")
corner.CornerRadius=UDim.new(0,12)
corner.Parent=label
local messages={
	starting="Запускаем башню…",modules="Загружаем модули игры…",
	generating="Строим 50 этапов и страховочные этажи…",services="Запускаем ловушки и чекпоинты…",
	ready="Загружаем прогресс и персонажа…",
}
local function update()
	local status=workspace:GetAttribute("TowerBootStatus")
	if status=="ready" and player:GetAttribute("DataLoaded") then
		gui.Enabled=false
		return
	end
	gui.Enabled=true
	if status=="failed" then
		local detail=tostring(workspace:GetAttribute("TowerBootError") or "Unknown error")
		detail=string.match(detail,"[^\n]+") or detail
		label.TextColor3=Color3.fromRGB(255,150,130)
		label.Text="Ошибка запуска игры\n"..string.sub(detail,1,220).."\nОткройте View → Output и скопируйте сообщение [Tower] STARTUP FAILED."
	else
		label.Text=messages[status] or "Подключаемся к серверу…"
	end
end
workspace:GetAttributeChangedSignal("TowerBootStatus"):Connect(update)
workspace:GetAttributeChangedSignal("TowerBootError"):Connect(update)
player:GetAttributeChangedSignal("DataLoaded"):Connect(update)
update()
task.delay(20,function()
	if gui.Enabled and workspace:GetAttribute("TowerBootStatus")~="failed" then
		label.Text..="\nЕсли ожидание продолжается, откройте View → Output и проверьте сообщения сервера."
	end
end)
