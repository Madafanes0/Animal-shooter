-- Kill a Beast: servidor (datos, disparo, establo, entrenador, tienda de armas)
local Players = game:GetService("Players")
local DataStoreService = game:GetService("DataStoreService")
local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local MarketplaceService = game:GetService("MarketplaceService")
local RunService = game:GetService("RunService")

local Config = require(ReplicatedStorage.Shared.Config)
local Map = require(script.Parent.Map)
local Assets = require(script.Parent.Assets)
local Tiles = require(ReplicatedStorage.Shared.Tiles)
local Models = require(ReplicatedStorage.Shared.Models)

local remotes = Instance.new("Folder")
remotes.Name = "Remotes"
local ShootFn = Instance.new("RemoteFunction")
ShootFn.Name = "Shoot"
ShootFn.Parent = remotes
local Action = Instance.new("RemoteEvent")
Action.Name = "Action"
Action.Parent = remotes
local Notify = Instance.new("RemoteEvent")
Notify.Name = "Notify"
Notify.Parent = remotes
remotes.Parent = ReplicatedStorage

-- La plantilla de Studio trae un SpawnLocation y un Baseplate que quedan en la zona de tiro
for _, name in { "SpawnLocation", "Baseplate" } do
	local extra = workspace:FindFirstChild(name)
	if extra then
		extra:Destroy()
	end
end

local plotCFrames = Map.build()
local plotsFolder = Instance.new("Folder")
plotsFolder.Name = "Plots"
plotsFolder.Parent = workspace

local okStore, store = pcall(function()
	return DataStoreService:GetDataStore("KillABeast_v1")
end)

type Data = {
	money: number,
	power: number,
	owned: { [string]: boolean },
	equipped: number,
	stableLevel: number,
	trainerLevel: number,
	animals: { number },
	held: { number },
	discovered: { [string]: boolean },
	kills: number,
	passes: { [string]: boolean },
	luckUntil: number,
	claimedWorlds: { [string]: boolean },
}

local data: { [Player]: Data } = {}
local plotOf: { [Player]: number } = {}
local plotModels: { [number]: Model } = {}
local lastShot: { [Player]: number } = {}
local rng = Random.new()
local giveHeld: (Player) -> ()

local function defaultData(): Data
	return {
		money = 0,
		power = 0,
		owned = { ["1"] = true },
		equipped = 1,
		stableLevel = 0,
		trainerLevel = 0,
		animals = {},
		held = {},
		discovered = {},
		kills = 0,
		passes = {},
		luckUntil = 0,
		claimedWorlds = {},
	}
end

local function income(d: Data): number
	local total = 0
	for _, entry in d.animals do
		total += Config.entryIncome(entry)
	end
	return total * (if d.passes.Money2 then 2 else 1)
end

local function heldMax(d: Data): number
	return Config.HELD_MAX + (if d.passes.BigHands then 50 else 0)
end

-- Suerte total: arma exclusiva × pase 2x × poción 3x
local function luckMult(d: Data): number
	local w = Config.Weapons[d.equipped]
	local luck = w.luck or 1
	if d.passes.Luck2 then
		luck *= 2
	end
	if d.luckUntil > os.time() then
		luck *= 3
	end
	return luck
end

-- El cliente lee todo su estado de un atributo JSON
local function push(plr: Player)
	local d = data[plr]
	if not d then
		return
	end
	plr:SetAttribute("State", HttpService:JSONEncode({
		money = d.money,
		power = d.power,
		owned = d.owned,
		equipped = d.equipped,
		stableLevel = d.stableLevel,
		trainerLevel = d.trainerLevel,
		animals = d.animals,
		held = d.held,
		discovered = d.discovered,
		income = income(d),
		kills = d.kills,
		passes = d.passes,
		claimedWorlds = d.claimedWorlds,
		luckLeft = math.max(0, d.luckUntil - os.time()),
		luck = luckMult(d),
		heldMax = heldMax(d),
	}))
	local ls = plr:FindFirstChild("leaderstats")
	if ls then
		(ls :: any).Kills.Value = d.kills
	end
end

local function notify(plr: Player, text: string, color: Color3?)
	Notify:FireClient(plr, text, color)
end

---------------------------------------------------------------- Parcelas

