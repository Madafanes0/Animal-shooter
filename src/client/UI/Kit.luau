-- Piezas de UI con el estilo "Studs" (copiadas de Roll a Chef): caras de color (degradado, brillo diagonal,
-- studs y borde negro), botones, casillas del HUD, tarjetas, barras, precios y textos con borde.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local Format = require(ReplicatedStorage:WaitForChild("Shared").Format)
local Theme = require(script.Parent.Theme)

local C = Theme.Colors

local Kit = {}

local sounds = {}
function Kit.sound(id: string, volume: number?)
	local sound = sounds[id]
	if not sound then
		sound = Theme.new("Sound", { SoundId = id, Volume = volume or 0.5, Parent = workspace })
		sounds[id] = sound
	end
	pcall(sound.Play, sound)
end
Kit.CLICK = "rbxasset://sounds/clickfast.wav"
Kit.PING = "rbxasset://sounds/electronicpingshort.wav"

function Kit.isTouch(): boolean
	return UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled
end

------------------------------------------------------------------ Texto

export type LabelProps = {
	Text: string?,
	Size: UDim2?,
	Position: UDim2?,
	AnchorPoint: Vector2?,
	TextSize: number?,
	Color: Color3?,
	Stroke: number?,
	StrokeColor: Color3?,
	Font: Font?,
	XAlign: Enum.TextXAlignment?,
	YAlign: Enum.TextYAlignment?,
	Scaled: boolean?,
	Parent: Instance?,
	Name: string?,
	ZIndex: number?,
	LayoutOrder: number?,
	Gradient: ColorSequence?,
	Wrapped: boolean?,
	Rich: boolean?,
}

-- Texto blanco con borde negro (el borde crece con el tamaño de letra)
function Kit.label(props: LabelProps): TextLabel
	local size = props.TextSize or 22
	local label = Theme.new("TextLabel", {
		Name = props.Name or "Label",
		Text = props.Text or "",
		Size = props.Size or UDim2.fromScale(1, 1),
		Position = props.Position or UDim2.new(),
		AnchorPoint = props.AnchorPoint or Vector2.zero,
		TextSize = size,
		TextColor3 = props.Color or C.Text,
		FontFace = props.Font or Theme.FontFace,
		TextXAlignment = props.XAlign or Enum.TextXAlignment.Center,
		TextYAlignment = props.YAlign or Enum.TextYAlignment.Center,
		TextScaled = props.Scaled == true,
		TextWrapped = props.Wrapped ~= false,
		RichText = props.Rich == true,
		ZIndex = props.ZIndex or 1,
		LayoutOrder = props.LayoutOrder or 0,
		Parent = props.Parent,
	})
	if props.Scaled then
		Theme.new("UITextSizeConstraint", { MaxTextSize = size, MinTextSize = 8, Parent = label })
	end
	if props.Stroke ~= 0 then
		Theme.textStroke(label, props.Stroke or math.clamp(size * 0.11, 1.5, 4), props.StrokeColor or C.Black)
	end
	if props.Gradient then
		Theme.gradient(label, props.Gradient, 90)
	end
	return label
end

------------------------------------------------------------------ Caras de color

-- Brillo diagonal: dos franjas claras como en los botones del pack
local SHINE = NumberSequence.new({
	NumberSequenceKeypoint.new(0, 1),
	NumberSequenceKeypoint.new(0.38, 1),
	NumberSequenceKeypoint.new(0.42, 0.72),
	NumberSequenceKeypoint.new(0.56, 0.72),
	NumberSequenceKeypoint.new(0.6, 1),
	NumberSequenceKeypoint.new(0.66, 1),
	NumberSequenceKeypoint.new(0.69, 0.82),
	NumberSequenceKeypoint.new(0.75, 0.82),
	NumberSequenceKeypoint.new(0.78, 1),
	NumberSequenceKeypoint.new(1, 1),
})

local function faceSequence(color: string): ColorSequence
	if color == "Rainbow" then
		return Theme.Rainbow
	end
	local f = Theme.Faces[color] or Theme.Faces.Gray
	return ColorSequence.new({
		ColorSequenceKeypoint.new(0, f[1]),
		ColorSequenceKeypoint.new(0.5, f[2]),
		ColorSequenceKeypoint.new(1, f[3]),
	})
end

export type FaceOptions = { Stroke: number?, Radius: number?, Studs: boolean?, Shine: boolean? }

