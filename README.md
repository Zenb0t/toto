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
| Touch the left half of the screen and drag | Move (floating stick) |
| Tap the **weapon** button | Auto-aim at the nearest enemy and attack |
| Drag from the weapon button, then release | Aim manually and fire. The button floats like the stick: touch anywhere in the faint circle around it and it jumps under your finger; the aim is measured from where you touched. Dragging back to the middle buzzes (phones that support it); letting go there cancels, as in Brawl Stars |
| **Utility** button (DASH, SHIELD, BLINK, FROST) | Same tap / drag gesture; Shield and Frost Nova don't need aiming |
| **Potion** buttons (under the weapon switch) | Drink one: Healing, Haste or Might. Walk over potions to pick them up |
| Walk onto a chest or a dropped item | Shows what it is; **Take** swaps it for yours, **Leave** keeps yours |
| **Map** (top left) | Show or hide the minimap; the choice is remembered |
| **Weapon: …** (top right) | Testing aid: cycle through every weapon |
| **II** (top right) | Pause menu: resume, customize controls, tune gameplay, restart run |

**Keyboard and mouse**

| Input | Action |
| --- | --- |
| WASD or arrow keys | Move |
| Mouse | Aim at the cursor (Fireball and Mephitic Cloud land on it) |
| Left click | Attack; hold to keep attacking |
| Right click or Space | Utility, toward the cursor |
| 1, 2, 3 | Drink a potion |
| E | Take the item you're standing on |
| M | Show or hide the minimap |
| Q | Next weapon (testing aid) |
| Esc | Pause menu; in the Tune screen, back one page |

**Customize controls** pauses the game and lets you drag the stick and buttons where you want them, and resize
the one you picked with the slider. Done saves the layout on the device, so it survives restarts and reloads.

**Tune gameplay** exposes the numbers that shape the feel, sorted into a menu: Player, Weapons, Utilities,
Potions, Enemies, Loot, Controls (each button's aim dead zone) and Camera (tilt, distance, field of view,
look-ahead, wall height). Weapons, Utilities and Potions list every item, so any of them can be tuned (the equipped
one is marked). Entries you changed show in gold; Reset resets the page you're on. Changes apply live and are
saved on Done.
**Send to Claude** (phone playtest page on claude.ai only) saves them as JSON where Claude can read them.