local function plotPart(model: Model, size: Vector3, cf: CFrame, color: Color3, material: Enum.Material?): Part
	local p = Instance.new("Part")
	p.Anchored = true
	p.Size = size
	p.CFrame = cf
	p.Color = color
	p.Material = material or Enum.Material.Plastic
	p.TopSurface = Enum.SurfaceType.Smooth
	p.Parent = model
	return p
end

local function fence(model: Model, a: Vector3, b: Vector3)
	local wood = Color3.fromRGB(185, 95, 45)
	local post = Color3.fromRGB(70, 55, 55)
	local dir = b - a
	local len = dir.Magnitude
	local cf = CFrame.lookAt((a + b) / 2, b)
	for _, y in { 1.6, 3.2 } do
		plotPart(model, Vector3.new(0.5, 0.6, len), cf + Vector3.new(0, y, 0), wood, Enum.Material.Wood)
	end
	local n = math.max(1, math.floor(len / 8))
	for i = 0, n do
		local p = a:Lerp(b, i / n)
		plotPart(model, Vector3.new(1, 4.5, 1), CFrame.new(p + Vector3.new(0, 2.25, 0)), post)
	end
end

-- Corral en coordenadas locales de la parcela
local PEN_Z, PEN_HW, PEN_HD = -26, 35, 35

