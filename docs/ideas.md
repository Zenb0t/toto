# Toto — Ideas Backlog

Raw ideas, written so each one can become a GitHub issue later (title, why, sketch, done when). Nothing here is
decided yet; once an idea is picked, its decision moves into `design.md`. Epics B, C, E and F still need a
review before they're filed; brainstorm-only ideas become `idea` issues.

Pitch, unchanged: **Brawl Stars meets Dungeon Crawl Stone Soup.** The core loop (fight → random gear → play
differently) works. The next big step is the world around it: **open areas and larger maps instead of a chain
of locked rooms**, monsters that come in groups, bosses, and numbers that are easy to tune.

Suggested order (each epic leans on the ones before it):

1. **Epic D: Health and damage scale** — every later epic gets tuned against these numbers, so change them first.
2. **Epic A: Open-world generation** — the biggest change to how a floor plays.
3. **Epic B: Monster bands** — needs A, since bands replace "one squad per room".
4. **Epic C: Bosses** — needs B (summoned adds) and A (arenas placed in open maps).
5. **Epic E: Potions** — needs A, since loot pacing changes without a chest per room.
6. **Epic F: Brawl Stars flavour** — independent, pick any time.

---

## Epic D: Health and damage scale

### D1. Scale health and damage up (×10 or ×100)

**Done** (×100, commit 47b4d16, on `main`). D2 and D3 are still open.

**Why.** Health is 2–14 and damage 1–4. At that scale, the smallest change is huge: +1 damage doubles a Magic
Missile, Might's "+1" is worth 50% on one weapon and 25% on another, and Tune → Health × rounds a kobold's 2
health to 2 or 3 with nothing in between. Balancing in 10% steps is impossible.

**Sketch.**
- Multiply every health, damage, heal and burn value by one factor (×100 reads like Brawl Stars: a 300-health
  kobold, a 1400-damage axe sweep; ×10 keeps damage numbers short on a phone).
- Change the defaults in the classes (`Monster`, `Weapon`, `Player`, potions, lava) rather than adding a global
  multiplier, so there is still one source of truth.
- Tests that check ratios ("an ogre takes several hits", "lava hurts") keep passing; tests that check exact
  numbers get rewritten as ratios where that's what they mean.

**Done when.** Every number scaled; the game plays the same at default settings; damage popups and the health bar
read well at the new size.

### D2. Make bonuses relative

**Why.** "+1 damage" and "restores 4 health" stop making sense once max health grows with levels and numbers scale.

**Sketch.** Might: +X% damage. Healing: restores X% of max health (or a flat amount plus a percentage). Ogre's
"+1 damage on every hit" becomes a strength multiplier. Each one stays a `Knob`.

### D3. Experience per monster, not per health point

**Why.** `main.gd` gives experience equal to the monster's max health. Rescaling health (D1) or adding a boss with
huge health would wreck levelling.

**Sketch.** Each monster gets an `experience` value in the `Bestiary` (starting from today's health values, so
levelling feels the same). `Experience` stays a pure class.

---

## Epic A: Open-world generation (more like Dungeon Crawl)

**Superseded.** Epic A became a small open world: a 3×3 grid of quadrants, starting with the village quadrant
and a 3-level crypt. Its decisions live in the epic map, issue #3 (with decision tickets as sub-issues). The other
quadrants, dungeons and villagers are `idea` issues #9, #10, #11. The notes below are kept as background.

### A1. Larger, open layouts

**Why.** Open areas and large maps are more fun than a chain of rooms. Dungeon Crawl mixes layout styles per
level: caves, open areas with scattered buildings, classic rooms, all on large maps.

**Sketch.** New layout generators behind one interface, each turning a seed into the same ASCII map format (so the
parser, terrain, fog and minimap keep working):
- **Cavern**: cellular-automata caves, smoothed, with the largest connected region kept (the Lair, the Mines).
- **Open field**: a large open area with scattered ruins, pillars, pools, lava and vaults dropped in (the Dungeon,
  the Depths).
- **Classic rooms**: today's `RoomGraph`, kept as one option among others.

Each `Branch` picks its layouts and their weights. Map size becomes a knob per branch.