-- Decora un Frame o botón como cara de color. Stroke = grosor del borde negro (0 = sin borde).
function Kit.face(frame: GuiObject, color: string, options: FaceOptions?)
	local opts = options or {}
	local radius = opts.Radius or 5
	frame.BackgroundColor3 = C.White
	frame.BackgroundTransparency = 0
	Theme.corner(frame, radius)
	Theme.new("UIGradient", { Name = "FaceGradient", Color = faceSequence(color), Rotation = if color == "Rainbow" then 0 else 90, Parent = frame })
	if (opts.Stroke or 3) > 0 then
		local stroke = Theme.stroke(frame, opts.Stroke or 3, C.Outline)
		stroke.Name = "Outline"
	end
	-- Capa interna recortada: los studs y el brillo no se salen de las esquinas
	local inner = Theme.new("Frame", { Name = "FaceInner", Size = UDim2.fromScale(1, 1), ClipsDescendants = true, ZIndex = frame.ZIndex, Parent = frame })
	Theme.corner(inner, radius)
	if opts.Studs ~= false then
		local studs = Theme.image("studs")
		if studs then
			Theme.new("ImageLabel", {
				Name = "Studs",
				Image = studs,
				ScaleType = Enum.ScaleType.Tile,
				TileSize = UDim2.fromOffset(22, 22),
				Size = UDim2.fromScale(1, 1),
				ImageTransparency = 0.78,
				ZIndex = frame.ZIndex,
				Parent = inner,
			})
		end
	end
	if opts.Shine ~= false then
		local shine = Theme.new("Frame", { Name = "Shine", Size = UDim2.fromScale(1, 1), BackgroundColor3 = C.White, BackgroundTransparency = 0, ZIndex = frame.ZIndex, Parent = inner })
		Theme.new("UIGradient", { Transparency = SHINE, Rotation = 28, Parent = shine })
	end
	-- Filo claro por dentro (bisel)
	local bevel = Theme.new("Frame", { Name = "Bevel", Size = UDim2.new(1, -4, 1, -4), Position = UDim2.fromOffset(2, 2), ZIndex = frame.ZIndex, Parent = inner })
	Theme.corner(bevel, math.max(0, radius - 2))
	Theme.stroke(bevel, 1.5, C.White, 0.55)
end

function Kit.setColor(frame: GuiObject, color: string)
	local gradient = frame:FindFirstChild("FaceGradient") :: UIGradient?
	if gradient then
		gradient.Color = faceSequence(color)
		gradient.Rotation = if color == "Rainbow" then 0 else 90
	end
end

------------------------------------------------------------------ Íconos

-- Ícono: imagen subida (Config/UIIcons) o, si no está, el emoji de respaldo
function Kit.icon(name: string, fallback: string, props: { [string]: any }): GuiObject
	local image = Theme.image(name)
	local icon
	if image then
		icon = Theme.new("ImageLabel", { Image = image, ScaleType = Enum.ScaleType.Fit })
	else
		icon = Theme.new("TextLabel", { Text = fallback, TextScaled = true, FontFace = Theme.FontFace, TextColor3 = C.White })
	end
	icon.Name = props.Name or "Icon"
	for key, value in props do
		if key ~= "Name" and not (key == "TextColor3" and image) then
			(icon :: any)[key] = value
		end
	end
	return icon
end

------------------------------------------------------------------ Botones

export type ButtonProps = {
	Text: string?,
	Color: string?,
	Size: UDim2,
	Position: UDim2?,
	AnchorPoint: Vector2?,
	Parent: Instance?,
	TextSize: number?,
	LayoutOrder: number?,
	OnClick: (() -> ())?,
	Name: string?,
	Stroke: number?,
	ZIndex: number?,
}

local function press(button: GuiButton)
	local scale = Theme.new("UIScale", { Name = "PressScale", Parent = button })
	button.MouseButton1Down:Connect(function()
		Theme.tween(scale, Theme.Fast, { Scale = 0.93 })
	end)
	local function up()
		Theme.tween(scale, Theme.Pop, { Scale = 1 })
	end
	button.MouseButton1Up:Connect(up)
	button.MouseLeave:Connect(up)
	button.SelectionGained:Connect(function()
		Theme.tween(scale, Theme.Fast, { Scale = 1.06 })
	end)
	button.SelectionLost:Connect(up)
end
Kit.press = press

