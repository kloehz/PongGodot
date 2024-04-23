extends Node2D

var PORT: int = 25565

@export var ipText: TextEdit
@export var UI: Control
@export var playerScene: PackedScene
@export var ballScene: PackedScene

var hasBallSpawned: bool = false

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

func _physics_process(_delta):
	if not multiplayer.is_server():
		return
	if multiplayer.get_peers().size() >= 1 && !hasBallSpawned:
		var new_ball: RigidBody2D = ballScene.instantiate()
		new_ball.position = get_viewport().get_visible_rect().size / 2
		add_child(new_ball, true)
		hasBallSpawned = true

func _on_connect_button_pressed():
	var peer: ENetMultiplayerPeer = ENetMultiplayerPeer.new()
	peer.create_client(ipText.text, PORT)
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
	var tempPlayer: CharacterBody2D = playerScene.instantiate()
	tempPlayer.name = str(id)
	tempPlayer.position = get_viewport().get_visible_rect().size / 2
	add_child(tempPlayer)
