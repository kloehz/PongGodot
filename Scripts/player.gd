extends CharacterBody2D

const SPEED = 300.0

var team_color_enum = Constants.TEAM_COLOR_ENUM.NONE
var has_collisioned = false
var player_name = ""
var start_position: Vector2

func _enter_tree():
	pass
	#name = str(get_multiplayer_authority())
	#set_multiplayer_authority(name.to_int())

func _ready():
	if(!is_multiplayer_authority()):
		return
	position = start_position
	return

func _physics_process(_delta):
	if !is_multiplayer_authority(): return
	var directiony = Input.get_axis("ui_up", "ui_down")
	var directionx = Input.get_axis("ui_left", "ui_right")
	if directiony:
		velocity.y = directiony * SPEED
	else:
		velocity.y = move_toward(velocity.y, 0, SPEED)
		
	if directionx:
		velocity.x = directionx * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
	move_and_slide()
	
func reset_position():
	position = start_position
	#for i in get_slide_collision_count():
		#var c = get_slide_collision(i)
		#if c.get_collider() is RigidBody2D && !has_collisioned:
			#print("entro: ", has_collisioned)
			#c.get_collider().apply_central_impulse(-c.get_normal() * 80)
