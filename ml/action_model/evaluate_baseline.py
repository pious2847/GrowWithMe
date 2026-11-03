#!/usr/bin/env python3
"""Split-safe sanity baseline for the generated action corpus.

If a screen -> majority-target lookup already scores unreasonably high, the
corpus is leaking the plan (a real behavioural-cloning model would learn
nothing). If it scores near zero, the data is noise. This prints both, plus
an action-type baseline, and writes baseline_metrics.json next to the corpus.

Pure stdlib so it runs anywhere; a neural policy should beat these numbers.
"""

from __future__ import annotations

import argparse
import json
from collections import Counter, defaultdict
from pathlib import Path


def load(path: Path) -> list[dict]:
    episodes = []
    with path.open(encoding="utf-8") as f:
        for line in f:
            line = line.strip()
            if line:
                episodes.append(json.loads(line))
    return episodes


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--dir", type=Path,
                        default=Path(__file__).parent / "dataset")
    args = parser.parse_args()

    train = load(args.dir / "train.jsonl")
    test = load(args.dir / "test.jsonl")
    if not test:
        test = load(args.dir / "val.jsonl")
    if not train or not test:
        raise SystemExit("train and test/val splits are required")

    type_by_screen: dict[str, Counter] = defaultdict(Counter)
    target_by_screen: dict[str, Counter] = defaultdict(Counter)
    next_by_screen_action: dict[tuple[str, str], Counter] = defaultdict(Counter)

    for ep in train:
        for s in ep["steps"]:
            screen = s["observation"]["screen"]
            act = s["action"]
            type_by_screen[screen][act["type"]] += 1
            if act.get("target"):
                target_by_screen[screen][act["target"]] += 1
            nxt = s["outcome"]["nextScreen"]
            next_by_screen_action[(screen, act["type"])][nxt] += 1

    total = 0
    type_hits = 0
    target_total = 0
    target_hits = 0
    next_hits = 0
    success_steps = 0

    for ep in test:
        for s in ep["steps"]:
            screen = s["observation"]["screen"]
            act = s["action"]
            total += 1
            if s["outcome"]["success"]:
                success_steps += 1

            if type_by_screen[screen]:
                pred = type_by_screen[screen].most_common(1)[0][0]
                if pred == act["type"]:
                    type_hits += 1

            if act.get("target"):
                target_total += 1
                pred_t = (target_by_screen[screen].most_common(1)[0][0]
                          if target_by_screen[screen] else None)
                if pred_t == act["target"]:
                    target_hits += 1

            ctx = next_by_screen_action.get((screen, act["type"]))
            if ctx:
                pred_n = ctx.most_common(1)[0][0]
                if pred_n == s["outcome"]["nextScreen"]:
                    next_hits += 1

    metrics = {
        "trainEpisodes": len(train),
        "testEpisodes": len(test),
        "testSteps": total,
        "actionTypeAccuracy": round(type_hits / total, 4) if total else 0,
        "targetTop1Accuracy": round(target_hits / target_total, 4) if target_total else 0,
        "nextScreenAccuracy": round(next_hits / total, 4) if total else 0,
        "testStepSuccessRate": round(success_steps / total, 4) if total else 0,
        "baseline": "per-screen majority class (no context, no history)",
    }
    out = args.dir / "baseline_metrics.json"
    out.write_text(json.dumps(metrics, indent=2) + "\n", encoding="utf-8")

    print(json.dumps(metrics, indent=2))
    print(f"wrote {out}")


if __name__ == "__main__":
    main()
