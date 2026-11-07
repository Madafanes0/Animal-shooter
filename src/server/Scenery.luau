-- Decoración de cada mundo (época) con piezas de bloques con studs: árboles, cactus, corales, hongos, cristales…
-- Cada mundo tiene sus props característicos; se ponen a los lados del pasillo para no tapar la caza.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Config = require(ReplicatedStorage.Shared.Config)
local Tiles = require(ReplicatedStorage.Shared.Tiles)

local Scenery = {}

local ALL = { Enum.NormalId.Top, Enum.NormalId.Bottom, Enum.NormalId.Front, Enum.NormalId.Back, Enum.NormalId.Left, Enum.NormalId.Right }
local rgb = Color3.fromRGB

type Ctx = { parent: Instance, rng: Random }

-- Bloque con studs; `at` es la base (el centro de la cara de abajo) y se apila hacia arriba
local function box(ctx: Ctx, size: Vector3, at: CFrame, color: Color3, material: Enum.Material?, studs: number?): Part
	local p = Instance.new("Part")
	p.Anchored = true
	p.Size = size
	p.CFrame = at * CFrame.new(0, size.Y / 2, 0)
	p.Color = color
	p.Material = material or Enum.Material.SmoothPlastic
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.Parent = ctx.parent
	if p.Material == Enum.Material.SmoothPlastic then
		Tiles(p, ALL, studs or 2)
	end
	return p
end

local function glow(ctx: Ctx, size: Vector3, at: CFrame, color: Color3): Part
	local p = box(ctx, size, at, color, Enum.Material.Neon)
	local light = Instance.new("PointLight")
	light.Color = color
	light.Range = 12
	light.Brightness = 1.5
	light.Parent = p
	return p
end

local function ball(ctx: Ctx, d: number, at: CFrame, color: Color3, material: Enum.Material?): Part
	local p = Instance.new("Part")
	p.Shape = Enum.PartType.Ball
	p.Anchored = true
	p.Size = Vector3.new(d, d, d)
	p.CFrame = at * CFrame.new(0, d / 2, 0)
	p.Color = color
	p.Material = material or Enum.Material.SmoothPlastic
	p.Parent = ctx.parent
	return p
end

local function jitter(ctx: Ctx, c: Color3, amount: number): Color3
	local h, s, v = c:ToHSV()
	return Color3.fromHSV(h, s, math.clamp(v + ctx.rng:NextNumber(-amount, amount), 0, 1))
end

------------------------------------------------------------------ props

local function tree(ctx: Ctx, at: CFrame, trunk: Color3, leaves: Color3, h: number)
	box(ctx, Vector3.new(2, h, 2), at, trunk)
	box(ctx, Vector3.new(9, 3, 9), at * CFrame.new(0, h, 0), jitter(ctx, leaves, 0.06))
	box(ctx, Vector3.new(6, 3, 6), at * CFrame.new(0, h + 3, 0), jitter(ctx, leaves, 0.06))
	box(ctx, Vector3.new(3, 2, 3), at * CFrame.new(0, h + 6, 0), jitter(ctx, leaves, 0.06))
end

local function palm(ctx: Ctx, at: CFrame, leaves: Color3)
	local h = ctx.rng:NextNumber(10, 15)
	for k = 0, 4 do
		box(ctx, Vector3.new(1.6, h / 5, 1.6), at * CFrame.new(k * 0.35, k * h / 5, 0), if k % 2 == 0 then rgb(150, 100, 60) else rgb(125, 82, 48))
	end
	local top = at * CFrame.new(1.6, h, 0)
	for k = 0, 3 do
		box(ctx, Vector3.new(1.4, 0.8, 7), top * CFrame.Angles(0, math.rad(45 + k * 90), 0) * CFrame.new(0, 0, -3) * CFrame.Angles(math.rad(-14), 0, 0), leaves)
	end
	ball(ctx, 1, top * CFrame.new(0.6, -1, 0.6), rgb(120, 80, 40))
end

local function pine(ctx: Ctx, at: CFrame, leaves: Color3, snow: boolean?)
	local h = ctx.rng:NextNumber(3, 5)
	box(ctx, Vector3.new(1.6, h, 1.6), at, rgb(110, 70, 40))
	for k, w in { 9, 7, 5, 3 } do
		local y = h + (k - 1) * 2.6
		box(ctx, Vector3.new(w, 2.6, w), at * CFrame.new(0, y, 0), jitter(ctx, leaves, 0.05))
		if snow then
			box(ctx, Vector3.new(w + 0.2, 0.6, w + 0.2), at * CFrame.new(0, y + 2.4, 0), rgb(245, 248, 255))
		end
	end
