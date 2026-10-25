"""Generates docs/index.html — self-contained TOVO LABs / GrowWithMe landing page."""
import base64
import io
import json
import os
from PIL import Image

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))


def b64_img(path, width, q=82):
    im = Image.open(os.path.join(ROOT, path)).convert("RGB")
    h = int(im.height * width / im.width)
    im = im.resize((width, h), Image.LANCZOS)
    buf = io.BytesIO()
    im.save(buf, "JPEG", quality=q, optimize=True)
    return "data:image/jpeg;base64," + base64.b64encode(buf.getvalue()).decode()


def b64_png(path, width):
    im = Image.open(os.path.join(ROOT, path)).convert("RGBA")
    im = im.resize((width, int(im.height * width / im.width)), Image.LANCZOS)
    buf = io.BytesIO()
    im.save(buf, "PNG", optimize=True)
    return "data:image/png;base64," + base64.b64encode(buf.getvalue()).decode()


A = {
    "mark": b64_png("doc/outreach/assets/tovo-labs-mark.png", 192),
    "onb": b64_img("mobile/flutter_02.png", 400),
    "home": b64_img("mobile/flutter_04.png", 400),
    "triage": b64_img("mobile/flutter_09.png", 400),
}

NAVY = "#0b1526"
CYAN = "#35c8ff"
GREEN = "#1e6423"

features = [
    ("Offline IMCI-aligned triage", "Adaptive questions with deterministic danger rules for children and pregnancy — works with zero network. The rules engine, never the AI, owns every risk verdict."),
    ("WHO growth monitoring", "Every weight plotted on WHO curves; slipping below \u22122 SD raises a malnutrition flag and schedules a catch-up visit."),
    ("EPI-synced care calendar", "Immunizations, ANC/PNC, Vitamin A and deworming reminders synced to Ghana's schedule — spoken aloud for low-literacy mothers."),
    ("\u201cNana\u201d, voice-first AI educator", "A Ghanaian-elder persona for health questions and daily guidance, with a compact on-device model that keeps core commands working offline."),
    ("Closed referral loop", "One tap generates a PDF patient report and SMSes it to the nearest CHPS compound, volunteer responders and the hospital — every alert tracked to closure."),
    ("Facility dashboard", "Surfaces missed visits, growth faltering and lost-to-follow-up families, each with an SMS nudge — so nothing quietly disappears."),
]
feat_html = "".join('<div class="card"><h3>{}</h3><p>{}</p></div>'.format(t, d) for t, d in features)

CSS = """
*{margin:0;padding:0;box-sizing:border-box}
body{font-family:'Segoe UI',system-ui,Arial,sans-serif;color:#0b1526;background:#fff;line-height:1.6}
.wrap{max-width:1060px;margin:0 auto;padding:0 24px}
header{background:#0b1526;color:#fff;padding:64px 0 72px}
.brandrow{display:flex;align-items:center;gap:14px;margin-bottom:40px}
.brandrow img{width:52px;height:52px}
.wordmark{font-weight:800;font-size:26px;letter-spacing:-.02em;color:#fff}
.wordmark span{color:#35c8ff}
h1{font-size:clamp(30px,5vw,52px);line-height:1.12;letter-spacing:-.02em;max-width:760px}
.tag{margin-top:18px;font-size:clamp(16px,2.2vw,21px);color:#c6d4e8;max-width:680px}
.herocta{margin-top:28px;display:flex;gap:14px;flex-wrap:wrap}
.btn{display:inline-block;padding:13px 22px;border-radius:10px;font-weight:600;text-decoration:none}
.btn.primary{background:#35c8ff;color:#0b1526}
.btn.ghost{border:1.5px solid #33465f;color:#fff}
.stats{display:flex;gap:28px;flex-wrap:wrap;margin-top:44px}
.stat b{display:block;font-size:30px;color:#35c8ff}
.stat span{color:#9fb4d0;font-size:14px}
section{padding:64px 0}
h2{font-size:clamp(24px,3.4vw,34px);letter-spacing:-.01em;margin-bottom:10px}
.kicker{color:#1e6423;font-weight:700;text-transform:uppercase;letter-spacing:.14em;font-size:13px;margin-bottom:8px}
.lead{color:#41526b;max-width:720px;margin-bottom:34px}
.grid{display:grid;grid-template-columns:repeat(auto-fit,minmax(280px,1fr));gap:18px}
.card{border:1.5px solid #e3e8ef;border-radius:14px;padding:22px}
.card h3{font-size:17px;margin-bottom:8px}
.card p{font-size:14.5px;color:#41526b}
.phones{display:flex;gap:22px;justify-content:center;flex-wrap:wrap;margin-top:14px}
.phones img{width:min(300px,86vw);border-radius:18px;border:1px solid #e3e8ef;box-shadow:0 14px 40px rgba(11,21,38,.14)}
.loop{background:#f4f8f5}
.loopsteps{display:flex;gap:12px;flex-wrap:wrap;margin-top:8px}
.step{background:#fff;border:1.5px solid #d7e6d8;border-radius:12px;padding:14px 18px;font-size:14.5px;flex:1;min-width:170px}
.step b{display:block;color:#1e6423;font-size:13px;text-transform:uppercase;letter-spacing:.1em;margin-bottom:4px}
.tech{background:#0b1526;color:#fff}
.tech .lead{color:#c6d4e8}
.tech .kicker{color:#35c8ff}
ul.clean{list-style:none;max-width:760px}
ul.clean li{padding:10px 0;border-bottom:1px solid #22334d;font-size:15px;color:#dbe6f5}
ul.clean li:last-child{border-bottom:none}
footer{padding:40px 0 56px;color:#41526b;font-size:14px}
footer a{color:#1e6423;text-decoration:none;font-weight:600}
.contact b{font-size:18px}
"""