local function buildPlot(i: number): Model
	local m = Instance.new("Model")
	m.Name = "Plot" .. i
	local cf = plotCFrames[i]
	local plotFloor = plotPart(m, Vector3.new(78, 0.4, 82), cf * CFrame.new(0, 0.2, -28), Color3.fromRGB(120, 225, 80), Enum.Material.SmoothPlastic)
	Tiles(plotFloor, { Enum.NormalId.Top }, 6)

	-- Establo grande (corral al fondo, granero detrás)
	local penCenter = cf * CFrame.new(0, 0, PEN_Z)
	local hw, hd = PEN_HW, PEN_HD
	local c = penCenter.Position
	fence(m, c + Vector3.new(-hw, 0, -hd), c + Vector3.new(hw, 0, -hd))
	fence(m, c + Vector3.new(-hw, 0, -hd), c + Vector3.new(-hw, 0, hd))
	fence(m, c + Vector3.new(hw, 0, -hd), c + Vector3.new(hw, 0, hd))
	fence(m, c + Vector3.new(-hw, 0, hd), c + Vector3.new(-5, 0, hd))
	fence(m, c + Vector3.new(5, 0, hd), c + Vector3.new(hw, 0, hd))
	-- Letrero chico con el nombre del dueño junto a la entrada
	local post = plotPart(m, Vector3.new(0.8, 6, 0.8), penCenter * CFrame.new(-9, 3, hd + 1), Color3.fromRGB(110, 65, 35), Enum.Material.Wood)
	post.Name = "SignPole"
	local signBoard = plotPart(m, Vector3.new(8, 2.4, 0.5), penCenter * CFrame.new(-9, 6.2, hd + 1), Color3.fromRGB(150, 90, 50), Enum.Material.Wood)
	signBoard.Name = "SignPost"
	local board = Instance.new("BillboardGui")
	board.Name = "OwnerSign"
	board.Size = UDim2.fromOffset(150, 26)
	board.StudsOffset = Vector3.new(0, 2.2, 0)
	board.MaxDistance = 90
	board.Adornee = signBoard
	local t = Instance.new("TextLabel")
	t.Name = "Text"
	t.Size = UDim2.fromScale(1, 1)
	t.BackgroundTransparency = 1
	t.FontFace = Font.new("rbxasset://fonts/families/Montserrat.json", Enum.FontWeight.Heavy)
	t.TextScaled = true
	t.TextColor3 = Color3.new(1, 1, 1)
	t.TextStrokeTransparency = 0
	t.Text = "Empty Stable"
	t.Parent = board
	board.Parent = signBoard

	-- Campo de entrenamiento afuera de la zona verde: caseta con toldo, cerca, 3 dianas y pacas de paja
	local DIRT = Color3.fromRGB(205, 165, 115)
	local WOODC = Color3.fromRGB(120, 72, 40)
	local DARKW = Color3.fromRGB(85, 50, 30)
	local ALL = { Enum.NormalId.Top, Enum.NormalId.Front, Enum.NormalId.Back, Enum.NormalId.Left, Enum.NormalId.Right }
	local function studPart(size: Vector3, at: CFrame, color: Color3, studs: number?): Part
		local p = plotPart(m, size, cf * at, color, Enum.Material.SmoothPlastic)
		Tiles(p, ALL, studs or 2)
		return p
	end
	local range = studPart(Vector3.new(22, 0.3, 22), CFrame.new(18, 0.15, 28), DIRT, 4)
	range.Name = "TrainerRange"
	local rc = (cf * CFrame.new(18, 0, 28)).Position
	fence(m, rc + Vector3.new(-11, 0, -11), rc + Vector3.new(-11, 0, 11))
	fence(m, rc + Vector3.new(11, 0, -11), rc + Vector3.new(11, 0, 11))
	fence(m, rc + Vector3.new(-11, 0, 11), rc + Vector3.new(11, 0, 11))

	-- Caseta: tarima, 4 postes y toldo a rayas rojo/blanco
	local pad = studPart(Vector3.new(9, 0.8, 7), CFrame.new(18, 0.4, 21), Color3.fromRGB(160, 100, 55))
	pad.Name = "TrainerPad"
	for _, x in { 13.8, 22.2 } do
		for _, z in { 17.8, 24.2 } do
			studPart(Vector3.new(0.9, 9, 0.9), CFrame.new(x, 4.8, z), DARKW)
		end
	end
	for k = 0, 5 do
		local stripe = if k % 2 == 0 then Color3.fromRGB(220, 50, 50) else Color3.new(1, 1, 1)
		studPart(Vector3.new(1.75, 0.6, 8.4), CFrame.new(13.6 + k * 1.75, 9.5, 21) * CFrame.Angles(math.rad(8), 0, 0), stripe)
	end
	studPart(Vector3.new(10.6, 0.5, 0.6), CFrame.new(18, 9.2, 24.9), WOODC)
	-- Mostrador bajito al frente de la caseta
	studPart(Vector3.new(8.4, 2.2, 0.8), CFrame.new(18, 1.9, 24.4), WOODC)
	studPart(Vector3.new(8.8, 0.3, 1.2), CFrame.new(18, 3.1, 24.4), DARKW)

	-- 3 dianas en caballetes a distintas distancias
	local targets = Instance.new("Folder")
	targets.Name = "Targets"
	targets.Parent = m
	for k, spot in { Vector3.new(12, 0, 31), Vector3.new(18, 0, 35), Vector3.new(24, 0, 31) } do
		local base = CFrame.new(spot)
		studPart(Vector3.new(0.6, 4, 0.6), base * CFrame.new(-1.4, 2, 0.6), WOODC)
		studPart(Vector3.new(0.6, 4, 0.6), base * CFrame.new(1.4, 2, 0.6), WOODC)
		studPart(Vector3.new(3.6, 0.4, 0.5), base * CFrame.new(0, 2.6, 0.6), DARKW)
		for ring, info in { { 5, Color3.new(1, 1, 1) }, { 3.6, Color3.fromRGB(230, 40, 40) }, { 2.2, Color3.new(1, 1, 1) }, { 0.9, Color3.fromRGB(230, 40, 40) } } do
			local disc = Instance.new("Part")
			disc.Shape = Enum.PartType.Cylinder
			disc.Anchored = true
			disc.Size = Vector3.new(0.4 + ring * 0.08, info[1], info[1])
			disc.CFrame = cf * base * CFrame.new(0, 5.2, 0) * CFrame.Angles(0, math.rad(90), 0)
			disc.Color = info[2]
			disc.Material = Enum.Material.SmoothPlastic
			disc.Name = if ring == 1 then "TrainerTarget" else "Ring"
			disc.Parent = if ring == 1 then targets else m
		end
		-- paca de paja detrás
		studPart(Vector3.new(4, 2.4, 2.4), base * CFrame.new(0, 1.2, 2.6), Color3.fromRGB(235, 200, 90))
		if k == 2 then
			studPart(Vector3.new(4, 2.4, 2.4), base * CFrame.new(0, 3.6, 2.6), Color3.fromRGB(225, 190, 80))
		end
	end

	local trainerSign = Instance.new("BillboardGui")
	trainerSign.Size = UDim2.fromOffset(170, 28)
	trainerSign.StudsOffset = Vector3.new(0, 10.5, 0)
	trainerSign.MaxDistance = 70
	trainerSign.Adornee = pad
	local tt = t:Clone()
	tt.Text = "TRAINING · STAND INSIDE"
	tt.TextColor3 = Color3.fromRGB(255, 220, 80)
	tt.Parent = trainerSign
	trainerSign.Parent = pad

	local spawnPart = plotPart(m, Vector3.new(7, 0.4, 7), cf * CFrame.new(-18, 0.3, 24), Color3.fromRGB(80, 160, 255), Enum.Material.SmoothPlastic)
	spawnPart.Name = "Spawn"

	local animals = Instance.new("Folder")
	animals.Name = "Animals"
	animals.Parent = m

	m:SetAttribute("Index", i)
	-- El cliente usa el corral para que los animales caminen por ahí
	m:SetAttribute("PenCenter", penCenter + Vector3.new(0, 0.4, 0))
	m:SetAttribute("PenSize", Vector3.new(hw - 3, 0, hd - 3))
	m.Parent = plotsFolder

	return m
