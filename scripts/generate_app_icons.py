# -*- coding: utf-8 -*-
import os
import shutil
from collections import deque
from PIL import Image, ImageDraw, ImageFilter

SRC = r"C:\Users\Admin\Downloads\log_app.png"
PROJECT_ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))

print(f"Loading master logo from {SRC}...")
img = Image.open(SRC).convert("RGB")
w, h = img.size
pixels = img.load()

# 1. Connected Flood Fill for Exterior Background
print("Extracting alpha mask with contour preservation...")
visited = bytearray(w * h)
q = deque()

# Seed borders
for x in range(w):
    for y in (0, h - 1):
        idx = y * w + x
        if not visited[idx] and min(pixels[x, y]) >= 245:
            visited[idx] = 1
            q.append((x, y))

for y in range(h):
    for x in (0, w - 1):
        idx = y * w + x
        if not visited[idx] and min(pixels[x, y]) >= 245:
            visited[idx] = 1
            q.append((x, y))

# BFS exterior
while q:
    x, y = q.popleft()
    for dx, dy in ((-1, 0), (1, 0), (0, -1), (0, 1)):
        nx, ny = x + dx, y + dy
        if 0 <= nx < w and 0 <= ny < h:
            idx = ny * w + nx
            if not visited[idx] and min(pixels[nx, ny]) >= 245:
                visited[idx] = 1
                q.append((nx, ny))

# Negative space inside text letters (B, a, b, D in y >= 1680)
for y in range(1680, h):
    for x in range(w):
        idx = y * w + x
        if not visited[idx] and min(pixels[x, y]) >= 245:
            visited[idx] = 1
            cq = deque([(x, y)])
            while cq:
                cx, cy = cq.popleft()
                for dx, dy in ((-1, 0), (1, 0), (0, -1), (0, 1)):
                    nx, ny = cx + dx, cy + dy
                    if 0 <= nx < w and 1680 <= ny < h:
                        nidx = ny * w + nx
                        if not visited[nidx] and min(pixels[nx, ny]) >= 245:
                            visited[nidx] = 1
                            cq.append((nx, ny))

# Anti-aliased alpha boundary
alpha = Image.new("L", (w, h), 255)
ap = alpha.load()
for y in range(h):
    for x in range(w):
        if visited[y * w + x]:
            ap[x, y] = 0

for y in range(1, h - 1):
    for x in range(1, w - 1):
        if not visited[y * w + x]:
            if (visited[(y-1)*w + x] or visited[(y+1)*w + x] or 
                visited[y*w + x-1] or visited[y*w + x+1]):
                r, g, b = pixels[x, y]
                d = max(255 - r, 255 - g, 255 - b)
                if d < 45:
                    ap[x, y] = int((d / 45) * 255)

alpha = alpha.filter(ImageFilter.GaussianBlur(1.0))
for y in range(h):
    for x in range(w):
        if visited[y * w + x]:
            ap[x, y] = 0

cutout = img.copy().convert("RGBA")
cutout.putalpha(alpha)

# 2. Extract Components
full_bbox = cutout.getbbox()
full_logo = cutout.crop(full_bbox)

# Extract Mark (illustration without text)
mark_crop = cutout.crop((full_bbox[0], full_bbox[1], full_bbox[2], 1665))
mark_bbox = mark_crop.getbbox()
mark_logo = mark_crop.crop(mark_bbox)

print(f"Full logo dimensions: {full_logo.size}")
print(f"Mark logo dimensions: {mark_logo.size}")

# 3. Build Master 1024x1024 Square App Icon
S = 1024
base = Image.new("RGB", (S, S))
bp = base.load()
for y in range(S):
    t = y / S
    r = 255
    g = int(249 - 8 * t)
    b = int(250 - 10 * t)
    for x in range(S):
        bp[x, y] = (r, g, b)

glow = Image.new("L", (S, S), 0)
ImageDraw.Draw(glow).ellipse((S * 0.1, S * 0.1, S * 0.9, S * 0.9), fill=80)
glow = glow.filter(ImageFilter.GaussianBlur(150))
base = Image.composite(Image.new("RGB", (S, S), (255, 255, 255)), base, glow)

w_mark = 670
h_mark = int(w_mark * mark_logo.height / mark_logo.width)
resized_mark = mark_logo.resize((w_mark, h_mark), Image.LANCZOS)
mx = (S - w_mark) // 2
my = (S - h_mark) // 2 - 10

# Soft drop shadow
pad = Image.new("L", (w_mark + 80, h_mark + 80), 0)
pad.paste(resized_mark.getchannel("A"), (40, 40))
sa = pad.point(lambda v: int(v * 0.18)).filter(ImageFilter.GaussianBlur(16))
shadow = Image.new("RGBA", sa.size, (180, 100, 110, 255))
shadow.putalpha(sa)

master_icon = base.convert("RGBA")
master_icon.alpha_composite(shadow, (mx - 40, my - 40 + 12))
master_icon.alpha_composite(resized_mark, (mx, my))

# Solid RGB master (required for iOS App Store & standard app icons)
master_rgb = master_icon.convert("RGB")

# 4. Generate Target Folders
FRONTEND_PUBLIC = os.path.join(PROJECT_ROOT, "frontend", "public")
MOBILE_ASSETS = os.path.join(PROJECT_ROOT, "mobile", "assets", "images")
ANDROID_RES = os.path.join(PROJECT_ROOT, "mobile", "android", "app", "src", "main", "res")
IOS_APPICON = os.path.join(PROJECT_ROOT, "mobile", "ios", "Runner", "Assets.xcassets", "AppIcon.appiconset")
MACOS_APPICON = os.path.join(PROJECT_ROOT, "mobile", "macos", "Runner", "Assets.xcassets", "AppIcon.appiconset")
WINDOWS_RES = os.path.join(PROJECT_ROOT, "mobile", "windows", "runner", "resources")
MOBILE_WEB = os.path.join(PROJECT_ROOT, "mobile", "web")

