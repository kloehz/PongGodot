extends Node2D

var PORT: int = 3000#OS.get_environment("GODOT_PORT").to_int() # 25565
var IP_REMOTE: String = "127.0.0.1"#OS.get_environment("GODOT_IP") # "127.0.0.1"
var IS_SERVER: int = 0#OS.get_environment("GODOT_SERVER").to_int() # 0 - 1

@export var player_scene: PackedScene
@export var ball_scene: PackedScene
@export var goal_control: Control

@onready var name_control = $CanvasLayer/NameControl
@onready var connection_panel = $CanvasLayer/ConnectionPannel
@onready var player_name_label = $CanvasLayer/NameControl/PlayerName
@onready var players_ready_label: Label = $CanvasLayer/ConnectionPannel/GridContainer/PlayersReady
@onready var total_players_label: Label = $CanvasLayer/ConnectionPannel/GridContainer/TotalPlayers
@onready var ready_button: Button = $CanvasLayer/ConnectionPannel/ReadyButton
@onready var blue_team_grid: GridContainer = $CanvasLayer/ConnectionPannel/BlueTeam
@onready var red_team_grid: GridContainer = $CanvasLayer/ConnectionPannel/RedTeam
@onready var red_team_button = $CanvasLayer/ConnectionPannel/RedTeamButton
@onready var blue_team_button = $CanvasLayer/ConnectionPannel/BlueTeamButton
@onready var blue_scoreboard = $Scoreboard/BlueScore
@onready var red_scoreboard = $Scoreboard/RedScore

var red_team_score: int = 0
var blue_team_score: int = 0
var hasBallSpawned: bool = false
var goal_score: int = 8
var new_ball: CharacterBody2D;
var new_ball_v2: CharacterBody2D;
var players_count = 0
var players_ready = 0
var players_list = {}
var is_ready = false

var rng = RandomNumberGenerator.new()

# ------------------------------------- Lobby functions -------------------------------------

func _on_confirm_name_pressed():
	name_control.hide()
	_on_player_connection()
	connection_panel.show()

func _on_player_connection():
	players_list[str(multiplayer.get_unique_id())] = {
		"player_name" = player_name_label.text
	}
	rpc("_update_players_state_labels_v2", players_count, players_ready)
	_update_players_state_labels_v2(players_count, players_ready)
	rpc("_update_players_state_v2", players_list)

func add_new_player(player_id):
	# Separate spawns based on teams
	var temp_player: CharacterBody2D = player_scene.instantiate()
	temp_player.set_multiplayer_authority(player_id.to_int())
	temp_player.player_name = players_list[player_id]["player_name"]
	temp_player.team_color_enum = players_list[player_id]["team_color"]
	var player_sprite = temp_player.get_node("Sprite2D")
	player_sprite.modulate = Constants.team_color_object[players_list[player_id]["team_color"]]
	# here we need to spawn players on side
	temp_player.team_color_enum = players_list[player_id]["team_color"]
	if players_list[player_id]["team_color"] == Constants.TEAM_COLOR_ENUM.BLUE:
		temp_player.start_position = get_blue_random_position()
	else:
		temp_player.start_position = get_red_random_position()
	add_child(temp_player, true)
	connection_panel.hide()

func get_blue_random_position() -> Vector2:
	var x_pos = rng.randf_range(40, get_viewport().get_visible_rect().size.x / 2 - 40)
	var y_pos = rng.randf_range(40, get_viewport().get_visible_rect().size.y - 40)
	var random_position = Vector2(x_pos, y_pos)
	return random_position

func get_red_random_position() -> Vector2:
	var x_pos = rng.randf_range(get_viewport().get_visible_rect().size.x / 2 + 10, get_viewport().get_visible_rect().size.x - 10)
	var y_pos = rng.randf_range(10, get_viewport().get_visible_rect().size.y - 10)
	var random_position = Vector2(x_pos, y_pos)
	return random_position

func _on_ready_button_pressed():
	is_ready = !is_ready
	players_list[str(multiplayer.get_unique_id())]["is_ready"] = is_ready
	
	if is_ready:
		ready_button.add_theme_color_override("font_color", Color("#33ff30"))
		rpc("_update_players_ready", 1, players_list)
	else:
		ready_button.add_theme_color_override("font_color", Color("#ff3730"))
		rpc("_update_players_ready", -1, players_list)

func _on_red_team_button_pressed():
	red_team_button.disabled = true
	blue_team_button.disabled = false
	ready_button.disabled = false
	_change_red_team_remote(multiplayer.get_unique_id(), player_name_label.text)
	rpc("_update_players_state_v2", players_list)
	rpc("_change_red_team_remote", multiplayer.get_unique_id(), player_name_label.text)

