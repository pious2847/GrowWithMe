# GrowWithMe Action Model Dataset

Training corpus for **Nana Actions** — the policy that navigates GrowWithMe and performs phone-level actions (call a clinic, message a CHW, share location, set an alarm) on the caregiver's behalf.

This directory is self-contained, reproducible, and **privacy-safe by construction**: every name, phone number, and health value is synthetic. No consented production data is required to bootstrap the model.

```
ml/action_model/
├── graph.py                    # screens, elements, goals — mirrors the Flutter app
├── generate_dataset.py         # persona-aware episode generator
├── validate_dataset.py         # schema + split-leakage + coverage checks
├── evaluate_baseline.py        # majority-class sanity baseline
├── schema/
│   ├── action_trajectory.schema.json
│   └── app_graph.json          # generated from graph.py
└── dataset/
    ├── train.jsonl             # 963 episodes / 4,337 steps
    ├── val.jsonl               # 122 episodes
    ├── test.jsonl              # 115 episodes
    ├── stats.json              # distributions and coverage
    ├── baseline_metrics.json
    └── manifest.json           # seed, versions, SHA-256 per file
```

Sample corpus: **1,200 episodes / 5,400 steps / 35 goals / 34 screens / 13 action types / 7.3 MB**. Regenerate at any scale.

## Quick start

```bash
cd ml/action_model
python3 generate_dataset.py --episodes 1200          # sample included in repo
python3 generate_dataset.py --episodes 60000 --out dataset_full --seed 7
python3 validate_dataset.py --dir dataset
python3 evaluate_baseline.py --dir dataset
```

Only the Python standard library is required. With no real usage data, this corpus is enough to pre-train a policy; consented telemetry then fine-tunes it.

## Episode format

One JSON object per line. An episode is a goal, the observations the caregiver saw, and the actions she took.

```json
{
  "episodeId": "gwm-health_check-first_time_mother-GH-123456-00003",
  "persona": "first_time_mother",
  "country": "GH", "locale": "en-GH", "language": "en",
  "goal": "health_check",
  "intents": ["My child is sick", "Check danger signs"],
  "startScreen": "home", "finalScreen": "assessment.questions",
  "outcome": {"completed": true, "success": true, "stepCount": 6, "durationMs": 9300},
  "split": "train",
  "steps": [{
    "stepId": 1,
    "observation": {
      "screen": "home",
      "elements": [
        {"id": "home.quick.health_check", "label": "Health check", "kind": "button",
         "box": [0.04, 0.40, 0.44, 0.075]}
      ],
      "scrolled": false,
      "state": {"country": "GH", "language": "en", "childCount": 1,
                "pregnant": false, "offline": false, "firstRun": false},
      "stepIndex": 0
    },
    "action": {"type": "tap", "target": "home.quick.health_check",
               "coords": [0.261, 0.438]},
    "outcome": {"success": true, "nextScreen": "assessment.picker"},
    "durationMs": 1420
  }]
}
```

The full JSON Schema is in [`schema/action_trajectory.schema.json`](schema/action_trajectory.schema.json).

### Observation

| Field | Meaning |
| --- | --- |
| `screen` / `screenTitle` | Stable screen id, same vocabulary as `ActionLogger` |
| `elements[]` | What is visible above the fold: `id`, `label`, `kind`, normalized `box` |
| `scrollable` / `scrolled` | Whether the screen has content below the fold and whether she has scrolled |
| `state` | Country, language, child count, pregnancy, offline/network, first run, consent |
| `stepIndex` | Position in the episode |

### Action space (13)

`tap`, `long_press`, `swipe`, `scroll`, `back`, `type`, `speak` (voice input), `toggle`, `call`, `send_sms`, `set_alarm`, `share_location`, `open_app`.

- UI actions carry `target` (an element id from the observation) and normalized `coords`.
- `type` and `speak` carry `value` + `valueKind`; values are synthetic samples.
- Device actions carry `value` (e.g. the regional emergency number) and still record the UI control that triggered them, so the policy learns *when* to escalate, not just how.
- A failed step (`outcome.success: false`, e.g. `empty_required_field`) is followed by the corrected retry — the model sees recovery behaviour, not only perfect paths.

## Personas and distribution

