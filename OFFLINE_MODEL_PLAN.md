# GrowWithMe — Offline On-Device Risk Model Plan

Goal: an ML risk-scoring model that runs fully offline on the phone,
downloaded in the background after install (not bundled in the APK),
trained on the Maternal Health Risk dataset and progressively localized
to Northern Ghana / Tamale as we collect our own case data.

## Reality checks that shape this plan

1. **The dataset is tiny tabular data, not language/image data.**
   1,014 rows × 6 vitals (age, systolic BP, diastolic BP, blood sugar,
   body temp, heart rate) → low/mid/high risk. The right tool is a small
   gradient-boosted tree or a 2-layer MLP trained **from scratch** — no
   transfer learning needed, and no 3–7 MB "lightweight model" needed
   either. The final model is **50–500 KB** as TFLite. Smaller, faster,
   and more accurate for tabular data than any repurposed mini-net.

2. **One model, BOTH apps, tolerant of missing inputs.** The full six
   vitals need equipment (BP cuff, glucometer, thermometer) that a
   responder carries but a mother at home usually doesn't. Instead of
   two models, we train ONE that accepts any subset of inputs:
   - **Responder app**: nurse enters all six vitals at the patient's
     side → full-strength prediction.
   - **Caregiver app**: the mother enters what she has — age, home
     thermometer reading, and the BP recorded in her **ANC card** from
     her last clinic visit; blood sugar usually stays blank. The model
     still predicts, with honestly lower confidence shown in the UI.
   How: XGBoost treats missing values natively; for the MLP we train
   with random feature-masking + missingness-indicator inputs. The
   caregiver app keeps its deterministic WHO/GHS danger-sign rules
   engine (already fully offline) as the safety floor — the model is a
   second opinion on top, never a replacement.

3. **The model NEVER downgrades the rules.** Danger-sign rules are the
   safety floor: if rules say urgent, it is urgent regardless of what
   the model says. The model adds a second opinion and a risk
   probability, with the standard "AI can make mistakes" disclaimer.

4. **"Focus on Tamale" cannot come from documents.** A tabular
   classifier learns from labeled rows, not PDFs. Localization comes
   from logging real local cases (vitals + outcome) and periodically
   fine-tuning the trained base on them — that IS the transfer-learning
   step, and it becomes possible only after we collect local data.
   Our Ghana documents (GHS guidance) belong in the rules engine and in
   Nana's prompt, where they already are.

5. **Language features need a language model — and 3–7 MB is not
   enough.** Nana's chat, diet planning, tips and check-in
   personalization are language tasks; at 3–7 MB a language model
   produces dangerous nonsense. The smallest genuinely usable option
   is a ~1B-parameter model quantized to ~500 MB (see Tier 2 below) —
   offered as an optional Wi-Fi download, never bundled.

## AI capability inventory → offline parity plan

What the caregiver app's AI does today, and which tier covers it
offline:

| Capability                        | Offline today            | Covered by |
|-----------------------------------|--------------------------|------------|
| Health-check triage (danger signs)| ✅ rules engine           | Tier 0 (done) |
| Voice output / input              | ✅ device TTS / on-device STT | Tier 0 (done) |
| Understanding what she SAYS       | keyword matching only    | Tier 1.5 |
| Nana chat + 7 app actions         | keyword parser only      | Tier 1.5 (understand + curated replies) / Tier 2 (full conversation) |
| Personalized check-in questions   | fixed core only          | Tier 2 |
| Diet planner (incl. spoken input) | static library (Tier 1.5 adds spoken-input understanding) | Tier 2 |
| Daily personalized tips           | static library           | Tier 2 |
| Vitals risk scoring (NEW)         | —                        | Tier 1 |

**Tier 0 — already shipped.** The offline fallbacks that exist:
rules triage, intent parser, tip/meal libraries, device TTS, STT.
These stay as the floor beneath everything below.

