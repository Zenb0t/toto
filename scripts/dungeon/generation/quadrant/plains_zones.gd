class_name PlainsZones
extends RefCounted
## The big picture of the plains: what each part of the land is. Zone centres are spread evenly over the ground
## inside the border, half a zone in from it (PoissonDisc), each with the room round it that no other zone reaches
## (half the way to the nearest other centre: the disc that fits in its Voronoi cell). Most zones are open meadow; a few hold a wood
## or a pond (woods and ponds keep off the forest border: a wood near it is smaller). The village's own ground, round the middle, is always
## meadow. Pure: the caller passes the random numbers.

enum Kind { MEADOW, WOOD, POND }

## A pond's zone needs this many cells of room beyond the pond's deep water (its shore, and a margin).
const POND_ROOM := 4
## A wood stays at least this many cells off the forest border, so it stands on its own instead of swelling it.
const WOOD_ROOM := 6
## A zone with no room for a wood this wide (its radius, in cells) stays meadow.
const MIN_WOOD_RADIUS := 6.0


## One part of the land.
class Zone:
	extends RefCounted
	var center: Vector2i
	var kind := Kind.MEADOW
	## How far from the centre the zone reaches before the next one starts, in cells.
	var reach := 0.0

	func _init(at: Vector2i, room: float) -> void:
		center = at
		reach = room


## The zones of a quadrant. A recipe asking for more woods or ponds than there are zones far enough from the
## village gets as many as there are.
static func plan(recipe: QuadrantRecipe, rng: RandomNumberGenerator) -> Array[Zone]:
	var land := recipe.interior().grow(-recipe.zone_spacing / 2)
	var centres := PoissonDisc.sample(land, recipe.zone_spacing, rng)
	var zones: Array[Zone] = []
	for centre in centres:
		zones.append(Zone.new(centre, _room_round(centre, centres)))
	var open_land := zones.filter(func(zone: Zone) -> bool: return _is_clear_of_village(zone, recipe))
	_shuffle(open_land, rng)
	var woods := 0
	for zone: Zone in open_land:
		if woods < recipe.wood_count and wood_radius(zone, recipe) >= MIN_WOOD_RADIUS:
			zone.kind = Kind.WOOD
			woods += 1
	var ponds := 0
	for zone: Zone in open_land:
		if ponds < recipe.pond_count and zone.kind == Kind.MEADOW and _has_room_for_a_pond(zone, recipe):
			zone.kind = Kind.POND
			ponds += 1
	return zones


## How far a wood in this zone reaches from its middle (before its edge wanders, see PlainsWoods): the recipe's
## share of the zone's room, but never closer than WOOD_ROOM to the forest border.
static func wood_radius(zone: Zone, recipe: QuadrantRecipe) -> float:
	var off_border := (_room_to_border(zone, recipe) - WOOD_ROOM) / (1.0 + PlainsWoods.EDGE_WOBBLE)
	return minf(zone.reach * recipe.wood_reach, off_border)


static func of_kind(zones: Array[Zone], kind: Kind) -> Array[Zone]:
	var found: Array[Zone] = []
	found.assign(zones.filter(func(zone: Zone) -> bool: return zone.kind == kind))
	return found


## Half the distance to the nearest other centre.
static func _room_round(centre: Vector2i, centres: Array[Vector2i]) -> float:
	var nearest := INF
	for other in centres:
		if other != centre:
			nearest = minf(nearest, Vector2(centre).distance_to(Vector2(other)))
	return nearest / 2.0


## Whether the biggest pond the recipe allows, with its shore, fits in the zone and stays off the border.
static func _has_room_for_a_pond(zone: Zone, recipe: QuadrantRecipe) -> bool:
	var needed := recipe.pond_radius_max + POND_ROOM
	return zone.reach >= needed and _room_to_border(zone, recipe) >= needed


## How many cells from the zone's centre to the nearest edge of the ground inside the border.
static func _room_to_border(zone: Zone, recipe: QuadrantRecipe) -> int:
	var inside := recipe.interior()
	return mini(mini(zone.center.x - inside.position.x, inside.end.x - 1 - zone.center.x),
		mini(zone.center.y - inside.position.y, inside.end.y - 1 - zone.center.y))


## Whether nothing of the zone overlaps the village and the grass round it.
static func _is_clear_of_village(zone: Zone, recipe: QuadrantRecipe) -> bool:
	return Vector2(zone.center - recipe.center()).length() - zone.reach > recipe.village_radius()


static func _shuffle(items: Array, rng: RandomNumberGenerator) -> void:
	for i in range(items.size() - 1, 0, -1):
		var j := rng.randi_range(0, i)
		var held: Variant = items[i]
		items[i] = items[j]
		items[j] = held