| Persona | Behaviour |
| --- | --- |
| `first_time_mother` | Explores, mis-taps, backtracks, slower |
| `experienced_mother` | Direct paths, fast |
| `low_literacy_caregiver` | Voice-first, listens aloud, avoids typing |
| `community_health_worker` | Rapid multi-child workflows |
| `high_risk_pregnancy` | Prioritises checks, vitals, escalation |
| `diaspora_supporter` | Longer sessions, sharing |
| `multilingual_caregiver` | Local-language fallback flows |

Countries: **GH, NG, KE, UG, TZ**, with locale, dial code, emergency number and local place names. Everyday goals (health check, Nana chat, calendar, meals, check-ins) dominate; onboarding, emergencies and device actions are represented in every split.

Distractors are intentional: personas with an `explore` rate wander into a neighbouring screen and come back, and targets below the fold require a `scroll`. That is why a per-screen majority baseline only reaches ~38% target accuracy — the corpus is not a lookup table.

## Splits

Splits are assigned **per goal, per episode**, so no trajectory (and no near-duplicate trajectory) crosses train/val/test. `validate_dataset.py` fails if an `episodeId` appears in more than one split.

Current sample: **963 train / 122 val / 115 test**, all 35 goals and all 13 action types present. `dataset/manifest.json` records the seed, generator/graph/app versions, and a SHA-256 for each file.

## Training recipe

The intended production model is a small, goal-conditioned sequence policy that runs on-device (Android NNAPI / TFLite, iOS Core ML):

1. **Observation encoder** — embed `screen` + each visible element (`id`, `label`, `kind`, `box`) and the state vector. Reuse the same vocabulary at runtime from the accessibility tree / widget registry.
2. **Goal encoder** — embed the user's intent (text from Nana, or a structured goal id) so one model covers every task.
3. **Policy head** — classify the action type, classify the target element, regress `coords` for thumb reach. Sequence context (previous 4–8 steps) matters: the same home screen leads to different next taps depending on the goal.
4. **Auxiliary heads** — next-screen prediction and success prediction improve representation quality and give the runtime a confidence signal.
5. **Safety gate** — device actions (`call`, `send_sms`, `share_location`) always render a one-tap confirmation. Never auto-send health content; never log free text.

Recommended objective: behaviour cloning with class-balanced sampling by `goal` × `screen`, plus an auxiliary next-screen loss. Evaluate target top-1 and full-episode success — not action-type accuracy alone.

## From corpus to production

The app already logs consented, metadata-only interactions (`lib/data/action/action_logger.dart`): screen id, action, target, coarse flags, duration. Events are queued offline and batched to `POST /api/v1/actions/events`.

```
synthetic pre-train  →  ship as Nana Actions (opt-in)
        ↑                         ↓
  weekly merge  ←  consented production trajectories (ActionEvent)
```

Production data must be de-identified, aggregated per session, and reviewed before it enters a training split. Keep the synthetic corpus as the seed and the regression suite: a new app screen is added to `graph.py`, the corpus is regenerated, and the policy is retrained before release.

## Extending

- **New screen/control:** add it to `SCREENS` in `graph.py`, add a goal in `GOALS`, regenerate, validate.
- **New locale/country:** extend `COUNTRIES` (locale, dial, emergency, languages, districts).
- **New device intent:** add the control to `DEVICE_INTENTS`, extend the action enum in the schema and the app's intent bridge.
- **New noise model:** adjust `PERSONAS` (error/explore/voice/delay) or add a persona; keep it in `stats.json` for reproducibility.

## Limitations

- Synthetic trajectories capture **structure**, not real pixels. Pair this corpus with the app's accessibility/UI-tree encoder; add a vision encoder later from consented screenshots if ever approved.
- Human intent language is templated. Real Nana chat text (consented) should be mixed in for the intent encoder.
- Phone-level surfaces (`device.dialer`, `device.sms`, `device.alarm`, `device.share`) are simplified stand-ins for Android system apps.
- The corpus is a bootstrap and evaluation harness, not a replacement for measured field behaviour. Every shipped policy must be shadow-tested against real sessions before it is allowed to act.

## Privacy

All values are generated. There is no real name, phone number, location, or health record in this directory. The app's own telemetry is explicitly opt-in, metadata-only (allow-listed keys on the server), and never includes chat text, form values, or symptom answers. See `backend/src/controllers/actionController.js` and `lib/features/settings/settings_screen.dart`.
