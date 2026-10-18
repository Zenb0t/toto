class_name VillageRules
extends RefCounted
## The last step of the village: checks it against the rules a village must keep. It changes nothing; it names the
## first rule that is broken (so the generator can try again and a test can say why), or returns "" when all hold.
## Pure.


static func broken_rule(grid: QuadrantGrid, layout: VillageLayout, lots: Array[VillageLotPacker.Placed]) -> String:
	var start := grid.find(QuadrantGrid.START)
	if start == QuadrantGrid.NO_CELL:
		return "the hero has no start"
	var reached := grid.reachable_from(start)
	for side in QuadrantExits.SIDES:
		for gate in VillagePalisade.gate_cells(grid.size, side):
			if not reached.has(gate):
				return "the gate on side %s can't be reached" % side
	if not reached.has(layout.square.position):
		return "the square can't be reached"
	for lot in lots:
		if not reached.has(lot.doorstep):
			return "the %s's doorstep can't be reached" % lot.lot_id
		if lot.lot_id == VillageLots.INN and not layout.is_square(lot.front):
			return "the inn doesn't face the square"
	return ""