-- Botón con cara de color y texto blanco con borde. Devuelve (botón, etiqueta).
function Kit.button(props: ButtonProps): (TextButton, TextLabel)
	local button = Theme.new("TextButton", {
		Name = props.Name or "Button",
		Size = props.Size,
		Position = props.Position or UDim2.new(),
		AnchorPoint = props.AnchorPoint or Vector2.zero,
		LayoutOrder = props.LayoutOrder or 0,
		Selectable = true,
		Text = "",
		ZIndex = props.ZIndex or 1,
		Parent = props.Parent,
	})
	Kit.face(button, props.Color or "Lime", { Stroke = props.Stroke })
	local label = Kit.label({ Text = props.Text or "", TextSize = props.TextSize or 24, Size = UDim2.new(1, -10, 1, -4), Position = UDim2.fromOffset(5, 2), Scaled = true, ZIndex = button.ZIndex + 1, Parent = button })
	press(button)
	if props.OnClick then
		local onClick = props.OnClick
		button.Activated:Connect(function()
			Kit.sound(Kit.CLICK, 0.4)
			onClick()
		end)
	end
	return button, label
end

-- Ícono de Robux (hexágono) con el número
function Kit.robux(parent: Instance, price: number | string, size: number, color: Color3?, zIndex: number?): Frame
	local holder = Theme.new("Frame", { Name = "Price", Size = UDim2.new(1, 0, 0, size), ZIndex = zIndex or 1, Parent = parent })
	Theme.list(holder, 3, true, Enum.HorizontalAlignment.Center)
	Kit.icon("robux", "⬢", { Size = UDim2.fromOffset(size, size), LayoutOrder = 1, TextColor3 = C.Robux, ZIndex = zIndex or 1, Parent = holder })
	local label = Kit.label({ Text = tostring(price), TextSize = size, Size = UDim2.fromOffset(0, size), LayoutOrder = 2, Wrapped = false, Color = color or C.White, ZIndex = zIndex or 1, Parent = holder })
	label.AutomaticSize = Enum.AutomaticSize.X
	return holder
end

-- Botón de precio: Cash = verde lima con "$100"; Robux = morado con el hexágono verde y el número
function Kit.priceButton(kind: string, amount: number, props: ButtonProps): (TextButton, TextLabel)
	if kind == "Cash" then
		props.Color = props.Color or "Lime"
		props.Text = "$" .. Format(amount)
		return Kit.button(props)
	end
	props.Color = props.Color or "Purple"
	props.Text = ""
	local button, label = Kit.button(props)
	local size = math.floor((props.TextSize or 24) * 1.05)
	local price = Kit.robux(button, amount, size, C.White, button.ZIndex + 1)
	price.AnchorPoint = Vector2.new(0.5, 0.5)
	price.Position = UDim2.fromScale(0.5, 0.5)
	label.Visible = false
	return button, label
end

-- Casilla grande del HUD (Shop, Pass, Rebirth, Index…): cara de color, ícono grande y nombre abajo
function Kit.tile(name: string, color: string, icon: string, fallback: string, size: number, parent: Instance, onClick: () -> ()): TextButton
	local button = Theme.new("TextButton", { Name = name, Size = UDim2.fromOffset(size, size), Text = "", Selectable = true, Parent = parent })
	Kit.face(button, color)
	Kit.icon(icon, fallback, { Size = UDim2.fromScale(0.82, 0.74), Position = UDim2.fromScale(0.09, 0.01), ZIndex = 2, Parent = button })
	local captionHeight = math.floor(size * 0.32)
	Kit.label({ Name = "Caption", Text = name, TextSize = math.floor(size * 0.25), Size = UDim2.new(1, 8, 0, captionHeight), Position = UDim2.new(0, -4, 1, -captionHeight + 2), Scaled = true, ZIndex = 3, Parent = button })
	press(button)
	button.Activated:Connect(function()
		Kit.sound(Kit.CLICK, 0.4)
		onClick()
	end)
	return button
end

-- Puntito rojo con "!" (hay algo para cobrar)
function Kit.badge(parent: GuiObject, size: number?): Frame
	local s = size or 26
	local badge = Theme.new("Frame", { Name = "Badge", Size = UDim2.fromOffset(s, s), AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(1, -2, 0, 2), BackgroundColor3 = Color3.fromRGB(235, 40, 60), BackgroundTransparency = 0, ZIndex = 8, Visible = false, Parent = parent })
	Theme.corner(badge, s)
	Theme.stroke(badge, 2.5, C.White)
	Kit.label({ Text = "!", TextSize = math.floor(s * 0.8), Stroke = 0, ZIndex = 9, Parent = badge })
	return badge
end

------------------------------------------------------------------ Paneles

