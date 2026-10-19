# Toto

[![Tests](https://github.com/Zenb0t/toto/actions/workflows/tests.yml/badge.svg)](https://github.com/Zenb0t/toto/actions/workflows/tests.yml)

A small real-time dungeon crawler for mobile: Dungeon Crawl Stone Soup's "the RNG shapes your build" meets
Brawl Stars' twin-stick touch combat. Built with Godot 4.4. It plays on a flat 2D plane and is shown in 3D, with
a tilted Brawl Stars-style camera (placeholder models for now).

Design decisions and the roadmap are in [`docs/design.md`](docs/design.md).

## Play

Open the project in Godot 4.4+ and press F5. The window runs in landscape. It plays by touch or with keyboard
and mouse, following whichever you used last.

**Touch**

| Input | Action |
| --- | --- |
| Touch the left half of the screen (below the Map button) and drag | Move (floating stick). The top left stays free for the Map button |
| Tap the **weapon** button | Auto-aim at the nearest enemy you can see and attack. Each weapon holds 3 shots of ammo (orange bar over your head) that reload one at a time |
| Drag from the weapon button, then release | Aim manually and fire. The button floats like the stick: touch anywhere in the faint circle around it and it jumps under your finger; the aim is measured from where you touched. Dragging back to the middle buzzes (phones that support it); letting go there cancels, as in Brawl Stars |
| Hold the weapon button (**Bow**) | Draws the bow: the longer you hold before letting go, the harder the arrow hits, up to a full charge at 1.5 s, which also pierces. You walk slower while drawing; the aim line fills up as it charges. A tap is a weak arrow |
| **Utility** button (DASH, SHIELD, BLINK, FROST) | Same tap / drag gesture; Shield and Frost Nova don't need aiming |
| **Potion** buttons (under the weapon switch) | Drink one: Healing, Haste or Might. Walk over potions to pick them up |
| Weapon button reads **REST** (by an unlit campfire, when nothing is hunting you) | Light it: it burns about 10 s and heals you up to half your health while you stand in its light. Stepping out pauses the healing; a hit or an attack stops it. Then it lies in embers (a countdown shows) for about 90 s, counted only while you are on that map. Refused while a monster hunts you or an awake one is in sight (sleeping ones don't count); a camp's fire is theirs until the last monster dies. **Resting in the wild is a gamble:** each time you light a campfire there is a seeded chance (30% on the plains, 45% in the crypt) that 3 of the area's monsters arrive at the edge of the light a few seconds later, already hunting you. Leaving and coming back can't re-roll it |
| Weapon button reads **REST** (on the village inn's doorstep, when nothing is hunting you) | Sit for 3 s: you are fully healed. Moving or a hit cancels it; the inn never has an ambush and no limit, so you can rest again at once. Refused while a monster hunts you or an awake one is in sight |
| Walk onto a chest or a dropped item | Shows what it is; **Take** swaps it for yours, **Leave** keeps yours |
| **Map** (top left) | Show or hide the minimap; the choice is remembered |
| Tap the minimap | Open the whole map, big on the screen (the game waits). Tap, click, Esc or M closes it |
| **Weapon: …** (top right) | Testing aid, hidden by default (Tune → Controls → Show weapon switch): cycle through every weapon |
| **II** (top right) | Pause menu: resume, customize controls, tune gameplay, credits, restart run |

**Keyboard and mouse**

| Input | Action |
| --- | --- |
| WASD or arrow keys | Move |
| Mouse | Aim at the cursor (Fireball and Mephitic Cloud land on it) |
| Left click | Attack; hold to keep attacking (with the Bow: hold to draw, release to shoot) |
| Right click or Space | Utility, toward the cursor |
| 1, 2, 3 | Drink a potion |
| E | Take the item you're standing on; by a campfire or on the inn's doorstep, rest (or hear why not: monsters around, or still embers) |
| M | Show or hide the minimap; closes the big map when it is open |
| Q | Next weapon (testing aid) |
| Esc | Pause menu; in the Tune screen, back one page |

**Customize controls** pauses the game and lets you drag the stick and buttons where you want them, and resize
the one you picked with the slider. Done saves the layout on the device, so it survives restarts and reloads.

**Tune gameplay** exposes the numbers that shape the feel, sorted into a menu: Player, Weapons, Utilities,
Potions, Enemies, Lich, Loot, Controls (each button's aim dead zone), Rest (campfire heal, burn, embers, light; ambush chances, size and delay; the inn's rest time and reach), Camera (tilt, distance indoors and outdoors, field of view,
look-ahead, wall height) and World (the plains' size, woods, lone trees, rock piles, ponds and the rest; they shape the next world, with
**New world** and **Same seed again** buttons). Weapons, Utilities and Potions list every item, so any of them can be tuned (the equipped
one is marked). Entries you changed show in gold; Reset resets the page you're on. Changes apply live and are
saved on Done.
**Send to Claude** (phone playtest page on claude.ai only) saves them as JSON where Claude can read them.

A run starts outdoors on the **plains**, in a **village** (48x36, a palisade with a gate on each side, streets to a square with a well, an inn, a few houses and a smithy, market or church, in KayKit Medieval Hexagon art): you start in front of the inn and know the whole village already; buildings turn see-through when they stand between the camera and you, and the HUD calls the place "The village" while you are inside. The plains are open grassland, 260x150, with a handful of separate woods (drawn as trees; they block walking and sight),
lone trees, a few piles of rocks for cover, ponds and a thick forest border with a barricaded exit in the middle of
each side. The camera stands farther back there than in the crypt, and you see farther (22 cells instead of 16). Somewhere out in
the grass, halfway to the border or farther, stands a small stone mausoleum: the crypt entrance, with no road to it. Step
onto its stairs to go down into the **crypt**, 3 levels of tombs and undead (the HUD says "Crypt level 2"), all grown from one world seed (shown in the pause menu), inspired by
Dungeon Crawl Stone Soup. The first level's silver stairs lead back out to the mausoleum. Six **camps** dot the plains, each a band of 2-4 goblins and kobolds round a campfire (asleep or wandering), bigger and tougher
the farther they are from the middle, with goblin archers toward the edge; three more campfires burn alone. In one corner of the map (never the crypt entrance's) stands the **ruin**, a walled courtyard with two or three gaps in its wall, the map's toughest band (always wandering) and a guaranteed chest holding a piece of gear; it stays open once looted. Two 3-wide dirt roads wind from the village gates to two of the four exits (picked by the seed) to follow across the map; they only change the colour of the ground. Campfires
show on the minimap once seen, and monsters killed on the plains stay dead. No monster lives in the village, and no camp stands in it or the grass round it.
Tune → World holds the knobs of the plains (the village and the ruin's gaps and band among them) and of the crypt (how far its campfire lies from the stairs, how many bands wander) and starts a new world or the same seed again. **Warp** (a playtest aid, off by default: set "Warp (0 = off)" to 1) adds a button per place to the page: the village (by the inn, the start), the ruin (beside its chest), the crypt entrance (in front of the mausoleum), crypt levels 1 to 3 (on their stairs up) and the Lich's arena (just outside its door, so walking in still locks it). It keeps what you carry and every map's record. The crypt's levels: oddly
shaped rooms, some with pillars for cover, mixed with hand-made vaults (moats, pools, lava rivers, a treasure
closet). Deep water stops feet but not shots; lava burns. You only see what's in your line of sight; explored
areas stay dimmed on the map, and a minimap (top left) charts what you've seen: the stairs, doors, water and
lava, and you. Items sometimes lie on the floor (the same ones for the same world seed), and some rooms are tougher than they should be. The monsters of a room are a band that sleeps there (a "z" over
their heads) or wanders slowly about it; one notices you only when it can see you close by (4 cells asleep, 9
wandering; in the crypt most bands sleep, a few wander and none starts awake) or when you hurt it, shows a "!", and comes for you. Your attacks and blasts make noise that wakes monsters
within 8 cells, even through walls, and a monster that notices you shouts, waking the rest of its band and anyone within 8 cells, who shout in turn,
so a careless fight can pull in a nearby band. You can escape a chase: a monster gives up after 5 seconds without
seeing you, or when you are 24 cells from its home, checks where it last saw you and walks home, noticing you again if it sees you on the way. Ordinary rooms don't lock, so you
can sneak past or pick your fight; only the Lich's arena and the **trap rooms** do (below). Loot is earned, not handed out:
clearing a room leaves nothing, so new gear (a weapon, or a utility: Dash, Shield, Blink, Frost Nova) is found
hidden on the floor or, rarely, dropped. Enemies carry the same weapons you do and fight the way their
weapon wants, as a team: they take turns to attack, spread out to flank you and aim ahead of where you run; a red preview shows where an attack is about to land, so you can step aside. About one in fifty drops
its weapon. Rooms get tougher the deeper you go, and each level more than the last. Each level has one campfire in an ordinary room a few rooms from the stairs (a rest spot later). Find the gold stairs (in the room
farthest from the start, usable once it is clear) to go down, keeping your gear, health and potions; the
third level has no stairs down: its farthest room is the **boss arena** (see below). On every level you arrive on silver stairs that lead back up, onto the gold
stairs of the level above (the first level's onto the mausoleum). The dungeon remembers: monsters you killed stay dead, opened chests stay open, items
you took stay gone, items you dropped stay where they fell and the map stays explored (the plains too). Monsters you left hurt
heal while you are away (Tune → Enemies → Heal while away). Defeating monsters earns experience; every level adds maximum health. The first two levels each hold one **trap room**: a room with a chest in the middle that looks like any other. Walking in seals it, a band tougher than the level's usual (Tune → World → Crypt trap room band) appears and fights to the death, and the chest stays shut until the last one falls; then it holds a weapon or utility you don't have. The third level's farthest room is the **boss arena**: a hall with four pillars that block shots and the **Lich**'s crypt at
its far end. It locks when you walk in and opens when he dies. The Lich, a dark purple skeleton mage with a crown, a robe and a
staff, starts awake, never gives up, keeps his distance (back off as you close in) and casts one telegraphed spell at a time with a
short pause between: the Mephitic Cloud and, as his rarest spell (every third cast), the Bone Spray: three waves of five bone shards in a half circle, each wave offset from the last, that pillars stop, and Summon Undead, which comes first whenever fewer than 5 skeletons (7 below half health) are alive: glowing floor spots between him and you pulse and raise skeletons that hunt you at once and all collapse when he dies. Hurt from a doorway before the arena locks, he withdraws into a nook of his crypt that no doorway can see, so you have to walk in. Killing him **wins the run**: a summary says
"You killed the Lich", and **Keep exploring** carries on in the same world, with him still dead. Tune → Lich holds every number of his.
If you die, you start over on the plains of a new world (a new seed) with the Dagger, the Dash and a Potion of
Healing.

## Play on a phone

`tools/web_playtest/package.sh <godot-binary>` exports the Web build and packs it into `build/web_playtest/`.
`toto-playtest.html` is a touch-friendly loader page that works on static hosts that serve only web file types.
Web export needs Godot's 4.4.1 export templates installed.

## Test

```sh
tools/ci/run_tests.sh <godot-4.4.1-binary>
```

Imports the project, runs the [GUT](https://github.com/bitwes/Gut) suite (vendored in `addons/gut`) and boots
the game headless, failing on any test failure or GDScript error. GitHub Actions runs the same script on every
pull request and push to `main` (`.github/workflows/tests.yml`). To run only the tests, or one file:

```sh
godot --headless --import
godot --headless -s addons/gut/gut_cmdln.gd -gexit
godot --headless -s addons/gut/gut_cmdln.gd -gselect=test_loot -gexit
```

## Credits

Characters, weapons and dungeon props: [KayKit Adventurers](https://kaylousberg.itch.io/kaykit-adventurers),
[KayKit Skeletons](https://kaylousberg.itch.io/kaykit-skeletons) and
[KayKit Dungeon Remastered](https://kaylousberg.itch.io/kaykit-dungeon-remastered) and
[KayKit Medieval Hexagon](https://kaylousberg.itch.io/kaykit-medieval-hexagon) by Kay Lousberg (CC0), in
`assets/` with their licenses. Also built with [Godot Engine](https://godotengine.org) (MIT) and its default font,
Noto Sans (SIL OFL 1.1); tests use [GUT](https://github.com/bitwes/Gut) (MIT). The phone playtest page loads
Pixelify Sans and IBM Plex Sans from Google Fonts (both SIL OFL 1.1). The pause menu's **Credits** screen lists
what ships in the game (`scripts/ui/credits.gd`); add new third-party assets there.

## Layout

- `scripts/core` – engine-agnostic building blocks (`Health`, `Cooldown`, `Ammo`)
- `scripts/dungeon` – the ASCII map format (`DungeonMapParser`; enemy letters pick their monster, `>` stairs down
  (the exit), `<` stairs up, `~` water, `L` lava, `*` floor item, and outdoors `T` tree grove, `B` boulder, `=` barricade, and the village's `Y` palisade, `G` gate, `:` street, `U` well, `X` prop, `D` inn doorstep, `I C S M` inn, church, smithy, market, `1`-`4` houses, `@` start), enemy navigation (`Pathfinder`), fog of war (`Exploration`, `FogView`),
  lava damage (`LavaBurn`), how the floor looks (`FloorPainter`, drawn in square `FloorChunk`s so the off-screen ones are skipped), how the dungeon dresses up (`DungeonDecor`: stone tints, cracks, pillars,
  torches and their light), moving liquids (`LiquidView`), room rules: enemies left per room, and the lock
  of rooms marked as locking (`DungeonProgress`; `LockingRoom`: the arena and trap marks; `Hideout`: where the Lich hides in the arena), and the rendering of floors, walls and doors (`DungeonView`, `Door`)
- `scripts/dungeon/generation/village` – the village, stamped in the plains' middle: `VillageGenerator` runs `VillagePalisade`,
  `VillageStreets`, `VillageLotPacker` (with the hand-written `VillageLots`), `VillageProps` and `VillageRules` (`Village`, in
  `scripts/dungeon`, holds its map letters and what a map knows of it)
- `scripts/dungeon/generation/quadrant` – the plains: `QuadrantGenerator` runs the steps (`QuadrantGround`,
  `QuadrantBorder`, `QuadrantExits`, `SetPiecePlacer`, `QuadrantRules`) over a `QuadrantGrid` by a plain-data
  `QuadrantRecipe` (every number a Knob); the ground comes from `PlainsZones` (meadow, wood and pond zones spread by
  `PoissonDisc`), `PlainsWoods` (woods rounded off by `GroveSmoothing`, single trees at their edges, lone trees), stamping hand-made `SetPiece`s (`SetPieces`: the crypt entrance, camps and campfires, the ruin (`Ruins`: its drawing, gaps, band); `CampCrews` fills each camp by how far out it lies; `QuadrantRoads` lays the dirt roads round them)
- `scripts/dungeon/generation` – the seeded generator (`DungeonGenerator`) and its pure parts: `Branch` and
  `BranchLook` (what each place is: the plains, Dungeon, Lair, Orcish Mines, Crypt, Depths), `RoomGraph`
  (which rooms and links), `RoomShapes` (floor plans, caves and pillars), `Vaults` (hand-made set pieces), `BossArena` (the Lich's room on crypt level 3), `TrapRoom` (which crypt room is the trap), `CryptRecipe` and `CryptCampfire` (the crypt's Knobs; which room holds the campfire),
  `DungeonDifficulty` (enemies by depth, out-of-depth rooms)
- `scripts/controls` – pure input math (`StickMath`, `AimGesture`, `AutoAim`, `MouseAim`, `TouchZones`) and `InputMode` (touch or
  keyboard and mouse)
- `scripts/equipment` – what the buttons do, as plain data: `Item`s, which are a `Weapon` (`MagicMissile`, `Knuckles`, `LightningBolt`, `MephiticCloud`,
  `Fireball`, `Crossbow`, `Bow`, or an `ArcWeapon` archetype: `Dagger`, `Sword`, `Battleaxe`) or a `Utility` (`Dash`, `Shield`, `Blink`, `FrostNova`, `Beckoning`). Each declares its own tunable `Knob`s
- `scripts/combat` – what an attack or utility does (`Shot`, `Slash`, `Nova`, `UtilityEffect`, `TickClock` for lingering effects, `PoisonStatus` so poison clouds don't stack, `ChainFalloff` for the Lightning Bolt's weaker jumps, `Charge`: seconds held to strength), when a weapon fires
  (`Wielder`: ammo and wind-up, for the player and enemies alike), how enemies fight (`EnemyTactics`: moving, flanking, aiming ahead, where to wander), when a calm monster
  notices the hero and who hears a noise or shout (`Awareness`), what they are doing (`EnemyBrain`, a small state machine: asleep, wander,
  noticing, idle, hunt, position, wind up, recover, check, return, retreat; `Awareness` also decides when a hunter gives up), which spell the Lich casts next (`SpellPicker`), how a band fights as a team (`Squad`: taking turns, flank
  spots),
  how aims are previewed (`AimShape`, `AimPreview`), and pure geometry (`HitShapes`, `Spread`, `ArcPolygon`)
- `scripts/monsters` – `Monster` (a kind of enemy: race, weapon, health, speed, size, strength), `Lich` (the boss: his tunable numbers and Bestiary entry), `BoneSpray` (his spray of shards: the pattern and its numbers), `SummonUndead` and `SummonSpots` (his summons: numbers and where skeletons rise), the
  `Bestiary` that lists them with their map letters, and `Band` (which home a monster lives at, a campfire or its
  room, and how the monsters of one home start: asleep or wandering, from the map's seed) and `Camps` (which campfire a monster lives at)
- `scripts/potions` – consumables: `Potion` (`HealingPotion`, `HastePotion`, `MightPotion`) and the `PotionBelt`
  that carries them
- `scripts/loot` – `LootTable`: what drops (pure rules, given a random generator)
- `scripts/tuning` – `Tuning` (generic knobs with limits, defaults and JSON export), `Knob`, `TuningSection` (an
  entry of the Tune menu) and `GameTuning` (which knobs exist, how the menu sorts them, and how they become gear)
- `scripts/settings` – saved settings: `ControlLayout`, `GameSettings` (what is saved, and how) on top of
  `SettingsStore` (sections in a ConfigFile)
- `scripts/ui` – touch widgets (`TouchStick`, `AimButton`, `TouchControls`), `KeyboardMouseControls`, `PauseMenu`, `LayoutEditor`,
  `TuningPanel`, `TuningSender`, `LootCard`, `MinimapView` (with `MinimapPainter`, which paints the picture), `MapOverlay` (the big map)
- `scripts/actors` – `Player`, `Enemy`, `Projectile`, `Explosion`, `LingeringZone` (`PoisonCloud`, `BurningGround`), `SlashEffect`, `Summoning` (carries out the Lich's Summon Undead), and the loot on the floor
  (`PickupArea`, `Chest`, `ItemDrop`). The player holds no input code
- `scripts/view3d` – how the game is shown: the 2D world runs the game and `WorldView3D` shows it in 3D.
  `GroundView` lays the 2D plane on the floor (floor, aim previews, telegraphs, fog), `MapView3D` stands walls
  and closed doors on it (`VillageView3D` the village's models, see-through when they hide the hero; `ForestView` the
  plains' trees, in chunks of MultiMeshes, from `TreeShape`), and `Puppets` moves a 3D stand-in with each actor. Pure parts: `WorldSpace`
  (2D plane to 3D), `CameraFraming` (the Brawl Stars-style camera), `GroundWindow` (which part of the plane
  the floor texture shows). `models/` holds the models: `CharacterModel` (KayKit characters, animated), `HeroBars` (health and ammo over the hero) and
  `CharacterLook` (who wears what), and the simple ones (chests, loot, shots, torches, the stairs' arch, the bow in hand: `BowModel`, picked with the others by `WeaponModel`)
- `scripts/run` – the run-level owner `Run` (world seed, the hero's carried state, which map is current and where
  the hero arrives on it, the run's clock, one record per visited map) and its pure parts: `HeroState` (what the
  hero carries between maps: gear, health, potions, experience, kills), `MapSpec` (a map's id, generator recipe and
  seed), `WorldLayout` (the world's maps, their seeds from the world seed, where each exit leads and which spot the
  hero arrives on), `MapRecord` (what the hero changed on a map: kills, opened chests, taken floor items, dropped
  items, explored cells, monsters left hurt; it round-trips through a dictionary) and `Regeneration` (how hurt
  monsters heal while the hero is away); `MapStage` (one built map in the running game: the parsed map, its floor, fog, 3D view
  and everything on it, freed whole on leaving); `RunSummary` (the end-of-run lines); `Place` ("The village", or the map's own name: "The plains", "Crypt level 2", for the HUD and banner); `Experience`: levels from
  kills, each adding maximum health
- `scripts/rest` – resting at a campfire: `Campfire` (unlit, burning, embers), `RestProfile` (its numbers, Knobs),
  `MonstersAround` (when resting is refused), `Ambush` (the seeded roll of each campfire lighting and who comes), `AmbushPlacement` (where they appear) and `AmbushParty` (the countdown), `RestOffer` (when the button reads REST, and the refusal), `RestSpot` (the node that carries a campfire out in the world), and the inn's `InnRest` (a 3 s rest, cancelled by moving or a hit) with `InnSpot` (its node on the doorstep)
- `scripts/main.gd` – composition root: wires controls, HUD and menus once, builds the run's current map
  (rebuilt in place on the stairs and on starting over, then its record applied; the record is written on leaving),
  routes controls to the player and applies the room rules (a camp's monsters, or the monsters of a room, are a band: settled at its home, the campfire or the room's middle,
  and woken by the hero's noise and by each other's shouts, a band always hearing its own)
- `tests/unit`, `tests/integration` – behaviour tests
