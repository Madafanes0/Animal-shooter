-- Kill a Beast: cliente (HUD, paneles y la cámara que sigue el disparo)
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local HttpService = game:GetService("HttpService")
local UserInputService = game:GetService("UserInputService")
local MarketplaceService = game:GetService("MarketplaceService")
local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local Models = require(ReplicatedStorage.Shared.Models)
local fmt = require(ReplicatedStorage.Shared.Format)
local Remotes = ReplicatedStorage:WaitForChild("Remotes")

local player = Players.LocalPlayer
local camera = workspace.CurrentCamera

local state: any = nil
local shooting = false

---------------------------------------------------------------- UI base (estilo Roll a Chef)

local Theme = require(script.Parent.UI.Theme)
local Kit = require(script.Parent.UI.Kit)
local Preview = require(script.Parent.UI.Preview)
local C = Theme.Colors

local gui = Theme.screen("KillABeastUI")

-- Texto con la fuente y el borde del estilo (lo usan también los efectos del disparo)
local function text(parent: Instance, props: { [string]: any }): TextLabel
	local t = Theme.new("TextLabel", { TextScaled = true, TextWrapped = true })
	Theme.textStroke(t, props.StrokeThickness or 3)
	props.StrokeThickness = nil
	for k, v in props do
		(t :: any)[k] = v
	end
	t.Parent = parent
	return t
end

local function action(kind: string, arg: any?)
	Remotes.Action:FireServer(kind, arg)
end

local currentPanel: string? = nil
local renderPanel: () -> ()
local function toggle(name: string)
	currentPanel = if currentPanel == name then nil else name
	renderPanel()
end

-- Casillas del lado izquierdo (2 × 2), como en Roll a Chef
local side = Theme.new("Frame", { Name = "Side", Size = UDim2.fromOffset(186, 186), AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 10, 0.5, 0), Parent = gui })
Theme.new("UIGridLayout", { CellSize = UDim2.fromOffset(88, 88), CellPadding = UDim2.fromOffset(10, 10), SortOrder = Enum.SortOrder.LayoutOrder, Parent = side })
for i, t in { { "Shop", "Lime", "store", "🛒" }, { "Stable", "Orange", "platform", "🐾" }, { "Index", "Blue", "book", "📖" }, { "Robux", "Gold", "robux", "⬢" } } do
	local tile = Kit.tile(t[1], t[2], t[3], t[4], 88, side, function()
		toggle(t[1])
	end)
	tile.LayoutOrder = i
end

-- Dinero y poder abajo a la izquierda
local stats = Theme.new("Frame", { Name = "Stats", Size = UDim2.fromOffset(340, 96), AnchorPoint = Vector2.new(0, 1), Position = UDim2.new(0, 12, 1, -8), Parent = gui })
local powerLabel = Kit.label({ Text = "Power 0", TextSize = 24, Size = UDim2.fromOffset(340, 30), XAlign = Enum.TextXAlignment.Left, Wrapped = false, Gradient = ColorSequence.new(Color3.fromRGB(150, 230, 255), Color3.fromRGB(60, 160, 255)), Parent = stats })
local moneyLabel = Kit.label({ Text = "$0", TextSize = 48, Size = UDim2.fromOffset(340, 56), Position = UDim2.fromOffset(0, 34), XAlign = Enum.TextXAlignment.Left, Wrapped = false, Stroke = 3.5, Gradient = ColorSequence.new(C.MoneyTop, C.Money), Parent = stats })

-- Ingreso arriba al centro, pista debajo, arma y suerte arriba a la derecha
local incomeLabel = Kit.label({ Text = "+$0/s", TextSize = 46, Size = UDim2.fromOffset(420, 52), AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 4), Wrapped = false, Stroke = 3.5, Gradient = ColorSequence.new(C.MoneyTop, C.Money), Parent = gui })
local hint = Kit.label({ Text = "", TextSize = 24, Size = UDim2.fromOffset(640, 30), AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 58), Scaled = true, Parent = gui })
local info = Kit.label({ Text = "", TextSize = 22, Size = UDim2.fromOffset(320, 56), AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -10, 0, 6), XAlign = Enum.TextXAlignment.Right, Scaled = true, Parent = gui })

local shootBtn = Kit.button({ Name = "Shoot", Text = "SHOOT!", Color = "Red", Size = UDim2.fromOffset(230, 76), AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.new(0.5, 0, 1, -112), TextSize = 40, Parent = gui })
shootBtn.Visible = false
Kit.button({ Name = "Home", Text = "Base", Color = "Blue", Size = UDim2.fromOffset(120, 56), AnchorPoint = Vector2.new(1, 1), Position = UDim2.new(1, -12, 1, -12), TextSize = 28, Parent = gui, OnClick = function()
	action("Home")
end })

-- Avisos flotantes
local function toast(msg: string, color: Color3?)
	local t = Kit.label({ Text = msg, TextSize = 30, Size = UDim2.fromOffset(620, 40), AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.3), Color = color or C.White, Scaled = true, ZIndex = 20, Parent = gui })
	local stroke = t:FindFirstChildOfClass("UIStroke")
	Theme.tween(t, TweenInfo.new(1.6), { Position = UDim2.fromScale(0.5, 0.2), TextTransparency = 1 })
	if stroke then
		Theme.tween(stroke, TweenInfo.new(1.6), { Transparency = 1 })
	end
	task.delay(1.7, t.Destroy, t)
end

Remotes.Notify.OnClientEvent:Connect(function(msg, color)
	toast(msg, color)
end)

---------------------------------------------------------------- Ventanas

local WINDOWS = {
	Shop = { Title = "Weapon Shop", Icon = "store", Fallback = "🛒", Color = "Lime" },
	Stable = { Title = "Stable", Icon = "platform", Fallback = "🐾", Color = "Orange" },
	Index = { Title = "Index", Icon = "book", Fallback = "📖", Color = "Blue" },
	Robux = { Title = "Robux Shop", Icon = "robux", Fallback = "⬢", Color = "Gold" },
}
local HEADER = 62

