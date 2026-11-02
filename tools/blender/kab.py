# Kill a Beast: genera en Blender los 100 animales y las 20 armas (estilo cartoon low-poly) y los exporta a FBX.
# Colores con "paleta": cada pieza usa un cuadrito de una textura chica, así cada modelo es un solo MeshPart.
# Uso en la consola de Blender (o por MCP):
#   exec(open("/Users/madafanes/roblots/kill-a-beast/tools/blender/kab.py").read())
#   build_animal("Lion"); export("Lion", "animals/22")      # uno
#   export_all()                                              # todos
# Ejes: el frente del modelo es -Y y arriba +Z; el FBX se exporta con axis_forward=-Z, axis_up=Y.
import bpy, math, os
from mathutils import Vector, Euler

ROOT = "/Users/madafanes/roblots/kill-a-beast"
OUT = os.path.join(ROOT, "assets", "models")
COLL = "KAB"

# ------------------------------------------------------------------ especies
# nombre: (forma, color cuerpo, color secundario, extras)
SPECIES = {
    # 1 Jungle
    "Frog": ("frog", "#5cc83c", "#d8f0a0", ""),
    "Parrot": ("bird", "#e8352c", "#2f7de0", "crest longtail"),
    "Monkey": ("quad", "#8a5a34", "#e8c49a", "ears_round tail_long face"),
    "Jaguar": ("quad", "#e8a43c", "#fff0d0", "ears_round spots tail_long"),
    "Golden Gorilla": ("ape", "#f2c032", "#7a5a2a", "ears_round"),
    # 2 Savanna
    "Zebra": ("quad", "#f4f4f4", "#222222", "ears_pointy stripes mane tail_thin"),
    "Gazelle": ("quad", "#d39a5a", "#fff4e0", "ears_pointy horns_thin tail_short slim"),
    "Hyena": ("quad", "#b8925e", "#4a3a2a", "ears_round spots mane tail_fluffy"),
    "Lion": ("quad", "#e0a848", "#9a5420", "ears_round bigmane tail_thin"),
    "Elder Elephant": ("quad", "#9a9aa6", "#e8e0d0", "ears_big trunk tusks bulky tail_thin"),
    # 3 Desert
    "Lizard": ("reptile", "#d8b048", "#8a6a28", "spots"),
    "Scorpion": ("scorpion", "#2a2a30", "#c83a2a", ""),
    "Fennec Fox": ("quad", "#f0c890", "#fff8ee", "ears_huge tail_fluffy slim"),
    "Camel": ("quad", "#d4a86a", "#f0d8b0", "ears_small hump longneck tail_thin"),
    "Sand Wyrm": ("snake", "#e0b860", "#a0602a", "fangs spikes big"),
    # 4 Swamp
    "Toad": ("frog", "#8a7a3a", "#e0d090", "warts"),
    "Heron": ("bird", "#c8d0dc", "#333a48", "longlegs longneck crest"),
    "Crocodile": ("reptile", "#4a7a3a", "#d8d090", "long spikes teeth"),
    "Hippo": ("quad", "#8a7a9a", "#e0a0b0", "ears_small bulky tail_short wide"),
    "Swamp Hydra": ("hydra", "#3a8a5a", "#c0e080", "fangs"),
    # 5 Pine Forest
    "Squirrel": ("quad", "#c06a2a", "#f8e0c0", "ears_pointy tail_big small"),
    "Deer": ("quad", "#b07040", "#fff0dc", "ears_pointy antlers spots tail_short slim"),
    "Boar": ("quad", "#5a4030", "#2a2018", "ears_pointy tusks mane tail_thin"),
    "Brown Bear": ("quad", "#7a4a2a", "#c89a6a", "ears_round bulky tail_short"),
    "Antler King": ("quad", "#6a4a8a", "#f0d060", "ears_pointy antlers_big mane tail_short"),
    # 6 Tundra
    "Arctic Hare": ("quad", "#f4f6fa", "#ffc0d0", "ears_long tail_puff small"),
    "Snow Fox": ("quad", "#f0f4ff", "#a0c0e0", "ears_pointy tail_big slim"),
    "Reindeer": ("quad", "#8a6040", "#f0e8dc", "ears_pointy antlers rednose tail_short"),
    "Musk Ox": ("quad", "#4a3628", "#d8c8a8", "ears_small wool horns_curl bulky"),
    "Frost Elk": ("quad", "#a8d8f0", "#ffffff", "ears_pointy antlers_big mane tail_short"),
    # 7 Glacier
    "Penguin": ("bird", "#252a36", "#ffffff", "upright flipper"),
    "Seal": ("seal", "#9aa4b0", "#e0e6ee", ""),
    "Walrus": ("seal", "#a0705a", "#e8d0b0", "tusks whiskers"),
    "Polar Bear": ("quad", "#f6f6f0", "#d0d8e0", "ears_round bulky tail_short"),
    "Ice Phoenix": ("bird", "#80d8ff", "#ffffff", "crest longtail bigwings"),
    # 8 Mountains
    "Goat": ("quad", "#e8e0d4", "#8a7a6a", "ears_long horns_back beard tail_short"),
    "Eagle": ("bird", "#6a4428", "#ffffff", "whitehead bigwings hook"),
    "Ibex": ("quad", "#a8845a", "#e8d8c0", "ears_small horns_big beard tail_short"),
    "Snow Leopard": ("quad", "#e8e4dc", "#5a5a5a", "ears_round spots tail_big"),
    "Yeti": ("ape", "#f0f4ff", "#a0b0d0", "wool horns_curl"),
    # 9 Volcano
    "Fire Salamander": ("reptile", "#1e1e22", "#ffb020", "spots"),
    "Lava Beetle": ("beetle", "#2a1a1a", "#ff5a1a", "horn"),
    "Magma Crab": ("crab", "#3a2a28", "#ff6a20", ""),
    "Ash Rhino": ("quad", "#5a5a60", "#ff6a2a", "ears_small horn_rhino bulky tail_thin"),
    "Volcano Drake": ("dragon", "#a02a1a", "#ffb030", "horns_back spikes"),
    # 10 Coral Reef
    "Crab": ("crab", "#e8502a", "#ffd0a0", ""),
    "Turtle": ("turtle", "#5aa04a", "#8a6a3a", ""),
    "Shark": ("fish", "#6a8ab0", "#f0f4f8", "teeth"),
    "Octopus": ("octopus", "#e85a8a", "#ffd0e0", ""),
    "Kraken": ("octopus", "#6a2a8a", "#e0a0ff", "big teeth"),
    # 11 Deep Caves
    "Bat": ("bat", "#3a3040", "#a08aa0", ""),
    "Cave Spider": ("spider", "#3a3a48", "#a0ff80", ""),
    "Mole Rat": ("quad", "#e8b0a0", "#ffffff", "ears_small teeth tail_thin small wide"),
    "Blind Bear": ("quad", "#5a5a6a", "#b0b0c0", "ears_round bulky blind tail_short"),
    "Cave Basilisk": ("snake", "#4a6a4a", "#e0e060", "horns_back fangs spikes"),
    # 12 Mushroom Grove
    "Snail": ("snail", "#e0c0a0", "#c050a0", ""),
    "Glow Moth": ("moth", "#c0a0ff", "#ffe060", ""),
    "Spore Boar": ("quad", "#6a4a6a", "#ff4a4a", "ears_pointy tusks mushrooms tail_thin"),
    "Fungus Stag": ("quad", "#8a6a50", "#ff6060", "ears_pointy antlers mushrooms tail_short"),
    "Mycelium Titan": ("ape", "#7a5aa0", "#ff4a4a", "mushrooms"),
    # 13 Prehistoric
    "Compy": ("dino", "#7ab04a", "#f0e090", "small"),
    "Raptor": ("dino", "#c08a4a", "#3a2a1a", "stripes claws"),
    "Triceratops": ("quad", "#5a8a9a", "#e0c080", "frill horns_tri bulky tail_long"),
    "Stegosaurus": ("quad", "#7a9a4a", "#e05a3a", "plates bulky tail_long smallhead"),
    "T-Rex": ("dino", "#5a7a3a", "#d0c080", "big teeth"),
    # 14 Ice Age
    "Dodo": ("bird", "#8a8a9a", "#f0d060", "upright bigbeak"),
    "Saber Cat": ("quad", "#d8a050", "#fff0d0", "ears_round sabers tail_short"),
    "Woolly Rhino": ("quad", "#7a5a3a", "#e8e0d0", "ears_small wool horn_rhino bulky"),
    "Mammoth": ("quad", "#6a4028", "#f4ecd8", "ears_small wool trunk tusks_big bulky"),
    "Glacier Behemoth": ("ape", "#a0d0f0", "#ffffff", "wool horns_big"),
    # 15 Candy Land
    "Gummy Bear": ("quad", "#ff5a7a", "#ffd0dc", "ears_round tail_short"),
    "Candy Bunny": ("quad", "#ffb0e0", "#ffffff", "ears_long tail_puff small"),
    "Choco Moose": ("quad", "#6a3a1a", "#ffe0b0", "ears_pointy antlers_big bulky tail_short"),
    "Lollipop Llama": ("quad", "#a0e0ff", "#ff7ab8", "ears_long longneck wool tail_short"),
    "Cake Dragon": ("dragon", "#ffe0f0", "#ff5a8a", "horns_back"),
    # 16 Haunted Woods
    "Crow": ("bird", "#22222a", "#5a5a7a", ""),
    "Ghost Cat": ("quad", "#e0e8ff", "#8a70c0", "ears_pointy tail_long slim"),
    "Werewolf": ("quad", "#4a4a5a", "#c0c0c8", "ears_pointy fangs mane tail_big"),
    "Headless Horse": ("quad", "#1e1e24", "#8a3aff", "headless mane tail_thin slim"),
    "Banshee Owl": ("bird", "#c8c0e0", "#6a4a9a", "owl"),
    # 17 Crystal Caverns
    "Gem Beetle": ("beetle", "#30c0b0", "#c080ff", "horn"),
    "Quartz Fox": ("quad", "#f0d0e8", "#ffffff", "ears_pointy tail_big crystals"),
    "Amethyst Lynx": ("quad", "#9a6ad0", "#f0e0ff", "ears_tuft tail_short crystals"),
    "Diamond Bull": ("quad", "#a0e8ff", "#ffffff", "ears_small horns_bull bulky crystals tail_thin"),
    "Prism Serpent": ("snake", "#ff80c0", "#80e0ff", "spikes big"),
    # 18 Sky Islands
    "Cloud Sheep": ("quad", "#ffffff", "#7a7a8a", "ears_small wool tail_short small"),
    "Sky Ray": ("ray", "#7ab0ff", "#ffffff", ""),
    "Thunder Hawk": ("bird", "#3a5aa0", "#ffe040", "bigwings crest hook"),
    "Pegasus": ("quad", "#ffffff", "#80c0ff", "ears_pointy mane wings tail_long slim"),
    "Storm Griffin": ("griffin", "#d0a050", "#ffffff", "wings"),
    # 19 Moon Base
    "Moon Rabbit": ("quad", "#e8e8f0", "#a0a0c0", "ears_long tail_puff small"),
    "Space Slug": ("slug", "#80e060", "#e0ff80", ""),
    "Crater Crab": ("crab", "#9a9aa8", "#e0e0f0", ""),
    "Astro Wolf": ("quad", "#5a6a90", "#e0e8ff", "ears_pointy fangs tail_big"),
    "Lunar Whale": ("whale", "#5a6aa0", "#e0e8ff", ""),
    # 20 Cosmic Void
    "Void Mite": ("spider", "#2a1040", "#ff40ff", "small"),
    "Star Jelly": ("jelly", "#ff80ff", "#80ffff", ""),
    "Nebula Fox": ("quad", "#6a3ac0", "#ff80d0", "ears_pointy tail_big crystals"),
    "Galaxy Stag": ("quad", "#2a2a6a", "#80c0ff", "ears_pointy antlers_big crystals tail_short"),
    "Cosmic Leviathan": ("snake", "#3a1a6a", "#ff5aff", "big fins horns_back"),
}

