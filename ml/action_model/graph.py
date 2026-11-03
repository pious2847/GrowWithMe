"""Grounded screen/action graph for the GrowWithMe caregiver app.

Everything here mirrors shipped Flutter routes and widget ids so a model
trained on the generated corpus speaks the same vocabulary as the app's
ActionLogger (`screen`, `action`, `target`). Keep this file in sync when a
screen or primary control changes; `generate_dataset.py` writes it out as
schema/app_graph.json for inspection and for the runtime action policy.
"""

from __future__ import annotations

APP_VERSION = "1.0.0"
GRAPH_VERSION = "2026.11.1"


def el(
    eid: str,
    label: str,
    *,
    kind: str = "button",
    box: tuple[float, float, float, float],
    to: str | None = None,
    action: str = "tap",
    requires_scroll: bool = False,
):
    """One interactive element, with normalized (x, y, w, h) bounds."""
    return {
        "id": eid,
        "label": label,
        "kind": kind,
        "box": list(box),
        "to": to,
        "action": action,
        "requiresScroll": requires_scroll,
    }


# ---------------------------------------------------------------------------
# Screens. Coordinates are normalized centers used only to synthesize touches;
# a trained policy consumes the element id/label, coordinates are auxiliary.
# ---------------------------------------------------------------------------

