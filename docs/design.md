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
| Platform | Mobile (landscape). Also playable with keyboard and mouse: the game follows whichever was used last (see Keyboard and mouse) | Brawl Stars-style touch play is the target; playtesting on a computer shouldn't feel like using a phone with a mouse |
| Build identity | No heroes. Your build is your equipment, and equipment comes from RNG | DCSS-style "make do with what you find" |
| Equipment slots | **Weapon** (attack button) + **Utility** (second button, on a cooldown) | Smallest set where builds feel different |
| Swap rule | Replace on pickup, with a quick compare. No inventory | Every drop is a decision, and it needs almost no UI |
| Loot sources | Guaranteed chest per cleared room, plus rare enemy drops | Predictable pacing, with occasional surprises |
| Dungeon | Generated each run from a seed shown in the pause menu (see Dungeon generation) | Every run differs, and a map worth keeping (or a broken one) can be reported |
| Goal | Go down 5 floors and out. Each floor's stairs sit in the room farthest from the start and only work once that room is clear. Other rooms are optional | Rewards exploring for loot vs. heading for the exit; Dungeon Crawl's descent |
| Rooms | Entering a room with enemies locks its doors until they're all defeated | Forces fights and gives clear pacing |
| Aiming | Brawl Stars style: **tap** = auto-aim at the nearest enemy, **drag** = manual aim with a preview, **release** = fire. Drag distance is the aim's strength, which weapons that target a spot use as distance. The buttons float like the move stick: a touch anywhere in a catch zone around a button (1.6× its size, Tune → Controls; the nearest button wins where zones overlap) grabs it, and the aim is measured from where the finger landed. Dragging from aiming back into the dead zone buzzes briefly (`Input.vibrate_handheld`, Tune → Controls, 0 = off) and the knob greys out: letting go there cancels, as in Brawl Stars. A plain tap still auto-aims | Proven on touch screens; floating buttons, like Brawl Stars', don't punish a thumb that lands a little off |
| Movement | Floating stick: it appears wherever the left thumb lands, in the left half below the top third of the screen (`ControlLayout.stick_zone`), which is left to the status lines and the Map button | Standard for mobile action games; the stick used to swallow taps on the Map button |
| Look | 3D shown over a 2D game: a fixed, tilted Brawl Stars-style camera; fantasy characters (humans, goblins, dwarfs) later | Brawl Stars' readability, with the game rules untouched |

## Equipment

Every item defines how it **aims** (shape + range) and what it **does**. Items change behaviour, not just stats.

| Weapon | Behaviour | Aim shape |
| --- | --- | --- |
| Magic Missile (starter; id `wand`) | One magic bolt, Dungeon Crawl's first spell | Line |
| Sword | The blade sweeps across an arc in front of you, hitting each enemy once as it passes | Cone |
| Fireball | Lobbed like Barley's bottles in Brawl Stars: drag distance picks the landing spot (a drag to the button's edge throws half as far; dragging on past the button throws up to the max range, 280); arcs over walls and enemies and explodes where it lands, hurting the thrower too | Landing circle at the dragged distance |
| Crossbow | A fan of bolts; strongest up close | Fan of lines |
| Lightning Bolt | Dungeon Crawl's bolt, shot like Jessie's: when it hits an enemy it jumps on to the nearest other enemy within 160, twice (never one it already hit) | Line |
| Mephitic Cloud | Lobbed like the fireball (like Emz's zones): leaves a poison cloud for 3 s that hurts enemies inside every 0.6 s. Doesn't hurt the thrower | Landing circle |
| Battleaxe | Like Frank's hammer: a long wind-up, then a 180° sweep for 400 damage | Cone |
| Knuckles | Like El Primo's fists: a flurry of 4 short, fast punches 0.07 s apart, alternating a little to each side, each thrown from where you stand by then, 50 damage each (two punches to a Magic Missile). Fought bare-handed | Narrow cone |

**Health points, like Brawl Stars.** Health and damage are counted in big numbers (the hero has 1000, a bandit
300, a Magic Missile does 100) rather than Dungeon Crawl's small ones, so weapons can be tuned finely (a punch
does half a missile) and tiers can come later without fractions. Tuned values saved on the old scale (×1) are
multiplied by 100 when loaded (`GameSettings`, knobs marked `Knob.is_points`).

