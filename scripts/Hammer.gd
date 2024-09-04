class_name Hammer
extends RigidBody2D

const IMPULSE := Vector2(100, -230)
const LAUNCH_DELAY := 0.2

var direction := -1

@onready var animation_player: AnimationPlayer = $AnimationPlayer

signal thrown

func _ready() -> void:
	animation_player.play("idle")
	await get_tree().create_timer(LAUNCH_DELAY).timeout
	launch()
	thrown.emit()

func launch() -> void:
	freeze = false
	apply_central_impulse(Vector2(IMPULSE.x * direction, IMPULSE.y))
	match direction:
		-1:
			animation_player.play("spin")
		+1:
			animation_player.play_backwards("spin")


func _on_visible_on_screen_notifier_2d_screen_exited() -> void:
	queue_free()
