#!/usr/bin/env python3
"""Generate a synthetic behaviour-cloning corpus for the GrowWithMe app.

Each line of the output JSONL is one *episode*: a caregiver goal, the screen
states she saw and the exact actions she took. The corpus is grounded in
`graph.py`, which mirrors the shipped Flutter screens, widget ids and device
intents, so the vocabulary matches the app's ActionLogger.

Design goals
------------
* privacy-safe by construction: every value is synthetic, no real person,
  phone number or health record is ever represented;
* persona-aware: first-time mothers explore and mis-tap, low-literacy users
  speak instead of typing, CHWs move fast, high-risk pregnancies escalate;
* global: country/locale/emergency-number variation for GH, NG, KE, UG, TZ;
* split-safe: episodes (not steps) are partitioned into train/val/test so no
  trajectory leaks across splits.

Usage
-----
    python3 generate_dataset.py --episodes 3000
    python3 generate_dataset.py --episodes 60000 --out dataset_full --seed 7
"""

from __future__ import annotations

import argparse
import hashlib
import json
import random
import statistics
from collections import Counter, defaultdict
from datetime import datetime, timezone
from pathlib import Path

from graph import (
    APP_VERSION,
    DEVICE_INTENTS,
    GOALS,
    GRAPH_VERSION,
    SCREENS,
    build_graph,
)

GENERATOR_VERSION = "1.0.0"

COUNTRIES = {
    "GH": {
        "locale": "en-GH",
        "dial": "+233",
        "emergency": "112",
        "languages": ["en", "tw", "dag", "ha"],
        "districts": ["Tamale", "Kumasi", "Accra", "Bolgatanga", "Wa", "Cape Coast"],
        "communities": ["Kalpohin", "Sagnarigu", "Asokwa", "Madina", "Bawku"],
    },
    "NG": {
        "locale": "en-NG",
        "dial": "+234",
        "emergency": "112",
        "languages": ["en", "ha"],
        "districts": ["Kano", "Lagos", "Enugu", "Kaduna", "Ibadan"],
        "communities": ["Sabon Gari", "Ikeja", "Nsukka", "Zaria"],
    },
    "KE": {
        "locale": "sw-KE",
        "dial": "+254",
        "emergency": "999",
        "languages": ["sw", "en"],
        "districts": ["Nairobi", "Kisumu", "Mombasa", "Nakuru"],
        "communities": ["Kibera", "Kondele", "Likoni", "Naivasha"],
    },
    "UG": {
        "locale": "en-UG",
        "dial": "+256",
        "emergency": "999",
        "languages": ["en", "sw", "lg"],
        "districts": ["Kampala", "Gulu", "Mbarara", "Mbale"],
        "communities": ["Kawempe", "Layibi", "Kakoba", "Nakaloke"],
    },
    "TZ": {
        "locale": "sw-TZ",
        "dial": "+255",
        "emergency": "112",
        "languages": ["sw", "en"],
        "districts": ["Dar es Salaam", "Arusha", "Mwanza", "Dodoma"],
        "communities": ["Kinondoni", "Kijichi", "Nyamagana", "Chang'ombe"],
    },
}

