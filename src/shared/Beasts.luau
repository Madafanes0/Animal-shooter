-- Construye animales de bloques (cuerpo, cabeza, patas) a partir de su config
local Config = require(script.Parent.Config)

local Beasts = {}

local function part(model: Model, name: string, size: Vector3, cf: CFrame, color: Color3): Part
	local p = Instance.new("Part")
	p.Name = name
	p.Size = size
	p.CFrame = cf
	p.Color = color
	p.Material = Enum.Material.SmoothPlastic
	p.Anchored = true
	p.CanCollide = false
	p.CanQuery = false
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.Parent = model
	return p
end

-- Devuelve el modelo con los pies en `cf`
function Beasts.build(animalId: number, cf: CFrame, withLabel: boolean?): Model
	local a = Config.Animals[animalId]
	local rar = Config.Rarities[a.rarity]
	local s = rar.scale
	local m = Instance.new("Model")
	m.Name = a.name

	local legH = 1 * s
	local body = part(m, "Body", Vector3.new(2, 1.5, 3) * s, cf * CFrame.new(0, legH + 0.75 * s, 0), a.color)
	m.PrimaryPart = body
	local head = part(m, "Head", Vector3.new(1.4, 1.4, 1.4) * s, cf * CFrame.new(0, legH + 1.6 * s, -1.7 * s), a.color2)
	for _, x in { -0.35, 0.35 } do
		part(m, "Eye", Vector3.new(0.25, 0.3, 0.1) * s, head.CFrame * CFrame.new(x * s, 0.2 * s, -0.72 * s), Color3.new(0, 0, 0))
	end
	part(m, "Snout", Vector3.new(0.7, 0.45, 0.4) * s, head.CFrame * CFrame.new(0, -0.3 * s, -0.8 * s), a.color)
	for _, x in { -0.7, 0.7 } do
		for _, z in { -1, 1 } do
			part(m, "Leg", Vector3.new(0.5, legH, 0.5) * Vector3.new(s, 1, s), cf * CFrame.new(x * s, legH / 2, z * s), a.color2)
		end
	end
	part(m, "Tail", Vector3.new(0.35, 0.35, 0.9) * s, cf * CFrame.new(0, legH + 1.1 * s, 1.8 * s), a.color2)
	if a.rarity >= 3 then
		for _, x in { -0.45, 0.45 } do
			part(m, "Horn", Vector3.new(0.25, 0.8, 0.25) * s, head.CFrame * CFrame.new(x * s, 0.95 * s, 0), rar.color)
		end
	end
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
		bb.StudsOffset = Vector3.new(0, 3 * s, 0)
		bb.AlwaysOnTop = false
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
		label(a.name, 22, Color3.new(1, 1, 1), 18)
		label("$" .. a.income .. "/s", 44, Color3.fromRGB(90, 255, 90), 20)
		bb.Parent = body
	end

	return m
end

return Beasts
