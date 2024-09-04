class_name HammerLauncher
extends Marker2D

func launch() -> void:
	var hammer_instance = load("res://scenes/items/hammer.tscn").instantiate() as Hammer
	hammer_instance.direction = owner.direction
	add_child(hammer_instance)
	await hammer_instance.thrown
