"""Generates Google Play store graphics as exact-size PNGs:
   store_assets/app_icon_512.png       (512x512)
   store_assets/feature_graphic_1024x500.png (1024x500)
Run:  python make_store_assets.py
"""
import math, os
import numpy as np
from PIL import Image, ImageDraw, ImageFont

OUT = os.path.join(os.path.dirname(__file__), 'store_assets')
os.makedirs(OUT, exist_ok=True)
FB = 'C:/Windows/Fonts/arialbd.ttf'
FR = 'C:/Windows/Fonts/arial.ttf'

# Game's five arrow colours + the multicolour heart-stroke ramp.
RAMP = [(0xE5, 0xB1, 0x42), (0xE6, 0x7E, 0x22), (0xE0, 0x5B, 0x8A),
        (0x9B, 0x59, 0xB6), (0x4A, 0x90, 0xE2)]


def lerp(a, b, t):
    return tuple(int(a[i] + (b[i] - a[i]) * t) for i in range(3))


def ramp_color(f):
    f = max(0.0, min(0.999, f))
    seg = f * (len(RAMP) - 1)
    i = int(seg)
    return lerp(RAMP[i], RAMP[i + 1], seg - i)


def diag_gradient(w, h, stops):
    """Diagonal (top-left -> bottom-right) multi-stop gradient as an RGB array."""
    yy, xx = np.mgrid[0:h, 0:w]
    d = (xx / w + yy / h) / 2.0  # 0..1 along the diagonal
    img = np.zeros((h, w, 3), np.float64)
    for c in range(3):
        pos = [s[0] for s in stops]
        val = [s[1][c] for s in stops]
        img[:, :, c] = np.interp(d, pos, val)
    return img


def radial_glow(w, h, cx, cy, r, color, strength):
    yy, xx = np.mgrid[0:h, 0:w]
    dist = np.sqrt((xx - cx) ** 2 + (yy - cy) ** 2) / r
    a = np.clip(1 - dist, 0, 1) ** 1.5 * strength
    layer = np.zeros((h, w, 3), np.float64)
    for c in range(3):
        layer[:, :, c] = color[c]
    return layer, a[:, :, None]


def heart_points(cx, cy, s, n=460):
    pts = []
    for k in range(n + 1):
        t = 2 * math.pi * k / n
        hx = 16 * math.sin(t) ** 3
        hy = -(13 * math.cos(t) - 5 * math.cos(2 * t) - 2 * math.cos(3 * t) - math.cos(4 * t))
        pts.append((cx + hx * s, cy + hy * s))
    return pts


def draw_heart(draw, cx, cy, s, width):
    pts = heart_points(cx, cy, s)
    # soft inner fill
    draw.polygon(pts, fill=(255, 255, 255, 16))
    n = len(pts)
    for i in range(n - 1):
        col = ramp_color(i / n)
        draw.line([pts[i], pts[i + 1]], fill=col + (255,), width=width)
        draw.ellipse([pts[i][0] - width / 2, pts[i][1] - width / 2,
                      pts[i][0] + width / 2, pts[i][1] + width / 2], fill=col + (255,))


def draw_arrow(draw, sx, sy, ex, ey, color, width):
    ang = math.atan2(ey - sy, ex - sx)
    hl = width * 1.5
    # faint motion trail
    tx, ty = sx - math.cos(ang) * width * 1.2, sy - math.sin(ang) * width * 1.2
    trail = tuple(int(color[i] * 0.5 + 255 * 0.0) for i in range(3))
    draw.line([(tx, ty), (sx, sy)], fill=trail + (120,), width=max(2, width - 4))
    draw.line([(sx, sy), (ex, ey)], fill=color + (255,), width=width)
    for da in (ang + math.radians(150), ang - math.radians(150)):
        draw.line([(ex, ey), (ex + math.cos(da) * hl, ey + math.sin(da) * hl)],
                  fill=color + (255,), width=width)


def sparkle(draw, cx, cy, r, color):
    draw.polygon([(cx, cy - r), (cx + r * 0.28, cy - r * 0.28), (cx + r, cy),
                  (cx + r * 0.28, cy + r * 0.28), (cx, cy + r),
                  (cx - r * 0.28, cy + r * 0.28), (cx - r, cy),
                  (cx - r * 0.28, cy - r * 0.28)], fill=color + (255,))


# --------------------------------------------------------------------------
# 1) APP ICON 512x512
# --------------------------------------------------------------------------
W = H = 512
bg = diag_gradient(W, H, [(0.0, (0x14, 0x1A, 0x44)), (0.55, (0x3B, 0x1E, 0x78)),
                          (1.0, (0x7C, 0x3A, 0xED))])
