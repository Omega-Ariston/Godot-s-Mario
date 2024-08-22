class_name Flower
extends Node2D

@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var sprite_2d: Sprite2D = $Sprite2D

const SPAWN_DURATION := 1.0
const SCORE := 1000

const RECT_ORIGIN := Rect2(0, 32, 64, 16)
const RECT_CYAN := Rect2(144, 32, 64, 16)

func _ready() -> void:
	match GameManager.current_world_type:
		GameManager.WorldType.GROUND:
			sprite_2d.region_rect = RECT_ORIGIN
		GameManager.WorldType.UNDER:
			sprite_2d.region_rect = RECT_CYAN
	animation_player.play("idle")
	# 让自身向上顶出一个砖的高度
	var tween := create_tween()
	tween.tween_property(self, "position:y", position.y - Variables.TILE_SIZE.y, SPAWN_DURATION)
	await tween.finished
