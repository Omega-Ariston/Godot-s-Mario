extends Node2D

@onready var spawn_point: SpawnPoint = $SpawnPoint
@onready var player: Player = $Player
@onready var foreground: TileMapLayer = $Foreground


func _ready() -> void:
	GameManager.uncontrol_player(player)
	GameManager.max_left_x = 0
	await GameManager.screen_ready
	var bgm_player := SoundManager.into_the_under()
	player.state_machine.current_state = Player.State.WALK
	var tween = create_tween()
	tween.tween_property(player, "global_position:x", player.global_position.x + Variables.TILE_SIZE.x * 7.5, 3)
	await bgm_player.finished
	GameManager.change_scene(StatusBar.level)
