-- Textura de cuadritos (estilo Steal an Egg) para pisos y muros
local TILE_IMAGE = "rbxassetid://83613953546188"

return function(part: BasePart, faces: { Enum.NormalId }, studs: number?)
	for _, face in faces do
		local t = Instance.new("Texture")
		t.Texture = TILE_IMAGE
		t.Face = face
		t.StudsPerTileU = studs or 4
		t.StudsPerTileV = studs or 4
		t.Parent = part
	end
end
