-- Carga los modelos de Blender (ModelAssets) con InsertService y los deja listos en ReplicatedStorage.Assets:
-- animales con el pivote en los pies (mirando a -Z) y armas con el pivote en la empuñadura.
local InsertService = game:GetService("InsertService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Config = require(ReplicatedStorage.Shared.Config)
local ModelAssets = require(ReplicatedStorage.Shared.ModelAssets)

local Assets = {}

-- Posición de la empuñadura respecto al centro del arma, en fracción de su tamaño (sale de tools/blender/kab.py)
local GRIPS = {
	{ 0, -0.081, -0.344 }, { 0, 0.37, -0.192 }, { 0, -0.065, 0.311 }, { 0, -0.167, 0.317 }, { 0, 0, 0.236 },
	{ 0, 0.205, 0.332 }, { 0, 0, 0.283 }, { 0, 0.166, 0.202 }, { 0, 0.145, 0.257 }, { 0, 0.145, 0.382 },
	{ 0, 0.145, 0.354 }, { 0, 0.029, 0.239 }, { 0, 0.145, 0.217 }, { 0.091, 0.145, 0.239 }, { 0, 0.029, 0.287 },
	{ 0, 0, 0.272 }, { 0, 0.136, 0.214 }, { 0, 0.029, 0.266 }, { 0, 0.029, 0.222 }, { 0, 0.001, 0.249 },
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
			m:ScaleTo(6.5 * Config.Rarities[a.rarity].scale / math.max(size.X, size.Y, size.Z))
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
