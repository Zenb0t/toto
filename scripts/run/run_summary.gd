class_name RunSummary
extends RefCounted
## The end of a run in a few lines, like Dungeon Crawl's tombstone: how it ended, how deep the hero got,
## how strong they grew and how many monsters fell. Pure.

enum Ending { DIED, ESCAPED }


static func title(ending: Ending) -> String:
	return "You escaped the dungeon!" if ending == Ending.ESCAPED else "You died"


## killer: what dealt the last blow (see Player.last_hurt_by); ignored for an escape.
static func lines(run: Run, level: int, ending: Ending, killer: String) -> PackedStringArray:
	var result := PackedStringArray()
	if ending == Ending.DIED:
		var cause := "Killed by %s" % killer if killer != "" else "Killed"
		var map := run.current_map()
		if map.branch().outdoors:
			result.append("%s on the %s." % [cause, map.branch().display_name])
		else:
			result.append("%s in the %s (floor %d of %d)." % [
				cause, map.branch().display_name, map.floor_number, WorldLayout.FLOOR_COUNT])
	else:
		result.append("Escaped with the treasure of floor %d." % WorldLayout.FLOOR_COUNT)
	result.append("Reached level %d." % level)
	var kills := run.hero.kills
	result.append("%d %s slain." % [kills, "monster" if kills == 1 else "monsters"])
	return result
