import os, json
from PIL import Image

ROOT = r"C:\Users\nckne\Desktop\capp\epay"
SRC  = os.path.join(ROOT, "assets", "images", "logo_mark.png")
SQ   = os.path.join(ROOT, "assets", "images", "logo_mark_square.png")
mark = Image.open(SRC).convert("RGBA")
sq   = Image.open(SQ).convert("RGBA")

def save(img, path, size):
    os.makedirs(os.path.dirname(path), exist_ok=True)
    img.resize((size, size), Image.LANCZOS).save(path)

# ---------- Android ----------
android = os.path.join(ROOT, "android", "app", "src", "main", "res")
for folder, px in [("mipmap-mdpi", 48), ("mipmap-hdpi", 72), ("mipmap-xhdpi", 96),
                   ("mipmap-xxhdpi", 144), ("mipmap-xxxhdpi", 192)]:
    save(mark, os.path.join(android, folder, "ic_launcher.png"), px)
print("android icons ok")

# ---------- iOS ----------
ios = os.path.join(ROOT, "ios", "Runner", "Assets.xcassets", "AppIcon.appiconset")
if os.path.isdir(ios):
    cj = os.path.join(ios, "Contents.json")
    data = json.load(open(cj))
    flat = sq.convert("RGB")          # iOS icons must be opaque, square
    for item in data.get("images", []):
        fn = item.get("filename")
        if not fn:
            continue
        sz = float(item["size"].split("x")[0])
        scale = float(item["scale"].replace("x", ""))
        px = int(round(sz * scale))
        flat.resize((px, px), Image.LANCZOS).save(os.path.join(ios, fn))
    print("ios icons ok")

# ---------- Web ----------
web = os.path.join(ROOT, "web")
if os.path.isdir(web):
    mark.resize((32, 32), Image.LANCZOS).save(os.path.join(web, "favicon.png"))
    for name, px in [("Icon-192.png", 192), ("Icon-512.png", 512),
                     ("Icon-maskable-192.png", 192), ("Icon-maskable-512.png", 512)]:
        save(sq, os.path.join(web, "icons", name), px)
    print("web icons ok")