end

local function acacia(ctx: Ctx, at: CFrame)
	box(ctx, Vector3.new(1.6, 6, 1.6), at, rgb(120, 85, 50))
	box(ctx, Vector3.new(1.2, 3, 1.2), at * CFrame.new(1.5, 5, 0) * CFrame.Angles(0, 0, math.rad(-35)), rgb(120, 85, 50))
	box(ctx, Vector3.new(14, 1.6, 9), at * CFrame.new(1.5, 7.5, 0), rgb(120, 150, 50))
	box(ctx, Vector3.new(9, 1.2, 6), at * CFrame.new(1.5, 9.1, 0), rgb(135, 165, 60))
end

local function rock(ctx: Ctx, at: CFrame, color: Color3, s: number)
	box(ctx, Vector3.new(4, 2.5, 3.5) * s, at, jitter(ctx, color, 0.08))
	box(ctx, Vector3.new(2.5, 1.8, 2.5) * s, at * CFrame.new(0.6 * s, 2.5 * s, 0.2 * s), jitter(ctx, color, 0.08))
end

local function cactus(ctx: Ctx, at: CFrame)
	local green = rgb(70, 160, 70)
	local h = ctx.rng:NextNumber(6, 9)
	box(ctx, Vector3.new(2, h, 2), at, green)
	for _, side in { -1, 1 } do
		local y = ctx.rng:NextNumber(2, h - 3)
		box(ctx, Vector3.new(2, 1.4, 1.4), at * CFrame.new(side * 1.8, y, 0), green)
		box(ctx, Vector3.new(1.4, 3, 1.4), at * CFrame.new(side * 2.4, y + 1, 0), green)
	end
	box(ctx, Vector3.new(1, 0.8, 1), at * CFrame.new(0, h, 0), rgb(255, 120, 170))
end

local function pyramid(ctx: Ctx, at: CFrame)
	for k = 0, 4 do
		local w = 16 - k * 3.2
		box(ctx, Vector3.new(w, 2.4, w), at * CFrame.new(0, k * 2.4, 0), jitter(ctx, rgb(225, 190, 120), 0.04))
	end
end

local function skull(ctx: Ctx, at: CFrame)
	local bone = rgb(240, 232, 210)
	box(ctx, Vector3.new(3, 2.6, 3), at, bone)
	box(ctx, Vector3.new(0.7, 0.7, 0.2), at * CFrame.new(-0.6, 1.4, -1.5), rgb(30, 30, 30))
	box(ctx, Vector3.new(0.7, 0.7, 0.2), at * CFrame.new(0.6, 1.4, -1.5), rgb(30, 30, 30))
	box(ctx, Vector3.new(4.5, 0.6, 0.6), at * CFrame.new(0, 2.8, 0) * CFrame.Angles(0, 0, math.rad(15)), bone)
end

local function water(ctx: Ctx, at: CFrame, w: number, d: number, color: Color3)
	local p = box(ctx, Vector3.new(w, 0.3, d), at * CFrame.new(0, -0.05, 0), color, Enum.Material.Glass)
	p.Transparency = 0.25
	p.CanCollide = false
end

local function lily(ctx: Ctx, at: CFrame)
	box(ctx, Vector3.new(2.4, 0.2, 2.4), at * CFrame.new(0, 0.25, 0), rgb(80, 170, 70))
	box(ctx, Vector3.new(0.6, 0.6, 0.6), at * CFrame.new(0.4, 0.45, 0.3), rgb(255, 140, 200))
end

local function deadTree(ctx: Ctx, at: CFrame, color: Color3)
	box(ctx, Vector3.new(1.8, 9, 1.8), at, color)
	box(ctx, Vector3.new(1, 4, 1), at * CFrame.new(1.4, 6, 0) * CFrame.Angles(0, 0, math.rad(-40)), color)
	box(ctx, Vector3.new(1, 3.5, 1), at * CFrame.new(-1.3, 4.5, 0.3) * CFrame.Angles(math.rad(10), 0, math.rad(45)), color)
	box(ctx, Vector3.new(0.8, 2.5, 0.8), at * CFrame.new(-0.3, 9, 0) * CFrame.Angles(math.rad(-25), 0, 0), color)