PERSONAS = {
    "first_time_mother": {
        "label": "First-time mother",
        "error": 0.09,
        "explore": 0.16,
        "voice": 0.22,
        "delay": (900, 3600),
        "pregnant": 0.65,
        "children": (0, 1),
        "countries": {"GH": 0.55, "NG": 0.15, "KE": 0.12, "UG": 0.10, "TZ": 0.08},
    },
    "experienced_mother": {
        "label": "Experienced mother",
        "error": 0.02,
        "explore": 0.04,
        "voice": 0.05,
        "delay": (450, 1700),
        "pregnant": 0.18,
        "children": (1, 3),
        "countries": {"GH": 0.45, "NG": 0.20, "KE": 0.15, "UG": 0.11, "TZ": 0.09},
    },
    "low_literacy_caregiver": {
        "label": "Voice-first caregiver",
        "error": 0.11,
        "explore": 0.10,
        "voice": 0.88,
        "delay": (1300, 4400),
        "pregnant": 0.40,
        "children": (0, 2),
        "countries": {"GH": 0.50, "NG": 0.16, "KE": 0.10, "UG": 0.14, "TZ": 0.10},
    },
    "community_health_worker": {
        "label": "Community health worker",
        "error": 0.02,
        "explore": 0.03,
        "voice": 0.12,
        "delay": (380, 1300),
        "pregnant": 0.05,
        "children": (2, 3),
        "countries": {"GH": 0.50, "NG": 0.15, "KE": 0.15, "UG": 0.12, "TZ": 0.08},
    },
    "high_risk_pregnancy": {
        "label": "High-risk pregnancy",
        "error": 0.05,
        "explore": 0.05,
        "voice": 0.34,
        "delay": (650, 2300),
        "pregnant": 1.0,
        "children": (0, 2),
        "countries": {"GH": 0.52, "NG": 0.18, "KE": 0.10, "UG": 0.12, "TZ": 0.08},
    },
    "diaspora_supporter": {
        "label": "Diaspora family supporter",
        "error": 0.04,
        "explore": 0.13,
        "voice": 0.20,
        "delay": (600, 2500),
        "pregnant": 0.10,
        "children": (1, 2),
        "countries": {"GH": 0.40, "NG": 0.22, "KE": 0.18, "UG": 0.10, "TZ": 0.10},
    },
    "multilingual_caregiver": {
        "label": "Multilingual caregiver",
        "error": 0.07,
        "explore": 0.09,
        "voice": 0.55,
        "delay": (800, 2900),
        "pregnant": 0.30,
        "children": (1, 2),
        "countries": {"GH": 0.45, "NG": 0.18, "KE": 0.14, "UG": 0.13, "TZ": 0.10},
    },
}

# How often each goal should appear. Everyday tasks dominate; emergencies and
# onboarding are rarer but still represented in every split.
GOAL_WEIGHTS = {
    "onboarding_new_user": 4,
    "explore_welcome_slides": 2,
    "onboarding_returning_user": 2,
    "add_child": 6,
    "add_pregnancy": 3,
    "log_weight": 6,
    "health_check": 9,
    "call_clinic_from_result": 2,
    "set_reminder": 7,
    "view_calendar": 8,
    "view_alerts": 7,
    "respond_to_alert": 3,
    "emergency_call": 2,
    "share_location_emergency": 2,
    "message_health_worker": 3,
    "ask_nana_text": 9,
    "ask_nana_voice": 5,
    "companion_quick_health": 4,
    "view_diet_plan": 6,
    "view_tips": 5,
    "pregnancy_checkin": 6,
    "view_pregnancy_records": 4,
    "log_vitals": 5,
    "child_growth_chart": 4,
    "change_language": 3,
    "review_privacy": 2,
    "toggle_companion": 1,
    "enable_analytics_optin": 1,
    "sync_now": 3,
    "set_medication_alarm": 3,
    "open_whatsapp_tip": 2,
    "toggle_auto_voice": 2,
    "hide_companion_gesture": 1,
    "set_phone_alarm": 2,
    "open_whatsapp_app": 1,
}

FIRST_NAMES = [
    "Ama", "Akua", "Abena", "Adwoa", "Efua", "Fatima", "Amina", "Zainab",
    "Grace", "Ngozi", "Wanjiku", "Achieng", "Mariam", "Hawa", "Chidinma",
    "Salamatu", "Ama", "Rahma", "Esther", "Blessing", "Neema", "Asha",
]
CHILD_NAMES = [
    "Kwame", "Kofi", "Yaw", "Ama", "Adjoa", "Musa", "Ibrahim", "Chidi",
    "Nia", "Zuri", "Juma", "Amani", "Sena", "Kofi", "Amina", "Tunde",
]
COMMUNITY_SUFFIXES = ["Community", "Junction", "Market", "Zongo", "Estate"]
REMINDER_TITLES = [
    "ANC visit", "Immunization", "Take iron tablets", "Postnatal check",
    "Blood pressure check", "Child weighing",
]
CHAT_QUESTIONS = [
    "My baby has fever, what should I do?",
    "What should I eat while pregnant?",
    "Is bleeding normal?",
    "My child is not eating well",
    "How often should I breastfeed?",
    "My head is pounding and I feel dizzy",
]
SPOKEN_QUESTIONS = [
    "Nana, my child is hot",
    "What food is good for my pregnancy?",
    "I feel pain in my belly",
    "Help me check my baby",
]
SMS_BODIES = [
    "I am coming to the clinic today.",
    "Please visit me, I am not feeling well.",
    "My baby has a fever. Can you help?",
]
ALARM_LABELS = ["Iron tablets", "Blood pressure medicine", "ANC visit"]


