class_name Bubble
extends Node2D

const SPEED := 60

func _ready() -> void:
	var water_surface := Variables.WATER_SURFACE_Y_OFFSET - Variables.TILE_SIZE.y
	# 上浮到水面
	if global_position.y > water_surface:
		var tween := create_tween()
		var duration := (global_position.y - water_surface) / SPEED as float
		tween.tween_property(self, "global_position:y", water_surface, duration)
		await tween.finished
	queue_free()
