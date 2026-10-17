class_name Potion
extends RefCounted
## A consumable, like Dungeon Crawl's potions: found lying around, carried in the potion belt, and drunk
## with a tap for an effect on the drinker. Plain data; subclasses say what drinking does.

## Stable identifier: used in tuning keys, so never rename one.
var id := ""
var display_name := ""
## One line shown on the floor and in the belt.
var description := ""
var button_label := ""
var color := Color.WHITE
## How often it turns up compared with other potions.
var frequency := 1


## The fields the Tune screen may change.
func knobs() -> Array[Knob]:
	return []


## What drinking it does to the drinker.
func effect() -> UtilityEffect:
	return UtilityEffect.new()
