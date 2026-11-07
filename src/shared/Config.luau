-- Kill a Beast: toda la configuración del juego (épocas, armas, animales, economía)
local C = {}

-- Mapa: la línea de tiro está en z = 0; el campo arranca en FIELD_START y cada época mide ZONE_LEN
C.ZONE_LEN = 120
C.FIELD_START = 20
C.FIELD_WIDTH = 100
C.NUM_EPOCHS = 20
C.MAX_DIST = C.ZONE_LEN * C.NUM_EPOCHS - 6
C.SHOT_COOLDOWN = 3
C.PLOTS = 6
C.HELD_MAX = 25 -- animales cargados sin colocar

C.Rarities = {
	{ name = "Common", color = Color3.fromRGB(200, 200, 200), weight = 60, mult = 1, scale = 1 },
	{ name = "Uncommon", color = Color3.fromRGB(85, 220, 90), weight = 25, mult = 2.5, scale = 1.1 },
	{ name = "Rare", color = Color3.fromRGB(70, 150, 255), weight = 10, mult = 6, scale = 1.25 },
	{ name = "Epic", color = Color3.fromRGB(180, 80, 255), weight = 4, mult = 15, scale = 1.45 },
	{ name = "Legendary", color = Color3.fromRGB(255, 190, 40), weight = 1, mult = 40, scale = 1.8 },
}

-- name, color del suelo, color de muro A, color de muro B, color de props
local epochDefs = {
	{ "Jungle", "#5fd13a", "#c8774a", "#b06640", "#2f8f2a", { "Frog", "Parrot", "Monkey", "Jaguar", "Golden Gorilla" } },
	{ "Savanna", "#c9c25a", "#c99a4a", "#b3853c", "#7a8f2a", { "Zebra", "Gazelle", "Hyena", "Lion", "Elder Elephant" } },
	{ "Desert", "#ecd38a", "#d9a35a", "#c48c48", "#5f9a3a", { "Lizard", "Scorpion", "Fennec Fox", "Camel", "Sand Wyrm" } },
	{ "Swamp", "#5a7a3a", "#5f5a3a", "#4c4830", "#3a5a2a", { "Toad", "Heron", "Crocodile", "Hippo", "Swamp Hydra" } },
	{ "Pine Forest", "#3f9a4a", "#7a5a3a", "#684c30", "#1f5f2f", { "Squirrel", "Deer", "Boar", "Brown Bear", "Antler King" } },
	{ "Tundra", "#d8e2d0", "#8a9aa0", "#76878e", "#6a8a6a", { "Arctic Hare", "Snow Fox", "Reindeer", "Musk Ox", "Frost Elk" } },
	{ "Glacier", "#e8f6ff", "#9fd2f0", "#86bfe2", "#bfe8ff", { "Penguin", "Seal", "Walrus", "Polar Bear", "Ice Phoenix" } },
	{ "Mountains", "#8f8f8f", "#6f6f78", "#5c5c66", "#f2f2f2", { "Goat", "Eagle", "Ibex", "Snow Leopard", "Yeti" } },
	{ "Volcano", "#3a2a2a", "#7a2a1a", "#5f1f14", "#ff6a1a", { "Fire Salamander", "Lava Beetle", "Magma Crab", "Ash Rhino", "Volcano Drake" } },
	{ "Coral Reef", "#f2e0a8", "#2a8ac8", "#2274a8", "#ff7a9a", { "Crab", "Turtle", "Shark", "Octopus", "Kraken" } },
	{ "Deep Caves", "#4a4a52", "#35353c", "#2a2a30", "#6a6a7a", { "Bat", "Cave Spider", "Mole Rat", "Blind Bear", "Cave Basilisk" } },
	{ "Mushroom Grove", "#7a5aa0", "#a05a8a", "#8a4a76", "#ff4a4a", { "Snail", "Glow Moth", "Spore Boar", "Fungus Stag", "Mycelium Titan" } },
	{ "Prehistoric", "#6aa04a", "#9a6a3a", "#84582e", "#3a7a2a", { "Compy", "Raptor", "Triceratops", "Stegosaurus", "T-Rex" } },
	{ "Ice Age", "#cfe2ea", "#8aa8b8", "#7694a4", "#a8d0e0", { "Dodo", "Saber Cat", "Woolly Rhino", "Mammoth", "Glacier Behemoth" } },
	{ "Candy Land", "#ffb6e1", "#ff7ab8", "#e865a2", "#7ae0ff", { "Gummy Bear", "Candy Bunny", "Choco Moose", "Lollipop Llama", "Cake Dragon" } },
	{ "Haunted Woods", "#3a3a4a", "#4a3a5a", "#3a2c48", "#6a4a8a", { "Crow", "Ghost Cat", "Werewolf", "Headless Horse", "Banshee Owl" } },
	{ "Crystal Caverns", "#5ac8c8", "#4a8ab8", "#3c76a2", "#c87aff", { "Gem Beetle", "Quartz Fox", "Amethyst Lynx", "Diamond Bull", "Prism Serpent" } },
	{ "Sky Islands", "#a8e8ff", "#ffffff", "#e6eef5", "#ffe07a", { "Cloud Sheep", "Sky Ray", "Thunder Hawk", "Pegasus", "Storm Griffin" } },
	{ "Moon Base", "#b8b8c0", "#5a5a6a", "#4a4a58", "#e0e0f0", { "Moon Rabbit", "Space Slug", "Crater Crab", "Astro Wolf", "Lunar Whale" } },
	{ "Cosmic Void", "#1a1030", "#2a1a50", "#1f1240", "#ff5aff", { "Void Mite", "Star Jelly", "Nebula Fox", "Galaxy Stag", "Cosmic Leviathan" } },
}

