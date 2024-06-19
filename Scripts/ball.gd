extends CharacterBody2D

var speed = 300

var current_ball_color = Constants.TEAM_COLOR_ENUM.NONE

var blue_team_score = 0
var red_team_score = 0

# Called when the node enters the scene tree for the first time.
func _ready():
	if !multiplayer.is_server():
		return
	rpc("start_ball_movement")

@rpc("any_peer", "call_local")
func start_ball_movement():
	if randi() % 2 == 0:
		velocity.x = 1
	else:
		velocity.x = -1

	if randi() % 2 == 0:
		velocity.y = 1
	else:
		velocity.y = -1
	velocity *= speed

func _physics_process(delta):
	if speed == 0:
		return
	var collision_info = move_and_collide(velocity * delta)
	if collision_info:
		# TODO: Y si aca en vez de syncronizar el movimiento hago
		# que se mueva y replique la direccion del movimiento en cada jugador?
		velocity = velocity.bounce(collision_info.get_normal())

@rpc("any_peer")
func change_ball_color(team_color_enum):
	current_ball_color = team_color_enum
	var sprite: Sprite2D = get_node("Sprite2D")
	sprite.modulate = Constants.team_color_object[current_ball_color]

func _on_area_2d_body_entered(node_collisioned):
	#velocity = velocity.bounce(node_collisioned.get_normal())
	if !multiplayer.is_server():
		return
	# si choca contra un jugador
	if node_collisioned.is_in_group("IsTeam"):
		change_ball_color(node_collisioned.team_color_enum)
		rpc("change_ball_color", node_collisioned.team_color_enum)

	# Si la pelota no tiene color
	if current_ball_color == Constants.TEAM_COLOR_ENUM.NONE:
		return

	# si la pelota choca contra una pared
	if node_collisioned.is_in_group("Wall"):
		node_collisioned.change_wall_color(current_ball_color)
