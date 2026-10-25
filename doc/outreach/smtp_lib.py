"""SMTP helpers for TOVO LABs outreach. Credentials live OUTSIDE the repo:
%TEMP%/opencode/smtp_tovolabs.json — never commit them.
"""
import json
import os
import smtplib
import ssl
import sys
from email.message import EmailMessage
from email.utils import formatdate
from pathlib import Path

CRED_PATH = Path(os.environ.get("TEMP", "/tmp")) / "opencode" / "smtp_tovolabs.json"
LOGO_PATH = Path(__file__).parent / "assets" / "tovo-labs-logo-onnavy.png"


def load_creds():
    d = json.loads(CRED_PATH.read_text(encoding="utf-8-sig"))
    return {
        "host": d.get("host", "smtp.gmail.com"),
        "port": int(d.get("port", 587)),
        "email": d["email"],
        "password": d["app_password"],
        "sender_name": "Abdul Hafis Mohammed",
        "sender_title": "CEO & Software Engineer, TOVO LABs",
    }


SIGNOFF_TEXT = """Abdul Hafis Mohammed
CEO & Software Engineer, TOVO LABs
GrowWithMe — offline care for mothers & under-fives, Northern Ghana
059 988 0977 | abdulhafis2847@gmail.com"""

SIGNOFF_HTML = """<div style="margin-top:28px;color:#0b1526;font-family:Arial,Helvetica,sans-serif;">
  <img src="cid:tovolabslogo" width="132" alt="TOVO LABs" style="display:block;margin-bottom:10px;border-radius:8px;">
  <div style="font-size:14px;line-height:1.55;">
    <b style="font-size:15px;">Abdul Hafis Mohammed</b><br>
    CEO &amp; Software Engineer, <b>TOVO LABs</b><br>
    <span style="color:#41526b;">GrowWithMe — offline care for mothers &amp; under-fives, Northern Ghana</span><br>
    059 988 0977 &nbsp;|&nbsp; <a href="mailto:abdulhafis2847@gmail.com" style="color:#1a5fb4;">abdulhafis2847@gmail.com</a>
  </div>
</div>"""


def build_email(to, subject, body_html, body_text, attachments=(), cc=()):
    creds = load_creds()
    msg = EmailMessage()
    msg["From"] = f'{creds["sender_name"]} (TOVO LABs) <{creds["email"]}>'
    msg["To"] = to if isinstance(to, str) else ", ".join(to)
    if cc:
        msg["Cc"] = cc if isinstance(cc, str) else ", ".join(cc)
    msg["Subject"] = subject
    msg["Date"] = formatdate(localtime=True)
    msg.set_content(body_text)
    msg.add_alternative(body_html, subtype="html")
    if LOGO_PATH.exists():
        with open(LOGO_PATH, "rb") as f:
            msg.get_payload()[1].add_attachment(
                f.read(), maintype="image", subtype="png", filename="tovo-labs-logo.png", cid="tovolabslogo"
            )
    for path in attachments:
        p = Path(path)
        with open(p, "rb") as f:
            msg.add_attachment(f.read(), maintype="application", subtype="octet-stream", filename=p.name)
    return msg, creds


def send(msg, creds):
    ctx = ssl.create_default_context()
    with smtplib.SMTP(creds["host"], creds["port"], timeout=120) as s:
        s.ehlo()
        s.starttls(context=ctx)
        s.ehlo()
        s.login(creds["email"], creds["password"])
        refused = s.send_message(msg)
        return refused


if __name__ == "__main__":
    creds = load_creds()
    m, c = build_email(
        "abdulhafis2847@gmail.com",
        "SMTP self-test — TOVO LABs outreach pipeline",
        "<p>Pipeline test from the TOVO LABs outreach sender. If you can read this and see the logo, SMTP is working.</p>" + SIGNOFF_HTML,
        "Pipeline test from the TOVO LABs outreach sender. If you can read this, SMTP is working.\n\n" + SIGNOFF_TEXT,
    )
    r = send(m, c)
    print("SELF-TEST OK, refused:", r)