local panel = Theme.new("Frame", { Name = "Window", Size = UDim2.fromOffset(740, 480), AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.52), BackgroundColor3 = C.Panel, BackgroundTransparency = 0.18, Visible = false, ZIndex = 5, Parent = gui })
Theme.corner(panel, 6)
Theme.stroke(panel, 3.5, C.Outline)
Theme.new("TextButton", { Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Selectable = false, Text = "", ZIndex = 5, Parent = panel })
local windowHeader = Theme.new("Frame", { Name = "Header", Size = UDim2.new(1, 0, 0, HEADER), ZIndex = 6, Parent = panel })
local headerIcon: GuiObject? = nil
local panelTitle = Kit.label({ Name = "Title", TextSize = 40, Size = UDim2.new(1, -230, 1, -6), Position = UDim2.fromOffset(74, 3), XAlign = Enum.TextXAlignment.Left, Scaled = true, ZIndex = 8, Stroke = 3.5, Parent = windowHeader })
local closeBtn = Kit.button({ Name = "Close", Text = "X", Color = "Red", Size = UDim2.fromOffset(54, 50), AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -8, 0.5, 0), TextSize = 34, ZIndex = 8, Parent = windowHeader, OnClick = function()
	currentPanel = nil
	renderPanel()
end })
local headerButtons = Theme.new("Frame", { Name = "HeaderButtons", Size = UDim2.new(0, 420, 1, -12), AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -72, 0.5, 0), ZIndex = 8, Parent = windowHeader })
Theme.list(headerButtons, 8, true, Enum.HorizontalAlignment.Right)
local scroll = Kit.scroll({ Position = UDim2.fromOffset(12, HEADER + 12), Size = UDim2.new(1, -24, 1, -HEADER - 22), ZIndex = 6, Parent = panel })
local grid = Theme.new("UIGridLayout", { CellPadding = UDim2.fromOffset(10, 14), SortOrder = Enum.SortOrder.LayoutOrder, Parent = scroll })
Theme.padding(scroll, 10, 6)

local currentHeaderColor = ""
local function setWindow(name: string)
	local def = WINDOWS[name]
	if currentHeaderColor ~= def.Color then
		for _, c in windowHeader:GetChildren() do
			if c.Name == "FaceGradient" or c.Name == "FaceInner" or c.Name == "Outline" or c:IsA("UICorner") then
				c:Destroy()
			end
		end
		Kit.face(windowHeader, def.Color, { Stroke = 3, Radius = 5 })
		currentHeaderColor = def.Color
	end
	if headerIcon then
		headerIcon:Destroy()
	end
	headerIcon = Kit.icon(def.Icon, def.Fallback, { Size = UDim2.fromOffset(88, 88), Position = UDim2.fromOffset(-22, -22), Rotation = -8, ZIndex = 9, Parent = windowHeader })
	panelTitle.Text = def.Title
end

local function clearPanel()
	for _, c in scroll:GetChildren() do
		if c:IsA("GuiObject") or c.Name == "IndexList" then
			c:Destroy()
		end
	end
	grid.Parent = scroll
	headerButtons:ClearAllChildren()
	Theme.list(headerButtons, 8, true, Enum.HorizontalAlignment.Right)
end

local function headerButton(textValue: string, color: string, order: number, onClick: () -> ())
	Kit.button({ Text = textValue, Color = color, Size = UDim2.fromOffset(200, 46), TextSize = 22, LayoutOrder = order, ZIndex = 8, Parent = headerButtons, OnClick = onClick })
end

-- Tarjeta oscura con borde de color y textos (nombre, detalle, extra) + botón opcional
local function itemCard(order: number, accent: Color3, title: string, titleColor: Color3?, line1: string, line2: string?, line2Color: Color3?): Frame
	local card = Kit.card({ Size = UDim2.fromOffset(100, 100), LayoutOrder = order, Parent = scroll })
	card.ZIndex = 6
	local accentBar = Theme.new("Frame", { Size = UDim2.new(0, 6, 1, -12), Position = UDim2.fromOffset(6, 6), BackgroundColor3 = accent, BackgroundTransparency = 0, ZIndex = 7, Parent = card })
	Theme.corner(accentBar, 3)
	Kit.label({ Text = title, TextSize = 24, Size = UDim2.new(1, -24, 0, 28), Position = UDim2.fromOffset(18, 6), XAlign = Enum.TextXAlignment.Left, Scaled = true, Color = titleColor or C.White, ZIndex = 7, Parent = card })
	Kit.label({ Text = line1, TextSize = 18, Size = UDim2.new(1, -24, 0, 22), Position = UDim2.fromOffset(18, 36), XAlign = Enum.TextXAlignment.Left, Scaled = true, Font = Theme.FontBold, Color = C.TextDim, ZIndex = 7, Parent = card })
	if line2 then
		Kit.label({ Text = line2, TextSize = 20, Size = UDim2.new(1, -24, 0, 22), Position = UDim2.fromOffset(18, 58), XAlign = Enum.TextXAlignment.Left, Scaled = true, Color = line2Color or C.Money, ZIndex = 7, Parent = card })
	end
	return card
end

local function cardButton(card: Frame, label: string, color: string, size: UDim2, pos: UDim2, onClick: () -> ())
	Kit.button({ Text = label, Color = color, Size = size, Position = pos, TextSize = 22, ZIndex = 8, Parent = card, OnClick = onClick })
end

local function renderShop()
	grid.CellSize = UDim2.new(0.5, -6, 0, 96)
	for i, w in Config.Weapons do
		if w.exclusive and not state.owned[tostring(i)] then
			continue
		end
		local owned = state.owned[tostring(i)]
		local card = itemCard(i, w.color, i .. ". " .. w.name, nil, "Reach: Epoch " .. Config.epochAt(w.range) .. (if w.luck then " · " .. w.luck .. "x luck" else ""))
		local label, color
		if state.equipped == i then
			label, color = "Equipped", "Gray"
		elseif owned then
			label, color = "Equip", "Blue"
		else
			label, color = "$" .. fmt(w.price), if state.money >= w.price then "Lime" else "Dark"
		end
		cardButton(card, label, color, UDim2.fromOffset(120, 50), UDim2.new(1, -130, 1, -58), function()
			action("BuyWeapon", i)
		end)
	end
end

