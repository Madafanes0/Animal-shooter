-- Vistas 3D chiquitas (ViewportFrame) de animales, armas y Tools para la UI
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Models = require(ReplicatedStorage:WaitForChild("Shared").Models)
local Theme = require(script.Parent.Theme)

local Preview = {}

-- Mete el modelo en un ViewportFrame y acomoda la cámara para que quepa. `from` = dirección desde el modelo
local function frame(model: Model, size: UDim2, parent: Instance?, from: Vector3, zIndex: number?): ViewportFrame
	local vp = Theme.new("ViewportFrame", {
		Size = size,
		BackgroundTransparency = 1,
		Ambient = Color3.fromRGB(190, 190, 200),
		LightColor = Color3.new(1, 1, 1),
		LightDirection = Vector3.new(-1, -2, -1),
		ZIndex = zIndex or 1,
		Parent = parent,
	})
	for _, d in model:GetDescendants() do
		if d:IsA("BillboardGui") or d:IsA("ParticleEmitter") or d:IsA("Script") or d:IsA("LocalScript") then
			d:Destroy()
		end
	end
	model.Parent = vp
	local cf, ext = model:GetBoundingBox()
	local radius = ext.Magnitude / 2
	local cam = Instance.new("Camera")
	cam.FieldOfView = 30
	local dist = radius / math.tan(math.rad(cam.FieldOfView / 2)) * 1.05
	cam.CFrame = CFrame.lookAt(cf.Position + from.Unit * dist, cf.Position)
	cam.Parent = vp
	vp.CurrentCamera = cam
	return vp
end

-- Animal (entrada con variante). `silhouette` = negro (aún no descubierto en el Index)
function Preview.animal(entry: number, size: UDim2, parent: Instance?, silhouette: boolean?, zIndex: number?): ViewportFrame
	local m = Models.animal(entry, CFrame.new(), false)
	local vp = frame(m, size, parent, Vector3.new(-0.7, 0.45, -1), zIndex)
	if silhouette then
		vp.Ambient = Color3.new(0, 0, 0)
		vp.LightColor = Color3.new(0, 0, 0)
		vp.ImageColor3 = Color3.fromRGB(20, 20, 30)
	end
	return vp
end

function Preview.weapon(index: number, size: UDim2, parent: Instance?, zIndex: number?): ViewportFrame
	return frame(Models.weapon(index, CFrame.new()), size, parent, Vector3.new(1, 0.35, -0.25), zIndex)
end

-- Copia visual de un Tool (arma o animal en la mano)
function Preview.tool(tool: Tool, size: UDim2, parent: Instance?, zIndex: number?): ViewportFrame
	local m = Instance.new("Model")
	for _, d in tool:GetChildren() do
		if d:IsA("BasePart") then
			local c = d:Clone()
			c.Anchored = true
			c.Parent = m
		end
	end
	local isWeapon = tool:GetAttribute("WeaponIndex") ~= nil
	return frame(m, size, parent, if isWeapon then Vector3.new(1, 0.35, -0.25) else Vector3.new(-0.7, 0.45, -1), zIndex)
end

return Preview
