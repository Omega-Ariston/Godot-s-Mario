class_name SubWorld
extends Node2D

@export var world_type: GameManager.WorldType

@onready var foreground: TileMapLayer = $Foreground
@onready var player: Player = $Player
@onready var camera_2d: Camera2D = $Player/Camera2D
@onready var spawn_point: SpawnPoint = $SpawnPoint

var viewport_size: Vector2

func _ready() -> void:
	GameManager.current_spawn_point = spawn_point.name
	GameManager.current_world_type = world_type
	setup_camera()
	GameManager.world_ready.emit()
	await GameManager.screen_ready
	SoundManager.play_world_bgm()
	GameManager.control_player(player)
	GameManager.game_timer.start()

func _process(_delta: float) -> void:
	var center_position := camera_2d.get_screen_center_position()
	var left_coord := center_position.x - viewport_size.x / 2
	GameManager.max_left_x = max(left_coord, GameManager.max_left_x)
	camera_2d.limit_left = ceili(GameManager.max_left_x)

func setup_camera() -> void:
	viewport_size = get_viewport_rect().size
	var used := foreground.get_used_rect()
	var tile_size := Variables.TILE_SIZE
	
	camera_2d.limit_top = floori(0.5 * tile_size.y) # 最上面一个方块只显示一半
	camera_2d.limit_right = floori((used.end.x - 1) * tile_size.x)
	camera_2d.limit_bottom = ceili((used.end.y - 0.5) * tile_size.y) # 最下面一个方块只显示一半
	camera_2d.limit_left = 0
