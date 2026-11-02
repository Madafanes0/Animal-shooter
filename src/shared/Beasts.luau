-- Construye animales de bloques con detalle (ojos, orejas, patas, alas, aletas...) según su forma
local Config = require(script.Parent.Config)

local Beasts = {}

local WHITE = Color3.new(1, 1, 1)
local BLACK = Color3.fromRGB(20, 20, 25)
local BEAK = Color3.fromRGB(255, 170, 40)

local function lighten(c: Color3, t: number): Color3
	return c:Lerp(WHITE, t)
end

local function darken(c: Color3, t: number): Color3
	return c:Lerp(Color3.new(0, 0, 0), t)
end

type Builder = {
	model: Model,
	base: CFrame,
	s: number,
	add: (self: Builder, name: string, size: Vector3, offset: CFrame, color: Color3, shape: Enum.PartType?, material: Enum.Material?) -> Part,
}

local function newBuilder(model: Model, base: CFrame, s: number): Builder
	local b = { model = model, base = base, s = s } :: any
	function b:add(name, size, offset, color, shape, material)
		local p = Instance.new("Part")
		p.Name = name
		if shape then
			p.Shape = shape
		end
		p.Size = size * self.s
		p.CFrame = self.base * (offset.Rotation + offset.Position * self.s)
		p.Color = color
		p.Material = material or Enum.Material.SmoothPlastic
		p.Anchored = true
		p.CanCollide = false
		p.CanQuery = false
		p.CastShadow = true
		p.TopSurface = Enum.SurfaceType.Smooth
		p.BottomSurface = Enum.SurfaceType.Smooth
		p.Parent = self.model
		return p
	end
	return b
end

-- Ojo con blanco, pupila y brillo; `at` es el centro del ojo en coordenadas locales del modelo
local function eye(b: Builder, at: Vector3, size: number)
	b:add("EyeWhite", Vector3.new(size, size, 0.12), CFrame.new(at), WHITE)
	b:add("Pupil", Vector3.new(size * 0.55, size * 0.6, 0.14), CFrame.new(at + Vector3.new(0, -size * 0.1, -0.02)), BLACK)
	b:add("Shine", Vector3.new(size * 0.2, size * 0.2, 0.16), CFrame.new(at + Vector3.new(size * 0.15, size * 0.12, -0.04)), WHITE, nil, Enum.Material.Neon)
end

local function rarityExtras(b: Builder, a, headTop: Vector3)
	local rar = Config.Rarities[a.rarity]
	if a.rarity >= 3 then
		for _, x in { -0.4, 0.4 } do
			b:add("Horn", Vector3.new(0.22, 0.7, 0.22), CFrame.new(headTop + Vector3.new(x, 0.3, 0.1)) * CFrame.Angles(math.rad(-15), 0, math.rad(-x * 40)), lighten(rar.color, 0.2))
		end
	end
	if a.rarity >= 4 then
		b:add("Collar", Vector3.new(1.5, 0.25, 1.3), CFrame.new(headTop + Vector3.new(0, -1.25, 0.6)), rar.color, nil, Enum.Material.Neon)
	end
	if a.rarity >= 5 then
		local gold = Color3.fromRGB(255, 205, 50)
		b:add("Crown", Vector3.new(0.9, 0.3, 0.9), CFrame.new(headTop + Vector3.new(0, 0.2, 0)), gold, nil, Enum.Material.Metal)
		for i = 0, 3 do
			local ang = i * math.pi / 2
			b:add("CrownTip", Vector3.new(0.2, 0.35, 0.2), CFrame.new(headTop + Vector3.new(math.cos(ang) * 0.35, 0.5, math.sin(ang) * 0.35)), gold, nil, Enum.Material.Metal)
		end
	end
end

