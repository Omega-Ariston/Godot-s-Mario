class_name Eatable
extends RigidBody2D

func _on_eaten(player: Player):
	player._eat(self)
