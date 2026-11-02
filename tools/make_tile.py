# Genera la textura de cuadritos (estilo Steal an Egg): fondo transparente, borde oscuro y cuadro interior
from PIL import Image, ImageDraw
import sys
S = 256
img = Image.new("RGBA", (S, S), (0, 0, 0, 0))
d = ImageDraw.Draw(img)
d.rectangle([0, 0, S - 1, S - 1], outline=(0, 0, 0, 55), width=6)
d.rectangle([6, 6, S - 7, 12], fill=(255, 255, 255, 35))
d.rounded_rectangle([64, 64, S - 65, S - 65], radius=18, outline=(0, 0, 0, 70), width=10)
d.rounded_rectangle([74, 74, S - 75, S - 75], radius=12, fill=(255, 255, 255, 28))
img.save(sys.argv[1])