# ---------------------------------------------------------------------------
# Synthetic values — never real people, always reproducible from the seed.
# ---------------------------------------------------------------------------

class ValueFactory:
    def __init__(self, rng: random.Random, country_code: str, district: str):
        self.rng = rng
        self.country = COUNTRIES[country_code]
        self.district = district

    def make(self, kind: str) -> str:
        rng = self.rng
        if kind in ("person_name",):
            return rng.choice(FIRST_NAMES)
        if kind == "child_name":
            return rng.choice(CHILD_NAMES)
        if kind == "phone_number":
            return f"{self.country['dial']} {rng.randint(20, 59)}{rng.randint(1000000, 9999999)}"
        if kind == "otp_code":
            return f"{rng.randint(0, 999999):06d}"
        if kind == "district":
            return self.district
        if kind == "community":
            return f"{rng.choice(['Sabon', 'Kpalsi', 'Nyohini', 'Kibra', 'Kawempe', 'Kimara'])} " \
                   f"{rng.choice(COMMUNITY_SUFFIXES)}"
        if kind == "systolic":
            return str(rng.randint(92, 158))
        if kind == "diastolic":
            return str(rng.randint(55, 102))
        if kind == "weight_kg":
            return f"{rng.uniform(46, 92):.1f}"
        if kind == "child_weight_kg":
            return f"{rng.uniform(5.5, 17.5):.1f}"
        if kind == "height_cm":
            return f"{rng.uniform(62, 104):.1f}"
        if kind == "reminder_title":
            return rng.choice(REMINDER_TITLES)
        if kind in ("chat_question", "chat_question_spoken"):
            return rng.choice(CHAT_QUESTIONS if kind == "chat_question" else SPOKEN_QUESTIONS)
        if kind == "sms_recipient":
            return "Community health worker"
        if kind == "sms_body":
            return rng.choice(SMS_BODIES)
        if kind in ("alarm_label", "alarm_kind"):
            return rng.choice(ALARM_LABELS)
        if kind in ("phone_kind",):
            return "emergency" if rng.random() < 0.85 else "chw"
        if kind in ("sms_kind",):
            return "health_worker"
        if kind in ("share_kind",):
            return "live_location"
        # Fallback: a short synthetic token keeps the schema uniform.
        return f"synthetic_{kind}"


def sample_country(persona: dict, rng: random.Random) -> str:
    codes = list(persona["countries"])
    weights = [persona["countries"][c] for c in codes]
    return rng.choices(codes, weights=weights, k=1)[0]


def sample_language(country_code: str, persona_key: str, rng: random.Random) -> str:
    langs = COUNTRIES[country_code]["languages"]
    if persona_key in ("low_literacy_caregiver", "multilingual_caregiver"):
        # Local languages are represented even while their UI is in beta, so
        # the model learns the fallback-to-English pattern.
        return rng.choices(langs, weights=[1.0 if l != "en" else 0.6 for l in langs], k=1)[0]
    return "en" if "en" in langs and rng.random() < 0.8 else langs[0]


