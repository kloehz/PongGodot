extends Node2D

var PORT: int = 25565

@export var ip_text: TextEdit
@export var player_scene: PackedScene
@export var ball_scene: PackedScene
@export var goal_control: Control

@onready var name_control = $CanvasLayer/NameControl
@onready var connection_panel = $CanvasLayer/ConnectionPannel
@onready var player_name_label = $CanvasLayer/NameControl/PlayerName
@onready var players_ready_label = $CanvasLayer/ConnectionPannel/GridContainer/PlayersReady
@onready var total_players_label = $CanvasLayer/ConnectionPannel/GridContainer/TotalPlayers
@onready var ready_button = $CanvasLayer/ConnectionPannel/ReadyButton
@onready var blue_team_grid: GridContainer = $CanvasLayer/ConnectionPannel/BlueTeam
@onready var red_team_grid: GridContainer = $CanvasLayer/ConnectionPannel/RedTeam
@onready var red_team_button = $CanvasLayer/ConnectionPannel/RedTeamButton
@onready var blue_team_button = $CanvasLayer/ConnectionPannel/BlueTeamButton

var red_team_score: int = 0
var blue_team_score: int = 0
var hasBallSpawned: bool = false
var goal_score: int = 8
var new_ball: RigidBody2D;
var new_ball_v2: CharacterBody2D;
var players_count = 0
var players_ready = 0
var players_list = {}
var is_ready = true

# TEMPORTAL VAR ENV
const IS_SERVER = false

# ------------------------------------- Lobby functions -------------------------------------

func _on_confirm_name_pressed():
	name_control.hide()
	_on_player_connection()
	connection_panel.show()

func _on_player_connection():
	var peer: ENetMultiplayerPeer = ENetMultiplayerPeer.new()
	peer.create_client(ip_text.text, PORT)
	if peer.get_connection_status() == MultiplayerPeer.CONNECTION_DISCONNECTED:
		print("Client connection failed")
		return
	multiplayer.multiplayer_peer = peer

func start_game(id: int):
	for player_id in players_list.keys():
		# Separate spawns based on teams
		var tempPlayer: CharacterBody2D = player_scene.instantiate()
		tempPlayer.player_name = player_name_label.text
		tempPlayer.name = str(id)
		tempPlayer.team_color_enum = Constants.TEAM_COLOR_ENUM.RED
		#start_game(multiplayer.get_unique_id())
		add_child(tempPlayer)

func _on_ready_button_pressed():
	players_list[multiplayer.get_unique_id()] = {
		"is_ready": is_ready
	}
	is_ready = false
	update_players_count(is_ready)

@rpc("any_peer")
func update_players_count(is_ready_rpc: bool):
	if is_ready_rpc:
		players_ready_label += 1
		players_ready += 1
	else:
		players_ready_label -= 1
		players_ready -= 1

func _on_red_team_button_pressed():
	red_team_button.disabled = true
	blue_team_button.disabled = false
	#_change_red_team_remote(multiplayer.get_unique_id(), player_name_label.text)
	rpc("_change_red_team_remote", multiplayer.get_unique_id(), player_name_label.text)

@rpc("any_peer" )
func _change_red_team_remote(player_id: int, player_name: String):
	var current_player = players_list.get(str(player_id))
	#if current_player && current_player["team_color"] != Constants.TEAM_COLOR_ENUM.RED:
	if current_player:
		var grid_childrens = blue_team_grid.get_children()
		for children in grid_childrens:
			if children.text == players_list[str(player_id)]["player_name"]:
				blue_team_grid.remove_child(children)
		
	players_list[str(player_id)] = {
		"team_color": Constants.TEAM_COLOR_ENUM.RED,
		"player_name": players_list[str(player_id)]["player_name"],
	}
	var player_label = Label.new()
	player_label.text = players_list[str(player_id)]["player_name"]
	red_team_grid.add_child(player_label)

func _on_blue_team_button_pressed():
	red_team_button.disabled = false
	blue_team_button.disabled = true
	#_change_blue_team_remote(multiplayer.get_unique_id(), player_name_label.text)
	rpc("_change_blue_team_remote", multiplayer.get_unique_id(), player_name_label.text)

@rpc("any_peer")
func _change_blue_team_remote(player_id: int, player_name: String):
	var current_player = players_list.get(str(player_id))
	#if current_player && current_player["team_color"] != Constants.TEAM_COLOR_ENUM.BLUE:
	if current_player:
		var grid_childrens = red_team_grid.get_children()
		for children in grid_childrens:
			if children.text == players_list[str(player_id)]["player_name"]:
				red_team_grid.remove_child(children)
				
	players_list[str(player_id)] = {
		"team_color": Constants.TEAM_COLOR_ENUM.BLUE,
		"player_name": players_list[str(player_id)]["player_name"],
	}
	var player_label = Label.new()
	player_label.text = player_name_label.text
	blue_team_grid.add_child(player_label)

# ----------------------------------- Player Counter UI -----------------------------------

func peer_connected(id):
	if IS_SERVER:
		return
	rpc("_update_total_players_label", 1)
	
func peer_disconnected(id):
	if IS_SERVER:
		return
	rpc("_update_total_players_label", -1)

@rpc("any_peer")
func _update_total_players_label(count: int):
	players_count += count
	total_players_label.text = str(players_count)

# ----------------------------------- Game Functions -----------------------------------

func _ready():
	if IS_SERVER:
		_is_server_connection()
		multiplayer.peer_connected.connect(peer_connected)
		multiplayer.peer_disconnected.connect(peer_disconnected)

func check_winner_team():
	if red_team_score == goal_score:
		rpc("show_goal_text", Constants.TEAM_COLOR_ENUM.RED)
		show_goal_text(Constants.TEAM_COLOR_ENUM.RED)
	if blue_team_score == goal_score:
		rpc("show_goal_text", Constants.TEAM_COLOR_ENUM.BLUE)
		show_goal_text(Constants.TEAM_COLOR_ENUM.BLUE)

func _physics_process(_delta):
	if not multiplayer.is_server():
		return
	if multiplayer.get_peers().size() >= 1 && !hasBallSpawned:
		new_ball = ball_scene.instantiate()
		new_ball.position = get_viewport().get_visible_rect().size / 2
		new_ball.name = "_Ball"
		add_child(new_ball, true)
		hasBallSpawned = true

@rpc("any_peer")
func show_goal_text(team: int):
	goal_control.visible = true
	var goal_label: Label = goal_control.get_node("GoalLabel")
	goal_label.modulate = Constants.team_color_object[team]
	var ball = get_node("_Ball")
	ball.speed = 0
	
func _is_server_connection():
	var peer: ENetMultiplayerPeer = ENetMultiplayerPeer.new()
	peer.create_server(PORT)
	if peer.get_connection_status() == MultiplayerPeer.CONNECTION_DISCONNECTED:
		print("Server creation failed")
		return
	multiplayer.multiplayer_peer = peer
	peer.peer_connected.connect(start_game)
