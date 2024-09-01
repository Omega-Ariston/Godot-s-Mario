class_name World
extends Node2D

@export var world_type: GameManager.WorldType
@export var level_time: int  # 8-1和8-3只有300秒，其余关是400秒
@export var level_name: String

@onready var foreground: TileMapLayer = $Foreground
@onready var camera_2d: Camera2D = $Player/Camera2D
@onready var player: Player = $Player
@onready var spawn_points: Node = $SpawnPoints
@onready var spawn_point: SpawnPoint = $SpawnPoints/SpawnPoint

var viewport_size: Vector2

func _ready() -> void:
	GameManager.screen_ready.connect(_on_screen_ready)
	# 旗帜关不会设置level_name
	if not level_name:
		GameManager.current_spawn_point = spawn_point.name
	elif GameManager.current_level != level_name:
		GameManager.current_level = level_name
		GameManager.current_spawn_point = spawn_point.name
	GameManager.max_left_x = max(0, spawn_points.find_child(GameManager.current_spawn_point).global_position.x - GameManager.INITIAL_CAMERA_OFFSET)
	StatusBar.time = level_time
	GameManager.current_world_type = world_type
	setup_camera()
	GameManager.world_ready.emit()

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
	camera_2d.limit_right = floori(used.end.x * tile_size.x)
	camera_2d.limit_bottom = ceili((used.end.y - 0.5) * tile_size.y) # 最下面一个方块只显示一半
	camera_2d.limit_left = 0

func _on_screen_ready() -> void:
	SoundManager.play_world_bgm()
	GameManager.control_player(player)
	GameManager.game_timer.start()
	
