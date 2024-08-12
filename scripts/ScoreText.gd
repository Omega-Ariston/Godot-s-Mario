class_name ScoreText
extends CanvasLayer

const SLOW_DURATION := 1.0
const FAST_DURATION := 0.5
const RISE_DISTANCE := Variables.TILE_SIZE.y * 2

enum Speed {
	SLOW, # 顶金币时的分数消失比较慢
	FAST, # 杀敌时的分数消失比较快
}

@onready var text_label: RichTextLabel = $Text


func initialize(pos: Vector2, text: String, speed: Speed) -> void:
	if not is_node_ready():
		await ready
	text_label.position = Vector2(128, 128)
	text_label.text = text
	var tween := create_tween()
	tween.tween_property(text_label, "position:y", text_label.position.y - RISE_DISTANCE, SLOW_DURATION if speed == Speed.SLOW else FAST_DURATION)
	await tween.finished
	queue_free()