icon = Image.fromarray(np.clip(bg, 0, 255).astype(np.uint8), 'RGB').convert('RGBA')
ov = Image.new('RGBA', (W, H), (0, 0, 0, 0))
d = ImageDraw.Draw(ov)
# top gloss
d.rectangle([0, 0, W, 210], fill=(255, 255, 255, 14))
for (x, y, r) in [(90, 120, 4), (150, 90, 4), (410, 360, 4), (360, 420, 4), (440, 140, 3)]:
    d.ellipse([x - r, y - r, x + r, y + r], fill=(255, 255, 255, 22))
draw_heart(d, 256, 250, 8.4, 30)
draw_arrow(d, 344, 192, 392, 144, RAMP[0], 13)
draw_arrow(d, 312, 146, 350, 100, (0x2E, 0xCC, 0x71), 12)
draw_arrow(d, 398, 236, 440, 214, (0x4A, 0x90, 0xE2), 12)
sparkle(d, 150, 250, 12, (255, 233, 168))
sparkle(d, 400, 300, 9, (255, 233, 168))
icon = Image.alpha_composite(icon, ov)
# rounded-corner mask
mask = Image.new('L', (W, H), 0)
ImageDraw.Draw(mask).rounded_rectangle([0, 0, W, H], radius=115, fill=255)
icon.putalpha(mask)
icon.save(os.path.join(OUT, 'app_icon_512.png'))
print('saved app_icon_512.png')

# --------------------------------------------------------------------------
# 2) FEATURE GRAPHIC 1024x500
# --------------------------------------------------------------------------
FW, FH = 1024, 500
base = diag_gradient(FW, FH, [(0.0, (0x10, 0x14, 0x3A)), (0.5, (0x2E, 0x1A, 0x66)),
                              (1.0, (0x5B, 0x21, 0xB6))])
glow, ga = radial_glow(FW, FH, 800, 250, 300, (0x7C, 0x3A, 0xED), 0.55)
base = base * (1 - ga) + glow * ga
feat = Image.fromarray(np.clip(base, 0, 255).astype(np.uint8), 'RGB').convert('RGBA')
ov = Image.new('RGBA', (FW, FH), (0, 0, 0, 0))
d = ImageDraw.Draw(ov)
for (x, y, r) in [(70, 380, 4), (120, 430, 3), (980, 80, 4), (930, 130, 3), (600, 70, 3)]:
    d.ellipse([x - r, y - r, x + r, y + r], fill=(255, 255, 255, 22))
# right-side heart + arrows
draw_heart(d, 792, 250, 9.6, 26)
draw_arrow(d, 884, 198, 930, 150, RAMP[0], 12)
draw_arrow(d, 852, 146, 888, 104, (0x2E, 0xCC, 0x71), 11)
draw_arrow(d, 928, 246, 972, 226, (0x4A, 0x90, 0xE2), 11)
sparkle(d, 660, 180, 12, (255, 233, 168))
sparkle(d, 946, 336, 9, (255, 233, 168))
# text
f_title = ImageFont.truetype(FB, 74)
f_tap = ImageFont.truetype(FB, 46)
f_sub = ImageFont.truetype(FR, 26)
f_pill = ImageFont.truetype(FB, 22)
d.text((58, 78), 'Arrow Puzzle', font=f_title, fill=(255, 255, 255, 255))
d.text((60, 168), 'TAP AWAY', font=f_tap, fill=(0xFF, 0xCE, 0x4A, 255))
d.text((60, 238), 'Clear the arrows — free the hidden shape!', font=f_sub,
       fill=(0xE8, 0xE2, 0xFF, 255))


def pill(x, y, w, h, fill, text, tcol):
    d.rounded_rectangle([x, y, x + w, y + h], radius=h // 2, fill=fill)
    bb = d.textbbox((0, 0), text, font=f_pill)
    d.text((x + (w - (bb[2] - bb[0])) / 2, y + (h - (bb[3] - bb[1])) / 2 - bb[1]),
           text, font=f_pill, fill=tcol)


pill(60, 300, 150, 46, (255, 255, 255, 38), '200 LEVELS', (255, 255, 255, 255))
pill(222, 300, 172, 46, (255, 255, 255, 38), '150+ SHAPES', (255, 255, 255, 255))
pill(60, 362, 340, 52, (0xFF, 0xCE, 0x4A, 255), 'PLAY YOUR OWN NAME!', (0x3A, 0x22, 0x00, 255))
feat = Image.alpha_composite(feat, ov).convert('RGB')
feat.save(os.path.join(OUT, 'feature_graphic_1024x500.png'))
print('saved feature_graphic_1024x500.png')
print('Folder:', OUT)
