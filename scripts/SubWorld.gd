class_name SubWorld
extends Node2D

@export var world_type: GameManager.WorldType

@onready var player: Player = $Player
@onready var spawn_point: SpawnPoint = $SpawnPoint

func _ready() -> void:
	GameManager.current_spawn_point = spawn_point.name
	GameManager.current_world_type = world_type
	GameManager.world_ready.emit()
	await GameManager.screen_ready
	SoundManager.play_world_bgm()
	GameManager.control_player(player)
	GameManager.game_timer.start()