# Orden igual a Config.luau (época * 10 + rareza)
ORDER = [
    ["Frog", "Parrot", "Monkey", "Jaguar", "Golden Gorilla"],
    ["Zebra", "Gazelle", "Hyena", "Lion", "Elder Elephant"],
    ["Lizard", "Scorpion", "Fennec Fox", "Camel", "Sand Wyrm"],
    ["Toad", "Heron", "Crocodile", "Hippo", "Swamp Hydra"],
    ["Squirrel", "Deer", "Boar", "Brown Bear", "Antler King"],
    ["Arctic Hare", "Snow Fox", "Reindeer", "Musk Ox", "Frost Elk"],
    ["Penguin", "Seal", "Walrus", "Polar Bear", "Ice Phoenix"],
    ["Goat", "Eagle", "Ibex", "Snow Leopard", "Yeti"],
    ["Fire Salamander", "Lava Beetle", "Magma Crab", "Ash Rhino", "Volcano Drake"],
    ["Crab", "Turtle", "Shark", "Octopus", "Kraken"],
    ["Bat", "Cave Spider", "Mole Rat", "Blind Bear", "Cave Basilisk"],
    ["Snail", "Glow Moth", "Spore Boar", "Fungus Stag", "Mycelium Titan"],
    ["Compy", "Raptor", "Triceratops", "Stegosaurus", "T-Rex"],
    ["Dodo", "Saber Cat", "Woolly Rhino", "Mammoth", "Glacier Behemoth"],
    ["Gummy Bear", "Candy Bunny", "Choco Moose", "Lollipop Llama", "Cake Dragon"],
    ["Crow", "Ghost Cat", "Werewolf", "Headless Horse", "Banshee Owl"],
    ["Gem Beetle", "Quartz Fox", "Amethyst Lynx", "Diamond Bull", "Prism Serpent"],
    ["Cloud Sheep", "Sky Ray", "Thunder Hawk", "Pegasus", "Storm Griffin"],
    ["Moon Rabbit", "Space Slug", "Crater Crab", "Astro Wolf", "Lunar Whale"],
    ["Void Mite", "Star Jelly", "Nebula Fox", "Galaxy Stag", "Cosmic Leviathan"],
]

WHITE, BLACK = "#ffffff", "#15151a"
GOLD, BONE, PINK, BEAK = "#ffcc33", "#f4ecd8", "#ff9aa8", "#ffaa2a"


def hex_rgb(h):
    h = h.lstrip("#")
    return tuple(int(h[i:i + 2], 16) / 255 for i in (0, 2, 4))


def shade(h, f):
    r, g, b = hex_rgb(h)
    if f < 0:
        r, g, b = r * (1 + f), g * (1 + f), b * (1 + f)
    else:
        r, g, b = r + (1 - r) * f, g + (1 - g) * f, b + (1 - b) * f
    return "#%02x%02x%02x" % (int(r * 255), int(g * 255), int(b * 255))


