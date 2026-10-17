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

**Quadrant exit**:
A gap in a quadrant's border leading to the neighbouring quadrant, one in the middle of each side. Blocked by a barricade until that quadrant exists.
_Avoid_: Gate (that's the village's), stairs, door

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
