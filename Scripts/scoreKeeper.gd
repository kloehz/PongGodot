extends Area2D

@export var scoreBoard: Label

var scoreCounter: int


func _on_body_entered(body):
	if body.name.contains("Ball"):
		scoreCounter+=1
		scoreBoard.text = str(scoreCounter)
		rpc("update_score", scoreCounter)
		body.queue_free()
		get_tree().root.get_node("NetworkManager").hasBallSpawned = false

@rpc("any_peer")
func update_score(newScore: int):
	scoreBoard.text = str(newScore)