-- Forma del modelo según el nombre (lo demás es cuadrúpedo)
local kinds = {
	bird = { "Parrot", "Heron", "Penguin", "Eagle", "Ice Phoenix", "Crow", "Banshee Owl", "Thunder Hawk", "Dodo", "Glow Moth", "Storm Griffin" },
	serpent = { "Sand Wyrm", "Swamp Hydra", "Shark", "Kraken", "Prism Serpent", "Lunar Whale", "Cosmic Leviathan", "Star Jelly", "Space Slug", "Snail", "Cave Basilisk", "Lizard", "Fire Salamander", "Crocodile", "Sky Ray" },
	bug = { "Scorpion", "Lava Beetle", "Gem Beetle", "Cave Spider", "Void Mite", "Crab", "Magma Crab", "Crater Crab", "Octopus", "Bat" },
}
local kindOf = {}
for kind, names in kinds do
	for _, n in names do
		kindOf[n] = kind
	end
end

C.Epochs = {}
C.Animals = {} -- id -> animal
C.AnimalOrder = {}

for e, def in epochDefs do
	local epoch = {
		index = e,
		name = def[1],
		ground = Color3.fromHex(def[2]),
		wallA = Color3.fromHex(def[3]),
		wallB = Color3.fromHex(def[4]),
		prop = Color3.fromHex(def[5]),
		animals = {},
	}
	local base = math.floor(1.9 ^ (e - 1) * 10) / 10
	for r, name in def[6] do
		local h = (e * 0.137 + r * 0.19) % 1
		local id = e * 10 + r
		local animal = {
			id = id,
			name = name,
			epoch = e,
			rarity = r,
			kind = kindOf[name] or "quad",
			income = math.max(1, math.floor(base * C.Rarities[r].mult + 0.5)),
			color = Color3.fromHSV(h, 0.5, 0.9),
			color2 = Color3.fromHSV(h, 0.65, 0.6),
		}
		C.Animals[id] = animal
		table.insert(C.AnimalOrder, id)
		table.insert(epoch.animals, animal)
	end
	C.Epochs[e] = epoch
end

local weaponNames = {
	"Slingshot", "Rock Sling", "Boomerang", "Blowgun", "Wooden Bow",
	"Spear Thrower", "Longbow", "Crossbow", "Musket", "Flintlock",
	"Revolver", "Hunting Rifle", "Double Shotgun", "Harpoon Gun", "Sniper Rifle",
	"Golden Crossbow", "Plasma Rifle", "Railgun", "Meteor Launcher", "Cosmic Cannon",
}

-- El arma i llega, sin poder, hasta la época i
C.Weapons = {}
for i, name in weaponNames do
	C.Weapons[i] = {
		index = i,
		name = name,
		range = (i - 1) * C.ZONE_LEN + 90,
		price = if i == 1 then 0 else math.floor(250 * 2.45 ^ (i - 2)),
		color = Color3.fromHSV((i * 0.11) % 1, 0.6, 1),
	}
