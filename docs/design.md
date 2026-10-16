# Toto — Design Notes

Living document. It records **decisions** and the reasons behind them, so they don't get lost in chat history.

## Pitch

A small real-time dungeon crawler for mobile. It combines Dungeon Crawl Stone Soup's dungeons, runs and
"the RNG shapes your build" with Brawl Stars' fast twin-stick combat and touch aiming.

## Current goal: validate the core loop

> Explore a room → fight → get random gear → the gear changes how you fight → next room → find the exit or die.

The playtest question: **does picking up a random item and immediately playing differently feel good?**
Anything that doesn't help answer that is deferred.

## Decisions

| Area | Decision | Why |
| --- | --- | --- |
| Platform | Mobile (landscape). Develop on desktop with mouse-emulated touch | Brawl Stars-style touch play is the target |
| Build identity | No heroes. Your build is your equipment, and equipment comes from RNG | DCSS-style "make do with what you find" |
| Equipment slots | **Weapon** (attack button) + **Utility** (second button, on a cooldown) | Smallest set where builds feel different |
| Swap rule | Replace on pickup, with a quick compare. No inventory | Every drop is a decision, and it needs almost no UI |
| Loot sources | Guaranteed chest per cleared room, plus rare enemy drops | Predictable pacing, with occasional surprises |
| Dungeon | Generated each run from a seed shown in the pause menu (see Dungeon generation) | Every run differs, and a map worth keeping (or a broken one) can be reported |
| Goal | Find the stairs out. They sit in the room farthest from the start and only work once that room is clear. Other rooms are optional | Rewards exploring for loot vs. heading for the exit |
| Rooms | Entering a room with enemies locks its doors until they're all defeated | Forces fights and gives clear pacing |
| Aiming | Brawl Stars style: **tap** = auto-aim at the nearest enemy, **drag** = manual aim with a preview, **release** = fire. Drag distance is the aim's strength, which weapons that target a spot use as distance | Proven on touch screens |
| Movement | Floating stick: it appears wherever the left thumb lands | Standard for mobile action games |

## Equipment

Every item defines how it **aims** (shape + range) and what it **does**. Items change behaviour, not just stats.

| Weapon | Behaviour | Aim shape |
| --- | --- | --- |
| Wand (starter) | One magic bolt | Line |
| Sword | The blade sweeps across an arc in front of you, hitting each enemy once as it passes | Cone |
| Fireball | Lobbed like Barley's bottles in Brawl Stars: drag distance picks the landing spot (eased, so short drags give fine control up close); arcs over walls and enemies and explodes where it lands, hurting the thrower too | Landing circle at the dragged distance |
| Crossbow | A fan of bolts; strongest up close | Fan of lines |

| Utility | Behaviour | Aim |
| --- | --- | --- |
| Dash (starter) | A quick burst of speed where you aim | Line as long as one dash |
| Shield | Blocks all damage (your own blasts included) for a moment | None: tap anywhere |
| Heal | Restores some health; slow to recharge | None: tap anywhere |

**Model (step 4).** `Weapon` and `Utility` are plain data objects (both `Item`s). Whoever wields a weapon owns
*when* (a `Wielder`: cooldown, wind-up, auto-aim tracking); the weapon owns *what* (it turns an aim into `Shot`s).
A utility turns an aim into a `UtilityEffect` (dash, shield time, healing) that the player applies. The buttons show the equipped
item's name and colour. The starter gear is a **Wand** (one magic bolt) and a **Dash**. New behaviours
(melee arc, explosions, spreads) are attack kinds: a weapon returns `Shot`s (projectiles, optionally
explosive) and `Slash`es (melee arcs), and the world carries them out.

**Per-item tuning.** Each item declares its tunable fields as `Knob`s; tuning keys are `<item id>.<field>`, so
every weapon keeps its own settings. A HUD button cycles weapons for testing, and the Tune screen shows the
equipped weapon's knobs only.

**Tuning.** Feel matters more than anything at this stage, so the numbers that shape it are editable in-game
(pause menu → Tune gameplay), saved on the device, and sent to Claude as JSON with one tap. Defaults live in the classes
(`Weapon`, `Utility`, `Player`, `Enemy`), and the tuning screen reads them, so there is one source of truth.
When a playtest settles on better values, they get copied into those defaults.

## Loot (step 6)

- **Chests.** Clearing a room leaves a chest at its centre. Walking onto it opens it and drops a weapon.
  The open chest stays, so you can see which rooms you have looted.