**Ammo, like Brawl Stars.** A weapon holds 3 charges (`Ammo`): each attack spends one, they reload one at a time
(each weapon its own reload time), and there is only a short gap between attacks (0.3 s), so a burst of three is
possible, then a wait. Attacking throws away the charge being reloaded, so a burst gets no bonus shot from
reload progress made between its shots (it used to fit about 4); waiting for a charge to finish pays. Over the hero's head (`HeroBars`): a green health bar with the number on it, and an orange
segment per charge, the reloading one filling up in a darker orange. The attack button only darkens while empty.
Enemies hold one charge that reloads 1.1× slower than the player's (Tune → Enemies: reload slowness), the pace the
playtest settled on (1.6× the old cooldown, from before ammo). Utilities keep a cooldown.

| Utility | Behaviour | Aim |
| --- | --- | --- |
| Dash (starter) | A quick burst of speed where you aim | Line as long as one dash |
| Shield | Blocks all damage (your own blasts included) for a moment | None: tap anywhere |
| Blink | Like Dungeon Crawl's scroll of blinking: an instant hop (140) where you aim. Walls and water stop it short; enemies don't, so it gets you out of a corner | Line as long as the hop |
| Lesser Beckoning | Like Gene's magic hand: a quick bolt that drags the first enemy it hits back to where it was cast, cancelling the attack it was winding up | Line |
| Frost Nova | A burst around you: 100 damage to every enemy in reach, and they act at half speed (moving, winding up, recovering) for 2.5 s. An icy ring on the floor marks a slowed enemy | The burst's circle around you |

