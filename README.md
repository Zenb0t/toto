# Toto

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
| E | Take the item you're standing on |
| M | Show or hide the minimap; closes the big map when it is open |
| Q | Next weapon (testing aid) |
| Esc | Pause menu; in the Tune screen, back one page |

**Customize controls** pauses the game and lets you drag the stick and buttons where you want them, and resize
the one you picked with the slider. Done saves the layout on the device, so it survives restarts and reloads.

**Tune gameplay** exposes the numbers that shape the feel, sorted into a menu: Player, Weapons, Utilities,
Potions, Enemies, Loot, Controls (each button's aim dead zone), Camera (tilt, distance, field of view,
look-ahead, wall height) and World (the plains' size, groves, ponds and the rest; they shape the next world, with
**New world** and **Same seed again** buttons). Weapons, Utilities and Potions list every item, so any of them can be tuned (the equipped
one is marked). Entries you changed show in gold; Reset resets the page you're on. Changes apply live and are
saved on Done.
**Send to Claude** (phone playtest page on claude.ai only) saves them as JSON where Claude can read them.

A run starts outdoors on the **plains**, in a **village** (36x28, a palisade with a gate on each side, streets to a square with a well, an inn, a few houses and a smithy, market or church, in KayKit Medieval Hexagon art): you start in front of the inn and know the whole village already; buildings turn see-through when they stand between the camera and you, and the HUD calls the place "the village" while you are inside. The plains are a 160x90 field of grass with tree groves (they block walking and sight),
boulders for cover, ponds and a thick forest border with a barricaded exit in the middle of each side. Somewhere out in
the grass, halfway to the border or farther, stands a small stone mausoleum: the crypt entrance, with no road to it. Step
onto its stairs to go down into a descent through 5 floors, each a different branch (the Dungeon, the Lair's caves, the Orcish
Mines, the Crypt, the Depths) and a new dungeon, all grown from one world seed (shown in the pause menu), inspired by
Dungeon Crawl Stone Soup. The first floor's silver stairs lead back out to the mausoleum. Six **camps** dot the plains, each a band of 2-4 goblins and kobolds round a campfire (asleep or wandering), bigger and tougher
the farther they are from the middle, with goblin archers toward the edge; three more campfires burn alone. Two 3-wide dirt roads wind from the village gates to two of the four exits (picked by the seed) to follow across the map; they only change the colour of the ground. Campfires
show on the minimap once seen, and monsters killed on the plains stay dead. No monster lives in the village, and no camp stands in it or the grass round it.
Tune → World holds the knobs of the plains and starts a new world or the same seed again. The dungeon floors: oddly
shaped rooms, some with pillars for cover, mixed with hand-made vaults (moats, pools, lava rivers, a treasure
closet). Deep water stops feet but not shots; lava burns. You only see what's in your line of sight; explored
areas stay dimmed on the map, and a minimap (top left) charts what you've seen: the stairs, doors, water and
lava, and you. Items sometimes lie on the floor (the same ones for the same world seed), and some rooms are tougher than they should be. The monsters of a room are a band that sleeps there (a "z" over
their heads) or wanders slowly about it; one notices you only when it can see you close by (4 cells asleep, 9
wandering) or when you hurt it, shows a "!", and comes for you. Your attacks and blasts make noise that wakes monsters
within 8 cells, even through walls, and a monster that notices you shouts, waking the rest of its band and anyone within 8 cells, who shout in turn,
so a careless fight can pull in a nearby band. You can escape a chase: a monster gives up after 5 seconds without
seeing you, or when you are 24 cells from its home, checks where it last saw you and walks home, noticing you again if it sees you on the way. Rooms don't lock, so you
can sneak past or pick your fight. Loot is earned, not handed out:
clearing a room leaves nothing, so new gear (a weapon, or a utility: Dash, Shield, Blink, Frost Nova) is found
hidden on the floor or, rarely, dropped. Enemies carry the same weapons you do and fight the way their
weapon wants, as a team: they take turns to attack, spread out to flank you and aim ahead of where you run; a red preview shows where an attack is about to land, so you can step aside. About one in fifty drops
its weapon. Rooms get tougher the deeper you go, and each floor more than the last. Find the gold stairs (in the room
farthest from the start, usable once it is clear) to go down, keeping your gear, health and potions; the
fifth floor's stairs lead out. On every floor you arrive on silver stairs that lead back up, onto the gold
stairs of the floor above (the first floor's onto the mausoleum). The dungeon remembers: monsters you killed stay dead, opened chests stay open, items
you took stay gone, items you dropped stay where they fell and the map stays explored (the plains too). Monsters you left hurt
heal while you are away (Tune → Enemies → Heal while away). Defeating monsters earns experience; every level adds maximum health. If you die, you start over on the plains of a new world (a new seed) with the Dagger, the Dash and a Potion of
Healing.

## Play on a phone

`tools/web_playtest/package.sh <godot-binary>` exports the Web build and packs it into `build/web_playtest/`.
`toto-playtest.html` is a touch-friendly loader page that works on static hosts that serve only web file types.
Web export needs Godot's 4.4.1 export templates installed.

## Test

```sh
godot --headless --import
godot --headless -s addons/gut/gut_cmdln.gd
```

Tests use [GUT](https://github.com/bitwes/Gut), vendored in `addons/gut`.

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
  lava damage (`LavaBurn`), how the dungeon dresses up (`DungeonDecor`: stone tints, cracks, pillars,
  torches and their light), moving liquids (`LiquidView`), room rules: enemies left per room, and the lock
  of rooms marked as locking (`DungeonProgress`), and the rendering of floors, walls and doors (`DungeonView`, `Door`)
- `scripts/dungeon/generation/village` – the village, stamped in the plains' middle: `VillageGenerator` runs `VillagePalisade`,
  `VillageStreets`, `VillageLotPacker` (with the hand-written `VillageLots`), `VillageProps` and `VillageRules` (`Village`, in
  `scripts/dungeon`, holds its map letters and what a map knows of it)
- `scripts/dungeon/generation/quadrant` – the plains: `QuadrantGenerator` runs the steps (`QuadrantGround`,
  `QuadrantBorder`, `QuadrantExits`, `SetPiecePlacer`, `QuadrantRules`) over a `QuadrantGrid` by a plain-data
  `QuadrantRecipe` (every number a Knob), stamping hand-made `SetPiece`s (`SetPieces`: the crypt entrance, camps and campfires; `CampCrews` fills each camp by how far out it lies; `QuadrantRoads` lays the dirt roads round them)
- `scripts/dungeon/generation` – the seeded generator (`DungeonGenerator`) and its pure parts: `Branch` and
  `BranchLook` (what each place is: the plains, Dungeon, Lair, Orcish Mines, Crypt, Depths), `RoomGraph`
  (which rooms and links), `RoomShapes` (floor plans, caves and pillars), `Vaults` (hand-made set pieces),
  `DungeonDifficulty` (enemies by depth, out-of-depth rooms)
- `scripts/controls` – pure input math (`StickMath`, `AimGesture`, `AutoAim`, `MouseAim`, `TouchZones`) and `InputMode` (touch or
  keyboard and mouse)
- `scripts/equipment` – what the buttons do, as plain data: `Item`s, which are a `Weapon` (`MagicMissile`, `Knuckles`, `LightningBolt`, `MephiticCloud`,
  `Fireball`, `Crossbow`, `Bow`, or an `ArcWeapon` archetype: `Dagger`, `Sword`, `Battleaxe`) or a `Utility` (`Dash`, `Shield`, `Blink`, `FrostNova`, `Beckoning`). Each declares its own tunable `Knob`s
- `scripts/combat` – what an attack or utility does (`Shot`, `Slash`, `Nova`, `UtilityEffect`, `TickClock` for lingering effects, `PoisonStatus` so poison clouds don't stack, `ChainFalloff` for the Lightning Bolt's weaker jumps, `Charge`: seconds held to strength), when a weapon fires
  (`Wielder`: ammo and wind-up, for the player and enemies alike), how enemies fight (`EnemyTactics`: moving, flanking, aiming ahead, where to wander), when a calm monster
  notices the hero and who hears a noise or shout (`Awareness`), what they are doing (`EnemyBrain`, a small state machine: asleep, wander,
  noticing, idle, hunt, position, wind up, recover, check, return; `Awareness` also decides when a hunter gives up), how a band fights as a team (`Squad`: taking turns, flank
  spots),
  how aims are previewed (`AimShape`, `AimPreview`), and pure geometry (`HitShapes`, `Spread`, `ArcPolygon`)
- `scripts/monsters` – `Monster` (a kind of enemy: race, weapon, health, speed, size, strength), the
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
- `scripts/actors` – `Player`, `Enemy`, `Projectile`, `Explosion`, `LingeringZone` (`PoisonCloud`, `BurningGround`), `SlashEffect`, and the loot on the floor
  (`PickupArea`, `Chest`, `ItemDrop`). The player holds no input code
- `scripts/view3d` – how the game is shown: the 2D world runs the game and `WorldView3D` shows it in 3D.
  `GroundView` lays the 2D plane on the floor (floor, aim previews, telegraphs, fog), `MapView3D` stands walls
  and closed doors on it (`VillageView3D` the village's models, see-through when they hide the hero), and `Puppets` moves a 3D stand-in with each actor. Pure parts: `WorldSpace`
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
  and everything on it, freed whole on leaving); `RunSummary` (the end-of-run lines); `Place` ("the village" or the branch, for the HUD and banner); `Experience`: levels from
  kills, each adding maximum health
- `scripts/main.gd` – composition root: wires controls, HUD and menus once, builds the run's current map
  (rebuilt in place on the stairs and on starting over, then its record applied; the record is written on leaving),
  routes controls to the player and applies the room rules (a camp's monsters, or the monsters of a room, are a band: settled at its home, the campfire or the room's middle,
  and woken by the hero's noise and by each other's shouts, a band always hearing its own)
- `tests/unit`, `tests/integration` – behaviour tests