end

for i = 1, Config.PLOTS do
	plotModels[i] = buildPlot(i)
end

-- Coloca los animales del establo en cuadrícula dentro del corral
local function refreshStable(plr: Player)
	local i = plotOf[plr]
	local d = data[plr]
	if not i or not d then
		return
	end
	local folder = plotModels[i].Animals
	folder:ClearAllChildren()
	local center = plotCFrames[i] * CFrame.new(0, 0.4, PEN_Z)
	local cols = 10
	for n, id in d.animals do
		local col = (n - 1) % cols
		local row = math.floor((n - 1) / cols)
		local pos = center * CFrame.new(-29.25 + col * 6.5, 0, -27 + row * 9) * CFrame.Angles(0, math.rad(180), 0)
		local beast = Models.animal(id, pos, true)
		beast:ScaleTo(beast:GetScale() * 0.75)
		beast:SetAttribute("Owner", plr.UserId)
		beast.Parent = folder
	end
end

local function plotSpawn(plr: Player): CFrame?
	local i = plotOf[plr]
	if not i then
		return nil
	end
	return plotModels[i].Spawn.CFrame + Vector3.new(0, 4, 0)
end

local function sendHome(plr: Player)
	local cf = plotSpawn(plr)
	local char = plr.Character
	if cf and char then
		char:PivotTo(cf * CFrame.Angles(0, math.rad(180), 0))
	end
end

-- Pone el arma equipada en la mano (quita la anterior)
local function giveWeapon(plr: Player)
	local d = data[plr]
	local char = plr.Character
	if not d or not char then
		return
	end
	for _, container in { plr:FindFirstChildOfClass("Backpack"), char } do
		if container then
			for _, t in container:GetChildren() do
				if t:IsA("Tool") and t:GetAttribute("WeaponIndex") then
					t:Destroy()
				end
			end
		end
	end
	local tool = Models.weaponTool(d.equipped)
	tool.Parent = plr:FindFirstChildOfClass("Backpack")
	local hum = char:FindFirstChildOfClass("Humanoid")
	if hum then
		hum:EquipTool(tool)
	end
end

-- Un Tool por cada animal cargado (se re-crean todos cuando cambia la lista)
giveHeld = function(plr: Player)
	local d = data[plr]
	local char = plr.Character
	local backpack = plr:FindFirstChildOfClass("Backpack")
	if not d or not char or not backpack then
		return
	end
	for _, container in { backpack, char } do
		for _, t in container:GetChildren() do
			if t:IsA("Tool") and t:GetAttribute("AnimalId") then
				t:Destroy()
			end
		end
	end
	for _, id in d.held do
		Models.animalTool(id).Parent = backpack
	end
end

-- ¿Está el jugador dentro de su propio corral?
local function inOwnPen(plr: Player): boolean
	local i = plotOf[plr]
	local char = plr.Character
	local root = char and char:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not i or not root then
		return false
	end
	local p = (plotCFrames[i] * CFrame.new(0, 0, PEN_Z)):PointToObjectSpace(root.Position)
	return math.abs(p.X) <= PEN_HW + 2 and math.abs(p.Z) <= PEN_HD + 2
end

---------------------------------------------------------------- Disparo

local function inShootZone(plr: Player): boolean
	local char = plr.Character
	local root = char and char:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not root then
		return false
	end
	local p = root.Position
	return math.abs(p.X) <= Config.FIELD_WIDTH / 2 and p.Z > -16 and p.Z < 16
end

