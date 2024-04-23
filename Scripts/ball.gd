extends RigidBody2D


# Called when the node enters the scene tree for the first time.
func _ready():
	if !multiplayer.is_server():
		return
	set_axis_velocity(Vector2(1,1) * -200)
