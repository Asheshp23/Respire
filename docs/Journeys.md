# Journeys — Product Specification

Journeys are short, guided sequences of daily practices. Each one is built around a single
"awareness gate", a simple way of placing attention, adapted from the *Vijñāna Bhairava*.
That contemplative text, more than a thousand years old, offers 112 brief ways of noticing
ordinary experience: the turn of the breath, sound, sensation, space.

Journeys keep the spirit of those practices (attention to the plain, felt moment) and tell
each gate as a sensory invitation through everyday images: a swing at the top of its arc,
still water after a ripple, a candle bending in faint air. The 112 Gates library presents the
full contemporary synthesis, tradition and all, with every traditional term explained plainly.

Five Journeys ship today, each five days long:

| # | Journey | Drawn from | Gates |
| --- | --- | --- | --- |
| 1 | **The Space Between Breaths** | The turning points of the breath | (written for the app) |
| 2 | **The Unprompted Mind** | AI-era gates across sections | 1, 26, 23, 37, 36 |
| 3 | **Listening as an Anchor** | V. Inner Sound, Resonance & Vibration | 51, 58, 56, 57, 60 |
| 4 | **Coming Home to the Body** | VI. Somatic Grounding in the Machine Age | 61, 67, 69, 70, 72 |
| 5 | **Digital Twilight** | VIII. Sleep, Transitions & Digital Twilight | 92, 85, 94, 86, 87 |

All draw on the **112 Gates**, the full library of dharanas (section 7). A chapter's `gate`
field names its source; that gate is woven into the personal opening before its practice.

---

## 1. Principles

| Principle | What it means in practice |
| --- | --- |
| **Sensory first, tradition glossed** | Lead with what can be felt: coolness, weight, stillness, sound. Traditional words (Kumbhaka, Prana, Soham…) may appear in the 112 Gates, always with a plain-language gloss beside them; journey cards stay in everyday language. No promises of awakening or health outcomes. |
| **Gentle cadence** | One new gate per calendar day. Depth comes from repetition and rest, not speed. |
| **Never punitive** | No streaks to lose and no "missed day" states. Pausing for a week just means the next gate is waiting. |
| **Always revisitable** | A completed day can be opened and practiced again at any time. |
| **Honest origins** | Name the source respectfully once ("inspired by"), without claiming to translate or teach it. |
| **Safe breathing** | Pauses are loose, never forced. Every card that asks for a longer pause also says "breathe whenever you need to." |

---

## 2. Structure

```
Journey ─┬─ origin (shown once, on the first day)
         └─ chapters (one per day)
               ├─ cards        story cards, read in order (image → notice → practice)
               ├─ practice     rhythm, length, world, focus, guiding line
               ├─ reflection   one question to carry afterward
               └─ completion   what's said when the day is done
```

**Card kinds**

| Kind | Purpose | Visual |
| --- | --- | --- |
| `origin` | Where the practice comes from. Day 1 only. | The chapter's world at rest |
| `image` | A metaphor drawn from nature or everyday life. | The world at the openness the image evokes (e.g. `1.0` for the top of a breath) |
| `notice` | The felt instruction, plus a short `cue` the person can repeat silently. | The world at mid-breath |
| `practice` | What happens next: rhythm, minutes, where. Always the last card. | A live breath line, plus **Begin practice** |

---

## 3. Progression

### Chapter states

| State | Shown as | Tappable | Condition |
| --- | --- | --- | --- |
| **Completed** | Filled prism node with a check | Yes, practice again | A practice session for this day was finished |
| **Available** | Ink node with a slowly breathing halo | Yes | Day 1, or the previous day was completed on an *earlier* calendar day |
| **Opens tomorrow** | Glass node with a sunrise | Shows why it's waiting | The previous day was completed *today* |
| **Locked** | Dim glass node with a lock | Shows why it's waiting | The previous day isn't completed yet |

Completing a day means **finishing its practice session** (the engine reaches its target
cycle count). Reading the cards is encouraged but not required. Leaving a session early
doesn't count, and nothing is lost either.

Unlocks are evaluated against the local calendar day, so the next gate opens at local
midnight. The map re-evaluates every minute while it's on screen and whenever it appears.

### Flow

```
Sidebar ▸ Journeys ▸ "The Space Between Breaths · Day 2 of 5"
   │
   ▼
Journey Map ─────────────────────────────────────────────────────────────
 │  header: title, summary, progress, "Where this comes from"
 │  winding path of day nodes (completed ✓ → available ◎ → waiting ☾ → locked 🔒)
 │
 │  iPhone: sticky Continue bar at the bottom (thumb zone) ─┐
 │  iPad:   story cards live in a pane beside the map ──────┤
 ▼                                                          ▼
Story Cards (swipe, or tap the right / left half)
 │  image → notice → practice
 ▼
Begin practice ─▶ Session (chapter's world, rhythm, focus, guiding line;
 │                 the personal opening still runs if it's enabled)
 ▼
Session finishes ─▶ Completion card (what's said, reflection question,
 │                   "The next gate opens tomorrow")
 ▼
Back to the map: the node fills in and the path lights up to it.
```

