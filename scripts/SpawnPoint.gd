class_name SpawnPoint
extends Marker2D

@export var direction: SPAWN_DIRECTION

enum SPAWN_DIRECTION {
	NONE = 0,
	UP = 1,
	DOWN = -1,
}

func _init() -> void:
	add_to_group("SpawnPoints")