local function renderStable()
	local cap = Config.stableCapacity(state.stableLevel)
	panelTitle.Text = string.format("Stable  %d/%d", #state.animals, cap)
	local maxedS = state.stableLevel >= Config.STABLE_MAX_LEVEL
	local maxedT = state.trainerLevel >= Config.TRAINER_MAX_LEVEL
	headerButton(if maxedS then "Slots MAX" else "+5 Slots $" .. fmt(Config.stableUpgradeCost(state.stableLevel)), "Lime", 1, function()
		action("UpgradeStable")
	end)
	headerButton(if maxedT then "Trainer MAX" else "Trainer $" .. fmt(Config.trainerUpgradeCost(state.trainerLevel)), "Orange", 2, function()
		action("UpgradeTrainer")
	end)

	grid.CellSize = UDim2.new(0.333, -7, 0, 124)
	local function animalCard(order: number, entry: number, inHand: boolean)
		local a, v = Config.decode(entry)
		local rar = Config.Rarities[a.rarity]
		local vColor = if v > 0 then Config.Variants[v].color else nil
		local card = itemCard(order, vColor or rar.color, Config.entryName(entry), vColor, (if inHand then "IN HAND · " else "") .. rar.name, "$" .. fmt(Config.entryIncome(entry)) .. "/s")
		for _, l in card:GetChildren() do
			if l:IsA("TextLabel") and l.Name ~= "CardTitle" then
				l.Size = UDim2.new(1, -96, 0, l.Size.Y.Offset)
			end
		end
		Preview.animal(entry, UDim2.fromOffset(78, 78), card, false, 7).Position = UDim2.new(1, -84, 0, 4)
		if inHand then
			cardButton(card, "Sell $" .. fmt(Config.sellValue(entry)), "Red", UDim2.new(1, -24, 0, 34), UDim2.new(0, 12, 1, -40), function()
				action("SellHeld", order)
			end)
		else
			cardButton(card, "Sell", "Red", UDim2.new(0.5, -16, 0, 34), UDim2.new(0, 12, 1, -40), function()
				action("Sell", order - 1000)
			end)
			cardButton(card, "Pick up", "Blue", UDim2.new(0.5, -16, 0, 34), UDim2.new(0.5, 4, 1, -40), function()
				action("PickUp", order - 1000)
			end)
		end
	end
	-- Primero los que traes en la mano, luego los colocados
	for slot, entry in state.held do
		animalCard(slot, entry, true)
	end
	for slot, entry in state.animals do
		animalCard(1000 + slot, entry, false)
	end
end

-- Index por mundos: cada época con sus 5 animales (vista 3D o silueta) y su recompensa al completarla
local function renderIndex()
	local found = 0
	for _ in state.discovered do
		found += 1
	end
	panelTitle.Text = string.format("Index  %d/%d", found, #Config.AnimalOrder)
	grid.Parent = nil
	local list = Theme.list(scroll, 16)
	list.Name = "IndexList"
	for e, epoch in Config.Epochs do
		local count = 0
		for _, a in epoch.animals do
			if state.discovered[tostring(a.id)] then
				count += 1
			end
		end
		local section = Kit.card({ Size = UDim2.new(1, -8, 0, 200), LayoutOrder = e, Parent = scroll })
		section.ZIndex = 6
		local outline = section:FindFirstChildOfClass("UIStroke")
		if outline then
			outline.Color = epoch.ground
			outline.Thickness = 2.5
		end
		local band = Theme.new("Frame", { Size = UDim2.new(1, 0, 0, 44), BackgroundColor3 = epoch.ground, BackgroundTransparency = 0.25, ZIndex = 6, Parent = section })
		Theme.corner(band, 4)
		Kit.label({ Text = string.format("World %d · %s", e, epoch.name), TextSize = 26, Size = UDim2.new(0.55, 0, 1, -6), Position = UDim2.fromOffset(12, 3), XAlign = Enum.TextXAlignment.Left, Scaled = true, ZIndex = 7, Parent = band })
		Kit.label({ Text = count .. "/5", TextSize = 24, Size = UDim2.fromOffset(70, 34), Position = UDim2.new(0.55, 0, 0, 5), Scaled = true, Color = if count == 5 then C.Money else C.White, ZIndex = 7, Parent = band })
		local reward = Config.worldReward(e)
		local claimed = state.claimedWorlds and state.claimedWorlds[tostring(e)]
		local rewardText = if claimed then "Claimed" else "$" .. fmt(reward.money) .. " + " .. reward.power .. " Power"
		Kit.button({ Text = rewardText, Color = if claimed then "Gray" elseif count == 5 then "Gold" else "Dark", Size = UDim2.fromOffset(230, 36), AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -8, 0.5, 0), TextSize = 20, ZIndex = 8, Parent = band, OnClick = function()
			if not claimed then
				action("ClaimWorld", e)
			end
		end })
		local row = Theme.new("Frame", { Size = UDim2.new(1, -16, 0, 144), Position = UDim2.fromOffset(8, 50), ZIndex = 6, Parent = section })
		Theme.new("UIGridLayout", { CellSize = UDim2.new(0.2, -8, 1, 0), CellPadding = UDim2.fromOffset(10, 0), SortOrder = Enum.SortOrder.LayoutOrder, Parent = row })
		for r, a in epoch.animals do
			local rar = Config.Rarities[a.rarity]
			local known = state.discovered[tostring(a.id)]
			local cell = Theme.new("Frame", { LayoutOrder = r, BackgroundColor3 = C.Card, BackgroundTransparency = 0.3, ZIndex = 6, Parent = row })
			Theme.corner(cell, 6)
			Theme.stroke(cell, 2, rar.color)
			Preview.animal(a.id, UDim2.new(1, -8, 1, -46), cell, not known, 7).Position = UDim2.fromOffset(4, 2)
			Kit.label({ Text = if known then a.name else "???", TextSize = 18, Size = UDim2.new(1, -8, 0, 22), Position = UDim2.new(0, 4, 1, -44), Scaled = true, ZIndex = 8, Parent = cell })
			Kit.label({ Text = rar.name, TextSize = 15, Size = UDim2.new(1, -8, 0, 18), Position = UDim2.new(0, 4, 1, -22), Scaled = true, Color = rar.color, ZIndex = 8, Parent = cell })
		end
	end
end

local function renderRobux()
	grid.CellSize = UDim2.new(0.5, -6, 0, 108)
	local function item(order: number, it, isPass: boolean)
		local owned = isPass and state.passes[it.key]
		local card = itemCard(order, it.color, it.name, it.color, it.desc)
		if owned then
			cardButton(card, "Owned", "Gray", UDim2.fromOffset(130, 50), UDim2.new(1, -140, 1, -58), function() end)
			return
		end
		Kit.priceButton("Robux", it.price, { Size = UDim2.fromOffset(130, 50), Position = UDim2.new(1, -140, 1, -58), TextSize = 24, ZIndex = 8, Parent = card, OnClick = function()
			if it.id == 0 then
				action("TestBuy", it.key) -- sin ID: gratis en Studio
			elseif isPass then
				MarketplaceService:PromptGamePassPurchase(player, it.id)
			else
				MarketplaceService:PromptProductPurchase(player, it.id)
			end
		end })
	end
	for n, it in Config.Passes do
		item(n, it, true)
	end
	for n, it in Config.Products do
		item(100 + n, it, false)
	end
end

renderPanel = function()
	if not currentPanel or not state then
		panel.Visible = false
		return
	end
	local wasOpen = panel.Visible
	clearPanel()
	setWindow(currentPanel)
	panel.Visible = true
	if not wasOpen then
		local scale = panel:FindFirstChild("PopScale") or Theme.new("UIScale", { Name = "PopScale", Parent = panel })
		scale.Scale = 0.85
		Theme.tween(scale, Theme.Pop, { Scale = 1 })
	end
	if currentPanel == "Shop" then
		renderShop()
	elseif currentPanel == "Stable" then
		renderStable()
	elseif currentPanel == "Robux" then
		renderRobux()
	else
		renderIndex()
	end
end


---------------------------------------------------------------- Estado

local lastPanelKey = ""
local lastPower: number? = nil

-- "+N" que sube junto al poder mientras entrenas
local function powerPop(gain: number)
	local t = text(stats, { Size = UDim2.fromOffset(120, 28), Position = UDim2.new(0, 150, 0, -6), Text = "+" .. fmt(gain), TextColor3 = Color3.fromRGB(255, 220, 80), ZIndex = 5 })
	TweenService:Create(t, TweenInfo.new(0.8), { Position = UDim2.new(0, 150, 0, -40), TextTransparency = 1, TextStrokeTransparency = 1 }):Play()
	task.delay(0.85, t.Destroy, t)
end

-- Entrenando: una piedrita vuela de tu personaje a una de las dianas
local function trainShot()
	local plots = workspace:FindFirstChild("Plots")
	local plot = plots and plots:FindFirstChild("Plot" .. tostring(player:GetAttribute("Plot")))
	local targets = plot and plot:FindFirstChild("Targets")
	local char = player.Character
	local hrp = char and char:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not targets or not hrp then
		return
	end
	local list = targets:GetChildren()
	local target = list[math.random(1, #list)] :: BasePart
	local from = hrp.Position + Vector3.new(0, 1.5, 0)
	local to = target.Position + Vector3.new(0, math.random() - 0.5, math.random() - 0.5)
	hrp.CFrame = CFrame.lookAt(hrp.Position, Vector3.new(to.X, hrp.Position.Y, to.Z))
	local rock = Instance.new("Part")
	rock.Shape = Enum.PartType.Ball
	rock.Size = Vector3.new(0.5, 0.5, 0.5)
	rock.Color = Color3.fromRGB(140, 140, 140)
	rock.Material = Enum.Material.Slate
	rock.Anchored = true
	rock.CanCollide = false
	rock.CanQuery = false
	rock.Position = from
	rock.Parent = workspace
	local tween = TweenService:Create(rock, TweenInfo.new(0.22, Enum.EasingStyle.Linear), { Position = to })
	tween:Play()
	tween.Completed:Connect(function()
		rock.Size = Vector3.new(1.4, 1.4, 1.4)
		rock.Material = Enum.Material.Neon
		rock.Color = Color3.fromRGB(255, 220, 80)
		TweenService:Create(rock, TweenInfo.new(0.2), { Size = Vector3.new(2.5, 2.5, 2.5), Transparency = 1 }):Play()
		task.delay(0.25, rock.Destroy, rock)
	end)
end

local function onState()
	local raw = player:GetAttribute("State")
	if not raw then
		return
	end
	state = HttpService:JSONDecode(raw)
	if lastPower and state.power > lastPower then
		powerPop(state.power - lastPower)
		if player:GetAttribute("Training") then
			trainShot()
		end
	end
	lastPower = state.power
	moneyLabel.Text = "$" .. fmt(state.money)
	incomeLabel.Text = "+$" .. fmt(state.income) .. "/s"
	powerLabel.Text = "Power " .. fmt(state.power) .. "  (+" .. Config.trainerGain(state.trainerLevel) .. "/train)"
	local w = Config.Weapons[state.equipped]
	local reach = Config.shotDistance(state.equipped, state.power)
	local luckText = if state.luck > 1 then " · Luck x" .. state.luck else ""
	if state.luckLeft > 0 then
		luckText ..= string.format(" (%d:%02d)", state.luckLeft // 60, state.luckLeft % 60)
	end
	info.Text = w.name .. luckText .. "\nReach: Epoch " .. Config.epochAt(reach) .. " · Stable " .. #state.animals .. "/" .. Config.stableCapacity(state.stableLevel)
	-- El dinero sube cada segundo; sólo redibuja el panel si cambió algo más
	local key = HttpService:JSONEncode({ state.owned, state.equipped, state.animals, state.held, state.passes, state.claimedWorlds, state.stableLevel, state.trainerLevel, state.discovered, currentPanel == "Shop" and math.floor(state.money) or 0 })
	if key ~= lastPanelKey then
		lastPanelKey = key
		renderPanel()
	end
end
player:GetAttributeChangedSignal("State"):Connect(onState)
onState()

---------------------------------------------------------------- Disparo

local function root(): BasePart?
	local c = player.Character
	return c and c:FindFirstChild("HumanoidRootPart") :: BasePart?
end

local function inShootZone(): boolean
	local r = root()
	if not r then
		return false
	end
	local p = r.Position
	return math.abs(p.X) <= Config.FIELD_WIDTH / 2 and p.Z > -16 and p.Z < 16
end

local function banner(a, rar, variant: number)
	local f = Instance.new("Frame")
	f.Size = UDim2.new(0.7, 0, 0, 110)
	f.Position = UDim2.new(0.15, 0, 0.12, 0)
	f.BackgroundTransparency = 1
	f.ZIndex = 30
	f.Parent = gui
	local entry = Config.entry(a.id, variant)
	local top = if variant > 0 then Config.Variants[variant].name:upper() .. " · " .. rar.name:upper() else rar.name:upper()
	text(f, { Size = UDim2.new(1, 0, 0.35, 0), Text = top, TextColor3 = if variant > 0 then Config.Variants[variant].color else rar.color, ZIndex = 30 })
	text(f, { Size = UDim2.new(1, 0, 0.4, 0), Position = UDim2.fromScale(0, 0.35), Text = "You hunted a " .. Config.entryName(entry) .. "!", ZIndex = 30 })
	text(f, { Size = UDim2.new(1, 0, 0.25, 0), Position = UDim2.fromScale(0, 0.75), Text = "+$" .. fmt(Config.entryIncome(entry)) .. "/s", TextColor3 = Color3.fromRGB(90, 255, 90), ZIndex = 30 })
	local scale = Instance.new("UIScale")
	scale.Scale = 0.2
	scale.Parent = f
	TweenService:Create(scale, TweenInfo.new(0.35, Enum.EasingStyle.Back), { Scale = 1 }):Play()
	task.delay(2.4, f.Destroy, f)
end

---------------------------------------------------------------- Efectos anime

-- Barras de cine, líneas de velocidad y flash de impacto
local fx = Instance.new("ScreenGui")
fx.Name = "AnimeFX"
fx.IgnoreGuiInset = true
fx.ResetOnSpawn = false
fx.DisplayOrder = 10
fx.Parent = player.PlayerGui

local function bar(top: boolean): Frame
	local f = Instance.new("Frame")
	f.BackgroundColor3 = Color3.new(0, 0, 0)
	f.BorderSizePixel = 0
	f.Size = UDim2.new(1, 0, 0.13, 0)
	f.AnchorPoint = Vector2.new(0, if top then 1 else 0)
	f.Position = UDim2.fromScale(0, if top then 0 else 1)
	f.Parent = fx
	return f
end
local topBar, bottomBar = bar(true), bar(false)

local function cinematic(on: boolean)
	local info = TweenInfo.new(0.25, Enum.EasingStyle.Quad)
	TweenService:Create(topBar, info, { AnchorPoint = Vector2.new(0, if on then 0 else 1) }):Play()
	TweenService:Create(bottomBar, info, { AnchorPoint = Vector2.new(0, if on then 1 else 0) }):Play()
end

local speedLines = Instance.new("Frame")
speedLines.BackgroundTransparency = 1
speedLines.Size = UDim2.fromScale(1, 1)
speedLines.Visible = false
speedLines.Parent = fx
local lines = {}
for i = 1, 36 do
	local l = Instance.new("Frame")
	l.BackgroundColor3 = Color3.new(1, 1, 1)
	l.BorderSizePixel = 0
	l.AnchorPoint = Vector2.new(0.5, 0.5)
	l.Parent = speedLines
	lines[i] = l
end

-- Recoloca las líneas radiales al azar (se llama cada frame para que parpadeen)
local function jitterLines(strength: number)
	for i, l in lines do
		local ang = (i / #lines) * math.pi * 2 + math.random() * 0.15
		local r = 0.32 + math.random() * 0.2
		l.Size = UDim2.new(0, math.random(2, 5), 0.18 + math.random() * 0.25 * strength, 0)
		l.Position = UDim2.fromScale(0.5 + math.cos(ang) * r, 0.5 + math.sin(ang) * r * 1.4)
		l.Rotation = math.deg(ang) + 90
		l.BackgroundTransparency = 0.15 + math.random() * 0.5
	end
end

local flash = Instance.new("Frame")
flash.Size = UDim2.fromScale(1, 1)
flash.BorderSizePixel = 0
flash.BackgroundTransparency = 1
flash.ZIndex = 50
flash.Parent = fx

-- Impact frame: blanco - negro - blanco y se desvanece
local function impactFrame()
	flash.BackgroundColor3 = Color3.new(1, 1, 1)
	flash.BackgroundTransparency = 0
	task.wait(0.05)
	flash.BackgroundColor3 = Color3.new(0, 0, 0)
	task.wait(0.05)
	flash.BackgroundColor3 = Color3.new(1, 1, 1)
	TweenService:Create(flash, TweenInfo.new(0.3), { BackgroundTransparency = 1 }):Play()
end

-- Texto gigante inclinado ("FIRE!!", "HIT!!")
local function shout(msg: string, color: Color3, rot: number)
	local t = text(fx, {
		Size = UDim2.fromScale(0.7, 0.22),
		Position = UDim2.fromScale(0.15, 0.3),
		Text = msg,
		TextColor3 = color,
		Rotation = rot,
		ZIndex = 40,
	})
	local st = Instance.new("UIStroke")
	st.Thickness = 5
	st.Parent = t
	local sc = Instance.new("UIScale")
	sc.Scale = 2.2
	sc.Parent = t
	TweenService:Create(sc, TweenInfo.new(0.18, Enum.EasingStyle.Back), { Scale = 1 }):Play()
	task.delay(0.55, function()
		TweenService:Create(t, TweenInfo.new(0.25), { TextTransparency = 1 }):Play()
		TweenService:Create(st, TweenInfo.new(0.25), { Transparency = 1 }):Play()
	end)
	task.delay(0.85, t.Destroy, t)
end

local function shake(cf: CFrame, amount: number): CFrame
	return cf * CFrame.new((math.random() - 0.5) * amount, (math.random() - 0.5) * amount, 0)
end

local function tweenCamera(to: CFrame, fov: number, time: number)
	TweenService:Create(camera, TweenInfo.new(time, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), { CFrame = to, FieldOfView = fov }):Play()
	task.wait(time)
end

---------------------------------------------------------------- Disparo anime

-- 1) agarras el arma y apuntas (cámara al hombro, barras, líneas), 2) FIRE!! con impact frame,
-- 3) la cámara persigue la bala, 4) el animal aparece de golpe, HIT!! y se desvanece, 5) a tu base
local function playShot(res)
	local r = root()
	local char = player.Character
	if not r or not char then
		return
	end
	local a, variant = Config.decode(res.animal)
	local rar = Config.Rarities[a.rarity]
	local displayColor = if variant > 0 then Config.Variants[variant].color else rar.color
	local legendaryWalk = (res.oneIn or 0) >= 1000
	local weapon = Config.Weapons[res.weapon]
	local humanoid = char:FindFirstChildOfClass("Humanoid")
	local oldSpeed = humanoid and humanoid.WalkSpeed or 16
	local oldJump = humanoid and humanoid.JumpPower or 50
	if humanoid then
		humanoid.WalkSpeed = 0
		humanoid.JumpPower = 0
		-- Siempre dispara con el arma en la mano (aunque traigas un animal)
		for _, tool in player.Backpack:GetChildren() do
			if tool:IsA("Tool") and tool:GetAttribute("WeaponIndex") then
				humanoid:EquipTool(tool)
			end
		end
	end
	shootBtn.Visible = false
	side.Visible = false
	panel.Visible = false
	hint.Text = ""
	local oldFov = camera.FieldOfView

	-- Mira hacia el campo
	r.CFrame = CFrame.lookAt(r.Position, r.Position + Vector3.new(0, 0, 1))
	camera.CameraType = Enum.CameraType.Scriptable
	cinematic(true)

	-- Fase 1: apuntar (cámara sobre el hombro, se cierra el FOV)
	local shoulder = r.CFrame * CFrame.new(2.2, 2.2, 5.5)
	local aimAt = r.Position + Vector3.new(0, 2, 40)
	tweenCamera(CFrame.lookAt(shoulder.Position, aimAt), 50, 0.45)
	speedLines.Visible = true
	local t0 = os.clock()
	while os.clock() - t0 < 0.7 do
		jitterLines(0.6)
		local pull = (os.clock() - t0) / 0.7
		camera.CFrame = CFrame.lookAt(shoulder.Position + Vector3.new(0, 0, pull * 1.5), aimAt)
		camera.FieldOfView = 50 - pull * 12
		task.wait()
	end

	-- Fase 2: FIRE!!
	task.spawn(impactFrame)
	shout("FIRE!!", Color3.fromRGB(255, 80, 60), -8)
	for _ = 1, 6 do
		camera.CFrame = shake(camera.CFrame, 0.8)
		task.wait()
	end

	-- Fase 3: la cámara sigue la bala
	local startPos = r.Position + Vector3.new(0.8, 2.5, 2)
	local landPos = Vector3.new(res.x, 1.5, Config.FIELD_START + res.dist)
	local peak = math.clamp(res.dist * 0.06, 8, 70)
	local duration = math.clamp(1 + res.dist / 500, 1.2, 5)

	local rock = Instance.new("Part")
	rock.Shape = Enum.PartType.Ball
	rock.Size = Vector3.new(1.2, 1.2, 1.2)
	rock.Color = if res.weapon <= 2 then Color3.fromRGB(130, 130, 130) else weapon.color
	rock.Material = if res.weapon <= 2 then Enum.Material.Slate else Enum.Material.Neon
	rock.Anchored = true
	rock.CanCollide = false
	rock.Parent = workspace
	local a0 = Instance.new("Attachment", rock)
	a0.Position = Vector3.new(0, 0.5, 0)
	local a1 = Instance.new("Attachment", rock)
	a1.Position = Vector3.new(0, -0.5, 0)
	local trail = Instance.new("Trail")
	trail.Attachment0 = a0
	trail.Attachment1 = a1
	trail.Color = ColorSequence.new(rar.color)
	trail.LightEmission = 1
	trail.Lifetime = 0.5
	trail.Parent = rock

	local beast: Model? = nil
	-- Más raro que 1 en 1000: la criatura aparece caminando antes de que llegue la bala
	if legendaryWalk then
		rock.Transparency = 1
		local stand = CFrame.new(landPos.X, 0, landPos.Z + 3)
		local walkFrom = stand * CFrame.new(-28, 0, 0)
		local b = Models.animal(res.animal, walkFrom * CFrame.Angles(0, math.rad(-90), 0), false)
		b.Parent = workspace
		beast = b
		local full = b:GetScale()
		flash.BackgroundColor3 = displayColor
		flash.BackgroundTransparency = 0.2
		TweenService:Create(flash, TweenInfo.new(0.6), { BackgroundTransparency = 1 }):Play()
		local title = text(fx, {
			Size = UDim2.fromScale(0.8, 0.1),
			Position = UDim2.fromScale(0.1, 0.16),
			Text = "!! ULTRA RARE · 1 in " .. fmt(res.oneIn) .. " !!",
			TextColor3 = displayColor,
			ZIndex = 40,
		})
		local walkTime = 2.8
		local w0 = os.clock()
		while os.clock() - w0 < walkTime do
			local t = (os.clock() - w0) / walkTime
			local step = math.abs(math.sin(t * walkTime * 9))
			local pos = walkFrom.Position:Lerp(stand.Position, t) + Vector3.new(0, step * 0.5 * full, 0)
			b:PivotTo(CFrame.new(pos) * CFrame.Angles(0, math.rad(-90), math.sin(t * walkTime * 9) * 0.06))
			local focus = pos + Vector3.new(0, 2 * full, 0)
			camera.CFrame = shake(CFrame.lookAt(stand.Position + Vector3.new(6, 2.5, -13), focus), step * 0.25)
			camera.FieldOfView = 60 - t * 15
			jitterLines(0.4)
			task.wait()
		end
		-- Gira hacia la cámara y ruge
		for i = 1, 10 do
			b:PivotTo(stand * CFrame.Angles(0, math.rad(-90 + 9 * i), 0))
			task.wait(0.02)
		end
		b:ScaleTo(full * 1.15)
		task.wait(0.08)
		b:ScaleTo(full)
		task.wait(0.5)
		title:Destroy()
		rock.Transparency = 0
		t0 = os.clock()
	end
	camera.FieldOfView = 85
	-- Animal caminando (si no entró ya con la animación de ultra raro)
	local walker = nil
	if not beast then
		local stand = Vector3.new(landPos.X, 0, landPos.Z + 3)
		local side = if landPos.X > 0 then -1 else 1
		local from = stand + Vector3.new(side * 16, 0, 4)
		local walkDir = (stand - from).Unit
		local facing = CFrame.Angles(0, math.atan2(-walkDir.X, -walkDir.Z), 0)
		local b = Models.animal(res.animal, CFrame.new(from) * facing, false)
		b.Parent = workspace
		beast = b
		walker = { model = b, from = from, to = stand, facing = facing, scale = b:GetScale() }
	end
	local dir = (landPos - startPos).Unit
	t0 = os.clock()
	while true do
		local alpha = math.min((os.clock() - t0) / duration, 1)
		-- Ease: arranca rapidísimo y frena un poco al llegar (sensación de cámara lenta)
		local eased = 1 - (1 - alpha) ^ 2
		local pos = startPos:Lerp(landPos, eased) + Vector3.new(0, math.sin(eased * math.pi) * peak, 0)
		rock.Position = pos
		jitterLines(1)
		camera.CFrame = shake(CFrame.lookAt(pos - dir * 9 + Vector3.new(0, 2.5, 0), pos + dir * 8), 0.15)
		camera.FieldOfView = 85 - alpha * 25
		-- El animal viene caminando hacia donde cae la bala y le pega justo al llegar
		if walker then
			local t = math.clamp((alpha - 0.15) / 0.85, 0, 1)
			local p = walker.from:Lerp(walker.to, t)
			local step = math.abs(math.sin(os.clock() * 14)) * 0.35 * walker.scale
			walker.model:PivotTo(CFrame.new(p + Vector3.new(0, step, 0)) * walker.facing)
		end
		if alpha >= 1 then
			break
		end
		task.wait()
	end

	-- Fase 4: HIT!! con freeze frame
	rock:Destroy()
	speedLines.Visible = false
	task.spawn(impactFrame)
	shout("HIT!!", displayColor, 6)
	local hitCam = CFrame.lookAt(landPos + Vector3.new(6, 4, -8), landPos + Vector3.new(0, 1.5, 3))
	camera.CFrame = hitCam
	camera.FieldOfView = 55
	local burst = Instance.new("Part")
	burst.Shape = Enum.PartType.Ball
	burst.Anchored = true
	burst.CanCollide = false
	burst.Material = Enum.Material.Neon
	burst.Color = rar.color
	burst.Size = Vector3.new(1, 1, 1)
	burst.Position = landPos + Vector3.new(0, 1, 3)
	burst.Parent = workspace
	TweenService:Create(burst, TweenInfo.new(0.45), { Size = Vector3.new(16, 16, 16), Transparency = 1 }):Play()
	task.delay(0.5, burst.Destroy, burst)
	for _ = 1, 8 do
		camera.CFrame = shake(hitCam, 1)
		task.wait()
	end
	banner(a, rar, variant)

	-- El animal parpadea en rojo y se desvanece, de pie
	if beast then
		for _, p in beast:GetDescendants() do
			if p:IsA("BasePart") then
				local original = p.Color
				p.Color = Color3.fromRGB(255, 60, 60)
				task.delay(0.15, function()
					p.Color = original
				end)
				TweenService:Create(p, TweenInfo.new(0.6, Enum.EasingStyle.Quad, Enum.EasingDirection.In, 0, false, 1.4), { Transparency = 1 }):Play()
			end
		end
	end
	-- Órbita lenta alrededor del animal
	local center = landPos + Vector3.new(0, 1.5, 3)
	local orbit0 = os.clock()
	while os.clock() - orbit0 < 2 do
		local ang = (os.clock() - orbit0) * 0.9 + 2.5
		camera.CFrame = CFrame.lookAt(center + Vector3.new(math.sin(ang) * 11, 4, math.cos(ang) * 11), center)
		task.wait()
	end
	if beast then
		beast:Destroy()
	end

	-- Fase 5: de vuelta a la base
	cinematic(false)
	action("Home")
	task.wait(0.15)
	camera.CameraType = Enum.CameraType.Custom
	camera.FieldOfView = oldFov
	if humanoid then
		humanoid.WalkSpeed = oldSpeed
		humanoid.JumpPower = oldJump
	end
	side.Visible = true
	renderPanel()
