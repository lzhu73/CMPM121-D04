extends "res://tests/test_case.gd"


func test_nothing_moves_until_the_first_arrow_key() -> void:
	var session := Session.new(Vector2i(10, 10))
	var start_head := session.dragon.body[0]

	session.tick()
	session.tick()
	assert_eq(session.dragon.body[0], start_head)
	assert_true(not session.over)

	#reversing into the neck should also not start the run
	session.turn(Vector2i.LEFT)
	session.tick()
	assert_eq(session.dragon.body[0], start_head)

	#a valid direction starts movement
	session.turn(Vector2i.RIGHT)
	session.tick()
	assert_eq(session.dragon.body.front(), start_head + Vector2i(1, 0))


func test_a_tick_moves_the_dragon_head() -> void:
	var session := Session.new(Vector2i(10, 10))
	session.turn(Vector2i.RIGHT)
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
	session.turn(Vector2i.RIGHT)
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
	session.turn(Vector2i.RIGHT)
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


func test_hitting_a_wall_ends_the_run() -> void:
	var session := Session.new(Vector2i(10, 10))
	session.turn(Vector2i.RIGHT)
	for i in 3:
		session.tick()
		assert_true(not session.over)
	session.tick()
	assert_true(session.over)


func test_biting_the_body_ends_the_run() -> void:
	var session := Session.new(Vector2i(10, 10))
	session.dragon.body = [
		Vector2i(5, 5),
		Vector2i(4, 5),
		Vector2i(3, 5),
		Vector2i(2, 5),
		Vector2i(1, 5),
	]
	session.food = Vector2i(1, 1)

	session.turn(Vector2i.DOWN)
	session.tick()

	session.turn(Vector2i.LEFT)
	session.tick()

	session.turn(Vector2i.UP)
	session.tick()

	assert_true(session.over)


func test_chasing_own_tail_is_safe() -> void:
	var session := Session.new(Vector2i(10, 10))
	session.dragon.body = [
		Vector2i(5, 5),
		Vector2i(4, 5),
		Vector2i(4, 4),
		Vector2i(5, 4),
	]
	session.food = Vector2i(1, 1)

	session.turn(Vector2i.UP)
	session.tick()
	assert_true(not session.over)
	assert_eq(session.dragon.body[0], Vector2i(5, 4))
