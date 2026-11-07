-- Genera el mapa: zona de bases, línea de tiro y el corredor de 20 épocas
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Config = require(ReplicatedStorage.Shared.Config)
local Tiles = require(ReplicatedStorage.Shared.Tiles)
local Models = require(ReplicatedStorage.Shared.Models)
local Scenery = require(script.Parent.Scenery)

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
		local display = Models.weapon(index, shopDisplayCF * CFrame.new(-8 + (i - 1) * 3.2, 5.4, 0) * CFrame.Angles(0, math.rad(90), 0))
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
	-- PixelsPerStud: el lienzo toma la forma del letrero (con FixedSize el texto salía estirado)
	gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	gui.PixelsPerStud = 30
	local t = Instance.new("TextLabel")
	t.Size = UDim2.fromScale(1, 1)
	t.BackgroundTransparency = 1
	t.FontFace = Font.new("rbxasset://fonts/families/Montserrat.json", Enum.FontWeight.Heavy)
	t.TextScaled = true
	t.TextColor3 = color
	t.TextStrokeTransparency = 0
	t.Text = text
	local pad = Instance.new("UIPadding")
	pad.PaddingLeft = UDim.new(0.04, 0)
	pad.PaddingRight = UDim.new(0.04, 0)
	pad.PaddingTop = UDim.new(0.12, 0)
	pad.PaddingBottom = UDim.new(0.12, 0)
	pad.Parent = t
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
	local baseHalf = 262
	local back, front = -178, -10
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
		Scenery.decorate(e, zStart, z1, folder)
	end
	local endZ = Config.FIELD_START + Config.NUM_EPOCHS * Config.ZONE_LEN
	block(Vector3.new(Config.FIELD_WIDTH + 8, 60, 4), Vector3.new(0, 30, endZ + 2), Color3.fromRGB(30, 10, 50))

	-- Tiendas junto a la línea de tiro (armas a la izquierda, Robux a la derecha): puesto de mercado con toldo
	-- de bloques a rayas, postes y mostrador de madera con studs y un vendedor detrás. El frente mira al pasillo.
	local DARK_WOOD = Color3.fromRGB(92, 58, 40)
	local TOP_WOOD = Color3.fromRGB(78, 74, 78)
	local function stall(name: string, cf: CFrame, title: string, stripeA: Color3, stripeB: Color3, titleColor: Color3, promptText: string, shirt: Color3): Model
		local shop = Instance.new("Model")
		shop.Name = name
		shop.Parent = folder
		local function piece(size: Vector3, at: CFrame, color: Color3, studs: number?): Part
			local p = block(size, Vector3.zero, color, shop, Enum.Material.SmoothPlastic)
			p.CFrame = cf * at
			Tiles(p, { Enum.NormalId.Top, Enum.NormalId.Front, Enum.NormalId.Back, Enum.NormalId.Left, Enum.NormalId.Right, Enum.NormalId.Bottom }, studs or 2)
			return p
		end
		for _, x in { -10, 10 } do
			for _, z in { -3.6, 3.6 } do
				piece(Vector3.new(1.3, 13, 1.3), CFrame.new(x, 6.5, z), DARK_WOOD)
			end
		end
		-- Toldo: franjas de bloques con su "pestaña" al frente
		for k = 0, 7 do
			local color = if k % 2 == 0 then stripeA else stripeB
			local x = -9.1 + k * 2.6
			piece(Vector3.new(2.6, 1.1, 10.4), CFrame.new(x, 13.4, 0), color)
			piece(Vector3.new(2.6, 1.2, 0.9), CFrame.new(x, 12.5, -5.4), color)
		end
		piece(Vector3.new(21.4, 0.6, 0.8), CFrame.new(0, 12.6, 3.6), DARK_WOOD)
		-- Mostrador: dos vigas con studs y la tabla de arriba
		local counter = piece(Vector3.new(21, 1.7, 0.9), CFrame.new(0, 1.3, -3.6), DARK_WOOD)
		piece(Vector3.new(21, 1.7, 0.9), CFrame.new(0, 3.2, -3.6), DARK_WOOD)
		piece(Vector3.new(22, 0.45, 2.6), CFrame.new(0, 4.3, -3.6), TOP_WOOD)
		local board = sign(title, (cf * CFrame.new(0, 16.3, -4.6)).Position, titleColor, shop)
		board.Size = Vector3.new(16, 3.6, 0.8)
		board.CFrame = cf * CFrame.new(0, 16.3, -4.6)
		local prompt = Instance.new("ProximityPrompt")
		prompt.Name = name
		prompt.ActionText = promptText
		prompt.ObjectText = title
		prompt.MaxActivationDistance = 14
		prompt.RequiresLineOfSight = false
		prompt.Parent = counter
		-- Vendedor con sombrero vaquero detrás del mostrador
		task.spawn(function()
			local ok, npc = pcall(function()
				local desc = Instance.new("HumanoidDescription")
				desc.HeadColor = Color3.fromRGB(234, 184, 146)
				desc.LeftArmColor = desc.HeadColor
				desc.RightArmColor = desc.HeadColor
				desc.TorsoColor = shirt
				desc.LeftLegColor = shirt
				desc.RightLegColor = shirt
				return Players:CreateHumanoidModelFromDescription(desc, Enum.HumanoidRigType.R15)
			end)
			if not ok or not npc then
				return
			end
			npc.Name = "Shopkeeper"
			local hum = npc:FindFirstChildOfClass("Humanoid")
			if hum then
				hum.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
			end
			for _, d in npc:GetDescendants() do
				if d:IsA("BasePart") then
					d.Anchored = true
				end
			end
			npc:PivotTo(cf * CFrame.new(0, 3, 0.4))
			local head = npc:FindFirstChild("Head") :: BasePart?
			if head then
				local hatColor = Color3.fromRGB(120, 80, 45)
				local brim = Instance.new("Part")
				brim.Shape = Enum.PartType.Cylinder
				brim.Size = Vector3.new(0.18, 2.6, 2.6)
				brim.CFrame = head.CFrame * CFrame.new(0, 0.55, 0) * CFrame.Angles(0, 0, math.rad(90))
				brim.Color = hatColor
				brim.Anchored = true
				brim.Parent = npc
				local crown = Instance.new("Part")
				crown.Size = Vector3.new(1.3, 0.75, 1.3)
				crown.CFrame = head.CFrame * CFrame.new(0, 0.95, 0)
				crown.Color = hatColor
				crown.Anchored = true
				crown.Parent = npc
				local band = crown:Clone()
				band.Size = Vector3.new(1.34, 0.18, 1.34)
				band.CFrame = head.CFrame * CFrame.new(0, 0.7, 0)
				band.Color = Color3.fromRGB(60, 40, 25)
				band.Parent = npc
			end
			npc.Parent = shop
		end)
		return shop
	end
	local weaponCF = CFrame.lookAt(Vector3.new(-80, 0, -26), Vector3.new(0, 0, -26))
	shopDisplayCF = weaponCF * CFrame.new(0, 0, -3.6)
	stall("WeaponShop", weaponCF, "WEAPONS", Color3.fromRGB(40, 120, 230), Color3.new(1, 1, 1), Color3.fromRGB(255, 220, 80), "Open Shop", Color3.fromRGB(50, 90, 160))
	Map.refreshShop()
	local robuxCF = CFrame.lookAt(Vector3.new(80, 0, -26), Vector3.new(0, 0, -26))
	local robux = stall("RobuxShop", robuxCF, "SHOP", Color3.fromRGB(40, 200, 90), Color3.fromRGB(255, 210, 50), Color3.fromRGB(120, 255, 140), "Open Shop", Color3.fromRGB(40, 140, 70))
	-- Cofre dorado sobre el mostrador
	local chest = block(Vector3.new(4, 2.4, 2.4), Vector3.zero, Color3.fromRGB(255, 200, 40), robux, Enum.Material.Foil)
	chest.CFrame = robuxCF * CFrame.new(0, 5.7, -3.6)
	local lid = block(Vector3.new(4.2, 0.5, 2.6), Vector3.zero, Color3.fromRGB(200, 120, 20), robux, Enum.Material.Metal)
	lid.CFrame = robuxCF * CFrame.new(0, 7.1, -3.6)

	-- Parcelas (bases): 6 en fila
	local plotCFrames = {}
	for i = 1, Config.PLOTS do
		local x = -210 + (i - 1) * 84
		plotCFrames[i] = CFrame.new(x, 0, -100)
	end
	return plotCFrames
end

return Map