def build_state(country_code: str, language: str, persona: dict, rng: random.Random,
                first_run: bool) -> dict:
    children = rng.randint(*persona["children"])
    return {
        "country": country_code,
        "language": language,
        "childCount": 0 if first_run else children,
        "pregnant": False if first_run else rng.random() < persona["pregnant"],
        "offline": rng.random() < 0.22,
        "network": "offline" if rng.random() < 0.22 else rng.choice(["wifi", "4g", "3g"]),
        "firstRun": first_run,
        "consented": True,
        "appVersion": APP_VERSION,
    }


# ---------------------------------------------------------------------------
# Simulation
# ---------------------------------------------------------------------------

def element_index(screen: str) -> dict[str, dict]:
    return {e["id"]: e for e in SCREENS[screen]["elements"]}


def visible_elements(screen: str, scrolled: bool) -> list[dict]:
    out = []
    for e in SCREENS[screen]["elements"]:
        if e["requiresScroll"] and not scrolled:
            continue
        out.append({
            "id": e["id"],
            "label": e["label"],
            "kind": e["kind"],
            "box": e["box"],
        })
    return out


def observation(screen: str, state: dict, scrolled: bool, step_index: int) -> dict:
    return {
        "screen": screen,
        "screenTitle": SCREENS[screen]["title"],
        "tab": SCREENS[screen]["tab"],
        "elements": visible_elements(screen, scrolled),
        "scrollable": any(e["requiresScroll"] for e in SCREENS[screen]["elements"]),
        "scrolled": scrolled,
        "state": state,
        "stepIndex": step_index,
    }


def jittered_center(box: list[float], rng: random.Random, noise: float) -> list[float]:
    x, y, w, h = box
    cx = x + w / 2 + rng.uniform(-0.012, 0.012) * max(noise, 0.1)
    cy = y + h / 2 + rng.uniform(-0.012, 0.012) * max(noise, 0.1)
    return [round(min(0.985, max(0.015, cx)), 3), round(min(0.985, max(0.015, cy)), 3)]


