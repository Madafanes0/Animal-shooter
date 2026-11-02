-- Kill a Beast: servidor (datos, disparo, establo, entrenador, tienda de armas)
local Players = game:GetService("Players")
local DataStoreService = game:GetService("DataStoreService")
local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local Beasts = require(ReplicatedStorage.Shared.Beasts)
local Map = require(script.Parent.Map)

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
	discovered: { [string]: boolean },
	kills: number,
}

local data: { [Player]: Data } = {}
local plotOf: { [Player]: number } = {}
local plotModels: { [number]: Model } = {}
local lastShot: { [Player]: number } = {}
local lastTrain: { [Player]: number } = {}
local rng = Random.new()

local function defaultData(): Data
	return {
		money = 0,
		power = 0,
		owned = { ["1"] = true },
		equipped = 1,
		stableLevel = 0,
		trainerLevel = 0,
		animals = {},
		discovered = {},
		kills = 0,
	}
end

local function income(d: Data): number
	local total = 0
	for _, id in d.animals do
		total += Config.Animals[id].income
	end
	return total
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
		discovered = d.discovered,
		income = income(d),
		kills = d.kills,
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

local function buildPlot(i: number): Model
	local m = Instance.new("Model")
	m.Name = "Plot" .. i
	local cf = plotCFrames[i]
	plotPart(m, Vector3.new(52, 0.4, 100), cf * CFrame.new(0, 0.2, 0), Color3.fromRGB(120, 225, 80), Enum.Material.SmoothPlastic)

	-- Establo chico (corral al fondo, granero detrás)
	local penCenter = cf * CFrame.new(0, 0, -22)
	local hw, hd = 19, 16
	local c = penCenter.Position
	fence(m, c + Vector3.new(-hw, 0, -hd), c + Vector3.new(hw, 0, -hd))
	fence(m, c + Vector3.new(-hw, 0, -hd), c + Vector3.new(-hw, 0, hd))
	fence(m, c + Vector3.new(hw, 0, -hd), c + Vector3.new(hw, 0, hd))
	fence(m, c + Vector3.new(-hw, 0, hd), c + Vector3.new(-5, 0, hd))
	fence(m, c + Vector3.new(5, 0, hd), c + Vector3.new(hw, 0, hd))
	local barn = plotPart(m, Vector3.new(22, 11, 6), penCenter * CFrame.new(0, 5.5, -hd - 4), Color3.fromRGB(190, 50, 45), Enum.Material.WoodPlanks)
	barn.Name = "Barn"
	plotPart(m, Vector3.new(24, 1.5, 8), penCenter * CFrame.new(0, 11.7, -hd - 4), Color3.fromRGB(240, 240, 240))

	local board = Instance.new("BillboardGui")
	board.Name = "OwnerSign"
	board.Size = UDim2.fromOffset(260, 60)
	board.StudsOffset = Vector3.new(0, 10, 0)
	board.Adornee = barn
	local t = Instance.new("TextLabel")
	t.Name = "Text"
	t.Size = UDim2.fromScale(1, 1)
	t.BackgroundTransparency = 1
	t.Font = Enum.Font.LuckiestGuy
	t.TextScaled = true
	t.TextColor3 = Color3.new(1, 1, 1)
	t.TextStrokeTransparency = 0
	t.Text = "Empty Stable"
	t.Parent = board
	board.Parent = barn

	-- Entrenador de disparo justo afuera del establo, a un lado de la entrada
	local pad = plotPart(m, Vector3.new(9, 0.6, 9), cf * CFrame.new(13, 0.5, 4), Color3.fromRGB(255, 200, 60), Enum.Material.SmoothPlastic)
	pad.Name = "TrainerPad"
	local target = Instance.new("Part")
	target.Anchored = true
	target.Shape = Enum.PartType.Cylinder
	target.Size = Vector3.new(1, 7, 7)
	target.CFrame = cf * CFrame.new(13, 4.5, 16) * CFrame.Angles(0, math.rad(90), 0)
	target.Color = Color3.new(1, 1, 1)
	target.Name = "TrainerTarget"
	target.Parent = m
	local bull = target:Clone()
	bull.Size = Vector3.new(1.1, 2.5, 2.5)
	bull.Color = Color3.fromRGB(230, 40, 40)
	bull.Name = "Bullseye"
	bull.Parent = m
	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = "Train"
	prompt.ActionText = "Train Power"
	prompt.ObjectText = "Shooting Trainer"
	prompt.HoldDuration = 0.4
	prompt.MaxActivationDistance = 10
	prompt.RequiresLineOfSight = false
	prompt.Parent = pad
	local trainerSign = Instance.new("BillboardGui")
	trainerSign.Size = UDim2.fromOffset(200, 36)
	trainerSign.StudsOffset = Vector3.new(0, 9, 0)
	trainerSign.MaxDistance = 60
	trainerSign.Adornee = pad
	local tt = t:Clone()
	tt.Text = "SHOOTING TRAINER"
	tt.TextColor3 = Color3.fromRGB(255, 220, 80)
	tt.Parent = trainerSign
	trainerSign.Parent = pad

	local spawnPart = plotPart(m, Vector3.new(7, 0.4, 7), cf * CFrame.new(-12, 0.5, 6), Color3.fromRGB(80, 160, 255), Enum.Material.SmoothPlastic)
	spawnPart.Name = "Spawn"

	local animals = Instance.new("Folder")
	animals.Name = "Animals"
	animals.Parent = m

	m:SetAttribute("Index", i)
	m.Parent = plotsFolder

	prompt.Triggered:Connect(function(plr)
		if plotOf[plr] ~= i then
			notify(plr, "This is not your trainer!")
			return
		end
		local d = data[plr]
		if not d or os.clock() - (lastTrain[plr] or 0) < 0.35 then
			return
		end
		lastTrain[plr] = os.clock()
		local gain = Config.trainerGain(d.trainerLevel)
		d.power += gain
		Notify:FireClient(plr, "+" .. gain .. " Power", Color3.fromRGB(255, 220, 80), "train")
		push(plr)
	end)
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
	local center = plotCFrames[i] * CFrame.new(0, 0.4, -22)
	local cols = 8
	for n, id in d.animals do
		local col = (n - 1) % cols
		local row = math.floor((n - 1) / cols)
		local pos = center * CFrame.new(-15.4 + col * 4.4, 0, -13.5 + row * 3.8) * CFrame.Angles(0, math.rad(180), 0)
		local beast = Beasts.build(id, pos, true)
		beast:ScaleTo(0.6)
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
	if #d.animals >= Config.stableCapacity(d.stableLevel) then
		return { err = "Your stable is full! Sell or upgrade." }
	end
	lastShot[plr] = os.clock()

	local maxDist = Config.shotDistance(d.equipped, d.power)
	local dist = maxDist * rng:NextNumber(0.8, 1)
	local animal = Config.rollAnimal(dist, rng)
	table.insert(d.animals, animal.id)
	d.discovered[tostring(animal.id)] = true
	d.kills += 1
	push(plr)

	local root = (plr.Character :: Model):FindFirstChild("HumanoidRootPart") :: BasePart
	local x = math.clamp(root.Position.X + rng:NextNumber(-10, 10), -Config.FIELD_WIDTH / 2 + 8, Config.FIELD_WIDTH / 2 - 8)
	-- El animal aparece en el establo cuando termina la animación
	task.delay(4, refreshStable, plr)
	return { dist = dist, x = x, animal = animal.id, weapon = d.equipped }
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
	if d.owned[key] then
		d.equipped = w.index
		notify(plr, "Equipped " .. w.name)
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

