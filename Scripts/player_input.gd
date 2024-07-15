class_name PlayerInput extends Node

var input_direction := Vector2.ZERO
var center := Vector2.ZERO 

@export var action_left := "ui_left"
@export var action_right := "ui_right"
@export var action_up := "ui_up"
@export var action_down := "ui_down"


@export_range(0, 500, 1) var clampzone_size : float = 75
@export_range(0, 200, 1) var deadzone_size : float = 10

func _ready():
	input_direction = Vector2(200, 200)
	NetworkTime.before_tick_loop.connect(_gather)
	if get_multiplayer_authority() != multiplayer.get_unique_id():
		set_process(false)
		set_physics_process(false)
	input_direction = Input.get_vector("ui_left","ui_right","ui_up","ui_down")

func _gather():
	if not is_multiplayer_authority():
		return
		
	input_direction = Input.get_vector("ui_left","ui_right","ui_up","ui_down")

func _input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		if event.pressed:
			if center == Vector2.ZERO:
				center = event.position
		if event.is_released():
			Input.action_release(action_left)
			Input.action_release(action_right)
			Input.action_release(action_up)
			Input.action_release(action_down)
			center = Vector2.ZERO

	if event is InputEventScreenDrag:
		var vector : Vector2 = event.position - center
		var touch_position = event.position
		vector = vector.limit_length(clampzone_size)
		
		if vector.length_squared() > deadzone_size * deadzone_size:
			touch_position = (vector - (vector.normalized() * deadzone_size)) / (clampzone_size - deadzone_size)
		
		if touch_position.x > 0:
			Input.action_release(action_left)
			Input.action_press(action_right, touch_position.x)
		else:
			Input.action_release(action_right)
			Input.action_press(action_left, -touch_position.x)
		if touch_position.y > 0:
			Input.action_release(action_up)
			Input.action_press(action_down, touch_position.y)
		else:
			Input.action_release(action_down)
			Input.action_press(action_up, -touch_position.y)
