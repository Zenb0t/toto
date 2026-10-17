# Which KayKit packs cover the first zone's art? (issue #19)

Researched 2026-10-17. Question: which KayKit packs (free and paid tiers) cover the crypt, plains, village, ruin,
the Lich and the goblins/kobolds/orcs, with a deep look at the **Character Animations** pack.

## How to read the evidence

- **Read directly (verified):** the official KayKit GitHub repositories (cloned and listed file by file), and this
  repo's own `assets/` (parsed glTF headers). Organisation: <https://github.com/KayKit-Game-Assets>.
- **Not fetchable from this sandbox:** `kaylousberg.com` and `kaylousberg.itch.io` do not resolve here, so their
  pages (tiers, prices, sizes, counts) were read only through search-engine excerpts of those pages. They are
  first-party text, but second-hand in delivery. Every such claim is tagged **[itch excerpt]**.
- **Unverified** items are marked as such. The Character Animations zip itself could not be downloaded, so nothing
  below about its bone names or clip list comes from opening its files.

## Short answer

Get **Dungeon Pack Remastered (free)**, **Halloween Bits (free)**, **Medieval Hexagon (free)** and the **Forest Nature
Pack (free)**; consider **Skeletons EXTRA** ($7.95, Necromancer and Golem) for the Lich. For **Character Animations**:
good and free, but it adds little over what the two packs we already ship carry; its real value is Rig_Large and
future-proofing, and it is not needed now. Still missing afterwards: goblins, kobolds, a real Lich, campfires,
ponds, and square-grid dirt roads. Details below.

## What the repo imports today

- `assets/kaykit_adventurers` (v1.0, 2023) and `assets/kaykit_skeletons` are Godot-imported `.glb` files.
  Each Adventurers model carries **76 animations**, each Skeleton **95**, on a **41-joint** skeleton (`root`, `hips`,
  `spine`, `chest`, arms, legs, `handslot.l/r`, plus IK helper bones). Parsed from the `.glb` headers.
  The pack READMEs say "75 animations" (Adventurers) and "90+" (Skeletons):
  <https://github.com/KayKit-Game-Assets/KayKit-Character-Pack-Adventures-1.0>,
  <https://github.com/KayKit-Game-Assets/KayKit-Character-Pack-Skeletons-1.0>.
- `CharacterLook.ANIMATED_MODEL = "Knight"`: `CharacterModel._animations_for_all()` loads the Knight, takes the
  `AnimationLibrary` of its `AnimationPlayer`, and shares it with every model (all share one skeleton). The
  Skeleton `.glb.import` files set `animation/import=false`, so only the Knight's clips ship. This is why design.md says
  five models add about 2 MB.
- Clips the game actually plays: `Idle`, `Running_A` (both looped), `Hit_A`, `Death_A`, and per weapon
  `1H_Melee_Attack_Slice_Horizontal`, `2H_Melee_Attack_Slice`, `1H_Ranged_Shoot`, `Unarmed_Melee_Attack_Punch_A`,
  `Spellcast_Shoot`; utilities use `Dodge_Forward`, `Block`, `Spellcast_Raise`. That is about 11 of 76.
- Note: the repo also ships a third pack, **Dungeon Remastered** (`assets/kaykit_dungeon`: banners, bottle, candles,
  chest, coins, torch, rubble), credited in `scripts/ui/credits.gd`.

## Character Animations (the user's favourite)

Pages: <https://kaylousberg.itch.io/kaykit-character-animations> (current),
<https://kaylousberg.itch.io/kaykit-animations> (Legacy, 1.2), <https://kaylousberg.com/game-assets/character-animations>,
update 1.1 devlog <https://kaylousberg.itch.io/kaykit-character-animations/devlog/1139588/character-animations-update-11>.

| Fact | Value | Source |
|---|---|---|
| Content | Humanoid animations, split per rig: **Rig_Medium** and **Rig_Large** | [itch excerpt] |
| Count | 133 on kaylousberg.com; **161** on the itch page; 133 + 28 tool clips (update 1.1) reconciles them, so the site page is just stale | [itch excerpt] |
| Sets | General (idle, hit, death, spawn, interact), Movement (walk, run, jump, crawl, sneak, dodge, crouch), Melee (1H, 2H, unarmed, dual-wield, block), Ranged, Simulation (emotes), Special (skeleton-specific) | [itch excerpt] |
| Update 1.1 | 28 tool clips (chop, dig, fish, hammer, lockpick...), **Rig_Medium only** | [itch excerpt] |
| Rig_Large | "on the lower side", more promised over time | [itch excerpt] |
| Formats | FBX and glTF (also .blend in the paid source tier) | [itch excerpt] |
| Licence | CC0 | [itch excerpt] |
| Price | Name your own price; free tier is the whole animation set; **Source Files $14.99** | [itch excerpt] |
| Size | Update 1.1 download: **free 14 MB, source 23 MB** (whole zip, all formats, both rigs) | [itch excerpt] |

