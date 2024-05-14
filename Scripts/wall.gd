extends StaticBody2D

# Esto trabaja como singleton a nivel global
#@export var wallData: WallData

var wall_color = 0

func change_wall_color(current_ball_color):
	# Todo esto deberia ir en un script para cada wall?
	var sprite: Sprite2D = get_node("Sprite2D")
	var ball_color = Constants.team_color_object[current_ball_color]
	add_wall_color_point(current_ball_color)
	wall_color = current_ball_color
	sprite.modulate = ball_color
	rpc("change_wall_color_remote", current_ball_color)
	
@rpc("any_peer")
func change_wall_color_remote(current_ball_color_enum):
	var sprite: Sprite2D = get_node("Sprite2D")
	var color = Constants.team_color_object[current_ball_color_enum]
	wall_color = current_ball_color_enum
	sprite.modulate = color

@rpc("any_peer")
func reset_wall_color_remote():
	var sprite: Sprite2D = get_node("Sprite2D")
	wall_color = Constants.TEAM_COLOR_ENUM.NONE
	sprite.modulate = wall_color

func add_wall_color_point(current_ball_color):
	if current_ball_color == wall_color:
		return
	var scene_tree = get_tree().root
	var network_manager = scene_tree.get_node("NetworkManager")
	# TODO: Patch? i dont know what happening here
	if !network_manager.IS_SERVER:
		return
	if current_ball_color == Constants.TEAM_COLOR_ENUM.BLUE:
		if wall_color == Constants.TEAM_COLOR_ENUM.RED:
			network_manager.red_team_walls -= 1
		network_manager.blue_team_walls += 1
	if current_ball_color == Constants.TEAM_COLOR_ENUM.RED:
		if wall_color == Constants.TEAM_COLOR_ENUM.BLUE:
			network_manager.blue_team_walls -= 1
		network_manager.red_team_walls += 1
	network_manager.check_winner_team()