local function quad(b: Builder, a)
	local c1, c2 = a.color, a.color2
	local legH = 1
	-- Patas con pezuñas
	for _, x in { -0.65, 0.65 } do
		for _, z in { -0.95, 0.95 } do
			b:add("Leg", Vector3.new(0.5, legH, 0.5), CFrame.new(x, legH / 2 + 0.15, z), c2)
			b:add("Hoof", Vector3.new(0.58, 0.3, 0.62), CFrame.new(x, 0.15, z - 0.03), darken(c2, 0.45))
		end
	end
	b:add("Body", Vector3.new(2, 1.5, 3), CFrame.new(0, legH + 0.85, 0), c1)
	b:add("Belly", Vector3.new(1.6, 0.2, 2.4), CFrame.new(0, legH + 0.1, 0), lighten(c1, 0.55))
	if a.id % 3 == 0 then
		for i, off in { Vector3.new(0.6, 0.5, 0.6), Vector3.new(-0.5, 0.3, -0.5), Vector3.new(0.2, 0.6, -0.9) } do
			b:add("Spot" .. i, Vector3.new(0.6, 0.12, 0.6), CFrame.new(0, legH + 1.6, 0) * CFrame.new(off.X, 0.02, off.Z), darken(c1, 0.3))
		end
	end
	-- Cabeza
	local head = Vector3.new(0, legH + 1.75, -1.75)
	b:add("Neck", Vector3.new(0.9, 0.9, 0.8), CFrame.new(0, legH + 1.3, -1.35), c1)
	b:add("Head", Vector3.new(1.5, 1.35, 1.35), CFrame.new(head), c2)
	b:add("Snout", Vector3.new(0.95, 0.6, 0.55), CFrame.new(head + Vector3.new(0, -0.32, -0.85)), lighten(c2, 0.4))
	b:add("Nose", Vector3.new(0.4, 0.22, 0.12), CFrame.new(head + Vector3.new(0, -0.15, -1.14)), BLACK)
	b:add("Mouth", Vector3.new(0.5, 0.06, 0.12), CFrame.new(head + Vector3.new(0, -0.5, -1.13)), darken(c2, 0.6))
	eye(b, head + Vector3.new(-0.38, 0.2, -0.69), 0.38)
	eye(b, head + Vector3.new(0.38, 0.2, -0.69), 0.38)
	for _, x in { -0.55, 0.55 } do
		b:add("Ear", Vector3.new(0.4, 0.6, 0.18), CFrame.new(head + Vector3.new(x, 0.85, 0.1)) * CFrame.Angles(0, 0, math.rad(-x * 30)), c2)
		b:add("EarIn", Vector3.new(0.22, 0.38, 0.05), CFrame.new(head + Vector3.new(x, 0.82, -0.02)) * CFrame.Angles(0, 0, math.rad(-x * 30)), lighten(c1, 0.6))
	end
	b:add("Tail", Vector3.new(0.3, 0.3, 1), CFrame.new(0, legH + 1.35, 1.85) * CFrame.Angles(math.rad(35), 0, 0), c2)
	b:add("TailTip", Vector3.new(0.42, 0.42, 0.42), CFrame.new(0, legH + 1.7, 2.3), lighten(c2, 0.5))
	rarityExtras(b, a, head + Vector3.new(0, 0.7, 0))
end

