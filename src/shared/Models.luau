-- Modelos de animales y armas: usa los de Blender (ReplicatedStorage.Assets, los carga el servidor)
-- y, si todavía no están, los de bloques de Beasts/WeaponModels.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
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

-- Animal con los pies en `cf`, mirando hacia -Z de `cf`. Los assets ya vienen con el pivote en los pies
-- y escalados a su tamaño (ver server/Assets).
function Models.animal(id: number, cf: CFrame, withLabel: boolean?): Model
	local m = asset("Animals", id)
	if not m then
		return Beasts.build(id, cf, withLabel)
	end
	setAnchored(m, true)
	m:PivotTo(cf)
	if withLabel then
		local a = Config.Animals[id]
		local rar = Config.Rarities[a.rarity]
		local _, size = m:GetBoundingBox()
		local bb = Instance.new("BillboardGui")
		bb.Size = UDim2.fromOffset(200, 70)
		bb.StudsOffset = Vector3.new(0, size.Y / 2 + 2, 0)
		bb.MaxDistance = 80
		bb.Adornee = m.PrimaryPart or m:FindFirstChildWhichIsA("BasePart")
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
		label(rar.name, 0, rar.color, 20)
		label(a.name, 22, Color3.new(1, 1, 1), 18)
		label("$" .. a.income .. "/s", 44, Color3.fromRGB(90, 255, 90), 20)
		bb.Parent = bb.Adornee
	end
	return m
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
function Models.animalTool(id: number): Tool
	local m = Models.animal(id, CFrame.new(), false)
	m:ScaleTo(m:GetScale() * 0.5)
	local tool = toTool(m, Config.Animals[id].name, CFrame.new(0, 0, 1) * CFrame.Angles(0, math.rad(180), 0))
	tool:SetAttribute("AnimalId", id)
	return tool
end

function Models.weapon(index: number, cf: CFrame): Model
	local m = asset("Weapons", index)
	if not m then
		return WeaponModels.build(index, cf, true)
	end
	setAnchored(m, true)
	m:PivotTo(cf)
	return m
end

function Models.weaponTool(index: number): Tool
	local m = asset("Weapons", index)
	if not m then
		return WeaponModels.tool(index)
	end
	setAnchored(m, false)
	-- Los assets de armas apuntan hacia -Z con el pivote en la empuñadura
	m:PivotTo(CFrame.new())
	local tool = toTool(m, Config.Weapons[index].name, CFrame.new(), CFrame.new())
	tool:SetAttribute("WeaponIndex", index)
	return tool
end

return Models
