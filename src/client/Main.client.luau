-- Kill a Beast: cliente (HUD, paneles y la cámara que sigue el disparo)
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local HttpService = game:GetService("HttpService")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local Models = require(ReplicatedStorage.Shared.Models)
local fmt = require(ReplicatedStorage.Shared.Format)
local Remotes = ReplicatedStorage:WaitForChild("Remotes")

local player = Players.LocalPlayer
local camera = workspace.CurrentCamera

local state: any = nil
local shooting = false

---------------------------------------------------------------- UI base

local gui = Instance.new("ScreenGui")
gui.Name = "KillABeastUI"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = false
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.Parent = player:WaitForChild("PlayerGui")

local FONT = Enum.Font.LuckiestGuy

local function corner(p: Instance, r: number?)
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, r or 10)
	c.Parent = p
end

local function stroke(p: Instance, color: Color3?, thick: number?)
	local s = Instance.new("UIStroke")
	s.Color = color or Color3.new(0, 0, 0)
	s.Thickness = thick or 2.5
	s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	s.Parent = p
end

local function text(parent: Instance, props: { [string]: any }): TextLabel
	local t = Instance.new("TextLabel")
	t.BackgroundTransparency = 1
	t.Font = FONT
	t.TextColor3 = Color3.new(1, 1, 1)
	t.TextStrokeTransparency = 0
	t.TextScaled = true
	for k, v in props do
		(t :: any)[k] = v
	end
	t.Parent = parent
	return t
end

local function button(parent: Instance, label: string, color: Color3, size: UDim2, pos: UDim2): TextButton
	local b = Instance.new("TextButton")
	b.Size = size
	b.Position = pos
	b.BackgroundColor3 = color
	b.Font = FONT
	b.Text = label
	b.TextScaled = true
	b.TextColor3 = Color3.new(1, 1, 1)
	b.TextStrokeTransparency = 0
	b.AutoButtonColor = true
	corner(b, 8)
	stroke(b)
	local pad = Instance.new("UIPadding")
	pad.PaddingTop = UDim.new(0.15, 0)
	pad.PaddingBottom = UDim.new(0.15, 0)
	pad.PaddingLeft = UDim.new(0, 6)
	pad.PaddingRight = UDim.new(0, 6)
	pad.Parent = b
	b.Parent = parent
	return b
end

-- Botones laterales (como Shop / Index de Steal an Egg)
local side = Instance.new("Frame")
side.BackgroundTransparency = 1
side.Size = UDim2.fromOffset(130, 170)
side.Position = UDim2.new(0, 8, 0.5, -85)
side.Parent = gui
local list = Instance.new("UIListLayout")
list.Padding = UDim.new(0, 8)
list.Parent = side
local shopBtn = button(side, "Shop", Color3.fromRGB(60, 200, 50), UDim2.new(1, 0, 0, 48), UDim2.new())
local stableBtn = button(side, "Stable", Color3.fromRGB(230, 140, 40), UDim2.new(1, 0, 0, 48), UDim2.new())
local indexBtn = button(side, "Index", Color3.fromRGB(40, 170, 230), UDim2.new(1, 0, 0, 48), UDim2.new())

-- Dinero y poder abajo a la izquierda
local stats = Instance.new("Frame")
stats.BackgroundTransparency = 1
stats.Size = UDim2.fromOffset(260, 80)
stats.Position = UDim2.new(0, 10, 1, -90)
stats.Parent = gui
local powerLabel = text(stats, { Size = UDim2.new(1, 0, 0.45, 0), TextXAlignment = Enum.TextXAlignment.Left, TextColor3 = Color3.fromRGB(80, 200, 255), Text = "Power 0" })
local moneyLabel = text(stats, { Size = UDim2.new(1, 0, 0.55, 0), Position = UDim2.fromScale(0, 0.45), TextXAlignment = Enum.TextXAlignment.Left, TextColor3 = Color3.fromRGB(90, 255, 90), Text = "$0" })

