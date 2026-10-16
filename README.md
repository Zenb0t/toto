# Toto

A small real-time dungeon crawler for mobile: Dungeon Crawl Stone Soup's "the RNG shapes your build" meets
Brawl Stars' twin-stick touch combat. Built with Godot 4.4. It plays on a flat 2D plane and is shown in 3D, with
a tilted Brawl Stars-style camera (placeholder models for now).

Design decisions and the roadmap are in [`docs/design.md`](docs/design.md).

## Play

Open the project in Godot 4.4+ and press F5. The window runs in landscape and treats the mouse as a finger.

| Input | Action |
| --- | --- |
| Touch the left half of the screen and drag | Move (floating stick) |
| Tap the **weapon** button | Auto-aim at the nearest enemy and attack |
| Drag from the weapon button, then release | Aim manually and fire |
| **Utility** button (DASH, SHIELD, BLINK, FROST) | Same tap / drag gesture; Shield and Frost Nova don't need aiming |
| **Potion** buttons (under the weapon switch) | Drink one: Healing, Haste or Might. Walk over potions to pick them up |
| Walk onto a chest or a dropped item | Shows what it is; **Take** swaps it for yours, **Leave** keeps yours |
| **Weapon: …** (top right) | Testing aid: switch between Magic Missile, Sword, Fireball and Crossbow |
| **II** (top right) or Esc | Pause menu: resume, customize controls, tune gameplay, restart run |
| WASD | Move (desktop only; a mouse is just one finger) |

**Customize controls** pauses the game and lets you drag the stick and buttons where you want them, and resize
the one you picked with the slider. Done saves the layout on the device, so it survives restarts and reloads.

**Tune gameplay** exposes the numbers that shape the feel (move speed, the weapon's cooldown, wind-up, shot
speed, range and damage, the dash, enemy speed and health, each button's aim dead zone, and the camera: tilt,
distance, field of view, look-ahead and wall height). Every weapon has
its own settings; the screen shows the equipped one's. Changes apply live and are saved on Done.
**Send to Claude** (phone playtest page on claude.ai only) saves them as JSON where Claude can read them.

A run is a descent through 5 floors, each a new dungeon (its seed is shown in the pause menu), inspired by
Dungeon Crawl Stone Soup: oddly
shaped rooms, some with pillars for cover, mixed with hand-made vaults (moats, pools, lava rivers, a treasure
closet). Deep water stops feet but not shots; lava burns. You only see what's in your line of sight; explored
areas stay dimmed on the map. Items sometimes lie on the floor, and some rooms are tougher than they should be. Entering a room with enemies locks its doors until you defeat them all, and clearing it leaves a
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

## Layout

- `scripts/core` – engine-agnostic building blocks (`Health`, `Cooldown`)
- `scripts/dungeon` – the ASCII map format (`DungeonMapParser`; enemy letters pick their monster, `>` exit,
  `~` water, `L` lava, `*` floor item), enemy navigation (`Pathfinder`), fog of war (`Exploration`, `FogView`),
  lava damage (`LavaBurn`), room-lock rules
  (`DungeonProgress`), and the rendering of floors, walls and doors (`DungeonView`, `Door`)
- `scripts/dungeon/generation` – the seeded generator (`DungeonGenerator`) and its pure parts: `RoomGraph`
  (which rooms and links), `RoomShapes` (floor plans and pillars), `Vaults` (hand-made set pieces),
  `DungeonDifficulty` (enemies by depth, out-of-depth rooms)
- `scripts/controls` – pure input math (`StickMath`, `AimGesture`, `AutoAim`)
- `scripts/equipment` – what the buttons do, as plain data: `Item`s, which are a `Weapon` (`MagicMissile`, `Sword`,
  `Fireball`, `Crossbow`) or a `Utility` (`Dash`, `Shield`, `Blink`, `FrostNova`). Each declares its own tunable `Knob`s
- `scripts/combat` – what an attack or utility does (`Shot`, `Slash`, `Nova`, `UtilityEffect`), when a weapon fires
  (`Wielder`: cooldown and wind-up, for the player and enemies alike), how enemies fight (`EnemyTactics`),
  how aims are previewed (`AimShape`, `AimPreview`), and pure geometry (`HitShapes`, `Spread`, `ArcPolygon`)
- `scripts/monsters` – `Monster` (a kind of enemy: race, weapon, health, speed, size, strength) and the
  `Bestiary` that lists them with their map letters
- `scripts/potions` – consumables: `Potion` (`HealingPotion`, `HastePotion`, `MightPotion`) and the `PotionBelt`
  that carries them
- `scripts/loot` – `LootTable`: what drops (pure rules, given a random generator)
- `scripts/tuning` – `Tuning` (generic knobs with limits, defaults and JSON export), `Knob`, and `GameTuning`
  (which knobs exist and how they become gear)
- `scripts/settings` – saved settings: `ControlLayout`, `GameSettings` (what is saved, and how) on top of
  `SettingsStore` (sections in a ConfigFile)
- `scripts/ui` – touch widgets (`TouchStick`, `AimButton`, `TouchControls`), `PauseMenu`, `LayoutEditor`,
  `TuningPanel`, `TuningSender`, `LootCard`
- `scripts/actors` – `Player`, `Enemy`, `Projectile`, `Explosion`, `SlashEffect`, and the loot on the floor
  (`PickupArea`, `Chest`, `ItemDrop`). The player holds no input code
- `scripts/view3d` – how the game is shown: the 2D world runs the game and `WorldView3D` shows it in 3D.
  `GroundView` lays the 2D plane on the floor (floor, aim previews, telegraphs, fog), `MapView3D` stands walls
  and closed doors on it, and `Puppets` moves a 3D stand-in with each actor. Pure parts: `WorldSpace`
  (2D plane to 3D), `CameraFraming` (the Brawl Stars-style camera), `GroundWindow` (which part of the plane
  the floor texture shows). `models/` holds the placeholder models
- `scripts/run` – `RunState`: what a run carries down the stairs (floor, gear, health, potions, experience);
  `Experience`: levels from kills, each adding maximum health
- `scripts/main.gd` – composition root (one floor): wires controls to the player and applies the room rules
- `tests/unit`, `tests/integration` – behaviour tests
