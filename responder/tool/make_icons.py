"""Renders the GrowWithMe Responder launcher icon from the in-app mark.

The app icon must match `ResponderMark` (forest tile, lime cross, lime
heartbeat) so the launcher and the in-app brand read as one product.
Run from the `responder/` directory:

    python tool/make_icons.py
"""

from PIL import Image, ImageDraw

FOREST = (11, 59, 46, 255)        # #0B3B2E
LIME = (199, 240, 107, 255)       # #C7F06B

SIZE = 1024
SCALE = 4  # supersample for smooth edges
S = SIZE * SCALE


def draw_mark(size, pad_ratio, background=True):
    """The mark itself, centred in a square canvas."""
    img = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    if background:
        # Full-bleed legacy icon; launchers apply their own corner mask.
        img.paste(FOREST, (0, 0, size, size))
    draw = ImageDraw.Draw(img)

    # Work in mark-space: the painter uses a 0..1 square, scaled and padded.
    w = size * (1 - 2 * pad_ratio)
    ox = oy = size * pad_ratio

    def px(x, y):
        return (ox + x * w, oy + y * w)

    arm = w * 0.10
    long = w * 0.50
    cx, cy = 0.5, 0.37
    r = arm * 0.38

    # Vertical and horizontal bars of the cross.
    for rect in (
        (cx * w - arm, cy * w - long / 2, cx * w + arm, cy * w + long / 2),
        (cx * w - long / 2, cy * w - arm, cx * w + long / 2, cy * w + arm),
    ):
        x0, y0, x1, y1 = rect
        draw.rounded_rectangle(
            (ox + x0, oy + y0, ox + x1, oy + y1),
            radius=r,
            fill=LIME,
        )

    # Heartbeat beneath the cross.
    pts = [
        (0.18, 0.80), (0.36, 0.80), (0.44, 0.72),
        (0.54, 0.88), (0.62, 0.80), (0.82, 0.80),
    ]
    pts = [px(x, y) for x, y in pts]
    stroke = w * 0.045
    draw.line(pts, fill=LIME, width=int(stroke), joint="curve")
    # Round caps.
    for p in (pts[0], pts[-1]):
        draw.ellipse(
            (p[0] - stroke / 2, p[1] - stroke / 2,
             p[0] + stroke / 2, p[1] + stroke / 2),
            fill=LIME,
        )

    return img


def main():
    # Legacy square icon (used as a fallback by some launchers).
    full = draw_mark(S, 0.0, background=True).resize((SIZE, SIZE), Image.LANCZOS)
    full.save("assets/icon/icon.png")

    # Adaptive foreground: transparent, mark sits inside the 66% safe zone.
    fg = draw_mark(S, 0.22, background=False).resize((SIZE, SIZE), Image.LANCZOS)
    fg.save("assets/icon/icon_foreground.png")

    # Monochrome layer for Android 13+ themed icons.
    mono = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
    mark = draw_mark(S, 0.22, background=False).resize(
        (SIZE, SIZE), Image.LANCZOS
    )
    alpha = mark.getchannel("A")
    mono.putalpha(alpha)
    mono.paste((255, 255, 255, 255), (0, 0), mark)
    mono.save("assets/icon/icon_monochrome.png")
    print("Wrote assets/icon/icon.png, icon_foreground.png, icon_monochrome.png")


if __name__ == "__main__":
    main()