### Edge cases

- **Practicing a completed day again** doesn't change its completion date or affect the next unlock.
- **Finishing two days on the same calendar day** isn't possible: the next node reads "Opens tomorrow".
- **Changing the clock or time zone** only shifts unlock timing; completions are stored as absolute dates.
- **New Journeys** appear in the sidebar as soon as their JSON file is added to the app bundle (see the schema).

---

## 4. Layout and reach

| Context | Map | Story cards | Primary action |
| --- | --- | --- | --- |
| iPhone portrait | Full width, vertical winding path, scrolls | Sheet, cards fill the screen | Bottom Continue bar; Next / Begin pill in the bottom third |
| iPhone landscape | Same, narrower swing | Sheet | Same |
| iPad full screen / large split | Map pane (≤ 420 pt) on the leading side | Inline pane, card ≤ 560 pt wide | Pill under the card |
| iPad slide-over / compact | Behaves like iPhone | Sheet | Bottom bar |

- Every node and control is at least 44 pt; nodes are 64 pt.
- Cards respond to swipes, taps on either half (back / next), the bottom buttons, VoiceOver
  adjustable actions (swipe up / down), and the keyboard arrow keys on iPad.
- With Reduce Motion, halos hold still, cards cross-fade instead of tilting, and worlds don't animate.

---

## 5. Content guidelines

- **Length:** titles of 2–5 words; bodies of 40–70 words (practice cards 30–40, since they lead into the session); cues of 2–6 words with "…" between beats.
- **Voice:** second person, present tense, warm and plain. Questions appear only in `reflection`.
- **Images** come from nature or ordinary life, and from the world the chapter is set in where possible.
- **No** medical claims, diagnoses, or outcome promises ("cures anxiety", "unlocks…").
- **Every pause instruction** includes permission to breathe whenever needed.

The content contract is `docs/journey.schema.json` (JSON Schema 2020-12). Journey files ship
in the app bundle as `<id>.journey.json`.

---

## 6. Future Journeys

New journeys can be assembled from the 112 Gates: one gate per day, retold through story cards,
with the tagline naming its source ("Gate 37 · Dopamine Spike Awareness").

| Journey | Section | Sketch |
| --- | --- | --- |
| **Coming to Your Senses** | II. Sensory Deprogramming | The pixelated gaze, the unseen smell, the void behind the eyes. |
| **The Open Prompt** | III. The Digital Void | The space between thoughts, the unborn thought, the background canvas. |
| **Freedom from the Feed** | IV. Emotion & Dopamine | Outrage as sensation, fulfillment beyond feedback, resting in unknowing. |
| **The Watcher** | VII. Consciousness vs. Machine | The observer of the AI, the mirror, the unbroken witness. |
| **One Field** | IX. Nondual Integration | Omnipresent space, the unmoving center, Soham. |

---

## 7. The 112 Gates

A browsable library of all 112 dharanas from a contemporary synthesis of the Vijñāna Bhairava
Tantra, drawing on Swami Lakshmanjoo's traditional Kashmir Shaivism, Jaideva Singh's scholarship,
Osho's psychological adaptations, Lorin Roche's sensory poetry, and modern nondual inquiry,
reinterpreted for the era of AI, digital saturation, and synthetic intelligence.

