class_name RestOffer
extends RefCounted
## What the controls offer by a place of rest. The touch attack button reads REST only while the fire can be lit,
## the hero is within reach and no monster hunts them: in a fight the button stays the attack. (An awake monster
## merely in sight still lets it read REST; pressing it then says why not.) Rest asked for anyway (E on the
## keyboard, or REST while watched) is answered by refusal(). Pure.


## Whether the touch attack button reads REST. fire_usable: unlit and not held by a band.
static func shows_rest(fire_usable: bool, within_reach: bool, verdict: MonstersAround.Verdict) -> bool:
	return fire_usable and within_reach and verdict != MonstersAround.Verdict.HUNTED


## Why the hero can't rest at this fire now ("" when they can, or when it is burning: nothing to say then).
static func refusal(fire: Campfire, verdict: MonstersAround.Verdict) -> String:
	if fire.state == Campfire.State.EMBERS:
		return "The fire is still embers: %d s" % ceili(fire.seconds_left())
	if fire.can_light():
		return MonstersAround.message(verdict)
	return ""


## Why the hero can't rest at the inn now ("" when they can): only the monsters around can forbid it.
static func inn_refusal(verdict: MonstersAround.Verdict) -> String:
	return MonstersAround.message(verdict)