SCREENS: dict[str, dict] = {
    "onboarding.welcome": {
        "title": "Welcome",
        "tab": None,
        "elements": [
            el("welcome.country_chip", "Choose country", box=(0.30, 0.09, 0.44, 0.055),
               to="onboarding.country_sheet"),
            el("welcome.next", "Continue", box=(0.50, 0.86, 0.84, 0.065), to="onboarding.phone"),
            el("welcome.listen", "Listen to this page", kind="icon", box=(0.85, 0.90, 0.12, 0.05)),
        ],
    },
    "onboarding.country_sheet": {
        "title": "Country & language",
        "tab": None,
        "elements": [
            el("country.ghana", "Ghana", box=(0.50, 0.30, 0.86, 0.06)),
            el("country.nigeria", "Nigeria", box=(0.50, 0.38, 0.86, 0.06)),
            el("country.kenya", "Kenya", box=(0.50, 0.46, 0.86, 0.06)),
            el("country.uganda", "Uganda", box=(0.50, 0.54, 0.86, 0.06)),
            el("country.tanzania", "Tanzania", box=(0.50, 0.62, 0.86, 0.06)),
            el("country.language_en", "English", kind="chip", box=(0.24, 0.74, 0.28, 0.05)),
            el("country.language_tw", "Twi · soon", kind="chip", box=(0.52, 0.74, 0.28, 0.05)),
            el("country.language_sw", "Kiswahili", kind="chip", box=(0.80, 0.74, 0.28, 0.05)),
            el("country.save", "Save", box=(0.50, 0.90, 0.86, 0.06), to="onboarding.welcome"),
        ],
    },
    "onboarding.phone": {
        "title": "Your phone number",
        "tab": None,
        "elements": [
            el("phone.field", "Phone number", kind="field", box=(0.50, 0.30, 0.86, 0.065)),
            el("phone.continue", "Send my code", box=(0.50, 0.45, 0.86, 0.065), to="onboarding.otp"),
            el("phone.back", "Back", kind="icon", box=(0.07, 0.06, 0.08, 0.05)),
            el("phone.trust_card", "Private by design", kind="card", box=(0.50, 0.72, 0.86, 0.10)),
        ],
    },
    "onboarding.otp": {
        "title": "Enter code",
        "tab": None,
        "elements": [
            el("otp.field", "6-digit code", kind="field", box=(0.50, 0.30, 0.72, 0.09)),
            el("otp.verify", "Verify", box=(0.50, 0.50, 0.86, 0.065), to="onboarding.privacy"),
            el("otp.resend", "Resend code", kind="text", box=(0.50, 0.60, 0.44, 0.05)),
            el("otp.back", "Back", kind="icon", box=(0.07, 0.06, 0.08, 0.05)),
        ],
    },
    "onboarding.privacy": {
        "title": "Your data is protected",
        "tab": None,
        "elements": [
            el("privacy.listen", "Listen to this page", box=(0.50, 0.31, 0.62, 0.055)),
            el("privacy.next", "I understand — continue", box=(0.50, 0.91, 0.86, 0.065),
               to="onboarding.profile"),
        ],
    },
    "onboarding.profile": {
        "title": "Tell us about you",
        "tab": None,
        "elements": [
            el("profile.name", "Your name", kind="field", box=(0.50, 0.22, 0.86, 0.06)),
            el("profile.district", "District", kind="field", box=(0.50, 0.33, 0.86, 0.06)),
            el("profile.community", "Community", kind="field", box=(0.50, 0.44, 0.86, 0.06)),
            el("profile.language", "Language", kind="select", box=(0.50, 0.55, 0.86, 0.06),
               to="onboarding.profile.language_sheet"),
            el("profile.consent_data", "I agree to data use", kind="checkbox", box=(0.20, 0.68, 0.10, 0.04)),
            el("profile.consent_location", "Share location in emergencies", kind="checkbox",
               box=(0.20, 0.75, 0.10, 0.04)),
            el("profile.start", "Start caring", box=(0.50, 0.90, 0.86, 0.065), to="home"),
        ],
    },
    "onboarding.profile.language_sheet": {
        "title": "Language",
        "tab": None,
        "elements": [
            el("lang.en", "English", kind="chip", box=(0.30, 0.35, 0.28, 0.05),
               to="onboarding.profile"),
            el("lang.tw", "Twi", kind="chip", box=(0.62, 0.35, 0.28, 0.05),
               to="onboarding.profile"),
            el("lang.dag", "Dagbani", kind="chip", box=(0.30, 0.45, 0.28, 0.05),
               to="onboarding.profile"),
            el("lang.ha", "Hausa", kind="chip", box=(0.62, 0.45, 0.28, 0.05),
               to="onboarding.profile"),
        ],
    },
    "home": {
        "title": "GrowWithMe",
        "tab": "home",
        "elements": [
            el("home.nana.ask", "Ask Nana", kind="card", box=(0.50, 0.26, 0.86, 0.13),
               to="nana.chat"),
            el("home.nana.speak", "Hear today's briefing", kind="icon", box=(0.74, 0.31, 0.10, 0.05)),
            el("home.quick.health_check", "Health check", box=(0.26, 0.44, 0.44, 0.075),
               to="assessment.picker"),
            el("home.quick.ask_nana", "Ask Nana", box=(0.74, 0.44, 0.44, 0.075), to="nana.chat"),
            el("home.quick.calendar", "Care calendar", box=(0.26, 0.54, 0.44, 0.075),
               to="tab.calendar"),
            el("home.quick.family", "My family", box=(0.74, 0.54, 0.44, 0.075),
               to="children.add"),
            el("home.pregnancy.card", "Pregnancy care", kind="card", box=(0.50, 0.66, 0.86, 0.10),
               to="pregnancy.detail"),
            el("home.visit.next", "Next visit", kind="row", box=(0.50, 0.78, 0.86, 0.055),
               to="tab.calendar", requires_scroll=True),
            el("home.child.rail", "Child card", kind="card", box=(0.30, 0.86, 0.30, 0.09),
               to="children.detail", requires_scroll=True),
            el("home.meals.card", "Today's meals", kind="card", box=(0.50, 0.93, 0.86, 0.10),
               to="diet.plan", requires_scroll=True),
            el("home.settings", "Settings", kind="icon", box=(0.94, 0.06, 0.08, 0.05),
               to="settings"),
            el("home.sync", "Sync now", kind="icon", box=(0.86, 0.06, 0.08, 0.05)),
            el("home.companion", "Nana companion", kind="avatar", box=(0.87, 0.62, 0.16, 0.12),
               to="companion.sheet"),
            el("home.pregnancy.add", "Add pregnancy", kind="button", box=(0.50, 0.72, 0.40, 0.045),
               to="pregnancy.add"),
            el("home.nav.calendar", "Calendar tab", kind="nav", box=(0.38, 0.97, 0.16, 0.05),
               to="tab.calendar"),
            el("home.nav.tips", "Tips tab", kind="nav", box=(0.62, 0.97, 0.16, 0.05),
               to="tab.tips"),
            el("home.nav.alerts", "Alerts tab", kind="nav", box=(0.86, 0.97, 0.16, 0.05),
               to="tab.alerts"),
        ],
    },
    "companion.sheet": {
        "title": "Nana",
        "tab": None,
        "elements": [
            el("companion.chat", "Chat with Nana", kind="row", box=(0.50, 0.52, 0.86, 0.06),
               to="nana.chat"),
            el("companion.talk", "Talk to Nana", kind="row", box=(0.50, 0.61, 0.86, 0.06),
               to="nana.chat"),
            el("companion.hide", "Hide Nana", kind="row", box=(0.50, 0.70, 0.86, 0.06)),
            el("companion.settings", "Companion settings", kind="row", box=(0.50, 0.79, 0.86, 0.06),
               to="settings"),
        ],
    },
    "tab.calendar": {
        "title": "Care calendar",
        "tab": "calendar",
        "elements": [
            el("calendar.add", "Add reminder", kind="fab", box=(0.86, 0.80, 0.12, 0.06),
               to="calendar.add"),
            el("calendar.visit_anc", "ANC visit", kind="row", box=(0.50, 0.34, 0.86, 0.06),
               to="calendar.add"),
            el("calendar.visit_immunization", "Immunization", kind="row", box=(0.50, 0.43, 0.86, 0.06),
               to="calendar.add"),
            el("calendar.filter", "Filter", kind="icon", box=(0.92, 0.06, 0.08, 0.05)),
        ],
    },
    "calendar.add": {
        "title": "New reminder",
        "tab": None,
        "elements": [
            el("reminder.title", "Reminder title", kind="field", box=(0.50, 0.28, 0.86, 0.06)),
            el("reminder.date", "Date", kind="select", box=(0.50, 0.40, 0.86, 0.06)),
            el("reminder.time", "Time", kind="select", box=(0.50, 0.50, 0.86, 0.06)),
            el("reminder.save", "Save reminder", box=(0.50, 0.86, 0.86, 0.065), to="tab.calendar"),
            el("reminder.back", "Back", kind="icon", box=(0.07, 0.06, 0.08, 0.05)),
        ],
    },
    "tab.tips": {
        "title": "Food & tips",
        "tab": "tips",
        "elements": [
            el("tips.diet", "Today's meal plan", kind="card", box=(0.50, 0.30, 0.86, 0.12),
               to="diet.plan"),
            el("tips.tip_card", "Daily tip", kind="card", box=(0.50, 0.45, 0.86, 0.10)),
            el("tips.listen", "Listen", kind="icon", box=(0.82, 0.31, 0.12, 0.05)),
            el("tips.share", "Share this tip", kind="button", box=(0.50, 0.56, 0.62, 0.05),
               to="device.share"),
        ],
    },
    "tab.alerts": {
        "title": "Alerts",
        "tab": "alerts",
        "elements": [
            el("alerts.item_urgent", "Urgent: danger sign", kind="row", box=(0.50, 0.30, 0.86, 0.08),
               to="alerts.detail"),
            el("alerts.item_followup", "Follow-up check", kind="row", box=(0.50, 0.42, 0.86, 0.08),
               to="alerts.detail"),
            el("alerts.call_chw", "Call health worker", kind="button", box=(0.50, 0.56, 0.86, 0.06),
               to="device.dialer"),
        ],
    },
    "alerts.detail": {
        "title": "Alert",
        "tab": None,
        "elements": [
            el("alert.accept", "Request help now", box=(0.50, 0.66, 0.86, 0.065)),
            el("alert.call", "Call health worker", box=(0.50, 0.75, 0.86, 0.065),
               to="device.dialer"),
            el("alert.share_location", "Share my location", box=(0.50, 0.84, 0.86, 0.065),
               to="device.share"),
            el("alert.message_chw", "Message my health worker", kind="text",
               box=(0.50, 0.90, 0.60, 0.045), to="device.sms"),
            el("alert.close", "Close alert", kind="text", box=(0.50, 0.94, 0.40, 0.04)),
        ],
    },
    "assessment.picker": {
        "title": "Who needs a check?",
        "tab": None,
        "elements": [
            el("check.pick_mother", "Me", kind="row", box=(0.50, 0.34, 0.86, 0.07),
               to="assessment.questions"),
            el("check.pick_child", "My child", kind="row", box=(0.50, 0.44, 0.86, 0.07),
               to="assessment.questions"),
            el("check.pick_pregnancy", "My pregnancy", kind="row", box=(0.50, 0.54, 0.86, 0.07),
               to="assessment.questions"),
            el("check.cancel", "Cancel", kind="text", box=(0.50, 0.80, 0.36, 0.05), to="home"),
        ],
    },
    "assessment.questions": {
        "title": "Health check",
        "tab": None,
        "elements": [
            el("check.yes", "Yes", kind="chip", box=(0.30, 0.66, 0.34, 0.07)),
            el("check.no", "No", kind="chip", box=(0.70, 0.66, 0.34, 0.07)),
            el("check.next", "Next question", box=(0.50, 0.80, 0.86, 0.065), to="assessment.questions"),
            el("check.listen", "Read aloud", kind="icon", box=(0.86, 0.10, 0.10, 0.05)),
        ],
    },
    "assessment.measurements": {
        "title": "Vitals",
        "tab": None,
        "elements": [
            el("vitals.systolic", "Systolic", kind="field", box=(0.50, 0.30, 0.86, 0.06)),
            el("vitals.diastolic", "Diastolic", kind="field", box=(0.50, 0.40, 0.86, 0.06)),
            el("vitals.weight", "Weight", kind="field", box=(0.50, 0.50, 0.86, 0.06)),
            el("vitals.save", "Save and see result", box=(0.50, 0.86, 0.86, 0.065),
               to="assessment.result"),
        ],
    },
    "assessment.result": {
        "title": "Your result",
        "tab": None,
        "elements": [
            el("result.listen", "Listen to advice", kind="button", box=(0.50, 0.58, 0.62, 0.055)),
            el("result.call_facility", "Call clinic", box=(0.50, 0.68, 0.86, 0.065),
               to="device.dialer"),
            el("result.add_reminder", "Remind me to follow up", box=(0.50, 0.77, 0.86, 0.065),
               to="calendar.add"),
            el("result.done", "Done", kind="text", box=(0.50, 0.90, 0.36, 0.05), to="home"),
        ],
    },
    "children.add": {
        "title": "Add a child",
        "tab": None,
        "elements": [
            el("child.name", "Child's name", kind="field", box=(0.50, 0.24, 0.86, 0.06)),
            el("child.dob", "Date of birth", kind="select", box=(0.50, 0.35, 0.86, 0.06)),
            el("child.sex_female", "Girl", kind="chip", box=(0.34, 0.47, 0.30, 0.05)),
            el("child.sex_male", "Boy", kind="chip", box=(0.66, 0.47, 0.30, 0.05)),
            el("child.save", "Save child", box=(0.50, 0.86, 0.86, 0.065), to="home"),
            el("child.back", "Back", kind="icon", box=(0.07, 0.06, 0.08, 0.05)),
        ],
    },
    "children.detail": {
        "title": "Child",
        "tab": None,
        "elements": [
            el("child.detail.log_growth", "Log weight & height", box=(0.50, 0.46, 0.86, 0.065),
               to="growth.log"),
            el("child.detail.vaccines", "Vaccination schedule", kind="row", box=(0.50, 0.56, 0.86, 0.06),
               to="tab.calendar"),
            el("child.detail.growth_chart", "Growth chart", kind="card", box=(0.50, 0.68, 0.86, 0.12)),
            el("child.detail.back", "Back", kind="icon", box=(0.07, 0.06, 0.08, 0.05), to="home"),
        ],
    },
    "growth.log": {
        "title": "Growth",
        "tab": None,
        "elements": [
            el("growth.weight", "Weight in kg", kind="field", box=(0.50, 0.30, 0.86, 0.06)),
            el("growth.height", "Height in cm", kind="field", box=(0.50, 0.41, 0.86, 0.06)),
            el("growth.save", "Save", box=(0.50, 0.86, 0.86, 0.065), to="children.detail"),
        ],
    },
    "pregnancy.add": {
        "title": "Add pregnancy",
        "tab": None,
        "elements": [
            el("pregnancy.lmp", "First day of last period", kind="select",
               box=(0.50, 0.32, 0.86, 0.06)),
            el("pregnancy.due", "Due date", kind="field", box=(0.50, 0.44, 0.86, 0.06)),
            el("pregnancy.save", "Save pregnancy", box=(0.50, 0.86, 0.86, 0.065), to="home"),
            el("pregnancy.back", "Back", kind="icon", box=(0.07, 0.06, 0.08, 0.05)),
        ],
    },
    "pregnancy.detail": {
        "title": "Pregnancy care",
        "tab": None,
        "elements": [
            el("pregnancy.checkin", "Weekly check-in", box=(0.50, 0.40, 0.86, 0.065),
               to="pregnancy.checkin"),
            el("pregnancy.records", "My records", kind="row", box=(0.50, 0.50, 0.86, 0.06),
               to="pregnancy.records"),
            el("pregnancy.danger", "Danger signs", kind="row", box=(0.50, 0.59, 0.86, 0.06),
               to="assessment.picker"),
            el("pregnancy.add_measurement", "Add vitals", kind="row", box=(0.50, 0.68, 0.86, 0.06),
               to="assessment.measurements"),
            el("pregnancy.back", "Back", kind="icon", box=(0.07, 0.06, 0.08, 0.05), to="home"),
        ],
    },
    "pregnancy.checkin": {
        "title": "Weekly check-in",
        "tab": None,
        "elements": [
            el("checkin.mood_good", "Feeling well", kind="chip", box=(0.30, 0.30, 0.36, 0.06)),
            el("checkin.mood_tired", "Tired", kind="chip", box=(0.70, 0.30, 0.36, 0.06)),
            el("checkin.symptom_none", "No warning signs", kind="chip", box=(0.30, 0.44, 0.40, 0.06)),
            el("checkin.symptom_bleeding", "Bleeding", kind="chip", box=(0.70, 0.44, 0.40, 0.06)),
            el("checkin.submit", "Send check-in", box=(0.50, 0.86, 0.86, 0.065), to="home"),
        ],
    },
    "pregnancy.records": {
        "title": "My records",
        "tab": None,
        "elements": [
            el("records.add_vitals", "Add vitals", box=(0.50, 0.50, 0.86, 0.065),
               to="assessment.measurements"),
            el("records.back", "Back", kind="icon", box=(0.07, 0.06, 0.08, 0.05),
               to="pregnancy.detail"),
        ],
    },
    "diet.plan": {
        "title": "Today's meals",
        "tab": None,
        "elements": [
            el("diet.breakfast", "Breakfast", kind="row", box=(0.50, 0.28, 0.86, 0.06)),
            el("diet.lunch", "Lunch", kind="row", box=(0.50, 0.38, 0.86, 0.06)),
            el("diet.dinner", "Dinner", kind="row", box=(0.50, 0.48, 0.86, 0.06)),
            el("diet.swap", "Swap a meal", box=(0.50, 0.62, 0.86, 0.06)),
            el("diet.listen", "Listen to meal plan", kind="icon", box=(0.84, 0.10, 0.12, 0.05)),
            el("diet.back", "Back", kind="icon", box=(0.07, 0.06, 0.08, 0.05), to="home"),
        ],
    },
    "nana.chat": {
        "title": "Nana",
        "tab": None,
        "elements": [
            el("nana.field", "Message Nana", kind="field", box=(0.50, 0.92, 0.62, 0.06)),
            el("nana.send", "Send", kind="icon", box=(0.90, 0.92, 0.10, 0.05)),
            el("nana.mic", "Speak", kind="icon", box=(0.80, 0.92, 0.10, 0.05),
               action="speak"),
            el("nana.quick.health", "Health check", kind="chip", box=(0.22, 0.76, 0.34, 0.05),
               to="assessment.picker"),
            el("nana.quick.feeding", "Feeding help", kind="chip", box=(0.58, 0.76, 0.34, 0.05)),
            el("nana.back", "Back", kind="icon", box=(0.07, 0.06, 0.08, 0.05), to="home"),
        ],
    },
    "settings": {
        "title": "Settings",
        "tab": None,
        "elements": [
            el("settings.region", "Country & language", kind="row", box=(0.50, 0.30, 0.86, 0.06),
               to="settings.region"),
            el("settings.companion_toggle", "Show Nana on screen", kind="toggle",
               box=(0.88, 0.40, 0.10, 0.04)),
            el("settings.auto_voice", "Read every question aloud", kind="toggle",
               box=(0.88, 0.49, 0.10, 0.04)),
            el("settings.voice", "Nana's voice", kind="segmented", box=(0.50, 0.60, 0.86, 0.07)),
            el("settings.privacy", "Your data is protected", kind="row", box=(0.50, 0.70, 0.86, 0.06),
               to="privacy.info"),
            el("settings.analytics", "Help improve GrowWithMe", kind="toggle",
               box=(0.88, 0.79, 0.10, 0.04)),
            el("settings.signout", "Sign out", kind="button", box=(0.50, 0.90, 0.86, 0.05)),
            el("settings.back", "Back", kind="icon", box=(0.07, 0.06, 0.08, 0.05), to="home"),
        ],
    },
    "settings.region": {
        "title": "Country & language",
        "tab": None,
        "elements": [
            el("region.ghana", "Ghana", kind="row", box=(0.50, 0.28, 0.86, 0.06)),
            el("region.nigeria", "Nigeria", kind="row", box=(0.50, 0.36, 0.86, 0.06)),
            el("region.kenya", "Kenya", kind="row", box=(0.50, 0.44, 0.86, 0.06)),
            el("region.language", "Language", kind="chip", box=(0.40, 0.62, 0.34, 0.05)),
            el("region.save", "Save", box=(0.50, 0.90, 0.86, 0.06), to="settings"),
        ],
    },
    "privacy.info": {
        "title": "Your data is protected",
        "tab": None,
        "elements": [
            el("privacy_info.listen", "Listen to this page", box=(0.50, 0.30, 0.62, 0.055)),
            el("privacy_info.close", "Back", kind="icon", box=(0.07, 0.06, 0.08, 0.05), to="settings"),
        ],
    },
    # Transient system surfaces — target of device intents.
    "device.dialer": {
        "title": "Dialer",
        "tab": None,
        "elements": [
            el("dialer.call", "Call", kind="button", box=(0.50, 0.88, 0.30, 0.06)),
            el("dialer.cancel", "Cancel", kind="text", box=(0.50, 0.94, 0.24, 0.04)),
        ],
    },
    "device.sms": {
        "title": "Messages",
        "tab": None,
        "elements": [
            el("sms.recipient", "Recipient", kind="field", box=(0.50, 0.16, 0.86, 0.05)),
            el("sms.body", "Message", kind="field", box=(0.50, 0.32, 0.86, 0.10)),
            el("sms.send", "Send message", kind="button", box=(0.86, 0.90, 0.12, 0.05)),
            el("sms.cancel", "Cancel", kind="text", box=(0.10, 0.06, 0.14, 0.05)),
        ],
    },
    "device.alarm": {
        "title": "Clock",
        "tab": None,
        "elements": [
            el("alarm.time", "Time", kind="select", box=(0.50, 0.42, 0.60, 0.06)),
            el("alarm.label", "Label", kind="field", box=(0.50, 0.54, 0.86, 0.06)),
            el("alarm.save", "Save alarm", kind="button", box=(0.50, 0.86, 0.50, 0.06)),
        ],
    },
    "device.share": {
        "title": "Share location",
        "tab": None,
        "elements": [
            el("share.whatsapp", "WhatsApp", kind="app", box=(0.40, 0.55, 0.30, 0.10)),
            el("share.sms", "Messages", kind="app", box=(0.70, 0.55, 0.30, 0.10)),
            el("share.cancel", "Cancel", kind="text", box=(0.50, 0.90, 0.24, 0.04)),
        ],
    },
}


