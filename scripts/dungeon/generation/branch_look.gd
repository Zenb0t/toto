class_name BranchLook
extends RefCounted
## How a branch looks: its floor, its walls, the light and what lies about. Plain data, read by the views.

## Floor colours: two alternating shades (built floors) or two blotchy ones (caves, see flagstones).
var floor_color := Color(0.4, 0.37, 0.43)
var floor_alt_color := Color(0.36, 0.33, 0.39)
## Built floors are flagstones set in grout; caves are bare earth or rock, with no grout.
var flagstones := true
var grout_color := Color(0.2, 0.18, 0.22)
var wall_color := Color(0.42, 0.39, 0.47)
var cap_color := Color(0.64, 0.6, 0.7)
## Speckles on cave walls (ore in the mines, moss in the lair); no speckles when transparent.
var vein_color := Color(0, 0, 0, 0)
var ambient_color := Color(0.6, 0.6, 0.7)
## Torches on the walls (built places are lit; caves mostly aren't).
var torches := true
## Small things lying along the walls (see DecorModel.make for the kinds).
var clutter: Array[String] = ["candle_lit", "candle_triple", "bottle_A_brown", "coin_stack_small"]
## Banners on the walls (see PropModel.BANNERS), or none.
var banners := true


static func dungeon() -> BranchLook:
	return BranchLook.new()


static func lair() -> BranchLook:
	var look := BranchLook.new()
	look.floor_color = Color(0.32, 0.4, 0.24)
	look.floor_alt_color = Color(0.38, 0.33, 0.22)
	look.flagstones = false
	look.wall_color = Color(0.36, 0.33, 0.27)
	look.cap_color = Color(0.36, 0.5, 0.26)
	look.vein_color = Color(0.3, 0.55, 0.25)
	look.ambient_color = Color(0.6, 0.7, 0.55)
	look.torches = false
	look.clutter = ["mushrooms", "mushrooms", "grass", "boulder", "grass"]
	look.banners = false
	return look


static func mines() -> BranchLook:
	var look := BranchLook.new()
	look.floor_color = Color(0.36, 0.3, 0.25)
	look.floor_alt_color = Color(0.31, 0.26, 0.22)
	look.flagstones = false
	look.wall_color = Color(0.4, 0.31, 0.24)
	look.cap_color = Color(0.52, 0.42, 0.33)
	look.vein_color = Color(0.95, 0.75, 0.3)
	look.ambient_color = Color(0.7, 0.6, 0.5)
	look.clutter = ["boulder", "boulder", "coin_stack_small", "bottle_A_brown"]
	look.banners = false
	return look


static func crypt() -> BranchLook:
	var look := BranchLook.new()
	look.floor_color = Color(0.3, 0.28, 0.36)
	look.floor_alt_color = Color(0.26, 0.24, 0.31)
	look.grout_color = Color(0.13, 0.11, 0.16)
	look.wall_color = Color(0.33, 0.3, 0.4)
	look.cap_color = Color(0.48, 0.44, 0.56)
	look.ambient_color = Color(0.5, 0.5, 0.68)
	look.clutter = ["coffin", "bones", "candle_lit", "candle_triple", "bones"]
	look.banners = false
	return look


static func depths() -> BranchLook:
	var look := BranchLook.new()
	look.floor_color = Color(0.62, 0.58, 0.56)
	look.floor_alt_color = Color(0.56, 0.52, 0.5)
	look.grout_color = Color(0.36, 0.3, 0.28)
	look.wall_color = Color(0.66, 0.62, 0.6)
	look.cap_color = Color(0.86, 0.78, 0.6)
	look.ambient_color = Color(0.72, 0.64, 0.6)
	look.clutter = ["brazier", "coin_stack_small", "candle_triple"]
	return look
