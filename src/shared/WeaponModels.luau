-- Modelos de las 20 armas hechos con partes. Todas apuntan hacia -Z y se agarran del "Handle".
local Config = require(script.Parent.Config)

local WeaponModels = {}

local WOOD = Color3.fromRGB(140, 85, 45)
local DARK_WOOD = Color3.fromRGB(95, 55, 30)
local STEEL = Color3.fromRGB(70, 72, 80)
local GOLD = Color3.fromRGB(255, 200, 50)
local RUBBER = Color3.fromRGB(200, 60, 50)

local function add(model: Model, handle: BasePart?, size: Vector3, offset: CFrame, color: Color3, material: Enum.Material?, shape: Enum.PartType?): Part
	local p = Instance.new("Part")
	if shape then
		p.Shape = shape
	end
	p.Size = size
	p.Color = color
	p.Material = material or Enum.Material.SmoothPlastic
	p.CanCollide = false
	p.CanQuery = false
	p.Massless = true
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	if handle then
		p.CFrame = handle.CFrame * offset
		local w = Instance.new("WeldConstraint")
		w.Part0 = handle
		w.Part1 = p
		w.Parent = p
	else
		p.Name = "Grip"
		p.CFrame = offset
	end
	p.Parent = model
	return p
end

local function slingshot(m: Model, h: BasePart)
	for _, x in { -1, 1 } do
		add(m, h, Vector3.new(0.25, 0.9, 0.25), CFrame.new(x * 0.3, 0.75, 0) * CFrame.Angles(0, 0, math.rad(-x * 25)), WOOD)
		add(m, h, Vector3.new(0.08, 0.08, 0.9), CFrame.new(x * 0.42, 1.15, 0.35) * CFrame.Angles(0, math.rad(x * 20), 0), RUBBER)
	end
	add(m, h, Vector3.new(0.35, 0.3, 0.15), CFrame.new(0, 1.15, 0.8), DARK_WOOD)
	add(m, h, Vector3.new(0.3, 0.3, 0.3), CFrame.new(0, 1.15, 0.7), Color3.fromRGB(130, 130, 130), Enum.Material.Slate, Enum.PartType.Ball)
end

local function sling(m: Model, h: BasePart)
	add(m, h, Vector3.new(0.08, 1.6, 0.08), CFrame.new(0, -0.8, 0), Color3.fromRGB(200, 170, 110), Enum.Material.Fabric)
	add(m, h, Vector3.new(0.45, 0.2, 0.45), CFrame.new(0, -1.65, 0), DARK_WOOD, Enum.Material.Fabric)
	add(m, h, Vector3.new(0.35, 0.35, 0.35), CFrame.new(0, -1.5, 0), Color3.fromRGB(130, 130, 130), Enum.Material.Slate, Enum.PartType.Ball)
end

local function boomerang(m: Model, h: BasePart)
	add(m, h, Vector3.new(0.25, 0.15, 1.6), CFrame.new(-0.4, 0, -0.5) * CFrame.Angles(0, math.rad(-40), 0), WOOD)
	add(m, h, Vector3.new(0.25, 0.15, 1.6), CFrame.new(0.4, 0, -0.5) * CFrame.Angles(0, math.rad(40), 0), WOOD)
	add(m, h, Vector3.new(0.27, 0.17, 0.4), CFrame.new(0, 0, -1.05), RUBBER)
end

local function blowgun(m: Model, h: BasePart)
	add(m, h, Vector3.new(0.2, 3.4, 0.2), CFrame.new(0, 0, -1.2) * CFrame.Angles(math.rad(90), 0, 0), Color3.fromRGB(160, 200, 90), Enum.Material.Wood, Enum.PartType.Cylinder)
	add(m, h, Vector3.new(0.28, 0.28, 0.4), CFrame.new(0, 0, 0.5), RUBBER)
end

local function bow(color: Color3, material: Enum.Material?)
	return function(m: Model, h: BasePart)
		add(m, h, Vector3.new(0.2, 1.2, 0.2), CFrame.new(0, 0.9, -0.15) * CFrame.Angles(math.rad(-15), 0, 0), color, material)
		add(m, h, Vector3.new(0.2, 1.2, 0.2), CFrame.new(0, -0.9, -0.15) * CFrame.Angles(math.rad(15), 0, 0), color, material)
		add(m, h, Vector3.new(0.04, 3.2, 0.04), CFrame.new(0, 0, 0.15), Color3.new(1, 1, 1))
		add(m, h, Vector3.new(0.08, 0.08, 2), CFrame.new(0, 0, -0.6), WOOD)
		add(m, h, Vector3.new(0.18, 0.18, 0.3), CFrame.new(0, 0, -1.65), STEEL)
	end
end

local function spear(m: Model, h: BasePart)
	add(m, h, Vector3.new(0.15, 0.15, 4), CFrame.new(0, 0.1, -0.8), WOOD)
	add(m, h, Vector3.new(0.35, 0.1, 0.7), CFrame.new(0, 0.1, -3.1), STEEL, Enum.Material.Metal)
end

local function crossbow(color: Color3, material: Enum.Material?)
	return function(m: Model, h: BasePart)
		add(m, h, Vector3.new(0.3, 0.3, 2.4), CFrame.new(0, 0.3, -0.7), color, material)
		add(m, h, Vector3.new(2.4, 0.15, 0.2), CFrame.new(0, 0.35, -1.6), STEEL, Enum.Material.Metal)
		add(m, h, Vector3.new(2.2, 0.04, 0.04), CFrame.new(0, 0.4, -1.1), Color3.new(1, 1, 1))
		add(m, h, Vector3.new(0.08, 0.08, 1.6), CFrame.new(0, 0.5, -1.2), DARK_WOOD)
	end
