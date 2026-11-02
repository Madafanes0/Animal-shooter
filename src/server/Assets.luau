-- Carga los modelos de Blender (ModelAssets) con InsertService y los deja listos en ReplicatedStorage.Assets:
-- animales con el pivote en los pies (mirando a -Z) y armas con el pivote en la empuñadura.
local InsertService = game:GetService("InsertService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Config = require(ReplicatedStorage.Shared.Config)
local ModelAssets = require(ReplicatedStorage.Shared.ModelAssets)

local Assets = {}

-- Posición de la empuñadura respecto al centro del arma, en fracción de su tamaño (sale de tools/blender/kab.py)
local GRIPS = {
	{ 0, -0.025, -0.271 }, { 0, 0.405, -0.227 }, { 0, 0, 0.38 }, { 0, 0, 0.319 }, { 0, 0, 0.402 },
	{ 0, 0.253, 0.338 }, { 0, 0, 0.402 }, { 0, 0.191, 0.348 }, { 0, 0.185, 0.216 }, { 0, 0.185, 0.398 },
	{ 0, 0.161, 0.368 }, { 0, 0.036, 0.201 }, { 0, 0.185, 0.175 }, { 0, 0.167, 0.209 }, { 0, 0.036, 0.254 },
	{ 0, 0, 0.402 }, { 0, 0.159, 0.182 }, { 0, 0.036, 0.242 }, { 0, 0.027, 0.208 }, { 0, -0.009, 0.232 },
}

local function weaponLength(i: number): number
	if i <= 4 then
		return 2.6
	elseif i <= 8 then
		return 4
	elseif i <= 18 then
		return 4.5
	end
	return 5.2
end

-- Caja alineada a los ejes del mundo que envuelve todas las partes (las mallas importadas pueden venir rotadas)
local function worldBounds(m: Model): (Vector3, Vector3)
	local lo = Vector3.new(math.huge, math.huge, math.huge)
	local hi = -lo
	for _, p in m:GetDescendants() do
		if p:IsA("BasePart") then
			local h = p.Size / 2
			for _, sx in { -1, 1 } do
				for _, sy in { -1, 1 } do
					for _, sz in { -1, 1 } do
						local c = p.CFrame:PointToWorldSpace(Vector3.new(h.X * sx, h.Y * sy, h.Z * sz))
						lo = lo:Min(c)
						hi = hi:Max(c)
					end
				end
			end
		end
	end
	return (lo + hi) / 2, hi - lo
end

-- Pone una parte invisible "Root" sin rotación como PrimaryPart; el pivote queda en `pivotOffset` desde el centro
local function setRoot(m: Model, pivotOffset: (Vector3) -> Vector3)
	local center, size = worldBounds(m)
	local root = Instance.new("Part")
	root.Name = "Root"
	root.Size = size
	root.CFrame = CFrame.new(center)
	root.Transparency = 1
	root.Anchored = true
	root.CanCollide = false
	root.CanQuery = false
	root.CanTouch = false
	root.Parent = m
	root.PivotOffset = CFrame.new(pivotOffset(size))
	m.PrimaryPart = root
end

-- Saca las partes del asset y las mete en un Model limpio
local function load(id: number, name: string): Model?
	local ok, asset = pcall(InsertService.LoadAsset, InsertService, id)
	if not ok or not asset then
		warn("No se pudo cargar el modelo", id, asset)
		return nil
	end
	local m = Instance.new("Model")
	m.Name = name
	for _, p in asset:GetDescendants() do
		if p:IsA("BasePart") then
			p.Anchored = true
			p.CanCollide = false
			p.CanQuery = false
			p.Parent = m
		end
	end
	asset:Destroy()
	return if m:FindFirstChildWhichIsA("BasePart") then m else nil
end

function Assets.start(onDone: () -> ())
	local root = Instance.new("Folder")
	root.Name = "Assets"
	local animals = Instance.new("Folder")
	animals.Name = "Animals"
	animals.Parent = root
	local weapons = Instance.new("Folder")
	weapons.Name = "Weapons"
	weapons.Parent = root
	root.Parent = ReplicatedStorage

	local pending = 0
	local function finished()
		pending -= 1
		if pending == 0 then
			onDone()
		end
	end
	for _ in ModelAssets.Animals do
		pending += 1
	end
	for _ in ModelAssets.Weapons do
		pending += 1
	end
	if pending == 0 then
		onDone()
	end

	for animalId, assetId in ModelAssets.Animals do
		task.spawn(function()
			local m = load(assetId, tostring(animalId))
			local a = Config.Animals[animalId]
			if not m or not a then
				finished()
				return
			end
			local _, size = worldBounds(m)
			m:ScaleTo(4.2 * Config.Rarities[a.rarity].scale / math.max(size.X, size.Y, size.Z))
			-- Pivote en los pies, al centro
			setRoot(m, function(s)
				return Vector3.new(0, -s.Y / 2, 0)
			end)
			m.Parent = animals
			finished()
		end)
	end

	for index, assetId in ModelAssets.Weapons do
		task.spawn(function()
			local m = load(assetId, tostring(index))
			if not m then
				finished()
				return
			end
			local _, size = worldBounds(m)
			m:ScaleTo(weaponLength(index) / math.max(size.X, size.Y, size.Z))
			local g = GRIPS[index]
			setRoot(m, function(s)
				return Vector3.new(g[1] * s.X, g[2] * s.Y, g[3] * s.Z)
			end)
			m.Parent = weapons
			finished()
		end)
	end
end

return Assets
