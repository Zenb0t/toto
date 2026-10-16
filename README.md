# Toto

A small real-time dungeon crawler for mobile: Dungeon Crawl Stone Soup's "the RNG shapes your build" meets
Brawl Stars' twin-stick touch combat. Built with Godot 4.4.

Design decisions and the roadmap are in [`docs/design.md`](docs/design.md).

## Play

Open the project in Godot 4.4+ and press F5. The window runs in landscape and treats the mouse as a finger.

| Input | Action |
| --- | --- |
| Touch the left half of the screen and drag | Move (floating stick) |
| Tap the **weapon** button (WAND) | Auto-aim at the nearest enemy and fire |
| Drag from the weapon button, then release | Aim manually and fire |
| **Utility** button (DASH) | Same tap / drag gesture |
| **II** (top right) or Esc | Pause menu: resume, customize controls, tune gameplay, restart run |
| WASD | Move (desktop only; a mouse is just one finger) |

**Customize controls** pauses the game and lets you drag the stick and buttons where you want them, and resize
the one you picked with the slider. Done saves the layout on the device, so it survives restarts and reloads.

**Tune gameplay** exposes the numbers that shape the feel (move speed, the weapon's cooldown, wind-up, shot
speed, range and damage, the dash, enemy speed and health). Changes apply live and are saved on Done.
**Export** shares them as JSON: in the phone playtest page you can copy them or send them straight to Claude.

Entering a room with enemies locks its doors until you defeat them all. Clear the dungeon to win. If you die, you start over.

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
- `scripts/dungeon` – the ASCII map format (`DungeonMapParser`, `TestDungeon`), room-lock rules
  (`DungeonProgress`), and the rendering of floors, walls and doors (`DungeonView`, `Door`)
- `scripts/controls` – pure input math (`StickMath`, `AimGesture`, `AutoAim`)
- `scripts/equipment` – what the buttons do: `Weapon` (fires `Shot`s) and `Utility`, plain data objects
- `scripts/tuning` – `Tuning` (generic knobs with limits, defaults and JSON export) and `GameTuning`
  (which knobs exist and how they become gear)
- `scripts/settings` – saved settings: `ControlLayout`, `GameSettings` (what is saved, and how) on top of
  `SettingsStore` (sections in a ConfigFile)
- `scripts/ui` – touch widgets (`TouchStick`, `AimButton`, `TouchControls`), `PauseMenu`, `LayoutEditor`,
  `TuningPanel`, `TuningExport`
- `scripts/actors` – `Player`, `Enemy`, `Projectile`. The player holds no input code
- `scripts/main.gd` – composition root: wires controls to the player and applies the room rules
- `tests/unit`, `tests/integration` – behaviour tests
