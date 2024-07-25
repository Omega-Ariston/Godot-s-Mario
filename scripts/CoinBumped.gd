class_name CoinBumped
extends Node2D

const BOUNCE_HEIGHT := GameManager.TILE_SIZE.y * 3
const BOUNCE_DURATION := 0.2

func _ready() -> void:
	# 让自身向上抛起两个tile_size后落下，然后消失，并出现分数200分
	var originalY := position.y
	var tween := create_tween()
	tween.tween_property(self, "position:y", originalY - BOUNCE_HEIGHT, BOUNCE_DURATION)
	tween.tween_property(self, "position:y", originalY - BOUNCE_HEIGHT * 1/3, BOUNCE_DURATION)
	await tween.finished
	queue_free()
	