**Does it fit our rig?** Partly known, partly not.

- Known: Kay says the current Adventurers (2.0) and Skeletons were *updated to be compatible* with Character
  Animations, and calls the animations "fully compatible with the characters in the other KayKit packs"
  [itch excerpt: Adventurers/Skeletons/Character Animations pages]. The Legacy animation pack is for "older style
  characters (the ones without legs)" and is no longer updated [itch excerpt].
- Known (local): the models we ship are **v1.0 from 2023** (`LICENSE.txt` says "Adventurers Character Pack (1.0)";
  the GitHub repos were last updated Sep 2023 and Feb 2024). They already contain a nearly identical clip vocabulary
  (`1H_Melee_Attack_Slice_Horizontal`, `Spellcast_Shoot`, `Dodge_Forward`, `Death_C_Skeletons`,
  `Skeletons_Awaken_Floor`, `Spawn_Ground_Skeletons`, `Taunt`...) on a 41-joint rig.
- **Unverified:** whether Rig_Medium's bone names and rest pose equal our v1.0 skeleton. That decides everything:
  - If they match, the Character Animations `.glb` can be loaded exactly like the Knight's (`AnimationLibrary`
    from its player), because Godot binds tracks by path (`Skeleton3D:bone_name`). Zero code beyond a new constant.
  - If not, either re-download Adventurers/Skeletons 2.0 (the free tiers, same CC0) and swap the models, or
    retarget with a Godot `BoneMap` + `SkeletonProfileHumanoid` (the rig is humanoid; a community comment says to switch
    the import to Humanoid [itch excerpt]).
  - **A one-hour check settles it:** download the free zip, run the `glb.py`-style header dump used here (joint
    names) and compare with the Knight's list.

**What it would replace or add compared with today.** We use 11 clips and ship the Knight's 76, so the pack replaces
nothing we need. It would add: tool clips (chop/dig/fish: useful for NPCs in the village), more emotes and idles,
more walks/runs, and **Rig_Large** clips (the only place a bulky boss or ogre gets its own motion, since our ogres are
scaled Barbarians). The Skeleton-specific clips we want for the Lich (awaken, spawn, summon) **already exist in the
Skeletons v1.0 files** (`Skeletons_Awaken_Standing`, `Spawn_Ground_Skeletons`, `Spellcast_Summon`, `Taunt`).

**Web-size effect.** Import it once and keep only the clips used (a Godot import setting or a trimmed
`AnimationLibrary`); each clip is a few KB of bone tracks. The 14 MB zip is mostly FBX and duplicated formats, so
the shipped addition would be well under 1 MB for ~20 clips (estimate, not measured). Option: the shipped
Knight `.glb` is 3.6 MB largely because it embeds 76 clips; moving the clips into a dedicated animations file and
importing the models without animations would likely shrink the download rather than grow it (estimate).

## Other packs

All are CC0 with a 1024x1024 gradient atlas (downsamplable to 128x128), so they match each other and our Adventurers
and Skeletons.

### Dungeon Pack Remastered (crypt)
Repo: <https://github.com/KayKit-Game-Assets/KayKit-Dungeon-Remastered-1.0>; page <https://kaylousberg.itch.io/kaykit-dungeon-remastered>.
Verified (repo listing, 203 models): `wall` (plus `_arched`, `_broken`, `_cracked`, `_corner`, `_doorway`, `_gated`,
`_window_*`, `_pillar`, `_half`...), `floor_tile_*` (large, small, broken, decorated, grates, spikes),
`floor_dirt_*`, `floor_wood_*`, `floor_foundation_*`, `stairs` (`_narrow`, `_wide`, `_walled`, `_wood`),
`pillar`, `pillar_decorated`, `column`, `barrier*` (a barrier is a ready-made **barricade**), `candle*`, `torch*`,
`rubble_half/large`, `trunk_*`, tables, beds, shelves, kegs, chests, banners. **No coffin** in the 1.0 repo.
Tiers [itch excerpt]: Free 1.1 29 MB, Extra 34 MB ($7.95, 25+ assets: tavern pieces, modular bar, beds), Source 37 MB
($11.95). 1.1 added 8 free assets: modular stairs, gentler stairs, ceiling pieces.
Size on disk of the whole glTF set in the repo: 9 MB for 203 models (about 45 KB each); a zone's 40 pieces is
about 2 MB uncompressed.
**Covers:** crypt walls, floors, stairs, boss-arena pillars/columns, candles, ruin broken walls/rubble, barricades,
inn interiors (Extra). **Already partly used.**

