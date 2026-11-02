# Sube assets/models/{animals,weapons}/*.fbx a Roblox (Open Cloud, tipo Model) y guarda los IDs en
# src/shared/ModelAssets.luau. Si ya tiene ID, sube una versión nueva del mismo asset (el ID no cambia).
# Uso: python3 tools/upload_models.py [animals|weapons] [nombre ...]
import json, os, re, sys, time, uuid, urllib.error, urllib.request

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
API = "https://apis.roblox.com"
KEY = open(os.path.expanduser("~/.roblox-api-key")).read().strip()
IDS_FILE = os.path.join(ROOT, "src", "shared", "ModelAssets.luau")


def req(method, url, body=None, headers=None):
    r = urllib.request.Request(url, data=body, method=method, headers={"x-api-key": KEY, **(headers or {})})
    for attempt in range(5):
        try:
            with urllib.request.urlopen(r) as res:
                raw = res.read()
                return json.loads(raw) if raw else {}
        except urllib.error.HTTPError as e:
            if e.code == 429 and attempt < 4:
                time.sleep(10 * (attempt + 1))
                continue
            sys.exit(f"{method} {url} -> {e.code}: {e.read().decode()}")


def read_ids():
    ids = {"Animals": {}, "Weapons": {}}
    if os.path.exists(IDS_FILE):
        group = None
        for line in open(IDS_FILE, encoding="utf-8"):
            m = re.match(r"\s*(Animals|Weapons) = \{", line)
            if m:
                group = m.group(1)
            m = re.match(r"\s*\[(\d+)\] = (\d+),", line)
            if m and group:
                ids[group][int(m.group(1))] = int(m.group(2))
    return ids


def write_ids(ids):
    lines = ["-- IDs de los modelos de Blender subidos a Roblox (generado por tools/upload_models.py).", "return {"]
    for group in ("Animals", "Weapons"):
        lines.append(f"\t{group} = {{")
        lines += [f"\t\t[{k}] = {ids[group][k]}," for k in sorted(ids[group])]
        lines.append("\t},")
    lines.append("}")
    open(IDS_FILE, "w", encoding="utf-8").write("\n".join(lines) + "\n")


def upload(path, display, owner, existing):
    b = uuid.uuid4().hex
    meta = {"assetId": existing} if existing else {"assetType": "Model", "displayName": display, "description": "Kill a Beast",
                                                   "creationContext": {"creator": owner}}
    body = b"".join([
        f"--{b}\r\nContent-Disposition: form-data; name=\"request\"\r\n\r\n{json.dumps(meta)}\r\n".encode(),
        f"--{b}\r\nContent-Disposition: form-data; name=\"fileContent\"; filename=\"model.fbx\"\r\nContent-Type: model/fbx\r\n\r\n".encode(),
        open(path, "rb").read(),
        f"\r\n--{b}--\r\n".encode(),
    ])
    h = {"Content-Type": f"multipart/form-data; boundary={b}"}
    op = req("PATCH", f"{API}/assets/v1/assets/{existing}", body, h) if existing else req("POST", f"{API}/assets/v1/assets", body, h)
    p = op["path"]
    for _ in range(90):
        if op.get("done"):
            break
        time.sleep(2)
        op = req("GET", f"{API}/assets/v1/{p}")
    if not op.get("done") or "error" in op:
        sys.exit(f"{path}: no se pudo subir ({op})")
    return int(op["response"]["assetId"])


def main():
    args = sys.argv[1:]
    kinds = [a for a in args if a in ("animals", "weapons")] or ["animals", "weapons"]
    only = {int(a) for a in args if a.isdigit()}
    info = req("POST", f"{API}/api-keys/v1/introspect", json.dumps({"apiKey": KEY}).encode(), {"Content-Type": "application/json"})
    owner = {"userId": str(info["authorizedUserId"])}
    ids = read_ids()
    for kind in kinds:
        group = kind.capitalize()
        folder = os.path.join(ROOT, "assets", "models", kind)
        for f in sorted(os.listdir(folder), key=lambda x: int(x[:-4])):
            n = int(f[:-4])
            if only and n not in only:
                continue
            ids[group][n] = upload(os.path.join(folder, f), f"KillABeast {group[:-1]} {n}", owner, ids[group].get(n))
            write_ids(ids)
            print(f"{kind} {n} -> {ids[group][n]}", flush=True)


if __name__ == "__main__":
    main()
