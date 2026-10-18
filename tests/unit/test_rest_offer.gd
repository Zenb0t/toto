extends GutTest
## What the controls offer by a campfire: REST on the attack button unless a fight is on, and why a rest is refused.

const CALM := MonstersAround.Verdict.CALM
const HUNTED := MonstersAround.Verdict.HUNTED
const WATCHED := MonstersAround.Verdict.WATCHED


func test_the_button_reads_rest_by_a_usable_fire_when_calm() -> void:
	assert_true(RestOffer.shows_rest(true, true, CALM))


func test_in_a_fight_the_button_stays_the_attack() -> void:
	assert_false(RestOffer.shows_rest(true, true, HUNTED))


func test_a_monster_merely_watching_still_lets_the_button_read_rest() -> void:
	assert_true(RestOffer.shows_rest(true, true, WATCHED))


func test_no_rest_on_the_button_out_of_reach_or_by_a_fire_that_cannot_be_lit() -> void:
	assert_false(RestOffer.shows_rest(true, false, CALM))
	assert_false(RestOffer.shows_rest(false, true, CALM))


func test_an_unlit_fire_is_refused_only_with_monsters_around() -> void:
	var fire := Campfire.new()

	assert_eq(RestOffer.refusal(fire, CALM), "")
	assert_eq(RestOffer.refusal(fire, HUNTED), MonstersAround.message(HUNTED))
	assert_eq(RestOffer.refusal(fire, WATCHED), MonstersAround.message(WATCHED))


func test_a_fire_in_embers_says_how_long_until_it_can_be_lit() -> void:
	var fire := Campfire.new(RestProfile.campfire(), Campfire.State.EMBERS, 41.2)

	assert_eq(RestOffer.refusal(fire, CALM), "The fire is still embers: 42 s")


func test_a_burning_fire_has_nothing_to_refuse() -> void:
	var fire := Campfire.new()
	fire.light()

	assert_eq(RestOffer.refusal(fire, HUNTED), "")