### Halloween Bits (crypt entrance, coffins, ruin)
Repo: <https://github.com/KayKit-Game-Assets/KayKit-Halloween-Bits-1.0>; page <https://kaylousberg.itch.io/halloween-bits>.
Verified (63 models): **`crypt`** (the stone mausoleum), **`coffin`, `coffin_decorated`**, `arch`, `arch_gate`, `shrine`,
`shrine_candles`, `pillar`, `gravestone`, `grave_A/B`, `gravemarker_*`, `fence*` (+ broken), `path_A-D`, `floor_dirt*`,
`tree_dead_*`, `tree_pine_*`, `bone_*`, `skull*`, `ribcage`, `lantern_*`, `candle*`, `bench`, `pumpkin_*`.
Tiers [itch excerpt]: Free 5.3 MB, Extra 9.5 MB ($3.95), Source 10 MB ($5.95). Repo: all glTF + bins 1.4 MB.
**Covers:** the mausoleum/crypt entrance (`crypt`), coffins, ruin props (broken fence, arch), dead trees, a stone path.
Style note: autumn/spooky palette (orange pines, pumpkins); use the neutral pieces.

### Medieval Hexagon Pack (village, plains)
Repo: <https://github.com/KayKit-Game-Assets/KayKit-Medieval-Hexagon-Pack-1.0>; page <https://kaylousberg.itch.io/kaykit-medieval-hexagon>.
Verified (221 models): `building_home_A/B`, `building_tavern` (the **inn**), `building_well`, `building_church`,
`building_blacksmith`, `building_market`, windmill, mine, ruin-like `building_destroyed`, `tent`, `fence_wood_*`,
`fence_stone_*` (+ gate), `wall_straight(_gate)`, `tree_single_*`, `trees_A/B_*`, `rock_single_A-E`, `hill_*`,
`hex_road_*`, `hex_river_*`, `hex_water`, `waterlily_*`, `waterplant_*`, props (barrel, crate, sack, wheelbarrow,
weaponrack, flag, ladder). Buildings come in blue/red/green/yellow. Units only in Extra.
Tiers [itch excerpt]: Free 33 MB, Extra 53 MB ($9.99), Source 61 MB ($14.99). glTF set is 12.8 MB for 221 models
(each building in four colours); 15 chosen pieces would be about 1 MB.
**Risks (inferred, not verified):** it is built for a hex-tile RTS, so building scale is tiny next to a Knight (needs
per-prop scaling) and roads/rivers/water are hex tiles that do not tile on our square grid (use as decals or props,
not as terrain). **Covers:** houses, well, inn, boulders, trees, fences/barricades, tent, stone walls, destroyed building.

### Forest Nature Pack (plains)
Page <https://kaylousberg.itch.io/kaykit-forest>; no public GitHub repo found.
[itch excerpt]: 200+ unique models (1500+ with recolours); **Free 6.1 MB** = 100+ trees, rocks, bushes, grass;
Extra 81 MB ($9.99) adds trees, rocks, modular terrain and 8 colour variants; Source 94 MB ($14.99). Released
April 2025. FBX/glTF/OBJ, CC0.
**Covers:** trees, boulders, bushes, grass. **Not confirmed:** ponds, campfire, logs (none named in any excerpt).
Cheapest download of the lot, so it is the best first look for the plains.

