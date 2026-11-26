#!/usr/bin/env python3
"""Deterministic story-map proposal generator (Rules 2-4 from ticket 249).

Reads `SmackAPad/Resources/Data/lessons-core.json` and
`SmackAPad/Resources/Data/electronic-path.json`, groups Path lessons into the
23 stages matching `LibraryCatalog` (excluding Intro lesson id=6 and any
genre-extension categories), orders each stage via `LibraryCatalog.orderStage`,
and proposes keystones and 2-3 option forks satisfying all equivalence rules.

Usage:
    python3 tools/story_map/generate.py > proposal.json
    python3 tools/story_map/generate.py --output path/to/proposal.json
    python3 tools/story_map/generate.py --summary
"""

from __future__ import annotations

import argparse
import json
from pathlib import Path
from typing import Any

REPO_ROOT = Path(__file__).resolve().parents[2]
CORE_PATH = REPO_ROOT / "SmackAPad" / "Resources" / "Data" / "lessons-core.json"
ELECTRONIC_PATH = REPO_ROOT / "SmackAPad" / "Resources" / "Data" / "electronic-path.json"

TECHNIQUES = ("groove", "sixteenths", "ghost", "swing", "fills")
EXTENSION_CATS = {"jersey", "footwork"}
WORLD_GENRES = {
    "Latin",
    "Afrobeat",
    "Afro-Cuban",
    "Highlife",
    "Reggae",
    "Reggaeton",
    "Middle Eastern",
    "Moombahton",
}


def classify_technique(lesson: dict[str, Any]) -> str:
    tags = set(lesson.get("tags", []))
    if "toms" in tags or lesson["cat"] == "fills":
        return "fills"
    if "triplet feel" in tags or lesson["division"] == 12:
        return "swing"
    if "ghost notes" in tags:
        return "ghost"
    if "16ths" in tags:
        return "sixteenths"
    return "groove"


def classify_genre(lesson: dict[str, Any]) -> str:
    genre = lesson.get("genre", "")
    if genre in ("Rock", "Punk"):
        return "rock"
    if genre in ("Funk", "Soul", "Gospel", "Blues"):
        return "funk"
    if genre in ("Jazz", "New Orleans"):
        return "jazz"
    if genre in ("Hip hop", "Trap", "Lo-fi", "Trip hop"):
        return "hiphop"
    if genre in WORLD_GENRES:
        return "world"
    if genre in ("Pop", "Country"):
        return "pop"
    return "electronic"


def order_stage(lessons: list[dict[str, Any]]) -> list[dict[str, Any]]:
    """Matches `LibraryCatalog.orderStage` for Path (non-intro) lessons."""
    genres: list[str] = []
    queues: dict[str, list[dict[str, Any]]] = {}
    for lesson in lessons:
        if lesson.get("cat") == "intro":
            continue
        genre_key = classify_genre(lesson)
        if genre_key not in queues:
            genres.append(genre_key)
            queues[genre_key] = []
        queues[genre_key].append(lesson)

    ordered: list[dict[str, Any]] = []
    max_len = max((len(queue) for queue in queues.values()), default=0)
    for idx in range(max_len):
        for genre_key in genres:
            queue = queues[genre_key]
            if idx < len(queue):
                ordered.append(queue[idx])
    return ordered


def are_equivalent(a: dict[str, Any], b: dict[str, Any]) -> bool:
    """Checks Rule 4 hard equivalence constraints between two lessons."""
    if a["division"] != b["division"]:
        return False
    if a["bars"] != b["bars"]:
        return False
    bpm_min = min(a["targetBpm"], b["targetBpm"])
    bpm_max = max(a["targetBpm"], b["targetBpm"])
    if bpm_max * 10 > bpm_min * 11:
        return False
    hits_min = min(len(a["hits"]), len(b["hits"]))
    hits_max = max(len(a["hits"]), len(b["hits"]))
    if hits_max * 4 > hits_min * 5:
        return False
    return True


def pair_score(a: dict[str, Any], b: dict[str, Any], distance: int) -> float:
    """Scores an equivalent candidate pair; higher is better."""
    score = 0.0
    if a["genre"] == b["genre"]:
        score += 100.0
    elif classify_genre(a) == classify_genre(b):
        score += 50.0

    # Reward shared feel/instrumentation tags while ignoring stage-wide tags.
    ignored = {"16ths", "2 bars", "triplet feel", "ghost notes"}
    tags_a = set(a.get("tags", [])) - ignored
    tags_b = set(b.get("tags", [])) - ignored
    score += 10.0 * len(tags_a & tags_b)

    # Prefer staying close to `LibraryCatalog.orderStage` order and close tempo/density.
    score -= 3.0 * distance
    bpm_min = max(1, min(a["targetBpm"], b["targetBpm"]))
    score -= 50.0 * abs(a["targetBpm"] - b["targetBpm"]) / bpm_min
    hits_min = max(1, min(len(a["hits"]), len(b["hits"])))
    score -= 30.0 * abs(len(a["hits"]) - len(b["hits"])) / hits_min
    return score


