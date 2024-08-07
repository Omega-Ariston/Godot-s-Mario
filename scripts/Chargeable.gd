extends Area2D

func _on_body_entered(body: Node2D) -> void:
	if body is Turtle and body.state_machine.current_state == Turtle.State.SHOOT:
		var player := get_tree().get_first_node_in_group("Player") as Player
		if owner is Brick:
			owner.on_bumped(player)
		elif owner is CoinBrick:
			owner.on_charged(player)