end

local function log(ctx: Ctx, at: CFrame)
	box(ctx, Vector3.new(7, 1.8, 1.8), at * CFrame.Angles(0, ctx.rng:NextNumber(0, math.pi), 0), rgb(120, 78, 45))
end

local function iceSpike(ctx: Ctx, at: CFrame)
	local h = ctx.rng:NextNumber(5, 11)
	local p = box(ctx, Vector3.new(2.4, h, 2.4), at * CFrame.Angles(math.rad(ctx.rng:NextNumber(-10, 10)), 0, math.rad(ctx.rng:NextNumber(-10, 10))), rgb(170, 230, 255), Enum.Material.Ice)
	p.Transparency = 0.15
	box(ctx, Vector3.new(1.4, h * 0.4, 1.4), at * CFrame.new(0, h, 0), rgb(210, 245, 255), Enum.Material.Ice)
end

local function igloo(ctx: Ctx, at: CFrame)
	local snow = rgb(240, 248, 255)
	box(ctx, Vector3.new(10, 3, 10), at, snow)
	box(ctx, Vector3.new(8, 2.6, 8), at * CFrame.new(0, 3, 0), snow)
	box(ctx, Vector3.new(5, 2, 5), at * CFrame.new(0, 5.6, 0), snow)
	box(ctx, Vector3.new(3, 3, 3), at * CFrame.new(0, 0, -5.5), snow)
	box(ctx, Vector3.new(1.8, 2.2, 0.4), at * CFrame.new(0, 0, -7.1), rgb(40, 50, 70))
end

local function peak(ctx: Ctx, at: CFrame)
	local stone = rgb(120, 120, 130)
	for k = 0, 5 do
		local w = 18 - k * 3
		box(ctx, Vector3.new(w, 3, w), at * CFrame.new(ctx.rng:NextNumber(-0.6, 0.6), k * 3, 0), if k >= 4 then rgb(248, 250, 255) else jitter(ctx, stone, 0.05))
	end
end

local function volcano(ctx: Ctx, at: CFrame)
	local stone = rgb(55, 40, 40)
	for k = 0, 4 do
		local w = 18 - k * 3
		box(ctx, Vector3.new(w, 3, w), at * CFrame.new(0, k * 3, 0), jitter(ctx, stone, 0.05))
	end
	glow(ctx, Vector3.new(4, 0.6, 4), at * CFrame.new(0, 15, 0), rgb(255, 110, 20))
	glow(ctx, Vector3.new(1.2, 13, 1.2), at * CFrame.new(3.5, 2, -3.5) * CFrame.Angles(math.rad(-14), 0, math.rad(14)), rgb(255, 140, 30))
end

local function lavaPool(ctx: Ctx, at: CFrame)
	glow(ctx, Vector3.new(8, 0.3, 6), at, rgb(255, 100, 20))
	box(ctx, Vector3.new(9, 0.6, 1), at * CFrame.new(0, 0, 3.4), rgb(45, 35, 35))
	box(ctx, Vector3.new(9, 0.6, 1), at * CFrame.new(0, 0, -3.4), rgb(45, 35, 35))
end