ShootFn.OnServerInvoke = function(plr: Player)
	local d = data[plr]
	if not d then
		return { err = "Loading..." }
	end
	if os.clock() - (lastShot[plr] or 0) < Config.SHOT_COOLDOWN then
		return { err = "Reloading..." }
	end
	if not inShootZone(plr) then
		return { err = "Go to the Shoot Zone!" }
	end
	if #d.held >= heldMax(d) then
		return { err = "Your hands are full! Place or sell animals." }
	end
	lastShot[plr] = os.clock()

	local maxDist = Config.shotDistance(d.equipped, d.power)
	local dist = maxDist * rng:NextNumber(0.8, 1)
	local luck = luckMult(d)
	local animal, chance = Config.rollAnimal(dist, rng, luck)
	local variant, vChance = Config.rollVariant(rng, luck)
	local size, sChance = Config.rollSize(rng, luck)
	local entry = Config.entry(animal.id, variant, size)
	table.insert(d.held, entry)
	d.discovered[tostring(animal.id)] = true
	d.kills += 1
	push(plr)

	local root = (plr.Character :: Model):FindFirstChild("HumanoidRootPart") :: BasePart
	local x = math.clamp(root.Position.X + rng:NextNumber(-10, 10), -Config.FIELD_WIDTH / 2 + 8, Config.FIELD_WIDTH / 2 - 8)
	-- El animal llega a tu mano cuando termina la animación
	task.delay(4, giveHeld, plr)
	-- "1 en N" para que el cliente sepa si toca la animación de criatura rara
	return { dist = dist, x = x, animal = entry, weapon = d.equipped, oneIn = math.floor(1 / (chance * vChance * sChance)) }
end

---------------------------------------------------------------- Acciones

local handlers = {}

function handlers.Home(plr: Player)
	sendHome(plr)
end

function handlers.BuyWeapon(plr: Player, d: Data, index: any)
	local w = Config.Weapons[tonumber(index) or 0]
	if not w then
		return
	end
	local key = tostring(w.index)
	if w.exclusive and not d.passes[w.pass] then
		notify(plr, "Get it in the Robux Shop!")
		return
	end
	if d.owned[key] or w.exclusive then
		d.equipped = w.index
		notify(plr, "Equipped " .. w.name)
		giveWeapon(plr)
		return
	end
	if not d.owned[tostring(w.index - 1)] then
		notify(plr, "Buy the previous weapon first!")
		return
	end
	if d.money < w.price then
		notify(plr, "Not enough money!")
		return
	end
	d.money -= w.price
	d.owned[key] = true
	d.equipped = w.index
	notify(plr, "Bought " .. w.name .. "!", Color3.fromRGB(90, 255, 90))
	giveWeapon(plr)
end

function handlers.UpgradeStable(plr: Player, d: Data)
	if d.stableLevel >= Config.STABLE_MAX_LEVEL then
		return
	end
	local cost = Config.stableUpgradeCost(d.stableLevel)
	if d.money < cost then
		notify(plr, "Not enough money!")
		return
	end
	d.money -= cost
	d.stableLevel += 1
	notify(plr, "Stable upgraded! " .. Config.stableCapacity(d.stableLevel) .. " slots", Color3.fromRGB(90, 255, 90))
end

function handlers.UpgradeTrainer(plr: Player, d: Data)
	if d.trainerLevel >= Config.TRAINER_MAX_LEVEL then
		return
	end
	local cost = Config.trainerUpgradeCost(d.trainerLevel)
	if d.money < cost then
		notify(plr, "Not enough money!")
		return
	end
	d.money -= cost
	d.trainerLevel += 1
	notify(plr, "Trainer upgraded! +" .. Config.trainerGain(d.trainerLevel) .. " power per train", Color3.fromRGB(90, 255, 90))
end

-- Reclamar la recompensa de un mundo con sus 5 animales descubiertos
function handlers.ClaimWorld(plr: Player, d: Data, epochArg: any)
	local e = tonumber(epochArg)
	local epoch = e and Config.Epochs[e]
	if not epoch or d.claimedWorlds[tostring(e)] then
		return
	end
	for _, a in epoch.animals do
		if not d.discovered[tostring(a.id)] then
			notify(plr, "Discover all 5 beasts of " .. epoch.name .. " first!")
			return
		end
	end
	local reward = Config.worldReward(e :: number)
	d.claimedWorlds[tostring(e)] = true
	d.money += reward.money
	d.power += reward.power
	notify(plr, epoch.name .. " complete! +$" .. reward.money .. " · +" .. reward.power .. " Power", Color3.fromRGB(255, 220, 80))