-- Info del arma y del establo arriba a la derecha
local info = text(gui, { Size = UDim2.fromOffset(260, 50), Position = UDim2.new(1, -270, 0, 8), TextXAlignment = Enum.TextXAlignment.Right, Text = "" })

-- Ingreso por segundo arriba al centro, pista debajo
local incomeLabel = text(gui, { Size = UDim2.new(0.5, 0, 0, 44), Position = UDim2.new(0.25, 0, 0, 6), Text = "+$0/s", TextColor3 = Color3.fromRGB(90, 255, 90) })
local hint = text(gui, { Size = UDim2.new(0.6, 0, 0, 28), Position = UDim2.new(0.2, 0, 0, 52), Text = "" })
local shootBtn = button(gui, "SHOOT!", Color3.fromRGB(230, 50, 50), UDim2.fromOffset(200, 70), UDim2.new(0.5, -100, 1, -100))
shootBtn.Visible = false

local homeBtn = button(gui, "Base", Color3.fromRGB(110, 110, 200), UDim2.fromOffset(100, 44), UDim2.new(1, -110, 1, -54))

-- Avisos flotantes
local function toast(msg: string, color: Color3?)
	local t = text(gui, {
		Size = UDim2.new(0.5, 0, 0, 34),
		Position = UDim2.new(0.25, 0, 0.3, 0),
		Text = msg,
		TextColor3 = color or Color3.new(1, 1, 1),
		ZIndex = 20,
	})
	TweenService:Create(t, TweenInfo.new(1.6), { Position = UDim2.new(0.25, 0, 0.2, 0), TextTransparency = 1, TextStrokeTransparency = 1 }):Play()
	task.delay(1.7, t.Destroy, t)
end

Remotes.Notify.OnClientEvent:Connect(function(msg, color)
	toast(msg, color)
end)

---------------------------------------------------------------- Paneles

local panel = Instance.new("Frame")
panel.Size = UDim2.new(0.6, 0, 0.7, 0)
panel.Position = UDim2.new(0.2, 0, 0.15, 0)
panel.BackgroundColor3 = Color3.fromRGB(45, 45, 60)
panel.Visible = false
panel.ZIndex = 5
corner(panel, 14)
stroke(panel, Color3.new(0, 0, 0), 4)
local sizeLimit = Instance.new("UISizeConstraint")
sizeLimit.MinSize = Vector2.new(300, 260)
sizeLimit.MaxSize = Vector2.new(720, 520)
sizeLimit.Parent = panel
panel.Parent = gui

local panelTitle = text(panel, { Size = UDim2.new(1, -70, 0, 42), Position = UDim2.fromOffset(14, 6), TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 6 })
local closeBtn = button(panel, "X", Color3.fromRGB(230, 50, 50), UDim2.fromOffset(42, 42), UDim2.new(1, -50, 0, 6))
closeBtn.ZIndex = 6
local header = Instance.new("Frame")
header.BackgroundTransparency = 1
header.Size = UDim2.new(1, -24, 0, 0)
header.Position = UDim2.fromOffset(12, 54)
header.ZIndex = 6
header.Parent = panel
local scroll = Instance.new("ScrollingFrame")
scroll.BackgroundTransparency = 1
scroll.BorderSizePixel = 0
scroll.ScrollBarThickness = 8
scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
scroll.CanvasSize = UDim2.new()
scroll.ZIndex = 6
scroll.Parent = panel
local grid = Instance.new("UIGridLayout")
grid.CellPadding = UDim2.fromOffset(8, 8)
grid.SortOrder = Enum.SortOrder.LayoutOrder
grid.Parent = scroll

local currentPanel: string? = nil
local renderPanel: () -> ()