function handlers.Sell(plr: Player, d: Data, slot: any)
	slot = tonumber(slot)
	local id = slot and d.animals[slot]
	if not id then
		return
	end
	table.remove(d.animals, slot)
	local value = Config.sellValue(Config.Animals[id])
	d.money += value
	notify(plr, "Sold " .. Config.Animals[id].name .. " for $" .. value, Color3.fromRGB(90, 255, 90))
	refreshStable(plr)
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
		plotModels[i].Barn.OwnerSign.Text.Text = plr.DisplayName .. "'s Stable"
	end
	push(plr)
	refreshStable(plr)

	plr.CharacterAdded:Connect(function(char)
		char:WaitForChild("HumanoidRootPart")
		task.wait()
		sendHome(plr)
	end)
	if plr.Character then
		sendHome(plr)
	end
end)

Players.PlayerRemoving:Connect(function(plr)
	save(plr)
	local i = plotOf[plr]
	if i then
		plotModels[i].Animals:ClearAllChildren()
		plotModels[i].Barn.OwnerSign.Text.Text = "Empty Stable"
	end
	data[plr] = nil
	plotOf[plr] = nil
	lastShot[plr] = nil
	lastTrain[plr] = nil
end)

game:BindToClose(function()
	for _, plr in Players:GetPlayers() do
		save(plr)
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