end

-- Colocar en el establo un animal que traes en la mano
function handlers.Place(plr: Player, d: Data, id: any)
	local pos = table.find(d.held, tonumber(id) or -1)
	if not pos then
		return
	end
	if not inOwnPen(plr) then
		notify(plr, "Go inside your stable to place it!")
		return
	end
	if #d.animals >= Config.stableCapacity(d.stableLevel) then
		notify(plr, "Your stable is full! Upgrade it or sell animals.")
		return
	end
	local animalId = table.remove(d.held, pos) :: number
	table.insert(d.animals, animalId)
	notify(plr, "Placed " .. Config.entryName(animalId) .. "!", Color3.fromRGB(90, 255, 90))
	refreshStable(plr)
	giveHeld(plr)
end

-- Sacar un animal del establo a la mano
function handlers.PickUp(plr: Player, d: Data, slot: any)
	slot = tonumber(slot)
	local id = slot and d.animals[slot]
	if not id or #d.held >= heldMax(d) then
		return
	end
	table.remove(d.animals, slot)
	table.insert(d.held, id)
	refreshStable(plr)
	giveHeld(plr)
end

function handlers.SellHeld(plr: Player, d: Data, slot: any)
	slot = tonumber(slot)
	local id = slot and d.held[slot]
	if not id then
		return
	end
	table.remove(d.held, slot)
	local value = Config.sellValue(id)
	d.money += value
	notify(plr, "Sold " .. Config.entryName(id) .. " for $" .. value, Color3.fromRGB(90, 255, 90))
	giveHeld(plr)
end

function handlers.Sell(plr: Player, d: Data, slot: any)
	slot = tonumber(slot)
	local id = slot and d.animals[slot]
	if not id then
		return
	end
	table.remove(d.animals, slot)
	local value = Config.sellValue(id)
	d.money += value
	notify(plr, "Sold " .. Config.entryName(id) .. " for $" .. value, Color3.fromRGB(90, 255, 90))
	refreshStable(plr)
end

---------------------------------------------------------------- Robux

local function findShopItem(key: string)
	for _, item in Config.Passes do
		if item.key == key then
			return item, true
		end
	end
	for _, item in Config.Products do
		if item.key == key then
			return item, false
		end
	end
	return nil, false
end

local function grantPass(plr: Player, key: string)
	local d = data[plr]
	if not d or d.passes[key] then
		return
	end
	d.passes[key] = true
	local item = findShopItem(key)
	notify(plr, "Thanks! " .. (if item then item.name else key) .. " unlocked!", Color3.fromRGB(255, 220, 80))
	-- Las armas exclusivas se equipan al comprarlas
	for _, w in Config.EXCLUSIVE_WEAPONS do
		if w.pass == key then
			d.owned[tostring(w.index)] = true
			d.equipped = w.index
			giveWeapon(plr)
		end
	end
	push(plr)
end

local function grantProduct(plr: Player, key: string): boolean
	local d = data[plr]
	if not d then
		return false
	end
	if key == "Luck15" then
		d.luckUntil = math.max(d.luckUntil, os.time()) + Config.LUCK_BOOST_MINUTES * 60
		notify(plr, "3x Luck active!", Color3.fromRGB(120, 255, 160))
	elseif key == "Cash" then
		local amount = math.max(5000, income(d) * 600)
		d.money += amount
		notify(plr, "+$" .. amount .. "!", Color3.fromRGB(90, 255, 90))
	else
		return false
	end
	push(plr)
	return true
end

-- Sin ID todavía: en Studio se regala para probar; en el juego publicado avisa
function handlers.TestBuy(plr: Player, d: Data, key: any)
	local item, isPass = findShopItem(tostring(key))
	if not item or item.id ~= 0 then
		return
	end
	if not RunService:IsStudio() then
		notify(plr, "Coming soon!")
		return
	end
	if isPass then
		grantPass(plr, item.key)
	else
		grantProduct(plr, item.key)
	end
end

MarketplaceService.PromptGamePassPurchaseFinished:Connect(function(plr, passId, bought)
	if not bought then
		return
	end
	for _, item in Config.Passes do
		if item.id == passId then
			grantPass(plr, item.key)
		end
	end
end)

