class_name BoneSpray
extends Weapon
## The Lich's Bone Spray: 3 waves of 5 bone shards in a half circle in front of him, toward the hero, each wave
## starting a little way out from him and offset (angularly) from the last, so the gaps move and the hero has to
## read them. Built from the Shot and Spread pieces: the shards are ordinary shots, stopped by walls and pillars.
## The pattern is pure (wave_angles_degrees, shard_directions, start_point, wave_delay); attacks() only turns it
## into Shots, the later waves carrying a delay so the world releases them one after another (see Shot.delay).
##
## The first wave is aimed straight at the hero; every second wave after it is turned by wave_offset_degrees and the
## ones between go back, so each wave is offset from the last. The default offset is half the gap between two
## neighbouring shards: the odd waves come through the gaps of the even ones, and a hero who stands still is hit.
## This holds its tunable numbers (Tune → Lich); the defaults live here. The Enemy swaps it in as the weapon of
## the cast (see SpellPicker.Spell.BONE_SPRAY).

const DEFAULT_SHARDS_PER_WAVE := 5
const DEFAULT_WAVES := 3
## A half circle.
const DEFAULT_SPREAD_DEGREES := 180.0
## Half the gap between two shards of a wave (180 / 4 / 2).
const DEFAULT_WAVE_OFFSET_DEGREES := 22.5
const DEFAULT_WAVE_INTERVAL_SECONDS := 0.4
## How far from the Lich the shards start, in cells: "a little way out".
const DEFAULT_START_DISTANCE_CELLS := 1.5
const DEFAULT_SHARD_SPEED := 200.0
const DEFAULT_SHARD_RANGE := 520.0
const DEFAULT_DAMAGE := 80
const DEFAULT_WINDUP := 0.5
const SHARD_SIZE := 5.0
const SHARD_COLOR := Color(0.92, 0.9, 0.78)

var shards_per_wave := DEFAULT_SHARDS_PER_WAVE
var waves := DEFAULT_WAVES
var spread_degrees := DEFAULT_SPREAD_DEGREES
var wave_offset_degrees := DEFAULT_WAVE_OFFSET_DEGREES
var wave_interval_seconds := DEFAULT_WAVE_INTERVAL_SECONDS
var start_distance_cells := DEFAULT_START_DISTANCE_CELLS
var shard_speed := DEFAULT_SHARD_SPEED
var shard_range := DEFAULT_SHARD_RANGE
var damage := DEFAULT_DAMAGE


func _init() -> void:
	id = "bone_spray"
	display_name = "Bone Spray"
	description = "Waves of bone shards in a half circle."
	button_label = "SPRAY"
	color = SHARD_COLOR
	windup = DEFAULT_WINDUP
	# One cast: the Lich's spell pause is his pace, not an ammo bar.
	ammo = 1
	reload = 0.0
	attack_interval = 0.0


func knobs() -> Array[Knob]:
	return [
		Knob.new("shards_per_wave", "Shards per wave", 1, 12, 1),
		Knob.new("waves", "Waves", 1, 6, 1),
		Knob.new("spread_degrees", "Spread (deg)", 30, 360, 5),
		Knob.new("wave_offset_degrees", "Offset between waves (deg)", 0, 90, 2.5),
		Knob.new("wave_interval_seconds", "Time between waves (s)", 0.05, 2.0, 0.05),
		Knob.new("start_distance_cells", "Shards start this far out (cells)", 0, 4, 0.25),
		Knob.new("shard_speed", "Shard speed", 60, 600, 10),
		Knob.new("shard_range", "Shard range", 100, 1000, 10),
		Knob.new("damage", "Shard damage", 10, 300, 10, true),
		Knob.new("windup", "Telegraph (s)", 0.1, 2.0, 0.05),
	]


## The angles, in degrees from the aim, of the shards of a wave (0 is the first): the evenly fanned half circle,
## turned by the wave's share of the offset.
func wave_angles_degrees(wave: int) -> Array[float]:
	var angles := Spread.angles_degrees(shards_per_wave, spread_degrees)
	var turn := wave_turn_degrees(wave)
	for index in angles.size():
		angles[index] += turn
	return angles


## How far a wave is turned from the aim: none for the first, the whole offset for the second, none again for the
## third, and so on.
func wave_turn_degrees(wave: int) -> float:
	return wave_offset_degrees * (wave % 2)


## The directions the shards of a wave fly in, for an aim.
func shard_directions(aim: Vector2, wave: int) -> Array[Vector2]:
	var directions: Array[Vector2] = []
	for angle in wave_angles_degrees(wave):
		directions.append(aim.normalized().rotated(deg_to_rad(angle)))
	return directions


## Where a shard starts: a little way out from the Lich, along its own direction.
func start_point(origin: Vector2, direction: Vector2) -> Vector2:
	return origin + direction.normalized() * start_distance_cells * DungeonView.TILE_SIZE


## Seconds after the cast that a wave is released.
func wave_delay(wave: int) -> float:
	return wave * wave_interval_seconds


## Every shard of every wave; the shards of later waves carry the delay that releases them in turn.
func attacks(origin: Vector2, direction: Vector2, _aim_distance: float) -> Array:
	var shards: Array = []
	for wave in waves:
		for shard_direction in shard_directions(direction, wave):
			var shard := Shot.new(start_point(origin, shard_direction), shard_direction, shard_speed, damage, shard_range)
			shard.delay = wave_delay(wave)
			shard.size = SHARD_SIZE
			shard.color = SHARD_COLOR
			shards.append(shard)
	return shards


func travel_seconds(distance: float) -> float:
	return distance / shard_speed


func aim_range() -> float:
	return shard_range


## The preview is the half circle the spray covers.
func aim_shape() -> AimShape:
	return AimShape.cone(shard_range, spread_degrees)
