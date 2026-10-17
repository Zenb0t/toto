# Toto

A top-down dungeon crawler for phones: Brawl Stars combat in a Dungeon Crawl Stone Soup world. This glossary pins
down the words the design uses for the first zone (village, plains, crypt).

## Language

### World

**Quadrant**:
One map of the world's 3×3 grid, entered and left through its exits. The run starts in the centre quadrant.
_Avoid_: Zone, region, level, floor (for an outdoor map)

**Plains**:
The open grassland of the centre quadrant around the village: groves, boulders, ponds and monster camps.
_Avoid_: Field, overworld

**Village**:
The palisaded settlement in the centre of the plains where every run starts, with a gate on each side. No monsters live there, though they may chase the hero in.
_Avoid_: Town, hub, base, safe zone

**Inn**:
The village building where the hero takes a full rest: full health after a short wait, with no risk and no limit on uses.
_Avoid_: Tavern, hotel

**Village lot**:
One piece of the village, such as a house, the inn or the square, with its doorstep and the things that always stand by it. A village is fitted together from lots.
_Avoid_: Plot, tile, building (a lot holds more than its building)

**Square**:
The open space at the heart of the village, with the well, where the streets from the four gates meet. The inn faces it.
_Avoid_: Plaza, centre, market (that's a lot of its own)

**Quadrant exit**:
A gap in a quadrant's border leading to the neighbouring quadrant, one in the middle of each side. Blocked by a barricade until that quadrant exists.
_Avoid_: Gate (that's the village's), stairs, door

**Ruin**:
A broken-walled set piece in one corner of the plains, home to the toughest group on the map and a guaranteed chest.
_Avoid_: Vault (for the ruin itself), fort, castle

**Camp**:
The spot on the plains, around a campfire, where one band of monsters lives, asleep or wandering. Camps farther from the village hold tougher bands. Once its band is dead, the campfire is the hero's to rest at.
_Avoid_: Spawn, nest, lair (that's a branch)

**Crypt entrance**:
A small stone mausoleum on the plains with stairs down to the first level of the crypt.
_Avoid_: Dungeon entrance, portal

### Monsters

**Band**:
The monsters that live together at one home and start the same way, asleep or wandering. Each one gives up a chase on its own.
_Avoid_: Group, pack, squad (that's how a band takes turns to attack)

**Home**:
The spot a band lives at and goes back to when one of its members gives up a chase: a camp's campfire, the middle of the ruin, or a crypt room.
_Avoid_: Spawn, lair, post

**Noise**:
What the hero's attacks make: it wakes monsters close by, even ones that can't see the hero.
_Avoid_: Sound, alarm

**Shout**:
The noise a monster makes when it notices the hero. Every monster it wakes shouts in turn, so a band, or a camp close by, wakes one after another.
_Avoid_: Alert, call, aggro

### Crypt

**Lich**:
The unique boss at the bottom of the crypt, killed to win a run. A named monster of its own, separate from the regular Necromancer.
_Avoid_: Necromancer (for the boss), final boss

**Necromancer**:
A regular human monster (`n` in the Bestiary) that fights with the Mephitic Cloud. Not a boss.
_Avoid_: Lich

**Boss arena**:
The crypt room where the Lich waits. Its doors lock when the hero enters and open when the Lich dies.
_Avoid_: Boss room, boss chamber

**Bone Spray**:
A Lich spell: waves of bone shards fly outward from a half circle in front of him.
_Avoid_: Bone spears, shard burst

**Summon Undead**:
A Lich spell: skeletons rise from marked spots on the floor near him.
_Avoid_: Raise dead, spawn

**Summon cap**:
The most summoned skeletons that may be alive at once. Only living skeletons count.
_Avoid_: Skeleton limit, minion cap