local function bird(b: Builder, a)
	local c1, c2 = a.color, a.color2
	for _, x in { -0.35, 0.35 } do
		b:add("Leg", Vector3.new(0.16, 0.8, 0.16), CFrame.new(x, 0.45, 0), BEAK)
		b:add("Foot", Vector3.new(0.45, 0.1, 0.5), CFrame.new(x, 0.05, -0.15), BEAK)
	end
	b:add("Body", Vector3.new(1.8, 1.9, 2), CFrame.new(0, 1.8, 0), c1, Enum.PartType.Ball)
	b:add("Belly", Vector3.new(1.3, 1.4, 0.4), CFrame.new(0, 1.65, -0.8), lighten(c1, 0.6), Enum.PartType.Ball)
	for _, x in { -1, 1 } do
		b:add("Wing", Vector3.new(0.25, 1.2, 1.6), CFrame.new(x * 0.95, 1.95, 0.1) * CFrame.Angles(0, 0, math.rad(x * 15)), c2)
		b:add("WingTip", Vector3.new(0.2, 0.6, 0.8), CFrame.new(x * 1.05, 1.4, 0.6) * CFrame.Angles(0, 0, math.rad(x * 15)), darken(c2, 0.3))
	end
	for i, ang in { -20, 0, 20 } do
		b:add("Feather" .. i, Vector3.new(0.3, 0.12, 1), CFrame.new(math.rad(ang) * 1.2, 2, 1.3) * CFrame.Angles(math.rad(25), math.rad(ang), 0), c2)
	end
	local head = Vector3.new(0, 3.05, -0.4)
	b:add("Head", Vector3.new(1.25, 1.2, 1.2), CFrame.new(head), c1)
	b:add("Beak", Vector3.new(0.5, 0.35, 0.7), CFrame.new(head + Vector3.new(0, -0.1, -0.85)), BEAK)
	b:add("BeakTip", Vector3.new(0.3, 0.2, 0.3), CFrame.new(head + Vector3.new(0, -0.22, -1.2)), darken(BEAK, 0.25))
	eye(b, head + Vector3.new(-0.32, 0.18, -0.61), 0.34)
	eye(b, head + Vector3.new(0.32, 0.18, -0.61), 0.34)
	b:add("Crest", Vector3.new(0.18, 0.55, 0.6), CFrame.new(head + Vector3.new(0, 0.8, 0.1)) * CFrame.Angles(math.rad(-20), 0, 0), c2)
	rarityExtras(b, a, head + Vector3.new(0, 0.6, 0))
end

local function serpent(b: Builder, a)
	local c1, c2 = a.color, a.color2
	local segments = { { 1.5, 0 }, { 1.35, 1.2 }, { 1.15, 2.3 }, { 0.9, 3.25 }, { 0.65, 4 } }
	for i, seg in segments do
		local size, z = seg[1], seg[2]
		b:add("Seg" .. i, Vector3.new(size * 1.1, size, size * 1.1), CFrame.new(0, size / 2 + 0.05, z), if i % 2 == 0 then c2 else c1)
		b:add("Stripe" .. i, Vector3.new(size * 0.6, 0.12, size * 0.5), CFrame.new(0, size + 0.08, z), lighten(c1, 0.5))
	end
	b:add("TailFin", Vector3.new(1.4, 0.15, 0.8), CFrame.new(0, 0.35, 4.6), c2)
	for _, x in { -1, 1 } do
		b:add("Fin", Vector3.new(0.9, 0.12, 0.6), CFrame.new(x * 0.95, 0.5, 0.4) * CFrame.Angles(0, 0, math.rad(x * -20)), c2)
	end
	b:add("DorsalFin", Vector3.new(0.15, 0.8, 1), CFrame.new(0, 1.85, 0.6) * CFrame.Angles(math.rad(-20), 0, 0), c2)
	local head = Vector3.new(0, 1.25, -1.2)
	b:add("Head", Vector3.new(1.6, 1.3, 1.5), CFrame.new(head), c1)
	b:add("Jaw", Vector3.new(1.3, 0.35, 1.1), CFrame.new(head + Vector3.new(0, -0.7, -0.15)), lighten(c1, 0.4))
	for _, x in { -0.4, 0.4 } do
		b:add("Fang", Vector3.new(0.14, 0.3, 0.14), CFrame.new(head + Vector3.new(x * 0.8, -0.6, -0.65)), WHITE)
	end
	eye(b, head + Vector3.new(-0.42, 0.25, -0.76), 0.38)
	eye(b, head + Vector3.new(0.42, 0.25, -0.76), 0.38)
	rarityExtras(b, a, head + Vector3.new(0, 0.65, 0))
