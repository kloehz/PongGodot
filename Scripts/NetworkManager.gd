extends Node2D

var PORT: int = 25565

@export var ip_text: TextEdit
@export var UI: Control
@export var player_scene: PackedScene
@export var ball_scene: PackedScene
@export var goal_control: Control

var red_team_score: int = 0
var blue_team_score: int = 0
var hasBallSpawned: bool = false
var goal_score: int = 8
var new_ball: CharacterBody2D;

func _ready():
	multiplayer.peer_connected.connect(peer_connected)
	multiplayer.peer_disconnected.connect(peer_disconnected)
	multiplayer.connected_to_server.connect(peer_connected)
	multiplayer.connection_failed.connect(peer_connected)

func peer_connected(id):
	print("Player Connected: ", id)

func peer_disconnected(id):
	print("peer_disconnected: ", id)

func connected_to_server():
	print("connected_to_server: ")


func connection_failed():
	print("connection_failed: ")
# --------------------------------------------

func _physics_process(_delta):
	if not multiplayer.is_server():
		return
	if multiplayer.get_peers().size() >= 1 && !hasBallSpawned:
		new_ball = ball_scene.instantiate()
		new_ball.position = get_viewport().get_visible_rect().size / 2
		new_ball.name = "_Ball"
		add_child(new_ball, true)
		hasBallSpawned = true

func _on_connect_button_pressed():
	var peer: ENetMultiplayerPeer = ENetMultiplayerPeer.new()
	peer.create_client(ip_text.text, PORT)
	if peer.get_connection_status() == MultiplayerPeer.CONNECTION_DISCONNECTED:
		print("Client connection failed")
		return
	multiplayer.multiplayer_peer = peer
	start_game(multiplayer.get_unique_id())

func _on_host_button_pressed():
	var peer: ENetMultiplayerPeer = ENetMultiplayerPeer.new()
	peer.create_server(PORT)
	if peer.get_connection_status() == MultiplayerPeer.CONNECTION_DISCONNECTED:
		print("Server creation failed")
		return
	multiplayer.multiplayer_peer = peer
	peer.peer_connected.connect(start_game)
	start_game(multiplayer.get_unique_id())

func start_game(id: int):
	UI.hide()
	var tempPlayer: CharacterBody2D = player_scene.instantiate()
	tempPlayer.name = str(id)
	tempPlayer.team_color_enum = Constants.TEAM_COLOR_ENUM.RED
	add_child(tempPlayer)

func check_winner_team():
	if red_team_score == goal_score:
		rpc("show_goal_text", Constants.TEAM_COLOR_ENUM.RED)
		show_goal_text(Constants.TEAM_COLOR_ENUM.RED)
		print("red_team_win")
	if blue_team_score == goal_score:
		rpc("show_goal_text", Constants.TEAM_COLOR_ENUM.BLUE)
		show_goal_text(Constants.TEAM_COLOR_ENUM.BLUE)
		print("blue_team_win")
		
@rpc("any_peer")
func show_goal_text(team: int):
	goal_control.visible = true
	var goal_label: Label = goal_control.get_node("GoalLabel")
	goal_label.modulate = Constants.team_color_object[team]
	var ball = get_node("_Ball")
	ball.speed = 0

