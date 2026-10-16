# Toto

A small real-time dungeon crawler: Dungeon Crawl Stone Soup's procedural dungeons and permadeath-style runs,
with Brawl Stars' twin-stick, fast action. Built with Godot 4.4.

## Play

Open the project in Godot 4.4+ and press F5.

| Input      | Action          |
| ---------- | --------------- |
| WASD       | Move            |
| Mouse      | Aim             |
| Left click | Shoot (hold)    |

Clear every enemy to move to a new floor. If you die, you start over on a fresh one.

## Test

```sh
godot --headless --import
godot --headless -s addons/gut/gut_cmdln.gd
```

Tests use [GUT](https://github.com/bitwes/Gut) (vendored in `addons/gut`).

## Layout

- `scripts/core` – engine-agnostic building blocks (`Health`, `Cooldown`)
- `scripts/dungeon` – seeded generation (`DungeonGenerator`), spawn planning, and the `DungeonView` renderer
- `scripts/actors` – `Player`, `Enemy`, `Projectile`
- `scripts/main.gd` – wires everything together and runs the win/lose loop
- `tests/unit`, `tests/integration` – behaviour tests
