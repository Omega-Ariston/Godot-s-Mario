class_name BumpArea
extends Area2D

signal bump(bumper)

func _init() -> void:
	area_entered.connect(_on_area_entered)
	

func _on_area_entered(bumper: Bumper) -> void:
	print_debug("[Bumped] %s => %s" % [bumper.owner.name, owner.name])
	bump.emit(bumper)
