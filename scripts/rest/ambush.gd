class_name Ambush
extends RefCounted
## The gamble of resting in the wild: each lighting of a campfire makes one seeded roll, and a hit brings a few of
## the area's monsters to the edge of the light, already hunting the hero. The inn never rolls.
##
## The roll depends on nothing but the map's seed, the campfire's cell and how many times it has been lit (the
## lighting, counted from 0, which the map record keeps): the same lighting always gives the same answer, so
## leaving, returning, reloading or retrying can't re-roll it. Who comes is picked the same way, from the monsters
## the map puts near the campfire. Where they appear is AmbushPlacement's; how they wait is AmbushParty's. Pure;
## every number is a Knob (Tune -> Rest).

## The monsters the map has this close to the campfire (its nearest spawns) are "the area's monsters".
const AREA_SPAWNS := 6
## Who comes when the map has no monster at all to take after.
const FALLBACK_MONSTER := "kobold"
## Band ids of ambushers start here, clear of room numbers (from 0), of the camps' (from Camps.FIRST_BAND_ID,
## 1,000,000) and of the ruin's band (2,000,000, #39).
const FIRST_BAND_ID := 3_000_000

## Tune keys are "<id>.<field>".
var id := "ambush"
## The chance a lighting of a campfire on the open plains brings an ambush.
var chance := 0.3
## The same in the crypt, where the dark is more dangerous.
var crypt_chance := 0.45
## How many monsters arrive.
var size := 3
## How long after the fire is lit they arrive, in seconds.
var delay_seconds := 4.0
## How far outside the fire's light they appear, in cells.
var margin_cells := 1.5


func knobs() -> Array[Knob]:
	return [
		Knob.new("chance", "Ambush chance on the plains", 0, 1, 0.05),
		Knob.new("crypt_chance", "Ambush chance in the crypt", 0, 1, 0.05),
		Knob.new("size", "Ambushers", 1, 6, 1),
		Knob.new("delay_seconds", "Ambushers arrive after (s)", 0.5, 20, 0.5),
		Knob.new("margin_cells", "Appear outside the light (cells)", 0.5, 4, 0.25),
	]


## The chance one lighting brings an ambush, on open ground or in the crypt.
func chance_for(outdoors: bool) -> float:
	return chance if outdoors else crypt_chance


## Whether this lighting of the campfire at fire (0 for the first time it is lit) brings an ambush.
func hits(map_seed: int, fire: Vector2i, lighting: int, outdoors: bool) -> bool:
	return _rng_of("roll", map_seed, fire, lighting).randf() < chance_for(outdoors)


## The monsters (Bestiary ids) that come, picked from the area's: the ones the map spawns nearest the fire.
func crew(map: DungeonMap, fire: Vector2i, map_seed: int, lighting: int) -> Array[String]:
	var area := _area_monsters(map, fire)
	var rng := _rng_of("crew", map_seed, fire, lighting)
	var picked: Array[String] = []
	for _i in size:
		picked.append(area[rng.randi_range(0, area.size() - 1)])
	return picked


## The dice AmbushPlacement picks this lighting's arrival cells by.
static func placement_rng(map_seed: int, fire: Vector2i, lighting: int) -> RandomNumberGenerator:
	return _rng_of("place", map_seed, fire, lighting)


## The id of the band the ambushers of a campfire make: different for each campfire of a map.
static func band_id(map: DungeonMap, fire: Vector2i) -> int:
	return FIRST_BAND_ID + fire.y * map.size.x + fire.x


func _area_monsters(map: DungeonMap, fire: Vector2i) -> Array[String]:
	var spawns := map.enemy_spawns.duplicate()
	spawns.sort_custom(func(a: Vector2i, b: Vector2i) -> bool:
		var da := Vector2(a - fire).length_squared()
		var db := Vector2(b - fire).length_squared()
		return da < db if da != db else (a.y < b.y if a.y != b.y else a.x < b.x))
	var area: Array[String] = []
	for cell: Vector2i in spawns.slice(0, AREA_SPAWNS):
		area.append(map.monster_at(cell))
	if area.is_empty():
		area.append(FALLBACK_MONSTER)
	return area


static func _rng_of(purpose: String, map_seed: int, fire: Vector2i, lighting: int) -> RandomNumberGenerator:
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(["ambush", purpose, map_seed, fire, lighting])
	return rng
