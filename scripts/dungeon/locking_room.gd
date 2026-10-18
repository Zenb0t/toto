class_name LockingRoom
extends RefCounted
## The rooms that lock when the hero walks in, and why: the boss arena (it opens when the Lich dies) and the trap
## rooms. A generated map marks each by one mark letter on a floor cell inside the room, which the map parser reads
## into DungeonMap.locking_rooms. Every other room never locks. Pure.

enum Kind { ARENA, TRAP }

## Mark letters in the map format (a floor cell of the room; nothing is drawn there).
const ARENA_MARK := "A"
const TRAP_MARK := "R"
## DungeonMap.locking_kind's answer for a room that never locks.
const NONE := -1


## The mark letter that makes a room of this kind.
static func mark_of(kind: Kind) -> String:
	return ARENA_MARK if kind == Kind.ARENA else TRAP_MARK


## Every mark letter of the map format.
static func marks() -> Array[String]:
	return [ARENA_MARK, TRAP_MARK]


## The kind a mark letter stands for, or NONE.
static func kind_of(mark: String) -> int:
	match mark:
		ARENA_MARK:
			return Kind.ARENA
		TRAP_MARK:
			return Kind.TRAP
	return NONE
