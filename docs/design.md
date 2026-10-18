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
| Loot sources | Earned, not handed out: hidden floor finds (dead ends, vaults), rare enemy drops (2%) and set-piece chests. Clearing a room leaves nothing | Loot is scarce, so new gear is a moment; a chest per cleared room made gear routine |
| Dungeon | Generated each run from one world seed shown in the pause menu; every map's seed comes from it (see Dungeon generation) | Every run differs, and a map worth keeping (or a broken one) can be reported |
| Goal | A run starts outdoors on the **plains**; find the crypt entrance (a small mausoleum out in the grass) and go down the **crypt**'s 3 levels and out (until the Lich, #47, waits at the bottom). Each level's stairs down sit in the room farthest from the start and only work once that room is clear; stairs up lead back (the first level's lead out to the mausoleum). Other rooms are optional. The first zone (village, camps, the ruin, a 3-level crypt and the Lich) replaces this descent piece by piece, see the first-zone spec (#29) | Rewards exploring for loot vs. heading for the exit; Dungeon Crawl's descent, now with somewhere open to start from |
| Rooms | Ordinary rooms don't lock: their monsters are a **band** that sleeps or wanders at home until it notices the hero (see Enemies → Bands). Only rooms marked as locking (`DungeonProgress`; trap rooms and the boss arena, none yet) lock their doors on entering until their enemies are all defeated | Sneaking past or picking a fight is the hero's choice, as in Dungeon Crawl; a lock is kept for the fights that are meant to be forced |
| Aiming | Brawl Stars style: **tap** = auto-aim at the nearest enemy, **drag** = manual aim with a preview, **release** = fire. Drag distance is the aim's strength, which weapons that target a spot use as distance. The buttons float like the move stick: a touch anywhere in a catch zone around a button (1.6× its size, Tune → Controls; the nearest button wins where zones overlap) grabs it, and the aim is measured from where the finger landed. Dragging from aiming back into the dead zone buzzes briefly (`Input.vibrate_handheld`, Tune → Controls, 0 = off) and the knob greys out: letting go there cancels, as in Brawl Stars. A plain tap still auto-aims | Proven on touch screens; floating buttons, like Brawl Stars', don't punish a thumb that lands a little off |
| Movement | Floating stick: it appears wherever the left thumb lands, in the left half below the top third of the screen (`ControlLayout.stick_zone`), which is left to the status lines and the Map button; the map comes first: a touch on the minimap or the Map button is always theirs, never the stick's or an aim button's (`TouchControls.keep_touches_for`), and the HUD draws above the touch controls | Standard for mobile action games; the stick used to swallow taps on the Map button |
| Look | 3D shown over a 2D game: a fixed, tilted Brawl Stars-style camera; fantasy characters (humans, goblins, dwarfs) later | Brawl Stars' readability, with the game rules untouched |

## Equipment

Every item defines how it **aims** (shape + range) and what it **does**. Items change behaviour, not just stats.

| Weapon | Behaviour | Aim shape |
| --- | --- | --- |
| Dagger (starter; an arc weapon) | A quick, short stab: reach 55, a 70° arc, 110 damage (was 100), reloads in 0.6 s. Two stabs kill a goblin (220 hp with the enemy health bonus), three a bandit (330), two do not; a full burst of three does a little over half a Sword's | Cone |
| Magic Missile (id `wand`) | One magic bolt for 140 (was 100, about 115 damage per second at its 1.2 s reload), Dungeon Crawl's first spell. Goblins and apprentices cast it; the player finds it | Line |
| Sword (an arc weapon) | The blade sweeps across an arc in front of you, hitting each enemy once as it passes | Cone |
| Fireball | Lobbed like Barley's bottles in Brawl Stars: drag distance picks the landing spot (a drag to the button's edge throws half as far; dragging on past the button throws up to the max range, 280); arcs over walls and enemies and explodes where it lands for 200, hurting the thrower too; then the ground burns for 1.5 s, ticking 34 every 0.5 s (about 100 more to anyone who stays), like Barley's puddle. Burn damage per tick and burn time are Tune knobs | Landing circle at the dragged distance |
| Crossbow | A fan of bolts; strongest up close | Fan of lines |
| Lightning Bolt | Dungeon Crawl's bolt, shot like Jessie's: when it hits an enemy it jumps on to the nearest other enemy within 160, up to 3 times (4 enemies at most; never one it already hit), and every jump hits softer: 180 on the first enemy, then 117, 76, 49 (65% kept per jump, `ChainFalloff`). Tune knobs: first hit damage, damage kept per jump (0.3 to 1.0) and jumps (capped at 3 so tuning can't make it a screen-wide killer). Deep elf mages use the same bolt | Line |
| Mephitic Cloud | Lobbed like the fireball (like Emz's zones): leaves a poison cloud for 6 s; the first tick comes 0.6 s after it lands (a grace window to run out of it), then one every 0.6 s: ticks at 0.6, 1.2 ... 6.0 s, 10 of 50 = 500 to one that stays. Damage only comes from standing inside; nothing lingers after leaving. It used to last 3 s at 100 a tick with a tick on landing (same 500 total, spread thinner). **Poison doesn't stack:** a body inside several clouds takes at most one tick per 0.6 s, from whichever cloud ticks first, for that cloud's damage, so extra clouds only widen the coverage and add time (the same holds for enemy clouds on the player). Enemy casters (Necromancer, Skeletal mage) get the same numbers and the same grace window through the weapon. Doesn't hurt the thrower | Landing circle |
| Battleaxe (an arc weapon) | Like Frank's hammer: a long wind-up, then a 180° sweep for 400 damage | Cone |
| Bow | Like Angelo's bow in Brawl Stars: hold the button to draw, let go to shoot one fast arrow along a long, narrow line. A tap does 60 damage; the damage grows evenly with the time held to 240 at a full charge (1.5 s), and only a full charge pierces, hitting every enemy on the line once. The hero walks at half speed while drawing. Range 460 (a little past the Crossbow's 380; the hero sees 512), arrow speed 900 | Line, filling up (brighter, from the hero outward) as it charges |
| Knuckles | Like El Primo's fists: a flurry of 4 short, fast punches 0.07 s apart, alternating a little to each side, each thrown from where you stand by then, 50 damage each (three punches are a bit more than a Magic Missile). Fought bare-handed | Narrow cone |

**Health points, like Brawl Stars.** Health and damage are counted in big numbers (the hero has 1000, a bandit
300, a Magic Missile does 140) rather than Dungeon Crawl's small ones, so weapons can be tuned finely (a punch
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
floor finds), sit beside chests (30%, for the rare chest), and drop from enemies (10%, when they drop no gear). Walking over one
picks it up; there is nothing to choose, unless that kind is full, then it stays where it is. While haste or
might works, a ring in its colour shows on the floor around the hero. Each potion's numbers are in Tune.