class EpisodeSimulator:
    def __init__(self, goal_id: str, persona_key: str, country_code: str,
                 seed: int, index: int):
        self.goal_id = goal_id
        self.goal = GOALS[goal_id]
        self.persona_key = persona_key
        self.persona = PERSONAS[persona_key]
        self.country_code = country_code
        self.seed = seed
        self.index = index
        self.rng = random.Random(seed)
        self.country = COUNTRIES[country_code]
        self.district = self.rng.choice(self.country["districts"])
        self.language = sample_language(country_code, persona_key, self.rng)
        self.values = ValueFactory(self.rng, country_code, self.district)
        self.first_run = self.goal.get("start") == "onboarding.welcome"
        self.state = build_state(country_code, self.language, self.persona,
                                 self.rng, self.first_run)
        self.screen = self.goal.get("start", "home")
        self.stack: list[str] = []
        self.scrolled = False
        self.steps: list[dict] = []
        self.elapsed = 0

    # -- primitives ---------------------------------------------------------
    def _duration(self, typing: bool = False) -> int:
        lo, hi = self.persona["delay"]
        d = self.rng.randint(lo, hi)
        return d + (self.rng.randint(350, 1400) if typing else 0)

    def _append(self, obs: dict, action: dict, outcome: dict, duration: int) -> None:
        step = {
            "stepId": len(self.steps) + 1,
            "observation": obs,
            "action": action,
            "outcome": outcome,
            "durationMs": duration,
        }
        self.elapsed += duration
        self.steps.append(step)

    def _tap(self, eid: str, step: dict, *, distractor: bool = False) -> str:
        elements = element_index(self.screen)
        if eid not in elements:
            raise ValueError(
                f"goal {self.goal_id}: element {eid} not on screen {self.screen}")
        e = elements[eid]
        obs = observation(self.screen, self.state, self.scrolled, len(self.steps))
        coords = jittered_center(e["box"], self.rng, 1.0 + self.persona["error"] * 6)

        action: dict = {"type": "tap", "target": eid, "coords": coords}
        next_screen = self.screen

        if eid in DEVICE_INTENTS and not distractor:
            info = DEVICE_INTENTS[eid]
            kind = info["kind"]
            action = {
                "type": kind,
                "target": eid,
                "coords": coords,
                "value": self.values.make(info["param"]),
            }
            if kind == "call":
                action["value"] = self.country["emergency"]
            if e["action"] == "speak":
                action["valueKind"] = step.get("valueKind")
        elif e["action"] == "speak" and not distractor:
            action = {
                "type": "speak",
                "target": eid,
                "coords": coords,
                "value": self.values.make(step.get("valueKind", "chat_question_spoken")),
                "valueKind": step.get("valueKind", "chat_question_spoken"),
            }
        elif e["kind"] == "toggle" and not distractor:
            action = {
                "type": "toggle",
                "target": eid,
                "coords": coords,
                "value": self.rng.choice(["on", "off"]),
            }
        elif step["type"] == "type":
            action = {
                "type": "type",
                "target": eid,
                "coords": coords,
                "value": self.values.make(step["valueKind"]),
                "valueKind": step["valueKind"],
            }
        else:
            # Naive assistive tap: the observation's label is the handle.
            action["label"] = e["label"]

        failure = None
        success = True
        if not distractor and step["type"] == "type" and step.get("allow_error", True):
            if self.rng.random() < self.persona["error"] * 0.6:
                success = False
                failure = "empty_required_field"
                action["value"] = ""

        next_screen = step.get("next") or e.get("to") or self.screen
        if next_screen != self.screen:
            self.stack.append(self.screen)
            self.screen = next_screen
            self.scrolled = False

        outcome = {"success": success, "nextScreen": self.screen}
        if failure:
            outcome["error"] = failure
        self._append(obs, action, outcome, self._duration(typing=step["type"] == "type"))
        return self.screen

    def _scroll(self, direction: str = "down") -> None:
        obs = observation(self.screen, self.state, self.scrolled, len(self.steps))
        action = {
            "type": "scroll",
            "target": None,
            "coords": None,
            "direction": direction,
            "amount": 0.35,
        }
        self.scrolled = True
        self._append(obs, action, {"success": True, "nextScreen": self.screen},
                     self._duration())

    def _back(self) -> None:
        obs = observation(self.screen, self.state, self.scrolled, len(self.steps))
        self.screen = self.stack.pop() if self.stack else "home"
        self.scrolled = False
        self._append(obs, {"type": "back", "target": None, "coords": None},
                     {"success": True, "nextScreen": self.screen}, self._duration())

    def _long_press(self, eid: str) -> None:
        e = element_index(self.screen).get(eid)
        if not e:
            raise ValueError(
                f"goal {self.goal_id}: element {eid} not on screen {self.screen}")
        obs = observation(self.screen, self.state, self.scrolled, len(self.steps))
        coords = jittered_center(e["box"], self.rng, 1.0)
        self._append(
            obs,
            {
                "type": "long_press",
                "target": eid,
                "coords": coords,
                "holdMs": self.rng.randint(650, 1200),
            },
            {"success": True, "nextScreen": self.screen},
            self._duration(),
        )

    def _open_app(self, eid: str, app: str) -> None:
        e = element_index(self.screen).get(eid)
        if not e:
            raise ValueError(
                f"goal {self.goal_id}: element {eid} not on screen {self.screen}")
        obs = observation(self.screen, self.state, self.scrolled, len(self.steps))
        coords = jittered_center(e["box"], self.rng, 1.0)
        self._append(
            obs,
            {"type": "open_app", "target": eid, "coords": coords, "value": app},
            {"success": True, "nextScreen": self.screen},
            self._duration(),
        )

    def _swipe(self, direction: str, amount: float) -> None:
        obs = observation(self.screen, self.state, self.scrolled, len(self.steps))
        if direction == "left":
            start, end = [0.82, 0.52], [0.82 - amount * 0.6, 0.52]
        elif direction == "right":
            start, end = [0.18, 0.52], [0.18 + amount * 0.6, 0.52]
        elif direction == "up":
            start, end = [0.50, 0.78], [0.50, 0.78 - amount * 0.6]
        else:
            start, end = [0.50, 0.32], [0.50, 0.32 + amount * 0.6]
        self._append(
            obs,
            {
                "type": "swipe",
                "target": None,
                "coords": [[round(start[0], 3), round(start[1], 3)],
                           [round(end[0], 3), round(end[1], 3)]],
                "direction": direction,
                "amount": amount,
            },
            {"success": True, "nextScreen": self.screen},
            self._duration(),
        )

    # -- exploration noise --------------------------------------------------
    def _distract(self, upcoming_target: str) -> None:
        visible = {e["id"] for e in visible_elements(self.screen, self.scrolled)}
        elements = element_index(self.screen)
        candidates = [
            eid for eid, e in elements.items()
            if eid in visible
            and eid != upcoming_target
            and eid not in DEVICE_INTENTS
            and e.get("to")
            and e["to"] not in ("device.dialer", "device.sms", "device.share")
            and e["kind"] not in ("toggle", "avatar")
        ]
        if not candidates:
            return
        eid = self.rng.choice(candidates)
        before = self.screen
        self._tap(eid, {"type": "tap", "target": eid}, distractor=True)
        if self.screen != before:
            self._back()

    # -- goal walk ----------------------------------------------------------
    def run(self) -> dict:
        for raw in self.goal["steps"]:
            step = dict(raw)
            kind = step["type"]
            target = step.get("target")

            if kind == "scroll":
                self._scroll(step.get("direction", "down"))
                continue

            if kind == "back":
                self._back()
                continue

            if kind == "swipe":
                self._swipe(step.get("direction", "left"), step.get("amount", 0.6))
                continue

            if kind == "long_press":
                self._long_press(target)
                continue

            if kind == "open_app":
                self._open_app(target, step["value"])
                continue

            # Voice preferences: low-literacy personas sometimes reach a voice
            # affordance instead of typing when one exists on screen.
            if kind == "type" and self.persona["voice"] > 0.5:
                voice_alt = self._voice_alternative(target)
                if voice_alt and self.rng.random() < 0.25:
                    self._tap(voice_alt, {"type": "speak", "target": voice_alt,
                                          "valueKind": "chat_question_spoken"})
                    continue

            # Auto-scroll when the target is below the fold.
            if target:
                e = element_index(self.screen).get(target)
                if e and e["requiresScroll"] and not self.scrolled:
                    self._scroll()
                if not e:
                    raise ValueError(
                        f"goal {self.goal_id}: {target} missing on {self.screen}")

            if self.rng.random() < self.persona["explore"]:
                self._distract(target or "")
                # A detour may have returned to an unscrolled copy of the
                # screen, so re-check the fold after every distraction.
                if target:
                    e = element_index(self.screen).get(target)
                    if e and e["requiresScroll"] and not self.scrolled:
                        self._scroll()

            if kind == "tap" or kind == "speak":
                if kind == "speak":
                    e = element_index(self.screen).get(target)
                    if not e or e["action"] != "speak":
                        # Fall back to whichever mic is on the current screen.
                        target = next(
                            (x["id"] for x in SCREENS[self.screen]["elements"]
                             if x["action"] == "speak"), target)
                self._tap(target, step)
            elif kind == "type":
                self._tap(target, step)
            else:
                raise ValueError(f"unknown step type {kind}")

        return self._episode()

    def _voice_alternative(self, target: str | None) -> str | None:
        for e in SCREENS[self.screen]["elements"]:
            if e["action"] == "speak":
                return e["id"]
        return None

    def _episode(self) -> dict:
        episode_id = (
            f"gwm-{self.goal_id}-{self.persona_key}-{self.country_code}-"
            f"{self.seed}-{self.index:05d}"
        )
        return {
            "episodeId": episode_id,
            "generatorVersion": GENERATOR_VERSION,
            "graphVersion": GRAPH_VERSION,
            "seed": self.seed,
            "persona": self.persona_key,
            "personaLabel": self.persona["label"],
            "country": self.country_code,
            "locale": self.country["locale"],
            "language": self.language,
            "goal": self.goal_id,
            "goalDescription": self.goal["description"],
            "intents": self.goal["intents"],
            "startScreen": self.goal.get("start", "home"),
            "finalScreen": self.screen,
            "outcome": {
                "completed": True,
                "success": all(s["outcome"]["success"] for s in self.steps),
                "stepCount": len(self.steps),
                "durationMs": self.elapsed,
            },
            "device": {
                "platform": "android",
                "appVersion": APP_VERSION,
                "locale": self.country["locale"],
            },
            "steps": self.steps,
        }