A run is a descent through 5 floors, each a different branch (the Dungeon, the Lair's caves, the Orcish
Mines, the Crypt, the Depths) and a new dungeon (its seed is shown in the pause menu), inspired by
Dungeon Crawl Stone Soup: oddly
shaped rooms, some with pillars for cover, mixed with hand-made vaults (moats, pools, lava rivers, a treasure
closet). Deep water stops feet but not shots; lava burns. You only see what's in your line of sight; explored
areas stay dimmed on the map, and a minimap (top left) charts what you've seen: the stairs, doors, water and
lava, and you. Items sometimes lie on the floor, and some rooms are tougher than they should be. Entering a room with enemies locks its doors until you defeat them all, and clearing it leaves a
chest with a random weapon or utility (Dash, Shield, Blink, Frost Nova), and often a potion. Enemies carry the same weapons you do and fight the way their
weapon wants; a red preview shows where an attack is about to land, so you can step aside. They sometimes drop
their weapon. Rooms get tougher the deeper you go, and each floor more than the last. Find the gold stairs (in the room
farthest from the start, usable once it is clear) to go down, keeping your gear, health and potions; the
fifth floor's stairs lead out. Defeating monsters earns experience; every level adds maximum health. If you die, you start over on floor 1 with Magic Missile, the Dash and a Potion of
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
[KayKit Dungeon Remastered](https://kaylousberg.itch.io/kaykit-dungeon-remastered) by Kay Lousberg (CC0), in
`assets/` with their licenses.

## Layout

- `scripts/core` – engine-agnostic building blocks (`Health`, `Cooldown`)
- `scripts/dungeon` – the ASCII map format (`DungeonMapParser`; enemy letters pick their monster, `>` exit,
  `~` water, `L` lava, `*` floor item), enemy navigation (`Pathfinder`), fog of war (`Exploration`, `FogView`),
  lava damage (`LavaBurn`), how the dungeon dresses up (`DungeonDecor`: stone tints, cracks, pillars,
  torches and their light), moving liquids (`LiquidView`), room-lock rules
  (`DungeonProgress`), and the rendering of floors, walls and doors (`DungeonView`, `Door`)
- `scripts/dungeon/generation` – the seeded generator (`DungeonGenerator`) and its pure parts: `Branch` and
  `BranchLook` (what each floor is: Dungeon, Lair, Orcish Mines, Crypt, Depths), `RoomGraph`
  (which rooms and links), `RoomShapes` (floor plans, caves and pillars), `Vaults` (hand-made set pieces),
  `DungeonDifficulty` (enemies by depth, out-of-depth rooms)
- `scripts/controls` – pure input math (`StickMath`, `AimGesture`, `AutoAim`, `MouseAim`, `TouchZones`) and `InputMode` (touch or
  keyboard and mouse)
- `scripts/equipment` – what the buttons do, as plain data: `Item`s, which are a `Weapon` (`MagicMissile`, `Sword`, `Battleaxe`, `LightningBolt`, `MephiticCloud`,
  `Fireball`, `Crossbow`) or a `Utility` (`Dash`, `Shield`, `Blink`, `FrostNova`, `Beckoning`). Each declares its own tunable `Knob`s
- `scripts/combat` – what an attack or utility does (`Shot`, `Slash`, `Nova`, `UtilityEffect`), when a weapon fires
  (`Wielder`: cooldown and wind-up, for the player and enemies alike), how enemies fight (`EnemyTactics`),
  how aims are previewed (`AimShape`, `AimPreview`), and pure geometry (`HitShapes`, `Spread`, `ArcPolygon`)
- `scripts/monsters` – `Monster` (a kind of enemy: race, weapon, health, speed, size, strength) and the
  `Bestiary` that lists them with their map letters
- `scripts/potions` – consumables: `Potion` (`HealingPotion`, `HastePotion`, `MightPotion`) and the `PotionBelt`
  that carries them
- `scripts/loot` – `LootTable`: what drops (pure rules, given a random generator)
- `scripts/tuning` – `Tuning` (generic knobs with limits, defaults and JSON export), `Knob`, `TuningSection` (an
  entry of the Tune menu) and `GameTuning` (which knobs exist, how the menu sorts them, and how they become gear)
- `scripts/settings` – saved settings: `ControlLayout`, `GameSettings` (what is saved, and how) on top of
  `SettingsStore` (sections in a ConfigFile)
- `scripts/ui` – touch widgets (`TouchStick`, `AimButton`, `TouchControls`), `KeyboardMouseControls`, `PauseMenu`, `LayoutEditor`,
  `TuningPanel`, `TuningSender`, `LootCard`, `MinimapView` (with `MinimapPainter`, which paints the picture)
- `scripts/actors` – `Player`, `Enemy`, `Projectile`, `Explosion`, `SlashEffect`, and the loot on the floor
  (`PickupArea`, `Chest`, `ItemDrop`). The player holds no input code
- `scripts/view3d` – how the game is shown: the 2D world runs the game and `WorldView3D` shows it in 3D.
  `GroundView` lays the 2D plane on the floor (floor, aim previews, telegraphs, fog), `MapView3D` stands walls
  and closed doors on it, and `Puppets` moves a 3D stand-in with each actor. Pure parts: `WorldSpace`
  (2D plane to 3D), `CameraFraming` (the Brawl Stars-style camera), `GroundWindow` (which part of the plane
  the floor texture shows). `models/` holds the models: `CharacterModel` (KayKit characters, animated) and
  `CharacterLook` (who wears what), and the simple ones (chests, loot, shots, torches, the stairs' arch)
- `scripts/run` – `RunState`: what a run carries down the stairs (floor, gear, health, potions, experience);
  `Experience`: levels from kills, each adding maximum health
- `scripts/main.gd` – composition root (one floor): wires controls to the player and applies the room rules
- `tests/unit`, `tests/integration` – behaviour tests
