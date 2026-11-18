"""Build a 'GrowWithMe — by TOVO LABs' venture logo lockup."""
from PIL import Image, ImageDraw, ImageFont
import os

BASE = os.path.dirname(os.path.abspath(__file__))
ICON = os.path.join(BASE, "..", "..", "..", "mobile", "assets", "icon", "icon.png")
FRAUNCES = os.path.join(BASE, "fonts", "Fraunces.ttf")
MANROPE = os.path.join(BASE, "fonts", "Manrope.ttf")
OUT = os.path.join(BASE, "growwithme-tovo-lockup.png")

BG = (11, 56, 43)        # #0B382B deep green from the app icon
LIME = (199, 240, 107)   # #C7F06B sprout lime
CYAN = (56, 189, 248)    # TOVO cyan accent
WHITE = (245, 250, 246)

W, H = 1400, 420
img = Image.new("RGB", (W, H), BG)
d = ImageDraw.Draw(img)

# --- Icon: isolate the mark from its gradient background ---
icon = Image.open(ICON).convert("RGBA")
px = icon.load()
# Background dark greens have R <= ~20; the darker leaf has R ~89.
# Build a soft alpha ramp across R=25..55 so antialiased edges stay smooth.
for yy in range(icon.height):
    for xx in range(icon.width):
        r, g, b, _ = px[xx, yy]
        if r <= 25:
            a = 0
        elif r >= 55:
            a = 255
        else:
            a = int((r - 25) / 30 * 255)
        px[xx, yy] = (r, g, b, a)

# crop to the visible mark (central region)
s = icon.size[0]
box = (int(s*0.25), int(s*0.15), int(s*0.75), int(s*0.80))
mark = icon.crop(box)
target_h = 300
mark = mark.resize((int(mark.width * target_h / mark.height), target_h), Image.LANCZOS)
img.paste(mark, (40, (H - mark.height)//2), mark)

# --- Text block starts after the mark ---
tx = 40 + mark.width + 34

f_title = ImageFont.truetype(FRAUNCES, 104)
f_sub = ImageFont.truetype(MANROPE, 40)
f_tag = ImageFont.truetype(MANROPE, 27)

title = "GrowWithMe"
sub = "by TOVO LABs"
tag = "CARE THAT GROWS WITH YOU"

# vertical centring of the three-line block
line_heights = [104, 48, 34]
total = sum(line_heights) + 26
y = (H - total) // 2 - 6

# subtle accent rule to the left of "by TOVO LABs"
d.text((tx, y), title, font=f_title, fill=WHITE)
y += line_heights[0] + 2

# accent bar
d.rounded_rectangle((tx+2, y+18, tx+8, y+40), radius=3, fill=LIME)
d.text((tx+22, y-2), sub, font=f_sub, fill=LIME)
y += line_heights[1] + 8

d.text((tx+2, y), tag, font=f_tag, fill=(150, 190, 170))

img.save(OUT, "PNG", optimize=True)
print("Saved:", OUT, img.size, os.path.getsize(OUT), "bytes")