# ---------------------------------------------------------------------------
# Corpus assembly
# ---------------------------------------------------------------------------

def allocate_goal_counts(total: int, rng: random.Random) -> list[str]:
    goals = list(GOALS)
    weights = [GOAL_WEIGHTS.get(g, 1) for g in goals]
    floor = 6 if total >= len(goals) * 6 else max(1, total // len(goals))
    remaining = total - floor * len(goals)
    if remaining < 0:
        floor = 1
        remaining = max(0, total - len(goals))
    counts = {g: floor for g in goals}
    weighted = list(zip(goals, weights))
    picks = rng.choices(
        [g for g, _ in weighted],
        weights=[w for _, w in weighted],
        k=remaining,
    )
    for g in picks:
        counts[g] += 1
    # Trim if floor overshot a very small request.
    while sum(counts.values()) > total:
        g = rng.choice([g for g in counts if counts[g] > 1])
        counts[g] -= 1
    return [g for g, c in counts.items() for _ in range(c)]


def assign_splits(episodes: list[dict], rng: random.Random,
                  ratios: tuple[float, float, float]) -> None:
    by_goal: dict[str, list[dict]] = defaultdict(list)
    for ep in episodes:
        by_goal[ep["goal"]].append(ep)
    for goal, eps in by_goal.items():
        rng.shuffle(eps)
        n = len(eps)
        n_train = max(1, int(round(n * ratios[0])))
        n_val = max(1, int(round(n * ratios[1]))) if n >= 3 else 0
        if n_train + n_val >= n:
            n_train = max(1, n - 2) if n >= 3 else n
            n_val = 1 if n >= 3 else 0
        for i, ep in enumerate(eps):
            if i < n_train:
                ep["split"] = "train"
            elif i < n_train + n_val:
                ep["split"] = "val"
            else:
                ep["split"] = "test"


def sha256_of(path: Path) -> str:
    h = hashlib.sha256()
    with path.open("rb") as f:
        for chunk in iter(lambda: f.read(1 << 20), b""):
            h.update(chunk)
    return h.hexdigest()


def compute_stats(episodes: list[dict]) -> dict:
    action_counts = Counter()
    goal_counts = Counter()
    persona_counts = Counter()
    country_counts = Counter()
    screen_counts = Counter()
    split_counts = Counter()
    value_kinds = Counter()
    target_counts = Counter()
    lengths = []
    durations = []
    successes = 0
    total_steps = 0

    for ep in episodes:
        goal_counts[ep["goal"]] += 1
        persona_counts[ep["persona"]] += 1
        country_counts[ep["country"]] += 1
        split_counts[ep["split"]] += 1
        lengths.append(len(ep["steps"]))
        durations.append(ep["outcome"]["durationMs"])
        for s in ep["steps"]:
            total_steps += 1
            a = s["action"]
            action_counts[a["type"]] += 1
            if a.get("target"):
                target_counts[a["target"]] += 1
            if a.get("valueKind"):
                value_kinds[a["valueKind"]] += 1
            screen_counts[s["observation"]["screen"]] += 1
            if s["outcome"]["success"]:
                successes += 1

    return {
        "episodes": len(episodes),
        "steps": total_steps,
        "splits": dict(split_counts),
        "goals": dict(goal_counts.most_common()),
        "personas": dict(persona_counts.most_common()),
        "countries": dict(country_counts.most_common()),
        "actions": dict(action_counts.most_common()),
        "topTargets": dict(target_counts.most_common(40)),
        "valueKinds": dict(value_kinds.most_common()),
        "screenCoverage": len(screen_counts),
        "screens": dict(screen_counts.most_common()),
        "stepsPerEpisode": {
            "mean": round(statistics.mean(lengths), 2),
            "median": statistics.median(lengths),
            "min": min(lengths),
            "max": max(lengths),
            "p95": sorted(lengths)[max(0, int(len(lengths) * 0.95) - 1)],
        },
        "durationMsPerEpisode": {
            "mean": int(statistics.mean(durations)),
            "median": int(statistics.median(durations)),
        },
        "stepSuccessRate": round(successes / total_steps, 4) if total_steps else 0,
        "uniqueElements": len(target_counts),
    }


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--episodes", type=int, default=3000,
                        help="total episodes to generate (default 3000)")
    parser.add_argument("--out", type=Path,
                        default=Path(__file__).parent / "dataset",
                        help="output directory")
    parser.add_argument("--seed", type=int, default=20261102)
    parser.add_argument("--train", type=float, default=0.8)
    parser.add_argument("--val", type=float, default=0.1)
    parser.add_argument("--test", type=float, default=0.1)
    args = parser.parse_args()

    if abs(args.train + args.val + args.test - 1.0) > 1e-6:
        raise SystemExit("train/val/test ratios must sum to 1.0")

    args.out.mkdir(parents=True, exist_ok=True)
    (args.out.parent / "schema").mkdir(parents=True, exist_ok=True)

    rng = random.Random(args.seed)
    (args.out.parent / "schema" / "app_graph.json").write_text(
        json.dumps(build_graph(), indent=2, ensure_ascii=False) + "\n",
        encoding="utf-8",
    )

    goal_plan = allocate_goal_counts(args.episodes, rng)
    episodes: list[dict] = []
    ep_index = 0
    for goal_id in goal_plan:
        persona_key = rng.choices(
            list(PERSONAS),
            weights=[4, 5, 3, 2, 3, 2, 2],
            k=1,
        )[0]
        persona = PERSONAS[persona_key]
        country = sample_country(persona, rng)
        seed = rng.randrange(1, 2**31 - 1)
        sim = EpisodeSimulator(goal_id, persona_key, country, seed, ep_index)
        episodes.append(sim.run())
        ep_index += 1

    assign_splits(episodes, rng, (args.train, args.val, args.test))
    episodes.sort(key=lambda e: e["episodeId"])

    files = {}
    for split in ("train", "val", "test"):
        path = args.out / f"{split}.jsonl"
        with path.open("w", encoding="utf-8") as f:
            for ep in episodes:
                if ep["split"] == split:
                    f.write(json.dumps(ep, ensure_ascii=False) + "\n")
        files[split] = {
            "file": path.name,
            "episodes": sum(1 for e in episodes if e["split"] == split),
            "sha256": sha256_of(path),
        }

    stats = compute_stats(episodes)
    stats_path = args.out / "stats.json"
    stats_path.write_text(json.dumps(stats, indent=2) + "\n", encoding="utf-8")

    manifest = {
        "name": "growwithme-action-model",
        "generatorVersion": GENERATOR_VERSION,
        "graphVersion": GRAPH_VERSION,
        "appVersion": APP_VERSION,
        "generatedAt": datetime.now(timezone.utc).isoformat(),
        "seed": args.seed,
        "requestedEpisodes": args.episodes,
        "ratios": {"train": args.train, "val": args.val, "test": args.test},
        "files": files,
        "stats": "stats.json",
        "graph": "../schema/app_graph.json",
    }
    (args.out / "manifest.json").write_text(
        json.dumps(manifest, indent=2) + "\n", encoding="utf-8")

    print(f"Generated {stats['episodes']} episodes / {stats['steps']} steps")
    print(f"Splits: {stats['splits']}")
    print(f"Goals: {len(stats['goals'])}  Screens: {stats['screenCoverage']}")
    print(f"Actions: {stats['actions']}")
    print(f"Output: {args.out.resolve()}")


if __name__ == "__main__":
    main()
