-- Estilo de la UI y helpers para armarla (copiado de Roll a Chef: estilo "Studs").
-- Todo se diseña en "unidades de diseño" sobre una pantalla de 1100 × 620 y cada ScreenGui lleva un UIScale que
-- se ajusta a la pantalla (Theme.scale). En un celular chico (667 × 375) la escala queda en ~0.6, así que los
-- botones de 80 unidades miden ~48 px (tamaño mínimo de toque) y el texto de 24 unidades ~14 px.
-- En TV (ViewportDisplaySize Large) todo crece un 15%. Los ScreenGui usan CoreUISafeInsets (notch, barra de
-- Roblox) y los paneles se anclan a su borde con AnchorPoint.
local GuiService = game:GetService("GuiService")
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")

local Theme = {}

Theme.DESIGN = Vector2.new(1100, 620)
Theme.MinTouch = 72 -- unidades de diseño: ~44 px en el celular más chico

-- Estilo "Studs" (como el UI pack de referencia): caras de color con degradado vertical, brillo diagonal, textura
-- de studs de Lego, borde negro grueso y texto blanco con borde negro.
Theme.Colors = {
	White = Color3.new(1, 1, 1),
	Black = Color3.fromRGB(14, 14, 18),
	Outline = Color3.fromRGB(18, 18, 22),
	Panel = Color3.fromRGB(22, 22, 28), -- fondo de las ventanas (semitransparente)
	Card = Color3.fromRGB(10, 10, 14), -- filas dentro de las ventanas
	CardStroke = Color3.fromRGB(168, 174, 182),
	Text = Color3.new(1, 1, 1),
	TextDim = Color3.fromRGB(200, 200, 210),
	Money = Color3.fromRGB(145, 253, 2),
	MoneyTop = Color3.fromRGB(215, 255, 90),
	Orange = Color3.fromRGB(255, 177, 3),
	OrangeTop = Color3.fromRGB(255, 220, 90),
	Red = Color3.fromRGB(240, 50, 60),
	Gold = Color3.fromRGB(255, 205, 60),
	Robux = Color3.fromRGB(130, 255, 60),
	Shade = Color3.fromRGB(0, 0, 0),
}

-- Caras de color: { arriba, centro, abajo }
local rgb = Color3.fromRGB
Theme.Faces = {
	Red = { rgb(255, 100, 115), rgb(228, 40, 66), rgb(185, 22, 48) },
	Pink = { rgb(255, 130, 195), rgb(250, 58, 152), rgb(196, 28, 108) },
	Yellow = { rgb(255, 240, 125), rgb(252, 212, 68), rgb(238, 165, 26) },
	Orange = { rgb(255, 205, 90), rgb(255, 160, 30), rgb(228, 105, 12) },
	Purple = { rgb(222, 120, 255), rgb(178, 40, 245), rgb(118, 18, 190) },
	Blue = { rgb(120, 205, 255), rgb(48, 136, 238), rgb(28, 88, 196) },
	Lime = { rgb(228, 255, 70), rgb(160, 245, 20), rgb(88, 196, 8) },
	Green = { rgb(120, 235, 120), rgb(50, 195, 75), rgb(25, 140, 50) },
	Gray = { rgb(185, 185, 192), rgb(128, 128, 136), rgb(84, 84, 92) },
	Dark = { rgb(70, 70, 80), rgb(45, 45, 52), rgb(28, 28, 34) },
	White = { rgb(255, 255, 255), rgb(240, 240, 242), rgb(205, 205, 212) },
	Gold = { rgb(255, 230, 110), rgb(255, 180, 30), rgb(230, 120, 10) },
	Cyan = { rgb(150, 245, 255), rgb(60, 205, 240), rgb(25, 140, 200) },
	Wood = { rgb(225, 170, 110), rgb(185, 125, 70), rgb(135, 85, 45) },
	Silver = { rgb(240, 245, 250), rgb(190, 200, 212), rgb(130, 140, 155) },
	Mythic = { rgb(255, 120, 140), rgb(235, 50, 90), rgb(160, 20, 70) },
}
-- Arcoíris (Day 7, X2 Money/Luck, caja exclusiva)
Theme.Rainbow = ColorSequence.new({
	ColorSequenceKeypoint.new(0, rgb(255, 80, 200)),
	ColorSequenceKeypoint.new(0.25, rgb(255, 120, 60)),
	ColorSequenceKeypoint.new(0.5, rgb(255, 235, 60)),
	ColorSequenceKeypoint.new(0.75, rgb(90, 230, 120)),
	ColorSequenceKeypoint.new(1, rgb(80, 170, 255)),
})