MarketplaceService.ProcessReceipt = function(info)
	local plr = Players:GetPlayerByUserId(info.PlayerId)
	if not plr then
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end
	for _, item in Config.Products do
		if item.id == info.ProductId and grantProduct(plr, item.key) then
			return Enum.ProductPurchaseDecision.PurchaseGranted
		end
	end
	return Enum.ProductPurchaseDecision.NotProcessedYet
end

local function checkPasses(plr: Player)
	for _, item in Config.Passes do
		if item.id ~= 0 then
			local ok, owns = pcall(MarketplaceService.UserOwnsGamePassAsync, MarketplaceService, plr.UserId, item.id)
			if ok and owns then
				grantPass(plr, item.key)
			end
		end
	end
end

Action.OnServerEvent:Connect(function(plr, kind, arg)
	local d = data[plr]
	local fn = handlers[kind]
	if not d or not fn then
		return
	end
	fn(plr, d, arg)
	push(plr)
end)

---------------------------------------------------------------- Jugadores

local function load(plr: Player): Data
	local d = defaultData()
	if okStore then
		local ok, saved = pcall(function()
			return store:GetAsync("u" .. plr.UserId)
		end)
		if ok and type(saved) == "table" then
			for k, v in saved do
				(d :: any)[k] = v
			end
		end
	end
	return d
end

local function save(plr: Player)
	local d = data[plr]
	if okStore and d then
		pcall(function()
			store:SetAsync("u" .. plr.UserId, d)
		end)
	end
end

Players.PlayerAdded:Connect(function(plr)
	local ls = Instance.new("Folder")
	ls.Name = "leaderstats"
	local kills = Instance.new("IntValue")
	kills.Name = "Kills"
	kills.Parent = ls
	ls.Parent = plr

	for i = 1, Config.PLOTS do
		local taken = false
		for _, p in plotOf do
			if p == i then
				taken = true
			end
		end
		if not taken then
			plotOf[plr] = i
			break
		end
	end
	data[plr] = load(plr)
	local i = plotOf[plr]
	if i then
		plr:SetAttribute("Plot", i)
		plotModels[i].SignPost.OwnerSign.Text.Text = plr.DisplayName .. "'s Stable"
	end
	push(plr)
	refreshStable(plr)
	task.spawn(checkPasses, plr)

	plr.CharacterAdded:Connect(function(char)
		char:WaitForChild("HumanoidRootPart")
		task.wait()
		sendHome(plr)
		giveWeapon(plr)
		giveHeld(plr)
	end)
	if plr.Character then
		sendHome(plr)
		giveWeapon(plr)
		giveHeld(plr)
	end
end)

Players.PlayerRemoving:Connect(function(plr)
	save(plr)
	local i = plotOf[plr]
	if i then
		plotModels[i].Animals:ClearAllChildren()
		plotModels[i].SignPost.OwnerSign.Text.Text = "Empty Stable"
	end
	data[plr] = nil
	plotOf[plr] = nil
	lastShot[plr] = nil
end)

game:BindToClose(function()
	for _, plr in Players:GetPlayers() do
		save(plr)
	end
end)

-- Entrenador: si estás parado en tu campo de tiro, sube el poder solo
local function onTrainer(plr: Player): boolean
	local i = plotOf[plr]
	local char = plr.Character
	local root = char and char:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not i or not root then
		return false
	end
	local p = plotCFrames[i]:PointToObjectSpace(root.Position)
	-- dentro de la caseta (tarima)
	return p.X > 13 and p.X < 23 and p.Z > 17 and p.Z < 25.5
end

task.spawn(function()
	while true do
		task.wait(0.5)
		for plr, d in data do
			local on = onTrainer(plr)
			if on then
				d.power += Config.trainerGain(d.trainerLevel)
				push(plr)
			end
			if plr:GetAttribute("Training") ~= on then
				plr:SetAttribute("Training", on)
			end
		end
	end
end)

-- Ingresos cada segundo y guardado cada 2 minutos
task.spawn(function()
	local tick = 0
	while true do
		task.wait(1)
		tick += 1
		for plr, d in data do
			local inc = income(d)
			if inc > 0 then
				d.money += inc
				push(plr)
			end
			if tick % 120 == 0 then
				task.spawn(save, plr)
			end
		end
	end
end)

-- Cuando cargan los modelos de Blender se rehacen la tienda, los establos y lo que traen en la mano
Assets.start(function()
	Map.refreshShop()
	for _, plr in Players:GetPlayers() do
		refreshStable(plr)
		giveWeapon(plr)
		giveHeld(plr)
	end
end)
