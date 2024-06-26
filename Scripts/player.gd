extends CharacterBody2D

const SPEED = 300.0

var team_color_enum = Constants.TEAM_COLOR_ENUM.NONE
var has_collisioned = false
var player_name = ""
var start_position: Vector2
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D

func _ready():
	if(!is_multiplayer_authority()):
		return
	position = start_position
	return

func _physics_process(_delta):
	if !is_multiplayer_authority(): return
	var directiony = Input.get_axis("ui_up", "ui_down")
	var directionx = Input.get_axis("ui_left", "ui_right")
	
	_play_animations(directiony, directionx)

	if directiony:
		velocity.y = directiony * SPEED
	else:
		velocity.y = move_toward(velocity.y, 0, SPEED)
		
	if directionx:
		velocity.x = directionx * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
	move_and_slide()
	
func _play_animations(x: float, y: float):
	if y == 1:
		animated_sprite.play("right")
	if y == -1:
		animated_sprite.play("left")
	if x == 1:
		animated_sprite.play("bot")
	if x == -1:
		animated_sprite.play("top")
	
func reset_position():
	position = start_position