os.makedirs(FRONTEND_PUBLIC, exist_ok=True)
os.makedirs(MOBILE_ASSETS, exist_ok=True)
os.makedirs(ANDROID_RES, exist_ok=True)
os.makedirs(IOS_APPICON, exist_ok=True)
os.makedirs(MACOS_APPICON, exist_ok=True)
os.makedirs(WINDOWS_RES, exist_ok=True)
os.makedirs(os.path.join(MOBILE_WEB, "icons"), exist_ok=True)

# 5. Save Shared High-Res Brand Logos
print("Saving shared brand assets...")
full_logo.save(os.path.join(FRONTEND_PUBLIC, "logo.png"))
full_logo.save(os.path.join(MOBILE_ASSETS, "logo.png"))

mark_logo.save(os.path.join(FRONTEND_PUBLIC, "logo_mark.png"))
mark_logo.save(os.path.join(MOBILE_ASSETS, "logo_mark.png"))

master_rgb.save(os.path.join(FRONTEND_PUBLIC, "app_icon_1024.png"))

# 6. Web Favicon & App Icons
print("Generating Web icons & favicons...")
master_rgb.resize((32, 32), Image.LANCZOS).save(os.path.join(FRONTEND_PUBLIC, "favicon.png"))
master_rgb.resize((180, 180), Image.LANCZOS).save(os.path.join(FRONTEND_PUBLIC, "apple-touch-icon.png"))
master_rgb.resize((192, 192), Image.LANCZOS).save(os.path.join(FRONTEND_PUBLIC, "icon-192.png"))
master_rgb.resize((512, 512), Image.LANCZOS).save(os.path.join(FRONTEND_PUBLIC, "icon-512.png"))

# Multi-resolution favicon.ico
master_rgb.resize((256, 256), Image.LANCZOS).save(
    os.path.join(FRONTEND_PUBLIC, "favicon.ico"),
    sizes=[(16, 16), (24, 24), (32, 32), (48, 48), (64, 64), (128, 128), (256, 256)]
)

# 7. Flutter Mobile Web Icons
master_rgb.resize((32, 32), Image.LANCZOS).save(os.path.join(MOBILE_WEB, "favicon.png"))
master_rgb.resize((192, 192), Image.LANCZOS).save(os.path.join(MOBILE_WEB, "icons", "Icon-192.png"))
master_rgb.resize((512, 512), Image.LANCZOS).save(os.path.join(MOBILE_WEB, "icons", "Icon-512.png"))
master_icon.resize((192, 192), Image.LANCZOS).save(os.path.join(MOBILE_WEB, "icons", "Icon-maskable-192.png"))
master_icon.resize((512, 512), Image.LANCZOS).save(os.path.join(MOBILE_WEB, "icons", "Icon-maskable-512.png"))

# 8. Android Launcher Icons (mipmap)
print("Generating Android mipmap launcher icons...")
android_sizes = {
    "mipmap-mdpi": 48,
    "mipmap-hdpi": 72,
    "mipmap-xhdpi": 96,
    "mipmap-xxhdpi": 144,
    "mipmap-xxxhdpi": 192,
}
for folder, size in android_sizes.items():
    dest_dir = os.path.join(ANDROID_RES, folder)
    os.makedirs(dest_dir, exist_ok=True)
    master_rgb.resize((size, size), Image.LANCZOS).save(os.path.join(dest_dir, "ic_launcher.png"))

# 9. iOS App Icons
print("Generating iOS AppIcon set...")
ios_icons = [
    ("Icon-App-20x20@1x.png", 20),
    ("Icon-App-20x20@2x.png", 40),
    ("Icon-App-20x20@3x.png", 60),
    ("Icon-App-29x29@1x.png", 29),
    ("Icon-App-29x29@2x.png", 58),
    ("Icon-App-29x29@3x.png", 87),
    ("Icon-App-40x40@1x.png", 40),
    ("Icon-App-40x40@2x.png", 80),
    ("Icon-App-40x40@3x.png", 120),
    ("Icon-App-60x60@2x.png", 120),
    ("Icon-App-60x60@3x.png", 180),
    ("Icon-App-76x76@1x.png", 76),
    ("Icon-App-76x76@2x.png", 152),
    ("Icon-App-83.5x83.5@2x.png", 167),
    ("Icon-App-1024x1024@1x.png", 1024),
]
for fname, size in ios_icons:
    master_rgb.resize((size, size), Image.LANCZOS).save(os.path.join(IOS_APPICON, fname))

# 10. macOS App Icons
print("Generating macOS AppIcon set...")
macos_icons = [
    ("app_icon_16.png", 16),
    ("app_icon_32.png", 32),
    ("app_icon_64.png", 64),
    ("app_icon_128.png", 128),
    ("app_icon_256.png", 256),
    ("app_icon_512.png", 512),
    ("app_icon_1024.png", 1024),
]
for fname, size in macos_icons:
    master_icon.resize((size, size), Image.LANCZOS).save(os.path.join(MACOS_APPICON, fname))

# 11. Windows Resources (.ico)
print("Generating Windows app_icon.ico...")
master_rgb.resize((256, 256), Image.LANCZOS).save(
    os.path.join(WINDOWS_RES, "app_icon.ico"),
    sizes=[(16, 16), (24, 24), (32, 32), (48, 48), (64, 64), (128, 128), (256, 256)]
)

print("All app icons and logos successfully generated!")
