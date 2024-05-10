extends CharacterBody2D

var speed = 300

var current_ball_color = Constants.TEAM_COLOR_ENUM.NONE

var blue_team_score = 0
var red_team_score = 0

# Called when the node enters the scene tree for the first time.
func _ready():
	if !multiplayer.is_server():
		return
	start_ball_movement()

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
		velocity = velocity.bounce(collision_info.get_normal())
	else:
		return
		
	var node_collisioned = collision_info.get_collider()
	
	if node_collisioned.is_in_group("IsTeam"):
		current_ball_color = node_collisioned.team_color_enum
		var sprite: Sprite2D = get_node("Sprite2D")
		sprite.modulate = Constants.team_color_object[current_ball_color]
		rpc("change_ball_color", node_collisioned.team_color_enum)

	if current_ball_color == Constants.TEAM_COLOR_ENUM.NONE:
		return

	if node_collisioned.is_in_group("Wall"):
		print("----------------------------")
		print("1111 ENTRAMOS ACA: ", current_ball_color)
		print("----------------------------")
		node_collisioned.change_wall_color(current_ball_color)

@rpc("any_peer")
func change_ball_color(team_color_enum):
	current_ball_color = team_color_enum
	var sprite: Sprite2D = get_node("Sprite2D")
	sprite.modulate = Constants.team_color_object[current_ball_color]
