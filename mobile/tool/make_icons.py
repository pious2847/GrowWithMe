"""Renders the GrowWithMe launcher icon from the in-app `BrandMark`.

The app icon must match the brand mark used across the app: a forest
gradient tile carrying a lime sprout-heart (two leaves and a bud). Keeping
the geometry in one place means the launcher and the in-app logo never
drift apart. Run from the `mobile/` directory:

    python tool/make_icons.py
"""

from PIL import Image, ImageDraw

FOREST_TOP = (14, 70, 54)         # #0E4636 (heroGradient start)
FOREST_BOTTOM = (6, 36, 27)       # #06241B (heroGradient end)
LIME = (199, 240, 107, 255)       # #C7F06B
LIME_SOFT = (199, 240, 107, 107)  # 42% — the right leaf in BrandMark

SIZE = 1024
SCALE = 4  # supersample for smooth edges
S = SIZE * SCALE


def lerp(a, b, t):
    return tuple(round(x + (y - x) * t) for x, y in zip(a, b))


def gradient(size, steps=128):
    """Linear top-left → bottom-right, matching AppColors.heroGradient."""
    small = Image.new("RGB", (steps, steps))
    small.putdata(
        [
            lerp(FOREST_TOP, FOREST_BOTTOM, (x + y) / (2 * (steps - 1)))
            for y in range(steps)
            for x in range(steps)
        ]
    )
    return small.resize((size, size), Image.BICUBIC)


def cubic(p0, p1, p2, p3, steps=64):
    pts = []
    for i in range(steps + 1):
        t = i / steps
        u = 1 - t
        pts.append(
            (
                u**3 * p0[0] + 3 * u**2 * t * p1[0] + 3 * u * t**2 * p2[0] + t**3 * p3[0],
                u**3 * p0[1] + 3 * u**2 * t * p1[1] + 3 * u * t**2 * p2[1] + t**3 * p3[1],
            )
        )
    return pts


# The two leaves, exactly as painted by `_MarkPainter` on a 0..1 square.
LEFT_LEAF = (
    cubic((0.5, 0.76), (0.20, 0.60), (0.18, 0.30), (0.38, 0.28))
    + cubic((0.38, 0.28), (0.47, 0.27), (0.5, 0.36), (0.5, 0.40))[1:]
    + cubic((0.5, 0.40), (0.5, 0.50), (0.44, 0.62), (0.5, 0.76))[1:]
)
RIGHT_LEAF = (
    cubic((0.5, 0.76), (0.80, 0.60), (0.82, 0.30), (0.62, 0.28))
    + cubic((0.62, 0.28), (0.53, 0.27), (0.5, 0.36), (0.5, 0.40))[1:]
    + cubic((0.5, 0.40), (0.5, 0.50), (0.56, 0.62), (0.5, 0.76))[1:]
)


def draw_mark(size, pad_ratio, mono=False):
    """The mark itself on a transparent canvas."""
    layer = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(layer)

    w = size * (1 - 2 * pad_ratio)
    ox = oy = size * pad_ratio

    def px(points):
        return [(ox + x * w, oy + y * w) for x, y in points]

    if mono:
        # A single opaque silhouette for Android 13+ themed icons.
        draw.polygon(px(RIGHT_LEAF), fill=(255, 255, 255, 255))
        draw.polygon(px(LEFT_LEAF), fill=(255, 255, 255, 255))
        dot = (ox + 0.5 * w, oy + 0.20 * w)
        r = w * 0.035
        draw.ellipse((dot[0] - r, dot[1] - r, dot[0] + r, dot[1] + r), fill=(255, 255, 255, 255))
    else:
        draw.polygon(px(RIGHT_LEAF), fill=LIME_SOFT)
        draw.polygon(px(LEFT_LEAF), fill=LIME)
        dot = (ox + 0.5 * w, oy + 0.20 * w)
        r = w * 0.035
        draw.ellipse((dot[0] - r, dot[1] - r, dot[0] + r, dot[1] + r), fill=LIME)

    return layer


def main():
    # Adaptive background: the same forest gradient as the in-app tile.
    gradient(S).resize((SIZE, SIZE), Image.LANCZOS).save(
        "assets/icon/icon_background.png"
    )

    # Legacy square icon. Launchers apply their own corner mask.
    full = gradient(S).convert("RGBA")
    full.alpha_composite(draw_mark(S, 0.08))
    full.resize((SIZE, SIZE), Image.LANCZOS).save("assets/icon/icon.png")

    # Adaptive foreground: mark only, inside the 66% safe zone. The
    # launcher adds a 16% inset on top of this padding.
    draw_mark(S, 0.07).resize((SIZE, SIZE), Image.LANCZOS).save(
        "assets/icon/icon_foreground.png"
    )

    # Monochrome layer for Android 13+ themed icons.
    draw_mark(S, 0.07, mono=True).resize((SIZE, SIZE), Image.LANCZOS).save(
        "assets/icon/icon_monochrome.png"
    )

    print(
        "Wrote assets/icon/icon.png, icon_background.png, "
        "icon_foreground.png, icon_monochrome.png"
    )


if __name__ == "__main__":
    main()
