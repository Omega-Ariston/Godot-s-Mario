extends Node2D

@onready var spawn_point: SpawnPoint = $SpawnPoint
@onready var player: Player = $Player
@onready var foreground: TileMapLayer = $Foreground


func _ready() -> void:
	await GameManager.screen_ready
	GameManager.uncontrol_player(player)
	var bgm_player := SoundManager.into_the_under()
	player.state_machine.current_state = Player.State.WALK
	var tween = create_tween()
	tween.tween_property(player, "global_position:x", player.global_position.x + Variables.TILE_SIZE.x * 7.5, 3)
	await bgm_player.finished
	GameManager.change_scene(StatusBar.level)