end

type GunSpec = {
	barrel: number,
	stock: Color3,
	metal: Color3,
	double: boolean?,
	scope: boolean?,
	neon: Color3?,
	bulky: number?,
	harpoon: boolean?,
}

local function gun(spec: GunSpec)
	return function(m: Model, h: BasePart)
		local thick = spec.bulky or 1
		add(m, h, Vector3.new(0.3, 0.45, 1.2), CFrame.new(0, 0.25, 0.55), spec.stock)
		add(m, h, Vector3.new(0.35 * thick, 0.4 * thick, 1.2), CFrame.new(0, 0.45, -0.4), spec.metal, Enum.Material.Metal)
		local offsets = if spec.double then { -0.09, 0.09 } else { 0 }
		for _, x in offsets do
			add(m, h, Vector3.new(spec.barrel, 0.18 * thick, 0.18 * thick), CFrame.new(x, 0.55, -1 - spec.barrel / 2) * CFrame.Angles(0, math.rad(90), 0), spec.metal, Enum.Material.Metal, Enum.PartType.Cylinder)
		end
		if spec.scope then
			add(m, h, Vector3.new(1.1, 0.22, 0.22), CFrame.new(0, 0.85, -0.6) * CFrame.Angles(0, math.rad(90), 0), Color3.fromRGB(30, 30, 35), Enum.Material.Metal, Enum.PartType.Cylinder)
		end
		if spec.neon then
			add(m, h, Vector3.new(0.12, 0.12, spec.barrel * 0.8), CFrame.new(0, 0.72 * thick, -1 - spec.barrel / 2), spec.neon, Enum.Material.Neon)
			add(m, h, Vector3.new(0.3 * thick, 0.3 * thick, 0.3 * thick), CFrame.new(0, 0.55, -1.05 - spec.barrel), spec.neon, Enum.Material.Neon, Enum.PartType.Ball)
		end
		if spec.harpoon then
			add(m, h, Vector3.new(0.3, 0.1, 0.5), CFrame.new(0, 0.55, -1.3 - spec.barrel), STEEL, Enum.Material.Metal)
		end
	end
end

local shapes = {
	slingshot,
	sling,
	boomerang,
	blowgun,
	bow(WOOD),
	spear,
	bow(DARK_WOOD),
	crossbow(WOOD),
	gun({ barrel = 3, stock = WOOD, metal = STEEL }),
	gun({ barrel = 1.6, stock = DARK_WOOD, metal = Color3.fromRGB(150, 120, 80) }),
	gun({ barrel = 0.9, stock = DARK_WOOD, metal = Color3.fromRGB(170, 170, 180) }),
	gun({ barrel = 2.6, stock = WOOD, metal = STEEL, scope = true }),
	gun({ barrel = 2.2, stock = DARK_WOOD, metal = STEEL, double = true }),
	gun({ barrel = 2.2, stock = Color3.fromRGB(40, 90, 140), metal = STEEL, harpoon = true }),
	gun({ barrel = 3.4, stock = Color3.fromRGB(60, 70, 50), metal = Color3.fromRGB(40, 40, 45), scope = true }),
	crossbow(GOLD, Enum.Material.Metal),
	gun({ barrel = 2.2, stock = Color3.fromRGB(230, 230, 240), metal = Color3.fromRGB(60, 60, 90), neon = Color3.fromRGB(80, 220, 255) }),
	gun({ barrel = 3.2, stock = Color3.fromRGB(30, 30, 40), metal = Color3.fromRGB(80, 80, 100), neon = Color3.fromRGB(120, 255, 120), scope = true }),
	gun({ barrel = 2.4, stock = Color3.fromRGB(80, 30, 20), metal = Color3.fromRGB(60, 40, 35), neon = Color3.fromRGB(255, 120, 30), bulky = 1.8 }),
	gun({ barrel = 2.8, stock = Color3.fromRGB(40, 20, 70), metal = Color3.fromRGB(70, 40, 120), neon = Color3.fromRGB(255, 90, 255), bulky = 2 }),
}

-- Modelo suelto (soldado al Handle). Si `anchored`, queda fijo para exhibir en la tienda.
function WeaponModels.build(index: number, cf: CFrame?, anchored: boolean?): Model
	local m = Instance.new("Model")
	m.Name = Config.Weapons[index].name
	local h = add(m, nil, Vector3.new(0.3, 0.9, 0.3), cf or CFrame.new(), DARK_WOOD)
	m.PrimaryPart = h
	shapes[index](m, h)
	if anchored then
		for _, p in m:GetDescendants() do
			if p:IsA("BasePart") then
				p.Anchored = true
			end
		end
	end
	return m
end

-- Tool que el jugador lleva en la mano
function WeaponModels.tool(index: number): Tool
	local tool = Instance.new("Tool")
	tool.Name = Config.Weapons[index].name
	tool.CanBeDropped = false
	tool.RequiresHandle = true
	tool.Grip = CFrame.new(0, -0.2, 0)
	tool:SetAttribute("WeaponIndex", index)
	local m = WeaponModels.build(index)
	for _, p in m:GetChildren() do
		p.Parent = tool
	end
	m:Destroy()
	return tool
end

return WeaponModels