local function coral(ctx: Ctx, at: CFrame)
	local colors = { rgb(255, 110, 140), rgb(255, 160, 60), rgb(200, 90, 230), rgb(80, 210, 220) }
	local c = colors[ctx.rng:NextInteger(1, #colors)]
	box(ctx, Vector3.new(1.4, 5, 1.4), at, c)
	for _, side in { -1, 1 } do
		box(ctx, Vector3.new(1.2, 3, 1.2), at * CFrame.new(side * 1.3, 2.5, 0) * CFrame.Angles(0, 0, math.rad(side * -25)), c)
	end
	ball(ctx, 1.4, at * CFrame.new(0, 5, 0), c)
end

local function seaweed(ctx: Ctx, at: CFrame)
	for k = 0, 3 do
		box(ctx, Vector3.new(0.8, 2, 0.8), at * CFrame.new(math.sin(k) * 0.6, k * 2, 0), rgb(60, 170, 90))
	end
end

local function shell(ctx: Ctx, at: CFrame)
	box(ctx, Vector3.new(2.4, 1, 2), at, rgb(255, 225, 210))
	box(ctx, Vector3.new(1.6, 0.6, 1.4), at * CFrame.new(0, 1, 0), rgb(255, 190, 180))
end

local function stalagmite(ctx: Ctx, at: CFrame, color: Color3)
	local h = ctx.rng:NextNumber(4, 9)
	box(ctx, Vector3.new(2.6, h * 0.5, 2.6), at, color)
	box(ctx, Vector3.new(1.6, h * 0.35, 1.6), at * CFrame.new(0, h * 0.5, 0), color)
	box(ctx, Vector3.new(0.8, h * 0.25, 0.8), at * CFrame.new(0, h * 0.85, 0), color)
end

local function crystal(ctx: Ctx, at: CFrame, color: Color3)
	for k = 1, 3 do
		local h = ctx.rng:NextNumber(3, 8)
		local p = box(ctx, Vector3.new(1.6, h, 1.6), at * CFrame.new(ctx.rng:NextNumber(-1.5, 1.5), 0, ctx.rng:NextNumber(-1.5, 1.5)) * CFrame.Angles(math.rad(ctx.rng:NextNumber(-20, 20)), 0, math.rad(ctx.rng:NextNumber(-20, 20))), color, Enum.Material.Neon)
		p.Transparency = 0.2
	end
	local light = Instance.new("PointLight")
	light.Color = color
	light.Range = 14
	light.Parent = ctx.parent:FindFirstChildWhichIsA("BasePart")
end

local function mushroom(ctx: Ctx, at: CFrame, cap: Color3, s: number)
	box(ctx, Vector3.new(1.8, 5, 1.8) * s, at, rgb(240, 230, 210))
	box(ctx, Vector3.new(8, 2, 8) * s, at * CFrame.new(0, 5 * s, 0), cap)
	box(ctx, Vector3.new(5, 1.4, 5) * s, at * CFrame.new(0, 7 * s, 0), cap)
	for _, o in { Vector3.new(2, 0, 1.5), Vector3.new(-1.8, 0, -1.5), Vector3.new(0.5, 0, -3) } do
		box(ctx, Vector3.new(1.2, 0.3, 1.2) * s, at * CFrame.new(o * s + Vector3.new(0, 7 * s, 0)), rgb(255, 255, 255))
	end
end

local function fern(ctx: Ctx, at: CFrame)
	for k = 0, 4 do
		box(ctx, Vector3.new(1, 0.5, 5), at * CFrame.Angles(0, math.rad(k * 72), 0) * CFrame.new(0, 0.4, -2) * CFrame.Angles(math.rad(25), 0, 0), rgb(70, 150, 60))
	end
end

local function bones(ctx: Ctx, at: CFrame)
	local bone = rgb(240, 232, 210)
	box(ctx, Vector3.new(1.2, 1.2, 12), at, bone)
	for k = -2, 2 do
		box(ctx, Vector3.new(7, 1, 1), at * CFrame.new(0, 2.5, k * 2.2) * CFrame.Angles(0, 0, math.rad(90)) * CFrame.new(0, -3, 0), bone)
	end
end

local function egg(ctx: Ctx, at: CFrame)
	ball(ctx, 2.6, at, rgb(235, 225, 180))
	box(ctx, Vector3.new(4, 0.6, 4), at, rgb(140, 110, 60))
end

local function lollipop(ctx: Ctx, at: CFrame)
	box(ctx, Vector3.new(0.6, 7, 0.6), at, rgb(255, 255, 255))
	local colors = { rgb(255, 90, 160), rgb(120, 220, 255), rgb(255, 220, 80), rgb(150, 255, 150) }
	box(ctx, Vector3.new(4.5, 4.5, 1), at * CFrame.new(0, 7, 0), colors[ctx.rng:NextInteger(1, #colors)])
	box(ctx, Vector3.new(2.2, 2.2, 1.1), at * CFrame.new(0, 8.15, 0), rgb(255, 255, 255))
end

local function candyCane(ctx: Ctx, at: CFrame)
	for k = 0, 4 do
		box(ctx, Vector3.new(1.2, 1.6, 1.2), at * CFrame.new(0, k * 1.6, 0), if k % 2 == 0 then rgb(240, 40, 60) else rgb(255, 255, 255))
	end
	box(ctx, Vector3.new(3, 1.2, 1.2), at * CFrame.new(1, 8, 0), rgb(240, 40, 60))
	box(ctx, Vector3.new(1.2, 2, 1.2), at * CFrame.new(2.4, 6.4, 0), rgb(255, 255, 255))
end

local function gumdrop(ctx: Ctx, at: CFrame)
	local colors = { rgb(255, 90, 160), rgb(120, 220, 255), rgb(255, 220, 80), rgb(150, 255, 150), rgb(200, 120, 255) }
	local c = colors[ctx.rng:NextInteger(1, #colors)]
	box(ctx, Vector3.new(3, 1.6, 3), at, c)
	box(ctx, Vector3.new(2, 1.2, 2), at * CFrame.new(0, 1.6, 0), c)
end

local function cupcake(ctx: Ctx, at: CFrame)
	box(ctx, Vector3.new(5, 3, 5), at, rgb(200, 140, 90))
	box(ctx, Vector3.new(5.6, 1.6, 5.6), at * CFrame.new(0, 3, 0), rgb(255, 170, 210))
	box(ctx, Vector3.new(3.6, 1.4, 3.6), at * CFrame.new(0, 4.6, 0), rgb(255, 200, 225))
	box(ctx, Vector3.new(1, 1, 1), at * CFrame.new(0, 6, 0), rgb(230, 30, 60))
end

local function tombstone(ctx: Ctx, at: CFrame)
	box(ctx, Vector3.new(3, 4, 0.8), at * CFrame.Angles(0, 0, math.rad(ctx.rng:NextNumber(-8, 8))), rgb(130, 130, 145))
	box(ctx, Vector3.new(1.8, 0.4, 0.2), at * CFrame.new(0, 2.6, -0.45), rgb(80, 80, 90))
	box(ctx, Vector3.new(3.4, 0.5, 2.4), at, rgb(70, 55, 45))
end

local function pumpkin(ctx: Ctx, at: CFrame)
	box(ctx, Vector3.new(3, 2.4, 3), at, rgb(255, 130, 20))
	box(ctx, Vector3.new(0.5, 0.8, 0.5), at * CFrame.new(0, 2.4, 0), rgb(70, 120, 40))
	glow(ctx, Vector3.new(0.6, 0.6, 0.2), at * CFrame.new(-0.6, 1.4, -1.55), rgb(255, 230, 80))
	glow(ctx, Vector3.new(0.6, 0.6, 0.2), at * CFrame.new(0.6, 1.4, -1.55), rgb(255, 230, 80))
end

local function cloud(ctx: Ctx, at: CFrame)
	local white = rgb(255, 255, 255)
	box(ctx, Vector3.new(10, 3, 6), at, white)
	box(ctx, Vector3.new(6, 2.4, 4), at * CFrame.new(-1, 3, 0), white)
	box(ctx, Vector3.new(4, 2, 4), at * CFrame.new(3, 3, 0.5), white)
end

local function floatingIsland(ctx: Ctx, at: CFrame)
	local up = at * CFrame.new(0, ctx.rng:NextNumber(8, 14), 0)
	box(ctx, Vector3.new(8, 1.6, 8), up, rgb(110, 210, 80))
	box(ctx, Vector3.new(6, 2.4, 6), up * CFrame.new(0, -2.4, 0), rgb(140, 100, 60))
	box(ctx, Vector3.new(3, 2, 3), up * CFrame.new(0, -4.4, 0), rgb(120, 85, 50))
	tree(ctx, up * CFrame.new(1.5, 1.6, 0), rgb(120, 80, 45), rgb(90, 200, 90), 2)
end

local function crater(ctx: Ctx, at: CFrame)
	local grey = rgb(150, 150, 160)
	for k = 0, 7 do
		box(ctx, Vector3.new(3, 1.2, 1.6), at * CFrame.Angles(0, math.rad(k * 45), 0) * CFrame.new(0, 0, -4), jitter(ctx, grey, 0.05))
	end
	box(ctx, Vector3.new(6, 0.2, 6), at, rgb(110, 110, 120))
end

local function antenna(ctx: Ctx, at: CFrame)
	box(ctx, Vector3.new(4, 1, 4), at, rgb(200, 205, 215))
	box(ctx, Vector3.new(0.6, 9, 0.6), at * CFrame.new(0, 1, 0), rgb(180, 185, 195), Enum.Material.Metal)
	box(ctx, Vector3.new(5, 0.4, 5), at * CFrame.new(0, 7, 0) * CFrame.Angles(math.rad(30), 0, 0), rgb(230, 235, 240), Enum.Material.Metal)
	glow(ctx, Vector3.new(0.8, 0.8, 0.8), at * CFrame.new(0, 10, 0), rgb(255, 60, 60))
end

local function planet(ctx: Ctx, at: CFrame)
	local colors = { rgb(255, 120, 220), rgb(120, 200, 255), rgb(255, 200, 90), rgb(160, 120, 255) }
	local up = at * CFrame.new(0, ctx.rng:NextNumber(10, 22), 0)
	local d = ctx.rng:NextNumber(4, 8)
	ball(ctx, d, up, colors[ctx.rng:NextInteger(1, #colors)])
	local ring = box(ctx, Vector3.new(d * 1.8, 0.3, d * 1.8), up * CFrame.new(0, d / 2, 0) * CFrame.Angles(math.rad(20), 0, 0), rgb(255, 255, 255), Enum.Material.Neon)
	ring.Transparency = 0.4
end

local function voidSpike(ctx: Ctx, at: CFrame)
	glow(ctx, Vector3.new(1.4, ctx.rng:NextNumber(5, 12), 1.4), at * CFrame.Angles(math.rad(ctx.rng:NextNumber(-15, 15)), 0, math.rad(ctx.rng:NextNumber(-15, 15))), rgb(255, 80, 255))
end

local function bush(ctx: Ctx, at: CFrame, color: Color3)
	box(ctx, Vector3.new(6, 2.6, 5), at, jitter(ctx, color, 0.06))
	box(ctx, Vector3.new(4, 2, 3.6), at * CFrame.new(0.6, 2.6, 0), jitter(ctx, color, 0.06))
end

------------------------------------------------------------------ mundos

-- Para cada mundo: lista de { prop, peso } (los "grandes" se ponen pegados a los muros)
local BIG = true
local WORLDS: { [number]: { { any } } } = {
	{ { function(c, a) tree(c, a, rgb(110, 75, 40), rgb(50, 160, 50), 7) end, 3, BIG }, { function(c, a) palm(c, a, rgb(60, 180, 60)) end, 3, BIG }, { function(c, a) bush(c, a, rgb(50, 150, 50)) end, 3 }, { fern, 2 } },
	{ { acacia, 4, BIG }, { function(c, a) rock(c, a, rgb(170, 140, 100), 1) end, 2 }, { function(c, a) bush(c, a, rgb(180, 170, 80)) end, 3 } },
	{ { cactus, 5 }, { pyramid, 1, BIG }, { skull, 2 }, { function(c, a) rock(c, a, rgb(210, 170, 110), 1.2) end, 2 } },
	{ { function(c, a) deadTree(c, a, rgb(80, 70, 50)) end, 3, BIG }, { function(c, a) water(c, a, 12, 8, rgb(80, 120, 70)) lily(c, a) end, 3 }, { function(c, a) mushroom(c, a, rgb(150, 110, 60), 0.6) end, 2 } },
	{ { function(c, a) pine(c, a, rgb(40, 120, 60)) end, 5, BIG }, { log, 2 }, { function(c, a) rock(c, a, rgb(130, 130, 125), 1) end, 2 } },
	{ { function(c, a) pine(c, a, rgb(60, 110, 80), true) end, 4, BIG }, { function(c, a) rock(c, a, rgb(235, 240, 248), 1.1) end, 3 }, { function(c, a) bush(c, a, rgb(220, 230, 240)) end, 2 } },
	{ { iceSpike, 5 }, { igloo, 1, BIG }, { function(c, a) rock(c, a, rgb(200, 235, 255), 1.3) end, 2 } },
	{ { peak, 2, BIG }, { function(c, a) rock(c, a, rgb(120, 120, 130), 1.4) end, 4 }, { function(c, a) pine(c, a, rgb(50, 100, 70), true) end, 2, BIG } },
	{ { volcano, 1, BIG }, { lavaPool, 3 }, { function(c, a) rock(c, a, rgb(50, 40, 40), 1.2) end, 3 } },
	{ { coral, 5 }, { seaweed, 3 }, { shell, 3 }, { function(c, a) water(c, a, 14, 10, rgb(60, 170, 220)) end, 1 } },
	{ { function(c, a) stalagmite(c, a, rgb(90, 85, 100)) end, 5 }, { function(c, a) crystal(c, a, rgb(120, 220, 255)) end, 2 }, { function(c, a) rock(c, a, rgb(70, 70, 80), 1.2) end, 2 } },
	{ { function(c, a) mushroom(c, a, rgb(230, 50, 60), c.rng:NextNumber(0.9, 1.6)) end, 3, BIG }, { function(c, a) mushroom(c, a, rgb(150, 80, 230), c.rng:NextNumber(0.5, 1)) end, 3 }, { function(c, a) glow(c, Vector3.new(0.8, 0.8, 0.8), a * CFrame.new(0, 1.5, 0), rgb(160, 255, 120)) end, 2 } },
	{ { fern, 4 }, { bones, 2, BIG }, { egg, 2 }, { function(c, a) palm(c, a, rgb(70, 150, 50)) end, 2, BIG } },
	{ { function(c, a) pine(c, a, rgb(150, 200, 220), true) end, 3, BIG }, { iceSpike, 2 }, { bones, 1, BIG }, { function(c, a) rock(c, a, rgb(200, 225, 240), 1.2) end, 2 } },
	{ { lollipop, 4 }, { candyCane, 3 }, { gumdrop, 4 }, { cupcake, 2, BIG } },
	{ { function(c, a) deadTree(c, a, rgb(50, 40, 55)) end, 4, BIG }, { tombstone, 4 }, { pumpkin, 3 } },
	{ { function(c, a) crystal(c, a, rgb(200, 120, 255)) end, 3 }, { function(c, a) crystal(c, a, rgb(90, 230, 230)) end, 3 }, { function(c, a) stalagmite(c, a, rgb(80, 120, 160)) end, 2 } },
	{ { cloud, 4 }, { floatingIsland, 2, BIG }, { function(c, a) bush(c, a, rgb(255, 230, 120)) end, 2 } },
	{ { crater, 3 }, { antenna, 2, BIG }, { function(c, a) rock(c, a, rgb(170, 170, 180), 1.2) end, 3 } },
	{ { planet, 3, BIG }, { voidSpike, 5 }, { function(c, a) crystal(c, a, rgb(255, 90, 255)) end, 2 } },
}

local function pick(rng: Random, list: { { any } })
	local total = 0
	for _, e in list do
		total += e[2]
	end
	local roll = rng:NextNumber() * total
	for _, e in list do
		roll -= e[2]
		if roll <= 0 then
			return e
		end
	end
	return list[1]
end

-- Llena la franja de una época (de z0 a z1) con sus props a los lados del pasillo
function Scenery.decorate(epochIndex: number, z0: number, z1: number, parent: Instance)
	local folder = Instance.new("Folder")
	folder.Name = "Scenery" .. epochIndex
	folder.Parent = parent
	local ctx: Ctx = { parent = folder, rng = Random.new(epochIndex * 97) }
	local halfW = Config.FIELD_WIDTH / 2
	local list = WORLDS[epochIndex]
	for side = -1, 1, 2 do
		local z = z0 + 8
		while z < z1 - 8 do
			local e = pick(ctx.rng, list)
			local big = e[3] == BIG
			local x = side * (if big then halfW - 10 else ctx.rng:NextNumber(halfW - 26, halfW - 6))
			local at = CFrame.new(x, 0, z) * CFrame.Angles(0, ctx.rng:NextNumber(0, math.pi * 2), 0)
			e[1](ctx, at)
			z += if big then ctx.rng:NextNumber(20, 28) else ctx.rng:NextNumber(10, 16)
		end
	end
	-- unos pocos chicos en el centro para que no se vea vacío
	for _ = 1, 3 do
		local e = pick(ctx.rng, list)
		if e[3] ~= BIG then
			e[1](ctx, CFrame.new(ctx.rng:NextNumber(-halfW + 20, halfW - 20), 0, ctx.rng:NextNumber(z0 + 15, z1 - 15)) * CFrame.Angles(0, ctx.rng:NextNumber(0, math.pi * 2), 0))
		end
	end
end

return Scenery