end

local function shoot()
	if shooting or not inShootZone() then
		return
	end
	shooting = true
	local ok, res = pcall(function()
		return Remotes.Shoot:InvokeServer()
	end)
	if ok and res then
		if res.err then
			toast(res.err, Color3.fromRGB(255, 120, 120))
		else
			playShot(res)
		end
	end
	shooting = false
end

shootBtn.Activated:Connect(shoot)
UserInputService.InputBegan:Connect(function(input, processed)
	if processed then
		return
	end
	if input.KeyCode == Enum.KeyCode.F or input.KeyCode == Enum.KeyCode.ButtonR2 then
		shoot()
	end
end)

-- Click con el arma en la mano también dispara
local function watchTools(char: Model)
	char.ChildAdded:Connect(function(child)
		if child:IsA("Tool") and child:GetAttribute("WeaponIndex") then
			child.Activated:Connect(shoot)
		elseif child:IsA("Tool") and child:GetAttribute("AnimalId") then
			-- Click con el animal en la mano: colocarlo en tu establo
			child.Activated:Connect(function()
				action("Place", child:GetAttribute("AnimalId"))
			end)
		end
	end)
end
if player.Character then
	watchTools(player.Character)
end
player.CharacterAdded:Connect(watchTools)

-- La tienda física abre el panel de armas
game:GetService("ProximityPromptService").PromptTriggered:Connect(function(prompt)
	if prompt.Name == "WeaponShop" then
		currentPanel = "Shop"
		renderPanel()
	elseif prompt.Name == "RobuxShop" then
		currentPanel = "Robux"
		renderPanel()
	end
end)


