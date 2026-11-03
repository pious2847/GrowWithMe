"""Sends the two global partner-collaboration emails (Medic + Dimagi) via the TOVO LABs SMTP.
Collaboration framing, no money ask. Logs to send_log.csv."""
import csv
import datetime
from pathlib import Path

from smtp_lib import SIGNOFF_HTML, SIGNOFF_TEXT, build_email, send

VIDEO = Path.home() / "OneDrive/Desktop/DEV/Flutter/GrowWithMe/demo-video/growwithme-outreach/renders/GrowWithMe-Demo-TOVO-LABs.mp4"

P = lambda s: f'<p style="margin:0 0 12px;">{s}</p>'

BOILER = ("TOVO LABs is a Ghanaian software engineering and product studio building digital solutions "
          "for modern organizations; GrowWithMe is our health platform for mothers and children under "
          "five in Northern Ghana.")

EMAILS = [
    {
        "org": "Medic (Community Health Toolkit)",
        "to": "hello@medic.org",
        "subject": "Knowledge exchange — GrowWithMe offline maternal-child AI (Ghana) × Community Health Toolkit",
        "html": P("Dear Medic team,")
        + P("I'm Abdul Hafis Mohammed, founder of TOVO LABs, a Ghanaian software studio. We've built "
            "<b>GrowWithMe</b>, an offline-first care companion for mothers and under-fives in Northern Ghana: "
            "IMCI-aligned triage with a deterministic clinical rules engine, WHO growth monitoring, an EPI-synced "
            "care calendar with spoken reminders, a voice-first AI educator with a compact on-device model, and "
            "urgent SMS alerts that route a PDF patient report to the nearest CHPS compound, volunteer responders "
            "and the hospital — every referral tracked to closure.")
        + P("We know and respect the Community Health Toolkit's role in this space. Rather than asking for "
            "anything, we're reaching out as builders who would value a knowledge exchange: how CHT approaches "
            "offline-first CHW workflows and government integrations, and where an independent, AI-assisted "
            "companion layer like ours — voice-first, on-device, with bounded deterministic risk classification — "
            "could complement platforms like yours rather than reinvent them. We're also happy to share what we've "
            "learned about on-device model compression for very low-end Androids.")
        + P("We're preparing a supervised district pilot with Ghana Health Service conversations underway. "
            "A 30-minute call with whoever owns community/partnership conversations would mean a lot."),
        "text": ("Dear Medic team,\n\nI'm Abdul Hafis Mohammed, founder of TOVO LABs, a Ghanaian software studio. We've built "
                 "GrowWithMe, an offline-first care companion for mothers and under-fives in Northern Ghana: IMCI-aligned triage "
                 "with a deterministic clinical rules engine, WHO growth monitoring, an EPI-synced care calendar with spoken "
                 "reminders, a voice-first AI educator with a compact on-device model, and urgent SMS alerts that route a PDF "
                 "patient report to the nearest CHPS compound, volunteer responders and the hospital — every referral tracked "
                 "to closure.\n\nWe know and respect the Community Health Toolkit's role in this space. Rather than asking for "
                 "anything, we're reaching out as builders who would value a knowledge exchange: how CHT approaches offline-first "
                 "CHW workflows and government integrations, and where an independent, AI-assisted companion layer like ours — "
                 "voice-first, on-device, with bounded deterministic risk classification — could complement platforms like yours "
                 "rather than reinvent them. We're also happy to share what we've learned about on-device model compression for "
                 "very low-end Androids.\n\nWe're preparing a supervised district pilot with Ghana Health Service conversations "
                 "underway. A 30-minute call with whoever owns community/partnership conversations would mean a lot."),
    },
    {
        "org": "Dimagi (CommCare)",
        "to": "info@dimagi.com",
        "subject": "Knowledge exchange — GrowWithMe offline maternal-child AI (Ghana) × CommCare",
        "html": P("Dear Dimagi team,")
        + P("I'm Abdul Hafis Mohammed, founder of TOVO LABs, a Ghanaian software studio. We've built <b>GrowWithMe</b>, "
            "an offline-first care companion for mothers and under-fives in Northern Ghana: IMCI-aligned triage with a "
            "deterministic clinical rules engine, WHO growth monitoring with malnutrition flags, an EPI-synced care calendar "
            "with spoken reminders for low-literacy mothers, a voice-first AI educator with a compact on-device model, and "
            "urgent SMS alerts that send a PDF patient report to the nearest CHPS compound, volunteer responders and the "
            "hospital — every referral tracked to closure on a facility dashboard.")
        + P("CommCare's depth in CHW workflows at national scale is something we admire. We're writing to propose a "
            "knowledge exchange, not an ask: we'd love to learn how Dimagi approaches offline data sync at scale, government "
            "deployments and open standards — and we can share our side of the ledger, particularly on-device AI for very "
            "low-end Androids (our Nana understanding model runs in about a megabyte, fully offline) and bounded "
            "deterministic safety design for AI in clinical-adjacent contexts.")
        + P("We're preparing a supervised district pilot with Ghana Health Service conversations underway. Would a "
            "30-minute call with your partnerships or open-community team be possible in the coming weeks?"),
        "text": ("Dear Dimagi team,\n\nI'm Abdul Hafis Mohammed, founder of TOVO LABs, a Ghanaian software studio. We've built "
                 "GrowWithMe, an offline-first care companion for mothers and under-fives in Northern Ghana: IMCI-aligned triage "
                 "with a deterministic clinical rules engine, WHO growth monitoring with malnutrition flags, an EPI-synced care "
                 "calendar with spoken reminders for low-literacy mothers, a voice-first AI educator with a compact on-device "
                 "model, and urgent SMS alerts that send a PDF patient report to the nearest CHPS compound, volunteer responders "
                 "and the hospital — every referral tracked to closure on a facility dashboard.\n\nCommCare's depth in CHW "
                 "workflows at national scale is something we admire. We're writing to propose a knowledge exchange, not an ask: "
                 "we'd love to learn how Dimagi approaches offline data sync at scale, government deployments and open standards "
                 "— and we can share our side of the ledger, particularly on-device AI for very low-end Androids (our Nana "
                 "understanding model runs in about a megabyte, fully offline) and bounded deterministic safety design for AI in "
                 "clinical-adjacent contexts.\n\nWe're preparing a supervised district pilot with Ghana Health Service "
                 "conversations underway. Would a 30-minute call with your partnerships or open-community team be possible in "
                 "the coming weeks?"),
    },
]

log = open(Path(__file__).parent / "send_log.csv", "a", newline="", encoding="utf-8")
w = csv.writer(log)
for e in EMAILS:
    html = e["html"] + P("<i>" + BOILER + "</i>") + SIGNOFF_HTML
    text = e["text"] + "\n\n" + BOILER + "\n\n" + SIGNOFF_TEXT
    try:
        msg, creds = build_email(e["to"], e["subject"], html, text, attachments=[VIDEO])
        refused = send(msg, creds)
        status = "sent" if not refused else f"partial_refused:{refused}"
        detail = ""
    except Exception as ex:
        status = "failed"
        detail = repr(ex)[:300]
    w.writerow([datetime.datetime.now().isoformat(timespec="seconds"), f"GLOBAL-{e['org'][:12]}", e["org"], e["to"], status, detail])
    log.flush()
    print(e["org"], "->", status, detail)
log.close()