def propose_stage(ordered: list[dict[str, Any]], window: int = 12) -> list[dict[str, Any]]:
    """Builds ordered keystone/fork nodes for one stage."""
    n = len(ordered)
    if n < 4:
        return [{"keystone": lesson["id"]} for lesson in ordered]

    target_forks = (n - 1) // 3
    extra_slots = (n - 1) - 3 * target_forks
    used = [False] * n
    nodes: list[dict[str, Any]] = [{"keystone": ordered[0]["id"]}]
    used[0] = True

    forks_made = 0
    triples_budget = extra_slots
    need_keystone = False
    idx = 1

    # Reserve ordered[n - 1] so the stage always ends with a keystone.
    while idx < n - 1:
        if used[idx]:
            idx += 1
            continue
        if need_keystone or forks_made >= target_forks:
            nodes.append({"keystone": ordered[idx]["id"]})
            used[idx] = True
            need_keystone = False
            idx += 1
            continue

        best_partner = None
        best_score = -1e9
        for j in range(idx + 1, min(n - 1, idx + window + 1)):
            if used[j]:
                continue
            if are_equivalent(ordered[idx], ordered[j]):
                score = pair_score(ordered[idx], ordered[j], j - idx)
                if score > best_score:
                    best_score = score
                    best_partner = j

        if best_partner is None:
            nodes.append({"keystone": ordered[idx]["id"]})
            used[idx] = True
            need_keystone = False
            idx += 1
            continue

        fork_indices = [idx, best_partner]
        used[idx] = True
        used[best_partner] = True

        if triples_budget > 0:
            best_third = None
            best_third_score = -1e9
            for k in range(idx + 1, min(n - 1, best_partner + 8)):
                if used[k]:
                    continue
                if are_equivalent(ordered[idx], ordered[k]) and are_equivalent(
                    ordered[best_partner], ordered[k]
                ):
                    if classify_genre(ordered[idx]) == classify_genre(ordered[k]) or (
                        classify_genre(ordered[best_partner]) == classify_genre(ordered[k])
                    ):
                        score3 = pair_score(ordered[idx], ordered[k], k - idx)
                        if score3 > best_third_score:
                            best_third_score = score3
                            best_third = k
            if best_third is not None:
                fork_indices.append(best_third)
                used[best_third] = True
                triples_budget -= 1

        nodes.append({"fork": [ordered[pos]["id"] for pos in fork_indices]})
        forks_made += 1
        need_keystone = True
        idx += 1

    if not used[n - 1]:
        nodes.append({"keystone": ordered[n - 1]["id"]})
        used[n - 1] = True

    return nodes


def load_path_lessons() -> list[dict[str, Any]]:
    core = json.loads(CORE_PATH.read_text(encoding="utf-8"))["lessons"]
    electronic = json.loads(ELECTRONIC_PATH.read_text(encoding="utf-8"))
    combined = core + electronic
    return [
        lesson
        for lesson in combined
        if lesson["id"] != 6
        and lesson["cat"] != "intro"
        and lesson["cat"] not in EXTENSION_CATS
    ]


def build_proposal() -> dict[str, list[dict[str, Any]]]:
    lessons = load_path_lessons()
    story_map: dict[str, list[dict[str, Any]]] = {}
    for level in range(1, 6):
        for tech in TECHNIQUES:
            if level >= 4 and tech == "groove":
                continue
            members = [
                lesson
                for lesson in lessons
                if lesson["level"] == level and classify_technique(lesson) == tech
            ]
            if not members:
                continue
            stage_id = f"L{level}-{tech}"
            ordered = order_stage(members)
            story_map[stage_id] = propose_stage(ordered)
    return story_map


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--output",
        type=Path,
        default=None,
        help="Optional file path to write the proposal JSON instead of stdout.",
    )
    parser.add_argument(
        "--summary",
        action="store_true",
        help="Print per-stage keystone and fork counts to stdout.",
    )
    args = parser.parse_args()

    proposal = build_proposal()

    if args.summary:
        for stage_id, nodes in proposal.items():
            keystones = sum(1 for node in nodes if "keystone" in node)
            forks = sum(1 for node in nodes if "fork" in node)
            lessons_count = sum(
                1 if "keystone" in node else len(node["fork"]) for node in nodes
            )
            print(f"{stage_id}: {lessons_count} lessons -> {keystones} keystones, {forks} forks")
        return

    rendered = json.dumps(proposal, indent=2) + "\n"
    if args.output is not None:
        args.output.write_text(rendered, encoding="utf-8")
    else:
        print(rendered, end="")


if __name__ == "__main__":
    main()