local function card(order: number, color: Color3): Frame
	local f = Instance.new("Frame")
	f.LayoutOrder = order
	f.BackgroundColor3 = color
	f.ZIndex = 7
	corner(f, 8)
	stroke(f, Color3.new(0, 0, 0), 2)
	f.Parent = scroll
	return f
end

local function setHeader(height: number)
	header.Size = UDim2.new(1, -24, 0, height)
	scroll.Position = UDim2.fromOffset(12, 58 + height)
	scroll.Size = UDim2.new(1, -24, 1, -70 - height)
end

local function clearPanel()
	for _, c in scroll:GetChildren() do
		if not c:IsA("UIGridLayout") then
			c:Destroy()
		end
	end
	header:ClearAllChildren()
end

local function action(kind: string, arg: any?)
	Remotes.Action:FireServer(kind, arg)
end

local function renderShop()
	panelTitle.Text = "Weapon Shop"
	setHeader(0)
	grid.CellSize = UDim2.new(0.5, -4, 0, 96)
	for i, w in Config.Weapons do
		local owned = state.owned[tostring(i)]
		local f = card(i, if owned then Color3.fromRGB(60, 90, 60) else Color3.fromRGB(70, 70, 90))
		local sw = Instance.new("Frame")
		sw.Size = UDim2.fromOffset(10, 76)
		sw.Position = UDim2.fromOffset(8, 10)
		sw.BackgroundColor3 = w.color
		sw.ZIndex = 8
		corner(sw, 4)
		sw.Parent = f
		text(f, { Size = UDim2.new(1, -130, 0, 30), Position = UDim2.fromOffset(26, 8), Text = i .. ". " .. w.name, TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 8 })
		text(f, {
			Size = UDim2.new(1, -130, 0, 22),
			Position = UDim2.fromOffset(26, 42),
			Text = "Reach: Epoch " .. Config.epochAt(w.range) .. " (" .. w.range .. " studs)",
			TextColor3 = Color3.fromRGB(200, 220, 255),
			TextXAlignment = Enum.TextXAlignment.Left,
			ZIndex = 8,
		})
		local label, color
		if state.equipped == i then
			label, color = "Equipped", Color3.fromRGB(120, 120, 120)
		elseif owned then
			label, color = "Equip", Color3.fromRGB(40, 170, 230)
		else
			label, color = "$" .. fmt(w.price), Color3.fromRGB(60, 200, 50)
		end
		local b = button(f, label, color, UDim2.fromOffset(96, 44), UDim2.new(1, -104, 0.5, -22))
		b.ZIndex = 8
		b.Activated:Connect(function()
			action("BuyWeapon", i)
		end)
	end
end

