# Genera un skybox de cielo estrellado (6 caras PNG en assets/sky). El color depende sólo de la altura de la
# dirección, así que las caras empatan en las orillas; las estrellas son puntos al azar en cada cara.
import numpy as np
from PIL import Image, ImageFilter
import os, sys

N = 1024
OUT = sys.argv[1]
rng = np.random.default_rng(7)
# (altura, color): de abajo del horizonte hacia el cenit
STOPS = [(-1.0, (40, 18, 80)), (-0.05, (120, 60, 170)), (0.0, (255, 150, 200)), (0.08, (150, 90, 220)),
         (0.35, (60, 40, 150)), (0.7, (25, 20, 90)), (1.0, (10, 10, 45))]


def gradient(y):
    out = np.zeros(y.shape + (3,))
    for (y0, c0), (y1, c1) in zip(STOPS, STOPS[1:]):
        m = (y >= y0) & (y <= y1)
        t = ((y - y0) / (y1 - y0))[m][:, None]
        out[m] = np.array(c0) * (1 - t) + np.array(c1) * t
    return out


u, v = np.meshgrid(np.linspace(-1, 1, N), np.linspace(-1, 1, N))
faces = {
    "side": -v / np.sqrt(u * u + v * v + 1),
    "up": 1 / np.sqrt(u * u + v * v + 1),
    "down": -1 / np.sqrt(u * u + v * v + 1),
}


def make(kind, seed):
    y = faces[kind]
    img = gradient(y)
    r = np.random.default_rng(seed)
    # estrellas: más arriba, más estrellas
    count = 900 if kind != "down" else 120
    xs = r.integers(0, N, count)
    ys = r.integers(0, N, count)
    for x, yy in zip(xs, ys):
        h = y[yy, x]
        if h < 0.03 or r.random() > (0.35 + h):
            continue
        b = r.uniform(0.5, 1.0)
        size = 2 if r.random() < 0.85 else 4
        tint = np.array([255, 255, 255]) if r.random() < 0.7 else np.array([255, 220, 150]) if r.random() < 0.5 else np.array([170, 210, 255])
        img[max(0, yy - size // 2):yy + size // 2 + 1, max(0, x - size // 2):x + size // 2 + 1] = img[max(0, yy - size // 2):yy + size // 2 + 1, max(0, x - size // 2):x + size // 2 + 1] * (1 - b) + tint * b
    im = Image.fromarray(np.clip(img, 0, 255).astype(np.uint8))
    glow = im.filter(ImageFilter.GaussianBlur(3))
    return Image.blend(im, glow, 0.25) if False else Image.fromarray(np.clip(np.array(im, dtype=float) + np.array(glow, dtype=float) * 0.35, 0, 255).astype(np.uint8))


os.makedirs(OUT, exist_ok=True)
for i, name in enumerate(["Bk", "Ft", "Lf", "Rt"]):
    make("side", i).save(os.path.join(OUT, f"sky_{name}.png"))
make("up", 10).save(os.path.join(OUT, "sky_Up.png"))
make("down", 11).save(os.path.join(OUT, "sky_Dn.png"))
