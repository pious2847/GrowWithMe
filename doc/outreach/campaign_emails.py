"""TOVO LABs — GrowWithMe outreach campaign (2026-10-25).
Sends personalized emails with the detailed demo video attached and the TOVO LABs
logo embedded in the signature. Credentials: %TEMP%/opencode/smtp_tovolabs.json.

Usage:
  python campaign_emails.py --only 1,2        # send specific ids
  python campaign_emails.py --list            # list all
  python campaign_emails.py --gap 150         # seconds between sends (default 150)
"""
import argparse
import csv
import sys
import time
from pathlib import Path

from smtp_lib import SIGNOFF_HTML, SIGNOFF_TEXT, build_email, send

VIDEO = None  # set at send time via --video

BOILER = (
    "TOVO LABs is a Ghanaian software engineering and product studio building "
    "digital solutions for modern organizations; GrowWithMe is our health platform "
    "for mothers and children under five in Northern Ghana."
)

FEATURES_HTML = """<ul style="margin:10px 0 14px 22px;padding:0;">
<li style="margin-bottom:6px;"><b>Offline IMCI-aligned triage</b> (child + pregnancy) — works with zero network</li>
<li><b>WHO growth monitoring</b> with automatic malnutrition flags</li>
<li><b>Care calendar synced to Ghana's EPI schedule</b> — immunizations, ANC/PNC, Vitamin A — with spoken reminders for low-literacy users</li>
<li><b>"Nana", a voice-first AI educator</b> with an offline fallback for no-connectivity homes</li>
<li><b>Urgent alert flow:</b> one tap SMSes the mother's risk report to the nearest CHPS compound, registered volunteer responders and the referral hospital — every referral tracked to closure</li>
<li><b>A facility dashboard</b> surfacing missed visits, growth faltering and lost-to-follow-up families</li>
</ul>"""

FEATURES_TEXT = """- Offline IMCI-aligned triage (child + pregnancy) — works with zero network
- WHO growth monitoring with automatic malnutrition flags
- Care calendar synced to Ghana's EPI schedule (immunizations, ANC/PNC, Vitamin A) with spoken reminders
- "Nana", a voice-first AI educator with an offline fallback for low-connectivity homes
- Urgent alert flow: one tap SMSes the mother's risk report to the nearest CHPS compound, registered
  volunteer responders and the referral hospital — every referral tracked to closure
- A facility dashboard surfacing missed visits, growth faltering and lost-to-follow-up families"""

VIDEO_NOTE_HTML = '<p style="margin:12px 0;">I have attached a <b>2¾-minute detailed demo video</b> — the whole product, offline, in one watch. A working Android APK is available today for technical reviewers.</p>'
VIDEO_NOTE_TEXT = "I have attached a 2¾-minute detailed demo video — the whole product, offline, in one watch. A working Android APK is available today for technical reviewers."

P = lambda s: f'<p style="margin:0 0 12px;">{s}</p>'

def email(id_, org, to, cc, subject, intro_html, intro_text, ask_html, ask_text, attach_video=True):
    return {
        "id": id_, "org": org, "to": to, "cc": cc or [], "subject": subject,
        "intro_html": intro_html, "intro_text": intro_text,
        "ask_html": ask_html, "ask_text": ask_text, "attach_video": attach_video,
    }