-- Fila oscura con borde gris (dentro de las ventanas). Title = texto sobre el borde de arriba.
function Kit.card(props: { Size: UDim2, Position: UDim2?, Parent: Instance?, LayoutOrder: number?, Title: string?, Name: string? }): Frame
	local card = Theme.new("Frame", {
		Name = props.Name or "Card",
		Size = props.Size,
		Position = props.Position or UDim2.new(),
		BackgroundColor3 = C.Card,
		BackgroundTransparency = 0.42,
		LayoutOrder = props.LayoutOrder or 0,
		Parent = props.Parent,
	})
	Theme.corner(card, 4)
	Theme.stroke(card, 2, C.CardStroke)
	if props.Title then
		Kit.label({ Name = "CardTitle", Text = props.Title, TextSize = 18, Size = UDim2.new(1, 0, 0, 22), Position = UDim2.fromOffset(0, -12), ZIndex = 3, Parent = card })
	end
	return card
end

function Kit.scroll(props: { [string]: any }): ScrollingFrame
	local scroll = Theme.new("ScrollingFrame", {
		ScrollBarThickness = 8,
		ScrollBarImageColor3 = Color3.fromRGB(205, 205, 212),
		ScrollBarImageTransparency = 0.1,
		CanvasSize = UDim2.new(),
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		ScrollingDirection = Enum.ScrollingDirection.Y,
		VerticalScrollBarInset = Enum.ScrollBarInset.ScrollBar,
		Selectable = false,
	})
	for key, value in props do
		(scroll :: any)[key] = value
	end
	return scroll
end

-- Barra como la de nivel: borde negro, relleno naranja con franjas y vacío claro con studs. set(fracción, izq, der)
function Kit.bar(size: UDim2, parent: Instance?, fill: { Color3 }?): (Frame, (number, string?, string?) -> ())
	local outer = Theme.new("Frame", { Name = "Bar", Size = size, BackgroundColor3 = Color3.fromRGB(236, 236, 240), BackgroundTransparency = 0, ClipsDescendants = false, Parent = parent })
	Theme.corner(outer, 3)
	Theme.stroke(outer, 3, C.Outline)
	local studs = Theme.image("studs")
	if studs then
		Theme.new("ImageLabel", { Image = studs, ScaleType = Enum.ScaleType.Tile, TileSize = UDim2.fromOffset(16, 16), Size = UDim2.fromScale(1, 1), ImageTransparency = 0.7, ImageColor3 = Color3.fromRGB(170, 170, 180), Parent = outer })
	end
	local colors = fill or { C.OrangeTop, C.Orange, Color3.fromRGB(235, 130, 0) }
	local bar = Theme.new("Frame", { Name = "Fill", Size = UDim2.fromScale(0, 1), BackgroundColor3 = C.White, BackgroundTransparency = 0, ZIndex = 2, ClipsDescendants = true, Parent = outer })
	Theme.corner(bar, 3)
	Theme.gradient(bar, ColorSequence.new({ ColorSequenceKeypoint.new(0, colors[1]), ColorSequenceKeypoint.new(0.5, colors[2]), ColorSequenceKeypoint.new(1, colors[3]) }), 90)
	local stripes = Theme.new("Frame", { Size = UDim2.fromScale(1, 1), BackgroundColor3 = C.White, BackgroundTransparency = 0, ZIndex = 3, Parent = bar })
	local seq = {}
	for i = 0, 12 do
		table.insert(seq, NumberSequenceKeypoint.new(i / 12, if i % 2 == 0 then 1 else 0.8))
	end
	Theme.new("UIGradient", { Transparency = NumberSequence.new(seq), Rotation = 30, Parent = stripes })
	local left = Kit.label({ Name = "Left", TextSize = 18, Size = UDim2.new(0.6, -10, 1, -2), Position = UDim2.fromOffset(10, 1), XAlign = Enum.TextXAlignment.Left, Scaled = true, ZIndex = 4, Parent = outer })
	local right = Kit.label({ Name = "Right", TextSize = 18, Size = UDim2.new(0.5, -10, 1, -2), Position = UDim2.new(0.5, 0, 0, 1), XAlign = Enum.TextXAlignment.Right, Scaled = true, ZIndex = 4, Parent = outer })
	return outer, function(fraction: number, leftText: string?, rightText: string?)
		Theme.tween(bar, Theme.Smooth, { Size = UDim2.fromScale(math.clamp(fraction, 0, 1), 1) })
		bar.Visible = fraction > 0.005
		left.Text = leftText or ""
		right.Text = rightText or ""
	end
end

return Kit