-- Montserrat (como el pack): Heavy para títulos y botones, Bold para textos chicos
Theme.FontFace = Font.new("rbxasset://fonts/families/Montserrat.json", Enum.FontWeight.Heavy)
Theme.FontBold = Font.new("rbxasset://fonts/families/Montserrat.json", Enum.FontWeight.Bold)
Theme.FontSemi = Font.new("rbxasset://fonts/families/Montserrat.json", Enum.FontWeight.SemiBold)

-- Íconos subidos a Roblox (los mismos de Roll a Chef); si falta uno, la UI usa el emoji de respaldo
local UIIcons = {
	["arrow"] = 90023755080784,
	["arrow_down"] = 81384475708124,
	["backpack"] = 101544544965391,
	["basket"] = 96288613765489,
	["book"] = 93585406127569,
	["calendar"] = 113165570918423,
	["cash"] = 99264112788584,
	["check"] = 117394853515342,
	["chefhat"] = 97928398209279,
	["clock"] = 136794035611044,
	["clover"] = 96503824297584,
	["crate"] = 74965179678955,
	["crown"] = 124089881207511,
	["dice"] = 112500688824658,
	["gear"] = 98370928294838,
	["gift"] = 129780699366523,
	["lock"] = 84311115603901,
	["lucky"] = 140238428972801,
	["platform"] = 73839646012800,
	["quests"] = 120397290951451,
	["rays"] = 134726909548673,
	["rebirth"] = 99287399199256,
	["robux"] = 138483345794617,
	["store"] = 109442124512295,
	["studs"] = 108124188314977,
	["ticket"] = 120510863725151,
	["trade"] = 72354422360799,
	["upgrade"] = 132534633726365,
}
function Theme.image(name: string): string?
	local id = UIIcons[name]
	return if id then "rbxassetid://" .. id else nil
end