RunService.Heartbeat:Connect(function()
	if shooting then
		return
	end
	local inZone = inShootZone()
	shootBtn.Visible = inZone
	if inZone then
		hint.Text = "Press SHOOT (or F) to hunt a beast!"
	elseif player:GetAttribute("Training") then
		hint.Text = "Training... stay on the range!"
	elseif state and #state.held > 0 then
		hint.Text = "Equip your animal and click inside your stable to place it"
	elseif state and #state.animals == 0 then
		hint.Text = "Walk forward to the Shoot Zone"
	else
		hint.Text = ""
	end
end)

-- Variante Rainbow: los modelos con la etiqueta cambian de color
local rainbowClock = 0
RunService.Heartbeat:Connect(function(dt)
	rainbowClock += dt
	if rainbowClock < 0.08 then
		return
	end
	rainbowClock = 0
	local hue = (os.clock() * 0.25) % 1
	for _, m in CollectionService:GetTagged("Rainbow") do
		for _, p in m:GetDescendants() do
			if p:IsA("BasePart") and p.Transparency < 1 then
				p.Color = Color3.fromHSV((hue + p.Position.Y * 0.03) % 1, 0.8, 1)
			end
		end
	end
end)

-- Animales del establo: caminan por el corral y de vez en cuando saltan (sólo en este cliente)
type Wander = { pos: Vector3, target: Vector3, wait: number, hop: number, yaw: number }
local wanderers: { [Model]: Wander } = setmetatable({}, { __mode = "k" }) :: any
local wanderRng = Random.new()

