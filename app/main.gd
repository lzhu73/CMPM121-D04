## Engine adapter: keeps the clock, passes keys to the Session, and draws what it holds.
## It never decides rules: those live in core/session.gd.
extends Node3D

const GRID := Vector2i(48, 48)  # your call: bigger grids make the dragon feel finer
const TICK_SECONDS := 0.1
const CAMERA_OFFSET := Vector3(0, 11, 7.5)  # above and behind the head
const DIRECTIONS := {
	"ui_up": Vector2i.UP,
	"ui_down": Vector2i.DOWN,
	"ui_left": Vector2i.LEFT,
	"ui_right": Vector2i.RIGHT,
}

var session := Session.new(GRID)
var meshes := {}  # kit piece name -> Mesh, shared by everything that shows it (Flyweight)
var segments: Array[MeshInstance3D] = []
var camera := Camera3D.new()
var food_model := MeshInstance3D.new()
var score_label := Label.new()
var status_label := Label.new()
var _clock := 0.0
var _shake := 0.0


func _ready() -> void:
	meshes = Stage.load_kit()
	_build_stage()

	food_model.mesh = meshes["food"]
	add_child(food_model)

	add_child(score_label)
	score_label.position = Vector2(16, 16)
	score_label.add_theme_constant_override("outline_size", 4)

	add_child(status_label)
	status_label.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	status_label.add_theme_font_size_override("font_size", 28)
	status_label.add_theme_constant_override("outline_size", 6)

	_sync_all()


## Input arrives as events, so even a tap shorter than one frame is never missed.
func _unhandled_input(event: InputEvent) -> void:
	if session.over:
		if event.is_action_pressed("ui_accept"):
			_restart()
		return

	for action in DIRECTIONS:
		if event.is_action_pressed(action):
			session.turn(DIRECTIONS[action])


func _process(delta: float) -> void:
	if not session.over:
		_clock += delta
		while _clock >= TICK_SECONDS:
			_clock -= TICK_SECONDS
			var was_over := session.over
			session.tick()
			_draw_dragon()
			_draw_food_and_score()
			if session.over and not was_over:
				_on_crash()
				break

	_follow(delta)


## Sky, light, and tiles live in app/stage.gd; the camera follows the head.
func _build_stage() -> void:
	add_child(Stage.new(session.board.tiles, meshes))
	add_child(camera)
	camera.position = _center(session.dragon.body[0]) + CAMERA_OFFSET


## Ease toward the head each frame, so the camera glides while the dragon steps.
func _follow(delta: float) -> void:
	var target := _center(session.dragon.body[0]) + CAMERA_OFFSET
	camera.position = camera.position.lerp(target, 1 - exp(-3 * delta))
	if _shake > 0.0:
		_shake = max(0.0, _shake - delta * 2.5)
		camera.position += Vector3(
			randf_range(-0.35, 0.35) * _shake, 0.0, randf_range(-0.35, 0.35) * _shake
		)

	camera.look_at(camera.position - CAMERA_OFFSET)


func _on_crash() -> void:
	_shake = 1.0
	for i in session.dragon.body.size():
		segments[i].rotation.x = randf_range(-0.06, 0.06)
		segments[i].rotation.z = randf_range(-0.06, 0.06)
	status_label.text = (
		"CRASHED!\n\nFinal Score: %d\nPress Space or Enter to play again" % session.score
	)
	status_label.visible = true


func _restart() -> void:
	session = Session.new(GRID)
	_clock = 0.0
	_shake = 0.0
	camera.position = _center(session.dragon.body[0]) + CAMERA_OFFSET
	_sync_all()


func _sync_all() -> void:
	status_label.text = "Press an arrow key to begin"
	status_label.visible = true
	_draw_food_and_score()
	_draw_dragon()


func _draw_food_and_score() -> void:
	if session.started and not session.over:
		status_label.visible = false
	food_model.visible = session.food != Session.NO_FOOD
	if food_model.visible:
		food_model.position = _center(session.food)
	score_label.text = "Score: %d\n" % session.score


func _draw_dragon() -> void:
	var body := session.dragon.body
	while segments.size() < body.size():
		var segment := MeshInstance3D.new()
		add_child(segment)
		segments.append(segment)
	var placed := Kit.layout(body)
	for i in segments.size():
		var segment := segments[i]
		segment.visible = i < body.size()
		if not segment.visible:
			continue
		var cell := body[i]
		segment.mesh = meshes[Kit.Piece.keys()[placed[i][0]].to_lower()]
		segment.position = _center(cell)
		segment.rotation = Vector3(0, placed[i][1] * PI / 2, 0)


func _center(cell: Vector2i) -> Vector3:
	return Vector3(cell.x + 0.5, 0, cell.y + 0.5)
