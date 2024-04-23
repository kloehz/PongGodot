extends CharacterBody2D


const SPEED = 300.0

func _enter_tree():
	set_multiplayer_authority(name.to_int())

func _ready():
	if(!is_multiplayer_authority()):
		return
	if(multiplayer.is_server()):
		position = Vector2(50, get_viewport().get_visible_rect().size.y / 2)
	else:
		position = Vector2(get_viewport().get_visible_rect().size.x - 50, get_viewport().get_visible_rect().size.y / 2)

func _physics_process(_delta):
	if !is_multiplayer_authority(): return
	var direction = Input.get_axis("ui_up", "ui_down")
	if direction:
		velocity.y = direction * SPEED
	else:
		velocity.y = move_toward(velocity.y, 0, SPEED)
	move_and_slide()