local function renderStable()
	local cap = Config.stableCapacity(state.stableLevel)
	panelTitle.Text = string.format("Stable  %d/%d", #state.animals, cap)
	setHeader(60)
	local function upgrade(label: string, sub: string, x: number, kind: string, maxed: boolean)
		local b = button(header, if maxed then label .. " (MAX)" else label .. "  " .. sub, Color3.fromRGB(230, 140, 40), UDim2.new(0.5, -4, 1, 0), UDim2.new(x, if x > 0 then 4 else 0, 0, 0))
		b.ZIndex = 7
		b.Activated:Connect(function()
			action(kind)
		end)
	end
	upgrade("+5 Slots", "$" .. fmt(Config.stableUpgradeCost(state.stableLevel)), 0, "UpgradeStable", state.stableLevel >= Config.STABLE_MAX_LEVEL)
	upgrade("Trainer Lv" .. state.trainerLevel + 1, "$" .. fmt(Config.trainerUpgradeCost(state.trainerLevel)), 0.5, "UpgradeTrainer", state.trainerLevel >= Config.TRAINER_MAX_LEVEL)

	grid.CellSize = UDim2.new(0.333, -6, 0, 110)
	-- Primero los que traes en la mano, luego los colocados
	for slot, id in state.held do
		local a = Config.Animals[id]
		local rar = Config.Rarities[a.rarity]
		local f = card(slot, Color3.fromRGB(80, 70, 50))
		stroke(f, rar.color, 3)
		text(f, { Size = UDim2.new(1, -10, 0, 18), Position = UDim2.fromOffset(5, 4), Text = "IN HAND · " .. rar.name, TextColor3 = rar.color, ZIndex = 8 })
		text(f, { Size = UDim2.new(1, -10, 0, 22), Position = UDim2.fromOffset(5, 22), Text = a.name, ZIndex = 8 })
		text(f, { Size = UDim2.new(1, -10, 0, 18), Position = UDim2.fromOffset(5, 46), Text = "$" .. fmt(a.income) .. "/s", TextColor3 = Color3.fromRGB(90, 255, 90), ZIndex = 8 })
		local b = button(f, "Sell $" .. fmt(Config.sellValue(a)), Color3.fromRGB(200, 60, 60), UDim2.new(1, -16, 0, 30), UDim2.new(0, 8, 1, -36))
		b.ZIndex = 8
		b.Activated:Connect(function()
			action("SellHeld", slot)
		end)
	end
	for slot, id in state.animals do
		local a = Config.Animals[id]
		local rar = Config.Rarities[a.rarity]
		local f = card(100 + slot, Color3.fromRGB(60, 60, 80))
		stroke(f, rar.color, 3)
		text(f, { Size = UDim2.new(1, -10, 0, 18), Position = UDim2.fromOffset(5, 4), Text = rar.name, TextColor3 = rar.color, ZIndex = 8 })
		text(f, { Size = UDim2.new(1, -10, 0, 22), Position = UDim2.fromOffset(5, 22), Text = a.name, ZIndex = 8 })
		text(f, { Size = UDim2.new(1, -10, 0, 18), Position = UDim2.fromOffset(5, 46), Text = "$" .. fmt(a.income) .. "/s", TextColor3 = Color3.fromRGB(90, 255, 90), ZIndex = 8 })
		local b = button(f, "Sell $" .. fmt(Config.sellValue(a)), Color3.fromRGB(200, 60, 60), UDim2.new(0.5, -10, 0, 30), UDim2.new(0, 8, 1, -36))
		b.ZIndex = 8
		b.Activated:Connect(function()
			action("Sell", slot)
		end)
		local pick = button(f, "Pick up", Color3.fromRGB(40, 170, 230), UDim2.new(0.5, -10, 0, 30), UDim2.new(0.5, 2, 1, -36))
		pick.ZIndex = 8
		pick.Activated:Connect(function()
			action("PickUp", slot)
		end)
	end
end

local function renderIndex()
	local found = 0
	for _ in state.discovered do
		found += 1
	end
	panelTitle.Text = string.format("Index  %d/%d", found, #Config.AnimalOrder)
	setHeader(0)
	grid.CellSize = UDim2.new(0.2, -7, 0, 70)
	for n, id in Config.AnimalOrder do
		local a = Config.Animals[id]
		local rar = Config.Rarities[a.rarity]
		local known = state.discovered[tostring(id)]
		local f = card(n, if known then a.color2 else Color3.fromRGB(30, 30, 35))
		stroke(f, rar.color, 2)
		text(f, { Size = UDim2.new(1, -6, 0, 16), Position = UDim2.fromOffset(3, 4), Text = Config.Epochs[a.epoch].name, TextColor3 = Color3.fromRGB(220, 220, 220), ZIndex = 8 })
		text(f, { Size = UDim2.new(1, -6, 0, 26), Position = UDim2.fromOffset(3, 22), Text = if known then a.name else "???", ZIndex = 8 })
		text(f, { Size = UDim2.new(1, -6, 0, 14), Position = UDim2.fromOffset(3, 50), Text = rar.name, TextColor3 = rar.color, ZIndex = 8 })
	end
end

renderPanel = function()
	if not currentPanel or not state then
		panel.Visible = false
		return
	end
	clearPanel()
	panel.Visible = true
	if currentPanel == "Shop" then
		renderShop()
	elseif currentPanel == "Stable" then
		renderStable()
	else
		renderIndex()
	end
end

local function toggle(name: string)
	currentPanel = if currentPanel == name then nil else name
	renderPanel()
end
shopBtn.Activated:Connect(function()
	toggle("Shop")
end)
stableBtn.Activated:Connect(function()
	toggle("Stable")
end)
indexBtn.Activated:Connect(function()
	toggle("Index")
end)
closeBtn.Activated:Connect(function()
	currentPanel = nil
	renderPanel()
end)
homeBtn.Activated:Connect(function()
	action("Home")
end)

---------------------------------------------------------------- Estado

local lastPanelKey = ""
local function onState()
	local raw = player:GetAttribute("State")
	if not raw then
		return
	end
	state = HttpService:JSONDecode(raw)
	moneyLabel.Text = "$" .. fmt(state.money)
	incomeLabel.Text = "+$" .. fmt(state.income) .. "/s"
	powerLabel.Text = "Power " .. fmt(state.power) .. "  (+" .. Config.trainerGain(state.trainerLevel) .. "/train)"
	local w = Config.Weapons[state.equipped]
	local reach = Config.shotDistance(state.equipped, state.power)
	info.Text = w.name .. "\nReach: Epoch " .. Config.epochAt(reach) .. " · Stable " .. #state.animals .. "/" .. Config.stableCapacity(state.stableLevel)
	-- El dinero sube cada segundo; sólo redibuja el panel si cambió algo más
	local key = HttpService:JSONEncode({ state.owned, state.equipped, state.animals, state.held, state.stableLevel, state.trainerLevel, state.discovered, currentPanel == "Shop" and math.floor(state.money) or 0 })
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

local function banner(a, rar)
	local f = Instance.new("Frame")
	f.Size = UDim2.new(0.7, 0, 0, 110)
	f.Position = UDim2.new(0.15, 0, 0.12, 0)
	f.BackgroundTransparency = 1
	f.ZIndex = 30
	f.Parent = gui
	text(f, { Size = UDim2.new(1, 0, 0.35, 0), Text = rar.name:upper(), TextColor3 = rar.color, ZIndex = 30 })
	text(f, { Size = UDim2.new(1, 0, 0.4, 0), Position = UDim2.fromScale(0, 0.35), Text = "You hunted a " .. a.name .. "!", ZIndex = 30 })
	text(f, { Size = UDim2.new(1, 0, 0.25, 0), Position = UDim2.fromScale(0, 0.75), Text = "+$" .. fmt(a.income) .. "/s", TextColor3 = Color3.fromRGB(90, 255, 90), ZIndex = 30 })
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
	local a = Config.Animals[res.animal]
	local rar = Config.Rarities[a.rarity]
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

	camera.FieldOfView = 85
	local beast: Model? = nil
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
		-- "De repente" aparece el animal cuando la bala va llegando
		if alpha > 0.75 and not beast then
			local b = Models.animal(res.animal, CFrame.new(landPos.X, 0, landPos.Z + 3), false)
			b.Parent = workspace
			local full = b:GetScale()
			b:ScaleTo(full * 0.05)
			beast = b
			task.spawn(function()
				for i = 1, 8 do
					if b.Parent then
						b:ScaleTo(full * i / 8)
					end
					task.wait(0.02)
				end
			end)
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
	shout("HIT!!", rar.color, 6)
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
	banner(a, rar)

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
	elseif state and #state.held > 0 then
		hint.Text = "Equip your animal and click inside your stable to place it"
	elseif state and #state.animals == 0 then
		hint.Text = "Walk forward to the Shoot Zone"
	else
		hint.Text = ""
	end
end)
