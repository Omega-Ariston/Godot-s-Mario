extends StaticBody2D

@export var direction := -1 # -1表示向上，1表示向下

const SPEED := 48
const UP_BOUND := Variables.TILE_SIZE.y
const DOWN_BOUND := Variables.TILE_SIZE.y * 16

func _physics_process(delta: float) -> void:
	global_position.y += direction * SPEED * delta
	match direction:
		-1:
			if global_position.y < UP_BOUND:
				global_position.y = DOWN_BOUND
		1:
			if global_position.y > DOWN_BOUND:
				global_position.y = UP_BOUND
