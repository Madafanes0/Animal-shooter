# Genera la textura de cuadritos (estilo Steal an Egg), OPACA: blanco con líneas grises. En el juego se tiñe
# con Texture.Color3 = color de la parte (las texturas semitransparentes parpadeaban al mover la cámara).
from PIL import Image, ImageDraw
import sys
S = 256
img = Image.new("RGB", (S, S), (255, 255, 255))
d = ImageDraw.Draw(img)
d.rectangle([0, 0, S - 1, S - 1], outline=(196, 196, 196), width=6)
d.rectangle([6, 6, S - 7, 12], fill=(255, 255, 255))
d.rounded_rectangle([64, 64, S - 65, S - 65], radius=18, outline=(208, 208, 208), width=10)
d.rounded_rectangle([74, 74, S - 75, S - 75], radius=12, fill=(250, 250, 250))
img.save(sys.argv[1])
