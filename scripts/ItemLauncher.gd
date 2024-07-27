class_name ItemLauncher
extends Marker2D

enum Launchable {
	FIREBALL,
	HAMMER,
	HADOUKEN,
}

@export var item: Launchable


func launch() -> void:
	# 发射火焰，最多只能发射两个
	if item == Launchable.FIREBALL:
		print_debug("LAUNCH: Fireball")
		var fireball_instance = load("res://scenes/items/fireball.tscn").instantiate() as Fireball
		fireball_instance.direction = owner.direction
		call_deferred("add_child", fireball_instance)