**Tier 1 — vitals risk model (~200 KB).** This document's main plan:
tabular model on the Maternal Health Risk dataset, both apps,
missing-input tolerant. Small enough to download on any connection.

**Tier 1.5 — tiny NLU model (~5 MB): the transfer-learning play.**
This is where a genuinely small model earns its keep. Fine-tune a
BERT-tiny/MobileBERT-class encoder (4–25 MB int8) to CLASSIFY and
EXTRACT — never generate:
- input: whatever the caregiver says/types, in natural Ghanaian
  English (or code-mixed Twi/Dagbani phrasing);
- output: intent (one of Nana's actions / question types) + symptom
  tags + slots (budget, pantry items, child name, dates).
Replies then come from VETTED content only — the GHS-approved tip
library, first-aid steps, and fixed templates — so every word offline
Nana says is human-approved. No hallucination possible; for a health
app this is safer than generation.

Training data comes free via **distillation**: in Colab, prompt the
online backend LLM to generate a few thousand labeled caregiver
utterances in Northern-Ghana phrasing (plus real anonymized chat logs
once consented). Fine-tune the tiny encoder on that — the big model's
understanding compressed into ~5 MB. Ship through the same model
registry; upgrades `localIntent()` in `nana_assistant.dart` from
keyword matching to real language understanding, and gives the diet
planner offline spoken-input extraction.

**Tier 2 — "Nana Lite": on-device small LLM (optional, ~500 MB).**
A 1B-class open model (e.g. Gemma 3 1B int4) run on-device via
MediaPipe/flutter_gemma, LoRA-fine-tuned in Colab on:
- Nana's system prompt, persona and GHS/WHO trusted knowledge
  (THIS is where our Northern-Ghana documents genuinely train a model),
- the exact JSON reply format ({"say", "action"}) so the existing
  action pipeline works unchanged offline,
- Northern-Ghana foods/terms (TZ, koko, moringa, dawadawa, ayoyo).
Serving rules: optional download on Wi-Fi only ("Get offline Nana —
500 MB"); needs a mid-range phone (~2 GB free RAM); the deterministic
danger-sign keyword layer keeps running IN FRONT of it, so any symptom
mention still forces start_health_check no matter what the model says;
same confirmation flow before actions; same "AI can make mistakes"
banner. When online, the backend LLM always takes over (better).
Nana Lite also covers offline diet plans, tips and check-in follow-ups
— they are just prompts to the same model.

## Architecture

```
Colab (training)                     Backend                      Both apps
─────────────────                    ────────────────             ─────────────────
UCI dataset → clean/split            /api/v1/models/              On wifi/first run:
mask-augmented training         →    maternal-risk        →       GET manifest →
(handles missing inputs)             { version, url,              download .tflite
XGBoost + tiny MLP, pick best        sha256, size,                → verify sha256 →
calibrate probabilities              features, norms,             store locally.
export .tflite + manifest.json       thresholds }                 Offline: tflite_flutter
upload to Cloudinary                                              scores whatever
                                                                  vitals were entered.
                                                                  Responder: all 6.
                                                                  Caregiver: age, temp,
                                                                  ANC-card BP…
```

## Phase 1 — Train in Colab (one afternoon)

Notebook steps:
1. `pip install datasets xgboost scikit-learn tensorflow`
2. Load `BenchmarkDatasets/maternal_health_risk` (or the original UCI
   CSV — same data with named columns, easier to sanity-check).
3. EDA: class balance (~40/33/27), duplicate rows (the UCI set has
   many — deduplicate BEFORE splitting or accuracy is inflated),
   feature ranges for the normalization manifest.
4. Baselines: logistic regression → XGBoost → 2-layer MLP (Keras,
   12→32→16→3: six values + six "is-missing" flags). Augment training
   by randomly masking feature subsets (especially the
   caregiver-realistic pattern: BS/HR missing, BP present-but-stale)
   so the model learns to predict from partial vitals. Evaluate BOTH
   conditions: all-six (responder) and partial (caregiver).
   Report accuracy, macro-F1, and per-class recall —
   **recall on the high-risk class is the metric that matters**
   (missing a high-risk mother is the costly error). Expect ~80–90%
   accuracy; class-weight the loss toward high-risk recall.
5. Calibrate probabilities (temperature scaling / isotonic) so "78%
   high risk" means something.
6. Export: Keras → `.tflite` (post-training quantization, ~50–200 KB).
   If XGBoost wins, either distill it into the MLP or emit the trees as
   plain Dart (a 100-tree model is just if-statements — no runtime
   needed at all).
7. Write `manifest.json`: version, file sha256, byte size, ordered
   feature list, per-feature mean/std (or min/max), class labels,
   decision thresholds, "trained on: UCI MHR v1, local rows: 0".
8. Upload both to Cloudinary (raw resource type).

## Phase 2 — Backend model registry (~30 min)

- `GET /api/v1/models/maternal-risk` → returns the manifest
  (public URL, version, sha256). Env var or small `Model` collection
  holds the current version; bumping it rolls out a new model to every
  phone — no app release needed.

## Phase 3 — App integration (both apps, shared design)

- Add `tflite_flutter` to both apps; the download/inference code is
  identical (worth a tiny shared package or copy-paste module).
- `ModelService`: on app start with connectivity, compare local vs
  manifest version → background-download → sha256 check → atomic swap.
  Never blocks the UI; each app works without the model (feature stays
  hidden until the file exists).
- **Responder app** — alert detail gains "Assess vitals": all six
  inputs (sane ranges pre-validated), offline inference, shows
  low/mid/high + probability + which vitals drove it, plus the AI
  disclaimer. Result attaches to the alert timeline when back online.
- **Caregiver app** — health check gains an optional "Add measurements"
  step: every field skippable, with hints ("copy the BP from your ANC
  card", "use a thermometer if you have one"). Fewer inputs → the UI
  says so: "estimate based on 3 of 6 measurements". The rules-engine
  verdict always displays first and can only be RAISED by the model,
  never lowered. Urgent stays urgent.

## Phase 4 — Localize to Tamale (the real transfer learning)

- Every "Assess vitals" use logs (consented, de-identified) vitals +
  the case outcome (referred / treated / false alarm) to the backend.
- At ~200+ local rows: fine-tune the base MLP on local data (freeze
  first layer, low LR), validate against held-out local cases, bump
  manifest version. Repeat quarterly. Each cycle the model drifts from
  "Bangladesh clinical population" toward "Northern Ghana reality"
  (different anemia/malaria prevalence, age distribution, BP norms).

## Phase 5 — Nana Lite (Tier 2, after Tiers 0–1 ship)

1. **Colab**: build the fine-tuning set from what we already have —
   Nana's SYSTEM_PROMPT + the GHS/WHO knowledge blocks in
   `nanaService.js`, sample conversations (export real anonymized
   Nana chats once we have consent), diet-plan and tip examples in the
   exact JSON format. A few hundred to a few thousand examples.
2. LoRA-fine-tune Gemma 3 1B (free Colab T4 handles it), evaluate
   against a checklist: JSON validity, action correctness, danger-sign
   → start_health_check compliance, no invented doses.
3. Quantize to int4 (~500 MB), publish through the same model-registry
   manifest with `kind: "llm"`.
4. **App**: settings toggle "Download offline Nana (500 MB, Wi-Fi)";
   `nana_assistant.dart` gains a third path between backend-LLM and
   keyword parser: local LLM if the file exists. The deterministic
   symptom-keyword check runs BEFORE the model and overrides it.
5. Low-end phones without the RAM simply never show the toggle —
   they keep Tier 0 behavior.

## Demo story

Nurse accepts an alert in Tamale with no data connection → opens
Assess vitals → enters BP 145/95, BS 8.2, temp 99.5 → phone (airplane
mode!) returns "HIGH risk — 84%" in <50 ms → she refers immediately;
the assessment syncs into the case timeline when signal returns.
"The AI works where the network doesn't."
