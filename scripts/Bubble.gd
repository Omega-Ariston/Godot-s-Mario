class_name Bubble
extends Node2D

const SPEED := 60

func _ready() -> void:
	# 上浮到水面
	if global_position.y > Variables.WATER_SURFACE_Y_OFFSET:
		var tween := create_tween()
		var duration := (global_position.y - Variables.WATER_SURFACE_Y_OFFSET) / SPEED as float
		tween.tween_property(self, "global_position:y", Variables.WATER_SURFACE_Y_OFFSET, duration)
		await tween.finished
	queue_free()
