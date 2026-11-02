-- Genera el mapa: zona de bases, línea de tiro y el corredor de 20 épocas
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Config = require(ReplicatedStorage.Shared.Config)

local Map = {}

local folder: Folder

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

-- Muro a cuadros como en Steal an Egg
local function checkerWall(x: number, z0: number, z1: number, height: number, colorA: Color3, colorB: Color3)
	local tile = 20
	local n = math.ceil((z1 - z0) / tile)
	for i = 0, n - 1 do
		for j = 0, math.ceil(height / tile) - 1 do
			local c = if (i + j) % 2 == 0 then colorA else colorB
			local w = block(Vector3.new(4, tile, tile), Vector3.new(x, tile / 2 + j * tile, z0 + i * tile + tile / 2), c, nil, Enum.Material.SmoothPlastic)
			w.TopSurface = Enum.SurfaceType.Smooth
		end
	end
end

local function bush(pos: Vector3, color: Color3)
	block(Vector3.new(10, 4, 8), pos + Vector3.new(0, 2, 0), color)
	block(Vector3.new(6, 3, 6), pos + Vector3.new(1, 5.5, 0), color)
end

function Map.build(): { CFrame }
	folder = Instance.new("Folder")
	folder.Name = "Map"
	folder.Parent = workspace

	local halfW = Config.FIELD_WIDTH / 2
	local grass = Color3.fromRGB(95, 210, 60)

	-- Zona de bases
	local baseHalf = 172
	block(Vector3.new(baseHalf * 2, 2, 110), Vector3.new(0, -1, -65), grass)
	checkerWall(-baseHalf - 2, -120, -10, 40, Color3.fromRGB(200, 120, 75), Color3.fromRGB(176, 102, 64))
	checkerWall(baseHalf + 2, -120, -10, 40, Color3.fromRGB(200, 120, 75), Color3.fromRGB(176, 102, 64))
	block(Vector3.new(baseHalf * 2 + 8, 40, 4), Vector3.new(0, 20, -122), Color3.fromRGB(176, 102, 64), nil, Enum.Material.SmoothPlastic)
	for _, side in { -1, 1 } do
		block(Vector3.new(baseHalf - halfW, 40, 4), Vector3.new(side * (halfW + (baseHalf - halfW) / 2), 20, -10), Color3.fromRGB(200, 120, 75), nil, Enum.Material.SmoothPlastic)
	end

	-- Línea de tiro
	local shoot = block(Vector3.new(Config.FIELD_WIDTH, 0.2, 24), Vector3.new(0, 0.1, 0), Color3.fromRGB(240, 220, 140), nil, Enum.Material.Sand)
	shoot.Name = "ShootZone"
	block(Vector3.new(Config.FIELD_WIDTH, 0.3, 1), Vector3.new(0, 0.15, 12), Color3.new(1, 1, 1))
	sign("SHOOT ZONE", Vector3.new(0, 18, -11), Color3.fromRGB(255, 230, 80))

	-- Corredor de épocas
	local rng = Random.new(7)
	for e, epoch in Config.Epochs do
		local z0 = Config.FIELD_START + (e - 1) * Config.ZONE_LEN - (if e == 1 then Config.FIELD_START - 12 else 0)
		local z1 = Config.FIELD_START + e * Config.ZONE_LEN
		block(Vector3.new(Config.FIELD_WIDTH, 2, z1 - z0), Vector3.new(0, -1, (z0 + z1) / 2), epoch.ground)
		checkerWall(-halfW - 2, z0, z1, 40, epoch.wallA, epoch.wallB)
		checkerWall(halfW + 2, z0, z1, 40, epoch.wallA, epoch.wallB)
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

	-- Parcelas (bases): 6 en fila
	local plotCFrames = {}
	for i = 1, Config.PLOTS do
		local x = -140 + (i - 1) * 56
		plotCFrames[i] = CFrame.new(x, 0, -65)
	end
	return plotCFrames
end

return Map
