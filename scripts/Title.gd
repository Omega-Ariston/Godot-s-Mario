extends Node2D

func _unhandled_input(event: InputEvent) -> void:
		# TODO: 续关的逻辑
	if event.is_action_pressed("start"):
		GameManager.change_scene("res://scenes/worlds/start.tscn")
