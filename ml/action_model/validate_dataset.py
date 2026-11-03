#!/usr/bin/env python3
"""Schema + integrity checks for a generated GrowWithMe action corpus.

Fails loudly on: missing fields, coordinates outside [0,1], action targets
that were not visible in the observation, split leakage (an episode appearing
in more than one split), manifest/file mismatches, and empty splits.

    python3 validate_dataset.py                # validates ./dataset
    python3 validate_dataset.py --dir dataset_full
"""

from __future__ import annotations

import argparse
import json
from pathlib import Path

from graph import SCREENS, build_graph

ACTION_SPACE = set(build_graph()["actionSpace"])
REQUIRED_EPISODE = {
    "episodeId", "persona", "country", "locale", "language", "goal",
    "startScreen", "finalScreen", "outcome", "steps", "split",
}
REQUIRED_STEP = {"stepId", "observation", "action", "outcome", "durationMs"}
COORD_ACTIONS = {"tap", "type", "toggle", "long_press", "open_app", "call",
                 "send_sms", "share_location", "set_alarm", "speak"}


def load_jsonl(path: Path) -> list[dict]:
    episodes = []
    with path.open(encoding="utf-8") as f:
        for lineno, line in enumerate(f, 1):
            line = line.strip()
            if not line:
                continue
            try:
                episodes.append(json.loads(line))
            except json.JSONDecodeError as e:
                raise SystemExit(f"{path.name}:{lineno}: invalid JSON: {e}")
    return episodes


def check_coords(value, where: str, errors: list[str]) -> None:
    if value is None:
        return
    if isinstance(value, list) and value and isinstance(value[0], list):
        for point in value:
            check_coords(point, where, errors)
        return
    if not (isinstance(value, list) and len(value) == 2):
        errors.append(f"{where}: coords must be [x, y]")
        return
    for n in value:
        if not isinstance(n, (int, float)) or not 0.0 <= n <= 1.0:
            errors.append(f"{where}: coord {n!r} outside [0,1]")


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--dir", type=Path,
                        default=Path(__file__).parent / "dataset")
    args = parser.parse_args()
    root: Path = args.dir

    errors: list[str] = []
    manifest_path = root / "manifest.json"
    if not manifest_path.exists():
        raise SystemExit(f"missing {manifest_path}")
    manifest = json.loads(manifest_path.read_text(encoding="utf-8"))

    seen_ids: dict[str, str] = {}
    split_episodes: dict[str, list[dict]] = {}
    all_actions: set[str] = set()
    goals_seen: set[str] = set()
    screens_seen: set[str] = set()

    for split in ("train", "val", "test"):
        path = root / f"{split}.jsonl"
        if not path.exists():
            errors.append(f"missing split file {path.name}")
            continue
        episodes = load_jsonl(path)
        split_episodes[split] = episodes
        expected = manifest["files"].get(split, {}).get("episodes")
        if expected is not None and expected != len(episodes):
            errors.append(
                f"{split}: manifest says {expected} episodes, file has {len(episodes)}")
        if not episodes:
            errors.append(f"{split}: split is empty")

        for ep in episodes:
            eid = ep.get("episodeId", "<missing>")
            missing = REQUIRED_EPISODE - set(ep)
            if missing:
                errors.append(f"{eid}: missing episode fields {sorted(missing)}")
                continue
            if eid in seen_ids:
                errors.append(f"{eid}: appears in both {seen_ids[eid]} and {split}")
            seen_ids[eid] = split
            if ep["split"] != split:
                errors.append(f"{eid}: split field {ep['split']} != file {split}")
            goals_seen.add(ep["goal"])
            screens_seen.add(ep["startScreen"])

            steps = ep["steps"]
            if not steps:
                errors.append(f"{eid}: no steps")
                continue
            if ep["outcome"].get("stepCount") != len(steps):
                errors.append(f"{eid}: outcome.stepCount mismatch")
            if ep["finalScreen"] != steps[-1]["outcome"]["nextScreen"]:
                errors.append(f"{eid}: finalScreen mismatch")

            for step in steps:
                where = f"{eid}/step{step.get('stepId')}"
                missing = REQUIRED_STEP - set(step)
                if missing:
                    errors.append(f"{where}: missing step fields {sorted(missing)}")
                    continue
                obs = step["observation"]
                act = step["action"]
                out = step["outcome"]
                screen = obs.get("screen")
                if screen not in SCREENS:
                    errors.append(f"{where}: unknown screen {screen!r}")
                else:
                    screens_seen.add(screen)
                action_type = act.get("type")
                all_actions.add(action_type)
                if action_type not in ACTION_SPACE:
                    errors.append(f"{where}: action {action_type!r} not in action space")
                if not isinstance(step["durationMs"], int) or step["durationMs"] < 0:
                    errors.append(f"{where}: bad durationMs")
                if not isinstance(out.get("success"), bool):
                    errors.append(f"{where}: outcome.success must be bool")
                if out.get("nextScreen") not in SCREENS:
                    errors.append(f"{where}: bad nextScreen {out.get('nextScreen')!r}")

                if action_type in COORD_ACTIONS and "coords" in act:
                    check_coords(act.get("coords"), where, errors)

                target = act.get("target")
                if target:
                    visible = {e["id"] for e in obs.get("elements", [])}
                    if target not in visible:
                        errors.append(
                            f"{where}: target {target!r} not visible on {screen}")
                if action_type == "type":
                    if "value" not in act or "valueKind" not in act:
                        errors.append(f"{where}: type action needs value/valueKind")

    # Graph coverage report (not fatal, but useful in CI logs).
    graph_goals = set(build_graph()["goals"])
    missing_goals = graph_goals - goals_seen
    missing_actions = ACTION_SPACE - all_actions
    unreached = set(SCREENS) - screens_seen

    if errors:
        print(f"FAILED with {len(errors)} error(s):")
        for e in errors[:40]:
            print(" -", e)
        if len(errors) > 40:
            print(f" ... and {len(errors) - 40} more")
        raise SystemExit(1)

    total_steps = sum(len(e["steps"]) for eps in split_episodes.values() for e in eps)
    print("OK")
    print(f"  episodes: {len(seen_ids)}  steps: {total_steps}")
    print(f"  splits: " + ", ".join(
        f"{k}={len(v)}" for k, v in split_episodes.items()))
    print(f"  goals: {len(goals_seen)}/{len(graph_goals)}")
    print(f"  actions: {len(all_actions)}/{len(ACTION_SPACE)}")
    if missing_goals:
        print(f"  goals without episodes: {sorted(missing_goals)}")
    if missing_actions:
        print(f"  actions without episodes: {sorted(missing_actions)}")
    if unreached:
        print(f"  screens never observed: {sorted(unreached)}")


if __name__ == "__main__":
    main()
