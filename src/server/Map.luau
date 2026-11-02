-- Genera el mapa: zona de bases, línea de tiro y el corredor de 20 épocas
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Config = require(ReplicatedStorage.Shared.Config)
local Tiles = require(ReplicatedStorage.Shared.Tiles)
local Models = require(ReplicatedStorage.Shared.Models)

local Map = {}

local folder: Folder
local shopDisplayCF: CFrame

-- Armas en exhibición sobre el mostrador (se vuelve a llamar cuando cargan los modelos de Blender)
function Map.refreshShop()
	local shop = folder:FindFirstChild("WeaponShop")
	if not shop then
		return
	end
	local old = shop:FindFirstChild("Displays")
	if old then
		old:Destroy()
	end
	local displays = Instance.new("Folder")
	displays.Name = "Displays"
	for i, index in { 1, 5, 8, 12, 17, 20 } do
		local display = Models.weapon(index, shopDisplayCF * CFrame.new(-7.5 + (i - 1) * 3, 4.6, 0) * CFrame.Angles(0, math.rad(90), 0))
		display.Parent = displays
	end
	displays.Parent = shop
end

local function block(size: Vector3, pos: Vector3, color: Color3, parent: Instance?, material: Enum.Material?): Part
	local p = Instance.new("Part")
	p.Anchored = true
	p.Size = size
	p.Position = pos
	p.Color = color
	p.Material = material or Enum.Material.Plastic
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.Parent = parent or folder
	return p
end

local function sign(text: string, pos: Vector3, color: Color3, parent: Instance?)
	local board = block(Vector3.new(30, 7, 1), pos, Color3.fromRGB(110, 70, 40), parent, Enum.Material.Wood)
	local gui = Instance.new("SurfaceGui")
	gui.Face = Enum.NormalId.Back
	gui.PixelsPerStud = 30
	local t = Instance.new("TextLabel")
	t.Size = UDim2.fromScale(1, 1)
	t.BackgroundTransparency = 1
	t.Font = Enum.Font.LuckiestGuy
	t.TextScaled = true
	t.TextColor3 = color
	t.TextStrokeTransparency = 0
	t.Text = text
	t.Parent = gui
	gui.Parent = board
	-- texto también por delante para quien lo vea desde el otro lado
	local front = gui:Clone()
	front.Face = Enum.NormalId.Front
	front.Parent = board
	return board
end

-- Muro a cuadros como en Steal an Egg: cuadros grandes con textura y pasto arriba.
-- Va de `from` a `to` (en X o en Z) sobre el piso.
local WALL_A = Color3.fromRGB(205, 125, 80)
local WALL_B = Color3.fromRGB(180, 104, 66)
local function checkerWall(from: Vector3, to: Vector3, height: number, colorA: Color3?, colorB: Color3?)
	local tile = 20
	local dir = to - from
	local len = dir.Magnitude
	local alongX = math.abs(dir.X) > math.abs(dir.Z)
	local unit = dir.Unit
	local n = math.ceil(len / tile - 0.01)
	local faces = if alongX then { Enum.NormalId.Front, Enum.NormalId.Back } else { Enum.NormalId.Left, Enum.NormalId.Right }
	for i = 0, n - 1 do
		local seg = math.min(tile, len - i * tile)
		local center = from + unit * (i * tile + seg / 2)
		for j = 0, math.ceil(height / tile) - 1 do
			local c = if (i + j) % 2 == 0 then (colorA or WALL_A) else (colorB or WALL_B)
			local size = if alongX then Vector3.new(seg, tile, 4) else Vector3.new(4, tile, seg)
			local w = block(size, Vector3.new(center.X, tile / 2 + j * tile, center.Z), c, nil, Enum.Material.SmoothPlastic)
			w.CastShadow = false
			Tiles(w, faces, 5)
		end
		local capSize = if alongX then Vector3.new(seg, 1.5, 5) else Vector3.new(5, 1.5, seg)
		local cap = block(capSize, Vector3.new(center.X, height + 0.75, center.Z), Color3.fromRGB(90, 200, 60), nil, Enum.Material.SmoothPlastic)
		cap.CastShadow = false
		Tiles(cap, { Enum.NormalId.Top, faces[1], faces[2] }, 2)
	end
end

local function bush(pos: Vector3, color: Color3)
	local all = { Enum.NormalId.Top, Enum.NormalId.Left, Enum.NormalId.Right, Enum.NormalId.Front, Enum.NormalId.Back }
	Tiles(block(Vector3.new(10, 4, 8), pos + Vector3.new(0, 2, 0), color, nil, Enum.Material.SmoothPlastic), all, 2)
	Tiles(block(Vector3.new(6, 3, 6), pos + Vector3.new(1, 5.5, 0), color, nil, Enum.Material.SmoothPlastic), all, 2)
end

local function floor(size: Vector3, pos: Vector3, color: Color3): Part
	local p = block(size, pos, color, nil, Enum.Material.SmoothPlastic)
	Tiles(p, { Enum.NormalId.Top }, 6)
	return p
end

