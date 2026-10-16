# Toto — Design Notes

Living document. It records **decisions** and the reasons behind them, so they don't get lost in chat history.

## Pitch

A small real-time dungeon crawler for mobile. It combines Dungeon Crawl Stone Soup's dungeons, runs and
"the RNG shapes your build" with Brawl Stars' fast twin-stick combat and touch aiming.

## Current goal: validate the core loop

> Explore a room → fight → get random gear → the gear changes how you fight → next room → clear the dungeon or die.

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
| Dungeon | One small handcrafted layout (`TestDungeon`). Same every run; only the loot varies | Playtests stay comparable |
| Rooms | Entering a room with enemies locks its doors until they're all defeated | Forces fights and gives clear pacing |
| Aiming | Brawl Stars style: **tap** = auto-aim at the nearest enemy, **drag** = manual aim with a preview, **release** = fire | Proven on touch screens |
| Movement | Floating stick: it appears wherever the left thumb lands | Standard for mobile action games |

## Equipment (planned)

Every item defines how it **aims** (shape + range) and what it **does**. Items change behaviour, not just stats.

| Weapon | Behaviour | Aim shape |
| --- | --- | --- |
| Sword | Short melee arc in front of you | Cone |
| Fireball | Slow projectile that explodes in an area on impact | Line + impact circle |
| Crossbow | A spread of bolts | Fan of lines |

Utilities (first ideas, not final): dash, shield, heal. A dash currently stands in on the utility button.

## Enemies (planned)

Three types, each answered best by different gear: **rusher** (melee chaser, the current enemy),
**ranged**, and **tank**.

## Explicitly deferred

Art and audio, procedural generation, rarity tiers, stat depth, meta-progression, multiplayer.

## Roadmap

1. ~~Design doc~~
2. ~~Fixed test dungeon with room locks~~
3. ~~Touch controls (move stick, aim buttons, auto-aim)~~
4. Equipment model: weapon and utility data drive what the buttons do
5. First item pool: sword, fireball, crossbow + utilities
6. Loot: room chests, rare drops, replace-on-pickup compare
7. Enemy types: rusher, ranged, tank
8. Web export for playtesting on a phone