**Potions** (consumables, like Dungeon Crawl's). Heal used to be a utility, but healing on a cooldown was too
strong: it made every fight winnable by waiting. Healing is now only from potions, which run out.

| Potion | Effect | How common |
| --- | --- | --- |
| Healing | Restores 400 health | 3 in 5 |
| Haste | Move 1.5× faster for 6 s | 1 in 5 |
| Might | Every attack does +100 damage for 8 s | 1 in 5 |

You carry up to 3 of each kind in the potion belt (buttons under the weapon switch, one per kind held, with
the count); tap one to drink it. Runs start with one Potion of Healing. Potions lie on the floor (half of the
floor finds), sit beside chests (30%), and drop from enemies (10%, when they drop no gear). Walking over one
picks it up; there is nothing to choose, unless that kind is full, then it stays where it is. While haste or
might works, a ring in its colour shows on the floor around the hero. Each potion's numbers are in Tune.

**Model (step 4).** `Weapon` and `Utility` are plain data objects (both `Item`s). Whoever wields a weapon owns
*when* (a `Wielder`: ammo, wind-up, auto-aim tracking); the weapon owns *what* (it turns an aim into `Shot`s).
A utility turns an aim into a `UtilityEffect` (dash, shield time, healing) that the player applies. The buttons show the equipped
item's name and colour. The starter gear is **Magic Missile** (one magic bolt) and a **Dash**. New behaviours
(melee arc, explosions, spreads) are attack kinds: a weapon returns `Shot`s (projectiles, optionally
explosive) and `Slash`es (melee arcs), and the world carries them out.

**Per-item tuning.** Each item declares its tunable fields as `Knob`s; tuning keys are `<item id>.<field>`, so
every weapon keeps its own settings. A HUD button (or Q) cycles weapons for testing.

**Tuning.** Feel matters more than anything at this stage, so the numbers that shape it are editable in-game
(pause menu → Tune gameplay), saved on the device, and sent to Claude as JSON with one tap. Defaults live in the classes
(`Weapon`, `Utility`, `Player`, `Enemy`), and the tuning screen reads them, so there is one source of truth.
When a playtest settles on better values, they get copied into those defaults.

**Tune screen menus.** The knobs are sorted into sections (`GameTuning.sections`): Player, Weapons, Utilities,
Potions, Enemies, Loot, Controls, Camera. A section with one group of knobs opens straight onto them; Weapons,
Utilities and Potions first list every item, so any of them can be tuned, not only the one equipped (which is
marked). Back or Esc goes up a page. Entries holding changed knobs are marked in gold, and Reset resets what the
page shows (Reset all, from the top menu).

## Keyboard and mouse

Touch stays the target, but a computer gets its own controls rather than a mouse pretending to be a finger:

| Input | Action |
| --- | --- |
| WASD or arrow keys | Move |
| Mouse | Aim: the attack goes toward the cursor, and spot-aimed weapons (Fireball, Mephitic Cloud) land on it |
| Left button | Attack; held, it shows the aim and keeps attacking whenever the weapon is ready |
| Right button or Space | Utility, toward the cursor |
| 1, 2, 3 | Drink a potion (in the potion bar's order) |
| E | Take the item on the floor |
| M | Show or hide the minimap |
| Q | Next weapon (testing aid) |
| Esc | Pause menu; in the Tune screen, back |

`InputMode` decides which kind of play is in use: phones start with touch, computers with keyboard and mouse, and
then whatever was used last wins (a key or click, or a touch). Godot copies clicks into touches and touches into
clicks so both kinds of widget keep working; those copies are marked as emulated and never switch the mode. With
keyboard and mouse, the stick hides and the two action buttons stay as indicators (item, cooldown and key), and
the potion bar shows each potion's key. Clicks on HUD buttons (potions, Take, the menu) never attack. The cursor is
turned into a point on the floor through the 3D camera (`WorldView3D.plane_point_at`), and `MouseAim` turns it into
the same aim a touch drag gives, so weapons don't know how they were aimed.

## Loot (step 6)

- **Chests.** Clearing a room leaves a chest at its centre. Walking onto it opens it and drops a weapon.
  The open chest stays, so you can see which rooms you have looted.
- **Rare drops.** A defeated enemy has a tunable chance (Tune → Loot, default 5%) to drop a weapon.
- **What drops.** Chests hold a random weapon or utility you don't already hold (a duplicate is no choice).
  An enemy's rare drop is the weapon it fought with (or a random find if you already hold that one).
  On the floor, weapons are round and utilities square.
- **Compare and swap.** Standing on a drop shows a card: the item's name and one-line description, what it
  replaces (what you hold in the same slot), and **Take** / **Leave**. Taking it leaves your old item on the floor in its place, so a swap can be
  undone; the card only returns after you step off and on again, so nothing is swapped by accident.
- **Runs start with Magic Missile and the Dash.** The HUD weapon switch stays as a testing aid for tuning each weapon, but the
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
| Magic Missile | Keeps to mid range and shoots |
| Fireball | Hangs back and lobs; backs away if you get close. Its blast hurts other enemies too |

Within their comfortable range they circle the player instead of standing still.

**Behaviour** is a small state machine (`EnemyBrain`), so each step can be tuned on its own:

| State | What the enemy does | Leaves when |
| --- | --- | --- |
| Idle | Waits | Its room locks and it gets a target |
| Hunt | Can't see the player: walks around walls (`Pathfinder`) | It sees the player, or gets its turn (lobbing weapons attack over walls) |
| Position | Keeps to its weapon's distance, at its flank spot | It loses sight, or gets its turn |
| Wind-up | Stands still and telegraphs the attack, aim locked | The attack is released (or a Beckoning yanks it) |
| Recover | Steps aside (alternating sides) for 0.35 s | Recovered: back to Hunt or Position |

**Teamwork** (`Squad`, one per room). Enemies no longer all fire at once: a room lets at most 2 enemies wind
up at the same time, and starts their attacks at least 0.35 s apart, so attacks come in a rhythm the player
can read and dodge one by one. They also spread out: seen from the player, neighbours take spots 70° apart,
centred on where the group already stands and in the order they stand (nobody crosses over), so a group
flanks and, when big enough, surrounds the player instead of bunching into one easy target.
**Aiming ahead.** Enemies aim 60% of the way to where a moving player will be when the attack arrives (wind-up
plus the shot's flight, `Weapon.travel_seconds`), so running in a straight line is punished but a sidestep
still dodges. All of these are in Tune → Enemies: aim ahead, step aside after attack, attackers at once, gap
between attacks, flank spread.

Their attacks are fair by
design: an enemy is slower between attacks than the player with the same weapon, and before each attack it
**stops and shows where it will go** (a red preview), with its aim locked, so stepping aside dodges it. Both
are tunable (Tune → Enemies: attack slowness, telegraph). Enemy attacks hurt only the player; the player's hurt
only enemies; blasts hurt everyone. Enemies no longer hurt on contact.

**Monsters** (`Bestiary`). Like Dungeon Crawl, the dungeon has peoples rather than generic enemies. Each
monster is a race with its own health, pace, size and strength, carrying one of the player's weapons (which
still decides how it fights). The map letter names the monster, so playtests stay comparable.

| Letter | Monster | Weapon | Health | Speed | Size | Notes |
| --- | --- | --- | --- | --- | --- | --- |
| `k` | Kobold | Sword | 200 | 1.25× | small | Quick and frail, comes in numbers |
| `g` | Goblin | Magic Missile | 200 | 1.1× | small | |
| `a` | Goblin archer | Crossbow | 200 | 1.1× | small | |
| `s` | Bandit (human) | Sword | 300 | 1× | | |
| `w` | Apprentice (human) | Magic Missile | 300 | 1× | | |
| `c` | Crossbowman (human) | Crossbow | 300 | 1× | | |
| `f` | Pyromancer (human) | Fireball | 300 | 1× | | |
| `n` | Necromancer (human) | Mephitic Cloud | 400 | 0.95× | | |
| `o` | Orc | Sword | 500 | 1× | large | |
| `W` | Orc wizard | Fireball | 400 | 0.95× | large | |
| `d` | Dwarf | Crossbow | 800 | 0.7× | | The tank: slow and sturdy |
| `e` | Deep elf mage | Lightning Bolt | 500 | 1.05× | | Pointy ears; bolts jump between foes |
| `z` | Skeleton (undead) | Sword | 400 | 0.9× | | |
| `x` | Skeleton archer (undead) | Crossbow | 400 | 0.9× | | |
| `m` | Skeletal mage (undead) | Mephitic Cloud | 500 | 0.9× | | |
| `Z` | Skeleton warrior (undead) | Battleaxe | 700 | 0.85× | large | |
| `O` | Ogre | Battleaxe | 1400 | 0.6× | huge | +100 damage on every hit |

Size is the body attacks hit, so an ogre is easier to hit than a kobold. Tune → Enemies scales every
monster's health at once (Health ×). Models show the race: colour, size, pointy ears (kobolds, goblins, elves),
tusks (orcs, ogres), a beard (dwarves); the red ring on the floor marks every one as a foe.

**By depth** (`DungeonDifficulty`): kobolds, goblins and bandits near the start; then human casters and archers,
orcs and necromancers; then orc wizards, dwarves and skeletons; deep elf mages, skeleton warriors and ogres
deepest. Deeper rooms also hold more monsters.

## Branches (areas)

Like Dungeon Crawl's branches, each floor of the descent is a different place (`Branch`), with its own
rooms, set pieces, inhabitants and look (`BranchLook`):

| Floor | Branch | Rooms | Vaults | Lives there | Look |
| --- | --- | --- | --- | --- | --- |
| 1 | Dungeon | Built, 15% caves | Pillared hall, statue gallery, treasure closet, moat island | (the depth's mix) | Grey flagstones, stone walls, torches and banners |
| 2 | Lair | 75% caves | Lake, pool, moat island | Goblins, goblin archers, kobolds | Mossy earth, moss-capped rock, glowing mushrooms, grass, boulders; no torches |
| 3 | Orcish Mines | 85% caves | Rubble cavern, ember corners, lava river | Orcs, orc wizards | Brown earth, rock veined with gold ore, boulders, coins; torches |
| 4 | Crypt | Built | Catacomb (rows of tombs), statue gallery, treasure closet | The undead | Violet stone, coffins, bone piles, candles |
| 5 | Depths | 30% caves | Lava lake (two causeways), ember corners, pillared hall | Deep elves, ogres, dwarves, orc wizards | Pale marble, sandstone caps, braziers |

A branch's favoured monsters are added (twice) to every room's pool, on top of what the depth calls for,
so the danger still grows floor by floor. **Caves** (`RoomShapes.cave`) are rough rectangles whose walls
wander in and out in stretches of three cells, with rounded corners; the middle of each side stays straight
so corridors can still meet it. Their floors are blotchy earth without grout. Free-standing pillars are carved columns in built places,
trees in the Lair and plain rock in the Mines (they block like walls all the same); columns and trees stand
on the floor with a shadow at their foot.
The HUD, the pause menu and the run summary name the branch ("Killed by an orc in the Orcish Mines"), and
arriving shows its name and a line of flavour for a moment ("The Orcish Mines. Pickaxes ring somewhere in
the dark."). The Dungeon itself has the odd cave (15% of its rooms).

## Floors (the descent)

Like Dungeon Crawl, a run is a descent: **5 floors**, each a new branch (see Branches), each more dangerous
than the last.
The stairs (gold, in the room farthest from the start, usable once that room is clear) lead down; on the
fifth floor they lead out, and the run is won. Dying, or restarting from the menu, starts over from floor 1.

Taking the stairs carries the run down (`RunState`): the weapon and utility held, health as it is (no free
healing between floors: potions are the only healing), the potion belt and experience. Everything else (the map, the
monsters, chests) is new. The HUD shows the floor; the pause menu shows the floor and its seed.

**Experience** (`Experience`). Like Dungeon Crawl's experience levels (or Brawl Stars' power cubes),
defeating monsters makes the hero tougher, so the descent stays winnable without free healing. A kill is worth
the monster's health in points (a kobold 200, an ogre 1400); going from level n to n+1 takes 500×n points; each
level adds 200 to maximum health (and heals those 200), up to level 10. Levels carry down the stairs. The HUD
shows the level and the progress toward the next; "LEVEL n!" rises over the hero.

**Danger** (`DungeonDifficulty.danger`): one level per floor down, plus half a level per room away from the
start. So rooms on one floor differ less than floors do: floor 1 tops out with orcs, floor 3 brings orc
wizards and dwarves, floor 5 ogres. Out-of-depth rooms still roll two levels deeper.

## Dungeon generation

Dungeon Crawl Stone Soup is the model for the dungeon itself: random levels with hand-made vaults mixed in,
terrain that changes how fights play, line of sight with map memory, items lying around for whoever explores,
and the odd room that is more dangerous than its depth suggests.

`DungeonGenerator` turns a seed into the same ASCII map format the parser always read, so room detection,
doors, locks, chests and enemy letters work unchanged, and a map can be printed and read when something looks
wrong.

1. **Room graph** (`RoomGraph`): 6–8 rooms on a 4×3 grid of slots, grown as a tree from a random start slot,
   plus up to two extra links so not every path is a dead end. Links only join neighbouring slots, so
   corridors are short and never cross.
2. **Shapes** (`RoomShapes`): the start room is a rectangle; the others are a rectangle, an L, a cross or two
   merged rectangles, never thinner than 7 cells. Fighting rooms get up to four 2×2 pillars, kept clear of
   the walls and never allowed to cut a room in two. Pillars block shots; the fireball lobs over them.
   About a third of rooms are **vaults** instead (`Vaults`): hand-written set pieces in the map format, randomly
   mirrored: moat island (treasure on an island with one bridge), pool, lava river, pillared hall, statue
   gallery, treasure closet (a walled chamber with a door), ember corners. Every vault keeps a floor ring along
   its edge so corridors always open onto floor.
3. **Corridors**: three cells wide with a door at each end, where both rooms have a straight wall facing
   each other. If two odd shapes can't be joined cleanly, they become rectangles.
4. **Difficulty** (`DungeonDifficulty`): by depth (rooms from the start). Near the start, two or so kobolds
   and goblins; deeper, more monsters (up to six), and tougher ones (see Monsters). 15% of rooms are **out of depth**:
   their enemies are picked as if two rooms deeper. Rooms are optional, so walking away is a real choice.
5. **Floor loot** (`*`): vault treasure, and half of the dead ends (rooms with one way in) hide an item, picked
   like a chest's. Exploring pays.
6. **Exit**: in the deepest room, in its corner farthest from the middle (where the chest appears).

**Terrain.** Deep water (`~`) blocks walking but not sight or shots: a shooter across a pool can hit you, and
you can hit back, but nobody walks over. Shallow water (`,`, like Dungeon Crawl's) can be waded through, but
everyone in it moves at 60% speed; enemies go round it when dry ground is close. The Lair's caves have
puddles of it, and its lake and pool have shallow shores. Lava (`L`) can be crossed, but burns (100 damage on stepping in, then
every half second; the Shield blocks it). Enemies path around water and avoid lava when they can.

**Fog of war** (`Exploration`, `FogView`). You see 16 cells around you (farther than any weapon reaches, so
nothing hits you from the dark), through floor, water and lava but not walls or closed doors. What you have
seen stays drawn, dimmed; what you haven't is dark. Enemies out of sight are hidden.

**Minimap** (`MinimapPainter`, `MinimapView`). Top left of the HUD, a picture with one pixel per cell (shown at
2 px) of what `Exploration` has seen: floor, doors, water, lava and the stairs in their own colours, cells in
view brighter than remembered ones, you as a bright dot. Walls and unseen cells are left blank, so the map's
shape shows through the gaps. It redraws whenever sight does. Enemies and loot aren't marked: the minimap is for
finding the way, and the fog already hides what you haven't seen. The **Map** button under the help line (or
M) shows or hides it, and the choice is saved with the settings so it holds across floors and runs.

Enemies find their way around walls and pillars (`Pathfinder`, on Godot's `AStarGrid2D`) when they can't
see the player, and only shoot with a clear line; fireball throwers lob over cover.

Generation rules are tested on many seeds through the real parser: same seed, same map; every cell reachable;
every room has a door; the start is quiet; the exit is guarded and away from the start.

## Graphics (3D view)

The target is Brawl Stars' camera and map feel with fantasy characters (humans, goblins, dwarfs...). Done in
phases, each played on a phone before the next:

1. **Camera and blockout** (done): a 3D view with placeholder shapes, to judge the camera.
2. **Map look** (done, see below): flagstones, stone walls with caps, columns, moving water and lava,
   torches, the stairs' arch, soft fog.
3. **Characters** (first pass done): KayKit Adventurers (CC0, by Kay Lousberg), rigged and animated. See
   Characters below. Still open: models of their own for goblins, orcs, dwarves and ogres.
4. **Polish**: ~~hit flashes, damage numbers~~ (a hit model flashes white and its damage rises above it:
   white over enemies, red over the hero; a defeated monster bursts into chunks in its colour; the camera
   jolts briefly when the hero is hit~~); particles for spells, sound.

**The game stays 2D; only the view is 3D.** Physics, hit shapes, pathfinding, fog and every test work on the
2D plane exactly as before. `WorldView3D` shows that plane in 3D:

- **The floor is the 2D world.** Everything the 2D world draws is rendered into a texture that lies on the
  floor, so ground marks come for free: the floor tiles, aim previews, red telegraphs, sword arcs, blasts,
  lava and water, the fog. The main screen doesn't draw the 2D world itself (it is on its own canvas layer,
  culled there). The texture covers a window around the camera, not the whole map, so it stays small
  enough for a phone, and it moves in whole texels so the floor doesn't shimmer.
- **What stands up is 3D.** Walls and closed doors are blocks (hidden until seen, dimmed when out of sight,
  like the fog); heroes, enemies, chests, floor items and shots are 3D models that copy their 2D actor every
  frame (`Puppets`). So in 2D, actors now draw only their marks on the ground: a team ring under heroes (blue)
  and enemies (red), shadows under shots and chests, a glow under items.
- **The camera** never turns. It looks down at the hero from the bottom of the screen, tilted 55°, from 17
  cells away with a narrow 38° field of view, aimed 1.5 cells ahead so more of what's in front shows. Up on
  the stick is still up on the screen, so the controls didn't change. All of it, and the wall height, is in
  Tune → Camera.
- **Placeholders**: characters are capsules with a head, eyes (which way they face) and the weapon in its
  colour; enemies have a health bar. Lobbed fireballs fly high above their shadow.

**Map look** (phase 2). Everything is decided per cell from the map (`DungeonDecor`, pure and
deterministic), so it costs nothing to store and never changes how the game plays:

- **Floor**: flagstones in two alternating shades (distances still read at a glance), each stone tinted a
  little differently, set in dark grout with a light bevel; one in 14 is cracked. Open doorways show a
  wooden threshold.
- **Walls**: stone blocks with a lighter cap that overhangs a little (Brawl Stars' blocks), each block's
  stone a slightly different shade. Small blocks of wall standing free inside a room (pillars, vault statues,
  at most 4 cells) are round columns; longer walls inside a room stay walls. Closed doors are wooden blocks.
- **Torches** (KayKit's mounted torch, with a flickering flame) hang on walls that face the camera, spread
  out along them, and throw a warm pool of light on the floor below (only on floor: it never spills over
  walls). **Banners** hang between some of them.
- **Clutter**: one floor cell in nine along a wall has something small on it (a candle, a bottle, coins),
  never where monsters, loot or the stairs are. Walking over it is fine: it is only looks.
- **Chests** are KayKit's, and their lid swings open.
- **Weapons on the floor** show the weapon itself (the model characters hold), floating and turning;
  utilities are glowing cubes, potions flasks. **Items on the floor** stay hidden until their cell has been seen, then stay shown (like the fog's map
  memory).
- **Water and lava** move: slow waves with highlights (`shaders/liquid.gdshader`), lava slower and hotter.
- **Stairs** stand under a stone arch trimmed in gold.
- **Cutaway**: walls right in front of the hero (the two cells toward the camera, three wide) drop to a low
  stub while the hero stands behind them, so a wall never hides you.
- **Fog** is a one-pixel-per-cell picture stretched smoothly over the map, so its edges fade across a cell.
  A wall counts as in sight when an open cell beside it is (sight grazing along a wall would otherwise
  leave it dimmed while you stand next to it).

## End of a run

Like Dungeon Crawl's tombstone, a run ends with a summary instead of an instant restart: "You died" (or
"You escaped the dungeon!"), what killed you and on which floor ("Killed by an orc wizard on floor 3 of 5"),
the level reached and the monsters slain, and a **Play again** button. Every attack carries its source
(the monster's name, "your own Fireball", "lava"), and the hero remembers what hurt them last. Kills are
counted across floors (`RunState`); the lines are written by `RunSummary` (pure).

**Characters** (phase 3, first pass). The models are KayKit's Adventurers and Skeletons packs (CC0, by Kay
Lousberg, kaylousberg.com; in `assets/kaykit_adventurers` and `assets/kaykit_skeletons`): Knight, Barbarian,
Mage, Rogue and hooded Rogue, and four skeletons, all on one rig, with weapons as separate models. `CharacterLook` (plain data) says who wears what:

- The hero is the Knight. Humans dress for their weapon: casters are mages, crossbowmen rogues, bandits
  hooded rogues.
- Races without a model of their own borrow one, coloured by their skin (head and arms only, so clothes keep
  their colours): kobolds are small brown hooded rogues, goblins small green rogues, orcs green barbarians
  (bareheaded, so the skin shows; their wizards green mages), dwarves short, broad barbarians, ogres huge
  yellowish ones, deep elves blue-skinned mages. The undead are KayKit's skeletons, dressed for their weapon
  (a warrior with the battleaxe, a hooded rogue with the crossbow, a mage with the cloud).
- Each weapon has a model in the right hand (sword, two-handed axe, crossbow, staff for the fireball, an open
  spellbook for the cloud, a wand for the rest) and an attack animation (a slice, a two-handed slice, a
  crossbow shot, a spell cast).
- Characters stand idle, run while moving, play their attack when it is released, and flinch when hit.
  When they die they fall where they stand: a monster's body lingers a moment (with the burst of chunks),
  the hero's stays down until the summary. Animations only run while the character is in sight.
- Size: the animations are imported once (with the Knight) and shared, so the five models add about 2 MB
  to the phone download.

## Explicitly deferred

Audio, rarity tiers, stat depth, meta-progression, multiplayer.

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
12. Graphics (see Graphics): ~~camera and blockout~~; map look, characters, polish still open
13. ~~Dungeon Crawl progression: potions instead of Heal, a bestiary of fantasy races (tank included), Blink
    and Frost Nova, 5 floors~~