**Arc weapons.** Dagger, Sword and Battleaxe share one archetype, `ArcWeapon`: a sweep across an arc in front of
you. They differ only in their numbers (reach, arc, damage, reload, wind-up, sweep), each set in the weapon's
own class, so a new arc weapon is just new numbers.

**Model (step 4).** `Weapon` and `Utility` are plain data objects (both `Item`s). Whoever wields a weapon owns
*when* (a `Wielder`: ammo, wind-up, auto-aim tracking); the weapon owns *what* (it turns an aim into `Shot`s).
A utility turns an aim into a `UtilityEffect` (dash, shield time, healing) that the player applies. The buttons show the equipped
item's name and colour. The starter gear is the **Dagger** and a **Dash**. New behaviours
(melee arc, explosions, spreads) are attack kinds: a weapon returns `Shot`s (projectiles, optionally
explosive) and `Slash`es (melee arcs), and the world carries them out.

**Per-item tuning.** Each item declares its tunable fields as `Knob`s; tuning keys are `<item id>.<field>`, so
every weapon keeps its own settings. A HUD button (or Q) cycles weapons for testing.

**Tuning.** Feel matters more than anything at this stage, so the numbers that shape it are editable in-game
(pause menu → Tune gameplay), saved on the device, and sent to Claude as JSON with one tap. Defaults live in the classes
(`Weapon`, `Utility`, `Player`, `Enemy`), and the tuning screen reads them, so there is one source of truth.
When a playtest settles on better values, they get copied into those defaults.

**Tune screen menus.** The knobs are sorted into sections (`GameTuning.sections`): Player, Weapons, Utilities,
Potions, Enemies, Loot, Controls, Camera, World (see The plains). A section with one group of knobs opens straight onto them; Weapons,
Utilities and Potions first list every item, so any of them can be tuned, not only the one equipped (which is
marked). Back or Esc goes up a page. Entries holding changed knobs are marked in gold, and Reset resets what the
page shows (Reset all, from the top menu).

## Keyboard and mouse

Touch stays the target, but a computer gets its own controls rather than a mouse pretending to be a finger:

| Input | Action |
| --- | --- |
| WASD or arrow keys | Move |
| Mouse | Aim: the attack goes toward the cursor, and spot-aimed weapons (Fireball, Mephitic Cloud) land on it |
| Left button | Attack; held, it shows the aim and keeps attacking whenever the weapon is ready. A weapon that charges (the Bow) is drawn while the button is held and shoots when it is let go |
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

- **Earned loot.** Clearing a room leaves nothing: gear is scarce, so a new piece is a moment. It comes from
  the floor (dead ends and vaults hide finds, see Floors), from rare enemy drops and from chests.
- **Chests.** Set pieces hold them: the ruin's is guaranteed (below, "The ruin"); trap rooms' come with the first zone. A chest is known in
  the map record by the id of what holds it (a room number, or `Ruins.NUMBER`), so an opened one stays open on return.
  Walking onto one opens it and drops a find. The open chest stays, so you can see what you have looted.
- **Rare drops.** A defeated enemy has a tunable chance (Tune → Loot → "Enemy drop chance", default 2%) to drop
  its weapon. (Room chests used to set the pacing and drops were 5%.)
- **What drops.** Chests hold a random weapon or utility you don't already hold (a duplicate is no choice).
  An enemy's rare drop is the weapon it fought with (or a random find if you already hold that one).
  On the floor, weapons are round and utilities square.
- **Compare and swap.** Standing on a drop shows a card: the item's name and one-line description, what it
  replaces (what you hold in the same slot), and **Take** / **Leave**. Taking it leaves your old item on the floor in its place, so a swap can be
  undone; the card only returns after you step off and on again, so nothing is swapped by accident.
- **Runs start with the Dagger and the Dash.** Loot is meant to be a grind, so the starter is good enough for the first fights
  (it kills goblins in two stabs) but clearly weaker than found weapons. The HUD weapon switch is a testing aid for
  tuning each weapon: hidden by default, shown by Tune → Controls → "Show weapon switch" (the keyboard key always
  works). Magic Missile stays an enemy weapon and can be found. Known risk: a melee start leaves no ranged answer to
  a kiting boss; if playtests show it hurting, put a ranged weapon in the ruin's chest. The weapon picked with the switch is not saved
  between runs (the "Show weapon switch" setting is saved with the rest of the tuning).

`LootTable` holds the rules (pure, given a seeded random generator). `Chest` and `WeaponDrop` only notice the
player; `main.gd` decides what drops and does the swap.

**Charged weapons** (the Bow). The charge is the time the attack button was held, whichever way it is aimed:
`AimGesture` counts it on a press (so a drag or a plain hold, then a release, carry it in `Release.held_seconds`),
and with the mouse `main.gd` counts it while the button is held and shoots on release (`KeyboardMouseControls.attack_released`).
`Wielder.start` hands it to `Weapon.charged_attacks`, which weapons that don't charge treat as `attacks`; the
rule itself (seconds held to damage and piercing) is the pure `Charge`. An attacker that passes no hold time (an
enemy) counts as fully charged. While drawing, `Player.charging` slows the hero by `Weapon.charging_move_share`, and
the preview line fills (`AimShape.fill`) as the charge grows. A tap still auto-aims, and with the bow it is the weak
arrow. Cancelling by dragging back into the dead zone shoots nothing and keeps the ammo. All the numbers are Knobs
(Tune → Weapons → Bow).

## Enemies

Enemies carry **the same weapons as the player**, and the weapon decides how they fight (`EnemyTactics`, from
`Weapon.ideal_distance`):

| Weapon | Behaviour |
| --- | --- |
| Sword | Rushes in and swings |
| Crossbow | Gets close, then fires its fan |
| Magic Missile | Keeps to mid range and shoots |
| Fireball | Hangs back and lobs; backs away if you get close. Its blast and the fire it leaves hurt other enemies too |
| Bow | Keeps to mid range. Enemies never draw it: after the telegraph (the line previewed on the floor) the arrow flies fully charged, 240 damage and piercing, so it hurts and it is a good reason to step aside. No monster carries one yet, so it only shows up as the player's find |

Within their comfortable range they circle the player instead of standing still.

**Behaviour** is a small state machine (`EnemyBrain`), so each step can be tuned on its own:

| State | What the enemy does | Leaves when |
| --- | --- | --- |
| Asleep | Sleeps at home, a "z" over its head | It notices the hero (see Bands): Noticing |
| Wander | Strolls slowly (half speed) to random spots within 6 cells of home, in sight of home and off lava | It notices the hero: Noticing |
| Noticing | Shows a "!" and stands still for 0.4 s, then goes after the hero | The pause is over: Hunt or Position |
| Check | Gave up the chase: walks (at full pace) to the spot where it last saw the hero | It gets there (or can't): Return. It notices the hero: Noticing |
| Return | Walks home at wander pace, out of the fight | It gets home: Wander. It notices the hero: Noticing |
| Idle | Waits (an awake enemy with no target) | It gets a target |
| Hunt | Can't see the player: walks around walls (`Pathfinder`) | It sees the player, or gets its turn (lobbing weapons attack over walls). It gives up: Check |
| Position | Keeps to its weapon's distance, at its flank spot | It loses sight, or gets its turn. It gives up: Check |
| Wind-up | Stands still and telegraphs the attack, aim locked | The attack is released (or a Beckoning yanks it) |
| Recover | Steps aside (alternating sides) for 0.35 s | Recovered: back to Hunt or Position |

**Bands** (`Band`, `Awareness`). The monsters of one **home** are a band; in the dungeon a home is a room,
on the plains a **camp's campfire**, or the middle of the **ruin**. A band starts **asleep** at home or **wandering** about it; which is decided
per home from the map's seed (`Band.start_of`; in the crypt 15% of bands wander, on the plains each camp by its
chance asleep), so the same map starts the same way. None starts awake.
A monster **notices** the hero only when it can see them (line of sight) within **4 cells asleep** or **9
cells wandering**; there are no dice. Taking damage wakes it at once, and so does hearing a noise or a shout
(below). `Awareness` holds the rules (the radii are its fields; damage, noise and shouts count as noticing);
`EnemyBrain` asks it while the enemy is calm, and a calm enemy only checks its line of sight once the hero is
within its radius. All of it is in Tune → Enemies: notice when asleep, notice when wandering, hero's noise
carries, monster's shout carries, noticing pause, wander speed, wander radius (how many bands start wandering
is the map's: Tune → World, the camps' and the crypt's).

**Giving up and going home** (`Awareness.gives_up`, `EnemyBrain`). The hero can escape a chase. A hunting
(Hunt or Position) monster settled at a home **gives up** after **5 s without seeing the hero**, or as soon as the
hero is **24 cells from its home**, even in plain sight (the hero is leaving its territory). The brain counts the
unseen time itself (reset whenever it sees the hero, and when it notices); the Enemy node hands it the hero's
distance from home in `Senses`, and `Awareness.gives_up(Awareness.Chase)` decides, so the rule is pure. A monster
with no home (never settled) never gives up. On giving up it enters **Check**: it walks to the spot it last saw the
hero inside its territory (the node remembers it; a hero seen 24+ cells from home is not walked to), then **Return**: it strolls home, then goes back to Wander. Reaching a spot is told
to the brain as `Senses.arrived` (close enough, or no path on, so a walled-off spot never strands it). A monster
that is checking or returning is awake and can **notice the hero again**, with the same rule and radius as a
wandering monster (**9 cells**, in sight; a deliberate choice: it is awake and strolling, and a separate radius
would be one more number nobody tunes), but only once the hero is back **within 24 cells of its home**
(`Awareness.in_territory`): a hero it gave up on at the edge would otherwise be noticed and given up on again
every few frames, with a "!" and a shout each time; it then pauses on a "!" and hunts, and **shouts again** (`noticed` fires on
the way into Noticing), which is fine: a band that settled down can be woken again. The shout chain still ends,
because only calm monsters hear a shout and a checking or returning one is busy. While it checks or returns a
monster is out of the fight for its **Squad**: it frees its attack turn and flank spot when it gives up (`Squad.leave`) and
reports no bearing until it hunts again, as a calm monster doesn't (`EnemyBrain.is_out_of_the_fight`). A home can be
marked **never gives up** (`Enemy.never_gives_up`, `Senses.never_gives_up`): its hunters hunt on however long and
far. `main.gd` sets it from `DungeonProgress.is_locking` of the room each monster spawned in, so the Lich's arena and
sealed trap rooms, once they are marked as locking, get it without further wiring. A camp's monsters give up like any
other and walk back to their campfire. Tune → Enemies: give up after unseen (s), give up
beyond home (cells).

**Noise and shouts** (`Awareness.noise_hearers`, `shout_hearers`). Fighting has consequences beyond the target.
The hero's attacks, hit or miss, make **noise**, and so does every blast where it bursts; it wakes monsters
within **8 cells, through walls** (only distance counts, so the rules are never told where walls are). A monster
that notices the hero **shouts**: the rest of its band hears it however far they are (a band joins its own),
and so does any other monster within **8 cells**, and each of those shouts in turn: a careless fight can pull
in a camp nearby. The chain ends because a calm
monster notices once (`Enemy.noticed` fires on the way into Noticing) and an awake one ignores what it hears.
The nodes only route events: `Player.attack_fired` and `Projectile.exploded` reach `main.gd` (`_make_noise`),
and `Enemy.noticed` too (`_on_enemy_noticed`); main hands the positions in cells (and, for a shout, each monster's band) to
`Awareness`, which says who hears, and calls `Enemy.alert()` on them. Enemy attacks make no noise: those enemies are awake already.
Auto-aim picks the nearest enemy the hero can see, wherever it is.

**Teamwork** (`Squad`, one per band). Once a band fights, its members take turns as a squad. Enemies no longer all fire at once: a band lets at most 2 enemies wind
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

Like Dungeon Crawl's branches, a place has its own rooms, set pieces, inhabitants and look (`Branch`,
`BranchLook`). The descent is now only the **Crypt** (`Branch.crypt()`, all 3 levels of it); the other branches
stay in code, one per old floor, for later ideas:

| Old floor | Branch | Rooms | Vaults | Lives there | Look |
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
Arriving shows where the hero is (see Place) and the branch's line of flavour for a moment ("Crypt level 1.
Something stirs in the tombs."). The Dungeon itself has the odd cave (15% of its rooms).

## Floors (the crypt)