**Done when.** A floor can be generated as one large open space; the existing generation tests (same seed same
map, everything reachable, start is quiet, exit is guarded) pass on every layout.

**Open questions.** Target map size? (Today's 4×3 slots are roughly 80×60 cells; Dungeon Crawl is 80×70 but with a
far smaller view.) How many screens across should a floor be on a phone?

### A2. Monsters notice you instead of doors locking

**Why.** Door locks only work with rooms. In an open map, fights should start when monsters notice you.

**Sketch.** Dungeon Crawl style awareness, as a pure class (`Awareness`?):
- Monsters start **asleep**, **wandering** or **awake**.
- Each tick a monster may notice the player based on distance, line of sight and noise (attacking makes noise).
- Noticing wakes the monster's band (B1).
- `EnemyBrain` gets an Asleep/Wander state before Hunt.

Locks stay only where they still add something: vaults and boss arenas (C2).

**Done when.** No door locks in open layouts; sneaking past a sleeping group is possible; attacking one group can
pull a nearby one.

### A3. New exit rules

**Why.** "Stairs in the farthest room, usable once it's clear" depends on rooms.

**Sketch.** Options to pick from:
- Stairs far from the start, guarded by a band, always usable (Dungeon Crawl: stairs are never locked).
- Two or three down stairs per floor (Dungeon Crawl has three), so there is a choice of route.
- The last floor's exit is behind the boss (C1).

### A4. Loot without a chest per room

**Why.** A guaranteed chest per cleared room sets the pacing today. Open maps need another rhythm.

**Sketch.** Chests become a reward for clearing a band (the band leader drops one), vaults keep their treasure,
and floor items get scattered by density (items per 100 cells) instead of "half of the dead ends". `LootTable`
stays the rule; only placement changes.

### A5. Performance on a large map

**Why.** A phone browser has to run fog, minimap, pathfinding and many monsters on a far bigger grid.

**Sketch.**
- Monsters far from the player sleep or update rarely (activation radius).
- Pathfinding: one shared flow field toward the player instead of an A* path per monster.
- Fog and minimap: redraw only cells that changed, in chunks.
- A perf test scene that reports frame time on the largest map.

### A6. Vaults placed anywhere

**Why.** Vaults are currently whole rooms. In Dungeon Crawl, vaults are stamped into any layout.

**Sketch.** A vault declares its footprint and entrances; the generator finds a free spot in any layout, carves it
in and connects its entrances to the floor around it. New vault ideas: goblin camp (a band around a fire), ruined
tower, bridge over a lava chasm, boss arena (C2).

---

## Epic B: Monster bands

### B1. Bands instead of one squad per room

**Why.** Groups of goblins with different weapons are more fun than a random mix per room, and `Squad` today is
tied to a room.