end

-- Armas exclusivas (pase de Robux): llegan lejos y dan suerte extra. `base` = modelo que usan (pintado).
C.EXCLUSIVE_WEAPONS = {
	{ name = "Ruby Crossbow", base = 16, range = 7 * C.ZONE_LEN + 90, luck = 1.5, color = Color3.fromRGB(255, 40, 80), pass = "W21" },
	{ name = "Thunder Railgun", base = 18, range = 13 * C.ZONE_LEN + 90, luck = 2, color = Color3.fromRGB(255, 230, 40), pass = "W22" },
	{ name = "Dragon Cannon", base = 20, range = C.MAX_DIST, luck = 3, color = Color3.fromRGB(255, 120, 20), pass = "W23" },
}
for k, w in C.EXCLUSIVE_WEAPONS do
	local index = 20 + k
	w.index = index
	w.exclusive = true
	w.price = 0
	C.Weapons[index] = w
end

-- Variantes: salen al azar al cazar y multiplican el ingreso
C.Variants = {
	[0] = { name = "", mult = 1, chance = 1 },
	{ name = "Golden", mult = 2, chance = 1 / 25, color = Color3.fromRGB(255, 200, 40) },
	{ name = "Diamond", mult = 6, chance = 1 / 250, color = Color3.fromRGB(130, 230, 255) },
	{ name = "Rainbow", mult = 12, chance = 1 / 1000, color = Color3.fromRGB(255, 90, 220) },
	{ name = "Platinum", mult = 3.5, chance = 1 / 80, color = Color3.fromRGB(225, 230, 240) },
}
-- Orden de tirada: de la más rara a la más común (los IDs no van en orden porque Platinum llegó después)
local variantOrder = {}
for v in C.Variants do
	if v > 0 then
		table.insert(variantOrder, v)
	end
end
table.sort(variantOrder, function(x, y)
	return C.Variants[x].chance < C.Variants[y].chance
end)

-- Tamaños: cambian qué tan grande se ve en el establo y su ingreso
C.Sizes = {
	[0] = { name = "", scale = 1, mult = 1, chance = 1 },
	{ name = "Mini", scale = 0.55, mult = 1.25, chance = 1 / 10 },
	{ name = "Big", scale = 1.45, mult = 1.6, chance = 1 / 12 },
	{ name = "Giant", scale = 2.1, mult = 3, chance = 1 / 45 },
	{ name = "Colossal", scale = 3.2, mult = 8, chance = 1 / 250 },
}

-- Un animal guardado es un número: tamaño * 10000 + variante * 1000 + id
function C.entry(id: number, variant: number, size: number?): number
	return (size or 0) * 10000 + variant * 1000 + id
end
function C.decode(entry: number)
	local size = math.floor(entry / 10000)
	local variant = math.floor(entry / 1000) % 10
	return C.Animals[entry % 1000], variant, size
end
function C.entryName(entry: number): string
	local a, v, size = C.decode(entry)
	local parts = {}
	if size > 0 then
		table.insert(parts, C.Sizes[size].name)
	end
	if v > 0 then
		table.insert(parts, C.Variants[v].name)
	end
	table.insert(parts, a.name)
	return table.concat(parts, " ")
end
function C.entryIncome(entry: number): number
	local a, v, size = C.decode(entry)
	return math.floor(a.income * C.Variants[v].mult * C.Sizes[size].mult + 0.5)
end

-- Devuelve la variante (la más rara primero) y su probabilidad
function C.rollVariant(rng: Random, luckMult: number)
	for _, v in variantOrder do
		local chance = math.min(C.Variants[v].chance * luckMult, 0.5)
		if rng:NextNumber() < chance then
			return v, chance
		end
	end
	return 0, 1
end

-- Tamaño: la suerte sólo ayuda a los grandes (Mini sale igual)
function C.rollSize(rng: Random, luckMult: number)
	for _, size in { 4, 3, 2, 1 } do
		local chance = C.Sizes[size].chance * (if size >= 2 then luckMult else 1)
		chance = math.min(chance, 0.4)
		if rng:NextNumber() < chance then
			return size, chance
		end
	end
	return 0, 1
