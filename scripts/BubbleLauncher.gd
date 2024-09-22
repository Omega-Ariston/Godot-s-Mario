class_name BubbleLauncher
extends Marker2D

# 每隔几秒生成一个泡泡

const LAUNCH_RANGE := [0.5, 1.5]

@onready var timer: Timer = $Timer

func _ready() -> void:
	GameManager.world_ready.connect(_on_world_ready)

func launch_bubble() -> void:
	var bubble_instance = preload("res://scenes/items/bubble.tscn").instantiate() as Bubble
	bubble_instance.global_position = global_position
	get_tree().root.add_child(bubble_instance)

func _on_world_ready() -> void:
	if GameManager.current_world_type == GameManager.WorldType.WATER:
		timer.start(GameManager.rng.randf_range(LAUNCH_RANGE[0], LAUNCH_RANGE[1]))

func _on_timer_timeout() -> void:
	launch_bubble()
	timer.start(GameManager.rng.randf_range(LAUNCH_RANGE[0], LAUNCH_RANGE[1]))