local function penPoint(center: CFrame, size: Vector3): Vector3
	return (center * CFrame.new(wanderRng:NextNumber(-size.X, size.X), 0, wanderRng:NextNumber(-size.Z, size.Z))).Position
end

RunService.Heartbeat:Connect(function(dt)
	local plots = workspace:FindFirstChild("Plots")
	if not plots then
		return
	end
	local camPos = camera.CFrame.Position
	for _, plot in plots:GetChildren() do
		local center = plot:GetAttribute("PenCenter")
		local size = plot:GetAttribute("PenSize")
		local folder = plot:FindFirstChild("Animals")
		if not center or not size or not folder or (center.Position - camPos).Magnitude > 260 then
			continue
		end
		for _, m in folder:GetChildren() do
			if not m:IsA("Model") then
				continue
			end
			local w = wanderers[m]
			if not w then
				local p = m:GetPivot().Position
				w = { pos = Vector3.new(p.X, center.Position.Y, p.Z), target = penPoint(center, size), wait = wanderRng:NextNumber(0, 2), hop = 0, yaw = math.pi }
				wanderers[m] = w
			end
			local lift = 0
			if w.hop > 0 then
				-- salto: arco de 0.5 s
				w.hop = math.max(0, w.hop - dt)
				lift = math.sin((1 - w.hop / 0.5) * math.pi) * 2.2
			elseif w.wait > 0 then
				w.wait -= dt
			else
				local delta = w.target - w.pos
				local dist = Vector3.new(delta.X, 0, delta.Z).Magnitude
				if dist < 0.5 then
					w.target = penPoint(center, size)
					w.wait = wanderRng:NextNumber(0.8, 3)
					if wanderRng:NextNumber() < 0.35 then
						w.hop = 0.5
					end
				else
					local dir = Vector3.new(delta.X, 0, delta.Z) / dist
					w.pos += dir * math.min(dist, 5 * dt)
					w.yaw = math.atan2(-dir.X, -dir.Z)
					-- pasitos: rebote chiquito al caminar
					lift = math.abs(math.sin(os.clock() * 12 + w.pos.X)) * 0.35
				end
			end
			m:PivotTo(CFrame.new(w.pos + Vector3.new(0, lift, 0)) * CFrame.Angles(0, w.yaw, 0))
		end
	end
end)