EMAILS = [
    email(1, "UNICEF Femtech Ventures", "corporate-partnerships@unicef.org", [],
        "GrowWithMe (by TOVO LABs, Ghana) — Femtech Ventures eligibility + application intent (4 Nov)",
        P("Dear UNICEF Venture Fund team,")
        + P("I'm Abdul Hafis Mohammed, CEO at TOVO LABs, a Ghanaian software studio. We intend to apply to the <b>Femtech Ventures call for the maternal continuum of care (Pillar 1)</b> before the 4 November 2026 deadline. GrowWithMe is a working prototype for mothers and children under five in Northern Ghana — exactly the frontline, low-bandwidth, local-language context the pillar describes:")
        + FEATURES_HTML
        + P("Two eligibility questions before we submit: <b>(1)</b> must the private-company registration in Ghana (a UNICEF programme country) be complete at submission, or by award? <b>(2)</b> does young-founder status change the application route? We are willing to open-source the funded component."),
        "Dear UNICEF Venture Fund team,\n\n"
        "I'm Abdul Hafis Mohammed, CEO at TOVO LABs, a Ghanaian software studio. We intend to apply to the Femtech Ventures call for the maternal continuum of care (Pillar 1) before the 4 November 2026 deadline. GrowWithMe is a working prototype for mothers and children under five in Northern Ghana — exactly the frontline, low-bandwidth, local-language context the pillar describes:\n\n"
        + FEATURES_TEXT + "\n\n"
        "Two eligibility questions before we submit: (1) must the private-company registration in Ghana (a UNICEF programme country) be complete at submission, or by award? (2) does young-founder status change the application route? We are willing to open-source the funded component.",
        P("Could you confirm this qualifies under Pillar 1, and answer the two questions above? We are happy to demo to your team by call."),
        "Could you confirm this qualifies under Pillar 1, and answer the two questions above? We are happy to demo to your team by call."),
    email(2, "Ghana Health Service — CIP", "innovation@ghs.gov.gh", [],
        "[TOVO LABs] Is the next CIP round open? MNCH app demo request — GrowWithMe",
        P("Dear CIP team,")
        + P("I'm Abdul Hafis Mohammed, CEO and Software Engineer at TOVO LABs. Our GrowWithMe platform is a working maternal-newborn health app built for your target regions — <b>Northern, Savannah and North-East</b>:")
        + FEATURES_HTML,
        "Dear CIP team,\n\n"
        "I'm Abdul Hafis Mohammed, CEO and Software Engineer at TOVO LABs. Our GrowWithMe platform is a working maternal-newborn health app built for your target regions — Northern, Savannah and North-East:\n\n"
        + FEATURES_TEXT,
        P("Is the next CIP round open, or may we demo to the desk in Accra? We would like GHS institutional backing for a <b>supervised district pilot with CHPS facilities</b> — the scale and district to be agreed with the desk."),
        "Is the next CIP round open, or may we demo to the desk in Accra? We would like GHS institutional backing for a supervised district pilot with CHPS facilities — the scale and district to be agreed with the desk."),
    email(3, "UNFPA Ghana", "ghana.info@unfpa.org", [],
        "[TOVO LABs] GrowWithMe — offline maternal health app for next cohort consideration",
        P("Dear UNFPA Ghana team,")
        + P("TOVO LABs is a Ghanaian software studio; <b>GrowWithMe</b>, our health app for mothers and under-fives, matches your <b>Innovation Strategy 2025–27</b> directly: it works with no data (offline-first), uses SMS for referral alerts and reminders, and continues care seamlessly from pregnancy to PNC to age five. A PDF patient report is generated at every urgent escalation and sent by SMS to the mother's hospital and the nearest responders — so the referral loop actually closes.")
        + FEATURES_HTML,
        "Dear UNFPA Ghana team,\n\n"
        "TOVO LABs is a Ghanaian software studio; GrowWithMe, our health app for mothers and under-fives, matches your Innovation Strategy 2025-27 directly: it works with no data (offline-first), uses SMS for referral alerts and reminders, and continues care seamlessly from pregnancy to PNC to age five. A PDF patient report is generated at every urgent escalation and sent by SMS to the mother's hospital and the nearest responders — so the referral loop actually closes.\n\n"
        + FEATURES_TEXT,
        P("We would like to be considered for your <b>next innovation sprint or cohort</b>, and for a seed pilot under the Partnership Framework's maternal-health innovation window."),
        "We would like to be considered for your next innovation sprint or cohort, and for a seed pilot under the Partnership Framework's maternal-health innovation window."),
    email(4, "UNDP Ghana Accelerator Lab", "allen.anie@undp.org", ["seth.akumani@undp.org", "fatima.farouta@undp.org"],
        "[TOVO LABs x UNDP AccLab] A running grassroots solution for Northern Ghana — 20-min call?",
        P("Dear Allen, Seth and Fatima,")
        + P("The Accelerator Lab maps grassroots solutions; <b>GrowWithMe is one already running</b>: an offline-first app for mothers and under-fives in Northern Ghana with IMCI triage, a spoken AI educator (&ldquo;Nana&rdquo;), and SMS referral alerts that reach the nearest CHPS compound and volunteer responders — tracked to closure.")
        + P("We want to test it properly, and we believe the Lab's toolkit — mapping, experimentation, portfolio — can shape the pilot design, not just endorse the tech."),
        "Dear Allen, Seth and Fatima,\n\n"
        "The Accelerator Lab maps grassroots solutions; GrowWithMe is one already running: an offline-first app for mothers and under-fives in Northern Ghana with IMCI triage, a spoken AI educator (\"Nana\"), and SMS referral alerts that reach the nearest CHPS compound and volunteer responders — tracked to closure.\n\n"
        "We want to test it properly, and we believe the Lab's toolkit — mapping, experimentation, portfolio — can shape the pilot design, not just endorse the tech.",
        P("Would a <b>20-minute call this week or next</b> be possible? We are specifically interested in which district to start in, to align with the Lab's current work."),
        "Would a 20-minute call this week or next be possible? We are specifically interested in which district to start in, to align with the Lab's current work."),
    email(5, "RAINS (Tamale)", "info@rainsgha.org", [],
        "Joint pilot proposal — GrowWithMe offline app × RAINS community networks",
        P("Dear RAINS team,")
        + P("I'm Abdul Hafis Mohammed from TOVO LABs, a Ghanaian software studio. Our app <b>GrowWithMe</b> serves exactly the mothers and under-fives your programs reach: offline triage aligned to IMCI, spoken daily guidance in plain language for low-literacy families, care reminders synced to the EPI schedule, and urgent SMS alerts that route to the nearest CHPS compound and volunteers — with every referral tracked to closure.")
        + P("<b>Rather than asking for money, we are proposing implementation collaboration:</b> RAINS' 30 years of community trust + our digital reach = a compelling joint proposal to funders (CIP Ghana, Gates Grand Challenges, Mastercard-backed accelerators)."),
        "Dear RAINS team,\n\n"
        "I'm Abdul Hafis Mohammed from TOVO LABs, a Ghanaian software studio. Our app GrowWithMe serves exactly the mothers and under-fives your programs reach: offline triage aligned to IMCI, spoken daily guidance in plain language for low-literacy families, care reminders synced to the EPI schedule, and urgent SMS alerts that route to the nearest CHPS compound and volunteers — with every referral tracked to closure.\n\n"
        "Rather than asking for money, we are proposing implementation collaboration: RAINS' 30 years of community trust + our digital reach = a compelling joint proposal to funders (CIP Ghana, Gates Grand Challenges, Mastercard-backed accelerators).",
        P("We could start with a <b>small supervised pilot</b> — a handful of volunteers in one community, supervised by your team. Would a 20-minute call, or a visit to Tamale, work?"),
        "We could start with a small supervised pilot — a handful of volunteers in one community, supervised by your team. Would a 20-minute call, or a visit to Tamale, work?"),
    email(6, "Moving Health Foundation", "info@moving.health", [],
        "Collaboration — your tricycle ambulances + our SMS alert dispatch (Northern Ghana)",
        P("Dear Moving Health team,")
        + P("TOVO LABs built <b>GrowWithMe</b>, an offline-first maternal-child care app for Northern Ghana. One piece of yours — emergency tricycle-ambulance transport — is the ground leg of a loop we have already automated: our app turns a mother's danger sign into a <b>PDF patient report SMSed to the nearest responders and the receiving facility in one tap</b>. Your transport could be the moving link in that loop."),
        "Dear Moving Health team,\n\n"
        "TOVO LABs built GrowWithMe, an offline-first maternal-child care app for Northern Ghana. One piece of yours — emergency tricycle-ambulance transport — is the ground leg of a loop we have already automated: our app turns a mother's danger sign into a PDF patient report SMSed to the nearest responders and the receiving facility in one tap. Your transport could be the moving link in that loop.",
        P("Specifically: <b>(1)</b> our urgent alerts can dispatch your tricycles with the full report included; <b>(2)</b> together we are a stronger joint proposal to CIP Ghana, Gates Grand Challenges and UNFPA. Would a 20-minute call work this week?"),
        "Specifically: (1) our urgent alerts can dispatch your tricycles with the full report included; (2) together we are a stronger joint proposal to CIP Ghana, Gates Grand Challenges and UNFPA. Would a 20-minute call work this week?"),
    email(7, "Grand Challenges (Gates Foundation)", "grandchallenges@gatesfoundation.org", [],
        "Add us to MNCH / digital-health RFP notifications — GrowWithMe (Ghana)",
        P("Dear Grand Challenges team,")
        + P("I'm Abdul Hafis Mohammed, CEO of TOVO LABs, a Ghanaian software studio. Our health platform <b>GrowWithMe</b> — offline IMCI-aligned triage, EPI-synchronized care reminders, a voice-first AI educator and SMS referral alerts that close the loop to facilities — is live and working for mothers and under-fives in Northern Ghana.")
        + P("Most of your relevant calls are deadline-driven, so our immediate ask is simple:"),
        "Dear Grand Challenges team,\n\n"
        "I'm Abdul Hafis Mohammed, CEO of TOVO LABs, a Ghanaian software studio. Our health platform GrowWithMe — offline IMCI-aligned triage, EPI-synchronized care reminders, a voice-first AI educator and SMS referral alerts that close the loop to facilities — is live and working for mothers and under-fives in Northern Ghana.\n\n"
        "Most of your relevant calls are deadline-driven, so our immediate ask is simple:",
        P("Please add us to notifications for upcoming <b>Grand Challenges RFPs in maternal-newborn health and digital health</b> (e.g. antenatal risk stratification in SSA), and tell us if any current or upcoming call fits a Ghana-based proposal — we will flag country-fit explicitly."),
        "Please add us to notifications for upcoming Grand Challenges RFPs in maternal-newborn health and digital health (e.g. antenatal risk stratification in SSA), and tell us if any current or upcoming call fits a Ghana-based proposal — we will flag country-fit explicitly."),
    email(8, "MSD for Mothers", "CSTMFORMOTHERS@msdformothers.com", [],
        "GrowWithMe — community-built maternal health platform (Ghana) — grant route inquiry",
        P("Dear MSD for Mothers team,")
        + P("I'm Abdul Hafis Mohammed, CEO of TOVO LABs — a Ghanaian software studio. <b>GrowWithMe</b> is our community-built maternal and child health platform: built in Ghana, for the communities it serves — offline triage aligned to IMCI, WHO growth monitoring, EPI-synced care reminders, and SMS referral alerts that reach the nearest CHPS compound, volunteers and the referral hospital, tracked to closure.")
        + FEATURES_HTML,
        "Dear MSD for Mothers team,\n\n"
        "I'm Abdul Hafis Mohammed, CEO of TOVO LABs — a Ghanaian software studio. GrowWithMe is our community-built maternal and child health platform: built in Ghana, for the communities it serves — offline triage aligned to IMCI, WHO growth monitoring, EPI-synced care reminders, and SMS referral alerts that reach the nearest CHPS compound, volunteers and the referral hospital, tracked to closure.\n\n"
        + FEATURES_TEXT,
        P("Which route fits us best: a <b>Global Grant pitch via the local MSD office</b>, or a <b>Kenneth C. Frazier Award</b> self-nomination? Guidance on either would be appreciated."),
        "Which route fits us best: a Global Grant pitch via the local MSD office, or a Kenneth C. Frazier Award self-nomination? Guidance on either would be appreciated."),
    email(9, "H2i / Mastercard AHC", "h2i.international@utoronto.ca", [],
        "GrowWithMe (Ghana) — joining the HENT community and Health Innovation Festival",
        P("Dear H2i team,")
        + P("I'm Abdul Hafis Mohammed, CEO of TOVO LABs, a Ghanaian software studio. Our maternal-child health platform <b>GrowWithMe</b> — offline triage, EPI-synced reminders, a voice-first AI educator and closed-loop SMS referrals — is live in Northern Ghana, and we are building the evidence base for a supervised district pilot with the Ghana Health Service.")
        + P("We would like to plug into the Africa Health Collaborative ecosystem through H2i."),
        "Dear H2i team,\n\n"
        "I'm Abdul Hafis Mohammed, CEO of TOVO LABs, a Ghanaian software studio. Our maternal-child health platform GrowWithMe — offline triage, EPI-synced reminders, a voice-first AI educator and closed-loop SMS referrals — is live in Northern Ghana, and we are building the evidence base for a supervised district pilot with the Ghana Health Service.\n\n"
        "We would like to plug into the Africa Health Collaborative ecosystem through H2i.",
        P("How does a Ghanaian venture <b>join the HENT community</b>, and what does a strong <b>Health Innovation Festival 2027</b> pitch look like? We would be glad to demo by call."),
        "How does a Ghanaian venture join the HENT community, and what does a strong Health Innovation Festival 2027 pitch look like? We would be glad to demo by call."),
    email(10, "Ministry of Health (Ghana)", "info@moh.gov.gh", [],
        "GrowWithMe MNCH platform — introduction and pathway to a supervised pilot",
        P("Dear Ministry of Health team,")
        + P("I'm Abdul Hafis Mohammed, CEO and Software Engineer at TOVO LABs, a Ghanaian software studio. I am introducing <b>GrowWithMe</b>, our maternal and child health platform for Northern Ghana — built around the national CHPS referral reality: offline IMCI-aligned triage, EPI-synchronized care reminders in spoken form for low-literacy mothers, and urgent SMS alerts with a PDF patient report that reach the nearest CHPS compound, volunteer responders and the referral hospital, tracked to closure.")
        + FEATURES_HTML,
        "Dear Ministry of Health team,\n\n"
        "I'm Abdul Hafis Mohammed, CEO and Software Engineer at TOVO LABs, a Ghanaian software studio. I am introducing GrowWithMe, our maternal and child health platform for Northern Ghana — built around the national CHPS referral reality: offline IMCI-aligned triage, EPI-synchronized care reminders in spoken form for low-literacy mothers, and urgent SMS alerts with a PDF patient report that reach the nearest CHPS compound, volunteer responders and the referral hospital, tracked to closure.\n\n"
        + FEATURES_TEXT,
        P("We would value your guidance on the <b>MoU / research-pilot pathway</b> for a supervised district pilot in the Northern Region, and we are happy to demo to the relevant unit in Accra."),
        "We would value your guidance on the MoU / research-pilot pathway for a supervised district pilot in the Northern Region, and we are happy to demo to the relevant unit in Accra."),
    email(11, "WHO Ghana Country Office", "afwcogh@who.int", [],
        "Technical review request — IMCI-aligned triage content (GrowWithMe, Ghana)",
        P("Dear WHO Ghana team,")
        + P("I'm Abdul Hafis Mohammed, CEO of TOVO LABs, a Ghanaian software studio. Our maternal-child health platform <b>GrowWithMe</b> implements an offline triage flow aligned to <b>IMCI danger-sign logic</b> and a care calendar synced to Ghana's EPI schedule, for mothers and under-fives in Northern Ghana. The deterministic clinical rules engine — never the AI — owns every risk verdict, which keeps the classification auditable."),
        "Dear WHO Ghana team,\n\n"
        "I'm Abdul Hafis Mohammed, CEO of TOVO LABs, a Ghanaian software studio. Our maternal-child health platform GrowWithMe implements an offline triage flow aligned to IMCI danger-sign logic and a care calendar synced to Ghana's EPI schedule, for mothers and under-fives in Northern Ghana. The deterministic clinical rules engine — never the AI — owns every risk verdict, which keeps the classification auditable.",
        P("May we request a <b>technical review of our triage and care content</b> for alignment with IMCI and EPI guidance? We would welcome your feedback before the supervised district pilot, and a conversation about endorsement after review."),
        "May we request a technical review of our triage and care content for alignment with IMCI and EPI guidance? We would welcome your feedback before the supervised district pilot, and a conversation about endorsement after review."),
    email(12, "University for Development Studies (Tamale)", "registrar@uds.edu.gh", [],
        "Joint research / evaluation partnership — GrowWithMe MNCH app (for routing to CRIPS)",
        P("Dear Registrar's office,")
        + P("I'm Abdul Hafis Mohammed, CEO of TOVO LABs, a Ghanaian software studio. Our maternal-child health platform <b>GrowWithMe</b> — offline IMCI-aligned triage, WHO growth monitoring, EPI-synced reminders and closed-loop SMS referrals — is running and ready for a supervised district pilot in the Northern Region. We are writing to propose a <b>joint research and evaluation partnership</b> with UDS, routed via CRIPS.")
        + P("The fit is direct: we need rigorous implementation evidence for funders (GHS CIP, Gates Grand Challenges, UNFPA); your School of Public Health needs real-world MNCH data and a live platform to study. A joint evaluation design would strengthen both sides' next grant applications."),
        "Dear Registrar's office,\n\n"
        "I'm Abdul Hafis Mohammed, CEO of TOVO LABs, a Ghanaian software studio. Our maternal-child health platform GrowWithMe — offline IMCI-aligned triage, WHO growth monitoring, EPI-synced reminders and closed-loop SMS referrals — is running and ready for a supervised district pilot in the Northern Region. We are writing to propose a joint research and evaluation partnership with UDS, routed via CRIPS.\n\n"
        "The fit is direct: we need rigorous implementation evidence for funders (GHS CIP, Gates Grand Challenges, UNFPA); your School of Public Health needs real-world MNCH data and a live platform to study. A joint evaluation design would strengthen both sides' next grant applications.",
        P("Could you route this to CRIPS / the School of Public Health, or connect us with the right focal person? We are happy to visit Tamale to present the working product."),
        "Could you route this to CRIPS / the School of Public Health, or connect us with the right focal person? We are happy to visit Tamale to present the working product."),
    email(13, "AfriKids Ghana", "infogh@afrikids.org", [],
        "Program cooperation — GrowWithMe offline MNCH app × AfriKids community programs (Upper East)",
        P("Dear AfriKids Ghana team,")
        + P("I'm Abdul Hafis Mohammed, CEO of TOVO LABs, a Ghanaian software studio. Our maternal-child health platform <b>GrowWithMe</b> — offline IMCI triage, spoken guidance for low-literacy families, EPI-synced reminders, and urgent SMS alerts routed to the nearest CHPS compound and volunteers — is live and built for exactly the northern Ghana communities your child-welfare programs serve.")
        + P("<b>To be explicit: this is not a funding request.</b> We are inviting a program-cooperation conversation — your 25 years of community insight would make our pilot design far better, and our digital tools could complement your health and child-protection programming in the Upper East."),
        "Dear AfriKids Ghana team,\n\n"
        "I'm Abdul Hafis Mohammed, CEO of TOVO LABs, a Ghanaian software studio. Our maternal-child health platform GrowWithMe — offline IMCI triage, spoken guidance for low-literacy families, EPI-synced reminders, and urgent SMS alerts routed to the nearest CHPS compound and volunteers — is live and built for exactly the northern Ghana communities your child-welfare programs serve.\n\n"
        "To be explicit: this is not a funding request. We are inviting a program-cooperation conversation — your 25 years of community insight would make our pilot design far better, and our digital tools could complement your health and child-protection programming in the Upper East.",
        P("Would a 30-minute conversation — in Bolgatanga or by call — be possible in the coming weeks?"),
        "Would a 30-minute conversation — in Bolgatanga or by call — be possible in the coming weeks?"),
    email(14, "STAR-Ghana Foundation", "info@star-ghana.org", [],
        "Concept-note collaboration — a CSO-centred rollout for GrowWithMe (Northern Ghana)",
        P("Dear STAR-Ghana team,")
        + P("I'm Abdul Hafis Mohammed, CEO of TOVO LABs, a Ghanaian software studio. Our maternal-child health platform <b>GrowWithMe</b> — offline triage, EPI-synced reminders, closed-loop SMS referrals and a facility dashboard — is ready for a supervised district pilot in Northern Ghana, and a civil-society-centred rollout is exactly the model we believe fits the regions best."),
        "Dear STAR-Ghana team,\n\n"
        "I'm Abdul Hafis Mohammed, CEO of TOVO LABs, a Ghanaian software studio. Our maternal-child health platform GrowWithMe — offline triage, EPI-synced reminders, closed-loop SMS referrals and a facility dashboard — is ready for a supervised district pilot in Northern Ghana, and a civil-society-centred rollout is exactly the model we believe fits the regions best.",
        P("When your next relevant call opens, we would like to <b>co-design a concept note with a CSO coalition</b>. Could you add us to your call notifications, or tell us who at STAR-Ghana we should speak with about MNCH / digital-health programming?"),
        "When your next relevant call opens, we would like to co-design a concept note with a CSO coalition. Could you add us to your call notifications, or tell us who at STAR-Ghana we should speak with about MNCH / digital-health programming?"),
    email(15, "MTN Ghana Foundation", "mtnghanafoundation@mtn.com", [],
        "Sponsorship inquiry — SMS cost coverage, devices and data for an MNCH pilot (GrowWithMe)",
        P("Dear MTN Ghana Foundation team,")
        + P("I'm Abdul Hafis Mohammed, CEO of TOVO LABs, a Ghanaian software studio. Our maternal-child health platform <b>GrowWithMe</b> runs a life-critical flow that MTN already powers better than anyone in the North: <b>SMS</b>. When a mother's child shows danger signs, one tap SMSes a PDF patient report to the nearest CHPS compound, volunteer responders and her referral hospital — offline, on any phone.")
        + FEATURES_HTML,
        "Dear MTN Ghana Foundation team,\n\n"
        "I'm Abdul Hafis Mohammed, CEO of TOVO LABs, a Ghanaian software studio. Our maternal-child health platform GrowWithMe runs a life-critical flow that MTN already powers better than anyone in the North: SMS. When a mother's child shows danger signs, one tap SMSes a PDF patient report to the nearest CHPS compound, volunteer responders and her referral hospital — offline, on any phone.\n\n"
        + FEATURES_TEXT,
        P("For the supervised district pilot we are requesting sponsorship consideration for: <b>(1) SMS gateway cost coverage</b> for referral alerts and reminders, <b>(2) devices for community health workers</b>, <b>(3) data bundles</b> — and, if possible, <b>zero-rating of the app's traffic</b>. Happy to complete the formal sponsorship form and demo in Accra."),
        "For the supervised district pilot we are requesting sponsorship consideration for: (1) SMS gateway cost coverage for referral alerts and reminders, (2) devices for community health workers, (3) data bundles — and, if possible, zero-rating of the app's traffic. Happy to complete the formal sponsorship form and demo in Accra."),
    email(16, "UNICEF Startup Lab (Ghana)", "info@unicefstartuplab.org", [],
        "Introducing GrowWithMe ahead of the next cohort — TOVO LABs (Ghana)",
        P("Dear UNICEF Startup Lab team,")
        + P("I'm Abdul Hafis Mohammed, CEO of TOVO LABs, a Ghanaian software studio. Ahead of your next cohort (we understand cohort 6 launched this April), I want to introduce <b>GrowWithMe</b> — our offline-first maternal-child health platform for Northern Ghana: IMCI-aligned triage with zero connectivity, WHO growth monitoring, EPI-synced care reminders, a voice-first AI educator with an offline fallback, and SMS referral alerts tracked to closure.")
        + FEATURES_HTML,
        "Dear UNICEF Startup Lab team,\n\n"
        "I'm Abdul Hafis Mohammed, CEO of TOVO LABs, a Ghanaian software studio. Ahead of your next cohort (we understand cohort 6 launched this April), I want to introduce GrowWithMe — our offline-first maternal-child health platform for Northern Ghana: IMCI-aligned triage with zero connectivity, WHO growth monitoring, EPI-synced care reminders, a voice-first AI educator with an offline fallback, and SMS referral alerts tracked to closure.\n\n"
        + FEATURES_TEXT,
        P("What would strengthen an application when the next call opens — and is there an opportunity to engage the Lab's mentors before then?"),
        "What would strengthen an application when the next call opens — and is there an opportunity to engage the Lab's mentors before then?"),
]


