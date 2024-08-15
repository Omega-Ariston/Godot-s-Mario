extends Node2D

@onready var animation_player: AnimationPlayer = $AnimationPlayer

signal vanished

const SCORE := 500

func _ready() -> void:
	SoundManager.play_sfx("Fireworks")
	ScoreManager.add_score(SCORE, self, false)
	animation_player.play("firework", -1, 1.0, false)

func vanish() -> void:
	visible = false
	await get_tree().create_timer(0.2).timeout
	vanished.emit()
	queue_free()