HTML = """<!doctype html>
<html lang="en">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width,initial-scale=1">
<title>GrowWithMe &mdash; by TOVO LABs</title>
<meta name="description" content="Offline-first AI care companion for mothers and children under five in Northern Ghana. IMCI-aligned triage, EPI care calendar, voice-first AI educator and a closed SMS referral loop &mdash; working with no internet.">
<meta property="og:title" content="GrowWithMe &mdash; by TOVO LABs">
<meta property="og:description" content="Offline-first AI care companion for mothers and children under five in Northern Ghana. Works with no internet.">
<meta property="og:type" content="website">
<style>{css}</style>
</head>
<body>
<header>
  <div class="wrap">
    <div class="brandrow">
      <img src="{mark}" alt="TOVO LABs">
      <div class="wordmark">tovo <span>labs</span></div>
    </div>
    <h1>Care that works where the network doesn&rsquo;t.</h1>
    <p class="tag">GrowWithMe is an offline-first AI care companion for mothers and children under five in Northern Ghana &mdash; built and working today.</p>
    <div class="herocta">
      <a class="btn primary" href="mailto:abdulhafis2847@gmail.com?subject=GrowWithMe%20demo%20request">Book a live demo</a>
      <a class="btn ghost" href="https://github.com/pious2847/GrowWithMe">See the repository</a>
    </div>
    <div class="stats">
      <div class="stat"><b>0 MB</b><span>data needed for triage, calendar &amp; growth monitoring</span></div>
      <div class="stat"><b>1 tap</b><span>from danger sign to SMS alert at facility + responders</span></div>
      <div class="stat"><b>0&ndash;59 m</b><span>covered from pregnancy through the fifth year</span></div>
    </div>
  </div>
</header>

<section>
  <div class="wrap">
    <div class="kicker">The problem</div>
    <h2>Distance, connectivity and literacy keep families from timely care</h2>
    <p class="lead">Northern Ghana carries some of the country&rsquo;s worst maternal and child health outcomes. Referrals die quietly between the CHPS compound and the hospital. Most digital-health pilots fail here because they assume a smartphone, data credit, or literacy the family doesn&rsquo;t have. GrowWithMe assumes the opposite.</p>
    <div class="phones">
      <img src="{onb}" alt="Consent-first onboarding">
      <img src="{home}" alt="Home with care calendar">
      <img src="{triage}" alt="Offline triage">
    </div>
  </div>
</section>

<section class="loop">
  <div class="wrap">
    <div class="kicker">The loop that closes</div>
    <h2>From a mother&rsquo;s thumb to a closed referral</h2>
    <div class="loopsteps">
      <div class="step"><b>1 &middot; Danger sign</b>Offline triage returns a verdict: low, moderate or urgent.</div>
      <div class="step"><b>2 &middot; One tap</b>PDF patient report SMSed to the nearest CHPS compound, volunteer responders and the hospital.</div>
      <div class="step"><b>3 &middot; Tracked</b>Every alert followed to closure &mdash; arrival confirmed, care confirmed.</div>
      <div class="step"><b>4 &middot; Seen</b>Facility dashboard surfaces missed visits, growth faltering and lost families.</div>
    </div>
  </div>
</section>

<section>
  <div class="wrap">
    <div class="kicker">What&rsquo;s inside</div>
    <h2>Built for the last mile, not the demo stage</h2>
    <div class="grid">{features}</div>
  </div>
</section>

<section class="tech">
  <div class="wrap">
    <div class="kicker">Engineering</div>
    <h2>Offline-first, voice-first, consent-first</h2>
    <p class="lead">Bounded AI: the LLM educates; a deterministic IMCI-aligned rules engine classifies every risk. Auditable by design.</p>
    <ul class="clean">
      <li><b>Flutter</b> offline-first architecture &mdash; local sync with last-write-wins and tombstones; the full core journey runs in airplane mode.</li>
      <li><b>Hybrid AI</b> &mdash; Llama 3.1 via NVIDIA NIM online; a compact fine-tuned on-device model keeps Nana&rsquo;s core commands working offline.</li>
      <li><b>Deterministic safety floor</b> &mdash; clinical rules can raise a verdict, never lower one; every urgent path ends with a human.</li>
      <li><b>Node/Express + MongoDB</b> backend, Arkesel SMS gateway, Cloudinary for referral reports &mdash; keys proxied server-side, nothing sensitive on the device.</li>
    </ul>
  </div>
</section>

<footer>
  <div class="wrap contact">
    <div class="kicker">Contact</div>
    <p class="contact"><b>Abdul Hafis Mohammed</b> &mdash; Founder, CEO &amp; Software Engineer, TOVO LABs<br>
    059 988 0977 &nbsp;&middot;&nbsp; <a href="mailto:abdulhafis2847@gmail.com">abdulhafis2847@gmail.com</a></p>
    <p style="margin-top:22px">TOVO LABs is a Ghanaian software engineering &amp; product studio. GrowWithMe is our health platform for mothers and children under five in Northern Ghana. A 2&frac34;-minute demo video and a working Android APK are available on request.</p>
    <p style="margin-top:14px">&copy; 2026 TOVO LABs</p>
  </div>
</footer>
</body>
</html>"""

out = HTML.format(css=CSS, features=feat_html, **A)
docs = os.path.join(ROOT, "docs")
os.makedirs(docs, exist_ok=True)
with open(os.path.join(docs, "index.html"), "w", encoding="utf-8") as f:
    f.write(out)
print("docs/index.html written:", os.path.getsize(os.path.join(docs, "index.html")) // 1024, "KB")