-- Inventario propio (en vez del de Roblox): arma primero y luego los animales, con su vista 3D
local StarterGui = game:GetService("StarterGui")
task.spawn(function()
	for _ = 1, 20 do
		if pcall(StarterGui.SetCoreGuiEnabled, StarterGui, Enum.CoreGuiType.Backpack, false) then
			break
		end
		task.wait(0.5)
	end
end)

local SLOT = 84
local hotbar = Kit.scroll({
	Name = "Hotbar",
	Size = UDim2.fromOffset(9 * (SLOT + 8) + 8, SLOT + 18),
	AnchorPoint = Vector2.new(0.5, 1),
	Position = UDim2.new(0.5, 0, 1, -4),
	ScrollingDirection = Enum.ScrollingDirection.X,
	AutomaticCanvasSize = Enum.AutomaticSize.X,
	ScrollBarThickness = 5,
	Parent = gui,
})
Theme.list(hotbar, 8, true, Enum.HorizontalAlignment.Center)
Theme.padding(hotbar, 6, 4)
side:GetPropertyChangedSignal("Visible"):Connect(function()
	hotbar.Visible = side.Visible
end)

local function myTools(): { Tool }
	local list = {}
	local char = player.Character
	for _, container in { char, player:FindFirstChildOfClass("Backpack") } do
		if container then
			for _, t in container:GetChildren() do
				if t:IsA("Tool") then
					table.insert(list, t)
				end
			end
		end
	end
	-- arma primero; luego por orden de nombre para que no brinquen al equipar
	table.sort(list, function(a, b)
		local wa, wb = a:GetAttribute("WeaponIndex") ~= nil, b:GetAttribute("WeaponIndex") ~= nil
		if wa ~= wb then
			return wa
		end
		local ea, eb = a:GetAttribute("AnimalId") or 0, b:GetAttribute("AnimalId") or 0
		if ea ~= eb then
			return ea > eb
		end
		return a:GetDebugId() < b:GetDebugId()
	end)
	return list