def compose_html(e):
    return (
        '<div style="font-family:Arial,Helvetica,sans-serif;font-size:15px;line-height:1.6;color:#1c2733;max-width:640px;">'
        + e["intro_html"]
        + VIDEO_NOTE_HTML
        + e["ask_html"]
        + P("<i>" + BOILER + "</i>")
        + SIGNOFF_HTML
        + "</div>"
    )


def compose_text(e):
    return (
        e["intro_text"]
        + "\n\n" + VIDEO_NOTE_TEXT
        + "\n\n" + e["ask_text"]
        + "\n\n" + BOILER
        + "\n\n" + SIGNOFF_TEXT
    )


def run(ids, gap, video):
    log_path = Path(__file__).parent / "send_log.csv"
    new = not log_path.exists()
    log = open(log_path, "a", newline="", encoding="utf-8")
    w = csv.writer(log)
    if new:
        w.writerow(["timestamp", "id", "org", "to", "status", "detail"])
    for i, e in enumerate(EMAILS):
        if ids and e["id"] not in ids:
            continue
        atts = [video] if (video and e["attach_video"]) else []
        try:
            msg, creds = build_email(e["to"], e["subject"], compose_html(e), compose_text(e), attachments=atts, cc=e["cc"])
            refused = send(msg, creds)
            status = "sent" if not refused else f"partial_refused:{refused}"
            detail = ""
        except Exception as ex:
            status = "failed"
            detail = repr(ex)[:300]
        import datetime
        w.writerow([datetime.datetime.now().isoformat(timespec="seconds"), e["id"], e["org"], e["to"], status, detail])
        log.flush()
        print(f"[{e['id']:>2}] {e['org']}: {status} {detail}")
        if i < len(EMAILS) - 1 and gap > 0:
            time.sleep(gap)
    log.close()


if __name__ == "__main__":
    ap = argparse.ArgumentParser()
    ap.add_argument("--only", default="")
    ap.add_argument("--gap", type=int, default=150)
    ap.add_argument("--video", default="")
    ap.add_argument("--list", action="store_true")
    a = ap.parse_args()
    if a.list:
        for e in EMAILS:
            print(f'{e["id"]:>2}  {e["org"]:<40} {e["to"]} cc={e["cc"]}')
        sys.exit(0)
    ids = {int(x) for x in a.only.split(",") if x.strip()} if a.only else None
    run(ids, a.gap, a.video or None)