# ------------------------------------------------------------------ constructor de piezas
class B:
    """Junta piezas (primitivas) con color; al final se unen en un solo objeto con UV a la paleta."""

    def __init__(self, name):
        self.name = name
        self.objs = []
        self.colors = []

    def _color_index(self, h):
        h = h.lower()
        if h not in self.colors:
            self.colors.append(h)
        return self.colors.index(h)

    def add(self, kind, loc, size, color, rot=(0, 0, 0), seg=16, bevel=0.0):
        loc = Vector(loc)
        if kind == "sphere":
            bpy.ops.mesh.primitive_uv_sphere_add(segments=seg, ring_count=max(6, seg // 2), radius=1, location=loc)
        elif kind == "cube":
            bpy.ops.mesh.primitive_cube_add(size=2, location=loc)
        elif kind == "cyl":
            bpy.ops.mesh.primitive_cylinder_add(vertices=12, radius=1, depth=2, location=loc)
        elif kind == "cone":
            bpy.ops.mesh.primitive_cone_add(vertices=12, radius1=1, radius2=0, depth=2, location=loc)
        elif kind == "torus":
            bpy.ops.mesh.primitive_torus_add(major_radius=1, minor_radius=0.3, major_segments=16, minor_segments=8, location=loc)
        o = bpy.context.active_object
        o.scale = size
        o.rotation_euler = Euler([math.radians(r) for r in rot])
        bpy.ops.object.transform_apply(location=False, rotation=True, scale=True)
        if kind == "cube" and bevel > 0:
            m = o.modifiers.new("b", "BEVEL")
            m.width = bevel
            m.segments = 2
            bpy.ops.object.modifier_apply(modifier="b")
        if kind in ("sphere", "torus") or (kind == "cube" and bevel > 0):
            bpy.ops.object.shade_smooth()
        o["ci"] = self._color_index(color)
        self.objs.append(o)
        return o

    # helpers de piezas
    def ball(self, loc, r, color, sq=(1, 1, 1), rot=(0, 0, 0), seg=16):
        return self.add("sphere", loc, (r * sq[0], r * sq[1], r * sq[2]), color, rot, seg)

    def box(self, loc, size, color, rot=(0, 0, 0), bevel=0.06):
        return self.add("cube", loc, (size[0] / 2, size[1] / 2, size[2] / 2), color, rot, bevel=bevel)

    def rod(self, a, b, r, color, cone=False):
        """Cilindro (o cono) de a a b."""
        a, b = Vector(a), Vector(b)
        d = b - a
        o = self.add("cone" if cone else "cyl", (a + b) / 2, (r, r, d.length / 2), color)
        # orientar el eje Z hacia d
        o.rotation_mode = "QUATERNION"
        o.rotation_quaternion = Vector((0, 0, 1)).rotation_difference(d.normalized())
        bpy.ops.object.select_all(action="DESELECT")
        o.select_set(True)
        bpy.context.view_layer.objects.active = o
        bpy.ops.object.transform_apply(location=False, rotation=True, scale=False)
        return o

    def spike(self, base, tip, r, color):
        return self.rod(base, tip, r, color, cone=True)

    def eyes(self, x, y, z, r=0.2, blind=False):
        for s in (-1, 1):
            if blind:
                self.ball((s * x, y, z), r * 0.9, "#d0d0d8", sq=(1, 0.5, 0.35))
                continue
            self.ball((s * x, y, z), r, WHITE)
            self.ball((s * x * 1.02, y - r * 0.55, z - r * 0.08), r * 0.62, BLACK)
            self.ball((s * x * 1.02 + r * 0.18, y - r * 0.95, z + r * 0.18), r * 0.2, WHITE, seg=8)

    def finish(self):
        """Une todo en un objeto, pone UV a la paleta y le asigna el material con la textura."""
        n = len(self.colors)
        grid = max(1, math.ceil(math.sqrt(n)))
        cell = 8
        px = grid * cell
        img_name = "pal_" + self.name
        if img_name in bpy.data.images:
            bpy.data.images.remove(bpy.data.images[img_name])
        img = bpy.data.images.new(img_name, px, px)
        pixels = [0.0] * (px * px * 4)
        for i, h in enumerate(self.colors):
            r, g, b = hex_rgb(h)
            cx, cy = (i % grid) * cell, (i // grid) * cell
            for yy in range(cy, cy + cell):
                for xx in range(cx, cx + cell):
                    k = (yy * px + xx) * 4
                    pixels[k:k + 4] = [r, g, b, 1.0]
        img.pixels = pixels
        path = os.path.join(OUT, "tex", self.name.replace(" ", "_") + ".png")
        img.filepath_raw = path
        img.file_format = "PNG"
        img.save()
        for o in self.objs:
            me = o.data
            uv = me.uv_layers.new(name="UV") if not me.uv_layers else me.uv_layers[0]
            i = o["ci"]
            u = ((i % grid) * cell + cell / 2) / px
            v = ((i // grid) * cell + cell / 2) / px
            for loop in uv.data:
                loop.uv = (u, v)
        bpy.ops.object.select_all(action="DESELECT")
        for o in self.objs:
            o.select_set(True)
        bpy.context.view_layer.objects.active = self.objs[0]
        bpy.ops.object.join()
        obj = bpy.context.active_object
        obj.name = self.name
        mat = bpy.data.materials.new("mat_" + self.name)
        mat.use_nodes = True
        nodes = mat.node_tree.nodes
        bsdf = next(nd for nd in nodes if nd.type == "BSDF_PRINCIPLED")
        tex = nodes.new("ShaderNodeTexImage")
        tex.image = img
        tex.interpolation = "Closest"
        mat.node_tree.links.new(tex.outputs[0], bsdf.inputs[0])
        obj.data.materials.clear()
        obj.data.materials.append(mat)
        return obj


def reset():
    if COLL not in bpy.data.collections:
        c = bpy.data.collections.new(COLL)
        bpy.context.scene.collection.children.link(c)
    c = bpy.data.collections[COLL]
    for o in list(c.objects):
        bpy.data.objects.remove(o, do_unlink=True)
    for m in list(bpy.data.meshes):
        if m.users == 0:
            bpy.data.meshes.remove(m)
    for m in list(bpy.data.materials):
        if m.users == 0:
            bpy.data.materials.remove(m)
    lc = bpy.context.view_layer.layer_collection.children[COLL]
    bpy.context.view_layer.active_layer_collection = lc
    if bpy.context.object and bpy.context.object.mode != "OBJECT":
        bpy.ops.object.mode_set(mode="OBJECT")


# ------------------------------------------------------------------ piezas comunes de animales
def has(ex, *keys):
    return any(k in ex for k in keys)


def ears(b, ex, c1, c2, hx, hy, hz, hr):
    for s in (-1, 1):
        x = s * hr * 0.6
        if "ears_long" in ex:
            b.ball((x * 0.7, hy + 0.1, hz + hr * 1.5), hr * 0.25, c1, sq=(1, 0.5, 3), rot=(0, s * 12, 0))
            b.ball((x * 0.7, hy + 0.02, hz + hr * 1.5), hr * 0.15, PINK, sq=(1, 0.4, 2.6), rot=(0, s * 12, 0))
        elif "ears_huge" in ex or "ears_big" in ex:
            big = 1.5 if "ears_big" in ex else 1.0
            if "ears_big" in ex:
                b.ball((s * hr * 1.15, hy + 0.25, hz), hr * 0.85, c1, sq=(0.18, 0.9, 1.1))
            else:
                b.spike((x, hy + 0.1, hz + hr * 0.6), (x * 1.6, hy + 0.15, hz + hr * 2.2), hr * 0.42, c1)
                b.spike((x * 1.02, hy + 0.04, hz + hr * 0.7), (x * 1.5, hy + 0.08, hz + hr * 2.0), hr * 0.28, PINK)
        elif "ears_pointy" in ex or "ears_tuft" in ex:
            b.spike((x, hy + 0.05, hz + hr * 0.7), (x * 1.25, hy + 0.1, hz + hr * 1.55), hr * 0.3, c1)
            b.spike((x * 1.02, hy - 0.02, hz + hr * 0.75), (x * 1.2, hy + 0.02, hz + hr * 1.35), hr * 0.17, PINK)
            if "ears_tuft" in ex:
                b.spike((x * 1.25, hy + 0.1, hz + hr * 1.5), (x * 1.3, hy + 0.1, hz + hr * 1.95), hr * 0.06, BLACK)
        elif "ears_small" in ex:
            b.ball((x * 1.1, hy + 0.1, hz + hr * 0.75), hr * 0.18, c1, sq=(1, 0.5, 1))
        else:  # redondas
            b.ball((x * 1.05, hy + 0.1, hz + hr * 0.8), hr * 0.3, c1, sq=(1, 0.5, 1))
            b.ball((x * 1.05, hy + 0.02, hz + hr * 0.8), hr * 0.18, PINK, sq=(1, 0.4, 1))


def head_horns(b, ex, c2, hy, hz, hr):
    top = hz + hr * 0.75
    for s in (-1, 1):
        if "antlers" in ex or "antlers_big" in ex:
            k = 1.5 if "antlers_big" in ex else 1.0
            col = "#e8d0a0" if "crystals" not in ex else c2
            base = Vector((s * hr * 0.4, hy + 0.1, top))
            mid = base + Vector((s * 0.5, 0.2, 0.8)) * k
            tip = mid + Vector((s * 0.3, 0.1, 0.7)) * k
            b.rod(base, mid, 0.08 * k, col)
            b.rod(mid, tip, 0.07 * k, col)
            b.rod(mid, mid + Vector((s * 0.1, -0.4, 0.5)) * k, 0.06 * k, col)
            b.rod(tip, tip + Vector((s * 0.5, 0.1, 0.1)) * k, 0.05 * k, col)
            b.rod(tip, tip + Vector((0, -0.2, 0.5)) * k, 0.05 * k, col)
        if "horns_thin" in ex:
            b.spike((s * hr * 0.3, hy + 0.1, top), (s * hr * 0.45, hy + 0.6, top + 1.1), 0.08, "#3a3028")
        if "horns_back" in ex:
            b.spike((s * hr * 0.35, hy + 0.2, top - 0.1), (s * hr * 0.6, hy + 1.0, top + 0.5), 0.14, BONE)
        if "horns_big" in ex:
            b.rod((s * hr * 0.3, hy + 0.1, top), (s * hr * 0.7, hy + 0.6, top + 0.5), 0.16, "#7a6a50")
            b.rod((s * hr * 0.7, hy + 0.6, top + 0.5), (s * hr * 1.0, hy + 1.1, top + 0.1), 0.13, "#7a6a50")
            b.spike((s * hr * 1.0, hy + 1.1, top + 0.1), (s * hr * 1.1, hy + 1.0, top - 0.4), 0.11, "#7a6a50")
        if "horns_curl" in ex:
            b.add("torus", (s * hr * 0.85, hy + 0.1, top - 0.2), (0.35, 0.35, 0.5), BONE, rot=(0, 90, 0))
        if "horns_bull" in ex:
            b.rod((s * hr * 0.4, hy, top - 0.1), (s * hr * 1.1, hy - 0.1, top + 0.1), 0.13, BONE)
            b.spike((s * hr * 1.1, hy - 0.1, top + 0.1), (s * hr * 1.3, hy - 0.2, top + 0.6), 0.12, BONE)
        if "horns_tri" in ex:
            b.spike((s * hr * 0.35, hy - 0.3, top), (s * hr * 0.45, hy - 1.3, top + 0.6), 0.13, BONE)


def crown(b, x, y, z, r=0.45):
    b.add("cyl", (x, y, z), (r, r, 0.14), GOLD)
    for i in range(5):
        a = i / 5 * math.tau
        b.spike((x + math.cos(a) * r * 0.85, y + math.sin(a) * r * 0.85, z + 0.1), (x + math.cos(a) * r * 0.9, y + math.sin(a) * r * 0.9, z + 0.45), 0.09, GOLD)
    b.ball((x, y - r, z + 0.05), 0.09, "#ff3a5a", seg=8)


def crystals(b, pts, c2):
    for (x, y, z) in pts:
        b.spike((x, y, z - 0.2), (x * 1.1, y, z + 0.6), 0.16, c2)


def mushrooms(b, pts, c2):
    for (x, y, z) in pts:
        b.add("cyl", (x, y, z + 0.15), (0.08, 0.08, 0.2), BONE)
        b.ball((x, y, z + 0.38), 0.3, c2, sq=(1, 1, 0.55))
        b.ball((x + 0.12, y - 0.1, z + 0.5), 0.06, WHITE, seg=8)


# ------------------------------------------------------------------ formas
def build_quad(b, c1, c2, ex):
    bulky = 1.25 if "bulky" in ex else 1.0
    small = 0.8 if "small" in ex else 1.0
    slim = 0.85 if "slim" in ex else 1.0
    wide = 1.2 if "wide" in ex else 1.0
    headless = "headless" in ex
    bw, bl, bh = 0.85 * bulky * slim * wide, 1.35 * bulky, 0.78 * bulky
    legh = 0.75 * (1.1 if "slim" in ex else 1.0) * (0.75 if "bulky" in ex else 1.0)
    bz = legh + bh * 0.75
    # cuerpo
    if "wool" in ex:
        for (x, y, z, r) in [(0, -0.6, 0.1, 0.85), (0, 0.5, 0.1, 0.85), (0.4, 0, 0.35, 0.7), (-0.4, 0, 0.35, 0.7), (0, 0, -0.1, 0.9)]:
            b.ball((x * bw, y * bl, bz + z * bh), r * bh * 1.25, c1 if "Lollipop" not in b.name else c1)
    else:
        b.ball((0, 0, bz), 1, c1, sq=(bw, bl, bh))
        b.ball((0, -0.1, bz - bh * 0.45), 1, shade(c2, 0) if c2 else c1, sq=(bw * 0.75, bl * 0.8, bh * 0.45))
    # patas con pezuñas
    for sx in (-1, 1):
        for sy in (-1, 1):
            x, y = sx * bw * 0.55, sy * bl * 0.55
            b.add("cyl", (x, y, legh / 2 + 0.12), (0.2 * bulky * small, 0.2 * bulky * small, legh / 2), c1)
            b.ball((x, y - 0.03, 0.14), 0.25 * bulky * small, shade(c1, -0.45), sq=(1, 1.1, 0.6))
    # marcas
    if "stripes" in ex:
        for i in range(5):
            y = -0.8 + i * 0.4
            b.box((0, y * bl, bz + 0.05), (bw * 2.04, 0.16, bh * 1.7), c2, rot=(12, 0, 0))
    if "spots" in ex:
        import random
        rnd = random.Random(len(b.name))
        for _ in range(9):
            a = rnd.uniform(-1.2, 1.2)
            y = rnd.uniform(-0.8, 0.8)
            b.ball((math.sin(a) * bw * 0.95, y * bl, bz + math.cos(a) * bh * 0.95), 0.16, shade(c2 if c2 != c1 else c1, -0.35), sq=(1, 1, 0.4), rot=(0, math.degrees(a), 0))
    if "hump" in ex:
        b.ball((0, 0.1, bz + bh * 0.85), 0.55, c1, sq=(1, 1.1, 0.9))
    if "plates" in ex:
        for i in range(6):
            y = -0.9 + i * 0.36
            b.box((0, y * bl, bz + bh * 0.95), (0.12, 0.4, 0.55), c2, rot=(0, 0, 0))
    if "mushrooms" in ex:
        mushrooms(b, [(0.3, -0.4, bz + bh * 0.8), (-0.35, 0.2, bz + bh * 0.85), (0.1, 0.7, bz + bh * 0.7)], c2)
    if "crystals" in ex:
        crystals(b, [(0.25, -0.2, bz + bh * 0.8), (-0.25, 0.3, bz + bh * 0.8), (0, 0.8, bz + bh * 0.6)], c2)
    # cola
    ty = bl * 0.95
    if "tail_big" in ex:
        b.ball((0, ty + 0.5, bz + 0.45), 0.5, c1, sq=(0.8, 0.9, 1.4), rot=(-35, 0, 0))
        b.ball((0, ty + 0.75, bz + 0.95), 0.33, WHITE if c1 != "#ffffff" else c2)
    elif "tail_fluffy" in ex:
        b.ball((0, ty + 0.3, bz + 0.2), 0.4, c1, sq=(0.8, 1.3, 0.8), rot=(-30, 0, 0))
    elif "tail_puff" in ex:
        b.ball((0, ty + 0.05, bz + 0.1), 0.3, WHITE)
    elif "tail_long" in ex:
        b.rod((0, ty, bz + 0.1), (0, ty + 0.9, bz + 0.6), 0.1, c1)
        b.rod((0, ty + 0.9, bz + 0.6), (0, ty + 1.2, bz + 1.1), 0.09, c1)
        b.ball((0, ty + 1.2, bz + 1.1), 0.13, c2)
    elif "tail_thin" in ex:
        b.rod((0, ty, bz + 0.1), (0, ty + 0.5, bz - 0.5), 0.06, c1)
        b.ball((0, ty + 0.55, bz - 0.6), 0.14, c2 if "mane" in ex or "bigmane" in ex else shade(c1, -0.3), sq=(1, 1, 1.5))
    elif "tail_short" in ex:
        b.ball((0, ty + 0.05, bz + 0.15), 0.18, c1)
    # cuello y cabeza
    hr = 0.62 * (0.75 if "smallhead" in ex else 1.0) * (1.1 if "bulky" in ex else 1.0) * small
    neck = 1.0 if "longneck" in ex else 0.35
    hy = -bl * 0.95 - 0.2
    hz = bz + bh * 0.4 + neck
    if "longneck" in ex:
        b.rod((0, -bl * 0.7, bz + 0.2), (0, hy + 0.15, hz - 0.2), 0.3, c1)
    if headless:
        b.add("cyl", (0, hy + 0.3, bz + bh * 0.6), (0.3, 0.3, 0.1), "#3a1010")
        for i in range(4):
            b.spike((0.12 * (i - 1.5), hy + 0.3, bz + bh * 0.6), (0.06 * (i - 1.5), hy + 0.35, bz + bh * 0.6 + 0.9 + 0.2 * (i % 2)), 0.14, c2)
    else:
        b.ball((0, hy + 0.25, hz - 0.3), hr * 0.75, c1)  # cuello
        b.ball((0, hy, hz), hr, c1)
        sn = 0.55 if "trunk" not in ex else 0.45
        b.ball((0, hy - hr * 0.75, hz - hr * 0.25), hr * sn, c2 if "face" in ex or c2 in ("#fff0d0", "#fff4e0", "#fff8ee", "#f0e8dc", "#fff0dc", "#e8c49a", "#ffffff", "#e8d8c0") else shade(c1, 0.25), sq=(1.1, 0.9, 0.8))
        b.ball((0, hy - hr * 1.2, hz - hr * 0.1), hr * 0.16, "#ff2a2a" if "rednose" in ex else BLACK, sq=(1.4, 0.8, 1))
        b.eyes(hr * 0.42, hy - hr * 0.72, hz + hr * 0.22, r=hr * 0.24, blind="blind" in ex)
        ears(b, ex, c1, c2, 0, hy, hz, hr)
        head_horns(b, ex, c2, hy, hz, hr)
        if "mane" in ex:
            for i in range(5):
                b.ball((0, hy + 0.4 + i * 0.3, hz + 0.35 - i * 0.12), 0.22, c2, sq=(0.6, 1.2, 1.2))
        if "bigmane" in ex:
            b.ball((0, hy + 0.25, hz), hr * 1.45, c2, sq=(1.1, 0.75, 1.1))
        if "trunk" in ex:
            p0 = Vector((0, hy - hr * 0.95, hz - hr * 0.3))
            p1 = p0 + Vector((0, -0.25, -0.55))
            p2 = p1 + Vector((0, -0.05, -0.55))
            b.rod(p0, p1, 0.2, c1)
            b.rod(p1, p2, 0.16, c1)
            b.ball(p2, 0.17, c1)
        if has(ex, "tusks", "tusks_big"):
            k = 1.6 if "tusks_big" in ex else 1.0
            for s in (-1, 1):
                a = Vector((s * hr * 0.35, hy - hr * 0.8, hz - hr * 0.5))
                b.rod(a, a + Vector((s * 0.1, -0.35 * k, -0.15 * k)), 0.07 * k, BONE)
                b.spike(a + Vector((s * 0.1, -0.35 * k, -0.15 * k)), a + Vector((s * 0.15, -0.6 * k, 0.15 * k)), 0.07 * k, BONE)
        if "horn_rhino" in ex:
            b.spike((0, hy - hr * 1.0, hz - hr * 0.05), (0, hy - hr * 1.25, hz + hr * 0.9), 0.2, BONE)
            b.spike((0, hy - hr * 0.6, hz + hr * 0.4), (0, hy - hr * 0.7, hz + hr * 0.9), 0.12, BONE)
        if "fangs" in ex or "sabers" in ex:
            ln = 0.55 if "sabers" in ex else 0.2
            for s in (-1, 1):
                b.spike((s * hr * 0.2, hy - hr * 1.0, hz - hr * 0.4), (s * hr * 0.2, hy - hr * 1.0, hz - hr * 0.4 - ln), 0.06, WHITE)
        if "teeth" in ex:
            b.box((0, hy - hr * 1.1, hz - hr * 0.45), (hr * 0.5, 0.06, 0.12), WHITE)
        if "beard" in ex:
            b.spike((0, hy - hr * 0.8, hz - hr * 0.6), (0, hy - hr * 0.8, hz - hr * 1.3), 0.13, shade(c1, -0.2))
        if "frill" in ex:
            b.ball((0, hy + hr * 0.5, hz + hr * 0.4), hr * 1.3, c2, sq=(1.1, 0.2, 0.9), rot=(-25, 0, 0))
        if "wings" in ex:
            pass
    if "wings" in ex:
        for s in (-1, 1):
            b.ball((s * (bw + 0.6), -0.1, bz + bh * 0.9), 0.9, c2 if "Pegasus" in b.name else WHITE, sq=(1.1, 0.5, 0.18), rot=(0, s * -25, 0))
            b.ball((s * (bw + 1.3), 0.2, bz + bh * 1.3), 0.6, WHITE, sq=(1.1, 0.4, 0.15), rot=(0, s * -35, 0))
    return hz + hr, hy


def build_ape(b, c1, c2, ex):
    bz = 1.6
    b.ball((0, 0, bz), 1, c1, sq=(1.1, 0.85, 1.05))
    b.ball((0, -0.55, bz - 0.1), 0.7, c2, sq=(1, 0.5, 1))
    for s in (-1, 1):
        b.rod((s * 1.0, -0.1, bz + 0.5), (s * 1.35, -0.4, 0.4), 0.33, c1)
        b.ball((s * 1.35, -0.45, 0.3), 0.35, c2)
        b.add("cyl", (s * 0.5, 0.1, 0.45), (0.33, 0.33, 0.45), c1)
        b.ball((s * 0.5, 0, 0.12), 0.36, c2, sq=(1, 1.2, 0.55))
    hz, hy = bz + 1.15, -0.25
    b.ball((0, hy, hz), 0.65, c1)
    b.ball((0, hy - 0.45, hz - 0.15), 0.45, c2, sq=(1.1, 0.7, 0.8))
    b.eyes(0.24, hy - 0.52, hz + 0.18, r=0.15)
    b.ball((0, hy - 0.8, hz - 0.1), 0.08, BLACK, sq=(1.6, 0.6, 1))
    ears(b, ex + " ears_round", c1, c2, 0, hy, hz - 0.2, 0.65)
    head_horns(b, ex, c2, hy, hz, 0.65)
    if "wool" in ex:
        for (x, y, z) in [(0.8, 0.3, bz + 0.6), (-0.8, 0.3, bz + 0.6), (0, 0.6, bz + 0.3)]:
            b.ball((x, y, z), 0.5, c1)
    if "mushrooms" in ex:
        mushrooms(b, [(0.5, 0.2, bz + 0.9), (-0.4, 0.4, bz + 0.85), (0, 0.3, hz + 0.45)], c2)
    return hz + 0.65, hy


def build_bird(b, c1, c2, ex):
    up = "upright" in ex
    legs = 1.4 if "longlegs" in ex else 0.55
    bz = legs + 0.75
    b.ball((0, 0, bz), 1, c1, sq=(0.85, 1.0 if not up else 0.85, 0.95 if not up else 1.25))
    b.ball((0, -0.45, bz - 0.1), 0.7, c2 if up or "owl" in ex else shade(c1, 0.45), sq=(0.9, 0.5, 1.1))
    for s in (-1, 1):
        b.rod((s * 0.3, 0, bz - 0.7), (s * 0.3, 0, 0.1), 0.06, BEAK)
        b.ball((s * 0.3, -0.15, 0.06), 0.18, BEAK, sq=(1, 1.6, 0.35))
        if "flipper" in ex:
            b.ball((s * 0.85, 0, bz), 0.55, c1, sq=(0.2, 0.5, 1.2), rot=(0, s * 15, 0))
        else:
            big = 1.6 if "bigwings" in ex else 1.0
            b.ball((s * 0.8 * (1 + (big - 1) * 0.6), 0.1, bz + 0.15 * big), 0.75 * big, c2 if c2 not in (WHITE,) or "whitehead" not in ex else shade(c1, -0.2), sq=(0.25, 1.0, 0.6), rot=(10, s * (15 + 25 * (big - 1)), 0))
    tail = 1.6 if "longtail" in ex else 0.8
    b.spike((0, 0.7, bz + 0.1), (0, 0.7 + tail, bz + 0.1 + tail * 0.3), 0.35, c2 if "longtail" in ex else shade(c1, -0.2))
    neck = 0.9 if "longneck" in ex else 0
    hz = bz + 1.0 + neck + (0.3 if up else 0)
    hy = -0.45 - (0.3 if neck else 0)
    if neck:
        b.rod((0, -0.3, bz + 0.6), (0, hy, hz - 0.3), 0.2, c1)
    hc = WHITE if "whitehead" in ex else c1
    hr = 0.75 if "owl" in ex else 0.6
    b.ball((0, hy, hz), hr, hc)
    if "owl" in ex:
        for s in (-1, 1):
            b.ball((s * 0.27, hy - 0.5, hz + 0.05), 0.3, shade(c2, 0.5), sq=(1, 0.4, 1))
        b.eyes(0.27, hy - 0.62, hz + 0.08, r=0.2)
        for s in (-1, 1):
            b.spike((s * 0.4, hy, hz + 0.5), (s * 0.55, hy + 0.1, hz + 0.95), 0.15, c1)
    else:
        b.eyes(0.25, hy - 0.42, hz + 0.15, r=0.16)
    bl = 0.9 if "bigbeak" in ex else 0.55
    if "hook" in ex:
        b.spike((0, hy - 0.45, hz - 0.05), (0, hy - 0.45 - bl, hz - 0.25), 0.18, BEAK)
    else:
        b.spike((0, hy - 0.45, hz - 0.1), (0, hy - 0.45 - bl, hz - 0.12), 0.2 if "bigbeak" in ex else 0.15, BEAK)
    if "crest" in ex:
        for i in range(3):
            b.spike((0, hy + 0.05 * i, hz + 0.5), (0, hy + 0.35 + 0.2 * i, hz + 1.0 - 0.15 * i), 0.1, c2)
    return hz + hr, hy


def build_reptile(b, c1, c2, ex, wings=False):
    long_ = 1.4 if "long" in ex else 1.0
    bz = 0.75
    b.ball((0, 0, bz), 1, c1, sq=(0.8, 1.4 * long_, 0.55))
    b.ball((0, 0, bz - 0.25), 1, c2, sq=(0.65, 1.2 * long_, 0.32))
    for sx in (-1, 1):
        for sy in (-1, 1):
            a = (sx * 0.7, sy * 0.8 * long_, bz - 0.1)
            b.rod(a, (sx * 1.05, sy * 0.85 * long_, 0.12), 0.14, c1)
            b.ball((sx * 1.05, sy * 0.85 * long_ - 0.1, 0.08), 0.18, shade(c1, -0.3), sq=(1, 1.3, 0.4))
    b.spike((0, 1.2 * long_, bz), (0, 3.0 * long_, 0.3), 0.32, c1)
    if "spots" in ex:
        for (x, y) in [(0.3, -0.5), (-0.35, 0.1), (0.2, 0.7), (-0.2, -1.0), (0.1, 1.3)]:
            b.ball((x, y * long_, bz + 0.45), 0.17, c2, sq=(1, 1, 0.4))
    if "spikes" in ex:
        for i in range(6):
            y = -1.0 + i * 0.5
            b.spike((0, y * long_, bz + 0.45), (0, y * long_ + 0.1, bz + 0.85), 0.12, shade(c1, -0.35))
    hy, hz = -1.45 * long_, bz + 0.25
    b.ball((0, hy, hz), 0.55, c1, sq=(1, 1.5 if "long" in ex else 1.1, 0.75))
    b.eyes(0.3, hy - 0.2, hz + 0.38, r=0.2)
    b.ball((0, hy - 0.7, hz - 0.05), 0.08, BLACK)
    if "teeth" in ex:
        for i in range(4):
            for s in (-1, 1):
                b.spike((s * 0.4, hy - 0.3 - i * 0.15, hz - 0.15), (s * 0.42, hy - 0.3 - i * 0.15, hz - 0.35), 0.05, WHITE)
    head_horns(b, ex, c2, hy, hz, 0.55)
    if wings:
        for s in (-1, 1):
            b.rod((s * 0.5, -0.2, bz + 0.4), (s * 1.6, 0.1, bz + 1.6), 0.08, shade(c1, -0.3))
            b.ball((s * 1.25, 0.3, bz + 1.0), 1.0, c2, sq=(0.9, 0.8, 0.12), rot=(0, s * -45, 0))
    return hz + 0.6, hy


def build_dino(b, c1, c2, ex):
    k = 1.35 if "big" in ex else (0.75 if "small" in ex else 1.0)
    bz = 1.8 * k
    b.ball((0, 0.1, bz), 1.0 * k, c1, sq=(0.8, 1.2, 0.85), rot=(-20, 0, 0))
    b.ball((0, -0.3 * k, bz - 0.2 * k), 0.75 * k, c2, sq=(0.75, 0.9, 0.7), rot=(-20, 0, 0))
    for s in (-1, 1):
        b.ball((s * 0.55 * k, 0.2 * k, bz - 0.5 * k), 0.5 * k, c1, sq=(0.8, 1.1, 1.2))
        b.rod((s * 0.55 * k, 0.3 * k, bz - 1.0 * k), (s * 0.55 * k, 0.15 * k, 0.15), 0.18 * k, c1)
        b.ball((s * 0.55 * k, -0.05 * k, 0.1), 0.25 * k, shade(c1, -0.4), sq=(1, 1.6, 0.5))
        b.rod((s * 0.45 * k, -0.7 * k, bz + 0.1 * k), (s * 0.55 * k, -1.0 * k, bz - 0.4 * k), 0.08 * k, c1)
        if "claws" in ex:
            b.spike((s * 0.55 * k, -0.2 * k, 0.25), (s * 0.55 * k, -0.6 * k, 0.45), 0.08 * k, WHITE)
    b.spike((0, 1.0 * k, bz + 0.1 * k), (0, 3.0 * k, bz + 0.3 * k), 0.45 * k, c1)
    if "stripes" in ex:
        for i in range(4):
            b.box((0, (-0.3 + i * 0.4) * k, bz + 0.2 * k), (1.65 * k, 0.12 * k, 1.5 * k), c2, rot=(-20, 0, 0))
    hy, hz = -1.2 * k, bz + 1.0 * k
    b.ball((0, -0.75 * k, bz + 0.65 * k), 0.4 * k, c1)
    b.ball((0, hy, hz), 0.6 * k, c1, sq=(0.9, 1.4, 0.85))
    b.eyes(0.32 * k, hy - 0.2 * k, hz + 0.3 * k, r=0.17 * k)
    if "teeth" in ex or "big" in ex:
        for i in range(4):
            for s in (-1, 1):
                b.spike((s * 0.38 * k, hy - (0.3 + i * 0.17) * k, hz - 0.3 * k), (s * 0.4 * k, hy - (0.3 + i * 0.17) * k, hz - 0.5 * k), 0.05 * k, WHITE)
    return hz + 0.55 * k, hy


def build_frog(b, c1, c2, ex):
    bz = 0.75
    b.ball((0, 0, bz), 1, c1, sq=(1.05, 1.0, 0.7))
    b.ball((0, -0.35, bz - 0.15), 0.8, c2, sq=(0.95, 0.75, 0.6))
    for s in (-1, 1):
        b.ball((s * 0.9, 0.35, 0.35), 0.45, c1, sq=(0.8, 1.3, 0.7))
        b.ball((s * 1.0, -0.25, 0.08), 0.3, c1, sq=(1.2, 1.5, 0.3))
        b.ball((s * 0.6, -0.75, 0.25), 0.2, c1, sq=(0.8, 0.8, 1.2))
        b.ball((s * 0.65, -0.95, 0.06), 0.22, c1, sq=(1.3, 1.3, 0.3))
        b.ball((s * 0.42, -0.45, bz + 0.65), 0.32, c1)
    b.eyes(0.42, -0.62, bz + 0.72, r=0.27)
    b.box((0, -0.95, bz - 0.05), (0.9, 0.05, 0.06), shade(c1, -0.5))
    if "warts" in ex:
        for (x, y) in [(0.3, 0.1), (-0.4, 0.3), (0.1, 0.5), (-0.1, -0.1), (0.5, -0.2)]:
            b.ball((x, y, bz + 0.6), 0.1, shade(c1, -0.3), seg=8)
    return bz + 1.0, -0.4


def build_seal(b, c1, c2, ex):
    b.ball((0, 0.2, 0.8), 1, c1, sq=(0.85, 1.7, 0.8))
    b.ball((0, -0.3, 0.55), 0.8, c2, sq=(0.85, 1.2, 0.6))
    b.ball((0, -1.1, 1.5), 0.65, c1)
    b.eyes(0.27, -1.62, 1.68, r=0.17)
    b.ball((0, -1.72, 1.4), 0.3, shade(c2, -0.05), sq=(1.2, 0.7, 0.7))
    b.ball((0, -1.95, 1.48), 0.07, BLACK)
    for s in (-1, 1):
        b.ball((s * 0.85, -0.7, 0.2), 0.4, shade(c1, -0.2), sq=(0.9, 0.6, 0.2), rot=(0, 0, s * 30))
        b.ball((s * 0.35, 2.0, 0.25), 0.4, shade(c1, -0.2), sq=(1, 0.7, 0.15), rot=(0, 0, s * 40))
        if "tusks" in ex:
            b.spike((s * 0.18, -1.85, 1.25), (s * 0.2, -1.95, 0.5), 0.07, BONE)
        if "whiskers" in ex:
            b.rod((s * 0.2, -1.95, 1.35), (s * 0.7, -2.05, 1.4), 0.015, WHITE)
    return 2.15, -1.1


def build_fish(b, c1, c2, ex, whale=False):
    k = 1.4 if whale else 1.0
    bz = 1.2 * k
    b.ball((0, 0, bz), 1, c1, sq=(0.75 * k, 2.0 * k, 0.8 * k))
    b.ball((0, -0.2, bz - 0.35 * k), 1, c2, sq=(0.6 * k, 1.7 * k, 0.5 * k))
    if whale:
        b.ball((0, 2.2 * k, bz + 0.1), 0.9, c1, sq=(1.4, 0.4, 0.15))
        for i in range(4):
            b.box((0, (-1.2 + i * 0.25) * k, bz - 0.55 * k), (0.9 * k, 0.06, 0.06), shade(c2, -0.2))
        b.spike((0, -0.3, bz + 0.75 * k), (0, -0.2, bz + 1.6 * k), 0.08, "#a0e0ff")
    else:
        b.spike((0, 1.7, bz), (0, 2.6, bz + 0.6), 0.1, c1)
        b.ball((0, 2.25, bz + 0.4), 0.7, c1, sq=(0.15, 0.55, 1.0), rot=(30, 0, 0))
        b.ball((0, 2.25, bz - 0.35), 0.5, c1, sq=(0.15, 0.55, 0.9), rot=(-30, 0, 0))
        b.ball((0, 0, bz + 0.85), 0.65, c1, sq=(0.15, 0.7, 1.0), rot=(-25, 0, 0))
    for s in (-1, 1):
        b.ball((s * 0.75 * k, -0.4, bz - 0.4 * k), 0.6 * k, shade(c1, -0.15), sq=(1, 0.5, 0.12), rot=(0, s * 30, 20))
    b.eyes(0.42 * k, -1.35 * k, bz + 0.18 * k, r=0.17 * k)
    if "teeth" in ex:
        for i in range(5):
            b.spike((-0.3 + i * 0.15, -1.75, bz - 0.25), (-0.3 + i * 0.15, -1.75, bz - 0.45), 0.05, WHITE)
    if "fins" in ex:
        for i in range(4):
            b.spike((0, -0.8 + i * 0.6, bz + 0.6 * k), (0, -0.5 + i * 0.6, bz + 1.3 * k), 0.18, c2)
    return bz + 0.9 * k, -1.3 * k


def build_ray(b, c1, c2, ex):
    bz = 1.4
    b.ball((0, 0, bz), 1, c1, sq=(2.2, 1.3, 0.25))
    b.ball((0, 0, bz - 0.1), 1, c2, sq=(2.0, 1.15, 0.2))
    b.spike((0, 1.0, bz), (0, 3.2, bz + 0.3), 0.1, c1)
    for s in (-1, 1):
        b.spike((s * 0.25, -1.1, bz), (s * 0.3, -1.6, bz - 0.2), 0.12, c1)
    b.eyes(0.4, -1.0, bz + 0.2, r=0.18)
    b.add("cyl", (0, 0, 0.6), (0.12, 0.12, 0.6), "#a0c8ff")
    return bz + 0.5, -0.8


def build_snake(b, c1, c2, ex, heads=1):
    k = 1.3 if "big" in ex else 1.0
    pts = []
    for i in range(14):
        t = i / 13
        a = t * math.tau * 1.25
        r = 1.4 * (1 - t * 0.55) * k
        pts.append(Vector((math.cos(a) * r, math.sin(a) * r + 0.3, 0.45 * k + t * 0.15)))
    for i, p in enumerate(pts):
        rr = (0.55 - i * 0.03) * k
        b.ball(p, rr, c1 if i % 3 else c2)
        if "spikes" in ex and i % 2 == 0:
            b.spike(p + Vector((0, 0, rr * 0.7)), p + Vector((0, 0, rr * 1.4)), 0.1 * k, c2)
        if "fins" in ex and i % 3 == 0:
            b.ball(p + Vector((0, 0, rr * 0.8)), rr * 0.8, c2, sq=(0.15, 1, 0.8))
    b.spike(pts[-1], pts[-1] + Vector((0.5, 0.6, 0.1)) * k, 0.15 * k, c1)
    tops = []
    for h in range(heads):
        off = (h - (heads - 1) / 2) * 0.9
        base = pts[0]
        nz = 1.8 * k + (0.3 if h == 1 else 0)
        neck_top = Vector((base.x * 0.4 + off, -0.7, nz))
        b.rod(base, neck_top, 0.42 * k, c1)
        hy, hz = -1.1, nz + 0.25 * k
        b.ball((off, hy, hz), 0.62 * k, c1, sq=(1, 1.35, 0.8))
        b.ball((off, hy - 0.2, hz - 0.3 * k), 0.5 * k, c2, sq=(0.9, 1.2, 0.4))
        b.eyes(0.33 * k, hy - 0.45 * k, hz + 0.3 * k, r=0.18 * k) if heads == 1 else None
        if heads > 1:
            for s in (-1, 1):
                b.ball((off + s * 0.3 * k, hy - 0.45 * k, hz + 0.25 * k), 0.15 * k, WHITE)
                b.ball((off + s * 0.31 * k, hy - 0.57 * k, hz + 0.25 * k), 0.09 * k, BLACK)
        if "fangs" in ex:
            for s in (-1, 1):
                b.spike((off + s * 0.22 * k, hy - 0.65 * k, hz - 0.2 * k), (off + s * 0.22 * k, hy - 0.65 * k, hz - 0.55 * k), 0.06 * k, WHITE)
        if "horns_back" in ex:
            for s in (-1, 1):
                b.spike((off + s * 0.3 * k, hy + 0.3, hz + 0.3 * k), (off + s * 0.45 * k, hy + 1.0, hz + 0.8 * k), 0.12 * k, BONE)
        tops.append((off, hy, hz + 0.5 * k))
    return tops[len(tops) // 2][2], tops[len(tops) // 2][1]


def build_turtle(b, c1, c2, ex):
    b.ball((0, 0, 0.75), 1.2, c2, sq=(1, 1.15, 0.6))
    for (x, y) in [(0, 0), (0.55, 0.4), (-0.55, 0.4), (0.55, -0.4), (-0.55, -0.4)]:
        b.ball((x, y, 1.15 - (abs(x) * 0.3)), 0.35, shade(c2, 0.2), sq=(1, 1, 0.35))
    b.ball((0, 0, 0.45), 1.2, shade(c1, 0.3), sq=(0.95, 1.1, 0.25))
    for sx in (-1, 1):
        for sy in (-1, 1):
            b.ball((sx * 0.95, sy * 0.85, 0.3), 0.32, c1, sq=(1, 1.2, 0.8))
    b.ball((0, -1.55, 0.75), 0.5, c1)
    b.eyes(0.25, -1.92, 0.9, r=0.15)
    b.box((0, -2.02, 0.62), (0.4, 0.04, 0.05), shade(c1, -0.5))
    return 1.5, -1.55


def build_octopus(b, c1, c2, ex):
    k = 1.35 if "big" in ex else 1.0
    b.ball((0, 0.2, 1.7 * k), 1.0 * k, c1, sq=(1, 1.1, 1.2))
    for i in range(8):
        a = i / 8 * math.tau
        p0 = Vector((math.cos(a) * 0.6 * k, math.sin(a) * 0.6 * k + 0.1, 0.9 * k))
        p1 = Vector((math.cos(a) * 1.4 * k, math.sin(a) * 1.4 * k, 0.25))
        p2 = Vector((math.cos(a + 0.4) * 1.9 * k, math.sin(a + 0.4) * 1.9 * k, 0.45))
        b.rod(p0, p1, 0.2 * k, c1)
        b.rod(p1, p2, 0.13 * k, c1)
        b.ball(p2, 0.14 * k, c2)
    for (x, y, z) in [(0.4, 0.3, 2.4), (-0.3, 0.6, 2.2), (0.1, 0.8, 1.6)]:
        b.ball((x * k, y * k, z * k), 0.13 * k, c2, sq=(1, 1, 0.4))
    b.eyes(0.4 * k, -0.7 * k, 1.6 * k, r=0.27 * k)
    if "teeth" in ex:
        for i in range(4):
            b.spike(((-0.25 + i * 0.17) * k, -0.75 * k, 1.05 * k), ((-0.25 + i * 0.17) * k, -0.78 * k, 0.85 * k), 0.06 * k, WHITE)
    return 3.0 * k, -0.2


def build_jelly(b, c1, c2, ex):
    b.ball((0, 0, 2.2), 1.2, c1, sq=(1, 1, 0.7))
    b.ball((0, 0, 1.75), 1.15, c2, sq=(1, 1, 0.15))
    for i in range(10):
        a = i / 10 * math.tau
        x, y = math.cos(a) * 0.8, math.sin(a) * 0.8
        b.rod((x, y, 1.7), (x * 1.1, y * 1.1, 0.9), 0.07, c2)
        b.rod((x * 1.1, y * 1.1, 0.9), (x * 0.9, y * 0.9, 0.15), 0.05, c1)
    for i in range(5):
        a = i / 5 * math.tau + 0.3
        b.spike((math.cos(a) * 0.4, math.sin(a) * 0.4, 2.85), (math.cos(a) * 0.5, math.sin(a) * 0.5, 3.15), 0.12, "#ffff80")
    b.eyes(0.35, -1.05, 2.15, r=0.2)
    return 3.2, 0


def build_crab(b, c1, c2, ex):
    b.ball((0, 0, 0.85), 1, c1, sq=(1.3, 0.95, 0.55))
    b.ball((0, 0, 0.65), 1, c2, sq=(1.2, 0.85, 0.35))
    for i, y in enumerate((-0.3, 0.15, 0.55)):
        for s in (-1, 1):
            p0 = Vector((s * 1.1, y, 0.75))
            p1 = Vector((s * 1.7, y + 0.1, 0.8))
            b.rod(p0, p1, 0.1, c1)
            b.rod(p1, Vector((s * 2.0, y + 0.15, 0.05)), 0.08, c1)
    for s in (-1, 1):
        b.rod((s * 0.9, -0.6, 0.9), (s * 1.3, -1.2, 1.0), 0.15, c1)
        b.ball((s * 1.4, -1.55, 1.05), 0.42, c1, sq=(0.8, 1.2, 0.8))
        b.spike((s * 1.25, -1.8, 1.25), (s * 1.15, -2.35, 1.35), 0.15, shade(c1, -0.2))
        b.spike((s * 1.5, -1.85, 0.9), (s * 1.4, -2.3, 0.85), 0.12, shade(c1, -0.2))
        b.rod((s * 0.35, -0.6, 1.2), (s * 0.4, -0.7, 1.75), 0.06, c1)
        b.ball((s * 0.4, -0.7, 1.85), 0.18, WHITE)
        b.ball((s * 0.4, -0.85, 1.87), 0.1, BLACK)
    b.box((0, -0.92, 0.85), (0.5, 0.04, 0.05), shade(c1, -0.5))
    return 2.1, -0.7


def build_beetle(b, c1, c2, ex):
    b.ball((0, 0.25, 0.9), 1, c2, sq=(1.0, 1.3, 0.75))
    b.box((0, 0.25, 1.55), (0.06, 2.4, 0.08), shade(c2, -0.5), bevel=0.02)
    b.ball((0, 0.25, 0.65), 1, c1, sq=(0.95, 1.2, 0.45))
    b.ball((0, -1.05, 0.75), 0.55, c1)
    b.eyes(0.28, -1.48, 0.9, r=0.17)
    for y in (-0.5, 0.2, 0.9):
        for s in (-1, 1):
            b.rod((s * 0.8, y, 0.6), (s * 1.4, y, 0.55), 0.08, c1)
            b.rod((s * 1.4, y, 0.55), (s * 1.6, y + 0.1, 0.0), 0.07, c1)
    if "horn" in ex:
        b.spike((0, -1.4, 0.95), (0, -2.0, 1.8), 0.18, c2)
    for s in (-1, 1):
        b.rod((s * 0.2, -1.4, 1.1), (s * 0.5, -1.8, 1.7), 0.04, c1)
    return 1.8, -1.0


def build_spider(b, c1, c2, ex):
    k = 0.75 if "small" in ex else 1.0
    b.ball((0, 0.6 * k, 1.0 * k), 0.9 * k, c1, sq=(1, 1.15, 0.9))
    for (x, y) in [(0, 0.4), (0.3, 0.9), (-0.3, 0.9)]:
        b.ball((x * k, y * k, 1.75 * k), 0.15 * k, c2, sq=(1, 1, 0.4))
    b.ball((0, -0.6 * k, 0.85 * k), 0.6 * k, c1)
    for i in range(4):
        for s in (-1, 1):
            y = (-0.9 + i * 0.35) * k
            p1 = Vector((s * 1.2 * k, y - 0.1 * k, 1.5 * k))
            b.rod((s * 0.4 * k, y * 0.5, 0.85 * k), p1, 0.07 * k, c1)
            b.rod(p1, (s * 1.8 * k, y - 0.2 * k, 0.0), 0.06 * k, c1)
    for s in (-1, 1):
        for (x, z, r) in [(0.18, 1.05, 0.14), (0.38, 0.95, 0.1)]:
            b.ball((s * x * k, -1.12 * k, z * k), r * k, c2, seg=8)
        b.spike((s * 0.15 * k, -1.1 * k, 0.6 * k), (s * 0.12 * k, -1.25 * k, 0.3 * k), 0.06 * k, WHITE)
    return 1.9 * k, -0.6 * k


def build_scorpion(b, c1, c2, ex):
    b.ball((0, 0, 0.6), 1, c1, sq=(0.75, 1.2, 0.45))
    segs = [Vector((0, 1.1, 0.7)), Vector((0, 1.6, 1.2)), Vector((0, 1.7, 1.9)), Vector((0, 1.4, 2.5)), Vector((0, 0.9, 2.7))]
    for i in range(len(segs) - 1):
        b.ball(segs[i], 0.3 - i * 0.03, c1)
        b.rod(segs[i], segs[i + 1], 0.2 - i * 0.02, c1)
    b.ball(segs[-1], 0.3, c2)
    b.spike(segs[-1], segs[-1] + Vector((0, -0.6, -0.3)), 0.12, c2)
    for y in (-0.4, 0.1, 0.6):
        for s in (-1, 1):
            b.rod((s * 0.6, y, 0.5), (s * 1.3, y, 0.45), 0.06, c1)
            b.rod((s * 1.3, y, 0.45), (s * 1.5, y + 0.1, 0.0), 0.05, c1)
    for s in (-1, 1):
        b.rod((s * 0.4, -0.9, 0.55), (s * 0.9, -1.6, 0.6), 0.12, c1)
        b.ball((s * 1.0, -1.9, 0.6), 0.32, c2, sq=(0.8, 1.3, 0.7))
        b.spike((s * 0.9, -2.15, 0.7), (s * 0.85, -2.6, 0.75), 0.1, c2)
        b.spike((s * 1.1, -2.15, 0.5), (s * 1.05, -2.55, 0.45), 0.09, c2)
    b.eyes(0.22, -1.05, 0.88, r=0.13)
    return 2.0, -0.8


def build_bat(b, c1, c2, ex):
    bz = 1.4
    b.ball((0, 0, bz), 0.65, c1, sq=(0.9, 0.85, 1.1))
    b.ball((0, -0.35, bz - 0.1), 0.45, c2, sq=(0.9, 0.5, 1))
    for s in (-1, 1):
        b.ball((s * 1.25, 0.1, bz + 0.35), 1.0, shade(c1, -0.2), sq=(1.1, 0.12, 0.65), rot=(0, s * -15, 0))
        for i in range(3):
            b.rod((s * 0.45, 0.05, bz + 0.3), (s * (0.9 + i * 0.6), 0.05, bz + 0.9 - i * 0.55), 0.04, c1)
        b.spike((s * 0.3, -0.05, bz + 0.55), (s * 0.5, 0, bz + 1.15), 0.18, c1)
        b.rod((s * 0.2, 0, bz - 0.6), (s * 0.25, 0, 0.1), 0.05, c1)
    b.eyes(0.22, -0.52, bz + 0.25, r=0.15)
    for s in (-1, 1):
        b.spike((s * 0.1, -0.6, bz - 0.05), (s * 0.1, -0.62, bz - 0.25), 0.04, WHITE)
    return bz + 1.0, -0.2


def build_moth(b, c1, c2, ex):
    bz = 1.3
    b.ball((0, 0.2, bz), 0.5, c1, sq=(0.8, 1.6, 0.8))
    b.ball((0, -0.6, bz + 0.2), 0.45, WHITE)
    for s in (-1, 1):
        b.ball((s * 1.2, -0.1, bz + 0.6), 1.0, c1, sq=(1.1, 0.8, 0.1), rot=(0, s * -25, 0))
        b.ball((s * 1.3, -0.1, bz + 0.65), 0.35, c2, sq=(1, 1, 0.12), rot=(0, s * -25, 0))
        b.ball((s * 0.9, 0.8, bz + 0.2), 0.6, shade(c1, -0.2), sq=(1.1, 0.8, 0.1), rot=(0, s * -15, 0))
        b.rod((s * 0.15, -0.9, bz + 0.5), (s * 0.5, -1.4, bz + 1.2), 0.03, c1)
        b.ball((s * 0.5, -1.4, bz + 1.2), 0.1, c2, seg=8)
        b.rod((s * 0.2, -0.3, bz - 0.3), (s * 0.35, -0.3, 0.05), 0.04, c1)
    b.eyes(0.2, -0.95, bz + 0.25, r=0.15)
    return bz + 1.3, -0.6


def build_snail(b, c1, c2, ex):
    b.ball((0, -0.2, 0.35), 1, c1, sq=(0.6, 1.6, 0.35))
    b.rod((0, -1.2, 0.4), (0, -1.5, 1.2), 0.3, c1)
    b.ball((0, -1.5, 1.3), 0.38, c1)
    for s in (-1, 1):
        b.rod((s * 0.15, -1.55, 1.55), (s * 0.3, -1.6, 2.1), 0.05, c1)
        b.ball((s * 0.3, -1.6, 2.15), 0.14, WHITE)
        b.ball((s * 0.31, -1.72, 2.15), 0.08, BLACK)
    b.ball((0, 0.3, 1.3), 1.0, c2, sq=(0.7, 1, 1))
    b.add("torus", (0, 0.3, 1.3), (0.62, 0.62, 1.2), shade(c2, 0.35), rot=(0, 90, 0))
    b.ball((0.5, 0.3, 1.3), 0.3, shade(c2, -0.2), sq=(0.4, 1, 1))
    b.ball((-0.5, 0.3, 1.3), 0.3, shade(c2, -0.2), sq=(0.4, 1, 1))
    return 2.3, -1.5


def build_slug(b, c1, c2, ex):
    for i in range(5):
        b.ball((0, -0.8 + i * 0.5, 0.45 + math.sin(i) * 0.1), 0.6 - i * 0.05, c1 if i % 2 == 0 else c2, sq=(1, 1, 0.7))
    b.ball((0, -1.3, 0.8), 0.55, c1)
    for s in (-1, 1):
        b.rod((s * 0.2, -1.4, 1.2), (s * 0.4, -1.5, 1.9), 0.06, c1)
        b.ball((s * 0.4, -1.5, 1.95), 0.18, WHITE)
        b.ball((s * 0.41, -1.66, 1.95), 0.1, BLACK)
    for (x, y) in [(0.3, -0.2), (-0.25, 0.4), (0.2, 0.9)]:
        b.ball((x, y, 0.85), 0.12, shade(c2, 0.4), seg=8)
    return 2.0, -1.3


def build_griffin(b, c1, c2, ex):
    top, hy = build_quad(b, c1, c2, "ears_none tail_long wings slim")
    return top, hy


SHAPES = {
    "quad": build_quad, "ape": build_ape, "bird": build_bird, "frog": build_frog, "seal": build_seal,
    "fish": build_fish, "whale": lambda b, c1, c2, ex: build_fish(b, c1, c2, ex, whale=True), "ray": build_ray,
    "snake": build_snake, "hydra": lambda b, c1, c2, ex: build_snake(b, c1, c2, ex, heads=3),
    "reptile": build_reptile, "dragon": lambda b, c1, c2, ex: build_reptile(b, c1, c2, ex + " spikes", wings=True),
    "dino": build_dino, "turtle": build_turtle, "octopus": build_octopus, "jelly": build_jelly, "crab": build_crab,
    "beetle": build_beetle, "spider": build_spider, "scorpion": build_scorpion, "bat": build_bat, "moth": build_moth,
    "snail": build_snail, "slug": build_slug, "griffin": build_griffin,
}


def build_animal(name, legendary=None):
    reset()
    shape, c1, c2, ex = SPECIES[name]
    b = B(name)
    if name == "Storm Griffin":
        # Grifo: cuerpo de león con cabeza de águila (pico) y alas
        top, hy = build_quad(b, c1, c2, "ears_none tail_long wings slim")
        b.spike((0, hy - 0.55, top - 0.75), (0, hy - 1.2, top - 0.95), 0.2, BEAK)
    else:
        top, hy = SHAPES[shape](b, c1, c2, ex)
    if legendary is None:
        legendary = any(name == row[4] for row in ORDER)
    if legendary and shape not in ("jelly",):
        crown(b, 0, hy, top + 0.05)
    return b.finish()


# ------------------------------------------------------------------ armas (apuntan a -Y, empuñadura en el origen)
WOOD, DWOOD, STEEL, DSTEEL = "#a0602e", "#6a3a1e", "#7a7e88", "#3a3c44"


def w_grip(b, color=DWOOD):
    b.box((0, 0, -0.35), (0.28, 0.32, 0.8), color, rot=(-12, 0, 0))


def build_weapon(i):
    reset()
    name = "W%02d" % i
    b = B(name)
    if i == 1:  # resortera
        b.add("cyl", (0, 0, -0.3), (0.12, 0.12, 0.45), WOOD)
        b.add("torus", (0, 0, -0.2), (0.14, 0.14, 0.3), "#c83a2a")
        for s in (-1, 1):
            b.rod((0, 0, 0.1), (s * 0.4, -0.05, 0.7), 0.1, WOOD)
            b.ball((s * 0.4, -0.05, 0.72), 0.11, WOOD)
            b.rod((s * 0.4, -0.05, 0.7), (s * 0.12, 0.45, 0.62), 0.03, "#e04040")
        b.ball((0, 0.5, 0.62), 0.16, "#6a4a2a", sq=(1.3, 0.7, 0.8))
        b.ball((0, 0.47, 0.66), 0.13, "#9a9a9a")
    elif i == 2:  # honda
        b.rod((0, 0, 0), (0, 0.1, -1.0), 0.03, "#d8c090")
        b.ball((0, 0.1, -1.1), 0.22, "#6a4a2a", sq=(1, 1, 0.6))
        b.ball((0, 0.1, -1.0), 0.17, "#8a8a8a")
        b.ball((0, 0, 0.05), 0.08, "#d8c090")
    elif i == 3:  # bumerán
        b.box((-0.35, -0.3, 0), (0.25, 0.9, 0.08), WOOD, rot=(0, 0, -40))
        b.box((0.35, -0.3, 0), (0.25, 0.9, 0.08), WOOD, rot=(0, 0, 40))
        b.box((0, -0.62, 0), (0.28, 0.28, 0.1), "#e05030", rot=(0, 0, 45))
    elif i == 4:  # cerbatana
        b.rod((0, 0.4, 0), (0, -2.4, 0), 0.09, "#8ab050")
        for y in (-0.4, -1.2, -2.0):
            b.add("cyl", (0, y, 0), (0.11, 0.11, 0.06), "#c08040", rot=(90, 0, 0))
        b.add("cyl", (0, 0.45, 0), (0.13, 0.13, 0.08), "#c83a2a", rot=(90, 0, 0))
    elif i in (5, 7, 16):  # arcos
        col = {5: WOOD, 7: DWOOD, 16: "#ffcc33"}[i]
        k = 1.25 if i != 5 else 1.0
        b.box((0, 0, 0), (0.14, 0.18, 0.5), "#3a2a1a")
        pts = [(0, 0, 0.25), (0, -0.25, 0.8 * k), (0, -0.1, 1.25 * k)]
        for s in (1, -1):
            p = [Vector((x, y, z * s)) for (x, y, z) in pts]
            b.rod(p[0], p[1], 0.07, col)
            b.rod(p[1], p[2], 0.055, col)
        b.rod((0, -0.1, 1.25 * k), (0, 0.15, 0), 0.015, WHITE)
        b.rod((0, 0.15, 0), (0, -0.1, -1.25 * k), 0.015, WHITE)
        b.rod((0, 0.15, 0.02), (0, -1.6, 0.02), 0.03, WOOD)
        b.spike((0, -1.6, 0.02), (0, -1.85, 0.02), 0.07, STEEL)
        for s in (-1, 1):
            b.box((s * 0.05, 0.1, 0.02), (0.02, 0.2, 0.12), "#e04040")
    elif i == 6:  # lanzador de lanzas
        b.rod((0, 0.4, 0.15), (0, -2.6, 0.15), 0.05, WOOD)
        b.spike((0, -2.6, 0.15), (0, -3.1, 0.15), 0.1, STEEL)
        b.box((0, 0.1, 0.0), (0.12, 1.0, 0.1), DWOOD)
        w_grip(b)
    elif i in (8, 16 + 100):  # ballesta
        b.box((0, -0.5, 0.15), (0.22, 1.6, 0.22), WOOD)
        w_grip(b)
        for s in (-1, 1):
            b.rod((0, -1.2, 0.2), (s * 0.85, -1.0, 0.2), 0.05, DSTEEL)
        b.rod((-0.85, -1.0, 0.24), (0, -0.55, 0.24), 0.015, WHITE)
        b.rod((0.85, -1.0, 0.24), (0, -0.55, 0.24), 0.015, WHITE)
        b.rod((0, -0.55, 0.28), (0, -1.5, 0.28), 0.03, DWOOD)
        b.spike((0, -1.5, 0.28), (0, -1.68, 0.28), 0.06, STEEL)
    else:  # armas de fuego y futuristas
        spec = {
            9: dict(barrel=2.0, stock=WOOD, metal=STEEL, long_stock=True),
            10: dict(barrel=1.2, stock=DWOOD, metal="#a08050"),
            11: dict(barrel=0.7, stock=DWOOD, metal="#b0b4c0", drum=True),
            12: dict(barrel=1.8, stock=WOOD, metal=DSTEEL, scope=True, long_stock=True),
            13: dict(barrel=1.5, stock=DWOOD, metal=DSTEEL, double=True, long_stock=True),
            14: dict(barrel=1.4, stock="#2a5a8a", metal=STEEL, harpoon=True, long_stock=True),
            15: dict(barrel=2.6, stock="#4a5a3a", metal="#2a2a30", scope=True, long_stock=True, bipod=True),
            17: dict(barrel=1.4, stock="#e8eaf0", metal="#3a3a5a", neon="#40e0ff", long_stock=True),
            18: dict(barrel=2.2, stock="#22222a", metal="#5a5a70", neon="#60ff60", scope=True, long_stock=True, rails=True),
            19: dict(barrel=1.6, stock="#5a2a1a", metal="#4a3028", neon="#ff8020", bulky=1.8, long_stock=True),
            20: dict(barrel=1.9, stock="#2a1050", metal="#4a2a8a", neon="#ff50ff", bulky=2.1, long_stock=True, rails=True),
        }[i]
        k = spec.get("bulky", 1.0)
        w_grip(b, spec["stock"])
        b.box((0, -0.35, 0.18), (0.26 * k, 0.9, 0.34 * k), spec["metal"], bevel=0.04)
        b.box((0, 0.1, -0.1), (0.06, 0.25, 0.04), DSTEEL)
        if spec.get("long_stock"):
            b.box((0, 0.65, 0.05), (0.22, 0.9, 0.3), spec["stock"], rot=(8, 0, 0))
        offs = (-0.07, 0.07) if spec.get("double") else (0,)
        for x in offs:
            b.rod((x, -0.7, 0.24), (x, -0.8 - spec["barrel"], 0.24), 0.07 * k, spec["metal"])
        b.box((0, -0.6 - spec["barrel"] * 0.4, 0.06), (0.16 * k, spec["barrel"] * 0.6, 0.12), spec["stock"])
        if spec.get("drum"):
            b.add("cyl", (0, -0.55, 0.22), (0.17, 0.17, 0.2), STEEL, rot=(90, 0, 0))
        if spec.get("scope"):
            b.rod((0, -0.1, 0.55), (0, -0.9, 0.55), 0.09, "#1a1a20")
            b.add("cyl", (0, -0.92, 0.55), (0.11, 0.11, 0.04), "#60a0ff", rot=(90, 0, 0))
        if spec.get("harpoon"):
            b.spike((0, -0.8 - spec["barrel"], 0.24), (0, -1.3 - spec["barrel"], 0.24), 0.14, STEEL)
            b.rod((0, -0.8 - spec["barrel"], 0.24), (0, -1.0 - spec["barrel"], 0.24), 0.03, STEEL)
        if spec.get("bipod"):
            for s in (-1, 1):
                b.rod((0, -1.8, 0.15), (s * 0.25, -1.9, -0.45), 0.03, DSTEEL)
        if spec.get("neon"):
            n = spec["neon"]
            b.rod((0, -0.3, 0.36 * k), (0, -0.6 - spec["barrel"], 0.36 * k), 0.035, n)
            b.ball((0, -0.85 - spec["barrel"], 0.24), 0.13 * k, n)
            for s in (-1, 1):
                b.box((s * 0.14 * k, -0.35, 0.18), (0.02, 0.5, 0.08), n)
        if spec.get("rails"):
            for s in (-1, 1):
                b.box((s * 0.12 * k, -0.6 - spec["barrel"] / 2, 0.24), (0.05, spec["barrel"], 0.08), spec["metal"])
        if i == 19:
            b.add("cyl", (0, -0.6, 0.24), (0.28, 0.28, 0.6), spec["metal"], rot=(90, 0, 0))
            b.ball((0, -1.25, 0.24), 0.22, "#ff4010")
        if i == 20:
            b.add("torus", (0, -1.2, 0.24), (0.35, 0.35, 0.8), spec["neon"], rot=(90, 0, 0))
            b.add("torus", (0, -1.8, 0.24), (0.28, 0.28, 0.7), spec["neon"], rot=(90, 0, 0))
    return b.finish()


# ------------------------------------------------------------------ exportar
def export(obj_name, rel):
    obj = bpy.data.objects[obj_name]
    bpy.ops.object.select_all(action="DESELECT")
    obj.select_set(True)
    bpy.context.view_layer.objects.active = obj
    path = os.path.join(OUT, rel + ".fbx")
    os.makedirs(os.path.dirname(path), exist_ok=True)
    bpy.ops.export_scene.fbx(filepath=path, use_selection=True, object_types={"MESH"}, path_mode="COPY",
                             embed_textures=True, apply_scale_options="FBX_SCALE_ALL", axis_forward="-Z", axis_up="Y",
                             use_mesh_modifiers=True, mesh_smooth_type="FACE")
    return path


def export_all(only=None):
    done = []
    for e, row in enumerate(ORDER, start=1):
        for r, name in enumerate(row, start=1):
            aid = e * 10 + r
            if only and aid not in only:
                continue
            build_animal(name)
            export(name, "animals/%d" % aid)
            done.append(aid)
    for i in range(1, 21):
        if only and ("w%d" % i) not in only:
            continue
        build_weapon(i)
        export("W%02d" % i, "weapons/%d" % i)
        done.append(100 + i)
    return done
