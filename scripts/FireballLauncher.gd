class_name FireballLauncher
extends Marker2D

func launch() -> void:
	var fireball_instance = load("res://scenes/items/fireball.tscn").instantiate() as Fireball
	fireball_instance.direction = owner.direction
	fireball_instance.global_position = global_position
	get_tree().root.add_child(fireball_instance)
	SoundManager.play_sfx("Fireball")
