class_name Session
extends RefCounted

const NO_FOOD := Vector2i(-1, -1)

var board: Board
var dragon: Dragon
var food := NO_FOOD
var score := 0
var started := false
var over := false
var rng := RandomNumberGenerator.new()


func _init(grid_size: Vector2i) -> void:
	board = Board.bordered(grid_size)
	dragon = Dragon.new(grid_size)
	rng.seed = 121
	_place_food()

func turn(direction: Vector2i) -> void:
	if over:
		return
	if not started:
		if direction == -dragon.heading:
			return
		started = true
	dragon.turn(direction)


func tick() -> void:
	if not started or over:
		return

	var old_tail: Vector2i = dragon.body.back()
	dragon.tick()

	var head := dragon.body[0]
	if board.is_solid(head) or head in dragon.body.slice(1):
		over = true
		return

	if head == food:
		dragon.body.append(old_tail)
		score += 1
		_place_food()


func _place_food() -> void:
	var free_cells: Array[Vector2i] = []
	for cell: Vector2i in board.tiles:
		if not board.is_solid(cell) and cell not in dragon.body:
			free_cells.append(cell)

	if free_cells.is_empty():
		food = NO_FOOD
	else:
		food = free_cells[rng.randi_range(0, free_cells.size() - 1)]