- **Rare drops.** A defeated enemy has a tunable chance (Tune → Loot, default 10%) to drop a weapon.
- **What drops.** Chests hold a random weapon or utility you don't already hold (a duplicate is no choice).
  An enemy's rare drop is the weapon it fought with (or a random find if you already hold that one).
  On the floor, weapons are round and utilities square.
- **Compare and swap.** Standing on a drop shows a card: the item's name and one-line description, what it
  replaces (what you hold in the same slot), and **Take** / **Leave**. Taking it leaves your old item on the floor in its place, so a swap can be
  undone; the card only returns after you step off and on again, so nothing is swapped by accident.
- **Runs start with the Wand and the Dash.** The HUD weapon switch stays as a testing aid for tuning each weapon, but the
  choice is no longer saved.

`LootTable` holds the rules (pure, given a seeded random generator). `Chest` and `WeaponDrop` only notice the
player; `main.gd` decides what drops and does the swap.

## Enemies

Enemies carry **the same weapons as the player**, and the weapon decides how they fight (`EnemyTactics`, from
`Weapon.ideal_distance`):

| Weapon | Behaviour |
| --- | --- |
| Sword | Rushes in and swings |
| Crossbow | Gets close, then fires its fan |
| Wand | Keeps to mid range and shoots |
| Fireball | Hangs back and lobs; backs away if you get close. Its blast hurts other enemies too |

Within their comfortable range they circle the player instead of standing still. Their attacks are fair by
design: an enemy is slower between attacks than the player with the same weapon, and before each attack it
**stops and shows where it will go** (a red preview), with its aim locked, so stepping aside dodges it. Both
are tunable (Tune → Enemies: attack slowness, telegraph). Enemy attacks hurt only the player; the player's hurt
only enemies; blasts hurt everyone. Enemies no longer hurt on contact.

The map says what each enemy carries (`s` sword, `w` wand, `c` crossbow, `f` fireball), so playtests stay
comparable; deeper rooms have tougher mixes. Tank-style enemies (more health, slower) are still an idea.

## Dungeon generation

`DungeonGenerator` turns a seed into the same ASCII map format the parser always read, so room detection,
doors, locks, chests and enemy letters work unchanged, and a map can be printed and read when something looks
wrong.

1. **Room graph** (`RoomGraph`): 6–8 rooms on a 4×3 grid of slots, grown as a tree from a random start slot,
   plus up to two extra links so not every path is a dead end. Links only join neighbouring slots, so
   corridors are short and never cross.
2. **Shapes** (`RoomShapes`): the start room is a rectangle; the others are a rectangle, an L, a cross or two
   merged rectangles, never thinner than 7 cells. Fighting rooms get up to four 2×2 pillars, kept clear of
   the walls and never allowed to cut a room in two. Pillars block shots; the fireball lobs over them.
3. **Corridors**: three cells wide with a door at each end, where both rooms have a straight wall facing
   each other. If two odd shapes can't be joined cleanly, they become rectangles.
4. **Difficulty** (`DungeonDifficulty`): by depth (rooms from the start). Near the start, two or so swords
   and wands; deeper, more enemies (up to six), crossbows, then fireballs.
5. **Exit**: in the deepest room, in its corner farthest from the middle (where the chest appears).

Enemies find their way around walls and pillars (`Pathfinder`, on Godot's `AStarGrid2D`) when they can't
see the player, and only shoot with a clear line; fireball throwers lob over cover.

Generation rules are tested on many seeds through the real parser: same seed, same map; every cell reachable;
every room has a door; the start is quiet; the exit is guarded and away from the start.

## Explicitly deferred

Art and audio, multiple floors, rarity tiers, stat depth, meta-progression, multiplayer.

## Roadmap

1. ~~Design doc~~
2. ~~Fixed test dungeon with room locks~~
3. ~~Touch controls (move stick, aim buttons, auto-aim)~~
4. ~~Equipment model: weapon and utility data drive what the buttons do~~
5. ~~First item pool: sword, fireball, crossbow, shield, heal~~
6. ~~Loot: room chests, rare drops, replace-on-pickup compare~~
7. Enemy types: ~~armed with the player's weapons, behaviour per weapon, telegraphed attacks~~; tank still open
11. ~~Generated dungeon: varied room shapes, pillars, depth-based difficulty, exit, seed in the pause menu~~
8. ~~Web export for playtesting on a phone~~
9. ~~Pause menu with a touch layout editor (move and resize controls, saved on the device)~~
10. ~~In-game tuning screen with Send to Claude (from the phone playtest page)~~