Theme.Fast = TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
Theme.Pop = TweenInfo.new(0.32, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
Theme.Smooth = TweenInfo.new(0.25, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)

local camera = workspace.CurrentCamera
local scales = {} :: { UIScale }
local listeners = {} :: { () -> () }

-- Escala de la pantalla respecto al diseño
function Theme.scale(): number
	local viewport = camera.ViewportSize
	local s = math.min(viewport.X / Theme.DESIGN.X, viewport.Y / Theme.DESIGN.Y)
	local ok, large = pcall(function()
		return GuiService.ViewportDisplaySize == Enum.DisplaySize.Large
	end)
	if ok and large then
		s *= 1.15
	end
	return math.clamp(s, 0.55, 1.6)
end

-- Tamaño útil de la pantalla en unidades de diseño
function Theme.usable(): Vector2
	local s = Theme.scale()
	local inset = GuiService:GetGuiInset()
	local viewport = camera.ViewportSize
	return Vector2.new(viewport.X / s, (viewport.Y - inset.Y) / s)
end

function Theme.compact(): boolean
	return Theme.usable().X < 900
end

local function rescale()
	local s = Theme.scale()
	for _, scale in scales do
		scale.Scale = s
	end
	for _, fn in listeners do
		task.spawn(fn)
	end
end
camera:GetPropertyChangedSignal("ViewportSize"):Connect(rescale)
pcall(function()
	GuiService:GetPropertyChangedSignal("ViewportDisplaySize"):Connect(rescale)
end)

-- fn() corre cada vez que cambia el tamaño de la pantalla (para reacomodar)
function Theme.onResize(fn: () -> ())
	table.insert(listeners, fn)
end

-- ScreenGui con su UIScale, en el área segura
function Theme.screen(name: string, order: number?, fullscreen: boolean?): ScreenGui
	local gui = Instance.new("ScreenGui")
	gui.Name = name
	gui.ResetOnSpawn = false
	gui.IgnoreGuiInset = fullscreen == true
	gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	gui.ScreenInsets = if fullscreen then Enum.ScreenInsets.None else Enum.ScreenInsets.CoreUISafeInsets
	gui.DisplayOrder = order or 0
	gui.Parent = Players.LocalPlayer:WaitForChild("PlayerGui")
	if not fullscreen then
		local scale = Instance.new("UIScale")
		scale.Scale = Theme.scale()
		scale.Parent = gui
		table.insert(scales, scale)
	end
	return gui
end

------------------------------------------------------------------ Instancias

-- Theme.new("Frame", {props}, {hijos})
function Theme.new(className: string, props: { [string]: any }?, children: { Instance }?): any
	local instance = Instance.new(className)
	if instance:IsA("GuiObject") then
		instance.BorderSizePixel = 0
		if instance:IsA("Frame") or instance:IsA("ScrollingFrame") or instance:IsA("TextLabel") or instance:IsA("ImageLabel") then
			instance.BackgroundTransparency = 1
		end
	end
	if instance:IsA("TextLabel") or instance:IsA("TextButton") or instance:IsA("TextBox") then
		local text = instance :: TextLabel
		text.FontFace = Theme.FontFace
		text.TextColor3 = Theme.Colors.Text
		text.TextSize = 22
		text.Text = ""
		text.TextWrapped = true
	end
	if instance:IsA("TextButton") or instance:IsA("ImageButton") then
		(instance :: TextButton).AutoButtonColor = false
	end
	local parent
	for key, value in props or {} do
		if key == "Parent" then
			parent = value
		else
			(instance :: any)[key] = value
		end
	end
	for _, child in children or {} do
		child.Parent = instance
	end
	if parent then
		instance.Parent = parent
	end
	return instance
end

function Theme.corner(parent: Instance, radius: number?): UICorner
	return Theme.new("UICorner", { CornerRadius = UDim.new(0, radius or 6), Parent = parent })
end

function Theme.stroke(parent: Instance, thickness: number?, color: Color3?, transparency: number?): UIStroke
	return Theme.new("UIStroke", {
		ApplyStrokeMode = if parent:IsA("TextLabel") or parent:IsA("TextBox") then Enum.ApplyStrokeMode.Contextual else Enum.ApplyStrokeMode.Border,
		Thickness = thickness or 3,
		Color = color or Theme.Colors.Outline,
		Transparency = transparency or 0,
		LineJoinMode = Enum.LineJoinMode.Round,
		Parent = parent,
	})
end

-- Borde de texto (para texto blanco sobre colores)
function Theme.textStroke(label: Instance, thickness: number?, color: Color3?): UIStroke
	return Theme.new("UIStroke", {
		ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual,
		Thickness = thickness or 2.5,
		Color = color or Theme.Colors.Outline,
		LineJoinMode = Enum.LineJoinMode.Round,
		Parent = label,
	})
end

function Theme.padding(parent: Instance, all: number, horizontal: number?): UIPadding
	local h = horizontal or all
	return Theme.new("UIPadding", {
		PaddingTop = UDim.new(0, all),
		PaddingBottom = UDim.new(0, all),
		PaddingLeft = UDim.new(0, h),
		PaddingRight = UDim.new(0, h),
		Parent = parent,
	})
end

function Theme.list(parent: Instance, padding: number?, horizontal: boolean?, align: Enum.HorizontalAlignment?): UIListLayout
	return Theme.new("UIListLayout", {
		Padding = UDim.new(0, padding or 8),
		FillDirection = if horizontal then Enum.FillDirection.Horizontal else Enum.FillDirection.Vertical,
		SortOrder = Enum.SortOrder.LayoutOrder,
		HorizontalAlignment = align or Enum.HorizontalAlignment.Left,
		VerticalAlignment = if horizontal then Enum.VerticalAlignment.Center else Enum.VerticalAlignment.Top,
		Parent = parent,
	})
end

function Theme.gradient(parent: Instance, sequence: ColorSequence, rotation: number?): UIGradient
	return Theme.new("UIGradient", { Color = sequence, Rotation = rotation or 90, Parent = parent })
end

function Theme.tween(instance: Instance, info: TweenInfo, goal: { [string]: any }): Tween
	local tween = TweenService:Create(instance, info, goal)
	tween:Play()
	return tween
end

-- Gradientes que giran (rarezas altas): se registran aquí y los mueve un solo loop (Main)
Theme.Spinning = {} :: { [UIGradient]: boolean }
function Theme.spin(gradient: UIGradient)
	Theme.Spinning[gradient] = true
	gradient.Destroying:Connect(function()
		Theme.Spinning[gradient] = nil
	end)
end

return Theme