end

-- Tienda de Robux. Pon el ID real del pase/producto (Creator Dashboard); con 0 sólo se puede probar en Studio.
C.Passes = {
	{ key = "Luck2", name = "2x Luck", desc = "Double luck on every shot", price = 199, id = 0, color = Color3.fromRGB(80, 220, 120) },
	{ key = "Money2", name = "2x Money", desc = "Your stable earns double", price = 149, id = 0, color = Color3.fromRGB(90, 255, 90) },
	{ key = "BigHands", name = "+50 Hand Slots", desc = "Carry 75 animals at once", price = 79, id = 0, color = Color3.fromRGB(255, 180, 60) },
	{ key = "W21", name = "Ruby Crossbow", desc = "Exclusive · 1.5x luck · Epoch 8", price = 249, id = 0, color = C.EXCLUSIVE_WEAPONS[1].color },
	{ key = "W22", name = "Thunder Railgun", desc = "Exclusive · 2x luck · Epoch 14", price = 599, id = 0, color = C.EXCLUSIVE_WEAPONS[2].color },
	{ key = "W23", name = "Dragon Cannon", desc = "Exclusive · 3x luck · Max reach", price = 1499, id = 0, color = C.EXCLUSIVE_WEAPONS[3].color },
}
C.Products = {
	{ key = "Luck15", name = "3x Luck · 15 min", desc = "Stacks with 2x Luck", price = 49, id = 0, color = Color3.fromRGB(120, 255, 160) },
	{ key = "Cash", name = "Cash Pack", desc = "10 minutes of income (min $5K)", price = 99, id = 0, color = Color3.fromRGB(90, 255, 90) },
}
C.LUCK_BOOST_MINUTES = 15

-- Establo y entrenador
C.STABLE_BASE = 10
C.STABLE_PER_LEVEL = 5
C.STABLE_MAX_LEVEL = 10
function C.stableCapacity(level: number): number
	return C.STABLE_BASE + level * C.STABLE_PER_LEVEL
end
function C.stableUpgradeCost(level: number): number
	return math.floor(400 * 2.3 ^ level)
end

C.TRAINER_MAX_LEVEL = 25
function C.trainerGain(level: number): number
	return level + 1
end
function C.trainerUpgradeCost(level: number): number
	return math.floor(200 * 1.9 ^ level)
end

-- El poder suma alcance con rendimiento decreciente: 100 = +24 %, 10K = +48 %, 1M = +72 %, 1B = +108 %
function C.powerMult(power: number): number
	return 1 + math.log10(1 + math.max(power, 0)) * 0.12
end
function C.shotDistance(weaponIndex: number, power: number): number
	return math.min(C.Weapons[weaponIndex].range * C.powerMult(power), C.MAX_DIST)
end

function C.epochAt(dist: number): number
	return math.clamp(math.floor(dist / C.ZONE_LEN) + 1, 1, C.NUM_EPOCHS)
end

-- Mientras más lejos llega la bala dentro de su época, más suerte
function C.luckAt(dist: number): number
	local within = (dist % C.ZONE_LEN) / C.ZONE_LEN
	return 1 + within * 2 + dist / 800
end

-- Devuelve el animal y la probabilidad de su rareza
function C.rollAnimal(dist: number, rng: Random, luckMult: number?)
	local epoch = C.Epochs[C.epochAt(dist)]
	local luck = C.luckAt(dist) * (luckMult or 1)
	local total = 0
	local weights = {}
	for r, rar in C.Rarities do
		local w = rar.weight * luck ^ (r - 1)
		weights[r] = w
		total += w
	end
	local roll = rng:NextNumber() * total
	for r = 1, #weights do
		roll -= weights[r]
		if roll <= 0 then
			return epoch.animals[r], weights[r] / total
		end
	end
	return epoch.animals[1], weights[1] / total
end

-- Recompensa por descubrir los 5 animales de un mundo (época)
function C.worldReward(epoch: number)
	return { money = math.floor(3000 * 2.6 ^ (epoch - 1)), power = math.floor(100 * 3 ^ (epoch - 1)) }
end

function C.sellValue(entry: number): number
	return C.entryIncome(entry) * 25
end

return C
