class_name Flower
extends Node2D

@onready var animation_player: AnimationPlayer = $AnimationPlayer

const SPAWN_DURATION := 1.0

func _ready() -> void:
	animation_player.play("idle")

	# 让自身向上顶出一个砖的高度
	var tween := create_tween()
	tween.tween_property(self, "position:y", position.y - GameManager.TILE_SIZE.y, SPAWN_DURATION)
	await tween.finished