**Sketch.** A **band** is a leader plus followers (Dungeon Crawl's bands):
- `Band` data: leader kind, follower kinds and counts, e.g. *goblin warband* = goblin chief (sword) + 2 goblin
  archers (crossbow) + 1 goblin (magic missile).
- Followers stay near the leader while wandering and share one `Squad` (attack rhythm, flank spots) once awake.
- `DungeonDifficulty` picks bands by depth instead of single monsters.

**Done when.** Floors spawn bands; a band moves and fights as a group; the attack rhythm (at most 2 winding up)
works per band.

### B2. A race carries a pool of weapons

**Why.** Today each monster kind has one weapon. A goblin with a sword should fight differently from a goblin
with a crossbow, and the player should see which one is which.

**Sketch.** `Monster` gets a weapon pool with weights (goblin: sword, crossbow, magic missile). The weapon shows
on the model (blade, bow, staff) so the player can read the band from afar. `EnemyTactics` already adapts to the
weapon, so behaviour comes for free.

### B3. Band roles

**Why.** Brawl Stars teams work because roles differ: tank, damage, support.

**Sketch.** Followers get roles that tweak their tactics: a **shield-bearer** stands between the player and the
archers, a **shaman** heals or hastes allies (a monster utility), archers keep behind the front line.

---

## Epic C: Bosses

### C1. The Giant becomes a boss

**Why.** The ogre/giant is already slow, huge and hits hard; it has the presence of a boss more than of a regular
monster.

**Sketch.**
- One Giant per run, on the last floor (or one boss per branch, see C3).
- Boss health bar at the top of the HUD, with its name.
- Attack patterns, each telegraphed big and red: **stomp** (a shockwave ring to jump out of with Dash/Blink),
  **boulder throw** (lobbed like the fireball, lands where you stand), **sweep** (today's battleaxe, wider),
  **roar** (calls a goblin band, B1).
- Phases: below 50% health it gets faster and stomps more often.
- Guaranteed good drop.

**Done when.** The Giant fight is beatable with the starter kit but hard; every attack can be dodged.

### C2. Boss arena

**Sketch.** A vault (A6) the boss waits in; entering seals it (the one place door locks stay), the exit opens on
the boss's death.

### C3. A boss per branch

**Sketch.** Dungeon Crawl's uniques: a named monster per branch. Lair: a goblin warchief and his band. Mines: an orc
warlord. Crypt: a lich. Depths: the Giant. Each reuses band and attack-pattern pieces from B and C1.

---

## Epic E: Potions

### E1. Potion economy for open maps

**Why.** Healing only comes from potions, and potions come partly from chests next to each room. With A4 the supply
changes and needs retuning.

**Sketch.** Decide how many healing potions a floor should give on average, then make `LootTable` place that many
(by density and from band leaders). A run-wide test checks the average over many seeds.

### E2. More potion kinds

Ideas, each a small issue:
- **Curing**: removes poison (needs poison on the player first) and heals a little.
- **Resistance**: halves fire and lava damage for a while.
- **Invisibility**: monsters lose track of you (needs A2's awareness).
- **Berserk**: big damage boost and speed, but you can't use your utility; exhausted afterwards.
- **Magic**: refills ammo and resets the utility cooldown.
- **Heal over time** vs **burst heal**: two healing potions with different uses.

### E3. Unknown potions (Dungeon Crawl's identification)

**Why.** Drinking an unknown potion is one of Dungeon Crawl's best "the RNG shapes your run" moments.

**Sketch.** Each run shuffles potion colours; a potion is unknown until drunk once (or until a band drops one you
see used). Keep it light for mobile: no scrolls of identify, and bad potions are mild (slow for 3 s, not death).

**Open question.** Does this fit quick phone sessions, or is it friction?

### E4. Potion belt UI for more kinds

**Why.** One button per kind held works for 3 kinds, not for 8.

**Sketch.** A fixed number of quick slots (3), with a small picker to choose what sits in them; or one potion
button that opens a radial menu.

---

## Epic F: Brawl Stars flavour

### F1. Tall grass

**Why.** Bushes are one of Brawl Stars' best map features, and they fit open maps and sneaking past sleeping bands
(A2).

**Sketch.** A terrain cell (`"`, like Dungeon Crawl's plants) that hides whoever stands in it from anyone not
close by. Monsters lose track of a player who ducks into it.

### F2. A super that charges by hitting

**Why.** Brawl Stars' super rewards aggression; a utility on a plain cooldown rewards waiting.

**Sketch.** The utility charges from damage dealt (with a slow trickle over time as well), so playing well unlocks
it sooner. Could replace the cooldown entirely or only for some utilities.

### F3. Breakable cover

**Sketch.** Crates and barrels (Brawl Stars' walls, Dungeon Crawl's rubble) that block shots until broken by a
blast or the battleaxe. Some hide a potion.

### F4. Weapon on the model

**Sketch.** Every character, player included, holds its weapon visibly. Needed by B2 anyway.

---

## Process (later)

When it's time to turn these into issues, follow a PRD → issues flow (in the style of Matt Pocock's skills): write
a short PRD per epic, split it into thin vertical slices (each one playable on the phone playtest), one issue per
slice, with labels per epic. That setup can live in the repo later.

## Open questions

- Map size target, and how many floors (still 5?) once each floor is much larger.
- Giant: only the final boss, or one boss per branch?
- Health scale: ×10 or ×100?
- Keep any locked-room fights in open maps (vaults, arenas), or none at all?
- Out-of-combat health regeneration: still none? Larger maps mean longer stretches between potions.
