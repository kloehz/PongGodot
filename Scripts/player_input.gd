class_name PlayerInput extends Node

var input_direction := Vector2.ZERO
 
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