end

local function bug(b: Builder, a)
	local c1, c2 = a.color, a.color2
	for i, z in { -0.6, 0, 0.6 } do
		for _, x in { -1, 1 } do
			b:add("Leg" .. i, Vector3.new(1.1, 0.16, 0.16), CFrame.new(x * 1.15, 0.45, z) * CFrame.Angles(0, 0, math.rad(x * 30)), darken(c2, 0.3))
		end
	end
	b:add("Body", Vector3.new(2, 1, 2.2), CFrame.new(0, 0.9, 0.2), c1)
	b:add("Shell", Vector3.new(2.1, 0.5, 2), CFrame.new(0, 1.5, 0.3), c2)
	b:add("ShellLine", Vector3.new(0.1, 0.52, 2.02), CFrame.new(0, 1.52, 0.3), darken(c2, 0.4))
	local head = Vector3.new(0, 1, -1.3)
	b:add("Head", Vector3.new(1.3, 0.9, 0.9), CFrame.new(head), c1)
	eye(b, head + Vector3.new(-0.35, 0.2, -0.47), 0.36)
	eye(b, head + Vector3.new(0.35, 0.2, -0.47), 0.36)
	for _, x in { -1, 1 } do
		b:add("Claw", Vector3.new(0.5, 0.4, 0.7), CFrame.new(x * 0.95, 0.75, -1.85), c2)
		b:add("Pincer", Vector3.new(0.18, 0.3, 0.5), CFrame.new(x * 1.1, 0.95, -2.3), darken(c2, 0.3))
		b:add("Antenna", Vector3.new(0.1, 0.9, 0.1), CFrame.new(head + Vector3.new(x * 0.3, 0.75, -0.2)) * CFrame.Angles(math.rad(-25), 0, math.rad(x * -20)), darken(c2, 0.3))
	end
	rarityExtras(b, a, head + Vector3.new(0, 0.45, 0))
end

local builders = { quad = quad, bird = bird, serpent = serpent, bug = bug }

-- Devuelve el modelo con los pies en `cf`, mirando hacia -Z de `cf`
function Beasts.build(animalId: number, cf: CFrame, withLabel: boolean?): Model
	local a = Config.Animals[animalId]
	local rar = Config.Rarities[a.rarity]
	local s = rar.scale
	local m = Instance.new("Model")
	m.Name = a.name
	local b = newBuilder(m, cf, s)
	builders[a.kind](b, a)
	local body = m:FindFirstChild("Body") or m:FindFirstChild("Seg1")
	m.PrimaryPart = body :: BasePart

	if a.rarity >= 5 then
		local light = Instance.new("PointLight")
		light.Color = rar.color
		light.Range = 14
		light.Brightness = 2
		light.Parent = body
		local sparkle = Instance.new("Sparkles")
		sparkle.SparkleColor = rar.color
		sparkle.Parent = body
	end

	if withLabel then
		local bb = Instance.new("BillboardGui")
		bb.Size = UDim2.fromOffset(200, 70)
		bb.StudsOffset = Vector3.new(0, 3.5 * s, 0)
		bb.MaxDistance = 80
		bb.Adornee = body
		local function label(text: string, y: number, color: Color3, size: number)
			local t = Instance.new("TextLabel")
			t.BackgroundTransparency = 1
			t.Size = UDim2.new(1, 0, 0, size)
			t.Position = UDim2.fromOffset(0, y)
			t.Font = Enum.Font.LuckiestGuy
			t.TextSize = size
			t.TextColor3 = color
			t.TextStrokeTransparency = 0
			t.Text = text
			t.Parent = bb
		end
		label(rar.name, 0, rar.color, 20)
		label(a.name, 22, WHITE, 18)
		label("$" .. a.income .. "/s", 44, Color3.fromRGB(90, 255, 90), 20)
		bb.Parent = body
	end

	return m
end

return Beasts
