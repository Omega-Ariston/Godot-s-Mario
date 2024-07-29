class_name ItemLauncher
extends Marker2D

enum Launchable {
	FIREBALL,
	HAMMER,
	HADOUKEN,
}

@export var item: Launchable


func launch() -> void:
	# 发射火焰
	if item == Launchable.FIREBALL:
		print_debug("LAUNCH: Fireball")
		var fireball_instance = load("res://scenes/items/fireball.tscn").instantiate() as Fireball
		fireball_instance.direction = owner.direction
		fireball_instance.global_position = global_position
		get_tree().root.add_child(fireball_instance)