@rpc("any_peer")
func _change_red_team_remote(player_id: int, player_name: String):
	_remove_player_from_team(player_id)
	var current_player = players_list.get(str(player_id))
	if current_player:
		var grid_childrens = blue_team_grid.get_children()
		for children in grid_childrens:
			if children.text == player_name:
				blue_team_grid.remove_child(children)
	players_list[str(player_id)]["team_color"] = Constants.TEAM_COLOR_ENUM.RED
	players_list[str(player_id)]["player_name"] = player_name
	var player_label = Label.new()
	player_label.text = player_name
	red_team_grid.add_child(player_label)

func _on_blue_team_button_pressed():
	red_team_button.disabled = false
	blue_team_button.disabled = true
	ready_button.disabled = false
	_change_blue_team_remote(multiplayer.get_unique_id(), player_name_label.text)
	rpc("_update_players_state_v2", players_list)
	rpc("_change_blue_team_remote", multiplayer.get_unique_id(), player_name_label.text)

@rpc("any_peer")
func _change_blue_team_remote(player_id: int, player_name: String):
	_remove_player_from_team(player_id)
	var current_player = players_list.get(str(player_id))
	if current_player:
		var grid_childrens = red_team_grid.get_children()
		for children in grid_childrens:
			if children.text == player_name:
				red_team_grid.remove_child(children)
	players_list[str(player_id)]["team_color"] = Constants.TEAM_COLOR_ENUM.BLUE
	players_list[str(player_id)]["player_name"] = player_name
	var player_label = Label.new()
	player_label.text = player_name
	blue_team_grid.add_child(player_label)

# ----------------------------------- Player Sync -----------------------------------

func peer_connected(id):
	if !IS_SERVER:
		return
	players_count += 1
	rpc("_update_players_state_labels_v2", players_count, players_ready)
	rpc("_update_players_state_v2", players_list)
	rpc_id(id, "_reconcile_data_connected", players_list)

func peer_disconnected(id):
	if !IS_SERVER:
		return
	print("Desconectando usuario: ", id)
	players_count += -1
	if players_list.get(str(id)).get("is_ready"):
		players_ready += -1
	players_list.erase(str(id))
	rpc("_sync_players_team_state", id)
	rpc("_update_players_state_v2", players_list)
	rpc("_update_players_state_labels_v2", players_count, players_ready)
	if players_count == 0:
		get_node("_Ball").call_deferred("queue_free")
		red_team_score = 0
		blue_team_score = 0
		for wall in get_tree().get_nodes_in_group("Wall"):
			wall.reset_wall_color_remote()
		var players := multiplayer.get_peers()
		for player_remote in get_tree().get_nodes_in_group("IsTeam"):
			player_remote.call_deferred("queue_free")
	
@rpc("any_peer", "call_local")
func _update_players_ready(player_ready, players_list_rpc):
	players_ready += player_ready
	players_ready_label.text = str(players_ready)
	players_list = players_list_rpc
	if players_count == players_ready && players_count > 1:
		if IS_SERVER:
			for player_id in players_list.keys():
				rpc("_add_new_player_remote", player_id)
				#rpc_id(player_id.to_int(), "_add_new_player_remote", player_id)
				add_new_player(player_id)
				# ---------------------------------------------
			rpc("_spawn_ball")
				#rpc_id(player_id.to_int(), "_spawn_ball")
			_spawn_ball()
		connection_panel.hide()
	
@rpc
func _add_new_player_remote(id: String):
	add_new_player(id)
	
@rpc
func _spawn_ball():
	new_ball = ball_scene.instantiate()
	new_ball.set_multiplayer_authority(1)
	#new_ball.position = Vector2(576, 324) #get_viewport().get_visible_rect().size / 2
	new_ball.name = "_Ball"
	add_child(new_ball, true)
	hasBallSpawned = true
	
@rpc("any_peer")
func _sync_players_team_state(id):
	var current_player = players_list.get(str(id))
	var has_team = current_player.get("team_color")
	if !has_team:
		return
	if has_team == Constants.TEAM_COLOR_ENUM.BLUE:
		remove_blue_team_player(current_player)
	else:
		remove_red_team_player(current_player)
	
@rpc("any_peer")
func _remove_player_from_team(id: int):
	var current_player = players_list.get(str(id))
	if !current_player || !current_player.get("team_color"):
		return
	if current_player["team_color"] == Constants.TEAM_COLOR_ENUM.BLUE:
		remove_blue_team_player(current_player)
	else:
		remove_red_team_player(current_player)

