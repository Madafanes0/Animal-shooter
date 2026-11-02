-- Textura de cuadritos (estilo Steal an Egg) para pisos y muros. La imagen es opaca (blanco con líneas grises)
-- y se tiñe con el color de la parte; las semitransparentes parpadeaban al mover la cámara.
local TILE_IMAGE = "rbxassetid://137482990298150"

return function(part: BasePart, faces: { Enum.NormalId }, studs: number?)
	for _, face in faces do
		local t = Instance.new("Texture")
		t.Texture = TILE_IMAGE
		t.Face = face
		t.Color3 = part.Color
		t.StudsPerTileU = studs or 4
		t.StudsPerTileV = studs or 4
		t.Parent = part
	end
end