function Map.build(): { CFrame }
	folder = Instance.new("Folder")
	folder.Name = "Map"
	folder.Parent = workspace

	local halfW = Config.FIELD_WIDTH / 2
	local grass = Color3.fromRGB(95, 210, 60)

	-- Zona de bases (todo cerrado con muro a cuadros, abierto sólo hacia la línea de tiro)
	local baseHalf = 186
	local back, front = -132, -10
	floor(Vector3.new(baseHalf * 2, 2, front - back), Vector3.new(0, -1, (back + front) / 2), grass)
	checkerWall(Vector3.new(-baseHalf, 0, back), Vector3.new(-baseHalf, 0, front), 40)
	checkerWall(Vector3.new(baseHalf, 0, back), Vector3.new(baseHalf, 0, front), 40)
	checkerWall(Vector3.new(-baseHalf, 0, back), Vector3.new(baseHalf, 0, back), 40)
	checkerWall(Vector3.new(-baseHalf, 0, front), Vector3.new(-halfW - 2, 0, front), 40)
	checkerWall(Vector3.new(halfW + 2, 0, front), Vector3.new(baseHalf, 0, front), 40)

	-- Línea de tiro
	local shoot = floor(Vector3.new(Config.FIELD_WIDTH, 0.2, 24), Vector3.new(0, 0.1, 0), Color3.fromRGB(240, 220, 140))
	shoot.Name = "ShootZone"
	block(Vector3.new(Config.FIELD_WIDTH, 0.3, 1), Vector3.new(0, 0.15, 12), Color3.new(1, 1, 1))
	sign("SHOOT ZONE", Vector3.new(0, 18, -11), Color3.fromRGB(255, 230, 80))

	-- Corredor de épocas
	local rng = Random.new(7)
	for e, epoch in Config.Epochs do
		local z0 = Config.FIELD_START + (e - 1) * Config.ZONE_LEN - (if e == 1 then Config.FIELD_START - 12 else 0)
		local z1 = Config.FIELD_START + e * Config.ZONE_LEN
		floor(Vector3.new(Config.FIELD_WIDTH, 2, z1 - z0), Vector3.new(0, -1, (z0 + z1) / 2), epoch.ground)
		-- La primera época sigue el muro hasta la zona de bases (sin hueco en la línea de tiro)
		local wz0 = if e == 1 then -12 else z0
		checkerWall(Vector3.new(-halfW - 2, 0, wz0), Vector3.new(-halfW - 2, 0, z1), 40, epoch.wallA, epoch.wallB)
		checkerWall(Vector3.new(halfW + 2, 0, wz0), Vector3.new(halfW + 2, 0, z1), 40, epoch.wallA, epoch.wallB)
		-- Franja y letrero de inicio de época
		local zStart = Config.FIELD_START + (e - 1) * Config.ZONE_LEN
		block(Vector3.new(Config.FIELD_WIDTH, 0.2, 3), Vector3.new(0, 0.1, zStart), epoch.wallA)
		sign(string.format("Epoch %d: %s", e, epoch.name), Vector3.new(halfW - 18, 12, zStart), Color3.new(1, 1, 1))
		for _ = 1, 5 do
			bush(Vector3.new(rng:NextNumber(-halfW + 8, halfW - 8), 0, rng:NextNumber(zStart + 10, z1 - 10)), epoch.prop)
		end
	end
	local endZ = Config.FIELD_START + Config.NUM_EPOCHS * Config.ZONE_LEN
	block(Vector3.new(Config.FIELD_WIDTH + 8, 60, 4), Vector3.new(0, 30, endZ + 2), Color3.fromRGB(30, 10, 50))

	-- Tienda de armas: puesto con toldo entre las bases y la línea de tiro
	local shop = Instance.new("Model")
	shop.Name = "WeaponShop"
	shop.Parent = folder
	local shopCF = CFrame.new(0, 0, -32)
	local counter = block(Vector3.new(20, 3.5, 4), (shopCF * CFrame.new(0, 1.75, 0)).Position, Color3.fromRGB(150, 90, 50), shop, Enum.Material.WoodPlanks)
	block(Vector3.new(21, 0.4, 5), (shopCF * CFrame.new(0, 3.7, 0)).Position, Color3.fromRGB(110, 65, 35), shop, Enum.Material.Wood)
	for _, x in { -9.5, 9.5 } do
		block(Vector3.new(1, 12, 1), (shopCF * CFrame.new(x, 6, 1.5)).Position, Color3.fromRGB(110, 65, 35), shop, Enum.Material.Wood)
	end
	for i = 0, 6 do
		local stripe = if i % 2 == 0 then Color3.fromRGB(230, 50, 50) else Color3.new(1, 1, 1)
		local part = block(Vector3.new(3, 0.5, 8), (shopCF * CFrame.new(-9 + i * 3, 12, -0.5)).Position, stripe, shop, Enum.Material.Fabric)
		part.CFrame *= CFrame.Angles(math.rad(-12), 0, 0)
	end
	local shopSign = sign("WEAPON SHOP", (shopCF * CFrame.new(0, 14.5, 1.5)).Position, Color3.fromRGB(255, 220, 80), shop)
	shopSign.Size = Vector3.new(18, 4, 1)
	shopDisplayCF = shopCF
	Map.refreshShop()
	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = "WeaponShop"
	prompt.ActionText = "Open Shop"
	prompt.ObjectText = "Weapons"
	prompt.MaxActivationDistance = 14
	prompt.RequiresLineOfSight = false
	prompt.Parent = counter

	-- Parcelas (bases): 6 en fila
	local plotCFrames = {}
	for i = 1, Config.PLOTS do
		local x = -150 + (i - 1) * 60
		plotCFrames[i] = CFrame.new(x, 0, -78)
	end
	return plotCFrames
end

return Map
