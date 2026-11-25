extends "res://tests/test_case.gd"


func test_a_tick_moves_the_dragon_head() -> void:
	var session := Session.new(Vector2i(10, 10))
	session.tick()
	assert_eq(session.dragon.body[0], Vector2i(6, 5))


func test_the_dragon_starts_on_open_floor_inside_a_wall() -> void:
	var session := Session.new(Vector2i(10, 10))
	assert_true(session.board.is_solid(Vector2i(0, 0)))
	assert_true(not session.board.is_solid(session.dragon.body[0]))


func test_a_bite_grows_one_segment_and_scores_one_point() -> void:
	var session := Session.new(Vector2i(10, 10))
	var old_length := session.dragon.body.size()

	# Put food directly in front of the head.
	session.food = session.dragon.body[0] + Vector2i.RIGHT
	session.tick()
	assert_eq(session.dragon.body.size(), old_length + 1)
	assert_eq(session.score, 1)

	# An ordinary move should keep the same length and score.
	session.food = Vector2i(1, 1)
	session.tick()
	assert_eq(session.dragon.body.size(), old_length + 1)
	assert_eq(session.score, 1)


func test_new_food_uses_the_only_free_floor_cell() -> void:
	var session := Session.new(Vector2i(8, 3))
	session.food = Vector2i(5, 1)
	session.tick()
	assert_eq(session.food, Vector2i(6, 1))

	session.tick()
	assert_eq(session.score, 2)
	assert_eq(session.food, Session.NO_FOOD)


func test_starting_food_is_free_and_repeatable() -> void:
	var session := Session.new(Vector2i(10, 10))
	var replay := Session.new(Vector2i(10, 10))
	assert_true(not session.board.is_solid(session.food))
	assert_true(session.food not in session.dragon.body)
	assert_eq(session.food, replay.food)
