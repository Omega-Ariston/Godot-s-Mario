class_name FireBar
extends Node2D

const SPEED := 1.06

@export var direction: Direction

@onready var graphics: Node2D = $Graphics
@onready var animation_player: AnimationPlayer = $AnimationPlayer

enum Direction {
	CLOCKWISE,
	COUNTER_CLOCKWISE,
}

func _ready() -> void:
	var rng := RandomNumberGenerator.new()
	var current_frame := rng.randf_range(0, 0.7)
	animation_player.speed_scale = SPEED
	
	match direction:
		Direction.CLOCKWISE:
			animation_player.play("spin")
		Direction.COUNTER_CLOCKWISE:
			animation_player.play_backwards("spin")
		
	animation_player.seek(current_frame, true)

func _on_area_2d_body_entered(body: Player) -> void:
	body.hurt(self)