A run starts on the **plains** (next section), outdoors. The way on is a descent into the **crypt**: **3 levels**
of today's `DungeonGenerator` in the Crypt branch (see Branches), each more dangerous than the last. The plains'
**crypt entrance** (the mausoleum's stairs) leads down to level 1's stairs up, and those lead back out onto the
mausoleum (`WorldLayout`: the plains are map `plains`, the levels `crypt_1` to `crypt_3`; the map's depth picks
the generator's danger, and the branch is always the crypt, see `MapSpec.branch`). Every level starts on its
stairs up (`DungeonGenerator.VERSION` 3).
The stairs down (gold, in the room farthest from the start, usable once that room is clear) lead down; on the
third level they lead out, and the run is won. **Interim win:** the Lich (#47) will replace that, waiting in
an arena at the bottom; until then the last stairs still win the run.

**The crypt's campfire.** Each level has exactly one campfire (the map letter `F`, the same walkable scenery as the
plains' lone campfires), in an **ordinary room**: not the arrival room, not the stairs-down room and never a vault
(the room is chosen from the room graph by `CryptCampfire`, a pure step, and kept from being a vault). It lies the
wanted number of rooms from the stairs up (Tune → World → "Crypt campfire, rooms from stairs", default 3), or in
the nearest such room when the level has none that far (ties by the seed). A campfire is a **camp** to `Camps`
whenever a monster stands within 3 cells, so the generator keeps every monster of the campfire's room more than 3
cells away (the room may hold a few fewer): a crypt campfire is always a lone one, the future rest spot (#43).
The crypt has no camps.

**Crypt bands** start **mostly asleep**: 15% of them wander about their room (Tune → World → "Crypt bands
wandering"; `CryptRecipe.wandering_share`, read through `MapSpec.room_wandering_share`), none starts awake. This
replaced the old "Bands wandering" knob (a quarter, in Tune → Enemies), which only the dungeon used. No ordinary
room holds a guaranteed chest. The HUD, the arrival banner, the pause menu and the run summary name the level
(`MapSpec.place_name`: "Crypt level 2"; "The plains" outdoors, "The village" inside its palisade, see `Place`). Every floor also has **stairs up** (silver, `<` in
the map format, where the floor's start would be). Each set leads onto the matching stairs on the other floor:
down arrives on the stairs up below, up arrives on the stairs down above (`WorldLayout.destination` names the map
and the spot; `WorldLayout.arrival_cell` finds the spot on the parsed map). The stairs the hero arrives on only
lead on once the hero has stepped off them. Dying, or restarting from the menu, starts over on the plains of a
new world, with a new seed.

Taking the stairs carries the hero (`HeroState`): the weapon and utility held, health as it is (no free
healing between floors: healing comes from potions and from resting at a campfire, see **Resting**), the potion belt, experience and kills. The HUD shows the
floor; the pause menu shows the world seed and the floor.

**The world remembers** (`MapRecord`). Maps are never kept in memory once left: each visit makes the map again from
its seed, parses it and builds it, then applies the map's record before the first frame; leaving writes the record.
The run keeps one record per visited map. It holds:
- monsters killed, chests opened and floor items taken (written as they happen);
- items dropped (as data: item id, potion or gear, position): everything on the floor the map didn't start with,
  like gear swapped out, a chest's unclaimed find or an enemy's drop;
- the cells explored (`Exploration.seen_cells` out, `Exploration.restore` in), so the fog and minimap keep the
  hero's progress;
- monsters left hurt: their health and the run time they were left at;
- campfires: each one's state (unlit, burning, embers) and the seconds it has left, by its cell (see **Resting**);
- the version of the generator that made the map (`DungeonGenerator.VERSION`), so a saved record can tell when the
  same seed would no longer give the same map.

What makes a record match its regenerated map is **stable ids from map position**: an enemy is its spawn cell, a
floor item its loot cell, a chest its room (an opened chest comes back open). **Floor loot is seeded**: what lies on a loot cell is rolled from the map's seed and the cell alone
(`LootTable.floor_find`), not from what the hero holds, so a floor item seen, left and come back to is the same
(it may be something the hero already holds). **Regeneration** (`Regeneration`): hurt monsters heal while the hero
is away, 10 health a second by default (Tune → Enemies → "Heal while away"), in one-second steps counted from the run
time that passed (`Run.seconds_played`, the game's clock, which stops while paused). A record round-trips through a
plain dictionary (and JSON) unchanged, ready for save games later; today runs still last one session.

**The run and its maps.** One run-level owner, `Run` (pure), lives for the whole run: the world seed, the hero's
carried state and which map is current. Each map has an id and a spec (`MapSpec`: which generator recipe, which
seed); `WorldLayout` lists the maps of a world, derives each map's seed from the world seed (the same world seed
always gives the same floors) and holds the transition rule: from this map, through this exit, to which map and
which spot on it. The game no longer reloads its scene: taking the stairs frees the current map (`MapStage`: the
parsed map, its floor, fog, 3D view, actors and loot) and builds the next one inside the running game; the
composition root (`main.gd`) keeps the controls, HUD and menus wired once. Starting over does the same with
`Run.next_world`. Rebuilding a floor takes about 0.3 s on a desktop (about 40 ms of it generating and parsing the
map, the rest building the nodes), behind the "Down to…" message; on phones it is still to be measured.

**Experience** (`Experience`). Like Dungeon Crawl's experience levels (or Brawl Stars' power cubes),
defeating monsters makes the hero tougher, so the descent stays winnable without free healing. A kill is worth
the monster's health in points (a kobold 200, an ogre 1400); going from level n to n+1 takes 500×n points; each
level adds 200 to maximum health (and heals those 200), up to level 10. Levels carry down the stairs. The HUD
shows the level and the progress toward the next; "LEVEL n!" rises over the hero.

**Danger** (`DungeonDifficulty.danger`): one level per floor down, plus half a level per room away from the
start. So rooms on one floor differ less than floors do: level 1 tops out with orcs and level 3 brings orc
wizards and dwarves (the deeper floors of the old five-floor descent are not reached). Out-of-depth rooms still roll two levels deeper.

## The plains (quadrant generation)

The first map of a run is the **plains**, the centre **quadrant** of the world's 3x3 grid (see `GLOSSARY.md`).
It is made by `QuadrantGenerator` from a plain-data `QuadrantRecipe` and the map's seed (derived from the world seed,
like every map's), into the same ASCII format the parser always read; new letters `T` (tree grove), `B` (boulder)
and `=` (barricade) became `DungeonMap` *blockers*, so fog, minimap, pathfinding and terrain keep working.

Small pure steps run in order, each a class of its own (`scripts/dungeon/generation/quadrant`):

| Step | What it does |
| --- | --- |
| Ground (`QuadrantGround`) | Grass; tree groves where seeded noise (`FastNoiseLite`) is highest, cut so exactly the recipe's share of the ground is grove however the noise falls; boulders on grass; ponds (deep water, wobbly edge, a shallow shore 1.5 cells wide) clear of the middle and the border; then the middle, where the village will stand (its size plus 3 cells of margin), cleared to plain grass |
| Border (`QuadrantBorder`) | A forest of groves, 5 cells thick, all round |
| Exits (`QuadrantExits`) | A 3-wide lane through the border in the middle of each side, with a barricade across its outer end (the way is shut until that quadrant exists) and a cleared approach inside the border |
| Village (`VillageGenerator`) | Draws the village (next section) from the recipe's size and the quadrant's random numbers |
| Reserve (`SetPiecePlacer.reserve`) | A spot for each set piece: the village in the very middle (it comes first), the ruin second (in a corner, below), the others inside the border, as far out as the piece asks, no farther from the middle than it allows, clear of the exits and of the pieces before them (the village and its 3 cells of grass among them), and as far from them as the pieces' spacing rules say |
| Fill the camps (`CampCrews.dress`) | Draws a band of monsters into each reserved camp by how far out it lies (below) |
| Place (`SetPiecePlacer.stamp`) | Draws each piece on its spot and clears a margin of ground round it; then walkable ground cut off from the start is turned into grove, so nothing is unreachable |
| Roads (`QuadrantRoads`) | Dirt roads (letter **`r`**, terrain `ROAD`) from the village gates to **2** of the 4 exits (Knob `road_count`, 0-4), the exits picked by a seeded shuffle; a road leaves by the gate on its exit's side. See below |
| Validate (`QuadrantRules`) | At least `min_walkable_share` (70%) of the ground inside the border walkable, the start inside the village, every exit's front cell, every piece's key cell and the outside of every village gate reachable |

A step that breaks a rule does not fail the map: the whole thing is made again with the next random numbers (the
generator reports how many tries it took). If every try fails (a recipe asking for the impossible), the last resort is
the same quadrant without groves, boulders and ponds; if a set piece still finds no spot (Tune → World can make the
plains too small or the village too big for it), the same without the ruin (a plains with no free corner for it), without camps and campfires (a plains too small for them), or without both; if even that fails, the default recipe without obstacles, so no tuning leaves the world
without a map. The same recipe and seed always
give the same map (`QuadrantRecipe.VERSION` goes in the map's record).

**Set pieces** (`SetPiece`: a drawing in the map format, its key cell, how far out it must lie, its margin) are stamped by
**one shared placer**; the camps, campfires, the ruin and the village are pieces for the same two
calls. The first is the **crypt entrance** (`SetPieces.crypt_entrance`): a 5x5 stone mausoleum with its door facing the
camera and the stairs down inside, at least halfway out from the middle (0 in the middle, 1 at the border, measured to
the nearest side in the same proportion on both axes: `QuadrantRecipe.outward`), with no road to it. Stepping onto its
stairs goes down, through the same transition rule as any stairs, to the first floor.

**Rules to know.** The "walkable at least 70%" share is counted over the ground *inside* the border (a thick border would
otherwise eat it). Groves and barricades stop walking, sight and shots; boulders are small cover: they stop walking and
shots but sight passes over them (`DungeonMap.is_see_through`). Deep water stops feet but not shots, as in the dungeon.
The plains hold monsters in camps and in the ruin, and loot only in the ruin's chest; the hero
starts in the village, in front of the inn.

**The ruin** (#39, `Ruins`, `SetPieces.ruin`) is a 25x19 walled courtyard hand-written in the vault format with a broken shrine
in the middle, where the chest stands. Walls are ordinary `#` (the crypt entrance's too) and rubble is boulders `B`; no new look.
The drawing has four possible 3-wide **gaps** (the `o` cells: north, south, west, east); each map opens a seeded 2 or 3 of them (Knobs
`ruin_gaps_min` / `ruin_gaps_max`, default 2 and 3), and the drawing is mirrored randomly, so one design reads as many ruins.
*Where.* In a **corner**: the chest (the piece's anchor, so the validator checks it can be reached) lies at least 40% of the way
out along both axes (`SetPiece.corner_share`), and never in the same corner (which of the four quarters round the middle,
`QuadrantRecipe.corner_of`) as the crypt entrance. The ruin is reserved right after the village, the crypt entrance after it, and the rule
holds both ways (`SetPiece.other_corner_than`), so the crypt entrance keeps its "at least halfway out" rule and just takes another quarter.
*Who.* The map's toughest band, made like a camp at the very edge (goblins and goblin archers, no kobolds) but always one monster
bigger than the biggest camp can be (Knob `ruin_band_size`, default 7, raised to that if the camp Knobs are tuned up), so its threat
(`CampCrews.threat`) is above every camp's whatever the seeds roll. It always starts wandering (`Ruins.WANDERING_SHARE` 1.0) and its
home is the chest cell, the ruin's middle: `Band.home_of` takes monsters within 6 cells of the chest for the ruin's band, id
`Ruins.NUMBER` (2,000,000: clear of room numbers from 0 and camp ids from 1,000,000).
*What.* The chest (map letter **`$`**, at most one per map, parsed to `DungeonMap.ruin_cell`) is guaranteed: `main.gd` places it with
`_spawn_chest(Ruins.NUMBER, cell)`, and opening it records `Ruins.NUMBER` in the `MapRecord`, so it stays open after the hero leaves and
returns. It holds one gear piece the hero doesn't hold (`LootTable.pick_item_id`), and sometimes a potion. Size is not a Knob: the
drawing is fixed, and a plains too small to fit it in a corner beside the village (100x60 at the Tune minimum) is made without a ruin, by one more
last-resort step of the generator (`QuadrantRecipe.without_ruin`); when the ruin has no corner anywhere beside the village
(`SetPiecePlacer.fits_anywhere`, every spot tried), the generator skips the remaining tries, which would all fail the same way and
each cost a village. *Planned lever:* a melee start has no ranged answer to a kiting Lich (#8); if playtests show it hurting, the first fix is
a ranged weapon in this chest (not built).

**The village** (#40) is the first piece the placer stamps, in the very middle (`SetPiece.at_center`), and the safe place
the run starts in. It is 36x28 cells by default (Tune → World) and made by pure steps (`scripts/dungeon/generation/village`),
each a class of its own, from the quadrant's random numbers:

| Step | What it does |
| --- | --- |
| Palisade (`VillagePalisade`) | A wall of `Y` all round with a 3-cell gate (`G`) in the middle of each side, in line with the plains' own exits |
| Streets (`VillageStreets`) | A plus of 3-wide streets (`:`, walkable beaten earth) from the four gates to a 9x9 square with a 3x3 well (`U`) in the middle. The seed moves the square up to 2 cells off the middle on each axis, so the streets don't always cross at the same place |
| Lots (`VillageLotPacker`, `VillageLots`) | In this order: the **inn**, whose door must face the square; one or two of the **smithy, market, church**; three to five **houses** (a small or a big one). A lot is a hand-written drawing (see below), turned a quarter turn at a time so its doorstep faces a street, and maybe mirrored (8 ways). It must stay off the streets, the other lots and the strip along the palisade, and never touch another building. Of the ways it fits, one of the snuggest is taken (most neighbours: palisade, lots, streets), so lots end up packed along the street edges |
| Colours | Each house gets one of four colours, the four shuffled by the seed, so a village shows as many colours as it has houses |
| Props (`VillageProps`) | Barrels and crates (`X`) on 15% of the leftover ground (Knob), but never at a gate and only where the walkable cells round a cell stay joined, so nothing gets walled off |
| Rules (`VillageRules`) | Every gate, the square and every lot's doorstep can be walked to from the start, and the inn faces the square |

**Fallbacks, so it never fails.** A seed whose lots don't fit is drawn again, 20 tries; then the plan shrinks, one house at a time
down to 3, then the market goes; if that still doesn't fit the village grows by 2 cells on each axis until it does. The latest
village's `fallbacks` and `attempts` are kept by the generator for tests and bug reports (`QuadrantGenerator.last_village`).

**Village lots** (`VillageLots.DESIGNS`) are drawings in the map format of a building plus one row of ground in front, which holds
the doorstep `D` and what always stands by it (a barrel `X`). Every drawing faces south, the door on the bottom row. `H` is a
house wall and gets its colour digit (`1`-`4`) when the village is done; the inn keeps its `D`, which is the **inn's doorstep**
the inn's Rest looks for (`DungeonMap.village.inn_doorstep`; see **Resting**); every other lot's `D` is plain ground. Footprints follow
the art at scale 6: small house 5x5, big house 5x6, smithy 8x7, church 6x7, inn 7x8, market 11x8. A new lot is a new entry (and
a model in `VillageModels`).

**Map letters** (`Village`, read by `DungeonMapParser`): `Y` palisade, `G` gate, `:` street or square (the terrain `PATH`), `U` well,
`X` barrel or crate, `D` the inn's doorstep, `I` inn, `C` church, `S` smithy, `M` market, `1`-`4` a house by colour, and `@` the
hero's start on a street (a `P` that keeps the earth under it). The palisade, buildings, well and props are `DungeonMap` blockers:
all stop walking; the palisade and buildings stop sight, the well and props (low) don't. The map's `village` (`Village`) holds the
palisade's area, the gates, the well, the inn's doorstep and every building (kind, colour, rect, which way its door faces).
Nothing in the village spawns a monster (monsters may still chase the hero in).

**The start and the naming.** The hero starts on the square in front of the inn's doorstep (`@`). `MapStage` starts a map with the
village's cells already explored (`Exploration.restore`), so the minimap and the fog show it from the first step. `Place.at` names
where the hero is: "The village" inside the palisade (gates included), otherwise the map's own name (`MapSpec.place_name`:
"The plains", "Crypt level 2"); the HUD and the arrival banner use it, and crossing a gate shows the banner again. The pause menu
and the run summary name the map.

**Village look.** Real art: KayKit **Medieval Hexagon** (CC0, `assets/kaykit_medieval_hexagon`, only the 17 pieces used; credited in
`Credits`): houses A and B in blue, red, green and yellow, the inn (the red tavern), church (blue), smithy (green), market (yellow),
well, wooden fence and fence gate as the palisade, barrel and two crates. The pieces are tiny next to a cell, so all are drawn
**x6** (Knob `building_scale`, Tune → World, next world; the well and props are fitted smaller). They are models of their own
(`VillageView3D`, built from `VillageModels`), not wall blocks. Houses vary in colour per seed; the inn, church, smithy and market
keep fixed ones. A piece standing between the camera and the hero turns see-through (a dithered `transparency`, the way walls
are cut down): the cells in front of the hero count as hiding, and a taller piece hides from farther off and wider
(`CameraFraming.cells_hiding(hero_cell, height)`); props are too low to hide the hero. Streets and the square are drawn as beaten
earth. Size: the pack adds about 1.3 MB of source (`.gltf`, `.bin`, one shared 15 KB te

**Dirt roads** (#41, `QuadrantRoads`) are landmarks to follow across a 160x90 map. Each is 3 cells wide, like the gate and the exit
it joins, and bends gently. Decisions: the step runs *after* the set pieces are stamped, so the road is routed round them
(nothing is moved for a road). Routing is `AStarGrid2D` over the cells where a 3x3 block is all open grass, with the cost of a cell
`1 + road_bend * noise` (seeded simplex, features about 16 cells across; Knob `road_bend`, default 3, 0 = as straight as the
obstacles allow), so the cheapest way wanders along the noise's valleys instead of running ruler-straight. Ends: the cell in
front of the village gate's middle, and the cell in front of the exit's barricade. Roads never cross groves, boulders,
ponds (shallows included: they would be fords, and this is about landmarks) or the village, and keep out of every other set piece's
footprint (apron plus 1 cell), so no camp, campfire, monster or crypt entrance is on or touching a road. That
rule is by construction, so a future set piece (the ruin) is avoided without the road knowing it. Both roads are routed before
either is drawn; they may run along or cross each other. The seed shuffles the four exits and the roads go to the first ones
that can be reached (boulders and ponds sometimes shut a 3-wide way to one); only if fewer than `road_count` can is the whole map
made again (as for any broken rule). Why: remaking the map for one shut exit cost extra tries on 10 of 25 seeds and made the
plains about 50% slower to build; with the fallback no seed of those needs one. Roads only recolour grass: walkable like it, same speed and sight, and nothing is placed on them. The crypt entrance
is never a road's end. Map letter **`r`** (parser: `Terrain.ROAD`, walkable like floor); the minimap paints it a darker tan than
the village streets (`MinimapPainter.ROAD_COLOR`), and the ground is drawn as dry earth (`BranchLook.road_color`). `QuadrantRecipe.VERSION` is 4.

**Camps and campfires** (`SetPieces.camp`, `SetPieces.campfire`, `CampCrews`, `Camps`). The plains get **6 camps** (at
least 18 cells apart) and **3 lone campfires** (at least 35 cells apart and 12 from any camp; the first within 12 cells
beyond the village's clear radius, `QuadrantRecipe.village_radius`), all clear of the village and the 3 cells of grass
round it (the village is placed first, and a piece keeps its own margin off every piece before it, so a camp's ground
is at least 5 cells from the palisade). A set piece can name a spacing group and the least distance to other
groups (`SetPiece.spaced`, measured between key cells; the larger of the two pieces' rules holds) and a farthest
distance from the middle (`near_centre`); the placer enforces both. A camp is reserved as 7x7 open grass round a
campfire (new map letter **`F`**, walkable scenery; the parser lists them in `DungeonMap.campfire_cells`), and
`CampCrews.dress` then writes its band into the drawing, so what lives there depends on where the camp landed:
*toughness* runs from 0 (30% of the way out, just past the village) to 1 (the border); band size rounds from 2 to 4
along it, each non-archer is a goblin with chance equal to the toughness (else a kobold), and at the edge up to half the
band are goblin archers (never all). Near camps are two or three kobolds; far ones are four goblins and archers. All
of these are recoloured Rogues like the dungeon's, so nothing new is modelled. Each camp starts **asleep or
wandering** by a 50/50 seeded roll (`Band.start_of` with the camp's band id, so the same seed rolls the same).

The map only knows its campfires and its monsters, so `Camps.campfire_of` says that a monster belongs to the campfire
within 3 cells of it; a campfire with monsters round it is a camp's (`Camps.camp_campfires`), the others are lone
(`Camps.lone_campfires`). That is the camp-to-campfire mapping the later rest spots build on (a camp's campfire is held
by its band until its last member dies). `Band.home_of` makes each camp a band whose home is its campfire (any other
monster lives at its room's middle), and `main.gd` gives each band its own Squad and shout group, the camps apart from
the room bands (`Camps.band_id`, clear of room numbers); progress counts still go by room. Monsters killed on the plains stay dead through the map record (they never respawn; only hurt ones heal
while the hero is away).

The campfire is built in code (`CampfireModel`: stones, logs, a flickering flame and an `OmniLight3D`); `MapView3D`
shows it once its cell has been seen. Its look follows its state (see **Resting**): cold stones when unlit, a flame
and light when burning (and for a camp's fire while its band holds it), dim coals with an "Embers 74 s" label over
them in embers; the flame, glow and label only in sight. The minimap marks campfires orange.

**Resting** (`scripts/rest/`). Healing outside fights used to be potions only; a campfire now heals too, as a
risk-free-ish pause rather than a free refill. Rules are pure, nodes only carry them out:
- `Campfire` is the state, **unlit -> burning -> embers -> unlit**. `light()` starts it; `tick(delta, hero_in_light,
  health, max_health)` moves time on and returns the whole health points healed. It burns 10 s, then lies in
  **embers for 90 s** before it can be lit again. While it burns, a hero in its light (2.5 cells) heals 50 health a
  second **up to 50% of their maximum health** (never past it). Stepping out of the light pauses the healing (the
  fire burns on); a hit or an attack (`interrupt()`) ends the healing for that lighting. A fire left burning when
  the hero leaves the map burns on when they come back but heals no more: leaving ended that rest (so the record
  needs no "interrupted" flag).
- `RestProfile` holds the numbers a place of rest follows (heal share, rate, burn, embers, light radius, reach):
  the campfire's are the class defaults, all Knobs in **Tune -> Rest**. The inn is the second profile,
  `RestProfile.inn()`: a **3 s** rest (`rest_seconds`), healing up to **100%** of max health, no embers, reach 1 cell
  from the doorstep, and `cancels_on_move`. Its Knobs (id `inn`) are only the rest time and the reach; the heal and
  the rest are the same fields the campfire uses. An ambush roll (#44) will be another field; `Campfire`,
  `InnRest` and `MonstersAround` never name a place.
- `MonstersAround` is the shared "may the hero rest" rule: **refused while any monster on the map is hunting the
  hero (`EnemyBrain.is_hunting`: noticing, hunting, in position, attacking), or any awake monster is within 16
  cells and in line of sight** (Knob). Sleeping monsters don't block. The game describes each monster as a
  `MonstersAround.Nearby`; a refusal shows a floating message ("Can't rest: something is hunting you").
- `RestSpot` (a node per campfire) is the carrying out: it ticks its `Campfire` every physics frame, so the burn
  and the cooldown **only run while the hero is on the map** (the map is gone, and the game paused, otherwise),
  heals the hero and, once the hero rests at it (`RestSpot.rest()`), listens for their hits and attacks: a hit or an
  attack ends the rest only at the fire the hero rests at, never at another fire burning on the map. `MapRecord` keeps each campfire's state and seconds left by
  its cell (`remember_campfire`, `campfire_at`; also through the dictionary), written on leaving.
- A camp's campfire is **held by its band** (`Camps.is_held`: any monster of the camp not killed in the record):
  no Rest, and it burns for them. Once its last monster dies it goes out and is a campfire like the others; kills
  stay in the record, so a cleared camp's fire is usable on return. Any map with `F` cells works the same (plains,
  and the crypt's).
- **The attack button becomes REST** while an unlit, un-held campfire is within reach (2 cells) **and no monster
  hunts the hero** (`RestOffer.shows_rest`): in a fight the button stays the attack, so a campfire never takes the
  weapon away mid-fight. With an awake monster merely in sight (watched) it still reads REST, and pressing it shows
  the refusal ("Can't rest: something is watching"); nobody is attacking then. **E** on the keyboard (which takes a
  floor item first when one is on offer) asks to rest at the un-held campfire in reach whatever the verdict, and
  answers with `RestOffer.refusal`: the monsters-around message, or "The fire is still embers: 42 s". With the mouse,
  left click still attacks. The monsters are only looked over while an unlit fire is in reach, and line of sight
  only worked out for awake monsters within the 16 cells.
- **The inn's rest** (#45) is `InnRest` (pure: `begin()`, `tick(delta, hero_moving)`, `interrupt()`, `heal_for()`) carried
  out by `InnSpot`, a node standing on the inn's doorstep (`village.inn_doorstep`, plains only). On the doorstep
  (`RestProfile.is_within_reach`) the attack button reads **REST** (E too) by the same `RestOffer.shows_rest`: calm or
  watched shows it, a **hunting** monster leaves the button the attack. Pressing it asks `MonstersAround` first: hunted or
  watched is refused with the same floating message (`RestOffer.inn_refusal`), E included. Otherwise the hero sits
  ("Resting..." floats up) and after 3 s is healed to full ("Fully rested"). **Moving** (stick or keys held past
  a tenth of full push, `Player.is_moving`, so a thumb resting on the floating stick doesn't count; or being carried
  off the doorstep, by a dash or a blink) or **being hit** (`Health.damaged`) cancels it ("Rest interrupted", nothing healed, the time
  already waited is lost). There is no ambush and no limit: after a finish or a cancel the hero can rest again at once.
  Pressing REST during a rest does nothing. Unlike the campfire, the monsters rule is asked only when the rest begins:
  a monster that starts hunting mid-rest ends it only by hitting the hero.

**Look.** The plains have their own `Branch` (outdoors, so the HUD and the arrival banner say "the plains" and the run
summary "on the plains") and `BranchLook`: grass ground, no torches, trees for small free-standing groves. Big groves
are canopy blocks (taller than walls, uneven), boulders low grey blocks, barricades brown ones: **stand-ins built in
code.** The planned KayKit Forest Nature trees and rocks and the Halloween Bits mausoleum could not be downloaded in the
build session (the packs are only offered on itch.io, which the sandbox blocks), so no new asset pack ships yet; a new
pack goes in its own folder of `assets/` with a Credits entry (`Credits.Entry.folder`) and only its used pieces, and
`test_shipped_assets` fails if a pack is uncredited or a file unused.

**Tune → World** lists every knob of the recipe (size, walkable share, border thickness, groves, boulders, ponds, the
village's width, height, share of barrels and crates and art scale, how far out the crypt entrance lies, and the camps:
how many, least apart, band sizes nearest and farthest, chance asleep; the lone campfires: how many, least apart, least
from a camp), all defaults living in `QuadrantRecipe`. They shape the next world, not the one
being played: the page shows the world's seed with **New world** (a new seed) and **Same seed again** (this seed, a fresh
hero), both applying the tuning first (`Run.next_world`, `Run.same_world_again`). The section also holds the crypt's two knobs
(campfire distance from the stairs, in rooms; share of bands wandering), defaults in `CryptRecipe`; `Run` keeps both
recipes of a world.

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
5. **Floor loot** (`*`): vault treasure, and half of the dead ends (rooms with one way in) hide an item: a potion or
   gear, rolled from the map's seed and the cell (see Floors). Exploring pays.
6. **Exit** (the stairs down, `>`): in the deepest room, in its corner farthest from the middle (where chests used
   to appear, kept so seeds still make the same maps). The start is the **stairs up** (`<`) on every floor, the first included (it leads back to the plains).

**Terrain.** Deep water (`~`) blocks walking but not sight or shots: a shooter across a pool can hit you, and
you can hit back, but nobody walks over. Shallow water (`,`, like Dungeon Crawl's) can be waded through, but
everyone in it moves at 60% speed; enemies go round it when dry ground is close. The Lair's caves have
puddles of it, and its lake and pool have shallow shores. Lava (`L`) can be crossed, but burns (100 damage on stepping in, then
every half second; the Shield blocks it). Enemies path around water and avoid lava when they can.

**Fog of war** (`Exploration`, `FogView`). You see 16 cells around you (farther than any weapon reaches, so
nothing hits you from the dark), through floor, water and lava but not walls or closed doors. What you have
seen stays drawn, dimmed; what you haven't is dark. Enemies out of sight are hidden.

**Minimap** (`MinimapPainter`, `MinimapView`). Top left of the HUD, a picture with one pixel per cell (shown at
2 px) of what `Exploration` has seen: floor, doors, water, lava and the stairs in their own colours (outdoors also
tree groves, boulders and the barricaded exits), cells in
view brighter than remembered ones, you as a bright dot. Walls and unseen cells are left blank, so the map's
shape shows through the gaps. It redraws whenever sight does. Enemies and loot aren't marked: the minimap is for
finding the way, and the fog already hides what you haven't seen. The **Map** button under the help line (or
M) shows or hides it, and the choice is saved with the settings so it holds across floors and runs.

**Big map** (`MapOverlay`). Tapping (or clicking) the minimap opens the same picture big over a dimmed screen, and
the game pauses until it is closed by a tap, a click, Esc or M. It is cropped to what has been explored, plus a
two-cell border, and scaled by a whole number of pixels per cell (at most 12, so a lone room doesn't turn into
blocks) so every cell stays a crisp square. It opens only from the minimap, so hiding the minimap hides the
way in too.

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
  utilities are glowing cubes, potions flasks. A weapon with no model (the knuckles) is a glowing cube in its
  colour, like a utility. **Items on the floor** stay hidden until their cell has been seen, then stay shown (like the fog's map
  memory).
- **Water and lava** move: slow waves with highlights (`shaders/liquid.gdshader`), lava slower and hotter.
- **Stairs** stand under a stone arch trimmed in gold (down) or silver (up).
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
counted across floors (`HeroState`); the lines are written by `RunSummary` (pure).

**Credits.** Everything third-party that ships (the three KayKit packs, Godot and its default Noto Sans font) is
listed in the pause menu's Credits screen. `Credits` is plain data and `CreditsPanel` only shows it, so a new
asset pack means one new entry (naming its `assets/` folder), and tests fail if a pack in `assets/` is not credited, has no
license file, or holds a model or texture nothing uses. CC0 does not require
attribution; we credit anyway, and the MIT and OFL licenses of the engine and font do ask for it.

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
  spellbook for the cloud, a bow built from plain parts (`BowModel`: the KayKit pack has none), a wand for the rest) and an attack animation (a slice, a two-handed slice, a
  crossbow shot, a spell cast).
- Characters stand idle, run while moving, play their attack when it is released, and flinch when hit.
  When they die they fall where they stand: a monster's body lingers a moment (with the burst of chunks),
  the hero's stays down until the summary. Animations only run while the character is in sight.
- A monster shows a mark over its health bar: a "z" while it sleeps, a "!" while it notices the hero
  (`Enemy.mark`, shown by `CharacterModel.show_mark`).
- Size: the animations are imported once (with the Knight) and shared, so the five models add about 2 MB
  to the phone download.

**Lingering ground.** Mephitic Cloud's poison and the Fireball's fire share one rule, `LingeringZone`: a circle
that hurts the bodies inside it each time a `TickClock` (pure: first tick, interval, tick count) says a tick is
due, until its time runs out. `PoisonCloud` hurts one side (foes of whoever threw it); `BurningGround` hurts
everyone, the thrower and other enemies included, exactly like the blast it follows, so standing in your own
fire hurts and a Shield blocks it. Its source is the thrower's ("your own Fireball"). The burn covers the blast
area and starts ticking half a second after impact, so a target that stays takes 200 + 3 x 34, about 300; one
that steps out of the blast right away only takes the 200 (dodging is the counter, as with Barley).

**Poison does not stack.** A body that stands in several poison clouds takes poison as if it stood in one: one tick
per 0.6 s at most, whichever cloud ticks first, for that cloud's damage. The rule is the pure `PoisonStatus`
(`try_tick(now)`: has a full tick interval passed since the last poison tick that went through? a frame or three
early still counts, so a lone cloud is never blocked by its own previous tick). Each poisonable body (`Enemy`,
`Player`) owns one, because "when was I last poisoned" is a fact about the body, not about any cloud; clouds don't
know each other and there is no registry or global. `PoisonCloud` overrides `LingeringZone._hurt` to call the
body's `take_poison(damage, source, now)` (`now` is physics frames over the tick rate) instead of `take_damage`.
A body stepping from one cloud into another is still limited to one tick per 0.6 s, and a Shield blocks poison
without using up the interval. Fire is a different effect and keeps its own rule: `BurningGround` still calls
`take_damage`, so poison and fire both apply together, and overlapping fires still add up.
Like explosions and clouds, it is a plain 2D node; the 3D view has nothing mirroring those, so the fire needs no mirror either.

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