| Section | Gates | World | Rhythm | Minutes |
| --- | --- | --- | --- | --- |
| I. Breath & Neural Pacing | 1–12 | Aurora Lake | 4 · 2 · 6 · 2 | 3 |
| II. Sensory Deprogramming & Synthetic Perception | 13–24 | Sakura Moon | 4 · 6 | 3 |
| III. The Digital Void & Cognitive Space | 25–36 | Desert Stars | 4 · 1 · 6 · 2 | 3 |
| IV. Emotion, Dopamine & Algorithmic Freedom | 37–48 | Ember Peak | 4 · 8 (gate 3's doubled exhale) | 3 |
| V. Inner Sound, Resonance & Vibration | 49–60 | Cymatics | 4 · 6 | 4 |
| VI. Somatic Grounding in the Machine Age | 61–72 | Prairie Wind | 4 · 1 · 6 · 1 | 4 |
| VII. Consciousness vs. Machine Intelligence | 73–84 | Distant Storm | 5 · 2 · 5 · 2 | 4 |
| VIII. Sleep, Transitions & Digital Twilight | 85–96 | Ocean Tide | 4 · 7 · 8 | 5 |
| IX. Nondual Integration & The Infinite Field | 97–112 | Hidden Falls | 5 · 2 · 6 · 2 | 5 |

**Experience**

- **Today's gate** walks through all 112 in order, one per calendar day, then starts over.
- **Library:** search by words or number; filter by section; fluid grids (one column on iPhone,
  up to four on iPad); a check marks gates you've practiced.
- **Gate detail:** the section's world as art, the practice text verbatim, a safety note where one
  applies, *Words from the tradition* for any glossed term in the text, and how it's practiced.
  Previous / Practice / Next sit in a bottom bar within thumb reach.
- **Practice:** a session in the section's world and rhythm, with the gate as its guiding line;
  the personal opening still runs if enabled. Finishing records the gate as practiced.

**Safety notes** accompany gates that ask the body for something specific: breath holds (2),
long exhales (3), closing the ears (49), vocalizing (50), floating sensations (66), and gates
practiced lying down or near sleep (85, 86, 94).

**Content pipeline:** the source text lives in `scripts/dharanas_source.txt`.
`python3 scripts/build_dharanas.py` renumbers it 1–112, applies section worlds and rhythms,
cautions, and the glossary, and writes `Respire/Content/Dharanas/112-gates.dharanas.json`
(contract: `docs/dharana.schema.json`). Edit the source or the script, never the JSON by hand.

---

## 8. Today's gate in the personal opening

The 30-second opening (Apple's on-device model, or the template fallback) now carries a gate:
the one being practiced in the 112 Gates, a Journey day's source gate, or otherwise today's gate.
The model gets the gate's title and text and must turn its invitation into one sensory line in
its own words, without quoting or naming it. With no gate, the body's weight and support stand in.

## 9. Moment reminders

Three optional daily local notifications (112 Gates ▸ bell), each carrying the gate written for
that threshold: **On waking** (gate 87, The Waking Flash), **Between tasks** (gate 90, The Pause
Between Tasks), and **Before bed** (gate 85, Screen-to-Sleep Bridge). Each has its own time.
Permission is requested only when the first one is turned on. Tapping a reminder opens its gate.

## 10. Sound

Each world has its own nature sound, synthesized live with no audio files, plus an optional
solfeggio tone (174–963 Hz, or "Scene", the world's own tone). Both follow the breath engine's
lung volume, so sound swells and settles with the picture and the haptics, and pauses with them.
Sound is off by default, uses the ambient audio session (it respects the silent switch and mixes
with other audio), plays during the opening and the session, and fades out when either ends.
The tones are offered as a listening experience in an old tuning tradition, not as treatment.

## 11. Today and Places

**Today** is the first screen. It shows a greeting, the Place of the day ("Breathe now"), the journey in progress, today's gate, and a nudge to set up moment reminders.

**Places** are 21 illustrated destinations, such as Rain Station, Tea House, Moon Garden Gates and Singing Bowl Temple. You breathe your way through each one at in 4, out 6, and every breath moves you forward. A place progresses in one of three ways:

- **Stages:** a trip with named stops. One breath takes you one step toward the next stop.
- **Find:** one breath reveals one thing, such as a cup, a lantern or a firefly.
- **Counter:** a quiet count of breaths.

The Places grid lives under Explore in the sidebar. Each finished visit offers an after-pulse beside the baseline.

## 12. Gentler defaults

- **Focus picks the rhythm:** Calm anxiety → Calm (4·6), Focus → Coherent (5.5·5.5), Wind down → Unwind (4·8). This applies to free sessions only.
- **Session length:** 1, 3, 5 or 10 minutes, or open-ended, with 3 minutes as the default. A finished free session shows a completion card with a pulse check.
- **Openings on request:** the opening is off by default. "Begin with an opening" sits under Begin, and the Scene & Sound sheet has a setting to always begin with one.
- **One sheet:** Scene & Sound combines the scene picker, guidance, haptics, the phase chime, nature sound and tone. Every toolbar tool has a text label.
- **Gate levels:** each gate is Foundation (33), Deepening (49) or Nondual (30). Until 7 gates are practiced, the gate of the day comes from the foundations only.
- **Calmer motion:** rain falls slower, and the world dims softly during holds.
- **Phase chime:** an optional soft bell at the start of each phase: 528 Hz breathing in, 396 Hz breathing out, 440 Hz for holds.
- **Onboarding:** three screens: what brings you here, one moment reminder, then openings and approximate location. Location is asked for up front so it never interrupts a breath.

## 13. Cymatics

Cymatics is the tenth world: sound made visible, as standing waves on water in a dark bowl seen from above. It is built for awe, meaning something vast, intricate and slowly revealed that is far richer than its simple cause.

- **Breath:** the figure unfolds from the center to the rim and grows more intricate on the in-breath, then gathers back on the out-breath.
- **Stillness:** at the turns of the breath and in holds, the lines draw fine and the grains settle. Mid-breath, they dance. Unlike other worlds, this one doesn't dim during holds, because a hold is when the figure is clearest.
- **Tone:** the solfeggio tone chooses the figure, with nine symmetries from 174 to 963 Hz, warm to cool. Changing the tone morphs the water over about two seconds. With no tone set, the water holds the 528 Hz figure.
- **Sound:** a singing bowl whose paired partials beat slowly and swell with the breath.
- **Gates:** Section V (Inner Sound) is practiced here.
- **Journey:** in Listening as an Anchor, Day 3 (Sound in the Bones, humming) and Day 4 (Between the Syllables, the gaps) are set here. Days 1, 2 and 5 keep rain, ocean and desert, so the journey still moves from sounds in the world, to sound in the body, to silence.
- **Place:** Singing Bowl Temple. Seven bowls on an altar, low to high, one rung per out-breath, at in 4, out 7. Each rung bowl rings out and holds a small water figure with its own symmetry. In the round window above, each bowl adds a layer to one great mandala whose rings turn against each other. When all seven sing, the window fills with light. The sound is the Cymatics singing bowl.

## 14. One thing at a time

People couldn't tell where to start, and while breathing too much competed for their eyes. Five fixes:

- **Today has one button.** "Start breathing" begins straight away, in the rhythm for your focus and at your chosen length. Under "Or" sit today's Place and your journey. The gate of the day and the reminder nudge left Today; both are still in Gates.
- **Breathing has one thing to watch.** A soft circle grows as you breathe in and shrinks as you breathe out, with one word inside it: Breathe in, Hold or Breathe out. The world dims behind it, its own breathing light switches off, and the scene lines, countdown and toolbar disappear. Only pause and stop remain.
- **Before breathing, one line of how-to:** "Follow the circle. Breathe in as it grows, and out as it shrinks." Free sessions offer only two choices, focus and length. Journeys and gates offer none.
- **Places stay quiet while breathing.** The arrival and title step aside, leaving one short line such as "3 of 7 bowls" and the breath word.
- **Openings are a setting, not a link.** Turn them on in Scene & Sound; the extra link under Begin is gone.

## 15. Eyes closed

Most people meditate with their eyes closed, so the guide is something you hear and feel, not something you watch.

- **Breath tone (on by default):** a soft, warm note that rises a fifth as you breathe in, falls as you breathe out, and holds level in the pauses. It carries the length and shape of every breath, and fades when you pause.
- **Spoken guidance (on by default):** a slow, quiet voice speaks the words for the first two breaths ("Close your eyes, and breathe in."), then falls silent. When a session finishes on its own, a bell sounds, then "That's it. Gently open your eyes."
- **Haptics** keep swelling on the in-breath and fading on the out-breath, where the device supports them.
- **The screen stays awake** while breathing, so auto-lock never pauses a session.
- **Sound plays with the silent switch on**, because with eyes closed it is the guide. It still mixes with anything else playing.
- **Before starting**, the screen says: "Close your eyes. Breathe in as the sound rises, and out as it falls. Or follow the circle."
- **Switches:** Breath tone and Spoken guidance sit under "Eyes closed" in Scene & Sound.

## 16. Personas and guided sessions

Who's breathing sets the sessions, the pace, and the voice. It's chosen first in onboarding, in Settings, and at the top of the Breathe tab.

| Persona | Who | Voice | Limits |
|---|---|---|---|
| Kids | 5 to 11 | a little brighter, unhurried | short sessions, no breath holds |
| Teens | 12 to 17 | natural | — |
| Adults | | slow and a little low | — |
| Wise | 60 and over | slowest | seated, no breath holds |

There are 13 guided sessions, each with a full hand-written spoken script: a settling-in, words for the first breaths, an imagery set that changes from session to session, and a closing. All the words are in `Core/Practices/PracticeCatalog.swift`.

- **Kids:** Bumble Bee Breath (with a soft hum to hum along to), Balloon Belly, Sleepy Starfish.
- **Teens:** Box Breathing for Stress, Sleep Sanctuary, Before a Test.
- **Adults, connection:** Space Before You Speak, Cool the Argument, Boundary Breath.
- **Pranayama, adults and Wise:** Bhramari (humming), and Nadi Shodhana, where the voice names the nostril on every breath.
- **Wise:** Gentle Chair Breath, Evening Gratitude.

Agnisar is left out on purpose: forceful abdominal work shouldn't be taught by voice alone. The scripts are hand-written rather than generated, so they stay calm and specific. The on-device model could later vary them lightly within the same structure.