end

local slotTools: { Tool } = {}
local function equipSlot(i: number)
	local tool = slotTools[i]
	local hum = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
	if not tool or not hum or shooting then
		return
	end
	if tool.Parent == player.Character then
		hum:UnequipTools()
	else
		hum:EquipTool(tool)
	end
end

local rebuildQueued = false
local function rebuildHotbar()
	rebuildQueued = false
	for _, c in hotbar:GetChildren() do
		if c:IsA("GuiObject") then
			c:Destroy()
		end
	end
	slotTools = myTools()
	for i, tool in slotTools do
		local equipped = tool.Parent == player.Character
		local entry = tool:GetAttribute("AnimalId")
		local color = "Dark"
		if entry then
			local a, v = Config.decode(entry)
			color = if v == 1 then "Gold" elseif v == 2 then "Cyan" elseif v == 3 then "Rainbow" elseif a.rarity >= 5 then "Orange" elseif a.rarity >= 4 then "Purple" elseif a.rarity >= 3 then "Blue" else "Dark"
		end
		local slot = Theme.new("TextButton", { Name = "Slot" .. i, Size = UDim2.fromOffset(SLOT, SLOT), Text = "", LayoutOrder = i, Parent = hotbar })
		Kit.face(slot, if equipped then "Lime" else color, { Stroke = if equipped then 4 else 3 })
		Kit.press(slot)
		Preview.tool(tool, UDim2.fromScale(0.92, 0.78), slot, 3).Position = UDim2.fromScale(0.04, 0.02)
		if i <= 9 then
			Kit.label({ Text = tostring(i), TextSize = 20, Size = UDim2.fromOffset(20, 22), Position = UDim2.fromOffset(4, 2), XAlign = Enum.TextXAlignment.Left, ZIndex = 4, Parent = slot })
		end
		Kit.label({ Text = tool.Name, TextSize = 13, Size = UDim2.new(1, -6, 0, 18), Position = UDim2.new(0, 3, 1, -20), Scaled = true, Font = Theme.FontBold, ZIndex = 4, Parent = slot })
		slot.Activated:Connect(function()
			Kit.sound(Kit.CLICK, 0.4)
			equipSlot(i)
		end)
	end
end

local function queueRebuild()
	if not rebuildQueued then
		rebuildQueued = true
		task.defer(rebuildHotbar)
	end
end

local function watchContainer(container: Instance)
	container.ChildAdded:Connect(function(c)
		if c:IsA("Tool") then
			queueRebuild()
		end
	end)
	container.ChildRemoved:Connect(function(c)
		if c:IsA("Tool") then
			queueRebuild()
		end
	end)
	queueRebuild()
end
if player.Character then
	watchContainer(player.Character)
end
player.CharacterAdded:Connect(watchContainer)
player.ChildAdded:Connect(function(c)
	if c:IsA("Backpack") then
		watchContainer(c)
	end
end)
local backpack = player:FindFirstChildOfClass("Backpack")
if backpack then
	watchContainer(backpack)
end

local NUMBER_KEYS = { Enum.KeyCode.One, Enum.KeyCode.Two, Enum.KeyCode.Three, Enum.KeyCode.Four, Enum.KeyCode.Five, Enum.KeyCode.Six, Enum.KeyCode.Seven, Enum.KeyCode.Eight, Enum.KeyCode.Nine }
UserInputService.InputBegan:Connect(function(input, processed)
	if processed then
		return
	end
	local i = table.find(NUMBER_KEYS, input.KeyCode)
	if i then
		equipSlot(i)
	end
end)

