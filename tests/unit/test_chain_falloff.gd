extends GutTest
## A chaining shot hits hardest first and loses damage with every jump.


func test_the_first_foe_takes_the_full_damage() -> void:
	assert_eq(ChainFalloff.damage_after(180, 0.65, 0), 180)


func test_each_jump_keeps_a_share_of_the_damage_before_it() -> void:
	var hits: Array[int] = []
	for jumps in 4:
		hits.append(ChainFalloff.damage_after(180, 0.65, jumps))

	assert_eq(hits, [180, 117, 76, 49] as Array[int])


func test_keeping_everything_makes_every_hit_equal() -> void:
	assert_eq(ChainFalloff.damage_after(180, 1.0, 3), 180)


func test_a_negative_jump_count_counts_as_the_first_hit() -> void:
	assert_eq(ChainFalloff.damage_after(180, 0.5, -2), 180)
