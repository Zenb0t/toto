class_name RunSummary
extends RefCounted
## The end of a run in a few lines, like Dungeon Crawl's tombstone: how it ended, how deep the hero got,
## how strong they grew and how many monsters fell. Pure.

enum Ending { DIED, WON }


static func title(ending: Ending) -> String:
	return "You killed the Lich" if ending == Ending.WON else "You died"


## killer: what dealt the last blow (see Player.last_hurt_by); ignored for a win.
static func lines(run: Run, level: int, ending: Ending, killer: String) -> PackedStringArray:
	var result := PackedStringArray()
	if ending == Ending.DIED:
		var cause := "Killed by %s" % killer if killer != "" else "Killed"
		var map := run.current_map()
		if map.branch().outdoors:
			result.append("%s on the %s." % [cause, map.branch().display_name])
		else:
			result.append("%s on %s of %d." % [cause, map.place_name().to_lower(), WorldLayout.FLOOR_COUNT])
	else:
		result.append("The crypt is quiet at last. Keep exploring if you like.")
	result.append("Reached level %d." % level)
	var kills := run.hero.kills
	result.append("%d %s slain." % [kills, "monster" if kills == 1 else "monsters"])
	return result
