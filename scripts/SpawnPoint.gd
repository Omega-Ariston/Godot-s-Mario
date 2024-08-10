class_name SpawnPoint
extends Marker2D

@export var direction: Spawn_Direction
@export var type: Type

enum Spawn_Direction {
	NONE = 0,
	UP = 1,
	DOWN = -1,
}

enum Type {
	NONE,
	PIPE,
	VINE,
}

func _init() -> void:
	add_to_group("SpawnPoints")