func remove_blue_team_player(current_player):
	var grid_blue_childrens = blue_team_grid.get_children()
	for children in grid_blue_childrens:
		if children.text == current_player["player_name"]:
			blue_team_grid.remove_child(children)

func remove_red_team_player(current_player):
	var grid_red_childrens = red_team_grid.get_children()
	for children in grid_red_childrens:
		if children.text == current_player["player_name"]:
			red_team_grid.remove_child(children)
 
@rpc("any_peer")
func _reconcile_data_connected(players_list_reconcilier):
	# Update players teams selected if have it
	for key in players_list_reconcilier:
		if key == str(multiplayer.get_unique_id()):
			break
		var current_player = players_list_reconcilier[str(key)]
		if !current_player.get("team_color"):
			return
		if current_player["team_color"] == Constants.TEAM_COLOR_ENUM.BLUE:
			var player_label = Label.new()
			player_label.text = current_player["player_name"]
			blue_team_grid.add_child(player_label)
		if current_player["team_color"] == Constants.TEAM_COLOR_ENUM.RED:
			var player_label = Label.new()
			player_label.text = current_player["player_name"]
			red_team_grid.add_child(player_label)

@rpc("any_peer")
func _update_players_state_labels_v2(remote_players_count, remote_players_ready):
	players_count = remote_players_count
	players_ready = remote_players_ready
	total_players_label.text = str(players_count)
	players_ready_label.text = str(players_ready)

@rpc("any_peer")
func _update_players_state_v2(remote_players_list):
	players_list = remote_players_list

# ----------------------------------- Game Functions -----------------------------------

func _ready():
	if IS_SERVER:
		_is_server_connection()
		multiplayer.peer_connected.connect(peer_connected)
		multiplayer.peer_disconnected.connect(peer_disconnected)
	else:
		var peer: ENetMultiplayerPeer = ENetMultiplayerPeer.new()
		peer.create_client(IP_REMOTE, PORT)
		if peer.get_connection_status() == MultiplayerPeer.CONNECTION_DISCONNECTED:
			print("Client connection failed")
			return
		multiplayer.multiplayer_peer = peer

func check_winner_team():
	if red_team_score == goal_score:
		
		rpc("show_goal_text", Constants.TEAM_COLOR_ENUM.RED)
		#show_goal_text(Constants.TEAM_COLOR_ENUM.RED)
		await get_tree().create_timer(3).timeout
		var ball = get_node("_Ball")
		ball.speed = 0
		rpc("reset_ball_state")
		reset_ball_state()
		rpc("reset_players_state")
		reset_players_state()
	if blue_team_score == goal_score:
		rpc("show_goal_text", Constants.TEAM_COLOR_ENUM.BLUE)
		#show_goal_text(Constants.TEAM_COLOR_ENUM.BLUE)
		await get_tree().create_timer(3).timeout
		var ball = get_node("_Ball")
		ball.speed = 0
		rpc("reset_ball_state")
		reset_ball_state()
		rpc("reset_players_state")
		reset_players_state()

@rpc("any_peer")
func reset_players_state():
	for player in get_tree().get_nodes_in_group("IsTeam"):
		player.reset_position()

@rpc("any_peer")
func show_goal_text(team: Constants.TEAM_COLOR_ENUM):
	goal_control.visible = true
	var goal_label: Label = goal_control.get_node("GoalLabel")
	goal_label.modulate = Constants.team_color_object[team]
	if Constants.TEAM_COLOR_ENUM.BLUE == team:
		blue_scoreboard.text = str(blue_scoreboard.text.to_int() + 1)
	else:
		red_scoreboard.text = str(red_scoreboard.text.to_int() + 1)
	
@rpc("any_peer")
func reset_ball_state():
	var ball = get_node("_Ball")
	ball.position = Vector2(576, 324)
	ball.speed = 300
	ball.start_ball_movement()

# Deprecated
func reset_players_state_remote():
	for player_remote_id in multiplayer.get_peers():
		rpc_id(player_remote_id, "reset_player_position")

@rpc("any_peer")
func reset_player_position():
	pass
	#if local_player_character:
	#	local_player_character.reset_position()

func _is_server_connection():
	var peer: ENetMultiplayerPeer = ENetMultiplayerPeer.new()
	peer.create_server(PORT)
	if peer.get_connection_status() == MultiplayerPeer.CONNECTION_DISCONNECTED:
		print("Server creation failed")
		return
	multiplayer.multiplayer_peer = peer
	#peer.peer_connected.connect(start_game)
	print("Server connection success")
