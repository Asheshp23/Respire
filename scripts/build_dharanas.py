#!/usr/bin/env python3
"""
Builds Respire/Content/Dharanas/112-gates.dharanas.json from the source synthesis
in scripts/dharanas_source.txt (section headers like "I. Title (Dharanas 1–12)"
followed by "n. Title: practice" lines, numbered per section).

Dharanas are renumbered 1–112 globally. Each section gets a world, focus, and
rhythm for practicing in the app; a few gates get a gentle safety caution.

Run from the repository root:  python3 scripts/build_dharanas.py
"""
import json
import re
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
SOURCE = ROOT / "scripts" / "dharanas_source.txt"
OUTPUT = ROOT / "Respire" / "Content" / "Dharanas" / "112-gates.dharanas.json"

# numeral: (id, subtitle, world, focus, (inhale, holdFull, exhale, holdEmpty), minutes)
SECTIONS = {
    "I":    ("breath-and-neural-pacing", "Pacing the nervous system to the speed of breath, not the machine", "aurora", "calmAnxiety", (4, 2, 6, 2), 3),
    "II":   ("sensory-deprogramming", "Unlearning the screen and returning to raw sensation", "sakura", "focus", (4, 0, 6, 0), 3),
    "III":  ("digital-void", "The open space beneath thought, data, and prompts", "desert", "focus", (4, 1, 6, 2), 3),
    "IV":   ("emotion-and-dopamine", "Meeting urgency, outrage, and desire as sensation", "volcano", "calmAnxiety", (4, 0, 8, 0), 3),
    "V":    ("inner-sound", "Sound and vibration as doorways to stillness", "rain", "calmAnxiety", (4, 0, 6, 0), 4),
    "VI":   ("somatic-grounding", "Coming back to weight, bone, breath, and skin", "wind", "calmAnxiety", (4, 1, 6, 1), 4),
    "VII":  ("consciousness-and-machine", "The awareness that watches all the processing", "thunder", "focus", (5, 2, 5, 2), 4),
    "VIII": ("sleep-and-transitions", "Thresholds of waking, sleeping, and switching", "ocean", "windDown", (4, 7, 8, 0), 5),
    "IX":   ("nondual-integration", "One field: the screen, the room, the heart", "waterfall", "focus", (5, 2, 6, 2), 5),
}

# Gentle cautions where a practice asks the body for something specific.
CAUTIONS = {
    2: "Hold only while it stays easy and the throat stays soft. Skip breath holds if you're pregnant or have heart, lung, or blood-pressure concerns.",
    3: "Lengthen the exhale only as far as feels comfortable; there's no need to strain toward exactly double.",
    49: "Press the ear openings closed lightly, never into the ear canal, and stop if anything feels uncomfortable.",
    50: "Keep the sound soft and let it end whenever the breath runs out.",
    66: "If floating sensations ever feel unsettling, open your eyes and feel your feet on the floor.",
    85: "Practice somewhere safe to rest, never while driving or moving.",
    86: "Practice somewhere safe to rest, never while driving or moving.",
    94: "Lie somewhere safe and comfortable before you begin.",
}

GLOSSARY = [
    ("Dharana", "A way of placing attention; each one is a “gate” into awareness.", ["dharana"]),
    ("Kumbhaka", "A natural pause or gentle hold of the breath.", ["kumbhaka"]),
    ("Prana", "The felt sense of aliveness and breath moving through the body.", ["prana", "pranic"]),
    ("Anahata", "The heart center; also the “unstruck” sound heard in silence.", ["anahata"]),
    ("AUM", "A traditional sound, hummed to feel vibration in the chest and skull.", ["aum"]),
    ("Mantra", "A sound or phrase repeated to steady attention.", ["mantra"]),
    ("Third eye", "The space between the eyebrows, used as a point of attention.", ["third eye"]),
    ("Bhairava", "In the text, the vast awareness at the heart of all experience.", ["bhairava"]),
    ("Lila", "Play: the world seen as a spontaneous, playful expression.", ["lila"]),
    ("Svarupa", "One's own essential nature.", ["svarupa"]),
    ("Ananda", "The quiet joy of simply being.", ["ananda"]),
    ("Soham", "“I am that”, a phrase traditionally heard in the sound of the breath.", ["soham"]),
    ("Nondual", "Not two: no final separation between the one who knows and what is known.", ["nondual"]),
]

ATTRIBUTION = (
    "A contemporary synthesis of the Vijñāna Bhairava Tantra, drawing on the traditional Kashmir "
    "Shaivism of Swami Lakshmanjoo, the scholarship of Jaideva Singh, Osho’s psychological "
    "adaptations, Lorin Roche’s sensory poetry, and modern nondual inquiry, reinterpreted for the "
    "era of AI, digital saturation, and synthetic intelligence."
)


def build():
    sections, current, number = [], None, 0
    for line in SOURCE.read_text(encoding="utf-8").splitlines():
        line = line.strip()
        if not line:
            continue
        header = re.match(r"^([IVX]+)\. (.+?) \(Dharanas (\d+)[–-](\d+)\)$", line)
        if header:
            numeral, title, first, _ = header.groups()
            sid, subtitle, world, focus, rhythm, minutes = SECTIONS[numeral]
            assert number == int(first) - 1, f"section {numeral} starts at {first}, expected {number + 1}"
            current = {
                "id": sid, "numeral": numeral, "title": title, "subtitle": subtitle,
                "world": world, "focus": focus,
                "practice": dict(zip(["inhale", "holdFull", "exhale", "holdEmpty"], rhythm), minutes=minutes),
                "dharanas": [],
            }
            sections.append(current)
            continue
        item = re.match(r"^\d+\. (.+?): (.+)$", line)
        assert item and current is not None, f"unrecognized line: {line}"
        number += 1
        dharana = {"number": number, "title": item.group(1), "text": item.group(2)}
        if number in CAUTIONS:
            dharana["caution"] = CAUTIONS[number]
        current["dharanas"].append(dharana)

    assert number == 112, f"expected 112 dharanas, found {number}"
    return {
        "schemaVersion": 1,
        "id": "112-gates",
        "title": "112 Gates",
        "subtitle": "Dharanas for an age of screens and synthetic minds",
        "attribution": ATTRIBUTION,
        "glossary": [{"term": t, "meaning": m, "matches": k} for t, m, k in GLOSSARY],
        "sections": sections,
    }


if __name__ == "__main__":
    collection = build()
    OUTPUT.parent.mkdir(parents=True, exist_ok=True)
    OUTPUT.write_text(json.dumps(collection, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    counts = [len(s["dharanas"]) for s in collection["sections"]]
    print(f"wrote {OUTPUT.relative_to(ROOT)}: {len(counts)} sections {counts}, {sum(counts)} dharanas")
