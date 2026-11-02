-- Modelos de animales y armas: usa los de Blender (ReplicatedStorage.Assets, los carga el servidor)
-- y, si todavía no están, los de bloques de Beasts/WeaponModels. Aplica las variantes (Golden, Diamond, Rainbow).
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CollectionService = game:GetService("CollectionService")
local Config = require(script.Parent.Config)
local Beasts = require(script.Parent.Beasts)
local WeaponModels = require(script.Parent.WeaponModels)

local Models = {}

local function asset(kind: string, key: number): Model?
	local root = ReplicatedStorage:FindFirstChild("Assets")
	local folder = root and root:FindFirstChild(kind)
	local m = folder and folder:FindFirstChild(tostring(key))
	return if m then (m :: Model):Clone() else nil
end

local function setAnchored(m: Model, anchored: boolean)
	for _, p in m:GetDescendants() do
		if p:IsA("BasePart") then
			p.Anchored = anchored
			p.CanCollide = false
			p.CanQuery = false
			p.Massless = true
		end
	end
end

-- Pinta todo el modelo de un color/material (quita la textura de la paleta)
local function paint(m: Model, color: Color3, material: Enum.Material, transparency: number?)
	for _, p in m:GetDescendants() do
		if p:IsA("BasePart") and p.Transparency < 1 then
			if p:IsA("MeshPart") then
				p.TextureID = ""
			end
			p.Color = color
			p.Material = material
			p.Transparency = transparency or 0
		end
	end
end

local function applyVariant(m: Model, variant: number)
	local v = Config.Variants[variant]
	if variant == 0 or not v then
		return
	end
	if variant == 1 then
		paint(m, v.color, Enum.Material.Foil)
	elseif variant == 2 then
		paint(m, v.color, Enum.Material.Glass, 0.15)
	else
		paint(m, v.color, Enum.Material.Neon)
		CollectionService:AddTag(m, "Rainbow") -- el cliente le cambia el color
	end
	local root = m.PrimaryPart or m:FindFirstChildWhichIsA("BasePart")
	if root then
		local sparkle = Instance.new("ParticleEmitter")
		sparkle.Texture = "rbxasset://textures/particles/sparkles_main.dds"
		sparkle.Color = ColorSequence.new(v.color)
		sparkle.Rate = 6 * variant
		sparkle.Lifetime = NumberRange.new(0.6, 1.2)
		sparkle.Size = NumberSequence.new(0.6, 0)
		sparkle.Speed = NumberRange.new(1, 3)
		sparkle.SpreadAngle = Vector2.new(180, 180)
		sparkle.LightEmission = 1
		sparkle.Parent = root
	end
end

-- Animal (entrada con variante) con los pies en `cf`, mirando hacia -Z de `cf`
function Models.animal(entry: number, cf: CFrame, withLabel: boolean?): Model
	local a, variant = Config.decode(entry)
	local m = asset("Animals", a.id)
	if m then
		setAnchored(m, true)
		m:PivotTo(cf)
	else
		m = Beasts.build(a.id, cf, false)
	end
	local model = m :: Model
	applyVariant(model, variant)
	if withLabel then
		local rar = Config.Rarities[a.rarity]
		local _, size = model:GetBoundingBox()
		local bb = Instance.new("BillboardGui")
		bb.Size = UDim2.fromOffset(200, 70)
		bb.StudsOffset = Vector3.new(0, size.Y / 2 + 2, 0)
		bb.MaxDistance = 80
		bb.Adornee = model.PrimaryPart or model:FindFirstChildWhichIsA("BasePart")
		local function label(text: string, y: number, color: Color3, sz: number)
			local t = Instance.new("TextLabel")
			t.BackgroundTransparency = 1
			t.Size = UDim2.new(1, 0, 0, sz)
			t.Position = UDim2.fromOffset(0, y)
			t.Font = Enum.Font.LuckiestGuy
			t.TextSize = sz
			t.TextColor3 = color
			t.TextStrokeTransparency = 0
			t.Text = text
			t.Parent = bb
		end
		label(if variant > 0 then Config.Variants[variant].name .. " · " .. rar.name else rar.name, 0, if variant > 0 then Config.Variants[variant].color else rar.color, 20)
		label(a.name, 22, Color3.new(1, 1, 1), 18)
		label("$" .. Config.entryIncome(entry) .. "/s", 44, Color3.fromRGB(90, 255, 90), 20)
		bb.Parent = bb.Adornee
	end
	return model
end

-- Convierte un modelo en Tool: todo soldado a un Handle invisible (en `handleAt` o en el centro)
local function toTool(m: Model, name: string, grip: CFrame, handleAt: CFrame?): Tool
	local tool = Instance.new("Tool")
	tool.Name = name
	tool.CanBeDropped = false
	local cf = handleAt or m:GetBoundingBox()
	local handle = Instance.new("Part")
	handle.Name = "Handle"
	handle.Size = Vector3.new(0.4, 0.4, 0.4)
	handle.Transparency = 1
	handle.CanCollide = false
	handle.Massless = true
	handle.CFrame = cf
	handle.Parent = tool
	for _, p in m:GetDescendants() do
		if p:IsA("BasePart") then
			p.Anchored = false
			p.CanCollide = false
			p.Massless = true
			local w = Instance.new("WeldConstraint")
			w.Part0 = handle
			w.Part1 = p
			w.Parent = p
		end
	end
	for _, child in m:GetChildren() do
		child.Parent = tool
	end
	m:Destroy()
	tool.Grip = grip
	return tool
end

-- Animal cargado en la mano (más chico)
function Models.animalTool(entry: number): Tool
	local m = Models.animal(entry, CFrame.new(), false)
	m:ScaleTo(m:GetScale() * 0.5)
	local tool = toTool(m, Config.entryName(entry), CFrame.new(0, 0, 1) * CFrame.Angles(0, math.rad(180), 0))
	tool:SetAttribute("AnimalId", entry)
	return tool
end

-- Modelo base del arma (las exclusivas usan otro modelo pintado de su color)
local function weaponModel(index: number, cf: CFrame, anchored: boolean): Model
	local w = Config.Weapons[index]
	local base = w.base or index
	local m = asset("Weapons", base)
	if m then
		setAnchored(m, anchored)
		m:PivotTo(cf)
	else
		m = WeaponModels.build(base, cf, anchored)
	end
	local model = m :: Model
	if w.exclusive then
		paint(model, w.color, Enum.Material.Neon)
	end
	return model
end

function Models.weapon(index: number, cf: CFrame): Model
	return weaponModel(index, cf, true)
end

function Models.weaponTool(index: number): Tool
	local m = weaponModel(index, CFrame.new(), false)
	-- El pivote de los assets está en la empuñadura; el de los de bloques en su Handle
	local tool = toTool(m, Config.Weapons[index].name, CFrame.new(), m:GetPivot())
	tool:SetAttribute("WeaponIndex", index)
	return tool
end

return Models
