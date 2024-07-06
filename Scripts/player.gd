extends CharacterBody2D

const SPEED = 300.0

var team_color_enum = Constants.TEAM_COLOR_ENUM.NONE
var has_collisioned = false
var player_name = ""
var start_position: Vector2
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var rollback_synchronyzer = $RollbackSynchronizer

@export var input: PlayerInput

func _ready():
	position = start_position
	rollback_synchronyzer.process_settings()

func _apply_movement_from_input(delta):
	var direction = input.input_direction
	
	# Apply movement
	if direction:
		velocity = direction * SPEED
	else:
		velocity = Vector2.ZERO
	velocity *= NetworkTime.physics_factor
	move_and_slide()
	velocity /= NetworkTime.physics_factor

func _rollback_tick(delta, tick, is_fresh):
	_apply_movement_from_input(delta)