### Skeletons (current) and Adventurers (current)
Pages <https://kaylousberg.itch.io/kaykit-skeletons>, <https://kaylousberg.itch.io/kaykit-adventurers>.
- Skeletons: 4 base (warrior, rogue, mage, minion; the ones we have) + **EXTRA $7.95: Skeleton Golem ("a big bulky
  Skeleton Golem, perfect for a boss") and Necromancer** + alternate texture [itch excerpt]; Source $11.95.
- Adventurers (current page): 5 base (Knight, Barbarian, Mage, Rogue, Ranger) + EXTRA $7.95 (Engineer, Druid, bulkier
  Barbarian, alternate textures) [itch excerpt]. The 1.0 repo (what we ship) says 4 + 2.
- **For the Lich:** the Necromancer (EXTRA) is the nearest skeletal caster; the Golem could be a bulky boss.
  Whether the Necromancer looks like a "Lich" is a taste question; verify in the pack preview. Both are CC0.

### Mystery Monthly Series (monsters, paid)
Pages <https://kaylousberg.itch.io/kaykit-series-4>, `-series-5`, `-series-6`; $19.99 each [itch excerpt]; also in
The Complete KayKit ($150, v7, 614 MB [itch excerpt]) <https://kaylousberg.itch.io/kaykit-complete>.
- Series 4 (15 chars): includes **Orc Raider**, Werewolf, Paladin, Ninja, Clown, Robots...; stated to be
  "technically identical to the Adventurer characters" (same rig) [itch excerpt].
- Series 5 (14): Combat Mech, Black Knight, Vampire, Witch, Frost Golem, Caveman, Tiefling... no orc, no goblin.
- Series 6 (14): **Orc Brute**, Lorekeeper, Cleric, Monstrosity, Plant Warrior, Avian Swordsman... "new style, with legs".
- **No goblin or kobold in any series** [itch excerpt searches; not exhaustive]. Series 2 and 3 rosters were not checked.

### Others, not needed
Prototype Bits (<https://github.com/KayKit-Game-Assets/KayKit-Prototype-Bits-1.0>: blockout walls/doors/pillars, 72 models),
Resource Bits, Block Bits, Platformer, RPG Tools Bits, Fantasy Weapons Bits (<https://kaylousberg.itch.io/fantasy-weapons-bits>,
possible weapons for orcs), City Builder, Furniture, Restaurant, Space Base, Board Game Bits. None names a campfire.
Legacy packs (older art style, no legs) are not a fit: Spooktober, Dungeon Pack (legacy), Medieval Builder, Mini Game
Variety, Legacy Animations.

## Coverage against the needs

| Need | Covered by | Status |
|---|---|---|
| Crypt walls, floors, stairs | Dungeon Remastered (free) | covered, verified |
| Coffins | Halloween Bits `coffin`, `coffin_decorated` | covered, verified |
| Candles | Dungeon, Halloween | covered (already shipped) |
| Boss arena pillars | Dungeon `pillar`, `pillar_decorated`, `column` | covered, verified |
| Stone mausoleum (crypt entrance) | Halloween Bits `crypt` | covered, verified by name; look unconfirmed |
| Ruin: broken walls | Dungeon `wall_broken`, `rubble_*`; Hexagon `building_destroyed` | covered |
| Campfires | none found (Dungeon `torch_lit` is a stand-in; Forest/Resource Bits unconfirmed) | **gap** |
| Trees, boulders | Hexagon, Forest Nature (free), Halloween (dead trees) | covered |
| Ponds | Hexagon `hex_water`/`waterlily` are hex tiles; Forest unconfirmed | **partial** |
| Barricades at exits | Dungeon `barrier*`; Hexagon `fence_*`, `wall_straight_gate` | covered |
| Dirt roads | Dungeon `floor_dirt_*`, Halloween `path_A-D` (square); Hexagon `hex_road_*` (hex) | covered via square tiles |
| Houses, well, inn | Hexagon `building_home_A/B`, `building_well`, `building_tavern`; Dungeon Extra tavern interior | covered, scale caveat |
| Lich | Skeletons EXTRA Necromancer (taste check) | **partial** |
| Goblins, kobolds | nothing | **gap** |
| Orcs | Mystery Monthly Series 4 Orc Raider or Series 6 Orc Brute ($19.99 each) | paid only |

## Recommendation

1. **Dungeon Pack Remastered, free tier** (29 MB zip, about 2 MB shipped): crypt shell, pillars, stairs, barricades.
2. **Halloween Bits, free tier** (5.3 MB): crypt entrance, coffins, ruin bits, dead trees, paths.
3. **Medieval Hexagon, free tier** (33 MB zip, about 1 MB shipped): village buildings, well, inn, fences, tent, rocks.
   Plan for rescaling.
4. **Forest Nature Pack, free tier** (6.1 MB): plains trees, rocks, bushes. Check for campfire/pond before relying on it.
5. **Skeletons EXTRA, $7.95**: only if the Necromancer looks right as the Lich.
6. **Character Animations, free**: grab it, run the bone-name comparison, and keep it for Rig_Large and village NPC tool
   work; do not block the zone on it. If bones do not match, do not retarget just for animations we already have.
7. Skip the $19.99 Mystery Monthly packs unless one orc is worth that price; orcs are currently green Barbarians.

**Still missing after these:** goblins and kobolds (no KayKit model exists; keep recoloured Rogues), a campfire,
ponds that fit a square grid, hex-free roads at village scale, and any Lich beyond the Necromancer. A campfire is
easy to build from `torch_lit` + a particle, as the torches already do.

**Web download budget (estimate):** about 4-6 MB of extra models/props for the zone vs. the current ~2 MB characters;
`.glb` files import to compact `.scn`, and the shared 1024 atlas per pack costs about 20-100 KB each. Measure after
import with the web export script.