# ---------------------------------------------------------------------------
# Goals: ordered intent paths. Steps reference element ids; typing is marked
# with kind="type" and a value kind. The generator resolves the next screen
# from the element definition, so this stays declarative.
# ---------------------------------------------------------------------------

def tap(eid: str) -> dict:
    return {"type": "tap", "target": eid}


def type_into(eid: str, value_kind: str) -> dict:
    return {"type": "type", "target": eid, "valueKind": value_kind}


def scroll(direction: str = "down", amount: float = 0.35) -> dict:
    return {"type": "scroll", "direction": direction, "amount": amount}


def back() -> dict:
    return {"type": "back"}


def long_press(eid: str) -> dict:
    return {"type": "long_press", "target": eid}


def swipe(direction: str = "left", amount: float = 0.6) -> dict:
    return {"type": "swipe", "direction": direction, "amount": amount}


def open_app(target: str, app: str) -> dict:
    return {"type": "open_app", "target": target, "value": app}


def speak(utterance_kind: str, target: str = "nana.mic") -> dict:
    return {"type": "speak", "target": target, "valueKind": utterance_kind}


def device(kind: str, target: str | None = None) -> dict:
    return {"type": kind, "target": target}


GOALS: dict[str, dict] = {
    "onboarding_new_user": {
        "description": "First launch to a ready home screen",
        "start": "onboarding.welcome",
        "intents": ["I am new", "set up my account"],
        "steps": [
            tap("welcome.country_chip"),
            tap("country.language_en"),
            tap("country.save"),
            tap("welcome.next"),
            type_into("phone.field", "phone_number"),
            tap("phone.continue"),
            type_into("otp.field", "otp_code"),
            tap("otp.verify"),
            tap("privacy.next"),
            type_into("profile.name", "person_name"),
            type_into("profile.district", "district"),
            type_into("profile.community", "community"),
            tap("profile.consent_data"),
            tap("profile.start"),
        ],
    },
    "explore_welcome_slides": {
        "description": "Swipe through the welcome carousel before starting",
        "start": "onboarding.welcome",
        "intents": ["Show me around", "What can this app do?"],
        "steps": [
            swipe("left"),
            swipe("left"),
            tap("welcome.next"),
        ],
    },
    "onboarding_returning_user": {
        "description": "Sign back in on a new phone",
        "start": "onboarding.welcome",
        "intents": ["Sign in", "I already have an account"],
        "steps": [
            tap("welcome.next"),
            type_into("phone.field", "phone_number"),
            tap("phone.continue"),
            type_into("otp.field", "otp_code"),
            {"type": "tap", "target": "otp.verify", "next": "home"},
        ],
    },
    "add_child": {
        "description": "Register a child under five",
        "intents": ["Add my child", "My baby is not in the app"],
        "steps": [
            tap("home.quick.family"),
            type_into("child.name", "child_name"),
            tap("child.dob"),
            tap("child.sex_female"),
            tap("child.save"),
        ],
    },
    "add_pregnancy": {
        "description": "Start tracking a pregnancy",
        "intents": ["I am pregnant", "Track my pregnancy"],
        "steps": [
            tap("home.pregnancy.add"),
            tap("pregnancy.lmp"),
            tap("pregnancy.save"),
        ],
    },
    "log_weight": {
        "description": "Log a child's growth measurement",
        "intents": ["Record my baby's weight", "Log growth"],
        "steps": [
            tap("home.child.rail"),
            tap("child.detail.log_growth"),
            type_into("growth.weight", "child_weight_kg"),
            type_into("growth.height", "height_cm"),
            tap("growth.save"),
        ],
    },
    "health_check": {
        "description": "Run a symptom triage check",
        "intents": ["My child is sick", "Check danger signs", "I do not feel well"],
        "steps": [
            tap("home.quick.health_check"),
            tap("check.pick_child"),
            tap("check.no"),
            tap("check.next"),
            tap("check.yes"),
            {"type": "tap", "target": "check.next", "next": "assessment.result"},
        ],
    },
    "call_clinic_from_result": {
        "description": "Call the clinic straight from triage advice",
        "intents": ["Call the clinic", "Speak to a nurse about this result"],
        "steps": [
            tap("home.quick.health_check"),
            tap("check.pick_mother"),
            tap("check.no"),
            {"type": "tap", "target": "check.next", "next": "assessment.result"},
            tap("result.call_facility"),
            tap("dialer.call"),
        ],
    },
    "set_reminder": {
        "description": "Add an ANC or immunization reminder",
        "intents": ["Remind me about my clinic visit", "Set a vaccination reminder"],
        "steps": [
            tap("home.quick.calendar"),
            tap("calendar.add"),
            type_into("reminder.title", "reminder_title"),
            tap("reminder.date"),
            tap("reminder.time"),
            tap("reminder.save"),
        ],
    },
    "view_calendar": {
        "description": "Check upcoming visits",
        "intents": ["When is my next visit?", "Show my calendar"],
        "steps": [tap("home.quick.calendar")],
    },
    "view_alerts": {
        "description": "Open the alerts inbox",
        "intents": ["Do I have any alerts?", "Check messages"],
        "steps": [tap("home.nav.alerts")],
    },
    "respond_to_alert": {
        "description": "Request help from a nearby responder",
        "intents": ["I need help now", "Send a health worker to me"],
        "steps": [
            tap("home.nav.alerts"),
            tap("alerts.item_urgent"),
            tap("alert.accept"),
        ],
    },
    "emergency_call": {
        "description": "Call the emergency number from an alert",
        "intents": ["Call an ambulance", "This is an emergency"],
        "steps": [
            tap("home.nav.alerts"),
            tap("alerts.item_urgent"),
            tap("alert.call"),
            tap("dialer.call"),
        ],
    },
    "share_location_emergency": {
        "description": "Share live location during an emergency",
        "intents": ["Let them find me", "Share my location with the nurse"],
        "steps": [
            tap("home.nav.alerts"),
            tap("alerts.item_urgent"),
            tap("alert.share_location"),
            tap("share.whatsapp"),
        ],
    },
    "message_health_worker": {
        "description": "Send an SMS update to a community health worker",
        "intents": ["Message my health worker", "Tell the nurse I am coming"],
        "steps": [
            tap("home.nav.alerts"),
            tap("alerts.item_followup"),
            tap("alert.message_chw"),
            type_into("sms.recipient", "sms_recipient"),
            type_into("sms.body", "sms_body"),
            tap("sms.send"),
        ],
    },
    "ask_nana_text": {
        "description": "Ask Nana a care question in chat",
        "intents": ["Ask about fever", "What should I feed my baby?"],
        "steps": [
            tap("home.quick.ask_nana"),
            type_into("nana.field", "chat_question"),
            tap("nana.send"),
        ],
    },
    "ask_nana_voice": {
        "description": "Speak a question to Nana hands-free",
        "intents": ["Talk to Nana", "Ask by voice"],
        "steps": [
            tap("home.nana.ask"),
            speak("chat_question_spoken"),
        ],
    },
    "companion_quick_health": {
        "description": "Use the floating companion to start a check",
        "intents": ["Nana, check my baby", "Start a health check from Nana"],
        "steps": [
            tap("home.companion"),
            tap("companion.chat"),
            tap("nana.quick.health"),
            tap("check.pick_child"),
        ],
    },
    "view_diet_plan": {
        "description": "Read today's locally-sourced meal plan",
        "intents": ["What should I eat today?", "Show my meal plan"],
        "steps": [
            tap("home.meals.card"),
            tap("diet.listen"),
        ],
    },
    "view_tips": {
        "description": "Browse daily care tips",
        "intents": ["Give me a tip", "Care advice for today"],
        "steps": [
            tap("home.nav.tips"),
            tap("tips.tip_card"),
            tap("tips.listen"),
        ],
    },
    "pregnancy_checkin": {
        "description": "Complete the weekly pregnancy check-in",
        "intents": ["Weekly check-in", "Report how I feel"],
        "steps": [
            tap("home.pregnancy.card"),
            tap("pregnancy.checkin"),
            tap("checkin.mood_good"),
            tap("checkin.symptom_none"),
            tap("checkin.submit"),
        ],
    },
    "view_pregnancy_records": {
        "description": "Review pregnancy vitals history",
        "intents": ["Show my records", "What was my blood pressure?"],
        "steps": [
            tap("home.pregnancy.card"),
            tap("pregnancy.records"),
            tap("records.back"),
        ],
    },
    "log_vitals": {
        "description": "Record blood pressure and weight",
        "intents": ["Record my blood pressure", "Log vitals"],
        "steps": [
            tap("home.pregnancy.card"),
            tap("pregnancy.add_measurement"),
            type_into("vitals.systolic", "systolic"),
            type_into("vitals.diastolic", "diastolic"),
            type_into("vitals.weight", "weight_kg"),
            tap("vitals.save"),
            tap("result.done"),
        ],
    },
    "child_growth_chart": {
        "description": "Open a child's growth chart",
        "intents": ["Is my baby growing well?", "Show the growth chart"],
        "steps": [
            tap("home.child.rail"),
            scroll("down"),
            tap("child.detail.growth_chart"),
        ],
    },
    "change_language": {
        "description": "Switch the app language from settings",
        "intents": ["Change language", "Use Twi"],
        "steps": [
            tap("home.settings"),
            tap("settings.region"),
            tap("region.language"),
            tap("region.save"),
        ],
    },
    "review_privacy": {
        "description": "Read the privacy explainer",
        "intents": ["How is my data used?", "Show privacy"],
        "steps": [
            tap("home.settings"),
            tap("settings.privacy"),
            tap("privacy_info.listen"),
        ],
    },
    "toggle_companion": {
        "description": "Hide or restore the on-screen companion",
        "intents": ["Hide Nana", "Turn the avatar off"],
        "steps": [
            tap("home.settings"),
            tap("settings.companion_toggle"),
        ],
    },
    "enable_analytics_optin": {
        "description": "Opt in to anonymous interaction sharing",
        "intents": ["Help improve the app", "Share usage data"],
        "steps": [
            tap("home.settings"),
            tap("settings.analytics"),
        ],
    },
    "sync_now": {
        "description": "Force a sync after being offline",
        "intents": ["Sync my data", "Upload when online"],
        "steps": [tap("home.sync")],
    },
    "set_medication_alarm": {
        "description": "Set a phone alarm for medication",
        "intents": ["Remind me to take my iron tablets", "Set an alarm"],
        "steps": [
            tap("home.quick.calendar"),
            tap("calendar.add"),
            type_into("reminder.title", "reminder_title"),
            tap("reminder.save"),
        ],
    },
    "open_whatsapp_tip": {
        "description": "Share a care tip with family on WhatsApp",
        "intents": ["Share this tip", "Send the tip to my sister"],
        "steps": [
            tap("home.nav.tips"),
            tap("tips.share"),
            tap("share.whatsapp"),
        ],
    },
    "toggle_auto_voice": {
        "description": "Turn on read-aloud for every question",
        "intents": ["Read questions aloud", "Voice mode for my mother"],
        "steps": [
            tap("home.settings"),
            tap("settings.auto_voice"),
        ],
    },
    "hide_companion_gesture": {
        "description": "Long-press the floating companion to tuck her away",
        "intents": ["Hide the avatar", "Nana is covering the screen"],
        "steps": [
            long_press("home.companion"),
        ],
    },
    "set_phone_alarm": {
        "description": "Set a system alarm for medication (device intent)",
        "start": "device.alarm",
        "intents": ["Set an alarm for my tablets", "Wake me for my medicine"],
        "steps": [
            tap("alarm.time"),
            type_into("alarm.label", "alarm_label"),
            tap("alarm.save"),
        ],
    },
    "open_whatsapp_app": {
        "description": "Open WhatsApp to message family (device intent)",
        "start": "device.share",
        "intents": ["Open WhatsApp", "Message my sister on WhatsApp"],
        "steps": [
            open_app("share.whatsapp", "whatsapp"),
        ],
    },
}


# Elements that are device-level intents rather than in-app routes.
DEVICE_INTENTS = {
    "dialer.call": {"kind": "call", "param": "phone_kind"},
    "alerts.call_chw": {"kind": "call", "param": "phone_kind"},
    "alert.call": {"kind": "call", "param": "phone_kind"},
    "sms.send": {"kind": "send_sms", "param": "sms_kind"},
    "alarm.save": {"kind": "set_alarm", "param": "alarm_kind"},
    "share.whatsapp": {"kind": "share_location", "param": "share_kind"},
    "share.sms": {"kind": "share_location", "param": "share_kind"},
}


def build_graph() -> dict:
    return {
        "app": "growwithme",
        "appVersion": APP_VERSION,
        "graphVersion": GRAPH_VERSION,
        "platforms": ["android"],
        "actionSpace": [
            "tap",
            "long_press",
            "type",
            "scroll",
            "swipe",
            "back",
            "speak",
            "toggle",
            "call",
            "send_sms",
            "set_alarm",
            "share_location",
            "open_app",
        ],
        "screens": SCREENS,
        "goals": GOALS,
        "deviceIntents": DEVICE_INTENTS,
    }
