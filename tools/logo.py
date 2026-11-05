import os, math
from PIL import Image, ImageDraw, ImageFont, ImageFilter

OUT = r"C:\Users\nckne\Desktop\capp\epay\assets\images"
os.makedirs(OUT, exist_ok=True)

NAVY   = (14, 60, 155)
DEEP   = (7, 30, 69)
BLUE   = (21, 87, 214)
SKY    = (46, 155, 240)
CYAN   = (92, 200, 245)
WHITE  = (255, 255, 255)

def lerp(a, b, t):
    return tuple(int(round(a[i] + (b[i] - a[i]) * t)) for i in range(3))

def diagonal_gradient(size, c1, c2):
    """Smooth 45-degree gradient."""
    img = Image.new("RGB", (size, size))
    px = img.load()
    for y in range(size):
        for x in range(size):
            t = (x + y) / (2.0 * (size - 1))
            px[x, y] = lerp(c1, c2, t)
    return img

def rounded_mask(size, radius):
    m = Image.new("L", (size, size), 0)
    d = ImageDraw.Draw(m)
    d.rounded_rectangle([0, 0, size - 1, size - 1], radius=radius, fill=255)
    return m

def build_mark(size=1024, rounded=True, radius_ratio=0.225):
    S = size
    SS = 4  # supersample factor for the glyph layer
    grad = diagonal_gradient(S, SKY, NAVY)

    # soft gloss sweep across the top-left
    gloss = Image.new("L", (S, S), 0)
    gd = ImageDraw.Draw(gloss)
    gd.ellipse([-S * 0.45, -S * 0.75, S * 0.95, S * 0.45], fill=70)
    gloss = gloss.filter(ImageFilter.GaussianBlur(S * 0.10))
    grad = Image.composite(Image.new("RGB", (S, S), (255, 255, 255)), grad,
                           gloss.point(lambda v: int(v * 0.55)))

    base = grad.convert("RGBA")

    # ---- glyph layer (supersampled) ----
    L = S * SS
    gl = Image.new("RGBA", (L, L), (0, 0, 0, 0))
    g = ImageDraw.Draw(gl)

    u = L / 100.0  # 1 unit = 1% of canvas

    # "E" — three rounded bars anchored on a left spine
    bar_h   = 10.5 * u
    r       = bar_h / 2
    x0      = 21 * u
    spine_w = 10.5 * u
    top_y   = 26 * u
    mid_y   = 44.75 * u
    bot_y   = 63.5 * u

    g.rounded_rectangle([x0, top_y, x0 + spine_w, bot_y + bar_h],
                        radius=r, fill=WHITE + (255,))
    g.rounded_rectangle([x0, top_y, x0 + 35 * u, top_y + bar_h],
                        radius=r, fill=WHITE + (255,))
    g.rounded_rectangle([x0, mid_y, x0 + 26 * u, mid_y + bar_h],
                        radius=r, fill=WHITE + (255,))
    g.rounded_rectangle([x0, bot_y, x0 + 35 * u, bot_y + bar_h],
                        radius=r, fill=WHITE + (255,))

    # ---- rising arrow: growth + payment flow ----
    ax, ay = 60.0 * u, 73.0 * u      # foot of the shaft
    tx_, ty_ = 80.0 * u, 27.0 * u    # arrow tip
    dx, dy = tx_ - ax, ty_ - ay
    ln = math.hypot(dx, dy)
    ux, uy = dx / ln, dy / ln        # unit direction
    px_, py_ = -uy, ux               # unit perpendicular

    head_len  = 15.0 * u
    head_half = 9.5 * u
    shaft_w   = 8.0 * u

    # shaft stops where the head begins
    sx, sy = tx_ - ux * head_len * 0.82, ty_ - uy * head_len * 0.82
    g.line([(ax, ay), (sx, sy)], fill=CYAN + (255,), width=int(shaft_w))
    g.ellipse([ax - shaft_w / 2, ay - shaft_w / 2,
               ax + shaft_w / 2, ay + shaft_w / 2], fill=CYAN + (255,))

    # clean triangular head
    hbx, hby = tx_ - ux * head_len, ty_ - uy * head_len
    g.polygon([(tx_, ty_),
               (hbx + px_ * head_half, hby + py_ * head_half),
               (hbx - px_ * head_half, hby - py_ * head_half)],
              fill=CYAN + (255,))

    gl = gl.resize((S, S), Image.LANCZOS)

    # subtle drop shadow under the glyph
    sh = gl.split()[3].filter(ImageFilter.GaussianBlur(S * 0.012))
    shadow = Image.new("RGBA", (S, S), (0, 0, 0, 0))
    shadow.putalpha(sh.point(lambda v: int(v * 0.33)))
    base = Image.alpha_composite(base, shadow.convert("RGBA"))
    base = Image.alpha_composite(base, gl)

    if rounded:
        base.putalpha(rounded_mask(S, int(S * radius_ratio)))
    return base

def load_font(size, bold=True):
    names = (["segoeuib.ttf", "arialbd.ttf", "seguisb.ttf"] if bold
             else ["segoeui.ttf", "arial.ttf"])
    for n in names:
        for p in (r"C:\Windows\Fonts", "/usr/share/fonts/truetype/dejavu"):
            fp = os.path.join(p, n)
            if os.path.exists(fp):
                try:
                    return ImageFont.truetype(fp, size)
                except Exception:
                    pass
    return ImageFont.load_default()

def build_wordmark(dark_text=True, height=320):
    mark_s = height
    mark = build_mark(mark_s).resize((mark_s, mark_s), Image.LANCZOS)

    f = load_font(int(height * 0.62), bold=True)
    tmp = ImageDraw.Draw(Image.new("RGB", (10, 10)))
    bb_e = tmp.textbbox((0, 0), "E", font=f)
    bb_p = tmp.textbbox((0, 0), "Pay", font=f)
    w_e = bb_e[2] - bb_e[0]
    w_p = bb_p[2] - bb_p[0]

    gap = int(height * 0.22)
    W = mark_s + gap + w_e + w_p + int(height * 0.12)
    H = height
    img = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    img.alpha_composite(mark, (0, 0))

    d = ImageDraw.Draw(img)
    tx = mark_s + gap
    ty = (H - (bb_e[3] - bb_e[1])) // 2 - bb_e[1]
    c_e = SKY if dark_text else CYAN
    c_p = (10, 42, 94) if dark_text else WHITE
    d.text((tx, ty), "E", font=f, fill=c_e + (255,))
    d.text((tx + w_e, ty), "Pay", font=f, fill=c_p + (255,))
    return img

# ---------- emit ----------
mark = build_mark(1024)
mark.save(os.path.join(OUT, "logo_mark.png"))
mark.resize((512, 512), Image.LANCZOS).save(os.path.join(OUT, "logo_512.png"))
mark.resize((192, 192), Image.LANCZOS).save(os.path.join(OUT, "logo_192.png"))

build_mark(1024, rounded=False).save(os.path.join(OUT, "logo_mark_square.png"))

build_wordmark(True).save(os.path.join(OUT, "logo_wordmark.png"))
build_wordmark(False).save(os.path.join(OUT, "logo_wordmark_white.png"))

print("logo files written to", OUT)
for f in sorted(os.listdir(OUT)):
    print("  ", f)
