class_name HadoukenLauncher
extends Marker2D

func launch() -> void:
	var hadouken_instance = preload("res://scenes/items/hadouken.tscn").instantiate() as Hadouken
	hadouken_instance.global_position = global_position
	get_tree().root.add_child(hadouken_instance)
