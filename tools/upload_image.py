# Sube un PNG a Roblox como Image (Open Cloud) e imprime su assetId. Uso: python3 tools/upload_image.py archivo.png "Nombre"
import json, os, sys, time, uuid, urllib.request

API = "https://apis.roblox.com"
KEY = open(os.path.expanduser("~/.roblox-api-key")).read().strip()


def req(method, url, body=None, headers=None):
    r = urllib.request.Request(url, data=body, method=method, headers={"x-api-key": KEY, **(headers or {})})
    with urllib.request.urlopen(r) as res:
        raw = res.read()
        return json.loads(raw) if raw else {}


path, name = sys.argv[1], sys.argv[2]
info = req("POST", f"{API}/api-keys/v1/introspect", json.dumps({"apiKey": KEY}).encode(), {"Content-Type": "application/json"})
meta = {"assetType": "Image", "displayName": name, "description": "Kill a Beast",
        "creationContext": {"creator": {"userId": str(info["authorizedUserId"])}}}
b = uuid.uuid4().hex
body = b"".join([
    f"--{b}\r\nContent-Disposition: form-data; name=\"request\"\r\n\r\n{json.dumps(meta)}\r\n".encode(),
    f"--{b}\r\nContent-Disposition: form-data; name=\"fileContent\"; filename=\"img.png\"\r\nContent-Type: image/png\r\n\r\n".encode(),
    open(path, "rb").read(),
    f"\r\n--{b}--\r\n".encode(),
])
op = req("POST", f"{API}/assets/v1/assets", body, {"Content-Type": f"multipart/form-data; boundary={b}"})
for _ in range(60):
    if op.get("done"):
        break
    time.sleep(2)
    op = req("GET", f"{API}/assets/v1/{op['path']}")
print(op["response"]["assetId"])
